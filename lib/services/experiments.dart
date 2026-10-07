import '../models/golden_habit.dart';
import 'checkin_service.dart';

/// 🧪 Experiment progress (#23). Sequence Day 5: "I'll be tracking your next
/// 3 scores. If the 1:30pm window works, we convert. If not, we go deeper."
/// The window is the habit Core's next [experimentLength] check-ins AFTER the
/// start day; the baseline is up to 3 check-ins on or before it.
const experimentLength = 3;

/// A score lift of at least this much (average, 1–5 scale) counts as working.
const _minLift = 0.5;

class ExperimentProgress {
  const ExperimentProgress({
    required this.during,
    required this.baseline,
  });

  /// The Core's scores inside the window, oldest first (≤ 3).
  final List<int> during;

  /// Up to 3 scores before the experiment, oldest first.
  final List<int> baseline;

  int get done => during.length;
  bool get due => done >= experimentLength;

  /// "Day N of 3" — the start day itself shows Day 1 (as in the Sequence's
  /// Day 5 summary), capped at 3.
  int get day => (done + 1).clamp(1, experimentLength);

  double? get duringAvg => _avg(during);
  double? get baselineAvg => _avg(baseline);

  /// True when the window's average beats the baseline by [_minLift]; with no
  /// baseline, an average of 4+ ("Solid") counts.
  bool get improved {
    final d = duringAvg;
    if (d == null) return false;
    final b = baselineAvg;
    return b == null ? d >= 4 : d - b >= _minLift;
  }

  static double? _avg(List<int> xs) =>
      xs.isEmpty ? null : xs.reduce((a, b) => a + b) / xs.length;
}

/// Progress of [e] for a habit in [core] (short id), from [checkins] in any
/// order.
ExperimentProgress experimentProgress(
  HabitExperiment e,
  String core,
  List<DailyCheckin> checkins,
) {
  final scored = [
    for (final c in checkins)
      if (c.scores[core] != null) c,
  ]..sort((a, b) => a.date.compareTo(b.date));
  final during = [
    for (final c in scored)
      if (c.date.compareTo(e.startDay) > 0) c.scores[core]!,
  ].take(experimentLength).toList();
  final before = [
    for (final c in scored)
      if (c.date.compareTo(e.startDay) <= 0) c.scores[core]!,
  ];
  final baseline =
      before.length > 3 ? before.sublist(before.length - 3) : before;
  return ExperimentProgress(during: during, baseline: baseline);
}

/// Labels for the fields an experiment can change.
const experimentFieldLabels = <String, String>{
  'where': 'Where',
  'when': 'When',
  'what': 'What',
  'trigger': 'Cue',
  'anchorReminder': 'Anchor reminder',
  'obstacleIf': 'Obstacle — IF',
  'obstacleThen': 'Obstacle — THEN',
  'startingVersion': 'Starting version',
  'makeObvious': 'Make it Obvious',
  'makeEasy': 'Make it Easy',
  'makeRewarding': 'Make it Rewarding',
};

/// Golden Habits whose experiment has run its 3 check-ins — the ones Nova
/// asks about ("keep it or retire it?").
List<GoldenHabit> dueExperiments(
  List<GoldenHabit> habits,
  List<DailyCheckin> checkins,
  String Function(String coreId) shortCore,
) => [
  for (final h in habits)
    if (h.experiment != null &&
        experimentProgress(h.experiment!, shortCore(h.coreId), checkins).due)
      h,
];
