import 'package:flutter/material.dart';
import '../../theme/momentum_tokens.dart';

/// The Habits Hierarchy pyramid: 5 stacked trapezoid bands.
/// Tip (id 5) = Golden Habit, base (id 1) = Pain Point.
///
/// `active` = the band number currently in progress (1..5).
/// `completed` = list of band numbers already finished.
/// `compact` = short variant for in-section headers.
class HHSPyramid extends StatelessWidget {
  const HHSPyramid({
    super.key,
    this.active = 0,
    this.completed = const [],
    this.compact = false,
  });

  final int active;
  final List<int> completed;
  final bool compact;

  static const _bands = [
    _Band(5, 'forge', 'Golden Habit', 'Golden Habit', Color(0xFF9AA0AD)),
    _Band(4, 'keystone', 'Keystone Habit', 'Keystone', Color(0xFFD99C3A)),
    _Band(3, 'principle', 'Core Dimension', 'Dimension', Color(0xFFE87A3C)),
    _Band(2, 'core', 'Related Core', 'Core', Color(0xFFE83838)),
    _Band(1, 'pain', 'Pain Point', 'Pain Point', Color(0xFF9C2520)),
  ];

  @override
  Widget build(BuildContext context) {
    final maxW = compact ? 280.0 : 360.0;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: AspectRatio(
          aspectRatio: compact ? 280 / 150 : 520 / 720,
          child: CustomPaint(
            painter: _HHSPyramidPainter(
              bands: _bands,
              active: active,
              completed: completed,
              compact: compact,
            ),
          ),
        ),
      ),
    );
  }
}

class _Band {
  const _Band(this.id, this.key, this.label, this.shortLabel, this.fill);
  final int id;
  final String key;
  final String label;
  final String shortLabel;
  final Color fill;
}

class _HHSPyramidPainter extends CustomPainter {
  _HHSPyramidPainter({
    required this.bands,
    required this.active,
    required this.completed,
    required this.compact,
  });

  final List<_Band> bands;
  final int active;
  final List<int> completed;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    // Normalised geometry: scale viewBox to actual size.
    final vbW = compact ? 280.0 : 520.0;
    final vbH = compact ? 150.0 : 720.0;
    final sx = size.width / vbW;
    final sy = size.height / vbH;
    canvas.save();
    canvas.scale(sx, sy);

    final apexX = vbW / 2;
    final apexY = compact ? 6.0 : 90.0;
    final baseY = compact ? 132.0 : 600.0;
    final slope = (vbW - 40) / 2 / (baseY - apexY);
    const slices = 5;
    final sliceH = (baseY - apexY) / slices;
    const inset = 2.0;

    // Header (progress squares + trophy) — full size only
    if (!compact) {
      _paintHeader(canvas, apexX);
    }

