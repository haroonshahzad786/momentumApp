import 'package:cloud_firestore/cloud_firestore.dart';

import 'all_habits.dart' show itemKey, parseHabitLine;
import 'checkin_service.dart' show CheckinService;

// Routines Timeline data layer. Written directly to Firestore from Flutter (same
// pattern as CheckinService — `users/{uid}/**` is owner-writable, no backend):
//   • users/{uid}/habit_schedule/{habitKey}  → HabitSchedule (when a habit fires)
//   • users/{uid}/habit_log/{yyyy-MM-dd}     → HabitDayLog (done today / logs)
//   • users/{uid}/settings/routine_anchors   → the player's anchors + usual times
// Habits are keyed by Core + name ([habitKey]) because list lines and Golden
// Habits are two stores that already match on exactly that pair.

/// Stable key for one habit: short Core id + normalised name.
String habitKey(String core, String name) =>
    '${core}__${itemKey(parseHabitLine(name).name)}';

/// A daily moment routines stack onto ("After breakfast").
class Anchor {
  const Anchor(this.id, this.label, this.usualTime);
  final String id;
  final String label;

  /// HH:mm — where anchored habits sit on the timeline.
  final String usualTime;

  int get minutes => parseHm(usualTime) ?? 0;

  Map<String, dynamic> toMap() =>
      {'id': id, 'label': label, 'usualTime': usualTime};

  static Anchor? fromMap(Object? m) {
    if (m is! Map) return null;
    final id = '${m['id'] ?? ''}'.trim();
    final label = '${m['label'] ?? ''}'.trim();
    if (id.isEmpty || label.isEmpty) return null;
    return Anchor(id, label, '${m['usualTime'] ?? '12:00'}');
  }
}

const List<Anchor> kDefaultAnchors = [
  Anchor('wake_up', 'Wake up', '07:00'),
  Anchor('after_breakfast', 'After breakfast', '08:15'),
  Anchor('after_lunch', 'After lunch', '13:00'),
  Anchor('after_dinner', 'After dinner', '19:30'),
  Anchor('before_bed', 'Before bed', '22:30'),
];

/// "07:30" → minutes since midnight (null if not HH:mm).
int? parseHm(String? s) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch((s ?? '').trim());
  if (m == null) return null;
  final h = int.parse(m.group(1)!), mi = int.parse(m.group(2)!);
  if (h > 23 || mi > 59) return null;
  return h * 60 + mi;
}

String fmtHm(int minutes) {
  final m = minutes.clamp(0, 24 * 60 - 1);
  return '${(m ~/ 60).toString().padLeft(2, '0')}:'
      '${(m % 60).toString().padLeft(2, '0')}';
}

/// When a routine fires, or what triggers a non-routine. Stored per habit.
class HabitSchedule {
  const HabitSchedule({
    this.slotType = 'none',
    this.scheduledTime,
    this.endTime,
    this.anchorId,
    this.triggers = const [],
  });

  /// 'time' | 'anchor' | 'none'.
  final String slotType;
  final String? scheduledTime;
  final String? endTime;
  final String? anchorId;

  /// Non-routines: short strings like "Stress spikes".
  final List<String> triggers;

  Map<String, dynamic> toMap() => {
        'slotType': slotType,
        'scheduledTime': scheduledTime,
        'endTime': endTime,
        'anchorId': anchorId,
        'triggers': triggers,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory HabitSchedule.fromMap(Map<String, dynamic> m) => HabitSchedule(
        slotType: '${m['slotType'] ?? 'none'}',
        scheduledTime: m['scheduledTime'] as String?,
        endTime: m['endTime'] as String?,
        anchorId: m['anchorId'] as String?,
        triggers: [
          for (final t in (m['triggers'] as List? ?? const []))
            if ('$t'.trim().isNotEmpty) '$t'.trim(),
        ],
      );
}

/// Where a routine lands on the timeline.
class ResolvedSlot {
  const ResolvedSlot({required this.minutes, this.anchor, this.endTime});
  final int minutes;

