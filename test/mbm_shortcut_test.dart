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

  test('an idea titled with its method preselects it and drops the prefix', () {
    CantinaIdea titled(String title, String desc) => CantinaIdea(
          id: 'x', kind: 'mbm', core: 'mindset', pain: '', title: title, desc: desc,
          upvotes: 0, adopted: 0, link: false,
        );
    final o = ideaStrategy(titled('Make It Obvious · phone charges outside bedroom', 'No screen'));
    expect(o.kind, MbmKind.obvious);
    expect(o.text, 'phone charges outside bedroom — No screen');
    expect(ideaStrategy(titled('Make it Easy: 2-minute start rule', '')).kind, MbmKind.easy);
    expect(ideaStrategy(titled('make it fun - music on', '')).kind, MbmKind.rewarding);
    final plain = ideaStrategy(titled('Shoes by the door', ''));
    expect(plain.kind, isNull);
    expect(plain.text, 'Shoes by the door');
  });

  test('each MBM kind fills its own habit field', () {
    expect(MbmKind.values.map((k) => k.field), ['makeObvious', 'makeEasy', 'makeRewarding']);
  });
}
