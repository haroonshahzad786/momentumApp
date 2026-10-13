import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/services/behavior_tracker.dart';

List<String> _types(BehaviorTracker t) =>
    [for (final e in t.pending) e['type'] as String];

void main() {
  final t = BehaviorTracker.instance;
  setUp(t.debugReset);

  test('screen() logs views, collapses repeats, flags A→B→A as backtrack', () {
    t
      ..screen('dashboard')
      ..screen('dashboard')
      ..screen('lists')
      ..screen('dashboard');
    expect(_types(t), ['screen_view', 'screen_view', 'screen_view', 'backtrack']);
  });

  test('forward navigation is not a backtrack', () {
    t
      ..screen('a')
      ..screen('b')
      ..screen('c');
    expect(_types(t), ['screen_view', 'screen_view', 'screen_view']);
  });

  test('skip() records where', () {
    t.skip('intro', screen: 'intro');
    expect(t.pending.single['payload'], {'where': 'intro'});
    expect(t.pending.single['screen'], 'intro');
  });
}
