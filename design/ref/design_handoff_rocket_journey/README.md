# Handoff: Rocket Journey — Zoom Cinematic + Hull Reveal

## Overview

A single continuous space-journey animation for Moore Momentum. The player's rocket climbs a vertical solar route — **Earth → Moon → Mars → Jupiter → Saturn → Pluto → Station** — and at every arrival the camera zooms in, the rocket's hull peels open, and the player lands on the **cockpit dashboard** (the five Core panels + three nose instruments) where they do their work. When they're done, the hull seals and the rocket launches for the next planet.

Two things that were originally separate animations are merged here into one loop:

```
zoom out → cruise → zoom in → LAND → hull unseals → DASHBOARD (dwell/work)
      ↑                                                      │
      └────────────── launch ← hull seals ←──────────────────┘
```

## About the Design Files

The files in this bundle are **design references created in HTML** — a working prototype that shows the intended look, timing and behavior. They are **not production code to copy directly**.

The task is to **recreate this animation in the target codebase's existing environment** using its established patterns. The shipping surface for this project is **Flutter (web)**, so the expected implementation is Flutter — see "Porting to Flutter" below for the direct mapping. If you are implementing in a different environment (React, Vue, SwiftUI), the same model applies: one fixed-size world, one camera transform, a per-leg timeline.

The prototype is React + inline Babel purely so it could run in a browser without a build step. Do not treat `rocket.jsx` / `dash-rocket.jsx` / `hull-sequence.jsx` as the component boundaries you must ship — they are reference implementations of the math and the layer order.

## Fidelity

**High-fidelity.** Final art, final colors, final timing curves. Positions of the dashboard overlays are field-tested percentages that match the production art exactly — copy them verbatim (see "Cockpit dashboard overlays"). Layout, easing, and durations should be reproduced as specified.

## Screens / Views

### 1. Journey map (the world)

**Purpose:** the player sees the whole route and where they are on it. Free inspection when idle.

**Layout — one fixed world, camera moves.** The route is laid out **once** in a fixed-size world and never re-laid-out. Only a single transform on the world container changes. This is what keeps it smooth.

- World size: **1600 × 5800** logical px. Single vertical lane at **x = 800**.
- Content bounds (used to frame the "see everything" beat): **y 700 → 5700**.
- Planets, bottom (Earth) to top (Station). `y` is the planet's center in world px; `w` is its drawn width; `ar` is the source PNG's aspect ratio (w/h); `seatF` is the fraction of the planet's height above its center where the rocket rests:

  | Planet  | y    | w   | ar        | asset               | seatF |
  |---------|------|-----|-----------|---------------------|-------|
  | Earth   | 5400 | 360 | 595/594   | `planet-earth.png`  | 0.50  |
  | Moon    | 4720 | 190 | 256/256   | `planet-moon.png`   | 0.50  |
  | Mars    | 4030 | 270 | 588/594   | `planet-mars.png`   | 0.50  |
  | Jupiter | 3200 | 450 | 608/595   | `planet-jupiter.png`| 0.50  |
  | Saturn  | 2300 | 780 | 1096/595  | `planet-saturn.png` | 0.45  |
  | Pluto   | 1560 | 180 | 594/594   | `planet-pluto.png`  | 0.50  |
  | Station | 950  | 330 | 712/581   | `station3.png`      | 0.42  |

  Derived: `h = w / ar`, `halfH = h / 2`.
  **Rocket seat (landing point) = `{ x: 800, y: planet.y - planet.h * seatF + 6 }`** — i.e. it sits on top of the body. Saturn and Station use a smaller `seatF` because their rings/structure extend past the body.

- Rocket sprite: **86 × 163** world px (`ROCKET_W = 86`, `ROCKET_H = ROCKET_W * 980/516`), asset `rocket-journey.png` (closed hull). `transform-origin: 50% 88%` so rotation pivots near the engine.
- Planet label: centered under each planet at `y + halfH + 30`, font-size 34, uppercase, `letter-spacing: .3em`, `color: rgba(241,241,241,.75)`.
- Trajectory: a straight dashed vertical line per leg, from `seat(from).y - ROCKET_H` to `seat(to).y + 40`. `stroke-width 3`, `stroke-dasharray "4 18"`, round caps. **Completed legs `rgba(0,169,143,.7)` (teal), upcoming legs `rgba(241,241,241,.22)`.**

