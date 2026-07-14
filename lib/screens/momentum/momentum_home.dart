import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/phase1_state.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/checkin_service.dart';
import '../../services/notification_service.dart';
import '../../services/offline.dart';
import '../../services/onboarding_service.dart';
import '../../services/points_service.dart';
import '../../services/profile_service.dart';
import '../../theme/momentum_tokens.dart';
import '../../widgets/momentum/core_alert_sheet.dart';
import '../../widgets/momentum/menu_drawer.dart';
import '../../widgets/momentum/mm_buttons.dart';
import '../../widgets/momentum/offline_banner.dart';
import '../../widgets/momentum/starfield.dart';
import '../../widgets/momentum/web_shell.dart';
import '../ai_chat_page.dart';
import 'checkin_page.dart';
import 'daily_ritual_step0.dart';
import 'dashboard_page.dart';
import 'phase1_flow.dart';
import 'sub_screens.dart';
import 'summary_page.dart';
import 'web_cockpit.dart';
import 'web_screens.dart';

/// Post-auth shell. Owns the active screen, menu drawer, and routing
/// between Dashboard / Check-in / Summary / sub-screens / chat.
class MomentumHome extends StatefulWidget {
  const MomentumHome({super.key});

  @override
  State<MomentumHome> createState() => _MomentumHomeState();
}

class _MomentumHomeState extends State<MomentumHome> {
  String _screen = 'dashboard';
  bool _menuOpen = false;
  final _auth = AuthService();
  final _profileService = ProfileService();
  final _checkin = CheckinService();
  final _onboarding = OnboardingService();
  final _points = PointsService();

  UserProfile? _profile;
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

