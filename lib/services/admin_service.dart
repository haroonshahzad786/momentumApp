import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Reads the signed-in user's `admin` custom claim (ADMIN_PANEL_BACKEND_PLAN.md
/// §0). The claim is granted server-side only, via
/// `vf-bridge/functions-flutter/scripts/setAdminClaim.js` — there is no
/// in-app way to become an admin.
///
/// A claim granted while the app is running (or in a prior session) is not
/// visible on a cached ID token, so callers that need the current truth
/// (the route guard, the sidebar nav check) should force-refresh.
class AdminService {
  AdminService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Future<bool> isAdmin({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final result = await user.getIdTokenResult(forceRefresh);
    return result.claims?['admin'] == true;
  }

  /// The real published config version (`config/_meta.version`, bumped by
  /// `adminSetConfig` on every publish — #A7.3). `config/*` is signed-in-read
  /// per the §0 rules, so this is a direct Firestore read, no new endpoint.
  /// Null if the doc doesn't exist yet (no config published) or the read
  /// fails — callers show no pill rather than a fabricated number.
  Future<int?> configVersion() async {
    try {
      final snap = await _db.collection('config').doc('_meta').get();
      final v = snap.data()?['version'];
      return v is num ? v.toInt() : null;
    } catch (_) {
      return null;
    }
  }
}
