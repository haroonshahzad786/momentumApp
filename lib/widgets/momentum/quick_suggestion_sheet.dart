import 'package:flutter/material.dart';

import '../../models/golden_habit.dart';
import '../../services/experiments.dart' show experimentLength;
import '../../services/habits_service.dart';
import '../../services/offline.dart';
import '../../theme/momentum_tokens.dart';
import 'mm_buttons.dart';

/// What the player did with a [QuickSuggestionSheet].
enum QuickSuggestionOutcome { added, goDeeper, skipped }

/// Result: the outcome, and the experiment it started (when added).
typedef QuickSuggestionResult = ({
  QuickSuggestionOutcome outcome,
  HabitExperiment? experiment,
});

/// Opens the 🚀 Quick Suggestion sheet for a habit (#23 step 2). [note] is
/// what the player said about it (the flag note) or why it was flagged.
Future<QuickSuggestionResult> showQuickSuggestion(
  BuildContext context, {
  required String userId,
  required String habitId,
  required String habitName,
  String note = '',
}) async {
  final r = await showModalBottomSheet<QuickSuggestionResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (_) => QuickSuggestionSheet(
          userId: userId,
          habitId: habitId,
          habitName: habitName,
          note: note,
        ),
  );
  return r ?? (outcome: QuickSuggestionOutcome.skipped, experiment: null);
}

/// Phase 1 & 2 Details, PATH 1 — Quick Suggestion: Nova scans the player's
/// data, names the friction point, offers 1–2 tweaks → [✅ Add as Experiment]
/// [🔬 Go Deeper Instead] [⏭️ Skip]. One Claude call per open.
class QuickSuggestionSheet extends StatefulWidget {
  const QuickSuggestionSheet({
    super.key,
    required this.userId,
    required this.habitId,
    required this.habitName,
    this.note = '',
    this.service,
  });

  final String userId;
  final String habitId;
  final String habitName;
  final String note;

  /// For tests.
  final HabitsService? service;

  @override
  State<QuickSuggestionSheet> createState() => _QuickSuggestionSheetState();
}

