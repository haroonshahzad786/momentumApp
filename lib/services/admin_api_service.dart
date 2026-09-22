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

  /// §9 Audit log (#A9.3) — newest first. `action`/`adminUid` are exact-match
  /// server-side filters, `since`/`until` bound `when`; `cursor` is the last
  /// row's `id` from the previous page (`nextCursor` in the response).
  Future<Map<String, dynamic>> listAuditLog({
    String? action,
    String? adminUid,
    DateTime? since,
    DateTime? until,
    int limit = 50,
    String? cursor,
  }) {
    return _get('adminListAuditLog', {
      if (action != null && action.isNotEmpty) 'action': action,
      if (adminUid != null && adminUid.isNotEmpty) 'adminUid': adminUid,
      if (since != null) 'since': since.toUtc().toIso8601String(),
      if (until != null) 'until': until.toUtc().toIso8601String(),
      'limit': '$limit',
      if (cursor != null) 'cursor': cursor,
    });
  }

  /// §5 Momentum lists (#A5.1) — one row per distinct list type across both
  /// stores (`system` 'momentum' | 'core'). No completion numbers by design
  /// (there is no fixed prompt set to complete) — see the response `note`.
  Future<Map<String, dynamic>> listMomentumLists() => _get('adminListMomentumLists');

  /// §5 List Detail (#A5.4) — per-player progress for one list type.
  /// `coreId` + `categoryId` are required when `system == 'core'`.
  Future<Map<String, dynamic>> getListDetail({
    required String system,
    required String name,
    String? coreId,
    String? categoryId,
  }) {
    return _get('adminGetListDetail', {
      'system': system,
      'name': name,
      if (coreId != null && coreId.isNotEmpty) 'coreId': coreId,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
    });
  }

  /// §4 Habits library (#A4.1/#A4.2/#A4.4) — templates + real per-core
  /// distribution + `config/streaks` (formation rules).
  Future<Map<String, dynamic>> listHabitTemplates() => _get('adminListHabitTemplates');

  /// §4 Habit template CRUD (#A4.1). `action` ∈ create|update|duplicate|
  /// archive|unarchive (no hard delete). `reason` required. For `update`, pass
  /// only the fields that changed (null fields are omitted from the request).
  Future<Map<String, dynamic>> habitTemplate({
    required String action,
    required String reason,
    String? templateId,
    String? name,
    String? coreId,
    String? cadence,
    String? difficulty,
  }) {
    return _post('adminHabitTemplate', {
      'action': action,
      'reason': reason,
      if (templateId != null) 'templateId': templateId,
      if (name != null) 'name': name,
      if (coreId != null) 'coreId': coreId,
      if (cadence != null) 'cadence': cadence,
      if (difficulty != null) 'difficulty': difficulty,
    });
  }

  /// §7 Economy config publish (#A7.3). `path` ∈ economy|levels|streaks|journey;
  /// `changes` (changed keys only) is shallow-merged into `config/{path}`, the
  /// config version is bumped, and the diff is audit-logged. `reason` required.
  /// Response carries the new `version`.
  Future<Map<String, dynamic>> setConfig({
    required String path,
    required Map<String, dynamic> changes,
    required String reason,
  }) {
    return _post('adminSetConfig', {'path': path, 'changes': changes, 'reason': reason});
  }

  /// §7 Feature flags / kill switches (#A7.6/#A7.7). `patch` is merged into
  /// `feature_flags/{key}` (a new key creates the flag); `reason` is required
  /// and the change is audit-logged with a before/after diff.
  Future<Map<String, dynamic>> setFeatureFlag({
    required String key,
    required Map<String, dynamic> patch,
    required String reason,
  }) {
    return _post('adminSetFeatureFlag', {'key': key, 'patch': patch, 'reason': reason});
  }

  /// §6 Integrations — #A6.2 "Test connection": a real round-trip health
  /// check against the Claude API (Models API — costs no tokens). `ok` (from the base `_decode`
  /// check) just means this endpoint ran; the real result is `connected`.
  Future<Map<String, dynamic>> testAiConnection() => _get('adminAiTestConnection');

  /// §6 Integrations — #A6.3. `current` is the live (model, prompt) pair;
  /// `history` is every distinct version ever detected, newest first.
  Future<Map<String, dynamic>> getNovaConfigHistory() => _get('adminGetNovaConfigHistory');

  /// §8 Content editor (#A8.1). Returns every `content/{section}` doc as
  /// `{id, keys, updatedAt, updatedBy}` — no pagination, small collection.
  Future<Map<String, dynamic>> listContent() => _get('adminListContent');

  /// §10 Analytics (#A10.4). Real `habitsByCore` + points/credits
  /// issued-vs-spent; `dauWau`/`retention`/`phase1Funnel`/`economyAnomaly`
  /// each come back as `{needsSpec: true}` — not built, not faked (#A10.1-3).
  Future<Map<String, dynamic>> getAnalytics() => _get('adminGetAnalytics');

  /// §11 Cantina moderation. `type` ∈ posts|tribes|reports|banned_words.
  /// `status` only applies to type='reports' (filters open/resolved/dismissed).
  Future<Map<String, dynamic>> listCantinaContent({required String type, String? status}) {
    return _get('adminListCantinaContent', {
      'type': type,
      if (status != null) 'status': status,
    });
  }

  /// §11 Cantina moderation. One call, `type`+`action` pick the branch — see
  /// adminModerateCantina's own doc comment in functions-flutter/index.js for
  /// the full type/action/extra-field matrix. `reason` required except for
  /// type='banned_words' where it's still required by the backend but not
  /// listed as a hard client-side precondition here (kept consistent: always
  /// pass one).
  Future<Map<String, dynamic>> moderateCantina({
    required String type,
    String? id,
    required String action,
    String? reason,
    String? name,
    String? status,
    String? note,
    List<String>? words,
  }) {
    return _post('adminModerateCantina', {
      'type': type,
      if (id != null) 'id': id,
      'action': action,
      if (reason != null) 'reason': reason,
      if (name != null) 'name': name,
      if (status != null) 'status': status,
      if (note != null) 'note': note,
      if (words != null) 'words': words,
    });
  }

  /// §8 Content editor (#A8.1). `changes` adds/updates string keys in
  /// `content/{section}` (creating the section if new); `deletes` removes
  /// keys. `reason` required. Response carries the new content version.
  Future<Map<String, dynamic>> setContent({
    required String section,
    Map<String, String> changes = const {},
    List<String> deletes = const [],
    required String reason,
  }) {
    return _post('adminSetContent', {
      'section': section,
      if (changes.isNotEmpty) 'changes': changes,
      if (deletes.isNotEmpty) 'deletes': deletes,
      'reason': reason,
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
