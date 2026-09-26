import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/services/checkin_service.dart';

void main() {
  test('structured entry round-trips; blanks are dropped', () {
    const e = CaptainsLogEntry(wins: ' Did my jumping jacks ', lessons: '');
    expect(e.isEmpty, isFalse);
    expect(e.toMap(), {'wins': 'Did my jumping jacks'});
    expect(CaptainsLogEntry.from(e.toMap()).wins, 'Did my jumping jacks');
    expect(const CaptainsLogEntry(wins: '  ', lessons: '').isEmpty, isTrue);
  });

  test('old single-box logs still show up (as a win)', () {
    final day = DailyCheckin.fromDoc('2026-07-21', {
      'scores': {'physical': 4},
      'logs': {'physical': 'Felt great after the walk', 'mindset': ''},
    });
    expect(day.captainsLog.keys, ['physical']);
    expect(day.captainsLog['physical']!.wins, 'Felt great after the walk');
  });

  test('new captainsLog field wins over the legacy copy', () {
    final day = DailyCheckin.fromDoc('2026-09-26', {
      'scores': {'physical': 2},
      'logs': {'physical': 'Wins: x · Lessons: y'},
      'captainsLog': {
        'physical': {'wins': 'x', 'lessons': 'Meeting ran long'},
      },
    });
    expect(day.captainsLog['physical']!.lessons, 'Meeting ran long');
    expect(day.captainsLog['physical']!.wins, 'x');
  });
}
