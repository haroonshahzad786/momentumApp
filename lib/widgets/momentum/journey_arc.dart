import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/momentum_tokens.dart';

/// Curved planet-journey path with planet markers + ship pulse on the arc.
class JourneyArc extends StatefulWidget {
  const JourneyArc({super.key, required this.planetIdx, this.progress = 0.38});
  final int planetIdx;
  final double progress;

  @override
  State<JourneyArc> createState() => _JourneyArcState();
}

class _JourneyArcState extends State<JourneyArc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 90,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, __) => CustomPaint(
          painter: _JourneyPainter(
            planetIdx: widget.planetIdx,
            progress: widget.progress,
            pulse: _pulse.value,
          ),
        ),
      ),
    );
  }
}

class _JourneyPainter extends CustomPainter {
  _JourneyPainter({
    required this.planetIdx,
    required this.progress,
    required this.pulse,
  });
  final int planetIdx;
  final double progress;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final planets = MM.planets;

    Offset arcPoint(double t) {
      final x = 14 + t * (w - 28);
      final y =
          (1 - t) * (1 - t) * (h - 14) + 2 * (1 - t) * t * (-10) + t * t * (h - 14);
      return Offset(x, y);
    }

    // Dashed arc
    final pathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = const LinearGradient(
        colors: [Color(0xB32A7DE1), Color(0x809B5CFF)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    final dashed = _dashedArc(arcPoint, 3, 4);
    canvas.drawPath(dashed, pathPaint);

    // Planet markers
    final segs = planets.length - 1;
    for (int i = 0; i < planets.length; i++) {
      final t = i / segs;
      final p = arcPoint(t);
      final reached = i <= planetIdx;
      final color = planets[i]['color'] as Color;
      final fillPaint = Paint()..color = reached ? color : Colors.transparent;
      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = reached ? color : Colors.white.withOpacity(0.3);
      final r = i == planetIdx ? 6.0 : 4.0;
      if (i == planetIdx) {
        canvas.drawCircle(
          p,
          r,
          Paint()
            ..color = color.withOpacity(0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
      canvas.drawCircle(p, r, fillPaint);
      canvas.drawCircle(p, r, strokePaint);

      // Label — CustomPaint bypasses MediaQuery textScaler so we size
      // these manually to ~1.2× the prior 7pt baseline.
      final tp = TextPainter(
        text: TextSpan(
          text: (planets[i]['name'] as String).toUpperCase(),
          style: TextStyle(
            fontSize: 8.5,
            color: reached ? Colors.white : Colors.white.withOpacity(0.5),
            letterSpacing: 0.85,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final yOffset = i < 2 ? -18.0 : 14.0;
      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy + yOffset));
    }

    // Ship marker on arc
    final t = math.min(1, (planetIdx + progress) / segs);
    final ship = arcPoint(t.toDouble());
    canvas.drawCircle(ship, 3, Paint()..color = Colors.white);
    final ringR = 6 + pulse * 8;
    canvas.drawCircle(
      ship,
      ringR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = Colors.white.withOpacity((1 - pulse) * 0.5),
    );
  }

  Path _dashedArc(Offset Function(double t) f, double dash, double gap) {
    final p = Path();
    const steps = 200;
    bool drawing = true;
    double covered = 0;
    Offset? cursor;
    for (int i = 0; i <= steps; i++) {
      final pt = f(i / steps);
      if (cursor == null) {
        p.moveTo(pt.dx, pt.dy);
        cursor = pt;
        continue;
      }
      final dx = pt.dx - cursor.dx;
      final dy = pt.dy - cursor.dy;
      final len = math.sqrt(dx * dx + dy * dy);
      covered += len;
      if (drawing) {
        p.lineTo(pt.dx, pt.dy);
        if (covered >= dash) {
          drawing = false;
          covered = 0;
        }
      } else {
        p.moveTo(pt.dx, pt.dy);
        if (covered >= gap) {
          drawing = true;
          covered = 0;
        }
      }
      cursor = pt;
    }
    return p;
  }

  @override
  bool shouldRepaint(covariant _JourneyPainter old) =>
      old.planetIdx != planetIdx ||
      old.progress != progress ||
      old.pulse != pulse;
}
