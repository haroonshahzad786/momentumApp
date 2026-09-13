import 'package:flutter/material.dart';

import '../../theme/momentum_tokens.dart';

/// Small shared pieces reused across the admin screens, so each screen file
/// stays focused on its own layout rather than redefining card chrome.

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key, required this.child, this.width});
  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: MM.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip({super.key, required this.status});
  final String status;

  Color get _color {
    switch (status) {
      case 'active':
        return MM.teal;
      case 'warned':
        return MM.yellow;
      case 'regressed':
      case 'suspended':
        return MM.red;
      case 'invited':
        return MM.blue;
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (status.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(status.toUpperCase(), style: MM.displayX(size: 8.5, color: _color)),
    );
  }
}

class AdminErrorView extends StatelessWidget {
  const AdminErrorView({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: MM.red, size: 32),
            const SizedBox(height: 12),
            Text('Failed to load', style: MM.display(size: 14, color: MM.white)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.5))),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class AdminRefreshButton extends StatelessWidget {
  const AdminRefreshButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.refresh, color: MM.blue, size: 16),
          const SizedBox(width: 6),
          Text('Refresh', style: MM.body(size: 12, color: MM.blue)),
        ]),
      ),
    );
  }
}

String adminShortWhen(String iso) {
  if (iso.isEmpty) return '';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  final local = dt.toLocal();
  return '${local.month}/${local.day} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

/// Shows a "not built yet" snackbar for design elements that exist visually
/// but have no real backend/UI behind them yet (bulk actions, CSV download
/// trigger, Add client, etc.) — visible and honest, not silently ignored.
void adminShowSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$feature — not built yet.')),
  );
}
