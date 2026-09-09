# Claude Design brief — Moore Momentum Backend & Admin Console

**How to use this file:** in Claude Code run `/design` and paste this whole file as the prompt
(or say: *"use the brief in `backend_claude_design.md`"*). It produces a multi-artboard canvas you
can pan, zoom and edit by hand. Source of truth for the content: `BACKEND_PLAN.md` in this repo.

---

## Goal

Visualise the backend/admin layer described in `BACKEND_PLAN.md` **before any of it is built** —
so I can see the shape of the admin console and decide what's worth building first.

This is a mockup of an internal tool, not the player-facing app. It must feel like it belongs to
Moore Momentum (same dark space theme), but it is dense, data-first, and desktop-only —
no marketing polish, no hero sections, no rounded-friendly onboarding cards.

Audience: me (the founder/operator) plus one support person. Assume a 1440×900 desktop.

---

## Design system — match the existing app

The real app's tokens live in `lib/theme/momentum_tokens.dart`. Use these exactly.

**Colour**
| Token | Hex | Use |
|---|---|---|
| `pageBg` | `#06070D` | canvas background |
| `panel` | `#131A3D` | card / panel fill |
| `navy` | `#111C4E` | secondary surface, table header |
| `navy2` | `#0A1136` | sidebar fill |
| `blue` | `#2A7DE1` | primary action, Mindset core |
| `red` | `#EA0029` | destructive, alerts, streak fire |
| `teal` | `#00A98F` | success, Physical core |
| `yellow` | `#FFC629` | achievements, Career core, "unsaved changes" |
| `magenta` | `#FF3D8B` | Relationships core |
| `violet` | `#9B5CFF` | Emotional core |
| `white` | `#F1F1F1` | primary text |
| white 60% / 36% / 18% | — | secondary text / tertiary text / hairline borders |

**Type**
- Display / headings: **Orbitron**, 700–800, uppercase, letter-spacing ~0.05em
- Body & UI: **Red Hat Display**, 400/600, 13px base
- All numbers, ids, config values, timestamps: **JetBrains Mono**, tabular figures

**Surface style** — the app calls these glass panels: `#131A3D` at ~85% opacity, 1px `rgba(255,255,255,0.18)`
border, 12px radius, subtle outer glow in the accent colour when a panel is active.
⚠️ Borders must be **uniform** — never a heavier border on one side only (that's a real rendering
bug we hit in the app).

**Planets** (used in the journey config artboard, in this order):
Earth `#3AA6FF` · Moon `#CFD2DC` · Mars `#D76B3A` · Jupiter `#D9A86B` · Saturn `#E8C178` · Pluto `#9AA3C7`

**Density rules for this tool:** 8px grid, 32px row height in tables, no illustration, no emoji in
chrome (💎 for credits is fine inline), icons are thin-line outline only.

---

## Canvas layout

Lay the artboards on one canvas in two rows, left to right in this order. Label each artboard with
its number and the `BACKEND_PLAN.md` section it maps to.

**Row 1 — the ones I actually need to see (build these first):**
1. System map
2. Admin shell + overview
3. Economy tuner
4. Player inspector
5. Cantina moderation

**Row 2 — supporting (lower fidelity is fine):**
6. Content library editor
7. Feature flags & rollout
8. Analytics
9. Build roadmap board

---

## 1 — System map *(architecture, not a screen)*

A single diagram artboard, ~1600×1000. Show how the pieces connect **today vs. after the plan**,
with the new pieces visually distinct (solid = exists, dashed + yellow = to build).

Nodes:
- **Clients** — Flutter Web (primary), Android/iOS (secondary)
- **Cloud Functions** `vf-bridge/functions-flutter` (codebase `flutter`) — the only place new
  functions go; never FlutterFlow's `functions/index.js` (show that one greyed out and fenced off)
- **Firestore** — `users/{uid}` (+ `points`, `credits`, `phase1`, golden habits), `space_cantina_posts`,
  `vf_events/{uid}`, and the **new** `config/*` tree
