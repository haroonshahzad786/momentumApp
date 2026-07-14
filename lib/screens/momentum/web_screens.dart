// web_screens.dart — Desktop (>= kWebBreakpoint) layouts for the secondary
// destinations, wired to the same real services the mobile screens use.
// Rendered inside WebShell's content column (the topbar supplies the title).
// Mirrors design/webversion/project/web-screens.jsx.
//
// Deep edit flows (habit detail/edit/flag, routine editing, mark-as-formed)
// stay on the mobile layout — narrowing the window below kWebBreakpoint brings
// the full-interaction mobile screen back.

import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/core_list.dart';
import '../../models/golden_habit.dart';
import '../../models/momentum_list.dart';
import '../../models/user_profile.dart';
import '../../services/cantina_service.dart';
import '../../services/checkin_service.dart';
import '../../services/core_lists_service.dart';
import '../../services/habits_service.dart';
import '../../services/momentum_lists_service.dart';
import '../../services/onboarding_service.dart';
import '../../services/profile_service.dart';
import '../../theme/momentum_tokens.dart';

const Map<String, String> kCoreIcon = {
  'mindset': '🧠',
  'career': '💰',
  'relationships': '👥',
  'physical': '💪',
  'emotional': '🧘',
};

Color coreHex(String id) => MM.coreColor[id] ?? MM.blue;

// ═══════════════════════════════════════════════════════════════
// Shared desktop primitives
// ═══════════════════════════════════════════════════════════════
class WebPanel extends StatelessWidget {
  const WebPanel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.borderColor,
      this.leftAccent,
      this.background});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? leftAccent;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? const Color(0xFF111C4E).withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          top: BorderSide(color: borderColor ?? Colors.white.withOpacity(0.10)),
          right:
              BorderSide(color: borderColor ?? Colors.white.withOpacity(0.10)),
          bottom:
              BorderSide(color: borderColor ?? Colors.white.withOpacity(0.10)),
          left: leftAccent != null
              ? BorderSide(color: leftAccent!, width: 3)
              : BorderSide(color: borderColor ?? Colors.white.withOpacity(0.10)),
        ),
      ),
      child: child,
    );
  }
}

class WebSection extends StatelessWidget {
  const WebSection(
      {super.key,
      required this.title,
      this.meta,
      this.accent = Colors.white,
      this.action,
      required this.child});
  final String title;
  final String? meta;
  final Color accent;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(title,
                          style: GoogleFonts.orbitron(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.6,
                              color: Colors.white)),
                    ),
                    if (meta != null) ...[
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(meta!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.orbitron(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: accent)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (action != null) action!,
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class WebStat extends StatelessWidget {
  const WebStat(
      {super.key,
      required this.label,
      required this.value,
      this.accent = Colors.white,
      this.sub});
  final String label;
  final String value;
  final Color accent;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return WebPanel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(),
              style: GoogleFonts.orbitron(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Colors.white.withOpacity(0.5))),
          const SizedBox(height: 6),
          Text(value, style: MM.display(size: 26, color: accent, height: 1)),
          if (sub != null) ...[
            const SizedBox(height: 5),
            Text(sub!,
                style: MM.body(size: 11, color: Colors.white.withOpacity(0.5))),
          ],
        ],
      ),
    );
  }
}

Widget _ghost(String label, VoidCallback onTap) => Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Text(label.toUpperCase(),
              style: GoogleFonts.orbitron(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: Colors.white)),
        ),
      ),
    );

/// Shared loading/error/empty wrapper + scroll padding for a desktop screen.
class _ScreenScaffold extends StatelessWidget {
  const _ScreenScaffold({
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.child,
  });
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: MM.blue));
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load',
                style: MM.display(size: 16, color: Colors.white)),
            const SizedBox(height: 12),
            _ghost('Retry', onRetry),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 4, 40, 56),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LISTS — real MomentumLists in a manifest grid (tap to expand items)
// ═══════════════════════════════════════════════════════════════
class WebLists extends StatefulWidget {
  const WebLists({super.key});
  @override
  State<WebLists> createState() => _WebListsState();
}