**The camera.** Everything is framed against the **HUD-free band**, not the raw viewport — the HUD occupies the bottom **150 px** (`HUD_H`).

```
visH   = max(200, viewportH - 150)
world.transform = translate(viewportW/2, visH/2) scale(s) translate(-focusX, -focusY)
```

- **Landed frame** (`landedCam`) — fits `[planet top − rocket − 40 headroom … planet bottom + 100 for label]` into the band, **never zooming past scale 1**:
  ```
  top = p.y - p.h*p.seatF - ROCKET_H - 40
  bot = p.y + p.halfH + 100
  s   = min(1, visH*0.92 / (bot-top), viewportW*0.9 / (p.w*1.1))
  focus = { x: 800, y: (top+bot)/2 }
  ```
- **Full-route frame** (`fit`) — `min(viewportW/1600, visH/5000) * 0.94`, focus `{ x: 800, y: (700+5700)/2 = 3200 }`.
- Free interaction when idle: wheel zooms about the cursor (clamped `fit*0.7 … 2.5`), drag pans. Zoom/pan is **disabled during a flight**; a click mid-flight skips to the landed state.
- Current planet is persisted (`localStorage['mm-journey-planet']`) and restored **zoomed-in and landed** on reload — never replay the cinematic on refresh.

### 2. Cockpit overlay (hull reveal + dashboard)

**Purpose:** the payoff at every arrival. This is where the player works.

Full-screen overlay above the map: `position: fixed; inset: 0; z-index: 40`, centered column, `gap: 18px`, background `radial-gradient(ellipse at 50% 40%, rgba(8,12,34,.82), rgba(2,3,10,.96))` + `backdrop-filter: blur(6px)`, fades in over **350 ms**.

- Kicker: "HULL UNSEALING" / "SEALING HULL" — 13px, weight 800, `letter-spacing .3em`, uppercase, `rgba(241,241,241,.6)`.
- Below it the planet name — 30px, weight 800, `letter-spacing .06em`, uppercase.
- The rocket, at `height = min(520, viewportH * 0.56)`, rendered at **90%** of that height.
- Buttons appear only after the reveal finishes: "BACK TO MAP" (ghost) and "SEAL & LAUNCH → {next}" (primary).

### 3. HUD (persistent, bottom)

`position: fixed; bottom: 0; z-index: 20`, column, `gap: 10px`, `padding: 0 16px 20px`. `pointer-events: none` on the container, `auto` on children so the map stays draggable behind it.

- **Planet chips** — pill row in a `rgba(10,13,30,.7)` + `blur(10px)` capsule. Current chip: `--mm-blue` fill, white text, `0 0 16px rgba(42,125,225,.6)` glow. Visited: teal text. Unvisited: `rgba(241,241,241,.5)`. Clicking a chip cold-jumps to that planet (cancels any auto-run).
- **Actions** — "FULL JOURNEY" (ghost), "OPEN HULL" (ghost), "LAUNCH → {next}" (primary), and a **0.5× / 1× / 2×** speed selector. All button text 13px / weight 800 / `letter-spacing .12em` / uppercase, `border-radius: 999px`, `padding: 12px 26px`.
- Hint line: "scroll to zoom · drag to pan · click anywhere mid-flight to skip", 11px, `rgba(241,241,241,.4)`.

## Interactions & Behavior

### The flight timeline (per leg)

One timeline per leg, three beats. Base durations (divide all by the speed multiplier):

