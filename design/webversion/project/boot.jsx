// boot.jsx — Moore Momentum brand mark (authentic vector), app icon, home screen,
// and the boot / loading animation. Mark paths are the official logo geometry:
//   cls-1 (left "M")          → Ignition Red
//   cls-2 (right "W" + arrow) → Momentum Blue

const MM_RED  = '#e8112d';   // Ignition Red
const MM_BLUE = '#1f9ad6';   // Momentum Blue

// Authentic logo path data (250×250 space)
const MM_PATH_M = 'm80.74,139.95c2.77,4.04,5.73,4.02,8.42-.06,11.61-17.56,23.2-35.14,34.79-52.71,6.42-9.73,12.86-19.44,19.24-29.2.48-.74.99-1.96.7-2.57-.28-.58-1.6-.88-2.48-.9-4.34-.09-8.68.01-13.02-.06-2.7-.05-4.63,1.02-6.13,3.26-8.81,13.2-17.66,26.37-26.5,39.55-2.92,4.36-5.82,8.74-8.76,13.08-1.07,1.58-2.11,1.74-3.27.57-.38-.39-.69-.86-.99-1.31-5.63-8.42-11.26-16.83-16.88-25.25-5.93-8.87-11.85-17.75-17.79-26.62-1.46-2.18-3.43-3.35-6.15-3.28-3.42.09-6.85.01-10.27.02-2.99.01-3.98.97-3.99,3.94,0,37.17,0,74.34,0,111.51,0,2.9.98,3.87,3.86,3.9,3.48.04,6.97.01,10.45.01,4.11,0,4.95-.84,4.95-4.93,0-24.76,0-49.52,0-74.28v-2.34c.21-.11.43-.23.64-.34.52.59,1.11,1.13,1.55,1.77,3.88,5.63,7.74,11.27,11.59,16.91,6.68,9.78,13.33,19.57,20.03,29.33Z';
const MM_PATH_W = 'm110.77,170.31c8.94-13.41,17.92-26.78,26.89-40.17,2.72-4.06,5.41-8.13,8.17-12.16,1.19-1.74,2.35-1.73,3.62-.11.23.29.44.59.64.89,6.56,9.78,13.12,19.57,19.68,29.35,5.06,7.55,10.14,15.1,15.19,22.67,1.24,1.85,2.88,3,5.14,3.03,3.91.05,7.83.06,11.74,0,2.01-.03,3.01-.95,3.35-2.94.14-.84.13-1.7.13-2.56,0-31.3,0-62.6,0-93.9,0-3.47.99-4.47,4.44-4.48,3.73-.01,7.46.01,11.19-.04.48,0,1.21-.27,1.36-.61.17-.38-.12-1.03-.35-1.5-.18-.37-.56-.63-.86-.94-7.09-7.07-14.18-14.14-21.27-21.2-2.41-2.4-3.94-2.4-6.37.01-5.07,5.04-10.13,10.1-15.19,15.15-2.21,2.2-4.45,4.37-6.59,6.64-.43.46-.49,1.27-.72,1.91.61.19,1.21.53,1.82.55,2.93.06,5.87.01,8.8.03,3.25.02,4.38,1.16,4.38,4.43,0,19.87,0,39.74,0,59.6,0,.77-.12,1.54-.19,2.31l-.52.15c-.39-.43-.83-.83-1.16-1.31-1.85-2.65-3.67-5.33-5.5-7.99-8.93-13.04-17.84-26.1-26.8-39.11-2.38-3.46-5.36-3.44-7.83-.07-.29.39-.55.81-.82,1.22-8.74,13.24-17.48,26.48-26.22,39.72-9.18,13.9-18.36,27.8-27.49,41.73-.43.65-.88,1.85-.58,2.26.42.58,1.53.91,2.35.93,4.34.09,8.68-.02,13.02.06,2.92.06,4.97-1.16,6.57-3.55Z';
// tight viewBox around the mark only (excludes the wordmark) — padded so the
// arrow tip (≈y44) is never clipped.
const MM_VIEWBOX = '22 38 206 148';

