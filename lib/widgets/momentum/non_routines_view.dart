import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/all_habits.dart';
import '../../services/checkin_service.dart';
import '../../services/core_lists_service.dart';
import '../../services/habits_service.dart';
import '../../services/offline.dart';
import '../../theme/momentum_tokens.dart';
import 'habit_color.dart';
import 'mm_buttons.dart';
import 'offline_banner.dart';

const Map<String, String> _coreIcon = {
  'mindset': '🧠',
  'career': '💰',
  'relationships': '👥',
  'physical': '💪',
  'emotional': '🧘',
};

const Map<String, String> _coreTitle = {
  'mindset': 'Mindset',
  'career': 'Career & Finances',
  'relationships': 'Relationships',
  'physical': 'Physical Health',
  'emotional': 'Emotional & Mental',
};

/// Non-Routines List (Phase 1&2 Details §4C, #21) — the rocket's right (checklist) icon.
/// Emotion-triggered habits per Core, in the player's priority order (drag to
/// reprioritise), with each habit's IF-THEN. Mindset keeps #1 Mantra and
/// #2 Gratitude locked on top; formed Golden Habits have left for the Trophy
/// Room.
class NonRoutinesView extends StatefulWidget {
  const NonRoutinesView({super.key, required this.onNav, this.wide = false});

  final void Function(String key) onNav;
  final bool wide;

  @override
  State<NonRoutinesView> createState() => _NonRoutinesViewState();
}

class _NonRoutinesViewState extends State<NonRoutinesView> {
  final _habits = HabitsService();
  final _lists = CoreListsService();
  final _checkins = CheckinService();

