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

CoreList list(String core, String name, List<String> items,
        {Map<String, String> colors = const {}}) =>
    CoreList(
        coreId: core,
        coreLabel: core,
        categoryId: 'golden_habit',
        name: name,
        items: items,
        colors: colors);

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
      expect(all.single.color, HabitColor.orange);
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
      expect(a.color, HabitColor.green);
      expect(a.progress, isNull);
      expect(b.color, HabitColor.orange);
      expect(b.progress!.days, 8);
      expect(b.slot, HabitSlot.evening);
    });

    test('list-only lines use the colour the player tagged', () {
      final all = mergeAllHabits(
        golden: const [],
        routineLists: [
          list('career_finance_core', 'Routines List', ['Inbox zero'],
              colors: {'inbox_zero': 'red'})
        ],
        nonRoutineLists: const [],
        coreScores: {'career': List.filled(20, 5)},
      );
      expect(all.single.color, HabitColor.red,
          reason: "the tag, not the Core's scores");
      expect(all.single.slot, HabitSlot.anytime);
      expect(all.single.isGolden, isFalse);
    });

    test('untagged line → no colour, not a made-up one', () {
      final all = mergeAllHabits(
        golden: const [],
        routineLists: const [],
        nonRoutineLists: [list('emotional_mental_core', 'Non-Routine', ['Breathe when anxious'])],
        coreScores: const {},
      );
      expect(all.single.color, isNull);
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

  group('colour key', () {
    test('itemKey matches functions-flutter/coreLists.js', () {
      expect(itemKey('Morning · Journal 5 min'), 'morning_journal_5_min');
      expect(itemKey('  Walk 20 min!! '), 'walk_20_min');
      expect(itemKey('Café ☕ time'), 'caf_time');
      expect(itemKey('x' * 400).length, 150);
      expect(itemKey('···'), '');
    });

    test('lineStatus: Golden Habit auto colour + progress, else the tag', () {
      final l = list('mindset_core', 'Routines List',
          ['Morning · Journal 5 min', 'Scroll phone in bed', 'Coffee'],
          colors: {'scroll_phone_in_bed': 'red', 'coffee': 'purple'});
      final idx = goldenIndex([gh('h', 'Journal 5 min', 'mindset_core')]);
      final scores = {'mindset': List.filled(6, 4)};
      final a = lineStatus(l, 'Morning · Journal 5 min', idx, scores);
      expect(a.color, HabitColor.orange);
      expect(a.progress!.days, 6);
      expect(a.golden, isNotNull);
      expect(lineStatus(l, 'Scroll phone in bed', idx, scores).color,
          HabitColor.red);
      expect(lineStatus(l, 'Coffee', idx, scores).color, isNull,
          reason: 'unknown colour ids are ignored');
    });

    test('status counter tallies only red / orange / green', () {
      final n = statusCounts([
        HabitColor.red,
        HabitColor.orange,
        HabitColor.orange,
        HabitColor.green,
        HabitColor.black,
        HabitColor.note,
        null,
      ]);
      expect((n.red, n.orange, n.green), (1, 2, 1));
    });
  });

  group('Non-Routines list', () {
    AllHabit nr(String name, String core, HabitColor? c, {String? id}) => AllHabit(
        name: name,
        core: core,
        isRoutine: false,
        slot: HabitSlot.throughout,
        color: c,
        habitId: id);

    test('default priority: highest damage first (red, orange, blue …)', () {
      final out = orderByPriority([
        nr('b', 'career', HabitColor.blue),
        nr('n', 'career', null),
        nr('r', 'career', HabitColor.red),
        nr('o', 'career', HabitColor.orange),
      ], const []);
      expect([for (final h in out) h.name], ['r', 'o', 'b', 'n']);
    });

    test('saved order wins; habits it does not know follow by priority', () {
      final out = orderByPriority([
        nr('A', 'career', HabitColor.red, id: 'a'),
        nr('B', 'career', HabitColor.orange, id: 'b'),
        nr('New bad one', 'career', HabitColor.red),
      ], const ['g:b', 'g:a']);
      expect([for (final h in out) h.name], ['B', 'A', 'New bad one']);
    });

    test('keys: Golden Habit by id, line by name', () {
      expect(nr('X', 'career', null, id: 'h9').key, 'g:h9');
      expect(nr('Breathe when anxious', 'career', null).key, 'n:breathe_when_anxious');
    });

    test('formed Golden Habits graduate; routines excluded; Mindset always there', () {
      final all = [
        nr('Formed one', 'physical', HabitColor.green, id: 'f'),
        nr('Still forming', 'physical', HabitColor.orange, id: 's'),
        AllHabit(
            name: 'Routine',
            core: 'physical',
            isRoutine: true,
            slot: HabitSlot.morning,
            color: HabitColor.red),
        nr('Tagged healthy line', 'career', HabitColor.green),
      ];
      final out = nonRoutineList(all, const {});
      expect(out.graduated, 1);
      expect(out.byCore.keys, ['mindset', 'career', 'physical']);
      expect(out.byCore['mindset'], isEmpty);
      expect([for (final h in out.byCore['physical']!) h.name], ['Still forming']);
      expect(out.byCore['career']!.single.name, 'Tagged healthy line',
          reason: 'only formed Golden Habits leave for the Trophy Room');
    });

    test('IF-THEN: trigger → response, else the obstacle plan', () {
      final withTrigger = mergeAllHabits(
        golden: [
          GoldenHabit.fromJson({
            'habitId': 't',
            'habitName': 'Reframe',
            'coreId': 'mindset_core',
            'habitType': 'non_routine',
            'trigger': 'spiraling into "not good enough"',
            'what': 'pause and ask what a growth-owner would do',
          }),
          GoldenHabit.fromJson({
            'habitId': 'o',
            'habitName': 'Walk',
            'coreId': 'physical_health_core',
            'habitType': 'routine',
            'obstacleIf': 'it rains',
            'obstacleThen': 'walk the stairs',
          }),
        ],
        routineLists: const [],
        nonRoutineLists: const [],
        coreScores: const {},
      );
      final t = withTrigger.firstWhere((h) => h.habitId == 't');
      expect(t.ifText, 'spiraling into "not good enough"');
      expect(t.thenText, 'pause and ask what a growth-owner would do');
      final o = withTrigger.firstWhere((h) => h.habitId == 'o');
      expect((o.ifText, o.thenText), ('it rains', 'walk the stairs'));
    });
  });
}
