import 'package:cloud_firestore/cloud_firestore.dart';

/// Accountability Partners (Pillar 2 — Interstellar Collaboration, sub-feature).
///
/// The spec allows **one active partner at a time** with a **daily or weekly**
/// check-in cadence. V1 pairs the player with an accountability buddy from a
/// curated crew (`candidates`) — the same NPC-vs-real honesty as the Tribes
/// `memberCount` and the leaderboard demo crew. Real two-way matching is the
/// V2 `matchAccountabilityPartner` cloud function.
///
/// Because there is exactly one active partnership, it is stored as a single
/// doc at `users/{uid}/accountability/active`. That lives UNDER the user's own
/// document, so the existing `users/{uid}/{document=**}` owner rule already
/// permits it — no new Firestore rule to deploy (unlike the top-level `tribes`
/// collection).
class AccountabilityService {
  AccountabilityService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _activeRef(String uid) =>
      _db.collection('users').doc(uid).collection('accountability').doc('active');

  /// The user's current partnership, or null if the slot is open.
  Future<AccountabilityPairing?> getActive(String uid) async {
    final snap = await _activeRef(uid).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null || (data['partnerId'] ?? '').toString().isEmpty) {
      return null;
    }
    return AccountabilityPairing.fromDoc(data);
  }

  /// Pairs the user with [candidate] at the chosen [cadence]. Overwrites any
  /// existing partnership (callers enforce the one-active rule before calling).
  Future<void> setPartner({
    required String uid,
    required AccountabilityCandidate candidate,
    required String cadence, // 'daily' | 'weekly'
    required int createdAt,
  }) async {
    await _activeRef(uid).set({
      'partnerId': candidate.id,
      'partnerName': candidate.name,
      'partnerCore': candidate.core,
      'partnerAvatar': candidate.avatar,
      'cadence': cadence == 'weekly' ? 'weekly' : 'daily',
      'createdAt': createdAt,
      'lastNudgeAt': null,
      'nudgeCount': 0,
      'serverAt': FieldValue.serverTimestamp(),
    });
  }

  /// Records a check-in with the partner (increments the streak of mutual
  /// check-ins). Callers gate this on [AccountabilityPairing.checkInDue] so a
  /// player can only log once per cadence period.
  Future<void> logCheckIn({required String uid, required int at}) async {
    final ref = _activeRef(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (data == null || (data['partnerId'] ?? '').toString().isEmpty) return;
      final count =
          (data['nudgeCount'] is num) ? (data['nudgeCount'] as num).toInt() : 0;
      tx.set(
          ref,
          {
            'lastNudgeAt': at,
            'nudgeCount': count + 1,
          },
          SetOptions(merge: true));
    });
  }

  /// Ends the partnership, freeing the slot.
  Future<void> end(String uid) => _activeRef(uid).delete();

  /// Curated accountability crew available to pair with. `core` is a short core
  /// id (`physical`…) or `general`; `avatar` is the single-letter monogram.
  static const List<AccountabilityCandidate> candidates = [
    AccountabilityCandidate(
      id: 'ap_maya',
      name: 'Maya R.',
      core: 'physical',
      avatar: 'M',
      blurb: 'Marathon-in-training. Will chase you for the 6am run.',
    ),
    AccountabilityCandidate(
      id: 'ap_devon',
      name: 'Devon T.',
      core: 'career',
      avatar: 'D',
      blurb: 'Deep-work sprints. Trades focus wins every evening.',
    ),
    AccountabilityCandidate(
      id: 'ap_aisha',
      name: 'Aisha K.',
      core: 'mindset',
      avatar: 'A',
      blurb: 'Meditation streak keeper. Calm, consistent, kind.',
    ),
    AccountabilityCandidate(
      id: 'ap_leo',
      name: 'Leo M.',
      core: 'relationships',
      avatar: 'L',
      blurb: 'Weekly reach-outs. Great at the gentle nudge.',
    ),
    AccountabilityCandidate(
      id: 'ap_sana',
      name: 'Sana P.',
      core: 'emotional',
      avatar: 'S',
      blurb: 'Journaling buddy. Keeps the honesty high, judgement zero.',
    ),
    AccountabilityCandidate(
      id: 'ap_kai',
      name: 'Kai N.',
      core: 'general',
      avatar: 'K',
      blurb: 'Generalist. Any Core, any goal — just wants you to show up.',
    ),
  ];
}

/// A pilot you can pair with as an accountability partner (NPC crew in V1).
class AccountabilityCandidate {
  const AccountabilityCandidate({
    required this.id,
    required this.name,
    required this.core,
    required this.avatar,
    required this.blurb,
  });

  final String id;
  final String name;
  final String core; // short core id or 'general'
  final String avatar;
  final String blurb;
}

/// The user's single active partnership.
class AccountabilityPairing {
  const AccountabilityPairing({
    required this.partnerId,
    required this.partnerName,
    required this.partnerCore,
    required this.partnerAvatar,
    required this.cadence,
    required this.createdAt,
    required this.lastNudgeAt,
    required this.nudgeCount,
  });

  final String partnerId;
  final String partnerName;
  final String partnerCore;
  final String partnerAvatar;
  final String cadence; // 'daily' | 'weekly'
  final int createdAt;
  final int? lastNudgeAt; // ms since epoch, null until first check-in
  final int nudgeCount;

  bool get isWeekly => cadence == 'weekly';

  factory AccountabilityPairing.fromDoc(Map<String, dynamic> d) =>
      AccountabilityPairing(
        partnerId: (d['partnerId'] ?? '').toString(),
        partnerName: (d['partnerName'] ?? 'Partner').toString(),
        partnerCore: (d['partnerCore'] ?? 'general').toString(),
        partnerAvatar: (d['partnerAvatar'] ?? '?').toString(),
        cadence: (d['cadence'] ?? 'daily').toString() == 'weekly'
            ? 'weekly'
            : 'daily',
        createdAt: (d['createdAt'] is num) ? (d['createdAt'] as num).toInt() : 0,
        lastNudgeAt:
            (d['lastNudgeAt'] is num) ? (d['lastNudgeAt'] as num).toInt() : null,
        nudgeCount:
            (d['nudgeCount'] is num) ? (d['nudgeCount'] as num).toInt() : 0,
      );

  /// Whether a check-in can be logged right now. Daily → once per calendar day;
  /// weekly → once per rolling 7 days.
  bool checkInDue(DateTime now) {
    final last = lastNudgeAt;
    if (last == null) return true;
    final lastDt = DateTime.fromMillisecondsSinceEpoch(last);
    if (isWeekly) {
      return now.difference(lastDt).inDays >= 7;
    }
    final lastDay = DateTime(lastDt.year, lastDt.month, lastDt.day);
    final today = DateTime(now.year, now.month, now.day);
    return today.isAfter(lastDay);
  }

  /// Human label for when the next check-in unlocks (used when not yet due).
  String nextDueLabel(DateTime now) {
    final last = lastNudgeAt;
    if (last == null) return 'Check in now';
    final lastDt = DateTime.fromMillisecondsSinceEpoch(last);
    if (isWeekly) {
      final days = 7 - now.difference(lastDt).inDays;
      if (days <= 1) return 'Next check-in tomorrow';
      return 'Next check-in in $days days';
    }
    return 'Next check-in tomorrow';
  }
}
