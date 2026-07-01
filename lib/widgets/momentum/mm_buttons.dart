import 'package:flutter/material.dart';
import '../../theme/momentum_tokens.dart';

/// Glowing primary action — the blue gradient pill from the design.
class MMPrimaryButton extends StatefulWidget {
  const MMPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.pulse = false,
    this.expand = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool pulse;
  final bool expand;
  final EdgeInsetsGeometry padding;
  final bool busy;

  @override
  State<MMPrimaryButton> createState() => _MMPrimaryButtonState();
}

class _MMPrimaryButtonState extends State<MMPrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  bool _down = false;

  @override
  void initState() {
    super.initState();
    if (!widget.pulse) _pulse.stop();
  }

  @override
  void didUpdateWidget(covariant MMPrimaryButton old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !_pulse.isAnimating) _pulse.repeat(reverse: true);
    if (!widget.pulse && _pulse.isAnimating) _pulse.stop();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.busy;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final glow = 24.0 + (widget.pulse ? _pulse.value * 20 : 0.0);
        return GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapCancel: enabled ? () => setState(() => _down = false) : null,
          onTapUp: enabled
              ? (_) {
                  setState(() => _down = false);
                  widget.onPressed?.call();
                }
              : null,
          child: AnimatedScale(
            scale: _down ? 0.98 : 1,
            duration: const Duration(milliseconds: 120),
            child: Container(
              width: widget.expand ? double.infinity : null,
              padding: widget.padding,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3A8DFF), Color(0xFF1F5FB8)],
                ),
                border: Border.all(color: const Color(0xFF4D9BFF)),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2A7DE1).withOpacity(
                        enabled ? (widget.pulse ? 0.85 : 0.55) : 0.2),
                    blurRadius: glow,
                  ),
                ],
              ),
              child: Center(
                child: widget.busy
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Opacity(
                        opacity: enabled ? 1 : 0.5,
                        child: Text(
                          widget.label.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: MM.display(
                            size: 14,
                            color: Colors.white,
                            weight: FontWeight.w700,
                            letterSpacing: 14 * 0.14,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Ghost / secondary button — thin border, transparent fill.
class MMGhostButton extends StatelessWidget {
  const MMGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.borderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(MM.r2),
      child: Container(
        width: expand ? double.infinity : null,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.18)),
          borderRadius: BorderRadius.circular(MM.r2),
        ),
        child: Center(
          child: Text(
            label.toUpperCase(),
            style: MM.display(
              size: 11,
              color: color ?? MM.white,
              weight: FontWeight.w600,
              letterSpacing: 11 * 0.14,
            ),
          ),
        ),
      ),
    );
  }
}

/// Small numeric / label chip.
class MMChip extends StatelessWidget {
  const MMChip({
    super.key,
    required this.label,
    this.color,
    this.leading,
  });
  final String label;
  final Color? color;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.04 * 11,
              color: color ?? MM.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
