import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/services/accountability_service.dart';

AccountabilityPairing pairing({required String cadence, int? lastNudgeAt}) =>
    AccountabilityPairing(
      partnerId: 'ap_maya',
      partnerName: 'Maya R.',
      partnerCore: 'physical',
      partnerAvatar: 'M',
      cadence: cadence,
      createdAt: 0,
      lastNudgeAt: lastNudgeAt,
      nudgeCount: 0,
    );

void main() {
  final now = DateTime(2026, 7, 21, 14, 0); // a Tuesday afternoon

  group('checkInDue — daily cadence', () {
    test('due when never checked in', () {
      expect(pairing(cadence: 'daily').checkInDue(now), isTrue);
    });

    test('NOT due when already checked in earlier today', () {
      final earlierToday = DateTime(2026, 7, 21, 8).millisecondsSinceEpoch;
      expect(
          pairing(cadence: 'daily', lastNudgeAt: earlierToday).checkInDue(now),
          isFalse);
    });

    test('due when last check-in was yesterday', () {
      final yesterday = DateTime(2026, 7, 20, 23).millisecondsSinceEpoch;
      expect(pairing(cadence: 'daily', lastNudgeAt: yesterday).checkInDue(now),
          isTrue);
    });
  });

  group('checkInDue — weekly cadence', () {
    test('due when never checked in', () {
      expect(pairing(cadence: 'weekly').checkInDue(now), isTrue);
    });

    test('NOT due 3 days after last check-in', () {
      final threeDaysAgo = now.subtract(const Duration(days: 3));
      expect(
          pairing(cadence: 'weekly', lastNudgeAt: threeDaysAgo.millisecondsSinceEpoch)
              .checkInDue(now),
          isFalse);
    });

    test('due exactly 7 days after last check-in', () {
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      expect(
          pairing(cadence: 'weekly', lastNudgeAt: sevenDaysAgo.millisecondsSinceEpoch)
              .checkInDue(now),
          isTrue);
    });
  });

  group('nextDueLabel', () {
    test('weekly shows remaining days', () {
      final twoDaysAgo = now.subtract(const Duration(days: 2));
      final label = pairing(
              cadence: 'weekly', lastNudgeAt: twoDaysAgo.millisecondsSinceEpoch)
          .nextDueLabel(now);
      expect(label, 'Next check-in in 5 days');
    });

    test('daily shows tomorrow', () {
      final earlierToday = DateTime(2026, 7, 21, 8).millisecondsSinceEpoch;
      expect(
          pairing(cadence: 'daily', lastNudgeAt: earlierToday).nextDueLabel(now),
          'Next check-in tomorrow');
    });
  });

  test('cadence normalizes unknown values to daily', () {
    final p = AccountabilityPairing.fromDoc({
      'partnerId': 'ap_kai',
      'cadence': 'monthly', // not a valid cadence
    });
    expect(p.cadence, 'daily');
    expect(p.isWeekly, isFalse);
  });
}
