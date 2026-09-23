# Moore Momentum (MM) — UI Design Prompt for Claude Design Tool

> **How to use this prompt:** Paste the entire prompt below into Claude (or your design tool). For best results, request **one screen at a time** — start with the *Default Rocket Dashboard* (Phase 2 home), then iterate outward. The "Master Brief" sets the universe; the "Screen-by-Screen" section specifies each artifact.

---

## 🎯 MASTER BRIEF (paste this with every screen request)

You are designing the UI for **Moore Momentum (MM)** — an AI-powered, gamified self-improvement mobile + web app that turns leveling up across the **5 Core Areas of Life** (🧠 Mindset, 💰 Career & Finances, 👥 Relationships, 💪 Physical Health, 🧘 Emotional & Mental Health) into an ethically addictive space adventure. The player pilots a rocket through the cosmos; daily habit check-ins move the ship; consistency unlocks upgrades, planets, and identity transformation.

### Core Design Principle (non-negotiable)
Every design decision answers ONE question: **"Will the player want to come back tomorrow?"** Daily use must feel like a game, not a chore. Reward effort, never punish failure. Setbacks are reframed as data, never shame.

### Aesthetic Direction
- **Vibe:** *"Tron meets Stranger Things meets vintage arcade game"* — 80s neon nostalgia fused with futuristic optimism. Steampunk-sci-fi hybrid. Cinematic cockpit energy.
- **Mood:** Electrifying, hopeful, mission-control serious-but-playful. Confident. Immersive.
- **Reference points:** Cyberpunk 2077 HUDs (cleaner), Apollo mission control panels, Destiny 2 vault UI, Halo waypoint displays, retro CRT scan-lines used sparingly.

### Brand System (use exactly)
**Typography**
- Display / headers / numerals / mission titles: **Orbitron** (geometric, futuristic, tech-y)
- Body, dialogue, microcopy: **Red Hat Display** (humanist, readable, modern)

**Primary Palette**
| Color | Hex | RGB | Use |
|---|---|---|---|
| Momentum Blue | `#2a7de1` | 42, 125, 225 | Primary actions, Mindset Core highlights, navigation accents |
| Ignition Red | `#ea0029` | 234, 0, 41 | Critical alerts, streak fire, "launch" energy |

**Secondary Palette**
| Color | Hex | Use |
|---|---|---|
| Cosmic Teal | `#00a98f` | Physical Health Core, success/forming states |
| Solar Yellow | `#FFC629` | Achievements, badges, Mystery Box, Space Credits |
| Deep Navy | `#111c4e` | Primary background — space depth |
| Midnight Black | `#171d1a` | Pure backgrounds, panel base |
| Cool Gray | `#20372e` | Locked states, inactive Cores |
| Subtle White | `#f1f1f1` | Body copy on dark |

### Core Visual Language
- **Default backgrounds:** Deep Navy (`#111c4e`) → Midnight Black (`#171d1a`) radial gradients, with subtle starfield, scan-lines, or noise grain (3–8% opacity).
- **Glow language:** Each of the 5 Cores has its own neon halo color (Mindset = blue, Career = yellow, Relationships = magenta/pink, Physical = teal, Emotional = violet — pick the magenta + violet to round out the palette consistently across all screens).
- **Locked states:** Greyscale + soft gold lock icon, subtle pulse animation hinting they CAN be unlocked. Never demanding, never shaming.
- **Habit color progression (CRITICAL — applies everywhere habits appear):**
  - 🔴 Bad habit → 🟠 Golden Habit forming → 🔵 MBMs attached → 🟢 Fully formed → 🏆 Trophy Room
- **Iconography:** Custom line+glow icons (rocket, planet, shield, wings, thrusters, ring, infinity, checklist, steering wheel). NOT generic Material/Apple SF symbols.
- **Motion:** Cinematic. Reward moments get full celebration animations (particle bursts, ship trajectory arcs, lock-shatter, fireworks). Failure moments get calm, informational animations — NEVER red flashing or shake.
- **Surfaces:** Slightly glassmorphic panels (10–15% opacity, blur ~12px) with thin neon hairline borders. Sharp 90° corners or 4–8px rounded — pick one and hold it across the system.

### Voice & Tone (for all UI copy)
- **Nova AI** (the in-app companion) speaks like a confident mission controller, NOT a cheerleader. Direct, warm, science-anchored. "Got it." "Logged." "Moving on." "That's data, not defeat."
- Players are addressed as **"Player One"** / **"Captain"** — never "user."
- Action verbs: launch, ignite, fire on all cylinders, break gravity, lock in, forge.
- NEVER use punitive language. Missed days = "relaunching from last checkpoint."

