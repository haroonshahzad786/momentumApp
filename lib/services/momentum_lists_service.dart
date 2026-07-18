import '../config/api_config.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/momentum_list.dart';
import 'offline.dart';

/// Reads the user's Momentum Lists via the existing `fetchAllMomentumLists`
/// endpoint in the default codebase (deployed for FlutterFlow but read-only
/// reuse from Flutter is fine per the backend isolation rule).
class MomentumListsService {
  MomentumListsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl =
      'https://us-central1-momentum-bce49.cloudfunctions.net';
  static const String _secret = ApiConfig.secret;

  /// Momentum Lists with offline fallback — on a network failure the last-good
  /// payload from disk is returned with `fromCache: true`.
  Future<Fetched<List<MomentumList>>> getAllLists(String userId) async {
    final cacheKey = 'cache:momentum_lists:$userId';
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/fetchAllMomentumLists'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'secret': _secret, 'userId': userId}),
      );
      if (response.statusCode != 200) {
        throw Exception(
          'fetchAllMomentumLists failed (${response.statusCode}): ${response.body}',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('fetchAllMomentumLists returned non-JSON-object');
      }
      if (decoded['ok'] != true) {
        throw Exception(
          'fetchAllMomentumLists error: ${decoded['error'] ?? 'unknown'}',
        );
      }
      final raw = decoded['lists'] as List? ?? const [];
      await LocalCache.putJson(cacheKey, raw);
      return Fetched(_parse(raw), fromCache: false);
    } catch (e) {
      if (isNetworkError(e)) {
        final cached = await LocalCache.getJson(cacheKey);
        if (cached is List) return Fetched(_parse(cached), fromCache: true);
      }
      rethrow;
    }
  }

  List<MomentumList> _parse(List<dynamic> raw) => raw
      .whereType<Map>()
      .map((m) => MomentumList.fromJson(m.cast<String, dynamic>()))
      .toList();

  /// Appends a single item to the named Momentum List (creating the list if it
  /// doesn't exist yet), preserving the existing items. Used by the Cantina
  /// Ideas Well "adopt" flow to file a Tech/App pick into the user's list.
  /// Skips an exact-duplicate line.
  Future<void> appendItem(String userId, String listName, String item) async {
    final trimmed = item.trim();
    if (trimmed.isEmpty) return;
    final current = await getAllLists(userId);
    final existing = current.data.firstWhere(
      (l) => l.name.trim().toLowerCase() == listName.trim().toLowerCase(),
      orElse: () => MomentumList(name: listName, items: const []),
    );
    if (existing.items
        .any((i) => i.trim().toLowerCase() == trimmed.toLowerCase())) {
      return; // already there
    }
    await saveList(userId, existing.name, [...existing.items, trimmed]);
  }

  /// Persists the full item set for one Momentum List (create-or-replace).
  /// Reuses the existing `UpdateMomentumList` endpoint in the default codebase
  /// — the same "reuse a deployed write endpoint" pattern as
  /// `CoreListsService.addHabit` (`saveCoreListItems`), so no new backend is
  /// added. The endpoint merge-writes `{ name, items[] }` to
  /// `/users/{uid}/momentum_lists/{listName}` (doc id = list name) and accepts
  /// `ItemsCSV` as an array (commas inside an item are preserved).
  ///
  /// After a successful write the local cache is refreshed so an offline reopen
  /// shows the edit.
  Future<void> saveList(
    String userId,
    String name,
    List<String> items,
  ) async {
    final cleaned = items.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final response = await _client.post(
      Uri.parse('$_baseUrl/UpdateMomentumList'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'secret': _secret,
        'ff_uid': userId,
        'ListName': name.trim(),
        'ItemsCSV': cleaned,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'UpdateMomentumList failed (${response.statusCode}): ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw Exception(
        'UpdateMomentumList error: '
        '${decoded is Map ? decoded['error'] ?? 'unknown' : 'bad response'}',
      );
    }

    // Keep the offline cache in sync so a reopen (or offline reload) reflects
    // the edit without waiting for the next network fetch.
    final cacheKey = 'cache:momentum_lists:$userId';
    final cached = await LocalCache.getJson(cacheKey);
    final list = (cached is List) ? [...cached] : <dynamic>[];
    final entry = {'name': name.trim(), 'items': cleaned};
    final idx = list.indexWhere(
      (e) => e is Map && (e['name'] ?? '').toString() == name.trim(),
    );
    if (idx >= 0) {
      list[idx] = entry;
    } else {
      list.add(entry);
    }
    await LocalCache.putJson(cacheKey, list);
  }

  void dispose() => _client.close();
}
