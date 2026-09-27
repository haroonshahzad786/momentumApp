import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/economy_config_service.dart';
import '../../theme/momentum_tokens.dart';
import 'streak_flame.dart';

/// Where a streak sits between its milestones (Gamification §6: 3/7/14/30/60/
/// 90/180/365 by default, admin-editable in `config/streaks`).
class StreakMilestoneProgress {
  const StreakMilestoneProgress({
    required this.streak,
    required this.previous,
    required this.next,
  });

  /// [milestones] need not be sorted; non-positive values are ignored.
  factory StreakMilestoneProgress.of(int streak, List<int> milestones) {
    final ms = milestones.where((m) => m > 0).toSet().toList()..sort();
    final s = streak < 0 ? 0 : streak;
    var prev = 0;
    for (final m in ms) {
      if (s < m) return StreakMilestoneProgress(streak: s, previous: prev, next: m);
      prev = m;
    }
    return StreakMilestoneProgress(streak: s, previous: prev, next: null);
  }

  final int streak;

  /// Last milestone already passed (0 before the first).
  final int previous;

  /// Next milestone to reach; null once every milestone is behind the player.
  final int? next;

  int get daysToNext => next == null ? 0 : next! - streak;

  /// 0–1 fill of the current milestone segment (previous → next).
  double get fraction {
    final n = next;
    if (n == null) return 1;
    return ((streak - previous) / (n - previous)).clamp(0.0, 1.0);
  }

  String get countdown {
    final n = next;
    if (n == null) return 'Every milestone reached';
    final d = daysToNext;
    return '$d ${d == 1 ? 'day' : 'days'} to $n-day reward';
  }
}

/// The dashboard's persistent streak readout (PRD 12.10 "Across top: Current
/// Streak with consecutive days and days until reward"). [compact] is the
/// phone top-bar block; the default is the full-width desktop bar.
class StreakBar extends StatefulWidget {
  const StreakBar({
    super.key,
    required this.streak,
    this.streakState = 'ok',
    this.streakSavers = 0,
    this.milestones,
    this.compact = false,
    this.onTap,
  });

  final int streak;

  /// #17 — 'ok' · 'warning' · 'protected' · 'vacation' · 'broken'.
  final String streakState;
  final int streakSavers;

  /// Overrides the `config/streaks` read (tests, previews).
  final List<int>? milestones;
  final bool compact;
  final VoidCallback? onTap;

  @override
  State<StreakBar> createState() => _StreakBarState();
}

class _StreakBarState extends State<StreakBar> {
  List<int> _milestones = EconomyConfigService.defaultStreakMilestones;

  @override
  void initState() {
    super.initState();
    final given = widget.milestones;
    if (given != null) {
      _milestones = given;
    } else {
      EconomyConfigService().streakMilestones().then((m) {
        if (mounted) setState(() => _milestones = m);
      }).catchError((_) {});
    }
  }

  Color get _stateColor => switch (widget.streakState) {
        'ok' => MM.yellow,
        'vacation' || 'protected' => MM.teal,
        _ => MM.red,
      };

  /// Protection / warning note, or null when there is nothing to say.
  String? get _note => switch (widget.streakState) {
        'warning' => '⚠ Check in today',
        'vacation' => '🌴 Paused',
        'protected' => '🛡️ Saver covers gap',
        _ => widget.streakSavers > 0 ? '🛡️ Saver ready' : null,
      };

  @override
  Widget build(BuildContext context) {
    final p = StreakMilestoneProgress.of(widget.streak, _milestones);
    return Semantics(
      button: widget.onTap != null,
      label: '${widget.streak}-day streak. ${p.countdown}',
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: widget.compact ? _compact(p) : _wide(p),
      ),
    );
  }

  Widget _bar(StreakMilestoneProgress p, double height) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: p.fraction,
          minHeight: height,
          backgroundColor: Colors.white.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation(_stateColor),
        ),
      );

  Widget _compact(StreakMilestoneProgress p) {
    final note = _note;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreakFlame(days: widget.streak),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text('STREAK',
                    style: MM.displayX(size: 11, color: _stateColor)),
                if (note != null) ...[
                  const SizedBox(width: 4),
                  // Just the glyph up here — the phone top bar has no room.
                  Text(note.split(' ').first,
                      style: TextStyle(fontSize: 10, color: _stateColor)),
                ],
              ]),
              const SizedBox(height: 2),
              Text('DAY ${widget.streak}',
                  style: MM.display(size: 18, color: Colors.white)),
              const SizedBox(height: 4),
              SizedBox(width: 92, child: _bar(p, 3)),
              const SizedBox(height: 3),
              Text(
                  p.next == null
                      ? 'ALL MILESTONES'
                      : '${p.daysToNext}D TO ${p.next} 🎁',
                  style: MM.display(
                      size: 8.5, color: Colors.white.withOpacity(0.55))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _wide(StreakMilestoneProgress p) {
    final note = _note;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111C4E).withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _stateColor.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          StreakFlame(days: widget.streak, size: 30),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('CURRENT STREAK',
                  style: GoogleFonts.orbitron(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: _stateColor)),
              const SizedBox(height: 3),
              Text('${widget.streak} ${widget.streak == 1 ? 'DAY' : 'DAYS'}',
                  style: MM.display(size: 20, color: Colors.white, height: 1)),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(p.countdown,
                          overflow: TextOverflow.ellipsis,
                          style: MM.body(
                              size: 12,
                              color: Colors.white,
                              weight: FontWeight.w600)),
                    ),
                    if (p.next != null)
                      Text('${p.previous} → ${p.next} 🎁',
                          style: MM.body(
                              size: 11,
                              color: Colors.white.withOpacity(0.5))),
                  ],
                ),
                const SizedBox(height: 7),
                _bar(p, 6),
              ],
            ),
          ),
          if (note != null) ...[
            const SizedBox(width: 18),
            Text(note,
                style: MM.body(
                    size: 11.5, color: _stateColor, weight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}
