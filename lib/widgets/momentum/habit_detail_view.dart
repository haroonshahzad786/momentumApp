import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/golden_habit.dart';
import '../../services/all_habits.dart' show coreScoreSeries;
import '../../services/checkin_service.dart';
import '../../services/experiments.dart';
import '../../services/formation.dart';
import '../../services/habits_service.dart';
import '../../services/offline.dart';
import '../../services/onboarding_service.dart';
import '../../theme/momentum_tokens.dart';
import 'experiment_card.dart';
import 'formation_room.dart' show FormationCelebration;
import 'glass_panel.dart';
import 'mm_buttons.dart';
import 'offline_banner.dart';
import 'quick_suggestion_sheet.dart';

/// Detailed Golden Habit View (#22) — "the living master document for that
/// habit" (Phase 1 & 2 Details §4A, §4E). Every field the spec lists, in its
/// order, with all editable fields editable in place. Opened from any Golden
/// Habit row via the `habit:<habitId>` nav key, on web and phone.
///
/// Nav keys it emits: `trophy`, `rebuild:hhs:<id>` (Phase 1 Stage 1 Golden
/// Habit rebuild) and `rebuild:mbs:<id>` (Stage 2 MBM adjustment).
class HabitDetailView extends StatefulWidget {
  const HabitDetailView({
    super.key,
    required this.habitId,
    required this.onNav,
    this.wide = false,
  });

  final String habitId;
  final void Function(String key) onNav;

  /// Desktop: two columns (the habit spec | status, MBMs, notes, log).
  final bool wide;

  @override
  State<HabitDetailView> createState() => _HabitDetailViewState();
}

const Map<String, String> _coreTitle = {
  'mindset': 'Mindset',
  'career': 'Career & Finances',
  'relationships': 'Relationships',
  'physical': 'Physical Health',
  'emotional': 'Emotional & Mental',
};

const Map<String, String> _coreIcon = {
  'mindset': '🧠',
  'career': '💰',
  'relationships': '👥',
  'physical': '💪',
  'emotional': '🧘',
};

/// The short version of a habit for the header line (P1-10 #7). Nova stores
/// its whole formatted Golden Habit block in `displayText`, so a multi-line or
/// long value falls back to the WHAT line.
String abbreviatedVersion(GoldenHabit h) {
  final d = h.displayText.trim();
  if (d.isEmpty || d.contains('\n') || d.length > 160) return h.what.trim();
  return d;
}

/// A Captain's Log line for this habit's Core; [mentions] = names the habit.
typedef HabitLogLine =
    ({String date, String wins, String lessons, bool mentions});

/// The Core's Captain's Log entries, newest first, ones that mention the
/// habit by name first. The log is kept per Core (#15), not per habit.
List<HabitLogLine> habitLogLines(
  List<DailyCheckin> checkins,
  String core,
  String habitName,
) {
  final words =
      habitName
          .toLowerCase()
          .split(RegExp(r'[^a-z0-9]+'))
          .where((w) => w.length >= 4)
          .toSet();
  bool mentions(String text) {
    final t = text.toLowerCase();
    return words.isNotEmpty && words.any(t.contains);
  }

  final out = <HabitLogLine>[
    for (final c in checkins)
      if (c.captainsLog[core] case final e? when !e.isEmpty)
        (
          date: c.date,
          wins: e.wins.trim(),
          lessons: e.lessons.trim(),
          mentions: mentions('${e.wins} ${e.lessons}'),
        ),
  ];
  // Stable: mentions first, each group keeps newest-first order.
  return [...out.where((l) => l.mentions), ...out.where((l) => !l.mentions)];
}

class _HabitDetailViewState extends State<HabitDetailView> {
  final _habits = HabitsService();
  final _checkins = CheckinService();
  final _onboarding = OnboardingService();

  GoldenHabit? _h;
  List<DailyCheckin> _recent = const [];
  bool _loading = true;
  bool _offline = false;
  Object? _error;

