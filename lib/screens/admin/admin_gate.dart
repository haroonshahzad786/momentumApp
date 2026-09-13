import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../theme/momentum_tokens.dart';

/// Route guard for the admin panel (ADMIN_PANEL_BACKEND_PLAN.md §0 / #A0.2).
///
/// Verifies the signed-in user's server-issued `admin` custom claim before
/// rendering [child] — the sidebar/drawer only *hide* the entry point for
/// non-admins, they are not the access control. This is that access control,
/// and it force-refreshes the ID token so a claim granted moments ago (e.g.
/// via setAdminClaim.js right before a demo) is honored without a re-login.
class AdminGate extends StatefulWidget {
  const AdminGate({super.key, required this.child});

  final Widget child;

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  final _admin = AdminService();
  bool? _isAdmin;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final ok = await _admin.isAdmin(forceRefresh: true);
    if (mounted) setState(() => _isAdmin = ok);
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
    return widget.child;
  }
}
