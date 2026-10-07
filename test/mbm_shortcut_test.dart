import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/services/cantina_ideas_service.dart';
import 'package:untitled2/widgets/momentum/mbm_shortcut.dart';

CantinaIdea idea(String id, String kind, String core, int upvotes) => CantinaIdea(
      id: id,
      kind: kind,
      core: core,
      pain: '',
      title: id,
      desc: '',
      upvotes: upvotes,
      adopted: 0,
      link: false,
    );

void main() {
  test('Ideas Well: only MBMs, the habit\'s Core first, most upvoted first', () {
    final ideas = [
      idea('a', 'mbm', 'mindset', 50),
      idea('b', 'mbm', 'physical', 3),
      idea('c', 'habit', 'physical', 99),
      idea('d', 'mbm', 'physical', 12),
      idea('e', 'tech', 'physical', 40),
      idea('f', 'mbm', 'career', 8),
    ];
    expect(mbmIdeasFor(ideas, 'physical').map((i) => i.id), ['d', 'b', 'a', 'f']);
    expect(mbmIdeasFor(const [], 'physical'), isEmpty);
  });

  test('appending a strategy keeps what was there and skips duplicates', () {
    expect(appendMbm('', 'Shoes by the door'), 'Shoes by the door');
    expect(appendMbm('Sticky note on mug', 'Shoes by the door'),
        'Sticky note on mug\nShoes by the door');
    expect(appendMbm('Shoes by the door', 'shoes by the door'), 'Shoes by the door');
    expect(appendMbm('Sticky note', '   '), 'Sticky note');
  });

  test('each MBM kind fills its own habit field', () {
    expect(MbmKind.values.map((k) => k.field), ['makeObvious', 'makeEasy', 'makeRewarding']);
  });
}
