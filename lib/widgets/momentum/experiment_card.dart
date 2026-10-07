import 'package:flutter/material.dart';

import '../../models/golden_habit.dart';
import '../../services/experiments.dart';
import '../../theme/momentum_tokens.dart';
import 'glass_panel.dart';
import 'mm_buttons.dart';

/// 🧪 The active experiment on a Golden Habit (#23): what changed, Day N of
/// 3, and — once its 3 check-ins are in — the before / during scores with
/// Keep / Retire ("Successful experiments become permanent; unsuccessful ones
/// are retired with learnings captured"). The player decides; the card only
/// recommends.
class ExperimentCard extends StatelessWidget {
  const ExperimentCard({
    super.key,
    required this.experiment,
    required this.progress,
    required this.coreName,
    required this.onKeep,
    required this.onRetire,
    this.onGoDeeper,
    this.busy = false,
    this.showTitle = true,
  });

  final HabitExperiment experiment;
  final ExperimentProgress progress;
  final String coreName;
  final VoidCallback onKeep;
  final VoidCallback onRetire;

  /// Offered when the scores didn't lift — "If not, we go deeper."
  final VoidCallback? onGoDeeper;
  final bool busy;
  final bool showTitle;

  static const _purple = MM.violet;

  static String _short(String s, [int max = 90]) {
    final t = s.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.isEmpty) return '(empty)';
    return t.length <= max ? t : '${t.substring(0, max - 1)}…';
  }

  static String _avg(double? v) => v == null ? '—' : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final e = experiment;
    return GlassPanel(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      leftAccentColor: _purple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTitle) ...[
            Row(
              children: [
                Text(
                  '🧪 EXPERIMENT',
                  style: MM.displayX(size: 9, color: _purple),
                ),
                const Spacer(),
                Text(
                  p.due ? '3 OF 3 · READY' : 'DAY ${p.day} OF $experimentLength',
                  style: MM.displayX(
                    size: 9,
                    color: p.due ? MM.teal : Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Text(
            e.title.isEmpty ? 'Habit tweak' : e.title,
            style: MM.display(size: 14, color: Colors.white),
          ),
          if (e.hypothesis.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              e.hypothesis,
              style: MM.body(color: Colors.white.withOpacity(0.7), size: 12),
            ),
          ],
          const SizedBox(height: 8),
          for (final c in e.changes.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: RichText(
                text: TextSpan(
                  style: MM.body(color: Colors.white, size: 12),
                  children: [
                    TextSpan(
                      text: '${experimentFieldLabels[c.key] ?? c.key}: ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: _short(c.value.from),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const TextSpan(text: '  →  '),
                    TextSpan(text: _short(c.value.to)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 4),
          if (!p.due)
            Text(
              p.done == 0
                  ? 'Starts with your next $coreName check-in. Nova checks in '
                      'after $experimentLength.'
                  : '${p.done} of $experimentLength $coreName check-ins in '
                      '(scores ${p.during.join(' · ')}). Nova checks in after '
                      '$experimentLength.',
              style: MM.body(color: Colors.white.withOpacity(0.55), size: 11.5),
            )
          else ...[
            Text(
              'Before: ${_avg(p.baselineAvg)} avg'
              '${p.baseline.isEmpty ? ' (no earlier scores)' : ''}  ·  '
              'During: ${_avg(p.duringAvg)} avg (${p.during.join(' · ')})',
              style: MM.body(color: Colors.white, size: 12.5),
            ),
            const SizedBox(height: 6),
            Text(
              p.improved
                  ? "Your scores lifted — this one's working. Keep it and it "
                      'becomes part of the habit for good.'
                  : "No clear lift yet. That's data, not failure — retire it "
                      "(Nova won't suggest it again) or go deeper.",
              style: MM.body(
                color: (p.improved ? MM.teal : MM.yellow).withOpacity(0.9),
                size: 12,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                IntrinsicWidth(
                  child: MMPrimaryButton(
                    label: '✅ Keep it',
                    busy: busy,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    onPressed: busy ? null : onKeep,
                  ),
                ),
                IntrinsicWidth(
                  child: MMGhostButton(
                    label: '♻️ Retire it',
                    color: MM.yellow,
                    borderColor: MM.yellow.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    onPressed: busy ? null : onRetire,
                  ),
                ),
                if (!p.improved && onGoDeeper != null)
                  IntrinsicWidth(
                    child: MMGhostButton(
                      label: '🔬 Go Deeper',
                      color: MM.blue,
                      borderColor: MM.blue.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      onPressed: busy ? null : onGoDeeper,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Asks what the player learned before retiring an experiment ("retired
/// with learnings captured"). Null = cancelled; '' = retire without a note.
Future<String?> askRetireLearnings(BuildContext context) {
  final ctl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          backgroundColor: MM.navy2,
          title: Text(
            'RETIRE THIS EXPERIMENT',
            style: MM.displayX(size: 12, color: MM.yellow),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "The old version comes back, and Nova won't suggest this tweak "
                'again. What did you learn? (optional)',
                style: MM.body(color: Colors.white.withOpacity(0.8), size: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ctl,
                minLines: 2,
                maxLines: 4,
                style: MM.body(color: Colors.white, size: 13),
                cursorColor: MM.yellow,
                decoration: InputDecoration(
                  hintText: 'e.g. 6am was too early on school days',
                  hintStyle: MM.body(color: Colors.white38, size: 12),
                  filled: true,
                  fillColor: MM.navy.withOpacity(0.55),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: MM.body(color: Colors.white70, size: 13),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctl.text.trim()),
              child: Text(
                'Retire it',
                style: MM.body(color: MM.yellow, size: 13),
              ),
            ),
          ],
        ),
  );
}

/// "Nova checks in after 3 days" — shown on the Cockpit once an experiment's
/// 3 check-ins are in, until the player keeps or retires it ([onLater] hides
/// it for today).
class ExperimentReviewOverlay extends StatelessWidget {
  const ExperimentReviewOverlay({
    super.key,
    required this.habitName,
    required this.experiment,
    required this.progress,
    required this.coreName,
    required this.onKeep,
    required this.onRetire,
    required this.onGoDeeper,
    required this.onLater,
    this.busy = false,
  });

  final String habitName;
  final HabitExperiment experiment;
  final ExperimentProgress progress;
  final String coreName;
  final VoidCallback onKeep;
  final VoidCallback onRetire;
  final VoidCallback onGoDeeper;
  final VoidCallback onLater;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.72),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '🧪 NOVA CHECKING IN',
                  style: MM.displayX(size: 11, color: MM.violet),
                ),
                const SizedBox(height: 8),
                Text(
                  '$experimentLength check-ins since you started this '
                  'experiment on $habitName. Here\'s how it went:',
                  style: MM.body(color: Colors.white, size: 13.5, height: 1.45),
                ),
                const SizedBox(height: 12),
                ExperimentCard(
                  experiment: experiment,
                  progress: progress,
                  coreName: coreName,
                  busy: busy,
                  onKeep: onKeep,
                  onRetire: onRetire,
                  onGoDeeper: onGoDeeper,
                ),
                Align(
                  child: TextButton(
                    onPressed: busy ? null : onLater,
                    child: Text(
                      'Decide later',
                      style: MM.body(color: Colors.white60, size: 12.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
