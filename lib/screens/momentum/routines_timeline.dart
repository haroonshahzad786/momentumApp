import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/checkin_service.dart' show CheckinService;
import '../../services/routine_schedule.dart';
import '../../theme/momentum_tokens.dart';
import '../../services/all_habits.dart' show HabitColor;

// Routines Timeline + By Core (design/ref/routines-timeline-design). Pure view:
// the owning screen loads habits, schedules and the day log, and handles the
// writes through the callbacks.

const _kInk = Color(0xFF0A1033);
const _kPanel = Color(0xFF0D1543);
const _kPanel2 = Color(0xFF121C4F);
const _kLine = Color(0xFF1F2B6C);
const _kLine2 = Color(0xFF24327A);
const _kMuted = Color(0xFFA9B4DC);
const _kFaint = Color(0xFF8D98C7);
const _kDone = Color(0xFF00A98F);
const _kDoneHi = Color(0xFF2EE6C5);
const _kAnchor = Color(0xFFFFC629);

/// Width of the time-label column on wide layouts (fits "After breakfast").
const double _kTimeCol = 196;

const _kCoreOrder = [
  'mindset',
  'career',
  'relationships',
  'physical',
  'emotional',
];
const _kCoreName = {
  'mindset': 'Mindset',
  'career': 'Career & Finances',
  'relationships': 'Relationships',
  'physical': 'Physical Health',
  'emotional': 'Emotional & Mental Health',
};
const _kCoreEmoji = {
  'mindset': '🧠',
  'career': '💰',
  'relationships': '👥',
  'physical': '💪',
  'emotional': '🧘',
};

Color _coreColor(String core) => MM.coreColor[core] ?? MM.blue;

/// One habit as the timeline sees it.
class TlHabit {
  TlHabit({
    required this.key,
    required this.name,
    required this.core,
    required this.isRoutine,
    this.color,
    this.dayCount,
    this.flagged = false,
    this.isExperiment = false,
    this.habitId,
    this.slot,
    this.triggers = const [],
  });

  final String key;
  final String name;

  /// Short Core id.
  final String core;
  final bool isRoutine;
  final HabitColor? color;
  final int? dayCount;
  final bool flagged;
  final bool isExperiment;
  final String? habitId;

  /// Routines only; null = unscheduled.
  final ResolvedSlot? slot;
  final List<String> triggers;

  /// 'Struggling' | 'Forming' | 'Formed' | null (untagged).
  String? get statusLabel => switch (color) {
        HabitColor.red => 'Struggling',
        HabitColor.orange => 'Forming',
        HabitColor.green => 'Formed',
        _ => null,
      };

  Color get statusColor => switch (color) {
        HabitColor.red => const Color(0xFFFF4F6D),
        HabitColor.green => _kDoneHi,
        _ => const Color(0xFFFFC27A),
      };

  String get statusText {
    final s = statusLabel;
    if (s == null) return '';
    if (color == HabitColor.orange && dayCount != null) {
      return '$s · Day ${dayCount!.clamp(0, 14)}/14';
    }
    return s;
  }
}

enum _View { timeline, byCore }

class RoutinesTimeline extends StatefulWidget {
  const RoutinesTimeline({
    super.key,
    required this.routines,
    required this.nonRoutines,
    required this.anchors,
    required this.logFor,
    required this.weekDots,
    required this.selected,
    required this.onSelectDay,
    required this.onToggleDone,
    required this.onLog,
    required this.onAdd,
    required this.onOpen,
    required this.onCheckIn,
    this.showTitle = true,
  });

  final List<TlHabit> routines;
  final List<TlHabit> nonRoutines;
  final List<Anchor> anchors;
  final HabitDayLog logFor;

  /// Mon→Sun dot colours (null = no dot).
  final List<Color?> weekDots;
  final DateTime selected;
  final ValueChanged<DateTime> onSelectDay;
  final void Function(TlHabit h, bool done) onToggleDone;
  final void Function(TlHabit h) onLog;

  /// Opens Add Habit, optionally with a Core / anchor already picked.
  final void Function({String? core, String? anchorId}) onAdd;
  final void Function(TlHabit h) onOpen;
  final VoidCallback? onCheckIn;

  /// False inside a screen that already carries the "Routines" title.
  final bool showTitle;

  @override
  State<RoutinesTimeline> createState() => _RoutinesTimelineState();
}

