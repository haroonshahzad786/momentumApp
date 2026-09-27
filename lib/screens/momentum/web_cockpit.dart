import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/momentum_tokens.dart';
import '../../widgets/momentum/journey_stage.dart';
import '../../widgets/momentum/mm_buttons.dart';
import '../../widgets/momentum/starfield.dart';
import '../../widgets/momentum/streak_bar.dart';

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
  });

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
        final center = _RocketStage(
          planetIdx: _planetIdx,
          activeCores: activeCores,
          atRiskCores: atRiskCores,
          streak: streak,
          onNav: onNav,
          onCheckIn: onCheckIn,
          onCoreAlert: onCoreAlert,
        );
        final right = _FlightData(
          planet: MM.planets[_planetIdx],
          streakProtection: streakProtection,
          balance: balance,
          momentumScore: momentumScore,
          spaceCredits: spaceCredits,
          nextPlanetName: _nextPlanetName,
          onNav: onNav,
        );
        // PRD 12.10 "Across top: Current Streak with consecutive days and
        // days until reward".
        final streakBar = StreakBar(
          streak: streak,
          streakState: streakState,
          streakSavers: streakSavers,
          onTap: onStreakTap,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 4, 40, 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              streakBar,
              const SizedBox(height: 20),
              wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 20, child: left),
                    const SizedBox(width: 24),
                    Expanded(flex: 30, child: center),
                    const SizedBox(width: 24),
                    Expanded(flex: 20, child: right),
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
        );
      },
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
      child: Text(text,
          style: GoogleFonts.orbitron(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: Colors.white)),
    );

// ═══════════════════════════════════════════════════════════════
// LEFT — the 5 cores
// ═══════════════════════════════════════════════════════════════
class _CoresColumn extends StatelessWidget {
  const _CoresColumn(
      {required this.cores, required this.activeCores, required this.onNav});
  final List<(String, String, String)> cores;
  final List<String> activeCores;
  final void Function(String key) onNav;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel('THE 5 CORES'),
        const SizedBox(height: 12),
        for (final core in cores) ...[
          _CoreCard(
            id: core.$1,
            label: core.$2,
            icon: core.$3,
            active: activeCores.contains(core.$1),
            // Active → that Core's habits; dormant → fuel it via HHS.
            onTap: () => onNav(activeCores.contains(core.$1)
                ? 'habits:${core.$1}'
                : 'fuel:${core.$1}'),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        MMGhostButton(label: 'Manage cores →', onPressed: () => onNav('habits')),
      ],
    );
  }
}

class _CoreCard extends StatelessWidget {
  const _CoreCard(
      {required this.id,
      required this.label,
      required this.icon,
      required this.active,
      required this.onTap});
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
                color: active
                    ? hex.withOpacity(0.13)
                    : Colors.white.withOpacity(0.05),
                border: Border.all(
                    color: active
                        ? hex.withOpacity(0.4)
                        : Colors.white.withOpacity(0.12)),
                boxShadow: active
                    ? [
                        BoxShadow(
                            color: hex.withOpacity(0.27),
                            blurRadius: 14,
                            spreadRadius: -2)
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
                  Text(label,
                      style: MM.body(
                          size: 13.5,
                          color: active
                              ? Colors.white
                              : Colors.white.withOpacity(0.55),
                          weight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(active ? 'ACTIVE' : 'DORMANT · FUEL THIS CORE →',
                      style: GoogleFonts.orbitron(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: active ? hex : MM.yellow.withOpacity(0.8))),
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
  });
  final int planetIdx;
  final List<String> activeCores;
  final Set<String> atRiskCores;
  final int streak;
  final void Function(String key) onNav;
  final VoidCallback onCheckIn;
  final void Function(String coreId) onCoreAlert;

  @override
  State<_RocketStage> createState() => _RocketStageState();
}

class _RocketStageState extends State<_RocketStage> {
  /// Shared between the journey stage (which drives it) and the panel-wide
  /// starfield (which reads it), so the stars stream faster mid-flight.
  late final ValueNotifier<double> _warp =
      ValueNotifier<double>(journeyIdleWarp(widget.planetIdx));

  @override
  void dispose() {
    _warp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planetIdx = widget.planetIdx;
    final planetColor = MM.planets[planetIdx]['color'] as Color;
    return Container(
      constraints: const BoxConstraints(minHeight: 620),
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
            child: StarfieldBackground(
                showScanlines: false, showStars: false),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('MISSION IN PROGRESS',
                    style: GoogleFonts.orbitron(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.2,
                        color: const Color(0xFFD8C0FF).withOpacity(0.85))),
                const SizedBox(height: 14),
                // Cockpit dashboard by default; plays the arrival cinematic in
                // place when the player reaches a new planet, and the vertical
                // rail on its right replays any leg on tap.
                JourneyStage(
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
                ),
                const SizedBox(height: 20),
                FractionallySizedBox(
                  widthFactor: 0.8,
                  child: MMPrimaryButton(
                    label: 'Daily Check-in →',
                    pulse: true,
                    expand: true,
                    onPressed: widget.onCheckIn,
                  ),
                ),
              ],
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
    // PRD 12.10 stats box: Current Planet · Momentum Score · Balance %.
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
                    accent: planet['color'] as Color,
                    sub: nextPlanetName == null
                        ? 'Final stop'
                        : 'Next: $nextPlanetName')),
            const SizedBox(width: 12),
            Expanded(
                child: _Stat(
                    label: 'Balance',
                    value: balance == null ? '—' : '$balance%',
                    accent: MM.teal,
                    sub: '5-Core, 7 days')),
          ],
        ),
        const SizedBox(height: 12),
        _Stat(
          label: 'Momentum Score',
          value: _fmt(momentumScore),
          accent: MM.yellow,
          sub: 'Propels the rocket forward',
        ),
        const SizedBox(height: 12),
        _Stat(
          label: 'Space Credits',
          value: _fmt(spaceCredits),
          accent: MM.yellow,
          sub: 'Spend in the Cantina',
        ),
        if (streakProtection != null) ...[
          const SizedBox(height: 12),
          streakProtection!,
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
  const _Stat(
      {required this.label,
      required this.value,
      required this.accent,
      this.sub,
      this.valueSize = 28});
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
          Text(label.toUpperCase(),
              style: GoogleFonts.orbitron(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Colors.white.withOpacity(0.5))),
          const SizedBox(height: 6),
          Text(value,
              style: MM.display(size: valueSize, color: accent, height: 1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          if (sub != null) ...[
            const SizedBox(height: 5),
            Text(sub!,
                style: MM.body(size: 11, color: Colors.white.withOpacity(0.5))),
          ],
        ],
      ),
    );
  }
}
