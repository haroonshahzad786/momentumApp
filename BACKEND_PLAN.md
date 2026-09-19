# Moore Momentum — Backend & Admin Plan

> **Resume instructions (for Claude):** this file is the canonical backlog for **backend/admin** work —
> remote config, the admin console, moderation, scheduling and the AI layer. Sibling of
> `COMPLETION_PLAN.md` (client/feature work). To "continue the backend todo": open this file, take the
> lowest unchecked task whose dependencies are met, mark it `[~]`, implement + verify, mark `[x]`, and
> update the **Status** line of its section.
>
> Rewritten **2026-09-08** to describe what a backend/admin layer would realistically control given the
> structures the app *already has* — Firestore, the `flutter` Cloud Functions codebase in `vf-bridge`,
> and the Voiceflow bridge. (The previous revision was derived from the client's old Django app; that
> framing didn't match how this app is actually built. The old-app notes remain useful as *reference*
> for shapes that worked — see Source documents — but this plan is not a port of it.)

Legend: `[ ]` todo · `[~]` in progress · `[x]` done · 🔒 blocked on client content/assets/decision

**Backend rule (unchanged):** new cloud functions go in `vf-bridge/functions-flutter/` (codebase
`flutter`) — **never** extend FlutterFlow's `functions/index.js`.

---

## 0. Where things stand today

What exists:
- Firestore + HTTP Cloud Functions in a single `functions-flutter/index.js` — ping, profile, golden
  habits (flag/form/list), phase-1 state, momentum methods, check-in awards, onboarding sync,
  transcript forge, plus a Cantina DM trigger.
- Working server-side: points ledger, credits ledger, streak state machine, check-in awards.
- Claude agent (Nova): its `award_section` / `forge_golden_habit` tools write the points ledger and Golden
  Habit directly (server-validated, idempotent); the points-ledger watcher drives the in-app celebration.
  Voiceflow is retired (2026-09-19) — see `ADMIN_PANEL_BACKEND_PLAN.md` §6.

What does **not** exist: any remote config, any admin surface, any scheduler, any moderation tooling,
any feature flags, any analytics store, any `timezone` on the profile.

Where the rules currently live — this is the list the plan is aimed at:

| Rule / content | Where it's hard-coded today |
|---|---|
| Credit awards, level multiplier | `functions-flutter/index.js` — `CHECKIN_CREDITS = 10`, `HIGH_SCORE_CREDITS = 5`, `FORMATION_CREDITS = 25`, `CANTINA_WELCOME_CREDITS = 25`, `CREDIT_LEVEL_MULT` |
| Streak milestones + payouts | `index.js` — `STREAK_MILESTONES`, `STREAK_MILESTONE_CREDITS` |
| Planets / world order / colours | `lib/theme/momentum_tokens.dart` — `MM.planets`, read by dashboard, cockpit, journey arc, journey stage |
| Rocket route geometry | `lib/widgets/momentum/journey_stage.dart` (parabolic dx table) |
| Cantina unlock gate | `lib/screens/momentum/phase1_flow.dart` — `stage1Done` |
| Level names / titles | client strings (`momentum_home.dart`, `web_screens.dart`) |
| Starter Ideas Well posts, starter Tribes | `lib/services/cantina_ideas_service.dart`, `lib/services/tribes_service.dart` (seeded client-side on first run) |
| Daily Ritual steps, check-in questions, HHS questions | client screens |
| Core lists templates (Routines / Non-Routines) | client |

Every row above means "ship an app update to change a number".

---

## 1. Game engine / progression rules — *highest value*

**Status:** not started. Moving these server-side means tuning without a release.

- [ ] **#B1 `config/*` remote config tree + client & function loader.**
  One Firestore tree the app reads and caches, with `config/_meta.version` so functions cache
  in-process and re-read on a version bump (not per request). Ships with the **current values as
  defaults**, so day-one behaviour is byte-identical.
  ```
  config/economy    → MP + credits per action (check-in, habit complete, ritual step,
                      Cantina post), multipliers, daily caps
  config/levels     → MP per level, level names/titles, unlock effects
  config/streaks    → what counts as a streak, grace days, break rules, milestone bonuses
  config/unlocks    → phase/stage gates (e.g. Cantina = Phase 1 Stage 2), what exists, what gates it
  config/journey    → worlds: id, name, order, distance/MP required, what moves the rocket
  ```
  *Acceptance:* change a value in Firestore → live in app + functions on the next version bump, no deploy.

- [ ] **#B2 Migrate the existing constants into `config/economy` + `config/streaks`.**
  `CHECKIN_CREDITS`, `HIGH_SCORE_CREDITS`, `FORMATION_CREDITS`, `CANTINA_WELCOME_CREDITS`,
  `CREDIT_LEVEL_MULT`, `STREAK_MILESTONES`, `STREAK_MILESTONE_CREDITS` out of `index.js`.
  *Depends on:* #B1. *Acceptance:* curl-verify a check-in award is unchanged (10💎 + 5💎 high score).