// ─── The vector mark ───────────────────────────────────────────
// `phase`: 'static' (fully shown) or 'draw' (wipes up + arrow launches).
function LogoMark({ size = 120, phase = 'static', glow = true, idSuffix = '' }) {
  const drawing = phase === 'draw';
  const h = size * (148 / 206);
  const gid = 'mmglow' + idSuffix;
  const mid = 'mmgap' + idSuffix;
  const svgStyle = { position: 'absolute', inset: 0, width: '100%', height: '100%', overflow: 'visible' };
  const filt = glow ? `url(#${gid})` : undefined;
  const Defs = (
    <defs>
      <filter id={gid} x="-30%" y="-30%" width="160%" height="160%">
        <feGaussianBlur stdDeviation="3" result="b" />
        <feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge>
      </filter>
    </defs>
  );
  return (
    <div style={{ position: 'relative', width: size, height: h }}>
      {/* red M */}
      <svg viewBox={MM_VIEWBOX} style={svgStyle} className={drawing ? 'mm-wipe-m' : undefined}>
        {Defs}
        <path d={MM_PATH_M} fill={MM_RED} filter={filt} />
      </svg>
      {/* blue W + arrow — masked to keep a small gap away from the red M */}
      <svg viewBox={MM_VIEWBOX} style={svgStyle} className={drawing ? 'mm-wipe-w' : undefined}>
        {Defs}
        <mask id={mid} maskUnits="userSpaceOnUse" x="0" y="0" width="250" height="250">
          <rect x="0" y="0" width="250" height="250" fill="#fff" />
          {/* dilate the red shape → subtract a thin band from the blue */}
          <path d={MM_PATH_M} fill="#000" stroke="#000" strokeWidth="7"
                strokeLinejoin="round" strokeLinecap="round" />
        </mask>
        <path d={MM_PATH_W} fill={MM_BLUE} filter={filt} mask={`url(#${mid})`} />
      </svg>
    </div>
  );
}

// ─── Wordmark (red MOORE / blue MOMENTUM, as in the logo) ───────
function Wordmark({ fontSize = 15, className = '' }) {
  return (
    <div className={className} style={{
      fontFamily: 'Orbitron, system-ui, sans-serif', fontWeight: 800,
      letterSpacing: '.01em', fontSize, lineHeight: 1, whiteSpace: 'nowrap' }}>
      <span style={{ color: MM_RED }}>MOORE</span>
      <span style={{ color: MM_BLUE }}>MOMENTUM</span>
    </div>
  );
}

// ─── App icon: rounded-squircle tile with the mark ──────────────
function AppIcon({ size = 88, radius }) {
  const r = radius == null ? size * 0.225 : radius;
  return (
    <div style={{
      width: size, height: size, borderRadius: r, position: 'relative', overflow: 'hidden',
      background: 'radial-gradient(120% 120% at 50% 0%, #1a2c66 0%, #0a1030 55%, #06070d 100%)',
      boxShadow: 'inset 0 1px 0 rgba(255,255,255,.14), inset 0 0 0 1px rgba(255,255,255,.05), 0 10px 24px rgba(0,0,0,.5)',
      display: 'grid', placeItems: 'center' }}>
      <div style={{ position: 'absolute', inset: 0,
        background: 'radial-gradient(80% 60% at 30% 18%, rgba(255,255,255,.10), transparent 60%)' }} />
      <div style={{ position: 'absolute', width: '78%', height: '78%', borderRadius: '50%',
        background: `radial-gradient(circle, ${MM_BLUE}33 0%, ${MM_RED}22 45%, transparent 70%)`,
        filter: 'blur(6px)' }} />
      <LogoMark size={size * 0.66} phase="static" glow={true} idSuffix={'icon' + size} />
    </div>
  );
}

