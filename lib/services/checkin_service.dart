import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Persists and reads the Daily Check-In's per-Core scores, written directly to
/// Firestore from Flutter (same pattern the Cantina messaging uses — no backend
/// endpoint, stays in the Flutter side of the system).
///
/// Stored at `/users/{uid}/checkins/{yyyy-MM-dd}` (one doc per day; re-running
/// the check-in the same day merges). Core keys are the SHORT ids the check-in
/// uses: 'mindset' · 'career' · 'relationships' · 'physical' · 'emotional'.
///
/// This is the real source the Routines screen derives habit lifecycle stage
/// from (Gamification Spec §8 — formation is measured on the habit's Core score).
class CheckinService {
  CheckinService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('checkins');

  /// `yyyy-MM-dd` doc id for [d] (local date — one check-in per calendar day).
  static String dayId(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// [captainsLog] is the per-Core Captain's Log (🏆 wins / 📚 lessons,
  /// PRD 12.C). Empty entries aren't stored. `logs` keeps the older one-string
  /// shape (wins + lessons joined) for readers that predate the split — the
  /// admin Client Detail endpoint returns it.
  Future<void> saveCheckin({
    required String uid,
    required Map<String, int> scores,
    Map<String, CaptainsLogEntry> captainsLog = const {},
    DateTime? date,
  }) async {
    final d = date ?? DateTime.now();
    final entries = {
      for (final e in captainsLog.entries)
        if (!e.value.isEmpty) e.key: e.value,
    };
    await _col(uid).doc(dayId(d)).set({
      'date': dayId(d),
      'scores': scores,
      'captainsLog': {for (final e in entries.entries) e.key: e.value.toMap()},
      'logs': {for (final e in entries.entries) e.key: e.value.asText},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Recent daily check-ins, most-recent first, capped at [limit] days.
  Future<List<DailyCheckin>> getRecent(String uid, {int limit = 30}) async {
    final snap = await _col(uid)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => DailyCheckin.fromDoc(d.id, d.data()))
        .toList();
  }
}

/// One Core's Captain's Log entry for a day: what went well, what didn't.
class CaptainsLogEntry {
  const CaptainsLogEntry({this.wins = '', this.lessons = ''});

  final String wins;
  final String lessons;

  bool get isEmpty => wins.trim().isEmpty && lessons.trim().isEmpty;

  Map<String, String> toMap() => {
        if (wins.trim().isNotEmpty) 'wins': wins.trim(),
        if (lessons.trim().isNotEmpty) 'lessons': lessons.trim(),
      };

  /// One-string form for older readers.
  String get asText => [
        if (wins.trim().isNotEmpty) 'Wins: ${wins.trim()}',
        if (lessons.trim().isNotEmpty) 'Lessons: ${lessons.trim()}',
      ].join(' · ');

  /// From a stored `captainsLog.{core}` map, or an older single-box `logs`
  /// string (kept as a win — it was an open "what's the data?" note).
  static CaptainsLogEntry from(Object? v) {
    if (v is Map) {
      return CaptainsLogEntry(
          wins: '${v['wins'] ?? ''}', lessons: '${v['lessons'] ?? ''}');
    }
    if (v is String) return CaptainsLogEntry(wins: v);
    return const CaptainsLogEntry();
  }
}

/// One day's check-in: per-Core 1–5 scores keyed by SHORT core id.
class DailyCheckin {
  const DailyCheckin(
      {required this.date, required this.scores, this.captainsLog = const {}});
  final String date; // yyyy-MM-dd
  final Map<String, int> scores; // shortCoreId → 1..5

  /// shortCoreId → that day's Captain's Log (non-empty entries only).
  final Map<String, CaptainsLogEntry> captainsLog;

  factory DailyCheckin.fromDoc(String id, Map<String, dynamic> data) {
    final raw = data['scores'];
    final scores = <String, int>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        final n = v is num ? v.toInt() : int.tryParse('$v');
        if (n != null) scores['$k'] = n;
      });
    }
    final log = <String, CaptainsLogEntry>{};
    final legacy = data['logs'];
    if (legacy is Map) {
      legacy.forEach((k, v) {
        final e = CaptainsLogEntry.from(v);
        if (!e.isEmpty) log['$k'] = e;
      });
    }
    final structured = data['captainsLog'];
    if (structured is Map) {
      structured.forEach((k, v) {
        final e = CaptainsLogEntry.from(v);
        if (!e.isEmpty) log['$k'] = e;
      });
    }
    return DailyCheckin(
      date: (data['date'] ?? id).toString(),
      scores: scores,
      captainsLog: log,
    );
  }
}

