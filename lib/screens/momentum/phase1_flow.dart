import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/momentum_list.dart';
import '../../models/phase1_state.dart';
import '../../models/golden_habit.dart';
import '../../services/all_habits.dart' show AllHabit, mergeAllHabits;
import '../../services/habits_service.dart';
import '../../services/chat_service.dart';
import '../../services/core_lists_service.dart';
import '../../services/momentum_lists_service.dart';
import '../../theme/momentum_tokens.dart';
import '../../widgets/momentum/confetti_overlay.dart';
import '../../widgets/momentum/glass_panel.dart';
import '../../widgets/momentum/hhs_pyramid.dart';
import '../../widgets/momentum/mm_buttons.dart';
import '../../widgets/momentum/starfield.dart';
import '../../widgets/momentum/mbm_shortcut.dart';
import '../../widgets/momentum/refinement_summary.dart';
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
    this.onStartCheckin,
    this.entryStage,
    this.entryHabitId,
    this.entryDraft,
  });

  final Phase1State state;
  final void Function(Phase1State next) onStateChange;
  final VoidCallback onBack;
  final VoidCallback onExitToCockpit;

  /// Starts today's check-in — the post-refinement flow delivers it "right
  /// now in the same session" (#23 step 3). Null falls back to the Cockpit.
  final VoidCallback? onStartCheckin;

  /// Phase 1 Re-Entry Bridge target (PHASE 1 & 2 DETAILS §4C). `null` lands on
  /// the hub; `'hhs'` deep-links into Stage 1 (rebuild a Golden Habit); `'mbs'`
  /// deep-links into Stage 2 (re-engineer the MBMs). Read once in initState.
  final String? entryStage;

  /// Golden Habit id to pre-load when re-entering via "Go Deeper" (#7) — Stage 2
  /// momentifies this specific flagged habit instead of the newest.
  final String? entryHabitId;

  /// Pre-filled (unsent) opener for the HHS chat — "Fuel this Core" (#20)
  /// names the locked Core the player tapped.
  final String? entryDraft;

  @override
  State<Phase1Flow> createState() => _Phase1FlowState();
}

class _Phase1FlowState extends State<Phase1Flow> {
  late String _view; // hub | section | new-habit | command-center | mbs

  /// Returning / Go Deeper session to start when the chat opens (P1-2); null
  /// with a returning player = resume their unfinished session.
  ({String mode, String? habitId})? _start;

  /// The session the chat is showing (null = first-time conversation).
  HhsSession? _session;

  /// Stage 2 (MBS) runs as its own Nova session (P1-5).
  HhsSession? _mbsSession;

  /// The habit a Go Deeper session just refined, and how (#23 step 3).
  String? _refinedHabitId;
  bool _refinedRebuilt = true;

  /// Has forged a Golden Habit before — new habits use returning sessions.
  bool get _returning => widget.state.stage1Completed;

  /// The "Fuel this Core" opener, used by the first chat only — it leaked into
  /// later sessions' inputs (P1-10 #6).
  late String? _draft = widget.entryDraft;

  @override
  void initState() {
    super.initState();
    switch (widget.entryStage) {
      case 'mbs':
        // Path B — re-engineer the MBMs straight in Stage 2.
        _view = 'mbs';
        break;
      case 'hhs':
        final id = widget.entryHabitId;
        if (id != null && id.isNotEmpty) {
          // Go Deeper / Need Help → rebuild this habit in its own session.
          _start = (mode: 'go_deeper', habitId: id);
          _view = 'section';
        } else {
          // A returning player picks how to find the next habit first.
          _view = _returning ? 'new-habit' : 'section';
        }
        break;
      default:
        _view = widget.state.lastView ?? 'hub';
    }
  }

  /// Switches screen and saves it as the resume point (#26 / P1-1). [base]
  /// carries a state change made in the same tap, since [widget.state] only
  /// updates on the next build.
  void _go(String view, {Phase1State? base}) {
    setState(() {
      if (_view == 'section' && view != 'section') _draft = null;
      _view = view;
    });
    final from = base ?? widget.state;
    if (base != null || from.lastView != view) {
      widget.onStateChange(from.copyWith(lastView: view));
    }
  }

