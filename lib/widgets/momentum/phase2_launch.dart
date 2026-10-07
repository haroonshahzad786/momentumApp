import 'package:flutter/material.dart';

import '../../theme/momentum_tokens.dart';
import 'mm_buttons.dart';

/// Phase 1 → Phase 2 hand-off (#25 / P1-8), from the Phase 1 & 2 Sequence
/// doc: "PHASE 2 LAUNCH SEQUENCE — The Mission Begins", then "SECTION 0:
/// DASHBOARD ORIENTATION — Your Cockpit, Brief Tour Before Day 1 Begins"
/// (an interactive Next/Back tutorial, ~90 seconds, ending on the Daily
/// Check-In). Shown once, right after Stage 2 completes.

/// One stop on the cockpit tour.
typedef TourStep = ({String icon, String title, String body});

const _coreLabels = <String, (String, String)>{
  'physical': ('💪', 'Physical Health'),
  'mindset': ('🧠', 'Mindset'),
  'career': ('💰', 'Career & Finances'),
  'relationships': ('👥', 'Relationships'),
  'emotional': ('🧘', 'Emotional & Mental Health'),
};

/// The tour, in the Sequence doc's order. [web] swaps the phone's ☰ menu for
/// the desktop sidebar; [activeCores] (short ids) drives the Cores stop.
List<TourStep> cockpitTourSteps({
  required bool web,
  required List<String> activeCores,
}) {
  final cores = [
    for (final e in _coreLabels.entries)
      '${e.value.$1} ${e.value.$2}: '
          '${activeCores.contains(e.key) ? 'ACTIVE — your Golden Habit lives here.' : 'Locked.'}',
  ].join('\n');
  return [
    web
        ? (
          icon: '🧭',
          title: 'Left sidebar',
          body:
              'Routines, Habits, Tasks, Lists (your Command Center), Space Cantina '
              'and your Trophy Room. Everything lives here when you need it.',
        )
        : (
          icon: '☰',
          title: 'Top left — Menu',
          body:
              'Command Center, Space Cantina, Phase 1 return access, and settings. '
              'Everything lives in here when you need it.',
        ),
    (
      icon: '🏆',
      title: 'Trophy Room',
      body:
          'Every habit you form lands here. This is where your identity '
          'transformation becomes visible.',
    ),
    (
      icon: '📊',
      title: web ? 'Flight Data' : 'Top right — Stats Box',
      body:
          'Your planet, your Momentum Score, and your 7-day Balance %. At a glance — '
          'where you are and how balanced your growth is across all 5 Cores. '
          'Your ultimate goal: "Fire On All Cylinders" 🚀.',
    ),
    (
      icon: '🔥',
      title: 'Streak counter',
      body: 'Day 0. That changes the moment you complete today\'s check-in.',
    ),
    (
      icon: '🚀',
      title: 'Your rocket — your 5 Cores',
      body:
          '$cores\n\nLocked Cores light up the moment you create a Golden Habit '
          'with at least one MBM for it in Phase 1.',
    ),
    (
      icon: '🎯',
      title: 'Tip of the rocket',
      body:
          '🎯 Steering wheel → Command Center / Momentum Lists\n'
          '⏰ Clock → your Routines by time of day\n'
          '∞ Infinity → All Habits quick view\n'
          '☑️ Checklist → your Non-Routine habits',
    ),
    (
      icon: '▶️',
      title: 'Your Daily Check-In',
      body:
          'The most important button in your entire mission. Every morning. One '
          'press. Scoring begins — activating your streak, your rocket progress, '
          'your rewards, and more.',
    ),
  ];
}

/// "The Mission Begins" — the launch moment between Phase 1 and the tour.
class MissionBeginsOverlay extends StatelessWidget {
  const MissionBeginsOverlay({super.key, required this.onReady});
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    final lines = [
      'Phase 1: complete.',
      'Your Golden Habit is locked and loaded.',
      'Your MBMs are engineered.',
      'Your Space Cantina tribe is ready.',
    ];
    return Material(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 60, end: 0),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder:
                      (_, dy, child) => Transform.translate(
                        offset: Offset(0, dy),
                        child: child,
                      ),
                  child: const Text('🚀', style: TextStyle(fontSize: 64)),
                ),
                const SizedBox(height: 12),
                Text(
                  'LEVEL 2 COMPLETE ✅',
                  style: MM.displayX(size: 11, color: MM.teal),
                ),
                const SizedBox(height: 16),
                for (final l in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      l,
                      textAlign: TextAlign.center,
                      style: MM.body(color: Colors.white, size: 14),
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  'Now the real mission begins.',
                  textAlign: TextAlign.center,
                  style: MM.display(size: 20, color: MM.yellow),
                ),
                const SizedBox(height: 16),
                Text(
                  'Phase 2 is where everything you built in Phase 1 comes alive.\n'
                  'One check-in. Every morning. Score your habits. Log your wins. '
                  'Watch your rocket move.\n'
                  "That's the mission. It's simple by design.",
                  textAlign: TextAlign.center,
                  style: MM.body(
                    color: Colors.white.withOpacity(0.75),
                    size: 12.5,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 20),
                MMPrimaryButton(
                  label: 'Show me my cockpit →',
                  pulse: true,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onPressed: onReady,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The Next/Back cockpit tour. [onLaunch] starts Day 1's check-in;
/// [onClose] ends the tour without it.
class CockpitTourOverlay extends StatefulWidget {
  const CockpitTourOverlay({
    super.key,
    required this.steps,
    required this.onLaunch,
    required this.onClose,
  });

  final List<TourStep> steps;
  final VoidCallback onLaunch;
  final VoidCallback onClose;

  @override
  State<CockpitTourOverlay> createState() => _CockpitTourOverlayState();
}

class _CockpitTourOverlayState extends State<CockpitTourOverlay> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final last = _i == widget.steps.length - 1;
    final step = widget.steps[_i];
    return Material(
      color: Colors.black.withOpacity(0.55),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              color: MM.navy2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MM.yellow.withOpacity(0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'YOUR FLIGHT DECK · ${_i + 1}/${widget.steps.length}',
                      style: MM.displayX(size: 9, color: MM.yellow),
                    ),
                    const Spacer(),
                    if (!last)
                      TextButton(
                        onPressed: widget.onClose,
                        child: Text(
                          'Skip tour',
                          style: MM.body(color: Colors.white54, size: 12),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(step.icon, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        step.title,
                        style: MM.display(size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  step.body,
                  style: MM.body(
                    color: Colors.white.withOpacity(0.8),
                    size: 12.5,
                    height: 1.5,
                  ),
                ),
                if (last) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Ready to launch Day 1?',
                    style: MM.display(size: 15, color: MM.yellow),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (_i > 0)
                      IntrinsicWidth(
                        child: MMGhostButton(
                          label: '← Back',
                          onPressed: () => setState(() => _i--),
                        ),
                      ),
                    const Spacer(),
                    if (last) ...[
                      TextButton(
                        onPressed: widget.onClose,
                        child: Text(
                          'Later',
                          style: MM.body(color: Colors.white60, size: 13),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IntrinsicWidth(
                        child: MMPrimaryButton(
                          label: "Let's go 🚀",
                          pulse: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          onPressed: widget.onLaunch,
                        ),
                      ),
                    ] else
                      IntrinsicWidth(
                        child: MMPrimaryButton(
                          label: 'Next →',
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          onPressed: () => setState(() => _i++),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
