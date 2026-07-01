import '../config/api_config.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_message.dart';
import 'offline.dart';

/// Wraps the three Voiceflow-backed Firebase Cloud Functions.
/// All endpoints are HTTP `onRequest` (not callable). They expect a shared
/// secret + the Firebase user uid.
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
    final response = await _client.post(
      _uri('vfLaunchConversation'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'secret': _secret, 'userId': userId}),
    );
    final data = _decode(response, 'vfLaunchConversation');
    if (data['skipped'] == true) return const [];
    return _parseAssistantParts(data);
  }

  Future<List<ChatMessage>> sendMessage(String userId, String text) async {
    final response = await _client.post(
      _uri('vfSendMessage'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'secret': _secret,
        'userId': userId,
        'text': text,
      }),
    );
    final data = _decode(response, 'vfSendMessage');
    return _parseAssistantParts(data);
  }

  List<ChatMessage> _parseAssistantParts(Map<String, dynamic> data) {
    final parts = data['assistantParts'] as List? ?? const [];
    final ids = (data['assistantMessageIds'] as List? ?? const [])
        .map((e) => e.toString())
        .toList();
    final messages = <ChatMessage>[];
    final now = DateTime.now();
    int idIdx = 0;

    String nextId() => idIdx < ids.length
        ? ids[idIdx++]
        : 'local-${now.microsecondsSinceEpoch}-${idIdx++}';

    for (final raw in parts) {
      if (raw is! Map) continue;
      final part = raw.cast<String, dynamic>();
      final type = part['type']?.toString();
      final urls = (part['imageUrls'] as List?)
              ?.map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList() ??
          const <String>[];

      if (type == 'text') {
        final text = (part['text']?.toString() ?? '').trim();
        if (text.isEmpty) continue;
        messages.add(ChatMessage(
          id: nextId(),
          role: 'assistant',
          text: text,
          imageUrls: urls,
          createdAt: now,
        ));
      } else if (type == 'image') {
        if (urls.isEmpty) continue;
        if (messages.isNotEmpty) {
          // Attach image to the most recent text message so the bubble
          // and the visual stage stay in sync.
          final last = messages.removeLast();
          messages.add(ChatMessage(
            id: last.id,
            role: last.role,
            text: last.text,
            imageUrls: [...last.imageUrls, ...urls],
            createdAt: last.createdAt,
          ));
        } else {
          // Image-only part with no preceding text — emit as standalone.
          messages.add(ChatMessage(
            id: nextId(),
            role: 'assistant',
            text: '',
            imageUrls: urls,
            createdAt: now,
          ));
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
  }) async {
    final cacheKey = 'cache:vf_messages:$userId';
    try {
      final response = await _client.post(
        _uri('vfGetLatestMessages'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'secret': _secret,
          'userId': userId,
          'limit': limit,
        }),
      );
      final data = _decode(response, 'vfGetLatestMessages');
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

  List<ChatMessage> _parseMessages(List<dynamic> raw) => raw
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
