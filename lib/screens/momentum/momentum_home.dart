import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/behavior_tracker.dart';

import '../../models/phase1_state.dart';
import '../../models/user_profile.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../models/golden_habit.dart';
import '../../services/checkin_service.dart';
import '../../services/core_fuel.dart';
import '../../services/experiments.dart';
import '../../services/habits_service.dart';
import '../../services/notification_service.dart';
import '../../services/routine_reminders.dart';
import '../../widgets/momentum/routine_reminder_ui.dart';
import '../../services/offline.dart';
import '../../services/onboarding_service.dart';
import '../../services/points_service.dart';
import '../../services/profile_service.dart';
import '../../theme/momentum_tokens.dart';
import '../../widgets/momentum/all_habits_view.dart';
import '../../widgets/momentum/non_routines_view.dart';
import '../../widgets/momentum/celebration_host.dart';
import '../../widgets/momentum/core_alert_sheet.dart';
import '../../widgets/momentum/menu_drawer.dart';
import '../../widgets/momentum/mm_buttons.dart';
import '../../widgets/momentum/offline_banner.dart';
import '../../widgets/momentum/screen_shell.dart';
import '../../widgets/momentum/starfield.dart';
import '../../widgets/momentum/web_shell.dart';
// Co-Pilot v2 (console layout). The original `ai_chat_page.dart` is still on
// disk but no longer linked — swap this import back to compare the two.
import '../admin/admin_gate.dart';
import '../admin/admin_shell.dart';
import '../copilot_console_page.dart';
import 'checkin_page.dart';
import 'daily_ritual_step0.dart';
import 'dashboard_page.dart';
import 'journey_page.dart';
import 'phase1_flow.dart';
import '../../widgets/momentum/habit_detail_view.dart';
import '../../widgets/momentum/core_unlock_overlay.dart';
import '../../widgets/momentum/experiment_card.dart';
import '../../widgets/momentum/phase2_launch.dart';
import 'sub_screens.dart';
import 'summary_page.dart';
import 'web_cockpit.dart';
import 'web_screens.dart';
import '../../widgets/momentum/ship_warning.dart';
import '../../widgets/momentum/streak_protection.dart';
import '../../services/journey_config_service.dart';

/// Post-auth shell. Owns the active screen, menu drawer, and routing
/// between Dashboard / Check-in / Summary / sub-screens / chat.
class MomentumHome extends StatefulWidget {
  const MomentumHome({super.key});

  @override
  State<MomentumHome> createState() => _MomentumHomeState();
}

class _MomentumHomeState extends State<MomentumHome> {
  String _screen = 'dashboard';

  /// Short Core id the Habits screen is filtered to (a Core tapped on the
  /// rocket, #20); null shows every Core.
  String? _habitsCore;
  String? _routinesFocus; // Golden Habit id to show on Routines

  /// List opened from a Command Center console button (`lists:<name>`).
  Set<String> _listsExpand = const {};

  /// Locked Core the player chose to fuel — pre-drafts the HHS opener.
  String? _fuelCore;

  /// How the returning player chose to start fuelling [_fuelCore] on Nova's
  /// screen (returning_voluntary / returning_guided); read once by Phase 1.
  String? _phase1Mode;

  /// Locked Core being fuelled: Nova shows the start options instead of chat.
  String? _novaChooseCore;

  /// Core + start mode of the Habits Hierarchy conversation shown in Nova's
  /// panel (cleared the next time Nova opens).
  ({String core, String mode})? _novaFuel;

  /// Detailed Habit View (#22): the open Golden Habit, and the screen its
  /// back button returns to.
  String? _habitId;
  String _habitReturn = 'habits';

  /// First-time vs returning landing (#26 / P1-1) runs once per session.
  bool _landingDone = false;

  /// Cores that just lit up, waiting for their "CORE UNLOCKED" moment (#30).
  final List<String> _coreUnlocks = [];

  /// Phase 1 → Phase 2 hand-off right after Stage 2 (#25 / P1-8):
  /// 'mission' ("The Mission Begins") then 'tour' (cockpit tour); null = none.
  String? _launch;
  bool _menuOpen = false;

  // Nova (Co-Pilot) floats over the current screen instead of replacing it, so
  // the menu and stats stay on screen. `_novaFull` swaps it for the roomy
  // full-screen chat. One GlobalKey keeps the same conversation (and any typed
  // text) alive while it moves between the two layouts.
  bool _novaOpen = false;
  bool _novaFull = false;
  String? _novaDraft;
  GlobalKey _novaKey = GlobalKey();

  /// Menu → Command Center: land on the cockpit with the console open.
  bool _openCommand = false;
  final _auth = AuthService();
  final _adminService = AdminService();
  bool _isAdmin = false;
  final _profileService = ProfileService();
  final _checkin = CheckinService();
  final _habitsService = HabitsService();

  /// Golden Habits whose 🧪 experiment has run its 3 check-ins (#23) — Nova
  /// asks keep / retire on the Cockpit — and the check-ins behind them.
  List<GoldenHabit> _dueExperiments = const [];
  List<DailyCheckin> _expCheckins = const [];
  bool _expBusy = false;
  final _onboarding = OnboardingService();
  final _points = PointsService();

  UserProfile? _profile;

  // #16 missed check-ins: relaunch screen (2+ missed weekdays, once per gap)
  // and the 1-miss Ship Warning banner (snoozable for an hour).
  bool _relaunchOpen = false;
  bool _warnSnoozed = false;
  bool _checkedInThisSession = false;
  bool _loading = true;
  bool _offline = false;
  bool _errorOffline = false;
  String? _error;

  // The scores from the most recent check-in, handed to the Summary so its
  // Balance Meter reflects today before the Firestore read settles.
  Map<String, int> _lastCheckinScores = const {};

  // Momentum Points engine (#9): points credited for today's check-in (shown as
  // the Summary's "Earned Today") and an optimistic running-total override so
  // the new score shows immediately without a profile-reload spinner. The
  // override is cleared on the next authoritative profile fetch.
  int? _earnedToday;
  int? _momentumOverride;

  // Streak (#10): optimistic override of the running streak after a qualifying
  // check-in (cleared on the next authoritative profile fetch) + the milestone
  // reached this check-in, handed to the Summary for a celebration.
  int? _streakOverride;
  int? _streakMilestone;

  // Space Credits (#13): optimistic override of the balance after a check-in
  // earns credits (cleared on the next authoritative profile fetch).
  int? _creditsOverride;

  // Phase 1 progress. Seeded from the persisted profile on launch (see
  // _fetchProfile) and written back to Firestore on every change via
  // _persistPhase1 so it survives an app restart.
  Phase1State _phase1 = const Phase1State();

  // Phase 1 Re-Entry Bridge target (§4C): null → hub · 'hhs' → Stage 1 rebuild
  // · 'mbs' → Stage 2 MBM re-engineer. Set by _returnToPhase1, read by
  // Phase1Flow on entry, and cleared on any normal navigation via _go.
  String? _phase1Entry;
  // Golden Habit id to pre-load on re-entry (Mission Control "Go Deeper").
  String? _phase1EntryHabitId;

  // Real check-in context for Mission Control (#7): per-Core prior scores (for
  // the ≤3.0×3 auto-flag pattern) and each Core's Golden Habit. Prefetched when
  // the check-in flow starts so the data is ready by the time scoring begins.
  Map<String, List<int>> _checkinCoreHistory = const {};
  Map<String, GoldenHabitRef> _checkinHabitByCore = const {};
  Map<String, List<GoldenHabitRef>> _checkinHabitsByCore = const {};

  // Core Balance 5-day alert (#8): each Core's recent daily scores (most-recent-
  // first, incl. today's saved score) and the set out of balance (<3.0 for 5+
  // consecutive days). Feeds the red ⚠️ badge + iCore Alert on dashboard +
  // check-in. `_coreAlertCore` is the Core whose iCore Alert overlay is open.
  Map<String, List<int>> _coreScores = const {};

  /// #18 Balance % — variance of the 7-day Core averages; null = no data yet.
  int? _balancePct;
  Set<String> _atRiskCores = const {};
  String? _coreAlertCore;

