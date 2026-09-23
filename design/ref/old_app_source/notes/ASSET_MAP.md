# Asset Map — old "5 Core Life" app

Everything the client's old app can donate, mapped to **what it was used for** and **whether it's worth reusing** for Moore Momentum.

All paths are under:
`5corelife-mobile/5corelife-fix-registration-id-for-ios/src/assets/`

Totals: **878 PNG · 14 Lottie (.json) · 14 GIF · 24 MP4 · 8 sounds · ~169 MB**.
Most PNGs ship `@2x`/`@3x` retina variants (React Native convention) — for Flutter reuse, prefer the `@3x` (highest-res) as the source and downscale.

Reuse legend: ⭐ = directly reusable graphic · 🔁 = reusable idea/logic, not the file · ⚠️ = app-specific chrome, low value.

---

## A. THE ROCKET (highest-value — this is what the client flagged)

| Folder | Files | Was used for | Reuse |
|---|---|---|---|
| `images/improvement_colors/colors_rocket/` | `01..05-rocket-armor.png`, `default.png`, `rocket5/25/50/100/1000.png` | Rocket **body / armor skins** (5 rarities + base) | ⭐ |
| `images/improvement_colors/colors_rocket_dashboard/` | `default.png`, `default_0.png` | Small body for the cockpit/dashboard rocket | ⭐ |
| `images/improvement_wings/wings_rocket/` | `default.png`, `rocket5/25/50/100/1000.png` | **Wing skins** (re-tinted at runtime via DuoTone) | ⭐ |
| `images/improvement_wings/wings_rocket_dashboard/` | same set | Small wings for dashboard | ⭐ |
| `images/improvement_turbines/turbines_rocket/` | `default.png`, `rocket0/5/25/50.png`, `empty_space.png`, `flameCopy4.png` | **Engine/thruster skins** + flame anchor | ⭐ |
| `images/improvement_turbines/turbines_rocket_dashboard/` | `default*/rocket5/25/50.png` | Small turbines for dashboard | ⭐ |
| `images/improvement_*/*` (tier icons) | `itemRare/VeryRare/Epic.png`, `rocketNN.png` | Store **tier icons** (buttons) | ⭐ |
| `images/improvements/` (44) | `window.png`, `bgWindow*.png`, `iconColors/iconWings.png`, `name*.png`, `rocket.png`, `shadow*.png` | Improvements-store **UI chrome** (cockpit window frame, slot buttons) | 🔁 |
| `animations/rocket_fire/` | `FireHi.json`, `FireMi.json`, `FireLo.json` | **Flame Lottie**, 3 power tiers (currently commented out in favor of GIFs) | ⭐ |
| `images/cores/` flames | `Thruster_Low.gif`, `Thruster_Mid.gif`, `Thruster_High.gif`, `Truster_High_looped.gif` | **Live flame** keyed to momentum (<36 / 36–70 / >70) | ⭐ |

> Filename → price/rarity decoder: `rocket5/25/50/100/1000` are the old credit prices; tiers are **Common/Uncommon/Rare/Very Rare/Epic**. Turbine tiers also carry a **flame count** (Rare=2, Very Rare=3, Epic/Star Jump=5, base=1). See `ROCKET_SYSTEM.md`.

## B. THE 5 CORES (the "fuel tanks")

| Folder | Files | Was used for | Reuse |
|---|---|---|---|
| `images/cores/` | `mindset/emotional/relationship/physical/career` × `_on/_off/_mask.png` | The 5 **core tank bodies** + silhouette masks | ⭐ |
| `animations/cores/` | `red/blue/pink/purple/green_liquid.json` | **Liquid-fill Lottie** masked into each core; fill % = core power | ⭐ |
| `images/cores/` HUD | `points_screen.png`, `coin.png`, `planet.png`, `flame.png`, `handle_icon.png`, `storage_icon.png`, `settings_icon.png` | Cockpit **HUD** (credits, destination, momentum %) | 🔁 |
| `images/overview/` (99) | `iconMindset/Emotional/...`, FAVORITES art | Core **icons** + Habit-Overview accordion art | ⭐ (icons) |
| `images/habits_screen/` (26) | `background_{red,blue,pink,purple,green}.png` + title art | Per-core habit-screen **backgrounds** | ⭐ |
| `images/check_in/` (63) | per-core imagery | Quiz / self-review core art | 🔁 |

Core identity table (color-coded): **MINDSET** #AC2912 red · **EMOTIONAL_HEALTH** #1B51A1 blue · **RELATIONSHIPS** #C8348C pink · **PHYSICAL_HEALTH** #7D2C7D purple · **CAREER_FINANCES** #6E9A30 green.

## C. SPACE TRAVEL / JOURNEY (the progression map)

| Folder | Files | Was used for | Reuse |
|---|---|---|---|
| `images/journey/origins_destinations/` (17) | `earth, moon, mars, ceres, jupiter, europa, saturn, titan, uranus, neptune, triton, pluto, eris, mercury, station1/2/3.png` | **Planets / space stations** — the 16-stop travel ladder | ⭐ |
| `images/journey/obstacles/` | `Asteroids.gif`, `UFOs.gif`, `asteroidsStatic.png`, `ufo.png`, `spaceCrate.png` | **Obstacles** shown mid-leg (mission active & not yet passed) | ⭐ |
| `animations/ufos/` | `UFOs.json` | UFO obstacle Lottie | ⭐ |
| `images/journey/` | `background.png`, guide-line art | Single-leg "zoomed-in" view | 🔁 |
| `images/lifetime/` (13) | `background_simple.png`, `background_planets_only.png`, `background_planets.png` | Zoomed-out **solar-system map** backdrop | ⭐ |
| `images/aliens/` (8) | `01..04-alien.png` + `*-fondo.jpg` | **Alien** encounters (deliver inspirational quotes post-night-check) | ⭐ |

