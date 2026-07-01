import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/momentum_tokens.dart';

/// Animated starfield + radial nebula background.
/// Drop this at the bottom of a Stack — paints itself, ignores hits.
class StarfieldBackground extends StatefulWidget {
  const StarfieldBackground({
    super.key,
    this.showScanlines = true,
    this.accent,
  });

  final bool showScanlines;
  final Color? accent;

  @override
  State<StarfieldBackground> createState() => _StarfieldBackgroundState();
}

class _StarfieldBackgroundState extends State<StarfieldBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _twinkle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _twinkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent ?? MM.blue;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // base radial nebula
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -1.2),
                radius: 1.3,
                colors: [
                  accent.withOpacity(0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, 1.2),
                radius: 1.5,
                colors: [Color(0x269B5CFF), Colors.transparent],
              ),
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [Color(0xFF111C4E), Color(0xFF060B22), Color(0xFF02030A)],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),
          // stars
          AnimatedBuilder(
            animation: _twinkle,
            builder: (_, __) => CustomPaint(
              painter: _StarsPainter(opacity: 0.55 + _twinkle.value * 0.35),
            ),
          ),
          if (widget.showScanlines)
            CustomPaint(painter: _ScanlinesPainter()),
        ],
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  _StarsPainter({required this.opacity});
  final double opacity;

  // Fixed seed so stars don't jitter between frames.
  static final List<_Star> _stars = _generate();

  static List<_Star> _generate() {
    final rng = math.Random(42);
    return List.generate(60, (_) {
      final r = rng.nextDouble();
      return _Star(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: 0.6 + rng.nextDouble() * 1.4,
        color: r < 0.85
            ? Colors.white
            : (r < 0.92
                ? const Color(0xFFFFC88C)
                : const Color(0xFF8CC8FF)),
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in _stars) {
      final paint = Paint()..color = s.color.withOpacity(opacity);
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter old) => old.opacity != opacity;
}

class _Star {
  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
  });
  final double x;
  final double y;
  final double radius;
  final Color color;
}

class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinesPainter old) => false;
}
