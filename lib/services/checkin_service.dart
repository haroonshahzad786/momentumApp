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

  Future<void> saveCheckin({
    required String uid,
    required Map<String, int> scores,
    Map<String, String> logs = const {},
    DateTime? date,
  }) async {
    final d = date ?? DateTime.now();
    await _col(uid).doc(dayId(d)).set({
      'date': dayId(d),
      'scores': scores,
      'logs': logs,
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

/// One day's check-in: per-Core 1–5 scores keyed by SHORT core id.
class DailyCheckin {
  const DailyCheckin({required this.date, required this.scores});
  final String date; // yyyy-MM-dd
  final Map<String, int> scores; // shortCoreId → 1..5

  factory DailyCheckin.fromDoc(String id, Map<String, dynamic> data) {
    final raw = data['scores'];
    final scores = <String, int>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        final n = v is num ? v.toInt() : int.tryParse('$v');
        if (n != null) scores['$k'] = n;
      });
    }
    return DailyCheckin(
      date: (data['date'] ?? id).toString(),
      scores: scores,
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
/// days — the trigger for the red ⚠️ badge + iCore Alert.
bool isCoreOutOfBalance(List<int> scores) => coreLowStreak(scores) >= 5;