- [ ] **#B3 Move `MM.planets` and the unlock gates to `config/journey` + `config/unlocks`.**
  Client keeps a baked-in default copy for cold start / offline (`Fetched<T>` + `LocalCache`, the
  pattern already used for Habits/Lists/Routines/Dashboard), then prefers the remote copy.
  *Acceptance:* adding a world or changing an MP threshold needs no app build.

- [ ] **#B4 Streak engine reads its rules from config** — grace days, weekday-only vs. any-day,
  break/regression behaviour. *Depends on:* #B1.

- [ ] **#B5 Levels engine server-side.** Thresholds + titles from `config/levels`; emits a level-up
  event; drives the credit multiplier already in the ledger.

---

## 2. Content management (no-code editing)

**Status:** not started. Same `config/` mechanism, different payloads — content rather than rules.

- [ ] **#B6 Habits library** — suggested/starter habits per core (Mindset, Career, Health,
  Relationships, Spirituality). Replaces the client-side suggestion logic in `add_habit_page.dart`.
- [ ] **#B7 Daily Ritual steps** — prompts, order, copy.
- [ ] **#B8 Check-in questions + HHS assessment questions & scoring.**
- [ ] **#B9 Core lists templates** — Routines / Non-Routines starter items.
- [ ] **#B10 Copy & microcopy** — screen text, empty states, celebration messages, so marketing can
  edit without a dev. Keyed strings with a baked-in fallback; never block a render on a fetch.
- [ ] **#B11 Assets** — planet/world art, rocket skins, ship upgrades (the ship-upgrade UI in the doc
  images). Firebase Storage + a manifest doc; client resolves by id with a bundled fallback.
  🔒 Partly blocked on client art (see §9).

---

## 3. AI / Nova control

**Status:** not started.

- [ ] **#B12 Claude agent config as data** — which agent version, per-stage prompts, model choice,
  held in `config/ai` rather than hardcoded in `functions-flutter/index.js` / `hhsSystemPrompt.js`.
- [ ] **#B13 Guardrails** — max messages per session, cost cap per user per period, hard stop +
  graceful message when hit.
- [ ] **#B14 Transcript review** — store and browse conversations in the admin console; flag bad
  answers. (`flutterForgeFromTranscript` already handles transcripts; this is retention + a viewer.)
- [ ] **#B15 Prompt / system-message editing** for the in-app AI chat (`lib/screens/ai_chat_page.dart`,
  `lib/services/chat_service.dart`).
- [ ] 🔒 **#B16 Nova / economy boundary decision.** Nova awards MP *itself* today. If the backend
  becomes the authority on the economy, Nova must call in rather than write directly — otherwise two
  writers and no single source of truth. Client decision, not a build task.

---

## 4. Users & support

**Status:** not started.

- [ ] **#B17 User search + profile view** — HHS scores, current phase/stage, points & credits history,
  streak state, golden habits, check-in calendar.
- [ ] **#B18 Manual adjustments** — grant/deduct MP or credits, reset a stage, unlock a feature for a
  tester, reset onboarding. Every adjustment writes an audit entry (who/when/what/why).
- [ ] **#B19 Suspend / delete account** — including GDPR "delete my data" (Firestore subtrees + Auth
  record + Storage).
- [ ] **#B20 Read-only impersonation view** for support debugging. Read-only by construction, not by
  UI convention.

---

## 5. Community (Cantina) moderation

**Status:** not started. Needed before the social pillars carry real user content.

- [ ] **#B21 Review / remove Ideas Well posts and thread messages**
  (`space_cantina_posts`, the direct-Firestore thread messages).
- [ ] **#B22 Space Tribes admin** — approve, rename, delete.
- [ ] **#B23 Ban / mute users, report queue, banned-word list.**
- [ ] **#B24 Pin / feature content.**
- [ ] **#B25 (later) AI moderation pass** on new posts — classification-shaped, cheap model.

---

## 6. Feature flags & release control

**Status:** not started.

- [ ] **#B26 Flag store + client gate** — turn Cantina, AI chat, web-cockpit sections on/off per
  platform, per cohort, or per % rollout. Firebase Remote Config is a legitimate off-the-shelf answer
  here; only build custom if the cohort logic outgrows it.
- [ ] **#B27 Force-update / maintenance-mode banner.**
- [ ] **#B28 A/B tests** on copy or MP values. *Depends on:* #B1, #B10, #B33.

---

## 7. Notifications & lifecycle

**Status:** not started. Cloud Scheduler → scheduled functions + FCM.
*Depends on:* **#B29 timezone** — nothing time-based is correct without it.

- [ ] **#B29 Add `timezone` to the user profile.** Captured at signup from the device, editable in
  settings. Every scheduled job needs it to know when "yesterday" ended for a given player.
  Small schema change, large blast radius — do it before the scheduler, not after.
- [ ] **#B30 Daily ritual reminder** (timezone-bucketed).
- [ ] **#B31 Streak-about-to-break nudge.**
- [ ] **#B32 Re-engagement after N days inactive.** N from config.
- [ ] **#B32b Scheduled/triggered campaign templates** in the admin console — audience, template,
  schedule, send. Editable copy comes from §2.