| Beat | Duration | What happens |
|---|---|---|
| 1. Pull back | **1000 ms** | scale `landed → fit`, focus lerps to the full-route center. Rocket lifts ~30 px in the last 40% of the beat, plume ramps in. Player sees every stage at once. |
| 2. Cruise | **2600 ms × pace** | rocket travels `t: 0 → 0.86` of the leg. Camera **holds the full-route frame** (do not drift it — content slides under the HUD if you do). |
| 3. Approach + land | **1500 ms** | `t: 0.86 → 1.0` (`easeOutCubic`), scale `fit → landed`, plume fades to 0. |

- `pace = 0.88^legIndex` — each successive leg's cruise is 12% shorter, so later legs feel faster.
- Zoom beats use **`easeInOutCubic`**; the approach uses **`easeOutCubic`**. Linear zoom looks mechanical.
- **Scale must blend geometrically**, not linearly: `s = a * (b/a)^e`. Linear scale interpolation makes the pull-back feel like it stalls.
- **Pin the subject's screen position across zoom transitions.** Solve the focus each frame so the rocket's *screen* y is a lerp between its start and end screen positions:
  ```
  screenY(worldY, focusY, s) = visH/2 + (worldY - focusY) * s
  camPin(worldY, y0, y1, s, e) = { fx: 800, fy: worldY - (lerp(y0,y1,e) - visH/2) / s, s }
  ```
  Without this, liftoff and touchdown swing behind the HUD mid-zoom.
- On touchdown: a dust puff ellipse at the seat — scales `0.2 → 2.6`, opacity `0.9 → 0`, **900 ms** `ease-out`.
- Honor reduced-motion: skip straight to the landed state.

### The hull reveal

Frame-flip sequence, **780 ms per frame**. Frame order for OPEN:

```
[ rocket-journey.png, armor-1.png, armor-2.png, armor-3.png ] → COCKPIT DASHBOARD
```

- **`stop` (depth) controls how many armor frames are traversed, not where the sequence ends.** Every arrival — Earth included — always terminates on the cockpit dashboard. The armor plates are the reveal, not the endpoint.
- Depth per arrival: `depth = clamp(planetIndex + 1, 1, 4)` → Earth peels 1 plate, Moon 2, Mars 3, Jupiter/Saturn/Pluto/Station all 4.
- CLOSE plays the exact same list reversed.
- Frames are **mounted once** and toggled via `opacity` + `visibility` (never unmounted) so a replay never refetches.
- **Register every frame on the rocket BODY, not the image box.** The source arts have different transparent padding; matching image heights makes the silhouette jump between frames. Each frame carries its measured alpha bounding box and is scaled/offset so the body is a constant height:
  ```
  s  = targetBodyHeight / (box.y1 - box.y0 + 1)
  w  = nat.w * s;  h = nat.h * s
  dx = (nat.w/2 - (box.x0+box.x1)/2) * s
  dy = (nat.h/2 - (box.y0+box.y1)/2) * s
  ```
  Measured boxes (native px):

  | Frame | native | body bbox (x0,y0,x1,y1) |
  |---|---|---|
  | `rocket-journey.png` | 320 × 608 | 15, 14, 308, 575 |
  | `armor-1/2/3.png`    | 430 × 775 | 51, 24, 376, 695 |
  | `rocket.png` (cockpit) | 330 × 627 | 16, 16, 317, 593 |

- The armor arts ship **without wings** — `hull-wings.png` is layered *behind* them (scaled to ~1.04× body width, wing bottoms seated at the hull base) and hidden on the closed shell and cockpit frames, which have their own fins.
- Target body height = **90%** of the overlay's available height.

### The merged loop ("Full journey")

An `auto` flag drives the whole chain unattended:

1. Settle on Earth → after **500 ms**, hull opens.
2. Reveal finishes → **1800 ms dwell** on the dashboard (this stands in for the player actually working).
3. Hull seals (reverse frames).
4. Seal completes → `flyLeg(current)`.
5. Landing → after **850 ms**, hull opens again. Repeat through Station.

All durations divide by the speed multiplier. Any manual action — Back to map, a planet chip, or clicking mid-flight — sets `auto = false` and hands control back to the player. **In the real app, replace the 1800 ms dwell with "the player closed the dashboard."**

### Galaxy background (three layers, back to front)