  // Core Balance 5-day alert (#8): each Core's recent daily scores (most-recent-
  // first, incl. today's saved score) and the set out of balance (<3.0 for 5+
  // consecutive days). Feeds the red ⚠️ badge + iCore Alert on dashboard +
  // check-in. `_coreAlertCore` is the Core whose iCore Alert overlay is open.
  Map<String, List<int>> _coreScores = const {};
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
    _fetchProfile();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      NotificationService.instance.saveTokenForUser(uid);
    }
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
    _profileService.dispose();
    _onboarding.dispose();
    _points.dispose();
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
      // Compute the Core Balance 5-day alert badges (#8) from real check-ins.
      _loadCoreBalance();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _errorOffline = isNetworkError(e);
        _loading = false;
      });
    }
  }

  void _go(String key) => setState(() {
        _screen = key;
        _menuOpen = false;
        // Normal navigation always lands Phase 1 on its hub.
        _phase1Entry = null;
        _phase1EntryHabitId = null;
      });

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
    _onboarding.goldenHabits(uid).then((list) {
      final map = <String, GoldenHabitRef>{};
      for (final h in list) {
        map.putIfAbsent(h.shortCoreId, () => h); // newest per Core
      }
      if (mounted) setState(() => _checkinHabitByCore = map);
    }).catchError((_) {});
    _checkin.getRecent(uid, limit: 30).then((recent) {
      final today = CheckinService.dayId(DateTime.now());
      final hist = <String, List<int>>{};
      for (final d in recent) {
        if (d.date == today) continue; // today's score is the live slider
        d.scores.forEach((core, sc) => (hist[core] ??= <int>[]).add(sc));
      }
      if (mounted) setState(() => _checkinCoreHistory = hist);
    }).catchError((_) {});
  }

  /// Loads the Core Balance state (#8): each Core's recent daily scores
  /// (most-recent-first, incl. today) and which Cores are out of balance
  /// (<3.0 for 5+ consecutive days). Fire-and-forget; refreshes the badges.
  void _loadCoreBalance() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    _checkin.getRecent(uid, limit: 30).then((recent) {
      // getRecent is date-desc, so per-Core lists come out most-recent-first.
      final scores = <String, List<int>>{};
      for (final d in recent) {
        d.scores.forEach((core, sc) => (scores[core] ??= <int>[]).add(sc));
      }
      final atRisk = <String>{};
      scores.forEach((core, list) {
        if (isCoreOutOfBalance(list)) atRisk.add(core);
      });
      if (mounted) {
        setState(() {
          _coreScores = scores;
          _atRiskCores = atRisk;
        });
      }
    }).catchError((_) {});
  }

  void _showCoreAlert(String coreId) =>
      setState(() => _coreAlertCore = coreId);
  void _dismissCoreAlert() => setState(() => _coreAlertCore = null);

  /// Persists a manual Mission Control flag / experiment onto a Golden Habit.
  void _flagHabit(String habitId,
      {required bool flagged, String reason = '', String note = ''}) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty || habitId.isEmpty) return;
    _onboarding
        .flagGoldenHabit(
            userId: uid,
            habitId: habitId,
            flagged: flagged,
            reason: reason,
            note: note)
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
    setState(() => _phase1 = next);
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

  void _openChat() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const AiChatPage(),
    ));
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
      Map<String, int> scores, Map<String, String> logs) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      try {
        await _checkin.saveCheckin(uid: uid, scores: scores, logs: logs);
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
    // Stash for the summary's Balance Meter so today's scores fold into the
    // rolling 7-day average immediately, without waiting on the read.
    _lastCheckinScores = scores;
    // Today's scores may newly tip a Core in/out of balance — refresh badges.
    _loadCoreBalance();
    if (mounted) _go('summary');
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
        planet: p?.planet ?? 'earth',
        activeCores: activeCores,
        atRiskCores: _atRiskCores,
        level: p?.level ?? 'cadet',
        momentumScore: _momentumOverride ?? (p?.momentumScore ?? 0),
        spaceCredits: _creditsOverride ?? (p?.spaceCredits ?? 0),
        balance: p?.balance ?? 0,
        phase1State: _phase1,
        onCheckIn: _startCheckin,
        onMenu: () => setState(() => _menuOpen = true),
        onChat: _openChat,
        onNav: _go,
        onCoreAlert: _showCoreAlert,
        offline: _offline,
        onRefreshOffline: _fetchProfile,
      );
    }
    if (_screen == 'phase1') {
      return Phase1Flow(
        state: _phase1,
        entryStage: _phase1Entry,
        entryHabitId: _phase1EntryHabitId,
        onStateChange: _persistPhase1,
        onBack: () => _go('dashboard'),
        onExitToCockpit: () => _go('dashboard'),
      );
    }
    if (_screen == 'ritual0') {
      return DailyRitualStep0(
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        onContinue: _completeStep0,
        onSkip: () => _go('checkin'),
        onClose: () => _go('dashboard'),
      );
    }
    if (_screen == 'checkin') {
      return CheckInPage(
        activeCores: activeCores,
        atRiskCores: _atRiskCores,
        coreHistory: _checkinCoreHistory,
        habitByCore: _checkinHabitByCore,
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
        onBack: () => _go('dashboard'),
        onChat: _openChat,
        onNav: _go,
      );
    }
    if (_screen == 'routines') {
      return RoutinesScreen(
        onBack: () => _go('dashboard'),
        onChat: _openChat,
        onNav: _go,
      );
    }
    if (_screen == 'habits') {
      return HabitsScreen(
        onBack: () => _go('dashboard'),
        onChat: _openChat,
        onNav: _go,
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

  @override
  Widget build(BuildContext context) {
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
          child: _errorOffline
              ? OfflineErrorView(
                  onRetry: _fetchProfile, what: 'your profile')
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Could not load profile',
                            style: MM.display(size: 16, color: Colors.white)),
                        const SizedBox(height: 8),
                        Text('Something went wrong. Please try again.',
                            textAlign: TextAlign.center,
                            style: MM.body(
                                color: Colors.white.withOpacity(0.6),
                                size: 12)),
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
    if (MediaQuery.of(context).size.width >= kWebBreakpoint) {
      return _buildDesktop();
    }

    return Stack(
      children: [
        Positioned.fill(child: _buildBody()),
        if (_menuOpen)
          Positioned.fill(
            child: MenuDrawer(
              user: FirebaseAuth.instance.currentUser,
              onClose: () => setState(() => _menuOpen = false),
              onNav: _go,
              onChat: _openChat,
              onSignOut: () => _auth.signOut(),
            ),
          ),
        // iCore Alert (#8) — opened by tapping a Core's red ⚠️ badge.
        if (_coreAlertCore != null) Positioned.fill(child: _buildCoreAlert()),
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
    final isShell = _shellScreens.contains(_screen) ||
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
          if (_coreAlertCore != null)
            Positioned.fill(child: _buildCoreAlert()),
        ],
      );
    }

    final p = _profile;
    final idx = MM.planets.indexWhere((e) => e['id'] == (p?.planet ?? 'earth'));
    final planetName = MM.planets[idx < 0 ? 0 : idx]['name'] as String;
    final activeCores = p?.activeCores ?? const <String>[];
    final name = (p?.displayName.isNotEmpty ?? false)
        ? p!.displayName
        : (FirebaseAuth.instance.currentUser?.displayName ?? 'Commander');
    final streak = _streakOverride ?? (p?.streak ?? 0);
    final level = p?.level ?? 'cadet';

    Widget content;
    var showTopbar = true;
    var title = 'Cockpit';
    var subtitle = 'Mission Control';
    var accent = MM.blue;
    switch (_screen) {
      case 'dashboard':
        content = WebCockpit(
          name: name,
          streak: streak,
          planet: p?.planet ?? 'earth',
          activeCores: activeCores,
          atRiskCores: _atRiskCores,
          level: level,
          momentumScore: _momentumOverride ?? (p?.momentumScore ?? 0),
          spaceCredits: _creditsOverride ?? (p?.spaceCredits ?? 0),
          balance: p?.balance ?? 0,
          onNav: _go,
          onCheckIn: _startCheckin,
          onCoreAlert: _showCoreAlert,
        );
        break;
      case 'routines':
        title = 'Routines';
        subtitle = 'Daily Orbit';
        accent = MM.teal;
        content = const WebRoutines();
        break;
      case 'habits':
        title = 'Habits';
        subtitle = 'Golden Habits';
        accent = MM.magenta;
        content = const WebHabits();
        break;
      case 'tasks':
        title = 'Tasks';
        subtitle = 'Missions · Today';
        accent = MM.yellow;
        content = const WebTasks();
        break;
      case 'lists':
        title = 'Lists';
        subtitle = 'Manifest';
        accent = MM.blue;
        content = const WebLists();
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
            content: content,
            showTopbar: showTopbar,
            title: title,
            subtitle: subtitle,
            accent: accent,
          ),
        ),
        if (_menuOpen)
          Positioned.fill(
            child: MenuDrawer(
              user: FirebaseAuth.instance.currentUser,
              onClose: () => setState(() => _menuOpen = false),
              onNav: _go,
              onChat: _openChat,
              onSignOut: () => _auth.signOut(),
            ),
          ),
        if (_coreAlertCore != null) Positioned.fill(child: _buildCoreAlert()),
      ],
    );
  }

  Widget _buildCoreAlert() {
    final coreId = _coreAlertCore!;
    final meta = _coreMeta[coreId] ?? ('This Core', MM.red);
    final scores = _coreScores[coreId] ?? const <int>[];
    final lows = <int>[];
    for (final s in scores) {
      if (s < 3) {
        lows.add(s);
      } else {
        break;
      }
    }
    return CoreAlertSheet(
      coreName: meta.$1,
      coreColor: meta.$2,
      lowScores: lows,
      streakDays: lows.length,
      onReviewHabits: () {
        _dismissCoreAlert();
        _go('habits');
      },
      onReturnToPhase1: () {
        _dismissCoreAlert();
        _returnToPhase1(null);
      },
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
                          border:
                              Border.all(color: Colors.white.withOpacity(0.12)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text('🔒', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 14),
                  Text('SPACE CANTINA LOCKED',
                      style: MM.displayX(size: 11, color: MM.yellow)),
                  const SizedBox(height: 8),
                  Text('Momentify your habit first',
                      textAlign: TextAlign.center,
                      style: MM.display(size: 20, color: Colors.white)),
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
