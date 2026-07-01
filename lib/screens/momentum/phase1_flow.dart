import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/phase1_state.dart';
import '../../services/onboarding_service.dart';
import '../../theme/momentum_tokens.dart';
import '../../widgets/momentum/glass_panel.dart';
import '../../widgets/momentum/hhs_pyramid.dart';
import '../../widgets/momentum/mm_buttons.dart';
import '../../widgets/momentum/starfield.dart';
import 'hhs_chat_view.dart';

// ─── MBM catalogue ───────────────────────────────────────────────────────
class _Mbm {
  const _Mbm(this.id, this.name, this.icon, this.desc, this.color);
  final String id;
  final String name;
  final String icon;
  final String desc;
  final Color color;
}

const _mbms = <_Mbm>[
  _Mbm(
    'obvious',
    'Make It Obvious',
    '🔍',
    'Design environmental cues so the habit is impossible to forget.',
    MM.yellow,
  ),
  _Mbm(
    'easy',
    'Make It Easy',
    '⚡',
    'Shrink the friction so starting takes under 2 minutes.',
    MM.blue,
  ),
  _Mbm(
    'reward',
    'Make It Rewarding',
    '🎉',
    'Layer in dopamine — celebrate every rep, even the small ones.',
    MM.magenta,
  ),
];

// ─── Phase1Flow container ────────────────────────────────────────────────
class Phase1Flow extends StatefulWidget {
  const Phase1Flow({
    super.key,
    required this.state,
    required this.onStateChange,
    required this.onBack,
    required this.onExitToCockpit,
    this.entryStage,
    this.entryHabitId,
  });

  final Phase1State state;
  final void Function(Phase1State next) onStateChange;
  final VoidCallback onBack;
  final VoidCallback onExitToCockpit;

  /// Phase 1 Re-Entry Bridge target (PHASE 1 & 2 DETAILS §4C). `null` lands on
  /// the hub; `'hhs'` deep-links into Stage 1 (rebuild a Golden Habit); `'mbs'`
  /// deep-links into Stage 2 (re-engineer the MBMs). Read once in initState.
  final String? entryStage;

  /// Golden Habit id to pre-load when re-entering via "Go Deeper" (#7) — Stage 2
  /// momentifies this specific flagged habit instead of the newest.
  final String? entryHabitId;

  @override
  State<Phase1Flow> createState() => _Phase1FlowState();
}

class _Phase1FlowState extends State<Phase1Flow> {
  late String _view; // hub | section | command-center | mbs

  @override
  void initState() {
    super.initState();
    switch (widget.entryStage) {
      case 'mbs':
        // Path B — re-engineer the MBMs straight in Stage 2.
        _view = 'mbs';
        break;
      case 'hhs':
        // Path A — rebuild the Golden Habit by re-entering the HHS chat.
        _view = 'section';
        break;
      default:
        _view = widget.state.lastView ?? 'hub';
    }
  }

  void _go(String view) => setState(() => _view = view);

  void _startStage1() => _go('section');

  /// Live HHS progress from the Voiceflow agent (0–5 sections complete).
  /// Never regress — a returning player keeps the higher progress they banked.
  void _onHhsProgress(int completed) {
    if (completed > widget.state.stage1Progress) {
      widget.onStateChange(
          widget.state.copyWith(stage1Progress: completed));
    }
  }

  /// Golden Habit forged + locked in → Stage 1 complete, unlock Command Center.
  void _onHhsComplete() {
    widget.onStateChange(widget.state.copyWith(
      stage1Progress: 5,
      stage1Completed: true,
    ));
    _go('command-center');
  }

  void _startStage2() => _go('mbs');

  void _completeStage2() {
    widget.onStateChange(widget.state.copyWith(
      stage1Completed: true,
      stage1Progress: 5,
      stage2Completed: true,
    ));
    widget.onExitToCockpit();
  }

