import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/momentum_tokens.dart';
import '../../widgets/momentum/journey_arc.dart';
import '../../widgets/momentum/mm_buttons.dart';
import '../../widgets/momentum/rocket_widget.dart';
import '../../widgets/momentum/starfield.dart';

/// Desktop flagship: the 3-column Cockpit (5 Cores · rocket stage · flight
/// data), wired to the real profile data MomentumHome already holds. Mirrors
/// web.jsx's WebCockpit; the mobile DashboardPage still renders below 900px.
class WebCockpit extends StatelessWidget {
  const WebCockpit({
    super.key,
    required this.name,
    required this.streak,
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
  final String planet;
  final List<String> activeCores;
  final Set<String> atRiskCores;
  final String level;
  final int momentumScore;
  final int spaceCredits;
  final int balance;
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

  // Next-planet momentum threshold used for the "Next planet in …" readout.
  int get _nextPlanetPts {
    const step = 12000;
    return ((momentumScore ~/ step) + 1) * step;
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
          streak: streak,
          balance: balance,
          momentumScore: momentumScore,
          spaceCredits: spaceCredits,
          nextPlanetPts: _nextPlanetPts,
          onNav: onNav,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 4, 40, 56),
          child: wide
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
        );
      },
    );
  }
}

// ── shared glass panel base (mm-panel) ──
class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding, this.borderColor});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111C4E).withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: borderColor ?? Colors.white.withOpacity(0.10)),
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
      required this.active});
  final String id;
  final String label;
  final String icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final hex = MM.coreColor[id] ?? MM.blue;
    return Opacity(
      opacity: active ? 1 : 0.58,
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
                          color: Colors.white,
                          weight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(active ? 'ACTIVE' : 'DORMANT',
                      style: GoogleFonts.orbitron(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: active
                              ? hex
                              : Colors.white.withOpacity(0.4))),
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CENTER — rocket stage
// ═══════════════════════════════════════════════════════════════
class _RocketStage extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
          const Positioned.fill(
              child: StarfieldBackground(showScanlines: false)),
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
                RocketWidget(
                  width: 260,
                  maxWidth: 280,
                  activeCores: activeCores,
                  atRiskCores: atRiskCores,
                  streak: streak,
                  onNav: onNav,
                  onCoreAlert: onCoreAlert,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 96,
                  child: JourneyArc(planetIdx: planetIdx, progress: 0.38),
                ),
                const SizedBox(height: 20),
                FractionallySizedBox(
                  widthFactor: 0.8,
                  child: MMPrimaryButton(
                    label: 'Daily Check-in →',
                    pulse: true,
                    expand: true,
                    onPressed: onCheckIn,
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
    required this.streak,
    required this.balance,
    required this.momentumScore,
    required this.spaceCredits,
    required this.nextPlanetPts,
    required this.onNav,
  });
  final int streak;
  final int balance;
  final int momentumScore;
  final int spaceCredits;
  final int nextPlanetPts;
  final void Function(String key) onNav;

  @override
  Widget build(BuildContext context) {
    final toNext = (nextPlanetPts - momentumScore).clamp(0, nextPlanetPts);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel('FLIGHT DATA'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _Stat(
                    label: 'Streak', value: '${streak}d', accent: MM.red)),
            const SizedBox(width: 12),
            Expanded(
                child: _Stat(
                    label: 'Balance',
                    value: '$balance%',
                    accent: MM.teal)),
          ],
        ),
        const SizedBox(height: 12),
        _Stat(
          label: 'Momentum Score',
          value: _fmt(momentumScore),
          accent: MM.yellow,
          sub: 'Next planet in ${_fmt(toNext)} pts',
        ),
        const SizedBox(height: 12),
        _Stat(
          label: 'Space Credits',
          value: _fmt(spaceCredits),
          accent: MM.yellow,
          sub: 'Spend in the Cantina',
        ),
        const SizedBox(height: 12),
        // active quest
        _QuestCard(streak: streak, onTap: () => onNav('trophy')),
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
      this.sub});
  final String label;
  final String value;
  final Color accent;
  final String? sub;

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
              style: MM.display(size: 28, color: accent, height: 1)),
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

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.streak, required this.onTap});
  final int streak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Next milestone at the coming multiple of 50 days.
    final target = ((streak ~/ 50) + 1) * 50;
    final pct = (streak / target).clamp(0.0, 1.0);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: _Panel(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          borderColor: MM.yellow.withOpacity(0.35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text('ACTIVE QUEST',
                      style: GoogleFonts.orbitron(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: MM.yellow)),
                ],
              ),
              const SizedBox(height: 6),
              Text('Reach a $target-day streak',
                  style: MM.body(
                      size: 13.5,
                      color: Colors.white,
                      weight: FontWeight.w600)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 5,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation(MM.yellow),
                ),
              ),
              const SizedBox(height: 6),
              Text('$streak/$target days',
                  style: MM.body(
                      size: 10.5, color: Colors.white.withOpacity(0.5))),
            ],
          ),
        ),
      ),
    );
  }
}
