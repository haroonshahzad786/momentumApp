import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/onboarding_service.dart';
import '../../theme/momentum_tokens.dart';
import '../../widgets/momentum/mm_buttons.dart';
import '../../widgets/momentum/starfield.dart';

/// Daily Check-In: Score Your 5 Cores (Screen 3.3)
/// One core at a time, slider 1-5 with labels, captain's log textarea,
/// locked cores show gold lock pulse.
class CheckInPage extends StatefulWidget {
  const CheckInPage({
    super.key,
    this.activeCores = const ['mindset', 'career', 'physical'],
    this.atRiskCores = const <String>{},
    this.coreHistory = const {},
    this.habitByCore = const {},
    required this.onClose,
    required this.onComplete,
    required this.onFlagHabit,
    required this.onReturnToPhase1,
    this.onCoreAlert,
  });

  final List<String> activeCores;

  /// Cores out of balance (5+ days below 3.0) — show the red ⚠️ badge that
  /// opens the iCore Alert.
  final Set<String> atRiskCores;

  /// Per-Core prior check-in scores, most-recent-first, EXCLUDING today (today's
  /// live slider value is prepended on-screen). Feeds the real auto-flag
  /// pattern: a Core ≤ 3.0 for 3+ consecutive check-ins.
  final Map<String, List<int>> coreHistory;

  /// shortCoreId → the Core's real Golden Habit, so Mission Control flags /
  /// pre-loads the right habit (empty when none forged for that Core yet).
  final Map<String, GoldenHabitRef> habitByCore;

  final VoidCallback onClose;
  final void Function(Map<String, int> scores, Map<String, String> logs)
      onComplete;

  /// Persists a manual flag / experiment onto a Core's Golden Habit.
  final void Function(String habitId,
      {required bool flagged, String reason, String note}) onFlagHabit;

  /// Phase 1 Re-Entry Bridge (PHASE 1 & 2 DETAILS §4C). [stage] selects where
  /// the player lands in Phase 1:
  ///   • `null`  — proactive return to the Phase 1 hub to ignite a new Core.
  ///   • `'hhs'` — Path A "Rebuild This Habit" → Stage 1 (Habits Hierarchy).
  ///   • `'mbs'` — Path B "Better MBM Strategies" → Stage 2 (Momentum Boosting).
  /// [habitId] (when present) pre-loads the flagged Golden Habit on re-entry.
  final void Function(String? stage, {String? habitId}) onReturnToPhase1;

  /// Opens the iCore Alert for an out-of-balance Core (tapped red badge).
  final void Function(String coreId)? onCoreAlert;

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  static const _cores = <_Core>[
    _Core('mindset', 'Mindset', MM.blue,
        'I am a focused operator who runs on calm clarity, not panic.', [
      _Habit('Morning meditation · 10 min', 'mbms', 'Routine'),
      _Habit('Read 5 pages', 'forming', 'Routine'),
    ]),
    _Core('career', 'Career & Finances', MM.yellow,
        'I move with clarity on the work that compounds.', [
      _Habit('Deep-work block · 90 min', 'formed', 'Routine'),
      _Habit('Daily review · 5 min', 'mbms', 'Routine'),
      _Habit('Money log · weekly', 'forming', 'Non-Routine'),
    ]),
    _Core('relationships', 'Relationships', MM.magenta,
        'I show up first, fully, for the people who matter.', [],
        locked: true),
    _Core('physical', 'Physical Health', MM.teal,
        'I am an energized, active person who trains 5 days a week.', [
      _Habit('Strength training', 'mbms', 'Routine'),
      _Habit('Walk · 8,000 steps', 'forming', 'Routine'),
      _Habit('Hydrate · 3L', 'forming', 'Routine'),
    ]),
    _Core('emotional', 'Emotional & Mental', MM.violet,
        'I process, I do not perform.', [],
        locked: true),
  ];

  static const _scoreLabels = [
    '',
    'Completely skipped',
    'Partial',
    'Got through it · struggled',
    'Solid · minor friction',
    'Nailed it',
  ];

