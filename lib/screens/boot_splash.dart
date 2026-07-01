import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/momentum_tokens.dart';
import '../widgets/momentum/starfield.dart';

/// Brand colours from the Moore Momentum logo (boot.jsx).
const Color _brandRed = Color(0xFFE8112D); // Ignition Red
const Color _brandBlue = Color(0xFF1F9AD6); // Momentum Blue

/// Startup boot / loading animation: the logo mark wipes in over a glow pulse,
/// the MOORE·MOMENTUM wordmark and tagline fade up, and an "IGNITION %" bar
/// fills. Calls [onDone] once the sequence finishes. Ported from boot.jsx.
class BootSplash extends StatefulWidget {
  const BootSplash({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<BootSplash> createState() => _BootSplashState();
}

class _BootSplashState extends State<BootSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  bool _done = false;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_done) {
        _done = true;
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) widget.onDone();
        });
      }
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _interval(double begin, double end, Curve curve) {
    final t = ((_c.value - begin) / (end - begin)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MM.pageBg,
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final pct = (Curves.easeOut.transform(_c.value) * 100).round();
          final wipe = _interval(0.05, 0.42, Curves.easeOutCubic);
          final logoOpacity = _interval(0.05, 0.28, Curves.easeOut);
          final glow = _interval(0.40, 1.0, Curves.easeOut);
          final word = _interval(0.62, 0.86, Curves.easeOut);
          final tag = _interval(0.74, 0.96, Curves.easeOut);

          return Stack(
            fit: StackFit.expand,
            children: [
              const Positioned.fill(child: StarfieldBackground(accent: _brandBlue)),
              // Centre cluster: glow + wiping logo + wordmark + tagline.
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 230,
                    height: 150,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Radial glow pulse behind the mark.
                        Opacity(
                          opacity: glow * 0.9,
                          child: Transform.scale(
                            scale: 0.7 + glow * 0.34,
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    _brandBlue.withValues(alpha: 0.27),
                                    _brandRed.withValues(alpha: 0.20),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.40, 0.68],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Logo mark, revealed bottom→top (the "wipe").
                        Opacity(
                          opacity: logoOpacity,
                          child: ClipRect(
                            clipper: _WipeClipper(wipe),
                            child: Image.asset(
                              'assets/brand/moore_mark.png',
                              height: 132,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  // Wordmark: MOORE (red) · MOMENTUM (blue).
                  _FadeUp(
                    t: word,
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.orbitron(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                        children: const [
                          TextSpan(
                              text: 'MOORE',
                              style: TextStyle(color: _brandRed)),
                          TextSpan(
                              text: 'MOMENTUM',
                              style: TextStyle(color: _brandBlue)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _FadeUp(
                    t: tag,
                    child: Text(
                      'BUILD YOUR MOMENTUM',
                      style: GoogleFonts.orbitron(
                        fontSize: 9.5,
                        color: Colors.white.withValues(alpha: 0.55),
                        letterSpacing: 3.2,
                      ),
                    ),
                  ),
                ],
              ),
              // Progress bar pinned near the bottom.
              Positioned(
                left: 0,
                right: 0,
                bottom: 64,
                child: Column(
                  children: [
                    Container(
                      width: 168,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: pct / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_brandRed, _brandBlue],
                              ),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                    color: _brandBlue.withValues(alpha: 0.6),
                                    blurRadius: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      pct < 100 ? 'IGNITION · $pct%' : 'MOMENTUM ENGAGED',
                      style: GoogleFonts.orbitron(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 2.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Reveals its child from the bottom up as [t] goes 0 → 1.
class _WipeClipper extends CustomClipper<Rect> {
  _WipeClipper(this.t);
  final double t;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, size.height * (1 - t), size.width, size.height);

  @override
  bool shouldReclip(_WipeClipper old) => old.t != t;
}

/// Fade + rise, driven by an external 0→1 value.
class _FadeUp extends StatelessWidget {
  const _FadeUp({required this.t, required this.child});
  final double t;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, (1 - t) * 10),
        child: child,
      ),
    );
  }
}
