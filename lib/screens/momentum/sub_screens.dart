import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/golden_habit.dart';
import '../../models/momentum_list.dart';
import '../../models/core_list.dart';
import '../../services/habits_service.dart';
import '../../services/momentum_lists_service.dart';
import '../../services/core_lists_service.dart';
import '../../services/checkin_service.dart';
import '../../services/onboarding_service.dart';
import '../../theme/momentum_tokens.dart';
import '../../widgets/momentum/glass_panel.dart';
import '../../widgets/momentum/mm_buttons.dart';
import '../../widgets/momentum/offline_banner.dart';
import '../../widgets/momentum/screen_shell.dart';
import '../../services/offline.dart';
import '../../models/cantina_message.dart';
import '../../services/cantina_service.dart';
import 'add_habit_page.dart';

// ─── LISTS ─────────────────────────────────────────────────
class ListsScreen extends StatefulWidget {
  const ListsScreen({
    super.key,
    this.onBack,
    this.onChat,
    this.onNav,
    this.expand = const <String>{},
  });
  final VoidCallback? onBack;
  final VoidCallback? onChat;
  final void Function(String key)? onNav;

  /// List names to pre-expand on open (e.g. deep-linked from the Daily Ritual
  /// "View Your Mantra" / "View Grateful List" buttons).
  final Set<String> expand;

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  final _service = MomentumListsService();
  List<MomentumList> _lists = const [];
  late final Set<String> _expanded = {...widget.expand};
  bool _loading = true;
  bool _offline = false;
  bool _errorOffline = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
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
      final result = await _service.getAllLists(uid);
      if (!mounted) return;
      setState(() {
        _lists = result.data;
        _offline = result.fromCache;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _errorOffline = isNetworkError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: 'Lists',
      subtitle: 'MANIFEST · ${_lists.length}',
      accent: MM.blue,
      onBack: widget.onBack,
      onChat: widget.onChat,
      onNav: widget.onNav,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: MM.blue)),
      );
    }
    if (_error != null) {
      if (_errorOffline) {
        return OfflineErrorView(onRetry: _load, what: 'your lists');
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text('Could not load lists',
                style: MM.display(size: 14, color: Colors.white)),
            const SizedBox(height: 6),
            Text('Something went wrong. Please try again.',
                textAlign: TextAlign.center,
                style:
                    MM.body(color: Colors.white.withOpacity(0.6), size: 12)),
            const SizedBox(height: 14),
            MMGhostButton(label: 'Retry', onPressed: _load),
          ],
        ),
      );
    }
    return Column(
      children: [
        if (_offline) OfflineBanner(onRefresh: _load),
        if (_lists.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Text('No Momentum Lists yet',
                    style: MM.display(size: 14, color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                  'Lists are created automatically as you go through onboarding with the AI.',
                  textAlign: TextAlign.center,
                  style:
                      MM.body(color: Colors.white.withOpacity(0.55), size: 12),
                ),
              ],
            ),
          )
        else
          for (final l in _lists) ...[
            _ListTile(
              list: l,
              expanded: _expanded.contains(l.name),
              onToggle: () => setState(() {
                if (!_expanded.add(l.name)) _expanded.remove(l.name);
              }),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _ListTile extends StatelessWidget {
  const _ListTile({
    required this.list,
    required this.expanded,
    required this.onToggle,
  });
  final MomentumList list;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        leftAccentColor: MM.blue,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              _CoreDot(color: MM.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  list.name,
                  style: MM.body(
                      color: Colors.white,
                      size: 14,
                      weight: FontWeight.w600),
                ),
              ),
              MMChip(label: '${list.count}', color: MM.blue),
              const SizedBox(width: 6),
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.white.withOpacity(0.5),
                size: 18,
              ),
            ]),
            if (expanded) ...[
              const SizedBox(height: 10),
              ...list.items.map((item) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6, right: 8),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: MM.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item,
                            style: MM.body(color: Colors.white, size: 12),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── ROUTINES ──────────────────────────────────────────────
// New design (Claude / screens.jsx RoutinesScreen):
//   • ROUTINE       → the daily schedule. Grouped BY TIME (parsed from each
//     stored line) or BY CORE. Lifecycle 🔴→🟠→🟢 ("the sea of green").
//   • NON-ROUTINE   → identity habits. When formed (14d · 80%) they graduate
//     to the Trophy Room.
// Backend (`fetchAllCoreListItems`) stores only flat item STRINGS per core, so
// the time-block / cue subtags are parsed out of the line on-device, and the
// lifecycle stage (not stored anywhere yet) defaults to neutral but is editable.

/// One of the three time-of-day buckets the routine schedule clusters into.
class _TimeBlock {
  const _TimeBlock(this.id, this.name, this.label, this.time);
  final String id;
  final String name;
  final String label;
  final String time;
}

const List<_TimeBlock> _timeBlocks = [
  _TimeBlock('morning', 'Launch Sequence', 'MORNING', '06:30'),
  _TimeBlock('workday', 'Deep Work Block', 'WORKDAY', '09:00'),
  _TimeBlock('evening', 'Re-entry', 'EVENING', '21:00'),
];
const _TimeBlock _anytimeBlock =
    _TimeBlock('anytime', 'Unscheduled', 'ANYTIME', '');

/// keyword → block id. Only short, unambiguous tokens map a block.
const Map<String, String> _blockKeywords = {
  'morning': 'morning', 'dawn': 'morning', 'am': 'morning',
  'launch': 'morning', 'wake': 'morning', 'sunrise': 'morning',
  'afternoon': 'workday', 'midday': 'workday', 'noon': 'workday',
  'workday': 'workday', 'work': 'workday', 'day': 'workday',
  'evening': 'evening', 'night': 'evening', 'pm': 'evening',
  'bedtime': 'evening', 'reentry': 'evening', 're-entry': 'evening',
  'dusk': 'evening', 'sunset': 'evening',
};

/// Lifecycle stage for a routine (color transformation — the sea of green).
class _RoutineStage {
  const _RoutineStage(this.id, this.color, this.label);
  final String id;
  final Color color;
  final String label;
}

const Map<String, _RoutineStage> _routineStages = {
  'bad': _RoutineStage('bad', MM.red, 'Bad'),
  'forming': _RoutineStage('forming', MM.yellow, 'Forming'),
  'formed': _RoutineStage('formed', MM.teal, 'Formed'),
};

const Map<String, String> _coreIcon = {
  'mindset_core': '🧠',
  'career_finance_core': '💰',
  'relationships_core': '👥',
  'physical_health_core': '💪',
  'emotional_mental_core': '🧘',
};

const Map<String, String> _coreShort = {
  'mindset_core': 'Mindset',
  'career_finance_core': 'Career',
  'relationships_core': 'Relationships',
  'physical_health_core': 'Physical',
  'emotional_mental_core': 'Emotional',
};

/// Full backend coreId → the SHORT id the daily check-in scores are keyed by.
const Map<String, String> _coreShortId = {
  'mindset_core': 'mindset',
  'career_finance_core': 'career',
  'relationships_core': 'relationships',
  'physical_health_core': 'physical',
  'emotional_mental_core': 'emotional',
};

/// A single habit parsed from a stored Routines List / Non-Routine line.
/// `stage` is local-only (no backend source yet) and editable by the player.
class _RoutineHabit {
  _RoutineHabit({
    required this.raw,
    required this.name,
    required this.coreId,
    required this.coreLabel,
    this.blockId,
    this.cue,
  });

  final String raw;
  String name;
  final String coreId;
  final String coreLabel;
  String? blockId; // null → Anytime
  String? cue;
  String? stage; // null → neutral (no backend source yet; set in edit sheet)

  /// Splits a stored line into {block, cue, name}. Accepts the recommended
  /// `Block · Habit · cue` convention (delimiter `·` or `|`) and falls back to
  /// scanning a plain line for an embedded time-of-day keyword.
  static _RoutineHabit parse(String raw, String coreId, String coreLabel) {
    final tokens = raw
        .split(RegExp(r'\s*[·|]\s*'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    String? blockId;
    String? cue;
    final nameParts = <String>[];
    for (final t in tokens) {
      final key = t.toLowerCase();
      if (blockId == null &&
          _blockKeywords.containsKey(key) &&
          t.split(' ').length <= 2) {
        blockId = _blockKeywords[key];
        continue;
      }
      if (cue == null && RegExp(r'^(after|before|when|during|once)\b',
              caseSensitive: false).hasMatch(t)) {
        cue = t;
        continue;
      }
      nameParts.add(t);
    }
    var name = nameParts.join(' · ');
    if (name.isEmpty) name = raw;
    // Fallback: a strong block keyword sitting inside the habit name.
    blockId ??= _scanForBlock(name);
    return _RoutineHabit(
      raw: raw,
      name: name,
      coreId: coreId,
      coreLabel: coreLabel,
      blockId: blockId,
      cue: cue,
    );
  }

  static String? _scanForBlock(String text) {
    for (final w in text.toLowerCase().split(RegExp(r'[^a-z]+'))) {
      // Only the unambiguous time words — avoid matching "work"/"day".
      if (const {'morning', 'afternoon', 'evening', 'night'}.contains(w)) {
        return _blockKeywords[w];
      }
    }
    return null;
  }
}

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key, this.onBack, this.onChat, this.onNav});
  final VoidCallback? onBack;
  final VoidCallback? onChat;
  final void Function(String key)? onNav;

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  final _service = CoreListsService();
  final _checkin = CheckinService();
  final _habitsSvc = HabitsService();
  List<_RoutineHabit> _routine = const [];
  List<_RoutineHabit> _nonRoutine = const [];
  bool _loading = true;
  bool _offline = false;
  bool _errorOffline = false;
  String? _error;
  String _view = 'time'; // time | core
  bool _hasStageData = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    _habitsSvc.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
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
      final result = await _service.getRoutineData(uid);
      final data = result.data;
      // Real lifecycle source: recent per-Core check-in scores (Spec §8).
      // A check-in fetch failure must not blank the list — fall back to neutral.
      List<DailyCheckin> checkins = const [];
      try {
        checkins = await _checkin.getRecent(uid, limit: 30);
      } catch (_) {}
      final byCore = _coreScoreSeries(checkins);
      if (!mounted) return;
      setState(() {
        _routine = _expand(data.routine, byCore);
        _nonRoutine = _expand(data.nonRoutine, byCore);
        _hasStageData = byCore.isNotEmpty;
        _offline = result.fromCache;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _errorOffline = isNetworkError(e);
        _loading = false;
      });
    }
  }

  /// Builds shortCoreId → daily scores (most-recent first) from check-ins,
  /// which already arrive ordered newest→oldest.
  Map<String, List<int>> _coreScoreSeries(List<DailyCheckin> checkins) {
    final byCore = <String, List<int>>{};
    for (final c in checkins) {
      c.scores.forEach((coreShort, v) {
        byCore.putIfAbsent(coreShort, () => []).add(v);
      });
    }
    return byCore;
  }

  List<_RoutineHabit> _expand(
          List<CoreList> lists, Map<String, List<int>> byCore) =>
      [
        for (final l in lists)
          for (final item in l.items)
            _RoutineHabit.parse(item, l.coreId, l.coreLabel)
              ..stage = deriveRoutineStage(
                  byCore[_coreShortId[l.coreId]] ?? const []),
      ];

  int get _total => _routine.length + _nonRoutine.length;

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: 'Routines',
      subtitle: 'FULL ROUTINES LIST · $_total',
      accent: MM.teal,
      onBack: widget.onBack,
      onChat: widget.onChat,
      onNav: widget.onNav,
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: MM.teal)),
      );
    }
    if (_error != null) {
      if (_errorOffline) {
        return OfflineErrorView(onRetry: _load, what: 'your routines');
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text('Could not load routines',
                style: MM.display(size: 14, color: Colors.white)),
            const SizedBox(height: 6),
            Text('Something went wrong. Please try again.',
                textAlign: TextAlign.center,
                style: MM.body(color: Colors.white.withOpacity(0.6), size: 12)),
            const SizedBox(height: 14),
            MMGhostButton(label: 'Retry', onPressed: _load),
          ],
        ),
      );
    }
    if (_total == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Text('No Routines yet',
                style: MM.display(size: 14, color: Colors.white)),
            const SizedBox(height: 6),
            Text(
              'Habits you forge with the Co-pilot land here — Routines on your '
              'daily schedule, Non-Routines as identity habits.',
              textAlign: TextAlign.center,
              style: MM.body(color: Colors.white.withOpacity(0.55), size: 12),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_offline) OfflineBanner(onRefresh: _load),
        // Control bar: organisation toggle + forge (Co-pilot) action.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SegToggle(
              value: _view,
              onChange: (v) => setState(() => _view = v),
              options: const [
                MapEntry('time', 'BY TIME'),
                MapEntry('core', 'BY CORE'),
              ],
            ),
            InkWell(
              onTap: _addHabit,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF00C9A7), MM.teal],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: MM.teal.withOpacity(0.6)),
                  boxShadow: [
                    BoxShadow(color: MM.teal.withOpacity(0.45), blurRadius: 14)
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add, size: 14, color: Color(0xFF04130F)),
                  const SizedBox(width: 5),
                  Text('ADD',
                      style: MM.display(
                          size: 11,
                          color: const Color(0xFF04130F),
                          weight: FontWeight.w700,
                          letterSpacing: 11 * 0.1)),
                ]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── ROUTINE section ──
        _sectionHeader(
          'ROUTINE',
          _hasStageData
              ? '${_routine.where((h) => h.stage == 'formed').length}/${_routine.length} GREEN'
              : '${_routine.length} HABITS',
          MM.teal,
        ),
        const SizedBox(height: 10),
        if (_routine.isEmpty)
          _emptyNote('No scheduled routines yet.')
        else
          ..._buildRoutineGroups(),

        // ── NON-ROUTINE section ──
        const SizedBox(height: 22),
        _sectionHeader('NON-ROUTINE', 'IDENTITY HABITS', null),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            'Active in your daily check-in. When formed (14d · 80%) they '
            'graduate to the Trophy Room.',
            style: MM.body(color: Colors.white.withOpacity(0.6), size: 11),
          ),
        ),
        const SizedBox(height: 12),
        if (_nonRoutine.isEmpty)
          _emptyNote('No identity habits yet.')
        else
          ..._nonRoutine.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _RoutineRow(habit: h, onTap: () => _edit(h)),
              )),

        // Trophy Room link.
        const SizedBox(height: 10),
        InkWell(
          onTap: () => widget.onNav?.call('trophy'),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [MM.yellow.withOpacity(0.14), Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: MM.yellow.withOpacity(0.4)),
            ),
            child: Row(children: [
              const Text('🏆', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Formed identity habits → Trophy Room',
                        style: MM.body(
                            color: Colors.white,
                            size: 12.5,
                            weight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Permanent identity markers, by Core',
                        style: MM.body(
                            color: Colors.white.withOpacity(0.6), size: 10.5)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: MM.yellow, size: 18),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'TAP ANY HABIT TO EDIT · STAGE & TIME ARE YOURS TO SET',
            textAlign: TextAlign.center,
            style: MM.displayX(size: 9, color: Colors.white.withOpacity(0.35)),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRoutineGroups() {
    final widgets = <Widget>[];
    if (_view == 'time') {
      final blocks = [..._timeBlocks, _anytimeBlock];
      for (final b in blocks) {
        final items = _routine.where((h) {
          final id = h.blockId ?? 'anytime';
          return id == b.id;
        }).toList();
        if (items.isEmpty) continue;
        widgets.add(_groupHeader(
          b.name,
          b.time.isEmpty ? b.label : '${b.label} · ${b.time}',
          MM.teal,
        ));
        widgets.addAll(items.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _RoutineRow(habit: h, onTap: () => _edit(h)),
            )));
        widgets.add(const SizedBox(height: 12));
      }
    } else {
      // BY CORE — group by the real coreId from the backend.
      final byCore = <String, List<_RoutineHabit>>{};
      for (final h in _routine) {
        byCore.putIfAbsent(h.coreId, () => []).add(h);
      }
      byCore.forEach((coreId, items) {
        final icon = _coreIcon[coreId] ?? '✦';
        final label = _coreShort[coreId] ?? items.first.coreLabel;
        widgets.add(_groupHeader(
            '$icon $label', 'CORE', _coreHex[coreId] ?? MM.teal));
        widgets.addAll(items.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _RoutineRow(habit: h, onTap: () => _edit(h)),
            )));
        widgets.add(const SizedBox(height: 12));
      });
    }
    return widgets;
  }

  Widget _sectionHeader(String title, String meta, Color? metaColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title, style: MM.displayX(size: 10, color: Colors.white)),
          Text(meta,
              style: MM.displayX(
                  size: 9, color: metaColor ?? Colors.white.withOpacity(0.45))),
        ],
      ),
    );
  }

  Widget _groupHeader(String title, String meta, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Flexible(
          child: Text(title,
              overflow: TextOverflow.ellipsis,
              style: MM.displayX(size: 9, color: accent)),
        ),
        const SizedBox(width: 8),
        Text('· $meta',
            style:
                MM.displayX(size: 9, color: Colors.white.withOpacity(0.45))),
      ]),
    );
  }

  Widget _emptyNote(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Text(text,
            style: MM.body(color: Colors.white.withOpacity(0.45), size: 11)),
      );

  /// Opens the dedicated "Add a habit" page and, on save, PERSISTS the new
  /// habit to the per-core list via `saveCoreListItems` so it's trackable in
  /// future sessions (and feeds the stage pipeline). On success the list is
  /// re-fetched so the habit appears exactly as stored.
  Future<void> _addHabit() async {
    final draft = await Navigator.of(context).push<NewHabitDraft>(
      MaterialPageRoute(builder: (_) => const AddHabitPage()),
    );
    if (draft == null || !mounted) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      _toast('Not signed in — could not save habit', error: true);
      return;
    }

    // Compose the stored line. For routines, prefix the time block as a `·`
    // subtag so it round-trips through `_RoutineHabit.parse` on the next read.
    final line = draft.isRoutine && draft.blockId != null
        ? '${_blockLabel(draft.blockId!)} · ${draft.name}'
        : draft.name;

    _toast('Saving ${draft.name}…');
    try {
      // Dual-write, mirroring the Voiceflow HHS so the habit shows in BOTH
      // screens: the per-core list (Routines screen) AND the structured
      // golden_habits object (Habits screen). A routine IS a Golden Habit.
      await _service.addHabit(
        userId: uid,
        coreId: draft.coreId,
        isRoutine: draft.isRoutine,
        itemLine: line,
      );
      await _habitsSvc.addGoldenHabit(
        userId: uid,
        coreId: draft.coreId,
        habitName: draft.name,
        isRoutine: draft.isRoutine,
        when: draft.isRoutine ? _blockLabel(draft.blockId ?? '') : null,
      );
    } catch (e) {
      if (mounted) _toast(friendlyError(e, action: 'save your habit'), error: true);
      return;
    }
    if (!mounted) return;
    await _load(); // re-fetch so the new habit shows with its derived stage
    if (!mounted) return;
    _toast(draft.isRoutine
        ? 'Routine saved to ${_blockLabel(draft.blockId ?? '').toLowerCase()}'
        : 'Non-routine saved to your daily check-in');
  }

  String _blockLabel(String id) {
    switch (id) {
      case 'morning':
        return 'Morning';
      case 'workday':
        return 'Workday';
      case 'evening':
        return 'Evening';
      default:
        return id.isEmpty ? 'Anytime' : id[0].toUpperCase() + id.substring(1);
    }
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: MM.body(color: Colors.white, size: 12)),
      backgroundColor: (error ? MM.red : MM.teal).withOpacity(0.92),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: error ? 4 : 2),
    ));
  }

  Future<void> _edit(_RoutineHabit h) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _RoutineEditSheet(habit: h),
    );
    if (changed == true && mounted) setState(() {});
  }
}

