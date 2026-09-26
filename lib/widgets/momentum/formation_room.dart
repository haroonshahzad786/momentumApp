import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../screens/copilot_console_page.dart';
import '../../services/checkin_service.dart';
import '../../services/formation.dart';
import '../../services/onboarding_service.dart';
import '../../services/profile_service.dart';
import '../../theme/momentum_tokens.dart';
import 'confetti_overlay.dart';
import 'mm_buttons.dart';

const _coreMeta = <String, (String, String, Color)>{
  'mindset': ('Mindset', '🧠', MM.blue),
  'career': ('Career & Finances', '💰', MM.yellow),
  'relationships': ('Relationships', '👥', MM.magenta),
  'physical': ('Physical Health', '💪', MM.teal),
  'emotional': ('Emotional & Mental', '🧘', MM.violet),
};

const _identityLine = 'This is now automatic and part of who you ARE!';

/// Trophy Room body (#11 + #19, Gamification spec §8), shared by the web and
/// mobile Trophy Rooms: Habit Formation Goal, 30/60/90-day reviews, formed
/// trophies (with un-form) and forming habits (AI-validated confirm, or the
/// early "mark formed" path).
class FormationRoom extends StatefulWidget {
  const FormationRoom({
    super.key,
    required this.userId,
    this.onFormedCount,
    this.onHabitCount,
    this.onAskNova,
    this.tileWidth,
  });

  final String userId;

  /// Reports the formed-habit count after each load (for the host's header).
  final ValueChanged<int>? onFormedCount;

  /// Reports the total Golden Habit count after each load.
  final ValueChanged<int>? onHabitCount;

  /// Opens Nova with a pre-filled message; defaults to pushing the console.
  final void Function(String draft)? onAskNova;

  /// Fixed tile width for a grid (web); null = full-width list (mobile).
  final double? tileWidth;

  @override
  State<FormationRoom> createState() => _FormationRoomState();
}

class _Habit {
  _Habit(this.ref, this.progress);
  final GoldenHabitRef ref;
  final FormationProgress progress;
  String get name => ref.habitName.trim().isEmpty ? 'Golden Habit' : ref.habitName.trim();
}

class _FormationRoomState extends State<FormationRoom> {
  final _onboarding = OnboardingService();
  final _profiles = ProfileService();
  final _checkin = CheckinService();