    for (final band in bands) {
      final sliceIdx = 5 - band.id; // 0 = tip
      final isActive = band.id == active;
      final isDone = completed.contains(band.id);
      final isLocked = band.id == 5 && !completed.contains(5);

      final yTop = apexY + sliceIdx * sliceH;
      final yBot = apexY + (sliceIdx + 1) * sliceH;
      final halfTop = (yTop - apexY) * slope;
      final halfBot = (yBot - apexY) * slope;

      final path = Path()
        ..moveTo(apexX - halfTop + inset, yTop + inset)
        ..lineTo(apexX + halfTop - inset, yTop + inset)
        ..lineTo(apexX + halfBot - inset, yBot - inset)
        ..lineTo(apexX - halfBot + inset, yBot - inset)
        ..close();

      // Drop shadow underlay
      canvas.drawPath(
        path.shift(const Offset(0, 2)),
        Paint()
          ..color = Colors.black.withOpacity(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // Fill
      final fillPaint = Paint()
        ..color = band.fill.withOpacity(isLocked ? 0.55 : (isActive ? 1.0 : 1.0));
      canvas.drawPath(path, fillPaint);

      // Active glow ring (mimics mm-flame)
      if (isActive) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Colors.white.withOpacity(0.35),
        );
      }

      // Lock icon on tip
      if (isLocked && !compact) {
        final yMid = apexY + (sliceIdx + 0.5) * sliceH;
        _paintLock(canvas, Offset(apexX, yMid - 16));
      }

      // Band label
      final yMid = apexY + (sliceIdx + 0.5) * sliceH;
      final halfMid = (yMid - apexY) * slope;
      final labelSize = compact
          ? math_clamp(halfMid * 0.18, 7, 11)
          : math_clamp(halfMid * 0.2, 11, 22);

      final labelText = compact ? band.shortLabel.toUpperCase() : band.label;
      final textY = yMid + ((isLocked && !compact) ? 6 : 0);
      _paintText(
        canvas,
        labelText,
        Offset(apexX, textY),
        labelSize,
        compact ? 1.2 : 0.5,
        band.id == 1 ? FontWeight.w700 : FontWeight.w600,
      );

      // Done checkmark badge in upper-right corner of band
      if (isDone) {
        final radius = compact ? 5.0 : 9.0;
        final offsetX = apexX + halfMid - (compact ? 12 : 22);
        _paintCheck(canvas, Offset(offsetX, yMid), radius);
      }
    }

    // Rocket sitting at the base — full size only
    if (!compact) {
      _paintRocket(canvas, Offset(apexX, baseY + 50));
    }

