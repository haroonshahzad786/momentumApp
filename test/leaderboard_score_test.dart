import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/services/leaderboard_score.dart';

typedef Row = ({String id, int score, int streak, int longest, int formed});

Row row(String id, {int score = 0, int streak = 0, int longest = 0, int formed = 0}) =>
    (id: id, score: score, streak: streak, longest: longest, formed: formed);

Map<String, double> scores(List<Row> rows) => {
      for (final s in compositeLeaderboardScores(
        rows,
        score: (r) => r.score,
        streak: (r) => r.streak,
        longestStreak: (r) => r.longest,
        formedHabits: (r) => r.formed,
      ))
        s.member.id: s.score,
    };

void main() {
  test('empty crew returns no scores', () {
    expect(scores([]), isEmpty);
  });

  test('top of every factor scores 75 (ship-upgrade 25% stubbed at 0)', () {
    final s = scores([
      row('a', score: 1000, streak: 10, longest: 20, formed: 3),
      row('b', score: 500, streak: 5, longest: 10, formed: 1),
    ]);
    expect(s['a'], closeTo(75, 1e-9));
  });

  test('momentum is weighted 60%, achievements 15%', () {
    final s = scores([
      row('momentum', score: 1000),
      row('achiever', streak: 10, longest: 10, formed: 5),
    ]);
    expect(s['momentum'], closeTo(60, 1e-9));
    expect(s['achiever'], closeTo(15, 1e-9));
  });

  test('achievements can reorder members with close momentum scores', () {
    final s = scores([
      row('a', score: 1000, streak: 0, longest: 0, formed: 0),
      row('b', score: 950, streak: 30, longest: 30, formed: 4),
    ]);
    expect(s['b']!, greaterThan(s['a']!));
  });

  test('everyone at zero does not divide by zero', () {
    final s = scores([row('a'), row('b')]);
    expect(s.values, everyElement(0.0));
  });
}
