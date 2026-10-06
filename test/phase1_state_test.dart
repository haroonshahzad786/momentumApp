import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/models/phase1_state.dart';

void main() {
  test('a brand-new player lands straight in the HHS', () {
    const s = Phase1State();
    expect(s.brandNew, isTrue);
    expect(s.finished, isFalse);
    expect(s.landingEntry, 'hhs');
  });

  test('a player part-way through Phase 1 resumes where they left off', () {
    const mid = Phase1State(stage1Progress: 2, lastView: 'section');
    expect(mid.brandNew, isFalse);
    expect(mid.landingEntry, isNull);
    const stage2 = Phase1State(
      stage1Progress: 5,
      stage1Completed: true,
      lastView: 'mbs',
    );
    expect(stage2.finished, isFalse);
    expect(stage2.landingEntry, isNull);
  });

  test('finishing Stage 2 finishes Phase 1', () {
    const done = Phase1State(
      stage1Completed: true,
      stage1Progress: 5,
      stage2Completed: true,
    );
    expect(done.finished, isTrue);
  });

  test('copyWith keeps the resume point unless a new one is given', () {
    const s = Phase1State(lastView: 'section');
    expect(s.copyWith(stage1Progress: 3).lastView, 'section');
    expect(s.copyWith(lastView: 'hub').lastView, 'hub');
  });
}
