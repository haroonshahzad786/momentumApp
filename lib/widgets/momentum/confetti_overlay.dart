import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/momentum_tokens.dart';

/// Celebration confetti — a one-shot particle burst painted over whatever it's
/// stacked on. Used wherever the player is actually awarded points: the
/// Voiceflow `CELEBRATION` events in Phase 1, the Stage 2 "Momentified" unlock,
/// and the Daily Check-In recap.
///
/// Hand-rolled rather than a package: it's a single CustomPainter, keeps the
/// dependency list lean, and renders identically on web (the primary surface)
/// where a plugin-backed particle lib would be another asset to load.
///
/// Always non-interactive — it never eats a tap from the screen underneath
/// (several of the hosts are tap-to-dismiss overlays).
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    super.key,
    this.trigger = 0,
    this.count = 80,
    this.duration = const Duration(milliseconds: 2600),
    this.startDelay = const Duration(milliseconds: 150),
    this.origin = const Alignment(0, -0.45),
    this.haptics = true,
  });

  /// Bump this to replay the burst (e.g. the next award in a queue).
  final int trigger;

  /// Particles per burst. ~80 reads as generous without costing frames.
  final int count;

  final Duration duration;

  /// Small lead-in so the burst lands with the host's own entrance animation
  /// instead of firing before anything is on screen.
  final Duration startDelay;

  /// Launch point, in Alignment space (-1..1).
  final Alignment origin;

  /// Fire a medium impact when the burst starts (no-op on web/desktop).
  final bool haptics;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: widget.duration);
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = _spawn(widget.trigger);
    _play();
  }

  @override
  void didUpdateWidget(covariant ConfettiOverlay old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) {
      _particles = _spawn(widget.trigger);
      _ctrl.reset();
      _play();
    }
  }

  void _play() {
    Future.delayed(widget.startDelay, () {
      if (!mounted) return;
      if (widget.haptics) HapticFeedback.mediumImpact();
      _ctrl.forward(from: 0);
    });
  }

  /// Seeded off the trigger so consecutive bursts differ, but a rebuild of the
  /// same burst (a parent setState mid-flight) doesn't reshuffle the confetti.
  List<_Particle> _spawn(int seed) {
    final rnd = math.Random(seed * 7919 + widget.count);
    return List<_Particle>.generate(widget.count, (i) {
      // Fan upward and out: mostly vertical, spread either side of the origin.
      final angle = -math.pi / 2 + (rnd.nextDouble() - 0.5) * 2.1;
      final speed = 0.55 + rnd.nextDouble() * 0.85;
      return _Particle(
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        color: _palette[i % _palette.length],
        size: 5 + rnd.nextDouble() * 7,
        aspect: 0.35 + rnd.nextDouble() * 0.9,
        spin: (rnd.nextDouble() - 0.5) * 14,
        flutterRate: 3 + rnd.nextDouble() * 5,
        drag: 0.55 + rnd.nextDouble() * 0.4,
        round: i % 5 == 0,
      );
    });
  }

  static const _palette = <Color>[
    MM.yellow,
    MM.teal,
    MM.blue,
    MM.magenta,
    MM.violet,
    MM.red,
    Colors.white,
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              particles: _particles,
              t: _ctrl.value,
              origin: widget.origin,
            ),
          ),
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.aspect,
    required this.spin,
    required this.flutterRate,
    required this.drag,
    required this.round,
  });

  /// Launch velocity, in fractions of the overlay's short side per unit time.
  final double vx;
  final double vy;
  final Color color;

  /// Long edge, in logical pixels.
  final double size;

  /// Short edge as a fraction of [size].
  final double aspect;

  /// Rotations per unit time.
  final double spin;

  /// Foil-flutter rate — squashes the piece horizontally as it tumbles.
  final double flutterRate;

  /// Air resistance applied to the launch velocity.
  final double drag;

  /// Round pieces mixed in with the rectangles.
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.particles,
    required this.t,
    required this.origin,
  });

  final List<_Particle> particles;

  /// 0..1 progress through the burst.
  final double t;
  final Alignment origin;

  static const _gravity = 1.15;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final short = math.min(size.width, size.height);
    final ox = (origin.x + 1) / 2 * size.width;
    final oy = (origin.y + 1) / 2 * size.height;
    // Fade the tail of the burst rather than snapping the pieces off screen.
    final fade = t < 0.72 ? 1.0 : (1 - (t - 0.72) / 0.28).clamp(0.0, 1.0);
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      // Launch velocity decays exponentially; gravity keeps pulling.
      final travel = (1 - math.exp(-p.drag * t * 3)) / p.drag;
      final x = ox + p.vx * travel * short;
      final y = oy + p.vy * travel * short + 0.5 * _gravity * t * t * short;
      if (y > size.height + 40) continue;

      paint.color = p.color.withOpacity(fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size * 0.32, paint);
      } else {
        // The horizontal squash reads as a piece tumbling edge-on.
        final w = p.size * math.cos(p.flutterRate * t * math.pi).abs();
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: math.max(w, 1),
              height: p.size * p.aspect,
            ),
            const Radius.circular(1.2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.t != t || old.particles != particles || old.origin != origin;
}

/// A "+N MP" badge that pops in with an elastic overshoot and keeps a soft glow
/// pulse. Pairs with [ConfettiOverlay] at the moment an award lands, so the
/// number itself is the thing being celebrated.
class PointsPopBadge extends StatefulWidget {
  const PointsPopBadge({
    super.key,
    required this.label,
    this.color = MM.yellow,
    this.fontSize = 30,
    this.delay = const Duration(milliseconds: 150),
  });

  /// Pre-formatted, e.g. '+10 MP'.
  final String label;
  final Color color;
  final double fontSize;
  final Duration delay;

  @override
  State<PointsPopBadge> createState() => _PointsPopBadgeState();
}

class _PointsPopBadgeState extends State<PointsPopBadge>
    with TickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _pop.forward();
    });
  }

  @override
  void dispose() {
    _pop.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pop = CurvedAnimation(parent: _pop, curve: Curves.elasticOut);
    return AnimatedBuilder(
      animation: Listenable.merge([pop, _glow]),
      builder: (_, __) {
        final glow = 10 + _glow.value * 14;
        return Opacity(
          opacity: _pop.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.4 + pop.value * 0.6,
            child: Text(
              widget.label,
              style: MM
                  .display(size: widget.fontSize, color: widget.color, height: 1)
                  .copyWith(
                shadows: [
                  Shadow(color: widget.color.withOpacity(0.7), blurRadius: glow),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
