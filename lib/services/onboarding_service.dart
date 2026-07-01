import '../config/api_config.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// The forged Golden Habit, for the Stage 1 confirm card. Populated once the
/// Voiceflow agent has persisted the habit (`forged == true`).
class OnboardingFields {
  const OnboardingFields({
    required this.core,
    required this.coreLabel,
    required this.habitName,
    required this.when,
    required this.where,
    required this.what,
    required this.ifThen,
    required this.why,
  });

  final String core;
  final String coreLabel;
  final String habitName;
  final String when;
  final String where;
  final String what;
  final String ifThen;
  final String why;

  factory OnboardingFields.fromJson(Map<String, dynamic> j) => OnboardingFields(
        core: (j['core'] ?? '').toString(),
        coreLabel: (j['coreLabel'] ?? '').toString(),
        habitName: (j['habitName'] ?? '').toString(),
        when: (j['when'] ?? '').toString(),
        where: (j['where'] ?? '').toString(),
        what: (j['what'] ?? '').toString(),
        ifThen: (j['ifThen'] ?? '').toString(),
        why: (j['why'] ?? '').toString(),
      );
}

/// Read-only snapshot of HHS Stage 1 progress.
///
/// The Voiceflow agent owns the conversation, awards the per-section MP, and
/// persists the Golden Habit on a clean finish. This just reports what the
/// agent has done so the cockpit can advance the pyramid + celebrate.
class OnboardingSync {
  const OnboardingSync({
    required this.available,
    required this.completedCount,
    required this.forged,
    required this.reachedForge,
    required this.totalPoints,
    required this.fields,
  });

  final bool available; // false until the agent has awarded anything
  final int completedCount; // 0–5 sections done (from cumulative MP)
  final bool forged; // a Golden Habit doc now exists
  // True once the agent has narrated forge/Level-1-complete in the transcript,
  // even if no habit doc was written and the +25 Keystone award was skipped
  // (so MP-derived completedCount caps at 4). Drives Stage-1 completion.
  final bool reachedForge;
  final int totalPoints;
  final OnboardingFields? fields;

  bool get stage1Done => forged || reachedForge;

  factory OnboardingSync.fromJson(Map<String, dynamic> j) => OnboardingSync(
        available: j['available'] == true,
        completedCount: (j['completedCount'] as num? ?? 0).toInt().clamp(0, 5),
        forged: j['forged'] == true,
        reachedForge: j['reachedForge'] == true,
        totalPoints: (j['totalPoints'] as num? ?? 0).toInt(),
        fields: j['fields'] is Map
            ? OnboardingFields.fromJson(
                (j['fields'] as Map).cast<String, dynamic>())
            : null,
      );

  static const empty = OnboardingSync(
    available: false,
    completedCount: 0,
    forged: false,
    reachedForge: false,
    totalPoints: 0,
    fields: null,
  );
}

/// The active (most-recently forged) Golden Habit, used to drive Stage 2 MBS:
/// its real fields personalize the Momentum-Method suggestions and the
/// momentify call targets it by `habitId`.
class ActiveHabit {
  const ActiveHabit({
    required this.habitId,
    required this.habitName,
    required this.coreLabel,
    required this.when,
    required this.where,
    required this.what,
    required this.obstacleIf,
    required this.obstacleThen,
  });

  final String habitId;
  final String habitName;
  final String coreLabel;
  final String when;
  final String where;
  final String what;
  final String obstacleIf;
  final String obstacleThen;

  factory ActiveHabit.fromJson(Map<String, dynamic> j) => ActiveHabit(
        habitId: (j['habitId'] ?? '').toString(),
        habitName: (j['habitName'] ?? '').toString(),
        coreLabel: (j['coreLabel'] ?? '').toString(),
        when: (j['when'] ?? '').toString(),
        where: (j['where'] ?? '').toString(),
        what: (j['what'] ?? '').toString(),
        obstacleIf: (j['obstacleIf'] ?? '').toString(),
        obstacleThen: (j['obstacleThen'] ?? '').toString(),
      );
}

/// Lightweight reference to a Golden Habit, keyed to the SHORT core id the
/// check-in / dashboard use. Used by Mission Control to flag the right habit
/// and by the Go-Deeper bridge to pre-load it.
class GoldenHabitRef {
  const GoldenHabitRef({
    required this.habitId,
    required this.shortCoreId,
    required this.habitName,
    required this.flagged,
    required this.flagReason,
  });

  final String habitId;
  final String shortCoreId;
  final String habitName;
  final bool flagged;
  final String flagReason;

  /// Golden Habits store coreId in long form (`physical_health_core`); the
  /// check-in/dashboard key Cores by short id (`physical`). Map long → short.
  static const _shortCoreByLong = {
    'mindset_core': 'mindset',
    'career_finance_core': 'career',
    'physical_health_core': 'physical',
    'emotional_mental_core': 'emotional',
    'relationships_core': 'relationships',
  };
  static const _validShort = {
    'mindset', 'career', 'physical', 'emotional', 'relationships'
  };

  static String shortCore(String raw) {
    final r = raw.trim();
    if (_shortCoreByLong.containsKey(r)) return _shortCoreByLong[r]!;
    if (_validShort.contains(r)) return r;
    return r;
  }

