import 'dart:math' as math;

import '../../widgets/momentum/phase2_launch.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/momentum_tokens.dart';
import '../../widgets/momentum/command_center_console.dart';
import '../../widgets/momentum/info_tip.dart';
import '../../widgets/momentum/journey_stage.dart';
import '../../widgets/momentum/mm_buttons.dart';
import '../../widgets/momentum/starfield.dart';
import '../../widgets/momentum/streak_bar.dart';
import '../../widgets/momentum/web_shell.dart';

/// Desktop flagship: the 3-column Cockpit (5 Cores · rocket stage · flight
/// data), wired to the real profile data MomentumHome already holds. Mirrors
/// web.jsx's WebCockpit; the mobile DashboardPage still renders below 900px.
class WebCockpit extends StatelessWidget {
  const WebCockpit({
    super.key,
    required this.name,
    required this.streak,
    this.streakState = 'ok',
    this.streakProtection,
    this.streakSavers = 0,
    this.onStreakTap,
    required this.planet,
    required this.activeCores,
    required this.atRiskCores,
    required this.level,
    required this.momentumScore,
    required this.spaceCredits,
    required this.balance,
    required this.onNav,
    required this.onCheckIn,
    required this.onCoreAlert,
    required this.onChat,
    this.novaOpen = false,
    this.novaSnap = false,
    this.phase1Banner,
    this.openCommand = false,
  });

  /// Opens the Co-Pilot (the star button).
  final VoidCallback onChat;

  /// While [novaOpen] the centre square flips over and goes empty; Nova itself
  /// hangs from the top of the window (see `_HangingNova` in momentum_home).
  /// [novaSnap] skips the flip-back (Nova moved to the full-screen chat).
  final bool novaOpen;
  final bool novaSnap;

  /// "Continue Phase 1" banner while Phase 1 is unfinished — the phone has
  /// the Phase 1 pill; web had no way back in (P1-10 #5).
  final Widget? phase1Banner;

  /// Open straight into the Command Center console (menu → Command Center).
  final bool openCommand;

  final String name;
  final int streak;

  /// #17 — 'ok' · 'warning' · 'protected' · 'vacation' · 'broken'.
  final String streakState;

  /// Streak Savers + Vacation Mode card, shown under the flight data.
  final Widget? streakProtection;
  final int streakSavers;
  final VoidCallback? onStreakTap;
  final String planet;
  final List<String> activeCores;
  final Set<String> atRiskCores;
  final String level;
  final int momentumScore;
  final int spaceCredits;
  final int? balance;
  final void Function(String key) onNav;
  final VoidCallback onCheckIn;
  final void Function(String coreId) onCoreAlert;

  static const List<(String, String, String)> _cores = [
    ('mindset', 'Mindset', '🧠'),
    ('career', 'Career & Finances', '💰'),
    ('relationships', 'Relationships', '👥'),
    ('physical', 'Physical Health', '💪'),
    ('emotional', 'Emotional & Mental', '🧘'),
  ];

  int get _planetIdx {
    final i = MM.planets.indexWhere((p) => p['id'] == planet);
    return i < 0 ? 0 : i;
  }