  @override
  Widget build(BuildContext context) {
    switch (_view) {
      case 'section':
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        return HhsChatView(
          userId: uid,
          onProgress: _onHhsProgress,
          onComplete: _onHhsComplete,
          onBack: () => _go('hub'),
        );
      case 'command-center':
        return _CommandCenterUnlockView(
          onContinue: () => _go('mbs'),
        );
      case 'mbs':
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        return _MBSStage2View(
          userId: uid,
          habitId: widget.entryHabitId,
          onBack: () => _go('hub'),
          onComplete: _completeStage2,
        );
      case 'hub':
      default:
        return _Phase1HubView(
          state: widget.state,
          onBack: widget.onBack,
          onStartStage1: _startStage1,
          onStartStage2: _startStage2,
        );
    }
  }
}

// ─── Reusable: starfield-backed scaffold ─────────────────────────────────
class _PhaseScaffold extends StatelessWidget {
  const _PhaseScaffold({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MM.pageBg,
      body: Stack(
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          SafeArea(
            child: SingleChildScrollView(child: child),
          ),
        ],
      ),
    );
  }
}

// ─── Back-button (rounded chip) ──────────────────────────────────────────
class _BackChip extends StatelessWidget {
  const _BackChip({required this.onPressed, this.size = 36});
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: MM.navy.withOpacity(0.55),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.arrow_back_ios_new,
            size: 14, color: Colors.white),
      ),
    );
  }
}

// ─── 1. Phase 1 Hub ──────────────────────────────────────────────────────
class _Phase1HubView extends StatelessWidget {
  const _Phase1HubView({
    required this.state,
    required this.onBack,
    required this.onStartStage1,
    required this.onStartStage2,
  });

  final Phase1State state;
  final VoidCallback onBack;
  final VoidCallback onStartStage1;
  final VoidCallback onStartStage2;