  /// A returning player starts a new Golden Habit from the chooser; a
  /// first-timer goes straight into their HHS.
  void _startStage1() => _returning ? _go('new-habit') : _go('section');

  void _startReturning(String mode) {
    _start = (mode: mode, habitId: null);
    _session = null;
    _go('section');
  }

  /// Live HHS progress from the Claude agent (0–5 sections complete).
  /// Never regress — a returning player keeps the higher progress they banked.
  void _onHhsProgress(int completed) {
    if (completed > widget.state.stage1Progress) {
      widget.onStateChange(widget.state.copyWith(stage1Progress: completed));
    }
  }

  /// Golden Habit forged + locked in → Stage 1 complete, unlock Command Center.
  void _onHhsComplete() {
    final done = widget.state.copyWith(
      stage1Progress: 5,
      stage1Completed: true,
    );
    final session = _session;
    _start = null;
    _session = null;
    if (session == null) {
      // First-time: the Command Center unlock is the Stage 1 reward.
      _go('command-center', base: done);
    } else if (session.isGoDeeper) {
      // Rebuilt in place → what changed + its 🧪 experiment, then check-in.
      _refinedHabitId = session.habitId;
      _refinedRebuilt = true;
      _go('refined', base: done);
    } else {
      // Returning: Nova already summarised the progress (no unlock reveal).
      // The MBM Shortcut offers Full MBS / Ideas Well / manual entry (P1-6).
      _go('mbm-shortcut', base: done);
    }
  }

  void _startStage2() => _go('mbs');

  /// Nova finished Level 2. A first-timer gets the Space Cantina unlock (the
  /// Phase 1 culmination); a returning player already has it, so back to the
  /// hub — the new habit is ready for daily tracking.
  void _onMbsComplete() {
    final session = _mbsSession;
    _mbsSession = null;
    final pathB = widget.entryStage == 'mbs' &&
        (widget.entryHabitId ?? '').isNotEmpty;
    if (widget.state.stage2Completed && pathB) {
      // Go Deeper Path B (better MBMs for an existing habit).
      _refinedHabitId =
          (session?.habitId ?? '').isNotEmpty ? session!.habitId : widget.entryHabitId;
      _refinedRebuilt = false;
      _go('refined');
    } else if (widget.state.stage2Completed) {
      _go('hub');
    } else {
      _go('cantina');
    }
  }

  void _completeStage2() {
    widget.onStateChange(
      widget.state.copyWith(
        stage1Completed: true,
        stage1Progress: 5,
        stage2Completed: true,
        // Phase 1 is done: a later visit opens on the hub, not mid-flow.
        lastView: 'hub',
      ),
    );
    widget.onExitToCockpit();
  }

