import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/widgets/momentum/journey_stage.dart';

/// The drawn trajectory and the flown trajectory must be the same curve.
///
/// They diverged once: the painter trimmed the dashes by moving the bezier's
/// endpoints while leaving the control point alone, which reshapes the curve
/// instead of shortening it. These tests pin the two together.
void main() {
  /// Closest distance from [p] to [path], by walking its flattened metrics.
  double distanceToPath(Offset p, Path path) {
    var best = double.infinity;
    for (final metric in path.computeMetrics()) {
      final steps = (metric.length / 2).ceil().clamp(2, 20000);
      for (var i = 0; i <= steps; i++) {
        final tan = metric.getTangentForOffset(metric.length * i / steps);
        if (tan == null) continue;
        final d = (tan.position - p).distance;
        if (d < best) best = d;
      }
    }
    return best;
  }

  test('every flown point lies on the drawn path', () {
    for (var i = 0; i < kJourneyStops.length - 1; i++) {
      final leg = JourneyLeg(kJourneyStops[i], kJourneyStops[i + 1], i);
      final path = leg.path;
      for (var s = 0; s <= 40; s++) {
        final t = s / 40;
        final d = distanceToPath(leg.pos(t), path);
        expect(d, lessThan(1.0),
            reason: 'leg $i (${leg.a.id}→${leg.b.id}) at t=$t is ${d.toStringAsFixed(1)}px '
                'off the drawn path');
      }
    }
  });

  test('drawn path starts and ends exactly on the two seats', () {
    for (var i = 0; i < kJourneyStops.length - 1; i++) {
      final leg = JourneyLeg(kJourneyStops[i], kJourneyStops[i + 1], i);
      final metric = leg.path.computeMetrics().first;
      final start = metric.getTangentForOffset(0)!.position;
      final end = metric.getTangentForOffset(metric.length)!.position;
      expect((start - leg.a.seat).distance, lessThan(0.5), reason: 'leg $i start');
      expect((end - leg.b.seat).distance, lessThan(0.5), reason: 'leg $i end');
      // pos() agrees at the endpoints too.
      expect((leg.pos(0) - leg.a.seat).distance, lessThan(0.001));
      expect((leg.pos(1) - leg.b.seat).distance, lessThan(0.001));
    }
  });

  test('legs actually bow, and bow alternately', () {
    for (var i = 0; i < kJourneyStops.length - 1; i++) {
      final leg = JourneyLeg(kJourneyStops[i], kJourneyStops[i + 1], i);
      final mid = leg.pos(0.5);
      final chordMid = Offset(
        (leg.p0.dx + leg.p2.dx) / 2,
        (leg.p0.dy + leg.p2.dy) / 2,
      );
      final offset = mid.dx - chordMid.dx;
      // A quadratic sits halfway to its control point at t=0.5, so the bow is
      // kBow/2 — signed by leg parity.
      expect(offset.abs(), greaterThan(100),
          reason: 'leg $i is essentially straight');
      expect(offset.isNegative, i.isOdd,
          reason: 'leg $i bows the wrong way');
    }
  });

  test('nose is upright at the seats and tilted mid-arc', () {
    for (var i = 0; i < kJourneyStops.length - 1; i++) {
      final leg = JourneyLeg(kJourneyStops[i], kJourneyStops[i + 1], i);
      expect(leg.angleDeg(0.5).abs(), greaterThan(5),
          reason: 'leg $i has no visible lean mid-arc');
      // The flight lerps the angle back to 0 on approach, so only the raw
      // tangent is checked here — it must stay within a sane range.
      expect(leg.angleDeg(0.5).abs(), lessThan(90),
          reason: 'leg $i leans implausibly far');
    }
  });
}
