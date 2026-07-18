import 'package:cloud_firestore/cloud_firestore.dart';

/// The three time-horizon buckets a task lives in. Stored as the string id.
enum TaskBucket { today, tomorrow, later }

extension TaskBucketX on TaskBucket {
  String get id => name; // 'today' | 'tomorrow' | 'later'
  String get label {
    switch (this) {
      case TaskBucket.today:
        return 'Today';
      case TaskBucket.tomorrow:
        return 'Tomorrow';
      case TaskBucket.later:
        return 'Later';
    }
  }

  static TaskBucket fromId(String? id) {
    switch (id) {
      case 'tomorrow':
        return TaskBucket.tomorrow;
      case 'later':
        return TaskBucket.later;
      default:
        return TaskBucket.today;
    }
  }
}

/// One user task. Persisted directly to Firestore from Flutter — the same
/// direct-write pattern the Daily Check-In ([CheckinService]) and Cantina
/// messaging use (no cloud-function endpoint; stays on the Flutter side of the
/// system per the backend-isolation rule).
///
/// NOTE: tasks do NOT award Momentum Points — the per-task point value is part
/// of the (undesigned, [PLACEHOLDER]) Phase-2 economy and is deliberately not
/// wired here, so no fabricated rewards leak in.
class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.bucket,
    required this.done,
    required this.createdAt,
  });

  final String id;
  final String title;
  final TaskBucket bucket;
  final bool done;
  final int createdAt; // client millisSinceEpoch — stable ordering within bucket

  TaskItem copyWith({String? title, TaskBucket? bucket, bool? done}) => TaskItem(
        id: id,
        title: title ?? this.title,
        bucket: bucket ?? this.bucket,
        done: done ?? this.done,
        createdAt: createdAt,
      );

  factory TaskItem.fromDoc(String id, Map<String, dynamic> data) => TaskItem(
        id: id,
        title: (data['title'] ?? '').toString(),
        bucket: TaskBucketX.fromId(data['bucket'] as String?),
        done: data['done'] == true,
        createdAt: (data['createdAt'] is num)
            ? (data['createdAt'] as num).toInt()
            : 0,
      );
}

/// Reads and writes the user's tasks at `/users/{uid}/tasks/{taskId}`.
/// cloud_firestore's on-device cache means reads/writes work offline and sync
/// on reconnect, so no separate LocalCache layer is needed here.
class TaskService {
  TaskService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('tasks');

  /// All tasks, ordered oldest-first (stable append order within each bucket).
  Future<List<TaskItem>> getAll(String uid) async {
    final snap = await _col(uid).orderBy('createdAt').get();
    return snap.docs.map((d) => TaskItem.fromDoc(d.id, d.data())).toList();
  }

  /// Creates a task and returns its generated id.
  Future<String> add({
    required String uid,
    required String title,
    required TaskBucket bucket,
    required int createdAt,
  }) async {
    final ref = _col(uid).doc();
    await ref.set({
      'title': title.trim(),
      'bucket': bucket.id,
      'done': false,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> update(
    String uid,
    String taskId, {
    String? title,
    TaskBucket? bucket,
    bool? done,
  }) async {
    final data = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (title != null) data['title'] = title.trim();
    if (bucket != null) data['bucket'] = bucket.id;
    if (done != null) data['done'] = done;
    await _col(uid).doc(taskId).set(data, SetOptions(merge: true));
  }

  Future<void> delete(String uid, String taskId) async =>
      _col(uid).doc(taskId).delete();
}
