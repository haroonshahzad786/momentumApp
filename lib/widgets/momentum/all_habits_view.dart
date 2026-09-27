import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/all_habits.dart';
import '../../services/checkin_service.dart';
import '../../services/core_lists_service.dart';
import '../../services/habits_service.dart';
import '../../services/offline.dart';
import '../../theme/momentum_tokens.dart';
import 'mm_buttons.dart';
import 'offline_banner.dart';

const Map<String, String> _coreIcon = {
  'mindset': '🧠',
  'career': '💰',
  'relationships': '👥',
  'physical': '💪',
  'emotional': '🧘',
};

const Map<String, String> _coreTitle = {
  'mindset': 'Mindset',
  'career': 'Career & Finances',
  'relationships': 'Relationships',
  'physical': 'Physical Health',
  'emotional': 'Emotional & Mental',
};

/// ALL HABITS Quick View (PRD §11, #21) — the rocket's centre (∞) icon. Every
/// habit the player has, from both stores, toggled By Time / By Core. Shared
/// by the phone screen and the desktop shell.
class AllHabitsView extends StatefulWidget {
  const AllHabitsView({super.key, required this.onNav, this.wide = false});

  final void Function(String key) onNav;

  /// Desktop: sections flow into two columns.
  final bool wide;

  @override
  State<AllHabitsView> createState() => _AllHabitsViewState();
}

class _AllHabitsViewState extends State<AllHabitsView> {
  static const _viewKey = 'mm.allhabits.view';

  final _habits = HabitsService();
  final _lists = CoreListsService();
  final _checkins = CheckinService();