/// Maps a habit's Core daily-score history → routine lifecycle stage, per the
/// Gamification Mechanics Spec §8 ("Full Routines List color transformation").
///
/// [scores] is one Core's daily scores, **most-recent first**, one entry per
/// check-in day that scored this Core (1–5). Returns `'bad' | 'forming' |
/// 'formed'`, or `null` when there's no data yet (→ neutral, no fabrication).
///
///   🟢 Formed  — ≥14 days of history AND ≥80% scored ≥3 on the Core.
///   🔴 Bad     — Core under 3 for ≥5 consecutive most-recent days (the spec's
///                red "At-Risk" threshold; recent struggle takes display priority).
///   🟠 Forming — the default "Active Golden Habit, in progress" state.
String? deriveRoutineStage(List<int> scores) {
  if (scores.isEmpty) return null;

  // 🔴 Recent struggle dominates the color so the player can act on it.
  var leadingMisses = 0;
  for (final s in scores) {
    if (s < 3) {
      leadingMisses++;
    } else {
      break;
    }
  }
  if (leadingMisses >= 5) return 'bad';

  // 🟢 Formed: sustained 80%+ consistency over a 2-week-plus window.
  if (scores.length >= 14) {
    final consistent = scores.where((s) => s >= 3).length;
    if (consistent / scores.length >= 0.80) return 'formed';
  }

  // 🟠 Default working state.
  return 'forming';
}

/// Core Balance 5-Day Alert (PHASE 1 & 2 DETAILS §"When a Core Is Out of
/// Balance"): how many consecutive most-recent check-ins a Core scored BELOW
/// 3.0. [scores] is that Core's daily scores, most-recent-first.
int coreLowStreak(List<int> scores) {
  var n = 0;
  for (final s in scores) {
    if (s < 3) {
      n++;
    } else {
      break;
    }
  }
  return n;
}

/// A Core is "out of balance" once it's scored below 3.0 for 5+ consecutive
/// days — the trigger for the red ⚠️ badge + iCore Alert — and stays so until
/// it scores above 3.0 on 2 consecutive days (Gamification spec §10, #18).
bool isCoreOutOfBalance(List<int> scores) => coreAlertInfo(scores).active;

/// Core Balance alert state for one Core (#18, Gamification spec §10).
class CoreAlertInfo {
  const CoreAlertInfo({
    required this.active,
    this.lowRunScores = const [],
    this.recoveryDays = 0,
  });

  final bool active;

  /// Scores of the below-3.0 run that raised the alert, most-recent-first.
  final List<int> lowRunScores;

  /// Consecutive above-3.0 days since that run (the alert clears at 2).
  final int recoveryDays;

  int get lowRunDays => lowRunScores.length;
}

/// Replays a Core's daily scores (most-recent-first, as stored) oldest → newest:
///  * 5+ consecutive days below 3.0 raises the alert;
///  * it clears only after 2 consecutive days ABOVE 3.0 — a 3 is neither low
///    nor recovering, so it resets both counts;
///  * a new low day while the alert is up keeps it up.
CoreAlertInfo coreAlertInfo(List<int> scoresRecentFirst) {
  var active = false;
  var run = <int>[]; // current low run, oldest-first
  var alertRun = <int>[];
  var high = 0;
  for (final s in scoresRecentFirst.reversed) {
    if (s < 3) {
      run.add(s);
      high = 0;
      if (run.length >= 5) {
        active = true;
        alertRun = List.of(run);
      } else if (active) {
        // Still struggling inside an open alert: the newest low run is the
        // context worth showing once it's the longer story.
        if (run.length >= alertRun.length) alertRun = List.of(run);
      }
    } else {
      run = <int>[];
      if (s > 3) {
        high++;
        if (active && high >= 2) {
          active = false;
          alertRun = <int>[];
        }
      } else {
        high = 0;
      }
    }
  }
  return CoreAlertInfo(
    active: active,
    lowRunScores: active ? alertRun.reversed.toList() : const [],
    recoveryDays: active ? high : 0,
  );
}

/// Rolling per-Core averages over the most recent [days] check-in days
/// (Balance Meter: "last 7 weekday check-ins, weekends excluded unless the
/// player checked in" — i.e. the last 7 days that have a check-in).
/// [recent] may be in any order; Cores are averaged over the days they were
/// scored.
Map<String, double> rollingCoreAverages(List<DailyCheckin> recent,
    {int days = 7}) {
  final byDate = <String, Map<String, int>>{};
  for (final d in recent) {
    if (d.scores.isNotEmpty) byDate[d.date] = {...?byDate[d.date], ...d.scores};
  }
  final window = (byDate.keys.toList()..sort((a, b) => b.compareTo(a))).take(days);
  final sums = <String, int>{};
  final counts = <String, int>{};
  for (final dt in window) {
    byDate[dt]!.forEach((core, sc) {
      sums[core] = (sums[core] ?? 0) + sc;
      counts[core] = (counts[core] ?? 0) + 1;
    });
  }
  return {for (final c in sums.keys) c: sums[c]! / counts[c]!};
}

/// Balance % (PRD §14 "Balance Percentage"; Build Tracker C.10 — simple
/// variance-based for MVP): 100% when every scored Core has the same 7-day
/// average, falling as they spread apart. On the 1–5 scale the widest possible
/// spread is a standard deviation of 2, which maps to 0%.
/// Null until at least one Core has data.
int? balancePercent(Map<String, double> averages) {
  final v = averages.values.toList();
  if (v.isEmpty) return null;
  final mean = v.reduce((a, b) => a + b) / v.length;
  final variance =
      v.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / v.length;
  final sd = math.sqrt(variance);
  return (100 * (1 - sd / 2)).clamp(0, 100).round();
}
