# Moore Momentum — Admin Panel Backend Plan

> **Resume instructions (for Claude):** this file tracks the **backend work needed to make the Admin
> Panel design real** — the design itself is a static Claude Design export at
> `design/ref/admin-panel-export/Admin Panel.dc.html` (client-approved layout, no backend behind it
> yet). This is a *focused, screen-by-screen* companion to `BACKEND_PLAN.md` (the general backend
> backlog) — every task here maps back to a `#B_` id in that file where one already exists, and gets a
> new `#A_` id where the admin-panel design introduces something `BACKEND_PLAN.md` didn't yet cover.
> To continue: take the lowest unchecked task whose dependencies are met, mark it `[~]`, implement +
> verify, mark `[x]`.

Legend: `[ ]` todo · `[~]` in progress · `[x]` done · 🔒 blocked on client decision/content

**Non-negotiable, blocks every other task in this file:** the admin panel is **admin-accounts only**.
No screen, endpoint, or config write may ship ahead of the gating in §0.

**Flutter UI progress (this file otherwise only tracks backend):** a real, working admin UI now exists
on top of the backend below, built 2026-09-13 and verified in the browser (release web build,
`localhost:8765`) by the client directly:
- `lib/screens/admin/admin_shell.dart` (`AdminShell`) — full-screen takeover matching
  `design/ref/admin-panel-export/Admin Panel.dc.html`'s layout exactly (one sidebar: brand header +
  MONITOR/PEOPLE/PRODUCT/SYSTEM nav groups + account footer). Intercepted at the top of
  `momentum_home.dart`'s `build()` — admin is a different persona from the player app, not another
  screen inside `WebShell`/mobile chrome (three iterations before landing here: nested-inside-WebShell
  squeezed it into a narrow column; a top tab-strip lost the "one sidebar" feel; this full-takeover
  version is what the client confirmed matches). Sections without a real screen yet
  (`kAdminBuiltScreens` = `overview`, `clients`) show an honest "soon" tag + `AdminStubScreen` rather
  than being hidden.
