import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'offline.dart';

/// A points award worth celebrating, as written by the FlutterFlow-side
/// `updateUserPoints` endpoint that the Voiceflow agent calls:
///
/// ```
/// {{ updateUserPoints({ userId: ff_id, type: "Pain Points", points: 10 }) }}
/// ```
///
/// It writes `users/{uid}/points/summary/history/{auto}` = `{type, points,
/// timestamp}` and bumps `points/summary.total`, so the newest history entry is
/// what the agent just awarded.
class PointsAward {
  const PointsAward({
    required this.points,
    required this.type,
    required this.at,
  });

  /// Points added by this award (e.g. 10 for "Pain Points").
  final int points;

  /// The award label the agent passed, e.g. "Pain Points" / "Core Confirmed".
  final String type;

  /// Server timestamp of the award, null if it hasn't materialised yet.
  final DateTime? at;

  /// True when the award landed within [window] of now.
  bool isRecent(Duration window) {
    final t = at;
    if (t == null) return false;
    return DateTime.now().difference(t).abs() <= window;
  }

  /// Awards older than this are stale — a celebration event that arrives with
  /// no fresh award shows without a number rather than reusing an old one.
  bool get isFresh => isRecent(const Duration(minutes: 5));
}

/// A `CELEBRATION` (or other) event raised by the Voiceflow agent through the
/// FlutterFlow-side `handleVoiceflowEvent` endpoint:
///
/// ```
/// {{ handleVoiceflowEvent({ userId: ff_id, eventName: "CELEBRATION", ... }) }}
/// ```
///
/// That endpoint merges a single doc per user at `vf_events/{uid}` with
/// `{eventName, status, payload, eventCount, updatedAt}` — `eventCount` is the
/// increment we key replay off, since the doc itself is reused forever.
class CelebrationEvent {
  const CelebrationEvent({
    required this.eventName,
    required this.eventCount,
    this.award,
  });

  final String eventName;
  final int eventCount;

  /// The award that triggered it, when a fresh one is on the ledger.
  final PointsAward? award;

  bool get isCelebration => eventName.toUpperCase() == 'CELEBRATION';
}

/// Watches for points landing on the player's ledger and raises a celebration.
///
/// **The ledger is the trigger, not the agent's event.** `updateUserPoints` is
/// the call the agent reliably makes; the paired
/// `handleVoiceflowEvent({eventName:"CELEBRATION"})` was observed NOT to arrive
/// for real awards (it rejects a call without the shared `secret`, and the
/// agent step as written doesn't send one) — so keying the confetti off
/// `vf_events` meant the confetti never fired in normal play. Watching the
/// points history sub-collection instead catches EVERY award, whoever wrote it:
/// the Voiceflow agent, the daily check-in, or the Stage 2 momentify.
///
/// The `vf_events` doc is still watched as a secondary trigger, for celebration
/// moments the agent raises without points. It is read-only to clients
/// (`allow read: if true; allow write: if false`), so "already celebrated" is
/// tracked on the device ([LocalCache]) rather than written back — no Firestore
/// rules change needed either way.
///
/// On both paths the first snapshot only establishes a baseline, so opening the
/// app never replays an award the player already saw.
class CelebrationService {
  CelebrationService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static String _seenKey(String uid) => 'celebration:seen:$uid';
  static String _seenAwardKey(String uid) => 'celebration:award:$uid';

  /// How recently an award must have landed to be worth celebrating. Wide
  /// enough to survive a slow first sync after the app opens, short enough that
  /// yesterday's points never re-fire.
  static const _ledgerWindow = Duration(minutes: 2);

  /// Emits once per NEW award (or agent celebration event) for [uid].
  Stream<CelebrationEvent> watch(String uid) {
    if (uid.isEmpty) return const Stream<CelebrationEvent>.empty();

    final out = StreamController<CelebrationEvent>();
    final subs = <StreamSubscription<Object?>>[];

    Future<void> start() async {
      subs.add(_watchLedger(uid, out));
      subs.add(_watchAgentEvents(uid, out));
    }

    out.onListen = start;
    out.onCancel = () async {
      for (final s in subs) {
        await s.cancel();
      }
    };
    return out.stream;
  }

