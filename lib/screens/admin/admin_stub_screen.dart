import 'package:flutter/material.dart';

import '../../theme/momentum_tokens.dart';
import 'admin_widgets.dart';

/// Reachable-but-honest placeholder for sidebar sections that don't have a
/// real screen yet. Some of these DO have a working backend already (e.g.
/// Feature flags → adminSetFeatureFlag, Audit log → adminListAuditLog) —
/// this screen exists because no Flutter UI has been built on top of it yet,
/// not because nothing works.
class AdminStubScreen extends StatelessWidget {
  const AdminStubScreen({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Align(
        alignment: Alignment.topLeft,
        child: AdminPanel(
          width: 620,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title.toUpperCase(), style: MM.display(size: 14, color: MM.white)),
                const SizedBox(height: 10),
                Text(
                  'No screen built yet for this section. Some sections already have a working '
                  'backend (see ADMIN_PANEL_BACKEND_PLAN.md) — this is a UI gap, not necessarily '
                  'a missing feature.',
                  style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.6)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
