import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/models/core_list.dart';
import 'package:untitled2/models/golden_habit.dart';
import 'package:untitled2/services/all_habits.dart';

GoldenHabit g(String name, String core, String type) => GoldenHabit.fromJson({
      'habitId': name,
      'habitName': name,
      'coreId': core,
      'coreLabel': core,
      'habitType': type,
    });

CoreList list(String core, String name, List<String> items) => CoreList(
      coreId: core,
      coreLabel: core,
      categoryId: 'golden_habit',
      name: name,
      items: items,
    );

void main() {
  test('a Golden Habit with no line gets one in its Core and type list', () {
    final out = withGoldenLines(
      routine: const [],
      nonRoutine: const [],
      golden: [
        g('Morning Mental Reset', 'mindset_core', 'Routine Habit'),
        g('Pause & Breathe', 'emotional_mental_core', 'non_routine'),
      ],
    );
    expect(out.routine.single.items, ['Morning Mental Reset']);
    expect(out.routine.single.name, 'Routines List');
    expect(out.nonRoutine.single.items, ['Pause & Breathe']);
    expect(out.nonRoutine.single.coreId, 'emotional_mental_core');
  });

  test('existing lines are kept; matching names are not duplicated', () {
    final out = withGoldenLines(
      routine: [
        list('mindset_core', 'Routines List', ['Morning · Morning Mental Reset · 7am', 'Read 5 pages']),
        list('physical_health_core', 'Routines List', ['Stretch']),
      ],
      nonRoutine: const [],
      golden: [
        g('morning mental reset', 'mindset_core', 'routine'),
        g('Energy Reset Ritual', 'physical_health_core', 'routine'),
      ],
    );
    expect(out.routine[0].items, ['Morning · Morning Mental Reset · 7am', 'Read 5 pages']);
    expect(out.routine[1].items, ['Stretch', 'Energy Reset Ritual']);
  });

  test('a habit already listed under the other type is left where it is', () {
    final out = withGoldenLines(
      routine: const [],
      nonRoutine: [list('mindset_core', 'Non-Routine', ['Gratitude'])],
      golden: [g('Gratitude', 'mindset_core', 'routine')],
    );
    expect(out.routine, isEmpty);
    expect(out.nonRoutine.single.items, ['Gratitude']);
  });
}
