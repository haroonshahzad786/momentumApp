import 'package:flutter/material.dart';

import '../../theme/momentum_tokens.dart';
import 'confetti_overlay.dart';
import 'mm_buttons.dart';

/// Cores that became active since the player last saw the rocket. [seen] null
/// = first look on this device: nothing to celebrate (the Sequence: "unlock
/// animation triggered on first habit creation — not on login").
List<String> newlyUnlockedCores(List<String>? seen, List<String> active) {
  if (seen == null) return const [];
  return [
    for (final c in active)
      if (!seen.contains(c)) c,
  ];
}

/// "CORE UNLOCKED" celebration (#30 / P1-7): a Core lights up the first time
/// a Golden Habit is forged in it.
class CoreUnlockOverlay extends StatelessWidget {
  const CoreUnlockOverlay({
    super.key,
    required this.emoji,
    required this.name,
    required this.color,
    required this.onContinue,
  });

  final String emoji;
  final String name;
  final Color color;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.72),
      child: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.3, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.elasticOut,
                      builder:
                          (_, v, child) =>
                              Transform.scale(scale: v, child: child),
                      child: Container(
                        width: 104,
                        height: 104,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.18),
                          border: Border.all(color: color, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.6),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'CORE UNLOCKED',
                      style: MM.displayX(size: 12, color: color),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: MM.display(size: 22, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your Golden Habit lit up this Core. Keep fueling it — '
                      'every habit you form here adds momentum to your rocket.',
                      textAlign: TextAlign.center,
                      style: MM.body(
                        color: Colors.white.withOpacity(0.75),
                        size: 12.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    MMPrimaryButton(
                      label: 'Continue 🚀',
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      onPressed: onContinue,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: ConfettiOverlay(count: 90, origin: Alignment(0, -0.35)),
            ),
          ),
        ],
      ),
    );
  }
}