  static const _stageDefs = {
    'bad': _StageDef(Color(0xFFEA0029), 'Bad'),
    'forming': _StageDef(MM.yellow, 'Forming'),
    'mbms': _StageDef(MM.blue, 'MBMs attached'),
    'formed': _StageDef(MM.teal, 'Formed'),
    'trophy': _StageDef(MM.yellow, 'Trophy'),
  };

  int _idx = 0;
  final Map<String, int> _scores = {};
  final Map<String, String> _logs = {};

  // Mission Control intervention: the Core whose intervention is open, plus a
  // transient experiment toast after a path is picked.
  String? _flagCoreId;
  String? _expToast;
  Timer? _toastTimer;

  void _openFlag(String coreId) => setState(() => _flagCoreId = coreId);
  void _closeFlag() => setState(() => _flagCoreId = null);

  GoldenHabitRef? _refFor(String coreId) => widget.habitByCore[coreId];

  /// Display name for a Core's flagged habit: its real Golden Habit name, else
  /// the Core's first listed habit, else the Core name.
  String _flagLabel(String coreId) {
    final ref = _refFor(coreId);
    if (ref != null && ref.habitName.trim().isNotEmpty) {
      return ref.habitName.trim();
    }
    final core = _cores.firstWhere((c) => c.id == coreId,
        orElse: () => _cores.first);
    return core.habits.isNotEmpty ? core.habits.first.name : core.name;
  }

  /// Today's effective score (live slider, default 3) followed by the Core's
  /// prior check-in scores — most-recent-first.
  List<int> _recentFor(String coreId) =>
      [_scores[coreId] ?? 3, ...?widget.coreHistory[coreId]];

  /// Consecutive most-recent check-ins (incl. today) at or below 3.0 — the
  /// auto-flag pattern fires at ≥ 3.
  int _consecutiveLow(String coreId) {
    var n = 0;
    for (final s in _recentFor(coreId)) {
      if (s <= 3) {
        n++;
      } else {
        break;
      }
    }
    return n;
  }

  /// Last up-to-3 scores for the pattern chart, oldest-first (D-2 … D0).
  List<double> _patternBars(String coreId) =>
      _recentFor(coreId).take(3).toList().reversed.map((s) => s.toDouble()).toList();