---

## 8. Analytics & business

**Status:** not started.

- [ ] **#B33 Event ledger (`events/`) + BigQuery export.** Append-only `{uid, type, payload, ts}`.
  One substrate serving three things: analytics, economy-balance monitoring, and context for any
  future AI feature. Batch writes to keep Firestore cost sane.
- [ ] **#B34 DAU/WAU, retention cohorts, Phase 1 funnel, habit completion rates, drop-off points.**
  Firebase Analytics + BigQuery covers most of this without custom work — build dashboards, not a
  pipeline.
- [ ] **#B35 Economy anomaly report** — earning too fast / too slow, surfaced to the admin console.
  *Depends on:* #B33.
- [ ] 🔒 **#B36 Subscriptions / entitlements** — paid tiers, promo codes, comped accounts.
  Only if and when a paid tier is decided.

---

## 9. Blocked on client content / assets

- [ ] 🔒 **Rocket / ship-upgrade art** — variants + skins for the ship-upgrade UI. Asset production.
- [ ] 🔒 **Vetted habits database** (the 500+ set) — blocks the full #B6 library.
- [ ] 🔒 **Badge library** — names, criteria, rarity per category.
- [x] ~~`handleVoiceflowEvent` secret confirmation~~ — moot: Voiceflow retired 2026-09-19; the app no longer
  reads `vf_events`.

---

## Security — non-negotiable before any of this ships

- [x] **#B37 🔴 Replace the hardcoded shared secret with Firebase ID-token auth — DONE, tracked in
  `ADMIN_PANEL_BACKEND_PLAN.md` §0/§6.** Superseded for admin-facing endpoints by the `admin` custom
  claim + `requireAdmin()` (#A0.1/#A0.3, ID-token-based, deployed and verified). The player-facing
  `flutter*`/default-codebase endpoints keep the shared-secret pattern (`API_SECRET`) by design — they
  authenticate a *client build*, not an admin — but that secret is now in Secret Manager via
  `defineSecret`, not hardcoded in source (#A6.1, deployed + smoke-tested 2026-09-14: correct secret →
  200, wrong/missing → 401). Not a full token-per-player rework — that would be a separate, larger task
  if ever needed; this closes the specific "secret string in the public web bundle" hole.

- [x] **#B38 Admin custom claim + rules path — DONE, tracked in `ADMIN_PANEL_BACKEND_PLAN.md`
  §0 (#A0.1–#A0.4).** `admin: true` custom claim (`scripts/setAdminClaim.js`), `requireAdmin()` server
  gate on every admin endpoint, Firestore rules for `config/*`/`feature_flags/*`/`admin_audit_log/*`,
  and a client-side route guard (`AdminGate`) — all deployed and verified, including the non-admin
  denial path (403 via rules-checked REST, not just the Admin SDK).

---

## Recommendation — don't build all of it

Two things pay for themselves immediately:

1. **Remote config for the game engine** (§1: points, levels, streaks, unlocks) — a single Firestore
   `config/*` tree the app reads and caches. Cheap to build, and it removes the need to ship an app
   update every time a rule changes.
2. **A small admin web app** — a route in the existing Flutter web app reusing `WebShell`, gated by the
   `admin` claim, with **user lookup + manual MP adjustment + Cantina moderation**. Those are the three
   things needed on day one of real users.

Everything else — A/B tests, campaigns, analytics dashboards — comes later, or goes to off-the-shelf:
**Firebase Remote Config** (flags), **Firebase Analytics + BigQuery** (§8), **FCM** (§7) cover a lot
without custom work.

### Suggested order

| Step | Contents |
|---|---|
| 1 | #B37 auth fix + #B38 admin claim & rules *(before anything writable)* |
| 2 | #B1–#B2 config tree + constant migration |
| 3 | Admin shell + #B17 user lookup + #B18 manual adjustment |
| 4 | #B21–#B23 Cantina moderation |
| 5 | #B3–#B5 journey/streak/level rules to config |
| 6 | #B29 timezone → #B30–#B32 scheduled notifications |
| 7 | #B33 event ledger → §8 analytics |
| 8 | §2 content management, §3 AI control, §6 flags |

---

## Source documents

- Feature backlog: `COMPLETION_PLAN.md` (client-side work)
- Traceability: `design/ref/documentation/PROGRESS_AND_TRACEABILITY.md` (+ `.docx`)
- Cantina spec: `design/ref/Space Cantina - Social Component Of The MM System.docx`
- Client spec: `design/ref/Gamification Mechanics Specs Reference (Pre-PRD).docx`
- Old Django app (reference only, **not** a port target): `design/ref/old_app_source/` —
  `notes/GAME_LOOP.md`, `ROCKET_SYSTEM.md`, `ASSET_MAP.md`
- Our functions: `C:\Users\haroon\vf-bridge\functions-flutter\index.js` (codebase `flutter`)
