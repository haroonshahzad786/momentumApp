import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/services/journey_config_service.dart';
import 'package:untitled2/widgets/momentum/journey_stage.dart';

void main() {
  const defaultIds = ['earth', 'moon', 'mars', 'jupiter', 'saturn', 'pluto'];
  const allIds = [
    'earth', 'spacestation', 'moon', 'mars', 'jupiter', 'saturn', 'uranus', 'neptune', 'pluto',
  ];

  test('default route keeps the hand-tuned layout', () {
    final stops = journeyStopsFor(defaultIds);
    expect(stops.map((s) => s.id), [...defaultIds, 'station']);
    expect(stops.first.y, 5400);
    expect(stops[3].dx, 380); // Jupiter, verbatim from the handoff
    expect(stops.last.y, 950);
  });

  test('8 destinations: ordered bottom→top, Earth/Station centred, no body overlap', () {
    final stops = journeyStopsFor(allIds);
    expect(stops.map((s) => s.id), [...allIds, 'station']);
    expect(stops.first.dx, 0);
    expect(stops.last.dx, 0);
    for (var i = 0; i + 1 < stops.length; i++) {
      final a = stops[i], b = stops[i + 1];
      expect(b.y, lessThan(a.y));
      // Neighbours either clear each other vertically or sit on opposite sides.
      final vClear = (a.y - b.y) >= (a.halfH + b.halfH) * 0.8;
      final hClear = (a.x - b.x).abs() >= (a.w + b.w) / 2 * 0.8;
      expect(vClear || hClear, isTrue, reason: '${a.id} vs ${b.id}');
    }
  });

  test('config parse: live seeded doc → default route; 8 enabled → all', () {
    final (g, seeded) = JourneyConfigService.parse({
      'planets': [
        for (final id in defaultIds) {'id': id, 'mpRequired': null},
      ],
    });
    expect(g, 'milky_way');
    expect(seeded.where((p) => p.enabled).map((p) => p.id), defaultIds);

    final (_, all) = JourneyConfigService.parse({
      'planets': [
        for (final id in allIds) {'id': id, 'enabled': true},
      ],
    });
    expect(all.where((p) => p.enabled).map((p) => p.id), allIds);

    final (_, tooFew) = JourneyConfigService.parse({
      'planets': [
        {'id': 'moon', 'enabled': false},
        {'id': 'mars', 'enabled': false},
      ],
    });
    expect(tooFew.where((p) => p.enabled).map((p) => p.id), defaultIds);
  });
}