    canvas.restore();
  }

  void _paintHeader(Canvas canvas, double apexX) {
    const squareSize = 22.0;
    const gap = 6.0;
    final totalW = 4 * squareSize + 3 * gap + 16 + 28;
    final startX = (520.0 - totalW) / 2;
    const headerY = 22.0;

    for (int i = 0; i < 4; i++) {
      final n = i + 1;
      final isDone = completed.contains(n);
      final isActive = n == active;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          startX + i * (squareSize + gap),
          headerY,
          squareSize,
          squareSize,
        ),
        const Radius.circular(2),
      );
      final fill = isDone
          ? const Color(0xFF1D8A3A)
          : isActive
              ? const Color(0xFF1D8A3A).withOpacity(0.6)
              : const Color(0xFFD0D3D8);
      canvas.drawRRect(rect, Paint()..color = fill);
      if (isActive) {
        canvas.drawRRect(
          rect,
          Paint()
            ..color = const Color(0xFF1D8A3A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    // Trophy
    final trophyDone = completed.contains(5);
    final trophyX = startX + 4 * (squareSize + gap) + 16;
    final trophyColor = trophyDone ? MM.yellow : const Color(0xFFD0D3D8);
    final trophyStroke =
        trophyDone ? const Color(0xFFC98A00) : const Color(0xFF9AA0AD);

    // Trophy is simplified to an icon-like shape.
    final tx = trophyX;
    final ty = headerY - 2;
    final cup = Path()
      ..moveTo(tx + 4, ty + 4)
      ..lineTo(tx + 22, ty + 4)
      ..lineTo(tx + 22, ty + 11)
      ..arcToPoint(Offset(tx + 4, ty + 11),
          radius: const Radius.circular(9), clockwise: false)
      ..close();
    canvas.drawPath(cup, Paint()..color = trophyColor);
    canvas.drawPath(
        cup,
        Paint()
          ..color = trophyStroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    // base
    canvas.drawRect(
      Rect.fromLTWH(tx + 9, ty + 18, 8, 6),
      Paint()..color = trophyColor,
    );
    canvas.drawLine(
      Offset(tx + 6, ty + 24),
      Offset(tx + 20, ty + 24),
      Paint()
        ..color = trophyStroke
        ..strokeWidth = 1.2,
    );
  }

  void _paintLock(Canvas canvas, Offset c) {
    final p = Paint()..color = const Color(0xFF5A5F6B).withOpacity(0.85);
    canvas.drawRect(Rect.fromLTWH(c.dx - 6, c.dy - 2, 12, 9), p);
    final hoop = Path()
      ..moveTo(c.dx - 4, c.dy - 2)
      ..lineTo(c.dx - 4, c.dy - 5)
      ..arcToPoint(Offset(c.dx + 4, c.dy - 5),
          radius: const Radius.circular(4))
      ..lineTo(c.dx + 4, c.dy - 2);
    canvas.drawPath(
      hoop,
      Paint()
        ..color = const Color(0xFF5A5F6B).withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _paintCheck(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF1D8A3A));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final s = r * 0.4;
    final tick = Path()
      ..moveTo(c.dx - s, c.dy)
      ..lineTo(c.dx - s * 0.3, c.dy + s * 0.7)
      ..lineTo(c.dx + s, c.dy - s);
    canvas.drawPath(
      tick,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.22
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintRocket(Canvas canvas, Offset c) {
    final shadow = Paint()..color = Colors.black.withOpacity(0.25);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(c.dx, c.dy + 38), width: 44, height: 8),
        shadow);

    // nose
    final nose = Path()
      ..moveTo(c.dx, c.dy - 38)
      ..cubicTo(c.dx - 14, c.dy - 28, c.dx - 16, c.dy - 8, c.dx - 16, c.dy + 6)
      ..lineTo(c.dx + 16, c.dy + 6)
      ..cubicTo(c.dx + 16, c.dy - 8, c.dx + 14, c.dy - 28, c.dx, c.dy - 38)
      ..close();
    canvas.drawPath(nose, Paint()..color = const Color(0xFFEA3A3A));

    // hull
    final hull = Path()
      ..moveTo(c.dx - 16, c.dy + 6)
      ..lineTo(c.dx - 16, c.dy + 24)
      ..lineTo(c.dx - 10, c.dy + 32)
      ..lineTo(c.dx + 10, c.dy + 32)
      ..lineTo(c.dx + 16, c.dy + 24)
      ..lineTo(c.dx + 16, c.dy + 6)
      ..close();
    canvas.drawPath(hull, Paint()..color = const Color(0xFFE8EAEF));

    // porthole
    canvas.drawCircle(
        Offset(c.dx, c.dy + 8), 6, Paint()..color = const Color(0xFF1F4F99));
    canvas.drawCircle(
      Offset(c.dx, c.dy + 8),
      6,
      Paint()
        ..color = MM.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // fins
    final finL = Path()
      ..moveTo(c.dx - 16, c.dy + 14)
      ..lineTo(c.dx - 26, c.dy + 30)
      ..lineTo(c.dx - 16, c.dy + 28)
      ..close();
    final finR = Path()
      ..moveTo(c.dx + 16, c.dy + 14)
      ..lineTo(c.dx + 26, c.dy + 30)
      ..lineTo(c.dx + 16, c.dy + 28)
      ..close();
    canvas.drawPath(finL, Paint()..color = const Color(0xFFC41D1D));
    canvas.drawPath(finR, Paint()..color = const Color(0xFFC41D1D));

    // flame
    final flame = Path()
      ..moveTo(c.dx - 7, c.dy + 32)
      ..quadraticBezierTo(c.dx - 10, c.dy + 42, c.dx, c.dy + 48)
      ..quadraticBezierTo(c.dx + 10, c.dy + 42, c.dx + 7, c.dy + 32)
      ..close();
    canvas.drawPath(flame, Paint()..color = MM.yellow);
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset center,
    double size,
    double letterSpacing,
    FontWeight weight,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: letterSpacing,
          shadows: const [
            Shadow(
                color: Color(0x59000000), offset: Offset(0, 1), blurRadius: 2),
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _HHSPyramidPainter old) {
    return old.active != active ||
        old.completed.length != completed.length ||
        old.compact != compact;
  }
}

double math_clamp(double v, double min, double max) {
  return v < min ? min : (v > max ? max : v);
}
