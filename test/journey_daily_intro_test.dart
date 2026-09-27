import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled2/widgets/momentum/journey_stage.dart';

/// #20 — the first dashboard view of the day opens on the whole route, holds,
/// then flies in to the cockpit; later views that day open straight in.

/// Real HTTP so google_fonts can load (see ship_warning_test.dart).
class _RealHttp extends HttpOverrides {}

void main() {
  setUpAll(() => HttpOverrides.global = _RealHttp());

  String today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Widget host() => const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 700,
            height: 520,
            child: JourneyStage(
              planetIdx: 0,
              activeCores: [],
              atRiskCores: {},
              streak: 0,
              dailyIntro: true,
            ),
          ),
        ),
      );

  double zoom(WidgetTester t) =>
      t.widget<JourneyZoomBar>(find.byType(JourneyZoomBar)).value;

  /// Lets the SharedPreferences futures resolve, then renders a frame.
  Future<void> settlePrefs(WidgetTester t) async {
    for (var i = 0; i < 6; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pump();
    }
  }

  testWidgets('first view of the day: out → hold → in', (t) async {
    SharedPreferences.setMockInitialValues({'mm.journey.seen_planet': '0'});
    await t.pumpWidget(host());
    await settlePrefs(t);

    expect(zoom(t), 0, reason: 'opens zoomed right out on the route');
    await t.pump(const Duration(milliseconds: 1000));
    expect(zoom(t), 0, reason: 'holds on the route');

    await t.pump(const Duration(milliseconds: 500)); // hold ends (1400 ms)
    await t.pump(const Duration(milliseconds: 1100)); // mid fly-in
    expect(zoom(t), inExclusiveRange(0.05, 0.95));

    await t.pump(const Duration(milliseconds: 1300));
    expect(zoom(t), 1, reason: 'lands on the cockpit');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('mm.journey.intro_day'), '"${today()}"');
  });

  testWidgets('already shown today: opens straight on the cockpit', (t) async {
    SharedPreferences.setMockInitialValues({
      'mm.journey.seen_planet': '0',
      'mm.journey.intro_day': '"${today()}"',
    });
    await t.pumpWidget(host());
    await settlePrefs(t);
    expect(zoom(t), 1);
    await t.pump(const Duration(seconds: 4));
    expect(zoom(t), 1);
  });
}
