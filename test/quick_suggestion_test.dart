import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/services/habits_service.dart';

void main() {
  test('Quick Suggestion parses data points and tweaks, skipping junk', () {
    final s = QuickSuggestion.fromJson({
      'ok': true,
      'diagnosis': 'Cue collides with meetings',
      'title': '1:30 buffer',
      'hypothesis': 'Earlier slot dodges meetings',
      'dataPoints': [
        {'source': "Captain's Log", 'text': 'Meeting ran long'},
        'junk',
      ],
      'tweaks': [
        {'field': 'when', 'label': 'WHEN', 'from': '1:45pm', 'to': '1:30pm', 'why': 'before meetings'},
        {'field': 'makeEasy', 'to': 'Shoes by the door'},
      ],
    });
    expect(s.title, '1:30 buffer');
    expect(s.dataPoints.single.source, "Captain's Log");
    expect(s.tweaks.map((t) => (t.field, t.from, t.to)), [
      ('when', '1:45pm', '1:30pm'),
      ('makeEasy', '', 'Shoes by the door'),
    ]);
    expect(s.tweaks.last.label, 'makeEasy'); // falls back to the field key
  });
}