/// Pill segmented toggle (BY TIME / BY CORE).
class _SegToggle extends StatelessWidget {
  const _SegToggle({
    required this.value,
    required this.onChange,
    required this.options,
  });
  final String value;
  final ValueChanged<String> onChange;
  final List<MapEntry<String, String>> options;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: MM.navy.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((o) {
          final on = value == o.key;
          return InkWell(
            onTap: () => onChange(o.key),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
              decoration: BoxDecoration(
                color: on ? MM.teal : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                o.value,
                style: MM.display(
                  size: 10,
                  color: on ? const Color(0xFF04130F) : MM.white60,
                  weight: FontWeight.w700,
                  letterSpacing: 10 * 0.12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// One row in the Full Routines List.
class _RoutineRow extends StatelessWidget {
  const _RoutineRow({required this.habit, required this.onTap});
  final _RoutineHabit habit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final core = _coreHex[habit.coreId] ?? MM.teal;
    final stage = habit.stage == null ? null : _routineStages[habit.stage];
    final formed = habit.stage == 'formed';
    final dotColor = stage?.color ?? Colors.white.withOpacity(0.32);
    final icon = _coreIcon[habit.coreId] ?? '✦';
    final coreLabel = _coreShort[habit.coreId] ?? habit.coreLabel;
    final sub = habit.cue ??
        (stage != null
            ? '${stage.label.toUpperCase()}${formed ? ' · GREEN' : ''}'
            : null);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: formed
              ? MM.teal.withOpacity(0.14)
              : MM.navy.withOpacity(0.40),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: formed
                ? MM.teal.withOpacity(0.5)
                : Colors.white.withOpacity(0.10),
          ),
        ),
        child: Row(children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
              boxShadow: stage == null
                  ? null
                  : [BoxShadow(color: dotColor, blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MM.body(
                    color: formed ? Colors.white : Colors.white.withOpacity(0.9),
                    size: 13,
                    weight: formed ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MM.displayX(
                        size: 8.5, color: (stage?.color ?? MM.white60)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: core.withOpacity(0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: core.withOpacity(0.30)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(icon, style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 5),
              Text(coreLabel.toUpperCase(),
                  style: MM.displayX(size: 8.5, color: core)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Bottom sheet to correct the parsed parts of a habit and set its stage.
/// Edits are applied to the in-session model (the player can modify); they do
/// not yet write back to Firestore (Voiceflow owns the save path).
class _RoutineEditSheet extends StatefulWidget {
  const _RoutineEditSheet({required this.habit});
  final _RoutineHabit habit;
  @override
  State<_RoutineEditSheet> createState() => _RoutineEditSheetState();
}

class _RoutineEditSheetState extends State<_RoutineEditSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.habit.name);
  late final TextEditingController _cue =
      TextEditingController(text: widget.habit.cue ?? '');
  late String? _blockId = widget.habit.blockId;
  late String? _stage = widget.habit.stage;

  @override
  void dispose() {
    _name.dispose();
    _cue.dispose();
    super.dispose();
  }

  void _save() {
    final h = widget.habit;
    h.name = _name.text.trim().isEmpty ? h.name : _name.text.trim();
    h.cue = _cue.text.trim().isEmpty ? null : _cue.text.trim();
    h.blockId = _blockId;
    h.stage = _stage;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final hex = _coreHex[widget.habit.coreId] ?? MM.teal;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
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
            Text('EDIT HABIT', style: MM.displayX(size: 12, color: hex)),
            const SizedBox(height: 14),
            _fieldLabel('HABIT NAME'),
            _textField(_name, hex, 'Habit name'),
            const SizedBox(height: 12),
            _fieldLabel('WHEN · TIME BLOCK'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final b in _timeBlocks)
                _choiceChip(b.label, _blockId == b.id, MM.teal,
                    () => setState(() => _blockId = b.id)),
              _choiceChip('ANYTIME', _blockId == null, MM.teal,
                  () => setState(() => _blockId = null)),
            ]),
            const SizedBox(height: 12),
            _fieldLabel('STAGE'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in _routineStages.values)
                _choiceChip(s.label.toUpperCase(), _stage == s.id, s.color,
                    () => setState(() => _stage = s.id)),
              _choiceChip('NONE', _stage == null, Colors.white54,
                  () => setState(() => _stage = null)),
            ]),
            const SizedBox(height: 12),
            _fieldLabel('CUE / ANCHOR (optional)'),
            _textField(_cue, hex, 'e.g. after coffee'),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: MMGhostButton(
                  label: 'Cancel',
                  expand: true,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MMPrimaryButton(
                  label: 'Save',
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  onPressed: _save,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: MM.displayX(size: 9, color: Colors.white.withOpacity(0.55))),
      );

  Widget _textField(TextEditingController c, Color hex, String hint) {
    return TextField(
      controller: c,
      style: MM.body(color: Colors.white, size: 13),
      cursorColor: hex,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: MM.body(color: Colors.white.withOpacity(0.35), size: 13),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        filled: true,
        fillColor: MM.navy.withOpacity(0.55),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: hex.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: hex),
        ),
      ),
    );
  }

  Widget _choiceChip(String label, bool on, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: on ? color.withOpacity(0.18) : MM.navy.withOpacity(0.45),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: on ? color : Colors.white.withOpacity(0.12),
            width: on ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: MM.displayX(
              size: 9, color: on ? Colors.white : Colors.white.withOpacity(0.7)),
        ),
      ),
    );
  }
}

// ─── HABITS ────────────────────────────────────────────────
const _coreHex = {
  'mindset_core': MM.blue,
  'career_finance_core': MM.yellow,
  'relationships_core': MM.magenta,
  'physical_health_core': MM.teal,
  'emotional_mental_core': MM.violet,
};

const _stageDefs = {
  'bad': _Stage(MM.red, 'Bad'),
  'forming': _Stage(MM.yellow, 'Forming'),
  'mbms': _Stage(MM.blue, 'MBMs attached'),
  'formed': _Stage(MM.teal, 'Formed'),
  'trophy': _Stage(MM.yellow, 'Trophy'),
};

class _Stage {
  const _Stage(this.color, this.label);
  final Color color;
  final String label;
}

// Golden Habits are fetched live from the backend (see GoldenHabit /
// HabitsService); they used to be a hardcoded _mockHabits list here.

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key, this.onBack, this.onChat, this.onNav});
  final VoidCallback? onBack;
  final VoidCallback? onChat;
  final void Function(String key)? onNav;

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final _svc = HabitsService();
  List<GoldenHabit> _habits = const [];
  bool _loading = true;
  bool _offline = false;
  bool _errorOffline = false;
  String? _error;
  String? _openId;
  String _uid = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _svc.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Not signed in';
      });
      return;
    }
    _uid = uid;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _svc.getGoldenHabits(uid);
      debugPrint('[Habits] uid=$uid fetched ${result.data.length} golden '
          'habits (offline=${result.fromCache})');
      if (!mounted) return;
      setState(() {
        _habits = result.data;
        _offline = result.fromCache;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[Habits] uid=$uid fetch FAILED: $e');
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _errorOffline = isNetworkError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_openId != null && _habits.any((h) => h.habitId == _openId)) {
      final open = _habits.firstWhere((h) => h.habitId == _openId);
      return _HabitDetail(
        h: open,
        svc: _svc,
        userId: _uid,
        onBack: () => setState(() => _openId = null),
        onChanged: (updated) => setState(() {
          _habits = [
            for (final h in _habits)
              h.habitId == updated.habitId ? updated : h,
          ];
        }),
      );
    }
    return ScreenShell(
      title: 'Habits',
      subtitle: 'GOLDEN HABITS · ${_habits.length}',
      accent: MM.magenta,
      onBack: widget.onBack,
      onChat: widget.onChat,
      onNav: widget.onNav,
      child: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(MM.magenta))),
      );
    }
    if (_error != null) {
      if (_errorOffline) {
        return OfflineErrorView(onRetry: _fetch, what: 'your Golden Habits');
      }
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(Icons.cloud_off, color: Colors.white.withOpacity(0.5), size: 40),
            const SizedBox(height: 12),
            Text("Couldn't load your Golden Habits",
                textAlign: TextAlign.center,
                style: MM.body(color: Colors.white, size: 13)),
            const SizedBox(height: 6),
            Text('Something went wrong. Please try again.',
                textAlign: TextAlign.center,
                style: MM.body(color: Colors.white.withOpacity(0.45), size: 11)),
            const SizedBox(height: 16),
            MMGhostButton(label: 'Retry', onPressed: _fetch),
          ],
        ),
      );
    }
    return Column(
      children: [
        if (_offline) OfflineBanner(onRefresh: _fetch),
        if (_habits.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Text('🏆', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 12),
                Text('No Golden Habits yet',
                    style: MM.display(size: 16, color: Colors.white)),
                const SizedBox(height: 8),
                SizedBox(
                  width: 250,
                  child: Text(
                    'Forge your first one with the Co-pilot in Phase 1.',
                    textAlign: TextAlign.center,
                    style: MM.body(color: Colors.white.withOpacity(0.6), size: 12),
                  ),
                ),
                const SizedBox(height: 14),
                // Diagnostic: which account we queried. Remove once confirmed.
                Text('signed in as: $_uid',
                    textAlign: TextAlign.center,
                    style: MM.mono(
                        size: 9, color: Colors.white.withOpacity(0.35))),
              ],
            ),
          )
        else
          ..._habits.map((h) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _HabitCard(
                  h: h,
                  onOpen: () => setState(() => _openId = h.habitId),
                ),
              )),
        const SizedBox(height: 6),
        MMGhostButton(
          label: '+ Forge new Golden Habit',
          expand: true,
          padding: const EdgeInsets.symmetric(vertical: 14),
          onPressed: () => widget.onChat?.call(),
        ),
        const SizedBox(height: 6),
        Text(
          'POWERED BY GOLDEN HABIT FORGE (PHASE 1)',
          style: MM.display(
            size: 10,
            color: Colors.white.withOpacity(0.4),
            letterSpacing: 10 * 0.16,
          ),
        ),
      ],
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({required this.h, required this.onOpen});
  final GoldenHabit h;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final hex = _coreHex[h.coreId] ?? Colors.white;
    final stage = _stageDefs[h.stage] ?? _stageDefs['forming']!;
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(8),
      child: GlassPanel(
        leftAccentColor: hex,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _CoreDot(color: stage.color, size: 8),
                        const SizedBox(width: 6),
                        Text(stage.label.toUpperCase(),
                            style: MM.displayX(size: 9, color: stage.color)),
                        const SizedBox(width: 6),
                        Text(
                            '· ${(h.habitType == 'routine' ? 'ROUTINE' : 'NON-ROUTINE')}',
                            style: MM.displayX(
                                size: 9,
                                color: Colors.white.withOpacity(0.4))),
                      ]),
                      const SizedBox(height: 4),
                      Text(h.habitName,
                          style: MM.body(
                              color: Colors.white,
                              size: 14,
                              weight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(h.coreLabel.toUpperCase(),
                          style: MM.display(
                              size: 10,
                              color: hex,
                              letterSpacing: 10 * 0.1)),
                    ],
                  ),
                ),
                Text('${h.streak}🔥',
                    style: MM.display(size: 14, color: hex)),
              ],
            ),
            const SizedBox(height: 10),
            Text(h.what,
                style: MM.body(
                    color: Colors.white.withOpacity(0.7), size: 12)),
            const SizedBox(height: 10),
            Row(
              children: List.generate(7, (i) {
                final on = h.week[i] == 1;
                return Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      margin: EdgeInsets.only(right: i < 6 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: on ? hex : Colors.white.withOpacity(0.05),
                        border: Border.all(
                            color: on
                                ? hex
                                : Colors.white.withOpacity(0.08)),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: on
                            ? [
                                BoxShadow(
                                    color: hex.withOpacity(0.33),
                                    blurRadius: 6)
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          dayLabels[i],
                          style: MM.display(
                            size: 7,
                            color: on
                                ? Colors.black
                                : Colors.white.withOpacity(0.35),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitDetail extends StatefulWidget {
  const _HabitDetail({
    required this.h,
    required this.svc,
    required this.userId,
    required this.onBack,
    required this.onChanged,
  });
  final GoldenHabit h;
  final HabitsService svc;
  final String userId;
  final VoidCallback onBack;

  /// Called with the locally-updated habit after a successful edit / flag so
  /// the parent list reflects the change without a refetch.
  final ValueChanged<GoldenHabit> onChanged;

  @override
  State<_HabitDetail> createState() => _HabitDetailState();
}

class _HabitDetailState extends State<_HabitDetail> {
  bool _saving = false;

  // Getters keep the existing build body (which reads `h` / `onBack`) intact.
  GoldenHabit get h => widget.h;
  VoidCallback get onBack => widget.onBack;

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: MM.body(color: Colors.white, size: 12)),
      backgroundColor: (error ? MM.red : MM.teal).withOpacity(0.92),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: error ? 4 : 2),
    ));
  }

  /// Edit: lets the player tweak the core mechanics (name / what / where / when
  /// / cue / IF-THEN / MVA). Persisted via `saveGoldenHabit` which rewrites the
  /// whole doc, so [HabitsService.updateGoldenHabit] sends every field from the
  /// edited copy — the Forge-authored context (pain point, BTTF, why) is carried
  /// through untouched.
  Future<void> _openEdit() async {
    final updated = await showModalBottomSheet<GoldenHabit>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _HabitEditSheet(habit: h),
    );
    if (updated == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await widget.svc.updateGoldenHabit(userId: widget.userId, habit: updated);
      widget.onChanged(updated);
      _toast('Habit updated');
    } catch (e) {
      _toast("Couldn't save — check your connection", error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Flag (anti-shame): manual flag for refinement, per Product Design Rationale
  /// C4. "Flagging is data, not failure" — the reason/note give the Co-pilot
  /// something to pattern-match. The Go-Deeper intervention (C5 Path A/B) is
  /// Phase 2 and not built here. Persisted via the isolated
  /// `flutterFlagGoldenHabit` endpoint.
  Future<void> _openFlag() async {
    final result = await showModalBottomSheet<_FlagResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _HabitFlagSheet(habit: h),
    );
    if (result == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await widget.svc.flagGoldenHabit(
        userId: widget.userId,
        habitId: h.habitId,
        flagged: result.flagged,
        reason: result.reason,
        note: result.note,
      );
      widget.onChanged(h.copyWith(
        flagged: result.flagged,
        flagReason: result.flagged ? result.reason : '',
        flagNote: result.flagged ? result.note : '',
      ));
      _toast(result.flagged
          ? "Flagged — that's data, not failure"
          : 'Flag removed');
    } catch (e) {
      _toast("Couldn't update flag — check your connection", error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hex = _coreHex[h.coreId] ?? Colors.white;
    final stage = _stageDefs[h.stage] ?? _stageDefs['forming']!;
    const formedThreshold = 14;
    final pct = math.min(100, (h.daysFormed / formedThreshold * 100).round());

    return ScreenShell(
      title: h.habitName,
      subtitle:
          '${h.coreLabel.toUpperCase()} · ${h.coreDimension.toUpperCase()}',
      accent: hex,
      onBack: onBack,
      hideNav: true,
      child: Column(
        children: [
          Row(children: [
            _CoreDot(color: stage.color, size: 8),
            const SizedBox(width: 6),
            Text(stage.label.toUpperCase(),
                style: MM.displayX(size: 10, color: stage.color)),
            const SizedBox(width: 6),
            Text('· ${(h.habitType == 'routine' ? 'ROUTINE' : 'NON-ROUTINE')}',
                style: MM.displayX(
                    size: 10, color: Colors.white.withOpacity(0.5))),
            const Spacer(),
            Text('${h.streak}🔥',
                style: MM.display(size: 20, color: hex)),
          ]),
          if (h.flagged) ...[
            const SizedBox(height: 10),
            GlassPanel(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              leftAccentColor: MM.yellow,
              background: BoxDecoration(
                color: MM.yellow.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⚠', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FLAGGED FOR REFINEMENT',
                            style: MM.displayX(size: 9, color: MM.yellow)),
                        if (h.flagReason.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(h.flagReason,
                              style:
                                  MM.body(color: Colors.white, size: 12)),
                        ],
                        if (h.flagNote.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(h.flagNote,
                              style: MM.body(
                                  color: Colors.white.withOpacity(0.6),
                                  size: 11)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          GlassPanel(
            margin: const EdgeInsets.only(bottom: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            leftAccentColor: hex,
            background: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [hex.withOpacity(0.08), Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PROGRESS TO FORMED',
                        style: MM.displayX(
                            size: 10,
                            color: Colors.white.withOpacity(0.65))),
                    Text('${h.daysFormed} / $formedThreshold d',
                        style: MM.display(size: 12, color: hex)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: pct / 100,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation(hex),
                  ),
                ),
              ],
            ),
          ),
          _Section(
            label: 'BTTF VISION',
            color: hex,
            child: Text('"${h.backToFutureIdentity}"',
                style: MM
                    .body(color: Colors.white, size: 13)
                    .copyWith(fontStyle: FontStyle.italic)),
          ),
          _Section(
            label: 'PAIN POINT',
            color: MM.red.withOpacity(0.7),
            child: Text(h.painPoint,
                style: MM.body(color: Colors.white.withOpacity(0.85))),
          ),
          _Section(
            label: 'THE HABIT',
            color: hex,
            child: Column(
              children: [
                _KV(k: 'WHAT', v: h.what),
                _KV(k: 'WHERE', v: h.where),
                _KV(k: 'WHEN', v: h.when),
              ],
            ),
          ),
          _Section(
            label: 'CUE',
            color: MM.blue,
            child: Column(
              children: [
                _KV(k: 'TRIGGER', v: h.trigger),
                _KV(k: 'ANCHOR', v: h.anchorReminder),
              ],
            ),
          ),
          _Section(
            label: 'IF · THEN OBSTACLE PLAN',
            color: MM.yellow,
            child: Column(
              children: [
                _KV(k: 'IF', v: h.obstacleIf),
                _KV(k: 'THEN', v: h.obstacleThen),
              ],
            ),
          ),
          _Section(
            label: 'WHY IT WORKS',
            color: MM.magenta,
            child: Column(
              children: [
                _KV(k: 'WANT IT', v: h.whyWant),
                _KV(k: 'CAN DO IT', v: h.whyCan),
                _KV(k: 'EFFECTIVE', v: h.whyEffective),
              ],
            ),
          ),
          _Section(
            label: 'STARTING VERSION (MVA)',
            color: MM.teal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.startingVersion,
                    style: MM.body(color: Colors.white, size: 13)),
                const SizedBox(height: 6),
                Text(
                  'Fall back to this when friction is high. Non-zero beats perfect.',
                  style: MM.body(
                      color: Colors.white.withOpacity(0.5), size: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: MMGhostButton(
                label: 'Edit',
                expand: true,
                color: hex,
                borderColor: hex.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: _saving ? null : _openEdit,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MMGhostButton(
                label: h.flagged ? '⚑ Flagged' : '⚠ Flag',
                expand: true,
                color: MM.yellow,
                borderColor: MM.yellow.withOpacity(h.flagged ? 0.9 : 0.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: _saving ? null : _openFlag,
              ),
            ),
          ]),
          if (_saving) ...[
            const SizedBox(height: 12),
            const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(MM.teal)),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Bottom sheet to edit the core mechanics of a Golden Habit. Pops the edited
/// [GoldenHabit] (via `copyWith`) on save, or null on cancel. The network write
/// is done by the caller so it can show a busy / error state.
class _HabitEditSheet extends StatefulWidget {
  const _HabitEditSheet({required this.habit});
  final GoldenHabit habit;
  @override
  State<_HabitEditSheet> createState() => _HabitEditSheetState();
}

class _HabitEditSheetState extends State<_HabitEditSheet> {
  late final _name = TextEditingController(text: widget.habit.habitName);
  late final _what = TextEditingController(text: widget.habit.what);
  late final _where = TextEditingController(text: widget.habit.where);
  late final _when = TextEditingController(text: widget.habit.when);
  late final _trigger = TextEditingController(text: widget.habit.trigger);
  late final _anchor = TextEditingController(text: widget.habit.anchorReminder);
  late final _obstacleIf = TextEditingController(text: widget.habit.obstacleIf);
  late final _obstacleThen =
      TextEditingController(text: widget.habit.obstacleThen);
  late final _mva = TextEditingController(text: widget.habit.startingVersion);

  @override
  void dispose() {
    for (final c in [
      _name,
      _what,
      _where,
      _when,
      _trigger,
      _anchor,
      _obstacleIf,
      _obstacleThen,
      _mva,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    // Name is the only field we won't let go blank.
    final updated = widget.habit.copyWith(
      habitName: name.isEmpty ? widget.habit.habitName : name,
      what: _what.text.trim(),
      where: _where.text.trim(),
      when: _when.text.trim(),
      trigger: _trigger.text.trim(),
      anchorReminder: _anchor.text.trim(),
      obstacleIf: _obstacleIf.text.trim(),
      obstacleThen: _obstacleThen.text.trim(),
      startingVersion: _mva.text.trim(),
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    final hex = _coreHex[widget.habit.coreId] ?? MM.teal;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final maxH = MediaQuery.of(context).size.height * 0.85;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxH),
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
            Text('EDIT HABIT', style: MM.displayX(size: 12, color: hex)),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('HABIT NAME'),
                    _field(_name, hex, 'Habit name'),
                    const SizedBox(height: 12),
                    _label('WHAT'),
                    _field(_what, hex, 'What you do', lines: 2),
                    const SizedBox(height: 12),
                    _label('WHERE'),
                    _field(_where, hex, 'Where you do it'),
                    const SizedBox(height: 12),
                    _label('WHEN'),
                    _field(_when, hex, 'e.g. after morning coffee'),
                    const SizedBox(height: 12),
                    _label('CUE · TRIGGER'),
                    _field(_trigger, hex, 'What kicks it off'),
                    const SizedBox(height: 12),
                    _label('CUE · ANCHOR / REMINDER'),
                    _field(_anchor, hex, 'What anchors it'),
                    const SizedBox(height: 12),
                    _label('IF (obstacle)'),
                    _field(_obstacleIf, hex, 'If this gets in the way…'),
                    const SizedBox(height: 12),
                    _label('THEN (plan)'),
                    _field(_obstacleThen, hex, '…then I will'),
                    const SizedBox(height: 12),
                    _label('STARTING VERSION (MVA)'),
                    _field(_mva, hex, 'The non-zero fallback', lines: 2),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: MMGhostButton(
                  label: 'Cancel',
                  expand: true,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MMPrimaryButton(
                  label: 'Save',
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  onPressed: _save,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: MM.displayX(size: 9, color: Colors.white.withOpacity(0.55))),
      );

  Widget _field(TextEditingController c, Color hex, String hint,
      {int lines = 1}) {
    return TextField(
      controller: c,
      style: MM.body(color: Colors.white, size: 13),
      cursorColor: hex,
      minLines: lines,
      maxLines: lines == 1 ? 1 : lines + 1,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: MM.body(color: Colors.white.withOpacity(0.35), size: 13),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        filled: true,
        fillColor: MM.navy.withOpacity(0.55),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: hex.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: hex),
        ),
      ),
    );
  }
}

/// Result of the flag sheet: whether the habit should be flagged, plus the
/// reason / note the player chose.
class _FlagResult {
  const _FlagResult(this.flagged, this.reason, this.note);
  final bool flagged;
  final String reason;
  final String note;
}

/// Bottom sheet for manually flagging a habit for refinement (Product Design
/// Rationale C4). Anti-shame: "flagging is data, not failure". Reasons are
/// grounded in C5's two root causes (the habit is wrong vs. execution is
/// failing). Pops a [_FlagResult]; the Go-Deeper intervention is Phase 2.
class _HabitFlagSheet extends StatefulWidget {
  const _HabitFlagSheet({required this.habit});
  final GoldenHabit habit;
  @override
  State<_HabitFlagSheet> createState() => _HabitFlagSheetState();
}

class _HabitFlagSheetState extends State<_HabitFlagSheet> {
  static const _reasons = [
    'The habit itself feels wrong',
    "The strategy / cue isn't working",
    'Life circumstances changed',
    'Too hard right now',
    'Other',
  ];

  late String _reason = _reasons.contains(widget.habit.flagReason)
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
            Text('⚠ FLAG FOR REFINEMENT',
                style: MM.displayX(size: 12, color: MM.yellow)),
            const SizedBox(height: 8),
            Text(
              "Flagging is data, not failure. It tells your Co-pilot this "
              'habit needs a tweak — nothing breaks your streak.',
              style: MM.body(color: Colors.white.withOpacity(0.6), size: 12),
            ),
            const SizedBox(height: 16),
            Text("WHAT'S GOING ON?",
                style:
                    MM.displayX(size: 9, color: Colors.white.withOpacity(0.55))),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final r in _reasons)
                _chip(r, _reason == r, () => setState(() => _reason = r)),
            ]),
            const SizedBox(height: 14),
            Text('NOTE (optional)',
                style:
                    MM.displayX(size: 9, color: Colors.white.withOpacity(0.55))),
            const SizedBox(height: 6),
            TextField(
              controller: _note,
              style: MM.body(color: Colors.white, size: 13),
              cursorColor: MM.yellow,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Anything that helps your Co-pilot understand…',
                hintStyle:
                    MM.body(color: Colors.white.withOpacity(0.35), size: 13),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
            Row(children: [
              Expanded(
                child: MMGhostButton(
                  label: already ? 'Remove flag' : 'Cancel',
                  expand: true,
                  color: already ? MM.red : null,
                  borderColor: already ? MM.red.withOpacity(0.5) : null,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  onPressed: () => Navigator.of(context).pop(
                      already ? const _FlagResult(false, '', '') : null),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MMPrimaryButton(
                  label: already ? 'Update flag' : 'Flag this habit',
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  onPressed: () => Navigator.of(context).pop(
                      _FlagResult(true, _reason, _note.text.trim())),
                ),
              ),
            ]),
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
              size: 12),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, this.color, required this.child});
  final String label;
  final Color? color;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      leftAccentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: MM.displayX(
                  size: 9, color: color ?? Colors.white.withOpacity(0.5))),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV({required this.k, required this.v});
  final String k;
  final String v;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(k,
                style: MM.display(
                    size: 9,
                    color: Colors.white.withOpacity(0.5),
                    letterSpacing: 9 * 0.08)),
          ),
          Expanded(
            child: Text(v,
                style: MM.body(color: Colors.white, size: 12)),
          ),
        ],
      ),
    );
  }
}

// ─── TASKS ─────────────────────────────────────────────────
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key, this.onBack, this.onChat, this.onNav});
  final VoidCallback? onBack;
  final VoidCallback? onChat;
  final void Function(String key)? onNav;

  @override
  Widget build(BuildContext context) {
    final buckets = [
      [
        'Today',
        [
          ['Q3 report draft', MM.yellow, 30, false],
          ['10m breathwork', MM.blue, 15, true],
          ['Grocery run', MM.teal, 10, false],
        ]
      ],
      [
        'Tomorrow',
        [
          ['1:1 with Sara', MM.magenta, 20, false],
          ['Yoga class', MM.teal, 25, false],
        ]
      ],
      [
        'Later',
        [
          ['Tax filing prep', MM.yellow, 60, false],
        ]
      ],
    ];
    return ScreenShell(
      title: 'Tasks',
      subtitle: 'MISSIONS · TODAY',
      accent: MM.yellow,
      onBack: onBack,
      onChat: onChat,
      onNav: onNav,
      child: Column(
        children: buckets.map((b) {
          final name = b[0] as String;
          final items = b[1] as List<List<dynamic>>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                  child: Text(
                    '${name.toUpperCase()} · ${items.length}',
                    style: MM.displayX(
                        size: 10, color: Colors.white.withOpacity(0.5)),
                  ),
                ),
                ...items.map((it) {
                  final t = it[0] as String;
                  final hex = it[1] as Color;
                  final pts = it[2] as int;
                  final done = it[3] as bool;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Opacity(
                      opacity: done ? 0.55 : 1,
                      child: GlassPanel(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: done ? hex : Colors.transparent,
                              border: Border.all(
                                  color: done
                                      ? hex
                                      : Colors.white.withOpacity(0.3),
                                  width: 1.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: done
                                ? const Icon(Icons.check,
                                    color: Colors.black, size: 11)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              t,
                              style: MM
                                  .body(color: Colors.white, size: 13)
                                  .copyWith(
                                      decoration: done
                                          ? TextDecoration.lineThrough
                                          : null),
                            ),
                          ),
                          _CoreDot(color: hex, size: 6),
                          const SizedBox(width: 6),
                          Text('+$pts',
                              style: MM.display(size: 10, color: hex)),
                        ]),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── CANTINA ───────────────────────────────────────────────
class _CrewMember {
  const _CrewMember(this.id, this.name, this.score, this.level, this.online,
      this.hex, this.avatar, this.streak, this.planet, this.cores,
      {this.me = false, this.isReal = false, this.uid});

  /// Builds a crew member from a real registered user.
  factory _CrewMember.fromUser(CantinaUser u, {required bool isMe}) {
    final palette = <Color>[
      MM.magenta,
      MM.blue,
      MM.teal,
      MM.violet,
      MM.yellow,
      MM.red,
    ];
    final color = palette[u.uid.hashCode.abs() % palette.length];
    final avatar = u.name.isNotEmpty ? u.name[0].toUpperCase() : '?';
    return _CrewMember(
      u.uid,
      isMe ? 'You' : u.name,
      u.score,
      u.level,
      false,
      color,
      avatar,
      u.streak,
      u.planet,
      u.activeCores,
      me: isMe,
      isReal: true,
      uid: u.uid,
    );
  }

  final String id;
  final String name;
  final int score;
  final String level;
  final bool online;
  final Color hex;
  final String avatar;
  final int streak;
  final String planet;
  final List<String> cores;
  final bool me;

  /// True when this row is backed by a real Firestore user (vs demo crew).
  final bool isReal;

  /// Firebase uid for real users; null for demo crew.
  final String? uid;
}

const _crew = <_CrewMember>[
  _CrewMember('maya', 'Maya R.', 12420, 'CMDR', true, MM.magenta, 'M', 84,
      'Saturn',
      ['mindset', 'career', 'relationships', 'physical', 'emotional']),
  _CrewMember('devon', 'Devon T.', 10115, 'NAV', true, MM.blue, 'D', 62,
      'Jupiter',
      ['mindset', 'career', 'physical', 'emotional']),
  _CrewMember('me', 'You', 8420, 'NAV', true, MM.yellow, 'Y', 47, 'Mars',
      ['mindset', 'career', 'physical'],
      me: true),
  _CrewMember('aisha', 'Aisha K.', 7980, 'NAV', false, MM.teal, 'A', 41,
      'Mars', ['mindset', 'career', 'physical']),
  _CrewMember('leo', 'Leo M.', 3210, 'CDT', false, MM.violet, 'L', 12, 'Moon',
      ['mindset', 'physical']),
];

class _Thread {
  const _Thread(this.id, this.name, this.preview, this.time, this.hex,
      this.history);
  final String id;
  final String name;
  final String preview;
  final String time;
  final Color hex;
  final List<Map<String, String>> history;
}

final _threads = <_Thread>[
  _Thread('maya', 'Maya R.', 'Nice 47-day streak 🔥', '2m', MM.magenta, [
    {'from': 'them', 'text': "Looked at your dashboard — that's a real streak now."},
    {'from': 'them', 'text': 'Want to start a 7-day Physical Cores challenge?'},
    {'from': 'me', 'text': "In. Let's go."},
    {'from': 'them', 'text': 'Nice 47-day streak 🔥'},
  ]),
  _Thread('squad', 'Squadron Pluto', 'Group challenge starts Monday', '1h',
      MM.violet, [
    {'from': 'them', 'text': 'Reminder: weekly recap drops tonight 9pm.'},
    {'from': 'them', 'text': 'I am in.'},
    {'from': 'them', 'text': 'Group challenge starts Monday.'},
  ]),
];

class CantinaScreen extends StatefulWidget {
  const CantinaScreen({super.key, this.onBack, this.onChat, this.onNav});
  final VoidCallback? onBack;
  final VoidCallback? onChat;
  final void Function(String key)? onNav;

  @override
  State<CantinaScreen> createState() => _CantinaScreenState();
}

class _CantinaScreenState extends State<CantinaScreen> {
  String _tab = 'ideas';

  @override
  Widget build(BuildContext context) {
    return ScreenShell(
      title: 'Cantina',
      subtitle: 'COSMIC SOCIAL HUB',
      accent: MM.teal,
      onBack: widget.onBack,
      onChat: widget.onChat,
      onNav: widget.onNav,
      child: Column(
        children: [
          _SegTabs(
            tabs: const [
              ['ideas', 'Ideas Well'],
              ['tribes', 'Tribes'],
              ['board', 'Leaderboard'],
              ['arena', 'Arena'],
            ],
            active: _tab,
            onTap: (t) => setState(() => _tab = t),
            fontSize: 9,
            letterSpacingEm: 0.04,
            radius: 9,
          ),
          const SizedBox(height: 14),
          if (_tab == 'ideas') const _IdeasWell(),
          if (_tab == 'board') _TribeBoard(onNav: widget.onNav),
          if (_tab == 'tribes') _TribesTab(onNav: widget.onNav),
          if (_tab == 'arena') const _ArenaTab(),
        ],
      ),
    );
  }
}

/// Leaderboard pillar — registered users + demo crew, ranked.
class _TribeBoard extends StatelessWidget {
  const _TribeBoard({this.onNav});
  final void Function(String key)? onNav;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassPanel(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("THIS WEEK'S TRIBE BOARD",
                  style: MM.displayX(
                      size: 10, color: Colors.white.withOpacity(0.5))),
              const SizedBox(height: 10),
              _LeaderboardList(onNav: onNav),
            ],
          ),
        ),
        Column(
          children: [
            Text('EVERY PILOT RISES · NO SHAME, JUST RIPPLES',
                textAlign: TextAlign.center,
                style: MM.displayX(
                    size: 10, color: Colors.white.withOpacity(0.4))),
            const SizedBox(height: 4),
            Text('Tap a pilot to adopt their top habits',
                textAlign: TextAlign.center,
                style: MM.displayX(
                    size: 10, color: Colors.white.withOpacity(0.28))),
          ],
        ),
      ],
    );
  }
}