  List<_Habit> _habits = const [];
  List<DailyCheckin> _checkins = const [];
  FormationGoal? _goal;
  bool _loading = true;
  String? _error;
  String? _busyHabit;
  bool _goalBusy = false;
  int _goalDays = kFirstGoalDefaultDays;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _onboarding.dispose();
    _profiles.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _habits.isEmpty;
      _error = null;
    });
    try {
      final habitsF = _onboarding.goldenHabits(widget.userId);
      final profileF = _profiles
          .getProfile(widget.userId)
          .then<UserProfile?>((p) => p.data)
          .catchError((_) => null);
      List<DailyCheckin> checkins = const [];
      try {
        checkins = await _checkin.getRecent(widget.userId, limit: 30);
      } catch (_) {}
      final byCore = <String, List<int>>{};
      for (final c in checkins) {
        c.scores.forEach((k, v) => (byCore[k] ??= <int>[]).add(v));
      }
      final habits = [
        for (final h in await habitsF) _Habit(h, formationProgress(byCore[h.shortCoreId] ?? const []))
      ];
      final profile = await profileF;
      if (!mounted) return;
      setState(() {
        _habits = habits;
        _checkins = checkins;
        _goal = profile?.formationGoal;
        _loading = false;
      });
      widget.onFormedCount?.call(habits.where((h) => h.ref.formed).length);
      widget.onHabitCount?.call(habits.length);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _askNova(String draft) {
    final f = widget.onAskNova;
    if (f != null) {
      f(draft);
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => CopilotConsolePage(draft: draft)));
    }
  }

  void _toast(String msg) =>
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(msg)));

  bool _wouldCrushGoal() {
    final g = _goal;
    if (g == null) return false;
    final s = _goalStatus(g);
    return !s.achieved && s.daysLeft > 0 && s.formed + 1 >= s.target;
  }

  GoalStatus _goalStatus(FormationGoal g) => goalStatus(
        g,
        [for (final h in _habits) if (h.ref.formed) h.ref.formedAt],
        [for (final h in _habits) if (!h.ref.formed) h.progress],
        DateTime.now(),
      );

  // ── actions ────────────────────────────────────────────────────────────

  Future<void> _confirm(_Habit h) async {
    setState(() => _busyHabit = h.ref.habitId);
    try {
      final crush = _wouldCrushGoal();
      final r = await _onboarding.confirmHabitFormation(userId: widget.userId, habitId: h.ref.habitId);
      if (!mounted) return;
      if (r.confirmed) {
        await _celebrate(h.name, credits: r.creditsEarned, note: r.note, goalCrushed: crush);
      } else if (!r.eligible) {
        _toast('Not quite yet — ${r.days}/$kFormationDays days · ${r.consistency}% consistency.');
      } else {
        await _notYet(h, r.note);
      }
    } catch (_) {
      _toast("Couldn't reach Nova — check your connection and try again.");
    } finally {
      if (mounted) setState(() => _busyHabit = null);
    }
    _load();
  }

  Future<void> _markEarly(_Habit h) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _Confirm(
        title: 'MARK AS FORMED',
        accent: MM.teal,
        body: '"${h.name}"\n\nThe 2-week standard: habits usually take 14+ days of consistency to form'
            '${h.progress.days > 0 ? ' (you have ${h.progress.days} logged)' : ''}. '
            "Mark it formed if it's now simply who you are.",
        yes: 'Mark Formed',
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busyHabit = h.ref.habitId);
    final crush = _wouldCrushGoal();
    final saved = await _onboarding.setHabitFormed(userId: widget.userId, habitId: h.ref.habitId, formed: true);
    if (!mounted) return;
    setState(() => _busyHabit = null);
    if (saved) {
      await _celebrate(h.name, goalCrushed: crush);
    } else {
      _toast("Couldn't save — check your connection and try again.");
    }
    _load();
  }

  Future<void> _notYet(_Habit h, String note) async {
    final early = await showDialog<bool>(
      context: context,
      builder: (ctx) => _Confirm(
        title: 'NOVA SAYS: NOT YET',
        accent: MM.yellow,
        body: '${note.isEmpty ? "Your scores look strong, but your Captain's Log suggests this one isn't automatic yet." : note}'
            '\n\nKeep going — or mark it formed anyway if it truly is who you are now.',
        yes: 'Mark formed anyway',
        no: 'Keep forming',
      ),
    );
    if (early == true && mounted) await _markEarly(h);
  }

  Future<void> _unform(_Habit h, {int? milestone}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _Confirm(
        title: 'UN-FORM & REBUILD',
        accent: MM.blue,
        body: '"${h.name}" goes back to forming so you can rebuild it with what you\'ve learned since. '
            "This is adaptation, not failure — your credits and history stay.",
        yes: 'Un-form',
        no: 'Keep it formed',
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busyHabit = h.ref.habitId);
    try {
      await _onboarding.reviewFormedHabit(userId: widget.userId, habitId: h.ref.habitId, keep: false);
    } catch (_) {
      _toast("Couldn't save — check your connection and try again.");
    }
    if (mounted) setState(() => _busyHabit = null);
    _load();
  }

  Future<void> _keep(_Habit h, int milestone) async {
    setState(() => _busyHabit = h.ref.habitId);
    try {
      await _onboarding.reviewFormedHabit(
          userId: widget.userId, habitId: h.ref.habitId, keep: true, milestone: milestone);
    } catch (_) {
      _toast("Couldn't save — check your connection and try again.");
    }
    if (mounted) setState(() => _busyHabit = null);
    _load();
  }

  Future<void> _setGoal({required bool next}) async {
    setState(() => _goalBusy = true);
    try {
      final g = await _onboarding.setFormationGoal(userId: widget.userId, next: next, days: next ? null : _goalDays);
      if (mounted) setState(() => _goal = FormationGoal.tryParse(g) ?? _goal);
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _goalBusy = false);
    }
  }

  Future<void> _celebrate(String habit, {int credits = 0, String note = '', bool goalCrushed = false}) =>
      showDialog<void>(
        context: context,
        barrierColor: const Color(0xDD06070D),
        builder: (_) => FormationCelebration(
          habitName: habit,
          creditsEarned: credits,
          note: note,
          goalCrushed: goalCrushed,
        ),
      );

  // ── build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: MM.yellow)),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(children: [
          Text('Could not load trophies', style: MM.display(size: 14, color: Colors.white)),
          const SizedBox(height: 14),
          MMGhostButton(label: 'Retry', onPressed: _load),
        ]),
      );
    }
    final today = DateTime.now();
    final reviews = <(_Habit, int)>[
      for (final h in _habits)
        if (h.ref.formed)
          if (dueReview(h.ref.formedAt, today, h.ref.reviews) case final m?) (h, m)
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _goalCard(),
        for (final r in reviews) _reviewCard(r.$1, r.$2),
        if (_habits.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text('No Golden Habits yet — forge one in Phase 1 and it starts forming here.',
                textAlign: TextAlign.center, style: MM.body(size: 13, color: Colors.white60)),
          ),
        for (final core in _coreMeta.keys) _coreSection(core),
      ],
    );
  }

  Widget _panel({required Widget child, Color? border}) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MM.panel.withOpacity(0.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: (border ?? Colors.white).withOpacity(border == null ? 0.1 : 0.45)),
        ),
        child: child,
      );

  Widget _bar(double v, Color c) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: v,
          minHeight: 7,
          backgroundColor: Colors.white.withOpacity(0.08),
          valueColor: AlwaysStoppedAnimation(c),
        ),
      );

  Widget _goalCard() {
    final muted = Colors.white.withOpacity(0.62);
    final g = _goal;
    if (g == null || _goalStatus(g).ended) {
      final ended = g != null;
      return _panel(
        border: MM.yellow,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('🎯  HABIT FORMATION GOAL', style: MM.displayX(size: 10, color: MM.yellow)),
          const SizedBox(height: 8),
          Text(
            ended
                ? 'That goal window has closed — ${_goalStatus(g).formed}/${g.habits} formed. No problem: set a fresh window and go again.'
                : "Let's aim to form 1 habit in your first 2 weeks.",
            style: MM.body(size: 14, color: Colors.white, height: 1.45),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Text('Form 1 habit in', style: MM.body(size: 12.5, color: muted)),
            const Spacer(),
            Text('$_goalDays days', style: MM.display(size: 14, color: Colors.white)),
          ]),
          Slider(
            value: _goalDays.toDouble(),
            min: kFirstGoalMinDays.toDouble(),
            max: kFirstGoalMaxDays.toDouble(),
            divisions: kFirstGoalMaxDays - kFirstGoalMinDays,
            activeColor: MM.yellow,
            onChanged: (v) => setState(() => _goalDays = v.round()),
          ),
          Row(children: [
            Text('7 · ambitious', style: MM.body(size: 11, color: muted)),
            const Spacer(),
            Text('21 · cautious', style: MM.body(size: 11, color: muted)),
          ]),
          const SizedBox(height: 12),
          MMPrimaryButton(
            label: 'Set my goal',
            busy: _goalBusy,
            onPressed: _goalBusy ? null : () => _setGoal(next: false),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ]),
      );
    }

    final s = _goalStatus(g);
    final forming = [for (final h in _habits) if (!h.ref.formed) h];
    final ci = closestToForming([for (final h in forming) h.progress]);
    final closest = ci == null ? null : forming[ci];
    final next = g.next;
    return _panel(
      border: s.achieved ? MM.teal : (s.atRisk ? MM.red : MM.yellow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text('🎯  HABIT FORMATION GOAL', style: MM.displayX(size: 10, color: MM.yellow)),
          const Spacer(),
          if (!s.achieved)
            Text('${s.daysLeft} DAY${s.daysLeft == 1 ? '' : 'S'} LEFT',
                style: MM.display(size: 10, color: s.atRisk ? MM.red : muted)),
        ]),
        const SizedBox(height: 8),
        Text('Form ${g.habits} habit${g.habits == 1 ? '' : 's'} in ${g.days} days',
            style: MM.display(size: 16, color: Colors.white)),
        const SizedBox(height: 10),
        _bar(s.fraction, s.achieved ? MM.teal : MM.yellow),
        const SizedBox(height: 6),
        Text('${s.formed}/${s.target} formed', style: MM.body(size: 12, color: muted)),
        if (s.achieved) ...[
          const SizedBox(height: 12),
          Text('🎉 Goal crushed!', style: MM.display(size: 15, color: MM.teal)),
          const SizedBox(height: 4),
          Text('Next challenge: form ${next.$1} habit${next.$1 == 1 ? '' : 's'} in ${next.$2} days.',
              style: MM.body(size: 13, color: Colors.white, height: 1.4)),
          const SizedBox(height: 10),
          MMPrimaryButton(
            label: 'Accept next challenge',
            busy: _goalBusy,
            onPressed: _goalBusy ? null : () => _setGoal(next: true),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ] else ...[
          if (closest != null) ...[
            const SizedBox(height: 10),
            Text('CLOSEST HABIT TO FORMING', style: MM.displayX(size: 8.5, color: muted)),
            const SizedBox(height: 4),
            Text(
              '${closest.name} — ${closest.progress.days}/$kFormationDays days · '
              '${closest.progress.pctRounded}% consistency',
              style: MM.body(size: 13, color: Colors.white, height: 1.4),
            ),
          ],
          if (s.atRisk) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MM.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: MM.red.withOpacity(0.35)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(
                  'Only ${s.daysLeft} day${s.daysLeft == 1 ? '' : 's'} left and no habits close to forming. Need help?',
                  style: MM.body(size: 13, color: Colors.white, height: 1.4),
                ),
                const SizedBox(height: 8),
                MMGhostButton(
                  label: '🤖 Get help from Nova',
                  expand: true,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: () => _askNova(
                      'My habit formation goal ends in ${s.daysLeft} day${s.daysLeft == 1 ? '' : 's'} and none of my habits are close to forming. '
                      'Can you help me figure out what to adjust?'),
                ),
              ]),
            ),
          ],
        ],
      ]),
    );
  }

  Widget _reviewCard(_Habit h, int milestone) {
    final drop = coreDrop(_checkins, h.ref.shortCoreId, h.ref.formedAt);
    final slipping = drop != null && drop >= kSlipDrop;
    final core = _coreMeta[h.ref.shortCoreId]?.$1 ?? 'Core';
    final busy = _busyHabit == h.ref.habitId;
    return _panel(
      border: slipping ? MM.red : MM.blue,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('$milestone-DAY TROPHY REVIEW', style: MM.displayX(size: 10, color: slipping ? MM.red : MM.blue)),
        const SizedBox(height: 8),
        Text('Is "${h.name}" still automatic?', style: MM.body(size: 14, color: Colors.white, height: 1.4)),
        if (slipping) ...[
          const SizedBox(height: 6),
          Text(
            'Your $core average is down ${drop.toStringAsFixed(1)} since it formed. It may be worth '
            'un-forming and rebuilding with fresh insights — adaptation, not failure.',
            style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.7), height: 1.45),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          MMPrimaryButton(
            label: 'Still automatic ✓',
            expand: false,
            busy: busy,
            onPressed: busy ? null : () => _keep(h, milestone),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          ),
          MMGhostButton(
            label: 'Un-form & rebuild',
            onPressed: busy ? null : () => _unform(h, milestone: milestone),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          ),
          if (slipping)
            MMGhostButton(
              label: '🤖 Talk to Nova',
              onPressed: () => _askNova(
                  'My formed habit "${h.name}" seems to be slipping — my $core average dropped '
                  '${drop.toStringAsFixed(1)} points. Should I un-form and rebuild it?'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            ),
        ]),
      ]),
    );
  }

  Widget _coreSection(String core) {
    final list = _habits.where((h) => h.ref.shortCoreId == core).toList();
    if (list.isEmpty) return const SizedBox.shrink();
    final meta = _coreMeta[core]!;
    final formed = list.where((h) => h.ref.formed).toList();
    final forming = list.where((h) => !h.ref.formed).toList();
    final tiles = [for (final h in formed) _trophyTile(h, meta.$3), for (final h in forming) _formingTile(h, meta.$3)];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text(meta.$2, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(meta.$1.toUpperCase(), style: MM.displayX(size: 10, color: meta.$3)),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: meta.$3.withOpacity(0.2))),
          const SizedBox(width: 8),
          Text('${formed.length} 🏆', style: MM.mono(size: 10, color: Colors.white.withOpacity(0.5))),
        ]),
        const SizedBox(height: 10),
        if (widget.tileWidth == null)
          ...tiles.map((t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: t))
        else
          Wrap(spacing: 12, runSpacing: 12, children: [
            for (final t in tiles) SizedBox(width: widget.tileWidth, child: t),
          ]),
      ]),
    );
  }

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  String _date(String iso) {
    final d = DateTime.tryParse(iso);
    return d == null ? '' : '${_months[d.month - 1]} ${d.day}';
  }

  Widget _trophyTile(_Habit h, Color hex) {
    final date = _date(h.ref.formedAt);
    final busy = _busyHabit == h.ref.habitId;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MM.panel.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hex.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: hex.withOpacity(0.12), blurRadius: 14)],
      ),
      child: Row(children: [
        const Text('🏆', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(h.name, style: MM.body(size: 14, color: Colors.white, weight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(
              [
                if (date.isNotEmpty) 'FORMED ${date.toUpperCase()}' else 'FORMED',
                if (h.ref.formedVia == 'ai_validated') 'NOVA-VALIDATED',
                if (h.ref.formedVia == 'manual') 'MARKED EARLY',
              ].join(' · '),
              style: MM.display(size: 9, color: Colors.white.withOpacity(0.5)),
            ),
          ]),
        ),
        TextButton(
          onPressed: busy ? null : () => _unform(h),
          child: Text('Un-form', style: MM.body(size: 11.5, color: Colors.white.withOpacity(0.55))),
        ),
      ]),
    );
  }

  Widget _formingTile(_Habit h, Color hex) {
    final p = h.progress;
    final busy = _busyHabit == h.ref.habitId;
    final muted = Colors.white.withOpacity(0.55);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MM.panel.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.eligible ? MM.teal.withOpacity(0.6) : Colors.white.withOpacity(0.1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text(p.eligible ? '🟢' : '🟠', style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(child: Text(h.name, style: MM.body(size: 13.5, color: Colors.white, weight: FontWeight.w600))),
        ]),
        const SizedBox(height: 10),
        _bar((p.days / kFormationDays).clamp(0.0, 1.0), p.eligible ? MM.teal : hex),
        const SizedBox(height: 6),
        Text(
          '${p.days.clamp(0, kFormationDays)}/$kFormationDays days · ${p.pctRounded}% consistency'
          '${p.eligible ? '' : ' (80% needed)'}',
          style: MM.body(size: 11.5, color: muted),
        ),
        const SizedBox(height: 10),
        if (p.eligible) ...[
          Text('Ready to form! Nova will check your log and confirm.',
              style: MM.body(size: 12, color: MM.teal, height: 1.35)),
          const SizedBox(height: 8),
          MMPrimaryButton(
            label: 'Confirm formation',
            busy: busy,
            onPressed: busy ? null : () => _confirm(h),
            padding: const EdgeInsets.symmetric(vertical: 11),
          ),
        ] else
          Align(
            alignment: Alignment.centerRight,
            child: MMGhostButton(
              label: 'Mark formed early',
              onPressed: busy ? null : () => _markEarly(h),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
      ]),
    );
  }
}

