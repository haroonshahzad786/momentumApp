# Moore Momentum — Effects Handoff (stars · co-pilot star · rocket flame)

Three specific effects that Claude Code didn't port correctly. This doc
explains EXACTLY how each one is built. Keep z-index, units, and keyframes
identical to what's listed here — most of the breakage comes from changing
units to px when they should be % / vmin, or losing the `position:absolute`
layer the effect sits on.

---

## 1. Background starfield (the "feels like we're moving" look)

There are **two layers** working together. Both are siblings of the
dashboard root and span the entire viewport.

### 1a. Static twinkling stars

A single fixed-position div with 10 hand-placed star dots painted via
multi-stop `radial-gradient`s. The whole layer twinkles on a 6s ease loop.

```css
.mm-starfield {
  position: absolute; inset: 0; overflow: hidden; pointer-events: none;
  background:
    radial-gradient(ellipse 90% 60% at 50% -10%, rgba(42,125,225,.18), transparent 60%),
    radial-gradient(ellipse 120% 80% at 50% 120%, rgba(155,92,255,.12), transparent 60%),
    radial-gradient(ellipse at 50% 50%, #111c4e 0%, #060b22 60%, #02030a 100%);
}

.mm-stars {
  position: absolute; inset: 0; pointer-events: none;
  background-image:
    radial-gradient(1px   1px   at 12% 18%, rgba(255,255,255,.85), transparent 50%),
    radial-gradient(1px   1px   at 28% 72%, rgba(255,255,255,.6),  transparent 50%),
    radial-gradient(1.5px 1.5px at 64% 30%, rgba(255,255,255,.9),  transparent 50%),
    radial-gradient(1px   1px   at 80% 56%, rgba(255,255,255,.7),  transparent 50%),
    radial-gradient(1px   1px   at 42% 88%, rgba(255,255,255,.55), transparent 50%),
    radial-gradient(2px   2px   at 90% 12%, rgba(255,200,140,.7),  transparent 50%),
    radial-gradient(1px   1px   at  8% 62%, rgba(140,200,255,.7),  transparent 50%),
    radial-gradient(1px   1px   at 56%  8%, rgba(255,255,255,.6),  transparent 50%),
    radial-gradient(1px   1px   at 36% 36%, rgba(255,255,255,.5),  transparent 50%),
    radial-gradient(1.5px 1.5px at 72% 82%, rgba(255,255,255,.6),  transparent 50%);
  animation: mm-twinkle 6s ease-in-out infinite;
}

@keyframes mm-twinkle {
  0%, 100% { opacity: .9; }
  50%      { opacity: .55; }
}
```

Mount order:
```jsx
<div className="mm-starfield" />
<div className="mm-stars" />
<div className="mm-scanlines" />   // optional CRT lines
```

All three are siblings, all `position:absolute; inset:0`, all
`pointer-events:none`, all *below* (lower z-index than) the rocket and UI.

### 1b. Shooting stars (4 diagonal streaks)

Four absolutely-positioned 1px lines drawn with horizontal
`linear-gradient`s, rotated 15°, animated diagonally with a 6s loop and
staggered delays. Mounted inside the rocket area so they pass behind the
rocket.

```jsx
<div style={{ position:'absolute', inset:'-20% -40%',
              pointerEvents:'none', overflow:'hidden', zIndex:0 }}>
  {[
    { top:'8%',  delay:'0s',   color:'#b58aff' },
    { top:'34%', delay:'1.1s', color:'#FFC629' },
    { top:'62%', delay:'2.0s', color:'#2a7de1' },
    { top:'82%', delay:'3.2s', color:'#ff3d8b' },
  ].map((s, i) => (
    <div key={i} style={{
      position:'absolute', top:s.top, left:'-15%',
      width:'45%', height:1,
      background:`linear-gradient(90deg, transparent, ${s.color}, transparent)`,
      boxShadow:`0 0 4px ${s.color}`,
      transform:'rotate(15deg)',
      animation:`mm-shoot 3.6s ease-in-out ${s.delay} infinite`,
    }} />
  ))}
</div>
```

```css
@keyframes mm-shoot {
  0%   { transform: translate(0, 0) rotate(15deg);            opacity: 0; }
  10%  { opacity: 1; }
  40%  { transform: translate(400px, 80px) rotate(15deg);     opacity: 0; }
  100% { transform: translate(400px, 80px) rotate(15deg);     opacity: 0; }
}
```

**Always on** — these run for the lifetime of the dashboard. Don't gate
them behind a "loading" flag; they create the sensation of forward motion.

### Common breakage in Claude Code

- **Stars disappear** → you removed `position:absolute; inset:0` from the
  starfield divs. They MUST be absolute-positioned siblings spanning the
  whole viewport. Don't put them inside flex containers without a min-size.
- **Stars look pixelated / wrong scale** → you converted the
  `radial-gradient` percentages to viewport units. Keep the percentage
  syntax exactly.
- **Shooting stars vanish on narrow screens** → you removed the
  `inset:'-20% -40%'` overflow. That negative inset extends the streak
  layer past the rocket so streaks can fly in/out from off-frame.

---

## 2. Co-pilot star button

Floating purple/blue gradient circle, bottom-right of the dashboard,
pulsing. The icon **inside** is an inline SVG star — NOT an emoji, NOT a
PNG.