  bool _editing = false;
  bool _saving = false;
  bool _allLogs = false;
  final Map<String, TextEditingController> _ctl = {};

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _habits.dispose();
    for (final c in _ctl.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    if (_uid.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Not signed in';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final checkinsF = _checkins
          .getRecent(_uid, limit: 30)
          .catchError((_) => const <DailyCheckin>[]);
      final res = await _habits.getGoldenHabits(_uid);
      final recent = await checkinsF;
      if (!mounted) return;
      setState(() {
        _h = res.data.where((h) => h.habitId == widget.habitId).firstOrNull;
        _recent = recent;
        _offline = res.fromCache;
        _loading = false;
        if (_h == null) _error = 'missing';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: MM.body(color: Colors.white, size: 12)),
        backgroundColor: (error ? MM.red : MM.teal).withOpacity(0.92),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── editing ───────────────────────────────────────────────────────────

  void _startEdit() {
    final j = _h!.toJson();
    for (final k in GoldenHabit.editableKeys) {
      (_ctl[k] ??= TextEditingController()).text = '${j[k] ?? ''}';
    }
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    final h = _h!;
    final j = h.toJson();
    final changed = <String, String>{
      for (final k in GoldenHabit.editableKeys)
        if (_ctl[k]!.text.trim() != '${j[k] ?? ''}') k: _ctl[k]!.text.trim(),
    };
    if (changed['habitName']?.isEmpty ?? false) {
      _toast("The habit needs a name", error: true);
      return;
    }
    if (changed.isEmpty) {
      setState(() => _editing = false);
      return;
    }
    setState(() => _saving = true);
    try {
      // Manual Edit = a 🧪 experiment when it changes the habit's mechanics
      // (#23); the server decides which fields count.
      final exp = await _habits.updateHabitDetail(
        userId: _uid,
        habitId: h.habitId,
        fields: changed,
        experiment: const {'source': 'manual'},
      );
      if (!mounted) return;
      final started = exp != null && exp.id != h.experiment?.id;
      setState(() {
        var next = h.applyEdits(changed);
        if (exp != null) {
          next = next.copyWith(
            experiment: exp,
            flagged: false,
            flagReason: '',
            flagNote: '',
          );
        }
        _h = next;
        _editing = false;
      });
      _toast(
        exp == null
            ? 'Saved — every view now shows the update'
            : started
            ? "Saved as a 🧪 Experiment — try it for $experimentLength days and Nova checks in"
            : 'Saved — added to your running 🧪 experiment (its 3 days restart)',
      );
    } catch (e) {
      _toast(
        isNetworkError(e)
            ? "You're offline — nothing was saved"
            : "Couldn't save — try again",
        error: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── 🧪 experiments (#23) ──────────────────────────────────────────────

  Future<void> _resolveExperiment(String outcome) async {
    final h = _h!;
    final e = h.experiment;
    if (e == null) return;
    var learnings = '';
    if (outcome == 'retire') {
      final r = await askRetireLearnings(context);
      if (r == null || !mounted) return;
      learnings = r;
    }
    setState(() => _saving = true);
    try {
      await _habits.resolveExperiment(
        userId: _uid,
        habitId: h.habitId,
        experimentId: e.id,
        outcome: outcome,
        learnings: learnings,
      );
      if (!mounted) return;
      _toast(
        outcome == 'keep'
            ? '✅ Kept — that tweak is now part of the habit'
            : "♻️ Retired — the old version is back, and Nova won't suggest it again",
      );
      await _load(); // a retire restores the old values
    } catch (e) {
      _toast(
        isNetworkError(e)
            ? "You're offline — nothing changed"
            : "Couldn't update the experiment — try again",
        error: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _experiment(GoldenHabit h, String core) => ExperimentCard(
    experiment: h.experiment!,
    progress: experimentProgress(h.experiment!, core, _recent),
    coreName: _coreTitle[core] ?? h.coreLabel,
    busy: _saving,
    onKeep: () => _resolveExperiment('keep'),
    onRetire: () => _resolveExperiment('retire'),
    onGoDeeper: () => widget.onNav('rebuild:mbs:${h.habitId}'),
  );

  /// PATH 1 — 🚀 Quick Suggestion (#23 step 2): Nova proposes 1–2 tweaks;
  /// accepting one starts a 🧪 experiment (and clears the flag).
  Future<void> _quick() async {
    final h = _h!;
    final r = await showQuickSuggestion(
      context,
      userId: _uid,
      habitId: h.habitId,
      habitName: h.habitName,
      note: [h.flagReason, h.flagNote].where((t) => t.isNotEmpty).join(' — '),
    );
    if (!mounted) return;
    switch (r.outcome) {
      case QuickSuggestionOutcome.added:
        _toast(
          '🧪 Experiment activated — try it for $experimentLength days and Nova checks in',
        );
        await _load();
      case QuickSuggestionOutcome.goDeeper:
        await _rebuild();
      case QuickSuggestionOutcome.skipped:
        break;
    }
  }

  /// The three resolution paths, shown while the habit is flagged.
  Widget _flagPaths() => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final b in [
          MMGhostButton(
            label: '🚀 Quick Suggestion',
            color: MM.yellow,
            borderColor: MM.yellow.withOpacity(0.6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            onPressed: _saving ? null : _quick,
          ),
          MMGhostButton(
            label: '🔬 Go Deeper',
            color: MM.blue,
            borderColor: MM.blue.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            onPressed: _saving ? null : _rebuild,
          ),
          MMGhostButton(
            label: '✏️ Manual Edit',
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            onPressed: _saving ? null : _startEdit,
          ),
        ])
          IntrinsicWidth(child: b),
      ],
    ),
  );

  // ── actions ───────────────────────────────────────────────────────────

  Future<bool?> _ask(
    String title,
    String body,
    String yes, {
    String no = 'Cancel',
    Color accent = MM.teal,
  }) => showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          backgroundColor: MM.navy2,
          title: Text(title, style: MM.displayX(size: 12, color: accent)),
          content: Text(
            body,
            style: MM.body(color: Colors.white.withOpacity(0.8), size: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(no, style: MM.body(color: Colors.white70, size: 13)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(yes, style: MM.body(color: accent, size: 13)),
            ),
          ],
        ),
  );

  /// Mark as Formed — the same validation as the Trophy Room (#19): the
  /// 14-day / 80% standard, then Nova reads the Captain's Log.
  Future<void> _markFormed() async {
    final h = _h!;
    setState(() => _saving = true);
    try {
      final r = await _onboarding.confirmHabitFormation(
        userId: _uid,
        habitId: h.habitId,
      );
      if (!mounted) return;
      if (r.confirmed) {
        await _celebrate(r.creditsEarned, r.note);
        return;
      }
      final early = await _ask(
        r.eligible ? 'NOVA SAYS: NOT YET' : 'NOT QUITE YET',
        r.eligible
            ? '${r.note.isEmpty ? "Your scores look strong, but your Captain's Log suggests this one isn't automatic yet." : r.note}'
                '\n\nKeep going — or mark it formed anyway if it truly is who you are now.'
            : 'The 2-week standard: ${r.days}/$kFormationDays days logged at '
                '${r.consistency}% consistency (80% needed). '
                "Mark it formed anyway if it's now simply who you are.",
        'Mark formed anyway',
        no: 'Keep forming',
        accent: MM.yellow,
      );
      if (early != true || !mounted) return;
      final ok = await _onboarding.setHabitFormed(
        userId: _uid,
        habitId: h.habitId,
        formed: true,
      );
      if (!mounted) return;
      if (ok) {
        await _celebrate(0, '');
      } else {
        _toast("Couldn't save — check your connection", error: true);
      }
    } catch (_) {
      _toast("Couldn't reach Nova — check your connection", error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _celebrate(int credits, String note) async {
    await showDialog<void>(
      context: context,
      builder:
          (_) => FormationCelebration(
            habitName: _h!.habitName,
            creditsEarned: credits,
            note: note,
          ),
    );
    await _load();
  }

  /// Need Help / Rebuild → Phase 1 Stage 1 (the Golden Habit) or Stage 2
  /// (its MBMs), with this habit pre-loaded (§4C Re-Entry Bridge).
  Future<void> _rebuild() async {
    final stage = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: MM.navy2,
      builder:
          (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'NEED HELP?',
                    style: MM.displayX(size: 12, color: MM.blue),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "No failure here — only data. Where's the friction?",
                    style: MM.body(
                      color: Colors.white.withOpacity(0.65),
                      size: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  MMGhostButton(
                    label: 'The habit itself → rebuild it (Phase 1 · Stage 1)',
                    expand: true,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    onPressed: () => Navigator.pop(ctx, 'hhs'),
                  ),
                  const SizedBox(height: 8),
                  MMGhostButton(
                    label: 'The methods → better MBMs (Phase 1 · Stage 2)',
                    expand: true,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    onPressed: () => Navigator.pop(ctx, 'mbs'),
                  ),
                ],
              ),
            ),
          ),
    );
    if (stage != null) widget.onNav('rebuild:$stage:${_h!.habitId}');
  }

  /// Routine ↔ Non-Routine (§4E): the habit carries over, its MBMs are
  /// flagged for review, scores stay, and the switch is logged.
  Future<void> _changeType() async {
    final h = _h!;
    final to = h.habitType == 'non_routine' ? 'routine' : 'non_routine';
    final toRoutine = to == 'routine';
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: MM.navy2,
            title: Text(
              toRoutine ? 'MAKE IT A ROUTINE?' : 'MAKE IT A NON-ROUTINE?',
              style: MM.displayX(size: 12, color: MM.blue),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${toRoutine ? 'Routines happen at a set time (Morning / Afternoon / Evening).' : 'Non-routines are triggered by a situation or feeling, any time of day.'}'
                  '\n\nYour Golden Habit and scoring history stay. It moves to your '
                  '${toRoutine ? 'Routines' : 'Non-Routines'} list, and its MBMs are '
                  'flagged so you can rework them for the new type.',
                  style: MM.body(
                    color: Colors.white.withOpacity(0.8),
                    size: 13,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reason,
                  maxLength: 500,
                  style: MM.body(color: Colors.white, size: 13),
                  decoration: InputDecoration(
                    hintText:
                        'Why? (optional), e.g. "only when I feel stressed"',
                    hintStyle: MM.body(
                      color: Colors.white.withOpacity(0.35),
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: MM.body(color: Colors.white70, size: 13),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Change type',
                  style: MM.body(color: MM.blue, size: 13),
                ),
              ),
            ],
          ),
    );
    final why = reason.text.trim();
    reason.dispose();
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await _habits.reclassifyHabit(
        userId: _uid,
        habitId: h.habitId,
        to: to,
        reason: why,
      );
      _toast(
        'Now a ${toRoutine ? 'routine' : 'non-routine'} — review its MBMs when you can',
      );
      await _load();
    } catch (e) {
      _toast(
        isNetworkError(e)
            ? "You're offline — nothing changed"
            : "Couldn't change the type — try again",
        error: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _mbmReview(GoldenHabit h) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: MM.yellow.withOpacity(0.08),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: MM.yellow.withOpacity(0.4)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⚠️ Review these for a ${_typeName(h.habitType)} habit',
          style: MM.body(color: MM.yellow, size: 12, weight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          h.habitType == 'non_routine'
              ? 'Non-routines work best with IF-THEN plans and emotional awareness anchors.'
              : 'Routines work best with environment design: cues, time and place.',
          style: MM.body(color: Colors.white.withOpacity(0.7), size: 11.5),
        ),
        const SizedBox(height: 8),
        IntrinsicWidth(
          child: MMGhostButton(
            label: 'Review MBMs · Phase 1 Stage 2',
            color: MM.yellow,
            borderColor: MM.yellow.withOpacity(0.5),
            onPressed: () => widget.onNav('rebuild:mbs:${h.habitId}'),
          ),
        ),
      ],
    ),
  );

  Future<void> _flag() async {
    final h = _h!;
    final r = await showModalBottomSheet<HabitFlagResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => HabitFlagSheet(habit: h),
    );
    if (r == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await _habits.flagGoldenHabit(
        userId: _uid,
        habitId: h.habitId,
        flagged: r.flagged,
        reason: r.reason,
        note: r.note,
      );
      if (!mounted) return;
      setState(
        () =>
            _h = h.copyWith(
              flagged: r.flagged,
              flagReason: r.flagged ? r.reason : '',
              flagNote: r.flagged ? r.note : '',
            ),
      );
      _toast(
        r.flagged
            ? "Flagged — that's data, not failure. Pick a path above to tune it."
            : 'Flag removed',
      );
    } catch (_) {
      _toast("Couldn't update the flag — check your connection", error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: CircularProgressIndicator(color: MM.magenta)),
      );
    }
    final err = _error;
    if (err != null || _h == null) {
      if (err != null && err != 'missing' && isNetworkError(err)) {
        return OfflineErrorView(onRetry: _load, what: 'this habit');
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Text(
              err == 'missing'
                  ? 'This habit no longer exists'
                  : 'Could not load this habit',
              style: MM.display(size: 14, color: Colors.white),
            ),
            const SizedBox(height: 12),
            MMGhostButton(label: 'Retry', onPressed: _load),
          ],
        ),
      );
    }

    final h = _h!;
    final core = GoldenHabitRef.shortCore(h.coreId);
    final accent = MM.coreColor[core] ?? MM.magenta;
    final progress = formationProgress(
      coreScoreSeries(_recent)[core] ?? const [],
    );

    final spec = <Widget>[
      _section('THE HABIT', accent, [
        _field(
          'Abbreviated version',
          'displayText',
          abbreviatedVersion(h),
          fallback: h.what,
        ),
        _field('WHAT', 'what', h.what),
        _field('WHERE', 'where', h.where),
        _field('WHEN', 'when', h.when),
      ]),
      _section('PAIN POINT', MM.red, [_field(null, 'painPoint', h.painPoint)]),
      _section('BACK TO THE FUTURE GOAL', MM.violet, [
        _field(null, 'backToFutureIdentity', h.backToFutureIdentity),
      ]),
      _section('ANCHOR REMINDER', MM.blue, [
        _field('CUE', 'trigger', h.trigger),
        _field('REMINDER', 'anchorReminder', h.anchorReminder),
      ]),
      _section('OBSTACLE PLAN', MM.yellow, [
        _field('IF', 'obstacleIf', h.obstacleIf),
        _field('THEN', 'obstacleThen', h.obstacleThen),
      ]),
      _section('WHY THIS WORKS · TRIPLE-CHECK', MM.magenta, [
        _field('WANT', 'whyWant', h.whyWant),
        _field('CAN', 'whyCan', h.whyCan),
        _field('EFFECTIVE', 'whyEffective', h.whyEffective),
      ]),
      _section('STARTING VERSION', MM.teal, [
        _field(null, 'startingVersion', h.startingVersion),
        if (!_editing)
          Text(
            'Fall back to this when friction is high. Non-zero beats perfect.',
            style: MM.body(color: Colors.white.withOpacity(0.45), size: 11),
          ),
      ]),
    ];

    final side = <Widget>[
      if (h.experiment != null && !_editing) _experiment(h, core),
      _formation(h, progress, accent),
      _section('MOMENTUM-BOOSTING METHODS', MM.blue, [
        if (h.mbmsNeedReview && !_editing) _mbmReview(h),
        _field(
          'MAKE IT OBVIOUS',
          'makeObvious',
          h.makeObvious,
          empty:
              h.mbsCompleted
                  ? null
                  : 'Not set yet — Phase 1 · Stage 2 builds these.',
        ),
        _field('MAKE IT EASY', 'makeEasy', h.makeEasy),
        _field('MAKE IT FUN', 'makeRewarding', h.makeRewarding),
      ]),
      _section('ONE-TIME ACTIONS', MM.teal, [
        _field(
          null,
          'oneTimeActions',
          h.oneTimeActions,
          lines: 3,
          empty:
              'Setup tasks that remove friction for good — e.g. "put the '
              'journal on my pillow". Tap Edit to add some.',
        ),
      ]),
      _section('MY NOTES', Colors.white70, [
        _field(
          null,
          'playerNotes',
          h.playerNotes,
          lines: 4,
          empty: 'Your own observations. Tap Edit to add a note.',
        ),
      ]),
      _captainsLog(h, core),
      if (h.reclassifications.isNotEmpty)
        _section('TYPE HISTORY', Colors.white70, [
          for (final r in h.reclassifications.reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${r.date} · ${_typeName(r.from)} → ${_typeName(r.to)}'
                '${r.source == 'ai' ? ' · suggested by Nova' : ''}'
                '${r.reason.isEmpty ? '' : '\n${r.reason}'}',
                style: MM.body(color: Colors.white.withOpacity(0.75), size: 12),
              ),
            ),
        ]),
    ];

