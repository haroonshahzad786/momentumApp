import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/models/user_profile.dart';
import 'package:untitled2/widgets/momentum/streak_protection.dart';

/// Real HTTP so google_fonts can load (see ship_warning_test.dart).
class _RealHttp extends HttpOverrides {}

Future<void> pumpReal(WidgetTester t, Widget w) =>
    HttpOverrides.runWithHttpOverrides(() async {
      await t.pumpWidget(w);
      await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));
      await t.pumpAndSettle();
    }, _RealHttp());

Finder ci(String s) => find.textContaining(RegExp(RegExp.escape(s), caseSensitive: false));

void main() {
  Widget host(Widget child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF06070D),
          body: Center(child: SizedBox(width: 380, child: child)),
        ),
      );

  StreakProtectionCard card({
    int savers = 0,
    VacationRange? active,
    VacationRange? upcoming,
    Future<void> Function(DateTime, int)? onStart,
    Future<void> Function()? onEnd,
  }) =>
      StreakProtectionCard(
        streakSavers: savers,
        maxStreakSavers: 1,
        streakSaverMilestone: 30,
        vacationMaxDays: 7,
        activeVacation: active,
        upcomingVacation: upcoming,
        onStartVacation: onStart ?? (_, __) async {},
        onEndVacation: onEnd ?? () async {},
      );

  test('profile parses #17 fields', () {
    final p = UserProfile.fromJson({
      'streakSavers': 1,
      'vacationMaxDays': 5,
      'activeVacation': {'start': '2026-09-28', 'end': '2026-10-02'},
      'upcomingVacation': {'start': 'bad', 'end': '2026-10-02'},
      'missState': 'vacation',
    });
    expect(p.streakSavers, 1);
    expect(p.vacationMaxDays, 5);
    expect(p.activeVacation!.days, 5);
    expect(p.upcomingVacation, isNull);
    expect(p.onVacation, isTrue);
    expect(p.needsRelaunch, isFalse);
  });

  testWidgets('no vacation: saver hint + plan dialog returns start/days', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 900));
    DateTime? gotStart;
    int? gotDays;
    await pumpReal(tester, host(card(onStart: (d, n) async {
      gotStart = d;
      gotDays = n;
    })));
    expect(ci('Earn a Streak Saver at a 30-day streak'), findsOneWidget);
    expect(ci('0/1'), findsOneWidget);
    await expectLater(find.byType(StreakProtectionCard), matchesGoldenFile('goldens/streak_protection.png'));
    await tester.tap(ci('Plan Vacation Mode'));
    await tester.pumpAndSettle();
    expect(find.byType(VacationModeDialog), findsOneWidget);
    await tester.tap(ci('Tomorrow'));
    await tester.pumpAndSettle();
    await tester.tap(ci('Start Vacation Mode'));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    expect(gotStart, DateTime(now.year, now.month, now.day + 1));
    expect(gotDays, 7);
  });

  testWidgets('active vacation shows end button; errors surface', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 900));
    await pumpReal(tester, host(card(
      savers: 1,
      active: const VacationRange('2026-09-28', '2026-10-02'),
      onEnd: () async => throw Exception('nope'),
    )));
    expect(ci('Streak Saver available'), findsOneWidget);
    expect(ci('Vacation Mode on until Fri 2 Oct'), findsOneWidget);
    await tester.tap(ci("I'm back"));
    await tester.pumpAndSettle();
    expect(ci('nope'), findsOneWidget);
  });

  testWidgets('upcoming vacation can be cancelled', (tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 900));
    var ended = 0;
    await pumpReal(tester, host(card(
      upcoming: const VacationRange('2026-10-05', '2026-10-07'),
      onEnd: () async => ended++,
    )));
    expect(ci('planned Mon 5 Oct – Wed 7 Oct'), findsOneWidget);
    await tester.tap(ci('Cancel vacation'));
    await tester.pumpAndSettle();
    expect(ended, 1);
  });
}