  factory GoldenHabitRef.fromJson(Map<String, dynamic> j) => GoldenHabitRef(
        habitId: (j['habitId'] ?? '').toString(),
        shortCoreId: shortCore((j['coreId'] ?? '').toString()),
        habitName: (j['habitName'] ?? '').toString(),
        flagged: j['flagged'] == true,
        flagReason: (j['flagReason'] ?? '').toString(),
      );
}

/// Reads HHS Stage 1 progress (`flutterSyncOnboarding`, "flutter" codebase).
class OnboardingService {
  OnboardingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl =
      'https://us-central1-momentum-bce49.cloudfunctions.net';
  static const String _secret = ApiConfig.secret;

  /// Safe to call after every turn — returns [OnboardingSync.empty] on any
  /// failure so a transient error never blocks the conversation.
  Future<OnboardingSync> sync(String userId) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/flutterSyncOnboarding'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'secret': _secret, 'userId': userId}),
      );
      if (response.statusCode != 200) return OnboardingSync.empty;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
        return OnboardingSync.empty;
      }
      return OnboardingSync.fromJson(decoded);
    } catch (_) {
      return OnboardingSync.empty;
    }
  }

  /// Asks the backend to reconstruct the Golden Habit from the chat transcript
  /// and persist it (`flutterForgeFromTranscript`) when the agent reached the
  /// forge stage but never wrote the `golden_habits` doc itself. Idempotent and
  /// best-effort — returns true only if a habit doc now exists. Safe to call
  /// once per session; the caller re-[sync]s afterwards to pick up the fields.
  Future<bool> forgeFromTranscript(String userId) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/flutterForgeFromTranscript'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'secret': _secret, 'userId': userId}),
      );
      if (response.statusCode != 200) return false;
      final decoded = jsonDecode(response.body);
      return decoded is Map && decoded['forged'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Fetches the active (newest) Golden Habit for Stage 2 MBS, or null if none
  /// exists yet / on any failure. Reads `flutterGetGoldenHabits` (newest first).
  Future<ActiveHabit?> activeHabit(String userId) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/flutterGetGoldenHabits'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'secret': _secret, 'userId': userId}),
      );
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['ok'] != true) return null;
      final habits = decoded['habits'];
      if (habits is! List || habits.isEmpty) return null;
      return ActiveHabit.fromJson((habits.first as Map).cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  /// Persists the Stage 2 Momentum-Method picks + IF-THEN onto the active
  /// Golden Habit and awards the three Stage-2 badges once (server-idempotent).
  /// Returns true on a successful save. Best-effort: a failure must not trap the
  /// player mid-flow (the caller still completes Stage 2 — the next save
  /// reconciles), mirroring the Phase 1 persistence philosophy.
  Future<bool> saveMomentumMethods({
    required String userId,
    String? habitId,
    required String makeObvious,
    required String makeEasy,
    required String makeRewarding,
    required String obstacleIf,
    required String obstacleThen,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/flutterSaveMomentumMethods'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'secret': _secret,
          'userId': userId,
          if (habitId != null && habitId.isNotEmpty) 'habitId': habitId,
          'makeObvious': makeObvious,
          'makeEasy': makeEasy,
          'makeRewarding': makeRewarding,
          'obstacleIf': obstacleIf,
          'obstacleThen': obstacleThen,
        }),
      );
      if (response.statusCode != 200) return false;
      final decoded = jsonDecode(response.body);
      return decoded is Map && decoded['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  /// All Golden Habits as light refs (newest first), keyed off the short core
  /// id. Returns an empty list on any failure (Mission Control degrades to a
  /// display-only intervention rather than blocking the check-in).
  Future<List<GoldenHabitRef>> goldenHabits(String userId) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/flutterGetGoldenHabits'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'secret': _secret, 'userId': userId}),
      );
      if (response.statusCode != 200) return const [];
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['ok'] != true) return const [];
      final habits = decoded['habits'];
      if (habits is! List) return const [];
      return habits
          .whereType<Map>()
          .map((m) => GoldenHabitRef.fromJson(m.cast<String, dynamic>()))
          .where((h) => h.habitId.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Fetches one Golden Habit by id (for the Go-Deeper pre-load), or null.
  Future<ActiveHabit?> habitById(String userId, String habitId) async {
    if (habitId.isEmpty) return null;
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/flutterGetGoldenHabits'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'secret': _secret, 'userId': userId, 'habitId': habitId}),
      );
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['ok'] != true) return null;
      final habit = decoded['habit'];
      if (habit is! Map) return null;
      return ActiveHabit.fromJson(habit.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  /// Flags / un-flags a Golden Habit for refinement (`flutterFlagGoldenHabit`).
  /// Anti-shame by design: a flag means "this needs adjusting," not failure. The
  /// endpoint merges the flag fields + appends a `flag_history` entry. Returns
  /// true on success; best-effort so a network blip never traps the player.
  Future<bool> flagGoldenHabit({
    required String userId,
    required String habitId,
    required bool flagged,
    String reason = '',
    String note = '',
  }) async {
    if (habitId.isEmpty) return false;
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/flutterFlagGoldenHabit'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'secret': _secret,
          'userId': userId,
          'habitId': habitId,
          'flagged': flagged,
          if (reason.isNotEmpty) 'flagReason': reason,
          if (note.isNotEmpty) 'flagNote': note,
        }),
      );
      if (response.statusCode != 200) return false;
      final decoded = jsonDecode(response.body);
      return decoded is Map && decoded['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  void dispose() => _client.close();
}