    final body =
        widget.wide
            ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: Column(children: spec)),
                const SizedBox(width: 16),
                Expanded(flex: 5, child: Column(children: side)),
              ],
            )
            : Column(
              children: [
                // Phone: the experiment and formation status lead.
                ...side.take(h.experiment != null && !_editing ? 2 : 1),
                ...spec,
                ...side.skip(h.experiment != null && !_editing ? 2 : 1),
              ],
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_offline) ...[
          OfflineBanner(onRefresh: _load),
          const SizedBox(height: 10),
        ],
        _header(h, core, accent),
        const SizedBox(height: 14),
        body,
        const SizedBox(height: 6),
        _actions(h, accent),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _header(GoldenHabit h, String core, Color accent) {
    final type =
        h.habitType == 'non_routine'
            ? 'NON-ROUTINE · CONTEXT-BASED'
            : 'ROUTINE · TIME-BASED';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${_coreIcon[core] ?? '•'} ${(_coreTitle[core] ?? h.coreLabel).toUpperCase()}',
              style: MM.displayX(size: 10, color: accent),
            ),
            Text(
              '· $type',
              style: MM.displayX(
                size: 10,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            if (h.flagged)
              Text(
                '· ⚠️ FLAGGED',
                style: MM.displayX(size: 10, color: MM.yellow),
              ),
            if (h.experiment != null)
              Text(
                '· 🧪 EXPERIMENT',
                style: MM.displayX(size: 10, color: MM.violet),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_editing)
          _input('habitName', lines: 1, big: true)
        else
          Text(h.habitName, style: MM.display(size: 20, color: Colors.white)),
        if (h.flagged && !_editing) ...[
          const SizedBox(height: 6),
          if (h.flagReason.isNotEmpty)
            Text(
              'Flagged: ${h.flagReason}${h.flagNote.isEmpty ? '' : ' — ${h.flagNote}'}',
              style: MM.body(color: MM.yellow.withOpacity(0.85), size: 12),
            ),
          Text(
            "That's data, not failure. How would you like to tackle it?",
            style: MM.body(color: Colors.white.withOpacity(0.6), size: 12),
          ),
          _flagPaths(),
        ],
        if (h.reclassifiedAt.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Reclassified on ${h.reclassifiedAt}'
            '${h.reclassifications.isEmpty ? '' : ' (was ${_typeName(h.reclassifications.last.from)})'}'
            ' · scoring history kept',
            style: MM.body(color: Colors.white.withOpacity(0.55), size: 12),
          ),
        ],
      ],
    );
  }

  static String _typeName(String t) => switch (t) {
    'routine' => 'routine',
    'non_routine' => 'non-routine',
    _ => 'unclassified',
  };

  Widget _formation(GoldenHabit h, FormationProgress p, Color accent) {
    final String status;
    if (h.formed) {
      status = '🟢 Formed — this is part of who you are.';
    } else if (p.eligible) {
      status =
          '✅ Eligible: ${p.days} days at ${p.pctRounded}% — ready to mark as formed.';
    } else {
      status =
          '🟠 Forming: ${p.daysToGo} more day${p.daysToGo == 1 ? '' : 's'} '
          'for the 14-day standard · ${p.pctRounded}% consistency (80% needed).';
    }
    return _section('FORMATION STATUS', accent, [
      Row(
        children: [
          Text(
            'Day ${p.days.clamp(0, kFormationDays)}/$kFormationDays',
            style: MM.display(size: 16, color: accent),
          ),
          const Spacer(),
          if (!h.formed)
            Text(
              '${p.pctRounded}%',
              style: MM.body(color: Colors.white.withOpacity(0.7), size: 12),
            ),
        ],
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          minHeight: 5,
          value:
              h.formed ? 1 : p.days.clamp(0, kFormationDays) / kFormationDays,
          backgroundColor: Colors.white.withOpacity(0.08),
          valueColor: AlwaysStoppedAnimation(h.formed ? MM.teal : accent),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        status,
        style: MM.body(color: Colors.white.withOpacity(0.75), size: 12),
      ),
      Text(
        'From your Core scores in the last ${_recent.length} check-ins.',
        style: MM.body(color: Colors.white.withOpacity(0.4), size: 10.5),
      ),
    ]);
  }

  Widget _captainsLog(GoldenHabit h, String core) {
    final lines = habitLogLines(_recent, core, h.habitName);
    final shown = _allLogs ? lines : lines.take(3).toList();
    return _section(
      "CAPTAIN'S LOG · ${(_coreTitle[core] ?? core).toUpperCase()}",
      MM.yellow,
      [
        if (lines.isEmpty)
          Text(
            'No entries yet. Your Wins and Lessons from each check-in show up here.',
            style: MM.body(color: Colors.white.withOpacity(0.5), size: 12),
          ),
        for (final l in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l.date}${l.mentions ? '  ·  mentions this habit' : ''}',
                  style: MM.body(
                    color:
                        l.mentions ? MM.yellow : Colors.white.withOpacity(0.45),
                    size: 10.5,
                  ),
                ),
                if (l.wins.isNotEmpty)
                  Text(
                    '🏆 ${l.wins}',
                    style: MM.body(color: Colors.white, size: 12),
                  ),
                if (l.lessons.isNotEmpty)
                  Text(
                    '📚 ${l.lessons}',
                    style: MM.body(color: Colors.white, size: 12),
                  ),
              ],
            ),
          ),
        if (lines.length > 3)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _allLogs = !_allLogs),
              child: Text(
                _allLogs ? 'Show fewer' : 'Show all ${lines.length}',
                style: MM.body(color: MM.yellow, size: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _actions(GoldenHabit h, Color accent) {
    if (_editing) {
      final row = Row(
        children: [
          Expanded(
            child: MMGhostButton(
              label: 'Cancel',
              expand: true,
              padding: const EdgeInsets.symmetric(vertical: 13),
              onPressed:
                  _saving ? null : () => setState(() => _editing = false),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: MMPrimaryButton(
              label: 'Save changes',
              busy: _saving,
              padding: const EdgeInsets.symmetric(vertical: 13),
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            h.experiment != null
                ? '🧪 Changes to the habit, cue, obstacle plan or MBMs join your '
                    'running experiment and restart its $experimentLength days.'
                : '🧪 Changes to the habit, cue, obstacle plan or MBMs start a '
                    '$experimentLength-day experiment. Notes and names don\'t.',
            style: MM.body(color: MM.violet.withOpacity(0.9), size: 11.5),
          ),
          const SizedBox(height: 10),
          row,
        ],
      );
    }
    final buttons = <Widget>[
      if (h.formed)
        MMGhostButton(
          label: '🏆 In the Trophy Room',
          color: MM.teal,
          borderColor: MM.teal.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          onPressed: () => widget.onNav('trophy'),
        )
      else
        MMGhostButton(
          label: '✓ Mark as Formed',
          color: MM.teal,
          borderColor: MM.teal.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          onPressed: _saving ? null : _markFormed,
        ),
      MMGhostButton(
        label: '✎ Edit',
        color: accent,
        borderColor: accent.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onPressed: _saving ? null : _startEdit,
      ),
      MMGhostButton(
        label:
            h.habitType == 'non_routine'
                ? '⇄ Make it a routine'
                : '⇄ Make it a non-routine',
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onPressed: _saving ? null : _changeType,
      ),
      MMGhostButton(
        label: '🛠 Need Help / Rebuild',
        color: MM.blue,
        borderColor: MM.blue.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onPressed: _saving ? null : _rebuild,
      ),
      MMGhostButton(
        label: h.flagged ? '⚠️ Flagged' : '⚠️ Flag',
        color: MM.yellow,
        borderColor: MM.yellow.withOpacity(h.flagged ? 0.9 : 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onPressed: _saving ? null : _flag,
      ),
    ];
    // MMGhostButton centres its label, which fills any width it's given.
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [for (final b in buttons) IntrinsicWidth(child: b)],
    );
  }

  // ── building blocks ───────────────────────────────────────────────────

  Widget _section(String label, Color color, List<Widget> children) =>
      GlassPanel(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        leftAccentColor: color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: MM.displayX(size: 9, color: color)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      );

  /// One field: read-only text, or an input while editing. [fallback] shows
  /// when the stored value is empty; [empty] is the hint if both are empty.
  Widget _field(
    String? label,
    String key,
    String value, {
    String fallback = '',
    String? empty,
    int lines = 2,
  }) {
    final shown = value.trim().isNotEmpty ? value.trim() : fallback.trim();
    final content =
        _editing
            ? _input(key, lines: lines)
            : Text(
              shown.isNotEmpty ? shown : (empty ?? '—'),
              style:
                  shown.isNotEmpty
                      ? MM.body(color: Colors.white, size: 12.5)
                      : MM.body(color: Colors.white.withOpacity(0.4), size: 12),
            );
    if (label == null) return content;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: MM.display(
              size: 8.5,
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 3),
          content,
        ],
      ),
    );
  }

  Widget _input(String key, {int lines = 2, bool big = false}) => TextField(
    controller: _ctl[key],
    minLines: 1,
    maxLines: lines < 2 ? 1 : lines + 2,
    style:
        big
            ? MM.display(size: 18, color: Colors.white)
            : MM.body(color: Colors.white, size: 12.5),
    cursorColor: MM.teal,
    decoration: InputDecoration(
      isDense: true,
      filled: true,
      fillColor: MM.navy.withOpacity(0.55),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: MM.teal),
      ),
    ),
  );
}

