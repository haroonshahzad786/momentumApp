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

/// Cockpit elements the tour can spotlight. A widget opts in with
/// `KeyedSubtree(key: tourKey('streak'), …)`; a step whose target isn't on
/// screen simply shows without a spotlight.
final Map<String, GlobalKey> _tourKeys = {};
GlobalKey tourKey(String id) => _tourKeys.putIfAbsent(id, GlobalKey.new);

/// Sub-areas of a keyed element, as fractions of its box (left, top, w, h) —
/// e.g. the quick-access icons sit at the tip of the rocket.
const Map<String, Rect> _tourRegions = {
  'tip': Rect.fromLTWH(0.22, 0.09, 0.56, 0.2),
};

/// What each step in [cockpitTourSteps] spotlights ('id' or 'id:region').
List<String?> cockpitTourTargets({required bool web}) => [
  web ? 'sidebar' : 'menu',
  'trophy',
  'stats',
  'streak',
  'rocket',
  'rocket:tip',
  'checkin',
];

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
    this.targets = const [],
    required this.onLaunch,
    required this.onClose,
  });

  final List<TourStep> steps;

  /// Per-step spotlight targets, aligned with [steps] (see [cockpitTourTargets]).
  final List<String?> targets;
  final VoidCallback onLaunch;
  final VoidCallback onClose;

  @override
  State<CockpitTourOverlay> createState() => _CockpitTourOverlayState();
}

class _CockpitTourOverlayState extends State<CockpitTourOverlay>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _i = 0;
  Rect? _hole;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMeasure();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulse.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() => _scheduleMeasure();

  void _go(int i) {
    setState(() => _i = i);
    _scheduleMeasure();
  }

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure(scroll: true));
  }

  /// Finds the current step's target on screen (scrolling it into view first)
  /// and stores its rect in this overlay's own coordinates.
  void _measure({bool scroll = false}) {
    if (!mounted) return;
    final spec = _i < widget.targets.length ? widget.targets[_i] : null;
    Rect? hole;
    if (spec != null) {
      final parts = spec.split(':');
      final ctx = tourKey(parts[0]).currentContext;
      if (ctx != null && ctx.mounted) {
        if (scroll && Scrollable.maybeOf(ctx) != null) {
          Scrollable.ensureVisible(ctx, alignment: 0.3, duration: Duration.zero);
        }
        final box = ctx.findRenderObject() as RenderBox?;
        final me = context.findRenderObject() as RenderBox?;
        if (box != null && box.attached && box.hasSize && me != null) {
          var r = me.globalToLocal(box.localToGlobal(Offset.zero)) & box.size;
          if (parts.length > 1) {
            final f = _tourRegions[parts[1]];
            if (f != null) {
              r = Rect.fromLTWH(
                r.left + r.width * f.left,
                r.top + r.height * f.top,
                r.width * f.width,
                r.height * f.height,
              );
            }
          }
          if (r.width > 0 && r.height > 0) hole = r.inflate(8);
        }
      }
    }
    if (hole != _hole) setState(() => _hole = hole);
    // A scroll can land a frame late — settle once more.
    if (scroll && spec != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _i == widget.steps.length - 1;
    final step = widget.steps[_i];
    final hole = _hole;
    final size = MediaQuery.of(context).size;
    final h = size.height;
    // Keep the card out of the spotlight: top when the target is low, or to
    // the roomier side when the target is tall (the rocket).
    final cardTop = hole != null && hole.center.dy > h * 0.55;
    final tall = hole != null && hole.height > h * 0.4 && hole.left > 40;
    final leftRoom = hole?.left ?? 0;
    final rightRoom = hole == null ? 0.0 : size.width - hole.right;
    final sideLeft = leftRoom >= rightRoom;
    final cardMax = tall ? (sideLeft ? leftRoom : rightRoom) - 32 : 520.0;
    return Material(
      color: hole == null ? Colors.black.withOpacity(0.55) : Colors.transparent,
      child: Stack(
        children: [
          if (hole != null)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder:
                      (_, __) => CustomPaint(
                        painter: _SpotlightPainter(hole, _pulse.value),
                      ),
                ),
              ),
            ),
          Align(
            alignment:
                tall && cardMax >= 280
                    ? (sideLeft ? Alignment.centerLeft : Alignment.centerRight)
                    : (cardTop ? Alignment.topCenter : Alignment.bottomCenter),
            child: ConstrainedBox(
          constraints: BoxConstraints(
                maxWidth: tall && cardMax >= 280 ? cardMax.clamp(280.0, 520.0) : 520,
              ),
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
                          onPressed: () => _go(_i - 1),
                        ),
                      ),
                    const Spacer(),
                    if (last) ...[
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 36),
                        ),
                        onPressed: widget.onClose,
                        child: Text(
                          'Later',
                          style: MM.body(color: Colors.white60, size: 13),
                        ),
                      ),
                      const SizedBox(width: 2),
                      IntrinsicWidth(
                        child: MMPrimaryButton(
                          label: "Let's go 🚀",
                          pulse: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
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
                          onPressed: () => _go(_i + 1),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
        ],
      ),
    );
  }
}

/// Dims everything except [hole], with a pulsing yellow ring around it.
class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter(this.hole, this.t);
  final Rect hole;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(hole, const Radius.circular(12));
    final scrim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(rr),
    );
    canvas.drawPath(scrim, Paint()..color = Colors.black.withOpacity(0.68));
    canvas.drawRRect(
      rr.inflate(2 + 4 * t),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = MM.yellow.withOpacity(0.35 + 0.5 * (1 - t))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + 4 * t),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = MM.yellow,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.hole != hole || old.t != t;
}
