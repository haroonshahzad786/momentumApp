import 'package:flutter/material.dart';
import '../../models/phase1_state.dart';
import '../../theme/momentum_tokens.dart';
import '../../widgets/momentum/glass_panel.dart';
import '../../widgets/momentum/journey_arc.dart';
import '../../widgets/momentum/mm_buttons.dart';
import '../../widgets/momentum/offline_banner.dart';
import '../../widgets/momentum/rocket_widget.dart';
import '../../widgets/momentum/starfield.dart';
import '../../widgets/momentum/streak_flame.dart';

/// Default Rocket Dashboard (Screen 3.1) — the cockpit / home screen.
class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    this.streak = 47,
    this.streakState = 'ok',
    this.planet = 'mars',
    this.activeCores = const ['mindset', 'career', 'physical'],
    this.atRiskCores = const <String>{},
    this.level = 'navigator',
    this.momentumScore = 8420,
    this.spaceCredits = 0,
    this.balance = 78,
    this.phase1State,
    required this.onCheckIn,
    required this.onMenu,
    required this.onChat,
    required this.onNav,
    this.onCoreAlert,
    this.offline = false,
    this.onRefreshOffline,
  });

  final int streak;

  /// Streak health (#10): 'ok' · 'warning' (1 weekday missed) · 'broken'.
  final String streakState;
  final String planet;
  final List<String> activeCores;

  /// Cores out of balance (5+ days below 3.0) — render the red ⚠️ badge.
  final Set<String> atRiskCores;
  final String level;
  final int momentumScore;

  /// Space Credits balance (#13g — reward currency, shown in the top status bar).
  final int spaceCredits;
  final int balance;
  final Phase1State? phase1State;
  final VoidCallback onCheckIn;
  final VoidCallback onMenu;
  final VoidCallback onChat;
  final void Function(String key) onNav;
  final void Function(String coreId)? onCoreAlert;
  final bool offline;
  final VoidCallback? onRefreshOffline;

  @override
  Widget build(BuildContext context) {
    final planetIdx =
        MM.planets.indexWhere((p) => p['id'] == planet).clamp(0, 5);
    final planetData = MM.planets[planetIdx];
    final planetColor = planetData['color'] as Color;

    return Scaffold(
      backgroundColor: MM.pageBg,
      body: Stack(
        children: [
          Positioned.fill(child: StarfieldBackground(accent: planetColor)),

          // Distant target planet
          Positioned(
            top: 80,
            right: -50,
            width: 220,
            height: 220,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.4, -0.4),
                    radius: 0.7,
                    colors: [
                      planetColor.withOpacity(0.4),
                      planetColor.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ─── TOP BAR ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IconBtn(
                        icon: Icons.menu,
                        onTap: onMenu,
                      ),
                      const SizedBox(width: 10),
                      _IconBtn(
                        icon: Icons.emoji_events_outlined,
                        color: MM.yellow,
                        borderColor: MM.yellow.withOpacity(0.35),
                        glow: true,
                        onTap: () => onNav('trophy'),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            StreakFlame(days: streak),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  Text('STREAK',
                                      style: MM.displayX(
                                          size: 11,
                                          color: streakState == 'ok'
                                              ? MM.yellow
                                              : MM.red)),
                                  if (streakState == 'warning') ...[
                                    const SizedBox(width: 4),
                                    const Text('⚠',
                                        style: TextStyle(
                                            fontSize: 10, color: MM.red)),
                                  ],
                                ]),
                                const SizedBox(height: 2),
                                Text('DAY $streak',
                                    style: MM.display(
                                        size: 18, color: Colors.white)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      GlassPanel(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        child: SizedBox(
                          width: 120,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _Stat('PLANET',
                                  (planetData['name'] as String).toUpperCase(),
                                  planetColor),
                              const SizedBox(height: 3),
                              _Stat(
                                  'SCORE', _fmt(momentumScore), Colors.white),
                              const SizedBox(height: 3),
                              _Stat('CREDITS', '${_fmt(spaceCredits)} 💎',
                                  MM.yellow),
                              const SizedBox(height: 3),
                              _Stat('BALANCE', '$balance%', MM.teal),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── OFFLINE BANNER (cached cockpit) ──────
                if (offline)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                    child: OfflineBanner(
                        onRefresh: onRefreshOffline ?? () {}),
                  ),

                // ─── PHASE INDICATOR PILL ─────────────────
                if (phase1State != null)
                  _PhasePill(
                    state: phase1State!,
                    onTap: () => onNav('phase1'),
                  ),

                // ─── QUICK ICON ROW ───────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        _QuickIcon(
                            icon: Icons.tune,
                            color: MM.blue,
                            label: 'Lists',
                            onTap: () => onNav('lists')),
                        const SizedBox(width: 8),
                        _QuickIcon(
                            icon: Icons.access_time,
                            color: MM.teal,
                            label: 'Routines',
                            onTap: () => onNav('routines')),
                      ]),
                      Row(children: [
                        _QuickIcon(
                            icon: Icons.all_inclusive,
                            color: MM.magenta,
                            label: 'Habits',
                            onTap: () => onNav('habits')),
                        const SizedBox(width: 8),
                        _QuickIcon(
                            icon: Icons.check_box_outlined,
                            color: MM.yellow,
                            label: 'Tasks',
                            onTap: () => onNav('tasks')),
                      ]),
                    ],
                  ),
                ),

                // ─── HERO ROCKET ──────────────────────────
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: RocketWidget(
                          activeCores: activeCores,
                          atRiskCores: atRiskCores,
                          streak: streak,
                          onNav: onNav,
                          onCoreAlert: onCoreAlert,
                        ),
                      ),
                      // Back near its original spot hanging off the right edge,
                      // but only far enough that the FAB's CENTRE stays on-screen
                      // — push it fully off and the taps stop registering.
                      Positioned(
                        right: -21,
                        bottom: -6,
                        child: _CopilotFAB(onTap: onChat),
                      ),
                    ],
                  ),
                ),

                // ─── JOURNEY ARC ──────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: JourneyArc(planetIdx: planetIdx),
                ),

                // ─── PRIMARY CTA ──────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    children: [
                      MMPrimaryButton(
                        label: 'Daily Check-in →',
                        pulse: true,
                        onPressed: onCheckIn,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${activeCores.length}/5 CORES ACTIVE · ${level.toUpperCase()}',
                        style: MM.display(
                            size: 10, color: Colors.white.withOpacity(0.45)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
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
  const _Stat(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: MM.displayX(
                  size: 7, color: Colors.white.withOpacity(0.6))),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(value,
                maxLines: 1,
                softWrap: false,
                style: MM.display(size: 10, color: color, height: 1)),
          ),
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
    this.borderColor,
    this.glow = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color? borderColor;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: MM.navy.withOpacity(0.55),
          border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.12)),
          borderRadius: BorderRadius.circular(10),
          boxShadow: glow
              ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12)]
              : null,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