/// Tribes pillar — squad threads list.
class _TribesTab extends StatelessWidget {
  const _TribesTab({this.onNav});
  final void Function(String key)? onNav;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
          child: Text('SQUAD THREADS · ${_threads.length}',
              style: MM.displayX(
                  size: 10, color: Colors.white.withOpacity(0.5))),
        ),
        ..._threads.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                onTap: () => onNav?.call('thread:${t.id}'),
                child: GlassPanel(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, color: t.hex),
                      child: Center(
                        child: Text(t.name[0],
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name,
                              style: MM.body(
                                  color: Colors.white,
                                  weight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(t.preview,
                              style: MM.body(
                                  color: Colors.white.withOpacity(0.6),
                                  size: 11)),
                        ],
                      ),
                    ),
                    Text(t.time,
                        style: MM.mono(
                            color: Colors.white.withOpacity(0.4), size: 10)),
                  ]),
                ),
              ),
            )),
        const SizedBox(height: 8),
        MMGhostButton(
          label: '+ Discover Tribes',
          expand: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          onPressed: () {},
        ),
      ],
    );
  }
}

/// Arena pillar — coming-soon placeholder.
class _ArenaTab extends StatelessWidget {
  const _ArenaTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      child: Column(
        children: [
          const Text('⚔️', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          Text('Weekly Arena',
              style: MM.display(size: 18, color: Colors.white)),
          const SizedBox(height: 8),
          SizedBox(
            width: 240,
            child: Text(
              'Tribe-vs-tribe competitions, Core Sprints, and real-life rewards.',
              textAlign: TextAlign.center,
              style:
                  MM.body(color: Colors.white.withOpacity(0.6), size: 12),
            ),
          ),
          const SizedBox(height: 16),
          MMChip(label: '🚀 LAUNCHING SOON', color: MM.yellow),
        ],
      ),
    );
  }
}

