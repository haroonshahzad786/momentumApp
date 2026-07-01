import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import '../../theme/momentum_tokens.dart';

/// Layered hero rocket: base PNG + per-core panels + nose instruments.
/// `activeCores` controls which panels show color vs gray.
/// Tap a nose icon (habits / lists / routines) to navigate.
class RocketWidget extends StatefulWidget {
  const RocketWidget({
    super.key,
    this.width,
    this.maxWidth = 240,
    this.viewportFraction = 0.7,
    this.activeCores = const ['mindset', 'career', 'physical'],
    this.atRiskCores = const <String>{},
    this.streak = 0,
    this.onNav,
    this.onCoreAlert,
  });

  /// Optional override. When null the rocket sizes itself responsively:
  /// `min(parentWidth * viewportFraction, parentHeight / aspect, maxWidth)`.
  final double? width;
  final double maxWidth;
  final double viewportFraction;
  final List<String> activeCores;

  /// Cores out of balance (below 3.0 for 5+ consecutive days) — show a red ⚠️
  /// badge that opens the iCore Alert.
  final Set<String> atRiskCores;
  final int streak;
  final void Function(String key)? onNav;
  final void Function(String coreId)? onCoreAlert;

  @override
  State<RocketWidget> createState() => _RocketWidgetState();
}

