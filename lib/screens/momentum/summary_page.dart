import 'package:flutter/material.dart';
import '../../services/checkin_service.dart';
import '../../theme/momentum_tokens.dart';
import '../../widgets/momentum/glass_panel.dart';
import '../../widgets/momentum/mm_buttons.dart';
import '../../widgets/momentum/starfield.dart';
import '../../widgets/momentum/streak_flame.dart';

/// Progress Summary / Mission Recap (Screen 3.5).
///
/// Real numbers only: Total Momentum + streak come from the persisted profile;
/// the 5-Core Balance Meter is the rolling 7-day average of real check-in
/// scores. The economy stats (per-check-in points, Space Credits, Mystery Box,
/// Daily Challenge) depend on the not-yet-built Points engine (#9) / gamified
/// economy (#13) — they are shown as clearly-marked "not yet live" placeholders
/// rather than fabricated figures.
class SummaryPage extends StatefulWidget {
  const SummaryPage({
    super.key,
    required this.onClose,
    this.userId = '',
    this.streak = 0,
    this.activeCores = const <String>[],
    this.momentumScore = 0,
    this.earnedToday,
    this.todayScores = const <String, int>{},
  });

  /// Signed-in uid — used to read recent check-ins for the Balance Meter.
  final String userId;
  final int streak;
  final List<String> activeCores;

  /// Real running Momentum Points from the profile.
  final int momentumScore;

  /// Points credited for today's check-in (#9). Null when unknown (e.g. opening
  /// the Summary outside a fresh check-in) → shown as a pending placeholder.
  final int? earnedToday;

  /// The scores just submitted this check-in — folded into the rolling average
  /// immediately so the meter reflects today even before the read settles.
  final Map<String, int> todayScores;

  final VoidCallback onClose;

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  final _checkin = CheckinService();

