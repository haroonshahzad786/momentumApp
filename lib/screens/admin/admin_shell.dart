import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/momentum_tokens.dart';
import '../../widgets/momentum/starfield.dart';
import 'admin_client_detail_screen.dart';
import 'admin_clients_screen.dart';
import 'admin_overview_screen.dart';
import 'admin_stub_screen.dart';

/// One destination in the admin sidebar. Mirrors the nav groups in
/// design/ref/admin-panel-export/Admin Panel.dc.html exactly, so every
/// section the design promises is reachable — sections with no backend (or
/// no screen) yet land on [AdminStubScreen] instead of being hidden, so the
/// nav is honest about what's really built.
class AdminNavItem {
  const AdminNavItem(this.key, this.label);
  final String key;
  final String label;
}

const List<(String, List<AdminNavItem>)> kAdminNavGroups = [
  ('MONITOR', [
    AdminNavItem('overview', 'Overview'),
    AdminNavItem('checks', 'Daily Checks'),
    AdminNavItem('analytics', 'Analytics'),
  ]),
  ('PEOPLE', [
    AdminNavItem('clients', 'Clients'),
    AdminNavItem('cantina', 'Cantina'),
  ]),
  ('PRODUCT', [
    AdminNavItem('habits', 'Habits library'),
    AdminNavItem('lists', 'Momentum lists'),
    AdminNavItem('economy', 'Economy'),
    AdminNavItem('content', 'Content'),
  ]),
  ('SYSTEM', [
    AdminNavItem('integrations', 'Integrations'),
    AdminNavItem('access', 'Access & passwords'),
    AdminNavItem('flags', 'Feature flags'),
    AdminNavItem('audit', 'Audit log'),
  ]),
];

/// Sections with a real, working screen behind them today. Everything else
/// in [kAdminNavGroups] renders [AdminStubScreen] — reachable, not hidden,
/// but honestly not built rather than faked.
const Set<String> kAdminBuiltScreens = {'overview', 'clients'};

/// The admin panel — a full-screen takeover matching
/// design/ref/admin-panel-export/Admin Panel.dc.html exactly: one sidebar
/// (brand + nav groups + account footer) and the selected section filling
/// everything else. This is a top-level replacement for the whole app UI
/// while active (see momentum_home.dart's `build()` — 'admin' short-circuits
/// before WebShell/mobile chrome is built at all), the same way the
/// signed-out AuthFlow replaces the whole app rather than nesting inside it.
/// Admin is a different persona from the player-facing app, not another
/// screen within it.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key, this.onExitAdmin});

  /// Wired to whatever the host uses to leave admin and return to the
  /// player-facing app (e.g. back to the Cockpit) — reachable from the
  /// brand header at the top of the sidebar.
  final VoidCallback? onExitAdmin;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  String _screen = 'overview';
  String? _clientUid;

  void _go(String key) => setState(() {
        _screen = key;
        _clientUid = null;
      });

  void _openClient(String uid) => setState(() => _clientUid = uid);
  void _closeClient() => setState(() => _clientUid = null);

  Widget _buildContent() {
    if (_clientUid != null) {
      return AdminClientDetailScreen(uid: _clientUid!, onBack: _closeClient);
    }
    if (_screen == 'clients') {
      return AdminClientsScreen(onOpenClient: _openClient);
    }
    if (_screen == 'overview') {
      return const AdminOverviewScreen();
    }
    final label = kAdminNavGroups
        .expand((g) => g.$2)
        .firstWhere((i) => i.key == _screen, orElse: () => const AdminNavItem('', ''))
        .label;
    return AdminStubScreen(title: label);
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'admin';

    return Scaffold(
      backgroundColor: MM.pageBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Sidebar(current: _screen, onNav: _go, email: email, onExitAdmin: widget.onExitAdmin),
              Expanded(child: _buildContent()),
            ],
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.current, required this.onNav, required this.email, this.onExitAdmin});

  final String current;
  final void Function(String key) onNav;
  final String email;
  final VoidCallback? onExitAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 236,
      decoration: BoxDecoration(
        color: MM.navy2,
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.18))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onExitAdmin,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Row(children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: MM.blue, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.rocket_launch, color: Colors.white, size: 15),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('MOORE MOMENTUM', style: MM.displayX(size: 11.5, color: MM.white)),
                      const SizedBox(height: 2),
                      Text('Admin panel', style: MM.body(size: 10.5, color: Colors.white.withOpacity(0.36))),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final group in kAdminNavGroups) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                    child: Text(group.$1, style: MM.displayX(size: 9.5, color: Colors.white.withOpacity(0.36))),
                  ),
                  for (final item in group.$2) _NavRow(item: item, active: current == item.key, onTap: () => onNav(item.key)),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.18)))),
            child: Row(children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)),
                alignment: Alignment.center,
                child: Text(email.isNotEmpty ? email[0].toUpperCase() : '?', style: MM.body(size: 10, color: MM.white, weight: FontWeight.w700)),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(email, overflow: TextOverflow.ellipsis, style: MM.body(size: 11.5, color: MM.white)),
                    Text('Owner · admin claim', style: MM.body(size: 10, color: Colors.white.withOpacity(0.36))),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.item, required this.active, required this.onTap});
  final AdminNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final built = kAdminBuiltScreens.contains(item.key);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        color: active ? Colors.white.withOpacity(0.06) : null,
        child: Row(children: [
          Container(width: 3, height: 14, color: active ? MM.blue : Colors.transparent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: MM.body(
                size: 12.5,
                color: active ? MM.white : Colors.white.withOpacity(built ? 0.75 : 0.4),
                weight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (!built) Text('soon', style: MM.displayX(size: 8, color: Colors.white.withOpacity(0.3))),
        ]),
      ),
    );
  }
}
