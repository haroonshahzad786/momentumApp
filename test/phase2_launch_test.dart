import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/widgets/momentum/phase2_launch.dart';

void main() {
  test('tour follows the Sequence order and ends on the Daily Check-In', () {
    final steps = cockpitTourSteps(web: false, activeCores: const ['physical']);
    expect(steps.map((s) => s.icon), ['☰', '🏆', '📊', '🔥', '🚀', '🎯', '▶️']);
    expect(steps.last.title, 'Your Daily Check-In');
  });

  test('web shows the sidebar instead of the phone menu', () {
    final web = cockpitTourSteps(web: true, activeCores: const []);
    expect(web.first.title, 'Left sidebar');
    expect(web[2].title, 'Flight Data');
  });

  test('Cores stop marks the active Core and invites the locked ones', () {
    final cores = cockpitTourSteps(web: false, activeCores: const ['physical'])[4].body;
    expect(cores, contains('💪 Physical Health: ACTIVE'));
    expect(cores, contains('🧠 Mindset: Locked.'));
    expect(cores, contains('light up the moment you create a Golden Habit'));
  });
}