class _QuickSuggestionSheetState extends State<QuickSuggestionSheet> {
  late final HabitsService _habits = widget.service ?? HabitsService();
  QuickSuggestion? _s;
  Object? _error;
  bool _saving = false;
  final Set<String> _off = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _s = null;
      _error = null;
    });
    try {
      final s = await _habits.quickSuggestion(
        userId: widget.userId,
        habitId: widget.habitId,
        note: widget.note,
      );
      if (mounted) setState(() => _s = s);
    } catch (e) {
      debugPrint('QuickSuggestion failed: $e');
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _add() async {
    final s = _s!;
    final picked = [
      for (final t in s.tweaks)
        if (!_off.contains(t.field)) t,
    ];
    if (picked.isEmpty) return;
    setState(() => _saving = true);
    try {
      final exp = await _habits.updateHabitDetail(
        userId: widget.userId,
        habitId: widget.habitId,
        fields: {for (final t in picked) t.field: t.to},
        experiment: {
          'source': 'quick',
          'title': s.title,
          'hypothesis': s.hypothesis,
        },
      );
      if (!mounted) return;
      Navigator.pop<QuickSuggestionResult>(context, (
        outcome: QuickSuggestionOutcome.added,
        experiment: exp,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNetworkError(e)
                ? "You're offline — nothing was saved"
                : "Couldn't save the tweak — try again",
          ),
        ),
      );
    }
  }

  void _close(QuickSuggestionOutcome o) =>
      Navigator.pop<QuickSuggestionResult>(context, (
        outcome: o,
        experiment: null,
      ));

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.88;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 620, maxHeight: maxH),
        child: Material(
          color: MM.navy2,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '🚀 QUICK SUGGESTION · NOVA',
                    style: MM.displayX(size: 11, color: MM.yellow),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.habitName,
                    style: MM.display(size: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  ..._body(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body() {
    if (_error != null) {
      return [
        Text(
          isNetworkError(_error!)
              ? "You're offline — Nova can't scan your data right now."
              : "Nova couldn't come up with a tweak this time.",
          style: MM.body(color: Colors.white, size: 13),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IntrinsicWidth(
              child: MMPrimaryButton(
                label: 'Try again',
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                onPressed: _load,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => _close(QuickSuggestionOutcome.goDeeper),
              child: Text(
                '🔬 Go Deeper instead',
                style: MM.body(color: MM.blue, size: 13),
              ),
            ),
          ],
        ),
      ];
    }
    final s = _s;
    if (s == null) {
      return [
        const SizedBox(height: 18),
        const Center(child: CircularProgressIndicator(color: MM.yellow)),
        const SizedBox(height: 12),
        Center(
          child: Text(
            "Scanning your Momentum Lists, Captain's Log and scores…",
            textAlign: TextAlign.center,
            style: MM.body(color: Colors.white70, size: 12.5),
          ),
        ),
        const SizedBox(height: 18),
      ];
    }
    return [
      if (s.dataPoints.isNotEmpty) ...[
        _label('📋 WHAT NOVA SAW', Colors.white60),
        for (final d in s.dataPoints)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${d.source.isEmpty ? '' : '${d.source}: '}${d.text}',
              style: MM.body(color: Colors.white.withOpacity(0.8), size: 12),
            ),
          ),
        const SizedBox(height: 10),
      ],
      _label('📍 DIAGNOSIS', MM.yellow),
      Text(s.diagnosis, style: MM.body(color: Colors.white, size: 13)),
      const SizedBox(height: 12),
      _label('💡 TRY THIS TOMORROW', MM.teal),
      for (final t in s.tweaks) _tweak(t, s.tweaks.length > 1),
      if (s.hypothesis.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(
          'Why this fits you: ${s.hypothesis}',
          style: MM.body(color: Colors.white.withOpacity(0.7), size: 12),
        ),
      ],
      const SizedBox(height: 10),
      Text(
        '🧪 This becomes a $experimentLength-day experiment. If your scores '
        'improve it becomes permanent; if not, we go deeper.',
        style: MM.body(color: MM.violet.withOpacity(0.95), size: 12),
      ),
      const SizedBox(height: 14),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          IntrinsicWidth(
            child: MMPrimaryButton(
              label: '✅ Add as Experiment',
              busy: _saving,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              onPressed:
                  _saving || _off.length == s.tweaks.length ? null : _add,
            ),
          ),
          IntrinsicWidth(
            child: MMGhostButton(
              label: '🔬 Go Deeper Instead',
              color: MM.blue,
              borderColor: MM.blue.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              onPressed:
                  _saving ? null : () => _close(QuickSuggestionOutcome.goDeeper),
            ),
          ),
          TextButton(
            onPressed:
                _saving ? null : () => _close(QuickSuggestionOutcome.skipped),
            child: Text(
              '⏭️ Skip',
              style: MM.body(color: Colors.white60, size: 13),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _label(String t, Color c) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: MM.displayX(size: 9, color: c)),
  );

  Widget _tweak(SuggestedTweak t, bool selectable) {
    final on = !_off.contains(t.field);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: MM.navy.withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: on ? MM.teal.withOpacity(0.5) : Colors.white12,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectable)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Checkbox(
                value: on,
                activeColor: MM.teal,
                visualDensity: VisualDensity.compact,
                onChanged:
                    (v) => setState(
                      () => v == true ? _off.remove(t.field) : _off.add(t.field),
                    ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.label,
                  style: MM.displayX(size: 9, color: Colors.white60),
                ),
                const SizedBox(height: 4),
                if (t.from.isNotEmpty)
                  Text(
                    t.from,
                    style: MM
                        .body(color: Colors.white38, size: 12)
                        .copyWith(decoration: TextDecoration.lineThrough),
                  ),
                Text(t.to, style: MM.body(color: Colors.white, size: 13)),
                if (t.why.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    t.why,
                    style: MM.body(
                      color: Colors.white.withOpacity(0.6),
                      size: 11.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