// ─── IDEAS WELL ────────────────────────────────────────────
/// A crowdsourced suggestion: a Golden Habit, MBM, or Tech/App (Pillar 1).
class _IdeaItem {
  const _IdeaItem(this.id, this.kind, this.core, this.pain, this.title,
      this.desc, this.up, this.adopted,
      {this.link = false});
  final int id;
  final String kind; // 'habit' | 'mbm' | 'tech'
  final String core;
  final String pain;
  final String title;
  final String desc;
  final int up;
  final int adopted;
  final bool link;
}

const _ideasWell = <_IdeaItem>[
  _IdeaItem(1, 'habit', 'physical', 'consistent exercise',
      'Lay gym clothes out the night before',
      'Cuts morning decisions to zero — shoes by the door, kit on the chair.',
      412, 1180),
  _IdeaItem(2, 'habit', 'mindset', 'racing thoughts',
      '10-min "brain dump" before bed',
      'Empty every open loop onto paper so sleep comes faster.', 388, 902),
  _IdeaItem(3, 'mbm', 'career', 'procrastination',
      'Make It Easy · 2-minute start rule',
      'Commit to just opening the doc. Momentum does the rest.', 356, 1410),
  _IdeaItem(4, 'habit', 'relationships', 'staying in touch',
      'Weekly 1-on-1 coffee, rotate friends',
      'One scheduled connection beats ten missed intentions.', 301, 640),
  _IdeaItem(5, 'mbm', 'physical', 'better sleep',
      'Make It Obvious · phone charges outside bedroom',
      'No screen = earlier lights-out, automatically.', 289, 733),
  _IdeaItem(6, 'tech', 'career', 'auto-saving',
      'Auto-transfer app · "round-up" savings',
      'Rounds every purchase up and banks the difference.', 254, 521,
      link: true),
  _IdeaItem(7, 'habit', 'emotional', 'stress spikes',
      'Box-breathing on the first deep breath cue',
      '4-4-4-4 the moment you notice tension in your chest.', 233, 455),
  _IdeaItem(8, 'tech', 'mindset', 'focus', 'Focus-timer app · 25/5 pomodoros',
      'Community top pick for deep-work blocks.', 198, 389, link: true),
];

