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

  void dispose() => _client.close();
}
