import '../config/api_config.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/golden_habit.dart';
import 'checkin_service.dart';
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
  /// the Habits screen — not just the Routines list. This mirrors the Claude
  /// HHS agent, which dual-writes every Golden Habit to BOTH `golden_habits` (rich
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

  /// #22 Detailed Habit View: saves only the changed [fields] (keys from
  /// [GoldenHabit.editableKeys]) via `flutterUpdateGoldenHabitDetail`, which
  /// also renames the Core's list line when the name changes. Throws on
  /// failure.
  ///
  /// [experiment] (`source`, optional `title` / `hypothesis`) makes a change
  /// to the habit's mechanics a 🧪 experiment (#23) starting today; the
  /// returned [HabitExperiment] is the habit's active one (null when none).
  Future<HabitExperiment?> updateHabitDetail({
    required String userId,
    required String habitId,
    required Map<String, String> fields,
    Map<String, String>? experiment,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/flutterUpdateGoldenHabitDetail'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'secret': _secret,
        'userId': userId,
        'habitId': habitId,
        'fields': fields,
        if (experiment != null)
          'experiment': {
            ...experiment,
            'day': CheckinService.dayId(DateTime.now()),
          },
      }),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode != 200 ||
        decoded is! Map<String, dynamic> ||
        decoded['ok'] != true) {
      throw Exception(
        'flutterUpdateGoldenHabitDetail failed '
        '(${response.statusCode}): ${response.body}',
      );
    }
    return HabitExperiment.tryParse(decoded['experiment']);
  }

  /// 🚀 Quick Suggestion (#23): Nova reads the habit, its Momentum Lists,
  /// Captain's Log and retired strategies (`flutterQuickSuggestion`) and
  /// proposes 1–2 tweaks. Nothing is saved — accept one with
  /// [updateHabitDetail] + `experiment: {'source': 'quick', …}`.
  Future<QuickSuggestion> quickSuggestion({
    required String userId,
    required String habitId,
    String note = '',
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/flutterQuickSuggestion'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'secret': _secret,
        'userId': userId,
        'habitId': habitId,
        'note': note,
      }),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode != 200 ||
        decoded is! Map<String, dynamic> ||
        decoded['ok'] != true) {
      throw Exception(
        'flutterQuickSuggestion failed '
        '(${response.statusCode}): ${response.body}',
      );
    }
    return QuickSuggestion.fromJson(decoded);
  }

  /// Keeps (`keep`) or retires (`retire`) the habit's active 🧪 experiment
  /// via `flutterResolveExperiment`. Retiring restores the old values.
  Future<void> resolveExperiment({
    required String userId,
    required String habitId,
    required String experimentId,
    required String outcome,
    String learnings = '',
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/flutterResolveExperiment'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'secret': _secret,
        'userId': userId,
        'habitId': habitId,
        'experimentId': experimentId,
        'outcome': outcome,
        'learnings': learnings,
      }),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode != 200 ||
        decoded is! Map<String, dynamic> ||
        decoded['ok'] != true) {
      throw Exception(
        'flutterResolveExperiment failed '
        '(${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Routine ↔ Non-Routine reclassification (§4E) via
  /// `flutterReclassifyGoldenHabit`: switches the type, records the audit
  /// entry, flags the MBMs for review and moves the habit's list line.
  /// [to] is 'routine' or 'non_routine'. Throws on failure.
  Future<void> reclassifyHabit({
    required String userId,
    required String habitId,
    required String to,
    String reason = '',
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/flutterReclassifyGoldenHabit'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'secret': _secret,
        'userId': userId,
        'habitId': habitId,
        'to': to,
        'source': 'player',
        'reason': reason,
      }),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode != 200 ||
        decoded is! Map<String, dynamic> ||
        decoded['ok'] != true) {
      throw Exception(
        'flutterReclassifyGoldenHabit failed '
        '(${response.statusCode}): ${response.body}',
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

  List<GoldenHabit> _parse(List<dynamic> list) =>
      list
          .whereType<Map>()
          .map((m) => GoldenHabit.fromJson(m.cast<String, dynamic>()))
          .toList();

  void dispose() => _client.close();
}

/// One proposed change in a [QuickSuggestion].
class SuggestedTweak {
  const SuggestedTweak({
    required this.field,
    required this.label,
    required this.from,
    required this.to,
    this.why = '',
  });

  final String field;
  final String label;
  final String from;
  final String to;
  final String why;
}

/// Nova's Quick Suggestion: what it saw, the friction point, and 1–2 tweaks.
class QuickSuggestion {
  const QuickSuggestion({
    required this.diagnosis,
    required this.title,
    required this.hypothesis,
    required this.dataPoints,
    required this.tweaks,
  });

  final String diagnosis;
  final String title;
  final String hypothesis;
  final List<({String source, String text})> dataPoints;
  final List<SuggestedTweak> tweaks;

  factory QuickSuggestion.fromJson(Map<String, dynamic> j) => QuickSuggestion(
    diagnosis: '${j['diagnosis'] ?? ''}',
    title: '${j['title'] ?? ''}',
    hypothesis: '${j['hypothesis'] ?? ''}',
    dataPoints: [
      if (j['dataPoints'] case final List list)
        for (final d in list)
          if (d is Map) (source: '${d['source'] ?? ''}', text: '${d['text'] ?? ''}'),
    ],
    tweaks: [
      if (j['tweaks'] case final List list)
        for (final t in list)
          if (t is Map)
            SuggestedTweak(
              field: '${t['field'] ?? ''}',
              label: '${t['label'] ?? t['field'] ?? ''}',
              from: '${t['from'] ?? ''}',
              to: '${t['to'] ?? ''}',
              why: '${t['why'] ?? ''}',
            ),
    ],
  );
}
