import 'package:flutter/material.dart';

import '../../services/routine_reminders.dart';
import '../../theme/momentum_tokens.dart';

const _kAlert = Color(0xFFFF4F6D);

/// Red count bubble for the Routines button; nothing when no routine is due.
class RoutineBadge extends StatelessWidget {
  const RoutineBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RoutineReminders.instance,
      builder: (context, _) {
        final n = RoutineReminders.instance.count;
        if (n == 0) return const SizedBox.shrink();
        return Container(
          constraints: const BoxConstraints(minWidth: 20),
          height: 20,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _kAlert,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: _kAlert.withOpacity(0.5), blurRadius: 8)],
          ),
          child: Text(n > 9 ? '9+' : '$n',
              style: MM.body(size: 11, color: Colors.white, weight: FontWeight.w700)),
        );
      },
    );
  }
}

/// One notification bar listing every routine that is due now. Collapsed it
/// shows a summary; tap to expand the full list with a tick per routine.
class RoutineReminderBar extends StatefulWidget {
  const RoutineReminderBar({super.key, required this.onOpenRoutines});
  final VoidCallback onOpenRoutines;

  @override
  State<RoutineReminderBar> createState() => _RoutineReminderBarState();
}

class _RoutineReminderBarState extends State<RoutineReminderBar> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RoutineReminders.instance,
      builder: (context, _) {
        final due = RoutineReminders.instance.due;
        if (due.isEmpty) return const SizedBox.shrink();
        final first = due.first;
        final summary = due.length == 1
            ? '${first.name} is due (${first.timeLabel})'
            : '${due.length} routines due now';
        return Material(
          type: MaterialType.transparency,
          child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2A1A2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kAlert.withOpacity(0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _open = !_open),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(children: [
                      const Icon(Icons.notifications_active, size: 18, color: _kAlert),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MM.body(size: 13.5, color: Colors.white, weight: FontWeight.w600)),
                      ),
                      TextButton(
                        onPressed: widget.onOpenRoutines,
                        child: Text('Open Routines', style: MM.body(size: 12.5, color: MM.teal)),
                      ),
                      Icon(_open ? Icons.expand_less : Icons.expand_more,
                          size: 20, color: Colors.white54),
                    ]),
                  ),
                ),
                if (_open)
                  for (final r in due)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 8, 8),
                      child: Row(children: [
                        SizedBox(
                          width: 48,
                          child: Text(r.timeLabel,
                              style: MM.body(size: 12, color: Colors.white60)),
                        ),
                        Expanded(
                          child: Text(r.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MM.body(size: 13, color: Colors.white)),
                        ),
                        IconButton(
                          tooltip: 'Mark done',
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.check_circle_outline, color: MM.teal),
                          onPressed: () => RoutineReminders.instance.markDone(r),
                        ),
                      ]),
                    ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }
}

/// Floating card raised the moment a routine's time arrives, so the player can
/// act on that one routine: mark it done, snooze it, or open the timeline.
class RoutineDuePopup extends StatelessWidget {
  const RoutineDuePopup({super.key, required this.onOpenRoutines, this.alignment = Alignment.bottomRight});
  final VoidCallback onOpenRoutines;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RoutineReminders.instance,
      builder: (context, _) {
        final svc = RoutineReminders.instance;
        final r = svc.popup;
        if (r == null) return const SizedBox.shrink();
        return SafeArea(
          child: Align(
            alignment: alignment,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Material(
                  color: const Color(0xFF0D1330),
                  elevation: 12,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: MM.teal.withOpacity(0.6)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.alarm, size: 18, color: MM.teal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                r.anchorLabel != null
                                    ? 'TIME FOR YOUR ROUTINE · ${r.anchorLabel!.toUpperCase()}'
                                    : 'TIME FOR YOUR ROUTINE · ${r.timeLabel}',
                                style: MM.body(size: 10.5, color: MM.teal, weight: FontWeight.w700)),
                          ),
                          InkWell(
                            onTap: svc.dismissPopup,
                            child: const Icon(Icons.close, size: 18, color: Colors.white54),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        Text(r.name,
                            style: MM.body(size: 17, color: Colors.white, weight: FontWeight.w700)),
                        const SizedBox(height: 14),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: MM.teal, foregroundColor: Colors.black),
                            onPressed: () => svc.markDone(r),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Mark done'),
                          ),
                          OutlinedButton(
                            onPressed: () => svc.snooze(r),
                            child: const Text('Snooze 10 min'),
                          ),
                          TextButton(
                            onPressed: () {
                              svc.dismissPopup();
                              onOpenRoutines();
                            },
                            child: const Text('Open'),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
