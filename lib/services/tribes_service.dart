import 'package:cloud_firestore/cloud_firestore.dart';

/// A Space Tribe (Pillar 2 — Interstellar Collaboration). Public or private
/// group of up to 20 members, organized loosely by Core focus. A player may
/// belong to at most 3 tribes in V1.
///
/// `memberCount` is the DISPLAY size (seeded tribes carry a base community size
/// for social proof); `memberUids` is the REAL membership used for join/leave
/// idempotency and "my tribes" — same NPC-vs-real split as the leaderboard crew.
class Tribe {
  const Tribe({
    required this.id,
    required this.name,
    required this.description,
    required this.core,
    required this.isPublic,
    required this.memberCount,
    required this.memberUids,
    required this.createdBy,
  });

  final String id;
  final String name;
  final String description;
  final String core; // short core id ('physical'…) or 'general'
  final bool isPublic;
  final int memberCount;
  final List<String> memberUids;
  final String createdBy;

  static const int maxMembers = 20;
  static const int maxJoinedPerUser = 3;

  bool isMember(String uid) => memberUids.contains(uid);
  bool get isFull => memberCount >= maxMembers;

  factory Tribe.fromDoc(String id, Map<String, dynamic> d) => Tribe(
        id: id,
        name: (d['name'] ?? '').toString(),
        description: (d['description'] ?? '').toString(),
        core: (d['core'] ?? 'general').toString(),
        isPublic: d['isPublic'] != false,
        memberCount:
            (d['memberCount'] is num) ? (d['memberCount'] as num).toInt() : 0,
        memberUids: (d['memberUids'] as List? ?? const [])
            .map((e) => e.toString())
            .toList(),
        createdBy: (d['createdBy'] ?? '').toString(),
      );
}

/// One message in a tribe's discussion feed (`tribes/{id}/posts`).
class TribePost {
  const TribePost({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String authorUid;
  final String authorName;
  final String text;
  final int createdAt;

  factory TribePost.fromDoc(String id, Map<String, dynamic> d) => TribePost(
        id: id,
        authorUid: (d['authorUid'] ?? '').toString(),
        authorName: (d['authorName'] ?? 'Pilot').toString(),
        text: (d['text'] ?? '').toString(),
        createdAt:
            (d['createdAt'] is num) ? (d['createdAt'] as num).toInt() : 0,
      );
}

/// Reads/writes Space Tribes directly against Firestore (top-level `tribes`
/// collection, like `cantina_dms`/`space_cantina_posts`). Join/leave mutate the
/// `memberUids` array + `memberCount` inside a transaction so concurrent joins
/// don't clobber the roster. Discussion posts live in a `posts` subcollection.
class TribesService {
  TribesService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('tribes');

  /// Tribes the user belongs to (real membership), newest-community-first.
  Future<List<Tribe>> getMyTribes(String uid) async {
    final snap = await _col.where('memberUids', arrayContains: uid).get();
    final tribes =
        snap.docs.map((d) => Tribe.fromDoc(d.id, d.data())).toList();
    tribes.sort((a, b) => b.memberCount.compareTo(a.memberCount));
    return tribes;
  }

  /// Public tribes to browse (seeds the starter set the first time the whole
  /// collection is empty). Sorted by community size.
  Future<List<Tribe>> getDiscover(String uid) async {
    var snap = await _col.get();
    if (snap.docs.isEmpty) {
      await _seedIfEmpty();
      snap = await _col.get();
    }
    final tribes = snap.docs
        .map((d) => Tribe.fromDoc(d.id, d.data()))
        .where((t) => t.isPublic)
        .toList();
    tribes.sort((a, b) => b.memberCount.compareTo(a.memberCount));
    return tribes;
  }

  /// Joins [tribeId]. Throws [TribeFullException] if the tribe is at capacity.
  /// Idempotent: joining a tribe you're already in is a no-op. The per-user
  /// ≤3 cap is enforced by the caller (which knows the user's joined count).
  Future<void> join(String uid, String tribeId) async {
    final ref = _col.doc(tribeId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final members = (data['memberUids'] as List? ?? const [])
          .map((e) => e.toString())
          .toList();
      if (members.contains(uid)) return; // already a member
      final count =
          (data['memberCount'] is num) ? (data['memberCount'] as num).toInt() : 0;
      if (count >= Tribe.maxMembers) {
        throw const TribeFullException();
      }
      tx.set(
          ref,
          {
            'memberUids': FieldValue.arrayUnion([uid]),
            'memberCount': count + 1,
          },
          SetOptions(merge: true));
    });
  }

  /// Leaves [tribeId] (no-op if not a member).
  Future<void> leave(String uid, String tribeId) async {
    final ref = _col.doc(tribeId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final members = (data['memberUids'] as List? ?? const [])
          .map((e) => e.toString())
          .toList();
      if (!members.contains(uid)) return;
      final count =
          (data['memberCount'] is num) ? (data['memberCount'] as num).toInt() : 1;
      tx.set(
          ref,
          {
            'memberUids': FieldValue.arrayRemove([uid]),
            'memberCount': count > 0 ? count - 1 : 0,
          },
          SetOptions(merge: true));
    });
  }

