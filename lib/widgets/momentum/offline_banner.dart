import 'package:flutter/material.dart';

import '../../theme/momentum_tokens.dart';
import 'mm_buttons.dart';

/// Slim banner shown above cached content when the last refresh failed because
/// the device is offline. Tapping REFRESH re-runs the fetch.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.onRefresh, this.busy = false});

  final VoidCallback onRefresh;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: MM.yellow.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MM.yellow.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 16, color: MM.yellow),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "You're offline — showing saved data",
              style: MM.body(color: Colors.white.withOpacity(0.85), size: 11.5),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: busy ? null : onRefresh,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: MM.yellow.withOpacity(0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: MM.yellow.withOpacity(0.55)),
              ),
              child: busy
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: MM.yellow),
                    )
                  : Text('REFRESH',
                      style: MM.display(
                          size: 10,
                          color: MM.yellow,
                          weight: FontWeight.w700,
                          letterSpacing: 10 * 0.1)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clean full-screen offline state shown when a load fails on the network AND
/// there's no saved data to fall back to (e.g. first run while offline). Avoids
/// dumping the raw SocketException at the user.
class OfflineErrorView extends StatelessWidget {
  const OfflineErrorView({super.key, required this.onRetry, this.what});

  final VoidCallback onRetry;

  /// Optional noun for the message, e.g. "your Golden Habits", "your lists".
  final String? what;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.cloud_off, color: Colors.white.withOpacity(0.5), size: 40),
          const SizedBox(height: 12),
          Text("You're offline",
              textAlign: TextAlign.center,
              style: MM.display(size: 15, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            "We couldn't reach the server${what == null ? '' : ' to load $what'}. "
            "Saved data will show here once you've loaded it online. "
            "Check your connection and try again.",
            textAlign: TextAlign.center,
            style: MM.body(color: Colors.white.withOpacity(0.55), size: 12),
          ),
          const SizedBox(height: 16),
          MMGhostButton(label: 'Retry', onPressed: onRetry),
        ],
      ),
    );
  }
}