### Target User Reminder
Entrepreneurial-minded 18–35 year olds who are skeptical of generic self-help, fluent in tech, and addicted to dopamine. The UI must out-design Calm, Headspace, and any competing habit app — and feel closer to a AAA game cockpit than a productivity app.

### What to AVOID
- Generic AI/SaaS aesthetics (purple gradients on white, Inter font, soft pastel cards)
- Punitive red error states or shameful empty states
- Flat illustration "yoga people" stock styles
- Hand-holding microcopy ("Don't worry!" "Great job!" — too saccharine)
- Cliché gamification (cartoon trophies, kid-game confetti)

---

## 🗺️ SCREEN-BY-SCREEN SPECIFICATION

The app has **two phases**, each with multiple screens. Phase 1 is one-time foundation building (a "character build"). Phase 2 is the daily execution loop where players spend most of their time.

---

### 🟦 PHASE 1, STAGE 1 — Habits Hierarchy System (HHS)
*Discovery: Pinpoint a pain point and forge a personalized Golden Habit.*

#### Screen 1.1 — Landing / Intro
- Full-bleed deep navy starfield, parallax stars
- Hero rocket centered, gentle hover animation, soft engine plume glow
- 5 Core icons orbit faintly around the rocket body (one Core highlighted in rotation)
- Headline (Orbitron): **"READY PLAYER ONE?"**
- Sub (Red Hat Display): "Pilot your rocket. Save the planet. Level up your life."
- Single pulsing CTA: **[ PRESS START ]** — neon blue, glowing rim, scan-line accent
- Earth visible in the lower foreground, distant planets (Moon, Mars, Jupiter, Saturn, Pluto) in the deep background

#### Screen 1.2 — Mission Brief / Intro Sequence (3 micro-screens)
- Screen A: Earth from space, AI voice card from Nova: *"Planet Earth is on the brink of self-destruction 🧨🌎. The only way to save it…"* — with WHO / WHAT / HOW pillars
- Screen B: Rocket on launchpad with all 5 Cores in full color, then morph to greyed/locked → signaling the journey begins
- Screen C: **Habits Hierarchy Pyramid** — 5 stacked levels, each with a lock icon and an emoji marker:
  1. 🔍 Pain Point Scanner
  2. 🧠 Core Connection
  3. 📘 Universal Principle
  4. 🔑 Keystone Creator
  5. ✨ Golden Habit Forge

#### Screen 1.3 — HHS Conversation (Steps 1–5)
- **Layout:** Full-screen chat with Nova AI (left avatar = stylized cosmic helmet/orb, glowing teal). Player input docked at bottom. Top of screen shows the **Hierarchy Pyramid** mini-map — current step highlighted with a pulse, completed steps lit in full color with green checkmark.
- **Progress bar (top edge):** 5 segments matching the 5 steps. Filling segment animates with energy crackle.
- **Question types:** mix of multiple choice cards, sliders (1–10 emotional impact), short text, confirmation pills (Yes / Adjust).
- **Reward beats every 2–3 questions:** Floating "+10 Momentum Points" pill drifts up; achievement unlocks ("🏆 Truth Seeker," "Core Confirmed," "Principle Decoder," "Keystone Forger," "Golden Habit Architect") trigger a brief celebration animation (particle burst + Orbitron callout).
- **Express vs Comprehensive Mode toggle** in top right — adapts question depth.

