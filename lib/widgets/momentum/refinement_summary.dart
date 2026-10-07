import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/golden_habit.dart';
import '../../services/checkin_service.dart';
import '../../services/experiments.dart';
import '../../services/habits_service.dart';
import '../../services/onboarding_service.dart' show GoldenHabitRef;
import '../../theme/momentum_tokens.dart';
import 'experiment_card.dart';
import 'mm_buttons.dart';
import 'starfield.dart';

/// Sequence "RETURNING PLAYERS — PATHWAY 3: Post-Phase-1-Refinement Flow"
/// (#23 step 3): after a Go Deeper rebuild, "briefly acknowledge what changed
/// and why", position it as a 🧪 experiment launch, and deliver the daily
/// check-in "right now in the same session". Prior scores, streak and Trophy
/// Room are untouched — only this habit changed.
class RefinementSummaryView extends StatefulWidget {
  const RefinementSummaryView({
    super.key,
    required this.habitId,
    required this.rebuilt,
    required this.onCheckin,
    required this.onCockpit,
  });

  final String habitId;

  /// true = Stage 1 rebuild (the habit itself); false = Stage 2 (new MBMs).
  final bool rebuilt;
  final VoidCallback onCheckin;
  final VoidCallback onCockpit;

  @override
  State<RefinementSummaryView> createState() => _RefinementSummaryViewState();
}

class _RefinementSummaryViewState extends State<RefinementSummaryView> {
  GoldenHabit? _h;
  List<DailyCheckin> _checkins = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      final res = await HabitsService().getGoldenHabits(uid);
      List<DailyCheckin> checkins = const [];
      try {
        checkins = await CheckinService().getRecent(uid, limit: 30);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _h = res.data.where((h) => h.habitId == widget.habitId).firstOrNull;
        _checkins = checkins;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = _h;
    final e = h?.experiment;
    final core = h == null ? '' : GoldenHabitRef.shortCore(h.coreId);
    return Scaffold(
      backgroundColor: MM.pageBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child:
                      _loading
                          ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 80),
                            child: Center(
                              child: CircularProgressIndicator(color: MM.teal),
                            ),
                          )
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                '🛠️',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 52),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'BACK TO THE MISSION',
                                textAlign: TextAlign.center,
                                style: MM.displayX(size: 11, color: MM.teal),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                h == null
                                    ? 'Your habit is updated'
                                    : widget.rebuilt
                                    ? '${h.habitName} has been rebuilt'
                                    : '${h.habitName} has new MBMs',
                                textAlign: TextAlign.center,
                                style: MM.display(size: 20, color: Colors.white),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                e != null
                                    ? "Here's what's different, and why it should work better:"
                                    : 'Nothing in its setup changed this time. '
                                        "It's ready for today's check-in.",
                                textAlign: TextAlign.center,
                                style: MM.body(
                                  color: Colors.white.withOpacity(0.75),
                                  size: 13,
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (h != null && e != null)
                                ExperimentCard(
                                  experiment: e,
                                  progress: experimentProgress(e, core, _checkins),
                                  coreName: h.coreLabel,
                                  // Not due yet: the card shows no outcome
                                  // buttons until its 3 check-ins are in.
                                  onKeep: () {},
                                  onRetire: () {},
                                ),
                              Text(
                                'Your scores, streak and Trophy Room are untouched. '
                                'Only this habit changed.',
                                textAlign: TextAlign.center,
                                style: MM.body(
                                  color: Colors.white.withOpacity(0.55),
                                  size: 12,
                                ),
                              ),
                              const SizedBox(height: 18),
                              MMPrimaryButton(
                                label: "Start today's check-in →",
                                pulse: true,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                onPressed: widget.onCheckin,
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: widget.onCockpit,
                                child: Text(
                                  'Back to the Cockpit',
                                  style: MM.body(
                                    color: Colors.white60,
                                    size: 13,
                                  ),
                                ),
                              ),
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
