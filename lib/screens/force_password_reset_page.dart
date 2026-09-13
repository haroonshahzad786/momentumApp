import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/access_service.dart';
import '../theme/momentum_tokens.dart';
import '../widgets/momentum/mm_buttons.dart';

/// Blocks the app until the player sets a new password — shown when an admin
/// has set `users/{uid}.forcePasswordReset = true` (ADMIN_PANEL_BACKEND_PLAN.md
/// §3 / #A3.2, "Force reset on next sign-in"). The player is already signed
/// in at this point (Firebase requires a recent sign-in to change a
/// password), so this just calls `updatePassword` directly and clears the
/// flag on success.
class ForcePasswordResetPage extends StatefulWidget {
  const ForcePasswordResetPage({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<ForcePasswordResetPage> createState() => _ForcePasswordResetPageState();
}

class _ForcePasswordResetPageState extends State<ForcePasswordResetPage> {
  final _access = AccessService();
  final _newPasswordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _newPasswordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final newPassword = _newPasswordCtrl.text;
    if (newPassword.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (newPassword != _confirmCtrl.text) {
      setState(() => _error = "Passwords don't match.");
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'Not signed in.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await user.updatePassword(newPassword);
      await _access.clearForcePasswordReset(user.uid);
      if (mounted) widget.onDone();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _busy = false;
        _error = e.code == 'requires-recent-login'
            ? 'For your security, please sign out and back in, then try again.'
            : (e.message ?? 'Could not set a new password.');
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = 'Could not set a new password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MM.pageBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_reset, color: MM.yellow, size: 40),
                  const SizedBox(height: 16),
                  Text('Set a new password',
                      textAlign: TextAlign.center,
                      style: MM.display(color: Colors.white, size: 18)),
                  const SizedBox(height: 8),
                  Text(
                    'An admin has required a password reset on this account before you can continue.',
                    textAlign: TextAlign.center,
                    style: MM.body(color: Colors.white.withOpacity(0.6), size: 13),
                  ),
                  const SizedBox(height: 24),
                  _field('New password', _newPasswordCtrl),
                  const SizedBox(height: 12),
                  _field('Confirm new password', _confirmCtrl),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: MM.body(color: MM.red, size: 12.5)),
                  ],
                  const SizedBox(height: 20),
                  MMPrimaryButton(
                    label: 'Set password',
                    busy: _busy,
                    onPressed: _busy ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: MM.body(color: Colors.white, size: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: MM.body(color: Colors.white.withOpacity(0.4), size: 14),
        filled: true,
        fillColor: MM.navy.withOpacity(0.55),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: MM.blue.withOpacity(0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: MM.blue.withOpacity(0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: MM.blue),
        ),
      ),
    );
  }
}
