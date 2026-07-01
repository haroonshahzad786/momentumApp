import 'phase1_state.dart';

/// Dashboard-facing view of a user's state, returned by
/// `flutterGetUserProfile` in the Firebase Functions "flutter" codebase.
class UserProfile {
  const UserProfile({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.momentumScore,
    required this.streak,
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
  final int streak;
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
        streak: (json['streak'] as num? ?? 0).toInt(),
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