class _WebListsState extends State<WebLists> {
  final _service = MomentumListsService();
  List<MomentumList> _lists = const [];
  final Set<String> _expanded = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
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
      final res = await _service.getAllLists(uid);
      if (!mounted) return;
      setState(() {
        _lists = res.data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ScreenScaffold(
      loading: _loading,
      error: _error,
      onRetry: _load,
      child: WebSection(
        title: 'MANIFEST',
        meta: '${_lists.length} LISTS',
        accent: MM.blue,
        child: _lists.isEmpty
            ? _empty('No lists yet', 'Lists you capture will appear here.')
            : _Grid(
                minTileWidth: 280,
                children: _lists.map((l) {
                  final open = _expanded.contains(l.name);
                  return Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => open
                          ? _expanded.remove(l.name)
                          : _expanded.add(l.name)),
                      child: WebPanel(
                        padding: const EdgeInsets.all(18),
                        leftAccent: MM.blue,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Text('🗂️',
                                    style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(l.name,
                                      style: MM.body(
                                          size: 14,
                                          color: Colors.white,
                                          weight: FontWeight.w600)),
                                ),
                                _chip('${l.count}', MM.blue),
                              ],
                            ),
                            if (open && l.items.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              for (final it in l.items)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 6, right: 8),
                                        child: Container(
                                            width: 5,
                                            height: 5,
                                            decoration: BoxDecoration(
                                                color: MM.blue.withOpacity(0.7),
                                                shape: BoxShape.circle)),
                                      ),
                                      Expanded(
                                        child: Text(it,
                                            style: MM.body(
                                                size: 12.5,
                                                color: Colors.white
                                                    .withOpacity(0.8))),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TASKS — Today / Tomorrow / Later columns (local; mirrors mobile mock)
// ═══════════════════════════════════════════════════════════════
class WebTasks extends StatefulWidget {
  const WebTasks({super.key});
  @override
  State<WebTasks> createState() => _WebTasksState();
}

class _WebTasksState extends State<WebTasks> {
  final Map<String, List<Map<String, dynamic>>> _tasks = {
    'Today': [
      {'n': 'Q3 report draft', 'core': 'career', 'pts': 30, 'done': false},
      {'n': '10m breathwork', 'core': 'mindset', 'pts': 15, 'done': true},
      {'n': 'Grocery run', 'core': 'physical', 'pts': 10, 'done': false},
    ],
    'Tomorrow': [
      {'n': '1:1 with Sara', 'core': 'relationships', 'pts': 20, 'done': false},
      {'n': 'Yoga class', 'core': 'physical', 'pts': 25, 'done': false},
    ],
    'Later': [
      {'n': 'Tax filing prep', 'core': 'career', 'pts': 60, 'done': false},
      {'n': 'Read 1 chapter', 'core': 'emotional', 'pts': 10, 'done': false},
    ],
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 4, 40, 56),
      child: LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= 820 ? 3 : 1;
        final entries = _tasks.entries.toList();
        return Wrap(
          spacing: 20,
          runSpacing: 20,
          children: entries.map((e) {
            final w = cols == 1
                ? c.maxWidth
                : (c.maxWidth - 20 * (cols - 1)) / cols;
            final open = e.value.where((t) => !(t['done'] as bool)).length;
            return SizedBox(
              width: w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
                    child: Row(
                      children: [
                        Text(e.key.toUpperCase(),
                            style: GoogleFonts.orbitron(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.6,
                                color: Colors.white)),
                        const Spacer(),
                        Text('$open OPEN',
                            style: GoogleFonts.orbitron(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: MM.yellow)),
                      ],
                    ),
                  ),
                  for (int i = 0; i < e.value.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _taskRow(e.key, i, e.value[i]),
                    ),
                  _ghost('+ Add task', () {}),
                ],
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _taskRow(String bucket, int i, Map<String, dynamic> t) {
    final done = t['done'] as bool;
    final hex = coreHex(t['core'] as String);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => t['done'] = !done),
        child: Opacity(
          opacity: done ? 0.55 : 1,
          child: WebPanel(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: done ? hex : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: done ? hex : Colors.white.withOpacity(0.3),
                        width: 1.5),
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 12, color: Colors.black)
                      : null,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(t['n'] as String,
                      style: MM.body(size: 13, color: Colors.white).copyWith(
                          decoration: done
                              ? TextDecoration.lineThrough
                              : null)),
                ),
                _chip('+${t['pts']}', hex),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HABITS — real Golden Habits in a lifecycle grid (read-focused)
// ═══════════════════════════════════════════════════════════════
class WebHabits extends StatefulWidget {
  const WebHabits({super.key});
  @override
  State<WebHabits> createState() => _WebHabitsState();
}

class _WebHabitsState extends State<WebHabits> {
  final _svc = HabitsService();
  List<GoldenHabit> _habits = const [];
  bool _loading = true;
  String? _error;

  static const _stage = {
    'bad': (Color(0xFFEA0029), 'Pain point', '🔴'),
    'forming': (Color(0xFFFFC629), 'Forming', '🟠'),
    'mbms': (Color(0xFF2A7DE1), 'MBMs attached', '🔵'),
    'formed': (Color(0xFF00A98F), 'Formed', '🟢'),
    'trophy': (Color(0xFFFFC629), 'Trophy', '🏆'),
  };

  @override
  void initState() {
    super.initState();
    _load();
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
      final res = await _svc.getGoldenHabits(uid);
      if (!mounted) return;
      setState(() {
        _habits = res.data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ScreenScaffold(
      loading: _loading,
      error: _error,
      onRetry: _load,
      child: WebSection(
        title: 'GOLDEN HABITS',
        meta: '${_habits.length} IN FORGE',
        accent: MM.magenta,
        child: _habits.isEmpty
            ? _empty('No golden habits yet',
                'Forge one in Phase 1 to start building momentum.')
            : _Grid(
                minTileWidth: 300,
                children: _habits.map((h) {
                  final st = _stage[h.stage] ?? _stage['forming']!;
                  final hex = coreHex(h.coreId);
                  final note = h.displayText.trim().isNotEmpty
                      ? h.displayText.trim()
                      : (h.when.trim().isNotEmpty ? h.when.trim() : '—');
                  return WebPanel(
                    padding: const EdgeInsets.all(18),
                    leftAccent: st.$1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(kCoreIcon[h.coreId] ?? '•',
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                      h.habitName.trim().isNotEmpty
                                          ? h.habitName.trim()
                                          : 'Golden Habit',
                                      style: MM.body(
                                          size: 14.5,
                                          color: Colors.white,
                                          weight: FontWeight.w600)),
                                  const SizedBox(height: 3),
                                  Text(h.coreLabel.toUpperCase(),
                                      style: GoogleFonts.orbitron(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                          color: hex)),
                                ],
                              ),
                            ),
                            Text(st.$3, style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(note,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: MM.body(
                                size: 11.5,
                                color: Colors.white.withOpacity(0.6),
                                height: 1.5)),
                        const SizedBox(height: 14),
                        Container(
                          height: 1,
                          color: Colors.white.withOpacity(0.07),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(st.$2.toUpperCase(),
                                style: GoogleFonts.orbitron(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: st.$1)),
                            const Spacer(),
                            Text('🔥 ${h.streak}d',
                                style: MM.body(
                                    size: 11,
                                    color: Colors.white.withOpacity(0.7))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: (h.daysFormed / 14).clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation(st.$1),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TROPHY — real formed habits by core + achievements
// ═══════════════════════════════════════════════════════════════
class WebTrophy extends StatefulWidget {
  const WebTrophy({super.key});
  @override
  State<WebTrophy> createState() => _WebTrophyState();
}

class _WebTrophyState extends State<WebTrophy> {
  final _onboarding = OnboardingService();
  final _checkin = CheckinService();
  List<_Formed> _formed = const [];
  int _totalHabits = 0;
  bool _loading = true;
  String? _error;

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
      List<DailyCheckin> checkins = const [];
      try {
        checkins = await _checkin.getRecent(uid, limit: 30);
      } catch (_) {}
      final byCore = <String, List<int>>{};
      for (final c in checkins) {
        c.scores.forEach((k, v) => byCore.putIfAbsent(k, () => []).add(v));
      }
      final formed = <_Formed>[];
      for (final h in habits) {
        final scores = byCore[h.shortCoreId] ?? const <int>[];
        final isFormed = h.formed || deriveRoutineStage(scores) == 'formed';
        if (isFormed) {
          formed.add(_Formed(
            name: h.habitName.trim().isNotEmpty
                ? h.habitName.trim()
                : 'Golden Habit',
            core: h.shortCoreId,
            days: scores.length,
          ));
        }
      }
      if (!mounted) return;
      setState(() {
        _formed = formed;
        _totalHabits = habits.length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = _formed.length;
    final badges = <(String, String, bool, Color, String)>[
      ('First Launch', 'Began your journey', true, MM.blue, '🚀'),
      ('Habit Forged', 'First formed habit', n >= 1, MM.yellow, '🛠️'),
      ('Momentum x3', '3 formed habits', n >= 3, MM.teal, '⚙️'),
      ('Constellation', '10 formed habits', n >= 10, MM.blue, '✨'),
      ('In the Forge', 'A habit in progress', _totalHabits >= 1, MM.magenta,
          '🔥'),
    ];
    return _ScreenScaffold(
      loading: _loading,
      error: _error,
      onRetry: _load,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WebSection(
            title: 'TROPHY ROOM',
            meta: '$n FORMED IDENTITY HABIT${n == 1 ? '' : 'S'}',
            accent: MM.yellow,
            child: _formed.isEmpty
                ? _empty('No formed habits yet',
                    'Keep a habit green and it graduates here.')
                : _Grid(
                    minTileWidth: 230,
                    children: _formed.map((h) {
                      final hex = coreHex(h.core);
                      return WebPanel(
                        padding: const EdgeInsets.all(18),
                        borderColor: hex.withOpacity(0.33),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(kCoreIcon[h.core] ?? '•',
                                style: const TextStyle(fontSize: 34)),
                            const SizedBox(height: 10),
                            Text(h.name,
                                textAlign: TextAlign.center,
                                style: MM.body(
                                    size: 14.5,
                                    color: Colors.white,
                                    weight: FontWeight.w600)),
                            const SizedBox(height: 5),
                            Text(h.core.toUpperCase(),
                                style: GoogleFonts.orbitron(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: hex)),
                            const SizedBox(height: 12),
                            Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.08)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🟢',
                                    style: TextStyle(fontSize: 13)),
                                const SizedBox(width: 6),
                                Text('${h.days}',
                                    style:
                                        MM.display(size: 15, color: MM.teal)),
                                const SizedBox(width: 6),
                                Text('days tracked',
                                    style: MM.body(
                                        size: 11,
                                        color: Colors.white.withOpacity(0.5))),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 30),
          WebSection(
            title: 'ACHIEVEMENTS',
            meta: '${badges.where((b) => b.$3).length}/${badges.length} EARNED',
            accent: MM.blue,
            child: _Grid(
              minTileWidth: 170,
              children: badges.map((b) {
                return Opacity(
                  opacity: b.$3 ? 1 : 0.42,
                  child: WebPanel(
                    padding: const EdgeInsets.all(16),
                    borderColor: b.$3
                        ? b.$4.withOpacity(0.33)
                        : Colors.white.withOpacity(0.1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(b.$5, style: const TextStyle(fontSize: 30)),
                        const SizedBox(height: 8),
                        Text(b.$1,
                            textAlign: TextAlign.center,
                            style: MM.body(
                                size: 12.5,
                                color: Colors.white,
                                weight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(b.$2,
                            textAlign: TextAlign.center,
                            style: MM.body(
                                size: 10.5,
                                color: Colors.white.withOpacity(0.55))),
                        if (!b.$3) ...[
                          const SizedBox(height: 8),
                          Text('LOCKED',
                              style: GoogleFonts.orbitron(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: Colors.white.withOpacity(0.4))),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Formed {
  const _Formed({required this.name, required this.core, required this.days});
  final String name;
  final String core;
  final int days;
}

// ═══════════════════════════════════════════════════════════════
// ROUTINES — real routine / non-routine core lists
// ═══════════════════════════════════════════════════════════════
class WebRoutines extends StatefulWidget {
  const WebRoutines({super.key});
  @override
  State<WebRoutines> createState() => _WebRoutinesState();
}

class _WebRoutinesState extends State<WebRoutines> {
  final _service = CoreListsService();
  List<CoreList> _routine = const [];
  List<CoreList> _nonRoutine = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
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
      final res = await _service.getRoutineData(uid);
      if (!mounted) return;
      setState(() {
        _routine = res.data.routine;
        _nonRoutine = res.data.nonRoutine;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Widget _coreListCard(CoreList l) {
    final hex = coreHex(l.coreId);
    return WebPanel(
      padding: const EdgeInsets.all(18),
      leftAccent: hex,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(kCoreIcon[l.coreId] ?? '•',
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    l.name.trim().isNotEmpty ? l.name.trim() : l.coreLabel,
                    style: MM.body(
                        size: 14,
                        color: Colors.white,
                        weight: FontWeight.w600)),
              ),
              _chip('${l.items.length}', hex),
            ],
          ),
          if (l.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final it in l.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5, right: 9),
                      child: Container(
                          width: 7,
                          height: 7,
                          decoration:
                              BoxDecoration(color: hex, shape: BoxShape.circle)),
                    ),
                    Expanded(
                      child: Text(it,
                          style: MM.body(
                              size: 12.5,
                              color: Colors.white.withOpacity(0.85))),
                    ),
                  ],
                ),
              ),
          ] else ...[
            const SizedBox(height: 8),
            Text('No items yet',
                style:
                    MM.body(size: 11, color: Colors.white.withOpacity(0.4))),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ScreenScaffold(
      loading: _loading,
      error: _error,
      onRetry: _load,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WebSection(
            title: 'ROUTINE',
            meta: 'DAILY ORBIT · THE SEA OF GREEN',
            accent: MM.teal,
            child: _routine.isEmpty
                ? _empty('No routines yet',
                    'Routine habits you build appear here, grouped by Core.')
                : _Grid(
                    minTileWidth: 300,
                    children: _routine.map(_coreListCard).toList()),
          ),
          const SizedBox(height: 30),
          WebSection(
            title: 'NON-ROUTINE',
            meta: 'IDENTITY HABITS → TROPHY ROOM',
            accent: MM.yellow,
            child: _nonRoutine.isEmpty
                ? _empty('No non-routine habits',
                    'Identity habits graduate to the Trophy Room when formed.')
                : _Grid(
                    minTileWidth: 300,
                    children: _nonRoutine.map(_coreListCard).toList()),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PROFILE — identity + real core radar + lifetime stats
// ═══════════════════════════════════════════════════════════════
class WebProfile extends StatefulWidget {
  const WebProfile({super.key, required this.onSignOut});
  final VoidCallback onSignOut;
  @override
  State<WebProfile> createState() => _WebProfileState();
}

class _WebProfileState extends State<WebProfile> {
  final _profileService = ProfileService();
  final _checkin = CheckinService();
  UserProfile? _profile;
  List<int> _radar = const [0, 0, 0, 0, 0];
  bool _loading = true;
  String? _error;

  static const _radarCores = [
    'mindset',
    'career',
    'relationships',
    'physical',
    'emotional'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _profileService.dispose();
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
      final res = await _profileService.getProfile(uid);
      List<DailyCheckin> checkins = const [];
      try {
        checkins = await _checkin.getRecent(uid, limit: 30);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _profile = res.data;
        _radar = _computeRadar(checkins);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<int> _computeRadar(List<DailyCheckin> checkins) {
    final byCore = <String, List<int>>{};
    for (final c in checkins) {
      c.scores.forEach((k, v) => byCore.putIfAbsent(k, () => []).add(v));
    }
    return _radarCores.map((core) {
      final scores = (byCore[core] ?? const <int>[]).take(7).toList();
      if (scores.isEmpty) return 0;
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      return (avg / 5 * 100).round();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    final raw = (p?.displayName ?? '').trim();
    final name = raw.isEmpty ? 'Commander' : raw;
    final planetName = () {
      final i = MM.planets.indexWhere((e) => e['id'] == (p?.planet ?? 'earth'));
      return MM.planets[i < 0 ? 0 : i]['name'] as String;
    }();
    return _ScreenScaffold(
      loading: _loading,
      error: _error,
      onRetry: _load,
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 820;
        final identity = _identityCard(name, p, planetName);
        final balance = _balanceCard();
        return wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 10, child: identity),
                  const SizedBox(width: 24),
                  Expanded(flex: 12, child: balance),
                ],
              )
            : Column(children: [
                identity,
                const SizedBox(height: 24),
                balance,
              ]);
      }),
    );
  }

  Widget _identityCard(String name, UserProfile? p, String planetName) {
    return WebPanel(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const RadialGradient(
                  center: Alignment(-0.4, -0.4),
                  colors: [Color(0xFFB58AFF), Color(0xFF6B3DF5), MM.blue],
                  stops: [0.0, 0.65, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                      color: MM.violet.withOpacity(0.5),
                      blurRadius: 26,
                      spreadRadius: -4),
                ],
              ),
              alignment: Alignment.center,
              child: Text(name[0].toUpperCase(),
                  style: GoogleFonts.orbitron(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(height: 14),
          Text(name,
              textAlign: TextAlign.center,
              style: MM.display(size: 20, color: Colors.white)),
          const SizedBox(height: 6),
          Text(
              '${(p?.level ?? 'cadet').toUpperCase()} · ${planetName.toUpperCase()} ORBIT',
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: MM.yellow)),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                  child: WebStat(
                      label: 'Streak',
                      value: '${p?.streak ?? 0}d',
                      accent: MM.red)),
              const SizedBox(width: 12),
              Expanded(
                  child: WebStat(
                      label: 'Score',
                      value: _fmt(p?.momentumScore ?? 0),
                      accent: MM.yellow)),
            ],
          ),
          const SizedBox(height: 12),
          _ghost('Sign out', widget.onSignOut),
        ],
      ),
    );
  }

  Widget _balanceCard() {
    return WebPanel(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('CORE BALANCE',
              style: GoogleFonts.orbitron(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: Colors.white)),
          const SizedBox(height: 6),
          Text('Your momentum across the 5 Cores (last 7 check-ins)',
              style: MM.body(size: 12, color: Colors.white.withOpacity(0.55))),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, c) {
            final radar = SizedBox(
              width: 240,
              height: 240,
              child: CustomPaint(
                painter: _RadarPainter(_radar, _radarCores),
              ),
            );
            final bars = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < _radarCores.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 22,
                            child: Text(kCoreIcon[_radarCores[i]] ?? '•',
                                style: const TextStyle(fontSize: 15))),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: _radar[i] / 100,
                              minHeight: 6,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation(
                                  coreHex(_radarCores[i])),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 26,
                          child: Text('${_radar[i]}',
                              textAlign: TextAlign.right,
                              style: MM.display(
                                  size: 12, color: coreHex(_radarCores[i]))),
                        ),
                      ],
                    ),
                  ),
              ],
            );
            return c.maxWidth >= 520
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      radar,
                      const SizedBox(width: 20),
                      Expanded(child: bars),
                    ],
                  )
                : Column(children: [
                    Center(child: radar),
                    const SizedBox(height: 20),
                    bars,
                  ]);
          }),
        ],
      ),
    );
  }

  static String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.scores, this.cores);
  final List<int> scores;
  final List<String> cores;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = math.min(cx, cy) - 8;
    Offset axis(int i, double f) {
      final a = -math.pi / 2 + i * (2 * math.pi / 5);
      return Offset(cx + r * f * math.cos(a), cy + r * f * math.sin(a));
    }

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;
    for (final f in [0.25, 0.5, 0.75, 1.0]) {
      final path = Path();
      for (int i = 0; i < 5; i++) {
        final o = axis(i, f);
        if (i == 0) {
          path.moveTo(o.dx, o.dy);
        } else {
          path.lineTo(o.dx, o.dy);
        }
      }
      path.close();
      canvas.drawPath(path, grid);
    }
    for (int i = 0; i < 5; i++) {
      canvas.drawLine(Offset(cx, cy), axis(i, 1), grid);
    }
    // data polygon
    final dataPath = Path();
    for (int i = 0; i < 5; i++) {
      final o = axis(i, (scores[i] / 100).clamp(0.0, 1.0));
      if (i == 0) {
        dataPath.moveTo(o.dx, o.dy);
      } else {
        dataPath.lineTo(o.dx, o.dy);
      }
    }
    dataPath.close();
    canvas.drawPath(
        dataPath,
        Paint()
          ..style = PaintingStyle.fill
          ..color = MM.blue.withOpacity(0.25));
    canvas.drawPath(
        dataPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = MM.blue
          ..strokeWidth = 2);
    for (int i = 0; i < 5; i++) {
      final o = axis(i, (scores[i] / 100).clamp(0.0, 1.0));
      canvas.drawCircle(o, 4, Paint()..color = coreHex(cores[i]));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.scores != scores;
}

// ═══════════════════════════════════════════════════════════════
// CANTINA — real streamed leaderboard + tribes + ideas well
// ═══════════════════════════════════════════════════════════════
class _WebCrew {
  const _WebCrew(this.id, this.name, this.score, this.streak, this.hex,
      {this.me = false, this.isReal = false, this.uid});
  final String id;
  final String name;
  final int score;
  final int streak;
  final Color hex;
  final bool me;
  final bool isReal;
  final String? uid;
}

const _webDemoCrew = <_WebCrew>[
  _WebCrew('maya', 'Maya R.', 12420, 84, MM.magenta),
  _WebCrew('devon', 'Devon T.', 10115, 62, MM.blue),
  _WebCrew('me', 'You', 8420, 47, MM.yellow, me: true),
  _WebCrew('aisha', 'Aisha K.', 7980, 41, MM.teal),
  _WebCrew('leo', 'Leo M.', 3210, 12, MM.violet),
];

class WebCantina extends StatefulWidget {
  const WebCantina({super.key, required this.onNav});
  final void Function(String key) onNav;
  @override
  State<WebCantina> createState() => _WebCantinaState();
}

class _WebCantinaState extends State<WebCantina> {
  final _svc = CantinaService();
  late final Stream<List<CantinaUser>> _users = _svc.watchUsers();
  late final Stream<Map<String, CantinaInboxEntry>> _inbox = _svc.watchInbox();
  late final String _myUid = _svc.currentUid;

  static const _palette = [
    MM.magenta,
    MM.blue,
    MM.teal,
    MM.violet,
    MM.yellow,
    MM.red
  ];

  final _tribes = const [
    ('Dawn Patrol', 14, 'physical', 'Early risers logging before 7am'),
    ('Deep Work Guild', 22, 'career', 'Focus-block accountability'),
    ('Mind Gardeners', 9, 'mindset', 'Daily journaling + meditation'),
  ];
  final _ideas = const [
    ('Habit-stack journaling right after coffee — the cue is already there.',
        'Nova_Rey', 42),
    ('I moved my check-in to the evening and my streak finally stuck.',
        'LunaVdB', 31),
    ('Treat the mystery box like a real reward — no peeking early!',
        'AstroKai', 27),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 4, 40, 56),
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 900;
        final left = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WebSection(
              title: 'LEADERBOARD',
              meta: 'THIS WEEK · MOMENTUM',
              accent: MM.violet,
              child: _leaderboard(),
            ),
            const SizedBox(height: 30),
            WebSection(
              title: 'IDEAS WELL',
              meta: 'COMMUNITY TIPS',
              accent: MM.teal,
              child: Column(
                children: _ideas.map((i) => _ideaCard(i.$1, i.$2, i.$3)).toList(),
              ),
            ),
          ],
        );
        final right = WebSection(
          title: 'YOUR TRIBES',
          meta: 'ACCOUNTABILITY CREW',
          accent: MM.magenta,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._tribes.map((t) => _tribeCard(t.$1, t.$2, t.$3, t.$4)),
              const SizedBox(height: 4),
              _ghost('+ Find a tribe', () {}),
            ],
          ),
        );
        return wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 14, child: left),
                  const SizedBox(width: 24),
                  Expanded(flex: 10, child: right),
                ],
              )
            : Column(children: [left, const SizedBox(height: 30), right]);
      }),
    );
  }

  Widget _leaderboard() {
    return StreamBuilder<List<CantinaUser>>(
      stream: _users,
      builder: (context, snap) {
        final real = (snap.data ?? const <CantinaUser>[]).map((u) {
          final hex = _palette[u.uid.hashCode.abs() % _palette.length];
          return _WebCrew(u.uid, u.uid == _myUid ? 'You' : u.name, u.score,
              u.streak, hex,
              me: u.uid == _myUid, isReal: true, uid: u.uid);
        }).toList();
        final hasMe = real.any((m) => m.me);
        final demo = _webDemoCrew.where((c) => !c.me || !hasMe).toList();
        final all = [...real, ...demo]
          ..sort((a, b) => b.score.compareTo(a.score));
        return StreamBuilder<Map<String, CantinaInboxEntry>>(
          stream: _inbox,
          builder: (context, inboxSnap) {
            final inbox = inboxSnap.data ?? const <String, CantinaInboxEntry>{};
            int unreadFor(_WebCrew c) {
              if (!c.isReal || c.me || c.uid == null) return 0;
              return inbox[_svc.dmPairId(c.uid!)]?.unreadCount ?? 0;
            }

            return WebPanel(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  for (var i = 0; i < all.length; i++)
                    _row(i + 1, all[i], unreadFor(all[i])),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _row(int rank, _WebCrew c, int unread) {
    final rankColor = rank <= 3
        ? [MM.yellow, const Color(0xFFCFD8E6), const Color(0xFFE8A35C)][rank - 1]
        : Colors.white.withOpacity(0.5);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => widget.onNav(c.me
            ? 'profile'
            : (c.isReal ? 'crew:dm:${c.uid}' : 'crew:${c.id}')),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: c.me ? MM.violet.withOpacity(0.13) : Colors.transparent,
            border: c.me
                ? Border.all(color: MM.violet.withOpacity(0.4))
                : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Text('$rank',
                    textAlign: TextAlign.center,
                    style: MM.display(size: 16, color: rankColor)),
              ),
              const SizedBox(width: 12),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  gradient: c.me
                      ? const RadialGradient(
                          center: Alignment(-0.4, -0.4),
                          colors: [Color(0xFFB58AFF), Color(0xFF6B3DF5)])
                      : null,
                  color: c.me ? null : MM.navy.withOpacity(0.7),
                ),
                alignment: Alignment.center,
                child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                    style: GoogleFonts.orbitron(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MM.body(
                                  size: 13.5,
                                  color: Colors.white,
                                  weight:
                                      c.me ? FontWeight.w700 : FontWeight.w500)),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: MM.red,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text('$unread',
                                style: MM.mono(size: 9, color: Colors.white)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('🔥 ${c.streak}-day streak',
                        style: MM.body(
                            size: 10.5, color: Colors.white.withOpacity(0.5))),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(_fmt(c.score),
                  style: MM.display(size: 14, color: MM.yellow)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ideaCard(String txt, String by, int up) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WebPanel(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('“$txt”',
                      style: MM.body(
                          size: 13, color: Colors.white, height: 1.5)),
                  const SizedBox(height: 8),
                  Text('— $by',
                      style: GoogleFonts.orbitron(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: Colors.white.withOpacity(0.5))),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: MM.teal.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: MM.teal.withOpacity(0.4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_upward, size: 14, color: MM.teal),
                  const SizedBox(height: 3),
                  Text('$up', style: MM.mono(size: 12, color: MM.teal)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tribeCard(String name, int members, String focus, String desc) {
    final hex = coreHex(focus);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WebPanel(
        padding: const EdgeInsets.all(16),
        leftAccent: hex,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(kCoreIcon[focus] ?? '•',
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(name,
                          style: MM.body(
                              size: 14,
                              color: Colors.white,
                              weight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('$members MEMBERS',
                          style: GoogleFonts.orbitron(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: hex)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(desc,
                style: MM.body(
                    size: 11.5,
                    color: Colors.white.withOpacity(0.6),
                    height: 1.5)),
          ],
        ),
      ),
    );
  }

  static String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ═══════════════════════════════════════════════════════════════
// Shared bits
// ═══════════════════════════════════════════════════════════════
Widget _chip(String text, Color hex) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: hex.withOpacity(0.1),
        border: Border.all(color: hex.withOpacity(0.27)),
      ),
      child: Text(text,
          style: MM.mono(size: 11, color: hex)),
    );

Widget _empty(String title, String sub) => WebPanel(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Text(title,
              style: MM.display(size: 15, color: Colors.white)),
          const SizedBox(height: 8),
          Text(sub,
              textAlign: TextAlign.center,
              style: MM.body(size: 12, color: Colors.white.withOpacity(0.55))),
        ],
      ),
    );

/// Responsive grid: fills the width with tiles at least [minTileWidth] wide.
class _Grid extends StatelessWidget {
  const _Grid({required this.children, required this.minTileWidth});
  final List<Widget> children;
  final double minTileWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      const gap = 16.0;
      final cols = math.max(1, (c.maxWidth / (minTileWidth + gap)).floor());
      final tileW = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: children
            .map((w) => SizedBox(width: tileW, child: w))
            .toList(),
      );
    });
  }
}