const _ideasCores = <List<dynamic>>[
  ['mindset', 'Mind', MM.blue],
  ['career', 'Career', MM.yellow],
  ['relationships', 'Rel.', MM.magenta],
  ['physical', 'Phys.', MM.teal],
  ['emotional', 'Emo.', MM.violet],
];

class _IdeasWell extends StatefulWidget {
  const _IdeasWell();

  @override
  State<_IdeasWell> createState() => _IdeasWellState();
}

class _IdeasWellState extends State<_IdeasWell> {
  String? _core; // null = all
  String _kind = 'habit';
  final Set<int> _votes = {};

  Color _hexOf(String id) => MM.coreColor[id] ?? Colors.white;
  String _shortOf(String id) =>
      (_ideasCores.firstWhere((c) => c[0] == id, orElse: () => const ['', '', MM.white])[1]) as String;

  void _showAdoptSheet(_IdeaItem item) {
    final hex = _hexOf(item.core);
    final nameCtrl = TextEditingController(text: item.title);
    final freqCtrl = TextEditingController(text: 'Daily');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: MM.navy,
            border: Border(top: BorderSide(color: hex, width: 2)),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ADOPT & CUSTOMIZE',
                  style: MM.displayX(size: 10, color: hex)),
              const SizedBox(height: 12),
              _sheetField('NAME', nameCtrl),
              const SizedBox(height: 12),
              _sheetField('FREQUENCY', freqCtrl),
              const SizedBox(height: 16),
              MMPrimaryButton(
                label: 'Add to my system →',
                onPressed: () {
                  Navigator.of(ctx).pop();
                  final shown = item.title.length > 24
                      ? '${item.title.substring(0, 24)}…'
                      : item.title;
                  _toast('✓ Added "$shown" to your system');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: MM.displayX(
                size: 9, color: Colors.white.withOpacity(0.5))),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          style: MM.body(color: Colors.white, size: 13),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.15)),
            ),
          ),
        ),
      ],
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0A2E29),
        duration: const Duration(milliseconds: 2000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0x8C00A98F)),
        ),
        content: Text(msg,
            textAlign: TextAlign.center,
            style: MM.body(color: Colors.white, size: 12)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final feed = _ideasWell
        .where((x) => x.kind == _kind)
        .where((x) => _core == null || x.core == _core)
        .map((x) => (item: x, up: x.up + (_votes.contains(x.id) ? 1 : 0)))
        .toList()
      ..sort((a, b) => b.up.compareTo(a.up));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Core filter
        Row(
          children: [
            _coreChip(label: 'ALL', selected: _core == null, hex: Colors.white,
                onTap: () => setState(() => _core = null)),
            ..._ideasCores.map((c) {
              final id = c[0] as String;
              final hex = c[2] as Color;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: _coreChip(
                    label: c[1] as String,
                    selected: _core == id,
                    hex: hex,
                    expand: true,
                    onTap: () =>
                        setState(() => _core = _core == id ? null : id),
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        // Kind toggle
        _SegTabs(
          tabs: const [
            ['habit', 'Habits'],
            ['mbm', 'MBMs'],
            ['tech', 'Tech/Apps'],
          ],
          active: _kind,
          onTap: (k) => setState(() => _kind = k),
          fontSize: 10,
          letterSpacingEm: 0.08,
          radius: 8,
        ),
        const SizedBox(height: 12),
        // Feed
        ...feed.map((row) {
          final x = row.item;
          final hex = _hexOf(x.core);
          final voted = _votes.contains(x.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassPanel(
              leftAccentColor: hex,
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upvote
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() =>
                        voted ? _votes.remove(x.id) : _votes.add(x.id)),
                    child: SizedBox(
                      width: 34,
                      child: Column(
                        children: [
                          Icon(Icons.arrow_drop_up,
                              size: 26,
                              color: voted
                                  ? hex
                                  : Colors.white.withOpacity(0.5)),
                          Text('${row.up}',
                              style: MM.mono(
                                  size: 11,
                                  color: voted
                                      ? hex
                                      : Colors.white.withOpacity(0.7))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          MMChip(
                              label: _shortOf(x.core).toUpperCase(),
                              color: hex),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text('· ${x.pain}',
                                overflow: TextOverflow.ellipsis,
                                style: MM.body(
                                    color: Colors.white.withOpacity(0.4),
                                    size: 9)),
                          ),
                        ]),
                        const SizedBox(height: 3),
                        Text(x.title,
                            style: MM.body(
                                color: Colors.white,
                                size: 13,
                                weight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(x.desc,
                            style: MM.body(
                                color: Colors.white.withOpacity(0.65),
                                size: 11)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Text('${x.adopted} adopted',
                              style: MM.mono(
                                  size: 10,
                                  color: Colors.white.withOpacity(0.45))),
                          const Spacer(),
                          if (x.link) ...[
                            Text('↗ OPEN APP',
                                style: MM.displayX(size: 10, color: hex)),
                            const SizedBox(width: 10),
                          ],
                          _addButton(x, hex),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _coreChip({
    required String label,
    required bool selected,
    required Color hex,
    required VoidCallback onTap,
    bool expand = false,
  }) {
    final isAll = label == 'ALL';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: expand ? double.infinity : null,
        padding: EdgeInsets.symmetric(
            horizontal: isAll ? 10 : 4, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? (isAll
                  ? Colors.white.withOpacity(0.14)
                  : hex.withOpacity(0.2))
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected ? hex : Colors.white.withOpacity(0.12)),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: MM.display(
                size: 10,
                color: selected ? Colors.white : Colors.white.withOpacity(0.7),
                weight: FontWeight.w600,
                letterSpacing: 10 * 0.05)),
      ),
    );
  }

  Widget _addButton(_IdeaItem x, Color hex) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showAdoptSheet(x),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: hex.withOpacity(0.13),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: hex.withOpacity(0.4)),
        ),
        child: Text('＋ ADD',
            style: MM.displayX(size: 10, color: Colors.white)),
      ),
    );
  }
}

/// The weekly leaderboard: real registered users (from `users`) merged with
/// the demo crew, sorted by score. Real rows open a 2-way DM; demo rows open
/// the mock profile; your own row opens your profile.
class _LeaderboardList extends StatefulWidget {
  const _LeaderboardList({this.onNav});
  final void Function(String key)? onNav;

  @override
  State<_LeaderboardList> createState() => _LeaderboardListState();
}

class _LeaderboardListState extends State<_LeaderboardList> {
  final _svc = CantinaService();
  late final Stream<List<CantinaUser>> _stream = _svc.watchUsers();
  late final Stream<Map<String, CantinaInboxEntry>> _inboxStream =
      _svc.watchInbox();
  late final String _myUid = _svc.currentUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CantinaUser>>(
      stream: _stream,
      builder: (context, snap) {
        final real = (snap.data ?? const <CantinaUser>[])
            .map((u) => _CrewMember.fromUser(u, isMe: u.uid == _myUid))
            .toList();
        final hasMe = real.any((m) => m.me);
        // Keep all demo crew; drop the demo "You" once a real self row exists.
        final demo = _crew.where((c) => !c.me || !hasMe).toList();
        final all = [...real, ...demo]
          ..sort((a, b) => b.score.compareTo(a.score));

        // Layer the live inbox over the score-sorted crew. The rank number
        // stays tied to score; the display order floats anyone you've chatted
        // with to the top (most-recent conversation first) and keeps them
        // there after the message is read — unread only drives the badge.
        return StreamBuilder<Map<String, CantinaInboxEntry>>(
          stream: _inboxStream,
          builder: (context, inboxSnap) {
            final inbox = inboxSnap.data ?? const <String, CantinaInboxEntry>{};

            CantinaInboxEntry? entryFor(_CrewMember c) {
              if (!c.isReal || c.me || c.uid == null) return null;
              return inbox[_svc.dmPairId(c.uid!)];
            }

            // Stable score rank (1-based) captured before reordering.
            final ranked = [
              for (var i = 0; i < all.length; i++) (rank: i + 1, member: all[i]),
            ];

            // Conversations float up by recency; everyone you haven't messaged
            // keeps their score order below them.
            ranked.sort((a, b) {
              final ea = entryFor(a.member);
              final eb = entryFor(b.member);
              final aChat = ea != null;
              final bChat = eb != null;
              if (aChat != bChat) return aChat ? -1 : 1;
              if (aChat && bChat) {
                final ta = ea.updatedAt, tb = eb.updatedAt;
                if (ta != null && tb != null && ta != tb) {
                  return tb.compareTo(ta); // most recent first
                }
                if (ta != null && tb == null) return -1;
                if (tb != null && ta == null) return 1;
                // No timestamps to separate them → unread first, then score.
                final ua = ea.unreadCount, ub = eb.unreadCount;
                if ((ua > 0) != (ub > 0)) return ua > 0 ? -1 : 1;
              }
              return a.rank.compareTo(b.rank);
            });

            return Column(
              children: [
                for (final r in ranked)
                  _row(r.rank, r.member, entryFor(r.member)?.unreadCount ?? 0),
              ],
            );
          },
        );
      },
    );
  }

  String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  Widget _row(int rank, _CrewMember c, int unread) {
    return InkWell(
      onTap: () => widget.onNav?.call(c.me
          ? 'profile'
          : (c.isReal ? 'crew:dm:${c.uid}' : 'crew:${c.id}')),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(
            horizontal: c.me ? 8 : 4, vertical: c.me ? 6 : 4),
        decoration: BoxDecoration(
          color: c.me ? MM.yellow.withOpacity(0.08) : Colors.transparent,
          border: c.me ? Border.all(color: MM.yellow.withOpacity(0.3)) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          SizedBox(
            width: 16,
            child: Text('$rank',
                style: MM.display(
                    size: 11, color: Colors.white.withOpacity(0.5))),
          ),
          Stack(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.hex),
              child: Center(
                child: Text(c.avatar,
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            if (c.online)
              Positioned(
                bottom: -1,
                right: -1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00FF88),
                    border: Border.all(color: MM.pageBg, width: 2),
                  ),
                ),
              ),
          ]),
          const SizedBox(width: 10),
          Expanded(
            child: Row(children: [
              Flexible(
                child: Text(c.name,
                    overflow: TextOverflow.ellipsis,
                    style: MM.body(
                        color: Colors.white,
                        size: 13,
                        weight: c.me ? FontWeight.w700 : FontWeight.w500)),
              ),
              if (unread > 0) ...[
                const SizedBox(width: 6),
                _UnreadBadge(count: unread),
              ],
            ]),
          ),
          MMChip(label: c.level),
          const SizedBox(width: 6),
          Text(_fmt(c.score), style: MM.display(size: 12, color: c.hex)),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right,
              color: Colors.white.withOpacity(0.4), size: 16),
        ]),
      ),
    );
  }
}