class _RocketWidgetState extends State<RocketWidget>
    with TickerProviderStateMixin {
  late final AnimationController _plume = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  // Curved version of `_plume` so the pulse eases in/out instead of
  // ticking linearly, matching the `ease-in-out` curve in
  // HANDOFF_EFFECTS_STARS_PLUME_COPILOT.md §3 (`mm-plume` keyframe).
  late final CurvedAnimation _plumeCurve = CurvedAnimation(
    parent: _plume,
    curve: Curves.easeInOut,
  );

  late final AnimationController _lockPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  // Each PNG is drawn at its NATURAL aspect ratio (not forced into a
  // square), so wing-shaped panels keep their proportions across every
  // screen size. Mindset stays at 0.53; the four wing panels are ~5%
  // smaller (0.50) per design tuning.
  static const double _panelWMindset = 0.53;
  static const double _panelWWing = 0.35;

  static const _coreDefs = <_CoreDef>[
    _CoreDef('mindset', Color(0xFFE8744A), 'core-mindset.png',
        Offset(0.50, 0.37), _panelWMindset, 0),
    _CoreDef('emotional', Color(0xFF4CC8C2), 'core-emotional.png',
        Offset(0.34, 0.47), _panelWWing, -0.04),
    _CoreDef('relationships', Color(0xFFD977A0), 'core-relationships.png',
        Offset(0.68, 0.47), _panelWWing, 0.04),
    _CoreDef('physical', Color(0xFF8A5FC4), 'core-physical.png',
        Offset(0.36, 0.69), _panelWWing, 0),
    _CoreDef('career', Color(0xFF5FA86B), 'core-career.png',
        Offset(0.65, 0.69), _panelWWing, 0),
  ];

  static const _noseIcons = <_NoseIcon>[
    _NoseIcon('habits', 'icon-habits.png', Offset(0.505, 0.13), 0.155),
    _NoseIcon('lists', 'icon-lists.png', Offset(0.39, 0.22), 0.11),
    _NoseIcon('routines', 'icon-routines.png', Offset(0.62, 0.22), 0.11),
  ];

  static const double _badgeW = 0.22;

  @override
  void dispose() {
    _plumeCurve.dispose();
    _plume.dispose();
    _lockPulse.dispose();
    super.dispose();
  }

  bool _isActive(String id) => widget.activeCores.contains(id);

  @override
  Widget build(BuildContext context) {
    // Source PNG is 516 x 980 → aspect h/w
    const aspect = 980 / 516;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = _resolveWidth(context, constraints, aspect);
        final double h = w * aspect;
        return _buildRocket(w, h);
      },
    );
  }

  double _resolveWidth(
      BuildContext context, BoxConstraints constraints, double aspect) {
    if (widget.width != null) return widget.width!;
    final media = MediaQuery.of(context).size;
    final parentW = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : media.width;
    final parentH = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : media.height;
    final byWidth = parentW * widget.viewportFraction;
    final byHeight = parentH / aspect;
    return [byWidth, byHeight, widget.maxWidth]
        .reduce((a, b) => a < b ? a : b);
  }

  Widget _buildRocket(double w, double h) {
    // Plume is drawn first in the Stack → it sits BEHIND the rocket
    // frame and the panel overlays, so any wing/body pixels in those
    // images naturally appear in front of the flame. We push the plume's
    // top edge well inside the rocket bounding box so the wings actually
    // overlap it.
    final plumeExtra = (widget.streak.clamp(0, 60)) * 0.18 / 100;
    final plumeHeight = h * (0.40 + plumeExtra);
    // Shift factor pushes the flame up by ~10% of plume height vs. before.
    final plumeShift = plumeHeight * 0.36;
    // Horizontal center nudged 4% rightward so it lines up under the nozzle.
    const plumeCx = 0.50;
    // Wider container gives the radial gradient room to fade smoothly on
    // the left/right edges so the flame doesn't look clipped at the sides.
    const plumeW = 0.31;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Engine plume
          Positioned(
            left: w * plumeCx - w * plumeW / 2,
            bottom: -plumeHeight + plumeShift,
            width: w * plumeW,
            child: AnimatedBuilder(
              animation: _plumeCurve,
              builder: (_, __) {
                // Very subtle breath — amplitude reduced so the flame no
                // longer reads as bouncing.
                final scaleY = 1 + _plumeCurve.value * 0.025;
                final opacity = 0.9 + _plumeCurve.value * 0.08;
                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scaleY: scaleY,
                    alignment: Alignment.topCenter,
                    // ClipOval gives the flame an oval silhouette (curvy
                    // on the left/right, rounded at the bottom).
                    // ImageFiltered adds a soft Gaussian blur so the
                    // oval's edge doesn't look like a hard cut.
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: ClipOval(
                        child: Container(
                          height: plumeHeight,
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(0, -0.4),
                              radius: 0.9,
                              colors: [
                                Color(0xFFFFF5B3),
                                Color(0xFFFFCE3A),
                                Color(0xFFFF6A1A),
                                Color(0x00FF6A1A),
                              ],
                              stops: [0.0, 0.3, 0.65, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Halo
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.1),
                    radius: 0.7,
                    colors: [
                      MM.blue.withOpacity(0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Rocket frame
          Positioned.fill(
            child: Image.asset(
              'assets/momentum/rocket.png',
              fit: BoxFit.contain,
            ),
          ),

          // Panels + core icons
          for (final c in _coreDefs) ..._buildCore(c, w, h),

          // Nose icons (clickable)
          for (final n in _noseIcons)
            Positioned(
              left: w * n.center.dx - (w * n.w) / 2,
              top: h * n.center.dy - (w * n.w) / 2,
              width: w * n.w,
              height: w * n.w,
              child: GestureDetector(
                onTap: () => widget.onNav?.call(n.kind),
                child: Image.asset(
                  'assets/momentum/${n.src}',
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCore(_CoreDef c, double w, double h) {
    final active = _isActive(c.id);
    final cx = w * c.center.dx;
    final cy = h * c.center.dy;
    final pw = w * c.width;
    final iconW = w * _badgeW;
    // Offsets are expressed in % of the rocket bounding box (same units as
    // cx/cy), per HANDOFF_ROCKET_DASHBOARD.md §4.1.
    final ix = cx + w * c.iconOffsetX;
    final iy = cy + h * c.iconOffsetY;
    final lockSize = iconW * 0.45;
    return [
      // Panel — drawn at natural aspect ratio anchored on (cx, cy).
      // We only fix the WIDTH; FractionalTranslation shifts it up by half
      // its rendered height so the image's geometric center lands on cy,
      // regardless of the PNG's actual shape.
      Positioned(
        left: cx - pw / 2,
        top: cy,
        child: FractionalTranslation(
          translation: const Offset(0, -0.5),
          child: IgnorePointer(
            child: Image.asset(
              'assets/momentum/panel-${c.id}-${active ? 'color' : 'gray'}.png',
              width: pw,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      Positioned(
        left: ix - iconW / 2,
        top: iy - iconW / 2,
        width: iconW,
        height: iconW,
        child: IgnorePointer(
          child: Container(
            decoration: active
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: c.hex.withOpacity(0.55),
                        blurRadius: iconW * 0.35,
                        spreadRadius: iconW * 0.02,
                      ),
                    ],
                  )
                : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipOval(
                  child: ColorFiltered(
                    colorFilter: active
                        ? const ColorFilter.mode(
                            Colors.transparent, BlendMode.dst)
                        : const ColorFilter.matrix([
                            0.3, 0.3, 0.3, 0, -40,
                            0.3, 0.3, 0.3, 0, -40,
                            0.3, 0.3, 0.3, 0, -40,
                            0,   0,   0,   1, 0,
                          ]),
                    child: Image.asset('assets/momentum/${c.iconSrc}',
                        fit: BoxFit.cover),
                  ),
                ),
                if (!active)
                  FadeTransition(
                    opacity: Tween(begin: 0.55, end: 1.0).animate(_lockPulse),
                    child: ScaleTransition(
                      scale: Tween(begin: 1.0, end: 1.06).animate(_lockPulse),
                      child: Icon(Icons.lock,
                          color: MM.yellow, size: lockSize),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      // Red ⚠️ Core Balance badge (5+ days below 3.0), tappable → iCore Alert.
      // Drawn last so it sits above the panel/icon; only active Cores qualify.
      if (active && widget.atRiskCores.contains(c.id))
        Positioned(
          left: ix + iconW * 0.20,
          top: iy - iconW * 0.50,
          width: iconW * 0.46,
          height: iconW * 0.46,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onCoreAlert?.call(c.id),
            child: FadeTransition(
              opacity: Tween(begin: 0.6, end: 1.0).animate(_lockPulse),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MM.red,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: MM.red.withOpacity(0.7), blurRadius: 8),
                  ],
                ),
                child: const Icon(Icons.priority_high,
                    color: Colors.white, size: 13),
              ),
            ),
          ),
        ),
    ];
  }
}

class _CoreDef {
  const _CoreDef(
    this.id,
    this.hex,
    this.iconSrc,
    this.center,
    this.width,
    this.iconOffsetX, [
    this.iconOffsetY = 0,
  ]);
  final String id;
  final Color hex;
  final String iconSrc;
  final Offset center;
  final double width; // fraction of rocket image width
  final double iconOffsetX;
  final double iconOffsetY;
}

class _NoseIcon {
  const _NoseIcon(this.kind, this.src, this.center, this.w);
  final String kind;
  final String src;
  final Offset center;
  final double w;
}
