import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/services/checkin_service.dart';
import 'package:untitled2/services/formation.dart';
import 'package:untitled2/widgets/momentum/formation_room.dart';

/// Real HTTP so google_fonts can load (see ship_warning_test.dart).
class _RealHttp extends HttpOverrides {}

Finder ci(String s) => find.textContaining(RegExp(RegExp.escape(s), caseSensitive: false));

void main() {
  test('formation progress: 14 days at 80%+', () {
    expect(formationProgress(List.filled(13, 4)).eligible, isFalse);
    expect(formationProgress(List.filled(14, 4)).eligible, isTrue);
    final p = formationProgress([...List.filled(8, 4), 2, 2]);
    expect(p.pctRounded, 80);
    expect(p.daysToGo, 4);
    expect(p.closeWithin(4), isTrue);
    expect(p.closeWithin(3), isFalse);
  });

  test('closest habit prefers eligible, then on-track and fewest days to go', () {
    final a = formationProgress([4, 4, 4]); // on track, 11 to go
    final b = formationProgress(List.filled(10, 4)); // on track, 4 to go
    final c = formationProgress(List.filled(12, 2)); // off track
    expect(closestToForming([a, b, c]), 1);
    expect(closestToForming([a, c, formationProgress(List.filled(14, 5))]), 2);
    expect(closestToForming([]), isNull);
  });

  test('goal status: progress, days left, at-risk, crushed', () {
    const g = FormationGoal(habits: 1, days: 14, start: '2026-09-10');
    final forming = [formationProgress([4, 4])]; // 12 days to go
    var s = goalStatus(g, const [], forming, DateTime(2026, 9, 21));
    expect(s.daysLeft, 3);
    expect(s.atRisk, isTrue);
    s = goalStatus(g, const [], [formationProgress(List.filled(12, 4))], DateTime(2026, 9, 21));
    expect(s.atRisk, isFalse); // 2 to go ≤ 3 left
    s = goalStatus(g, const ['2026-09-15T10:00:00Z', '2026-09-01T00:00:00Z'], forming, DateTime(2026, 9, 16));
    expect(s.formed, 1); // the earlier formation doesn't count
    expect(s.achieved, isTrue);
    expect(goalStatus(g, const [], forming, DateTime(2026, 9, 30)).ended, isTrue);
    expect(g.next, (2, 30));
    expect(const FormationGoal(habits: 4, days: 60, start: '2026-01-01').next, (4, 60));
  });

  test('reviews at 30/60/90 and the 1.0-point slip', () {
    expect(dueReview('2026-08-01T00:00:00Z', DateTime(2026, 8, 30), const {}), isNull);
    expect(dueReview('2026-08-01T00:00:00Z', DateTime(2026, 8, 31), const {}), 30);
    expect(dueReview('2026-08-01T00:00:00Z', DateTime(2026, 8, 31), const {'30': '2026-08-31'}), isNull);
    expect(dueReview('2026-06-01T00:00:00Z', DateTime(2026, 9, 26), const {'30': 'x'}), 90);
    final drop = coreDrop(const [
      DailyCheckin(date: '2026-08-01', scores: {'physical': 5}),
      DailyCheckin(date: '2026-09-01', scores: {'physical': 3}),
    ], 'physical', '2026-08-15T00:00:00Z');
    expect(drop, 2.0);
  });

  testWidgets('formation celebration: name, identity line, credits, goal', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 900));
    await HttpOverrides.runWithHttpOverrides(() async {
      await tester.pumpWidget(const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF06070D),
          body: FormationCelebration(
            habitName: 'Walk 20 min after dinner',
            creditsEarned: 25,
            note: 'Your log backs this up — nice work.',
            goalCrushed: true,
          ),
        ),
      ));
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));
      await tester.pump(const Duration(seconds: 4)); // let the confetti finish
    }, _RealHttp());
    expect(ci('This is now automatic and part of who you ARE!'), findsOneWidget);
    expect(ci('Walk 20 min after dinner'), findsOneWidget);
    expect(ci('+25 Space Credits'), findsOneWidget);
    expect(ci('formation goal crushed'), findsOneWidget);
    await expectLater(find.byType(FormationCelebration), matchesGoldenFile('goldens/formation_celebration.png'));
  });
}
