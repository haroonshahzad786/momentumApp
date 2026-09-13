import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Calls the admin-gated Cloud Functions built per
/// ADMIN_PANEL_BACKEND_PLAN.md (functions-flutter, codebase "flutter").
/// Every call sends the signed-in user's Firebase ID token as
/// `Authorization: Bearer <token>` — NOT the shared secret `ApiConfig` uses
/// for player-facing endpoints. The backend independently verifies the
/// `admin` custom claim server-side and rejects anyone else with 403
/// regardless of what a client sends (§0's `requireAdmin` gate).
class AdminApiService {
  AdminApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'https://us-central1-momentum-bce49.cloudfunctions.net';

  Future<Map<String, String>> _authHeaders() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _get(String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('$_baseUrl/$path').replace(
      queryParameters: (query == null || query.isEmpty) ? null : query,
    );
    final resp = await _client.get(uri, headers: await _authHeaders());
    return _decode(resp);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final resp = await _client.post(
      Uri.parse('$_baseUrl/$path'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    return _decode(resp);
  }

  Map<String, dynamic> _decode(http.Response resp) {
    final Object? decoded;
    try {
      decoded = jsonDecode(resp.body);
    } catch (_) {
      throw Exception('Unexpected response (${resp.statusCode}): ${resp.body}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response shape (${resp.statusCode})');
    }
    if (decoded['ok'] != true) {
      throw Exception(decoded['error']?.toString() ?? 'Request failed (${resp.statusCode})');
    }
    return decoded;
  }

  /// §1 Overview — 5 stat tiles + recent admin actions + needsAttention stub.
  Future<Map<String, dynamic>> getOverview() => _get('adminGetOverview');

  /// §2 Clients list — paginated/searchable.
  Future<Map<String, dynamic>> listClients({
    String? search,
    String? level,
    int limit = 100,
    String? cursor,
  }) {
    return _get('adminListClients', {
      if (search != null && search.isNotEmpty) 'search': search,
      if (level != null && level.isNotEmpty) 'level': level,
      'limit': '$limit',
      if (cursor != null) 'cursor': cursor,
    });
  }

  /// §2 Client Detail — full profile + economy history + habits + check-ins.
  Future<Map<String, dynamic>> getClientDetail(String uid) {
    return _get('adminGetClientDetail', {'uid': uid});
  }

  /// §2 Manual adjustments + suspend/unsuspend (#A2.4/#A2.6). `reason` is
  /// required by the backend for every action — see adminAdjustClient.
  Future<Map<String, dynamic>> adjustClient({
    required String uid,
    required String action, // grant_points|grant_credits|restore_checkpoint|reset_onboarding|suspend|unsuspend
    required String reason,
    int? amount,
    String? planet,
  }) {
    return _post('adminAdjustClient', {
      'uid': uid,
      'action': action,
      'reason': reason,
      if (amount != null) 'amount': amount,
      if (planet != null) 'planet': planet,
    });
  }

  /// §3 Access & Passwords (#A3.1–#A3.4). `reason` required.
  Future<Map<String, dynamic>> clientAccess({
    required String uid,
    required String action, // send_password_reset|force_password_reset|revoke_sessions|change_email
    required String reason,
    String? newEmail,
  }) {
    return _post('adminClientAccess', {
      'uid': uid,
      'action': action,
      'reason': reason,
      if (newEmail != null) 'newEmail': newEmail,
    });
  }
}