1. **Nebula** — static, `position: absolute; inset: 0`:
   ```css
   background:
     radial-gradient(900px 620px at 22% 18%, rgba(88,60,190,.34), transparent 68%),
     radial-gradient(1000px 700px at 82% 72%, rgba(0,120,150,.26), transparent 70%),
     radial-gradient(700px 500px at 62% 12%, rgba(190,60,120,.18), transparent 72%),
     radial-gradient(ellipse at 50% 45%, #0a1030 0%, #06070d 58%, #02030a 100%);
   ```
2. **Orbit rings** — four concentric ellipses centered on the viewport, `rotate(-14deg)`, `border: 1px solid rgba(160,190,255,.13)`, container `opacity: .5`. Sizes (w × h in `vmax`): 150×62, 108×44, 72×29, 44×18.
3. **Starfield** — a `<canvas>` that fills the stage, `pointer-events: none`. **This is the speed cue.**

   - Density: **one star per 7000 px²** of canvas area.
   - Per star: `x, y` random; `depth d = 0.3 + r²·1.5` (squared for parallax weighting); `radius 0.4–1.9`; `alpha 0.25–0.9`; color white, with a 16% chance of a blue (`190,215,255`) or amber (`255,214,190`) tint.
   - Each frame: `y += warp * d * dt`. Wrap to the top when a star's trail clears the bottom.
   - Trail length `= warp * 0.055 * d`. If `> 2.5 px`, draw a vertical line with a transparent→`alpha` gradient (`lineWidth = r*1.1`, round cap); otherwise draw a dot. That threshold is what turns points into streaks as speed rises.
   - `warp` eases toward a target: `warp += (target - warp) * min(1, dt*3.2)`.
   - **Targets:**
     - Idle (docked at planet *i*): `8 + i*5`
     - Flying leg *i*: `300 * 1.42^i × speedMultiplier`, cross-faded by the plume value so it ramps in on liftoff and out on touchdown.

     That gives Earth→Moon ≈ 300 and Pluto→Station ≈ 1750 — each leg visibly faster than the last.
   - `devicePixelRatio` capped at 2. Rebuild on resize (`ResizeObserver` on the parent).

### Engine fire (plume)

Two variants, same recipe:

```css
background: radial-gradient(ellipse at 50% 15%, #fff5b3 0%, #ffce3a 30%, #ff6a1a 65%, transparent 90%);
filter: blur(2px);
animation: mm-plume .5s ease-in-out infinite;   /* 1.1s on the dashboard */
transform-origin: top;
```
```css
@keyframes mm-plume { 0%,100% { transform: translateX(-50%) scaleY(1) } 50% { transform: translateX(-50%) scaleY(1.18) } }
```

- **Flight plume** (map rocket): `left: 50%; bottom: -24%; width: 26%; height: 34%`, `.5s` cycle. `opacity` is driven by the timeline — 0 when docked, ramps to 1 during beat 1, holds through cruise, fades to 0 on touchdown.
- **Dashboard plume** (cockpit): `left: 50.5%; bottom: -6%; width: 18%`, `1.1s` cycle, height `16 + min(streak,60)*0.18` % — it grows with the player's streak. **`left: 50.5%` is the rocket body's true horizontal midpoint** (bbox 16…317 of 330 native px); do not use 50% or the fire sits off-center.

### Cockpit dashboard overlays

Percentages of the rocket frame's box. **These are the production-tested values — copy verbatim.**

Five Core panels — `panel-{id}-color.png` when the Core is active, `panel-{id}-gray.png` when locked, `transform: translate(-50%,-50%)`, `transition: opacity .3s`:

| Core | hex (icon glow) | center [x%, y%] | width % | icon offset |
|---|---|---|---|---|
| mindset | `#e8744a` | 50, 37 | 53 | — |
| emotional | `#4cc8c2` | 34, 47 | 32 | [0, +4] |
| relationships | `#d977a0` | 68, 47 | 32 | [0, +4] |
| physical | `#8a5fc4` | 36, 69 | 32 | — |
| career | `#5fa86b` | 65, 69 | 32 | — |

