import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/golden_habit.dart';
import 'all_habits.dart';
import 'core_lists_service.dart';
import 'habits_service.dart';
import 'onboarding_service.dart' show GoldenHabitRef;
import 'routine_schedule.dart';

/// A routine whose time has come and that isn't ticked yet today.
class DueRoutine {
  const DueRoutine({
    required this.key,
    required this.name,
    required this.core,
    required this.minutes,
    this.anchorLabel,
  });
  final String key;
  final String name;

  /// Short Core id.
  final String core;

  /// Minutes after midnight it was due.
  final int minutes;
  final String? anchorLabel;

  String get timeLabel => fmtHm(minutes);
}

/// In-app routine reminders. Works out which of today's routines are due (their
/// time has been reached and they aren't ticked), so the shell can badge the
/// Routines button, fill the top notification bar and pop a card at the moment
/// a routine is due. In-app only: it runs while the app is open (no push).
class RoutineReminders extends ChangeNotifier {
  RoutineReminders._();
  static final RoutineReminders instance = RoutineReminders._();

  /// A popup is only raised for routines that became due this recently, so
  /// opening the app in the evening shows the bar/badge, not a card stack.
  static const _popupWindowMin = 30;

  final _schedSvc = RoutineScheduleService();
  final _lists = CoreListsService();
  final _habits = HabitsService();

  Timer? _tick;
  Timer? _reload;
  String? _uid;
  bool _loading = false;

  /// Routines with a time today: key → (name, core, minutes, anchor label).
  List<DueRoutine> _scheduled = const [];
  Set<String> _done = {};
  final Set<String> _popped = {};
  final Map<String, DateTime> _snoozedUntil = {};
  String _dayId = '';

  List<DueRoutine> _due = const [];
  DueRoutine? _popup;

  /// Bumped when a routine is ticked from outside the Routines screen, so an
  /// open Routines screen can reload.
  final ValueNotifier<int> externalChange = ValueNotifier<int>(0);

  /// Due and not ticked, earliest first.
  List<DueRoutine> get due => _due;
  int get count => _due.length;

  /// The routine to show in the popup right now, or null.
  DueRoutine? get popup => _popup;

  void start() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    if (_uid == uid && _tick != null) return;
    _uid = uid;
    _tick?.cancel();
    _reload?.cancel();
    refresh();
    _tick = Timer.periodic(const Duration(seconds: 20), (_) => _evaluate());
    _reload = Timer.periodic(const Duration(minutes: 5), (_) => refresh());
  }

  void stop() {
    _tick?.cancel();
    _reload?.cancel();
    _tick = _reload = null;
    _uid = null;
    _scheduled = const [];
    _due = const [];
    _popup = null;
    _popped.clear();
    _snoozedUntil.clear();
    notifyListeners();
  }

  /// Reloads schedules and today's ticks. Call after anything that changes them.
  Future<void> refresh() async {
    final uid = _uid;
    if (uid == null || _loading) return;
    _loading = true;
    try {
      final res = await _lists.getRoutineData(uid);
      var golden = <GoldenHabit>[];
      try {
        golden = (await _habits.getGoldenHabits(uid)).data;
      } catch (_) {}
      final anchors = await _schedSvc.loadAnchors(uid);
      final schedules = await _schedSvc.loadSchedules(uid);
      final log = await _schedSvc.loadLog(uid, DateTime.now());
      final lists = withGoldenLines(
        routine: res.data.routine,
        nonRoutine: res.data.nonRoutine,
        golden: golden,
      );
      final gi = goldenIndex(golden);
      final out = <DueRoutine>[];
      for (final l in lists.routine) {
        final core = GoldenHabitRef.shortCore(l.coreId);
        for (final raw in l.items) {
          final p = parseHabitLine(raw);
          final key = habitKey(core, raw);
          final g = gi[_goldenKey(core, p.name)];
          final slot = resolveSlot(
            schedule: schedules[key],
            anchors: anchors,
            blockId: p.blockId,
            cue: p.cue,
            when: g?.when ?? '',
          );
          if (slot == null) continue;
          out.add(DueRoutine(
            key: key,
            name: p.name,
            core: core,
            minutes: slot.minutes,
            anchorLabel: slot.anchor?.label,
          ));
        }
      }
      out.sort((a, b) => a.minutes.compareTo(b.minutes));
      _scheduled = out;
      _done = log.done.keys.toSet();
      _dayId = _today();
      _evaluate();
    } catch (e) {
      debugPrint('RoutineReminders.refresh failed: $e');
    } finally {
      _loading = false;
    }
  }

  // Matches goldenIndex's key (core + lower-cased name).
  String _goldenKey(String core, String name) =>
      '$core|${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim()}';

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  void _evaluate() {
    if (_dayId != _today()) {
      // Past midnight: yesterday's ticks no longer apply.
      _popped.clear();
      _snoozedUntil.clear();
      _done = {};
      _dayId = _today();
      refresh();
    }
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final due = [
      for (final r in _scheduled)
        if (r.minutes <= nowMin && !_done.contains(r.key)) r,
    ];
    DueRoutine? popup = _popup;
    if (popup != null && (_done.contains(popup.key))) popup = null;
    if (popup == null) {
      for (final r in due) {
        if (_popped.contains(r.key)) continue;
        final snooze = _snoozedUntil[r.key];
        if (snooze != null && now.isBefore(snooze)) continue;
        if (snooze == null && nowMin - r.minutes > _popupWindowMin) {
          // Became due long ago (e.g. app opened later): bar only.
          _popped.add(r.key);
          continue;
        }
        _popped.add(r.key);
        popup = r;
        break;
      }
    }
    final changed = popup?.key != _popup?.key ||
        due.length != _due.length ||
        !listEquals([for (final r in due) r.key], [for (final r in _due) r.key]);
    _due = due;
    _popup = popup;
    if (changed) notifyListeners();
  }

  /// Closes the popup; the routine stays in the bar and badge.
  void dismissPopup() {
    _popup = null;
    notifyListeners();
  }

  /// Re-raises the popup for [r] after [minutes].
  void snooze(DueRoutine r, {int minutes = 10}) {
    _snoozedUntil[r.key] = DateTime.now().add(Duration(minutes: minutes));
    _popped.remove(r.key);
    if (_popup?.key == r.key) _popup = null;
    notifyListeners();
  }

  /// Ticks [r] for today (the same write the Routines screen makes).
  Future<bool> markDone(DueRoutine r) async {
    final uid = _uid;
    if (uid == null) return false;
    final n = DateTime.now();
    final hm = fmtHm(n.hour * 60 + n.minute);
    _done = {..._done, r.key};
    _evaluate();
    try {
      await _schedSvc.setDone(uid, n, r.key, done: true, hm: hm);
      externalChange.value++;
      return true;
    } catch (e) {
      debugPrint('RoutineReminders.markDone failed: $e');
      _done = {..._done}..remove(r.key);
      _popped.remove(r.key);
      _evaluate();
      return false;
    }
  }

  /// The Routines screen changed a tick itself; take its word without a reload.
  void syncDone(String key, bool done) {
    _done = done ? {..._done, key} : ({..._done}..remove(key));
    _evaluate();
  }
}