class _QuickIcon extends StatelessWidget {
  const _QuickIcon({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: MM.navy.withOpacity(0.55),
          border: Border.all(color: MM.blue.withOpacity(0.35)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: MM.blue.withOpacity(0.25), blurRadius: 14),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: MM.display(
                  size: 8,
                  color: Colors.white.withOpacity(0.7),
                  weight: FontWeight.w600,
                  letterSpacing: 8 * 0.08,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhasePill extends StatelessWidget {
  const _PhasePill({required this.state, required this.onTap});
  final Phase1State state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s1 = state.stage1Completed;
    final s2 = state.stage2Completed;
    final inPhase2 = s1 && s2;
    final inStage2 = s1 && !s2;
    final label = inPhase2
        ? 'PHASE 2 · DAILY EXECUTION'
        : inStage2
            ? 'PHASE 1 · STAGE 2 IN PROGRESS'
            : 'PHASE 1 · STAGE 1 (${state.stage1Progress}/5)';
    final color = inPhase2 ? MM.teal : MM.yellow;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: MM.navy.withOpacity(0.6),
              border: Border.all(color: color.withOpacity(0.4)),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.25), blurRadius: 12),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [BoxShadow(color: color, blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 8),
                Text(label,
                    style: MM.display(
                      size: 9,
                      color: color,
                      weight: FontWeight.w700,
                      letterSpacing: 9 * 0.16,
                    )),
                const SizedBox(width: 8),
                Text('›',
                    style: TextStyle(
                      color: color.withOpacity(0.6),
                      fontSize: 14,
                      height: 1,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CopilotFAB extends StatefulWidget {
  const _CopilotFAB({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_CopilotFAB> createState() => _CopilotFABState();
}

class _CopilotFABState extends State<_CopilotFAB>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final glow = 24 + _pulse.value * 20;
        return GestureDetector(
          onTap: widget.onTap,
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.4, -0.4),
                    radius: 0.9,
                    colors: [Color(0xFFB58AFF), Color(0xFF6B3DF5), MM.blue],
                  ),
                  border: Border.all(
                      color: const Color(0xFFD8C0FF).withOpacity(0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: MM.violet.withOpacity(0.6),
                      blurRadius: glow,
                    ),
                  ],
                ),
                child: const Icon(Icons.star_border,
                    color: Colors.white, size: 48),
              ),
              const SizedBox(height: 4),
              Text(
                'CO-PILOT',
                style: MM.display(
                  size: 9,
                  color: const Color(0xFFD8C0FF),
                  weight: FontWeight.w900,
                  letterSpacing: 9 * 0.18,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
