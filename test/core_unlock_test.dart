import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/widgets/momentum/core_unlock_overlay.dart';

void main() {
  test('first look on a device celebrates nothing (not on login)', () {
    expect(newlyUnlockedCores(null, ['physical', 'mindset']), isEmpty);
  });

  test('only Cores that were not active before are new', () {
    expect(newlyUnlockedCores([], ['physical']), ['physical']);
    expect(newlyUnlockedCores(['physical'], ['physical', 'relationships']), ['relationships']);
    expect(newlyUnlockedCores(['physical', 'mindset'], ['physical']), isEmpty);
  });
}
