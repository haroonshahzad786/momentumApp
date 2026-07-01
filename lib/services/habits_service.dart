import '../config/api_config.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/golden_habit.dart';
import 'offline.dart';

/// Reads the user's Golden Habits from Firebase Functions (codebase "flutter").
/// Backed by `flutterGetGoldenHabits`, which reads
/// `/users/{uid}/golden_habits`.
class HabitsService {
  HabitsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl =
      'https://us-central1-momentum-bce49.cloudfunctions.net';
  static const String _secret = ApiConfig.secret;

  /// Creates a (minimal) structured Golden Habit so the new habit appears in
  /// the Habits screen — not just the Routines list. This mirrors the Voiceflow
  /// HHS, which dual-writes every Golden Habit to BOTH `golden_habits` (rich
  /// object, read here) and the per-core "Routines List"/"Non-Routine" list
  /// (read by the Routines screen). The quick-add page only captures the
  /// essentials; cue / MBM / IF-THEN are filled later by the Golden Habit Forge.
  ///
  /// Writes via the existing `saveGoldenHabit` endpoint (same read/write reuse
  /// precedent as the core-list endpoints — no backend change). A UNIQUE
  /// [habitId] is always sent so this can never merge-overwrite an existing
  /// rich Golden Habit that happens to share a name (saveGoldenHabit blanks
  /// unspecified fields on merge).
  Future<void> addGoldenHabit({
    required String userId,
    required String coreId,
    required String habitName,
    required bool isRoutine,
    String? when,
  }) async {
    final slug = habitName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 _-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final habitId =
        'gh_${slug.isEmpty ? 'habit' : slug}_${DateTime.now().millisecondsSinceEpoch}';

    final response = await _client.post(
      Uri.parse('$_baseUrl/saveGoldenHabit'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'secret': _secret,
        'userId': userId,
        'core': coreId, // full id accepted by coreNameToId
        'habitName': habitName,
        'habitId': habitId,
        'habitType': isRoutine ? 'routine' : 'non_routine',
        if (when != null && when.isNotEmpty) 'when': when,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'saveGoldenHabit failed (${response.statusCode}): ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw Exception(
        'saveGoldenHabit error: '
        '${decoded is Map ? decoded['error'] ?? 'unknown' : 'bad response'}',
      );
    }
  }

  /// Persists an edit to an existing Golden Habit. The detail screen only lets
  /// the player tweak the core mechanics (name / what / where / when / cue /
  /// IF-THEN / MVA), but `saveGoldenHabit` rewrites the WHOLE doc on merge and
  /// blanks any field it doesn't receive — so we send EVERY field from the
  /// (already-edited) [habit], preserving the Forge-authored context (pain
  /// point, BTTF, why-it-works, etc.) that isn't editable here.
  ///
  /// Reuses the existing `saveGoldenHabit` endpoint (same precedent as
  /// [addGoldenHabit]); no backend change required.
  Future<void> updateGoldenHabit({
    required String userId,
    required GoldenHabit habit,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/saveGoldenHabit'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'secret': _secret,
        'userId': userId,
        'core': habit.coreId,
        'habitId': habit.habitId,
        'habitName': habit.habitName,
        'painPoint': habit.painPoint,
        'backToFutureIdentity': habit.backToFutureIdentity,
        'coreDimension': habit.coreDimension,
        'habitType': habit.habitType,
        'where': habit.where,
        'when': habit.when,
        'what': habit.what,
        'cueType': habit.cueType,
        'trigger': habit.trigger,
        'anchorReminder': habit.anchorReminder,
        'obstacleIf': habit.obstacleIf,
        'obstacleThen': habit.obstacleThen,
        'whyWant': habit.whyWant,
        'whyCan': habit.whyCan,
        'whyEffective': habit.whyEffective,
        'startingVersion': habit.startingVersion,
        'displayText': habit.displayText,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'saveGoldenHabit failed (${response.statusCode}): ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw Exception(
        'saveGoldenHabit error: '
        '${decoded is Map ? decoded['error'] ?? 'unknown' : 'bad response'}',
      );
    }
  }

  /// Flags (or un-flags) a Golden Habit for refinement. The flag is data, not
  /// failure — the Co-pilot pattern-matches the reason/note to suggest a tweak.
  /// Persisted by the isolated `flutterFlagGoldenHabit` endpoint (Flutter
  /// codebase) so it never touches the FlutterFlow backend.
  Future<void> flagGoldenHabit({
    required String userId,
    required String habitId,
    required bool flagged,
    String reason = '',
    String note = '',
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/flutterFlagGoldenHabit'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'secret': _secret,
        'userId': userId,
        'habitId': habitId,
        'flagged': flagged,
        'flagReason': reason,
        'flagNote': note,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'flutterFlagGoldenHabit failed (${response.statusCode}): ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw Exception(
        'flutterFlagGoldenHabit error: '
        '${decoded is Map ? decoded['error'] ?? 'unknown' : 'bad response'}',
      );
    }
  }

  /// Golden Habits with offline fallback: on a network failure the last-good
  /// payload from disk is returned with `fromCache: true` so the UI can show
  /// saved habits + an offline banner instead of an error screen.
  Future<Fetched<List<GoldenHabit>>> getGoldenHabits(String userId) async {
    final cacheKey = 'cache:golden_habits:$userId';
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/flutterGetGoldenHabits'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'secret': _secret, 'userId': userId}),
      );
      if (response.statusCode != 200) {
        throw Exception(
          'flutterGetGoldenHabits failed (${response.statusCode}): ${response.body}',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('flutterGetGoldenHabits returned non-JSON-object');
      }
      if (decoded['ok'] != true) {
        throw Exception(
          'flutterGetGoldenHabits error: ${decoded['error'] ?? 'unknown'}',
        );
      }
      final list = decoded['habits'];
      final rawList = list is List ? list : const [];
      await LocalCache.putJson(cacheKey, rawList);
      return Fetched(_parse(rawList), fromCache: false);
    } catch (e) {
      if (isNetworkError(e)) {
        final cached = await LocalCache.getJson(cacheKey);
        if (cached is List) {
          return Fetched(_parse(cached), fromCache: true);
        }
      }
      rethrow;
    }
  }

  List<GoldenHabit> _parse(List<dynamic> list) => list
      .whereType<Map>()
      .map((m) => GoldenHabit.fromJson(m.cast<String, dynamic>()))
      .toList();

  void dispose() => _client.close();
}