  // shortCoreId → (display name, accent color), matching the check-in/summary.
  static const _coreMeta = <String, (String, Color)>{
    'mindset': ('Mindset', MM.blue),
    'career': ('Career & Finances', MM.yellow),
    'relationships': ('Relationships', MM.magenta),
    'physical': ('Physical Health', MM.teal),
    'emotional': ('Emotional & Mental', MM.violet),
  };

  @override
  void initState() {
    super.initState();
    BehaviorTracker.instance
      ..start()
      ..screen(_screen);
    _fetchProfile();
    RoutineReminders.instance.start();
    // Admin-controlled planet route (config/journey, #42) — rebuild the app
    // chrome when an admin publishes a new set of planets.
    JourneyConfigService.ensureLoaded();
    JourneyConfigService.listenable.addListener(_onRouteChanged);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      NotificationService.instance.saveTokenForUser(uid);
    }
    // Nav-visibility check only — AdminGate re-verifies (force-refreshed) on
    // actual entry to the admin screen. See ADMIN_PANEL_BACKEND_PLAN.md §0.
    _adminService.isAdmin(forceRefresh: true).then((ok) {
      if (mounted) setState(() => _isAdmin = ok);
    });
    NotificationService.instance.pendingThread.addListener(_onPendingThread);
    // Handle a notification that launched the app from a cold start.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onPendingThread());
  }

  /// Opens the thread referenced by a tapped notification, then clears it.
  void _onPendingThread() {
    final tid = NotificationService.instance.pendingThread.value;
    if (tid == null || !mounted) return;
    NotificationService.instance.pendingThread.value = null;
    _go('thread:$tid');
  }

  @override
  void dispose() {
    NotificationService.instance.pendingThread.removeListener(_onPendingThread);
    RoutineReminders.instance.stop();
    _profileService.dispose();
    _onboarding.dispose();
    _points.dispose();
    JourneyConfigService.listenable.removeListener(_onRouteChanged);
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Not signed in';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _profileService.getProfile(uid);
      if (!mounted) return;
      setState(() {
        _profile = result.data;
        // Seed Phase 1 from the persisted profile so progress survives restart.
        _phase1 = result.data.phase1State;
        _offline = result.fromCache;
        _loading = false;
        // Fresh profile is authoritative — drop the optimistic overrides.
        _momentumOverride = null;
        _streakOverride = null;
        _creditsOverride = null;
      });
      _landInPhase1IfUnfinished();
      _checkCoreUnlocks(result.data.activeCores);
      _checkExperiments();
      // Compute the Core Balance 5-day alert badges (#8) from real check-ins.
      _loadCoreBalance();
      _evaluateMissState(result.data);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _errorOffline = isNetworkError(e);
        _loading = false;
      });
    }
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  String _relaunchSeenKey(UserProfile p) =>
      'relaunch:seen:$_uid:${p.lastCompletedCheckinDate}';
  String get _warnSnoozeKey => 'shipwarn:snooze:$_uid';

  /// Decides whether to open the relaunch screen (#16) — once per gap, keyed to
  /// the last completed check-in — and whether the 1-miss banner is snoozed.
  Future<void> _evaluateMissState(UserProfile p) async {
    if (_uid == null || _checkedInThisSession) return;
    if (p.needsRelaunch) {
      final seen = await LocalCache.getJson(_relaunchSeenKey(p));
      if (mounted && seen != true) setState(() => _relaunchOpen = true);
    } else if (p.missState == 'warning') {
      final until = await LocalCache.getJson(_warnSnoozeKey);
      final snoozed =
          until is num && DateTime.now().millisecondsSinceEpoch < until.toInt();
      if (mounted) setState(() => _warnSnoozed = snoozed);
    }
  }

  void _closeRelaunch() {
    final p = _profile;
    if (p != null) LocalCache.putJson(_relaunchSeenKey(p), true);
    setState(() => _relaunchOpen = false);
  }

  void _snoozeShipWarning() {
    LocalCache.putJson(
      _warnSnoozeKey,
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
    );
    setState(() => _warnSnoozed = true);
  }

  bool get _showShipWarning =>
      _screen == 'dashboard' &&
      !_relaunchOpen &&
      !_warnSnoozed &&
      !_checkedInThisSession &&
      _profile?.missState == 'warning';

  Widget _buildRelaunch() {
    final p = _profile!;
    void then(VoidCallback f) {
      _closeRelaunch();
      f();
    }

    return RelaunchSheet(
      missedWeekdays: p.missedWeekdays,
      longAbsence: p.missState == 'long_absence',
      pointsRemoved: p.missPenaltyApplied,
      formedHabits: p.formedHabitsCount,
      spaceCredits: _creditsOverride ?? p.spaceCredits,
      level: p.level,
      onQuickCheckIn: () => then(() => _go('checkin_quick')),
      onFullCheckIn: () => then(_startCheckin),
      onCaptainsLog: () => then(() => _go('lists')),
      onTalkToNova: () => then(_openChat),
      onCantina:
          _phase1.stage2Completed ? () => then(() => _go('cantina')) : null,
      onClose: _closeRelaunch,
    );
  }

  /// #17 Streak Savers + Vacation Mode. Refetches the profile after a change
  /// so streak / miss state (and the warning/relaunch overlays) follow.
  Widget _buildStreakProtection({VoidCallback? afterChange}) {
    final p = _profile;
    final uid = _uid;
    if (p == null || uid == null) return const SizedBox.shrink();
    Future<void> change(bool start, [DateTime? from, int days = 0]) async {
      await _profileService.setVacationMode(
        uid,
        start: start,
        startDate: from == null ? null : ProfileService.localDateId(from),
        days: days,
      );
      await _fetchProfile();
      afterChange?.call();
    }

    return StreakProtectionCard(
      streakSavers: p.streakSavers,
      maxStreakSavers: p.maxStreakSavers,
      streakSaverMilestone: p.streakSaverMilestone,
      vacationMaxDays: p.vacationMaxDays,
      activeVacation: p.activeVacation,
      upcomingVacation: p.upcomingVacation,
      onStartVacation: (d, n) => change(true, d, n),
      onEndVacation: () => change(false),
    );
  }

  void _openStreakSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: MM.navy,
      isScrollControlled: true,
      // The sheet is its own route, so it closes after a change rather than
      // trying to rebuild from the refetched profile.
      builder:
          (sheet) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildStreakProtection(
                afterChange: () => Navigator.of(sheet).maybePop(),
              ),
            ),
          ),
    );
  }

  Widget _buildShipWarning() =>
      ShipWarningBanner(onCheckIn: _startCheckin, onSnooze: _snoozeShipWarning);

  void _go(String key) {
    // Fuelling a locked Core from the rocket stays on the dashboard: Nova
    // hangs in and the opener is pre-drafted, instead of leaving for Phase 1.
    if (key.startsWith('fuel:') &&
        _screen == 'dashboard' &&
        _novaAllowed &&
        _phase1.stage1Completed) {
      final core = key.substring(5);
      _novaChooseCore = core;
      _openChat(
        draft:
            "I want to fuel my ${_coreMeta[core]?.$1 ?? core} Core — let's build its first habit.",
      );
      return;
    }
    // Need Help / Rebuild from the Detailed Habit View → the §4C bridge.
    if (key.startsWith('rebuild:')) {
      final parts = key.split(':');
      if (parts.length >= 3) {
        _returnToPhase1(parts[1], habitId: parts.sublist(2).join(':'));
      }
      return;
    }
    // Points earned inside Phase 1 (a returning session's checkpoints) only
    // reached the Cockpit after a reload — refresh on the way out (P1-10 #9).
    // Delayed so the last state save commits first (see _persistPhase1).
    final leavingPhase1 = _screen == 'phase1' && key != 'phase1';
    _goTo(key);
    if (leavingPhase1) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _fetchProfile();
      });
    }
  }

  void _goTo(String key) => setState(() {
    // The desktop Cockpit already IS the journey stage — no separate map.
    if (key == 'journey' &&
        MediaQuery.of(context).size.width >= kWebBreakpoint) {
      key = 'dashboard';
    }
    // Normal navigation always lands Phase 1 on its hub.
    _phase1Entry = null;
    _phase1EntryHabitId = null;
    _phase1Mode = null;
    _fuelCore = null;
    _habitsCore = null;
    _routinesFocus = null;
    _listsExpand = const {};
    _openCommand = key == 'command';
    if (key == 'command') key = 'dashboard';
    // Replay the Flight Deck tour (Sequence §Your Cockpit) from the menu.
    if (key == 'tour') {
      key = 'dashboard';
      _launch = 'tour';
    }
    if (key.startsWith('lists:')) {
      _listsExpand = {key.substring(6)};
      key = 'lists';
    } else if (key.startsWith('habit:')) {
      _habitId = key.substring(6);
      if (_screen != 'habit') _habitReturn = _screen;
      key = 'habit';
    } else if (key.startsWith('routines:')) {
      _routinesFocus = key.substring(9);
      key = 'routines';
    } else if (key.startsWith('habits:')) {
      _habitsCore = key.substring(7);
      key = 'habits';
    } else if (key.startsWith('fuel:')) {
      // A locked Core lights up with its first Golden Habit, which only
      // the HHS forges — so fuelling one re-enters Stage 1 (§4C bridge).
      _fuelCore = key.substring(5);
      _phase1Entry = 'hhs';
      key = 'phase1';
    }
    // Nova lives on the Cockpit: leaving it closes the chat.
    if (key != 'dashboard') {
      _novaOpen = false;
      _novaFull = false;
      _novaDraft = null;
      _novaChooseCore = null;
      _novaFuel = null;
    }
    _screen = key;
    BehaviorTracker.instance.screen(key);
    _menuOpen = false;
  });

  /// Queues a "CORE UNLOCKED" celebration for each Core that became active
  /// since this device last saw the rocket (#30 / P1-7). The first look only
  /// records what's active — the moment belongs to the first habit, not login.
  Future<void> _checkCoreUnlocks(List<String> active) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    final key = 'cores:seen:$uid';
    final seen = await LocalCache.getJson(key);
    final fresh = newlyUnlockedCores(
      seen is List ? seen.map((e) => '$e').toList() : null,
      active,
    );
    await LocalCache.putJson(key, active);
    if (fresh.isNotEmpty && mounted) {
      setState(
        () =>
            _coreUnlocks.addAll(fresh.where((c) => !_coreUnlocks.contains(c))),
      );
    }
  }

  static const _coreEmoji = {
    'mindset': '🧠',
    'career': '💰',
    'relationships': '👥',
    'physical': '💪',
    'emotional': '🧘',
  };

  /// Shown on the rocket, not over Phase 1's own reward screens.
  Widget? _buildCoreUnlock() {
    if (_coreUnlocks.isEmpty || _screen == 'phase1') return null;
    final core = _coreUnlocks.first;
    final meta = _coreMeta[core];
    return CoreUnlockOverlay(
      key: ValueKey(core),
      emoji: _coreEmoji[core] ?? '✨',
      name: meta?.$1 ?? core,
      color: meta?.$2 ?? MM.teal,
      onContinue: () => setState(() => _coreUnlocks.removeAt(0)),
    );
  }

  /// Loads experiments whose 3 check-ins are in (#23), minus any the player
  /// put off until later today.
  Future<void> _checkExperiments() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    try {
      final habits = await _habitsService.getGoldenHabits(uid);
      if (!habits.data.any((h) => h.experiment != null)) {
        if (mounted) setState(() => _dueExperiments = const []);
        return;
      }
      final recent = await _checkin.getRecent(uid, limit: 30);
      final today = CheckinService.dayId(DateTime.now());
      final due = <GoldenHabit>[];
      for (final h in dueExperiments(
        habits.data,
        recent,
        GoldenHabitRef.shortCore,
      )) {
        final later = await LocalCache.getJson('exp:later:${h.experiment!.id}');
        if (later != today) due.add(h);
      }
      if (mounted) {
        setState(() {
          _dueExperiments = due;
          _expCheckins = recent;
        });
      }
    } catch (_) {
      // Best-effort: the Detailed View still shows the experiment.
    }
  }

  Future<void> _resolveDueExperiment(GoldenHabit h, String outcome) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final e = h.experiment;
    if (uid == null || e == null) return;
    var learnings = '';
    if (outcome == 'retire') {
      final r = await askRetireLearnings(context);
      if (r == null || !mounted) return;
      learnings = r;
    }
    setState(() => _expBusy = true);
    try {
      await _habitsService.resolveExperiment(
        userId: uid,
        habitId: h.habitId,
        experimentId: e.id,
        outcome: outcome,
        learnings: learnings,
      );
      if (!mounted) return;
      setState(
        () =>
            _dueExperiments = [
              for (final d in _dueExperiments)
                if (d.habitId != h.habitId) d,
            ],
      );
      _snack(
        outcome == 'keep'
            ? '✅ Kept — that tweak is now part of ${h.habitName}'
            : "♻️ Retired — the old version is back, and Nova won't suggest it again",
      );
    } catch (_) {
      _snack("Couldn't update the experiment — check your connection");
    } finally {
      if (mounted) setState(() => _expBusy = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: MM.body(color: Colors.white, size: 12)),
        backgroundColor: MM.navy2,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// On the Cockpit, after any Core-unlock / launch moment.
  Widget? _buildExperimentReview() {
    if (_dueExperiments.isEmpty ||
        _screen != 'dashboard' ||
        _coreUnlocks.isNotEmpty ||
        _launch != null) {
      return null;
    }
    final h = _dueExperiments.first;
    final core = GoldenHabitRef.shortCore(h.coreId);
    return ExperimentReviewOverlay(
      key: ValueKey(h.experiment!.id),
      habitName: h.habitName,
      experiment: h.experiment!,
      progress: experimentProgress(h.experiment!, core, _expCheckins),
      coreName: _coreMeta[core]?.$1 ?? h.coreLabel,
      busy: _expBusy,
      onKeep: () => _resolveDueExperiment(h, 'keep'),
      onRetire: () => _resolveDueExperiment(h, 'retire'),
      onGoDeeper: () {
        setState(() => _dueExperiments = _dueExperiments.skip(1).toList());
        _returnToPhase1('mbs', habitId: h.habitId);
      },
      onLater: () {
        LocalCache.putJson(
          'exp:later:${h.experiment!.id}',
          CheckinService.dayId(DateTime.now()),
        );
        setState(() => _dueExperiments = _dueExperiments.skip(1).toList());
      },
    );
  }

  /// "The Mission Begins" → cockpit tour, on the Cockpit once any Core-unlock
  /// moment is done (#25 / P1-8).
  Widget? _buildLaunch() {
    if (_launch == null || _screen != 'dashboard' || _coreUnlocks.isNotEmpty) {
      return null;
    }
    if (_launch == 'mission') {
      return MissionBeginsOverlay(
        onReady: () => setState(() => _launch = 'tour'),
      );
    }
    return CockpitTourOverlay(
      steps: cockpitTourSteps(
        web: MediaQuery.of(context).size.width >= kWebBreakpoint,
        activeCores: _profile?.activeCores ?? const [],
      ),
      targets: cockpitTourTargets(
        web: MediaQuery.of(context).size.width >= kWebBreakpoint,
      ),
      onLaunch: () {
        setState(() => _launch = null);
        _startCheckin();
      },
      onClose: () => setState(() => _launch = null),
    );
  }

  /// Web Cockpit banner back into an unfinished Phase 1 (P1-10 #5).
  Widget _phase1Banner() {
    final s = _phase1;
    final label =
        s.stage1Completed
            ? 'PHASE 1 · STAGE 2 — make your Golden Habit automatic'
            : 'PHASE 1 · STAGE 1 (${s.stage1Progress}/5) — forge your first Golden Habit';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: MM.yellow.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MM.yellow.withOpacity(0.45)),
      ),
      child: Row(
        children: [
          const Text('🚀', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: MM.displayX(size: 11, color: MM.yellow)),
          ),
          IntrinsicWidth(
            child: MMPrimaryButton(
              label: s.brandNew ? 'Ready Player One? →' : 'Continue Game 🎮',
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              onPressed: () => _go('phase1'),
            ),
          ),
        ],
      ),
    );
  }

  /// First-time vs returning landing (#26 / P1-1). Until Phase 1 is finished
  /// the player opens the app inside it, not on the Cockpit: a brand-new
  /// player goes straight into Nova's HHS (Sequence: the intro ends "Ready
  /// Player One?" and the interactive part begins), anyone part-way resumes
  /// where they left off. A player who has finished Phase 1 lands on the
  /// Cockpit as before. Once per session, and never over a screen the player
  /// already navigated to.
  void _landInPhase1IfUnfinished() {
    if (_landingDone) return;
    _landingDone = true;
    if (_phase1.finished || _screen != 'dashboard') return;
    setState(() {
      _phase1Entry = _phase1.landingEntry;
      _phase1EntryHabitId = null;
      _screen = 'phase1';
    });
  }

  /// Phase 1 Re-Entry Bridge (§4C). Routes the player back into Phase 1 from the
  /// Daily Check-In — either proactively (ignite a new Core, [stage] == null) or
  /// reactively via "Go Deeper" (Path A 'hhs' rebuild / Path B 'mbs' MBMs).
  /// [habitId] pre-loads the flagged Golden Habit on re-entry (#7).
  void _returnToPhase1(String? stage, {String? habitId}) => setState(() {
    _phase1Entry = stage;
    _phase1EntryHabitId = habitId;
    _screen = 'phase1';
    _menuOpen = false;
  });

  /// Prefetches the Mission Control context (#7) for the upcoming check-in: each
  /// active Core's Golden Habit + that Core's prior daily scores (most-recent-
  /// first, excluding today). Fire-and-forget — populates state as it arrives so
  /// the auto-flag pattern is ready by the time the player reaches scoring.
  void _prefetchCheckinData() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    _onboarding
        .goldenHabits(uid)
        .then((list) {
          final map = <String, GoldenHabitRef>{};
          final all = <String, List<GoldenHabitRef>>{};
          for (final h in list) {
            map.putIfAbsent(h.shortCoreId, () => h); // newest per Core
            (all[h.shortCoreId] ??= <GoldenHabitRef>[]).add(h);
          }
          if (mounted) {
            setState(() {
              _checkinHabitByCore = map;
              _checkinHabitsByCore = all;
            });
          }
        })
        .catchError((_) {});
    _checkin
        .getRecent(uid, limit: 30)
        .then((recent) {
          final today = CheckinService.dayId(DateTime.now());
          final hist = <String, List<int>>{};
          for (final d in recent) {
            if (d.date == today) continue; // today's score is the live slider
            d.scores.forEach((core, sc) => (hist[core] ??= <int>[]).add(sc));
          }
          if (mounted) setState(() => _checkinCoreHistory = hist);
        })
        .catchError((_) {});
  }

  /// Loads the Core Balance state (#8): each Core's recent daily scores
  /// (most-recent-first, incl. today) and which Cores are out of balance
  /// (<3.0 for 5+ consecutive days). Fire-and-forget; refreshes the badges.
  void _loadCoreBalance() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    _checkin
        .getRecent(uid, limit: 30)
        .then((recent) {
          // getRecent is date-desc, so per-Core lists come out most-recent-first.
          final scores = <String, List<int>>{};
          for (final d in recent) {
            d.scores.forEach((core, sc) => (scores[core] ??= <int>[]).add(sc));
          }
          final atRisk = <String>{};
          scores.forEach((core, list) {
            if (isCoreOutOfBalance(list)) atRisk.add(core);
          });
          final avgs = rollingCoreAverages(recent);
          final pct = balancePercent(avgs);
          CoreFuel.averages.value = avgs;
          if (mounted) {
            setState(() {
              _coreScores = scores;
              _atRiskCores = atRisk;
              _balancePct = pct;
            });
          }
        })
        .catchError((_) {});
  }

  void _showCoreAlert(String coreId) => setState(() => _coreAlertCore = coreId);
  void _dismissCoreAlert() => setState(() => _coreAlertCore = null);

  /// Persists a manual Mission Control flag / experiment onto a Golden Habit.
  void _flagHabit(
    String habitId, {
    required bool flagged,
    String reason = '',
    String note = '',
  }) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty || habitId.isEmpty) return;
    _onboarding
        .flagGoldenHabit(
          userId: uid,
          habitId: habitId,
          flagged: flagged,
          reason: reason,
          note: note,
        )
        .catchError((_) => false);
  }

  /// Applies a Phase 1 state change locally and persists it to Firestore.
  /// The save is fire-and-forget: a network failure must never block the
  /// player mid-onboarding, so it's swallowed (the local state still advances
  /// and the next successful save reconciles).
  void _persistPhase1(Phase1State next) {
    final justCompletedStage1 =
        next.stage1Completed && !_phase1.stage1Completed;
    final justCompletedStage2 =
        next.stage2Completed && !_phase1.stage2Completed;
    setState(() {
      _phase1 = next;
      if (justCompletedStage2) _launch = 'mission';
    });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    final save = _profileService.savePhase1State(uid, next);
    // Forging the Golden Habit (Stage 1) activates its Core + awards MP, and
    // momentifying it (Stage 2) awards another +50 and flips phase → daily —
    // refetch so the cockpit (activeCores, score, phase) reflects either. The
    // refetch must wait for the save to COMMIT: _fetchProfile re-seeds _phase1
    // from the server, so a read that races ahead of this write would clobber
    // the just-completed stage back to its prior value (cockpit stuck showing
    // "Stage 2 in progress" until a restart).
    if (justCompletedStage1 || justCompletedStage2) {
      save.then((_) => _fetchProfile()).catchError((_) {
        // Save failed: keep the optimistic local state; the next successful
        // save (or the check-in re-sync) reconciles it.
      });
    } else {
      save.catchError((_) {});
    }
  }

  /// [draft] pre-fills Nova's input (e.g. from the iCore Alert) — the player
  /// still chooses to send it.
  void _openChat({String? draft}) {
    // Opened from another screen (top-bar star): go to the Cockpit first.
    if (_screen != 'dashboard') _goTo('dashboard');
    setState(() {
      if (draft == null) _novaChooseCore = null;
      _novaFuel = null;
      // A fresh draft needs a fresh input bar; otherwise keep what's there.
      if (!_novaOpen || draft != null) _novaKey = GlobalKey();
      _novaOpen = true;
      _novaDraft = draft;
    });
  }

  /// The mode picked on Nova's "how do you want to start?" screen → on to the
  /// Habits Hierarchy conversation for the Core being fuelled.
  void _startFuel(String core, String mode) => setState(() {
    // The Habits Hierarchy conversation runs inside Nova's panel — the
    // dashboard (menu, stats) stays put underneath.
    _novaChooseCore = null;
    _novaFuel = (core: core, mode: mode);
    _novaKey = GlobalKey();
  });

  /// The Habits Hierarchy conversation drawn on Nova's monitor while a Core is
  /// being fuelled: the Phase 1 flow (pyramid, reward cards, forge) in place of
  /// the transcript.
  Widget _fuelScreen() {
    final fuel = _novaFuel!;
    final name = _coreMeta[fuel.core]?.$1 ?? fuel.core;
    return Phase1Flow(
      state: _phase1,
      entryStage: 'hhs',
      entryMode: fuel.mode,
      embedded: true,
      entryDraft: "I want to fuel my $name Core — let's build its first habit.",
      onStateChange: _persistPhase1,
      onBack: () => setState(() {
        _novaFuel = null;
        _novaKey = GlobalKey();
      }),
      onExitToCockpit: () {
        _closeNova();
        _fetchProfile();
      },
      onStartCheckin: () {
        _closeNova();
        _startCheckin();
      },
    );
  }

  void _closeNova() => setState(() {
    _novaOpen = false;
    _novaFull = false;
    _novaDraft = null;
  });

  /// Screens that are immersive flows of their own — Nova steps aside there.
  bool get _novaAllowed => const {
    'phase1',
    'checkin',
    'checkin_quick',
    'ritual0',
    'summary',
    'admin',
  }.contains(_screen) == false;

  Widget _novaPage() {
    // Phone / tablet: a narrower monitor, with its buttons tucked under the
    // stats card, so the header beside it stays visible.
    final w = MediaQuery.of(context).size.width;
    final small = w < kWebBreakpoint;
    return CopilotConsolePage(
      key: _novaKey,
      draft: _novaDraft,
      layout: _novaFull ? CopilotLayout.full : CopilotLayout.docked,
      onClose: _closeNova,
      onExpand: () => setState(() => _novaFull = true),
      onCollapse: () => setState(() => _novaFull = false),
      podMaxWidth: small ? (w * 0.64 > 460 ? 460 : w * 0.64) : null,
      controlsTop: small ? 56 : 4,
      screenChild: _novaFuel == null ? null : _fuelScreen(),
      // Back: out of the Habits Hierarchy / start options to Nova's chat; from
      // the chat itself it closes Nova.
      onBack:
          (_novaFuel != null || _novaChooseCore != null)
              ? () => setState(() {
                _novaFuel = null;
                _novaChooseCore = null;
                _novaKey = GlobalKey();
              })
              : _closeNova,
      onStartPick:
          _novaChooseCore == null
              ? null
              : (mode) => _startFuel(_novaChooseCore!, mode),
    );
  }

  /// The Co-Pilot overlay for the current layout; null when closed.
  /// [desktop] docks it in the content column beside the sidebar; on a phone
  /// it sits below the top stats and the shortcut row.
  Widget? _buildNova({required bool desktop}) {
    // Desktop Cockpit: Nova hangs from the top of the window over the (flipped,
    // emptied) centre square. The widget animates its own exit, so it stays in
    // the tree while closed.
    if (desktop && _screen == 'dashboard' && !_novaFull) {
      return Positioned.fill(
        child: _HangingNova(
          open: _novaOpen && _novaAllowed,
          snap: false,
          build: _novaPage,
        ),
      );
    }
    // Phone / tablet: Nova drops from under the top stats bar and covers the
    // rest of the screen (the rocket is hidden), so the menu button and stats
    // stay on screen. Animates its own exit like the desktop one.
    if (!desktop && !_novaFull) {
      return Positioned.fill(
        child: _HangingNova(
          open: _novaOpen && _novaAllowed,
          snap: false,
          mobile: true,
          cover: _screen != 'dashboard',
          build: _novaPage,
        ),
      );
    }
    if (!_novaOpen || !_novaAllowed) return null;
    // Desktop Cockpit is handled above; other desktop screens float it.
    if (desktop && _screen == 'dashboard' && !_novaFull) return null;
    final nova = _novaPage();
    if (_novaFull) return Positioned.fill(child: nova);
    return Positioned(
      top: 96,
      bottom: 8,
      left: 264,
      right: 0,
      child: Center(child: SizedBox(width: 360, child: nova)),
    );
  }

  // ── Daily Ritual Step 0 (Mantra & Grateful List) ────────────────────────
  // Per-day completion is remembered in LocalCache keyed by uid; the value is
  // the local calendar date (yyyy-mm-dd) the player last completed Step 0. The
  // pre-scoring screen appears at most once a day — and only until completed.
  static String _todayKey() {
    final n = DateTime.now();
    final m = n.month.toString().padLeft(2, '0');
    final d = n.day.toString().padLeft(2, '0');
    return '${n.year}-$m-$d';
  }

  String? get _step0CacheKey {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return (uid == null || uid.isEmpty) ? null : 'ritual:step0:$uid';
  }

  /// Daily Check-In entry point: show the optional Mantra & Grateful Step 0
  /// first, unless the player already completed it today (then go straight to
  /// scoring). Insert ahead of CheckInPage per PHASE 1 & 2 DETAILS §"STEP 0".
  Future<void> _startCheckin() async {
    _prefetchCheckinData(); // ready the Mission Control context (#7)
    final key = _step0CacheKey;
    if (key != null) {
      final done = await LocalCache.getJson(key);
      if (done == _todayKey()) {
        if (mounted) _go('checkin');
        return;
      }
    }
    if (mounted) _go('ritual0');
  }

  /// "Continue to Scoring →" — mark Step 0 done for today, then start scoring.
  void _completeStep0() {
    final key = _step0CacheKey;
    if (key != null) LocalCache.putJson(key, _todayKey());
    _go('checkin');
  }

  /// Persists the day's per-Core scores (the real source habit lifecycle stage
  /// is derived from), then advances to the summary. Save failures don't block
  /// the player from finishing their check-in.
  Future<void> _saveCheckin(
    Map<String, int> scores,
    Map<String, CaptainsLogEntry> captainsLog,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      try {
        await _checkin.saveCheckin(
          uid: uid,
          scores: scores,
          captainsLog: captainsLog,
        );
      } catch (_) {
        // Non-fatal: the check-in still completes locally.
      }
      // Re-sync Phase 1 state on the daily ritual so any drift (e.g. a save
      // that failed mid-onboarding) is reconciled. Fire-and-forget.
      _profileService.savePhase1State(uid, _phase1).catchError((_) {});
      // AI auto-flag (#7): a Core ≤3.0 for 3+ consecutive check-ins flags its
      // Golden Habit for refinement. Only flag Cores not already flagged, so a
      // sustained dip doesn't append a new flag every single day.
      _autoFlagStrugglingCores(uid, scores);
      // Momentum Points engine (#9): award the +10 weekday check-in points
      // (idempotent per day, server-side). Capture the day's points for the
      // Summary's "Earned Today" + optimistically bump the running total.
      final award = await _points.awardCheckin(
        userId: uid,
        dateId: CheckinService.dayId(DateTime.now()),
        scores: scores,
      );
      _earnedToday = award.dayPoints;
      if (award.totalPoints != null) _momentumOverride = award.totalPoints;
      // Streak (#10): reflect the new streak immediately + surface any milestone.
      if (award.streak != null) _streakOverride = award.streak;
      _streakMilestone = award.milestone;
      // Space Credits (#13): reflect the new balance immediately on the
      // dashboard + summary (base + high-score earned this check-in).
      if (award.spaceCredits != null) _creditsOverride = award.spaceCredits;
    }
    // A completed check-in ends any missed-check-in warning (#16).
    _checkedInThisSession = true;
    _relaunchOpen = false;
    // Stash for the summary's Balance Meter so today's scores fold into the
    // rolling 7-day average immediately, without waiting on the read.
    _lastCheckinScores = scores;
    // Today's scores may newly tip a Core in/out of balance — refresh badges.
    _loadCoreBalance();
    if (mounted) _go('summary');
    // Today's check-in may complete an experiment's 3-day window.
    _checkExperiments();
  }

  /// Flags each active Core's Golden Habit whose real pattern is 3+ consecutive
  /// check-ins (incl. today) at or below 3.0. Best-effort + idempotent-ish (skips
  /// Cores already flagged at prefetch time).
  void _autoFlagStrugglingCores(String uid, Map<String, int> todayScores) {
    _checkinHabitByCore.forEach((core, ref) {
      if (ref.flagged) return; // already flagged — don't re-flag every day
      final today = todayScores[core];
      if (today == null) return; // Core not scored today
      var streak = 0;
      for (final s in <int>[today, ...?_checkinCoreHistory[core]]) {
        if (s <= 3) {
          streak++;
        } else {
          break;
        }
      }
      if (streak >= 3) {
        _onboarding
            .flagGoldenHabit(
              userId: uid,
              habitId: ref.habitId,
              flagged: true,
              reason: 'Auto: $streak check-ins at or below 3.0',
            )
            .catchError((_) => false);
      }
    });
  }

  Widget _buildBody() {
    final p = _profile;
    // Real cockpit values in every phase. `activeCores` is server-derived from
    // the user's Golden Habits (cores stay grayed until their first habit), and
    // the phase (build vs daily) is reflected by the dashboard's phase pill,
    // gated off the persisted Phase 1 state.
    final activeCores = p?.activeCores ?? const <String>[];
    if (_screen == 'dashboard') {
      return DashboardPage(
        streak: _streakOverride ?? (p?.streak ?? 0),
        streakState: p?.streakState ?? 'ok',
        streakSavers: p?.streakSavers ?? 0,
        onStreakTap: _openStreakSheet,
        planet: p?.planet ?? 'earth',
        activeCores: activeCores,
        atRiskCores: _atRiskCores,
        level: p?.level ?? 'cadet',
        momentumScore: _momentumOverride ?? (p?.momentumScore ?? 0),
        spaceCredits: _creditsOverride ?? (p?.spaceCredits ?? 0),
        balance: _balancePct,
        phase1State: _phase1,
        onCheckIn: _startCheckin,
        onMenu: () => setState(() => _menuOpen = true),
        novaOpen: _novaOpen && _novaAllowed && !_novaFull,
        onChat: _openChat,
        onNav: _go,
        onCoreAlert: _showCoreAlert,
        offline: _offline,
        onRefreshOffline: _fetchProfile,
      );
    }
    if (_screen == 'journey') {
      // Planet states on a phone: the whole route, the rail and the arrival
      // cinematic — what the desktop Cockpit's centre stage gives for free.
      return JourneyPage(
        planet: p?.planet ?? 'earth',
        activeCores: activeCores,
        atRiskCores: _atRiskCores,
        streak: _streakOverride ?? (p?.streak ?? 0),
        momentumScore: _momentumOverride ?? (p?.momentumScore ?? 0),
        onBack: () => _go('dashboard'),
        onNav: _go,
        onCoreAlert: _showCoreAlert,
      );
    }
    if (_screen == 'phase1') {
      return Phase1Flow(
        state: _phase1,
        entryStage: _phase1Entry,
        entryHabitId: _phase1EntryHabitId,
        entryMode: _phase1Mode,
        entryDraft:
            _fuelCore == null
                ? null
                : "I want to fuel my ${_coreMeta[_fuelCore]?.$1 ?? _fuelCore} Core — let's build its first habit.",
        onStateChange: _persistPhase1,
        onBack: () => _go('dashboard'),
        onExitToCockpit: () => _go('dashboard'),
        onStartCheckin: _startCheckin,
      );
    }
    if (_screen == 'ritual0') {
      return DailyRitualStep0(
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        onContinue: _completeStep0,
        onSkip: () {
          BehaviorTracker.instance.skip('ritual_step0', screen: 'ritual0');
          _go('checkin');
        },
        onClose: () => _go('dashboard'),
      );
    }
    if (_screen == 'checkin' || _screen == 'checkin_quick') {
      return CheckInPage(
        singleCore: _screen == 'checkin_quick',
        activeCores: activeCores,
        atRiskCores: _atRiskCores,
        coreHistory: _checkinCoreHistory,
        habitByCore: _checkinHabitByCore,
        habitsByCore: _checkinHabitsByCore,
        onClose: () => _go('dashboard'),
        onComplete: _saveCheckin,
        onFlagHabit: _flagHabit,
        onReturnToPhase1: _returnToPhase1,
        onCoreAlert: _showCoreAlert,
      );
    }
    if (_screen == 'summary') {
      return SummaryPage(
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        streak: _streakOverride ?? (p?.streak ?? 0),
        streakMilestone: _streakMilestone,
        activeCores: activeCores,
        momentumScore: _momentumOverride ?? (p?.momentumScore ?? 0),
        spaceCredits: _creditsOverride ?? (p?.spaceCredits ?? 0),
        earnedToday: _earnedToday,
        todayScores: _lastCheckinScores,
        onClose: () => _go('dashboard'),
      );
    }
    if (_screen == 'lists') {
      return ListsScreen(
        key: ValueKey(_listsExpand.join()),
        expand: _listsExpand,
        onBack: () => _go('dashboard'),
        onChat: _openChat,
        onNav: _go,
      );
    }
    if (_screen == 'routines') {
      return RoutinesScreen(
        key: ValueKey(_routinesFocus),
        focusHabitId: _routinesFocus,
        onBack: () => _go('dashboard'),
        onChat: _openChat,
        onNav: _go,
      );
    }
    if (_screen == 'habits') {
      return HabitsScreen(
        key: ValueKey(_habitsCore),
        coreFilter: _habitsCore,
        onBack: () => _go('dashboard'),
        onChat: _openChat,
        onNav: _go,
      );
    }
    if (_screen == 'habit' && _habitId != null) {
      // Detailed Golden Habit View (#22).
      return ScreenShell(
        title: 'Golden Habit',
        subtitle: 'DETAILED VIEW',
        accent: MM.magenta,
        onBack: () => _go(_habitReturn),
        onChat: _openChat,
        onNav: _go,
        child: HabitDetailView(
          key: ValueKey(_habitId),
          habitId: _habitId!,
          onNav: _go,
        ),
      );
    }
    if (_screen == 'nonroutines') {
      // Non-Routines List (Phase 1&2 Details §4C, #21) — the rocket's right icon.
      return ScreenShell(
        title: 'Non-Routines',
        subtitle: 'BY CORE · PRIORITY',
        accent: MM.yellow,
        onBack: () => _go('dashboard'),
        onChat: _openChat,
        onNav: _go,
        child: NonRoutinesView(onNav: _go),
      );
    }
    if (_screen == 'allhabits') {
      // ∞ ALL HABITS Quick View (Phase 1&2 Details §4C, #21).
      return ScreenShell(
        title: 'All Habits',
        subtitle: 'QUICK VIEW',
        accent: MM.magenta,
        onBack: () => _go('dashboard'),
        onChat: _openChat,
        onNav: _go,
        child: AllHabitsView(onNav: _go),
      );
    }
    if (_screen == 'tasks') {
      return TasksScreen(
        onBack: () => _go('dashboard'),
        onChat: _openChat,
        onNav: _go,
      );
    }
    if (_screen == 'cantina') {
      // Cantina unlocks only after Phase 1 Stage 2 is complete (the habit is
      // momentified). Gate off persisted state so it survives a restart.
      if (!_phase1.stage2Completed) {
        return _CantinaLockedView(
          onBack: () => _go('dashboard'),
          onUnlock: () => _returnToPhase1('mbs'),
        );
      }
      return CantinaScreen(
        onBack: () => _go('dashboard'),
        onChat: _openChat,
        onNav: _go,
      );
    }
    if (_screen == 'trophy') {
      return TrophyScreen(
        onBack: () => _go('dashboard'),
        onChat: _openChat,
        onNav: _go,
      );
    }
    if (_screen == 'profile') {
      return ProfileScreen(
        onBack: () => _go('dashboard'),
        onChat: _openChat,
        onNav: _go,
        onSignOut: () => _auth.signOut(),
      );
    }
    if (_screen.startsWith('crew:')) {
      return CrewProfileScreen(
        crewId: _screen.substring(5),
        onBack: () => _go('cantina'),
        onChat: _openChat,
        onNav: _go,
      );
    }
    if (_screen.startsWith('thread:')) {
      return ThreadScreen(
        threadId: _screen.substring(7),
        onBack: () => _go('cantina'),
      );
    }
    return DashboardPage(
      onCheckIn: () => _go('checkin'),
      onMenu: () => setState(() => _menuOpen = true),
      onChat: _openChat,
      onNav: _go,
      offline: _offline,
      onRefreshOffline: _fetchProfile,
    );
  }

  void _onRouteChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Admin is a full-screen takeover, not another screen inside the app's
    // WebShell/mobile chrome — a different persona (admin vs player), same
    // way the signed-out AuthFlow replaces the whole app instead of nesting.
    // Bypasses loading/error/CelebrationHost/WebShell entirely; matches
    // design/ref/admin-panel-export/Admin Panel.dc.html's own single-sidebar
    // layout exactly, full window, no extra app chrome around it.
    if (_screen == 'admin') {
      return AdminGate(child: AdminShell(onExitAdmin: () => _go('dashboard')));
    }
    if (_loading) {
      return const Scaffold(
        backgroundColor: MM.pageBg,
        body: Center(child: CircularProgressIndicator(color: MM.blue)),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: MM.pageBg,
        body: SafeArea(
          child:
              _errorOffline
                  ? OfflineErrorView(
                    onRetry: _fetchProfile,
                    what: 'your profile',
                  )
                  : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Could not load profile',
                            style: MM.display(size: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Something went wrong. Please try again.',
                            textAlign: TextAlign.center,
                            style: MM.body(
                              color: Colors.white.withOpacity(0.6),
                              size: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _fetchProfile,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
        ),
      );
    }
    // At desktop widths render the web shell (sidebar + topbar + Cockpit);
    // below the breakpoint the existing full-bleed mobile screens are kept.
    // Either way the whole shell sits under the celebration host, so a points
    // award raised by the Claude agent bursts confetti on any screen.
    return CelebrationHost(
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      child:
          MediaQuery.of(context).size.width >= kWebBreakpoint
              ? _buildDesktop()
              : _buildMobile(),
    );
  }

  Widget _buildMobile() {
    return Stack(
      children: [
        // The reminder bar sits above the screen (not over its title); while it
        // shows, the screen below drops its own top inset.
        Positioned.fill(
          child: ListenableBuilder(
            listenable: RoutineReminders.instance,
            builder: (context, _) {
              final show = RoutineReminders.instance.count > 0;
              return Column(
                children: [
                  if (show)
                    SafeArea(
                      bottom: false,
                      child: RoutineReminderBar(
                          onOpenRoutines: () => _go('routines')),
                    ),
                  Expanded(
                    // Same widget either way, so the screen keeps its state
                    // when the bar appears or goes.
                    child: MediaQuery.removePadding(
                        context: context,
                        removeTop: show,
                        child: _buildBody()),
                  ),
                ],
              );
            },
          ),
        ),
        if (_buildNova(desktop: false) case final nova?) nova,
        RoutineDuePopup(
            onOpenRoutines: () => _go('routines'),
            alignment: Alignment.topCenter),
        if (_menuOpen)
          Positioned.fill(
            child: MenuDrawer(
              user: FirebaseAuth.instance.currentUser,
              onClose: () => setState(() => _menuOpen = false),
              onNav: _go,
              onChat: _openChat,
              onSignOut: () => _auth.signOut(),
              isAdmin: _isAdmin,
            ),
          ),
        if (_showShipWarning)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: _buildShipWarning()),
          ),
        // iCore Alert (#8) — opened by tapping a Core's red ⚠️ badge.
        if (_coreAlertCore != null) Positioned.fill(child: _buildCoreAlert()),
        if (_relaunchOpen && _profile != null)
          Positioned.fill(child: _buildRelaunch()),
        if (_buildCoreUnlock() case final unlock?)
          Positioned.fill(child: unlock),
        if (_buildLaunch() case final launch?) Positioned.fill(child: launch),
        if (_buildExperimentReview() case final review?)
          Positioned.fill(child: review),
      ],
    );
  }

  /// Nav destinations that live inside the desktop shell's content column.
  /// The immersive full-flow screens (check-in, summary, phase1, ritual0) fall
  /// outside it and render centered instead.
  static const _shellScreens = <String>{
    'dashboard',
    'routines',
    'habits',
    'allhabits',
    'habit',
    'nonroutines',
    'tasks',
    'lists',
    'cantina',
    'trophy',
    'profile',
  };

  /// Desktop (>= [kWebBreakpoint]) presentation. Wraps shell destinations in
  /// [WebShell] with the flagship [WebCockpit] for the dashboard; centers the
  /// immersive flows to a phone-width column so nothing stretches.
  Widget _buildDesktop() {
    final isShell =
        _shellScreens.contains(_screen) ||
        _screen.startsWith('crew:') ||
        _screen.startsWith('thread:');

    if (!isShell) {
      return Stack(
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: _buildBody(),
            ),
          ),
          if (_coreAlertCore != null) Positioned.fill(child: _buildCoreAlert()),
        ],
      );
    }

    final p = _profile;
    final idx = MM.planets.indexWhere((e) => e['id'] == (p?.planet ?? 'earth'));
    final planetName = MM.planets[idx < 0 ? 0 : idx]['name'] as String;
    final activeCores = p?.activeCores ?? const <String>[];
    final name =
        (p?.displayName.isNotEmpty ?? false)
            ? p!.displayName
            : (FirebaseAuth.instance.currentUser?.displayName ?? 'Commander');
    final streak = _streakOverride ?? (p?.streak ?? 0);
    final level = p?.level ?? 'cadet';

    Widget content;
    // The Cockpit draws its own title so its right column can start at the top.
    var showTopbar = _screen != 'dashboard';
    var title = 'Cockpit';
    var subtitle = 'Mission Control';
    var accent = MM.blue;
    switch (_screen) {
      case 'dashboard':
        content = WebCockpit(
          name: name,
          streak: streak,
          streakState: p?.streakState ?? 'ok',
          streakProtection: _buildStreakProtection(),
          streakSavers: p?.streakSavers ?? 0,
          onStreakTap: _openStreakSheet,
          planet: p?.planet ?? 'earth',
          activeCores: activeCores,
          atRiskCores: _atRiskCores,
          level: level,
          momentumScore: _momentumOverride ?? (p?.momentumScore ?? 0),
          spaceCredits: _creditsOverride ?? (p?.spaceCredits ?? 0),
          balance: _balancePct,
          onNav: _go,
          onCheckIn: _startCheckin,
          onCoreAlert: _showCoreAlert,
          phase1Banner: _phase1.finished ? null : _phase1Banner(),
          openCommand: _openCommand,
          onChat: _openChat,
          novaOpen: _novaOpen && !_novaFull && _novaAllowed,
          novaSnap: _novaFull,
        );
        break;
      case 'routines':
        title = 'Routines';
        subtitle = 'Daily Orbit';
        accent = MM.teal;
        content = WebRoutines(
          key: ValueKey(_routinesFocus),
          focusHabitId: _routinesFocus,
          onOpen: (id) => _go('habit:$id'),
        );
        break;
      case 'habits':
        title = 'All Habits';
        subtitle = 'Golden Habits';
        accent = MM.magenta;
        content = WebHabits(
          key: ValueKey(_habitsCore),
          coreFilter: _habitsCore,
          onOpen: (id) => _go('habit:$id'),
          onShowInRoutine: (id) => _go('routines:$id'),
        );
        break;
      case 'habit':
        title = 'Golden Habit';
        subtitle = 'Detailed View';
        accent = MM.magenta;
        content = SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 4, 40, 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntrinsicWidth(
                child: MMGhostButton(
                  label: '← Back',
                  onPressed: () => _go(_habitReturn),
                ),
              ),
              const SizedBox(height: 14),
              HabitDetailView(
                key: ValueKey(_habitId),
                habitId: _habitId ?? '',
                onNav: _go,
                wide: true,
              ),
            ],
          ),
        );
        break;
      case 'nonroutines':
        title = 'Non-Routines';
        subtitle = 'By Core · Priority';
        accent = MM.yellow;
        content = SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 4, 40, 56),
          child: NonRoutinesView(onNav: _go, wide: true),
        );
        break;
      case 'allhabits':
        title = 'All Habits';
        subtitle = 'Quick View';
        accent = MM.magenta;
        content = SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 4, 40, 56),
          child: AllHabitsView(onNav: _go, wide: true),
        );
        break;
      case 'tasks':
        title = 'Tasks';
        subtitle = 'Missions · Today';
        accent = MM.yellow;
        content = const WebTasks();
        break;
      case 'lists':
        title = 'Momentum Lists';
        subtitle = 'Manifest';
        accent = MM.blue;
        content = WebLists(
            key: ValueKey(_listsExpand.join()), expand: _listsExpand);
        break;
      case 'trophy':
        title = 'Trophy Room';
        subtitle = 'Identity';
        accent = MM.yellow;
        content = const WebTrophy();
        break;
      case 'profile':
        title = 'Profile';
        subtitle = 'Commander';
        accent = MM.violet;
        content = WebProfile(onSignOut: () => _auth.signOut());
        break;
      case 'cantina':
        if (!_phase1.stage2Completed) {
          // Locked until Stage 2 — reuse the mobile locked view, centered.
          showTopbar = false;
          content = Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: _buildBody(),
            ),
          );
        } else {
          title = 'Cantina';
          subtitle = 'Cosmic Social Hub';
          accent = MM.teal;
          content = WebCantina(onNav: _go);
        }
        break;
      default:
        // crew: DM/profile and thread: messaging keep their full-interaction
        // mobile screen, centered so it doesn't stretch.
        showTopbar = false;
        content = Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: _buildBody(),
          ),
        );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: WebShell(
            current: _screen,
            onNav: _go,
            name: name,
            streak: streak,
            planetName: planetName,
            level: level,
            onCheckIn: _startCheckin,
            onChat: _openChat,
            onSignOut: () => _auth.signOut(),
            isAdmin: _isAdmin,
            content: content,
            showTopbar: showTopbar,
            showTopbarActions: _screen != 'dashboard',
            title: title,
            subtitle: subtitle,
            accent: accent,
          ),
        ),
        if (_buildNova(desktop: true) case final nova?) nova,
        RoutineDuePopup(onOpenRoutines: () => _go('routines')),
        if (_menuOpen)
          Positioned.fill(
            child: MenuDrawer(
              user: FirebaseAuth.instance.currentUser,
              onClose: () => setState(() => _menuOpen = false),
              onNav: _go,
              onChat: _openChat,
              onSignOut: () => _auth.signOut(),
              isAdmin: _isAdmin,
            ),
          ),
        if (_showShipWarning)
          Positioned(top: 76, left: 232, right: 16, child: _buildShipWarning()),
        if (_coreAlertCore != null) Positioned.fill(child: _buildCoreAlert()),
        if (_relaunchOpen && _profile != null)
          Positioned.fill(child: _buildRelaunch()),
        if (_buildCoreUnlock() case final unlock?)
          Positioned.fill(child: unlock),
        if (_buildLaunch() case final launch?) Positioned.fill(child: launch),
        if (_buildExperimentReview() case final review?)
          Positioned.fill(child: review),
      ],
    );
  }

  Widget _buildCoreAlert() {
    final coreId = _coreAlertCore!;
    final meta = _coreMeta[coreId] ?? ('This Core', MM.red);
    final info = coreAlertInfo(_coreScores[coreId] ?? const <int>[]);
    final others = _atRiskCores.where((c) => c != coreId).toList();
    void chat(String draft) {
      _dismissCoreAlert();
      _openChat(draft: draft);
    }

    return CoreAlertSheet(
      coreName: meta.$1,
      coreColor: meta.$2,
      lowScores: info.lowRunScores,
      streakDays: info.lowRunDays,
      recoveryDays: info.recoveryDays,
      otherStrugglingCores: [
        for (final c in others) (_coreMeta[c] ?? (c, MM.red)).$1,
      ],
      onReviewHabits: () {
        _dismissCoreAlert();
        _go('habits');
      },
      onReturnToPhase1: () {
        _dismissCoreAlert();
        _returnToPhase1(null);
      },
      onGetAiHelp:
          () => chat(
            'My ${meta.$1} Core has been below 3.0 for ${info.lowRunDays} days in a row. '
            "Can you help me figure out which habits aren't landing and what to change?",
          ),
      onSimplify:
          others.isEmpty
              ? null
              : () => chat(
                "Multiple Cores are struggling (${[
                  meta.$1,
                  ...[for (final c in others) (_coreMeta[c] ?? (c, MM.red)).$1],
                ].join(', ')}). "
                "Let's simplify to keep my momentum alive — which habits should I keep active and which can I pause for now?",
              ),
      onDone: _dismissCoreAlert,
    );
  }
}