  /// Next stop on the route. Its Momentum threshold is still a spec
  /// placeholder (13c), so only the name is shown — never an invented number.
  String? get _nextPlanetName {
    final i = _planetIdx + 1;
    return i < MM.planets.length ? MM.planets[i]['name'] as String : null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 1080;
        final left = _CoresColumn(
          cores: _cores,
          activeCores: activeCores,
          onNav: onNav,
        );
        final centerStage = _RocketStage(
          planetIdx: _planetIdx,
          activeCores: activeCores,
          atRiskCores: atRiskCores,
          streak: streak,
          onNav: onNav,
          onCheckIn: onCheckIn,
          onCoreAlert: onCoreAlert,
          openCommand: openCommand,
          novaOpen: novaOpen,
          novaSnap: novaSnap,
        );
        final center = novaOpen
            ? centerStage
            : WithInfo(
                text:
                    'Your journey. Each active Core fuels the rocket and Momentum moves it '
                    'to the next planet. On its tip: steering wheel = Command Center, '
                    'clock = Routines, ∞ = All Habits, checklist = Non-Routines.',
                top: 10,
                right: 10,
                child: centerStage,
              );
        // Top of the right-hand column: Co-Pilot star + Daily Check-in, with
        // the search box beneath them.
        final actions = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                HoverHint(
                  text: 'Co-Pilot: chat with Nova, your AI guide, for help or a nudge.',
                  child: WebCopilotButton(onTap: onChat),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    key: tourKey('checkin'),
                    child: HoverHint(
                      text:
                          'Your Daily Check-In: one press every morning. It starts scoring and '
                          'keeps your streak, rocket progress and rewards moving.',
                      child: MMPrimaryButton(
                        label: 'Daily Check-in →',
                        pulse: true,
                        expand: true,
                        onPressed: onCheckIn,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const WebSearchField(),
          ],
        );
        final right = _FlightData(
          key: tourKey('stats'),
          planet: MM.planets[_planetIdx],
          streakProtection: streakProtection,
          balance: balance,
          momentumScore: momentumScore,
          spaceCredits: spaceCredits,
          nextPlanetName: _nextPlanetName,
          onNav: onNav,
        );
        // Phase 1&2 Details (Rocket Dashboard) "Across top: Current Streak with consecutive days and
        // days until reward".
        final streakBar = WithInfo(
          text:
              'Your streak: consecutive days you complete the Daily Check-In. '
              'Check in today to keep it going.',
          top: 4,
          right: 4,
          child: StreakBar(
            key: tourKey('streak'),
            streak: streak,
            streakState: streakState,
            streakSavers: streakSavers,
            onTap: onStreakTap,
          ),
        );

        // Narrow (tablet) Cockpit with Nova hanging: phone logic. Icons on the
        // left, stats on the right, everything else hidden (kept mounted).
        final narrowNova = novaOpen && !wide;
        final novaHeader = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    WebCopilotButton(onTap: onChat),
                    const SizedBox(width: 10),
                    _CheckInIcon(onTap: onCheckIn),
                  ],
                ),
                const SizedBox(height: 8),
                StreakBar(
                  compact: true,
                  slim: true,
                  streak: streak,
                  streakState: streakState,
                  streakSavers: streakSavers,
                  onTap: onStreakTap,
                ),
              ],
            ),
            const Spacer(),
            _NovaStats(
              planetName: (MM.planets[_planetIdx]['name'] as String),
              planetColor: MM.planets[_planetIdx]['color'] as Color,
              score: momentumScore,
              credits: spaceCredits,
              balance: balance,
            ),
          ],
        );

        return SingleChildScrollView(
          // Wide: the shell's topbar is off, so the right column can start at
          // the very top, level with the title.
          padding: EdgeInsets.fromLTRB(40, wide ? 26 : 4, 40, 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (narrowNova) novaHeader,
              Offstage(
                offstage: narrowNova,
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (phase1Banner != null) ...[
                phase1Banner!,
                const SizedBox(height: 14),
              ],
              if (!wide) ...[
                streakBar,
                const SizedBox(height: 16),
                actions,
                const SizedBox(height: 20),
              ],
              wide
                  ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(
                              height: _headerH,
                              child: _CockpitTitle(),
                            ),
                            streakBar,
                            const SizedBox(height: 20),
                            left,
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 30,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: _headerH),
                            center,
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            actions,
                            const SizedBox(height: 20),
                            right,
                          ],
                        ),
                      ),
                    ],
                  )
                  : Column(
                    children: [
                      center,
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: left),
                          const SizedBox(width: 24),
                          Expanded(child: right),
                        ],
                      ),
                    ],
                  ),
            ],
          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Height reserved for the title row above the left and centre columns.
const double _headerH = 80;

/// "MISSION CONTROL / Cockpit" heading (the shell topbar is off on the
/// Cockpit so the right-hand column can start at the top of the page).
class _CockpitTitle extends StatelessWidget {
  const _CockpitTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text('MISSION CONTROL',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.orbitron(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.4,
                color: MM.blue)),
        const SizedBox(height: 4),
        Text('Cockpit',
            maxLines: 1,
            softWrap: false,
            style: MM.display(
                size: 30, color: Colors.white, weight: FontWeight.w700)),
      ],
    );
  }
}

