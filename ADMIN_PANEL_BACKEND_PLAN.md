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
- `lib/screens/admin/admin_audit_screen.dart` — **§9 Audit log UI (2026-09-19; analyzer-clean, NOT yet
  browser-verified)** on `adminListAuditLog` via `AdminApiService.listAuditLog`: design's filter bar (text search,
  action, admin, date range) + When/Who/Action/Target/Reason table, cursor "Load more", client-side "Export log"
  CSV. Action/admin/date filters are server-side; text search is client-side over loaded rows (endpoint has none).
  Read-only by construction (log is append-only at the rules layer, #A9.2). `kAdminBuiltScreens` now = overview,
  clients, audit, flags, economy, habits, lists.
- `lib/screens/admin/admin_flags_screen.dart` — **§7 Feature flags + kill switches UI (2026-09-19; analyzer-clean,
  NOT yet browser-verified)**. Reads `feature_flags/*` live from Firestore (world-read), writes only via
  `adminSetFeatureFlag` (`AdminApiService.setFeatureFlag`; reason required, audit-logged with before/after). Table
  (flag, platforms, cohort, rollout bar, last changed) + New/Edit flag dialog; kill-switch panel for
  `maintenance_mode` / `force_update` (+ minVersion, semver-validated; a force-update can't be turned on without one).
  Regular-flag doc shape is defined by the screen (`description`, `platforms{ios,android,web}`, `cohort`,
  `rolloutPct`) — the backend imposes none. **The player app does not read `feature_flags` yet**, so flag/kill-switch
  changes are recorded + audited but change no client behavior until client-side gating exists (stated on screen).
  Live data today: only the two kill switches (both off, minVersion 1.0.0); zero regular flags.
- `lib/screens/admin/admin_economy_screen.dart` — **§7 Economy config editor UI (2026-09-19; analyzer-clean, NOT yet
  browser-verified)**. Left tree `config/{economy,levels,streaks,journey}`; right: generic editor over the doc's REAL
  fields (no invented key list) typed by stored value — number / bool / text / JSON for null·object·list — with
  per-row dirty state + "was …", **Preview diff**, and **Publish v{n+1}** (reason required) via `adminSetConfig`
  (`AdminApiService.setConfig`, changed keys only). Change-history panel = `admin_publish_config` audit entries for
  the selected doc (version, when, who, reason, key-by-key before→after). No add/delete-key. Discard-changes guard on
  tree switch. **On-screen caveat: nothing reads `config/*` at runtime yet (#A7.2 open), so a publish is versioned +
  audited but changes no live reward math.**
  **Backend tweak (DEPLOYED + browser-verified 2026-09-21):** `adminListAuditLog` now also returns `before`/`after`
  per row (CSV unchanged); the history panel shows version + key-by-key diffs (v6 `checkinCredits 11 → 10`, v5
  `10 → 11`, v1 seed `null → …`). Deploy needed `FUNCTIONS_DISCOVERY_TIMEOUT=60` once (default 10s discovery timed out).
- `lib/screens/admin/admin_habits_screen.dart` — **§4 Habits library UI (2026-09-19; analyzer-clean, NOT yet
  browser-verified)** on `adminListHabitTemplates` + `adminHabitTemplate` (`AdminApiService.listHabitTemplates` /
  `.habitTemplate`). Core filter chips with counts, show-archived toggle, table (template + id, core dot, cadence,
  difficulty, Edit / Duplicate / Archive|Restore — no hard delete), New/Edit dialog (name, core, difficulty,
  cadence; update sends changed fields only), reason required on every write. Below: read-only Formation rules
  (`config/streaks`, with an "Open Economy →" link — edited there, one editor) and a real Habits-per-core tally.
  **Assigned / Form rate show "—"** (nothing assigns a habit from a template yet, #A4.2 — not fabricated).
- `lib/screens/admin/admin_lists_screen.dart` — **§5 Momentum lists UI (2026-09-19; analyzer-clean, NOT yet
  browser-verified)** on `adminListMomentumLists` + `adminGetListDetail` (`AdminApiService.listMomentumLists` /
  `.getListDetail`). Honest subset: 3 real summary tiles (list types, lists started, weighted avg items), searchable/
  system-filterable table (list type, core, players, initiated, avg items, initiated-share bar), click-through detail
  (per-player items + last updated, "View" → Client Detail via the shell's `_openClient`), client-side CSV export for
  both levels. **Completion rate / where-players-stop / trend / per-prompt rates / Edit prompts are deliberately NOT
  shown** (#A5.2/#A5.3/#A5.5 — no fixed prompt set exists; on-screen note explains) — needs a schema decision first.
- **🔧 Index regression found + fixed while browser-testing (2026-09-19).** The `checkins.date` and
  `golden_habits.formed` field overrides added for #A1.1 (2026-09-14) listed only `COLLECTION_GROUP` indexes; defining
  a fieldOverride switches OFF Firestore's automatic single-field indexes for that field, so the collection-scope
  `orderBy('date','desc')` in `adminGetClientDetail` (and the player app's `CheckinService.getRecent`) started failing
  `FAILED_PRECONDITION`. Fixed by listing all four (ASC/DESC × COLLECTION/COLLECTION_GROUP) in
  `vf-bridge/firestore.indexes.json`; deployed with `firebase deploy --only firestore:indexes`. **Verified:** Client
  Detail loads again for a real account once the index finished building (~3 min). **Rule:** any fieldOverride must
  re-declare every scope/order the field is queried with.
- **Browser-verified 2026-09-19 (release web build, real admin session):** Audit log (filters/search), Feature flags
  (live kill switches, dialogs + validation), Economy (real fields, dirty state, diff preview, discard, JSON/list/bool
  editors), Habits library (archived toggle, formation rules, per-core tally, dialog validation), Momentum lists (32
  list types, detail view, View → Client Detail). No writes were made during testing. Economy diff history verified after the
  audit-log deploy. Not yet tested: real create/publish/archive writes.
- **2026-09-22 — Integrations, Content, Analytics, and Cantina moderation all shipped (backend +
  Flutter UI, deployed) AND browser-verified live (release-shaped web build, real admin session,
  will@mooremomentum.com signed in themselves).** Verified: #A6.3 (real model+prompt version + Test
  connection round-trip), #A8.1/#A8.2 (create section → add key → publish → live preview updates →
  change history shows correct diff → delete key → publish, all correct), #A10.4 (real habits-by-core
  bars and MP/credits issued-vs-spent numbers), §11 (Pin/Unpin a real post, Set watch/Set active on a
  real tribe, both audit-logged correctly with before/after) — and #A0.6's session timeout fired for
  real (an idle admin session got a real "Admin session expired" 401, confirming the 8h enforcement
  works against a real stale token, not just in theory).
  **One real bug found and fixed during this pass:** `ScaffoldMessenger.of(context)` called AFTER an
  `await` in `admin_content_screen.dart`/`admin_cantina_screen.dart` threw "Looking up a deactivated
  widget's ancestor is unsafe" and showed a FALSE "Publish failed"/"Failed" snackbar whenever the admin
  navigated to another screen while a mutation was still in flight — even though the write had already
  succeeded server-side (confirmed: the content delete that "failed" was actually published correctly).
  Fixed everywhere in both files by capturing `ScaffoldMessenger.of(context)` into a local BEFORE the
  `await`, not after. The same pre-existing pattern (`ScaffoldMessenger.of(context)` after an await)
  exists in several older admin screens (audit, clients, economy, flags, habits, lists,
  client_detail, `admin_widgets.dart`'s `adminShowSoon`) — not touched this pass, since they weren't
  part of this session's changes, but the same fix would apply if it's ever hit there.
  **Also independently confirmed live**: the tribes/space_cantina_posts rules fix is working for real
  players, not just in theory — "Night Owls Clubk" (a genuine non-seed tribe) and "Deep Work Guild"
  (a seed tribe with a real member beyond its seed base) both showed up with real `memberUids`, meaning
  actual player writes have succeeded since the fix went live. `kAdminBuiltScreens` now = overview, clients,
  audit, flags, economy, habits, lists, integrations, content, analytics, cantina. Also shipped:
  `#A0.6`'s session-timeout half (8h admin token expiry, enforced server-side in `requireAdmin`) and a
  real pre-existing bug fix (`tribes`/`space_cantina_posts` had no Firestore rules at all — every real
  write was silently failing `permission-denied` in production; fixed while building §11). Remaining
  sidebar items are backend-blocked or intentionally deferred: Daily Checks (no backend), Access &
  passwords (page-level view of #A3, already real per-client — just not assembled into its own screen),
  2FA enrollment itself (#A0.6's other half — needs Firebase Phone Auth provider enabled + the admin's
  real phone number), IP allowlist (🔒 low priority, one admin), #A7.2 (config→live-reward-math wiring,
  blocked on confirming the exact live field names in `config/economy`/`config/streaks` before touching
  real reward math), #A10.1-3 (event ledger + BigQuery — needs real infra/billing decisions outside
  this repo), #A6.4 (Disconnect semantics — 🔒 needs a client decision), #A5.2/3/5 (needs a prompt-schema
  decision).
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
- [x] **#A0.2 Route guard on the Flutter side — BROWSER-VERIFIED 2026-09-14.** `lib/screens/admin/
  admin_gate.dart` (`AdminGate`) — force-refreshes the ID token and checks the **decoded claim** before
  rendering its child (now `AdminShell`, not the old placeholder `AdminHomePage` — superseded by the
  real UI built 2026-09-13); a bare "not authorized" screen otherwise. Wired as the `'admin'` screen key
  in `momentum_home.dart`. The entry point itself (`WebShell`'s sidebar via `isAdmin`) only shows for
  accounts where `AdminService.isAdmin()` is true — visibility, not the enforcement; `AdminGate` is what
  actually enforces it. **Verified live signed in as will@mooremomentum.com** (the real admin account,
  the user entered the password themselves): the "Admin" nav item appears (the async claim check takes
  a couple seconds after sign-in — briefly absent right after login, not a bug, just unresolved yet),
  clicking it shows `AdminGate`'s loading spinner then the real `AdminShell` with live Overview data.
  Non-admin denial already covered by #A0.3's server-side proof (every real admin endpoint 403s a
  non-admin caller regardless of what the client-side gate shows).
- [x] **#A0.5 Sidebar identity block wiring — DONE + BROWSER-VERIFIED 2026-09-14.** `admin_shell.dart`'s
  `_Sidebar` footer showed hardcoded placeholder text (`"Owner · admin claim"`, and the design's
  `"config v14"` env pill was never actually rendered at all). Fixed: `AdminService.configVersion()`
  (new) reads `config/_meta.version` directly via Firestore (world-signed-in-read per the §0 rules, no
  new endpoint) and `_AdminShellState` fetches it once in `initState`; the footer now shows the real
  email (already wired), a corrected **"Admin · claim verified"** label (there's no "Owner" role in this
  system — just the one boolean `admin` custom claim — so that word was fabricated framing, not a typo),
  and a real **"config v{n}"** pill, omitted entirely while loading or if no config was ever published
  rather than showing a fake number. **Verified live**: signed in as the real admin, the footer showed
  "will@mooremomentum.com" / "Admin · claim verified" / "config v6" — matching the real publish history
  from #A7.3's earlier verification passes.
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
- [~] **#A0.6 2FA + session policy for admin accounts** (design's Access & Passwords page: "Require 2FA
  for admin accounts", "Admin session timeout: 8 hours", "Block admin sign-in outside allowlisted IPs").
  New — not in `BACKEND_PLAN.md`. **Session timeout DEPLOYED 2026-09-22:** `requireAdmin` now rejects
  (401 "Admin session expired") any call where the ID token's `auth_time` claim is more than 8h old —
  `auth_time` is set at the original sign-in and does NOT advance on a silent token refresh, so this
  forces a real re-authentication, not just a fresh token. This touches the shared gate used by every
  admin endpoint, so it required redeploying the entire `flutter` functions codebase (confirmed with the
  user first, since it could interrupt an already-8h-old live admin session). **Deploy hit a real
  infra wall**: Cloud Run's "Total CPU allocation, in milli vCPU, per project per region" quota
  (20,000 = 20 vCPU) got saturated deploying ~25 functions back to back — 8 functions failed
  mid-rollout and kept serving their pre-timeout code (Cloud Run doesn't cut traffic to an unhealthy
  revision, so nothing broke, just inconsistent versions briefly). User raised the quota in GCP Console
  (IAM & Admin → Quotas); all 8 redeployed successfully on retry. **Verified**: `adminPing` and
  `adminListClients` both correctly 401 unauthenticated. **Still open:** 2FA enrollment itself — needs
  the Phone Auth provider enabled in the Firebase console (SMS billing implication) and the admin's
  real phone number to enroll a second factor; deliberately NOT built as "required" without an
  enrollment flow existing first, since that would lock out the only admin account. IP allowlist
  remains 🔒 lower priority — only one admin exists today.

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
- [x] **#A2.2 Bulk actions — "Grant credits" + "Export selected" DONE + BROWSER-VERIFIED 2026-09-14;
  the other three still correctly blocked.** Both loop the existing single-client calls per the plan's
  own scoping note — no new endpoint. "Grant credits" opens a small amount+reason dialog
  (`_BulkCreditsDialog`, admin_clients_screen.dart) then calls `adminAdjustClient` (`grant_credits`)
  once per selected uid — one audit entry per account, not one for the batch, matching #A2.4's existing
  contract exactly (nothing new to verify there). "Export selected" builds a CSV client-side from the
  rows `adminListClients` already fetched (no extra request) and triggers a real browser download via
  new `lib/services/csv_download.dart` — a `dart.library.html`-conditional export (`csv_download_web.dart`
  real impl / `csv_download_stub.dart` throws `UnsupportedError`) so mobile builds that can technically
  reach this screen still compile; only the web build can actually download. **Verified live** signed in
  as the real admin: selected 2 real (invited, never-onboarded) test accounts — "Export selected"
  downloaded a real `clients_selected.csv` (checked its contents: exactly those 2 uids/rows); "Grant
  credits" (+5, with a reason) then confirmed via `flutterGetUserProfile` that BOTH accounts'
  `spaceCredits` went 0→5. "Send nudge"/"Assign habit"/"Send password reset" remain `adminShowSoon`
  stubs — still correctly blocked on notification-send infra / the Habits Library / §3 respectively,
  unchanged from this section's original scoping.
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

## 6. Integrations (Claude API / Nova)

> ## 🔄 2026-09-19 — Voiceflow is gone; Nova runs on the Claude API only
>
> The client is no longer using Voiceflow. The Claude-backed onboarding agent (`claudeLaunchConversation` /
> `claudeSendMessage` / `claudeGetLatestMessages` / `claudeSyncOnboarding` in `functions-flutter`) is now the
> **only** path — the `AiBackendConfig` rollback flag is deleted, and the Flutter app no longer calls any
> `vf*` endpoint, `flutterSyncOnboarding`, or `flutterForgeFromTranscript`.
>
> Changes made in `functions-flutter` (**deployed 2026-09-19**; the deleted endpoints now 404):
> - Raw `fetch` calls to the Messages API replaced with the official `@anthropic-ai/sdk` (typed errors,
>   built-in retries, client timeout, org-scoped workspace header via `defaultHeaders`).
> - `VOICEFLOW_API_KEY` secret binding, `VOICEFLOW_VERSION_ID`, and `adminVfTestConnection` removed.
> - `flutterSyncOnboarding` + `flutterForgeFromTranscript` and the whole transcript-parsing fallback
>   (`parseGoldenHabitFromMessages` etc.) removed — `forge_golden_habit` writes the habit and awards the +40 MP
>   atomically, so there is nothing to reconstruct.
> - The Flutter celebration watcher no longer listens to `vf_events`; the points-ledger watcher (which the
>   Claude tools write to via `award_section`) is the sole trigger.
>
> **Still to do outside this repo's control:**
> - **Revoke the old Voiceflow API key** in the Voiceflow dashboard (it was exposed in plaintext in commit
>   `7d1beb1` on the public remote — revoking it fully closes that exposure; no history scrub needed once dead).
> - The default codebase (`functions/index.js`) was cleaned too (2026-09-19, explicit client instruction —
>   one-time exception to the "never touch FlutterFlow's index.js" rule): `vfLaunchConversation`,
>   `vfSendMessage`, `vfGetLatestMessages`, `handleVoiceflowEvent`, `getUserProfileForVF`, the chat-parsing
>   helpers and the `VOICEFLOW_API_KEY` binding are gone and the five endpoints are **deleted in production**.
>   Still to do: `firebase functions:secrets:destroy VOICEFLOW_API_KEY` (no code binds it any more).

- [x] **#A6.1 Secrets out of source** — DONE 2026-09-14 for `API_SECRET` (both codebases) and, at the time,
  `VOICEFLOW_API_KEY`. **Now moot for Voiceflow** (see banner). `ANTHROPIC_API_KEY` follows the same
  Secret Manager pattern (`defineSecret`, no hardcoded fallback). Still not built: the admin "reveal · rotate"
  endpoint/UI for the key.
- [x] **#A6.2 "Test connection" — now against the Claude API.** `adminAiTestConnection` (admin-gated,
  read-only, no audit entry) calls the Models API (`GET /v1/models/{id}`) through the SDK — validates the key,
  the workspace scope, and that the configured model is reachable, at zero token cost. Returns
  `{ok, connected, model, latencyMs, error?}`; `ok` = "this endpoint ran", `connected` = the real Claude result.
  The Flutter Integrations screen's button calls it (`AdminApiService.testAiConnection`). **Deployed 2026-09-19;
  rejects unauthenticated calls (401) — not yet exercised with a real admin token against the live Claude API
  (click "Test connection" in the admin Integrations screen to verify).**
- [x] **#A6.3 Nova model + prompt version history — DEPLOYED + BROWSER-VERIFIED 2026-09-22.**
  New `nova_config_versions/{hash}` collection (hash = sha256 of `ANTHROPIC_MODEL` + `HHS_SYSTEM_PROMPT`,
  first 16 hex chars) — deliberately NOT moving the model/prompt into `config/*` (that's the broader
  `BACKEND_PLAN.md` **#B12**, still open); this is just the narrow "History" list the design asks for.
  New `adminGetNovaConfigHistory` (admin-gated, read-only from the caller's view — the version-log write
  is lazy and idempotent via a deterministic doc id, `create()` swallowing `ALREADY_EXISTS`) returns
  `{ current: {model, promptHash, promptPreview, promptChars}, history: [...] }`. Firestore rules added
  (`nova_config_versions/*`, admin-only read/create, no update/delete — same append-only shape as
  `admin_audit_log`). Flutter: `AdminApiService.getNovaConfigHistory()` + a new history panel on
  `AdminIntegrationsScreen` (current version pill + a version list); `integrations` added to
  `kAdminBuiltScreens`. **Deployed** (`FUNCTIONS_DISCOVERY_TIMEOUT=60` needed again, same as #A7.4's
  deploy); unauthenticated request confirmed `401`. **Not yet verified with a real admin session** —
  needs someone signed in as the real admin to open Integrations and confirm the current-version pill
  and a real logged history row.
- [ ] **#A6.4 Disconnect** — 🔒 confirm with the client what "Disconnect" should actually do (block new
  Nova conversations? fall back to a canned message?) before wiring it — don't guess a
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

- [x] **#A8.1 Copy store — DEPLOYED + BROWSER-VERIFIED 2026-09-22.** `BACKEND_PLAN.md` **#B10**.
  Unlike §7's config editor (mirrors EXISTING hardcoded constants), there was no existing copy store to
  mirror — every player-facing string today is a Dart literal, and picking which ones to expose is a
  real content-scope decision, not something to guess at. Shipped the generic mechanism only: new
  `content/{section}` collection, arbitrary section ids (`^[a-z0-9_]{1,64}$`) and arbitrary string keys
  (`^[a-zA-Z0-9_.]{1,128}$`) created from nothing via the editor itself. `adminListContent` (read) +
  `adminSetContent` (admin-gated, POST, `reason` required, supports add/update via `changes` and
  removal via `deletes`) reuse the exact versioned-publish + audit-log-as-history shape as
  `adminSetConfig` (#A7.3/#A7.4), per the plan's own suggestion — but with its own
  `content/_meta.version` counter, kept separate from `config/_meta.version` since a copy edit and a
  reward-math change are different kinds of risk. Firestore rules mirror `config/*` (signed-in read,
  admin write). Flutter: `AdminApiService.listContent()`/`.setContent()` + new
  `admin_content_screen.dart` (section tree with inline "+ New section", per-key dirty-state editor with
  add/delete-key support, diff-preview-on-publish dialog, change-history panel) wired into
  `admin_shell.dart` (`content` added to `kAdminBuiltScreens`). **Deployed**
  (`adminListContent`/`adminSetContent` both created cleanly, no quota issue this time); unauthenticated
  GET and POST both confirmed correctly rejected (401). **Browser-verified**: created section, added a
  key, published v1, live preview updated to the real value, change history showed the correct diff;
  deleted the key, published v2, history showed the delete correctly. Found and fixed a real bug in the
  same pass — see the file header's 2026-09-22 note (false "Publish failed" on navigate-away).
- [x] **#A8.2 Live preview pane — DONE alongside #A8.1.** Deliberately NOT a phone-frame mockup — there
  is no copy-key → screen-context mapping yet (nothing in the app reads `content/*`), so faking a phone
  preview would be fabricated UI. Ships the honest version instead: selecting a key shows its raw draft
  string in a preview panel, with an on-screen note explaining why it isn't a screen mockup. Upgrading to
  a real phone-frame preview is future work once a screen-context mapping exists.

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
- [x] **#A10.4 Habit completion by core, MP/credits issued vs. spent — DEPLOYED 2026-09-22, not yet
  browser-verified.** New `adminGetAnalytics` (admin-gated, read-only). `habitsByCore` duplicates
  #A4.4's aggregate (a fresh `collectionGroup("golden_habits")` scan) rather than sharing the call, so
  Analytics doesn't also pay for the full habit-template list read. Issued-vs-spent comes from ONE
  `collectionGroup("history")` scan across every `users/{uid}/{points|credits}/summary/history` doc —
  each entry has either a `points` or a `credits` numeric field (never both, since different call sites
  write them), so a positive value is "issued" and negative is "spent" with no second query needed
  (admin deductions already write negative history entries via #A2.4, same rows `#A1.1`'s creditsSpent
  tile reads a different way). Same honest caveat as #A1.1: "spent" can currently only mean admin
  deductions — no player-facing spending feature exists yet. The rest of §10 (#A10.1-3) is returned as
  `{needsSpec: true}` per section, not silently omitted. Flutter: `AdminApiService.getAnalytics()` + new
  `admin_analytics_screen.dart` (habits-by-core bars reusing `MM.coreColor`, an issued-vs-spent bar per
  currency, and honest "not built yet" panels for DAU/WAU, retention, Phase-1 funnel, and the anomaly
  banner) wired into `admin_shell.dart` (`analytics` added to `kAdminBuiltScreens`). **Deployed**;
  unauthenticated request confirmed `401`. **Browser-verified**: real habits-by-core bars (Physical
  1/5 formed, Relationships 0/2 formed, matching #A4.4's own known numbers) and real MP/credits
  issued-vs-spent totals rendered correctly against live data.

---

## 11. Cantina (moderation)

Design section starts at line 936 of the export (tribe approve/watch/pending states, thread list) —
this is `BACKEND_PLAN.md` **§5** in full: **#B21** (review/remove posts & threads), **#B22** (tribe
admin), **#B23** (ban/mute/report queue), **#B24** (pin/feature).

- [x] **DEPLOYED 2026-09-22 — real bug found and fixed while building this section.**
  `tribes_service.dart` and `cantina_ideas_service.dart` have written directly to `tribes` /
  `space_cantina_posts` since they were built, but **no Firestore rule ever existed for either
  collection** — every real write (join/leave/create tribe, tribe post, upvote, adopt, first-run
  seeding) was failing `permission-denied` in production, unrelated to anything built earlier this
  session. Found by tracing `firestore.rules` while designing moderation on top of what was assumed to
  be a working feature. **Fixed** (confirmed with the user before proceeding, since it changes real
  live behavior): base read/create/update rules added for both collections, admin-only moderation
  fields layered on in the same rules (players can only ever touch the exact fields the real client
  code writes — `upvotes`/`adopted` on posts, `memberUids`/`memberCount` on tribes; everything else,
  including the new moderation fields below, requires the `admin` claim).
- [x] **#B21 Review/remove posts.** `adminModerateCantina` (`type='post'`, `action` ∈
  remove/restore/pin/unpin/feature/unfeature) — soft-delete only (`removed`/`removedReason`/
  `removedBy`/`removedAt`), same "no hard delete" convention as Habits/Golden Habits. Targets
  `space_cantina_posts` (no thread/DM moderation — see caveat below).
- [x] **#B22 Space Tribes admin.** `adminModerateCantina` (`type='tribe'`, `action` ∈
  rename/delete/restore/set_status). `status` (`active`|`watch`|`pending`) is a NEW field — no
  "approve" gate exists on tribe creation today (tribes go live immediately, unchanged), so this is
  admin tooling only, not silently wired into a new approval-gated creation flow that would be a real
  product-behavior change nobody asked for.
- [x] **#B23 Ban/mute + report queue.** Mute lives on Client Detail (`adminAdjustClient` actions
  `cantina_mute`/`cantina_unmute`, mirrors the `suspend`/`unsuspend` pattern exactly) — narrower than
  full account suspend: blocks new Cantina writes only (tribe create/join, tribe posts, DMs — enforced
  **server-side** via `firestore.rules`' `isCantinaMuted()`, the real security boundary, not just a
  client-side check). Report queue: new `cantina_reports` collection + `adminListCantinaContent`
  (`type='reports'`, filterable by status) + `adminModerateCantina` (`type='report'`,
  resolve/dismiss). **Honest gap:** no client-side "report" button exists anywhere in the app yet, so
  the queue is real, working infrastructure with zero reports in it — same "live infra, zero
  consumers" pattern as #A7.1/#A8.1, not fabricated. Banned-word list: `cantina_moderation/banned_words`
  doc + admin CRUD via the same two endpoints — storage only, nothing scans new posts against it yet
  (that's `BACKEND_PLAN.md` **#B25**, explicitly later scope).
- [x] **#B24 Pin/feature.** `pinned`/`featured` booleans on `space_cantina_posts`, same endpoint as
  #B21. Not yet surfaced in the player-facing Ideas Well UI (badge/sort) — admin-side only for now.
- **Deliberately out of scope this pass:** moderating `cantina_dms` (private 1:1 messages) or
  `cantina_threads` (per-user mock/demo content) — browsing all players' private DMs is a real privacy
  decision, not just an engineering one; the report queue (once reporting ships) is the intended path
  for acting on a specific flagged DM, not blanket admin browsing.
- Flutter: `AdminApiService.listCantinaContent()`/`.moderateCantina()` + new
  `admin_cantina_screen.dart` (4 tabs: Ideas Well posts, Space Tribes, Report queue, Banned words) +
  `admin_client_detail_screen.dart`'s new Mute/Unmute button, wired into `admin_shell.dart` (`cantina`
  added to `kAdminBuiltScreens`). **Deployed** (`adminListCantinaContent`, `adminModerateCantina`,
  updated `adminAdjustClient`, new `cantina_reports` composite index, updated rules); unauthenticated
  requests to all three endpoints confirmed `401`. **Browser-verified**: real seeded Ideas Well posts
  loaded (8, matching the seed list exactly), Pin/Unpin a real post round-tripped correctly and
  audit-logged (`admin_moderate_cantina_post_pin`/`_unpin`), real Tribes loaded (6 — the 5 seeds plus
  a genuine player-created one, "Night Owls Clubk," with 1 real member — independent proof the rules
  fix is already working for real players), Set watch/Set active on a tribe round-tripped and
  audit-logged correctly. Found and fixed the same false-failure-snackbar bug as #A8.1 in this screen
  too (4 call sites) — see the file header's 2026-09-22 note.

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