- `lib/screens/admin/admin_overview_screen.dart` — real §1 tiles + recent actions, wired to
  `adminGetOverview` via new `lib/services/admin_api_service.dart` (sends the ID token, not the shared
  secret — separate from `ApiConfig`/ `ProfileService`'s pattern on purpose).
- `lib/screens/admin/admin_clients_screen.dart` + `admin_client_detail_screen.dart` — real §2 Clients
  list/search/filter (client-side at today's ~24-account scale) and Client Detail, with **working**
  action buttons wired to `adminAdjustClient`/`adminClientAccess`: grant/deduct MP or credits, restore
  checkpoint, reset onboarding, suspend/unsuspend, send password reset, force reset, revoke sessions,
  change email — every one requires a reason (enforced client-side too, not just server-side) and hits
  the real backend verified earlier in this file.
- Bulk actions, Export CSV, and Add client are visible per the design but call `adminShowSoon()` — a
  snackbar, not a silent no-op — since their backends don't exist yet (§A2.2/#A2.5's CSV-download
  trigger needs `dart:html`, deferred) or would need scope not yet built.

---

## 0. Access control — build this first, nothing else is safe without it

This is `BACKEND_PLAN.md` **#B37 + #B38**, restated as the literal requirement driving this whole panel:
*"this backend option should only be available for admin accounts."*

- [x] **#A0.1 Admin custom claim.** `vf-bridge/functions-flutter/scripts/setAdminClaim.js` —
  `node scripts/setAdminClaim.js grant|revoke <email>` / `list`, via the Admin SDK
  (`setCustomUserClaims`). **Run** — `will@mooremomentum.com` (uid `DNs29UhFc2ekA1jw0onbo8LtB212`)
  granted 2026-09-12, confirmed via `list`. Auth: a downloaded service-account key +
  `GOOGLE_APPLICATION_CREDENTIALS` (no `gcloud` install needed) — keep that key file outside the repo,
  it's a permanent credential.
- [~] **#A0.2 Route guard on the Flutter side.** `lib/screens/admin/admin_gate.dart` (`AdminGate`) —
  force-refreshes the ID token and checks the **decoded claim** before rendering its child; a bare
  "not authorized" screen otherwise. Wired as the `'admin'` screen key in both the mobile
  (`_buildBody()`) and desktop (`WebShell` switch) branches of `momentum_home.dart`, protecting a
  placeholder `AdminHomePage` (`lib/screens/admin/admin_home_page.dart`). The entry point itself
  (`WebShell`'s sidebar via `kAdminNavItem` / `isAdmin`, and `MenuDrawer`'s "ADMIN" group) only shows
  for accounts where `AdminService.isAdmin()` is true — visibility, not the enforcement; `AdminGate` is
  what actually enforces it, so it re-checks even if a nav item is somehow reached without one showing.
  **Analyzer-clean; the underlying claim now exists (#A0.1) and is proven server-side (#A0.3)**, but
  the Flutter UI itself is not yet browser-verified signed in as an actual admin (needs
  will@mooremomentum.com's password, which isn't something to hand to an agent) — worth a quick manual
  check in the running app: confirm the "Admin" entry appears for that account and not for others.
- [x] **#A0.3 Callable/HTTP function gate.** `functions-flutter/index.js` — `requireAdmin(req, res)`
  verifies `Authorization: Bearer <idToken>` via `admin.auth().verifyIdToken` and requires
  `decoded.admin === true`, 401/403 otherwise. **Deployed** (`flutter:adminPing`,
  `https://us-central1-momentum-bce49.cloudfunctions.net/adminPing`) and **verified end-to-end** with
  real ID tokens: admin claim → `200 {ok:true,...}`; no token → `401 Missing Authorization`; signed-in
  non-admin → `403 Admin claim required`. This is the shared helper every real admin endpoint (§1–§9)
  will call — no other admin endpoints exist yet, that's §1 onward. Supersedes the shared-secret
  pattern (`API_SECRET`) for anything admin-facing; carries over **#B37** (kill the hardcoded secret)
  but scoped to admin endpoints first — the existing `flutter*` endpoints are untouched.
- [x] **#A0.4 Firestore rules for admin-only paths.** Added `isAdmin()` plus `config/*` (signed-in
  read / admin write), `feature_flags/*` (world read / admin write), `admin_audit_log/*` (admin-only,
  create-only — enforces "append-only" at the rules layer per #A9.2) to `vf-bridge/firestore.rules`.
  **Deployed** (`firebase deploy --only firestore:rules`, compiled + released clean) — none of these
  collections have data yet, so this is forward cover for §7/§9, not something protecting live data
  today, but it's live and will apply the moment those collections get their first document.
- [ ] **#A0.5 Sidebar identity block wiring.** The design's sidebar footer shows
  `will@mooremomentum.com · Owner · admin claim` and an env pill (`config v14`) — wire this to the
  real signed-in admin's email/claim and the real `config/_meta.version`, not placeholder text.
- [ ] **#A0.6 2FA + session policy for admin accounts** (design's Access & Passwords page: "Require 2FA
  for admin accounts", "Admin session timeout: 8 hours", "Block admin sign-in outside allowlisted IPs").
  New — not in `BACKEND_PLAN.md`. Firebase Auth multi-factor enrollment for the admin account(s) +ID
  token custom claim carrying issue time for a server-side session-age check. IP allowlist is
  🔒 lower priority — only one admin exists today.

**Acceptance for this whole section:** a non-admin, fully-authenticated app user who navigates to
`/admin` or calls an admin endpoint directly gets nothing — not a read, not a write, not a friendlier
error than "not found."

---

## 1. Overview screen

Design: 5 stat tiles (active clients, checked-in today, avg score, credits spent, habits formed) +
"Recent admin actions" + "Needs attention" panel.

- [x] **#A1.1 Overview aggregation endpoint.** `adminGetOverview` (admin-gated, read-only, GET/POST).
  Every number is derived from real data, with two tiles honestly given **no** sparkline rather than a
  fake one: `activeClients` (total − suspended, via two `count()` aggregations rather than a `!=` query
  — `suspended` is absent on most docs, and Firestore's `!=` silently excludes documents missing the
  field entirely, which would have undercounted almost every real account; caught before deploy) and
  `habitsFormed` (collection-group `count()` on `golden_habits.formed==true`) are current-total-only —
  a real historical trend needs either a daily rollup (no scheduler exists yet) or another composite
  index, not justified for one dashboard tile. `checkedInToday` and `avgScoreToday` get a **real**
  7-day series from the actual `checkins` collection-group (new field-override index, see below).
  `creditsSpent` reuses §9's audit-log index and can currently only mean **admin deductions** — no
  player-facing spending feature exists yet (ship upgrades / skip-day purchases are still
  `[PLACEHOLDER]` per the client's own doc), so a name like "credits spent" would be misleading once a
  real purchase flow ships; that's noted in the endpoint's own comments, not hidden. **New indexes
  needed and deployed:** `checkins.date` + `golden_habits.formed` as collection-group field overrides;
  hit the same "index still building" transient as §9 (worse this time — several minutes, not seconds)
  plus one more real bug: the `creditsSpent` query's implicit ascending sort on `when` didn't match
  §9's existing `action ASC, when DESC` index, so it demanded a second composite index — fixed by adding
  an explicit `.orderBy("when", "desc")` to match the existing index instead of building a new one.
  **Deployed and verified** against real data: 24 active clients, 1 real formed habit, correctly all-zero
  check-in/credits-spent tiles (no real check-ins or admin deductions exist yet — honest, not broken),
  unauthenticated request correctly rejected with 401.
- [x] **#A1.2 "Recent admin actions" feed** — newest 6 rows of the audit log, inline in the same
  response (no separate store, no separate endpoint). Verified: real §7 config/flag publishes showed up
  correctly.
- [x] **#A1.3 "Needs attention" rules.** Deliberately **not invented** — returns `{ items: [],
  needsSpec: true }`, the same stubbed-not-fabricated pattern already used for undesigned economy
  bonuses (`bonusHooks` in `flutterAwardCheckinPoints`). Still needs the threshold decision this task
  was always blocked on before it can be real.

---

## 2. Clients (list) + Client Detail

Design: searchable/filterable client table with bulk actions; detail view with profile fields,
economy stats, and action buttons (grant/deduct MP & credits, restore rocket checkpoint, reset
onboarding).

- [x] **#A2.1 Client search + list endpoint.** `adminListClients` — this **is** `BACKEND_PLAN.md`
  **#B17** (user search + profile view). Paginated (`limit`/`cursor`), plus `format=csv`. Search:
  exact uid → direct doc lookup; contains `@` → exact email match; else a case-sensitive prefix match
  on `displayName`. Filters: `level` (exact, indexed) and `suspended` (exact, indexed — backed by a new
  `suspended` mirror field, set by #A2.6 below). **Known v1 limitation, documented in code and here,
  not silently missing:** the design's Active/Warned/Regressed/Invited status chips are computed
  per-row (`computeClientStatus`, reusing the same streak-state recompute `flutterGetUserProfile`
  uses) and returned on every row, but are **not yet filterable server-side** — that needs a
  materialized status field (a scheduled job or a write-time trigger), which is follow-up work, not
  a blocker for shipping list/search/detail/adjustments today. **Deployed and verified** against the
  real `users` collection (5 real accounts read back correctly, pagination cursor works) and CSV export
  confirmed.
- [ ] **#A2.2 Bulk actions** (design: "Send nudge", "Grant credits", "Assign habit", "Send password
  reset", "Export selected") — **not started.** "Grant credits" and "Export selected" are trivial now
  that the single-client versions exist (loop #A2.4/#A2.1, one audit entry per affected user, not one
  for the batch) — the other three need infrastructure that doesn't exist yet: "Send nudge" needs a
  notification-send path, "Assign habit" needs the Habits Library (§4, not started), "Send password
  reset" needs §3 (also not started). Do the two trivial ones whenever a real admin UI needs them;
  hold the rest until their dependencies land.
- [x] **#A2.3 Client detail read.** `adminGetClientDetail` — profile fields, full economy state
  (points/credits totals + last-10 history from each ledger), golden habits, last-30 check-ins,
  onboarding stage, real Firebase Auth `disabled` state alongside the Firestore `suspended` mirror, and
  `format=csv` for the check-in history. `BACKEND_PLAN.md` **#B17**. **Deployed and verified** on a
  disposable test account exercising every field.
- [x] **#A2.4 Manual adjustments.** `adminAdjustClient` (one endpoint, `action` field distinguishes the
  four) — `grant_points`/`grant_credits` (signed integer delta, writes the same `summary.total` +
  `history` + user-doc-mirror shape `flutterAwardCheckinPoints` uses, tagged `"Admin Adjustment"`),
  `restore_checkpoint` (sets `planet`, validated against the known planet ids — mirrors
  `MM.planets` client-side until #B3 moves it server-side), `reset_onboarding` (clears
  `stage1Progress`/`stage1Completed`/`stage2Completed`/`phase` — does **not** touch golden habits,
  intentionally non-destructive). This is `BACKEND_PLAN.md` **#B18** exactly as designed —
  **`reason` is a required field, rejected with 400 if missing**, and every branch writes one audit
  entry (§9) with real before/after values. **Deployed and verified**: all four actions, plus the
  reason-required guard, confirmed against a disposable test account; the resulting audit entries read
  back correctly via #A9.3.
- [x] **#A2.5 CSV export** (client list + client detail's check-in history) — both live, via
  `format=csv` on `adminListClients` and `adminGetClientDetail` respectively. Verified above.
- [x] **#A2.6 Suspend / unsuspend account** — added as two more `adminAdjustClient` actions:
  `admin.auth().updateUser(uid, { disabled })` + `revokeRefreshTokens` on suspend (so it takes effect
  immediately, not after token expiry), mirrored to a `suspended` boolean on the Firestore doc so
  #A2.1's list filter doesn't need a per-row Auth lookup. **Deployed and verified**: suspend flips real
  `disabled: true` on the Firebase Auth record, unsuspend flips it back. **Full account deletion is
  intentionally NOT built here** — it's `BACKEND_PLAN.md` **#B19** (GDPR-shaped: Firestore subtrees +
  Auth record + Storage, needs its own careful pass), correctly out of scope for this task.

---

## 3. Access & Passwords (per-client actions on the Client Detail page)

Design: "Send password reset link", "Force reset on next sign-in", "Revoke all client sessions",
"Change email on the account."

All four are one endpoint, `adminClientAccess` (`action` field picks the branch), same consolidation
pattern as `adminAdjustClient` in §2 — `reason` required on every call, rejected with 400 if missing.
**Deployed and verified end-to-end** on a disposable test account for all four.

- [x] **#A3.1 Send password reset.** `admin.auth().generatePasswordResetLink()`. No mail-sending infra
  exists in this project, so the endpoint hands back the one-time link (valid 1 hour, Firebase's
  default — matches the design's own note) for the admin to deliver themselves, rather than fabricating
  an email send. **Deliberately not logged in the audit entry** — a live password-reset link sitting in
  a doc admins can read would itself be a way to gain account access; the log only records that one was
  issued. Verified: real link returned, shape matches a Firebase `resetPassword` action URL.
- [x] **#A3.2 Force reset on next sign-in.** No native Firebase Auth flag, so this sets
  `users/{uid}.forcePasswordReset = true` (Firestore, already covered by the existing
  `users/{uid}/{document=**}` owner rule — no rules change needed). Client-side enforcement built too,
  not just the flag: `app.dart`'s `_PostAuthGate` (new, wraps the old inline "signed in → MomentumHome"
  branch) checks the flag once per sign-in and — if set — blocks on a new
  `ForcePasswordResetPage` (`lib/screens/force_password_reset_page.dart`) that calls
  `user.updatePassword()` directly (the player is already signed in) and clears the flag via a new
  `AccessService` (`lib/services/access_service.dart`) on success. Fails open on a read error (offline)
  — this is a UX nudge, not the security boundary, and a network hiccup must never permanently strand a
  player outside the app. `flutter analyze` clean. **Backend verified** (flag set/read via the real
  endpoint + Firestore); **the Flutter screen itself is not yet browser-verified** — needs an account
  with the flag actually set, walked through in a running browser.
- [x] **#A3.3 Revoke all sessions.** `admin.auth().revokeRefreshTokens(uid)`. Verified against a real
  Auth record: `tokensValidAfterTime` measurably advanced after the call.
- [x] **#A3.4 Change email.** `admin.auth().updateUser(uid, { email: newEmail, emailVerified: false })`
  + mirrors the new email onto the Firestore user doc (same mirror-field pattern as points/credits) +
  best-effort `generateEmailVerificationLink()` returned to the admin — this is the "requires
  confirmation from the new address" step the design promises, via the same hand-off-a-link approach as
  #A3.1 rather than a fabricated auto-send. Invalid email format rejected with 400 before touching Auth.
  Verified: bad input rejected, valid change updates both Auth and the Firestore mirror, verification
  link returned.
- [x] All four write an audit entry (§9) — verified in the same run: `admin_send_password_reset`,
  `admin_force_password_reset`, `admin_revoke_sessions`, `admin_change_email` all appeared correctly
  attributed via `adminListAuditLog`.

(Admin-account-level security — 2FA/session timeout/IP allowlist for the *admins themselves*, also
shown on this design page — is tracked in **#A0.6**, not here; don't conflate admin auth hardening
with client account support tools.)

---

## 4. Habits Library

Design: habit template table (core, cadence, difficulty, assigned count, form rate) + "Formation
rules" panel (reads `config/streaks`) + "Habits per core" distribution.

- [x] **#A4.1 Habit template CRUD.** One consolidated endpoint, `adminHabitTemplate` (`action`:
  create/update/duplicate/archive/unarchive — no hard delete, matching the design's grayed-out-row
  treatment for archived items), `reason` required. New `habit_templates/{id}` collection, rules mirror
  `config/*` (signed-in read so the client can adopt it later per **#B6** with no rules change, admin
  write). This *is* `BACKEND_PLAN.md` **#B6**'s content-management half. 🔒 the full 500+ vetted set is
  still blocked on client content per **#B6**/§9 of `BACKEND_PLAN.md` — the CRUD lets an admin seed
  templates incrementally without waiting for that. **Deployed and verified**: create/update/duplicate/
  archive/unarchive all correct with real before/after diffs; bad action, missing reason, and an
  invalid `coreId` all correctly rejected; rules re-verified with real data (signed-in read succeeds,
  non-admin write gets a real 403).
- [x] **#A4.2 Per-template stats** — **honestly stubbed**, not derived: `assignedCount: 0`,
  `formRate: null` on every template, with an explicit `templatesNote` explaining why. Nothing in the
  app assigns a real Golden Habit *from* a template yet — onboarding still forges habits via the
  Voiceflow agent (see §4's header comment in `functions-flutter/index.js`) — so any non-zero number
  here would be fabricated, not measured. Revisit once **#B6**'s client-side wiring actually links a
  forged habit back to the template it came from.
- [x] **#A4.3 Formation rules editor** — confirmed no new backend needed, as the plan predicted: this
  is just a UI on top of `config/streaks`, already built and publishable via `adminSetConfig` (§7).
  `adminListHabitTemplates` (below) bundles a read of `config/streaks` into its response so the future
  screen needs one call, not two.
- [x] **#A4.4 Habits-per-core distribution panel** — real aggregate (not template-linked) via
  `adminListHabitTemplates`: a full `golden_habits` collection-group scan tallied by core, both
  "assigned" (any Golden Habit in that core) and "formed" counts. **Verified against real data**:
  physical 4 assigned/1 formed, relationships 2 assigned/0 formed, matching §1's real `habitsFormed`
  total of 1.

---

## 5. Momentum Lists + List Detail

Design: 3 summary tiles, list-type table (initiated/completed/in-progress/completion rate), a
per-list detail with prompt-level drop-off and a per-player progress table.

**Structural finding, read before touching this section again:** the design's "completed",
"completion rate", and per-prompt funnel all assume each list type has a **fixed, ordered set of
prompts** ("completed" = "every prompt has an entry"). That concept **does not exist** anywhere in the
real schema — confirmed against `MomentumList.fromJson`'s own comment ("no core association or color
metadata stored server-side") and against real production data pulled while verifying this section:
list names include Voiceflow-generated free text like "Core Area", "RELATED CORE DIMENSION", "Bad
habit", "Paint Points" (a typo, still real data) — there is no canonical prompt schema to measure
against. Fabricating a per-list-type target prompt count to make those numbers exist would be a guess,
not a measurement, so **#A5.2 and #A5.3 are not built** — they're blocked on a real schema decision
(e.g. a canonical prompt count per list name, probably belonging in a future `config/lists`), not on
effort. #A5.1 and #A5.4 ship the honest subset of the same design: real counts, no fake completion.

- [x] **#A5.1 Lists analytics rollup.** `adminListMomentumLists` — one row per distinct list type found
  across **both** real stores ([[reference_core_lists_backend]]: `momentum_lists` — free-text, no core
  — and the per-core `golden_habit`/`pain_point` collections, which do have a core), via bare
  (unfiltered) collection-group scans grouped in memory — no new Firestore indexes needed, fine at
  today's scale. Reports `usersWithList`, `initiated` (≥1 item), `avgItems` per list type;
  `completed`/`completionRate` are omitted with the explanatory note above rather than included as
  fake zeros. `format=csv` supported. **Deployed and verified** against real data: 27 distinct list
  types across both stores, correct per-type counts.
- [ ] **#A5.2 "Where players stop" funnel** — not built; see the structural finding above. Needs a
  schema decision first.
- [ ] **#A5.3 Completion-rate-over-time trend** — not built, same reason as #A5.2 (there is no real
  "completion" to trend).
- [x] **#A5.4 List Detail: per-player progress table.** `adminGetListDetail` — same underlying data as
  #A5.1 sliced to one list type (`system`+`name`, plus `coreId`/`categoryId` for the per-core store),
  returns each player's `uid`/`displayName`/`itemCount`/`updatedAt` sorted most-recently-updated first.
  `uid` is handed back specifically so the future UI's "View" deep-links into Client Detail (§2) rather
  than duplicating it — no player-detail logic lives here. `format=csv` supported. Per-prompt answer
  rate is **not** included (same structural finding as #A5.2). **Deployed and verified**: real players
  returned for both a momentum list (4 users) and a per-core list (2 users, correct core filter),
  missing `coreId`/`categoryId` on a `system=core` request correctly rejected with 400.
- [ ] **#A5.5 Edit prompts / Export CSV.** Export CSV is **done** (both endpoints above). "Edit
  prompts" is **not applicable** as designed — there are no prompts to edit (see the structural finding
  above); once a real prompt schema exists this becomes content management parallel to **#B9**.

---

## 6. Integrations (Voiceflow / Nova)

Design: connection card (status, Test connection, Disconnect), a fields grid (Project ID, API key
reveal/rotate, Webhook URL, Nova version + History).

> ## 🔴 STOP — READ BEFORE DEPLOYING EITHER CODEBASE 🔴
>
> **`functions/index.js` (default/FlutterFlow) and `functions-flutter/index.js` are both mid-migration
> and MUST NOT be deployed as-is.** Both now read `API_SECRET` (and `functions/index.js` also
> `VOICEFLOW_API_KEY`) from `process.env` via `defineSecret` + `setGlobalOptions`, with **no hardcoded
> fallback left in source**. **Neither secret exists in Secret Manager yet** — creating them requires
> `firebase functions:secrets:set`, which needs a fresh `firebase login --reauth` that was interrupted
> (session expired) before it could run.
>
> **If you deploy either codebase before creating both secrets, every endpoint that calls `verifyKey()`
> will break for all real users** — `process.env.API_SECRET` will be `undefined`, so no client's shared
> secret will ever match. This is the single highest-blast-radius mistake available in this whole repo
> right now.
>
> **To finish this safely, in order:**
> 1. `firebase login --reauth` (interactive — needs a human at a browser).
> 2. `printf 'haroon786' | firebase functions:secrets:set API_SECRET --data-file -`
> 3. `printf 'VF.DM.68ba671716fd4f8038045f07.UfjyDEP2qGVIU7gM' | firebase functions:secrets:set VOICEFLOW_API_KEY --data-file -`
> 4. Only then: `firebase deploy --only functions` (both codebases — `setGlobalOptions` changed every
>    function's deploy spec in each file, so expect every function in both codebases to redeploy, not
>    just the ones touched this session).
> 5. Immediately smoke-test a real secret-gated endpoint from each codebase (e.g. `flutterGetUserProfile`
>    with the real secret) to confirm `verifyKey` still passes before considering this done.
>
> Until step 4 runs, **production is completely unaffected** — the currently-deployed functions still
> have the old hardcoded secrets baked in from their last real deploy. The risk is entirely in
> deploying the *local* edit before the secrets exist, not in leaving it as-is.

- [~] **#A6.1 🔴 Move the Voiceflow API key + the `handleVoiceflowEvent` shared secret out of source
  into Secret Manager**, exposed to this screen only via a masked read + an explicit "Reveal · rotate"
  action that itself requires the admin claim (**#A0.3**) and writes an audit entry. Same spirit as
  `BACKEND_PLAN.md` **#B37**, applied to the Voiceflow secret specifically. **Code written in both
  `functions/index.js` (touches the FlutterFlow-owned default codebase — explicitly confirmed with the
  client first, since this breaks the project's own "never touch index.js" rule, as a one-time
  exception scoped to this security fix) and `functions-flutter/index.js`. Not deployed — see the STOP
  box above.** The "reveal · rotate" admin-facing endpoint itself is not built yet either — do that
  after the secrets exist and the deploy is verified safe, not before.
- [ ] **#A6.2 "Test connection" action** — a real round-trip health check against the Voiceflow API
  (not a static "Connected" badge), surfacing the same failure the app would hit.
- [ ] **#A6.3 Nova version + history** — read whichever field currently records the published agent
  version; "History" needs a small version-log doc if one doesn't exist yet. Ties into
  `BACKEND_PLAN.md` **#B12** (agent config as data) and **#B14** (transcript review) if this page grows
  into full AI control rather than a status card.
- [ ] **#A6.4 Disconnect** — 🔒 confirm with the client what "Disconnect" should actually do (stop
  awarding points from Voiceflow events? block new conversations?) before wiring it — don't guess a
  destructive action's semantics.

---

## 7. Economy (config editor) + Feature Flags

Design: a `config/*` tree browser (economy / streaks / journey / planets / levels), editable
key-value rows with dirty-state tracking, "Preview diff" / "Publish v{n}", and a change-history panel.
Feature Flags: per-flag platform/cohort/rollout-% table plus two named kill switches
(`maintenance_mode`, `force_update`).

**Critical scoping note, read before touching this section again:** `config/economy` +
`config/streaks` back the *live* reward math in `flutterAwardCheckinPoints` — real users' real check-in
points/credits. Everything below except **#A7.2 is built, deployed, and safe**, because nothing reads
from `config/*` yet — it's live, tested infrastructure with zero consumers, not a partial feature.
**#A7.2 is the one piece that changes that**, and it's explicitly *not done* — it gets its own pass
with its own curl-verification that awards are byte-identical before/after, per `BACKEND_PLAN.md`
**#B2**'s own acceptance test. Do not casually wire it in as a side effect of another task.

- [~] **#A7.1 The `config/*` tree itself** — this is `BACKEND_PLAN.md` **#B1** (the design literally
  names `config/economy`, `config/journey`, `config/levels`, `config/streaks`). **Done: the tree,
  seeding, and the versioned editor.** `config/economy` / `streaks` / `levels` / `journey` are seeded
  with values **byte-identical to today's hardcoded constants** in `functions-flutter/index.js`
  (`CHECKIN_CREDITS`, `HIGH_SCORE_CREDITS`, `FORMATION_CREDITS`, `CANTINA_WELCOME_CREDITS`,
  `CREDIT_LEVEL_MULT`, `STREAK_MILESTONES`/`STREAK_MILESTONE_CREDITS`, plus the streak qualification
  rule — weekday-only, 4.0+ average, 1-weekday grace, 2-weekday break — which existed only as inline
  logic before, never as named constants). `config/levels.mpThresholds` and each planet's `mpRequired`
  in `config/journey` are left `null` — those are still `[PLACEHOLDER — DETAIL NEEDED]` per the client's
  own Gamification doc (BACKEND_PLAN.md §13b/13c), so nothing is fabricated. **Marked `[~]` not `[x]`**
  because the other half of #B1 — the app and Cloud Functions actually *reading* this tree at runtime,
  with the in-process cache keyed off `config/_meta.version` — doesn't exist yet; that's #A7.2's job.
- [ ] **#A7.2 Migrate the hardcoded constants** — `BACKEND_PLAN.md` **#B2**. Still open, on purpose (see
  the scoping note above). Needs: an in-process config loader/cache in `functions-flutter/index.js`
  keyed off `config/_meta.version`; `flutterAwardCheckinPoints` reading amounts from it instead of the
  hardcoded constants; a client-side loader with a baked-in fallback (same `Fetched<T>`/`LocalCache`
  pattern already used for Habits/Lists/Routines/Dashboard) so cold start/offline still works.
  *Acceptance test (from BACKEND_PLAN.md):* curl a check-in award before and after wiring — must still
  be 10💎 + 5💎 high score, unchanged.
