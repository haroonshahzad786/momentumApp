import 'package:cloud_firestore/cloud_firestore.dart';

/// Client read of the `config/*` tree the admin Economy screen publishes
/// (BACKEND_PLAN.md #B1/#B2, admin #A7.2). The Cloud Functions apply the real
/// reward math from the same docs; the app only needs display values here.
///
/// `config/*` is signed-in-read (§0 rules). Every getter falls back to the
/// values that were hardcoded before, so a failed read or a missing/invalid
/// field never breaks a screen.
class EconomyConfigService {
  EconomyConfigService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const defaultStreakMilestones = [3, 7, 14, 30, 60, 90, 180, 365];

  /// Last successfully read value, shared across instances for this session.
  static List<int>? _milestonesCache;

  Future<List<int>> streakMilestones() async {
    final cached = _milestonesCache;
    if (cached != null) return cached;
    try {
      final snap = await _db.collection('config').doc('streaks').get();
      final raw = snap.data()?['milestones'];
      if (raw is List) {
        final parsed = raw
            .whereType<num>()
            .map((n) => n.toInt())
            .where((n) => n > 0)
            .toSet()
            .toList()
          ..sort();
        if (parsed.isNotEmpty) return _milestonesCache = parsed;
      }
    } catch (_) {
      // Fall through to defaults (offline / rules / not seeded).
    }
    return defaultStreakMilestones;
  }
}
