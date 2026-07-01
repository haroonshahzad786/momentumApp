import 'package:flutter/material.dart';
import '../../theme/momentum_tokens.dart';

/// Glassmorphic panel: translucent navy with hairline border.
/// Use `accent: true` for the blue glow variant.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.accent = false,
    this.borderColor,
    this.leftAccentColor,
    this.background,
    this.borderRadius = 8,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool accent;
  final Color? borderColor;
  final Color? leftAccentColor;
  final Decoration? background;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final base = MM.navy.withOpacity(0.55);
    final border = borderColor ??
        (accent
            ? const Color(0x732A7DE1)
            : Colors.white.withOpacity(0.10));
    final radius = BorderRadius.circular(borderRadius);

    // Uniform border only — a non-uniform Border (e.g. a thicker left accent
    // side) combined with a borderRadius throws during paint and renders the
    // panel blank. The left accent is drawn as a clipped overlay stripe below.
    Widget panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background == null ? base : null,
        border: Border.all(color: border, width: 1),
        borderRadius: radius,
      ),
      child: DecoratedBox(
        decoration: background ?? const BoxDecoration(),
        child: child,
      ),
    );

    if (leftAccentColor != null) {
      panel = ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            panel,
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: leftAccentColor),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: boxShadow ??
            (accent
                ? const [
                    BoxShadow(
                      color: Color(0x2D2A7DE1),
                      blurRadius: 20,
                    ),
                  ]
                : null),
      ),
      child: panel,
    );
  }
}
