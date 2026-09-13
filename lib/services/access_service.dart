import 'package:cloud_firestore/cloud_firestore.dart';

/// Client-side half of the admin "Force reset on next sign-in" action
/// (ADMIN_PANEL_BACKEND_PLAN.md §3 / #A3.2). The admin endpoint
/// (`adminClientAccess`, action `force_password_reset`) sets
/// `users/{uid}.forcePasswordReset = true`; this service reads that flag at
/// sign-in and clears it once the player actually sets a new password —
/// direct Firestore, same pattern as check-ins (owner-write already covered
/// by the existing `users/{uid}/{document=**}` rule, no new rule needed).
class AccessService {
  AccessService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<bool> forcePasswordResetRequired(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    return (snap.data() ?? const {})['forcePasswordReset'] == true;
  }

  Future<void> clearForcePasswordReset(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .set({'forcePasswordReset': false}, SetOptions(merge: true));
  }
}
