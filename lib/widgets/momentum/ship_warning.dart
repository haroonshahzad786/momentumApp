import 'package:flutter/material.dart';

import '../../theme/momentum_tokens.dart';
import 'mm_buttons.dart';

/// Ship Warning — 1 missed weekday check-in (#16, Gamification spec §6).
/// Warning only: no consequence yet. Supportive copy + a one-hour snooze
/// ("player can defer the reminder by 1 hour — respects autonomy").
class ShipWarningBanner extends StatelessWidget {
  const ShipWarningBanner({
    super.key,
    required this.onCheckIn,
    required this.onSnooze,
  });

  final VoidCallback onCheckIn;
  final VoidCallback onSnooze;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: MM.navy.withOpacity(0.96),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MM.yellow.withOpacity(0.55)),
          boxShadow: [BoxShadow(color: MM.yellow.withOpacity(0.18), blurRadius: 22)],
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('⚠️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('SHIP WARNING', style: MM.displayX(size: 10, color: MM.yellow)),
                      const SizedBox(height: 3),
                      Text(
                        'You missed your last check-in. Your rocket is losing momentum. '
                        'Check in today to stay on course!',
                        style: MM.body(size: 13, color: Colors.white, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
            Row(mainAxisSize: MainAxisSize.min, children: [
              MMGhostButton(
                label: 'Remind me in 1 hour',
                onPressed: onSnooze,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              const SizedBox(width: 8),
              MMPrimaryButton(
                label: 'Check in now',
                expand: false,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                onPressed: onCheckIn,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// Relaunch — 2+ missed weekday check-ins (#16; spec §6 "MISS 2 CONSECUTIVE";
/// Sequence doc Phase 2 "Post-Gap Re-engagement"). Relaunch, not punishment:
/// states what happened, confirms everything that's preserved, offers a
/// one-Core minimum check-in and the spec's [Get Support] paths.
class RelaunchSheet extends StatelessWidget {
  const RelaunchSheet({
    super.key,
    required this.missedWeekdays,
    required this.longAbsence,
    required this.pointsRemoved,
    required this.formedHabits,
    required this.spaceCredits,
    required this.level,
    required this.onQuickCheckIn,
    required this.onFullCheckIn,
    required this.onCaptainsLog,
    required this.onTalkToNova,
    required this.onCantina,
    required this.onClose,
  });

  final int missedWeekdays;

  /// 5+ weekdays away — "Welcome back, Captain" framing (PRD 7).
  final bool longAbsence;

  /// Momentum Points removed by the relaunch (0 while the amount is unset).
  final int pointsRemoved;
  final int formedHabits;
  final int spaceCredits;
  final String level;

  final VoidCallback onQuickCheckIn;
  final VoidCallback onFullCheckIn;
  final VoidCallback onCaptainsLog;
  final VoidCallback onTalkToNova;

  /// Null while the Cantina is still locked (Stage 2 not complete).
  final VoidCallback? onCantina;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withOpacity(0.65);
    final levelName = level.isEmpty ? 'Cadet' : level[0].toUpperCase() + level.substring(1);
    Widget safe(String icon, String label) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: MM.body(size: 13, color: Colors.white))),
            const Text('✅', style: TextStyle(fontSize: 12)),
          ]),
        );
    Widget support(String label, VoidCallback? onTap) => MMGhostButton(
          label: label,
          onPressed: onTap,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        );

    return Material(
      type: MaterialType.transparency,
      child: Stack(children: [
        Positioned.fill(child: Container(color: const Color(0xDD06070D))),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: MM.navy.withOpacity(0.97),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MM.blue.withOpacity(0.5)),
                  boxShadow: [BoxShadow(color: MM.blue.withOpacity(0.25), blurRadius: 30)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Text('🚀  RELAUNCH', style: MM.displayX(size: 11, color: MM.blue)),
                      const Spacer(),
                      InkWell(
                        onTap: onClose,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.close, size: 18, color: muted),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Text(
                      longAbsence ? 'Welcome back, Captain.' : "You're back.",
                      style: MM.display(size: 20, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      longAbsence
                          ? "No judgment — let's pick up where you can."
                          : "That's the only thing that matters right now. Let's relaunch.",
                      style: MM.body(size: 14, color: Colors.white, height: 1.45),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'You missed $missedWeekdays weekday check-in${missedWeekdays == 1 ? '' : 's'}, so your '
                      'streak has reset and your rocket drops back to its last checkpoint'
                      '${pointsRemoved > 0 ? ' (−$pointsRemoved Momentum Points)' : ''}. '
                      "That's relaunching, not failing.",
                      style: MM.body(size: 12.5, color: muted, height: 1.5),
                    ),
                    const SizedBox(height: 14),
                    Text('EVERYTHING THAT MATTERS IS SAFE',
                        style: MM.displayX(size: 9, color: Colors.white.withOpacity(0.5))),
                    const SizedBox(height: 8),
                    safe('🏆', 'Trophy Room · $formedHabits formed habit${formedHabits == 1 ? '' : 's'}'),
                    safe('💎', 'Space Credits · $spaceCredits'),
                    safe('🗂️', 'Momentum Lists & Captain\'s Log'),
                    safe('⭐', 'Level · $levelName'),
                    const SizedBox(height: 14),
                    MMPrimaryButton(
                      label: 'Quick relaunch · score 1 Core',
                      onPressed: onQuickCheckIn,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    const SizedBox(height: 8),
                    MMGhostButton(
                      label: 'Full check-in',
                      expand: true,
                      onPressed: onFullCheckIn,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    const SizedBox(height: 16),
                    Text('GET SUPPORT', style: MM.displayX(size: 9, color: Colors.white.withOpacity(0.5))),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      support("📋 Review Captain's Log", onCaptainsLog),
                      support('🤖 Talk to Nova', onTalkToNova),
                      if (onCantina != null) support('🍹 Space Cantina', onCantina),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
