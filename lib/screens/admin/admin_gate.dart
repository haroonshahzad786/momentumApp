import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/admin_service.dart';
import '../../theme/momentum_tokens.dart';

/// #A0.6 2FA — PARKED (2026-09-25) until the project's Identity Platform
/// upgrade is approved. Must flip together with `ADMIN_REQUIRE_2FA` in
/// vf-bridge/functions-flutter/index.js, and only after the sign-in screen
/// handles `FirebaseAuthMultiFactorException`.
const bool kAdminRequire2fa = false;

/// Route guard for the admin panel (ADMIN_PANEL_BACKEND_PLAN.md §0 / #A0.2).
///
/// Verifies the signed-in user's server-issued `admin` custom claim before
/// rendering [child] — the sidebar/drawer only *hide* the entry point for
/// non-admins, they are not the access control. This is that access control,
/// and it force-refreshes the ID token so a claim granted moments ago (e.g.
/// via setAdminClaim.js right before a demo) is honored without a re-login.
///
/// #A0.6: `requireAdmin` also demands a second factor on the token, so an
/// admin without one is routed to authenticator-app enrollment, and an
/// enrolled admin whose session predates it re-verifies here.
class AdminGate extends StatefulWidget {
  const AdminGate({super.key, required this.child});

  final Widget child;

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  final _admin = AdminService();
  bool? _isAdmin;
  AdminMfaState? _mfa;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final ok = await _admin.isAdmin(forceRefresh: true);
    final mfa = ok && kAdminRequire2fa ? await _admin.mfaState() : null;
    if (mounted) {
      setState(() {
        _isAdmin = ok;
        _mfa = mfa;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdmin == null) {
      return const ColoredBox(
        color: MM.pageBg,
        child: Center(child: CircularProgressIndicator(color: MM.blue)),
      );
    }
    if (_isAdmin != true) {
      return const ColoredBox(
        color: MM.pageBg,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Not authorized.\nThis account does not have admin access.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );
    }
    switch (_mfa) {
      case AdminMfaState.notEnrolled:
        return _TotpEnrollView(admin: _admin, onDone: _check);
      case AdminMfaState.enrolledNeedsSignIn:
        return _TotpReverifyView(onDone: _check);
      case AdminMfaState.verified:
      case null:
        return widget.child;
    }
  }
}

/// Shared card chrome for the two 2FA screens.
class _MfaCard extends StatelessWidget {
  const _MfaCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: MM.pageBg,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: MM.panel,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: MM.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeField extends StatelessWidget {
  const _CodeField({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 6,
      style: const TextStyle(color: MM.white, letterSpacing: 6, fontSize: 20),
      textAlign: TextAlign.center,
      decoration: const InputDecoration(
        hintText: '6-digit code',
        hintStyle: TextStyle(color: Colors.white38, letterSpacing: 0),
        counterText: '',
      ),
      onSubmitted: (_) => onSubmit(),
    );
  }
}

String _mfaError(Object e) {
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-verification-code':
        return 'That code is wrong or expired. Try the current one.';
      case 'requires-recent-login':
        return 'For security, sign out and sign in again, then set up 2FA.';
      case 'operation-not-allowed':
        return 'Authenticator-app 2FA is not enabled for this Firebase project yet.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong password.';
    }
    return e.message ?? e.code;
  }
  return '$e';
}

/// First-time setup: scan a QR code into an authenticator app, confirm a code.
class _TotpEnrollView extends StatefulWidget {
  const _TotpEnrollView({required this.admin, required this.onDone});

  final AdminService admin;
  final VoidCallback onDone;

  @override
  State<_TotpEnrollView> createState() => _TotpEnrollViewState();
}

class _TotpEnrollViewState extends State<_TotpEnrollView> {
  final _code = TextEditingController();
  TotpSecret? _secret;
  String? _qrUrl;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      final secret = await widget.admin.startTotpEnrollment();
      final url = await secret.generateQrCodeUrl(
        accountName: FirebaseAuth.instance.currentUser?.email,
        issuer: 'Moore Momentum Admin',
      );
      if (mounted) {
        setState(() {
          _secret = secret;
          _qrUrl = url;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = _mfaError(e));
    }
  }

  Future<void> _confirm() async {
    final secret = _secret;
    if (secret == null || _code.text.trim().length != 6 || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.admin.finishTotpEnrollment(secret, _code.text.trim());
      widget.onDone();
    } catch (e) {
      if (mounted) setState(() => _error = _mfaError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final secret = _secret;
    return _MfaCard(
      title: 'Set up two-factor authentication',
      children: [
        const Text(
          'Admin accounts require an authenticator app (Google Authenticator, '
          '1Password, Authy…). Scan the code, then enter the 6-digit code it shows.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        const SizedBox(height: 16),
        if (_qrUrl != null) ...[
          Center(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: QrImageView(data: _qrUrl!, size: 200),
            ),
          ),
          const SizedBox(height: 12),
          const Text("Can't scan? Enter this key manually:",
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          SelectableText(secret!.secretKey,
              style: const TextStyle(
                  color: MM.white, fontFamily: 'monospace', fontSize: 13)),
          const SizedBox(height: 12),
          _CodeField(controller: _code, onSubmit: _confirm),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _confirm,
            style: FilledButton.styleFrom(backgroundColor: MM.blue),
            child: Text(_busy ? 'Verifying…' : 'Turn on 2FA'),
          ),
        ] else if (_error == null)
          const Center(child: CircularProgressIndicator(color: MM.blue)),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: MM.red)),
          if (secret == null)
            TextButton(onPressed: _start, child: const Text('Try again')),
        ],
      ],
    );
  }
}

/// Enrolled, but this session was signed in before 2FA (or without it):
/// re-authenticate with password + code to mint a token that carries the
/// second factor, without leaving the admin panel.
class _TotpReverifyView extends StatefulWidget {
  const _TotpReverifyView({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_TotpReverifyView> createState() => _TotpReverifyViewState();
}

class _TotpReverifyViewState extends State<_TotpReverifyView> {
  final _password = TextEditingController();
  final _code = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final cred = EmailAuthProvider.credential(
          email: user!.email!, password: _password.text);
      try {
        await user.reauthenticateWithCredential(cred);
      } on FirebaseAuthMultiFactorException catch (e) {
        final hint = e.resolver.hints.first;
        final assertion = await TotpMultiFactorGenerator.getAssertionForSignIn(
            hint.uid, _code.text.trim());
        await e.resolver.resolveSignIn(assertion);
      }
      widget.onDone();
    } catch (e) {
      if (mounted) setState(() => _error = _mfaError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _MfaCard(
      title: 'Verify it’s you',
      children: [
        const Text(
          'Admin access needs a two-factor sign-in. Enter your password and '
          'the code from your authenticator app.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: true,
          style: const TextStyle(color: MM.white),
          decoration: const InputDecoration(
              hintText: 'Password',
              hintStyle: TextStyle(color: Colors.white38)),
        ),
        const SizedBox(height: 8),
        _CodeField(controller: _code, onSubmit: _verify),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : _verify,
          style: FilledButton.styleFrom(backgroundColor: MM.blue),
          child: Text(_busy ? 'Verifying…' : 'Continue'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: MM.red)),
        ],
      ],
    );
  }
}