  @override
  Widget build(BuildContext context) {
    final s1Done = state.stage1Completed;
    final s2Done = state.stage2Completed;
    final s1Progress = state.stage1Progress;
    final completed = List<int>.generate(s1Progress, (i) => i + 1);

    return _PhaseScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BackChip(onPressed: onBack),
            const SizedBox(height: 14),
            Text('PHASE 1 · FOUNDATION',
                style: MM.displayX(size: 11, color: MM.yellow)),
            const SizedBox(height: 4),
            Text('Character Build',
                style: MM.display(size: 24, color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              'Move from vague pain point → personalized Golden Habit, then '
              'engineer it to be impossible to skip. 3–5 minutes for first-time; '
              '1–2 for returning Captains.',
              style: MM.body(
                color: Colors.white.withOpacity(0.65),
                size: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            _Stage1Card(
              done: s1Done,
              progress: s1Progress,
              completed: completed,
              onStart: onStartStage1,
            ),
            const SizedBox(height: 12),
            _Stage2Card(
              stage1Done: s1Done,
              stage2Done: s2Done,
              onStart: onStartStage2,
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'UNLOCKS: COMMAND CENTER · SPACE CANTINA · DAILY COCKPIT',
                style: MM.displayX(
                    size: 10, color: Colors.white.withOpacity(0.5)),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stage1Card extends StatelessWidget {
  const _Stage1Card({
    required this.done,
    required this.progress,
    required this.completed,
    required this.onStart,
  });

  final bool done;
  final int progress;
  final List<int> completed;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final accent = done ? MM.teal : MM.yellow;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [accent.withOpacity(done ? 0.12 : 0.10), Colors.transparent],
    );
    final active = done ? 0 : (progress + 1).clamp(0, 5);

    return GlassPanel(
      leftAccentColor: accent,
      borderRadius: 8,
      background: BoxDecoration(gradient: gradient),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STAGE 1 · HHS',
                      style: MM.displayX(size: 10, color: MM.yellow)),
                  const SizedBox(height: 4),
                  Text(
                    'Habits Hierarchy',
                    style: MM.body(
                      size: 15,
                      color: Colors.white,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (done)
                Text('✓ COMPLETE',
                    style: MM.displayX(size: 11, color: MM.teal)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '5-section AI conversation to surface your top pain point and '
            'forge your first Golden Habit.',
            style: MM.body(
              color: Colors.white.withOpacity(0.7),
              size: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 4),
          HHSPyramid(active: active, completed: completed),
          const SizedBox(height: 8),
          done
              ? MMGhostButton(
                  label: 'Forge another Golden Habit →',
                  expand: true,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: onStart,
                )
              : MMPrimaryButton(
                  label: progress > 0
                      ? 'Continue Stage 1 →'
                      : 'Begin Stage 1 →',
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: onStart,
                ),
        ],
      ),
    );
  }
}

class _Stage2Card extends StatelessWidget {
  const _Stage2Card({
    required this.stage1Done,
    required this.stage2Done,
    required this.onStart,
  });

  final bool stage1Done;
  final bool stage2Done;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final unlocked = stage1Done;
    final accent = stage2Done
        ? MM.teal
        : unlocked
            ? MM.magenta
            : Colors.white.withOpacity(0.18);
    final gradient = unlocked
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [MM.magenta.withOpacity(0.10), Colors.transparent],
          )
        : null;

    return Opacity(
      opacity: unlocked ? 1 : 0.55,
      child: GlassPanel(
        leftAccentColor: accent,
        background: gradient != null ? BoxDecoration(gradient: gradient) : null,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('STAGE 2 · MBS',
                        style: MM.displayX(
                            size: 10,
                            color: unlocked
                                ? MM.magenta
                                : Colors.white.withOpacity(0.4))),
                    const SizedBox(height: 4),
                    Text('3 Momentum Methods',
                        style: MM.body(
                          size: 15,
                          color: Colors.white,
                          weight: FontWeight.w600,
                        )),
                  ],
                ),
                if (stage2Done)
                  Text('✓ COMPLETE',
                      style: MM.displayX(size: 11, color: MM.teal))
                else if (!unlocked)
                  Text('🔒', style: MM.display(size: 18, color: MM.yellow)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Engineer your Golden Habit with Obvious / Easy / Rewarding '
              'strategies, then lock in an IF-THEN obstacle plan.',
              style: MM.body(
                color: Colors.white.withOpacity(0.7),
                size: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < _mbms.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(child: _MbmMiniCard(mbm: _mbms[i], active: stage2Done)),
                ],
              ],
            ),
            const SizedBox(height: 12),
            stage2Done
                ? MMGhostButton(
                    label: 'Refine MBMs →',
                    expand: true,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: unlocked ? onStart : null,
                  )
                : unlocked
                    ? MMPrimaryButton(
                        label: 'Begin Stage 2 →',
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        onPressed: onStart,
                      )
                    : MMGhostButton(
                        label: 'Locked · finish Stage 1 first',
                        expand: true,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        onPressed: null,
                      ),
          ],
        ),
      ),
    );
  }
}

class _MbmMiniCard extends StatelessWidget {
  const _MbmMiniCard({required this.mbm, required this.active});
  final _Mbm mbm;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: active ? mbm.color.withOpacity(0.13) : Colors.white.withOpacity(0.04),
        border: Border.all(
          color: active
              ? mbm.color.withOpacity(0.4)
              : Colors.white.withOpacity(0.1),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(mbm.icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 3),
          Text(
            mbm.name.replaceAll('Make It ', '').toUpperCase(),
            textAlign: TextAlign.center,
            style: MM.displayX(
              size: 7,
              color: active ? Colors.white : Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.from, required this.text});
  final String from;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isMe = from == 'me';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            gradient: isMe
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF3A8DFF), Color(0xFF1F5FB8)],
                  )
                : null,
            color: isMe ? null : MM.navy.withOpacity(0.7),
            border: Border.all(
              color: isMe
                  ? const Color(0xFF4D9BFF).withOpacity(0.5)
                  : MM.violet.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isMe ? 14 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 14),
            ),
          ),
          child: Text(text,
              style: MM.body(color: Colors.white, size: 13, height: 1.45)),
        ),
      ),
    );
  }
}

