import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/cantina_message.dart';

/// A registered user surfaced in the Cantina crew list + leaderboard.
class CantinaUser {
  CantinaUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.score,
    required this.streak,
    required this.level,
    required this.planet,
    required this.activeCores,
  });

  final String uid;
  final String name;
  final String email;
  final int score;
  final int streak;
  final String level;
  final String planet;
  final List<String> activeCores;

  factory CantinaUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final email = (d['email'] ?? '').toString();
    final rawName = (d['name'] ?? d['displayName'] ?? '').toString().trim();
    final name = rawName.isNotEmpty
        ? rawName
        : (email.contains('@') ? email.split('@').first : 'Cadet');
    final num scoreNum = d['points'] is num
        ? d['points'] as num
        : (d['momentumScore'] is num ? d['momentumScore'] as num : 0);
    return CantinaUser(
      uid: doc.id,
      name: name,
      email: email,
      score: scoreNum.toInt(),
      streak: d['streak'] is num ? (d['streak'] as num).toInt() : 0,
      level: (d['level'] ?? 'CDT').toString(),
      planet: (d['planet'] ?? 'Earth').toString(),
      activeCores: (d['activeCores'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// One DM thread's unread state, read from `users/{uid}/cantina_inbox/{pairId}`.
class CantinaInboxEntry {
  CantinaInboxEntry({required this.unreadCount, this.updatedAt});

  final int unreadCount;

  /// Last activity on the thread, if the backend stamps `updatedAt`.
  final DateTime? updatedAt;

  factory CantinaInboxEntry.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final c = d['unreadCount'];
    final ts = d['updatedAt'] ?? d['lastMessageAt'];
    return CantinaInboxEntry(
      unreadCount: c is num ? c.toInt() : 0,
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

/// Reads/writes Cantina crew + messages from Firestore.
///
/// Two kinds of message threads:
///  - demo/mock threads (Maya, Squadron Pluto, …): stored privately under the
///    signed-in user at `users/{uid}/cantina_threads/{threadId}/messages`.
///  - real user DMs (threadId `dm:{otherUid}`): a SHARED two-way thread at
///    `cantina_dms/{pairId}/messages`, where pairId is both uids sorted and
///    joined with `__` so both participants resolve the same location.
class CantinaService {
  CantinaService({FirebaseFirestore? db, FirebaseAuth? auth})
      : _db = db ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get currentUid => _auth.currentUser?.uid ?? 'anon';

  String get currentName =>
      _auth.currentUser?.displayName ?? _auth.currentUser?.email ?? 'You';

  // ── Crew / leaderboard ──────────────────────────────────────
  /// Live list of every registered user (rules allow listing `users`).
  Stream<List<CantinaUser>> watchUsers() {
    return _db
        .collection('users')
        .snapshots()
        .map((snap) => snap.docs.map(CantinaUser.fromDoc).toList());
  }

  /// One-shot fetch of a single user — used for a DM thread's title.
  Future<CantinaUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return CantinaUser.fromDoc(doc);
  }

  // ── Message location ────────────────────────────────────────
  bool _isDm(String threadId) => threadId.startsWith('dm:');

  String dmPairId(String otherUid) {
    final ids = [currentUid, otherUid]..sort();
    return ids.join('__');
  }

  CollectionReference<Map<String, dynamic>> _messagesRef(String threadId) {
    if (_isDm(threadId)) {
      return _db
          .collection('cantina_dms')
          .doc(dmPairId(threadId.substring(3)))
          .collection('messages');
    }
    // Mock/private thread under the signed-in user's own document.
    return _db
        .collection('users')
        .doc(currentUid)
        .collection('cantina_threads')
        .doc(threadId)
        .collection('messages');
  }

  // ── Messages ────────────────────────────────────────────────
  /// Live stream of every message in a thread, oldest first.
  Stream<List<CantinaMessage>> watchMessages(String threadId) {
    return _messagesRef(threadId)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(CantinaMessage.fromDoc).toList());
  }

  /// Appends a message from the current user. Server stamps the time.
  Future<void> sendMessage(String threadId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _messagesRef(threadId).add({
      'senderId': currentUid,
      'senderName': currentName,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Stamp my own inbox so threads I start also float to the top of the
    // leaderboard by recency (the Cloud Function maintains the recipient side).
    if (_isDm(threadId)) {
      final pairId = dmPairId(threadId.substring(3));
      try {
        await _db
            .collection('users')
            .doc(currentUid)
            .collection('cantina_inbox')
            .doc(pairId)
            .set({
          'unreadCount': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('sendMessage inbox stamp failed: $e');
      }
    }
  }

  /// Clears the chat history *for the current user only*.
  ///
  /// For a real DM the messages live in a SHARED collection, so we don't delete
  /// them — that would wipe the other person's copy too. Instead we record a
  /// private `clearedAt` cutoff in the user's own inbox; [watchClearedAt] +
  /// the UI hide everything at/before it. The other participant is unaffected.
  ///
  /// For a mock/private thread (stored under the user's own doc) there is no
  /// other party, so we delete the docs outright (in batches under the 500
  /// per-batch limit).
  Future<void> clearMessages(String threadId) async {
    if (_isDm(threadId)) {
      final pairId = dmPairId(threadId.substring(3));
      await _db
          .collection('users')
          .doc(currentUid)
          .collection('cantina_inbox')
          .doc(pairId)
          .set({
        'clearedAt': FieldValue.serverTimestamp(),
        'unreadCount': 0,
      }, SetOptions(merge: true));
      return;
    }
    final ref = _messagesRef(threadId);
    while (true) {
      final snap = await ref.limit(400).get();
      if (snap.docs.isEmpty) break;
      final batch = _db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
      if (snap.docs.length < 400) break;
    }
  }

  /// The current user's private "cleared history" cutoff for a DM thread.
  /// Messages created at/before this time are hidden from this user only.
  /// Emits null for mock threads or when nothing has been cleared.
  Stream<DateTime?> watchClearedAt(String threadId) {
    if (!_isDm(threadId)) return Stream<DateTime?>.value(null);
    final pairId = dmPairId(threadId.substring(3));
    return _db
        .collection('users')
        .doc(currentUid)
        .collection('cantina_inbox')
        .doc(pairId)
        .snapshots()
        .map((d) {
      final ts = d.data()?['clearedAt'];
      return ts is Timestamp ? ts.toDate() : null;
    });
  }

  /// Seeds a mock thread's opening demo messages the first time it's viewed so
  /// the channel isn't blank. No-ops for real DMs and for threads that already
  /// have messages.
  Future<void> seedIfEmpty(
    String threadId,
    List<Map<String, String>> history,
  ) async {
    if (_isDm(threadId) || history.isEmpty) return;
    final existing = await _messagesRef(threadId).limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _db.batch();
    // Backdate seeds so they sort before any live message sent afterwards.
    final base = DateTime.now().subtract(Duration(seconds: history.length));
    for (var i = 0; i < history.length; i++) {
      final m = history[i];
      final mine = m['from'] == 'me';
      batch.set(_messagesRef(threadId).doc(), {
        'senderId': mine ? currentUid : 'crew:$threadId',
        'senderName': mine ? currentName : '',
        'text': m['text'] ?? '',
        'createdAt': Timestamp.fromDate(base.add(Duration(seconds: i))),
        'seeded': true,
      });
    }
    await batch.commit();
  }

  // ── Unread badges ───────────────────────────────────────────
  /// Total unread across all of the user's DM threads (drives the nav badge).
  Stream<int> watchUnreadTotal() {
    return _db
        .collection('users')
        .doc(currentUid)
        .collection('cantina_inbox')
        .snapshots()
        .map((s) => s.docs.fold<int>(0, (sum, d) {
              final c = d.data()['unreadCount'];
              return sum + (c is num ? c.toInt() : 0);
            }));
  }

  /// Per-thread unread state, keyed by `pairId`. Drives the per-sender badge
  /// and "most-recent-first" ordering in the leaderboard. `updatedAt` is the
  /// last DM activity if the backend stamps it (falls back to null otherwise).
  Stream<Map<String, CantinaInboxEntry>> watchInbox() {
    return _db
        .collection('users')
        .doc(currentUid)
        .collection('cantina_inbox')
        .snapshots()
        .map((s) => {
              for (final d in s.docs)
                d.id: CantinaInboxEntry.fromDoc(d),
            });
  }

  /// Clears the unread counter for a DM thread (when it's opened / viewed).
  Future<void> markThreadRead(String threadId) async {
    if (!_isDm(threadId)) return;
    final pairId = dmPairId(threadId.substring(3));
    try {
      await _db
          .collection('users')
          .doc(currentUid)
          .collection('cantina_inbox')
          .doc(pairId)
          .set({'unreadCount': 0}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('markThreadRead failed: $e');
    }
  }
}
