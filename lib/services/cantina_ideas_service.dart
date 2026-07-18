import 'package:cloud_firestore/cloud_firestore.dart';

/// One community-shared idea in the Space Cantina "Ideas Well" (Pillar 1 —
/// Crowdsourced Idea Sharing). Stored in the top-level `space_cantina_posts`
/// collection so every player sees the same feed + live upvote/adopt counts.
class CantinaIdea {
  const CantinaIdea({
    required this.id,
    required this.kind,
    required this.core,
    required this.pain,
    required this.title,
    required this.desc,
    required this.upvotes,
    required this.adopted,
    required this.link,
  });

  final String id;
  final String kind; // 'habit' | 'mbm' | 'tech'
  final String core; // SHORT core id: physical | mindset | career | relationships | emotional
  final String pain;
  final String title;
  final String desc;
  final int upvotes;
  final int adopted;
  final bool link;

  CantinaIdea copyWith({int? upvotes, int? adopted}) => CantinaIdea(
        id: id,
        kind: kind,
        core: core,
        pain: pain,
        title: title,
        desc: desc,
        upvotes: upvotes ?? this.upvotes,
        adopted: adopted ?? this.adopted,
        link: link,
      );

  factory CantinaIdea.fromDoc(String id, Map<String, dynamic> d) => CantinaIdea(
        id: id,
        kind: (d['kind'] ?? 'habit').toString(),
        core: (d['core'] ?? 'mindset').toString(),
        pain: (d['pain'] ?? '').toString(),
        title: (d['title'] ?? '').toString(),
        desc: (d['desc'] ?? '').toString(),
        upvotes: (d['upvotes'] is num) ? (d['upvotes'] as num).toInt() : 0,
        adopted: (d['adopted'] is num) ? (d['adopted'] as num).toInt() : 0,
        link: d['link'] == true,
      );
}

/// The Ideas Well feed plus this user's per-idea vote/adopt state (so the UI can
/// show which cards they've already upvoted / added to their system).
class CantinaIdeasFeed {
  const CantinaIdeasFeed({
    required this.ideas,
    required this.votedIds,
    required this.adoptedIds,
  });
  final List<CantinaIdea> ideas;
  final Set<String> votedIds;
  final Set<String> adoptedIds;
}

/// Reads + writes the Ideas Well directly against Firestore (the same
/// direct-write pattern the Cantina DMs, check-ins and tasks use — no cloud
/// function). Upvotes and adopt-counts are updated in transactions so
/// concurrent players don't clobber the running totals; per-user vote/adopt
/// state lives under the user's own doc so a vote is idempotent + toggleable.
class CantinaIdeasService {
  CantinaIdeasService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('space_cantina_posts');

  DocumentReference<Map<String, dynamic>> _userState(String uid) =>
      _db.collection('users').doc(uid).collection('cantina').doc('ideas_state');

  /// Loads the community feed (seeding the curated starter set the first time
  /// the collection is empty) plus this user's voted/adopted ids.
  Future<CantinaIdeasFeed> getFeed(String uid) async {
    var snap = await _posts.get();
    if (snap.docs.isEmpty) {
      await _seedIfEmpty();
      snap = await _posts.get();
    }
    final ideas =
        snap.docs.map((d) => CantinaIdea.fromDoc(d.id, d.data())).toList();

    final state = await _userState(uid).get();
    final data = state.data() ?? const {};
    Set<String> keysOf(String field) {
      final m = data[field];
      if (m is Map) {
        return m.entries
            .where((e) => e.value == true)
            .map((e) => e.key.toString())
            .toSet();
      }
      return <String>{};
    }

    return CantinaIdeasFeed(
      ideas: ideas,
      votedIds: keysOf('voted'),
      adoptedIds: keysOf('adopted'),
    );
  }

  /// Toggles this user's upvote on [postId]. Returns the post's new upvote
  /// total. Idempotent: a second call with the same [currentlyVoted] flag is a
  /// no-op relative to the intended end-state.
  Future<int> toggleVote(
    String uid,
    String postId, {
    required bool currentlyVoted,
  }) async {
    final postRef = _posts.doc(postId);
    final stateRef = _userState(uid);
    return _db.runTransaction<int>((tx) async {
      final postSnap = await tx.get(postRef);
      final stateSnap = await tx.get(stateRef);
      final current = (postSnap.data()?['upvotes'] is num)
          ? (postSnap.data()!['upvotes'] as num).toInt()
          : 0;
      final voted = (stateSnap.data()?['voted'] as Map?) ?? const {};
      final alreadyVoted = voted[postId] == true;

      // Reconcile against the authoritative stored state to stay idempotent.
      if (currentlyVoted && alreadyVoted) {
        final next = current > 0 ? current - 1 : 0;
        tx.set(postRef, {'upvotes': next}, SetOptions(merge: true));
        tx.set(stateRef, {
          'voted': {postId: FieldValue.delete()}
        }, SetOptions(merge: true));
        return next;
      }
      if (!currentlyVoted && !alreadyVoted) {
        final next = current + 1;
        tx.set(postRef, {'upvotes': next}, SetOptions(merge: true));
        tx.set(stateRef, {
          'voted': {postId: true}
        }, SetOptions(merge: true));
        return next;
      }
      return current; // already in the desired state
    });
  }