  /// Primary trigger: a new doc in `users/{uid}/points/summary/history`.
  StreamSubscription<Object?> _watchLedger(
    String uid,
    StreamController<CelebrationEvent> out,
  ) {
    String? seenId;
    var loaded = false;

    Future<void> loadBaseline() async {
      final cached = await LocalCache.getJson(_seenAwardKey(uid));
      if (cached is String) seenId = cached;
      loaded = true;
    }

    final baseline = loadBaseline();

    return _db
        .collection('users')
        .doc(uid)
        .collection('points')
        .doc('summary')
        .collection('history')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen(
      (snap) async {
        await baseline;
        if (!loaded || snap.docs.isEmpty) return;
        final doc = snap.docs.first;
        if (doc.id == seenId) return;
        seenId = doc.id;
        await LocalCache.putJson(_seenAwardKey(uid), doc.id);

        final d = doc.data();
        final award = PointsAward(
          points: (d['points'] as num?)?.toInt() ?? 0,
          type: (d['type'] ?? '').toString(),
          at: (d['timestamp'] as Timestamp?)?.toDate(),
        );
        // AGE is the guard, deliberately NOT "is this the first snapshot we
        // saw". Treating the first snapshot as a baseline swallowed real
        // awards: when the listener's initial read landed after the award (a
        // slow first sync), the award itself became the baseline and nothing
        // ever fired. Age can't be fooled that way — the player's history is
        // full of old awards that must stay quiet, and only one that just
        // happened deserves confetti.
        if (award.points <= 0 || !award.isRecent(_ledgerWindow)) return;
        out.add(CelebrationEvent(
          eventName: 'CELEBRATION',
          eventCount: 0,
          award: award,
        ));
      },
      onError: (_) {
        // A celebration is decoration — never surface a read failure.
      },
    );
  }

  /// Secondary trigger: the agent's own `vf_events/{uid}` doc.
  StreamSubscription<Object?> _watchAgentEvents(
    String uid,
    StreamController<CelebrationEvent> out,
  ) {
    int? seen;
    var loaded = false;

    Future<void> loadBaseline() async {
      final cached = await LocalCache.getJson(_seenKey(uid));
      if (cached is num) seen = cached.toInt();
      loaded = true;
    }

    final baseline = loadBaseline();

    return _db.collection('vf_events').doc(uid).snapshots().listen(
      (snap) async {
        await baseline;
        if (!loaded || !snap.exists) return;
        final data = snap.data() ?? const <String, dynamic>{};
        final count = (data['eventCount'] as num?)?.toInt() ?? 0;
        final name = (data['eventName'] ?? '').toString();

        if (seen == null) {
          seen = count;
          await LocalCache.putJson(_seenKey(uid), count);
          return;
        }
        if (count <= seen!) return;
        seen = count;
        await LocalCache.putJson(_seenKey(uid), count);

        if (name.toUpperCase() != 'CELEBRATION') return;
        // The ledger watcher usually wins this race; CelebrationBus keeps the
        // pair from bursting twice for one award.
        out.add(CelebrationEvent(
          eventName: name,
          eventCount: count,
          award: await latestAward(uid),
        ));
      },
      onError: (_) {},
    );
  }

  /// The most recent `updateUserPoints` history entry, or null when the ledger
  /// is empty/unreadable. Retried briefly: the agent fires the points call and
  /// the celebration event back-to-back, so the write can still be in flight.
  Future<PointsAward?> latestAward(String uid) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final q = await _db
            .collection('users')
            .doc(uid)
            .collection('points')
            .doc('summary')
            .collection('history')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) {
          final d = q.docs.first.data();
          final award = PointsAward(
            points: (d['points'] as num?)?.toInt() ?? 0,
            type: (d['type'] ?? '').toString(),
            at: (d['timestamp'] as Timestamp?)?.toDate(),
          );
          if (award.isFresh && award.points > 0) return award;
        }
      } catch (_) {
        return null;
      }
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
    return null;
  }
}