/// Result of [HabitFlagSheet]: flag on/off + reason + note.
class HabitFlagResult {
  const HabitFlagResult(this.flagged, this.reason, this.note);
  final bool flagged;
  final String reason;
  final String note;
}

/// Bottom sheet for manually flagging a habit for refinement (Product Design
/// Rationale C4). Anti-shame: "flagging is data, not failure". Reasons are
/// grounded in C5's two root causes (the habit is wrong vs. execution is
/// failing). Pops a [HabitFlagResult].
class HabitFlagSheet extends StatefulWidget {
  const HabitFlagSheet({super.key, required this.habit});
  final GoldenHabit habit;
  @override
  State<HabitFlagSheet> createState() => _HabitFlagSheetState();
}

class _HabitFlagSheetState extends State<HabitFlagSheet> {
  static const _reasons = [
    'The habit itself feels wrong',
    "The strategy / cue isn't working",
    'Life circumstances changed',
    'Too hard right now',
    'Other',
  ];

  late String _reason =
      _reasons.contains(widget.habit.flagReason)
          ? widget.habit.flagReason
          : (widget.habit.flagReason.isEmpty ? _reasons.first : 'Other');
  late final _note = TextEditingController(text: widget.habit.flagNote);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final already = widget.habit.flagged;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: MM.navy2,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '⚠ FLAG FOR REFINEMENT',
              style: MM.displayX(size: 12, color: MM.yellow),
            ),
            const SizedBox(height: 8),
            Text(
              "Flagging is data, not failure. It tells your Co-pilot this "
              'habit needs a tweak — nothing breaks your streak.',
              style: MM.body(color: Colors.white.withOpacity(0.6), size: 12),
            ),
            const SizedBox(height: 16),
            Text(
              "WHAT'S GOING ON?",
              style: MM.displayX(
                size: 9,
                color: Colors.white.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in _reasons)
                  _chip(r, _reason == r, () => setState(() => _reason = r)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'NOTE (optional)',
              style: MM.displayX(
                size: 9,
                color: Colors.white.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _note,
              style: MM.body(color: Colors.white, size: 13),
              cursorColor: MM.yellow,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Anything that helps your Co-pilot understand…',
                hintStyle: MM.body(
                  color: Colors.white.withOpacity(0.35),
                  size: 13,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                filled: true,
                fillColor: MM.navy.withOpacity(0.55),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: MM.yellow.withOpacity(0.4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: MM.yellow),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: MMGhostButton(
                    label: already ? 'Remove flag' : 'Cancel',
                    expand: true,
                    color: already ? MM.red : null,
                    borderColor: already ? MM.red.withOpacity(0.5) : null,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    onPressed:
                        () => Navigator.of(context).pop(
                          already ? const HabitFlagResult(false, '', '') : null,
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MMPrimaryButton(
                    label: already ? 'Update flag' : 'Flag this habit',
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    onPressed:
                        () => Navigator.of(context).pop(
                          HabitFlagResult(true, _reason, _note.text.trim()),
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool on, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: on ? MM.yellow.withOpacity(0.18) : MM.navy.withOpacity(0.45),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: on ? MM.yellow : Colors.white.withOpacity(0.12),
            width: on ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: MM.body(
            color: on ? Colors.white : Colors.white.withOpacity(0.7),
            size: 12,
          ),
        ),
      ),
    );
  }
}
