import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/models/golden_habit.dart';
import 'package:untitled2/services/checkin_service.dart';
import 'package:untitled2/widgets/momentum/habit_detail_view.dart';

DailyCheckin day(String date, Map<String, CaptainsLogEntry> log) =>
    DailyCheckin(date: date, scores: const {'mindset': 4}, captainsLog: log);

void main() {
  group('habitLogLines', () {
    final checkins = [
      day('2026-10-05', {
        'mindset': const CaptainsLogEntry(wins: 'Calm morning'),
      }),
      day('2026-10-04', {
        'mindset': const CaptainsLogEntry(
          lessons: 'Skipped gratitude journal again',
        ),
        'physical': const CaptainsLogEntry(wins: 'Ran 5k'),
      }),
      day('2026-10-03', const {}),
      day('2026-10-02', {
        'mindset': const CaptainsLogEntry(wins: 'Journal done before coffee'),
      }),
    ];

    test(
      "only the habit's Core, mentions first, newest first in each group",
      () {
        final lines = habitLogLines(checkins, 'mindset', 'Gratitude Journal');
        expect(
          [for (final l in lines) l.date],
          ['2026-10-04', '2026-10-02', '2026-10-05'],
        );
        expect([for (final l in lines) l.mentions], [true, true, false]);
        expect(lines.first.lessons, 'Skipped gratitude journal again');
      },
    );

    test('short words never count as a mention', () {
      final lines = habitLogLines(checkins, 'mindset', 'Do it');
      expect(lines.every((l) => !l.mentions), isTrue);
    });

    test('no entries for the Core → empty', () {
      expect(habitLogLines(checkins, 'career', 'Anything'), isEmpty);
    });
  });

  test("abbreviated version falls back to WHAT for Nova's full block", () {
    GoldenHabit gh(String display) => GoldenHabit.fromJson({
      'habitId': 'x',
      'habitName': 'n',
      'what': 'Walk after lunch',
      'displayText': display,
    });
    expect(
      abbreviatedVersion(gh('Walk 2 min after lunch')),
      'Walk 2 min after lunch',
    );
    expect(
      abbreviatedVersion(gh('🏆 YOUR GOLDEN HABIT:\n\nWHERE: …')),
      'Walk after lunch',
    );
    expect(abbreviatedVersion(gh('x' * 200)), 'Walk after lunch');
    expect(abbreviatedVersion(gh('')), 'Walk after lunch');
  });

  group('GoldenHabit detail fields', () {
    final h = GoldenHabit.fromJson({
      'habitId': 'gh_1',
      'habitName': 'Gratitude Journal',
      'coreId': 'mindset_core',
      'habitType': 'Non-Routine Habit',
      'makeEasy': 'Journal on pillow',
      'mbsCompleted': true,
      'formed': true,
      'flagged': true,
      'flagReason': 'Too hard right now',
      'week': [1, 0, 1, 0, 1, 0, 0],
    });

    test('MBMs, notes and one-time actions are read', () {
      expect(h.makeEasy, 'Journal on pillow');
      expect(h.mbsCompleted, isTrue);
      expect(h.playerNotes, '');
      expect(h.oneTimeActions, '');
    });

    test('applyEdits changes only the edited fields', () {
      final e = h.applyEdits({
        'playerNotes': 'Works best at night',
        'habitName': 'Night Journal',
      });
      expect(e.playerNotes, 'Works best at night');
      expect(e.habitName, 'Night Journal');
      expect(e.makeEasy, 'Journal on pillow');
      expect(e.habitType, 'non_routine');
      expect(e.formed, isTrue);
      expect(e.flagged, isTrue);
      expect(e.flagReason, 'Too hard right now');
      expect(e.week, [1, 0, 1, 0, 1, 0, 0]);
    });

    test(
      'reclassification audit trail + MBM review flag are read and survive edits',
      () {
        final r = GoldenHabit.fromJson({
          'habitId': 'gh_2',
          'habitName': 'TEST Pause',
          'habitType': 'non_routine',
          'mbmsNeedReview': true,
          'reclassifiedAt': '2026-10-06',
          'reclassifications': [
            {
              'from': 'routine',
              'to': 'non_routine',
              'date': '2026-10-06',
              'source': 'player',
              'reason': 'stress',
            },
            'junk',
          ],
        });
        expect(r.mbmsNeedReview, isTrue);
        expect(r.reclassifiedAt, '2026-10-06');
        expect(r.reclassifications, hasLength(1));
        expect(r.reclassifications.single.from, 'routine');
        expect(r.reclassifications.single.reason, 'stress');
        final e = r.applyEdits({'playerNotes': 'x'});
        expect(e.mbmsNeedReview, isTrue);
        expect(e.reclassifications.single.to, 'non_routine');
        expect(h.reclassifications, isEmpty);
        expect(h.mbmsNeedReview, isFalse);
      },
    );

    test('editable keys match the server allowlist (goldenHabitDetail.js)', () {
      final js = File('../../vf-bridge/functions-flutter/goldenHabitDetail.js');
      if (!js.existsSync()) {
        markTestSkipped('backend checkout not next to the app');
        return;
      }
      final block =
          RegExp(
            r'const EDITABLE = \{([^}]*)\}',
          ).firstMatch(js.readAsStringSync())!.group(1)!;
      final serverKeys =
          RegExp(r'(\w+):').allMatches(block).map((m) => m.group(1)).toSet();
      expect(GoldenHabit.editableKeys.toSet(), serverKeys);
    });
  });
}