- [x] **#A7.3 Dirty-state + Preview diff + Publish flow.** `adminSetConfig` (admin-gated, POST,
  `reason` required) — merges a shallow patch into one `config/{path}` doc, bumps
  `config/_meta.version` on every publish, returns the before/after diff of just the changed keys. Dirty
  state and Preview-diff are UI-only concerns (the edited-but-unpublished values live in the future
  admin screen's local state until Publish is clicked) — no backend change needed for those.
  **Deployed and verified**: publishing a real change (v5→v6) produced the correct before/after diff;
  bad `path` and missing `reason` both correctly rejected with 400.
- [x] **#A7.4 Change history panel** — reuses the audit log (§9) rather than a bespoke history
  collection: every `adminSetConfig` publish writes an `admin_publish_config` entry with the version
  number and the real diff. **Verified**: all 6 seed/test publishes appeared correctly in
  `adminListAuditLog`.
- [x] **#A7.5 Planets editor** (`config/journey.planets`) — seeded with the 6 real planets (id, name,
  order, color) mirrored from `lib/theme/momentum_tokens.dart` `MM.planets`; `mpRequired` left `null`
  per the scoping note above (undesigned, **#B3**).
- [x] **#A7.6 Feature flag store.** Plain Firestore (`feature_flags/{key}`, rules from §0: world-read,
  admin-write) via the same `adminSetFeatureFlag` endpoint used for the kill switches below — the
  build-vs-buy question from `BACKEND_PLAN.md` **#B26** (Firebase Remote Config might cover per-%
  rollout natively) is **not re-litigated here**, just noted as still open; this ships the simplest
  thing consistent with how the rest of this admin panel already talks to Firestore directly, not a
  final call that Remote Config is wrong.