  /// Persists the chosen refinement as a flag + experiment note on the Core's
  /// real Golden Habit (anti-shame: a flag means "needs adjusting").
  void _logExperiment(String tag) {
    final coreId = _flagCoreId;
    _toastTimer?.cancel();
    if (coreId != null) {
      final ref = _refFor(coreId);
      if (ref != null) {
        widget.onFlagHabit(ref.habitId, flagged: true, reason: tag);
      }
    }
    setState(() {
      _flagCoreId = null;
      _expToast = '🧪 $tag · 3-day experiment logged';
    });
    _toastTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _expToast = null);
    });
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  List<_Core> get _displayed => _cores
      .map((c) => _Core(
            c.id,
            c.name,
            c.color,
            c.vision,
            c.habits,
            locked: !widget.activeCores.contains(c.id),
          ))
      .toList();

  void _advance() {
    final cores = _displayed;
    if (_idx == cores.length - 1) {
      widget.onComplete(_scores, _logs);
    } else {
      setState(() => _idx++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = _displayed;
    final core = cores[_idx];
    final isLast = _idx == cores.length - 1;
    final score = _scores[core.id] ?? 3;

    return Scaffold(
      backgroundColor: MM.pageBg,
      body: Stack(
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          SafeArea(
            child: Column(
              children: [
                _Header(idx: _idx, total: cores.length, onClose: widget.onClose),
                _Progress(cores: cores, idx: _idx),
                Expanded(
                  child: core.locked
                      ? _LockedView(
                          core: core,
                          onSkip: _advance,
                          onReturnToPhase1: () =>
                              widget.onReturnToPhase1(null),
                        )
                      : _ActiveView(
                          core: core,
                          score: score,
                          onScore: (v) =>
                              setState(() => _scores[core.id] = v),
                          log: _logs[core.id] ?? '',
                          onLog: (v) =>
                              setState(() => _logs[core.id] = v),
                          stageDefs: _stageDefs,
                          scoreLabels: _scoreLabels,
                          lowStreak: _consecutiveLow(core.id),
                          flagLabel: _flagLabel(core.id),
                          onFlag: () => _openFlag(core.id),
                          atRisk: widget.atRiskCores.contains(core.id),
                          onCoreAlert: widget.onCoreAlert == null
                              ? null
                              : () => widget.onCoreAlert!(core.id),
                        ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(18, 10, 18, 20),
                  child: Row(
                    children: [
                      if (_idx > 0) ...[
                        Expanded(
                          flex: 1,
                          child: MMGhostButton(
                            label: '← Back',
                            expand: true,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            onPressed: () => setState(() => _idx--),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: 2,
                        child: MMPrimaryButton(
                          label: isLast ? 'Lock In Day' : 'Next Core →',
                          onPressed: _advance,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_flagCoreId != null)
            Positioned.fill(
              child: _MissionControlIntervention(
                habitName: _flagLabel(_flagCoreId!),
                coreColor: core.color,
                last3: _patternBars(_flagCoreId!),
                onClose: _closeFlag,
                onPick: _logExperiment,
                onReturnToPhase1: (stage) => widget.onReturnToPhase1(stage,
                    habitId: _refFor(_flagCoreId!)?.habitId),
              ),
            ),
          if (_expToast != null)
            Positioned(
              left: 14,
              right: 14,
              bottom: 90,
              child: IgnorePointer(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A2E29),
                    borderRadius: BorderRadius.circular(10),
                    border: const Border.fromBorderSide(
                        BorderSide(color: Color(0x8C00A98F))),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 24)
                    ],
                  ),
                  child: Text(_expToast!,
                      textAlign: TextAlign.center,
                      style: MM.body(color: Colors.white, size: 12)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(
      {required this.idx, required this.total, required this.onClose});
  final int idx;
  final int total;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      child: Row(
        children: [
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, size: 18, color: Colors.white),
            ),
          ),
          Expanded(
            child: Center(
              child: Text('Daily Check-in',
                  style: MM.displayX(size: 12, color: Colors.white)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('${idx + 1} / $total',
                style: MM.display(size: 10, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.cores, required this.idx});
  final List<_Core> cores;
  final int idx;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: List.generate(cores.length, (i) {
          final c = cores[i];
          final passed = i <= idx;
          final color = passed
              ? (c.locked ? Colors.white.withOpacity(0.15) : c.color)
              : Colors.white.withOpacity(0.08);
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < cores.length - 1 ? 4 : 0),
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
                boxShadow: i == idx && !c.locked
                    ? [BoxShadow(color: c.color, blurRadius: 6)]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _LockedView extends StatelessWidget {
  const _LockedView({
    required this.core,
    required this.onSkip,
    required this.onReturnToPhase1,
  });
  final _Core core;
  final VoidCallback onSkip;
  final VoidCallback onReturnToPhase1;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, color: MM.yellow, size: 64),
            const SizedBox(height: 16),
            Text(core.name,
                style: MM.displayX(size: 14, color: Colors.white)),
            const SizedBox(height: 10),
            Text(
              'Not yet activated. Return to Phase 1 to ignite this Core.',
              style: MM.body(color: Colors.white.withOpacity(0.55)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            MMGhostButton(
                label: 'Return to Phase 1 →', onPressed: onReturnToPhase1),
            const SizedBox(height: 14),
            TextButton(
              onPressed: onSkip,
              child: Text('Skip Core →',
                  style: MM.display(
                    size: 11,
                    color: Colors.white.withOpacity(0.4),
                    weight: FontWeight.w600,
                    letterSpacing: 11 * 0.16,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveView extends StatelessWidget {
  const _ActiveView({
    required this.core,
    required this.score,
    required this.onScore,
    required this.log,
    required this.onLog,
    required this.stageDefs,
    required this.scoreLabels,
    required this.lowStreak,
    required this.flagLabel,
    required this.onFlag,
    required this.atRisk,
    required this.onCoreAlert,
  });
  final _Core core;
  final int score;
  final ValueChanged<int> onScore;
  final String log;
  final ValueChanged<String> onLog;
  final Map<String, _StageDef> stageDefs;
  final List<String> scoreLabels;

  /// Consecutive most-recent check-ins (incl. today) at or below 3.0.
  final int lowStreak;

  /// Display name of the Core's flagged Golden Habit.
  final String flagLabel;
  final VoidCallback onFlag;

  /// Core out of balance (5+ days below 3.0) → red ⚠️ badge by the Core name.
  final bool atRisk;
  final VoidCallback? onCoreAlert;

  @override
  Widget build(BuildContext context) {
    final isHigh = score >= 4;
    final isLow = score <= 2;
    // Mission Control surfaces only on the REAL pattern (3+ consecutive
    // check-ins ≤ 3.0), not on a single low day.
    final struggling = lowStreak >= 3;
    final flagName = flagLabel;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: core.color,
                boxShadow: [BoxShadow(color: core.color, blurRadius: 12)],
              ),
            ),
            const SizedBox(width: 10),
            Text(core.name,
                style: MM.displayX(size: 12, color: core.color)),
            const Spacer(),
            // Core Balance 5-day alert — red ⚠️ badge, tappable → iCore Alert.
            if (atRisk)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onCoreAlert,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: MM.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: MM.red.withOpacity(0.6)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('⚠️', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Text('AT RISK',
                        style: MM.display(
                            size: 9,
                            color: MM.red,
                            weight: FontWeight.w700,
                            letterSpacing: 9 * 0.1)),
                  ]),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          // Mission Control flag alert (amber, supportive — never red)
          if (struggling) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: MM.yellow.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: MM.yellow.withOpacity(0.4)),
              ),
              child: Row(children: [
                const Text('⚠',
                    style: TextStyle(color: MM.yellow, fontSize: 14)),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: MM.body(color: Colors.white, size: 11.5),
                      children: [
                        const TextSpan(text: 'Pattern detected on '),
                        TextSpan(
                            text: flagName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                        TextSpan(
                            text: ' — $lowStreak check-ins at or below 3.0.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onFlag,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: MM.yellow,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('RESOLVE',
                        style: MM.display(
                            size: 10,
                            color: const Color(0xFF1A1400),
                            weight: FontWeight.w700,
                            letterSpacing: 10 * 0.08)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
          ],
          // BTTF Vision
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [core.color.withOpacity(0.1), Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border(left: BorderSide(color: core.color, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BTTF VISION',
                    style: MM.displayX(
                        size: 8, color: Colors.white.withOpacity(0.45))),
                const SizedBox(height: 4),
                Text('"${core.vision}"',
                    style: MM
                        .body(color: Colors.white, size: 13)
                        .copyWith(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...core.habits.map((h) {
            final s = stageDefs[h.stage]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              // Uniform border only + a clipped left-accent stripe: a non-uniform
              // Border (thicker left side) combined with borderRadius paints the
              // whole card blank (see project_habits_card_blank).
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: IntrinsicHeight(
                  child: Row(children: [
                    Container(width: 3, color: core.color),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: s.color,
                              boxShadow: [
                                BoxShadow(color: s.color, blurRadius: 6)
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h.name,
                                    style: MM.body(
                                        color: Colors.white,
                                        weight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text(
                                  '${h.kind.toUpperCase()} · ${s.label.toUpperCase()}',
                                  style: MM.display(
                                    size: 9,
                                    color: Colors.white.withOpacity(0.45),
                                    weight: FontWeight.w600,
                                    letterSpacing: 9 * 0.12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onFlag,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(Icons.outlined_flag,
                                  size: 16,
                                  color: MM.yellow.withOpacity(0.7)),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          // Score header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('TODAY\'S SCORE',
                  style: MM.displayX(
                      size: 10, color: Colors.white.withOpacity(0.55))),
              Text(
                '$score',
                style: MM.display(
                  size: 56,
                  color: isHigh
                      ? core.color
                      : (isLow ? MM.yellow : Colors.white),
                  weight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: core.color,
              inactiveTrackColor: Colors.white.withOpacity(0.1),
              thumbColor: Colors.white,
              overlayColor: core.color.withOpacity(0.2),
              valueIndicatorColor: core.color,
              trackHeight: 6,
            ),
            child: Slider(
              value: score.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: '$score',
              onChanged: (v) => onScore(v.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (i) {
                final n = i + 1;
                final on = n == score;
                return SizedBox(
                  width: 20,
                  child: Text(
                    '$n',
                    textAlign: TextAlign.center,
                    style: MM.display(
                      size: 11,
                      color: on
                          ? Colors.white
                          : Colors.white.withOpacity(0.35),
                      weight: on ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isHigh
                  ? core.color.withOpacity(0.1)
                  : Colors.white.withOpacity(0.05),
              border: Border.all(
                color: isHigh
                    ? core.color.withOpacity(0.33)
                    : Colors.white.withOpacity(0.1),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              scoreLabels[score],
              textAlign: TextAlign.center,
              style: MM.body(
                color: isHigh ? Colors.white : Colors.white.withOpacity(0.7),
                size: 12,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("CAPTAIN'S LOG",
                  style: MM.displayX(
                      size: 10, color: Colors.white.withOpacity(0.55))),
              if (log.isNotEmpty)
                Text('✓ Logged',
                    style: MM.display(
                        size: 10, color: MM.teal, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: TextEditingController(text: log)
              ..selection =
                  TextSelection.collapsed(offset: log.length),
            onChanged: onLog,
            maxLines: 3,
            style: MM.body(color: Colors.white),
            decoration: InputDecoration(
              hintText: "What's the data? (optional)",
              hintStyle: MM.body(color: Colors.white.withOpacity(0.4)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.04),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: log.isNotEmpty
                      ? core.color.withOpacity(0.33)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: log.isNotEmpty
                      ? core.color.withOpacity(0.33)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: core.color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Core {
  const _Core(this.id, this.name, this.color, this.vision, this.habits,
      {this.locked = false});
  final String id;
  final String name;
  final Color color;
  final String vision;
  final List<_Habit> habits;
  final bool locked;
}

class _Habit {
  const _Habit(this.name, this.stage, this.kind);
  final String name;
  final String stage;
  final String kind;
}

class _StageDef {
  const _StageDef(this.color, this.label);
  final Color color;
  final String label;
}

/// Full-screen Mission Control intervention (amber, never red). Surfaces a
/// detected struggle pattern and offers refinement paths — no "recommended"
/// option, by design.
class _MissionControlIntervention extends StatefulWidget {
  const _MissionControlIntervention({
    required this.habitName,
    required this.coreColor,
    required this.last3,
    required this.onClose,
    required this.onPick,
    required this.onReturnToPhase1,
  });
  final String habitName;
  final Color coreColor;

  /// The Core's last up-to-3 check-in scores, oldest-first (D-2 … D0) — the
  /// real data behind the Pattern Detected chart.
  final List<double> last3;
  final VoidCallback onClose;
  final void Function(String tag) onPick;
  final void Function(String? stage) onReturnToPhase1;

  @override
  State<_MissionControlIntervention> createState() =>
      _MissionControlInterventionState();
}

class _MissionControlInterventionState
    extends State<_MissionControlIntervention> {
  String _view = 'paths'; // 'paths' | 'deeper'
  static const _amber = MM.yellow;

  void _pickPath(String id) {
    switch (id) {
      case 'deeper':
        setState(() => _view = 'deeper');
        break;
      case 'manual':
        widget.onPick('Manual edit');
        break;
      default:
        widget.onPick('Quick tweak');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xEB06070D),
      padding: const EdgeInsets.fromLTRB(14, 56, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onClose,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: MM.navy.withOpacity(0.55),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Text('⚠ MISSION CONTROL · NOVA',
                style: MM.displayX(size: 12, color: _amber)),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _patternCard(),
                  const SizedBox(height: 12),
                  if (_view == 'paths') ..._pathsView() else ..._deeperView(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _patternCard() {
    // Real recent scores (oldest-first); fall back to today's value alone.
    final bars = widget.last3.isNotEmpty ? widget.last3 : const <double>[3.0];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_amber.withOpacity(0.12), Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: _amber, width: 3),
          top: BorderSide(color: _amber.withOpacity(0.4)),
          right: BorderSide(color: _amber.withOpacity(0.4)),
          bottom: BorderSide(color: _amber.withOpacity(0.4)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PATTERN DETECTED',
              style: MM.displayX(size: 9, color: _amber)),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(bars.length, (i) {
                final s = bars[i];
                final back = bars.length - 1 - i; // 0 = today (D0)
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: i == 0 ? 0 : 4,
                        right: i == bars.length - 1 ? 0 : 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(s.toStringAsFixed(1),
                            style: MM.display(size: 11, color: _amber)),
                        const SizedBox(height: 4),
                        Container(
                          height: (s / 5) * 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [_amber, _amber.withOpacity(0.47)],
                            ),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                            boxShadow: [
                              BoxShadow(
                                  color: _amber.withOpacity(0.33),
                                  blurRadius: 8)
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(back == 0 ? 'D0' : 'D-$back',
                            style: MM.displayX(
                                size: 9,
                                color: Colors.white.withOpacity(0.5))),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: MM.body(color: Colors.white, size: 12),
              children: [
                TextSpan(
                    text: '${bars.length} consecutive check-ins at or '
                        'below 3.0 on '),
                TextSpan(
                    text: widget.habitName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const TextSpan(text: '.'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "That's not failure — that's your habit telling you something needs adjusting.",
            style: MM
                .body(color: Colors.white.withOpacity(0.85), size: 12)
                .copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  List<Widget> _pathsView() {
    const paths = [
      [
        'quick',
        '⚡',
        'Quick Suggestion',
        'UNDER 2 MIN',
        'Nova spots the cue/friction issue and proposes one targeted tweak.',
        'Logs as a 🧪 3-day Experiment.'
      ],
      [
        'deeper',
        '🔬',
        'Go Deeper',
        '5-8 MIN',
        'Step back into Phase 1 to rebuild the habit or its strategies.',
        'Pre-loads everything you already told Nova.'
      ],
      [
        'manual',
        '✏️',
        'Manual Edit',
        'YOUR CALL',
        'Full control. Adjust the habit yourself.',
        'Logs as a 🧪 Experiment with date stamp.'
      ],
    ];
    return [
      Text('CHOOSE YOUR PATH · NO RECOMMENDED OPTION',
          style: MM.displayX(size: 9, color: Colors.white.withOpacity(0.55))),
      const SizedBox(height: 8),
      ...paths.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _pickPath(p[0]),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: MM.navy.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p[1], style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                child: Text(p[2],
                                    style: MM.display(
                                        size: 14, color: Colors.white)),
                              ),
                              const SizedBox(width: 8),
                              Text(p[3],
                                  style: MM.displayX(
                                      size: 9,
                                      color: Colors.white.withOpacity(0.5))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(p[4],
                              style: MM.body(
                                  color: Colors.white.withOpacity(0.75),
                                  size: 12)),
                          const SizedBox(height: 6),
                          Text(p[5],
                              style: MM.body(size: 11, color: MM.yellow)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
    ];
  }

  List<Widget> _deeperView() {
    final subPaths = [
      [
        'A',
        'Rebuild This Habit',
        'Is this even the right habit?',
        'Return to HHS (Phase 1, Stage 1). Re-check Want / Can / Effective.',
        widget.coreColor,
      ],
      [
        'B',
        'Better MBM Strategies',
        'How do I make it easier?',
        'Return to MBS (Phase 1, Stage 2). Swap cues, friction reducers, rewards.',
        MM.blue,
      ],
    ];
    return [
      MMGhostButton(
        label: '← Back to paths',
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        onPressed: () => setState(() => _view = 'paths'),
      ),
      const SizedBox(height: 10),
      Text('GO DEEPER · PICK A REBUILD PATH',
          style: MM.displayX(size: 9, color: Colors.white.withOpacity(0.55))),
      const SizedBox(height: 8),
      ...subPaths.map((s) {
        final id = s[0] as String;
        final name = s[1] as String;
        final hint = s[2] as String;
        final desc = s[3] as String;
        final color = s[4] as Color;
        // Path A → Stage 1 (HHS) habit rebuild · Path B → Stage 2 (MBS) MBMs.
        final stage = id == 'A' ? 'hhs' : 'mbs';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onReturnToPhase1(stage),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: MM.navy.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.33)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PATH $id',
                      style: MM.displayX(size: 10, color: color)),
                  const SizedBox(height: 4),
                  Text(name, style: MM.display(size: 15, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(hint,
                      style: MM
                          .body(color: color, size: 11)
                          .copyWith(fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  Text(desc,
                      style: MM.body(
                          color: Colors.white.withOpacity(0.7), size: 12)),
                ],
              ),
            ),
          ),
        );
      }),
    ];
  }
}