#### Screen 1.4 — Pain Point Reframe Card
- After Step 1 conversation, show a styled summary card:
  - 😥 **Primary Challenge:** [generated text]
  - Two pills: **[ Yes, that's it ]** / **[ Adjust ]**
- Background of card: subtle pulsing aurora effect.

#### Screen 1.5 — Core Map (Step 2 visual)
- Visualize all 5 Cores as orbiting nodes around the player's pain point at center.
- **Primary Core** glows brightest with pulsing ring; the other 4 show **ripple effect lines** animating outward (connecting strands of light), with mini Current State / Potential State cards expandable on tap.

#### Screen 1.6 — Universal Principle Reveal (Step 3)
- Card flip animation revealing a **"sacred tablet"** style panel: principle name in Orbitron, short description, a small constellation drawn behind it. Feels earned.

#### Screen 1.7 — Golden Habit Forge (Step 5 final)
- Animated forging visual: raw materials (the player's strengths, passions, obstacles drawn from Momentum Lists) flow into a glowing furnace and emerge as a single **Golden Habit Card**.
- The card shows: Habit Name, Cue/Trigger, Action, Reward, Starting Version (MVA), and a built-in **IF-THEN Obstacle Plan** in a smaller nested box.
- Two CTAs: **[ Lock It In ✅ ]** / **[ Refine ]**

#### Screen 1.8 — Command Center Reveal (REWARD UNLOCK)
- **Major celebration moment.** Screen darkens, vault doors slide open, Momentum Lists fly in one by one with a typewriter-then-glow effect:
  - 🚀 Back to the Future / Legacy Goals
  - ⏰ Routines
  - 🛑 Obstacles
  - 🎮 Passions
  - 🛠️ Strengths
  - (more lists unlock progressively at planet milestones)
- Headline: **"COMMAND CENTER UNLOCKED 🔓"**
- Below: a 2x3 or 3x2 grid of "Momentum List" cards, each with icon + list name + count of stored entries.

---

### 🟪 PHASE 1, STAGE 2 — Momentum Boosting System (MBS)
*Engineer the Golden Habit into something automatic with the 3 MBMs.*

#### Screen 2.1 — Level 2 Intro
- Hero visual: rocket in orbit with the activated Core glowing
- Three MBM icons hover in locked state, pulsing with energy:
  - 🔍 **OBVIOUS** (Make it Obvious / Attractive)
  - ⚡ **EASY** (Make it Easy)
  - 🎉 **REWARDING** (Make it Fun / Rewarding)
- Progress bar updates from "Level 1 ✅" to "Level 2 → 0/3 MBMs"

#### Screen 2.2 — Obstacle & Opportunity Diagnostic
- Conversational with Nova, but with **obstacle indicator visualizations** — the friction point appears as a pulsing red blockage on a stylized "habit pathway" diagram.

#### Screen 2.3 — MBM Strategy Selection (×3 screens, one per MBM)
- Each MBM gets its own themed screen:
  - **Obvious** → magnifying glass / spotlight visuals
  - **Easy** → smooth flow / friction lines being erased
  - **Rewarding** → confetti / dopamine burst visuals
- Each presents 2–3 personalized strategy cards. Player picks one. Card flies into a "habit stack" panel below.

#### Screen 2.4 — Personal Assistant Mode (AI Agent reveal)
- Reveals automation capabilities: *"I'll handle the setup. Here's what I'm doing for you →"*
- Animated checklist of one-time setup actions (calendar block created, sticky note ordered, app installed). Each item self-checks as if Nova is doing it.

#### Screen 2.5 — Space Cantina Unlock (PHASE 1 CULMINATION REWARD)
- **Cosmic doors part open** revealing a vibrant cantina interior — neon signs in Orbitron, alien silhouettes at tables, Tribe banners hanging.
- Four pillar cards reveal in sequence:
  - 💡 **Ideas Well** (crowdsourced Golden Habits / MBMs)
  - 🤝 **Interstellar Collaboration** (Tribes & accountability partners)
  - 🏆 **Leaderboards** (anti-shame, multi-factor)
  - ⚔️ **Weekly Competitions**
- Tribe matched: e.g., "Energy Warriors" — shown as a unit patch the player earns.

---

### 🟩 PHASE 2 — Gamified Daily Execution (THE HEART OF THE APP)
*This is where 80% of the player's time is spent. Design priority: this set first.*

#### Screen 3.0 — Phase 2 Launch Animation
- Phase 1 completion banner fades → rocket lifts off → camera follows it into deep space → seamless transition into the Default Rocket Dashboard.

#### ⭐ Screen 3.1 — DEFAULT ROCKET DASHBOARD (Home / Cockpit) — *most important screen in the app*
**Layout (mobile-first vertical):**

- **TOP BAR**
  - ☰ Hamburger menu (top left) → Command Center, Space Cantina, Phase 1 return, Settings
  - 🏆 Trophy Room icon (next to hamburger)
  - 🔥 **Streak Counter** (top center) — shows "Day X" with a flame whose size grows with streak length
  - 📊 **Stats Box** (top right) — three stacked mini stats: Current Planet (Moon/Mars/etc.), Momentum Score (numeric), Balance % (7-day rolling)

- **HERO ROCKET (center stage)**
  - Stylized rocket rendered with the player's earned Wings / Armor / Thrusters upgrades visually applied
  - The 5 Cores rendered as **5 distinct sections of the ship body**, each glowing in its Core color when ACTIVE, greyed with a gold lock when INACTIVE
  - Engine plume animates at idle (subtle), intensifies when streak is hot
  - **Tip-of-rocket icon row** (just above the ship) — 4 quick-access glowing icons:
    - 🎯 Steering Wheel → Command Center / Momentum Lists
    - ⏰ Clock → Routines by time of day
    - ∞ Infinity → All Habits Quick View
    - ☑️ Checklist → Non-Routines

- **PRIMARY CTA (impossible to miss)**
  - **[ DAILY CHECK-IN ]** — bold, glowing, pulsing button. Largest interactive element. Subtle 3D press animation. Sits below the rocket.

- **BACKGROUND**
  - Deep space starfield with **Zoomed-Out Planet Journey arc** visible faintly behind/around the rocket — dotted trajectory line from Earth to current planet target, current rocket position marked on the arc.

- **BOTTOM NAV** (subtle, secondary)
  - All Habits / Space Cantina / Trophy Room / Profile

#### Screen 3.2 — Optional Mantra & Grateful List (pre-check-in)
- Clean card layout. Player's mantra in large Orbitron quotation block.
- 3 numbered text fields below for daily gratitude entries.
- Two CTAs equally weighted: **[ Open it ]** / **[ Skip — straight to scoring ]**

#### Screen 3.3 — Daily Check-In: Score Your 5 Cores (MAIN DAILY RITUAL)
- **One Core at a time** (full-screen card progression — swipe or "Next").
- For each ACTIVE Core:
  - Core icon + name in Core color at top
  - **BTTF Vision** quote card: "I am an energized, active person who…"
  - Habit list (Routine + Non-Routine) with their color-progression dots (🟠/🔵/🟢)
  - **Score Slider 1–5** — the hero interactive element. Slider is large, satisfying, with full labels visible on first session:
    - 1 = Completely skipped
    - 2 = Partial
    - 3 = Got through it but struggled
    - 4 = Solid — minor friction
    - 5 = Nailed it
  - Slider lock-in animation (4–5 = celebratory pulse; 1–3 = calm acknowledgment, never red)
  - **Captain's Log** prompt field below — multiline, optional. Auto-saves with ✅ Logged confirmation.

- For LOCKED Cores: greyed card with gold lock, soft pulse, copy: *"Not yet activated. Return to Phase 1 to ignite this Core."* with a subtle [Return to Phase 1 →] link.

#### Screen 3.4 — Mission Control AI Intervention (CRITICAL EMPATHY DESIGN)
- Triggered when a habit scores ≤3 for 3+ consecutive days. Slides in from right as a clean information panel — **NEVER an alarm popup**.
- **Pattern Detected card** at top: simple bar chart showing last 3 days (e.g., 2 | 2 | 2) with the line: *"Pattern detected: 3 consecutive days at or below 3.0."*
- Reframe copy: *"That's not failure — that's your habit telling you something needs adjusting."*
- **Three resolution path cards** (equally weighted, no "recommended" highlight):
  - ⚡ **QUICK SUGGESTION** (under 2 min)
  - 🔬 **GO DEEPER** (5–8 min, returns to Phase 1)
  - ✏️ **MANUAL EDIT** (full control)
- After selection, Quick Suggestion path shows: a "Mission Control Analysis" card pulling from Captain's Log entries, Obstacles List, and Lifestyle Factors → diagnoses cue competition / friction → suggests one tweak → activates as a 🧪 **Experiment** with 3-day check-in cycle.

#### Screen 3.5 — Progress Summary (post-check-in rewards screen)
- Each stat reveals **one by one** with brief counter animations — never all at once.
- **Sequence:**
  1. Momentum Points earned today (+25, animated counter)
  2. Total Momentum Score
  3. Streak Counter — flame icon ignites/grows
  4. Space Credits earned + total
  5. **Planet Journey Arc** — visual rocket movement along the trajectory line, with new % filled
  6. **5-Core Balance Meter** — horizontal bars per Core (filled per yesterday's score, empty + locked icon for inactive)
  7. **Today's Focus** card — AI-generated, 3–4 bullets pulling from active habits and flagged items (⚠️)
  8. **Ship Status** panel — Wings / Armor / Thrusters progress, "First Available Upgrade" callout
  9. **Daily Challenge** card with [ Accept ] / [ Skip ] CTAs
- **Mystery Box reveal (10–15% chance):** if triggered, a glowing wrapped box appears mid-summary with 2–3s anticipation animation, tap-to-reveal explosion → reward card flips up (bonus credits / streak saver / cosmetic / personalized alien message).

#### Screen 3.6 — Trophy Room
- Themed as a **museum gallery in deep space** — pedestals, soft spotlights, glassy displays.
- Trophies organized by Core (5 sections, each with its color theme).
- Each formed habit gets a **unique trophy rendering** based on the habit type (e.g., a glowing dumbbell-shaped crystal for fitness, a constellation for mindset).
- Tap a trophy → opens the Detailed View of that habit + formation date + identity-framing message: *"This habit is now part of who you ARE."*
- Empty state: faint silhouettes of "future trophies" — invitation, never absence.

#### Screen 3.7 — Space Cantina
- Recreate the Phase 1 reveal moment but as a navigable hub.
- **Four panel zones** (cantina booths):
  - 💡 Ideas Well — Reddit-style upvote feed of community Golden Habits / MBMs, with **Click-to-Adopt** on each card
  - 🤝 Tribes — feed of your matched Tribe (e.g., "Energy Warriors") with member count, recent posts, accountability partner match button
  - 🏆 Leaderboards — multi-factor (Momentum Points, longest streak, habits formed, ripple effect score) — anti-shame: every player visible, ranked but not punished
  - ⚔️ Weekly Competitions — current contest banner, prize callout, [ Join ] CTA

#### Screen 3.8 — Ship Bay (Upgrade Shop)
- Garage-meets-cockpit feel. Three upgrade categories displayed as workbenches:
  - **Wings** (unlocks more Momentum Lists + alien content)
  - **Armor** (streak protection, grace periods)
  - **Thrusters** (more Momentum Points per check-in)
- Each shows tiers: Common → Rare → Very Rare → Epic, with rarity color-coded borders (silver / blue / purple / gold).
- Locked tiers show level requirement: "Unlocks at Navigator (Level 2)" / "Commander (Level 3)."
- Currency displayed top right in Solar Yellow: 💎 Space Credits balance.

#### Screen 3.9 — Command Center (full view)
- Grid of all unlocked Momentum Lists as expandable cards.
- Each card: icon, list name, entry count, last updated date, "Cross-references" indicator (shows how many other lists this connects to).
- Tap any card → list detail screen with auto-tagged AI entries + a manual [ + Add ] button.
- Locked lists shown as ghost cards with unlock requirement: *"Unlocks at Mars (Wings Upgrade)."*

#### Screen 3.10 — Detailed Golden Habit View
- The "living document" for each habit.
- Sections: Cue/Trigger · Action · Reward · MVA Backup · IF-THEN Obstacle Plan · Attached MBMs (3 cards) · BTTF Vision link · Core link · Score history (sparkline graph) · Captain's Log entries (filtered to this habit).
- Color status pill at top: 🟠 / 🔵 / 🟢 / 🏆.
- **[ Edit ]** / **[ Flag for Refinement ]** / **[ View in Trophy Room ]** CTAs.

#### Screen 3.11 — Level-Up Moment (Cadet → Navigator → Commander)
- Full-screen takeover. Rocket animates dramatically — new visual upgrades applied in real time.
- Headline: **"NAVIGATOR ACHIEVED"** (Orbitron, neon).
- Unlocked benefits list: 1.25× credit multiplier, Rare-tier upgrades, etc.
- Single CTA: **[ Continue Mission ]**.

---

## 🧩 COMPONENT LIBRARY (build these consistently across all screens)

| Component | Spec |
|---|---|
| **Glassmorphic Panel** | bg: rgba navy 60%, blur 12px, 1px hairline border in Core color, 6px corner radius |
| **Score Slider** | 280–340px wide, glowing track in Momentum Blue, thumb is a neon orb, snap detents at 1/2/3/4/5 |
| **Core Card** | Aspect 4:5, Core icon top, status pill, glow halo in Core color when active |
| **CTA Button (Primary)** | Momentum Blue fill, Orbitron uppercase label, neon outer glow, pulse animation when idle |
| **CTA Button (Secondary)** | Transparent fill, 1px Subtle White border, hover = blue glow fill |
| **Reward Pill** | Solar Yellow text "+25 MP" floats up + fades, particle trail |
| **Streak Flame** | Animated SVG, scales 0.6× → 1.4× as streak grows from 1 → 365 days |
| **Lock Icon** | Solar Yellow on greyed-out element, soft 1.5s pulse |
| **Momentum List Card** | Icon top-left, count badge top-right, 3 most recent entries previewed below |
| **Captain's Log Entry** | Quote-styled card with date stamp, Core color accent stripe on left edge |
| **Mystery Box** | Wrapped glowing cube, idle floating animation, tap-to-reveal explosion |
| **Mission Control Alert** | Slide-in panel from right, ⚠️ amber accent (NOT red), data viz card, 3 path options |
| **Progress Bar** | Multi-segment (one per checkpoint), each segment fills with energy crackle animation |

---

## 🎬 ANIMATION PRINCIPLES

| Moment | Treatment |
|---|---|
| **Successful action / Score 4-5** | Particle burst, light pulse on the affected Core, sound: soft synth chime |
| **Streak milestone (7/14/21/30/60/90/180/365)** | Full-screen takeover, flame grows dramatically, badge unlocked card flies in |
| **Planet arrival** | Camera dollies forward, planet fills screen, alien guide silhouette appears with principle reveal |
| **Mystery Box trigger** | 2–3s anticipation float, tap → cube explodes, reward card flips up |
| **Level up (Cadet→Navigator→Commander)** | Ship visually transforms in real time, new upgrades materialize on hull |
| **Failure / Low score** | Calm dim, no shake, no red flash. Subtle amber pulse. Reframing copy. |
| **Form a habit (14d × 80%)** | Trophy materializes in Trophy Room with glow + identity-framing text |
| **Lock unlocks** | Lock shatters into particles → green checkmark fills the empty slot |
| **Page transitions** | Cinematic — never abrupt cuts. Use depth (parallax stars), camera drift, ship trajectory continuity |

---

## 📐 LAYOUT & RESPONSIVE NOTES

- **Mobile-first** (375–430px width primary). Hero rocket should be 60–70% of viewport height on home screen.
- **Tablet/desktop:** widen the dashboard into a true cockpit — side rails for navigation, larger planet journey arc, multi-pane Captain's Log.
- **Safe areas:** respect notches; bottom CTA button never covered by gesture indicator.
- **Touch targets:** minimum 48px; sliders 56px tall for thumb-friendliness.
- **Performance:** prefer SVG + CSS for animations on critical paths (dashboard, check-in). Reserve heavy WebGL/Canvas for the **planet arrival** and **level-up** moments only.

---

## ✅ DELIVERABLE REQUEST FORMAT

When generating each screen, please produce:
1. A **named, production-ready React component** (or HTML/CSS if specified) using the exact brand tokens above
2. **Inline comments** flagging where real data should be wired in (e.g., `// PULL FROM: player.activeCore`)
3. **Tailwind utility classes** OR a single co-located stylesheet — match what the dev team uses
4. **Mobile-first responsive** layout with breakpoints at 768px and 1024px
5. A **brief design rationale** (3–5 sentences) explaining the bold creative choice, NOT a generic description

---

## 🚀 SUGGESTED ORDER OF DESIGN GENERATION

To maintain coherence as the system grows, generate screens in this order:

1. **Default Rocket Dashboard** (Screen 3.1) — sets the entire visual language
2. **Daily Check-In: Score Your 5 Cores** (Screen 3.3) — the core daily ritual
3. **Progress Summary** (Screen 3.5) — the reward payoff
4. **Mission Control Intervention** (Screen 3.4) — proves the empathy design
5. **Trophy Room** (Screen 3.6) — proves the identity transformation moment
6. **Command Center** (Screen 3.9) and **Space Cantina** (Screen 3.7)
7. **Ship Bay** (Screen 3.8) and **Detailed Habit View** (Screen 3.10)
8. **Phase 1 screens** (1.1 → 2.5) — foundation flow, less time-sensitive
9. **Level-up moment** (Screen 3.11) — final polish

---

## 🛑 FINAL GUARDRAIL

Before submitting any design, sanity-check it against these:
- [ ] Would a 25-year-old who plays Destiny 2 think this is cool?
- [ ] Does this feel more like a cockpit than a productivity app?
- [ ] Is failure framed as data, never shame?
- [ ] Is the streak / planet / rocket visible at all times so progress always feels alive?
- [ ] Are the Cores color-coded consistently with the brand palette?
- [ ] Does the Daily Check-In button pull the eye more than anything else on the home screen?
- [ ] Did I use Orbitron + Red Hat Display, NOT Inter or any system font?

If any answer is no — redesign before shipping.

**End of Master Prompt.**