/// Small pill showing the number of unread DMs from a crew member, mirroring
/// the Cantina nav badge so the sender is easy to spot in the leaderboard.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      decoration: BoxDecoration(
        color: MM.red,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
      ),
    );
  }
}

class CrewProfileScreen extends StatelessWidget {
  const CrewProfileScreen(
      {super.key,
      required this.crewId,
      this.onBack,
      this.onChat,
      this.onNav});
  final String crewId;
  final VoidCallback? onBack;
  final VoidCallback? onChat;
  final void Function(String key)? onNav;

  @override
  Widget build(BuildContext context) {
    // Real registered users arrive as `dm:{uid}` — fetch them from Firestore
    // and show the same profile (Message + Challenge) as the demo crew, with
    // Message opening their two-way DM thread.
    if (crewId.startsWith('dm:')) {
      final uid = crewId.substring(3);
      return FutureBuilder<CantinaUser?>(
        future: CantinaService().getUser(uid),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return ScreenShell(
              title: 'Crew',
              subtitle: 'LOADING…',
              accent: MM.teal,
              onBack: onBack,
              onChat: onChat,
              onNav: onNav,
              child: const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                    child: CircularProgressIndicator(color: MM.teal)),
              ),
            );
          }
          final user = snap.data;
          if (user == null) {
            return ScreenShell(
              title: 'Crew',
              subtitle: 'NOT FOUND',
              accent: MM.teal,
              onBack: onBack,
              onChat: onChat,
              onNav: onNav,
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text('Crew member unavailable.',
                      style: MM.body(color: Colors.white.withOpacity(0.6))),
                ),
              ),
            );
          }
          return _buildProfile(context, _CrewMember.fromUser(user, isMe: false),
              messageKey: 'thread:dm:$uid');
        },
      );
    }
    final c = _crew.firstWhere((x) => x.id == crewId, orElse: () => _crew[0]);
    return _buildProfile(context, c, messageKey: 'thread:${c.id}');
  }

  Widget _buildProfile(BuildContext context, _CrewMember c,
      {required String messageKey}) {
    const cores = [
      {'id': 'mindset', 'name': 'MIND', 'hex': MM.blue},
      {'id': 'career', 'name': 'CAREER', 'hex': MM.yellow},
      {'id': 'relationships', 'name': 'CONNECT', 'hex': MM.magenta},
      {'id': 'physical', 'name': 'PHYSICAL', 'hex': MM.teal},
      {'id': 'emotional', 'name': 'EMOTION', 'hex': MM.violet},
    ];
    return ScreenShell(
      title: c.name,
      subtitle: '${c.level} · ${c.online ? 'ONLINE' : 'OFFLINE'}',
      accent: c.hex,
      onBack: onBack,
      onChat: onChat,
      onNav: onNav,
      child: Column(
        children: [
          GlassPanel(
            accent: true,
            borderColor: c.hex.withOpacity(0.4),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            margin: const EdgeInsets.only(bottom: 14),
            child: Row(children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.hex,
                  boxShadow: [
                    BoxShadow(color: c.hex.withOpacity(0.5), blurRadius: 16),
                  ],
                ),
                child: Center(
                  child: Text(c.avatar,
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        style: MM.display(size: 16, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('${c.level} · ON ${c.planet.toUpperCase()}',
                        style: MM.displayX(size: 10, color: c.hex)),
                    const SizedBox(height: 8),
                    Row(children: [
                      MMChip(label: '${c.streak}🔥', color: MM.teal),
                      const SizedBox(width: 6),
                      MMChip(label: '${c.score} MS', color: MM.yellow),
                    ]),
                  ],
                ),
              ),
            ]),
          ),
          GlassPanel(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACTIVE CORES · ${c.cores.length}/5',
                    style: MM.displayX(
                        size: 10, color: Colors.white.withOpacity(0.5))),
                const SizedBox(height: 10),
                Row(
                  children: cores.map((co) {
                    final on = c.cores.contains(co['id']);
                    final hex = co['hex'] as Color;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: on
                                  ? RadialGradient(
                                      colors: [
                                        hex.withOpacity(0.33),
                                        Colors.transparent
                                      ],
                                      stops: const [0, 0.7],
                                    )
                                  : null,
                              color: on
                                  ? null
                                  : Colors.white.withOpacity(0.04),
                              border: Border.all(
                                  color: on
                                      ? hex.withOpacity(0.47)
                                      : Colors.white.withOpacity(0.1)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(co['name'] as String,
                                  style: MM.display(
                                      size: 8,
                                      color: on
                                          ? Colors.white
                                          : Colors.white
                                              .withOpacity(0.3))),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Row(children: [
            Expanded(
              child: MMGhostButton(
                label: 'Message',
                expand: true,
                color: c.hex,
                borderColor: c.hex.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: () => onNav?.call(messageKey),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MMGhostButton(
                label: 'Challenge',
                expand: true,
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: () {},
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class ThreadScreen extends StatefulWidget {
  const ThreadScreen({super.key, required this.threadId, this.onBack});
  final String threadId;
  final VoidCallback? onBack;

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  final _draftCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _svc = CantinaService();
  late _Thread _thread;
  late final String _myUid;
  late final Stream<DateTime?> _clearedAt =
      _svc.watchClearedAt(widget.threadId);

  @override
  void initState() {
    super.initState();
    _myUid = _svc.currentUid;

    // Real-user DM (threadId `dm:{uid}`): shared two-way thread, no demo seed.
    if (widget.threadId.startsWith('dm:')) {
      final otherUid = widget.threadId.substring(3);
      _thread = _Thread(
          otherUid, 'Crew', '', '', MM.blue, const <Map<String, String>>[]);
      _loadDmTitle(otherUid);
      _svc.markThreadRead(widget.threadId);
      return;
    }

    var t = _threads.firstWhere((x) => x.id == widget.threadId,
        orElse: () => _threads.first);
    final crewMatch = _crew.where((x) => x.id == widget.threadId).toList();
    if (crewMatch.isNotEmpty &&
        !_threads.any((x) => x.id == widget.threadId)) {
      final c = crewMatch.first;
      t = _Thread(c.id, c.name, '', '', c.hex, [
        {'from': 'them', 'text': 'Hey — this is ${c.name.split(' ').first}'},
      ]);
    }
    _thread = t;
    // Backfill the opening demo messages once so the channel isn't blank.
    _svc.seedIfEmpty(widget.threadId, _thread.history).catchError(
        (Object e) => debugPrint('Cantina seedIfEmpty failed: $e'));
  }

  /// Resolves a real DM partner's display name for the header.
  Future<void> _loadDmTitle(String uid) async {
    final u = await _svc.getUser(uid);
    if (!mounted || u == null) return;
    setState(() => _thread =
        _Thread(uid, u.name, '', '', _thread.hex, const <Map<String, String>>[]));
  }

  @override
  void dispose() {
    _draftCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _draftCtrl.text.trim();
    if (t.isEmpty) return;
    _draftCtrl.clear();
    try {
      await _svc.sendMessage(widget.threadId, t);
    } catch (e) {
      debugPrint('Cantina sendMessage failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e, action: 'send your message'))),
      );
    }
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MM.navy,
        title: Text('Clear history?',
            style: MM.display(size: 16, color: Colors.white)),
        content: Text(
          'This permanently deletes all messages in this chat for everyone.',
          style: MM.body(color: Colors.white.withOpacity(0.7), size: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: MM.body(color: Colors.white.withOpacity(0.7))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Clear', style: MM.body(color: MM.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _svc.clearMessages(widget.threadId);
    } catch (e) {
      debugPrint('Cantina clearMessages failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(e, action: 'clear the history'))),
      );
    }
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MM.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: _thread.hex.withOpacity(0.2))),
              ),
              child: Row(children: [
                InkWell(
                  onTap: widget.onBack ??
                      () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: MM.navy.withOpacity(0.55),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        const Icon(Icons.chevron_left, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 34,
                  height: 34,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: _thread.hex),
                  child: Center(
                      child: Text(_thread.name[0],
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_thread.name,
                          style: MM.display(size: 14, color: Colors.white)),
                      Text('SQUAD CHANNEL',
                          style: MM.display(
                              size: 10,
                              color: _thread.hex,
                              letterSpacing: 10 * 0.1)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _confirmClear,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: MM.navy.withOpacity(0.55),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.12)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.delete_outline,
                        color: Colors.white.withOpacity(0.85), size: 20),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: StreamBuilder<DateTime?>(
                stream: _clearedAt,
                builder: (context, clearedSnap) {
                  final clearedAt = clearedSnap.data;
                  return StreamBuilder<List<CantinaMessage>>(
                    stream: _svc.watchMessages(widget.threadId),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              "Couldn't load messages.\n${snap.error}",
                              textAlign: TextAlign.center,
                              style: MM.body(
                                  color: Colors.white.withOpacity(0.6),
                                  size: 12),
                            ),
                          ),
                        );
                      }
                      if (!snap.hasData) {
                        return const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      // Hide anything cleared by this user (one-sided clear).
                      final msgs = clearedAt == null
                          ? snap.data!
                          : snap.data!
                              .where((m) =>
                                  m.createdAt == null ||
                                  m.createdAt!.isAfter(clearedAt))
                              .toList();
                      _scrollToBottom();
                  // Keep the thread marked read while it's on screen.
                  _svc.markThreadRead(widget.threadId);
                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(14),
                    itemCount: msgs.length,
                    itemBuilder: (_, i) {
                      final m = msgs[i];
                      final mine = m.senderId == _myUid;
                      return Align(
                        alignment:
                            mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.82),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            gradient: mine
                                ? const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF3A8DFF),
                                      Color(0xFF1F5FB8)
                                    ],
                                  )
                                : null,
                            color: mine ? null : MM.navy.withOpacity(0.7),
                            border: Border.all(
                                color: mine
                                    ? const Color(0xFF4D9BFF).withOpacity(0.5)
                                    : _thread.hex.withOpacity(0.33)),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(14),
                              topRight: const Radius.circular(14),
                              bottomLeft: Radius.circular(mine ? 14 : 4),
                              bottomRight: Radius.circular(mine ? 4 : 14),
                            ),
                          ),
                          child: Text(m.text,
                              style: MM.body(color: Colors.white, size: 13)),
                        ),
                      );
                    },
                  );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
              decoration: BoxDecoration(
                color: MM.pageBg,
                border: Border(
                    top: BorderSide(color: Colors.white.withOpacity(0.06))),
              ),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _draftCtrl,
                    style: MM.body(color: Colors.white),
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle:
                          MM.body(color: Colors.white.withOpacity(0.4)),
                      filled: true,
                      fillColor: MM.navy.withOpacity(0.6),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide(
                            color: _thread.hex.withOpacity(0.33)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide(
                            color: _thread.hex.withOpacity(0.33)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _send,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF3A8DFF), Color(0xFF1F5FB8)],
                      ),
                      border: Border.all(
                          color: _thread.hex.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TROPHY ────────────────────────────────────────────────
/// Segmented pill tab bar used by the Cantina hub and the Trophy Room.
/// `tabs` is a list of [key, label] pairs.
class _SegTabs extends StatelessWidget {
  const _SegTabs({
    required this.tabs,
    required this.active,
    required this.onTap,
    this.activeGradient = const [Color(0xFF16B89C), Color(0xFF0C7D6A)],
    this.fontSize = 11,
    this.letterSpacingEm = 0.1,
    this.radius = 10,
    this.glowColor,
  });

  final List<List<String>> tabs;
  final String active;
  final ValueChanged<String> onTap;
  final List<Color> activeGradient;
  final double fontSize;
  final double letterSpacingEm;
  final double radius;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: tabs.map((t) {
          final on = t[0] == active;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(t[0]),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
                decoration: BoxDecoration(
                  gradient: on
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: activeGradient)
                      : null,
                  borderRadius: BorderRadius.circular(radius - 3),
                  boxShadow: on && glowColor != null
                      ? [BoxShadow(color: glowColor!, blurRadius: 12)]
                      : null,
                ),
                child: Text(
                  t[1].toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MM.display(
                    size: fontSize,
                    color: on ? Colors.white : Colors.white.withOpacity(0.6),
                    weight: FontWeight.w700,
                    letterSpacing: fontSize * letterSpacingEm,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// A Golden Habit that has fully formed (14+ days @ 80%+). Identity payoff.
/// A Golden Habit as seen by the Trophy Room (#11): "formed" is either the
/// manual "Mark as Formed" flag OR the auto rule (14+ days of the Core's
/// check-in history with ≥80% scored ≥3, via `deriveRoutineStage == 'formed'`).
class _TrophyHabit {
  const _TrophyHabit({
    required this.habitId,
    required this.coreShort,
    required this.name,
    required this.autoFormed,
    required this.manualFormed,
    required this.days,
    required this.formedAt,
  });
  final String habitId;
  final String coreShort;
  final String name;
  final bool autoFormed;
  final bool manualFormed;
  final int days; // Core check-in history length (the formation window)
  final String formedAt; // ISO string when manually marked, else ''

  bool get formed => autoFormed || manualFormed;
}

const _trophyCores = <List<dynamic>>[
  ['mindset', 'Mindset', MM.blue],
  ['career', 'Career & Finances', MM.yellow],
  ['relationships', 'Relationships', MM.magenta],
  ['physical', 'Physical Health', MM.teal],
  ['emotional', 'Emotional & Mental', MM.violet],
];

class TrophyScreen extends StatefulWidget {
  const TrophyScreen({super.key, this.onBack, this.onChat, this.onNav});
  final VoidCallback? onBack;
  final VoidCallback? onChat;
  final void Function(String key)? onNav;

  @override
  State<TrophyScreen> createState() => _TrophyScreenState();
}

class _TrophyScreenState extends State<TrophyScreen> {
  final _onboarding = OnboardingService();
  final _checkin = CheckinService();

  String _tab = 'trophies';
  List<_TrophyHabit> _habits = const [];
  bool _loading = true;
  bool _busy = false; // during a Mark-as-Formed write
  bool _errorOffline = false;
  String? _error;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
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
      final habits = await _onboarding.goldenHabits(uid);
      // Real formation source: recent per-Core check-in scores (Spec §8).
      List<DailyCheckin> checkins = const [];
      try {
        checkins = await _checkin.getRecent(uid, limit: 30);
      } catch (_) {}
      final byCore = <String, List<int>>{};
      for (final c in checkins) {
        c.scores.forEach((k, v) => byCore.putIfAbsent(k, () => []).add(v));
      }
      final list = habits.map((h) {
        final scores = byCore[h.shortCoreId] ?? const <int>[];
        return _TrophyHabit(
          habitId: h.habitId,
          coreShort: h.shortCoreId,
          name: h.habitName.trim().isNotEmpty ? h.habitName.trim() : 'Golden Habit',
          autoFormed: deriveRoutineStage(scores) == 'formed',
          manualFormed: h.formed,
          days: scores.length,
          formedAt: h.formedAt,
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _habits = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _errorOffline = isNetworkError(e);
        _loading = false;
      });
    }
  }

  String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return '${_months[d.month - 1]} ${d.day}';
  }

  Future<void> _markFormed(_TrophyHabit h) async {
    final ok = await _confirmFormed(h);
    if (ok != true || !mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    setState(() => _busy = true);
    final saved =
        await _onboarding.setHabitFormed(userId: uid, habitId: h.habitId, formed: true);
    if (!mounted) return;
    setState(() => _busy = false);
    if (saved) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Couldn't save — check your connection and try again.")));
    }
  }

  Future<bool?> _confirmFormed(_TrophyHabit h) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: MM.navy,
        insetPadding: const EdgeInsets.all(28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: MM.teal.withOpacity(0.45)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MARK AS FORMED',
                  style: MM.displayX(size: 11, color: MM.teal)),
              const SizedBox(height: 10),
              Text('"${h.name}"',
                  style: MM.body(
                      color: Colors.white, size: 14, weight: FontWeight.w600)),
              const SizedBox(height: 10),
              Text(
                'The 2-week standard: habits usually take 14+ days of '
                'consistency to form${h.days > 0 ? ' (you have ${h.days} logged)' : ''}. '
                'Mark it formed if it\'s now simply who you are.',
                style: MM.body(
                    color: Colors.white.withOpacity(0.7),
                    size: 12.5,
                    height: 1.5),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: MMGhostButton(
                    label: 'Cancel',
                    expand: true,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MMPrimaryButton(
                    label: 'Mark Formed',
                    onPressed: () => Navigator.pop(ctx, true),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formedCount = _habits.where((h) => h.formed).length;
    return ScreenShell(
      title: 'Trophy Room',
      subtitle: _tab == 'trophies'
          ? 'FORMED · $formedCount'
          : 'ACHIEVEMENTS · 5/8',
      accent: MM.yellow,
      onBack: widget.onBack,
      onChat: widget.onChat,
      onNav: widget.onNav,
      child: Column(
        children: [
          _SegTabs(
            tabs: const [
              ['trophies', 'Trophy Room'],
              ['badges', 'Achievements'],
            ],
            active: _tab,
            onTap: (t) => setState(() => _tab = t),
            activeGradient: const [Color(0xFF3A8DFF), Color(0xFF1F5FB8)],
            glowColor: const Color(0x662A7DE1),
          ),
          const SizedBox(height: 14),
          if (_tab == 'trophies')
            _trophiesBody(formedCount)
          else
            const _AchievementsTab(),
        ],
      ),
    );
  }

  Widget _trophiesBody(int formedCount) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: MM.yellow)),
      );
    }
    if (_error != null) {
      if (_errorOffline) {
        return OfflineErrorView(onRetry: _load, what: 'your trophies');
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(children: [
          Text('Could not load trophies',
              style: MM.display(size: 14, color: Colors.white)),
          const SizedBox(height: 14),
          MMGhostButton(label: 'Retry', onPressed: _load),
        ]),
      );
    }
    return Column(
      children: [
        GlassPanel(
          accent: true,
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FORMED HABITS',
                  style: MM.displayX(size: 10, color: MM.yellow)),
              const SizedBox(height: 4),
              Text('$formedCount',
                  style: MM.display(size: 30, color: Colors.white)),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style:
                      MM.body(color: Colors.white.withOpacity(0.7), size: 12),
                  children: [
                    TextSpan(
                        text: formedCount == 0
                            ? 'No formed habits yet — keep showing up. Habits '
                                'graduate here once they\'re simply '
                            : '$formedCount ${formedCount == 1 ? 'habit is' : 'habits are'} now simply '),
                    const TextSpan(
                        text: 'who you are',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ],
          ),
        ),
        ..._trophyCores.map(_coreSection),
      ],
    );
  }

  Widget _coreSection(List<dynamic> c) {
    final id = c[0] as String;
    final name = c[1] as String;
    final hex = c[2] as Color;
    final formed = _habits.where((h) => h.coreShort == id && h.formed).toList();
    final forming =
        _habits.where((h) => h.coreShort == id && !h.formed).toList();
    // Skip Cores the player has no Golden Habit in — keeps the room focused.
    if (formed.isEmpty && forming.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hex,
                boxShadow: [BoxShadow(color: hex, blurRadius: 6)],
              ),
            ),
            const SizedBox(width: 8),
            Text(name.toUpperCase(), style: MM.displayX(size: 10, color: hex)),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 1, color: hex.withOpacity(0.2))),
            const SizedBox(width: 8),
            Text('${formed.length}',
                style:
                    MM.mono(size: 10, color: Colors.white.withOpacity(0.4))),
          ]),
          const SizedBox(height: 8),
          ...formed.map((h) => _trophyCard(h, hex)),
          ...forming.map((h) => _formingCard(h, hex)),
        ],
      ),
    );
  }

  Widget _trophyCard(_TrophyHabit h, Color hex) {
    final date = _fmtDate(h.formedAt);
    final sub = date.isNotEmpty
        ? 'FORMED ${date.toUpperCase()} · ${h.days} DAYS'
        : 'FORMED · ${h.days} DAYS';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassPanel(
        leftAccentColor: hex,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        boxShadow: [BoxShadow(color: hex.withOpacity(0.13), blurRadius: 14)],
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.4, -0.4),
                colors: [hex, hex.withOpacity(0.4)],
              ),
              boxShadow: [BoxShadow(color: hex.withOpacity(0.53), blurRadius: 12)],
            ),
            child: const Center(child: Text('🏆', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.name,
                    style: MM.body(color: Colors.white, weight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(sub,
                    style: MM.display(
                      size: 9,
                      color: Colors.white.withOpacity(0.5),
                      weight: FontWeight.w600,
                      letterSpacing: 9 * 0.08,
                    )),
              ],
            ),
          ),
          const SizedBox(width: 8),
          MMChip(label: h.manualFormed ? 'FORMED' : 'FORMED ✓', color: MM.teal),
        ]),
      ),
    );
  }

  /// A Golden Habit still forming — shows progress toward the 14-day standard
  /// and a manual "Mark as Formed" action.
  Widget _formingCard(_TrophyHabit h, Color hex) {
    final pct = (h.days / 14).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(h.name,
                    style: MM.body(
                        color: Colors.white.withOpacity(0.9),
                        weight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              Text('${h.days}/14 DAYS',
                  style: MM.display(
                      size: 9, color: Colors.white.withOpacity(0.45))),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation<Color>(hex),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: MMGhostButton(
                label: 'Mark as Formed',
                borderColor: MM.teal.withOpacity(0.5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onPressed: _busy ? null : () => _markFormed(h),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Achievements tab — the original Planet Conquest + badge grid.
class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab();

  @override
  Widget build(BuildContext context) {
    final achievements = [
      ['First Launch', 'Day 1 check-in', true, MM.blue, Icons.rocket_launch],
      ['7-Day Burn', 'Week streak', true, MM.red, Icons.local_fire_department],
      ['Moon Walker', 'Reached Moon', true, Color(0xFFCFD2DC), Icons.dark_mode],
      ['Mars Lander', 'Reached Mars', true, Color(0xFFD76B3A), Icons.public],
      ['Triple Core', '3 cores active', true, MM.yellow, Icons.bolt],
      ['Centurion', '100-day streak', false, MM.violet, Icons.timer],
      ['Full Crew', 'All 5 cores', false, MM.magenta, Icons.star],
      ['Pluto Pioneer', 'Reach Pluto', false, MM.teal, Icons.flight_takeoff],
    ];
    return Column(
      children: [
        GlassPanel(
          accent: true,
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PLANET CONQUEST',
                  style: MM.displayX(size: 10, color: MM.yellow)),
              const SizedBox(height: 4),
              Text('3 / 7', style: MM.display(size: 26, color: Colors.white)),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  height: 6,
                  color: Colors.white.withOpacity(0.1),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.42,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [MM.blue, MM.yellow]),
                        boxShadow: [BoxShadow(color: MM.yellow, blurRadius: 8)],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style:
                      MM.body(color: Colors.white.withOpacity(0.6), size: 11),
                  children: const [
                    TextSpan(text: 'Next target: '),
                    TextSpan(
                      text: 'Jupiter',
                      style: TextStyle(
                          color: Color(0xFFD9A86B),
                          fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: ' · 33 days to arrival'),
                  ],
                ),
              ),
            ],
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1,
          children: achievements.map((a) {
            final name = a[0] as String;
            final desc = a[1] as String;
            final earned = a[2] as bool;
            final hex = a[3] as Color;
            final icon = a[4] as IconData;
            return Opacity(
              opacity: earned ? 1 : 0.35,
              child: GlassPanel(
                padding: const EdgeInsets.all(14),
                borderColor: earned
                    ? hex.withOpacity(0.4)
                    : Colors.white.withOpacity(0.08),
                boxShadow: earned
                    ? [BoxShadow(color: hex.withOpacity(0.2), blurRadius: 16)]
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: hex, size: 32),
                    const SizedBox(height: 6),
                    Text(name,
                        textAlign: TextAlign.center,
                        style: MM.display(
                            size: 11,
                            color: earned
                                ? Colors.white
                                : Colors.white.withOpacity(0.5))),
                    const SizedBox(height: 2),
                    Text(desc,
                        textAlign: TextAlign.center,
                        style: MM.body(
                            color: Colors.white.withOpacity(0.5), size: 9)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── PROFILE ───────────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.onBack, this.onChat, this.onNav, this.onSignOut});
  final VoidCallback? onBack;
  final VoidCallback? onChat;
  final void Function(String key)? onNav;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final cores = [
      [MM.blue, 'MIND', 78],
      [MM.yellow, 'CAREER', 65],
      [MM.magenta, 'CONNECT', 42],
      [MM.teal, 'PHYSICAL', 81],
      [MM.violet, 'EMOTION', 54],
    ];
    return ScreenShell(
      title: 'Profile',
      subtitle: 'CMDR · ALEX MOORE',
      accent: MM.yellow,
      onBack: onBack,
      onChat: onChat,
      onNav: onNav,
      child: Column(
        children: [
          GlassPanel(
            accent: true,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            margin: const EdgeInsets.only(bottom: 14),
            child: Row(children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.4, -0.4),
                    radius: 0.9,
                    colors: [MM.yellow, MM.red],
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x8CFFC629), blurRadius: 16),
                  ],
                ),
                child: const Center(
                  child: Text('A',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w800,
                          fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alex Moore',
                        style: MM.display(size: 16, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('NAVIGATOR · LVL 12',
                        style: MM.displayX(size: 10, color: MM.yellow)),
                    const SizedBox(height: 8),
                    Row(children: [
                      MMChip(label: '47🔥', color: MM.teal),
                      const SizedBox(width: 6),
                      MMChip(label: '8,420 MS', color: MM.yellow),
                    ]),
                  ],
                ),
              ),
            ]),
          ),
          GlassPanel(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('5-CORE BALANCE',
                    style: MM.displayX(
                        size: 10, color: Colors.white.withOpacity(0.5))),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: CustomPaint(
                      painter: _RadarPainter(
                        scores: cores.map((c) => c[2] as int).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          GlassPanel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SettingTile(label: 'Notifications', onTap: () {}),
                _SettingTile(label: 'Connected calendars', onTap: () {}),
                _SettingTile(label: 'Privacy', onTap: () {}),
                _SettingTile(label: 'Subscription · PRO', onTap: () {}),
                _SettingTile(
                  label: 'Sign out',
                  color: MM.red,
                  onTap: onSignOut ?? () {},
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.label,
    required this.onTap,
    this.color,
    this.isLast = false,
  });
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool isLast;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
        ),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: MM.body(color: color ?? Colors.white, size: 13)),
          ),
          Icon(Icons.chevron_right,
              color: Colors.white.withOpacity(0.4), size: 18),
        ]),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.scores});
  final List<int> scores;
  static const _hexes = [MM.blue, MM.yellow, MM.magenta, MM.teal, MM.violet];

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) * 0.73;
    final n = scores.length;

    // Concentric rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 0.5;
    for (final m in [0.25, 0.5, 0.75, 1.0]) {
      final p = Path();
      for (int i = 0; i < n; i++) {
        final a = -math.pi / 2 + (i / n) * math.pi * 2;
        final x = cx + math.cos(a) * r * m;
        final y = cy + math.sin(a) * r * m;
        if (i == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      p.close();
      canvas.drawPath(p, ringPaint);
    }
    // Spokes
    final spoke = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 0.5;
    for (int i = 0; i < n; i++) {
      final a = -math.pi / 2 + (i / n) * math.pi * 2;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + math.cos(a) * r, cy + math.sin(a) * r),
        spoke,
      );
    }
    // Filled polygon
    final fill = Paint()..color = MM.blue.withOpacity(0.18);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = MM.blue
      ..strokeWidth = 1.5;
    final pts = <Offset>[];
    for (int i = 0; i < n; i++) {
      final a = -math.pi / 2 + (i / n) * math.pi * 2;
      final rr = (scores[i] / 100) * r;
      pts.add(Offset(cx + math.cos(a) * rr, cy + math.sin(a) * rr));
    }
    final poly = Path()..addPolygon(pts, true);
    canvas.drawPath(poly, fill);
    canvas.drawPath(poly, stroke);
    // Dots
    for (int i = 0; i < n; i++) {
      canvas.drawCircle(pts[i], 3, Paint()..color = _hexes[i]);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => old.scores != scores;
}

class _CoreDot extends StatelessWidget {
  const _CoreDot({required this.color, this.size = 10});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 8)],
      ),
    );
  }
}