- Core icon badge: uniform **22%** width, `aspect-ratio 1/1`, `border-radius 50%`, `object-fit cover`, centered on its panel + `iconOffset` (the teardrop panels' visual centers aren't their geometric centers).
- Active icon: `drop-shadow(0 0 4px {hex}aa)`. Locked: `grayscale(1) brightness(.5) contrast(.9)` plus a **`#FFC629` padlock** glyph at 40% of the badge, `mm-lockPulse 1.8s ease-in-out infinite`.
- Three nose instruments — clickable buttons, route to habits / lists / routines:

  | Instrument | asset | center [x%, y%] | width % |
  |---|---|---|---|
  | habits | `icon-habits.png` | 50.5, 13 | 15.5 |
  | lists | `icon-lists.png` | 39, 22 | 11 |
  | routines | `icon-routines.png` | 62, 22 | 11 |

- Halo behind the rocket: `inset: 10% -10% -10% -10%`, `radial-gradient(ellipse at 50% 45%, rgba(42,125,225,.22) 0%, transparent 60%)`, `blur(20px)`.
- Layer order (back → front): plume → halo → engine nozzle → wings → rocket frame → Core panels → icon badges → nose buttons.

## State Management

Only three pieces of React state drive renders; **everything per-frame lives in a mutable ref and writes directly to `style.transform`** — never per-frame `setState`.

| State | Type | Purpose |
|---|---|---|
| `current` | int | index of the docked planet; persisted to localStorage |
| `mode` | `'idle' \| 'flying'` | gates pan/zoom and button enablement |
| `hull` | `null \| { dir: 'open' \| 'close' }` | cockpit overlay visibility + direction |
| `speed` | 0.5 \| 1 \| 2 | duration divisor |
| `puff` | `{x, y, key} \| null` | one-shot touchdown dust |

Mutable (ref, no re-render): `cam {fx, fy, s}`, `rafId`, `viewport {w,h}`, `anim {to}`, `warp` (current), `warpT` (target), `drag`, `auto`.

**Animation API to build against:** `playLeg(fromPlanet, toPlanet)` for the cinematic and `jumpTo(planet)` for cold-start. The animation layer should stay **dumb about progression rules** — which level maps to which planet, and what advances the player, is not defined here and should be injected by the game logic.

## Design Tokens

Colors (from `styles.css`):

| Token | Hex | Use |
|---|---|---|
| `--mm-blue` | `#2a7de1` | primary actions, glow |
| blue light | `#4d9bff` | button gradient top, link hover |
| `--mm-teal` | `#00a98f` | completed legs, visited chips |
| `--mm-red` | `#ea0029` | ignition (unused here) |
| gold | `#FFC629` | lock badges |
| deep space | `#02030a` | stage base |
| space mid | `#06070d`, `#0a1030` | nebula stops |
| foreground | `#f1f1f1` | text (used at .4 / .5 / .6 / .75 alpha) |

Fire gradient stops: `#fff5b3` → `#ffce3a` → `#ff6a1a` → transparent.

Spacing: 6 / 10 / 16 / 18 / 20 / 26 / 30 px. Radii: `10px` (panels), `999px` (all pills/buttons). HUD reserve: **150 px**.

Type: `--f-display` (from `styles.css`) for all UI chrome. Scale: 11px hint · 11px chip · 13px kicker/button · 15px title · 30px planet name (overlay) · 34px planet label (world). Weights 700–800, `letter-spacing .06em–.3em`, uppercase throughout.

Easings: `easeInOutCubic` (zoom), `easeOutCubic` (approach/land), `ease-in-out` (plume pulse), `ease-out` (dust puff).

## Assets

All in `assets/` in this bundle. Client-supplied art, already downscaled for web.

**Planets & station** — `planet-earth.png`, `planet-moon.png`, `planet-mars.png`, `planet-jupiter.png`, `planet-saturn.png`, `planet-pluto.png`, `station3.png`

