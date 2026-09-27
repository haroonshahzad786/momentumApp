import 'package:flutter/material.dart';

import '../../services/all_habits.dart';
import '../../theme/momentum_tokens.dart';

/// Swatch for each PRD §11 colour. 🟠 is a real orange so "forming" never
/// reads as a 🌟 note (yellow).
Color habitColorValue(HabitColor? c) => switch (c) {
      HabitColor.red => MM.red,
      HabitColor.orange => const Color(0xFFFF8A1F),
      HabitColor.black => const Color(0xFF1B1F2B),
      HabitColor.green => MM.teal,
      HabitColor.blue => MM.blue,
      HabitColor.note => MM.yellow,
      null => Colors.white.withOpacity(0.28),
    };

/// Status dot. ⚫ gets a light ring so it shows on the dark UI; untagged lines
/// are a hollow ring.
class HabitColorDot extends StatelessWidget {
  const HabitColorDot(this.color, {super.key, this.size = 9});
  final HabitColor? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = color;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c == null ? Colors.transparent : habitColorValue(c),
        border: c == null || c == HabitColor.black
            ? Border.all(color: Colors.white.withOpacity(0.45), width: 1.2)
            : null,
      ),
    );
  }
}

/// The PRD's "status counter at top showing red/orange/green tallies".
class HabitStatusCounter extends StatelessWidget {
  const HabitStatusCounter(this.colors, {super.key, this.leading});
  final Iterable<HabitColor?> colors;

  /// e.g. "12 HABITS", shown before the tallies.
  final String? leading;

  @override
  Widget build(BuildContext context) {
    final n = statusCounts(colors);
    final style = MM.body(size: 12, color: Colors.white.withOpacity(0.7));
    Widget tally(HabitColor c, int count) => Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            HabitColorDot(c),
            const SizedBox(width: 5),
            Text('$count', style: style),
          ]),
        );
    return Semantics(
      label: '${leading ?? ''} ${n.red} red, ${n.orange} orange, ${n.green} green',
      excludeSemantics: true,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (leading != null) Text(leading!, style: style),
        tally(HabitColor.red, n.red),
        tally(HabitColor.orange, n.orange),
        tally(HabitColor.green, n.green),
      ]),
    );
  }
}

/// Picker for the player's own lines. Golden Habits aren't offered it — their
/// 🟠/🟢 comes from formation. Returns null when dismissed; `(color: null)`
/// means "remove the tag".
Future<({HabitColor? color})?> pickHabitColor(BuildContext context, HabitColor? current,
    {String? habitName}) {
  return showModalBottomSheet<({HabitColor? color})>(
    context: context,
    backgroundColor: MM.navy2,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('TAG THIS HABIT',
                style: MM.displayX(size: 11, color: Colors.white)),
            if (habitName != null) ...[
              const SizedBox(height: 4),
              Text(habitName,
                  style: MM.body(size: 12, color: Colors.white.withOpacity(0.6))),
            ],
            const SizedBox(height: 10),
            for (final c in HabitColor.values)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: HabitColorDot(c, size: 14),
                title: Text('${c.emoji}  ${c.label}',
                    style: MM.body(
                        size: 13, color: Colors.white, weight: FontWeight.w600)),
                subtitle: Text(c.meaning,
                    style: MM.body(size: 11, color: Colors.white.withOpacity(0.55))),
                trailing: c == current
                    ? const Icon(Icons.check, color: MM.teal, size: 18)
                    : null,
                onTap: () => Navigator.of(sheet).pop((color: c)),
              ),
            if (current != null)
              TextButton(
                onPressed: () => Navigator.of(sheet).pop((color: null)),
                child: Text('Remove tag',
                    style: MM.body(size: 12, color: Colors.white.withOpacity(0.6))),
              ),
          ],
        ),
      ),
    ),
  );
}
