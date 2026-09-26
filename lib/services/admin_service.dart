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
enum AdminMfaState { notEnrolled, enrolledNeedsSignIn, verified }

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

  /// #A0.6 — where the signed-in admin stands on the required second factor.
  /// `requireAdmin` rejects any token without `firebase.sign_in_second_factor`,
  /// so the gate uses this to route to enrollment / re-sign-in instead of
  /// letting every admin screen fail with 403s.
  Future<AdminMfaState> mfaState() async {
    final user = _auth.currentUser;
    if (user == null) return AdminMfaState.notEnrolled;
    final factors = await user.multiFactor.getEnrolledFactors();
    if (factors.isEmpty) return AdminMfaState.notEnrolled;
    final token = await user.getIdTokenResult(true);
    final fb = token.claims?['firebase'];
    final second = fb is Map ? fb['sign_in_second_factor'] : null;
    return second != null
        ? AdminMfaState.verified
        : AdminMfaState.enrolledNeedsSignIn;
  }

  /// Starts authenticator-app (TOTP) enrollment. Throws
  /// `requires-recent-login` if the session is old — callers ask for re-sign-in.
  Future<TotpSecret> startTotpEnrollment() async {
    final session = await _auth.currentUser!.multiFactor.getSession();
    return TotpMultiFactorGenerator.generateSecret(session);
  }

  Future<void> finishTotpEnrollment(TotpSecret secret, String code) async {
    final assertion =
        await TotpMultiFactorGenerator.getAssertionForEnrollment(secret, code);
    await _auth.currentUser!.multiFactor
        .enroll(assertion, displayName: 'Authenticator app');
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