  @override
  Widget build(BuildContext context) {
    switch (_view) {
      case 'section':
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        if (!_returning && _start == null) {
          return HhsChatView(
            userId: uid,
            initialDraft: _draft,
            onProgress: _onHhsProgress,
            onComplete: _onHhsComplete,
            onBack: () => _go('hub'),
          );
        }
        final session = _session;
        if (session != null) {
          return HhsChatView(
            key: ValueKey(session.id),
            userId: uid,
            sessionId: session.id,
            title: session.isGoDeeper ? 'Rebuild your Golden Habit' : null,
            lockInLabel:
                session.isGoDeeper
                    ? 'Lock it in 🔒 Save my rebuild'
                    : 'Lock it in 🔒 Make it automatic',
            initialDraft: _draft,
            onProgress: _onHhsProgress,
            onComplete: _onHhsComplete,
            onBack: () => _go('hub'),
          );
        }
        return _HhsSessionGate(
          userId: uid,
          start: _start,
          onSession: (s) => setState(() => _session = s),
          onNone: () => _go('new-habit'),
          onBack: () => _go('hub'),
        );
      case 'new-habit':
        return _NewHabitChooser(
          onPick: _startReturning,
          onBack: () => _go('hub'),
        );
      case 'command-center':
        return _CommandCenterUnlockView(
          onContinue: () => _go('mbs'),
          // Stage 1 is already saved — "Save game" just steps back out.
          onSave: widget.onExitToCockpit,
        );
      case 'mbs':
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        final mbs = _mbsSession;
        if (mbs != null) {
          return HhsChatView(
            key: ValueKey(mbs.id),
            userId: uid,
            sessionId: mbs.id,
            stage2: true,
            onProgress: (_) {},
            onComplete: _onMbsComplete,
            onBack: () => _go('hub'),
          );
        }
        return _HhsSessionGate(
          userId: uid,
          start: (
            mode: widget.state.stage2Completed ? 'mbs_returning' : 'mbs_first',
            habitId: widget.entryHabitId,
          ),
          onSession: (s) => setState(() => _mbsSession = s),
          onNone: () => _go('hub'),
          onBack: () => _go('hub'),
        );
      case 'cantina':
        return _CantinaUnlockView(onEnter: _completeStage2);
      case 'mbm-shortcut':
        return _ShortcutScaffold(
          child: MbmShortcutChooser(
            onFull: () => _go('mbs'),
            onIdeas: () => _go('mbm-ideas'),
            onManual: () => _go('mbm-manual'),
            onLater: () => _go('hub'),
          ),
        );
      case 'mbm-ideas':
      case 'mbm-manual':
        return _ShortcutScaffold(
          child: MbmAttachView(
            key: ValueKey(_view),
            fromIdeas: _view == 'mbm-ideas',
            onDone: () => _go('hub'),
            onBack: () => _go('mbm-shortcut'),
          ),
        );
      case 'refined':
        final id = _refinedHabitId;
        if (id == null || id.isEmpty) continue hub;
        return RefinementSummaryView(
          habitId: id,
          rebuilt: _refinedRebuilt,
          onCheckin: widget.onStartCheckin ?? widget.onExitToCockpit,
          onCockpit: widget.onExitToCockpit,
        );
      hub:
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
/// Resolves which returning / Go Deeper session the chat shows (P1-2):
/// starts [start] (resuming an unfinished one of the same kind), or with no
/// [start] resumes the player's unfinished session — [onNone] if there is
/// none. Starting runs Nova's opening recap, so it can take a few seconds.
class _HhsSessionGate extends StatefulWidget {
  const _HhsSessionGate({
    required this.userId,
    required this.start,
    required this.onSession,
    required this.onNone,
    required this.onBack,
  });

  final String userId;
  final ({String mode, String? habitId})? start;
  final ValueChanged<HhsSession> onSession;
  final VoidCallback onNone;
  final VoidCallback onBack;

  @override
  State<_HhsSessionGate> createState() => _HhsSessionGateState();
}

class _HhsSessionGateState extends State<_HhsSessionGate> {
  final _chat = ChatService();
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void dispose() {
    _chat.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    setState(() => _error = null);
    try {
      final start = widget.start;
      final session =
          start == null
              ? await _chat.currentSession(widget.userId)
              : await _chat.startSession(
                widget.userId,
                mode: start.mode,
                habitId: start.habitId,
              );
      if (!mounted) return;
      if (session == null) {
        widget.onNone();
      } else {
        widget.onSession(session);
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final rebuilding = widget.start?.mode == 'go_deeper';
    final level2 = widget.start?.mode.startsWith('mbs') ?? false;
    return _PhaseScaffold(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error == null) ...[
                  const CircularProgressIndicator(color: MM.blue),
                  const SizedBox(height: 16),
                  Text(
                    rebuilding
                        ? 'Nova is loading everything about this habit…'
                        : level2
                        ? 'Nova is preparing Level 2…'
                        : 'Nova is reviewing your habits and lists…',
                    textAlign: TextAlign.center,
                    style: MM.body(
                      color: Colors.white.withOpacity(0.8),
                      size: 13,
                    ),
                  ),
                ] else ...[
                  Text(
                    "Couldn't reach Nova",
                    style: MM.display(size: 15, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  MMGhostButton(label: 'Try again', onPressed: _resolve),
                  const SizedBox(height: 8),
                  MMGhostButton(label: 'Back', onPressed: widget.onBack),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Returning player, new Golden Habit (Phase 1&2 Sequence "RETURNING
/// PLAYERS"): voluntary discovery vs guided ("I know my pain point").
class _NewHabitChooser extends StatelessWidget {
  const _NewHabitChooser({required this.onPick, required this.onBack});

  final ValueChanged<String> onPick;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    Widget option(String emoji, String title, String body, String mode) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onPick(mode),
            child: GlassPanel(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: MM.body(
                            color: Colors.white,
                            size: 14,
                            weight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: MM.body(
                            color: Colors.white.withOpacity(0.65),
                            size: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white54),
                ],
              ),
            ),
          ),
        );

    return _PhaseScaffold(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _BackChip(onPressed: onBack),
                ),
                const SizedBox(height: 14),
                Text(
                  'NEW GOLDEN HABIT',
                  style: MM.displayX(size: 11, color: MM.yellow),
                ),
                const SizedBox(height: 6),
                Text(
                  'Welcome back, Captain. How do you want to start?',
                  style: MM.display(size: 18, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'Nova already knows your habits and Momentum Lists — no tutorial this time.',
                  style: MM.body(
                    color: Colors.white.withOpacity(0.6),
                    size: 12,
                  ),
                ),
                const SizedBox(height: 18),
                option(
                  '🧭',
                  'Help me find my next pain point',
                  "Nova recaps where you are and guides you to what's holding you back next.",
                  'returning_voluntary',
                ),
                option(
                  '🎯',
                  'I know my pain point',
                  'Name it and the Core — the full Habits Hierarchy, checkpoints and Momentum Points included.',
                  'returning_guided',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhaseScaffold extends StatelessWidget {
  const _PhaseScaffold({required this.child, this.celebrate = false});
  final Widget child;

  /// Fire a confetti burst over the page (unlock/award screens).
  final bool celebrate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MM.pageBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          SafeArea(child: SingleChildScrollView(child: child)),
          if (celebrate)
            const Positioned.fill(
              child: ConfettiOverlay(
                count: 120,
                origin: Alignment(0, -0.55),
                duration: Duration(milliseconds: 3000),
              ),
            ),
        ],
      ),
    );
  }
}

/// Centred, width-capped page for the MBM Shortcut screens (P1-6).
class _ShortcutScaffold extends StatelessWidget {
  const _ShortcutScaffold({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => _PhaseScaffold(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    ),
  );
}

// ─── Back-button (rounded chip) ──────────────────────────────────────────
class _BackChip extends StatelessWidget {
  const _BackChip({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: MM.navy.withOpacity(0.55),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          size: 14,
          color: Colors.white,
        ),
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
            Text(
              'PHASE 1 · FOUNDATION',
              style: MM.displayX(size: 11, color: MM.yellow),
            ),
            const SizedBox(height: 4),
            Text(
              'Character Build',
              style: MM.display(size: 24, color: Colors.white),
            ),
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
                  size: 10,
                  color: Colors.white.withOpacity(0.5),
                ),
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
                  Text(
                    'STAGE 1 · HHS',
                    style: MM.displayX(size: 10, color: MM.yellow),
                  ),
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
                Text(
                  '✓ COMPLETE',
                  style: MM.displayX(size: 11, color: MM.teal),
                ),
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
                // Gamification spec Phase Activation: "Ready Player One?"
                // and "Continue Game 🎮?" CTAs.
                label:
                    progress > 0 ? 'Continue Game 🎮' : 'Ready Player One? →',
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
    final accent =
        stage2Done
            ? MM.teal
            : unlocked
            ? MM.magenta
            : Colors.white.withOpacity(0.18);
    final gradient =
        unlocked
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
                    Text(
                      'STAGE 2 · MBS',
                      style: MM.displayX(
                        size: 10,
                        color:
                            unlocked
                                ? MM.magenta
                                : Colors.white.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '3 Momentum Methods',
                      style: MM.body(
                        size: 15,
                        color: Colors.white,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (stage2Done)
                  Text(
                    '✓ COMPLETE',
                    style: MM.displayX(size: 11, color: MM.teal),
                  )
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
                  Expanded(
                    child: _MbmMiniCard(mbm: _mbms[i], active: stage2Done),
                  ),
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
        color:
            active
                ? mbm.color.withOpacity(0.13)
                : Colors.white.withOpacity(0.04),
        border: Border.all(
          color:
              active
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

// ─── 3. Command Center Unlock (Sequence Section/Step 6) ─────────────────
// Three beats, per the Phase 1&2 Sequence doc: REWARD ACTIVATED intro →
// MOMENTUM LISTS ACTIVATED (each list's description plus the data the
// player's own answers stored) → lift-off bridge to Level 2.

/// Emoji per list, from the doc's list descriptions (§4B).
const Map<String, String> _listEmoji = {
  'Back to the Future': '🚀🔮',
  'Mantra': '🕉️',
  'Gratitude': '🙏✨',
  'Strengths': '🛠️💪',
  'Weaknesses': '😔📈',
  'Passions': '🎮🕺',
  'Dislikes': '👎🚫',
  'Routines': '⏰🔄',
  'Non-Routines': '⏰❌',
  'Top People': '🧑‍🧑‍🧒‍🧒',
  'Top Environments': '📍',
  'Top Irrational Fears': '❓😱',
  'Daily Bold Tracker': '👊📆',
  'Obstacles': '🛑',
  'Messes to Clean': '🧹🗑️',
  'Captain\'s Log': '👨‍✈️📓',
  'One-Time Actions': '⚡♾️',
  'Fav Tech Automations': '📱♾️',
  'Career Goals': '💼🎯',
  'Lifestyle Factors': '🏠',
  'Trophy Room': '🏆',
};

/// One list in the reveal: what it is + what Stage 1 stored in it.
class _RevealList {
  const _RevealList(this.name, this.desc, this.data, {this.note});
  final String name;
  final String desc;
  final List<String> data;

  /// Shown instead of data when nothing was stored (doc: "N/A for current
  /// Non-Routine Golden Habit").
  final String? note;
}

class _CommandCenterUnlockView extends StatefulWidget {
  const _CommandCenterUnlockView({
    required this.onContinue,
    required this.onSave,
  });
  final VoidCallback onContinue;
  final VoidCallback onSave;

  @override
  State<_CommandCenterUnlockView> createState() =>
      _CommandCenterUnlockViewState();
}

class _CommandCenterUnlockViewState extends State<_CommandCenterUnlockView> {
  int _step = 0; // 0 intro · 1 lists · 2 lift-off
  List<_RevealList>? _lists;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// What the player's Stage 1 answers stored, per list, in doc order. The
  /// habit lists (Routines / Non-Routines) come from the per-core path; a
  /// failure just means fewer rows — nothing is invented.
  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    var momentum = const <MomentumList>[];
    RoutineData? habits;
    if (uid.isNotEmpty) {
      final lists = MomentumListsService();
      final core = CoreListsService();
      try {
        final results = await Future.wait([
          lists
              .getAllLists(uid)
              .then<Object?>((f) => f.data)
              .timeout(const Duration(seconds: 8))
              .catchError((_) => null),
          core
              .getRoutineData(uid)
              .then<Object?>((f) => f.data)
              .timeout(const Duration(seconds: 8))
              .catchError((_) => null),
        ]);
        if (results[0] is List<MomentumList>) {
          momentum = results[0] as List<MomentumList>;
        }
        if (results[1] is RoutineData) habits = results[1] as RoutineData;
      } finally {
        lists.dispose();
        core.dispose();
      }
    }
    // Same merge as the console / Routines / Non-Routines screens, so a
    // Golden Habit with no list line still counts.
    var golden = const <GoldenHabit>[];
    try {
      final hs = HabitsService();
      try {
        golden = (await hs.getGoldenHabits(uid).timeout(
          const Duration(seconds: 8),
        )).data;
      } finally {
        hs.dispose();
      }
    } catch (_) {}
    final all =
        habits == null && golden.isEmpty
            ? const <AllHabit>[]
            : mergeAllHabits(
              golden: golden,
              routineLists: habits?.routine ?? const [],
              nonRoutineLists: habits?.nonRoutine ?? const [],
              coreScores: const {},
            );
    final routines = [for (final h in all) if (h.isRoutine) h.name];
    final nonRoutines = [for (final h in all) if (!h.isRoutine) h.name];
    final showHabits = routines.isNotEmpty || nonRoutines.isNotEmpty;

    final out = <_RevealList>[];
    for (final s in kMomentumListSpecs) {
      if (s.name == 'Routines' || s.name == 'Non-Routines') {
        if (!showHabits) continue;
        final data = s.name == 'Routines' ? routines : nonRoutines;
        out.add(
          _RevealList(
            s.name,
            s.blurb,
            data,
            note:
                data.isEmpty
                    ? 'N/A for current ${s.name == 'Routines' ? 'Non-Routine' : 'Routine'} Golden Habit'
                    : null,
          ),
        );
        continue;
      }
      if (s.name == 'Trophy Room') continue; // earned later, not in Stage 1
      final items = <String>{
        for (final l in momentum)
          if (momentumListSpecFor(l.name) == s) ...l.items.where((e) => !isArchivedItem(e)).map((e) { final t = parseListItem(e); return t.core == null ? t.label : "${t.core} · ${t.label}"; }),
      }.toList();
      if (items.isNotEmpty) out.add(_RevealList(s.name, s.blurb, items));
    }
    if (mounted) setState(() => _lists = out);
  }

  @override
  Widget build(BuildContext context) {
    return _PhaseScaffold(
      // Stage 1 complete — the Golden Habit is forged and the Lists are live.
      celebrate: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: KeyedSubtree(
            key: ValueKey(_step),
            child: switch (_step) {
              0 => _intro(),
              1 => _listsStep(),
              _ => _liftOff(),
            },
          ),
        ),
      ),
    );
  }

  Widget _novaLine(String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: MM.body(color: Colors.white.withOpacity(0.75), size: 12, height: 1.5),
  );

  Widget _intro() {
    const points = [
      ['📊', 'Stores all insights about you (strengths, obstacles, passions)'],
      ['🔄', 'Updates automatically as you share information'],
      ['🎯', 'Powers AI personalization for future habits'],
      ['📈', 'Evolves with you throughout your entire journey'],
    ];
    return Column(
      children: [
        Text('🥇 REWARD ACTIVATED 🥇', style: MM.displayX(size: 11, color: MM.yellow)),
        const SizedBox(height: 14),
        const Text('🔓', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 8),
        Text(
          'COMMAND CENTER UNLOCKED ✅',
          textAlign: TextAlign.center,
          style: MM.display(size: 20, color: Colors.white),
        ),
        const SizedBox(height: 12),
        _novaLine(
          'Your Command Center is your personal growth database—a living '
          'knowledge base that gets smarter with every interaction.',
        ),
        const SizedBox(height: 10),
        _novaLine('Think of it as your mission control that:'),
        const SizedBox(height: 10),
        for (final p in points)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Text(p[0], style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p[1],
                      style: MM.body(size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        _novaLine('💾 I\'ve now uploaded your intel.'),
        const SizedBox(height: 18),
        MMPrimaryButton(
          label: 'Show my Momentum Lists →',
          pulse: true,
          padding: const EdgeInsets.symmetric(vertical: 14),
          onPressed: () => setState(() => _step = 1),
        ),
      ],
    );
  }

  Widget _listsStep() {
    final lists = _lists;
    return Column(
      children: [
        Text(
          '🚀 📋 MOMENTUM LISTS ACTIVATED ✅',
          textAlign: TextAlign.center,
          style: MM.displayX(size: 11, color: MM.yellow),
        ),
        const SizedBox(height: 12),
        if (lists == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: CircularProgressIndicator(color: MM.blue),
          )
        else if (lists.isEmpty)
          _novaLine(
            'Your lists will fill in as you and Nova keep talking — '
            'nothing has been stored yet.',
          )
        else
          for (var i = 0; i < lists.length; i++)
            _RevealRow(
              index: i,
              emoji: _listEmoji[lists[i].name] ?? '📋',
              name: '${i + 1}. ${lists[i].name}',
              desc: lists[i].desc,
              data: lists[i].data,
              note: lists[i].note,
            ),
        const SizedBox(height: 14),
        _novaLine(
          'As you continue your journey, your Momentum Lists will expand '
          'with once-invisible insights and tools to help you build more '
          'momentum 💡✨🚀.',
        ),
        const SizedBox(height: 18),
        MMPrimaryButton(
          label: 'Continue →',
          pulse: true,
          padding: const EdgeInsets.symmetric(vertical: 14),
          onPressed: () => setState(() => _step = 2),
        ),
      ],
    );
  }

  Widget _liftOff() {
    return Column(
      children: [
        SizedBox(
          height: 230,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 2800),
            curve: Curves.easeInCubic,
            builder:
                (_, t, __) => Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    const Positioned(
                      bottom: 0,
                      child: Text('🌎', style: TextStyle(fontSize: 54)),
                    ),
                    Positioned(
                      bottom: 40 + 160 * t,
                      child: Opacity(
                        opacity: 1 - 0.35 * t,
                        child: Image.asset(
                          'assets/momentum/rocket.png',
                          height: 96 - 28 * t,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
        ),
        const SizedBox(height: 8),
        _novaLine(
          'You\'ve now built enough momentum to break Earth\'s gravitational '
          'pull and achieve lift-off 🌎 🚀.',
        ),
        const SizedBox(height: 8),
        Text(
          'Your epic journey has officially begun 🪐 👾 👽!',
          textAlign: TextAlign.center,
          style: MM.display(size: 16, color: Colors.white),
        ),
        const SizedBox(height: 14),
        _novaLine(
          'Ready to keep your momentum going in LEVEL 2? Science-backed '
          'habit hacks will make your new habit part of who you are.',
        ),
        const SizedBox(height: 18),
        MMPrimaryButton(
          label: 'Continue to Level 2 →',
          pulse: true,
          padding: const EdgeInsets.symmetric(vertical: 14),
          onPressed: widget.onContinue,
        ),
        const SizedBox(height: 8),
        MMGhostButton(
          label: 'Save game · come back later',
          expand: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          onPressed: widget.onSave,
        ),
      ],
    );
  }
}

class _RevealRow extends StatefulWidget {
  const _RevealRow({
    required this.index,
    required this.emoji,
    required this.name,
    required this.desc,
    this.data = const [],
    this.note,
  });
  final int index;
  final String emoji;
  final String name;
  final String desc;

  /// What the player's answers stored in this list (first few shown).
  final List<String> data;
  final String? note;

  @override
  State<_RevealRow> createState() => _RevealRowState();
}

class _RevealRowState extends State<_RevealRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOut,
  );
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  child: Text(
                    widget.emoji,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: MM.body(
                          size: 12,
                          color: Colors.white,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.desc,
                        style: MM.body(
                          color: Colors.white.withOpacity(0.55),
                          size: 10,
                        ),
                      ),
                      if (widget.data.isNotEmpty || widget.note != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          widget.data.isEmpty
                              ? '💾 ${widget.note}'
                              : '💾 ${widget.data.take(4).join(' · ')}'
                                  '${widget.data.length > 4 ? '  +${widget.data.length - 4} more' : ''}',
                          style: MM.body(
                            color: MM.teal.withOpacity(0.9),
                            size: 10.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  '✓',
                  style: MM.display(
                    size: 14,
                    color: MM.teal,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 4. Stage 2 complete: Space Cantina unlock (Sequence Section 5) ─────
// Level 2 itself is a Nova session (mbsSystemPrompt.js, P1-5); the Space
// Cantina unlock is the app's own reward screen, like Stage 1's Command Center.
class _CantinaUnlockView extends StatelessWidget {
  const _CantinaUnlockView({required this.onEnter});
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MM.pageBg,
      body: Stack(
        fit: StackFit.expand,
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
                    Text(
                      'SPACE CANTINA UNLOCKED',
                      style: MM.displayX(size: 11, color: MM.yellow),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Welcome, Captain',
                      style: MM.display(size: 22, color: Colors.white),
                    ),
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
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '✓ MOMENTIFIED HABIT',
                            style: MM.displayX(size: 9, color: MM.teal),
                          ),
                          const SizedBox(height: 6),
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
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🏅 STAGE 2 BADGES · +50 MP',
                            style: MM.displayX(size: 9, color: MM.yellow),
                          ),
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
                      onPressed: onEnter,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Stage 2 banked +50 MP (Friction Hunter / Method Master /
          // Implementation Wizard) and opened the Cantina — the biggest award
          // in Phase 1, so it gets the biggest burst.
          const Positioned.fill(
            child: ConfettiOverlay(
              count: 150,
              origin: Alignment(0, -0.6),
              duration: Duration(milliseconds: 3200),
              startDelay: Duration(milliseconds: 250),
            ),
          ),
        ],
      ),
    );
  }
}
