import 'package:flutter/material.dart';
import '../../theme/momentum_tokens.dart';

/// Animated streak flame — scales gently and glows red/yellow.
/// Used on the dashboard and check-in summary.
class StreakFlame extends StatefulWidget {
  const StreakFlame({super.key, required this.days, this.size = 36});
  final int days;
  final double size;

  @override
  State<StreakFlame> createState() => _StreakFlameState();
}

class _StreakFlameState extends State<StreakFlame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale =
        0.6 + (widget.days.clamp(0, 365)) / 365 * 0.8;
    final intensity =
        widget.days >= 30 ? 1.0 : (widget.days >= 7 ? 0.7 : 0.4);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final wobble = 1 + _ctrl.value * 0.06;
        return Transform.scale(
          scale: scale * wobble,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _FlamePainter(intensity: intensity),
            ),
          ),
        );
      },
    );
  }
}

class _FlamePainter extends CustomPainter {
  _FlamePainter({required this.intensity});
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final shader = RadialGradient(
      center: const Alignment(0, 0.6),
      radius: 0.6,
      colors: const [
        Colors.white,
        MM.yellow,
        MM.red,
        Color(0x009B5CFF),
      ],
      stops: const [0.0, 0.35, 0.75, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final paint = Paint()
      ..shader = shader
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1 + intensity * 1.5);

    final path = Path();
    final w = size.width;
    final h = size.height;
    // Flame outline (approximate)
    path.moveTo(w * 0.5, h * 0.10);
    path.cubicTo(w * 0.32, h * 0.32, w * 0.20, h * 0.45, w * 0.20, h * 0.62);
    path.cubicTo(w * 0.20, h * 0.80, w * 0.32, h * 0.92, w * 0.50, h * 0.92);
    path.cubicTo(w * 0.68, h * 0.92, w * 0.80, h * 0.80, w * 0.80, h * 0.62);
    path.cubicTo(w * 0.80, h * 0.50, w * 0.65, h * 0.40, w * 0.60, h * 0.26);
    path.cubicTo(w * 0.58, h * 0.40, w * 0.50, h * 0.45, w * 0.46, h * 0.40);
    path.cubicTo(w * 0.46, h * 0.26, w * 0.50, h * 0.18, w * 0.50, h * 0.10);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FlamePainter old) =>
      old.intensity != intensity;
}
