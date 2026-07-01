import '../config/api_config.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/core_list.dart';
import 'offline.dart';

/// Routine vs non-routine habit lists, split by [CoreListsService.getRoutineData].
class RoutineData {
  const RoutineData({required this.routine, required this.nonRoutine});
  final List<CoreList> routine;
  final List<CoreList> nonRoutine;
}

/// Reads the user's per-core lists via the existing `fetchAllCoreListItems`
/// endpoint in the default codebase (the one the HHS / `saveCoreListItems`
/// flow writes to). Read-only reuse from Flutter is fine per the backend
/// isolation rule — no new endpoint needed.
class CoreListsService {
  CoreListsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl =
      'https://us-central1-momentum-bce49.cloudfunctions.net';
  static const String _secret = ApiConfig.secret;

  String _coresCacheKey(String userId) => 'cache:core_lists:$userId';

  /// The raw `cores` array straight from the endpoint (before flattening).
  Future<List<dynamic>> _fetchCoresRaw(String userId) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/fetchAllCoreListItems'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'secret': _secret, 'userId': userId}),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'fetchAllCoreListItems failed (${response.statusCode}): ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('fetchAllCoreListItems returned non-JSON-object');
    }
    if (decoded['ok'] != true) {
      throw Exception(
        'fetchAllCoreListItems error: ${decoded['error'] ?? 'unknown'}',
      );
    }
    return decoded['cores'] as List? ?? const [];
  }

  /// All lists across every core/category, flattened. Network-only (used by the
  /// write flow, which must see fresh data); reads use the cached variants.
  Future<List<CoreList>> getAll(String userId) async =>
      CoreList.flattenFromResponse(await _fetchCoresRaw(userId));

  /// The "Routines List" doc from each core that has one (non-empty).
  Future<List<CoreList>> getRoutines(String userId) async {
    final all = await getAll(userId);
    return all
        .where((l) => l.name.toLowerCase() == 'routines list' && l.items.isNotEmpty)
        .toList();
  }

  /// Both habit lists the Golden-Habit Forge writes per core, split by type.
  ///   • routine    → "Routines List" docs (the daily schedule / sea-of-green)
  ///   • nonRoutine → "Non-Routine" docs (identity habits → Trophy Room)
  /// Offline fallback: on a network failure the last-good payload from disk is
  /// returned with `fromCache: true` so the Routines screen shows saved data.
  Future<Fetched<RoutineData>> getRoutineData(String userId) async {
    final cacheKey = _coresCacheKey(userId);
    try {
      final cores = await _fetchCoresRaw(userId);
      await LocalCache.putJson(cacheKey, cores);
      return Fetched(_split(CoreList.flattenFromResponse(cores)),
          fromCache: false);
    } catch (e) {
      if (isNetworkError(e)) {
        final cached = await LocalCache.getJson(cacheKey);
        if (cached is List) {
          return Fetched(_split(CoreList.flattenFromResponse(cached)),
              fromCache: true);
        }
      }
      rethrow;
    }
  }

  RoutineData _split(List<CoreList> all) {
    bool named(CoreList l, String n) => l.name.trim().toLowerCase() == n;
    return RoutineData(
      routine: all
          .where((l) => named(l, 'routines list') && l.items.isNotEmpty)
          .toList(),
      nonRoutine: all
          .where((l) => named(l, 'non-routine') && l.items.isNotEmpty)
          .toList(),
    );
  }

  /// Appends a single habit line to the user's per-core list and persists it,
  /// so the new routine is trackable in future sessions (and by the Routines
  /// screen's stage pipeline). Writes via the existing `saveCoreListItems`
  /// endpoint — the same per-core path the Voiceflow HHS flow uses:
  ///   /users/{uid}/core/{coreId}/golden_habit/{listName}
  ///
  ///   • isRoutine == true  → list "Routines List"
  ///   • isRoutine == false → list "Non-Routine"
  ///
  /// `saveCoreListItems` does `set({items}, {merge:true})`, which REPLACES the
  /// items array — so we first read the current items for the target list and
  /// send the full list back with [itemLine] appended. The exact stored list
  /// name is reused when one already exists (avoids creating a parallel doc
  /// under a different casing). Items are sent as an array, so commas in the
  /// habit text are preserved (the endpoint only comma-splits CSV strings).
  Future<void> addHabit({
    required String userId,
    required String coreId,
    required bool isRoutine,
    required String itemLine,
  }) async {
    final defaultName = isRoutine ? 'Routines List' : 'Non-Routine';
    final targetName = defaultName.toLowerCase();

    // Read current state so we don't clobber existing items on the replace.
    final all = await getAll(userId);
    CoreList? existing;
    for (final l in all) {
      if (l.coreId == coreId && l.name.trim().toLowerCase() == targetName) {
        existing = l;
        break;
      }
    }
    final listName = existing?.name ?? defaultName;
    final items = <String>[...?existing?.items];

    // Skip an exact duplicate line; otherwise append.
    final trimmed = itemLine.trim();
    if (!items.any((i) => i.trim().toLowerCase() == trimmed.toLowerCase())) {
      items.add(trimmed);
    }

    final response = await _client.post(
      Uri.parse('$_baseUrl/saveCoreListItems'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'secret': _secret,
        'userId': userId,
        'core': coreId, // full id is accepted by the endpoint's coreNameToId
        'category': 'Golden Habit', // → golden_habit
        'listName': listName,
        'items': items,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'saveCoreListItems failed (${response.statusCode}): ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw Exception(
        'saveCoreListItems error: '
        '${decoded is Map ? decoded['error'] ?? 'unknown' : 'bad response'}',
      );
    }
  }

  void dispose() => _client.close();
}
