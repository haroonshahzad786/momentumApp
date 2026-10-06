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

  /// Phase 1 is finished once Stage 2 is — the player then lives in Phase 2.
  bool get finished => stage2Completed;

  /// Nothing done yet: the player has never started the HHS (#26 / P1-1).
  bool get brandNew => !stage1Completed && stage1Progress == 0;

  /// Where an app launch lands an unfinished player (#26 / P1-1): 'hhs' takes
  /// a brand-new player straight into Nova; null resumes at [lastView]. Not
  /// used once [finished].
  String? get landingEntry => brandNew ? 'hhs' : null;

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