  List<AllHabit> _all = const [];
  bool _byCore = false;
  bool _loading = true;
  bool _offline = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    LocalCache.getJson(_viewKey).then((v) {
      if (mounted && v == 'core') setState(() => _byCore = true);
    });
    _load();
  }

  @override
  void dispose() {
    _habits.dispose();
    _lists.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
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
      final goldenF = _habits.getGoldenHabits(uid);
      final listsF = _lists.getRoutineData(uid);
      // Status only — a failed check-in read leaves rows neutral, not blank.
      final checkinsF = _checkins
          .getRecent(uid, limit: 30)
          .catchError((_) => const <DailyCheckin>[]);
      final golden = await goldenF;
      final lists = await listsF;
      final checkins = await checkinsF;
      if (!mounted) return;
      setState(() {
        _all = mergeAllHabits(
          golden: golden.data,
          routineLists: lists.data.routine,
          nonRoutineLists: lists.data.nonRoutine,
          coreScores: coreScoreSeries(checkins),
        );
        _offline = golden.fromCache || lists.fromCache;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _setByCore(bool v) {
    setState(() => _byCore = v);
    LocalCache.putJson(_viewKey, v ? 'core' : 'time');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: CircularProgressIndicator(color: MM.magenta)),
      );
    }
    final err = _error;
    if (err != null) {
      if (isNetworkError(err)) {
        return OfflineErrorView(onRetry: _load, what: 'your habits');
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(children: [
          Text('Could not load your habits',
              style: MM.display(size: 14, color: Colors.white)),
          const SizedBox(height: 12),
          MMGhostButton(label: 'Retry', onPressed: _load),
        ]),
      );
    }

    final sections =
        _byCore ? groupByCore(_all, _coreTitle) : groupByTime(_all);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_offline) ...[
          OfflineBanner(onRefresh: _load),
          const SizedBox(height: 10),
        ],
        _header(),
        const SizedBox(height: 16),
        if (_all.isEmpty) _empty() else _sections(sections),
      ],
    );
  }

  Widget _header() {
    int n(String s) => _all.where((h) => h.status == s).length;
    final style = MM.body(size: 12, color: Colors.white.withOpacity(0.7));
    Widget count(String status) => Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _dot(_statusColor(status)),
            const SizedBox(width: 5),
            Text('${n(status)}', style: style),
          ]),
        );
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 10,
      spacing: 12,
      children: [
        _Toggle(byCore: _byCore, onChanged: _setByCore),
        Semantics(
          label: '${_all.length} habits: ${n('formed')} formed, '
              '${n('forming')} forming, ${n('bad')} need work',
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('${_all.length} ${_all.length == 1 ? 'HABIT' : 'HABITS'}',
                style: style),
            for (final s in const ['formed', 'forming', 'bad'])
              if (n(s) > 0) count(s),
          ]),
        ),
      ],
    );
  }

  static Color _statusColor(String status) => switch (status) {
        'formed' => MM.teal,
        'forming' => MM.yellow,
        'bad' => MM.red,
        _ => Colors.white.withOpacity(0.35),
      };

  static Widget _dot(Color c) => Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );

  Widget _empty() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          const Text('∞', style: TextStyle(fontSize: 40, color: MM.magenta)),
          const SizedBox(height: 10),
          Text('No habits yet',
              style: MM.display(size: 15, color: Colors.white)),
          const SizedBox(height: 6),
          Text('Forge your first Golden Habit with Nova in Phase 1.',
              textAlign: TextAlign.center,
              style: MM.body(size: 12, color: Colors.white.withOpacity(0.6))),
          const SizedBox(height: 14),
          MMGhostButton(
              label: 'Forge a Golden Habit →',
              onPressed: () => widget.onNav('phase1')),
        ]),
      );

  Widget _sections(List<HabitSection> sections) {
    final panels = [for (final s in sections) _section(s)];
    if (!widget.wide || panels.length < 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final p in panels) ...[p, const SizedBox(height: 14)],
        ],
      );
    }
    // Two columns, filled alternately so both stay in reading order.
    Widget col(int start) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = start; i < panels.length; i += 2) ...[
                panels[i],
                const SizedBox(height: 14),
              ],
            ],
          ),
        );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [col(0), const SizedBox(width: 14), col(1)],
    );
  }

  Widget _section(HabitSection s) {
    final accent = _byCore ? (MM.coreColor[s.id] ?? MM.magenta) : MM.magenta;
    final icon = _byCore ? (_coreIcon[s.id] ?? '•') : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111C4E).withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            if (icon != null) ...[
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
            ],
            Text(s.title.toUpperCase(),
                style: GoogleFonts.orbitron(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: accent)),
            const Spacer(),
            Text('${s.habits.length}',
                style: MM.body(size: 11, color: Colors.white.withOpacity(0.5))),
          ]),
          const SizedBox(height: 8),
          for (final h in s.habits) _row(h),
        ],
      ),
    );
  }

  Widget _row(AllHabit h) {
    final color = _statusColor(h.status);
    final label = switch (h.status) {
      'formed' => 'Formed',
      'forming' => 'Forming',
      'bad' => 'Needs work',
      _ => 'No check-ins yet',
    };
    final p = h.progress;
    // By Time rows name their Core; By Core rows name their time slot.
    final tag = _byCore
        ? kHabitSlotLabel[h.slot]!
        : '${_coreIcon[h.core] ?? ''} ${_coreTitle[h.core] ?? h.core}';
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => widget.onNav(h.isGolden ? 'habits:${h.core}' : 'routines'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5, right: 10),
              child: _dot(color),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: h.name),
                      if (h.flagged) const TextSpan(text: '  ⚠️'),
                    ]),
                    style: MM.body(
                        size: 13, color: Colors.white, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      tag,
                      if (p != null)
                        'Day ${p.days.clamp(0, 14)}/14'
                            '${p.days > 0 ? ' · ${p.pctRounded}%' : ''}'
                      else
                        label,
                    ].join('  ·  '),
                    style: MM.body(
                        size: 11, color: Colors.white.withOpacity(0.55)),
                  ),
                  if (p != null) ...[
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: (p.days / 14).clamp(0.0, 1.0),
                        minHeight: 3,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.byCore, required this.onChanged});
  final bool byCore;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(String text, bool selected, bool value) => Semantics(
          button: true,
          selected: selected,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? MM.magenta.withOpacity(0.22) : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(text,
                  style: GoogleFonts.orbitron(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: selected
                          ? Colors.white
                          : Colors.white.withOpacity(0.5))),
            ),
          ),
        );
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          seg('BY TIME', !byCore, false),
          seg('BY CORE', byCore, true),
        ]),
      ),
    );
  }
}
