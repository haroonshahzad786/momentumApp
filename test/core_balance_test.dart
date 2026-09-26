import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/services/checkin_service.dart';
import 'package:untitled2/theme/momentum_tokens.dart';
import 'package:untitled2/widgets/momentum/core_alert_sheet.dart';

/// Real HTTP so google_fonts can load (see ship_warning_test.dart).
class _RealHttp extends HttpOverrides {}

Future<void> pumpReal(WidgetTester t, Widget w) =>
    HttpOverrides.runWithHttpOverrides(() async {
      await t.pumpWidget(w);
      await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));
      await t.pumpAndSettle();
    }, _RealHttp());

Finder ci(String s) => find.textContaining(RegExp(RegExp.escape(s), caseSensitive: false));

/// Scores are written oldest → newest here for readability; the app stores
/// them most-recent-first.
CoreAlertInfo alert(List<int> oldestFirst) =>
    coreAlertInfo(oldestFirst.reversed.toList());

void main() {
  group('Core Balance alert (spec §10)', () {
    test('5 consecutive days below 3.0 raises it; 4 does not', () {
      expect(alert([4, 2, 2, 2, 2]).active, isFalse);
      final a = alert([4, 2, 1, 2, 2, 2]);
      expect(a.active, isTrue);
      expect(a.lowRunScores, [2, 2, 2, 1, 2]); // most-recent-first
      expect(a.lowRunDays, 5);
    });

    test('persists until 2 consecutive days above 3.0', () {
      expect(alert([2, 2, 2, 2, 2, 4]).active, isTrue);
      expect(alert([2, 2, 2, 2, 2, 4]).recoveryDays, 1);
      expect(alert([2, 2, 2, 2, 2, 4, 5]).active, isFalse);
      // A 3 is not "above 3.0": resets the recovery count.
      expect(alert([2, 2, 2, 2, 2, 4, 3, 4]).active, isTrue);
      // A low day in between also resets it.
      expect(alert([2, 2, 2, 2, 2, 4, 2, 4]).active, isTrue);
      expect(alert([2, 2, 2, 2, 2, 4, 2, 4, 4]).active, isFalse);
    });

    test('isCoreOutOfBalance follows the same rule', () {
      expect(isCoreOutOfBalance([4, 2, 2, 2, 2, 2]), isTrue); // recent-first
      expect(isCoreOutOfBalance([4, 4, 2, 2, 2, 2, 2]), isFalse);
    });
  });

  group('Balance %', () {
    test('100% when equal, 0% at the widest spread, null without data', () {
      expect(balancePercent({}), isNull);
      expect(balancePercent({'a': 3.0, 'b': 3.0, 'c': 3.0}), 100);
      expect(balancePercent({'a': 1.0, 'b': 5.0}), 0);
      expect(balancePercent({'a': 4.2, 'b': 1.8, 'c': 4.6, 'd': 2.1, 'e': 3.5}), 44); // the spec's example meter
    });

    test('rolling averages use the latest 7 check-in days', () {
      final days = [
        for (var i = 1; i <= 9; i++)
          DailyCheckin(date: '2026-09-${i.toString().padLeft(2, '0')}', scores: {'m': i <= 2 ? 1 : 5}),
      ];
      expect(rollingCoreAverages(days)['m'], 5.0); // days 1–2 fall outside
    });
  });

  testWidgets('multi-Core alert: combined copy, simplification + AI help', (tester) async {
    await tester.binding.setSurfaceSize(const Size(700, 1300));
    var simplify = 0, ai = 0;
    await pumpReal(
      tester,
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF06070D),
          body: CoreAlertSheet(
            coreName: 'Career',
            coreColor: MM.yellow,
            lowScores: const [2, 1, 2, 2, 2],
            streakDays: 5,
            recoveryDays: 1,
            otherStrugglingCores: const ['Physical Health'],
            onReviewHabits: () {},
            onReturnToPhase1: () {},
            onGetAiHelp: () => ai++,
            onSimplify: () => simplify++,
            onDone: () {},
          ),
        ),
      ),
    );
    expect(ci('Multiple Cores are struggling'), findsOneWidget);
    expect(ci('also struggling · physical health'), findsOneWidget);
    expect(ci('one more clears this alert'), findsOneWidget);
    await expectLater(find.byType(CoreAlertSheet), matchesGoldenFile('goldens/core_alert_multi.png'));
    await tester.tap(ci('Emergency Simplification Mode'));
    await tester.tap(ci('Get AI Help'));
    expect([simplify, ai], [1, 1]);
  });
}
