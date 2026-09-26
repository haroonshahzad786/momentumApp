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

  /// 'ok' · 'warning' (1 weekday missed — grace active) · 'broken' (2+ missed).
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
