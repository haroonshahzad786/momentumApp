import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'checkin_service.dart';

/// One Today's Focus bullet from Nova.
class FocusBullet {
  const FocusBullet({required this.emoji, required this.text});

  final String emoji;
  final String text;

  factory FocusBullet.fromJson(Map<String, dynamic> j) => FocusBullet(
        emoji: (j['emoji'] ?? '').toString(),
        text: (j['text'] ?? '').toString(),
      );
}

/// 📍 Today's Focus (#24): Nova's 3–5 bullets for today, written from this
/// session's check-in plus Golden Habits (⚠️ flags, 🧪 experiments) and
/// Momentum Lists (`flutterTodaysFocus`). The server caches the result on the
/// day's check-in, so calling again for the same check-in is free. An empty
/// list means there's no check-in for [date] yet.
class TodaysFocusService {
  TodaysFocusService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl =
      'https://us-central1-momentum-bce49.cloudfunctions.net';

  Future<List<FocusBullet>> fetch({
    required String userId,
    Map<String, int> scores = const {},
    DateTime? date,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/flutterTodaysFocus'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'secret': ApiConfig.secret,
        'userId': userId,
        'date': CheckinService.dayId(date ?? DateTime.now()),
        'scores': scores,
      }),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode != 200 ||
        decoded is! Map<String, dynamic> ||
        decoded['ok'] != true) {
      throw Exception(
        'flutterTodaysFocus failed (${response.statusCode}): ${response.body}',
      );
    }
    return [
      for (final b in (decoded['bullets'] as List? ?? const []))
        if (b is Map<String, dynamic>) FocusBullet.fromJson(b),
    ];
  }
}