// ─── Starfield ──────────────────────────────────────────────────
function Stars({ count = 50 }) {
  const stars = React.useMemo(() => Array.from({ length: count }, () => ({
    x: Math.random() * 100, y: Math.random() * 100,
    s: Math.random() * 1.6 + 0.4, o: Math.random() * 0.5 + 0.2,
    d: Math.random() * 3 })), [count]);
  return (
    <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
      {stars.map((st, i) => (
        <span key={i} style={{ position: 'absolute', left: st.x + '%', top: st.y + '%',
          width: st.s, height: st.s, borderRadius: '50%', background: '#fff', opacity: st.o,
          animation: `mm-twinkle ${2 + st.d}s ease-in-out ${st.d}s infinite` }} />
      ))}
    </div>
  );
}

// ─── iOS-style home screen showing the app icon ─────────────────
function HomeScreen({ onLaunch }) {
  const now = new Date();
  return (
    <div style={{ position: 'absolute', inset: 0, overflow: 'hidden',
      background: 'radial-gradient(130% 90% at 50% -10%, #24306b 0%, #0c1130 45%, #06070d 100%)' }}>
      <Stars count={42} />
      <div style={{ position: 'absolute', top: 72, left: 0, right: 0, textAlign: 'center',
        color: 'rgba(255,255,255,.5)', fontFamily: 'Orbitron, sans-serif', fontSize: 12, letterSpacing: '.3em' }}>
        {now.toLocaleDateString(undefined, { weekday: 'long' }).toUpperCase()}
      </div>
      <div style={{ position: 'absolute', top: 92, left: 0, right: 0, textAlign: 'center',
        color: '#fff', fontFamily: 'Orbitron, sans-serif', fontSize: 44, fontWeight: 700 }}>
        {now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }).replace(/^0/, '')}
      </div>
      <div style={{ position: 'absolute', top: 210, left: 0, right: 0,
        display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 18, padding: '0 22px' }}>
        <button onClick={onLaunch} style={{ background: 'none', border: 'none', cursor: 'pointer',
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 7, padding: 0 }}>
          <AppIcon size={66} />
          <span style={{ color: '#fff', fontSize: 11.5, fontFamily: 'system-ui, sans-serif',
            textShadow: '0 1px 3px rgba(0,0,0,.6)' }}>Moore Momentum</span>
        </button>
      </div>
      <div style={{ position: 'absolute', bottom: 26, left: 0, right: 0, textAlign: 'center',
        color: 'rgba(255,255,255,.45)', fontSize: 11, fontFamily: 'system-ui, sans-serif' }}>
        Tap to launch ↑
      </div>
    </div>
  );
}