// ── shared glass panel base (mm-panel) ──
class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111C4E).withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: child,
    );
  }
}

Widget _sectionLabel(String text) => Padding(
  padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
  child: Text(
    text,
    style: GoogleFonts.orbitron(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.8,
      color: Colors.white,
    ),
  ),
);

// ═══════════════════════════════════════════════════════════════
// LEFT — the 5 cores
// ═══════════════════════════════════════════════════════════════
class _CoresColumn extends StatelessWidget {
  const _CoresColumn({
    required this.cores,
    required this.activeCores,
    required this.onNav,
  });
  final List<(String, String, String)> cores;
  final List<String> activeCores;
  final void Function(String key) onNav;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          _sectionLabel('THE 5 CORES'),
          const SizedBox(width: 4),
          const InfoTip(
              'Your 5 life Cores. An active Core holds your Golden Habit; a locked '
              'one lights up once you create a Golden Habit with at least one MBM '
              'for it in Phase 1. Tap a Core to open its habits (or fuel it).'),
        ]),
        const SizedBox(height: 12),
        for (final core in cores) ...[
          _CoreCard(
            id: core.$1,
            label: core.$2,
            icon: core.$3,
            active: activeCores.contains(core.$1),
            // Active → that Core's habits; dormant → fuel it via HHS.
            onTap:
                () => onNav(
                  activeCores.contains(core.$1)
                      ? 'habits:${core.$1}'
                      : 'fuel:${core.$1}',
                ),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        MMGhostButton(
          label: 'Manage cores →',
          onPressed: () => onNav('habits'),
        ),
      ],
    );
  }
}

