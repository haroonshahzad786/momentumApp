import '../config/api_config.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result of a Daily Check-In Momentum Points award (#9).
class CheckinAward {
  const CheckinAward({
    required this.awarded,
    required this.pointsAdded,
    required this.dayPoints,
    this.totalPoints,
    this.streak,
    this.streakUpdated = false,
    this.milestone,
    this.creditsEarned = 0,
    this.spaceCredits,
  });

  /// True only when this call newly credited the day's points.
  final bool awarded;

  /// Points added by THIS call (0 if the day was already awarded).
  final int pointsAdded;

  /// Points attributable to today's check-in (the base award if it's a
  /// completed weekday, whether or not this call was the one that credited it).
  final int dayPoints;

  /// New running total (null on a non-awarding day / failure).
  final int? totalPoints;

  /// New streak after this check-in (#10), null when unknown/failed.
  final int? streak;

  /// True when this check-in extended/reset the streak (a qualifying 4.0+ day).
  final bool streakUpdated;

  /// The streak milestone reached (3/7/14/30/60/90/180/365), else null.
  final int? milestone;

  /// Space Credits added by THIS check-in (base + high-score, #13). 0 if the
  /// day was already awarded.
  final int creditsEarned;

  /// New Space Credits balance after this check-in (null when unknown/failed).
  final int? spaceCredits;

  static const none =
      CheckinAward(awarded: false, pointsAdded: 0, dayPoints: 0);
}

/// Awards Momentum Points for the Daily Check-In via `flutterAwardCheckinPoints`
/// (functions-flutter). The base +10 for a completed weekday check-in is
/// idempotent per calendar day server-side; the high-score / streak-milestone /
/// Balance bonuses are stubbed hooks pending their spec.
class PointsService {
  PointsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl =
      'https://us-central1-momentum-bce49.cloudfunctions.net';
  static const String _secret = ApiConfig.secret;

  /// Awards the day's check-in points. [dateId] is the local `yyyy-MM-dd`.
  /// Best-effort: returns [CheckinAward.none] on any failure so a points blip
  /// never blocks the player from finishing their check-in.
  Future<CheckinAward> awardCheckin({
    required String userId,
    required String dateId,
    required Map<String, int> scores,
  }) async {
    try {
      final r = await _client.post(
        Uri.parse('$_baseUrl/flutterAwardCheckinPoints'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'secret': _secret,
          'userId': userId,
          'date': dateId,
          'scores': scores,
        }),
      );
      if (r.statusCode != 200) return CheckinAward.none;
      final d = jsonDecode(r.body);
      if (d is! Map || d['ok'] != true) return CheckinAward.none;
      return CheckinAward(
        awarded: d['awarded'] == true,
        pointsAdded: (d['pointsAdded'] as num? ?? 0).toInt(),
        dayPoints: (d['dayPoints'] as num? ?? 0).toInt(),
        totalPoints: (d['totalPoints'] as num?)?.toInt(),
        streak: (d['streak'] as num?)?.toInt(),
        streakUpdated: d['streakUpdated'] == true,
        milestone: (d['milestone'] as num?)?.toInt(),
        creditsEarned: (d['creditsEarned'] as num? ?? 0).toInt(),
        spaceCredits: (d['spaceCredits'] as num?)?.toInt(),
      );
    } catch (_) {
      return CheckinAward.none;
    }
  }

  void dispose() => _client.close();
}