  /// Records that this user adopted [postId] and bumps the post's adopt count
  /// (once per user — a re-adopt is a no-op on the counter). Returns true when
  /// this was a NEW adoption (so the caller only creates the habit once).
  Future<bool> markAdopted(String uid, String postId) async {
    final postRef = _posts.doc(postId);
    final stateRef = _userState(uid);
    return _db.runTransaction<bool>((tx) async {
      final stateSnap = await tx.get(stateRef);
      final postSnap = await tx.get(postRef);
      final adopted = (stateSnap.data()?['adopted'] as Map?) ?? const {};
      if (adopted[postId] == true) return false; // already adopted

      final current = (postSnap.data()?['adopted'] is num)
          ? (postSnap.data()!['adopted'] as num).toInt()
          : 0;
      tx.set(postRef, {'adopted': current + 1}, SetOptions(merge: true));
      tx.set(stateRef, {
        'adopted': {postId: true}
      }, SetOptions(merge: true));
      return true;
    });
  }

  /// Seeds the curated starter Ideas Well the first time the collection is
  /// empty. Deterministic doc ids (`seed_N`) keep it idempotent if two clients
  /// race — both write identical content. Only runs while the collection is
  /// empty, so it never resets live community counts.
  Future<void> _seedIfEmpty() async {
    final batch = _db.batch();
    for (var i = 0; i < _seed.length; i++) {
      batch.set(_posts.doc('seed_${i + 1}'), {
        ..._seed[i],
        'seed': true,
        'createdAt': i, // stable ordering for equal upvotes
      });
    }
    await batch.commit();
  }
}

/// Curated starter content for a fresh install — the same set the screen used
/// to render from a hardcoded list, now promoted to real, upvotable/adoptable
/// Firestore documents.
const List<Map<String, dynamic>> _seed = [
  {
    'kind': 'habit',
    'core': 'physical',
    'pain': 'consistent exercise',
    'title': 'Lay gym clothes out the night before',
    'desc': 'Cuts morning decisions to zero — shoes by the door, kit on the chair.',
    'upvotes': 412,
    'adopted': 1180,
    'link': false,
  },
  {
    'kind': 'habit',
    'core': 'mindset',
    'pain': 'racing thoughts',
    'title': '10-min "brain dump" before bed',
    'desc': 'Empty every open loop onto paper so sleep comes faster.',
    'upvotes': 388,
    'adopted': 902,
    'link': false,
  },
  {
    'kind': 'mbm',
    'core': 'career',
    'pain': 'procrastination',
    'title': 'Make It Easy · 2-minute start rule',
    'desc': 'Commit to just opening the doc. Momentum does the rest.',
    'upvotes': 356,
    'adopted': 1410,
    'link': false,
  },
  {
    'kind': 'habit',
    'core': 'relationships',
    'pain': 'staying in touch',
    'title': 'Weekly 1-on-1 coffee, rotate friends',
    'desc': 'One scheduled connection beats ten missed intentions.',
    'upvotes': 301,
    'adopted': 640,
    'link': false,
  },
  {
    'kind': 'mbm',
    'core': 'physical',
    'pain': 'better sleep',
    'title': 'Make It Obvious · phone charges outside bedroom',
    'desc': 'No screen = earlier lights-out, automatically.',
    'upvotes': 289,
    'adopted': 733,
    'link': false,
  },
  {
    'kind': 'tech',
    'core': 'career',
    'pain': 'auto-saving',
    'title': 'Auto-transfer app · "round-up" savings',
    'desc': 'Rounds every purchase up and banks the difference.',
    'upvotes': 254,
    'adopted': 521,
    'link': true,
  },
  {
    'kind': 'habit',
    'core': 'emotional',
    'pain': 'stress spikes',
    'title': 'Box-breathing on the first deep breath cue',
    'desc': '4-4-4-4 the moment you notice tension in your chest.',
    'upvotes': 233,
    'adopted': 455,
    'link': false,
  },
  {
    'kind': 'tech',
    'core': 'mindset',
    'pain': 'focus',
    'title': 'Focus-timer app · 25/5 pomodoros',
    'desc': 'Community top pick for deep-work blocks.',
    'upvotes': 198,
    'adopted': 389,
    'link': true,
  },
];
