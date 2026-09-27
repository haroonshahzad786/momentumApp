import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/models/core_list.dart';
import 'package:untitled2/models/golden_habit.dart';
import 'package:untitled2/services/all_habits.dart';

GoldenHabit gh(String id, String name, String core,
        {String type = 'routine', String when = '', bool formed = false, bool flagged = false}) =>
    GoldenHabit.fromJson({
      'habitId': id,
      'habitName': name,
      'coreId': core,
      'habitType': type,
      'when': when,
      'formed': formed,
      'flagged': flagged,
    });

CoreList list(String core, String name, List<String> items) => CoreList(
    coreId: core, coreLabel: core, categoryId: 'golden_habit', name: name, items: items);

void main() {
  group('parseHabitLine', () {
    test('Block · Habit · cue convention', () {
      final p = parseHabitLine('Morning · Journal 5 min · after coffee');
      expect(p.name, 'Journal 5 min');
      expect(p.blockId, 'morning');
      expect(p.cue, 'after coffee');
    });

    test('time word inside a plain name', () {
      expect(parseHabitLine('Walk 20 min in the evening').blockId, 'evening');
      expect(parseHabitLine('Deep work sprint').blockId, isNull,
          reason: '"work" alone is too ambiguous to place');
    });
  });

  group('mergeAllHabits', () {
    test('a Golden Habit also saved as a list line appears once', () {
      final all = mergeAllHabits(
        golden: [gh('h1', 'Journal 5 min', 'mindset_core')],
        routineLists: [list('mindset_core', 'Routines List', ['Morning · Journal 5 min'])],
        nonRoutineLists: const [],
        coreScores: const {},
      );
      expect(all, hasLength(1));
      expect(all.single.habitId, 'h1');
      expect(all.single.slot, HabitSlot.morning,
          reason: 'borrows the list line\'s block when `when` names none');
    });

    test('Golden-only habits show (the Routines screen misses these)', () {
      final all = mergeAllHabits(
        golden: [gh('h1', 'Deep Presence Practice', 'relationships_core', type: 'non_routine')],
        routineLists: const [],
        nonRoutineLists: const [],
        coreScores: const {},
      );
      expect(all.single.core, 'relationships');
      expect(all.single.slot, HabitSlot.throughout);
      expect(all.single.status, 'forming');
    });

    test('status: formed flag wins; forming carries Day X/14 progress', () {
      final all = mergeAllHabits(
        golden: [
          gh('a', 'A', 'physical_health_core', formed: true),
          gh('b', 'B', 'mindset_core', when: 'Evening'),
        ],
        routineLists: const [],
        nonRoutineLists: const [],
        coreScores: {'mindset': List.filled(8, 4)},
      );
      final a = all.firstWhere((h) => h.name == 'A');
      final b = all.firstWhere((h) => h.name == 'B');
      expect(a.status, 'formed');
      expect(a.progress, isNull);
      expect(b.status, 'forming');
      expect(b.progress!.days, 8);
      expect(b.slot, HabitSlot.evening);
    });

    test('list-only lines take their status from the Core\'s scores', () {
      final all = mergeAllHabits(
        golden: const [],
        routineLists: [list('career_finance_core', 'Routines List', ['Inbox zero'])],
        nonRoutineLists: const [],
        coreScores: {'career': List.filled(5, 1)},
      );
      expect(all.single.status, 'bad');
      expect(all.single.slot, HabitSlot.anytime);
      expect(all.single.isGolden, isFalse);
    });

    test('no check-ins yet → neutral, not a made-up colour', () {
      final all = mergeAllHabits(
        golden: const [],
        routineLists: const [],
        nonRoutineLists: [list('emotional_mental_core', 'Non-Routine', ['Breathe when anxious'])],
        coreScores: const {},
      );
      expect(all.single.status, 'none');
    });
  });

  group('grouping', () {
    final habits = mergeAllHabits(
      golden: [
        gh('1', 'Stretch', 'physical_health_core', when: 'morning'),
        gh('2', 'Gratitude note', 'mindset_core', when: 'evening'),
        gh('3', 'Pause before replying', 'relationships_core', type: 'non_routine'),
        gh('4', 'Plan the day', 'mindset_core', when: 'morning'),
      ],
      routineLists: const [],
      nonRoutineLists: const [],
      coreScores: const {},
    );

    test('By Time: day order, Core order inside, empty sections dropped', () {
      final s = groupByTime(habits);
      expect([for (final x in s) x.title], ['Morning', 'Evening', 'Throughout Day']);
      expect([for (final h in s.first.habits) h.name], ['Plan the day', 'Stretch']);
    });

    test('By Core: PRD Core order, routines by time then non-routines', () {
      final s = groupByCore(habits, const {'mindset': 'Mindset'});
      expect([for (final x in s) x.id], ['mindset', 'relationships', 'physical']);
      expect([for (final h in s.first.habits) h.name], ['Plan the day', 'Gratitude note']);
      expect(s[1].title, 'relationships', reason: 'falls back to the id');
    });
  });
}
