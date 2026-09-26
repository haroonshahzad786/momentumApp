import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../theme/momentum_tokens.dart';
import 'mm_buttons.dart';

/// Streak protection (#17, Gamification spec §6 / PRD 12.C): the Streak Saver
/// count and Vacation Mode controls. Protection only — nothing here punishes.
class StreakProtectionCard extends StatefulWidget {
  const StreakProtectionCard({
    super.key,
    required this.streakSavers,
    required this.maxStreakSavers,
    required this.streakSaverMilestone,
    required this.vacationMaxDays,
    required this.activeVacation,
    required this.upcomingVacation,
    required this.onStartVacation,
    required this.onEndVacation,
  });

  final int streakSavers;
  final int maxStreakSavers;
  final int streakSaverMilestone;
  final int vacationMaxDays;
  final VacationRange? activeVacation;
  final VacationRange? upcomingVacation;

  /// Starts Vacation Mode on [start] (local date) for [days] days. Throws with
  /// a player-facing message on a rule violation.
  final Future<void> Function(DateTime start, int days) onStartVacation;

  /// Ends the active vacation, or cancels the planned one.
  final Future<void> Function() onEndVacation;

  @override
  State<StreakProtectionCard> createState() => _StreakProtectionCardState();
}

class _StreakProtectionCardState extends State<StreakProtectionCard> {
  bool _busy = false;
  String? _error;

  Future<void> _run(Future<void> Function() f) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await f();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _plan() async {
    final picked = await showDialog<(DateTime, int)>(
      context: context,
      builder: (_) => VacationModeDialog(maxDays: widget.vacationMaxDays),
    );
    if (picked != null) await _run(() => widget.onStartVacation(picked.$1, picked.$2));
  }

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withOpacity(0.62);
    final active = widget.activeVacation;
    final upcoming = widget.upcomingVacation;
    final saverText = widget.streakSavers > 0
        ? 'Streak Saver available · covers a missed weekday automatically'
        : 'Earn a Streak Saver at a ${widget.streakSaverMilestone}-day streak';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MM.panel.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MM.teal.withOpacity(0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('STREAK PROTECTION', style: MM.displayX(size: 9, color: MM.teal)),
          const SizedBox(height: 10),
          Row(children: [
            Text('🛡️', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(widget.streakSavers > 0 ? 1 : 0.4))),
            const SizedBox(width: 8),
            Text('${widget.streakSavers}/${widget.maxStreakSavers}',
                style: MM.display(size: 15, color: widget.streakSavers > 0 ? MM.teal : muted)),
            const SizedBox(width: 10),
            Expanded(child: Text(saverText, style: MM.body(size: 12, color: muted, height: 1.35))),
          ]),
          const SizedBox(height: 12),
          if (active != null) ...[
            Text('🌴  Vacation Mode on until ${_pretty(active.end)}',
                style: MM.body(size: 13, color: Colors.white, height: 1.4)),
            const SizedBox(height: 4),
            Text('Your streak is paused — missed days don\'t count.',
                style: MM.body(size: 12, color: muted, height: 1.35)),
            const SizedBox(height: 10),
            MMGhostButton(
              label: "I'm back · end Vacation Mode",
              expand: true,
              onPressed: _busy ? null : () => _run(widget.onEndVacation),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ] else if (upcoming != null) ...[
            Text('🌴  Vacation Mode planned ${_pretty(upcoming.start)} – ${_pretty(upcoming.end)}',
                style: MM.body(size: 13, color: Colors.white, height: 1.4)),
            const SizedBox(height: 10),
            MMGhostButton(
              label: 'Cancel vacation',
              expand: true,
              onPressed: _busy ? null : () => _run(widget.onEndVacation),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ] else ...[
            Text('Going away? Pause your streak for up to ${widget.vacationMaxDays} days.',
                style: MM.body(size: 12, color: muted, height: 1.35)),
            const SizedBox(height: 10),
            MMGhostButton(
              label: '🌴 Plan Vacation Mode',
              expand: true,
              onPressed: _busy ? null : _plan,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: MM.body(size: 12, color: MM.red, height: 1.35)),
          ],
        ],
      ),
    );
  }
}