  Map<String, List<AllHabit>> _byCore = const {};
  int _graduated = 0;
  bool _loading = true;
  bool _offline = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _habits.dispose();
    _lists.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _load() async {
    if (_uid.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Not signed in';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final goldenF = _habits.getGoldenHabits(_uid);
      final listsF = _lists.getRoutineData(_uid);
      // Neither failing blanks the list: no check-ins → no Day X/14; no saved
      // order → default priority.
      final checkinsF = _checkins
          .getRecent(_uid, limit: 30)
          .catchError((_) => const <DailyCheckin>[]);
      final orderF = _lists
          .nonRoutineOrder(_uid)
          .catchError((_) => const <String, List<String>>{});
      final golden = await goldenF;
      final lists = await listsF;
      final all = mergeAllHabits(
        golden: golden.data,
        routineLists: lists.data.routine,
        nonRoutineLists: lists.data.nonRoutine,
        coreScores: coreScoreSeries(await checkinsF),
      );
      final nr = nonRoutineList(all, await orderF);
      if (!mounted) return;
      setState(() {
        _byCore = nr.byCore;
        _graduated = nr.graduated;
        _offline = golden.fromCache || lists.fromCache;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _reorder(String core, int from, int to) async {
    final before = _byCore[core]!;
    final next = [...before];
    if (to > from) to -= 1; // ReorderableListView's index is pre-removal
    next.insert(to, next.removeAt(from));
    setState(() => _byCore = {..._byCore, core: next});
    try {
      await _lists.nonRoutineOrder(_uid,
          core: core, order: [for (final h in next) h.key]);
    } catch (_) {
      if (!mounted) return;
      setState(() => _byCore = {..._byCore, core: before});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Couldn't save the new order — try again.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: CircularProgressIndicator(color: MM.yellow)),
      );
    }
    final err = _error;
    if (err != null) {
      if (isNetworkError(err)) {
        return OfflineErrorView(onRetry: _load, what: 'your non-routines');
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(children: [
          Text('Could not load your non-routines',
              style: MM.display(size: 14, color: Colors.white)),
          const SizedBox(height: 12),
          MMGhostButton(label: 'Retry', onPressed: _load),
        ]),
      );
    }

    final panels = [
      for (final e in _byCore.entries) _section(e.key, e.value),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_offline) ...[
          OfflineBanner(onRefresh: _load),
          const SizedBox(height: 10),
        ],
        _header(),
        const SizedBox(height: 16),
        _layout(panels),
        if (_graduated > 0) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: MMGhostButton(
              label: '🏆 $_graduated formed → Trophy Room',
              onPressed: () => widget.onNav('trophy'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _header() => Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 10,
        spacing: 12,
        children: [
          // BTTF link at the top — came only from the retired PRD; unconfirmed.
          MMGhostButton(
            label: '🔮 Back to the Future',
            onPressed: () => widget.onNav('lists'),
          ),
          HabitStatusCounter([
            for (final list in _byCore.values)
              for (final h in list) h.color,
          ]),
        ],
      );

  Widget _layout(List<Widget> panels) {
    if (!widget.wide || panels.length < 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final p in panels) ...[p, const SizedBox(height: 14)]],
      );
    }
    Widget col(int start) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = start; i < panels.length; i += 2) ...[
                panels[i],
                const SizedBox(height: 14),
              ],
            ],
          ),
        );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [col(0), const SizedBox(width: 14), col(1)],
    );
  }

  Widget _section(String core, List<AllHabit> habits) {
    final accent = MM.coreColor[core] ?? MM.yellow;
    final locked = core == 'mindset';
    final firstRank = locked ? 3 : 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111C4E).withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Text(_coreIcon[core] ?? '•', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text((_coreTitle[core] ?? core).toUpperCase(),
                style: GoogleFonts.orbitron(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: accent)),
            const Spacer(),
            Text('${habits.length}',
                style: MM.body(size: 11, color: Colors.white.withOpacity(0.5))),
          ]),
          const SizedBox(height: 8),
          if (locked) ...[
            _lockedRow(1, 'Mantra', 'Your personal affirmation'),
            _lockedRow(2, 'Gratitude', 'What you are grateful for'),
          ],
          if (habits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                  'No non-routine habits here yet. Forge one with Nova, or tag '
                  'emotion-triggered habits in Routines.',
                  style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.5))),
            )
          else
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorder: (from, to) => _reorder(core, from, to),
              children: [
                for (var i = 0; i < habits.length; i++)
                  _row(habits[i], firstRank + i, i,
                      key: ValueKey('$core/${habits[i].key}')),
              ],
            ),
        ],
      ),
    );
  }

  /// Mindset locked defaults: #1 Mantra and #2 Gratitude are reserved as
  /// linked rows that open Momentum Lists. Came only from the retired PRD —
  /// unconfirmed.
  Widget _lockedRow(int rank, String title, String sub) => Semantics(
        button: true,
        label: '#$rank $title, locked. Opens Momentum Lists',
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => widget.onNav('lists'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              SizedBox(
                width: 30,
                child: Text('#$rank',
                    style: MM.body(size: 12, color: Colors.white.withOpacity(0.5))),
              ),
              const Text('🔗', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: MM.body(
                            size: 13, color: Colors.white, weight: FontWeight.w600)),
                    Text(sub,
                        style: MM.body(
                            size: 11, color: Colors.white.withOpacity(0.5))),
                  ],
                ),
              ),
              Icon(Icons.lock_outline,
                  size: 15, color: Colors.white.withOpacity(0.4)),
            ]),
          ),
        ),
      );

  Widget _row(AllHabit h, int rank, int index, {required Key key}) {
    final p = h.progress;
    final status = p != null
        ? 'Day ${p.days.clamp(0, 14)}/14 · ${h.color!.label}'
        : (h.color?.label ?? 'Not tagged');
    final hasIfThen = h.ifText.isNotEmpty || h.thenText.isNotEmpty;
    return Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => widget.onNav(h.isGolden ? 'habit:${h.habitId}' : 'routines'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Tooltip(
                  message: 'Drag to reprioritise',
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4, top: 1),
                      child: Icon(Icons.drag_indicator,
                          size: 18, color: Colors.white.withOpacity(0.35)),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 26,
                child: Text('#$rank',
                    style: MM.body(size: 12, color: Colors.white.withOpacity(0.5))),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5, right: 9),
                child: HabitColorDot(h.color),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: h.name),
                        if (h.flagged) const TextSpan(text: '  ⚠️'),
                        if (h.experiment) const TextSpan(text: '  🧪'),
                      ]),
                      style: MM.body(
                          size: 13, color: Colors.white, weight: FontWeight.w600),
                    ),
                    if (hasIfThen) ...[
                      const SizedBox(height: 3),
                      Text.rich(
                        TextSpan(children: [
                          if (h.ifText.isNotEmpty) ...[
                            const TextSpan(
                                text: 'IF ',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: h.ifText),
                          ],
                          if (h.thenText.isNotEmpty) ...[
                            TextSpan(
                                text: h.ifText.isNotEmpty ? ', THEN ' : 'THEN ',
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            TextSpan(text: h.thenText),
                          ],
                        ]),
                        style: MM.body(
                            size: 11.5, color: Colors.white.withOpacity(0.75)),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(status,
                        style: MM.body(
                            size: 11, color: Colors.white.withOpacity(0.5))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
