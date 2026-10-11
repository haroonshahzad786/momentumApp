import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../theme/momentum_tokens.dart';
import 'command_center_console.dart';

/// Thruster flame, as a Lottie vector loop. Picked over the source GIFs: those
/// are 1-bit-transparency frames, which speckle badly around the soft edge of a
/// flame on a dark background, and they weigh ~20x more for a fixed resolution.
/// Three intensities ship — the streak decides how hard the engine is burning.
String flameAsset(int streak) {
  if (streak >= 21) return 'assets/momentum/rocket/flames/fire_hi.json';
  if (streak >= 7) return 'assets/momentum/rocket/flames/fire_mi.json';
  return 'assets/momentum/rocket/flames/fire_lo.json';
}

/// Layered hero rocket: base PNG + per-core panels + nose instruments.
/// `activeCores` controls which panels show color vs gray.
/// Tap a nose icon (Command Center / routines / all habits / non-routines).
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
    this.onCommandCenter,
    this.onOpenCommandCenter,
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

  /// Fires when the Command Center console opens (true) or closes (false), so
  /// the host can clear its own chrome around the stage.
  final ValueChanged<bool>? onCommandCenter;

  /// When set, the steering wheel hands the Command Center to the host (which
  /// shows the console over its whole panel) instead of swapping in place.
  final VoidCallback? onOpenCommandCenter;

  @override
  State<RocketWidget> createState() => _RocketWidgetState();
}

class _RocketWidgetState extends State<RocketWidget>
    with TickerProviderStateMixin {
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

  // Tip of the rocket (Phase 1&2 Details, Sequence, 2/26/26 meeting): large
  // centre-top steering wheel → Command Center; below it, smaller left clock →
  // Full Routines List, centre ∞ → All Habits Quick View, right checklist →
  // Non-Routines. Steering wheel + ∞ art are placeholders until real art lands.
  // Centres are measured from rocket.png's dark sockets (516×980 px): big
  // (258,137), left (195.5,209.5), right (321,209.5).
  static const _noseIcons = <_NoseIcon>[
    _NoseIcon('lists', 'icon-command.png', Offset(0.5, 0.1398), 0.19,
        'Command Center'),
    _NoseIcon('routines', 'icon-routines.png', Offset(0.3789, 0.2138), 0.11,
        'Routines'),
    // The rocket art has no 4th socket, so ∞ sits on its own gray plate, on
    // the centre line midway between the big socket (bottom y188) and the
    // Mindset panel (top y247).
    _NoseIcon('allhabits', 'icon-allhabits.png', Offset(0.5, 0.2219), 0.097,
        'All Habits', plate: true),
    _NoseIcon('nonroutines', 'icon-lists.png', Offset(0.6221, 0.2138), 0.11,
        'Non-Routines'),
  ];

  static const double _badgeW = 0.22;

  static const _coreName = {
    'mindset': 'Mindset',
    'emotional': 'Emotional & Mental',
    'relationships': 'Relationships',
    'physical': 'Physical Health',
    'career': 'Career & Finances',
  };

  @override
  void dispose() {
    _lockPulse.dispose();
    super.dispose();
  }

  /// The steering wheel swaps the rocket for the Command Center console in
  /// the same box, rather than navigating away.
  bool _commandOpen = false;

  bool _isActive(String id) => widget.activeCores.contains(id);

  void _setCommand(bool open) {
    setState(() => _commandOpen = open);
    widget.onCommandCenter?.call(open);
  }

  void _onNose(String kind) {
    if (kind == 'lists' && widget.onOpenCommandCenter != null) {
      widget.onOpenCommandCenter!();
    } else if (kind == 'lists') {
      _setCommand(true);
    } else {
      widget.onNav?.call(kind);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Source PNG is 516 x 980 → aspect h/w
    const aspect = 980 / 516;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = _resolveWidth(context, constraints, aspect);
        final double h = w * aspect;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          // The engine plume hangs below the rocket's box — don't clip it.
          layoutBuilder:
              (current, previous) => Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [...previous, if (current != null) current],
              ),
          transitionBuilder:
              (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween(begin: 0.96, end: 1.0).animate(anim),
                  child: child,
                ),
              ),
          child:
              _commandOpen
                  ? CommandCenterConsole(
                    key: const ValueKey('command'),
                    // Fills whatever box the host gives the stage — the
                    // Cockpit hands it the whole panel while it is open.
                    width:
                        constraints.maxWidth.isFinite
                            ? constraints.maxWidth
                            : w,
                    height:
                        constraints.maxHeight.isFinite
                            ? constraints.maxHeight
                            : h,
                    onClose: () => _setCommand(false),
                    onNav: widget.onNav,
                  )
                  : KeyedSubtree(
                    key: const ValueKey('rocket'),
                    child: _buildRocket(w, h),
                  ),
        );
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
    final plumeExtra = (widget.streak.clamp(0, 60)) * 0.28 / 100;
    // The Lottie artboard carries transparent padding around the flame, so the
    // burn renders a good deal smaller than its box — these are sized for the
    // visible flame, not the box.
    final plumeHeight = h * (0.66 + plumeExtra);
    // How far the plume's top edge is tucked up inside the hull. Smaller means
    // the flame sits lower and hangs further clear of the nozzle.
    final plumeShift = plumeHeight * 0.28;
    // Horizontal center nudged 4% rightward so it lines up under the nozzle.
    const plumeCx = 0.50;
    const plumeW = 0.54;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Engine plume. The Lottie loop carries its own flicker, so the old
          // breathe-and-blur wrapper is gone — stacking our pulse on top of the
          // animation's just fought it.
          Positioned(
            left: w * plumeCx - w * plumeW / 2,
            bottom: -plumeHeight + plumeShift,
            width: w * plumeW,
            height: plumeHeight,
            child: Lottie.asset(
              flameAsset(widget.streak),
              fit: BoxFit.fill,
              repeat: true,
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
              child: Tooltip(
                message: n.label,
                child: Semantics(
                  button: true,
                  label: n.label,
                  child: GestureDetector(
                    onTap: () => _onNose(n.kind),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: n.plate
                          ? DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF3A3F47),
                                border: Border.all(
                                    color: const Color(0xFF8A9099),
                                    width: w * 0.006),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x80000000), blurRadius: 4),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(w * 0.012),
                                child: Image.asset(
                                  'assets/momentum/${n.src}',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            )
                          : Image.asset(
                              'assets/momentum/${n.src}',
                              fit: BoxFit.contain,
                            ),
                    ),
                  ),
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
      // Tap the Core: active → that Core's habits; locked → "Fuel this Core"
      // (the first habit there is what unlocks it).
      Positioned(
        left: ix - iconW * 0.65,
        top: iy - iconW * 0.65,
        width: iconW * 1.3,
        height: iconW * 1.3,
        child: Tooltip(
          message: active ? _coreName[c.id]! : 'Fuel this Core',
          child: Semantics(
            button: true,
            label: active
                ? '${_coreName[c.id]} habits'
                : '${_coreName[c.id]} locked. Fuel this Core',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  widget.onNav?.call(active ? 'habits:${c.id}' : 'fuel:${c.id}'),
              child: const MouseRegion(cursor: SystemMouseCursors.click),
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
  const _NoseIcon(this.kind, this.src, this.center, this.w, this.label,
      {this.plate = false});
  final String kind;

  /// Draw a gray round plate behind the icon (for icons with no socket in the
  /// rocket art).
  final bool plate;
  final String label;
  final String src;
  final Offset center;
  final double w;
}
