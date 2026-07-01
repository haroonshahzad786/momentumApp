import '../config/api_config.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/phase1_state.dart';
import '../models/user_profile.dart';
import 'offline.dart';

/// Reads the dashboard profile from Firebase Functions (codebase "flutter").
class ProfileService {
  ProfileService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl =
      'https://us-central1-momentum-bce49.cloudfunctions.net';
  static const String _secret = ApiConfig.secret;

  /// Dashboard profile with offline fallback — on a network failure the
  /// last-good profile from disk is returned with `fromCache: true`.
  Future<Fetched<UserProfile>> getProfile(String userId) async {
    final cacheKey = 'cache:profile:$userId';
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/flutterGetUserProfile'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'secret': _secret, 'userId': userId}),
      );
      if (response.statusCode != 200) {
        throw Exception(
          'flutterGetUserProfile failed (${response.statusCode}): ${response.body}',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('flutterGetUserProfile returned non-JSON-object');
      }
      if (decoded['ok'] != true) {
        throw Exception(
          'flutterGetUserProfile error: ${decoded['error'] ?? 'unknown'}',
        );
      }
      final profile = decoded['profile'];
      if (profile is! Map<String, dynamic>) {
        throw Exception('flutterGetUserProfile missing profile object');
      }
      await LocalCache.putJson(cacheKey, profile);
      return Fetched(UserProfile.fromJson(profile), fromCache: false);
    } catch (e) {
      if (isNetworkError(e)) {
        final cached = await LocalCache.getJson(cacheKey);
        if (cached is Map<String, dynamic>) {
          return Fetched(UserProfile.fromJson(cached), fromCache: true);
        }
      }
      rethrow;
    }
  }

  /// Persists Phase 1 onboarding progress to the user doc. Fire-and-forget from
  /// the caller's perspective — a failure here must never block onboarding — so
  /// errors are thrown for the caller to swallow, not retried here.
  ///
  /// Also refreshes the cached profile (if present) so the cockpit reads the new
  /// state immediately on a subsequent offline launch instead of stale progress.
  Future<void> savePhase1State(String userId, Phase1State state) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/flutterSavePhase1State'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'secret': _secret,
        'userId': userId,
        'stage1Progress': state.stage1Progress,
        'stage1Completed': state.stage1Completed,
        'stage2Completed': state.stage2Completed,
        if (state.lastView != null) 'lastView': state.lastView,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'flutterSavePhase1State failed (${response.statusCode}): ${response.body}',
      );
    }

    // Keep the offline cache in sync with what we just wrote.
    final cacheKey = 'cache:profile:$userId';
    final cached = await LocalCache.getJson(cacheKey);
    if (cached is Map<String, dynamic>) {
      cached['stage1Progress'] = state.stage1Progress;
      cached['stage1Completed'] = state.stage1Completed;
      cached['stage2Completed'] = state.stage2Completed;
      cached['phase'] = state.stage1Completed && state.stage2Completed
          ? 'daily'
          : 'build';
      await LocalCache.putJson(cacheKey, cached);
    }
  }

  void dispose() => _client.close();
}