```jsx
<button
  onClick={onChat}
  aria-label="Open Co-pilot"
  style={{
    position:'absolute', right:14, bottom:200, zIndex:7,
    width:62, height:62, borderRadius:'50%',
    background:'radial-gradient(circle at 30% 30%, #b58aff 0%, #6b3df5 60%, #2a7de1 100%)',
    border:'1px solid rgba(216,192,255,.6)',
    boxShadow:'0 0 24px rgba(155,92,255,.6), 0 6px 18px rgba(0,0,0,.4)',
    color:'#fff', display:'grid', placeItems:'center', cursor:'pointer',
    animation:'mm-pulse 2.6s ease-in-out infinite',
    padding:0,
  }}>
  <svg width="30" height="30" viewBox="0 0 24 24"
       fill="none" stroke="currentColor" strokeWidth="1.7"
       strokeLinecap="round" strokeLinejoin="round">
    <path d="M12 2 L 14.5 8 L 21 9 L 16.5 13 L 18 20 L 12 16.5 L 6 20 L 7.5 13 L 3 9 L 9.5 8 Z" />
  </svg>
</button>

{/* Label sits directly under the button */}
<div style={{
  position:'absolute', right:0, bottom:182, zIndex:7,
  width:90, textAlign:'center', pointerEvents:'none',
  fontFamily:'Orbitron, system-ui, sans-serif',
  fontSize:9, letterSpacing:'.18em',
  color:'#d8c0ff', textShadow:'0 0 8px rgba(155,92,255,.6)',
  whiteSpace:'nowrap',
}}>CO-PILOT</div>
```

```css
@keyframes mm-pulse {
  0%,100% { box-shadow: 0 0 0 1px rgba(77,155,255,.4),
                        0 0 24px rgba(42,125,225,.55); }
  50%     { box-shadow: 0 0 0 1px rgba(77,155,255,.7),
                        0 0 44px rgba(42,125,225,.95); }
}
```

### Common breakage in Claude Code

- **Icon disappears or shows ★ glyph** → you replaced the inline `<svg>`
  with a Unicode `★` or `Icon name="star"`. Use the exact 10-point star
  path above (`M12 2 L 14.5 8 L 21 9 ...`). It's a single SVG path so
  `currentColor` strokes it white.
- **Button stretches into an oval** → you set `width: 62` without
  `height: 62`, or wrapped it in a flex parent that stretches children.
  Lock both dimensions and use `border-radius: 50%`.
- **Gradient looks flat** → you replaced `radial-gradient(circle at 30% 30%
  ...)` with a `linear-gradient`. The off-center radial is what gives the
  3D orb feel.
- **Label wraps to two lines** → you forgot `whiteSpace:'nowrap'` or sized
  the wrapper too narrow. Width 90px + nowrap fits "CO-PILOT" at 9px
  Orbitron with the .18em letter-spacing.

---

## 3. Rocket flame (engine plume)

A purely-CSS soft flame painted under the rocket. **No PNG, no canvas.**
Built from a `radial-gradient` ellipse with a 2px blur, sized to grow as
the streak grows.

```jsx
<div style={{
  position: 'absolute',
  left: '41%', bottom: '-6%',
  transform: 'translateX(-50%)',
  width: '18%',
  // height scales with streak: base 16% + up to 11% at streak=60
  height: `${16 + Math.min(streak, 60) * 0.18}%`,
  background: 'radial-gradient(ellipse at 50% 20%,' +
                ' #fff5b3 0%,' +
                ' #ffce3a 30%,' +
                ' #ff6a1a 65%,' +
                ' transparent 90%)',
  filter: 'blur(2px)',
  animation: 'mm-plume 1.1s ease-in-out infinite',
  zIndex: 0,   // BEHIND the rocket img (which is z-index:1)
}} />
```

```css
@keyframes mm-plume {
  0%, 100% { transform: translateX(-50%) scaleY(1)   translateY(0); opacity: .85; }
  50%      { transform: translateX(-50%) scaleY(1.18) translateY(2px); opacity: 1; }
}
```

The 4-stop gradient is what makes it look like a real flame:
- `#fff5b3` (pale yellow) — innermost
- `#ffce3a` (saturated yellow) — main body
- `#ff6a1a` (orange) — outer flame
- `transparent` — atmospheric fade

### Common breakage in Claude Code

- **Flame shows as a solid orange oval** → you collapsed the 4-stop
  gradient to 2 stops. Keep all four; the white-hot core is essential.
- **Flame sits OVER the rocket** → wrong z-index. Plume must be `z-index:0`
  and the rocket image `z-index:1`. The plume container should be the
  *first child* of the rocket wrapper, the rocket image the *second*.
- **Flame is centered under the rocket** → the rocket image has its nozzle
  slightly left of center. Use `left: 41%`, NOT 50%. The plume aligns to
  the actual nozzle position in the PNG.
- **Flame doesn't pulse** → you used `transform: scaleY(...)` without the
  `translateX(-50%)` from the base transform, so the keyframe overrides
  the centering. Both keyframe frames MUST include
  `translateX(-50%) scaleY(...)` together.
- **Flame too big / too small** → you used absolute `px`. Keep `width:18%`
  and `height` as a `%` so it scales with the rocket bounding box.

---

## Quick checklist after porting

1. Open the cockpit on a 375px-wide simulator.
2. Confirm: 10 white star dots visible in background. They twinkle.
3. Confirm: 4 colored shooting stars sweep diagonally across the rocket
   area, looping continuously.
4. Confirm: bottom-right co-pilot button is a perfect circle with a
   pulsing purple-to-blue gradient and a 5-pointed white star icon.
   "CO-PILOT" label fits on one line directly underneath.
5. Confirm: under the rocket, a yellow-orange flame glows softly and
   pulses ~1.1s. Sits BEHIND the rocket image. Aligned with the nozzle
   (slightly left of center).
6. Resize browser from 360px to 480px wide. Nothing distorts.

If any of those fail, re-read the section above for that effect — most
breaks come from changing `%` to `px`, removing `position:absolute`, or
swapping an SVG for an emoji.
