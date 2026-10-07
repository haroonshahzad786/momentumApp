import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/models/golden_habit.dart';
import 'package:untitled2/services/checkin_service.dart';
import 'package:untitled2/services/experiments.dart';

DailyCheckin day(String date, int? mindset) => DailyCheckin(
      date: date,
      scores: {if (mindset != null) 'mindset': mindset, 'physical': 5},
    );

const exp = HabitExperiment(
  id: 'e1',
  source: 'manual',
  title: 'New when',
  startDay: '2026-10-05',
  changes: {'when': (from: '7am', to: '6am')},
);

void main() {
  test('window = the next 3 Core check-ins after the start day', () {
    final p = experimentProgress(exp, 'mindset', [
      day('2026-10-09', 4),
      day('2026-10-02', 2),
      day('2026-10-05', 3), // start day → baseline
      day('2026-10-06', 4),
      day('2026-10-07', null), // Core not scored → skipped
      day('2026-10-08', 5),
      day('2026-10-10', 1), // after the window
      day('2026-10-01', 1),
      day('2026-09-30', 1),
    ]);
    expect(p.during, [4, 5, 4]);
    expect(p.baseline, [1, 2, 3]); // last 3 on/before the start, oldest first
    expect(p.due, isTrue);
    expect(p.day, 3);
    expect(p.improved, isTrue); // 4.33 vs 2.0
  });

  test('Day N of 3 starts at Day 1 on the start day', () {
    expect(experimentProgress(exp, 'mindset', [day('2026-10-05', 3)]).day, 1);
    final two = experimentProgress(exp, 'mindset', [day('2026-10-06', 3)]);
    expect(two.day, 2);
    expect(two.due, isFalse);
  });

  test('a lift under half a point is not "improved"; no baseline needs 4+', () {
    final flat = experimentProgress(exp, 'mindset', [
      day('2026-10-04', 3),
      day('2026-10-06', 3),
      day('2026-10-07', 3),
      day('2026-10-08', 4),
    ]);
    expect(flat.improved, isFalse); // 3.33 vs 3.0
    final noBase = experimentProgress(exp, 'mindset', [
      day('2026-10-06', 4),
      day('2026-10-07', 4),
      day('2026-10-08', 4),
    ]);
    expect(noBase.baseline, isEmpty);
    expect(noBase.improved, isTrue);
  });

  test('dueExperiments picks only habits whose window is complete', () {
    GoldenHabit habit(String id, HabitExperiment? e) => GoldenHabit.fromJson({
          'habitId': id,
          'habitName': id,
          'coreId': 'mindset_core',
          'experiment': e?.toJson(),
        });
    final checkins = [day('2026-10-06', 3), day('2026-10-07', 3), day('2026-10-08', 3)];
    final due = dueExperiments(
      [habit('a', exp), habit('b', null)],
      checkins,
      (c) => c.replaceAll('_core', ''),
    );
    expect(due.map((h) => h.habitId), ['a']);
    expect(dueExperiments([habit('a', exp)], checkins.take(2).toList(), (c) => 'mindset'), isEmpty);
  });

  test('model round-trips the experiment and retired strategies', () {
    final h = GoldenHabit.fromJson({
      'habitId': 'h',
      'habitName': 'Walk',
      'experiment': exp.toJson(),
      'retiredStrategies': ['5am', ' ', 'Alarm'],
    });
    expect(h.experiment!.changes['when']!.to, '6am');
    expect(h.retiredStrategies, ['5am', 'Alarm']);
    expect(GoldenHabit.fromJson(h.toJson()).experiment!.id, 'e1');
    expect(h.copyWith(clearExperiment: true).experiment, isNull);
    expect(HabitExperiment.tryParse({'id': ''}), isNull);
    expect(HabitExperiment.tryParse(null), isNull);
  });
}