  /// shortCoreId → rolling 7-day average score (1–5).
  Map<String, double> _balance = const {};
  int _balanceDays = 0;
  bool _balanceLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  /// Builds the 5-Core Balance Meter from the last 7 days of real check-ins.
  /// Each active Core is averaged over the days that scored it (no fabricated
  /// fill for Cores/days without data).
  Future<void> _loadBalance() async {
    final byDate = <String, Map<String, int>>{};
    if (widget.userId.isNotEmpty) {
      try {
        final recent = await _checkin.getRecent(widget.userId, limit: 7);
        for (final d in recent) {
          byDate[d.date] = d.scores;
        }
      } catch (_) {
        // Best-effort: an empty meter is honest; never fabricate scores.
      }
    }
    // Overlay today's just-submitted scores under today's date id (merges, so
    // it can't double-count a same-day check-in already returned above).
    if (widget.todayScores.isNotEmpty) {
      final todayId = CheckinService.dayId(DateTime.now());
      byDate[todayId] = {...?byDate[todayId], ...widget.todayScores};
    }

    // Most-recent 7 distinct days = the rolling window.
    final window = (byDate.keys.toList()..sort((a, b) => b.compareTo(a)))
        .take(7)
        .toList();
    final sums = <String, int>{};
    final counts = <String, int>{};
    for (final dt in window) {
      byDate[dt]!.forEach((core, sc) {
        sums[core] = (sums[core] ?? 0) + sc;
        counts[core] = (counts[core] ?? 0) + 1;
      });
    }
    final avg = <String, double>{};
    sums.forEach((core, s) {
      final c = counts[core] ?? 0;
      if (c > 0) avg[core] = s / c;
    });

    if (!mounted) return;
    setState(() {
      _balance = avg;
      _balanceDays = window.length;
      _balanceLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MM.pageBg,
      body: Stack(
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                  child: Row(
                    children: [
                      Text('Mission Recap',
                          style: MM.displayX(size: 13, color: Colors.white)),
                      const Spacer(),
                      MMGhostButton(
                        label: 'Cockpit →',
                        onPressed: widget.onClose,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                      ),
                    ],
                  ),
                ),
                // Confirmation banner
                _Reveal(
                  delay: const Duration(milliseconds: 0),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0x4000A98F), Color(0x0D00A98F)],
                      ),
                      border: Border.all(color: MM.teal.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: MM.teal,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 12),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Day logged. Moving on.',
                            style: MM.body(color: Colors.white, size: 12)),
                      ),
                      Text(_today(),
                          style: MM.display(size: 12, color: MM.teal)),
                    ]),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    child: Column(
                      children: [
                        // Real running Momentum Points.
                        _StatRow(
                          label: 'Total Momentum',
                          value: widget.momentumScore,
                          suffix: ' MP',
                          accent: MM.blue,
                          delay: 150,
                        ),
                        // Real per-check-in points (#9). Weekends / non-check-in
                        // opens have no award → pending placeholder.
                        if (widget.earnedToday != null)
                          _StatRow(
                            label: 'Earned Today',
                            value: widget.earnedToday!,
                            suffix: ' MP',
                            accent: MM.teal,
                            delay: 350,
                          )
                        else
                          const _PendingStatRow(
                            label: 'Earned Today',
                            note: 'Daily check-in points arrive with the '
                                'Momentum Points engine.',
                            delay: 350,
                          ),
                        // Real persisted streak (no optimistic +1 — the streak
                        // system increments server-side once #10 lands).
                        _StreakCallout(days: widget.streak, delay: 550),
                        // Space Credits await the gamified economy (#13).
                        const _PendingStatRow(
                          label: 'Space Credits',
                          note: 'The Space Credits economy comes online soon.',
                          delay: 750,
                        ),
                        _BalanceMeter(
                          balance: _balance,
                          activeCores: widget.activeCores,
                          loading: _balanceLoading,
                          days: _balanceDays,
                          delay: 950,
                        ),
                        const _TodaysFocus(delay: 1150),
                        const _DailyChallenge(delay: 1350),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _today() {
    final m = const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final d = DateTime.now();
    return '${m[d.month - 1]} ${d.day}';
  }
}

class _Reveal extends StatefulWidget {
  const _Reveal({required this.child, required this.delay});
  final Widget child;
  final Duration delay;
  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: _ctrl,
      curve: const Cubic(0.22, 1, 0.36, 1),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(curve),
        child: widget.child,
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.accent,
    this.suffix = '',
    required this.delay,
  });
  final String label;
  final int value;
  final Color? accent;
  final String suffix;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return _Reveal(
      delay: Duration(milliseconds: delay),
      child: GlassPanel(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label.toUpperCase(),
                style: MM.displayX(
                    size: 11, color: Colors.white.withOpacity(0.65))),
            _CountUp(
              to: value,
              suffix: suffix,
              style: MM.display(size: 22, color: accent ?? Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// A stat whose real value isn't available yet (depends on an unbuilt system).
/// Shows the label + a muted "—" + a one-line reason and a "SOON" chip —
/// deliberately no number, so nothing on this screen is fabricated.
class _PendingStatRow extends StatelessWidget {
  const _PendingStatRow({
    required this.label,
    required this.note,
    required this.delay,
  });
  final String label;
  final String note;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return _Reveal(
      delay: Duration(milliseconds: delay),
      child: GlassPanel(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(label.toUpperCase(),
                        style: MM.displayX(
                            size: 11, color: Colors.white.withOpacity(0.65))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.18)),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('SOON',
                          style: MM.display(
                              size: 8,
                              color: Colors.white.withOpacity(0.55),
                              weight: FontWeight.w700,
                              letterSpacing: 8 * 0.12)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(note,
                      style: MM.body(
                          color: Colors.white.withOpacity(0.5), size: 11.5)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('—',
                style:
                    MM.display(size: 22, color: Colors.white.withOpacity(0.3))),
          ],
        ),
      ),
    );
  }
}

class _CountUp extends StatefulWidget {
  const _CountUp({required this.to, this.suffix = '', required this.style});
  final int to;
  final String suffix;
  final TextStyle style;
  Duration get duration => const Duration(milliseconds: 900);

  @override
  State<_CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<_CountUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final eased =
            1 - (1 - _ctrl.value) * (1 - _ctrl.value) * (1 - _ctrl.value);
        final n = (eased * widget.to).round();
        return Text(_fmt(n) + widget.suffix, style: widget.style);
      },
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

class _StreakCallout extends StatelessWidget {
  const _StreakCallout({required this.days, required this.delay});
  final int days;
  final int delay;

  int _nextMilestone(int d) {
    for (final m in const [7, 14, 30, 60, 90, 180, 365]) {
      if (d < m) return m;
    }
    return 365;
  }

  @override
  Widget build(BuildContext context) {
    return _Reveal(
      delay: Duration(milliseconds: delay),
      child: GlassPanel(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderColor: MM.yellow.withOpacity(0.35),
        background: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MM.red.withOpacity(0.18),
              MM.yellow.withOpacity(0.10),
              MM.navy.withOpacity(0.55),
            ],
            stops: const [0, 0.6, 1],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          StreakFlame(days: days, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(days > 0 ? 'Current Streak' : 'No Active Streak',
                    style: MM.displayX(size: 10, color: MM.yellow)),
                const SizedBox(height: 2),
                Text('Day $days',
                    style: MM.display(size: 20, color: Colors.white)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('NEXT MILESTONE',
                  style: MM.display(
                      size: 10, color: Colors.white.withOpacity(0.5))),
              Text('${_nextMilestone(days)}',
                  style: MM.display(size: 16, color: MM.yellow)),
            ],
          ),
        ]),
      ),
    );
  }
}