/// Pick when Vacation Mode starts and how long it lasts. Pops `(start, days)`.
class VacationModeDialog extends StatefulWidget {
  const VacationModeDialog({super.key, required this.maxDays, this.now});

  final int maxDays;

  /// Injectable clock for tests.
  final DateTime? now;

  @override
  State<VacationModeDialog> createState() => _VacationModeDialogState();
}

class _VacationModeDialogState extends State<VacationModeDialog> {
  late final DateTime _today = _dateOnly(widget.now ?? DateTime.now());
  late DateTime _start = _today;
  late int _days = widget.maxDays.clamp(1, 7);

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withOpacity(0.62);
    final end = _start.add(Duration(days: _days - 1));
    Widget startChip(String label, DateTime d) {
      final on = _start == d;
      return ChoiceChip(
        label: Text(label),
        selected: on,
        onSelected: (_) => setState(() => _start = d),
        selectedColor: MM.teal.withOpacity(0.35),
        backgroundColor: MM.navy2,
        labelStyle: MM.body(size: 12, color: Colors.white),
        side: BorderSide(color: on ? MM.teal : Colors.white24),
      );
    }

    final custom = _start != _today && _start != _today.add(const Duration(days: 1));
    return Dialog(
      backgroundColor: MM.navy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: MM.teal.withOpacity(0.5)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('🌴  VACATION MODE', style: MM.displayX(size: 11, color: MM.teal)),
              const SizedBox(height: 10),
              Text('Pause your streak while you\'re away. Missed weekdays during '
                  'Vacation Mode never count against you.',
                  style: MM.body(size: 13, color: Colors.white, height: 1.45)),
              const SizedBox(height: 16),
              Text('STARTS', style: MM.displayX(size: 9, color: muted)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                startChip('Today', _today),
                startChip('Tomorrow', _today.add(const Duration(days: 1))),
                ActionChip(
                  label: Text(custom ? _pretty(_id(_start)) : 'Pick a date…'),
                  backgroundColor: custom ? MM.teal.withOpacity(0.35) : MM.navy2,
                  labelStyle: MM.body(size: 12, color: Colors.white),
                  side: BorderSide(color: custom ? MM.teal : Colors.white24),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _start,
                      firstDate: _today,
                      lastDate: _today.add(const Duration(days: 365)),
                    );
                    if (d != null) setState(() => _start = _dateOnly(d));
                  },
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Text('LASTS', style: MM.displayX(size: 9, color: muted)),
                const Spacer(),
                Text('$_days day${_days == 1 ? '' : 's'}', style: MM.display(size: 14, color: Colors.white)),
              ]),
              if (widget.maxDays > 1)
                Slider(
                  value: _days.toDouble(),
                  min: 1,
                  max: widget.maxDays.toDouble(),
                  divisions: widget.maxDays - 1,
                  activeColor: MM.teal,
                  onChanged: (v) => setState(() => _days = v.round()),
                ),
              Text('${_pretty(_id(_start))} – ${_pretty(_id(end))}',
                  style: MM.body(size: 12, color: muted)),
              const SizedBox(height: 18),
              MMPrimaryButton(
                label: 'Start Vacation Mode',
                onPressed: () => Navigator.of(context).pop((_start, _days)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              const SizedBox(height: 8),
              MMGhostButton(
                label: 'Not now',
                expand: true,
                onPressed: () => Navigator.of(context).pop(),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String _id(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "2026-09-28" → "Mon 28 Sep".
String _pretty(String id) {
  final d = DateTime.tryParse(id);
  if (d == null) return id;
  const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${wd[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';
}