// ─── The boot / loading animation ───────────────────────────────
function BootSplash({ onDone, autoLoop = false }) {
  const [run, setRun] = React.useState(0);
  const [pct, setPct] = React.useState(0);

  React.useEffect(() => {
    setPct(0);
    let raf; const start = performance.now(); const DUR = 2400;
    const tick = (now) => {
      const p = Math.min(1, (now - start) / DUR);
      setPct(Math.round((1 - Math.pow(1 - p, 2)) * 100));
      if (p < 1) raf = requestAnimationFrame(tick);
      else if (autoLoop) setTimeout(() => setRun((r) => r + 1), 1400);
      else if (onDone) setTimeout(onDone, 700);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [run, autoLoop, onDone]);

  return (
    <div key={run} style={{ position: 'absolute', inset: 0, overflow: 'hidden',
      background: 'radial-gradient(ellipse at 50% -10%, #1a2860 0%, #06070d 62%), #06070d',
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
      <Stars count={50} />

      <div style={{ position: 'relative', display: 'grid', placeItems: 'center' }}>
        <div className="mm-glow-pulse" style={{ position: 'absolute', width: 230, height: 230, borderRadius: '50%',
          background: `radial-gradient(circle, ${MM_BLUE}44 0%, ${MM_RED}33 40%, transparent 68%)` }} />
        <LogoMark size={172} phase="draw" glow={true} idSuffix="boot" />
      </div>

      <div className="mm-word" style={{ marginTop: 30 }}><Wordmark fontSize={17} /></div>
      <div className="mm-tag" style={{ marginTop: 10, color: 'rgba(241,241,241,.55)',
        fontFamily: 'Orbitron, sans-serif', fontSize: 9.5, letterSpacing: '.34em' }}>
        BUILD YOUR MOMENTUM
      </div>

      <div className="mm-prog" style={{ position: 'absolute', bottom: 64, width: 168 }}>
        <div style={{ height: 3, borderRadius: 3, background: 'rgba(241,241,241,.1)', overflow: 'hidden' }}>
          <div style={{ width: pct + '%', height: '100%',
            background: `linear-gradient(90deg, ${MM_RED}, ${MM_BLUE})`,
            boxShadow: `0 0 8px ${MM_BLUE}`, transition: 'width .08s linear' }} />
        </div>
        <div style={{ marginTop: 9, textAlign: 'center', color: 'rgba(241,241,241,.5)',
          fontFamily: 'Orbitron, sans-serif', fontSize: 9, letterSpacing: '.26em' }}>
          {pct < 100 ? `IGNITION · ${pct}%` : 'MOMENTUM ENGAGED'}
        </div>
      </div>
    </div>
  );
}

// keyframes injected once
if (!document.getElementById('mm-boot-css')) {
  const s = document.createElement('style');
  s.id = 'mm-boot-css';
  s.textContent = `
  @keyframes mm-twinkle { 0%,100%{opacity:.2} 50%{opacity:.85} }
  @keyframes mm-wipe { 0%{clip-path:inset(100% 0 0 0); opacity:0} 12%{opacity:1} 100%{clip-path:inset(0 0 0 0); opacity:1} }
  @keyframes mm-glowpulse { 0%{opacity:0; transform:scale(.7)} 50%{opacity:1} 65%{opacity:.5; transform:scale(1)} 100%{opacity:.85; transform:scale(1.04)} }
  @keyframes mm-fadeup { 0%{opacity:0; transform:translateY(10px)} 100%{opacity:1; transform:none} }

  .mm-wipe-m { animation: mm-wipe .7s cubic-bezier(.3,.7,.3,1) .15s both; }
  .mm-wipe-w { animation: mm-wipe .8s cubic-bezier(.3,.7,.3,1) .6s both; }
  .mm-glow-pulse { opacity:0; animation: mm-glowpulse 1.7s ease 1.1s forwards; }
  .mm-word { opacity:0; animation: mm-fadeup .7s ease 1.6s both; }
  .mm-tag  { opacity:0; animation: mm-fadeup .7s ease 1.9s both; }
  .mm-prog { opacity:0; animation: mm-fadeup .6s ease .4s both; }
  @media (prefers-reduced-motion: reduce) {
    .mm-wipe-m,.mm-wipe-w,.mm-glow-pulse,.mm-word,.mm-tag,.mm-prog{animation:none!important;opacity:1!important;clip-path:none!important;transform:none!important}
  }`;
  document.head.appendChild(s);
}

// ─── Launch device: home screen → boot splash → app ────────────
function LaunchScreen({ onEnter }) {
  const [mode, setMode] = React.useState('home');
  if (mode === 'boot') {
    return <BootSplash onDone={() => { if (onEnter) onEnter(); else setMode('home'); }} />;
  }
  return <HomeScreen onLaunch={() => setMode('boot')} />;
}

Object.assign(window, { LogoMark, Wordmark, AppIcon, HomeScreen, BootSplash, LaunchScreen, Stars, MM_RED, MM_BLUE, MM_PATH_M, MM_PATH_W, MM_VIEWBOX });