**Rocket / hull frames** — `rocket-journey.png` (closed hull, map sprite + reveal frame 0), `armor-1.png`, `armor-2.png`, `armor-3.png` (peel frames), `rocket.png` (cockpit dashboard frame), `rocket-cockpit.png` (duplicate of the cockpit frame, kept so the journey and the main dashboard can diverge), `hull-wings.png`, `hull-engine.png`, `hull-interior.png` (alternate interior frame used by `dash-rocket.jsx`)

**Dashboard overlays** — `core-{mindset,emotional,relationships,physical,career}.png`, `panel-{core}-color.png` + `panel-{core}-gray.png` (10 files), `icon-habits.png`, `icon-lists.png`, `icon-routines.png`

**Not assets:** the starfield, nebula, orbit rings, engine fire and dust puff are **all generated in code** — canvas and CSS gradients, no image files. Reproduce them from the recipes above.

### ⚠️ Missing art

**`01-rocket-armor.png` and `02-rocket-armor.png` were never delivered** — only frames 03, 04 and 05 arrived (bundled here as `armor-1/2/3.png`). With 4 hull frames covering 7 arrivals, Jupiter through Station all traverse the same maximum depth. Once the two missing plates arrive, add them to the front of the frame list and every arrival gets a visibly distinct peel depth. No other code changes needed.

## Porting to Flutter

Direct mapping of the prototype to the shipping surface:

- **World + camera** → `InteractiveViewer` with a `TransformationController`, `constrained: false`, `minScale: fitScale*0.7`, `maxScale: 2.5`, child a `SizedBox` of the world size wrapping a `Stack`. Scripted camera moves write matrices into the same controller, which gives you free pinch/scroll inspection for nothing.
  ```dart
  Matrix4 cameraFor(Offset focus, double scale, Size vp) =>
      Matrix4.identity()
        ..translate(vp.width / 2, visibleHeight / 2)
        ..scale(scale)
        ..translate(-focus.dx, -focus.dy);
  ```
- **Per-leg timeline** → one `AnimationController` with a `TweenSequence` of the three beats. Legs are straight vertical lines, so a simple lerp is enough — no `PathMetrics` needed, and the rocket stays upright the whole way.
- **Derive the base zoom from the viewport**, never hardcode it: `fitScale = min(vp.width/1600, visibleHeight/5000) * 0.94`.
- **Pre-size the planet PNGs** — pass `cacheWidth` on `Image.asset`, or ship two resolutions and swap at a scale threshold. Six large planet images scaled to 0.2 will chew GPU memory.
- **`RepaintBoundary`** the nebula, orbit rings and planets. Only the starfield and rocket layers should repaint per frame.
- **Starfield** → one `CustomPainter` driven by a `Ticker`; it's the only thing that needs a per-frame repaint.
- **Test in release** (`flutter run -d chrome --release`) — debug-mode canvas perf on web is misleadingly bad.
- **Persist camera state, not just the planet** — on cold start, `jumpTo` the saved planet zoomed-in and landed. Never replay the cinematic on refresh.
- **Skip/tap-to-finish is required** — a ~5s cinematic is delightful once and irritating on the fifth viewing. Also honor `MediaQuery.disableAnimations`.

## Files

| File | Contents |
|---|---|
| `Rocket Journey.html` | the prototype: world layout, camera math, flight timeline, starfield, HUD, merged loop |
| `hull-sequence.jsx` | `HullSequence` — frame-flip reveal, body-bbox registration (`hullFit`), wings layer |
| `rocket.jsx` | `Rocket` — the cockpit dashboard: Core panels, icon badges, lock states, nose buttons |
| `dash-rocket.jsx` | `DashRocket` — alternate cockpit built on `hull-interior.png` with a separate engine/wings layer. Reference only; the shipping cockpit is `rocket.jsx` |
| `styles.css` | Moore Momentum design tokens (`--mm-*`, `--f-display`) and shared keyframes |

Open `Rocket Journey.html` from a local web server (not `file://` — the Babel scripts need HTTP) to watch the animation. Press **FULL JOURNEY** to see the complete merged loop end to end; the **2×** speed button makes reviewing it quicker.
