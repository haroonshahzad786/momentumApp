# Moore Momentum — Rocket Dashboard Implementation Spec

Brief for Claude Code (or any dev): rebuild the Rocket cockpit so it scales
to any screen size **without distorting the rocket's anatomy**. The bug in
the screenshot is that the panels were positioned with absolute pixels and
broke when the rocket scaled — all overlay positions MUST be expressed as
percentages of the rocket image's own bounding box.

---

## 1. Mental model

The rocket is **not** built with code shapes. It is one PNG plus a fixed
number of PNG overlays positioned *relative to the rocket image*, not the
screen.

```
┌─────────────── screen ───────────────┐
│                                       │
│      ┌─── rocket bounding box ─┐     │  <- this box shrinks/grows
│      │                          │     │     with the viewport
│      │   [rocket-bg PNG]        │     │
│      │   [5 panel PNGs]         │     │
│      │   [5 core icon PNGs]     │     │
│      │   [3 nose-icon buttons]  │     │
│      │                          │     │
│      └──────────────────────────┘     │
└───────────────────────────────────────┘
```

Each overlay is positioned with `left: X%`, `top: Y%`, `width: W%` **of the
rocket bounding box**. The rocket bounding box itself is sized in viewport
units / max-width, so everything scales together.

---

## 2. Asset list (must ship in `/assets`)

| File | Purpose |
|---|---|
| `rocket.png` | Base metal frame, native 516 × 980 (transparent bg) |
| `panel-mindset-color.png` / `panel-mindset-gray.png` | Top wedge |
| `panel-emotional-color.png` / `panel-emotional-gray.png` | Mid-left wing |
| `panel-relationships-color.png` / `panel-relationships-gray.png` | Mid-right wing |
| `panel-physical-color.png` / `panel-physical-gray.png` | Bottom-left |
| `panel-career-color.png` / `panel-career-gray.png` | Bottom-right |
| `core-mindset.png` / `core-emotional.png` / `core-relationships.png` / `core-physical.png` / `core-career.png` | Round icon badges, centered on each panel |
| `icon-habits.png` / `icon-lists.png` / `icon-routines.png` | 3 nose-cone instrument buttons |

The Rocket component must **always** mount all 18 images so the browser
preloads them; only swap `*-color.png` ↔ `*-gray.png` based on active state.

---

## 3. Rocket container — responsive sizing

Native aspect ratio: **516 / 980 ≈ 0.527**. Preserve this.

```css
.rocket-wrap {
  position: relative;
  width: min(70vw, 240px);   /* shrink on phones, cap on tablets */
  aspect-ratio: 516 / 980;
}
```

Inside `.rocket-wrap`, every child uses `position: absolute` with `%`
units. **Never** use `px` for positions, widths, or font sizes inside the
rocket — only inside the icon badges' inner content where they're tied to
that badge's own size.

---

## 4. Exact percentage layout (USE THESE NUMBERS)