class _RoutinesTimelineState extends State<RoutinesTimeline> {
  _View _view = _View.timeline;
  int _tab = 0; // narrow: 0 routine | 1 non-routine
  final Set<int> _openGaps = {};
  Timer? _tick;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadPref();
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _loadPref() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (p.getString('routines_view') == 'core' && mounted) {
        setState(() => _view = _View.byCore);
      }
    } catch (_) {}
  }

  Future<void> _setView(_View v) async {
    setState(() => _view = v);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('routines_view', v == _View.byCore ? 'core' : 'timeline');
    } catch (_) {}
  }

  bool get _isToday =>
      CheckinService.dayId(widget.selected) == CheckinService.dayId(_now);
  /// Earlier days are history: view-only, nothing can be ticked or logged.
  bool get _isFuture => !_isToday;

  /// A past day with nothing recorded shows an empty timeline.
  bool get _histEmpty =>
      _isFuture &&
      widget.logFor.done.isEmpty &&
      widget.logFor.logs.isEmpty;

  bool _done(TlHabit h) => widget.logFor.done.containsKey(h.key);
  String? _doneAt(TlHabit h) => widget.logFor.done[h.key];
  List<String> _logs(TlHabit h) => widget.logFor.logs[h.key] ?? const [];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final narrow = c.maxWidth < 760;
      final all = widget.routines.length + widget.nonRoutines.length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(narrow),
          const SizedBox(height: 16),
          _weekCard(narrow),
          const SizedBox(height: 22),
          if (all == 0)
            _emptyAll()
          else if (_view == _View.byCore)
            _byCore(narrow)
          else if (narrow)
            _narrowTimeline()
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 68, child: _routineColumn(narrow)),
                const SizedBox(width: 24),
                Expanded(flex: 32, child: _nonRoutinePanel()),
              ],
            ),
        ],
      );
    });
  }

  // ── Header ────────────────────────────────────────────────
  Widget _header(bool narrow) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DAILY ORBIT',
            style: MM.display(size: 11, color: _kDone, weight: FontWeight.w600)
                .copyWith(letterSpacing: 3)),
        const SizedBox(height: 4),
        Text('Routines', style: MM.display(size: narrow ? 28 : 38)),
      ],
    );
    final switcher = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kLine),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _seg('TIMELINE', _view == _View.timeline, () => _setView(_View.timeline)),
        _seg('BY CORE', _view == _View.byCore, () => _setView(_View.byCore)),
      ]),
    );
    final add = _outlineBtn('+  ADD HABIT', () => widget.onAdd());
    final checkIn = widget.onCheckIn == null
        ? const SizedBox.shrink()
        : _pillBtn(narrow ? 'CHECK-IN →' : 'DAILY CHECK-IN →', widget.onCheckIn);
    if (narrow) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (widget.showTitle) ...[
          Row(children: [Expanded(child: title), checkIn]),
          const SizedBox(height: 12),
        ],
        Row(children: [
          switcher,
          const Spacer(),
          add,
          if (!widget.showTitle && widget.onCheckIn != null) ...[
            const SizedBox(width: 8),
            checkIn,
          ],
        ]),
      ]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.showTitle) Expanded(child: title) else const Spacer(),
        switcher,
        const SizedBox(width: 12),
        add,
        if (widget.onCheckIn != null) ...[const SizedBox(width: 12), checkIn],
      ],
    );
  }

  Widget _seg(String label, bool on, VoidCallback tap) => Semantics(
        button: true,
        selected: on,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: tap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? MM.blue : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(label,
                style: MM.display(
                    size: 11,
                    color: on ? Colors.white : _kMuted,
                    weight: FontWeight.w600)),
          ),
        ),
      );

  Widget _outlineBtn(String label, VoidCallback tap) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: tap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kLine2),
          ),
          child: Text(label,
              style: MM.display(size: 11, weight: FontWeight.w600)),
        ),
      );

  Widget _pillBtn(String label, VoidCallback? tap) => InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: tap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: MM.blue,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(color: MM.blue.withOpacity(0.4), blurRadius: 18),
            ],
          ),
          child: Text(label, style: MM.display(size: 11, weight: FontWeight.w700)),
        ),
      );

  // ── Week strip + today's orbit ────────────────────────────
  Widget _weekCard(bool narrow) {
    // History strip: the last 7 days, today last.
    final today = DateTime(_now.year, _now.month, _now.day);
    const names = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final days = Row(children: [
      for (var i = 0; i < 7; i++)
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 6 ? 0 : (narrow ? 5 : 8)),
            child: _dayCell(
              names[DateTime(today.year, today.month, today.day - 6 + i)
                      .weekday -
                  1],
              DateTime(today.year, today.month, today.day - 6 + i),
              widget.weekDots.length > i ? widget.weekDots[i] : null,
              narrow,
            ),
          ),
        ),
    ]);

    final total = widget.routines.length;
    final done = widget.routines.where(_done).length;
    final orbit = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Text(_isToday ? "Today's orbit" : 'That day',
              style: MM.body(size: 13, color: _kMuted)),
          const Spacer(),
          Text('$done / $total done',
              style: MM.display(size: 12, color: _kDoneHi)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : done / total,
            minHeight: 7,
            backgroundColor: _kLine,
            valueColor: const AlwaysStoppedAnimation(_kDoneHi),
          ),
        ),
      ],
    );
    final all = [...widget.routines, ...widget.nonRoutines];
    int n(HabitColor c) => all.where((h) => h.color == c).length;
    final counts = Wrap(spacing: 16, runSpacing: 4, children: [
      _count('Struggling', n(HabitColor.red), const Color(0xFFFF4F6D)),
      _count('Forming', n(HabitColor.orange), const Color(0xFFFFA53D)),
      _count('Formed', n(HabitColor.green), _kDoneHi),
    ]);

    return Container(
      padding: EdgeInsets.all(narrow ? 10 : 18),
      decoration: BoxDecoration(
        color: _kPanel.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kLine),
      ),
      child: narrow
          ? Column(children: [days])
          : Row(children: [
              Expanded(flex: 5, child: days),
              const SizedBox(width: 28),
              Expanded(flex: 3, child: orbit),
              const SizedBox(width: 24),
              counts,
            ]),
    );
  }

  Widget _count(String label, int n, Color c) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$n $label', style: MM.body(size: 12, color: _kMuted)),
      ]);

  Widget _dayCell(String name, DateTime d, Color? dot, bool narrow) {
    final sel = CheckinService.dayId(d) == CheckinService.dayId(widget.selected);
    final isToday = CheckinService.dayId(d) == CheckinService.dayId(_now);
    return Semantics(
      button: true,
      selected: sel,
      label: '$name ${d.day}',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => widget.onSelectDay(d),
        child: Container(
          constraints: BoxConstraints(minHeight: narrow ? 60 : 72),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            // History days are greyed; only today wears the brand blue.
            color: sel
                ? (isToday ? MM.blue : const Color(0xFF3A4378))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: sel
                    ? (isToday ? MM.blue : const Color(0xFF5A659E))
                    : _kLine2),
            boxShadow: sel && isToday
                ? [BoxShadow(color: MM.blue.withOpacity(0.4), blurRadius: 14)]
                : null,
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(name,
                style: MM.body(
                    size: 10.5, color: sel ? Colors.white : _kMuted)),
            const SizedBox(height: 2),
            Text('${d.day}',
                style: MM.display(
                    size: narrow ? 15 : 18,
                    color: isToday || sel ? Colors.white : _kMuted)),
            const SizedBox(height: 3),
            if (isToday && !narrow)
              Text('TODAY', style: MM.body(size: 9, color: Colors.white))
            else
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    color: dot ?? Colors.transparent, shape: BoxShape.circle),
              ),
          ]),
        ),
      ),
    );
  }

  // ── Timeline ──────────────────────────────────────────────
  Widget _narrowTimeline() {
    final done = widget.routines.where(_done).length;
    Widget tab(int i, String label, String badge, Color badgeColor) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _tab = i),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _tab == i ? const Color(0xFF0B3A4A) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(label,
                    style: MM.display(
                        size: 11,
                        color: _tab == i ? Colors.white : _kMuted,
                        weight: FontWeight.w600)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(badge,
                      style: MM.display(size: 10, color: badgeColor)),
                ),
              ]),
            ),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _kPanel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kLine),
        ),
        child: Row(children: [
          tab(0, 'ROUTINE', '$done/${widget.routines.length}', _kDoneHi),
          tab(1, 'NON-ROUTINE', '${widget.nonRoutines.length}',
              const Color(0xFFA78BFA)),
        ]),
      ),
      const SizedBox(height: 16),
      if (_tab == 0) _timelineBody(true) else _nonRoutinePanel(narrow: true),
    ]);
  }

  Widget _routineColumn(bool narrow) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('ROUTINE', style: MM.display(size: 20)),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text('DAILY ORBIT · THE SEA OF GREEN',
              style: MM.display(size: 10.5, color: _kDone, weight: FontWeight.w600)),
        ),
        const Spacer(),
        _legendMini(Icons.access_time, 'Set time', MM.blue),
        const SizedBox(width: 18),
        _legendMini(Icons.link, 'Anchored to a moment', _kAnchor),
      ]),
      const SizedBox(height: 14),
      _timelineBody(false),
    ]);
  }

  Widget _legendMini(IconData i, String t, Color c) => Row(children: [
        Icon(i, size: 15, color: c),
        const SizedBox(width: 6),
        Text(t, style: MM.body(size: 12, color: _kMuted)),
      ]);

  Widget _timelineBody(bool narrow) {
    if (_histEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _kPanel.withOpacity(0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kLine),
        ),
        child: Text('Nothing was recorded on this day.',
            style: MM.body(size: 13.5, color: _kMuted)),
      );
    }
    final entries = _buildEntries();
    final unscheduled = widget.routines.where((h) => h.slot == null).toList();
    final nextKey = _nextPending();
    final rows = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final prevDone = i > 0 && entries[i - 1].habit != null && _done(entries[i - 1].habit!);
      switch (e.kind) {
        case _Kind.label:
          rows.add(Padding(
            padding: EdgeInsets.only(
                left: narrow ? 92 : _kTimeCol + 56, top: i == 0 ? 0 : 6, bottom: 8),
            child: Text(e.label!,
                style: MM.display(
                    size: 10.5, color: _kFaint, weight: FontWeight.w600)
                    .copyWith(letterSpacing: 3)),
          ));
        case _Kind.gap:
          rows.add(_gapRow(e, i, narrow));
        case _Kind.now:
          rows.add(_nowRow(narrow));
        case _Kind.emptyAnchor:
          rows.add(_emptyAnchorRow(e.anchor!, narrow));
        case _Kind.habit:
          rows.add(_habitRow(e, narrow, e.habit!.key == nextKey, prevDone));
      }
    }
    return Container(
      padding: EdgeInsets.fromLTRB(narrow ? 0 : 20, 20, narrow ? 0 : 20, 20),
      decoration: narrow
          ? null
          : BoxDecoration(
              color: _kPanel.withOpacity(0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kLine),
            ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // One continuous rail behind every row, so nodes always sit on it and
        // gaps / NOW / empty anchors never break it.
        Opacity(
          opacity: _isFuture ? 0.72 : 1,
          child: Stack(children: [
          Positioned(
            left: (narrow ? 64.0 : _kTimeCol) + (narrow ? 28.0 : 56.0) / 2 - 1,
            top: 0,
            bottom: 0,
            width: 2,
            child: const ColoredBox(color: _kLine2),
          ),
          Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
        ])),
        if (unscheduled.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('ANYTIME · NO SLOT YET',
                style: MM.display(size: 10.5, color: _kFaint)
                    .copyWith(letterSpacing: 3)),
          ),
          for (final h in unscheduled) ...[
            _habitCard(h, narrow, h.key == nextKey, null),
            const SizedBox(height: 10),
          ],
        ],
      ]),
    );
  }

  String? _nextPending() {
    if (_isFuture) return null;
    final pending = widget.routines.where((h) => h.slot != null && !_done(h));
    if (pending.isEmpty) return null;
    final nowM = _now.hour * 60 + _now.minute;
    final sorted = pending.toList()
      ..sort((a, b) => a.slot!.minutes.compareTo(b.slot!.minutes));
    if (_isToday) {
      for (final h in sorted) {
        if (h.slot!.minutes >= nowM - 30) return h.key;
      }
    }
    return sorted.first.key;
  }

  List<_Entry> _buildEntries() {
    final sched = widget.routines.where((h) => h.slot != null).toList()
      ..sort((a, b) {
        final c = a.slot!.minutes.compareTo(b.slot!.minutes);
        return c != 0 ? c : a.name.compareTo(b.name);
      });
    final used = {
      for (final h in sched)
        if (h.slot!.anchor != null) h.slot!.anchor!.id,
    };
    // (minutes, entry) so habits and empty anchors interleave by time.
    final timed = <(int, int, _Entry)>[];
    for (var i = 0; i < sched.length; i++) {
      timed.add((sched[i].slot!.minutes, 1, _Entry.habit(sched[i])));
    }
    // Unclaimed anchors invite stacking, but showing every one is noisy: today
    // only the upcoming ones (max 2); other days just the last of the day.
    final nowMin = _now.hour * 60 + _now.minute;
    final free = [
      for (final a in widget.anchors)
        if (!used.contains(a.id)) a,
    ];
    final offer = _isToday
        ? free.where((a) => a.minutes > nowMin).take(2)
        : <Anchor>[];
    for (final a in offer) {
      timed.add((a.minutes, 2, _Entry.emptyAnchor(a)));
    }
    timed.sort((a, b) {
      final c = a.$1.compareTo(b.$1);
      return c != 0 ? c : a.$2.compareTo(b.$2);
    });

    final out = <_Entry>[];
    final nowM = _now.hour * 60 + _now.minute;
    var nowPlaced = !_isToday;
    String? section;
    int? prevEnd;
    for (final (m, _, e) in timed) {
      final s = m < 720 ? 'MORNING' : (m < 1020 ? 'AFTERNOON' : 'EVENING');
      if (!nowPlaced && nowM < m) {
        out.add(_Entry.now());
        nowPlaced = true;
      }
      if (prevEnd != null) {
        final gs = ((prevEnd + 30) / 60).ceil() * 60;
        final ge = (m ~/ 60) * 60;
        if (ge - gs >= 120) out.add(_Entry.gap(gs, ge));
      }
      if (s != section) {
        out.add(_Entry.label(s));
        section = s;
      }
      out.add(e);
      prevEnd = m;
    }
    if (!nowPlaced) out.add(_Entry.now());
    // A 2nd+ habit stacked on the same slot shares the first one's time label.
    for (var i = 1; i < out.length; i++) {
      final a = out[i - 1].habit, b = out[i].habit;
      if (a != null && b != null && a.slot!.minutes == b.slot!.minutes &&
          a.slot!.anchor?.id == b.slot!.anchor?.id) {
        out[i].firstInSlot = false;
      }
    }
    return out;
  }

  Widget _gapRow(_Entry e, int idx, bool narrow) {
    final open = _openGaps.contains(idx);
    final hours = (e.gapEnd! - e.gapStart!) ~/ 60;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: narrow ? 64 : _kTimeCol),
        _railPlain(narrow, dotted: true),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(
                  () => open ? _openGaps.remove(idx) : _openGaps.add(idx)),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kLine2),
                ),
                child: Wrap(spacing: 8, children: [
                  Text(
                      narrow
                          ? '$hours open hours'
                          : '$hours open hours · ${fmtHm(e.gapStart!)} – ${fmtHm(e.gapEnd!)}',
                      style: MM.body(size: 12.5, color: _kMuted)),
                  Text(open ? 'Collapse' : 'Expand',
                      style: MM.body(
                          size: 12.5, color: MM.blue, weight: FontWeight.w700)),
                ]),
              ),
            ),
            if (open)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var m = e.gapStart!; m <= e.gapEnd!; m += 60)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('${fmtHm(m)}   open',
                            style: MM.body(size: 11.5, color: _kFaint)),
                      ),
                  ],
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _railPlain(bool narrow, {bool dotted = false}) => SizedBox(
        width: narrow ? 28 : 56,
        height: 44,
      );

  Widget _nowRow(bool narrow) {
    final hm = fmtHm(_now.hour * 60 + _now.minute);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(
          width: narrow ? 64 : _kTimeCol,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: narrow ? 6 : 10, vertical: 5),
              decoration: BoxDecoration(
                color: MM.red,
                borderRadius: BorderRadius.circular(99),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(narrow ? hm : 'NOW $hm',
                    maxLines: 1,
                    softWrap: false,
                    style: MM.display(size: 10, weight: FontWeight.w700)),
              ),
            ),
          ),
        ),
        SizedBox(
          width: narrow ? 28 : 56,
          child: Center(
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: MM.red,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: MM.red.withOpacity(0.6), blurRadius: 8)],
              ),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (_, c) => Row(children: [
              for (var x = 0.0; x < c.maxWidth - 12; x += 12)
                Container(
                    width: 6,
                    height: 2,
                    margin: const EdgeInsets.only(right: 6),
                    color: MM.red),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _emptyAnchorRow(Anchor a, bool narrow) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(
              width: narrow ? 64 : _kTimeCol,
              child: narrow
                  ? _usually(a.usualTime, a, narrow)
                  : _anchorLabel(a)),
          SizedBox(
            width: narrow ? 28 : 56,
            child: Center(
              child: Container(
                width: narrow ? 24 : 38,
                height: narrow ? 24 : 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kPanel,
                  border: Border.all(color: _kLine2, width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _isFuture ? null : () => widget.onAdd(anchorId: a.id),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kLine2),
                ),
                child: Text(
                    narrow
                        ? '+  Stack a habit · ${a.label.toLowerCase()}'
                        : '+  Stack a habit on this anchor',
                    style: MM.body(size: 13.5, color: _kMuted)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _usually(String hm, Anchor a, bool narrow) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(Icons.link, size: 12, color: _kAnchor),
            const SizedBox(width: 2),
            Text('~$hm', style: MM.body(size: 11.5, color: _kMuted)),
          ],
        ),
      );

  Widget _anchorLabel(Anchor a) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              color: _kAnchor.withOpacity(0.07),
              border: Border.all(color: _kAnchor.withOpacity(0.7)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.link, size: 14, color: _kAnchor),
              const SizedBox(width: 6),
              Text(a.label,
                  style: MM.body(
                      size: 12.5,
                      color: _kAnchor,
                      weight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 4),
          Text('usually ~${a.usualTime}',
              style: MM.body(size: 11.5, color: _kMuted)),
        ],
      ));

  Widget _timeLabel(TlHabit h, bool narrow, bool first) {
    if (!first) return const SizedBox.shrink();
    final s = h.slot!;
    if (s.isAnchored) {
      return narrow ? _usually(s.anchor!.usualTime, s.anchor!, narrow) : _anchorLabel(s.anchor!);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(fmtHm(s.minutes),
            style: MM.display(size: narrow ? 13 : 17, weight: FontWeight.w700)),
        if (!narrow)
          Text('Set time', style: MM.body(size: 12, color: _kMuted)),
      ],
    );
  }

  Widget _habitRow(_Entry e, bool narrow, bool isNext, bool prevDone) {
    final h = e.habit!;
    final done = _done(h);
    final c = _coreColor(h.core);
    final nodeSize = narrow ? 28.0 : 44.0;
    final first = e.firstInSlot;
    final missed = _isFuture && !done;
    const missRed = Color(0xFFFF4F6D);
    final node = done
        ? Container(
            width: nodeSize,
            height: nodeSize,
            decoration: const BoxDecoration(color: _kDone, shape: BoxShape.circle),
            child: Icon(Icons.check, color: Colors.white, size: nodeSize * 0.5),
          )
        : Container(
            width: nodeSize,
            height: nodeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kPanel, // opaque: the rail must not show through the ring
              border: Border.all(
                  color: missed ? missRed.withOpacity(0.7) : isNext ? c : (h.slot!.isAnchored ? c.withOpacity(0.8) : c.withOpacity(0.9)),
                  width: 2.5),
            ),
            child: isNext
                ? Center(
                    child: Container(
                        width: nodeSize * 0.25,
                        height: nodeSize * 0.25,
                        decoration: BoxDecoration(color: c, shape: BoxShape.circle)))
                : (missed
                    ? Icon(Icons.close,
                        size: nodeSize * 0.45, color: missRed.withOpacity(0.8))
                    : null),
          );
    // No IntrinsicHeight: the card holds a Wrap, whose intrinsic height is wrong
    // and overflowed. The rail line is a Stack layer behind the row instead.
    final timeW = narrow ? 64.0 : _kTimeCol;
    final railW = narrow ? 28.0 : 56.0;
    return Stack(children: [
      // The rail is drawn once for the whole timeline; a done habit only tints
      // the stretch above its node.
      if (done)
        Positioned(
          left: timeW + railW / 2 - 1,
          top: 0,
          height: 10 + nodeSize / 2,
          width: 2,
          child: const ColoredBox(color: _kDone),
        ),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: timeW,
          child: Padding(
            padding: const EdgeInsets.only(top: 12, right: 10),
            child: Align(
                alignment: Alignment.topRight,
                child: _timeLabel(h, narrow, first)),
          ),
        ),
        SizedBox(
          width: railW,
          child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(child: node)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _habitCard(h, narrow, isNext, e.habit!.slot),
          ),
        ),
      ]),
    ]);
  }

  Widget _habitCard(TlHabit h, bool narrow, bool isNext, ResolvedSlot? slot) {
    final done = _done(h);
    final c = _coreColor(h.core);
    final chips = <Widget>[
      if (h.isExperiment && narrow) _chip('Experiment', _kDoneHi, tinted: true),
      _chip(_kCoreName[h.core]?.split(' ').first ?? h.core, c, tinted: true),
      if (h.statusLabel != null)
        _chip(h.statusText, h.statusColor, tinted: true),
      if (_isFuture && !done) _chip('Missed', const Color(0xFFFF4F6D), tinted: true),
      if (done && _doneAt(h) != null)
        _plain('Done ${_doneAt(h)}')
      else if (isNext && _isToday)
        _plain('Up next')
      else if (slot?.endTime != null && slot?.anchor == null)
        _plain('${fmtHm(slot!.minutes)} – ${slot.endTime}'),
    ];
    final name = Row(mainAxisSize: MainAxisSize.min, children: [
      Flexible(
        child: Text(h.name,
            style: MM.body(
                size: 16,
                color: done ? _kMuted : Colors.white,
                weight: FontWeight.w600)
                .copyWith(
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: _kMuted)),
      ),
      if (h.flagged)
        const Padding(
          padding: EdgeInsets.only(left: 6),
          child: Icon(Icons.warning_amber_rounded, size: 17, color: _kAnchor),
        ),
      if (h.isExperiment && !narrow)
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: _chip('Experiment', _kDoneHi, tinted: true),
        ),
    ]);

    final action = done
        ? InkWell(
            onTap: () => widget.onOpen(h),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: narrow
                  ? const Icon(Icons.chevron_right, size: 22, color: _kMuted)
                  : Text('Details →',
                      style: MM.body(size: 12.5, color: _kMuted)),
            ),
          )
        : _isFuture
        ? const SizedBox.shrink()
        : Semantics(
            button: true,
            label: 'Mark ${h.name} done',
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => widget.onToggleDone(h, true),
              child: Container(
                width: narrow ? 40 : 44,
                height: narrow ? 40 : 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isNext ? c : _kLine2, width: 2),
                ),
                child: Icon(Icons.check,
                    size: 20, color: isNext ? c : _kMuted),
              ),
            ),
          );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => widget.onOpen(h),
      child: Container(
        padding: EdgeInsets.all(narrow ? 10 : 14),
        decoration: BoxDecoration(
          color: isNext ? Color.alphaBlend(c.withOpacity(0.08), _kPanel2) : _kPanel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isNext ? c : (done ? _kDone.withOpacity(0.5) : _kLine)),
          boxShadow:
              isNext ? [BoxShadow(color: c.withOpacity(0.28), blurRadius: 18)] : null,
        ),
        child: Row(children: [
          _coreTile(h.core, narrow ? 34 : 44),
          SizedBox(width: narrow ? 10 : 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Narrow: the anchor pill lives inside the card (design).
                  if (narrow && slot?.isAnchored == true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: _kAnchor.withOpacity(0.7)),
                        ),
                        child: Text(slot!.anchor!.label,
                            style: MM.body(
                                size: 11,
                                color: _kAnchor,
                                weight: FontWeight.w600)),
                      ),
                    ),
                  name,
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: chips),
                ]),
          ),
          SizedBox(width: narrow ? 4 : 8),
          action,
        ]),
      ),
    );
  }

  Widget _coreTile(String core, double size) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _coreColor(core).withOpacity(0.16),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(_kCoreEmoji[core] ?? '•',
            style: TextStyle(fontSize: size * 0.45)),
      );

  Widget _chip(String t, Color c, {bool tinted = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: c.withOpacity(0.16),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(t,
            style: MM.body(size: 12, color: c, weight: FontWeight.w600)),
      );

  Widget _plain(String t) =>
      Text(t, style: MM.body(size: 12.5, color: _kMuted));

  // ── Non-routine panel ─────────────────────────────────────
  Widget _nonRoutinePanel({bool narrow = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (!narrow) ...[
        Text('NON-ROUTINE', style: MM.display(size: 20)),
        const SizedBox(height: 4),
        Text('IDENTITY HABITS → TROPHY ROOM',
            style: MM.display(size: 10.5, color: _kAnchor, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
            'No clock. These fire when a moment calls for them — log each time you use one.',
            style: MM.body(size: 13, color: _kMuted)),
        const SizedBox(height: 14),
      ] else ...[
        Row(children: [
          Text('NON-ROUTINE', style: MM.display(size: 16)),
          const Spacer(),
          Text('Triggered, not timed',
              style: MM.body(size: 12, color: _kMuted)),
        ]),
        const SizedBox(height: 12),
      ],
      for (final h in widget.nonRoutines) ...[
        _nonRoutineCard(h, narrow),
        const SizedBox(height: 12),
      ],
      if (!_isFuture)
      InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => widget.onAdd(),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kLine2),
          ),
          child: Text('+   Add an identity habit',
              style: MM.body(size: 14, color: _kMuted)),
        ),
      ),
      if (!narrow) ...[const SizedBox(height: 16), _legendCard()],
    ]);
  }

  Widget _nonRoutineCard(TlHabit h, bool narrow) {
    final logs = _logs(h);
    final c = _coreColor(h.core);
    final last = logs.isEmpty ? null : logs.last.substring(0, math.min(5, logs.last.length));
    final stats = Text(
        logs.isEmpty
            ? 'Not logged yet'
            : '${logs.length}× today · last at $last',
        style: MM.body(size: 13, color: Colors.white));
    final logBtn0 = Semantics(
      button: true,
      label: 'Log ${h.name}',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isFuture ? null : () => widget.onLog(h),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF7C5CF2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(narrow ? '+ LOG' : '+  LOG IT',
              style: MM.display(size: 11, weight: FontWeight.w700)),
        ),
      ),
    );
    final logBtn = _isFuture ? const SizedBox.shrink() : logBtn0;
    if (narrow) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kPanel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kLine),
        ),
        child: Row(children: [
          _coreTile(h.core, 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(h.name,
                  style: MM.body(size: 15, color: Colors.white, weight: FontWeight.w600)),
              Text(_kCoreName[h.core] ?? '',
                  style: MM.body(size: 11.5, color: c)),
              const SizedBox(height: 6),
              Text('TRIGGERS WHEN',
                  style: MM.display(size: 9, color: _kFaint)
                      .copyWith(letterSpacing: 2.5)),
              const SizedBox(height: 2),
              Text(
                  h.triggers.isEmpty
                      ? 'Whenever it comes up'
                      : h.triggers.join(' · '),
                  style: MM.body(size: 12, color: Colors.white)),
              const SizedBox(height: 4),
              Text('${logs.length}× today',
                  style: MM.body(size: 12, color: _kMuted)),
            ]),
          ),
          logBtn,
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kLine),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          _coreTile(h.core, 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(h.name,
                  style: MM.body(size: 16, color: Colors.white, weight: FontWeight.w600)),
              Text(_kCoreName[h.core] ?? '',
                  style: MM.body(size: 12, color: c)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Text('TRIGGERS WHEN',
            style: MM.display(size: 10, color: _kFaint).copyWith(letterSpacing: 3)),
        const SizedBox(height: 8),
        if (h.triggers.isEmpty)
          Text('Not set — open the habit to add a trigger.',
              style: MM.body(size: 12, color: _kFaint))
        else
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in h.triggers)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: _kLine2),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.bolt, size: 15, color: _kMuted),
                  const SizedBox(width: 6),
                  Flexible(
                      child: Text(t,
                          style: MM.body(size: 12.5, color: Colors.white))),
                ]),
              ),
          ]),
        const Divider(height: 28, color: _kLine),
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              stats,
              if (h.statusLabel != null)
                Text(h.statusText,
                    style: MM.body(size: 12, color: h.statusColor)),
            ]),
          ),
          logBtn,
        ]),
      ]),
    );
  }

  Widget _legendCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _kPanel.withOpacity(0.7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kLine),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('HOW HABITS LAND ON YOUR ORBIT',
              style: MM.display(size: 10, color: _kFaint).copyWith(letterSpacing: 3)),
          const SizedBox(height: 12),
          _legendRow(Icons.access_time, MM.blue, 'Set time',
              ' – pinned to the clock, e.g. 07:00.'),
          _legendRow(Icons.link, _kAnchor, 'Anchored',
              ' – stacked on a daily moment like a meal. Sits at your usual time for that moment.'),
          _legendRow(Icons.bolt, const Color(0xFFA78BFA), 'Non-routine',
              ' – no slot; triggered by a situation.'),
        ]),
      );

  Widget _legendRow(IconData i, Color c, String b, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(i, size: 18, color: c),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(
                  text: b,
                  style: MM.body(size: 13, color: Colors.white, weight: FontWeight.w700)),
              TextSpan(text: t, style: MM.body(size: 13, color: _kMuted)),
            ])),
          ),
        ]),
      );

  // ── By Core ───────────────────────────────────────────────
  Widget _byCore(bool narrow) {
    final empty = [
      for (final c in _kCoreOrder)
        if (!widget.routines.any((h) => h.core == c) &&
            !widget.nonRoutines.any((h) => h.core == c))
          c,
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('BY CORE', style: MM.display(size: 20)),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text('FIRE ON ALL 5 CYLINDERS',
              style: MM.display(size: 10.5, color: _kDone, weight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 14),
      for (final c in empty)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kAnchor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kAnchor.withOpacity(0.5)),
          ),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: _kAnchor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                  '${_kCoreName[c]} has no active habits. Add one to keep all 5 cylinders firing.',
                  style: MM.body(size: 13, color: _kAnchor)),
            ),
          ]),
        ),
      LayoutBuilder(builder: (context, box) {
        const gap = 16.0;
        final cols =
            (box.maxWidth / (340 + gap)).floor().clamp(1, 3);
        final n = _kCoreOrder.length;
        // The last row shares its width so no card is left orphaned.
        final tail = n % cols;
        double widthFor(int i) {
          final inRow = (tail != 0 && i >= n - tail) ? tail : cols;
          return (box.maxWidth - gap * (inRow - 1)) / inRow;
        }
        return Wrap(spacing: gap, runSpacing: gap, children: [
          for (var i = 0; i < n; i++)
            SizedBox(width: widthFor(i), child: _coreCard(_kCoreOrder[i])),
        ]);
      }),
    ]);
  }

  Widget _coreCard(String core) {
    final color = _coreColor(core);
    final rs = widget.routines.where((h) => h.core == core).toList()
      ..sort((a, b) => (a.slot?.minutes ?? 9999).compareTo(b.slot?.minutes ?? 9999));
    final ns = widget.nonRoutines.where((h) => h.core == core).toList();
    if (rs.isEmpty && ns.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _kAnchor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kAnchor.withOpacity(0.6)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _coreTile(core, 40),
            const SizedBox(width: 12),
            Expanded(
                child: Text(_kCoreName[core]!,
                    style: MM.body(size: 15, color: Colors.white, weight: FontWeight.w700))),
          ]),
          const SizedBox(height: 14),
          Text("This cylinder isn't firing yet",
              style: MM.display(size: 13)),
          const SizedBox(height: 6),
          Text('Pick one small Golden Habit to start building momentum here.',
              style: MM.body(size: 12.5, color: _kMuted)),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => widget.onAdd(core: core),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _kAnchor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('+  ADD FIRST HABIT',
                  style: MM.display(size: 11, color: _kInk, weight: FontWeight.w700)),
            ),
          ),
        ]),
      );
    }
    final doneN = rs.where(_done).length;
    final progressText = rs.isEmpty
        ? '${ns.fold<int>(0, (s, h) => s + _logs(h).length)}× logged'
        : '$doneN / ${rs.length} today';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kPanel.withOpacity(0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kLine),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          _coreTile(core, 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_kCoreName[core]!,
                  style: MM.body(size: 15, color: Colors.white, weight: FontWeight.w700)),
              Text(progressText, style: MM.body(size: 12, color: _kMuted)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: rs.isEmpty ? 0 : doneN / rs.length,
            minHeight: 5,
            backgroundColor: _kLine,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        if (rs.isNotEmpty) ...[
          const SizedBox(height: 14),
          _subLabel('ROUTINE'),
          for (final h in rs) _coreRow(h, color),
        ],
        if (ns.isNotEmpty) ...[
          const SizedBox(height: 14),
          _subLabel('NON-ROUTINE'),
          for (final h in ns) _coreNonRow(h),
        ],
        const SizedBox(height: 12),
        InkWell(
          onTap: () => widget.onAdd(core: core),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('+ Add to ${_kCoreName[core]!.split(' ').first}',
                style: MM.body(size: 12.5, color: MM.blue, weight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _subLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: MM.display(size: 10, color: _kFaint).copyWith(letterSpacing: 3)),
      );

  Widget _coreRow(TlHabit h, Color color) {
    final done = _done(h);
    final s = h.slot;
    final slotLabel = s == null
        ? 'Anytime'
        : s.isAnchored
            ? '${s.anchor!.label} ~${s.anchor!.usualTime}'
            : fmtHm(s.minutes);
    return InkWell(
      onTap: () => widget.onOpen(h),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(
            width: 96,
            child: Text(slotLabel,
                style: MM.body(size: 11.5, color: s?.isAnchored == true ? _kAnchor : _kMuted)),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(h.name,
                  style: MM.body(size: 13.5, color: done ? _kMuted : Colors.white, weight: FontWeight.w600)
                      .copyWith(
                          decoration: done ? TextDecoration.lineThrough : null,
                          decorationColor: _kMuted)),
              if (h.statusLabel != null)
                Text(h.statusText, style: MM.body(size: 11, color: h.statusColor)),
            ]),
          ),
          if (done)
            const Icon(Icons.check_circle, color: _kDone, size: 24)
          else
            Semantics(
              button: true,
              label: 'Mark ${h.name} done',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _isFuture ? null : () => widget.onToggleDone(h, true),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.7), width: 2),
                  ),
                  child: Icon(Icons.check, size: 18, color: color),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _coreNonRow(TlHabit h) {
    final logs = _logs(h);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(
          width: 96,
          child: Text(
              h.triggers.isEmpty ? 'Triggered' : h.triggers.first,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: MM.body(size: 11.5, color: const Color(0xFFA78BFA))),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(h.name,
                style: MM.body(size: 13.5, color: Colors.white, weight: FontWeight.w600)),
            Text(
                [
                  if (h.statusLabel != null) h.statusText,
                  '${logs.length}× today',
                ].join(' · '),
                style: MM.body(size: 11, color: _kMuted)),
          ]),
        ),
        if (!_isFuture)
        Semantics(
          button: true,
          label: 'Log ${h.name}',
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => widget.onLog(h),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF7C5CF2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('+ LOG', style: MM.display(size: 10.5, weight: FontWeight.w700)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _emptyAll() => Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: _kPanel.withOpacity(0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kLine),
        ),
        child: Column(children: [
          Text('No habits yet', style: MM.display(size: 16)),
          const SizedBox(height: 8),
          Text('Add one small Golden Habit to start your orbit.',
              style: MM.body(size: 13, color: _kMuted)),
          const SizedBox(height: 16),
          _pillBtn('+ ADD HABIT', () => widget.onAdd()),
        ]),
      );
}

enum _Kind { label, habit, gap, now, emptyAnchor }

class _Entry {
  _Entry._(this.kind,
      {this.label, this.habit, this.anchor, this.gapStart, this.gapEnd});
  factory _Entry.label(String s) => _Entry._(_Kind.label, label: s);
  factory _Entry.habit(TlHabit h) => _Entry._(_Kind.habit, habit: h);
  factory _Entry.emptyAnchor(Anchor a) => _Entry._(_Kind.emptyAnchor, anchor: a);
  factory _Entry.now() => _Entry._(_Kind.now);
  factory _Entry.gap(int a, int b) =>
      _Entry._(_Kind.gap, gapStart: a, gapEnd: b);

  final _Kind kind;
  final String? label;
  final TlHabit? habit;
  final Anchor? anchor;
  final int? gapStart;
  final int? gapEnd;
  // Set by the builder pass: false for a 2nd+ habit stacked on the same slot.
  bool firstInSlot = true;
}