> Planet **positions** on the map (x/y/angle per leg) are hard-coded in `helpers/destinationHelper.ts` (`journeyList` / `allPositions`) — reusable *logic*, not an asset.

## D. CINEMATICS & SOUND

| Folder | Files | Was used for | Reuse |
|---|---|---|---|
| `videos/copy_video/` | `Launch_copy.mp4`, `Landing_copy.mp4`, `_Launch1-5_copy.mp4`, `_Landing1-4_copy.mp4`, `SpaceBG2.mp4` | **Launch/landing cinematics** + animated space backdrop. The `_copy` set is the one actually wired up | ⭐ |
| `videos/` (root) | `Launch/Landing.mp4`, `_Launch1-5`, `_Landing1-4`, `SpaceBG.mp4` | Older/duplicate cut of the same | ⚠️ (dupes) |
| `sounds/` | `Ambience_Space_00.mp3`, `airlock.mp3`, `Menu_Select_00/01.mp3`, `Alien_Language_00.mp3`, `Jingle_Win_00.mp3`, `background_space.mp3`, `cockpit.m4a` | Ambience + UI FX + win jingle + alien voice | ⭐ |

## E. META / PROGRESSION UI

| Folder | Files | Was used for | Reuse |
|---|---|---|---|
| `images/trophies/` (55) | `container.png`, `trophy_*` (moon/mars/saturn/pluto/momentum), streak titles, `trophie_locked.png`, `letterReached/Completed.png` | **Trophy case** (14 badges: streaks 7/14/21, momentum 50/75/100, reach Moon/Mars/Saturn/Pluto, habits 1/5/10/20 formed) | ⭐ |
| `images/quests/` (55) | quest/mission modal art | **Quest / mission** result modals | 🔁 |
| `images/bonus/` (45) | `1/2/5/10Days.png`, `window.png`, `iconBonus.png`, `container*.png` | **Bonus shop** (consumables: skip check-in, boost momentum, add days) | 🔁 |
| `images/storage/` (24) | backgrounds + `improvements/trophies/bonus` labels & buttons | **Storage hub** menu | ⚠️ |
| `images/leaderboard/` (6) | `avatarCont.png` frame | Leaderboard rows (mini per-user rocket) | 🔁 |
| `images/quiz/` (37) | step/result art | First-run **core quiz** (self-assessment) | 🔁 |
| `images/cockpit_categories/` (18), `cockpit_self_review/` (6), `cockpit_self_review_done/` (3) | list + journaling art | Cockpit "purpose" lists + night self-review | ⚠️ |

## F. HABIT-CHECK LOOP UI

| Folder | Files | Was used for | Reuse |
|---|---|---|---|
| `images/habits/` (9) | `button_on/off.png`, `line.png` | Core **activation** power button | 🔁 |
| `images/set_habits/` (16) | UI + score-progress bar | **SetHabits** + `ScoreProgress` bar | 🔁 |
| `images/check_habits/` (3) | `button_pencil.png` | CheckHabits edit affordance | ⚠️ |

## G. ONBOARDING, AUTH, GLOBAL CHROME

| Folder | Files | Was used for | Reuse |
|---|---|---|---|
| `images/onboarding/` (20) | `button_next.png`, `highlight.png`, `iconSelection.png`, `screen*.png` (robot-speech frames) | 11-step **tutorial** overlays | 🔁 |
| `images/login/` (13) + `animations/login/`, `animations/loading/` | auth art + `LiquidLoad.json`, `LogoLights.json`, `Loader.json`, `Logo.json` | Login + **splash/loader** Lottie | ⭐ (splash) |
| `images/shared/` (94) | `background.png`, `background_universe.png`, `button_ok/cancel/confirm/edit.png`, `lineaGuia.png`, `Rocket-ok.gif`, `leavingplanet.gif`, `rocketCopy2.png` | Global backgrounds, buttons, transitions | ⭐ (starfields, rocket gifs) |
| `images/settings/` (4) | settings chrome | Settings | ⚠️ |

---

## Priority pull-list for Moore Momentum

If we cherry-pick, grab these first (all ⭐, and they map cleanly onto our existing rocket/momentum concepts):

1. **Rocket parts** — `improvement_colors/`, `improvement_wings/`, `improvement_turbines/` (both `_rocket` and `_dashboard`).
2. **Flames** — `rocket_fire/*.json` **and** `cores/Thruster_*.gif` (momentum-keyed).
3. **Cores** — `cores/*_on/_off/_mask.png` + `animations/cores/*_liquid.json` (liquid-fill gauges).
4. **Planets** — `journey/origins_destinations/*.png` + `lifetime/background_*.png` (map).
5. **Obstacles/aliens** — `journey/obstacles/*`, `ufos/UFOs.json`, `aliens/*`.
6. **Cinematics/sound** — `videos/copy_video/*`, `sounds/*`.
7. **Splash** — `animations/loading/Logo.json`, `login/LogoLights.json`.

> Note: these are the **old 5 Core Life** brand assets (rocket art, planet art). Reuse the *mechanics and generic space art* freely; re-skin anything that carries old branding/palette to match Moore Momentum before shipping.

See `ROCKET_SYSTEM.md` (rocket compositing/economy) and `GAME_LOOP.md` (full backend economy & core loop) for the logic behind these assets.
