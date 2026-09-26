import 'package:flutter/material.dart';
import '../../theme/momentum_tokens.dart';
import 'mm_buttons.dart';

/// iCore Alert (PHASE 1 & 2 DETAILS §"When a Core Is Out of Balance").
///
/// Shown when a Core has scored below 3.0 for 5+ consecutive days. A supportive
/// (never shaming) coaching message: names the unbalanced Core, shows the recent
/// low scores, suggests reviewing that Core's habits with links, and a [Done]
/// button to acknowledge.
class CoreAlertSheet extends StatelessWidget {
  const CoreAlertSheet({
    super.key,
    required this.coreName,
    required this.coreColor,
    required this.lowScores,
    required this.streakDays,
    this.recoveryDays = 0,
    this.otherStrugglingCores = const [],
    required this.onReviewHabits,
    required this.onReturnToPhase1,
    this.onGetAiHelp,
    this.onSimplify,
    required this.onDone,
  });

  final String coreName;
  final Color coreColor;

  /// The recent below-3.0 scores, most-recent-first.
  final List<int> lowScores;

  /// Consecutive days below 3.0.
  final int streakDays;

  /// Consecutive days above 3.0 since the low run (#18 — the alert clears at 2).
  final int recoveryDays;

  /// Names of the other Cores with an open alert (#18 multi-Core alert).
  final List<String> otherStrugglingCores;

  final VoidCallback onReviewHabits;
  final VoidCallback onReturnToPhase1;

  /// [Get AI Help] — targeted Nova session (spec §10 AI Dependency).
  final VoidCallback? onGetAiHelp;

  /// [Emergency Simplification Mode] — offered only in the multi-Core alert.
  final VoidCallback? onSimplify;
  final VoidCallback onDone;

  static const _red = MM.red;

  @override
  Widget build(BuildContext context) {
    // Oldest-first for a left→right "recent days" read.
    final bars = lowScores.take(5).toList().reversed.toList();
    // Overlay sits above the Scaffold layer, so provide a Material ancestor for
    // the InkWell-based buttons.
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
        // Scrim — tap to dismiss.
        Positioned.fill(
          child: GestureDetector(
            onTap: onDone,
            child: Container(color: const Color(0xCC06070D)),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: MM.navy.withOpacity(0.97),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _red.withOpacity(0.55)),
                boxShadow: [
                  BoxShadow(color: _red.withOpacity(0.25), blurRadius: 28),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('⚠️', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text('iCORE ALERT · ${coreName.toUpperCase()}',
                        style: MM.displayX(size: 11, color: _red)),
                  ]),
                  const SizedBox(height: 12),
                  Text(
                    'This core is unbalanced. You should focus your work to '
                    'improve it.',
                    style: MM.body(color: Colors.white, size: 14, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  // Recent low scores.
                  Text(
                    'BELOW 3.0 · $streakDays CONSECUTIVE DAYS',
                    style: MM.displayX(
                        size: 9, color: Colors.white.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 56,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < bars.length; i++)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: i == 0 ? 0 : 4,
                                  right: i == bars.length - 1 ? 0 : 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('${bars[i]}',
                                      style: MM.display(size: 11, color: _red)),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: (bars[i] / 5) * 36,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [_red, _red.withOpacity(0.5)],
                                      ),
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(3)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Review your $coreName habits — revisiting them in Phase 1 '
                    'can re-engineer what isn\'t landing.',
                    style: MM.body(
                        color: Colors.white.withOpacity(0.7),
                        size: 12.5,
                        height: 1.5),
                  ),
                  if (recoveryDays > 0) ...[
                    const SizedBox(height: 10),
                    Text(
                      '$recoveryDays day${recoveryDays == 1 ? '' : 's'} above 3.0 — '
                      '${recoveryDays >= 2 ? 'alert clears' : 'one more clears this alert'}.',
                      style: MM.body(color: MM.teal, size: 12.5, height: 1.4),
                    ),
                  ],
                  if (otherStrugglingCores.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _red.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'ALSO STRUGGLING · ${otherStrugglingCores.join(' · ').toUpperCase()}',
                            style: MM.displayX(size: 9, color: _red),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Multiple Cores are struggling. This might indicate broader '
                            'life stress. Consider simplifying or getting support.',
                            style: MM.body(color: Colors.white, size: 13, height: 1.45),
                          ),
                          if (onSimplify != null) ...[
                            const SizedBox(height: 10),
                            MMGhostButton(
                              label: 'Emergency Simplification Mode',
                              expand: true,
                              borderColor: MM.teal.withOpacity(0.6),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              onPressed: onSimplify,
                            ),
                            const SizedBox(height: 6),
                            Text("Let's simplify to keep your momentum alive.",
                                textAlign: TextAlign.center,
                                style: MM.body(
                                    color: Colors.white.withOpacity(0.6), size: 11.5)),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  // Links to detailed habit views / refinement.
                  Row(children: [
                    Expanded(
                      child: MMGhostButton(
                        label: 'Review Habits',
                        expand: true,
                        borderColor: coreColor.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        onPressed: onReviewHabits,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: MMGhostButton(
                        label: 'Return to Phase 1',
                        expand: true,
                        borderColor: MM.yellow.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        onPressed: onReturnToPhase1,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  if (onGetAiHelp != null) ...[
                    MMGhostButton(
                      label: '🤖 Get AI Help',
                      expand: true,
                      borderColor: MM.blue.withOpacity(0.6),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onPressed: onGetAiHelp,
                    ),
                    const SizedBox(height: 10),
                  ],
                  MMPrimaryButton(label: 'Done', onPressed: onDone),
                ],
              ),
            ),
          ),
          ),
        ),
        ],
      ),
    );
  }
}
