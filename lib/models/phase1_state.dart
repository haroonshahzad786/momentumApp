/// Phase 1 onboarding state — Stage 1 (HHS) progress + Stage 2 (MBS) flag.
///
/// Shape mirrors the JSX design `phase1State`:
///   { stage1Progress: 0-5, stage1Completed, stage2Completed, lastView? }
class Phase1State {
  const Phase1State({
    this.stage1Progress = 0,
    this.stage1Completed = false,
    this.stage2Completed = false,
    this.lastView,
  });

  final int stage1Progress;
  final bool stage1Completed;
  final bool stage2Completed;
  final String? lastView;

  Phase1State copyWith({
    int? stage1Progress,
    bool? stage1Completed,
    bool? stage2Completed,
    String? lastView,
  }) {
    return Phase1State(
      stage1Progress: stage1Progress ?? this.stage1Progress,
      stage1Completed: stage1Completed ?? this.stage1Completed,
      stage2Completed: stage2Completed ?? this.stage2Completed,
      lastView: lastView ?? this.lastView,
    );
  }
}