// ─── 3. Command Center Unlock ────────────────────────────────────────────
class _CommandCenterUnlockView extends StatelessWidget {
  const _CommandCenterUnlockView({required this.onContinue});
  final VoidCallback onContinue;

  static const _lists = [
    ['🚀🔮', 'Back to the Future', 'Aspirational identity across all 5 Cores'],
    ['⏰🔄', 'Routines', 'Daily schedule incl. your new Golden Habit'],
    ['🛑', 'Obstacles', 'Internal & external blockers + IF-THEN fallbacks'],
    ['🎮🕺', 'Passions', 'What energizes and motivates you'],
    ['🛠️💪', 'Strengths', 'Natural talents & adaptive traits'],
    ['📍', 'Top Environments', 'Spaces that shape your focus'],
    ['🏠⏰', 'Lifestyle Factors', 'Real-world constraints'],
  ];

  @override
  Widget build(BuildContext context) {
    return _PhaseScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
        child: Column(
          children: [
            const Text('🔓', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            Text('COMMAND CENTER UNLOCKED',
                style: MM.displayX(size: 11, color: MM.yellow)),
            const SizedBox(height: 4),
            Text('Your Personal Database',
                style: MM.display(size: 22, color: Colors.white)),
            const SizedBox(height: 10),
            Text(
              'Everything you shared has been routed into 7 Momentum Lists. '
              'The AI cross-references these in every future interaction.',
              textAlign: TextAlign.center,
              style: MM.body(
                color: Colors.white.withOpacity(0.7),
                size: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            ..._lists.asMap().entries.map((e) {
              final l = e.value;
              return _RevealRow(
                index: e.key,
                emoji: l[0],
                name: l[1],
                desc: l[2],
              );
            }),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    MM.blue.withOpacity(0.18),
                    MM.violet.withOpacity(0.12),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF4D9BFF).withOpacity(0.4),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text('Level 1 Complete 🚀',
                      style: MM.display(size: 14, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    'Lift-off ready. Continue to Stage 2 to engineer your '
                    'habit for friction-free execution.',
                    textAlign: TextAlign.center,
                    style: MM.body(
                      color: Colors.white.withOpacity(0.7),
                      size: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            MMPrimaryButton(
              label: 'Continue to Stage 2 →',
              pulse: true,
              padding: const EdgeInsets.symmetric(vertical: 14),
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}

class _RevealRow extends StatefulWidget {
  const _RevealRow({
    required this.index,
    required this.emoji,
    required this.name,
    required this.desc,
  });
  final int index;
  final String emoji;
  final String name;
  final String desc;

  @override
  State<_RevealRow> createState() => _RevealRowState();
}

class _RevealRowState extends State<_RevealRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final Animation<double> _opacity =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _offset = Tween(
    begin: const Offset(0, 0.3),
    end: Offset.zero,
  ).animate(_opacity);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 120 * widget.index), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: GlassPanel(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Text(widget.emoji,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.name,
                          style: MM.body(
                            size: 12,
                            color: Colors.white,
                            weight: FontWeight.w600,
                          )),
                      const SizedBox(height: 2),
                      Text(widget.desc,
                          style: MM.body(
                              color: Colors.white.withOpacity(0.55),
                              size: 10)),
                    ],
                  ),
                ),
                Text('✓',
                    style: MM.display(
                      size: 14,
                      color: MM.teal,
                      weight: FontWeight.w700,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 4. MBS Stage 2 ──────────────────────────────────────────────────────
class _MBSStage2View extends StatefulWidget {
  const _MBSStage2View({
    required this.userId,
    required this.onBack,
    required this.onComplete,
    this.habitId,
  });
  final String userId;

  /// When set (Go-Deeper re-entry, #7), momentify this specific flagged habit
  /// instead of the newest forged one.
  final String? habitId;
  final VoidCallback onBack;
  final VoidCallback onComplete;

  @override
  State<_MBSStage2View> createState() => _MBSStage2ViewState();
}

class _MBSStage2ViewState extends State<_MBSStage2View> {
  final _onboarding = OnboardingService();

  int _step = 0; // 0..2 MBMs, 3 = IF-THEN, 4 = complete (Cantina)
  final Map<String, String> _picks = {};

  ActiveHabit? _habit; // the forged Golden Habit we're momentifying
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _onboarding.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // Go-Deeper re-entry targets a specific flagged habit; otherwise momentify
    // the newest forged one.
    final id = widget.habitId;
    final h = (id != null && id.isNotEmpty)
        ? (await _onboarding.habitById(widget.userId, id) ??
            await _onboarding.activeHabit(widget.userId))
        : await _onboarding.activeHabit(widget.userId);
    if (!mounted) return;
    setState(() {
      _habit = h;
      _loading = false;
    });
  }

  String get _habitName => (_habit?.habitName.trim().isNotEmpty ?? false)
      ? _habit!.habitName.trim()
      : 'your Golden Habit';

  // Momentum-Method suggestions are personalized from the forged habit's real
  // fields (when / where / name / obstacle) rather than a hardcoded catalogue.
  // (A richer AI/Momentum-Lists-sourced generator is a future hook — kept
  // deterministic here so Stage 2 references the player's actual habit.)
  List<String> _strategiesFor(String id) {
    final when = (_habit?.when ?? '').trim();
    final where = (_habit?.where ?? '').trim();
    switch (id) {
      case 'obvious':
        return [
          when.isNotEmpty
              ? "Set a daily cue at $when so it's impossible to miss"
              : "Set a daily cue at a fixed time so it's impossible to miss",
          where.isNotEmpty
              ? 'Leave a visible reminder where you $where'
              : 'Leave a visible reminder in plain sight',
          'Stack it right after an existing routine you never skip',
        ];
      case 'easy':
        return [
          'Shrink it to a 2-minute version of "$_habitName"',
          'Prep everything the night before so step one is effortless',
          'Remove the single biggest obstacle that makes it hard to start',
        ];
      case 'reward':
        return [
          'Log it in Momentum for the MP burst + flame growth',
          'Pair it with something you enjoy (temptation bundling)',
          'Celebrate the moment you finish — make it feel like a win',
        ];
      default:
        return const [];
    }
  }

  List<String> get _ifThenOptions {
    final h = _habit;
    final hasPlan =
        (h?.obstacleIf.trim().isNotEmpty ?? false) ||
            (h?.obstacleThen.trim().isNotEmpty ?? false);
    return [
      if (hasPlan)
        'IF ${h!.obstacleIf.trim().isNotEmpty ? h.obstacleIf.trim() : 'life gets in the way'} '
            '→ THEN ${h.obstacleThen.trim().isNotEmpty ? h.obstacleThen.trim() : 'do the 30-second version'}',
      'IF I run out of time → THEN do the 30-second version',
      "IF I'm traveling → THEN do a minimal version wherever I am",
      "IF I'm drained → THEN just complete the first tiny step",
    ];
  }

  /// Persists the picks + IF-THEN onto the Golden Habit and awards the three
  /// Stage-2 badges, then advances to the Cantina unlock. Best-effort: a save
  /// failure still lets the player finish (the award is server-idempotent and
  /// the next save reconciles), matching the Phase 1 persistence philosophy.
  Future<void> _finishMbs() async {
    if (_saving) return;
    setState(() => _saving = true);

    final ifThen = _picks['ifthen'] ?? '';
    final arrow = ifThen.split('→');
    final ifPart = (arrow.isNotEmpty ? arrow[0] : '')
        .replaceFirst(RegExp(r'^\s*IF\s*', caseSensitive: false), '')
        .trim();
    final thenPart = (arrow.length > 1 ? arrow[1] : '')
        .replaceFirst(RegExp(r'^\s*THEN\s*', caseSensitive: false), '')
        .trim();

    await _onboarding.saveMomentumMethods(
      userId: widget.userId,
      habitId: _habit?.habitId,
      makeObvious: _picks['obvious'] ?? '',
      makeEasy: _picks['easy'] ?? '',
      makeRewarding: _picks['reward'] ?? '',
      obstacleIf: ifPart,
      obstacleThen: thenPart,
    );

    if (!mounted) return;
    setState(() {
      _saving = false;
      _step++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: MM.pageBg,
        body: Stack(
          children: [
            Positioned.fill(child: StarfieldBackground()),
            Center(child: CircularProgressIndicator(color: MM.blue)),
          ],
        ),
      );
    }
    if (_step >= _mbms.length + 1) return _buildCantina();
    if (_step == _mbms.length) return _buildIfThen();
    return _buildMbmStep();
  }

  // ----- Cantina unlock -----
  Widget _buildCantina() {
    return Scaffold(
      backgroundColor: MM.pageBg,
      body: Stack(
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('🛸', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 14),
                    Text('SPACE CANTINA UNLOCKED',
                        style: MM.displayX(size: 11, color: MM.yellow)),
                    const SizedBox(height: 6),
                    Text('Welcome, Captain',
                        style: MM.display(size: 22, color: Colors.white)),
                    const SizedBox(height: 10),
                    Text(
                      'Your Golden Habit is now Momentified — engineered for '
                      'friction-free execution. The Space Cantina opens: Ideas '
                      'Well, Tribes, Leaderboards, and Weekly Challenges.',
                      textAlign: TextAlign.center,
                      style: MM.body(
                        color: Colors.white.withOpacity(0.7),
                        size: 12,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GlassPanel(
                      borderColor: MM.teal.withOpacity(0.4),
                      background: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            MM.teal.withOpacity(0.18),
                            Colors.transparent
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('✓ MOMENTIFIED HABIT',
                              style:
                                  MM.displayX(size: 9, color: MM.teal)),
                          const SizedBox(height: 6),
                          Text(_habitName,
                              style:
                                  MM.body(color: Colors.white, size: 12)),
                          const SizedBox(height: 4),
                          Text(
                            '+ Make It Obvious · + Make It Easy · + Make It Rewarding · IF-THEN locked',
                            style: MM.body(
                              color: Colors.white.withOpacity(0.6),
                              size: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassPanel(
                      borderColor: MM.yellow.withOpacity(0.4),
                      background: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            MM.yellow.withOpacity(0.13),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🏅 STAGE 2 BADGES · +50 MP',
                              style: MM.displayX(size: 9, color: MM.yellow)),
                          const SizedBox(height: 6),
                          Text(
                            'Friction Hunter +10 · Method Master +15 · Implementation Wizard +25',
                            style: MM.body(
                              color: Colors.white.withOpacity(0.7),
                              size: 10,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    MMPrimaryButton(
                      label: 'Enter the Cockpit 🚀',
                      pulse: true,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      onPressed: widget.onComplete,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----- IF-THEN step (step == 3) -----
  Widget _buildIfThen() {
    final fallback = _picks['ifthen'];
    return Scaffold(
      backgroundColor: MM.pageBg,
      body: Stack(
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          SafeArea(
            child: Column(
              children: [
                _MbsHeader(
                  stepLabel: 'STAGE 2 · STEP 4/4',
                  title: '⚠️ IF-THEN Obstacle Plan',
                  color: MM.yellow,
                  onBack: () => setState(() => _step--),
                ),
                _MbsTrack(step: _step),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Bubble(
                          from: 'ai',
                          text:
                              "Last step. Pick the most likely obstacle and lock in a 'non-zero' fallback. The IF-THEN is your safety net when life happens.",
                        ),
                        const SizedBox(height: 10),
                        ..._ifThenOptions.map((o) {
                          final isOn = fallback == o;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _RadioRow(
                              label: o,
                              color: MM.yellow,
                              selected: isOn,
                              onTap: () => setState(() => _picks['ifthen'] = o),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.06)),
                    ),
                  ),
                  child: MMPrimaryButton(
                    label: _saving ? 'Momentifying…' : 'Lock it in 🔒',
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: (fallback != null && !_saving) ? _finishMbs : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----- MBM step (0..2) -----
  Widget _buildMbmStep() {
    final mbm = _mbms[_step];
    final picked = _picks[mbm.id];
    final strategies = _strategiesFor(mbm.id);

    return Scaffold(
      backgroundColor: MM.pageBg,
      body: Stack(
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          SafeArea(
            child: Column(
              children: [
                _MbsHeader(
                  stepLabel: 'STAGE 2 · STEP ${_step + 1}/4',
                  title: '${mbm.icon} ${mbm.name}',
                  color: mbm.color,
                  onBack: _step == 0
                      ? widget.onBack
                      : () => setState(() => _step--),
                ),
                _MbsTrack(step: _step),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Bubble(from: 'ai', text: mbm.desc),
                        const SizedBox(height: 8),
                        _Bubble(
                          from: 'ai',
                          text:
                              'For "$_habitName", here are 3 ${mbm.name} strategies. Pick the one that fits your life.',
                        ),
                        const SizedBox(height: 10),
                        ...strategies.map((s) {
                          final isOn = picked == s;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _RadioRow(
                              label: s,
                              color: mbm.color,
                              selected: isOn,
                              onTap: () =>
                                  setState(() => _picks[mbm.id] = s),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.06)),
                    ),
                  ),
                  child: MMPrimaryButton(
                    label: _step == _mbms.length - 1
                        ? 'On to IF-THEN →'
                        : 'Next MBM (${_mbms[_step + 1].name}) →',
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed:
                        picked != null ? () => setState(() => _step++) : null,
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

class _MbsHeader extends StatelessWidget {
  const _MbsHeader({
    required this.stepLabel,
    required this.title,
    required this.color,
    required this.onBack,
  });
  final String stepLabel;
  final String title;
  final Color color;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.08), Colors.transparent],
        ),
        border: Border(
          bottom: BorderSide(color: color.withOpacity(0.2)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Row(
        children: [
          _BackChip(onPressed: onBack, size: 32),
          Expanded(
            child: Column(
              children: [
                Text(stepLabel, style: MM.displayX(size: 9, color: color)),
                const SizedBox(height: 2),
                Text(title, style: MM.display(size: 13, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _MbsTrack extends StatelessWidget {
  const _MbsTrack({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          for (var i = 0; i < _mbms.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: i < step
                      ? _mbms[i].color
                      : i == step
                          ? _mbms[i].color.withOpacity(0.7)
                          : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: i == step
                      ? [BoxShadow(color: _mbms[i].color, blurRadius: 6)]
                      : null,
                ),
              ),
            ),
          ],
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: step > _mbms.length - 1
                    ? MM.yellow
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.18)
              : Colors.white.withOpacity(0.04),
          border: Border.all(
            color: selected ? color : Colors.white.withOpacity(0.12),
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [BoxShadow(color: color.withOpacity(0.33), blurRadius: 14)]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? color : Colors.transparent,
                border: Border.all(
                  color:
                      selected ? color : Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 10, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: MM.body(
                    color: Colors.white,
                    size: 12,
                    height: 1.5,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

