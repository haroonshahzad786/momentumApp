// Trophy Room & Habit Formation (#19, Gamification spec §8) — pure logic.
// Mirrors functions-flutter/formation.js so client and server agree.

import 'checkin_service.dart';

const int kFormationDays = 14;
const double kFormationPct = 0.8;
const List<int> kReviewMilestones = [30, 60, 90];
const double kSlipDrop = 1.0;
const int kFirstGoalMinDays = 7;
const int kFirstGoalMaxDays = 21;
const int kFirstGoalDefaultDays = 14;

/// Spec §8 Dynamic Progression Scaling: 1/14 → 2/30 → 3/45 → 4/60.
const List<(int, int)> kGoalLadder = [(1, 14), (2, 30), (3, 45), (4, 60)];

/// Formation progress of one Golden Habit from its Core's recent scores.
class FormationProgress {
  const FormationProgress({required this.days, required this.consistentDays});

  /// Scored days (of the last 30 check-ins) on the habit's Core.
  final int days;

  /// Of those, days scoring 3+.
  final int consistentDays;

  double get pct => days == 0 ? 0 : consistentDays / days;
  int get pctRounded => (pct * 100).round();

  /// 14+ days with 80%+ consistency — ready for (AI-validated) formation.
  bool get eligible => days >= kFormationDays && pct >= kFormationPct;

  /// Days still needed to reach the 14-day standard.
  int get daysToGo => (kFormationDays - days).clamp(0, kFormationDays);

  /// On course to form: consistency already at the 80% bar.
  bool get onTrack => pct >= kFormationPct;

  /// Could form within [daysLeft] days if consistency holds.
  bool closeWithin(int daysLeft) => onTrack && daysToGo <= daysLeft;
}

FormationProgress formationProgress(List<int> scores) => FormationProgress(
      days: scores.length,
      consistentDays: scores.where((s) => s >= 3).length,
    );

/// Ranks forming habits: eligible first, then on-track, then fewest days to go,
/// then higher consistency. Returns the index of the closest, or null.
int? closestToForming(List<FormationProgress> list) {
  if (list.isEmpty) return null;
  var best = 0;
  int rank(FormationProgress p) =>
      (p.eligible ? 2000 : 0) + (p.onTrack ? 1000 : 0) + (100 - p.daysToGo * 5) + p.pctRounded ~/ 10;
  for (var i = 1; i < list.length; i++) {
    if (rank(list[i]) > rank(list[best])) best = i;
  }
  return best;
}

/// The player's Habit Formation Goal (stored on the user doc).
class FormationGoal {
  const FormationGoal({required this.habits, required this.days, required this.start});

  final int habits;
  final int days;

  /// yyyy-MM-dd the goal window began.
  final String start;

  static FormationGoal? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final h = raw['habits'];
    final d = raw['days'];
    final s = (raw['start'] ?? '').toString();
    if (h is! num || d is! num || DateTime.tryParse(s) == null) return null;
    return FormationGoal(habits: h.toInt(), days: d.toInt(), start: s);
  }

  /// Days left in the window counting today (0 once it has ended).
  int daysLeft(DateTime today) {
    final end = DateTime.parse(start).add(Duration(days: days));
    final t = DateTime(today.year, today.month, today.day);
    return end.difference(t).inDays.clamp(0, days);
  }

  /// The rung after this one on the ladder (stays on the top rung).
  (int, int) get next {
    for (final g in kGoalLadder) {
      if (g.$1 > habits) return g;
    }
    return kGoalLadder.last;
  }
}

/// Where a goal stands today.
class GoalStatus {
  const GoalStatus({
    required this.formed,
    required this.target,
    required this.daysLeft,
    required this.atRisk,
  });

  final int formed;
  final int target;
  final int daysLeft;

  /// "Only N days left and no habits close to forming. Need help?"
  final bool atRisk;

  bool get achieved => formed >= target;
  bool get ended => daysLeft == 0 && !achieved;
  double get fraction => target == 0 ? 0 : (formed / target).clamp(0.0, 1.0);
}

/// [formedAt] = formedAt timestamps of currently formed habits;
/// [forming] = progress of the habits still forming.
GoalStatus goalStatus(FormationGoal goal, List<String> formedAt, List<FormationProgress> forming,
    DateTime today) {
  final formed = formedAt.where((f) => f.length >= 10 && f.substring(0, 10).compareTo(goal.start) >= 0).length;
  final left = goal.daysLeft(today);
  final needed = goal.habits - formed;
  final close = forming.where((p) => p.closeWithin(left)).length;
  return GoalStatus(
    formed: formed,
    target: goal.habits,
    daysLeft: left,
    atRisk: needed > 0 && left <= 4 && close < needed,
  );
}

/// The 30/60/90-day review now due for a habit formed on [formedAt], or null.
int? dueReview(String formedAt, DateTime today, Map<String, String> reviews) {
  final f = DateTime.tryParse(formedAt);
  if (f == null) return null;
  final age = DateTime(today.year, today.month, today.day)
      .difference(DateTime(f.year, f.month, f.day))
      .inDays;
  int? due;
  for (final m in kReviewMilestones) {
    if (age >= m && !reviews.containsKey('$m')) due = m;
  }
  return due;
}

/// Core average before formation minus after (positive = slipping), or null.
double? coreDrop(List<DailyCheckin> checkins, String core, String formedAt) {
  if (formedAt.length < 10) return null;
  final f = formedAt.substring(0, 10);
  final before = <int>[];
  final after = <int>[];
  for (final c in checkins) {
    final v = c.scores[core];
    if (v == null) continue;
    (c.date.compareTo(f) < 0 ? before : after).add(v);
  }
  if (before.isEmpty || after.isEmpty) return null;
  double avg(List<int> a) => a.reduce((x, y) => x + y) / a.length;
  return avg(before) - avg(after);
}
