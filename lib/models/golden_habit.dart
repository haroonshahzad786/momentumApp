/// A structured Golden Habit, as written by `saveGoldenHabit` and read back by
/// `flutterGetGoldenHabits` (Firebase Functions "flutter" codebase).
///
/// Stored at `/users/{uid}/golden_habits/{habitId}`. The backend does NOT yet
/// persist tracking fields (`stage`, `streak`, `week`, `daysFormed`), so those
/// default here until a tracking source fills them in.
class GoldenHabit {
  const GoldenHabit({
    required this.habitId,
    required this.habitName,
    required this.coreId,
    required this.coreLabel,
    required this.painPoint,
    required this.backToFutureIdentity,
    required this.coreDimension,
    required this.habitType,
    required this.where,
    required this.when,
    required this.what,
    required this.cueType,
    required this.trigger,
    required this.anchorReminder,
    required this.obstacleIf,
    required this.obstacleThen,
    required this.whyWant,
    required this.whyCan,
    required this.whyEffective,
    required this.startingVersion,
    required this.displayText,
    required this.stage,
    required this.streak,
    required this.week,
    required this.daysFormed,
    this.flagged = false,
    this.flagReason = '',
    this.flagNote = '',
  });

  final String habitId;
  final String habitName;
  final String coreId;
  final String coreLabel;
  final String painPoint;
  final String backToFutureIdentity;
  final String coreDimension;

  /// Normalized to 'routine' | 'non_routine' (backend stores free text like
  /// "Routine Habit").
  final String habitType;
  final String where;
  final String when;
  final String what;
  final String cueType;
  final String trigger;
  final String anchorReminder;
  final String obstacleIf;
  final String obstacleThen;
  final String whyWant;
  final String whyCan;
  final String whyEffective;
  final String startingVersion;
  final String displayText;

  /// One of: bad | forming | mbms | formed | trophy. Defaults to 'forming'.
  final String stage;
  final int streak;
  final List<int> week; // length 7, Mon→Sun, 1 = done
  final int daysFormed;

  /// Player flagged this habit for refinement (anti-shame: "that's data, not
  /// failure"). Persisted by `flutterFlagGoldenHabit`.
  final bool flagged;
  final String flagReason;
  final String flagNote;

  static String _s(dynamic v) => v == null ? '' : v.toString().trim();

  /// Collapses free-text habit type ("Routine Habit", "non_routine", …) to the
  /// 'routine' / 'non_routine' tokens the UI switches on.
  static String _normalizeType(dynamic v) {
    final raw = _s(v).toLowerCase();
    if (raw.contains('non')) return 'non_routine';
    if (raw.contains('routine')) return 'routine';
    return raw;
  }

  static List<int> _week(dynamic v) {
    if (v is List && v.length == 7) {
      return v
          .map((e) => e is num ? e.toInt() : (int.tryParse('$e') ?? 0))
          .toList();
    }
    return const [0, 0, 0, 0, 0, 0, 0];
  }

  factory GoldenHabit.fromJson(Map<String, dynamic> j) {
    final rawStage = _s(j['stage']);
    return GoldenHabit(
      habitId: _s(j['habitId']),
      habitName: _s(j['habitName']),
      coreId: _s(j['coreId']),
      coreLabel: _s(j['coreLabel']),
      painPoint: _s(j['painPoint']),
      backToFutureIdentity: _s(j['backToFutureIdentity']),
      coreDimension: _s(j['coreDimension']),
      habitType: _normalizeType(j['habitType']),
      where: _s(j['where']),
      when: _s(j['when']),
      what: _s(j['what']),
      cueType: _s(j['cueType']),
      trigger: _s(j['trigger']),
      anchorReminder: _s(j['anchorReminder']),
      obstacleIf: _s(j['obstacleIf']),
      obstacleThen: _s(j['obstacleThen']),
      whyWant: _s(j['whyWant']),
      whyCan: _s(j['whyCan']),
      whyEffective: _s(j['whyEffective']),
      startingVersion: _s(j['startingVersion']),
      displayText: _s(j['displayText']),
      // Tracking fields are not stored by saveGoldenHabit yet.
      stage: rawStage.isEmpty ? 'forming' : rawStage,
      streak: (j['streak'] as num? ?? 0).toInt(),
      week: _week(j['week']),
      daysFormed: (j['daysFormed'] as num? ?? 0).toInt(),
      flagged: j['flagged'] == true,
      flagReason: _s(j['flagReason']),
      flagNote: _s(j['flagNote']),
    );
  }

  /// Returns a copy with the given fields overridden. Used by the Habits detail
  /// screen to reflect an edit / flag locally without refetching.
  GoldenHabit copyWith({
    String? habitName,
    String? where,
    String? when,
    String? what,
    String? trigger,
    String? anchorReminder,
    String? obstacleIf,
    String? obstacleThen,
    String? startingVersion,
    bool? flagged,
    String? flagReason,
    String? flagNote,
  }) {
    return GoldenHabit(
      habitId: habitId,
      habitName: habitName ?? this.habitName,
      coreId: coreId,
      coreLabel: coreLabel,
      painPoint: painPoint,
      backToFutureIdentity: backToFutureIdentity,
      coreDimension: coreDimension,
      habitType: habitType,
      where: where ?? this.where,
      when: when ?? this.when,
      what: what ?? this.what,
      cueType: cueType,
      trigger: trigger ?? this.trigger,
      anchorReminder: anchorReminder ?? this.anchorReminder,
      obstacleIf: obstacleIf ?? this.obstacleIf,
      obstacleThen: obstacleThen ?? this.obstacleThen,
      whyWant: whyWant,
      whyCan: whyCan,
      whyEffective: whyEffective,
      startingVersion: startingVersion ?? this.startingVersion,
      displayText: displayText,
      stage: stage,
      streak: streak,
      week: week,
      daysFormed: daysFormed,
      flagged: flagged ?? this.flagged,
      flagReason: flagReason ?? this.flagReason,
      flagNote: flagNote ?? this.flagNote,
    );
  }
}