  /// Creates a tribe with [uid] as its first member. Returns the new id.
  Future<String> createTribe({
    required String uid,
    required String name,
    required String description,
    required String core,
    required bool isPublic,
    required int createdAt,
  }) async {
    final ref = _col.doc();
    await ref.set({
      'name': name.trim(),
      'description': description.trim(),
      'core': core,
      'isPublic': isPublic,
      'memberUids': [uid],
      'memberCount': 1,
      'createdBy': uid,
      'createdAt': createdAt,
    });
    return ref.id;
  }

  /// Discussion posts for a tribe, oldest-first.
  Future<List<TribePost>> getPosts(String tribeId, {int limit = 100}) async {
    final snap = await _col
        .doc(tribeId)
        .collection('posts')
        .orderBy('createdAt')
        .limit(limit)
        .get();
    return snap.docs.map((d) => TribePost.fromDoc(d.id, d.data())).toList();
  }

  Future<void> addPost({
    required String tribeId,
    required String uid,
    required String authorName,
    required String text,
    required int createdAt,
  }) async {
    await _col.doc(tribeId).collection('posts').add({
      'authorUid': uid,
      'authorName': authorName,
      'text': text.trim(),
      'createdAt': createdAt,
      'serverAt': FieldValue.serverTimestamp(),
    });
  }

  /// Seeds a handful of starter tribes the first time the collection is empty.
  /// Deterministic ids keep concurrent seeding idempotent.
  Future<void> _seedIfEmpty() async {
    final batch = _db.batch();
    for (var i = 0; i < _seed.length; i++) {
      batch.set(_col.doc('tribe_seed_${i + 1}'), {
        ..._seed[i],
        'memberUids': <String>[],
        'createdBy': 'system',
        'createdAt': i,
        'seed': true,
      });
    }
    await batch.commit();
  }
}

/// Thrown when a join is attempted on a tribe that's already at 20 members.
class TribeFullException implements Exception {
  const TribeFullException();
  @override
  String toString() => 'This tribe is full (20 members).';
}

/// Curated starter tribes for a fresh install. `memberCount` is a base
/// community size for social proof; real joins add to it.
const List<Map<String, dynamic>> _seed = [
  {
    'name': 'Dawn Patrol',
    'description': 'Early risers keeping each other honest on the 6am launch.',
    'core': 'physical',
    'isPublic': true,
    'memberCount': 14,
  },
  {
    'name': 'Deep Work Guild',
    'description': 'Focus blocks, no-distraction sprints, shipping real work.',
    'core': 'career',
    'isPublic': true,
    'memberCount': 11,
  },
  {
    'name': 'Calm Mind Collective',
    'description': 'Meditation, journaling, and taming the racing-thoughts loop.',
    'core': 'mindset',
    'isPublic': true,
    'memberCount': 9,
  },
  {
    'name': 'Connection Crew',
    'description': 'Small weekly reach-outs so nobody drifts. Relationships first.',
    'core': 'relationships',
    'isPublic': true,
    'memberCount': 7,
  },
  {
    'name': 'Steady State',
    'description': 'General tribe for anyone building momentum, any Core.',
    'core': 'general',
    'isPublic': true,
    'memberCount': 18,
  },
];