/// Formation celebration (spec §8): confetti, the habit's name, the identity
/// line, rewards, and — when this formation hits the goal — "goal crushed".
class FormationCelebration extends StatelessWidget {
  const FormationCelebration({
    super.key,
    required this.habitName,
    this.creditsEarned = 0,
    this.note = '',
    this.goalCrushed = false,
  });

  final String habitName;
  final int creditsEarned;
  final String note;
  final bool goalCrushed;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: MM.navy,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: MM.yellow.withOpacity(0.6)),
                boxShadow: [BoxShadow(color: MM.yellow.withOpacity(0.25), blurRadius: 40)],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('🏆', style: TextStyle(fontSize: 54)),
                const SizedBox(height: 10),
                Text(goalCrushed ? 'FORMATION GOAL CRUSHED' : 'HABIT FORMED',
                    style: MM.displayX(size: 11, color: MM.yellow)),
                const SizedBox(height: 10),
                Text('"$habitName"',
                    textAlign: TextAlign.center, style: MM.display(size: 18, color: Colors.white)),
                const SizedBox(height: 10),
                Text(_identityLine,
                    textAlign: TextAlign.center,
                    style: MM.body(size: 14.5, color: Colors.white, height: 1.45, weight: FontWeight.w600)),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Nova: $note',
                      textAlign: TextAlign.center,
                      style: MM.body(size: 12.5, color: Colors.white.withOpacity(0.7), height: 1.45)),
                ],
                if (creditsEarned > 0) ...[
                  const SizedBox(height: 12),
                  Text('+$creditsEarned Space Credits 💎', style: MM.display(size: 15, color: MM.yellow)),
                ],
                if (goalCrushed) ...[
                  const SizedBox(height: 10),
                  Text('Your next challenge is waiting in the Trophy Room.',
                      textAlign: TextAlign.center, style: MM.body(size: 12.5, color: MM.teal)),
                ],
                const SizedBox(height: 18),
                MMPrimaryButton(label: 'Onward', onPressed: () => Navigator.of(context).pop()),
              ]),
            ),
          ),
        ),
      ),
      const IgnorePointer(child: ConfettiOverlay(count: 120, origin: Alignment(0, -0.5))),
    ]);
  }
}

class _Confirm extends StatelessWidget {
  const _Confirm({required this.title, required this.accent, required this.body, required this.yes, this.no = 'Cancel'});
  final String title;
  final Color accent;
  final String body;
  final String yes;
  final String no;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: MM.navy,
      insetPadding: const EdgeInsets.all(28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: accent.withOpacity(0.45)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: MM.displayX(size: 11, color: accent)),
            const SizedBox(height: 10),
            Text(body, style: MM.body(size: 13, color: Colors.white.withOpacity(0.85), height: 1.5)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: MMGhostButton(
                  label: no,
                  expand: true,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: MMPrimaryButton(label: yes, onPressed: () => Navigator.pop(context, true))),
            ]),
          ]),
        ),
      ),
    );
  }
}
