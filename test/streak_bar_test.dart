import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/widgets/momentum/streak_bar.dart';

/// Real HTTP so google_fonts can load (see ship_warning_test.dart).
class _RealHttp extends HttpOverrides {}

Future<void> pumpReal(WidgetTester t, Widget w) =>
    HttpOverrides.runWithHttpOverrides(() async {
      await t.pumpWidget(w);
      await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));
      await t.pump(const Duration(milliseconds: 100));
    }, _RealHttp());

void main() {
  const ms = [3, 7, 14, 30, 60, 90, 180, 365];

  group('StreakMilestoneProgress', () {
    test('before the first milestone', () {
      final p = StreakMilestoneProgress.of(0, ms);
      expect(p.previous, 0);
      expect(p.next, 3);
      expect(p.daysToNext, 3);
      expect(p.fraction, 0);
      expect(p.countdown, '3 days to 3-day reward');
    });

    test('mid-segment', () {
      final p = StreakMilestoneProgress.of(10, ms);
      expect(p.previous, 7);
      expect(p.next, 14);
      expect(p.daysToNext, 4);
      expect(p.fraction, closeTo(3 / 7, 1e-9));
    });

    test('landing exactly on a milestone targets the next one', () {
      final p = StreakMilestoneProgress.of(7, ms);
      expect(p.previous, 7);
      expect(p.next, 14);
      expect(p.fraction, 0);
    });

    test('one day out reads singular', () {
      expect(StreakMilestoneProgress.of(13, ms).countdown,
          '1 day to 14-day reward');
    });

    test('past the last milestone', () {
      final p = StreakMilestoneProgress.of(400, ms);
      expect(p.next, isNull);
      expect(p.daysToNext, 0);
      expect(p.fraction, 1);
      expect(p.countdown, 'Every milestone reached');
    });

    test('unsorted / junk admin config is normalised', () {
      final p = StreakMilestoneProgress.of(5, [30, -1, 7, 0, 7, 3]);
      expect(p.previous, 3);
      expect(p.next, 7);
    });

    test('negative streak clamps to zero', () {
      expect(StreakMilestoneProgress.of(-2, ms).streak, 0);
    });
  });

  group('StreakBar', () {
    Widget host(Widget child) => MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: const Color(0xFF06070D),
            body: Center(child: SizedBox(width: 900, child: child)),
          ),
        );

    testWidgets('wide bar shows days + countdown + range, and taps',
        (t) async {
      var taps = 0;
      await pumpReal(
          t,
          host(StreakBar(
              streak: 10, milestones: ms, onTap: () => taps++)));
      expect(find.text('10 DAYS'), findsOneWidget);
      expect(find.text('4 days to 14-day reward'), findsOneWidget);
      expect(find.text('7 → 14 🎁'), findsOneWidget);
      await t.tap(find.byType(StreakBar));
      expect(taps, 1);
    });

    testWidgets('warning state surfaces the check-in nudge', (t) async {
      await pumpReal(
          t,
          host(const StreakBar(
              streak: 2, streakState: 'warning', milestones: ms)));
      expect(find.text('⚠ Check in today'), findsOneWidget);
    });

    testWidgets('compact phone block shows DAY n and days-to-next',
        (t) async {
      await pumpReal(
          t, host(const StreakBar(streak: 5, compact: true, milestones: ms)));
      expect(find.text('DAY 5'), findsOneWidget);
      expect(find.text('2D TO 7 🎁'), findsOneWidget);
    });
  });
}