/// 5-Core Balance Meter — rolling 7-day average of real check-in scores.
class _BalanceMeter extends StatelessWidget {
  const _BalanceMeter({
    required this.balance,
    required this.activeCores,
    required this.loading,
    required this.days,
    required this.delay,
  });
  final Map<String, double> balance;
  final List<String> activeCores;
  final bool loading;
  final int days;
  final int delay;

  static const _cores = [
    {'id': 'mindset', 'name': 'Mind', 'color': MM.blue},
    {'id': 'career', 'name': 'Career', 'color': MM.yellow},
    {'id': 'relationships', 'name': 'Rel.', 'color': MM.magenta},
    {'id': 'physical', 'name': 'Phys.', 'color': MM.teal},
    {'id': 'emotional', 'name': 'Emo.', 'color': MM.violet},
  ];

  @override
  Widget build(BuildContext context) {
    return _Reveal(
      delay: Duration(milliseconds: delay),
      child: GlassPanel(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('5-CORE BALANCE · 7-DAY ROLLING',
                    style: MM.displayX(
                        size: 10, color: Colors.white.withOpacity(0.55))),
                if (!loading)
                  Text(
                    days == 0 ? 'NO DATA YET' : '$days DAY${days == 1 ? '' : 'S'}',
                    style: MM.display(
                        size: 9, color: Colors.white.withOpacity(0.4)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: MM.blue),
                  ),
                ),
              )
            else
              ..._cores.map((c) {
                final id = c['id'] as String;
                final active = activeCores.contains(id);
                final avg = balance[id];
                final hasData = avg != null;
                final pct = (active && hasData) ? (avg / 5).clamp(0.0, 1.0) : 0.0;
                final color = c['color'] as Color;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    SizedBox(
                      width: 44,
                      child: Text((c['name'] as String).toUpperCase(),
                          style: MM.display(
                            size: 10,
                            color: active
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                          )),
                    ),
                    Expanded(
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: active
                            ? (hasData
                                ? FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: pct,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [
                                          color.withOpacity(0.66),
                                          color,
                                        ]),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        boxShadow: [
                                          BoxShadow(
                                              color: color, blurRadius: 8),
                                        ],
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink())
                            : const Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(Icons.lock,
                                      color: MM.yellow, size: 12),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 30,
                      child: Text(
                        active
                            ? (hasData ? avg.toStringAsFixed(1) : '–')
                            : '—',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        style: MM.display(
                          size: 11,
                          color: active && hasData
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ]),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// Today's Focus — Nova's coaching surface. The personalized version is fed by
/// the AI pattern engine (not yet wired), so this is shown as a clearly-marked
/// preview with general guidance and NO fabricated per-habit numbers.
class _TodaysFocus extends StatelessWidget {
  const _TodaysFocus({required this.delay});
  final int delay;
  @override
  Widget build(BuildContext context) {
    return _Reveal(
      delay: Duration(milliseconds: delay),
      child: GlassPanel(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text("TODAY'S FOCUS · NOVA",
                  style: MM.displayX(
                      size: 10, color: Colors.white.withOpacity(0.55))),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: MM.blue.withOpacity(0.12),
                  border: Border.all(color: MM.blue.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('PREVIEW',
                    style: MM.display(
                        size: 8,
                        color: MM.blue,
                        weight: FontWeight.w700,
                        letterSpacing: 8 * 0.12)),
              ),
            ]),
            const SizedBox(height: 10),
            Text(
              'Personalized focus from Nova arrives once the AI has more of '
              'your check-in history to learn from. For now: keep your '
              'lowest Core in view and protect the habit that moves it.',
              style: MM.body(
                  color: Colors.white.withOpacity(0.7), size: 12.5, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Daily Challenge — a gamified-economy feature (#13). Shown as a marked
/// "coming soon" teaser with no fabricated reward amount or live actions.
class _DailyChallenge extends StatelessWidget {
  const _DailyChallenge({required this.delay});
  final int delay;
  @override
  Widget build(BuildContext context) {
    return _Reveal(
      delay: Duration(milliseconds: delay),
      child: GlassPanel(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderColor: MM.teal.withOpacity(0.35),
        background: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [MM.teal.withOpacity(0.15), MM.navy.withOpacity(0.55)],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('DAILY CHALLENGE',
                  style: MM.displayX(size: 10, color: MM.teal)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: MM.teal.withOpacity(0.12),
                  border: Border.all(color: MM.teal.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('COMING SOON',
                    style: MM.display(
                        size: 8,
                        color: MM.teal,
                        weight: FontWeight.w700,
                        letterSpacing: 8 * 0.12)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              'Optional streak challenges land with the gamified economy.',
              style: MM.body(
                  color: Colors.white.withOpacity(0.7), size: 13),
            ),
          ],
        ),
      ),
    );
  }
}
