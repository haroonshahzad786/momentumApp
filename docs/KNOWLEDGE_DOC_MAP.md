# Moore Momentum — Knowledge Doc Map

**Prepared by:** Haroon (Developer) · **For:** Will Moore · **Last updated:** 30 Sep 2026

**What this is:** Will, this map covers the documents in your **MASTER** folder. For each document it
shows what I built from it in the app, so you can see *which doc each feature came from* and *which
docs I haven't used yet*.

- **How to read the references:** every file name below is written exactly as it appears in the MASTER
  folder. Files inside a sub-folder show the folder first, e.g. `DOCS SHARED W- HAROON TO UPDATED PRD-FINALIZE APP / …`.
- **More detail:** *Moore Momentum - Build Progress & Traceability - From Haroon.docx* (in `DOCS SHARED W- HAROON TO UPDATED PRD-FINALIZE APP`)
  quotes the exact passage from your docs and shows a screenshot for each feature.
- **Task numbers** (#1, #2 …) are the numbers I use in my build plan and weekly reports.
- **Updates:** I add a new entry to section 6 at the end of each week.

---

## 1. Your MASTER docs → what I built from them

Listed in the order I follow when two docs disagree. The newest scope wins, and the Gamification spec
wins on game mechanics.

| # | Document in MASTER | What it feeds in the app | Tasks |
|---|---|---|---|
| 1 | **Gamification Mechanics Specs Reference (Pre-PRD).docx** · *what the app is tested against* | Momentum Points and how they're scored, streaks and milestones, missed check-ins (Ship Warning / Relaunch), Vacation Mode and Streak Savers, Space Credits earning, Trophy Room and habit formation (14 days / 80%), formation goals, Core Balance alert rules, Profile rank | #9, #10, #11, #12, #13a, #13g, #15, #16, #17, #18, #19 |
| 2 | **10K VIEW OF THE MM SYSTEM (…).docx** + **HOW GAMIFICATION, AI, AND SCIENCE_PRINCIPLES ARE WOVEN INTO THE MM SYSTEM.docx** | What's in the MVP vs post-MVP: Leveling, planet mechanics, ship upgrades, Mystery Box and badges moved to post-MVP | Scope for #15–#42 |
| 3 | **DOCS SHARED W- HAROON TO UPDATED PRD-FINALIZE APP / PHASE 1 AND 2 SEQUENCE (SIMPLEST INCL. PLAYER FACING WALKTHROUGH VERSION FOR CODERS).docx** | The player-facing flow: onboarding stages, the Daily Ritual order, Command Center and Momentum Lists, Tasks, the "Return to Phase 1" bridge | #1, #2, #3, #4, #5, #14 |
| 4 | **DOCS SHARED W- HAROON TO UPDATED PRD-FINALIZE APP / PHASE 1 AND PHASE 2 DETAILS (condensed).docx** | Core unlocking (Cores stay grey until the first habit), Golden Habit View (the per-Core Habits screen with each Golden Habit's details), Step 0 Mantra & Grateful List, Progress Summary numbers, the 5-day "Core out of balance" alert | #2, #5, #6, #8, Golden Habit screens |
| 5 | **PRD - Product Requirements Doc (Formerly the _ISSUES AND FEATURES DETAILED VERSION_ Doc).docx** | Rocket Dashboard layout (streak bar, stats box, rocket nose icons), All Habits view (By Time / By Core), habit colour key 🔴🟠⚫🟢🔵🌟, Non-Routines list with IF-THEN, Captain's Log prompts, Balance %, Vacation Mode 7-day limit | #15, #17, #18, #20, #21 |
| 6 | **Scope v2.docx** | Only used for *suggested* numbers where the Gamification spec says "placeholder". None are final; each one needs your OK first. | Suggested defaults in the open-questions list |
| 7 | **Haroon Calls and meetings.docx** (our call notes + your decisions) | Momentum Points mode (fixed +10 or scaled by scores), planet route (5 by default, up to 8), Cantina stays in-app for MVP, admin 2FA parked | #41, #42 |
| 8 | **Product Design Rationale.docx** | *Why* both the AI and the player flag Cores in Mission Control, and why Core Balance is enforced | #7, #8 |
| 9 | **DOCS SHARED W- HAROON TO UPDATED PRD-FINALIZE APP / Space Cantina - Social Component Of The MM System.docx** | Cantina unlock rule (after Phase 1 Stage 2), the 4 pillars, MVP/V1/V2 rollout, no-shame rules: Ideas Well, Space Tribes, Accountability Partners, Cantina messaging | #4, #14 (Cantina V1) |
| 10 | **MM Build Guide.docx** (80-feature MVP spec) | Checklist to make sure no MVP feature was missed; gaps were added to my build plan (BG-F items) | Cross-check, BG-F items |
| 11 | **DOCS SHARED W- HAROON TO UPDATED PRD-FINALIZE APP / MM Build Tracker.xlsx** | The Balance % formula (item C.10) | #18 |
| 12 | **AI-First Prioritized Implementation Guide.docx** | Capturing behaviour data (marked "never cut") | #33 (planned) |
| 13 | **Issues, Open Questions, & Potential Features.docx** | The list of open questions I sent you | Open questions |
| 14 | **Images inside the docs above** | Cockpit status bar with 💎 Space Credits, the ship-upgrade screen, the skip-check-in screen | #13g, 13h (waiting on you) |

## 2. MASTER docs I read but haven't built from

These are older, replaced by a newer doc, or about business rather than the app. Nothing in the app
comes from them yet.

| Document or folder in MASTER | Why it isn't driving work |
|---|---|
| **More detailed and Original MM System Docs (Created Nov 2025 before switched to less doc method)** (whole folder) | Older versions; replaced by the current docs above |
| **Original-Archived Docs-Notes / Copy of ISSUES AND FEATURES (DETAILED VERSION) TO ADDRESS WITH PHASE 1 AND 2_.docx** | Replaced by the PRD |
| **Original Notes for Issues To Address, Features To Develop, Questions, Etc** (whole folder) | Early notes; their content is now in the PRD |
| **No Code-Vibe Coding Docs** (whole folder) | Written for the FlutterFlow / no-code build; the app is now plain Flutter |
| **MM WIREFRAME GENERATION MASTER GUIDE.docx** | Nov 2025 wireframe guide; the newer designs replaced it |
| **MM 3 Month Master Plan (Original before went to 5 docs instead of 9)_.docx** | Older plan |
| **Additional MM System Master Project Documents** (Calendar Integration, Video Library, Alternate Versions) | Not in the MVP yet. Calendar integration is waiting on your decision. |
| **AI-FIRST STRATEGY & DATA LEARNING GUIDE (UPDATED).docx** · **VALIDATION AND TESTING PROTOCOL (…).docx** · **MVP Scope Audit for the PRD (Features Catalog)_.docx** | Read for context; the features they list are tracked through the PRD and the Build Guide |
| **Investment Thesis and Market Positioning (…).docx** · **Competition Updated (…).docx** · **KEY DIFFERENTIATORS (Moat) OF THE MM SYSTEM.docx** | Business docs, not app features |
| **_MAIN KNOWLEDGE DOCS NAVIGATION GUIDE (…).docx** · **_MM SYSTEM MASTER NAVIGATION GUIDE (…).docx** · **_PRIORITIZED WILL_S TO-DOS TO BUILD MM SOFTWARE.docx** | Guides to the doc set; used to find my way around it |

## 3. Other sources (outside MASTER)

| Source | What it feeds |
|---|---|
| **Admin panel design** (the approved Claude Design export) | Every admin screen: Clients, Client Detail, Audit log, Feature flags, Economy, Habits library, Lists, Integrations, Content, Analytics, Cantina moderation |
| **Rocket Journey prototype** (the approved `Rocket Journey.html`) | The curved flight path between planets on the Cockpit |
| **Your change requests** (Aug 2026) | Co-Pilot console text on the cockpit screen, the points celebration |
| **Product direction** (Jul 2026) | Web / desktop is the main product; the desktop layout is designed separately from mobile |

---

## 4. Feature → doc → where to find it in the app

Use this table when testing: it shows where each feature came from and how to reach it in the app.

- **Web** = the desktop browser. Screens are in the **left sidebar** (Cockpit, Routines, Habits, Tasks,
  Lists, Cantina, Trophy); **Profile** is under your avatar and **Daily Check-in →** is in the top bar.
- **Phone** = the phone layout. Use the **≡ menu** (Dashboard, Journey Map, Daily Check-in, Today's Recap,
  Lists, Routines, Habits, Tasks, Cantina, Trophy Room, Profile) or the **bottom bar** (Habits, Cantina,
  Trophy, Profile).
- *"Only when…"* means the feature appears only in that situation, so use a test account set up that way.

| Feature built | Main doc(s) in MASTER | Where to find it in the app |
|---|---|---|
| #1 Save Phase 1 progress | PHASE 1 AND 2 SEQUENCE · PHASE 1 AND PHASE 2 DETAILS (condensed) | Phone: ≡ → **Foundation Hub**. Leave mid-stage and come back: you resume where you stopped. |
| #2 Cores unlock progressively | PHASE 1 AND 2 SEQUENCE · PHASE 1 AND PHASE 2 DETAILS (condensed) | **Cockpit** rocket: Cores without a habit are grey. Tap a grey Core → **Fuel this Core** opens Stage 1. |
| #3 Stage 1 onboarding with Nova (AI) | PHASE 1 AND 2 SEQUENCE · Gamification Mechanics Specs (Phase 1, Stage 1) | New account → **Foundation Hub → Stage 1** chat with Nova. Or tap a grey Core on the Cockpit. |
| #4 Stage 2 + Cantina unlock | PHASE 1 AND 2 SEQUENCE · Gamification Mechanics Specs · Space Cantina | **Foundation Hub → Stage 2**. After finishing it, **Cantina** unlocks in the sidebar / bottom bar. |
| #5 Daily Ritual Step 0 (Mantra & Gratitude) | PHASE 1 AND PHASE 2 DETAILS (condensed) | **Daily Check-in →**; the first screen is Mantra & Grateful List (optional, can be skipped). |
| #6 Progress Summary real numbers | PHASE 1 AND PHASE 2 DETAILS (condensed) · Gamification Mechanics Specs (Balance Meter) | Finish a **Daily Check-in** → the summary screen. Phone: ≡ → **Today's Recap**. |
| #7 Mission Control flags + AI auto-flag | Product Design Rationale | **Daily Check-in**: an amber "⚠ Mission Control · Nova" alert. *Only when* a Core has scored 3 or below in 3 check-ins in a row. |
| #8 Core Balance 5-day alert | PHASE 1 AND PHASE 2 DETAILS (condensed) | ⚠️ next to a Core in the **Daily Check-in** / progress gauges; tap it for the iCore Alert. *Only when* a Core has been low for 5 days. |
| #9 Momentum Points | Gamification Mechanics Specs | **Cockpit** stats box → Momentum Score. Points celebration after each check-in. |
| #10 Streaks | Gamification Mechanics Specs §6 | **Cockpit** streak bar across the top (phone: top bar). |
| #11 Trophy Room | Gamification Mechanics Specs §8 | Sidebar / bottom bar → **Trophy**. |
| #12 Profile | Gamification Mechanics Specs §2 | Web: avatar → **Profile**. Phone: bottom bar → **Profile**. |
| #13a Space Credits · #13g Credits on the dashboard | Gamification Mechanics Specs · images in the docs | **Cockpit** stats box → 💎 Space Credits. |
| #14 Momentum Lists | PHASE 1 AND 2 SEQUENCE (Command Center) | Sidebar / ≡ → **Lists**. Tap a list to open and edit it. |
| #14 Tasks | PHASE 1 AND 2 SEQUENCE (Command Center) | Sidebar / ≡ → **Tasks**. |
| #14 Cantina V1 (Ideas Well, Tribes, Partners, messaging) | Space Cantina - Social Component Of The MM System | Sidebar / bottom bar → **Cantina** (tabs for each pillar). *Only after* Stage 2 is complete. |
| #15 Captain's Log | Gamification Mechanics Specs §6–7 · PRD 12.C | Write: **Daily Check-in** → 🏆 Wins / 📚 Lessons boxes under each Core. Read back: **Lists** → "Captain's Log · last 30 days". |
| #16 Missed check-ins (Ship Warning / Relaunch) | Gamification Mechanics Specs §6 | **Cockpit**: Ship Warning banner *only when* 1 weekday is missed; Relaunch screen *only when* 2+ are missed. |
| #17 Vacation Mode + Streak Savers | Gamification Mechanics Specs §6 · PRD | Web: **Cockpit** → "Streak Protection" card. Phone: tap the streak in the top bar. |
| #18 Core Balance completion + Balance % | Gamification Mechanics Specs §10 · PRD §14 · MM Build Tracker C.10 | **Cockpit** stats box → Balance %. Also on **Profile**. iCore Alert → **🤖 Get AI Help**. |
| #19 Trophy Room completion (goals, AI check, reviews) | Gamification Mechanics Specs §8 | **Trophy** → Habit Formation Goal card (set a goal), formed habits and their 30/60/90-day reviews. |
| #20 Rocket Dashboard | PRD §12.10 | **Cockpit**: streak bar, stats box and the 3 icons on the rocket's nose. The first visit each day starts zoomed out. |
| #21 All Habits view | PRD §11 | **Cockpit** → the centre **∞** icon on the rocket's nose. Toggle **By Time / By Core**. |
| #21 Colour key | PRD §11 | **Routines** (rocket's 🕒 clock icon or sidebar) → web: tap a habit line; phone: open the habit's edit sheet. |
| #21 Non-Routines list | PRD §11 | **Cockpit** → the ☑ checklist icon on the rocket's nose. Drag habits to reorder. |
| #41 Points mode · #42 Planet route | Haroon Calls and meetings (your decisions, 25 Sep) | Admin account → sidebar **Admin → Economy** → "Momentum Points per check-in" and "Planet route" cards. |
| Admin panel | Admin panel design (outside MASTER) | Admin account → sidebar **Admin** (only shown to admins). |

---

## 5. Still to build: your decision

Will, these are the features in your docs that aren't built yet. Please mark the **Need it?** column
(**Yes** / **No** / **Later**) so I only build what you actually want and we agree the order in advance.

- **Status:** *Ready* = I can build it now. *Needs your input* = I need numbers or rules from you first.
  *Post-MVP* = your newest docs (10K VIEW + HOW GAMIFICATION…) put it after launch.
- Doc names are shortened here; section 1 has the full file names.

### 5.1 Daily loop gaps (highest priority)

| Feature still to build | Reference in MASTER | Status | Need it? |
|---|---|---|---|
| **#21 step 4 · "N/A — not triggered" score:** lets players skip scoring a non-routine habit that didn't come up that day | PRD §11 | Needs your input | |
| **#22 Detailed Golden Habit View:** one full page per habit: where/when/what, reminder anchor, IF-THEN plan, why it works, progress, experiments, Captain's Log notes, edit/delete | PRD 8.C / 12.C · PHASE 1 AND PHASE 2 DETAILS ("Detailed Golden Habit View: Living Master Document") | Ready | |
| **#23 Habit experiments + AI fixes:** ⚠️ Flag on any habit → Quick Suggestion (AI) / Go Deeper / Manual Edit; each change runs as a 3-day 🧪 experiment, then is kept or retired | PRD 13.C · PHASE 1 AND 2 SEQUENCE (Day 5) | Ready | |
| **#24 Today's Focus (AI):** 3–5 tips written from today's check-in; a private nudge when the Captain's Log doesn't match the score | PHASE 1 AND 2 SEQUENCE · PHASE 1 AND PHASE 2 DETAILS · Gamification Mechanics Specs | Ready | |
| **#25 Phase 2 first launch:** "Phase 1 complete, mission begins" moment + a 90-second Cockpit tour | PHASE 1 AND 2 SEQUENCE §0 | Ready | |
| **#26 New vs returning players:** "Press Start to Begin" intro for new players; returning players skip straight to where they left off | PRD §4 · PHASE 1 AND 2 SEQUENCE · Haroon Calls and meetings (22 Jul) | Ready | |
| **#27 Progress Summary polish:** stats revealed one by one, "% to next planet" bar, first-mission card, quick-action buttons | PRD 12.C · PHASE 1 AND 2 SEQUENCE | Ready | |
| **#28 Daily reset time + weekend rules:** a new day starts at 4 AM (adjustable); weekend check-ins show only Cores with 7-day habits | PRD | Ready | |
| **#29 Adding a habit by hand:** the manual add screen also runs the Triple-Check and asks for MBMs and a time block | PRD §7 / 12.C | Ready | |

### 5.2 Phase 1 and Command Center

| Feature still to build | Reference in MASTER | Status | Need it? |
|---|---|---|---|
| **#30 Phase 1 reward moments:** named milestone badges during onboarding (Truth Seeker → … → Golden Habit Architect) with their points and a progress bar | PHASE 1 AND 2 SEQUENCE · PHASE 1 AND PHASE 2 DETAILS · HOW GAMIFICATION… | Ready | |
| **#31 Command Center rules:** locked lists shown greyed with a hint, where each entry came from, archive instead of delete, search across lists, One-Time Actions list | PRD 10.C · PHASE 1 AND 2 SEQUENCE | Ready | |
| **#32 Returning to Phase 1:** guided flows for adding a new habit later, Quick Add from the Ideas Well, habit version history | PHASE 1 AND 2 SEQUENCE | Ready | |
| **BG-F7 Triple-Check scoring:** player rates WANT / CAN / EFFECTIVE 1–5; below 3 → the AI suggests changes | MM Build Guide | Ready | |
| **BG-F8 Refine the Golden Habit before locking it:** Tweak / Alternative / Custom / Regenerate | MM Build Guide | Ready | |
| **BG-F10 Onboarding feedback:** "How helpful was this Golden Habit?" (1–5 + comment) | MM Build Guide | Ready | |
| **BG-F22 Animated score sliders** with a message for each score | MM Build Guide | Ready (visual only) | |

### 5.3 AI safety, data and admin

| Feature still to build | Reference in MASTER | Status | Need it? |
|---|---|---|---|
| **#33 Behaviour data capture:** record how players move through the app (timing, skips, exits) to improve the AI later | AI-First Prioritized Implementation Guide (marked "NEVER CUT") · AI-FIRST STRATEGY & DATA LEARNING GUIDE | Ready | |
| **#34 AI review queue:** low-confidence AI suggestions held for you to review in the admin panel | PRD 13.D3 · HOW GAMIFICATION… · 10K VIEW | Ready | |
| **#35 Healthy-use checks:** gentle message on compulsive app-checking or 8+ new habits a week | PRD 13.D6 · HOW GAMIFICATION… | Ready | |
| **AI chat limits + transcript review** (#B13 / #B14): message and cost caps per player; read Nova conversations in the admin panel | HOW GAMIFICATION… · 10K VIEW | Ready | |
| **#37 Lists analytics:** "completed" and completion rate per list | Haroon Calls and meetings (9 Sep) | Needs your input | |
| **Feature switches + maintenance banner** (#B26 / #B27): turn Cantina / AI chat on or off, force-update message | PRD | Ready | |
| **Player data export + "delete my data"** (BG-F56 / #B19) | MM Build Guide | Ready | |

### 5.4 Notifications and integrations

| Feature still to build | Reference in MASTER | Status | Need it? |
|---|---|---|---|
| **#36 Notifications:** daily reminder, streak-about-to-break nudge, come-back message; per-type on/off, quiet hours, max 3 a day | PRD 17.2 | Ready | |
| **BG-F53 Google Calendar sync** | Additional MM System Master Project Documents / CALENDAR INTEGRATION TECHNICAL SPECIFICATIONS · MM Build Guide | Needs your input | |
| **BG-F42 Weekly Missions:** each Momentum List becomes a weekly quest that earns points | MM Build Guide · _PRIORITIZED WILL_S TO-DOS… | Needs your input | |
| **BG-F6 / BG-F9 Habits database (500+ habits)** + matching habits to each player | MM Build Guide | Needs your input (the habit list) | |
| **Video library** of habit / principle videos | Additional MM System Master Project Documents / VIDEO LIBRARY FOR UNIVERSAL PRINCIPLES_HABITS | Not planned yet | |

### 5.5 Post-MVP (after launch, per your newest docs)

| Feature still to build | Reference in MASTER | Status | Need it? |
|---|---|---|---|
| **13b Levels** (Cadet → Navigator → Commander) | Gamification Mechanics Specs §2 · Scope v2 (suggested numbers) | Post-MVP · needs your numbers | |
| **13c Planet journey mechanics** (days / points to reach each planet) | Gamification Mechanics Specs · Scope v2 | Post-MVP · needs your numbers | |
| **13d Ship upgrades** (Armor, Thrusters) | Gamification Mechanics Specs · images in the docs | Post-MVP · needs your numbers | |
| **13e Mystery Box** | Gamification Mechanics Specs · 10K VIEW | Post-MVP · needs your numbers | |
| **13f Badges** | Gamification Mechanics Specs | Post-MVP · needs your numbers | |
| **13h Skip-a-check-in purchase** | Gamification Mechanics Specs · images in the docs | Needs your input (options + costs) | |
| **Cantina Leaderboard / Arena** (V2) | Space Cantina - Social Component… | Post-MVP | |
| **Share to Reddit button** | Haroon Calls and meetings (your decision, 25 Sep) | Post-MVP | |
| **#39 Endless journey** (next galaxy after the last planet) | Haroon Calls and meetings (9 Sep) | Post-MVP (design ready) | |
| **BG-F43 Asteroids / aliens when progress stalls** | MM Build Guide | Post-MVP · needs design | |
| **Subscriptions / paid tiers** (#B36) | Haroon Calls and meetings | Needs your input (tiers + pricing) | |
| **Admin 2FA** | Haroon Calls and meetings | Parked (needs a paid Firebase tier) | |

---

## 6. Weekly updates

*I add a new entry here at the end of each week.*

### Week 39 (21–27 Sep 2026) and earlier: first version
- Map created covering everything built so far (#1–#21, the admin panel and the web build).
- Docs I built from this week: **PRD** (#15, #17, #18, #20, #21), **Gamification Mechanics Specs** §6,
  §8, §10 (#15–#19), **Haroon Calls and meetings** (#41, #42), **MM Build Tracker** (Balance %).
- Read the full MASTER folder for the first time (52 files, 25 Sep). This changed the scope: leveling,
  planets, ship, Mystery Box and badges are now post-MVP.
