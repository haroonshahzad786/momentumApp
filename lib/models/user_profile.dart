import '../services/formation.dart';
import 'phase1_state.dart';

/// Dashboard-facing view of a user's state, returned by
/// `flutterGetUserProfile` in the Firebase Functions "flutter" codebase.
class UserProfile {
  const UserProfile({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.momentumScore,
    this.spaceCredits = 0,
    required this.streak,
    this.longestStreak = 0,
    this.streakState = 'ok',
    this.lastCheckinDate = '',
    this.missedWeekdays = 0,
    this.missState = 'none',
    this.missPenaltyApplied = 0,
    this.lastCompletedCheckinDate = '',
    this.formedHabitsCount = 0,
    this.streakSavers = 0,
    this.maxStreakSavers = 1,
    this.streakSaverMilestone = 30,
    this.vacationMaxDays = 7,
    this.activeVacation,
    this.upcomingVacation,
    this.formationGoal,
    this.formationGoalsCompleted = 0,
    required this.planet,
    required this.level,
    required this.balance,
    required this.activeCores,
    required this.showMysteryBox,
    required this.stage1Progress,
    required this.stage1Completed,
    required this.stage2Completed,
    required this.phase,
  });

  final String userId;
  final String displayName;
  final String email;
  final int momentumScore;

  /// Space Credits balance (#13a — reward currency).
  final int spaceCredits;

  /// Effective current streak (#10): consecutive qualifying weekday check-ins,
  /// already zeroed server-side once 2 weekdays have been missed.
  final int streak;
  final int longestStreak;

  /// 'ok' · 'warning' (1 weekday missed — grace active) · 'protected' (a
  /// Streak Saver covers the gap; spent on the next check-in) · 'vacation'
  /// (Vacation Mode on) · 'broken' (gap too big).
  final String streakState;
  final String lastCheckinDate;

  /// #16 missed check-ins — weekdays missed since the last *completed*
  /// check-in (any score). 'none' (never checked in) · 'ok' · 'warning'
  /// (1 missed) · 'relaunch' (2+) · 'long_absence' (5+).
  final int missedWeekdays;
  final String missState;

  /// Momentum Points removed by this profile load's relaunch penalty (0 unless
  /// an admin configured `config/streaks.missPenaltyPoints`).
  final int missPenaltyApplied;
  final String lastCompletedCheckinDate;

  /// Habits moved to the Trophy Room (mirrored server-side).
  final int formedHabitsCount;

  /// #17 Streak Savers held (earned at the [streakSaverMilestone]-day
  /// milestone, capped at [maxStreakSavers]) — spent automatically.
  final int streakSavers;
  final int maxStreakSavers;
  final int streakSaverMilestone;

  /// #17 Vacation Mode — at most [vacationMaxDays] days; the vacation covering
  /// today and the next planned one (either may be null).
  final int vacationMaxDays;
  final VacationRange? activeVacation;
  final VacationRange? upcomingVacation;

  /// #19 Habit Formation Goal (null = not set yet) + goals hit so far.
  final FormationGoal? formationGoal;
  final int formationGoalsCompleted;

  bool get onVacation => activeVacation != null || missState == 'vacation';

  bool get needsRelaunch =>
      missState == 'relaunch' || missState == 'long_absence';

  final String planet;
  final String level;
  final int balance;
  final List<String> activeCores;
  final bool showMysteryBox;

  // Persisted Phase 1 onboarding state. `phase` is 'build' until both stages
  // complete, then 'daily'.
  final int stage1Progress;
  final bool stage1Completed;
  final bool stage2Completed;
  final String phase;

  /// The Phase 1 progress the cockpit seeds its local state from on launch.
  Phase1State get phase1State => Phase1State(
        stage1Progress: stage1Progress,
        stage1Completed: stage1Completed,
        stage2Completed: stage2Completed,
      );

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        userId: (json['userId'] ?? '').toString(),
        displayName: (json['displayName'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        momentumScore: (json['momentumScore'] as num? ?? 0).toInt(),
        spaceCredits: (json['spaceCredits'] as num? ?? 0).toInt(),
        streak: (json['streak'] as num? ?? 0).toInt(),
        longestStreak: (json['longestStreak'] as num? ?? 0).toInt(),
        streakState: (json['streakState'] ?? 'ok').toString(),
        lastCheckinDate: (json['lastCheckinDate'] ?? '').toString(),
        missedWeekdays: (json['missedWeekdays'] as num? ?? 0).toInt(),
        missState: (json['missState'] ?? 'none').toString(),
        missPenaltyApplied: (json['missPenaltyApplied'] as num? ?? 0).toInt(),
        lastCompletedCheckinDate:
            (json['lastCompletedCheckinDate'] ?? '').toString(),
        formedHabitsCount: (json['formedHabitsCount'] as num? ?? 0).toInt(),
        streakSavers: (json['streakSavers'] as num? ?? 0).toInt(),
        maxStreakSavers: (json['maxStreakSavers'] as num? ?? 1).toInt(),
        streakSaverMilestone:
            (json['streakSaverMilestone'] as num? ?? 30).toInt(),
        vacationMaxDays: (json['vacationMaxDays'] as num? ?? 7).toInt(),
        activeVacation: VacationRange.tryParse(json['activeVacation']),
        upcomingVacation: VacationRange.tryParse(json['upcomingVacation']),
        formationGoal: FormationGoal.tryParse(json['formationGoal']),
        formationGoalsCompleted:
            (json['formationGoalsCompleted'] as num? ?? 0).toInt(),
        planet: (json['planet'] ?? 'earth').toString(),
        level: (json['level'] ?? 'cadet').toString(),
        balance: (json['balance'] as num? ?? 0).toInt(),
        activeCores: (json['activeCores'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        showMysteryBox: json['showMysteryBox'] == true,
        stage1Progress: (json['stage1Progress'] as num? ?? 0).toInt(),
        stage1Completed: json['stage1Completed'] == true,
        stage2Completed: json['stage2Completed'] == true,
        phase: (json['phase'] ?? 'build').toString(),
      );
}

/// An inclusive yyyy-MM-dd date range of Vacation Mode (#17).
class VacationRange {
  const VacationRange(this.start, this.end);

  final String start;
  final String end;

  static final _id = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static VacationRange? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final s = (raw['start'] ?? '').toString();
    final e = (raw['end'] ?? '').toString();
    if (!_id.hasMatch(s) || !_id.hasMatch(e)) return null;
    return VacationRange(s, e);
  }

  /// Calendar days in the range (inclusive).
  int get days =>
      DateTime.parse(end).difference(DateTime.parse(start)).inDays + 1;
}
