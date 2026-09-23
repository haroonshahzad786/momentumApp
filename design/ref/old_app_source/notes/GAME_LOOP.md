# Game Loop & Economy — old "5 Core Life" app

How the old app turned a habit tracker into a game. This is the *logic* companion to
`ASSET_MAP.md` (graphics) and `ROCKET_SYSTEM.md` (the rocket specifically).

- Backend: `5corelife-api/5corelife-master/src` (Django REST + Celery)
- **All seed numbers live in** `users/management/commands/initialize_db.py`
- Frontend loop: `5corelife-mobile/.../src/modules/{dashboard,core,onboarding}`

---

## The metaphor
Your **rocket = your life**. It's built from **5 cores** (life areas). Doing habits fuels the
cores, which builds **momentum**, which flies the rocket across the **solar system**
(Earth → Space Stations → planets → Endless). Everything is a reskin of: *track habits, score
daily, keep a streak.*

The 5 cores: **MINDSET, EMOTIONAL_HEALTH, RELATIONSHIPS, PHYSICAL_HEALTH, CAREER_FINANCES**
(new users start with only MINDSET enabled).

## Two numbers run everything (`users/models/users.py → UserProfile`)
- **`momentum`** = average `power` of enabled cores (+10 bonus increments if active). Gates all travel.
- **`credits`** = spendable currency (also mirrored into lifetime `score`).
- Supporting: `core_cap` (per-core ceiling, raised by WINGS), `core_power_increase` (flat display bonus), `destination_index`, `days_in_journey`, `night_checks_in_row`.

## The daily loop
```
MORNING CHECK  (habits/morning-check/)
  → pick the habits you'll do
  → +25 credits
  → get/keep a Quest; every 3rd day (from day 2) also get a Mission
NIGHT CHECK    (habits/night-check/)
  → score each active core 1..5
  → core.power += score × 3   (or × thruster core_power_multiplier if equipped)
     clamped at user_core_cap  (= profile.core_cap + destination.core_cap)
  → +25 credits, streak++, days_in_journey++
  → resolve journey / quest / mission / rewards / trophies
```
**Miss a check-in** (>4h past night time, `habits/tasks.py`): every enabled core loses **−4**
power (floored at 0) unless you burn a `SKIP_CHECK_IN` bonus.

## Travel = the progression ladder (16 stops)
`destinations` seed (index · name · length days · momentum required · cores unlockable · core_cap):

```
 1 Space Station 1  1d  10   1  50      9 Space Station 2 10d  50   5  60
 2 The Moon         2d  15   2  50     10 Uranus         11d  55   5  70
 3 Mars             3d  20   3  50     11 Space Station 3 12d  65   5  70
 4 Ceres            4d  25   4  50     12 Neptune        14d  70   5  70
 5 Jupiter          6d  30   5  60     13 Triton         16d  75   5  70
 6 Europa           7d  35   5  60     14 Pluto          18d  75   5  80
 7 Saturn           8d  40   5  60     15 Eris           20d  75   5 100
 8 Titan            9d  45   5  60     16 Endless       999d  80   5 100
```
**Arrive** only if you reach the destination's `length` in days **AND** momentum ≥ its
`momentum_required`. Past the halfway point, falling short of momentum = journey **Failed**
(resets `days_in_journey`). Arrival pays **50 × days_in_journey credits**, unlocks the next
destination, auto-grants that destination's **ARMOR**, unlocks more cores, and raises `core_cap`.

## Quests & Missions (the daily/periodic challenges)
- **Quests** (one per journey): e.g. `fragile_cargo` (keep cores within 20%), `navigate_safely`
  (no core drops below yesterday). Success on journey-end pays `25 × days` credits.
- **Missions** (every 3 days): `balanced_cores` (cores within 40%), `previous_day`
  (every core ≥ yesterday), `core_lower` (avg daily score > 3), `comfort_zone` (self-verify).
  Success pays **50 credits**. Obstacle sprite shown while active: comfort_zone/previous_day →
  **asteroids**, balanced_cores/core_lower → **UFOs**.

## Rewards / loot drops (`rewards/views.py`)
On a successful quest or mission, roll `randint(1,100)`:
```
 ≤5 → 5% band · ≤15 → 10% · ≤30 → 15% · ≤50 → 20% · else → nothing (50%)
```
Then grant a not-yet-owned Bonus or Improvement whose `probability_reward` matches the band.
(This is why rocket parts can *drop* as well as be bought.)

## The economy sinks
- **Improvements** (rocket parts) — see `ROCKET_SYSTEM.md`. WINGS raise `core_cap`; THRUSTERS
  raise the score→power multiplier; ARMOR is destination-unlocked. Seeded prices: WINGS
  150/300/500/1000/5000; THRUSTERS 250/500/2500/10000.
- **Bonuses** (`bonus/`) — one-time consumables: `SKIP_CHECK_IN` (cost 200) negates a missed
  check-in; `INCREASE_MOMENTUM_JOURNEY` (cost 5) +10 momentum for a journey;
  `INCREASE_CORE_POWER_DAY` (cost 200) +10 momentum for a day.

## Trophies (badges, no payout) — `trophy/`
Awarded on check-in when any threshold is met: streaks **7/14/21** days, momentum **50/75/100**,
reach **Moon/Mars/Saturn/Pluto**, **1/5/10/20** habits marked "formed".

## Onboarding (11 steps) teaches + collects
Reuses the real dashboard screens with a robot-speech overlay. Teaches the rocket/cores/habits/
cockpit metaphor; collects your **first habits**, **first active core**, and the **two daily
check-in times** that drive the whole `isCheckInTime` loop afterward.

## Supporting content (no economy hooks)
`core_quiz` (onboarding self-assessment, *not* wired into starting power in this build),
`goals`, `mantras`, `inspirations` (alien quotes), `funeral`/`fears`/`top_people` (reflective
lists), `self_review` (journaling), `cockpit_list` (dashboard "purpose" lists).

---

## The whole loop in one line
**Do habits → score cores 1–5 nightly (×3 → power, capped) → momentum flies the rocket across
16 destinations → arriving/quests/missions pay credits + drop parts → spend credits on rocket
upgrades (which give real stat boosts) → repeat, chasing streaks and trophies.**

### Known bugs spotted (if we port any of this, fix these)
- `rewards/views.py` combines bonuses+improvements but guards only by the improvements-list
  length → bonus-only reward bands can misfire.
- `add_credits` does `goal.score = +total_credits` (**sets** instead of adds).
- `cores.add_core_power` clamp path **assigns** `user_core_cap` instead of adding, so a single
  high score can jump a near-cap core straight to the cap.
- `destinationHelper.journeyList` has `'The Moons'` typo (id 2); the live map uses the correct
  `allPositions()` path so it's cosmetic, but the legacy lookup for the Moon is broken.
