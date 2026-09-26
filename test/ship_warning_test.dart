import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/widgets/momentum/ship_warning.dart';

/// flutter_test blocks all HTTP (400s), but the app's google_fonts styles
/// download Orbitron / Red Hat Display on first use. Run the widget under the
/// real client so fonts load (needs network; no app code changes).
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
        home: Scaffold(backgroundColor: const Color(0xFF06070D), body: child),
      );

  testWidgets('relaunch sheet: copy, preserved items, actions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1100));
    var quick = 0, nova = 0, closed = 0;
    await pumpReal(tester, host(RelaunchSheet(
      missedWeekdays: 3,
      longAbsence: false,
      pointsRemoved: 0,
      formedHabits: 1,
      spaceCredits: 90,
      level: 'cadet',
      onQuickCheckIn: () => quick++,
      onFullCheckIn: () {},
      onCaptainsLog: () {},
      onTalkToNova: () => nova++,
      onCantina: null,
      onClose: () => closed++,
    )));
    expect(find.text("You're back."), findsOneWidget);
    expect(find.textContaining('missed 3 weekday check-ins'), findsOneWidget);
    expect(find.text('Trophy Room · 1 formed habit'), findsOneWidget);
    expect(find.text('Space Credits · 90'), findsOneWidget);
    expect(ci('Space Cantina'), findsNothing); // locked → hidden
    await expectLater(find.byType(RelaunchSheet), matchesGoldenFile('goldens/relaunch_sheet.png'));
    await tester.tap(ci('Quick relaunch'));
    await tester.tap(ci('Talk to Nova'));
    await tester.tap(find.byIcon(Icons.close));
    expect([quick, nova, closed], [1, 1, 1]);
  });

  testWidgets('long absence uses welcome-back copy and shows the penalty', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1100));
    await pumpReal(tester, host(RelaunchSheet(
      missedWeekdays: 9,
      longAbsence: true,
      pointsRemoved: 20,
      formedHabits: 0,
      spaceCredits: 0,
      level: 'navigator',
      onQuickCheckIn: () {},
      onFullCheckIn: () {},
      onCaptainsLog: () {},
      onTalkToNova: () {},
      onCantina: () {},
      onClose: () {},
    )));
    expect(find.text('Welcome back, Captain.'), findsOneWidget);
    expect(find.textContaining('−20 Momentum Points'), findsOneWidget);
    expect(ci('Space Cantina'), findsOneWidget);
  });

  testWidgets('ship warning banner: snooze + check-in', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 300));
    var snooze = 0, checkin = 0;
    await pumpReal(tester, host(Align(
      alignment: Alignment.topCenter,
      child: ShipWarningBanner(onCheckIn: () => checkin++, onSnooze: () => snooze++),
    )));
    expect(find.textContaining('Your rocket is losing momentum'), findsOneWidget);
    await expectLater(find.byType(ShipWarningBanner), matchesGoldenFile('goldens/ship_warning.png'));
    await tester.tap(ci('Remind me in 1 hour'));
    await tester.tap(ci('Check in now'));
    expect([snooze, checkin], [1, 1]);
  });
}
