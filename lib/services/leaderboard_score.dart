import 'dart:math' as math;

/// Multi-factor anti-shame leaderboard composite (Cantina spec, Pillar 3):
/// **60% momentum score + 25% ship upgrades + 15% achievements** (formed
/// habits + current streak + longest streak ever). Each input is min-max
/// normalized against this crew (0–100) so no bucket dominates just by having
/// bigger raw units (momentum scores run into the thousands; streaks are
/// single/double digits).
///
/// Ship upgrades (13d) aren't built — every [PLACEHOLDER] tier cost is still
/// undesigned — so that slice is a stubbed **0 for every member**. That's a
/// deliberate "don't invent the numbers" choice, not a bug: adding the same
/// constant (0) to every composite can never change the relative ordering,
/// so ranking is correct today and will pick up its real 25% weight the
/// moment 13d ships real tiers.
///
/// Generic over the member type because the mobile (`_CrewMember`) and web
/// (`_WebCrew`) screens keep separate row types.
List<({T member, double score})> compositeLeaderboardScores<T>(
  List<T> members, {
  required num Function(T) score,
  required num Function(T) streak,
  required num Function(T) longestStreak,
  required num Function(T) formedHabits,
}) {
  if (members.isEmpty) return const [];

  double maxOf(num Function(T) f) {
    final v = members.map((m) => f(m).toDouble()).fold(0.0, math.max);
    return v <= 0 ? 1 : v; // avoid divide-by-zero when everyone is at 0
  }

  final maxScore = maxOf(score);
  final maxFormed = maxOf(formedHabits);
  final maxStreak = maxOf(streak);
  final maxLongest = maxOf(longestStreak);

  double achievements(T m) {
    final formedN = formedHabits(m) / maxFormed;
    final streakN = streak(m) / maxStreak;
    final longestN = longestStreak(m) / maxLongest;
    return (formedN + streakN + longestN) / 3 * 100;
  }

  return [
    for (final m in members)
      (
        member: m,
        score: 0.60 * (score(m) / maxScore * 100) +
            0.25 * 0.0 /* ship upgrades — stubbed, see doc comment */ +
            0.15 * achievements(m),
      ),
  ];
}