- [x] **#A7.7 Kill switches** — `maintenance_mode` and `force_update` (+ `minVersion`) seeded as
  `feature_flags` docs, both `enabled: false` (byte-identical to today's actual behavior — the app has
  no maintenance-mode or force-update check today, so "disabled" is the truthful default, not a guess).
  **Verified**: signed-out read succeeds (world-readable), a signed-in non-admin's write attempt against
  the real Firestore rules (not the Admin SDK, which bypasses rules) got a real `403`.

---

## 8. Content (copy/microcopy editor)

Design: section tree, key/value table with per-row state + "Publish content", live phone preview.

- [ ] **#A8.1 Copy store** — `BACKEND_PLAN.md` **#B10** (keyed strings, baked-in client fallback, never
  block a render on a fetch). Same versioned-publish shape as §7's config editor — likely worth sharing
  the publish/version-history mechanism (#A7.3/#A7.4) rather than building it twice.
- [ ] **#A8.2 Live preview pane** — purely a client-side rendering of the selected key against the
  phone-frame mock already in the design; no new backend, just needs the copy key → screen-context
  mapping to know what to preview.

---

## 9. Audit Log

Design: filterable (action type, admin, date range) append-only table, "1–10 of 1,486 · append-only,
never edited", export.

- [x] **#A9.1 `admin_audit_log` collection.** `writeAuditLog({ adminUid, adminEmail, action, target,
  reason, before, after })` in `functions-flutter/index.js` — the one shared writer every admin
  mutation (§0–§8) should call rather than each section inventing its own log; this is the concrete
  backing store for `BACKEND_PLAN.md` **#B18**'s "every adjustment writes an audit entry" requirement.
  Already wired into the one sensitive action that exists today: `scripts/setAdminClaim.js` writes a
  `grant_admin_claim` / `revoke_admin_claim` entry on every run (attributed to the service-account
  email, since a CLI script has no Firebase Auth uid of its own), with an optional `--reason` flag.
  **Deployed and verified** — granting will@mooremomentum.com's claim produced a real entry, read back
  correctly by #A9.3 below.
- [x] **#A9.2 Enforce append-only at the rules layer.** `admin_audit_log/*` in `firestore.rules`:
  `create` allowed for admin claim, `read` admin-only, `update`/`delete` always `false` — the design's
  own copy ("never edited") is a rule, not a UI convention. **Deployed and verified**: an authenticated
  admin's ID token, used against the *rules-checked* Firestore REST API (not the Admin SDK, which
  bypasses rules), got `403` on both an update and a delete attempt against a real log entry.
- [x] **#A9.3 Filtered/paginated read + CSV export.** New `adminListAuditLog` endpoint (admin-gated via
  **#A0.3**) — `limit`/`cursor` pagination, `action`/`adminUid` exact-match filters, `since`/`until`
  range on `when`, `format=csv` for a download (matches the design's filter bar: action type, admin,
  date range, "Export log"). Needed two composite Firestore indexes (`action`+`when`,
  `adminUid`+`when` — added to `firestore.indexes.json`); first calls 500'd with
  `FAILED_PRECONDITION: index is currently building`, resolved once the (near-instant, tiny-collection)
  build finished. **Deployed and verified**: plain read, both filters, and the CSV export all returned
  the real logged entry correctly.

---

## 10. Analytics

Design: economy-anomaly banner, DAU/WAU chart, retention cohort grid, Phase-1 funnel, habit-completion-
by-core bars, MP/credits issued-vs-spent chart.

This screen is the UI for `BACKEND_PLAN.md` **§8** in full:

- [ ] **#A10.1 Event ledger** — **#B33** (`events/` append-only `{uid, type, payload, ts}` +
  BigQuery export). Everything else on this screen either reads this or Firebase Analytics directly.
- [ ] **#A10.2 DAU/WAU, retention cohorts, Phase-1 funnel** — **#B34**; per `BACKEND_PLAN.md`'s own
  recommendation, prefer Firebase Analytics + BigQuery dashboards over custom pipelines here.
- [ ] **#A10.3 Economy anomaly banner** — **#B35**, now with a concrete trigger shown in the design
  ("credits earned 2.3× faster than baseline since config v13") — i.e. the anomaly detector should be
  able to correlate a spike with a specific `config` version from #A7.3's version history.
- [ ] **#A10.4 Habit completion by core, MP/credits issued vs. spent** — derivable from the existing
  points/credits ledgers without waiting on **#B33**; can ship before the full event ledger.

---

## 11. Cantina (moderation)

Design section starts at line 936 of the export (tribe approve/watch/pending states, thread list) —
this is `BACKEND_PLAN.md` **§5** in full: **#B21** (review/remove posts & threads), **#B22** (tribe
admin), **#B23** (ban/mute/report queue), **#B24** (pin/feature). No new ids — build straight from
`BACKEND_PLAN.md`; this section exists here only so the panel's screen list has an owner for every
sidebar item.

---

## Suggested build order

Unchanged in spirit from `BACKEND_PLAN.md`'s recommendation, resequenced around *this* panel:

| Step | Contents |
|---|---|
| 1 | §0 access control (**#A0.1–#A0.6**) — nothing else ships before this |
| 2 | §2 Clients + Client Detail + §3 Access & Passwords (**#B17/#B18/#B19** + new client-support actions) |
| 3 | §9 Audit log store (**#A9.1–3**) — build before §2's actions ship, so day-one adjustments are already logged |
| 4 | §7 Economy config editor + Feature flags (**#B1/#B2/#B26/#B27** + versioning **#A7.3/4**) |
| 5 | §1 Overview (depends on §9 for "recent actions" and §7/§10 for "needs attention") |
| 6 | §4 Habits Library, §5 Momentum Lists (content + analytics, mostly additive) |
| 7 | §11 Cantina moderation (**#B21–24**) |
| 8 | §6 Integrations hardening (**#A6.1** secret migration can move earlier if the Voiceflow secret issue is urgent) |
| 9 | §10 Analytics / event ledger (**#B33–35**), §8 Content editor (**#B10**) |

---

## Source documents

- General backend backlog (superset of most tasks here): `BACKEND_PLAN.md`
- Client-side feature backlog: `COMPLETION_PLAN.md`
- Traceability of what's already built: `design/ref/documentation/PROGRESS_AND_TRACEABILITY.md`
- **This panel's design source:** `design/ref/admin-panel-export/Admin Panel.dc.html` +
  `design/ref/admin-panel-export/support.js` (Claude Design canvas export — static, no backend wired)
- Cantina spec: `design/ref/Space Cantina - Social Component Of The MM System.docx`
- Our functions: `C:\Users\haroon\vf-bridge\functions-flutter\index.js` (codebase `flutter` — admin
  endpoints belong here too, per the existing backend-isolation rule; consider splitting them into
  their own file within this codebase, e.g. `admin.js`, once the endpoint count grows, but keep them
  out of FlutterFlow's `functions/index.js`)