- **Voiceflow / Nova** — currently writes MP *directly* via `updateUserPoints`. Draw this as a red
  double-headed arrow labelled **"two writers — unresolved"** (§3 #B16 in the plan).
- **New:** Cloud Scheduler → scheduled functions → FCM · `events/` ledger → BigQuery · Admin console
- **Gate:** draw the `admin: true` custom claim + Firestore rules as an explicit checkpoint every
  admin write passes through. This should be impossible to miss in the diagram.

Also mark the security hole in red on the client→functions edge:
`API_SECRET = "haroon786"` shipped in the public web bundle → to be replaced by Firebase ID-token auth.

---

## 2 — Admin shell + overview

The chrome every other admin screen sits in. Reuses the app's `WebShell` pattern:
**left sidebar (240px) + topbar + content area.**

- Sidebar on `#0A1136`: wordmark at top, then nav — Overview · Economy · Players · Cantina ·
  Content · Flags · Notifications · Analytics · Audit log. Active item: blue left-edge bar + glow.
  Bottom of sidebar: signed-in admin, environment pill (**PROD** in red / **DEV** in teal).
- Topbar: page title, global search ("search a user by email or uid"), and a config-version chip
  reading `config v14 · published 2h ago`.
- Overview content: a row of 5 stat tiles (DAU, check-ins today, MP awarded today, credits spent
  today, new signups) then two panels — "Recent admin actions" (audit trail rows) and
  "Needs attention" (3 reported Cantina posts · economy anomaly flag · 2 users pending deletion).

Every stat tile shows a value + a 7-day sparkline + delta. Use the mono font for the numbers.

---

## 3 — Economy tuner *(the screen I'd use most)*

Editing `config/*` — this is the whole point of the plan, so give it the most detail.

Left: a tree of config docs — `economy` · `levels` · `streaks` · `unlocks` · `journey` · `ai`.
Right: a form for the selected doc.

Show `config/economy` selected, with these **real current values** as the seeded defaults:

| Key | Current | Notes column |
|---|---|---|
| `CHECKIN_CREDITS` | `10` | completed weekday check-in |
| `HIGH_SCORE_CREDITS` | `5` | any core scored 5/5 |
| `FORMATION_CREDITS` | `25` | habit reaching the Trophy Room |
| `CANTINA_WELCOME_CREDITS` | `25` | first Cantina post |
| `CREDIT_LEVEL_MULT` | `cadet 1 · navigator 1.25 · commander 1.5` | multiplier by level |

Each editable row: label, mono value input, an inline "was `10`" diff marker in yellow when changed,
and a revert arrow. Two rows should be shown in a dirty/edited state so the diff treatment is visible.

Bottom bar (sticky): `3 changes` · **Preview diff** · **Publish** (blue, primary) — publishing writes
a new version and bumps `config/_meta.version`. Next to it, a caption:
*"Live in the app on the next version bump — no deploy, no app update."*

Include a right-hand rail: **Change history** — who / when / what changed, last 5 entries.

Also show a small collapsed preview of `config/journey` beneath: the six planets in order as coloured
chips with an MP-required field each, so it's clear world order and thresholds become data.

---

## 4 — Player inspector

Support's day-one screen. Search result → one user.

- Header: avatar initial, display name, email, uid (mono, copyable), signup date, timezone
  (flag this field as **new** — it doesn't exist yet), current level pill (Cadet/Navigator/Commander),
  current planet chip, streak count with flame.
- Tabs: **Overview · Points & Credits · Check-ins · Habits · Phase 1 · Cantina · Audit**
- Overview tab content: HHS scores as a 5-core bar row using the core colours; a 12-week check-in
  heatmap calendar; golden habits list with formed/forming state.
- Right rail: **Manual adjustment** panel — grant/deduct MP, grant/deduct credits, reset a stage,
  unlock a feature, reset onboarding. Each with a **required reason field** and a warning that every
  action is written to the audit trail. Destructive items (suspend, GDPR delete) sit in a separate
  red-bordered group at the bottom.

---

## 5 — Cantina moderation

A queue, not a browser. Two columns: **Reports (6)** on the left, selected item detail on the right.

- Report rows: post excerpt, author, tribe, reason, reporter count, age.
- Detail pane: full post, author's history strip (posts / prior removals / joined date),
  and actions — **Remove post · Warn author · Mute 7d · Ban · Dismiss report**.
- A secondary tab bar for **Ideas Well · Threads · Tribes**. Under Tribes: rows with approve /
  rename / delete, plus a member count.
- Somewhere visible: a banned-word list chip group with an "+ add" affordance.

Anti-shame note that must show in the UI: removal messaging to the user is supportive, never punitive
— show the drafted notice text in a small preview card next to the Remove action.

---

## 6 — Content library editor

Lower fidelity. A two-pane editor over the content that's hard-coded in the client today:
Habits library (per core) · Daily Ritual steps · Check-in questions · HHS questions & scoring ·
Core list templates · Copy & microcopy · Assets.

Show the **Copy & microcopy** pane selected: a searchable key/value table
(`empty.habits.title`, `celebration.levelup.body`, …) with a live phone-shaped preview on the right
showing the string in context. Mark two entries as overridden from default.

---

## 7 — Feature flags & rollout

A table of flags: Cantina · AI chat · Web cockpit sections · Ship upgrades.
Per row: on/off per platform (web / android / ios), cohort selector, a % rollout slider with the
current value, and last-changed-by. Plus two special rows styled distinctly: **Maintenance mode**
and **Force update** (with a minimum-version field).

---

## 8 — Analytics

Dashboard of what the event ledger unlocks. Keep charts calm and consistent — one accent per series,
no rainbow. Panels: DAU/WAU line · retention cohort grid · **Phase 1 funnel** (bar-drop: signup →
HHS → Stage 1 → golden habit → Stage 2 → Cantina unlock) · habit completion rate by core (5 bars in
core colours) · MP & credits issued vs. spent over time, with an **economy anomaly** banner
("earning 2.3× faster than baseline") sitting above it.

---

## 9 — Build roadmap board

The plan itself as a board so I can see sequence and size at a glance. Eight columns matching
`BACKEND_PLAN.md`'s suggested order:

1. Security — ID-token auth (#B37) + admin claim & rules (#B38) ← *gates everything*
2. Config tree + constant migration (#B1–#B2)
3. Admin shell + user lookup + manual adjustment (#B17–#B18)
4. Cantina moderation (#B21–#B23)
5. Journey / streak / level rules to config (#B3–#B5)
6. Timezone (#B29) → scheduled notifications (#B30–#B32)
7. Event ledger (#B33) → analytics
8. Content management · AI control · flags

Cards carry the `#Bxx` id and a one-line title. Colour the column headers: red for step 1
(non-negotiable), blue for 2–4 (the recommendation: *build these two things first*), white-36% for
5–8 (later). Mark 🔒 cards (client art, habits DB, badge library, Nova/economy boundary decision)
with a lock and a muted treatment in a separate "Blocked on client" lane at the bottom.

---

## What I want out of it

Real-looking density over polish. Every screen should be populated with plausible data — no lorem,
no empty tables. If a number is unknown, use the seeded default from `BACKEND_PLAN.md` rather than
inventing something. I should be able to look at artboard 3 and 4 and decide *"yes, that's the two
things worth building first"* — or that they're wrong.
