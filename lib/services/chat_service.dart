import '../config/api_config.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_message.dart';
import 'offline.dart';

/// Wraps the HHS Stage 1 onboarding chat's Claude-backed Firebase Cloud
/// Functions (`claudeLaunchConversation` / `claudeSendMessage` /
/// `claudeGetLatestMessages`, "flutter" codebase). All endpoints are HTTP
/// `onRequest` (not callable). They expect a shared secret + the Firebase
/// user uid.
class ChatService {
  ChatService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // TODO: if your Cloud Functions are NOT in us-central1, change this.
  static const String _baseUrl =
      'https://us-central1-momentum-bce49.cloudfunctions.net';

  // Matches API_SECRET in index.js.
  static const String _secret = ApiConfig.secret;

  Uri _uri(String name) => Uri.parse('$_baseUrl/$name');

  /// Returns the seeded first assistant messages, or empty if a conversation
  /// already exists for this user (server replied { skipped: true }).
  /// The deployed function splits the reply into multiple parts; each text
  /// part becomes one ChatMessage and the image part following it attaches
  /// its imageUrls to that bubble.
  Future<List<ChatMessage>> launchConversation(String userId) async {
    const endpoint = 'claudeLaunchConversation';
    final response = await _client.post(
      _uri(endpoint),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'secret': _secret, 'userId': userId}),
    );
    final data = _decode(response, endpoint);
    if (data['skipped'] == true) return const [];
    return _parseAssistantParts(data);
  }

  /// [sessionId] null = the player's first-time HHS conversation; otherwise a
  /// returning / Go Deeper session (P1-2).
  Future<List<ChatMessage>> sendMessage(
    String userId,
    String text, {
    String? sessionId,
  }) async {
    const endpoint = 'claudeSendMessage';
    final response = await _client.post(
      _uri(endpoint),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'secret': _secret,
        'userId': userId,
        'text': text,
        if (sessionId != null) 'sessionId': sessionId,
      }),
    );
    final data = _decode(response, endpoint);
    return _parseAssistantParts(data);
  }

  List<ChatMessage> _parseAssistantParts(Map<String, dynamic> data) {
    final parts = data['assistantParts'] as List? ?? const [];
    final ids =
        (data['assistantMessageIds'] as List? ?? const [])
            .map((e) => e.toString())
            .toList();
    final messages = <ChatMessage>[];
    final now = DateTime.now();
    int idIdx = 0;

    String nextId() =>
        idIdx < ids.length
            ? ids[idIdx++]
            : 'local-${now.microsecondsSinceEpoch}-${idIdx++}';

    for (final raw in parts) {
      if (raw is! Map) continue;
      final part = raw.cast<String, dynamic>();
      final type = part['type']?.toString();
      final urls =
          (part['imageUrls'] as List?)
              ?.map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList() ??
          const <String>[];

      if (type == 'text') {
        final text = (part['text']?.toString() ?? '').trim();
        if (text.isEmpty) continue;
        messages.add(
          ChatMessage(
            id: nextId(),
            role: 'assistant',
            text: text,
            imageUrls: urls,
            createdAt: now,
          ),
        );
      } else if (type == 'image') {
        if (urls.isEmpty) continue;
        if (messages.isNotEmpty) {
          // Attach image to the most recent text message so the bubble
          // and the visual stage stay in sync.
          final last = messages.removeLast();
          messages.add(
            ChatMessage(
              id: last.id,
              role: last.role,
              text: last.text,
              imageUrls: [...last.imageUrls, ...urls],
              createdAt: last.createdAt,
            ),
          );
        } else {
          // Image-only part with no preceding text — emit as standalone.
          messages.add(
            ChatMessage(
              id: nextId(),
              role: 'assistant',
              text: '',
              imageUrls: urls,
              createdAt: now,
            ),
          );
        }
      }
    }
    return messages;
  }

  /// Conversation history with offline fallback — on a network failure the
  /// last-good transcript from disk is returned with `fromCache: true`.
  Future<Fetched<List<ChatMessage>>> getLatestMessages(
    String userId, {
    int limit = 50,
    String? sessionId,
  }) async {
    const endpoint = 'claudeGetLatestMessages';
    final cacheKey =
        'cache:claude_messages:$userId${sessionId == null ? '' : ':$sessionId'}';
    try {
      final response = await _client.post(
        _uri(endpoint),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'secret': _secret,
          'userId': userId,
          'limit': limit,
          if (sessionId != null) 'sessionId': sessionId,
        }),
      );
      final data = _decode(response, endpoint);
      final raw = data['messages'] as List? ?? const [];
      await LocalCache.putJson(cacheKey, raw);
      return Fetched(_parseMessages(raw), fromCache: false);
    } catch (e) {
      if (isNetworkError(e)) {
        final cached = await LocalCache.getJson(cacheKey);
        if (cached is List) {
          return Fetched(_parseMessages(cached), fromCache: true);
        }
      }
      rethrow;
    }
  }

  /// The unfinished returning / Go Deeper session to resume, or null.
  Future<HhsSession?> currentSession(String userId) async {
    const endpoint = 'claudeHhsSession';
    final response = await _client.post(
      _uri(endpoint),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'secret': _secret,
        'userId': userId,
        'action': 'current',
      }),
    );
    final s = _decode(response, endpoint)['session'];
    return s is Map ? HhsSession.fromJson(s.cast<String, dynamic>()) : null;
  }

  /// Resumes an unfinished session of [mode] (and [habitId] for Go Deeper) or
  /// starts one — Nova's opening turn (the recap) runs server-side, so this
  /// can take a few seconds. [mode]: returning_voluntary | returning_guided |
  /// go_deeper.
  Future<HhsSession> startSession(
    String userId, {
    required String mode,
    String? habitId,
  }) async {
    const endpoint = 'claudeHhsSession';
    final response = await _client.post(
      _uri(endpoint),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'secret': _secret,
        'userId': userId,
        'action': 'start',
        'mode': mode,
        if (habitId != null) 'habitId': habitId,
      }),
    );
    final s = _decode(response, endpoint)['session'];
    if (s is! Map) throw Exception('$endpoint returned no session');
    return HhsSession.fromJson(s.cast<String, dynamic>());
  }

  List<ChatMessage> _parseMessages(List<dynamic> raw) =>
      raw
          .whereType<Map>()
          .map((m) => ChatMessage.fromJson(m.cast<String, dynamic>()))
          .toList();

  Map<String, dynamic> _decode(http.Response response, String fnName) {
    if (response.statusCode != 200) {
      throw Exception(
        '$fnName failed (${response.statusCode}): ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('$fnName returned non-JSON-object response');
    }
    if (decoded['ok'] == false) {
      throw Exception('$fnName error: ${decoded['error'] ?? 'unknown'}');
    }
    return decoded;
  }

  void dispose() => _client.close();
}

/// A returning / Go Deeper HHS session (P1-2).
class HhsSession {
  const HhsSession({required this.id, required this.mode, this.habitId = ''});

  final String id;
  final String mode; // returning_voluntary | returning_guided | go_deeper
  final String habitId;

  bool get isGoDeeper => mode == 'go_deeper';

  factory HhsSession.fromJson(Map<String, dynamic> j) => HhsSession(
    id: '${j['id'] ?? ''}',
    mode: '${j['mode'] ?? ''}',
    habitId: '${j['habitId'] ?? ''}',
  );
}