/// Shown when the player taps the Cantina tab before completing Phase 1
/// Stage 2. The Space Cantina unlocks only once the Golden Habit is
/// momentified (anti-shame: framed as "next step," not "denied").
class _CantinaLockedView extends StatelessWidget {
  const _CantinaLockedView({required this.onBack, required this.onUnlock});
  final VoidCallback onBack;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MM.pageBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: onBack,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: MM.navy.withOpacity(0.55),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text('🔒', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 14),
                  Text(
                    'SPACE CANTINA LOCKED',
                    style: MM.displayX(size: 11, color: MM.yellow),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Momentify your habit first',
                    textAlign: TextAlign.center,
                    style: MM.display(size: 20, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'The Cantina — Ideas Well, Tribes, Leaderboards — opens once '
                    'you finish Phase 1 Stage 2 and engineer your Golden Habit '
                    'for friction-free execution.',
                    textAlign: TextAlign.center,
                    style: MM.body(
                      color: Colors.white.withOpacity(0.7),
                      size: 12,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  MMPrimaryButton(
                    label: 'Go to Stage 2 →',
                    pulse: true,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    onPressed: onUnlock,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Desktop Cockpit's Nova: lowers from the very top of the window (bounce) over
/// the centre column, full height, and swings back up on close. No container.
/// [build] is called while visible or still animating out; the page keeps one
/// GlobalKey so the conversation survives.
class _HangingNova extends StatefulWidget {
  const _HangingNova({
    required this.open,
    required this.snap,
    required this.build,
    this.mobile = false,
    this.cover = false,
  });
  final bool open;
  final bool snap;

  /// Phone / tablet on screens other than the dashboard: cover the page below
  /// the header with the starfield (the dashboard hides its own content).
  final bool cover;

  /// Phone / tablet: hang below the top stats bar over an opaque backdrop,
  /// instead of over the desktop's centre column.
  final bool mobile;
  final Widget Function() build;

  @override
  State<_HangingNova> createState() => _HangingNovaState();
}

class _HangingNovaState extends State<_HangingNova>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    reverseDuration: const Duration(milliseconds: 500),
    value: widget.open ? 1 : 0,
  );
  late bool _mounted = widget.open;

  @override
  void didUpdateWidget(covariant _HangingNova old) {
    super.didUpdateWidget(old);
    if (widget.open && !old.open) {
      _mounted = true;
      _ctl.forward();
    } else if (!widget.open && old.open) {
      _ctl.reverse().whenComplete(() {
        if (mounted && !widget.open) setState(() => _mounted = false);
      });
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_mounted) return const SizedBox.shrink();
    if (widget.mobile) {
      // Header stays (menu, trophy, streak, phase tag, stats). The monitor
      // hangs from just below the top of the screen; an opaque backdrop starts
      // under the phase tag and hides the shortcut row and the rocket.
      final pad = MediaQuery.of(context).padding.top;
      final slide = CurvedAnimation(
        parent: _ctl,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return Stack(
        children: [
          if (widget.cover)
            Positioned(
              left: 0,
              right: 0,
              top: pad + 134,
              bottom: 0,
              child: FadeTransition(
                opacity: _ctl,
                child: const StarfieldBackground(),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            top: pad + 40,
            bottom: 0,
            child: ClipRect(
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(slide),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: widget.build(),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        // Centre column of WebCockpit's 20/30/20 row (40px side padding, 24px
        // gaps), inside the content column beside the 264px sidebar.
        final avail = c.maxWidth - 264;
        final w = avail > kWebContentMaxWidth ? kWebContentMaxWidth : avail;
        final off = 264 + (avail - w) / 2;
        double left;
        double width;
        // Three-column Cockpit: hang from the very top of the window. Narrower
        // (tablet): phone logic — the page title stays, the monitor emerges
        // from the bottom of the title bar and the cockpit shows only icons
        // (left) and stats (right) beside it.
        final narrow = w < 1080;
        if (!narrow) {
          final unit = (w - 80 - 48) / 70;
          left = off + 40 + 20 * unit + 24;
          width = 30 * unit;
        } else {
          width = 420;
          left = off + (w - width) / 2;
        }
        final hang = SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _ctl,
              curve: const Interval(0.25, 1, curve: Curves.easeOutBack),
              reverseCurve: Curves.easeInCubic,
            ),
          ),
          child: widget.build(),
        );
        return Stack(
          children: [
            Positioned(
              left: left,
              width: width,
              top: narrow ? 96 : 0,
              bottom: 0,
              child: narrow ? ClipRect(child: hang) : hang,
            ),
          ],
        );
      },
    );
  }
}