These are the field-tested values from the working layout. Coordinates are
in `% of the rocket bounding box`. `iconOffset` is added to the panel's
`center` to nudge the icon inside the panel (some panel shapes have a
visual center that isn't their geometric center).

### 4.1 Five Core panels

| Core | Center (cx, cy) | Width | Icon offset |
|---|---|---|---|
| mindset       | 50, 37 | 53% | 0, 0 |
| emotional     | 34, 47 | 32% | 0, +4 |
| relationships | 68, 47 | 32% | 0, +4 |
| physical      | 36, 69 | 32% | 0, 0 |
| career        | 65, 69 | 32% | 0, 0 |

All five **core icon badges** share one uniform size: `BADGE_W = 22%` of
the rocket bounding box. Center each icon with `translate(-50%, -50%)`.

### 4.2 Three nose-cone instruments (buttons, click → navigate)

| Kind | Center (cx, cy) | Width | Navigates to |
|---|---|---|---|
| habits   | 50.5, 13 | 15.5% | Habits screen |
| lists    | 39,   22 | 11%   | Lists screen |
| routines | 62,   22 | 11%   | Routines screen |

### 4.3 Engine plume (decorative, sits behind rocket)

```
position: absolute;
left: 41%; bottom: -6%;
width: 18%;
height: calc(16% + min(streak, 60) * 0.18%);
transform: translateX(-50%);
background: radial-gradient(ellipse at 50% 20%,
  #fff5b3 0%, #ffce3a 30%, #ff6a1a 65%, transparent 90%);
filter: blur(2px);
animation: plume 1.1s ease-in-out infinite;
z-index: 0;
```

---

## 5. Z-index layering (bottom → top)

| z-index | Layer |
|---|---|
| 0 | Engine plume |
| 0 | Halo glow behind rocket |
| 1 | Rocket frame PNG |
| 2 | Panel PNGs (color or gray) |
| 3 | Core icon badges |
| 4 | Nose instrument buttons (clickable) |

---

## 6. Active vs locked state

For each Core: if `activeCores.includes(coreId)` → show
`panel-{id}-color.png` and the icon in full color with a small color-tinted
drop-shadow glow. Otherwise → `panel-{id}-gray.png` plus the icon with
`filter: grayscale(1) brightness(0.5)` and a pulsing gold padlock overlay.

```css
@keyframes lock-pulse {
  0%, 100% { opacity: 0.6; transform: scale(1); }
  50%      { opacity: 1;   transform: scale(1.06); }
}
```

---

## 7. Preload pattern (avoid piecemeal pop-in)

On mount, call `new Image(); img.src = ...` for every asset listed in §2
inside a `useEffect`. When `Promise.all(...)` resolves, set `ready = true`.

Render the rocket markup **always** but with
`visibility: hidden; opacity: 0; pointer-events: none` while `!ready`. On
`ready === true`, set it to `visible`, `opacity: 1`, and trigger a one-shot
`rocket-launch` keyframe that translates the rocket from `translateY(120%)`
up to `translateY(0)` over 1.1s with ease-out.

Show a small placeholder rocket SVG (just a single white rocket outline)
bobbing with the text "SYSTEMS WARMING" centered in the rocket area while
not ready.

---

## 8. Dashboard chrome (responsive)

Everything outside the rocket scales independently. The dashboard layout
is a vertical flex column at 100% viewport height with these sections:

```
top bar    [hamburger + trophy]  [streak]  [stats panel]   ← row
quick-icons [Lists]  [Routines]  ----  [Habits]  [Tasks]   ← justify-between
rocket area (centered)                                      ← min-height grows
journey arc (planets row)                                   ← fixed height ~80
spacer / co-pilot float                                     ← absolute
daily check-in button                                       ← bottom, full-width
"3/5 cores active · navigator" line                         ← small
```

### Quick-icon row — exact layout

```jsx
<div style={{ display:'flex', justifyContent:'space-between',
              alignItems:'center', padding:'0 14px', marginTop:8 }}>
  <div style={{ display:'flex', gap:8 }}>
    <QuickIcon kind="lists" />
    <QuickIcon kind="routines" />
  </div>
  <div style={{ display:'flex', gap:8 }}>
    <QuickIcon kind="habits" />
    <QuickIcon kind="tasks" />
  </div>
</div>
```

Each `QuickIcon`: 52×52, radius 12, navy translucent bg, 1px navy-blue
border, icon top + 7-pt uppercase label below.

### Rocket area

```jsx
<div style={{ marginTop: -34 }}>   // pulls rocket up into the chrome
  <RocketWrap />
</div>
```

The negative margin closes the gap between quick-icons and rocket — keep
it; it makes the layout work on small phones.

### Co-pilot floating button

Absolute, `right: 14px; bottom: 200px`, 62×62 circle, purple-to-blue
radial gradient, white star SVG. Label "CO-PILOT" in Orbitron 9px directly
below the button.

### Daily Check-in button

```css
.daily-checkin {
  width: 100%;
  padding: 16px 24px;
  border-radius: 999px;  /* pill — NOT square corners */
  background: linear-gradient(180deg, #3a8dff, #1f5fb8);
  border: 1px solid #4d9bff;
  font-family: Orbitron; letter-spacing: 0.14em;
  text-transform: uppercase;
}
```

Container around it: `padding: 24px 20px 72px;` — the generous bottom
padding keeps it clear of the home indicator on iPhones.

---

## 9. Testing matrix

Verify the rocket renders correctly on these widths without panels
sliding off the frame:

- 360px wide (Galaxy S, Pixel 4a, smaller Android)
- 375px (iPhone SE, iPhone 13 mini)
- 390px (iPhone 14)
- 414px (iPhone 14 Plus)
- 430px (iPhone 14 Pro Max)
- 480–720px (foldables open, small tablets)

The rocket should always:
1. Stay centered horizontally
2. Keep its 516:980 aspect ratio
3. Have all 5 panels visibly seated inside the metal frame
4. Have all 3 nose instruments inside the nose cone
5. Not exceed 240px wide on tablets (cap with `max-width`)

---

## 10. Common bugs that match the broken screenshot

- **Panels at wrong size, showing as bare circles** → you used `core-*.png`
  but forgot to also render the `panel-*-color.png` underneath. Both must
  render: panel as background layer, core icon on top.
- **Panels offset from the rocket** → you used fixed pixel positions
  instead of percentages of the rocket bounding box.
- **Panels disappear when narrow** → your `width` is in px instead of `%`.
- **Icons too small/big** → forgot to use the uniform `BADGE_W = 22%`.
- **Pop-in during launch animation** → didn't preload images; mount the
  Rocket component invisibly so the browser caches all PNGs before reveal.

---

## 11. Final result

When done, the rocket should look identical at 360px and 480px viewport
widths — just scaled. No panel shifts, no icon misalignments, no
overlapping CTAs. Stars/shooting-stars animate in the background at all
times.