  /// Null for a set time.
  final Anchor? anchor;
  final String? endTime;
  bool get isAnchored => anchor != null;
}

/// Resolves a routine's slot: saved schedule first; else migrate the legacy
/// time-of-day block / cue text onto an anchor (Morning → wake up, Afternoon →
/// after lunch, Evening → after dinner); null = unscheduled ("anytime").
ResolvedSlot? resolveSlot({
  required HabitSchedule? schedule,
  required List<Anchor> anchors,
  String? blockId,
  String? cue,
  String when = '',
}) {
  Anchor? byId(String? id) {
    for (final a in anchors) {
      if (a.id == id) return a;
    }
    return null;
  }

  if (schedule != null) {
    if (schedule.slotType == 'time') {
      final m = parseHm(schedule.scheduledTime);
      if (m != null) {
        return ResolvedSlot(minutes: m, endTime: schedule.endTime);
      }
    } else if (schedule.slotType == 'anchor') {
      final a = byId(schedule.anchorId);
      if (a != null) return ResolvedSlot(minutes: a.minutes, anchor: a);
    }
  }
  // Legacy: a clock time written in the free-text `when` ("7:30", "7am").
  final t = RegExp(r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b', caseSensitive: false)
      .firstMatch(when);
  if (t != null && (t.group(2) != null || t.group(3) != null)) {
    var h = int.parse(t.group(1)!);
    final ap = t.group(3)?.toLowerCase();
    if (ap == 'pm' && h < 12) h += 12;
    if (ap == 'am' && h == 12) h = 0;
    final mi = int.tryParse(t.group(2) ?? '0') ?? 0;
    if (h < 24 && mi < 60) return ResolvedSlot(minutes: h * 60 + mi);
  }
  // Word-boundary matches only: "out of bed" / "bedroom" must not mean bedtime.
  final text = '${cue ?? ''} $when'.toLowerCase();
  bool has(String re) => RegExp(re).hasMatch(text);
  String? id;
  if (has(r'breakfast')) {
    id = 'after_breakfast';
  } else if (has(r'lunch')) {
    id = 'after_lunch';
  } else if (has(r'dinner|supper')) {
    id = 'after_dinner';
  } else if (has(r'before (going to )?bed|bedtime')) {
    id = 'before_bed';
  } else if (has(r'wak(e|ing)')) {
    id = 'wake_up';
  }
  id ??= switch (blockId) {
    'morning' => 'wake_up',
    'workday' => 'after_lunch',
    'evening' => 'after_dinner',
    _ => null,
  };
  final a = byId(id);
  return a == null ? null : ResolvedSlot(minutes: a.minutes, anchor: a);
}

/// One day's completions: routines ticked (key → HH:mm) and non-routine logs
/// (key → HH:mm timestamps, oldest first).
class HabitDayLog {
  const HabitDayLog({this.done = const {}, this.logs = const {}});
  final Map<String, String> done;
  final Map<String, List<String>> logs;

  static HabitDayLog fromDoc(Map<String, dynamic>? d) {
    if (d == null) return const HabitDayLog();
    final done = <String, String>{};
    (d['done'] as Map? ?? const {}).forEach((k, v) => done['$k'] = '$v');
    final logs = <String, List<String>>{};
    (d['logs'] as Map? ?? const {}).forEach((k, v) {
      if (v is List) logs['$k'] = [for (final e in v) '$e'];
    });
    return HabitDayLog(done: done, logs: logs);
  }

  int get doneCount => done.length;
}

class RoutineScheduleService {
  RoutineScheduleService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection('users').doc(uid);

  Future<List<Anchor>> loadAnchors(String uid) async {
    try {
      final snap =
          await _user(uid).collection('settings').doc('routine_anchors').get();
      final list = [
        for (final a in (snap.data()?['anchors'] as List? ?? const []))
          if (Anchor.fromMap(a) != null) Anchor.fromMap(a)!,
      ];
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return kDefaultAnchors;
  }

  Future<void> saveAnchors(String uid, List<Anchor> anchors) => _user(uid)
      .collection('settings')
      .doc('routine_anchors')
      .set({'anchors': [for (final a in anchors) a.toMap()]});

  Future<Map<String, HabitSchedule>> loadSchedules(String uid) async {
    try {
      final snap = await _user(uid).collection('habit_schedule').get();
      return {
        for (final d in snap.docs) d.id: HabitSchedule.fromMap(d.data()),
      };
    } catch (_) {
      return const {};
    }
  }

  Future<void> saveSchedule(String uid, String key, HabitSchedule s) =>
      _user(uid).collection('habit_schedule').doc(key).set(s.toMap());

  Future<HabitDayLog> loadLog(String uid, DateTime day) async {
    try {
      final snap = await _user(uid)
          .collection('habit_log')
          .doc(CheckinService.dayId(day))
          .get();
      return HabitDayLog.fromDoc(snap.data());
    } catch (_) {
      return const HabitDayLog();
    }
  }

  /// Logs for each of [days] (same order), for the week strip.
  Future<List<HabitDayLog>> loadLogs(String uid, List<DateTime> days) =>
      Future.wait([for (final d in days) loadLog(uid, d)]);

  /// Ticks (or un-ticks) a routine for [day]; [hm] is the completion time.
  Future<void> setDone(
    String uid,
    DateTime day,
    String key, {
    required bool done,
    required String hm,
  }) {
    return _user(uid)
        .collection('habit_log')
        .doc(CheckinService.dayId(day))
        .set({
      'date': CheckinService.dayId(day),
      'done': {key: done ? hm : FieldValue.delete()},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Appends a timestamp to a non-routine's log for [day].
  Future<void> logNonRoutine(
    String uid,
    DateTime day,
    String key, {
    required String hm,
  }) {
    return _user(uid)
        .collection('habit_log')
        .doc(CheckinService.dayId(day))
        .set({
      'date': CheckinService.dayId(day),
      'logs': {
        key: FieldValue.arrayUnion([hm]),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
