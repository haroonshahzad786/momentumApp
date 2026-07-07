  # Moore Momentum — Completion Plan

>   **Resume instructions (for Claude):** This file is the source of truth for finishing the app
> per the rules docs (`C:\Users\haroon\Downloads\willMoore (2)\rules`, extracted to
> `design/ref/_extracted/`). On request to "continue the todo", open this file, pick the lowest
> unchecked task whose dependencies are met, mark it `[~]` in progress, implement + verify, then
> mark it `[x]` and update the **Status** line. Keep this file in sync as the canonical backlog.

**Scope:** Core loop first (working product loop before the deep gamified economy).
**Placeholders:** The docs leave many exact numbers as `[PLACEHOLDER]` (MP per planet, Space-Credit
costs per ship tier, formed-habit counts per level, badge criteria). **Never invent these** — stub the
hook and flag *needs spec from the user*.

**Backend rule:** New cloud functions go in the Flutter-only functions file — never extend FlutterFlow's
`index.js`. vf-bridge has two codebases: default (FlutterFlow + vf chat) and flutter (new endpoints).

Legend: `[ ]` todo · `[~]` in progress · `[x]` done · 🔒 blocked on user spec

> **▶ RESUME HERE (next session):** #1–#12 ✅ ALL CORE-LOOP TASKS DONE (M0–M4), device-verified + on GitHub.
> **Only the two DEFERRED buckets remain — both 🔒 BLOCKED ON USER SPEC:**
> **#13 Gamified economy** (Space Credits ledger, leveling Cadet→Navigator→Commander, planet journey +
> alien guides, ship upgrades, Mystery Box, badge library) — nearly every threshold is `[PLACEHOLDER —
> DETAIL NEEDED]` in the Gamification doc. **#14 Cantina full build + Lists editing + Tasks screen** (MVP
> Reddit-bridge → V1 native Tribes/Ideas-Well/Leaderboards; Lists become editable; Tasks wired). Don't start
> #13/#14 without the user's numbers/decisions — surface what's needed and ask.
> _(2026-06-30: also produced a client traceability doc — `design/ref/documentation/` — mapping #1–#9 to
> the source `.docx` specs with quoted excerpts + 12 app screenshots, exported to both `.md` and a formatted
> `Moore Momentum - Build Progress & Traceability.docx`. Update it as more features land.)_
> Note: #10/#11 have 🔒 PLACEHOLDER thresholds (streak milestone payouts, formation badges) — stub those
> hooks, surface "needs spec", never fabricate. #10: streak increments on weekday check-in; 1st missed
> weekday = warning, 2nd consecutive = relaunch (level/credits/Trophy preserved); persist streak/
> lastCheckinDate/longestStreak. (The `flutterAwardCheckinPoints` marker `checkin_<date>` already records
> which days were checked in — reusable for streak continuity.)
>
> _(#4 device-verification, 2026-06-28, emulator-5554, uid `aGFJOhlFG3Oz8wdRICmKabiNdU33`): normalizer
> redeployed; GET confirmed `makeObvious/makeEasy/makeRewarding` read back the CLIENT's real picks (not the
> "TEST_OBV" probe). Drove the full MBS flow via the Cantina-locked deep-link ("GO TO STAGE 2") → 4 picks →
> "Lock it in" momentified → "Enter the Cockpit". Profile now `stage2Completed:true, phase:"daily"`, MP
> stayed **103** (idempotent — re-running momentify awarded 0). Cantina opens the real CantinaScreen (Ideas
> Well/Tribes/Leaderboard/Arena), not the lock view. Cold force-stop+relaunch → phase pill "PHASE 2 · DAILY
> EXECUTION" persists. **Bug fixed this session:** "Enter the Cockpit" left the cockpit stuck on "Stage 2 in
> progress" until a restart — `_persistPhase1` (momentum_home) fired the Firestore save fire-and-forget then
> immediately `_fetchProfile()`, so the read raced ahead of the write and re-seeded `_phase1` with stale
> `stage2Completed:false`. Fixed by chaining the refetch AFTER the save commits; rebuilt+installed and
> re-verified the cockpit flips to daily IMMEDIATELY on Enter-the-Cockpit (no restart)._
>
> _(prior #3 context retained below)_
> #3 open question RESOLVED + both
> defects FIXED & deployed+verified (2026-06-22). Finding: the Voiceflow agent does NOT persist
> `golden_habits` even on a clean run (Nova reached "LEVEL 1 COMPLETE"/"MOMENTUM LISTS ACTIVATED"
> but `forged:false`/`activeCores:[]`), and it skips the Keystone +25 award (clean finish = 85 MP,
> so the MP-derived `completedCount` caps at 4 and the old `forged || completedCount>=5` gate
> dead-ended). **Fixes shipped (NO new LLM — user wanted Voiceflow to stay the only AI):**
> **(A)** `flutterForgeFromTranscript` (functions-flutter) deterministically parses Nova's "YOUR
> GOLDEN HABIT" summary message from `vf_messages` and writes the `golden_habits` doc
> (saveGoldenHabit schema; idempotent). Client (`OnboardingService.forgeFromTranscript` +
> `hhs_chat_view._syncOnboarding`) calls it once when reachedForge && !forged.
> **(B)** `flutterSyncOnboarding` now returns `reachedForge` (transcript-marker based) and forces
> `completedCount=5` on it; the cockpit gate is `forged || reachedForge || completedCount>=5`.
> Verified live on `verifyCleanRun20260622a`: forge wrote `gh_morning_momentum_movement` → sync
> `forged:true, completedCount:5` + full fields → profile `activeCores:["physical"]`; idempotent
> ("exists") and safe on never-onboarded uids ("not_forged").
> **STILL OPEN (proper fix, Voiceflow dashboard — Claude can't edit the VF agent):** make Nova call
> the `saveGoldenHabit` HTTP endpoint at the forge step (it already captures every field); then the
> transcript parser becomes a pure no-op safety net. **DEVICE-VERIFIED (2026-06-24, emulator-5554,
> uid aGFJOhlFG3Oz8wdRICmKabiNdU33):** cold launch → dashboard + hub read persisted Phase 1 state
> from Firestore (Stage 1 ✓ COMPLETE, 5/5 pyramid, 2 cores active); live HhsChatView resumed the
> transcript, re-synced, and rendered the Forge Confirm card with REAL persisted golden-habit fields
> ("walk 20 min in evening · Physical Health Core"); tapped **"Lock it in"** → Command Center
> Unlocked (7 Lists) → cold force-stop+relaunch → state held. Persistence round-trip confirmed
> on-device. Caveat: run was on an ALREADY-onboarded account (verifies resume + lock-in + round-trip);
> a literally-from-zero brand-new-account run remains covered by the server script verifyCleanRun20260622a,
> not a fresh device account. Minor cosmetic: one forge field showed a parser-fallback placeholder
> ("WHAT: what info will go there") — not a persistence defect. See [[reference_vf_onboarding_agent]].

---

## M0 — Foundation (do first; unblocks everything)

- [x] **#1 Persist Phase 1 state to Firestore.** Add `stage1Progress (0-5)`, `stage1Completed`,
  `stage2Completed`, and top-level `phase ('build'|'daily')` to the user profile. Load in
  `ProfileService.getProfile`; seed `MomentumHome._phase1` from the profile instead of
  `const Phase1State()`; write back on every `Phase1Flow.onStateChange` and on check-in.
  *Why first:* the "Return to Phase 1" / Go Deeper bridge (already built) is currently local-only and
  resets on restart.
  *Done 2026-06-21:* new `flutterSavePhase1State` endpoint (functions-flutter) + `phase1` fields on
  `flutterGetUserProfile` (phase derived server-side); `UserProfile.phase1State`,
  `ProfileService.savePhase1State` (syncs offline cache), `_persistPhase1` write-back in momentum_home,
  re-sync on check-in. Deployed + endpoint smoke-tested (progress clamp 0-5 + phase derivation verified).
  Debug Phase-2 toggle left local-only (removed in #2). Not yet exercised on-device.
- [x] **#2 Replace debug Phase-2 toggle with real gating.** Remove the menu Switch that injects
  hardcoded Mars/Navigator/47-streak/5-cores. Phase derives from persisted state
  (`stage1Completed && stage2Completed` ⇒ `daily`). Dashboard streak/planet/level/score/balance come
  from the real profile in both phases. `activeCores` = cores with ≥1 Golden Habit
  ("cores grayed out until first habit created in that Core").
  *Done 2026-06-21:* deleted the DEBUG toggle (menu_drawer `inPhase2`/`onTogglePhase` params + block,
  momentum_home wiring) and all `_phase2Debug*` overrides — dashboard/summary now read real profile
  values in every phase; phase shown via the existing dashboard phase pill (gated off persisted #1
  state). Backend `flutterGetUserProfile` now derives `activeCores` live from the `golden_habits`
  subcollection, mapping long coreIds (mindset_core…) → short (mindset…). Deployed + verified
  (2 habits in 2 cores → activeCores = [physical, mindset]). Brand-new accounts → empty (all cores
  grayed), matching spec.

## M1 — Real onboarding

- [x] **#3 Drive HHS Stage 1 with the Voiceflow AI** (not the hardcoded `_contentFor` 5 sections).
  Pain Point → Core → Universal Principle → Keystone → Golden Habit Forge, captured via the existing
  `ChatService` / `vf*` functions. Persist the resulting Golden Habit (`saveGoldenHabit`) + auto-tag
  Momentum Lists. Award Truth Seeker +10, Core Confirmed +15, Principle Decoder +20, Keystone Forger
  +25, Golden Habit Architect +40.
  *Built 2026-06-21:* Hardcoded 5-section stepper REPLACED with an embedded Nova chat
  (`hhs_chat_view.dart`) — drives the real Voiceflow onboarding agent via `ChatService`. New
  `OnboardingService` + read-only `flutterSyncOnboarding` endpoint report progress; pyramid advances
  + per-section reward overlays fire from the agent's MP. Forge → confirm card → `stage1Completed`;
  momentum_home refetches profile so the new Core + MP show. Removed the old `_HHSSectionView`/
  `_contentFor` catalogue. Analyzer-clean; deployed; progress/MP tracking verified live (MP 10→1 section,
  25→2). **KEY FINDING (changed the design):** the VF agent OWNS awarding MP (+10/15/20/25/40) AND is
  expected to persist the Golden Habit + tag Lists on a clean finish — it does NOT expose captured data
  in readable state variables. So the endpoint is READ-ONLY (no awarding/writing) to avoid
  double-counting; `activeCores` (#2) lights up from the agent-written `golden_habits`. See
  [[reference_vf_onboarding_agent]].
  **✅ DEVICE-VERIFIED (2026-06-24):** on emulator-5554 the persisted flow round-trips end-to-end —
  hub shows Stage 1 ✓ COMPLETE (5/5) after cold start, the live chat resumed + rendered the Forge
  Confirm card from the real persisted `golden_habits` doc, "Lock it in" unlocked Command Center, and
  a cold force-stop+relaunch held the state. Done on an already-onboarded account; a from-zero
  brand-new-account device run is still only server-script-verified (verifyCleanRun20260622a).
  Safety net (Stage 1 completes at completedCount≥5 / reachedForge) remains so the flow can't dead-end.
  **Residual optional follow-up (not blocking):** have Nova call `saveGoldenHabit` directly in the
  Voiceflow dashboard so the transcript parser becomes a pure no-op (Claude can't edit the VF agent).
- [x] **#4 Make Stage 2 MBS real + gate Cantina unlock.** Persist the 3 MBM picks (Obvious/Easy/
  Rewarding) + IF-THEN onto the active Golden Habit. Drive suggestions from AI/Momentum Lists. On real
  completion set `stage2Completed` and unlock Cantina + Command Center from persisted state. Award
  Friction Hunter +10, Method Master +15, Implementation Wizard +25.
  *Built 2026-06-24:* new `flutterSaveMomentumMethods` (functions-flutter) merges makeObvious/makeEasy/
  makeRewarding + refined obstacleIf/Then onto the active (newest, or explicit habitId) golden habit and
  awards Friction Hunter +10 / Method Master +15 / Implementation Wizard +25 once (idempotent via
  `mbsAwarded`; same points/summary+history+mirror schema as updateUserPoints). `OnboardingService`
  gains `activeHabit()` (reads flutterGetGoldenHabits) + `saveMomentumMethods()`. `_MBSStage2View` now
  fetches the real forged habit, **personalizes the MBM/IF-THEN suggestions from its real fields** (a
  richer AI/Lists generator is left as a future hook — deterministic for now per "don't invent"),
  persists on "Lock it in", and shows the real habit name + a "+50 MP / 3 badges" summary on the Cantina
  unlock. momentum_home **gates the Cantina screen behind persisted `stage2Completed`** (`_CantinaLockedView`
  → deep-links to Stage 2) and refetches the profile when Stage 2 newly completes. Analyzer-clean.
  *Deployed + partially device-verified 2026-06-24 (emulator-5554, uid aGFJOhlFG3Oz8wdRICmKabiNdU33):*
  flutterSaveMomentumMethods deployed & working — Cantina LOCK shown, MBS suggestions personalized from
  the real habit ("walk 20 min in evening", WHEN="Evening"), momentify awarded **+50 MP (53→103)**,
  IF-THEN persisted, idempotent re-call awarded 0, Cantina-unlock screen shows the REAL habit name +
  "+50 / 3 badges".
  **BUG (normalizer) — FIXED & redeployed 2026-06-28:** makeObvious/makeEasy/makeRewarding read back empty
  because normalizeGoldenHabit (functions-flutter) didn't map them (the WRITE was always fine). Added the 3
  fields + mbsCompleted/mbsAwarded to the normalizer and redeployed `flutterGetGoldenHabits`.
  **BUG (cockpit refresh race) — FIXED & re-verified 2026-06-28:** "Enter the Cockpit" left the dashboard
  stuck on "Stage 2 in progress" until a restart — `_persistPhase1` (momentum_home) saved phase1 state
  fire-and-forget then immediately `_fetchProfile()`, so the read raced ahead of the write and re-seeded
  `_phase1` with stale `stage2Completed:false`. Fixed by chaining the refetch after the save commits
  (`save.then((_) => _fetchProfile())`). Rebuilt+installed; cockpit now flips to daily IMMEDIATELY.
  **✅ DEVICE-VERIFIED 2026-06-28 (emulator-5554):** full MBS flow via the Cantina-locked "GO TO STAGE 2"
  deep-link → 4 picks → momentified → "Enter the Cockpit" flips phase→daily immediately, MP stayed 103
  (idempotent), Cantina opens the real CantinaScreen; cold force-stop+relaunch persists "PHASE 2 · DAILY
  EXECUTION". GET confirmed the client's real MBM + IF-THEN picks overwrote the earlier probe values.

## M2 — Daily ritual complete

- [x] **#5 Daily Ritual Step 0 (Mantra & Gratitude).** Optional pre-scoring screen
  (`[View Mantra] [View Grateful List] [Skip] [Continue to Scoring →]`), opens Command Center lists then
  returns. Skippable; remembers per-day completion. Insert ahead of `CheckInPage`.
  *Built + device-verified 2026-06-29:* new `daily_ritual_step0.dart` (`DailyRitualStep0`) shown ahead of
  the check-in. Reads the user's Momentum Lists and matches the Mantra (`/mantra|affirmation/i`) + Grateful
  (`/grateful|gratitude|thank/i`) buckets by name; renders the mantra as a quotation block + the grateful
  items as a scan, with gentle "set one up" prompts when absent. `[View Your Mantra]`/`[View Grateful List]`
  push the Command Center `ListsScreen` (new optional `expand` param pre-expands the matched list) and
  return on back. momentum_home: `_startCheckin` gates the new `ritual0` screen on per-day completion
  (LocalCache key `ritual:step0:<uid>` = today's yyyy-mm-dd); `[Continue to Scoring →]` marks today done,
  `[Skip]` advances without marking (can reappear later the same day). Dashboard `onCheckIn` now routes
  through `_startCheckin`. Analyzer-clean. **DEVICE-VERIFIED (emulator-5554):** Daily Check-In → Step 0
  appears; View Your Mantra → Command Center Lists → back returns to Step 0; Continue to Scoring → check-in
  scoring; re-tapping Daily Check-In same day → goes straight to scoring (Step 0 remembered). Verified on an
  account with no Mantra/Grateful list (empty-state prompts); populated rendering is simple string display.
- [x] **#6 Real numbers in Progress Summary.** `summary_page.dart` hardcodes +125 MP, 2,740 credits,
  focus, daily challenge. Use real MP earned (from #9), updated streak, credits balance, and the
  5-Core Balance Meter = rolling 7-day average of check-in scores. AI focus reminders may stay static
  but must be clearly marked not-yet-real (no fake numbers).
  *Built + device-verified 2026-06-29:* `summary_page.dart` rewritten — **Total Momentum** = real profile
  `momentumScore`; **streak** = real persisted value (removed the optimistic +1); **5-Core Balance Meter**
  = real rolling 7-day average computed in-screen from `CheckinService.getRecent(limit:7)` + today's just-
  submitted scores (folded in via new `momentum_home._lastCheckinScores` → `SummaryPage.todayScores`),
  averaged per active Core over days that scored it (locked/no-data Cores show lock/"–", never fabricated).
  Since #9 (points) and #13 (economy) aren't built, the economy stats carry **no fake numbers**: "Earned
  Today" and "Space Credits" are `_PendingStatRow`s ("—" + SOON chip + reason); Today's Focus is a marked
  **PREVIEW** with general guidance (removed the fake "2.3 average" lines); Daily Challenge is a **COMING
  SOON** teaser (removed the fake "+50 MP"/Accept-Skip); the fake "+150 credits" Mystery Box is removed
  (deferred to #13). Analyzer-clean. **DEVICE-VERIFIED (emulator-5554):** scored REL=5 / PHYS=4 → Lock In
  Day → Summary showed Total Momentum 103 MP, Earned Today/Space Credits "—·SOON", streak Day 0, Balance
  Meter REL 5.0 / PHYS 4.0 over a real 3-day window, Focus PREVIEW, Daily Challenge COMING SOON.
- [x] **#7 Persist Mission Control flags + AI auto-flag.** Persist manual flags/experiments onto the
  Golden Habit (`flutterFlagGoldenHabit` exists). Auto-flag when a Core/habit scored ≤3.0 for 3+
  consecutive check-ins. Ensure "Go Deeper" passes the flagged habit id so the returning-player flow
  pre-loads it.
  *Built 2026-06-29:* `OnboardingService` gains `goldenHabits` (list as `GoldenHabitRef` keyed by SHORT
  core id + flagged state), `habitById`, and `flagGoldenHabit`. momentum_home prefetches Mission Control
  context on `_startCheckin` (`_checkinHabitByCore` + per-Core prior scores `_checkinCoreHistory` from
  `getRecent`, excluding today). CheckInPage: the struggling alert is now the REAL pattern (consecutive
  check-ins ≤3.0 incl. today's live slider, ≥3 fires), the Pattern-Detected chart shows real last-3 scores,
  the flag icon / RESOLVE open the intervention on the Core's real Golden Habit, and picking a path persists
  a flag+experiment via `flutterFlagGoldenHabit`. **Auto-flag** runs in `_saveCheckin` (`_autoFlagStruggling
  Cores`): each active Core ≤3.0 for 3+ consecutive check-ins flags its habit (skips already-flagged, so a
  sustained dip doesn't re-flag daily). **Go Deeper** now threads the flagged `habitId` → `_returnToPhase1(
  stage, habitId:)` → `Phase1Flow.entryHabitId` → `_MBSStage2View` loads that specific habit via `habitById`
  (fallback newest). **Also fixed a PRE-EXISTING blank-render bug:** the check-in habit-row card mixed a
  non-uniform Border (thick left) with borderRadius → painted blank (rows + flag icons invisible/untappable);
  rebuilt with a uniform border + clipped left stripe ([[project_habits_card_blank]]). Analyzer-clean.
  **DEVICE-VERIFIED (physical Pixel 6):** habit rows now render with flag icons; tapping flag → Mission
  Control → "Quick Suggestion" persisted `flagged:true, flagReason:"Quick tweak"` on the physical habit
  (confirmed via GET); experiment toast shown; "Go Deeper → Path B" navigated to Stage 2 MBS pre-loaded with
  the flagged habit ("walk 20 min in evening"). **Auto-flag trigger NOT reproduced on-device** — needs 3
  consecutive low calendar-days of history; can't fabricate dates on a physical device and no admin creds to
  seed checkins. Logic is analyzer-clean and reuses the SAME `flagGoldenHabit` persistence verified above +
  the same `_consecutiveLow` computation the (testable) pattern display uses. *(Note: emulator clock-trick to
  seed past dates corrupts the emulator display — avoid; verify on the physical device instead.)*
- [x] **#8 Core Balance 5-day alert.** Any Core below 3.0 for 5+ consecutive days ⇒ red ⚠️ badge on the
  Core (dashboard + check-in), tappable to an iCore message with recent low scores + links + `[Done]`.
  *Built + device-verified 2026-06-30:* detection `coreLowStreak`/`isCoreOutOfBalance` (≥5 consecutive
  scores <3.0) in checkin_service. momentum_home `_loadCoreBalance` (from `getRecent`, most-recent-first
  incl. today) computes `_atRiskCores` on profile load + after each check-in; passed to DashboardPage (→
  RocketWidget red ⚠️ "!" badge on the at-risk Core's icon, tappable) and CheckInPage (→ red "⚠️ AT RISK"
  chip in the Core header). Tapping either opens the new `CoreAlertSheet` overlay (iCore Alert) with the
  spec copy "This core is unbalanced. You should focus your work to improve it.", a recent-low-scores bar
  strip, a review suggestion, links [Review Habits]→habits / [Return to Phase 1], and [Done]. **DEVICE-
  VERIFIED (emulator-5554)** via a temporary at-risk injection: dashboard rocket badge + check-in AT-RISK
  chip both render and both open the iCore Alert; Done dismisses; clean build (injection removed) shows no
  badge (data-driven). **Bug fixed during build:** the overlay's InkWell buttons threw "No Material
  ancestor" — wrapped `CoreAlertSheet` in `Material(type: transparency)`. Analyzer-clean. **Real 5-day
  trigger + populated low-score bars NOT reproduced on-device** (can't fabricate 5 low calendar-days / no
  admin creds — same limit as #7 auto-flag); detection is a trivial pure function.

## M3 — Economy core

- [x] **#9 Momentum Points engine.** Confirmed: +10/completed weekday check-in; Phase 1 section awards
  (10/15/20/25/40 and 10/15/25). Persist running `momentumScore` + per-check-in breakdown.
  🔒 high-score (5/5) bonus, streak-milestone bonus, Balance Bonus amounts are PLACEHOLDER — stub hooks.
  *Built + device-verified 2026-06-30:* new `flutterAwardCheckinPoints` endpoint (functions-flutter) awards
  **+10 per completed WEEKDAY check-in** (a Core scored), idempotent per calendar day via a deterministic
  history doc id `checkin_<date>` (re-checkin same day = +0). Same points schema as updateUserPoints/
  flutterSaveMomentumMethods: `points/summary.total` (the profile `momentumScore` source of truth) +
  `summary/history/checkin_<date>` breakdown entry (`type:"Daily Check-In", points, date`) + user-doc
  `points` mirror. Weekends + empty check-ins award 0 (no marker). The high-score(5/5)/streak-milestone/
  Balance bonuses are **STUBBED** in `bonusHooks` (eligible flag + amount 0 + needsSpec:true) — NOT
  fabricated; wire real amounts once specced. The Phase-1 section awards (10/15/20/25/40 HHS, 10/15/25 MBS)
  were already handled by the VF agent (#3) + flutterSaveMomentumMethods (#4). Client: new `PointsService.
  awardCheckin` called in `momentum_home._saveCheckin`; an optimistic `_momentumOverride` updates the running
  total without a reload spinner (cleared on next profile fetch), and `_earnedToday` feeds the Summary. This
  also makes #6's pending **"Earned Today"** real (now a teal `_StatRow` when a fresh award exists, else the
  placeholder). **DEVICE-VERIFIED (emulator-5554):** completed weekday check-in → Summary "Total Momentum
  113 MP / Earned Today 10 MP"; GET profile `momentumScore:113` (was 103); re-award 2026-06-30 →
  alreadyAwarded, +0, total 113; weekend (2026-06-28) → reason "weekend" no award; empty scores →
  "not_completed". Analyzer-clean. Endpoint deployed.
- [x] **#10 Streak system.** Confirmed: increments on weekday check-in; weekends optional (don't break);
  1st missed weekday = warning only; 2nd consecutive = "relaunch" (level/credits/Trophy preserved).
  Persist `streak`, `lastCheckinDate`, `longestStreak`. 🔒 milestone payouts (7/14/30/60/90/180/365) +
  Streak Saver mechanics are PLACEHOLDER — detect milestones, stub payouts.
  *Built + verified 2026-07-02:* **Streak rule (Gamification Spec §6):** a streak day = a WEEKDAY check-in
  with a **≥4.0 average** across scored Cores (not just any check-in). Implemented in
  `flutterAwardCheckinPoints` (same txn as points): weekends exempt (early return), 1 missed weekday = grace
  (streak survives → "warning"), 2+ missed weekdays reset to 1; persists `streak`/`lastCheckinDate`/
  `longestStreak` on the user doc; idempotent per day via `lastCheckinDate`. Milestones 3/7/14/30/60/90/180/365
  **detected** (returns `milestone`), payouts **stubbed** (`bonusHooks.streakMilestone`, PLACEHOLDER — not
  fabricated). `flutterGetUserProfile` computes the **effective streak** vs the client's local `today` (passed
  by `ProfileService`): gap 1 → `streakState:"warning"`, gap ≥2 → streak 0 / `"broken"` — so the dashboard is
  truthful between check-ins. Client: `UserProfile` gains `longestStreak`/`streakState`/`lastCheckinDate`;
  `PointsService`/`CheckinAward` return streak+milestone; `momentum_home` `_streakOverride`/`_streakMilestone`
  (optimistic, like points); dashboard shows a red "STREAK ⚠" on warning; Summary streak callout shows the new
  Day count + "🎉 N-DAY MILESTONE". **VERIFIED:** curl state-machine (1→2→3+milestone→4 grace→1 reset;
  low-avg no-extend; weekend exempt) + effective-read (ok/warning/broken, longest preserved); **device**
  (emulator-5554): qualifying weekday check-in → Summary "Day 1", next milestone 3, MP 113→123; GET
  `streak:1,longest:1,last:2026-07-02`; re-award idempotent (streakUpdated:false). Analyzer-clean; both
  endpoints deployed. **Note:** the "relaunch"/MP-reduction on 2 misses (rocket regression) is economy #13 —
  #10 resets the streak + preserves level/credits/Trophy (untouched); the MP-reduction amount is PLACEHOLDER.
- [x] **#11 Trophy Room from real formation.** Replace hardcoded `_formedHabits`. Formed = 14+ days
  history AND ≥80% of applicable days scored ≥3 on the habit's Core (reuse `deriveRoutineStage`). List
  real formed habits by Core; support manual "Mark as Formed" (2-week-standard confirm) writing a
  formed flag/date. 🔒 formation badges by count — defer.
  *Built + device-verified 2026-07-02:* `TrophyScreen` rewritten to fetch REAL data — `OnboardingService.
  goldenHabits` (now carries `formed`/`formedAt`) + `CheckinService.getRecent` per-Core scores. A habit is
  "formed" if **manually marked** OR **auto** (`deriveRoutineStage(coreScores) == 'formed'` — the 14d/≥80%
  rule). Trophy tab: summary count + per-Core sections (only Cores with a Golden Habit shown); formed →
  🏆 trophy card ("FORMED {date} · {days} DAYS"); still-forming → progress card ("{days}/14 DAYS" bar) +
  a **"Mark as Formed"** action → **2-week-standard confirm dialog** → `flutterSetHabitFormed` (new
  functions-flutter endpoint writes `formed`+`formedAt`; normalizer returns them) → refetch. Achievements
  tab (badges) left as the existing placeholder (🔒 formation-badges-by-count deferred). Analyzer-clean.
  **DEVICE-VERIFIED (emulator-5554):** Trophy Room showed the 2 real habits as forming (relationships 1/14,
  physical 3/14); "Mark as Formed" on "walk 20 min in evening" → confirm dialog ("2-week standard … you have
  3 logged") → habit became a 🏆 trophy ("FORMED JUL 2 · 3 DAYS"), count → 1; GET confirms
  `formed:true, formedAt:2026-07-02`. Auto-formation (14+ days) not device-reproduced (needs 14 days of
  history — same limit as #7/#8) but reuses the verified `deriveRoutineStage`. Endpoints deployed. *(Emulator
  display froze again mid-test → rebooted to recover; verify on a physical device when possible.)*

## M4

- [x] **#12 Profile screen real data.** Replace mock ("Alex Moore", 78/65/42/81/54). Wire name/level/
  streak/score from the profile; compute the 5-Core radar from rolling 7-day check-in averages. Sign
  Out stays functional; mark other settings tiles as not-yet-wired.
  *Built + device-verified 2026-07-06:* `ProfileScreen` (sub_screens) rewritten StatelessWidget→Stateful,
  fetches `ProfileService.getProfile` + `CheckinService.getRecent`. Header shows real displayName (email
  local-part fallback → "Commander"; avatar = 1st letter), real `level` (subtitle + chip), real `streak`🔥
  + `momentumScore` MP chips. The `_RadarPainter` (0–100) is fed by `_computeRadar` = per-Core rolling
  7-day check-in average (avg/5·100), Cores with no data → 0 + a "check in daily…" hint. Settings tiles
  (Notifications/Connected calendars/Privacy/Subscription) now show a **"SOON"** tag + a "coming soon"
  snackbar (`_SettingTile.wired=false`); **Sign out stays functional** (red, real `onSignOut`). Loading/
  offline/error states added. Analyzer-clean. **DEVICE-VERIFIED (emulator-5554):** Profile showed
  "naginashaheen88 · CADET · 1🔥 · 123 MP", a real radar (physical+relationships extended, others centred),
  SOON tiles → snackbar. *(No new backend — pure client using existing endpoints.)*

---

## Deferred (out of core-loop scope — captured so nothing is lost)

- [~] **#13 Gamified economy** 🔒 — Space Credits ledger; Leveling Cadet→Navigator→Commander (3
  simultaneous criteria); Planet journey + alien-guide arrival + quests; Ship Upgrades
  (Wings→Armor→Thrusters, fixed order — not implemented at all today); Mystery Box (10–15%/check-in,
  guaranteed every 10th); Badge library. Nearly every threshold is PLACEHOLDER — split into per-system
  tasks once the user provides numbers.
  **Split into sub-tasks (2026-07-06): 13a ledger · 13b leveling · 13c planets · 13d ship · 13e mystery box
  · 13f badges.** User is providing the [PLACEHOLDER] numbers per system.
  **🖼 DESIGN-REFERENCE IMAGES (2026-07-07 — previously ignored: the text-only `_extracted/*.txt` dropped all
  embedded images).** The 12 doc images are now saved to `design/ref/_doc_images/` (pulled from the `.docx`
  zips' `word/media/`). What they add beyond the text — and the GAPS they surface:
  - **Ship Upgrades UI (13d)** — `gam-07-improvements-hub`, `gam-06-ship-upgrade-wings`,
    `gam-04-ship-upgrade-turbines`, `gam-01-rocket-base-variants`: an "IMPROVEMENTS" hub with category
    buttons (COLORS · WINGS · TURBINES[=Thrusters] · ARMOR); each category = a rocket-in-porthole preview +
    green **GET** button + a row of tiers with 💎 prices (mockup shows +5/+25/+50, illustrative) + a grid of
    visual variants; the rocket art morphs per upgrade tier. "Colors" = cosmetic skins (post-MVP). Needs
    per-tier rocket ART assets (Wings/Armor/Thrusters × Common/Rare/VeryRare/Epic) — currently absent.
  - **GAP → dashboard Space Credits readout** — `gam-05`, `phase-03`, `phase-01` all show the dashboard
    top status bar displaying **Space Credits (💎)** next to Planet + Momentum Score. Our shipped dashboard
    shows PLANET/SCORE/BALANCE but NOT credits. Quick win now that 13a ledger + `profile.spaceCredits` exist.
    (Added as 13g below.)
  - **GAP → "Skip Check-in / Bonus" credit sink** — `gam-09-skip-checkin-bonus-purchase`: a purchase screen
    to spend credits and skip 1/2/5 days (mockup 5/10/15 💎) to protect the streak — the Streak-Saver /
    Vacation-Mode / Armor-grace SPEND mechanic as a screen. Not previously in the plan. (Added as 13h below.)
  - **Planet journey full-screen view** — `phase-02-planet-journey-travel`: a dedicated full-screen rocket-
    travelling-Earth→space-station view (dashed trajectory), beyond the dashboard's small JourneyArc → 13c.
  - **Streak/milestone Trophies** — `gam-03-streak-milestone-trophy`: a Trophies CAROUSEL with per-trophy
    progress ("7 STREAK DAYS · 2 of 7"), distinct from formed-habit trophies → feeds 13f + the Trophy Room
    "Achievements" tab (still a placeholder from #11).
  - **Cantina Leaderboard** — `gam-08-cantina-leaderboard`: rank · avatar · name · score · medal (gold/
    silver/bronze), current player row highlighted → enrich #14.
  - **iCore Alert framing** — `gam-02-icore-alert-cockpit`: the alert renders INSIDE the rocket cockpit-
    porthole screen (we shipped a plain centered overlay in #8) → optional visual-polish on #8.
  - **Branding note** — `phase-01` center shows a "5 CORE LIFE" splash; our shipped splash is Moore Momentum
    (deliberate per [[project_branding_boot_splash]]) — design ref only, not a change.
  - **[x] 13a Space Credits ledger (foundation) — BUILT + backend-verified 2026-07-06.** New credits schema
    `users/{uid}/credits/summary.total` + `history` subcollection + `users/{uid}.spaceCredits` mirror
    (parallels the points schema). `creditMultiplier(level)` applies the SPECIFIED level multiplier
    (cadet 1× / navigator 1.25× / commander 1.5×). The one specified amount — the **25-credit Cantina
    welcome bonus** — is wired into `flutterSaveMomentumMethods` (Stage-2 completion), guarded by a NEW
    `cantinaWelcomeCredited` flag INDEPENDENT of `mbsAwarded` (so already-Stage-2 players get credits on
    next momentify without re-awarding MP; idempotent). `flutterGetUserProfile` returns `spaceCredits`.
    Client: `UserProfile.spaceCredits`; Summary "Space Credits" is now a real `_StatRow` (💎, was SOON);
    Profile header shows a `💎` chip. Curl-verified: 0→25 credits, MP unchanged (123), idempotent re-run;
    profile returns spaceCredits. Analyzer-clean; both endpoints deployed. On-device visual blocked by the
    recurring emulator display-freeze (backend is the source of truth here).
    🔒 **NEEDS FROM USER (set ①) to wire the rest of earning:** base credits/check-in, high-score(5/5)
    bonus, habit-formation bonus, streak-milestone credits (per 3/7/14/30/60/90/180/365). Then wire into
    `flutterAwardCheckinPoints` (+ level mult) / `flutterSetHabitFormed`.
  - [ ] **13b Leveling** (Cadet→Navigator→Commander, 3 simultaneous criteria). NEEDS set ②: formed-habits/
    planet/streak thresholds per transition. Levels never downgrade.
  - [ ] **13c Planet journey** (Moon→Mars→Jupiter→Saturn→Pluto + arrival: alien guide, list unlock, bonus
    credits, quest). NEEDS set ③: MP per planet, arrival bonus credits, regression threshold. UI: a
    full-screen travel view (`phase-02-planet-journey-travel`) — rocket on a dashed trajectory Earth→station;
    dashboard already has a small JourneyArc.
  - [ ] **13d Ship upgrades** (Wings→Armor→Thrusters fixed order; effects specified: armor grace 1/2/3/week,
    thrusters +25/50/75/100% MP; epic=Commander). NEEDS set ④: credit costs per tier. UI per
    `gam-07/06/04`: "IMPROVEMENTS" hub (Colors/Wings/Turbines/Armor) → per-category porthole preview + GET +
    tier row (💎 prices) + variant grid; **needs per-tier rocket ART assets** (12 functional variants + color
    skins) which don't exist yet — flag to the user (asset production, not just numbers).
  - [ ] **13e Mystery Box** (10–15%/check-in, guaranteed 10th, needs Captain's Log; 70% useful/30%
    delightful reward table mostly specified). NEEDS set ⑤: exact % (pick 10–15).
  - [ ] **13f Badge / Trophy library** (last) — NEEDS the full badge list (names/criteria/rarity). Also the
    **streak/milestone Trophies** (`gam-03`) — a carousel with per-trophy progress ("N-STREAK-DAYS · x of N")
    — feed both this and the Trophy Room "Achievements" tab (placeholder since #11).
  - [x] **13g Dashboard Space Credits readout — DONE + device-verified 2026-07-07.** Added a `CREDITS · N 💎`
    `_Stat` row to the dashboard top status bar (between SCORE and BALANCE), fed by `profile.spaceCredits`
    (`DashboardPage.spaceCredits` ← momentum_home). Analyzer-clean; verified on the physical Pixel 6 (shows
    "CREDITS · 25 💎"). No new numbers needed (used the 13a ledger).
  - [ ] **13h Skip-Check-in / streak-protection purchase** (image-surfaced, `gam-09`) — a "Bonus" screen to
    spend credits and skip 1/2/5 days (mockup 5/10/15 💎) protecting the streak. Ties into #10 streak +
    Armor grace (#13d). NEEDS set: the skip-day options + credit costs. (Was not an explicit task before.)
- [ ] **#14 Cantina full build + Lists editing + Tasks** — Cantina: DMs are real Firestore but threads
  are seeded mocks; docs want MVP Reddit-bridge gateway, then V1 native (Ideas Well upvote/click-to-
  adopt, Tribes ≤20 members/≤3 joined, Accountability Partners, anti-shame leaderboards recalced 6h).
  Momentum Lists are read-only → add editing (20-list Command Center spec). Tasks screen is pure mock →
  wire to real storage or descope. (Cantina competitions + pro marketplace are explicitly post-MVP.)
  UI ref (image-surfaced): the **Leaderboard** (`gam-08-cantina-leaderboard`) = rank · avatar · name · score ·
  medal (gold/silver/bronze), current player's row highlighted; anti-shame ordering per the Cantina doc.

---

## Implementation status reference (audit 2026-06-20)

**REAL today:** auth, dashboard fetch, check-in scoring persistence (`/users/{uid}/checkins/{day}`),
Momentum Lists / Routines / Habits reads, Cantina DMs, AI chat (Voiceflow), notifications, offline cache.
**PARTIAL:** Phase 1 flow (UI real, content hardcoded, state NOT persisted), Summary (UI real, numbers
fake), gamification (display-only).
**MOCK:** Trophy Room, Profile, Tasks.
**Already done this session:** Phase 1 Re-Entry Bridge — the dead "Return to Phase 1" button + Mission
Control "Go Deeper" Path A (→HHS) / Path B (→MBS) now navigate; Path A verified on emulator.