class _CoreCard extends StatelessWidget {
  const _CoreCard({
    required this.id,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String id;
  final String label;
  final String icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hex = MM.coreColor[id] ?? MM.blue;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF111C4E).withOpacity(0.55),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color:
                      active
                          ? hex.withOpacity(0.13)
                          : Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color:
                        active
                            ? hex.withOpacity(0.4)
                            : Colors.white.withOpacity(0.12),
                  ),
                  boxShadow:
                      active
                          ? [
                            BoxShadow(
                              color: hex.withOpacity(0.27),
                              blurRadius: 14,
                              spreadRadius: -2,
                            ),
                          ]
                          : null,
                ),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 19)),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: MM.body(
                        size: 13.5,
                        color:
                            active
                                ? Colors.white
                                : Colors.white.withOpacity(0.55),
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      active ? 'ACTIVE' : 'DORMANT · FUEL THIS CORE →',
                      style: GoogleFonts.orbitron(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: active ? hex : MM.yellow.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // left accent bar
              Container(
                width: 3,
                height: 30,
                decoration: BoxDecoration(
                  color: active ? hex : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CENTER — rocket stage
// ═══════════════════════════════════════════════════════════════
class _RocketStage extends StatefulWidget {
  const _RocketStage({
    required this.planetIdx,
    required this.activeCores,
    required this.atRiskCores,
    required this.streak,
    required this.onNav,
    required this.onCheckIn,
    required this.onCoreAlert,
    this.openCommand = false,
    this.novaOpen = false,
    this.novaSnap = false,
  });
  final bool novaOpen;
  final bool novaSnap;
  final int planetIdx;
  final List<String> activeCores;
  final Set<String> atRiskCores;
  final int streak;
  final void Function(String key) onNav;
  final VoidCallback onCheckIn;
  final void Function(String coreId) onCoreAlert;
  final bool openCommand;

  @override
  State<_RocketStage> createState() => _RocketStageState();
}

class _RocketStageState extends State<_RocketStage>
    with SingleTickerProviderStateMixin {
  /// The Command Center console is open in the stage — it takes the panel.
  late bool _commandOpen = widget.openCommand;

  /// 0 = rocket face, 1 = flipped away (empty) while Nova hangs.
  late final AnimationController _novaCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
    reverseDuration: const Duration(milliseconds: 600),
    value: widget.novaOpen ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant _RocketStage old) {
    super.didUpdateWidget(old);
    if (widget.openCommand && !old.openCommand) _commandOpen = true;
    if (widget.novaOpen && !old.novaOpen) {
      _novaCtl.forward();
    } else if (!widget.novaOpen && old.novaOpen) {
      if (widget.novaSnap) {
        _novaCtl.value = 0;
      } else {
        _novaCtl.reverse();
      }
    }
  }

  /// Shared between the journey stage (which drives it) and the panel-wide
  /// starfield (which reads it), so the stars stream faster mid-flight.
  late final ValueNotifier<double> _warp = ValueNotifier<double>(
    journeyIdleWarp(widget.planetIdx),
  );

  @override
  void dispose() {
    _novaCtl.dispose();
    _warp.dispose();
    super.dispose();
  }

  /// The whole stage square flips over and is gone (nothing of the rocket
  /// shows); Nova hangs over the space it leaves, from the top of the window.
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _novaCtl,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_novaCtl.value);
        final back = t > 0.5;
        final angle = t * math.pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateX(back ? angle - math.pi : angle),
          child: Visibility(
            visible: !back,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: true,
            child: _front(context, 0),
          ),
        );
      },
    );
  }

  Widget _front(BuildContext context, double extra) {
    final planetIdx = widget.planetIdx;
    final planetColor = MM.planets[planetIdx]['color'] as Color;
    return Container(
      constraints: BoxConstraints(minHeight: 620 + extra),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF0A1136).withOpacity(0.35),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Nebula base + a starfield that is always drifting behind the whole
          // panel, and streaks when the rocket is under way.
          const Positioned.fill(
            child: StarfieldBackground(showScanlines: false, showStars: false),
          ),
          Positioned.fill(child: MovingStarfield(speed: _warp)),
          // target planet halo
          Positioned(
            top: 26,
            right: 26,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.3),
                  colors: [
                    planetColor.withOpacity(0.8),
                    planetColor.withOpacity(0.13),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 0.7],
                ),
              ),
            ),
          ),
          // The normal stage stays mounted under the console (so the journey
          // keeps its state) and just fades out of the way.
          IgnorePointer(
            ignoring: _commandOpen,
            child: AnimatedOpacity(
              opacity: _commandOpen ? 0 : 1,
              duration: const Duration(milliseconds: 350),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'MISSION IN PROGRESS',
                      style: GoogleFonts.orbitron(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.2,
                        color: const Color(0xFFD8C0FF).withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Cockpit dashboard by default; plays the arrival cinematic in
                    // place when the player reaches a new planet, and the vertical
                    // rail on its right replays any leg on tap.
                    JourneyStage(
                      key: tourKey('rocket'),
                      planetIdx: planetIdx,
                      activeCores: widget.activeCores,
                      atRiskCores: widget.atRiskCores,
                      streak: widget.streak,
                      height: 500,
                      rocketWidth: 260,
                      warpSpeed: _warp,
                      dailyIntro: true,
                      onNav: widget.onNav,
                      onCoreAlert: widget.onCoreAlert,
                      onOpenCommandCenter:
                          () => setState(() => _commandOpen = true),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Command Center console — takes the whole panel while open.
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
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
                      ? Padding(
                        key: const ValueKey('command'),
                        padding: const EdgeInsets.all(12),
                        child: LayoutBuilder(
                          builder:
                              (context, c) => CommandCenterConsole(
                                width: c.maxWidth,
                                height: c.maxHeight,
                                onClose:
                                    () => setState(() => _commandOpen = false),
                                onNav: widget.onNav,
                              ),
                        ),
                      )
                      : const SizedBox.shrink(key: ValueKey('none')),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// RIGHT — flight data
// ═══════════════════════════════════════════════════════════════
class _FlightData extends StatelessWidget {
  const _FlightData({
    super.key,
    required this.planet,
    required this.streakProtection,
    required this.balance,
    required this.momentumScore,
    required this.spaceCredits,
    required this.nextPlanetName,
    required this.onNav,
  });
  final Map<String, dynamic> planet;
  final Widget? streakProtection;
  final int? balance;
  final int momentumScore;
  final int spaceCredits;
  final String? nextPlanetName;
  final void Function(String key) onNav;

  @override
  Widget build(BuildContext context) {
    // Phase 1&2 Details (Rocket Dashboard) stats box: Current Planet · Momentum Score · Balance %.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel('FLIGHT DATA'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'Planet',
                value: (planet['name'] as String).toUpperCase(),
                valueSize: 20,
                tip: 'Your current planet on the route. Momentum Score carries you to the next stop.',
                accent: planet['color'] as Color,
                sub:
                    nextPlanetName == null
                        ? 'Final stop'
                        : 'Next: $nextPlanetName',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Stat(
                label: 'Balance',
                value: balance == null ? '—' : '$balance%',
                tip: 'How evenly your last 7 days covered all 5 Cores. '
                    'Aim to Fire On All Cylinders 🚀.',
                accent: MM.teal,
                sub: '5-Core, 7 days',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Stat(
          label: 'Momentum Score',
          value: _fmt(momentumScore),
          tip: 'Points you earn from check-ins and habits. They propel your rocket forward.',
          accent: MM.yellow,
          sub: 'Propels the rocket forward',
        ),
        const SizedBox(height: 12),
        _Stat(
          label: 'Space Credits',
          value: _fmt(spaceCredits),
          tip: 'Your currency. Spend it in the Space Cantina.',
          accent: MM.yellow,
          sub: 'Spend in the Cantina',
        ),
        if (streakProtection != null) ...[
          const SizedBox(height: 12),
          WithInfo(
            text:
                'Streak Savers and Vacation Mode protect your streak on days '
                "you can't check in.",
            child: streakProtection!,
          ),
        ],
      ],
    );
  }

  static String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.accent,
    this.sub,
    this.valueSize = 28,
    this.tip,
  });
  final String? tip;
  final String label;
  final String value;
  final Color accent;
  final String? sub;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: GoogleFonts.orbitron(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
            if (tip != null) InfoTip(tip!, size: 14),
          ]),
          const SizedBox(height: 6),
          Text(
            value,
            style: MM.display(size: valueSize, color: accent, height: 1),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (sub != null) ...[
            const SizedBox(height: 5),
            Text(
              sub!,
              style: MM.body(size: 11, color: Colors.white.withOpacity(0.5)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Check-in as an icon (the tablet Nova header has no room for the long
/// "Daily Check-in" button).
class _CheckInIcon extends StatelessWidget {
  const _CheckInIcon({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Daily Check-in',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3A8DFF), Color(0xFF1F5FB8)],
            ),
            boxShadow: [BoxShadow(color: MM.blue.withOpacity(0.4), blurRadius: 12)],
          ),
          child: const Icon(Icons.task_alt, size: 24, color: Colors.white),
        ),
      ),
    );
  }
}

/// Compact planet / score / credits / balance card (same four values as the
/// phone's top-right card).
class _NovaStats extends StatelessWidget {
  const _NovaStats({
    required this.planetName,
    required this.planetColor,
    required this.score,
    required this.credits,
    required this.balance,
  });
  final String planetName;
  final Color planetColor;
  final int score;
  final int credits;
  final int? balance;

  static String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    Widget row(String l, String v, Color c) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l,
                  style: GoogleFonts.orbitron(
                      fontSize: 9,
                      letterSpacing: 1.2,
                      color: Colors.white.withOpacity(0.55))),
              Text(v,
                  style: GoogleFonts.orbitron(
                      fontSize: 12, fontWeight: FontWeight.w700, color: c)),
            ],
          ),
        );
    return SizedBox(
      width: 170,
      child: _Panel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row('PLANET', planetName.toUpperCase(), planetColor),
            row('SCORE', _fmt(score), Colors.white),
            row('CREDITS', '${_fmt(credits)} 💎', MM.yellow),
            row('BALANCE', balance == null ? '—' : '$balance%', MM.teal),
          ],
        ),
      ),
    );
  }
}
