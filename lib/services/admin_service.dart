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
  AdminService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Future<bool> isAdmin({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final result = await user.getIdTokenResult(forceRefresh);
    return result.claims?['admin'] == true;
  }
}
