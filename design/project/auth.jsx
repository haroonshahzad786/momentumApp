// auth.jsx — Intro carousel, Sign-up, Sign-in, and guest "skip" flow.
// Mocks Firebase: state lives in the host tweak block, persisted to disk.

// ─── Mini Firebase mock ──────────────────────────────────────
// In a real build this calls firebase.auth().createUserWithEmailAndPassword
// or signInAnonymously(). Here we synthesize a uid + display name and stash
// it on the user's account.
function mockFirebaseAuth(action, payload = {}) {
  const uid = 'mm_' + Math.random().toString(36).slice(2, 11);
  if (action === 'guest')   return { uid, isGuest: true,  email: null,             displayName: 'Cadet ' + uid.slice(3,6).toUpperCase() };
  if (action === 'signup')  return { uid, isGuest: false, email: payload.email,    displayName: payload.name || payload.email.split('@')[0] };
  if (action === 'signin')  return { uid, isGuest: false, email: payload.email,    displayName: payload.email.split('@')[0] };
  return null;
}

// ─── (kept) sky-and-grass background — no longer used by intro,
//     but available if you want the daytime treatment elsewhere.
function SkyGround({ children }) {
  return (
    <div style={{
      width:'100%', height:'100%', position:'relative', overflow:'hidden',
      background:
        'linear-gradient(180deg, #7fc7ff 0%, #b9e2ff 45%, #d8eeff 62%, #6fb35c 62%, #4d8f3d 100%)',
    }}>
      {/* clouds */}
      {[
        { left:'8%',  top:'18%', s:1   },
        { left:'70%', top:'12%', s:.8  },
        { left:'40%', top:'28%', s:.6  },
        { left:'82%', top:'34%', s:.5  },
      ].map((c, i) => (
        <div key={i} style={{
          position:'absolute', left:c.left, top:c.top,
          transform:`scale(${c.s})`, opacity:.85,
        }}>
          <svg width="80" height="30" viewBox="0 0 80 30">
            <ellipse cx="20" cy="20" rx="18" ry="9" fill="#fff" />
            <ellipse cx="38" cy="14" rx="14" ry="11" fill="#fff" />
            <ellipse cx="56" cy="18" rx="16" ry="10" fill="#fff" />
          </svg>
        </div>
      ))}
      {/* distant mountains */}
      <svg viewBox="0 0 400 80" preserveAspectRatio="none" style={{ position:'absolute', left:0, right:0, bottom:'38%', width:'100%', height:60 }}>
        <polygon points="0,80 60,30 110,60 170,20 240,55 310,25 380,50 400,40 400,80" fill="#7a9ab0" opacity=".55" />
        <polygon points="0,80 80,50 150,70 220,40 290,65 360,45 400,55 400,80" fill="#5b7a8f" opacity=".45" />
      </svg>
      {/* grass texture lines */}
      <div style={{
        position:'absolute', left:0, right:0, top:'62%', bottom:0,
        background:
          'repeating-linear-gradient(95deg, rgba(0,0,0,.04) 0, rgba(0,0,0,.04) 2px, transparent 2px, transparent 14px),' +
          'linear-gradient(180deg, #7bb96a 0%, #3f7a32 100%)',
      }} />
      {children}
    </div>
  );
}

// ─── Intro carousel: 3 slides with copy in a viewport-shaped panel ───
// ─── Slide 1 hero: the 5-Core rocket illustration (bck.png) ───
// Single image with all 5 icons baked in — fills the hero area.
function IntroHeroCores() {
  return (
    <div style={{ position:'relative', width:'100%', height:'100%' }}>
      {/* faint orbital rings behind the rocket */}
      <svg viewBox="0 0 300 300" preserveAspectRatio="xMidYMid meet"
           style={{ position:'absolute', inset:0, width:'100%', height:'100%' }}>
        <circle cx="150" cy="150" r="90"  fill="none" stroke="rgba(155,92,255,.28)" strokeWidth=".7" strokeDasharray="2 3" />
        <circle cx="150" cy="150" r="122" fill="none" stroke="rgba(42,125,225,.22)" strokeWidth=".7" strokeDasharray="2 3" />
      </svg>
      {/* halo */}
      <div style={{
        position:'absolute', left:'50%', top:'50%', transform:'translate(-50%, -50%)',
        width:'78%', height:'78%', borderRadius:'50%',
        background:'radial-gradient(circle, rgba(42,125,225,.32) 0%, transparent 60%)',
        filter:'blur(14px)', pointerEvents:'none',
      }} />
      {/* hero rocket — pushed toward the top, gentle up/down bob */}
      <div style={{
        position:'absolute', left:0, right:0, top:'-30%',
        height:'100%', display:'grid', placeItems:'center',
        animation:'mm-bob 2.6s ease-in-out infinite',
      }}>
        <img src="assets/intro-cores.png" alt="" style={{
          maxWidth:'100%', maxHeight:'100%', width:'auto', height:'auto',
          objectFit:'contain',
          filter:'drop-shadow(0 8px 18px rgba(0,0,0,.45)) drop-shadow(0 0 28px rgba(42,125,225,.45))',
        }} />
      </div>
    </div>
  );
}

// ─── Slide 2 hero: planet journey arc with rocket angled along the tangent ───
function IntroHeroJourney() {
  // Curve: M 24 160 Q 80 20 150 70  (yellow ascent)  Q 220 110 280 130 (dashed)
  // Rocket placed near apex of yellow arc (t≈0.6) where it's traveling right
  // and curving downward — gives the classic "cresting the trajectory" pose.
  const planets = [
    { name:'EARTH',   x:8,  y:82, c:'#3aa6ff', reached:true,  big:true },
    { name:'MOON',    x:24, y:54, c:'#cfd2dc', reached:true },
    { name:'JUPITER', x:66, y:44, c:'#d9a86b' },
    { name:'SATURN',  x:84, y:64, c:'#e8c178' },
  ];
  return (
    <div style={{ position:'relative', width:'100%', height:'100%' }}>
      <svg viewBox="0 0 300 200" preserveAspectRatio="none"
           style={{ position:'absolute', inset:0, width:'100%', height:'100%' }}>
        <defs>
          <linearGradient id="intro-arc" x1="0" x2="1">
            <stop offset="0%" stopColor="#2a7de1" stopOpacity=".9" />
            <stop offset="100%" stopColor="#9b5cff" stopOpacity=".7" />
          </linearGradient>
        </defs>
        {/* full route (dashed) */}
        <path d="M 24 160 Q 80 20 150 70 Q 220 110 280 130"
              fill="none" stroke="url(#intro-arc)" strokeWidth="1.5" strokeDasharray="4 5" />
        {/* traversed portion (yellow) */}
        <path d="M 24 160 Q 80 20 150 70"
              fill="none" stroke="#FFC629" strokeWidth="2"
              style={{ filter:'drop-shadow(0 0 6px #FFC629)' }} />
      </svg>
      {planets.map((p) => (
        <div key={p.name} style={{ position:'absolute', left:`${p.x}%`, top:`${p.y}%`,
            transform:'translate(-50%, -50%)', textAlign:'center' }}>
          <div style={{
            width: p.big ? 22 : 14, height: p.big ? 22 : 14, borderRadius:'50%',
            background:`radial-gradient(circle at 30% 30%, ${p.c}, ${p.c}77)`,
            boxShadow: p.reached ? `0 0 12px ${p.c}` : 'none',
            opacity: p.reached ? 1 : .5, margin:'0 auto',
          }} />
          <div className="t-display-x" style={{ fontSize:7, letterSpacing:'.14em',
            color: p.reached ? p.c : 'rgba(255,255,255,.5)', marginTop:4 }}>{p.name}</div>
        </div>
      ))}
      {/* Rocket: positioned at apex of yellow arc; rotated so its nose
          aligns with the path tangent. The default image points UP, so a
          clockwise rotation of ~80° points it right-and-slightly-down along
          the descent toward Jupiter. */}
      <div style={{
        position:'absolute', left:'42%', top:'30%',
        transform:'translate(-50%, -50%) rotate(78deg)',
        width:70, height:104,
      }}>
        <img src="assets/intro-cores.png" alt="" style={{
          width:'100%', height:'100%', objectFit:'contain',
          filter:'drop-shadow(0 0 16px #FFC629)',
        }} />
      </div>
    </div>
  );
}

// ─── Slide 3 hero: streak flame + trophy preview ───
function IntroHeroTrophies() {
  return (
    <div style={{ position:'relative', width:'100%', height:'100%',
        display:'grid', gridTemplateColumns:'1.1fr 1fr', gap:14, alignItems:'center', padding:'0 4%' }}>
      <div style={{ display:'flex', flexDirection:'column', alignItems:'center' }}>
        <div style={{ width:96, height:128, position:'relative',
          filter:'drop-shadow(0 0 24px #ea002988) drop-shadow(0 0 10px #FFC629)',
          animation:'mm-flame 1.2s ease-in-out infinite' }}>
          <svg viewBox="0 0 36 36" width="100%" height="100%">
            <defs>
              <radialGradient id="intro-flame" cx="50%" cy="80%" r="60%">
                <stop offset="0%"  stopColor="#fff" />
                <stop offset="35%" stopColor="#FFC629" />
                <stop offset="75%" stopColor="#ea0029" />
                <stop offset="100%" stopColor="#9b5cff" stopOpacity="0" />
              </radialGradient>
            </defs>
            <path d="M18 4 C 12 12, 8 16, 8 22 C 8 28, 12 32, 18 32 C 24 32, 28 28, 28 22 C 28 18, 24 14, 22 10 C 21 14, 19 16, 17 14 C 17 10, 18 7, 18 4 Z" fill="url(#intro-flame)" />
          </svg>
        </div>
        <div className="t-display t-num" style={{ fontSize:32, color:'#fff', marginTop:6 }}>47</div>
        <div className="t-display-x" style={{ fontSize:9, letterSpacing:'.2em', color:'var(--mm-yellow)' }}>DAY STREAK</div>
      </div>
      <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:8 }}>
        {[
          { i:'🚀', c:'#2a7de1' },
          { i:'🌙', c:'#cfd2dc' },
          { i:'🔥', c:'#ea0029' },
          { i:'⚡', c:'#FFC629' },
          { i:'🪐', c:'#9b5cff', l:true },
          { i:'⭐', c:'#ff3d8b', l:true },
        ].map((t, i) => (
          <div key={i} style={{
            aspectRatio:'1/1',
            background: t.l ? 'rgba(241,241,241,.05)' : `radial-gradient(circle at 30% 30%, ${t.c}55, transparent 70%)`,
            border:`1px solid ${t.l ? 'rgba(241,241,241,.12)' : t.c+'77'}`,
            borderRadius:8, display:'grid', placeItems:'center', fontSize:22,
            opacity: t.l ? .35 : 1,
            boxShadow: t.l ? 'none' : `0 0 12px ${t.c}55`,
            filter: t.l ? 'grayscale(1)' : 'none',
          }}>{t.i}</div>
        ))}
      </div>
    </div>
  );
}

// ─── Slide 4 hero: AI Co-pilot star + chat preview ───
function IntroHeroCopilot() {
  return (
    <div style={{ position:'relative', width:'100%', height:'100%',
        display:'grid', gridTemplateColumns:'1fr 1.4fr', gap:14, alignItems:'center', padding:'0 4%' }}>
      {/* Big animated star */}
      <div style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:8 }}>
        <div style={{
          width:90, height:90, borderRadius:'50%',
          background:'radial-gradient(circle at 30% 30%, #b58aff 0%, #6b3df5 55%, #2a7de1 100%)',
          display:'grid', placeItems:'center',
          boxShadow:'0 0 30px rgba(155,92,255,.7), 0 0 60px rgba(42,125,225,.45)',
          animation:'mm-bob 2.6s ease-in-out infinite',
        }}>
          <svg width="46" height="46" viewBox="0 0 24 24" fill="#fff" stroke="#fff" strokeWidth=".7" strokeLinejoin="round">
            <path d="M12 2 L 14.6 8.4 L 21.5 9.1 L 16.3 13.6 L 17.9 20.4 L 12 16.7 L 6.1 20.4 L 7.7 13.6 L 2.5 9.1 L 9.4 8.4 Z" />
          </svg>
        </div>
        <div className="t-display-x" style={{ fontSize:9, letterSpacing:'.22em', color:'#d8c0ff' }}>CO-PILOT</div>
        <div style={{ fontSize:9, color:'#00ff88', display:'flex', alignItems:'center', gap:5,
            fontFamily:'var(--f-display)', letterSpacing:'.14em' }}>
          <span style={{ width:6, height:6, borderRadius:'50%', background:'#00ff88',
            boxShadow:'0 0 6px #00ff88' }} />
          ONLINE
        </div>
      </div>
      {/* Mini chat preview */}
      <div style={{
        background:'rgba(17,28,78,.55)', backdropFilter:'blur(10px)',
        border:'1px solid rgba(155,92,255,.35)', borderRadius:12,
        padding:10, display:'flex', flexDirection:'column', gap:7,
        boxShadow:'0 0 18px rgba(155,92,255,.2)',
      }}>
        {[
          { from:'ai', text:'Pattern: Mindset dipped 3 days. Want a tweak?' },
          { from:'me', text:'Yes please' },
          { from:'ai', text:'Move meditation to right after coffee. Lower friction.' },
        ].map((m, i) => (
          <div key={i} style={{
            alignSelf: m.from === 'me' ? 'flex-end' : 'flex-start',
            maxWidth:'88%',
            padding:'6px 9px',
            borderRadius: m.from === 'me' ? '10px 10px 3px 10px' : '10px 10px 10px 3px',
            background: m.from === 'me'
              ? 'linear-gradient(180deg, #3a8dff 0%, #1f5fb8 100%)'
              : 'rgba(155,92,255,.18)',
            border: m.from === 'me' ? '1px solid rgba(77,155,255,.5)' : '1px solid rgba(155,92,255,.35)',
            color:'#fff', fontSize:9.5, lineHeight:1.4,
          }}>{m.text}</div>
        ))}
        {/* typing indicator */}
        <div style={{ alignSelf:'flex-start', padding:'6px 9px',
          borderRadius:'10px 10px 10px 3px',
          background:'rgba(155,92,255,.18)', border:'1px solid rgba(155,92,255,.35)',
          display:'flex', gap:3 }}>
          {[0,1,2].map(i => (
            <span key={i} style={{ width:4, height:4, borderRadius:'50%', background:'#d8c0ff',
              animation:`mm-bob 1s ease-in-out ${i*0.15}s infinite` }} />
          ))}
        </div>
      </div>
    </div>
  );
}

const INTRO_SLIDES = [
  {
    eyebrow: 'WELCOME, CADET',
    title:   'A mission, not a checklist',
    body:    "Moore Momentum turns becoming who you want to be into a space mission you actually want to fly. Real change, measured in light-years.",
    accent:  '#2a7de1',
    hero:    IntroHeroCores,
  },
  {
    eyebrow: 'THE 5-CORE ENGINE',
    title:   'Powered by 5 Cores',
    body:    'Your rocket runs on five life areas: Mindset, Career, Relationships, Physical & Emotional. Every habit you build fuels a Core — and the ship.',
    accent:  '#FFC629',
    hero:    IntroHeroJourney,
  },
  {
    eyebrow: 'YOUR AI CO-PILOT',
    title:   'Nova has your six',
    body:    "Ask Co-pilot to plan your day, decode a slump, or rework a stalled habit. Personal mission control — in your pocket, 24/7.",
    accent:  '#9b5cff',
    hero:    IntroHeroCopilot,
  },
  {
    eyebrow: 'PLOT YOUR COURSE',
    title:   'Streaks. Planets. Trophies.',
    body:    'Show up daily to push the rocket deeper into the system. Earn upgrades, unlock planets, fill your Trophy Room with identity you can keep.',
    accent:  '#ea0029',
    hero:    IntroHeroTrophies,
  },
];

// ─── HOLD TO LAUNCH (final-slide CTA) ───
function HoldToLaunch({ onLaunch }) {
  const [pct, setPct] = React.useState(0);
  const [holding, setHolding] = React.useState(false);
  const raf = React.useRef(null);
  const start = () => {
    setHolding(true);
    const t0 = performance.now();
    const tick = (t) => {
      const p = Math.min(1, (t - t0) / 900);
      setPct(p);
      if (p < 1) raf.current = requestAnimationFrame(tick);
      else { setHolding(false); onLaunch(); }
    };
    raf.current = requestAnimationFrame(tick);
  };
  const stop = () => {
    setHolding(false);
    if (raf.current) cancelAnimationFrame(raf.current);
    setPct(0);
  };
  return (
    <button onMouseDown={start} onMouseUp={stop} onMouseLeave={stop}
            onTouchStart={start} onTouchEnd={stop} onTouchCancel={stop}
      style={{
        position:'relative', width:'100%', padding:'18px',
        background:'linear-gradient(180deg, #3a8dff 0%, #1f5fb8 100%)',
        border:'1px solid #4d9bff', borderRadius:10,
        color:'#fff', fontFamily:'var(--f-display)', fontWeight:700,
        fontSize:14, letterSpacing:'.18em', textTransform:'uppercase',
        cursor:'pointer', overflow:'hidden',
        boxShadow: holding
          ? '0 0 0 1px rgba(77,155,255,.8), 0 0 36px rgba(255,198,41,.7), inset 0 1px 0 rgba(255,255,255,.3)'
          : '0 0 0 1px rgba(77,155,255,.4), 0 0 24px rgba(42,125,225,.55), inset 0 1px 0 rgba(255,255,255,.25)',
        transition: 'box-shadow .2s',
      }}>
      <div style={{
        position:'absolute', left:0, top:0, bottom:0, width:`${pct*100}%`,
        background:'linear-gradient(90deg, rgba(255,198,41,.45), rgba(234,0,41,.5))',
        transition: holding ? 'none' : 'width .2s',
      }} />
      <span style={{ position:'relative' }}>
        {pct >= 1 ? 'Igniting…' : holding ? `Hold · ${Math.round(pct*100)}%` : 'Hold to Launch 🚀'}
      </span>
    </button>
  );
}

function IntroScreen({ onFinish, onSignIn }) {
  const [idx, setIdx] = React.useState(0);
  const [drag, setDrag] = React.useState(null);
  const slide = INTRO_SLIDES[idx];
  const last = idx === INTRO_SLIDES.length - 1;
  const Hero = slide.hero;

  const onStart = (e) => {
    const x = e.touches ? e.touches[0].clientX : e.clientX;
    setDrag({ startX: x, dx: 0 });
  };
  const onMove = (e) => {
    if (!drag) return;
    const x = e.touches ? e.touches[0].clientX : e.clientX;
    setDrag({ ...drag, dx: x - drag.startX });
  };
  const onEnd = () => {
    if (!drag) return;
    if (drag.dx < -50 && idx < INTRO_SLIDES.length - 1) setIdx(idx + 1);
    else if (drag.dx > 50 && idx > 0) setIdx(idx - 1);
    setDrag(null);
  };

  return (
    <div onTouchStart={onStart} onTouchMove={onMove} onTouchEnd={onEnd}
         onMouseDown={onStart} onMouseMove={onMove} onMouseUp={onEnd} onMouseLeave={onEnd}
         style={{
           width:'100%', height:'100%', position:'relative', overflow:'hidden',
           background:'#06070d', paddingTop:56, userSelect:'none',
         }}>
      {/* Layered space backdrop — accent shifts per slide */}
      <div style={{
        position:'absolute', inset:0, transition:'background 600ms ease',
        background: `
          radial-gradient(ellipse 100% 60% at 50% -10%, ${slide.accent}40 0%, transparent 60%),
          radial-gradient(ellipse 90% 70% at 50% 110%, ${slide.accent}22 0%, transparent 60%),
          radial-gradient(ellipse at 50% 40%, #111c4e 0%, #060b22 55%, #02030a 100%)
        `,
      }} />
      <div className="mm-stars" />

      {/* shooting star */}
      <div style={{
        position:'absolute', top:'12%', left:'-10%', width:'30%', height:1,
        background:`linear-gradient(90deg, transparent, ${slide.accent}, transparent)`,
        boxShadow:`0 0 4px ${slide.accent}`,
        animation:'mm-shoot 6s ease-in-out infinite', transform:'rotate(15deg)',
      }} />
      {/* Big translucent planet in corner */}
      <div style={{
        position:'absolute', bottom:'-22%', right:'-22%', width:280, height:280, borderRadius:'50%',
        background:`radial-gradient(circle at 32% 32%, ${slide.accent}aa, ${slide.accent}33 50%, transparent 75%)`,
        filter:'blur(2px)', opacity:.55, transition:'background 600ms ease',
      }} />

      {/* top bar: progress segments + skip */}
      <div style={{ position:'absolute', top:56, left:0, right:0, padding:'12px 16px', zIndex:10,
        display:'flex', alignItems:'center', gap:10 }}>
        <div style={{ flex:1, display:'flex', gap:6 }}>
          {INTRO_SLIDES.map((_, i) => (
            <button key={i} onClick={() => setIdx(i)} aria-label={`Go to slide ${i+1}`}
              style={{
                flex:1, height:3, borderRadius:2, border:'none', padding:0, cursor:'pointer',
                background: i < idx ? slide.accent
                          : i === idx ? '#fff'
                          : 'rgba(241,241,241,.18)',
                boxShadow: i === idx ? `0 0 8px ${slide.accent}` : 'none',
                transition:'all .4s',
              }} />
          ))}
        </div>
        <button onClick={onFinish} style={{
          background:'transparent', border:'1px solid rgba(241,241,241,.2)',
          borderRadius:999, padding:'5px 12px', fontFamily:'var(--f-display)',
          fontSize:9, letterSpacing:'.18em', color:'rgba(241,241,241,.7)', cursor:'pointer',
        }}>SKIP →</button>
      </div>

      {/* HERO visual */}
      <div style={{
        position:'absolute', top:'12%', left:'5%', right:'5%', height:'42%', zIndex:5,
        transform: drag ? `translateX(${drag.dx * 0.4}px)` : 'translateX(0)',
        transition: drag ? 'none' : 'transform .4s cubic-bezier(.22,1,.36,1)',
        opacity: drag ? Math.max(.3, 1 - Math.abs(drag.dx) / 300) : 1,
      }}>
        <Hero />
      </div>

      {/* copy + nav */}
      <div style={{ position:'absolute', left:0, right:0, bottom:0, padding:'0 22px 28px', zIndex:6 }}>
        <div style={{
          transform: drag ? `translateX(${drag.dx * 0.6}px)` : 'translateX(0)',
          transition: drag ? 'none' : 'transform .4s cubic-bezier(.22,1,.36,1)',
          opacity: drag ? Math.max(.4, 1 - Math.abs(drag.dx) / 240) : 1,
        }}>
          <div className="t-display-x" style={{ fontSize:10, letterSpacing:'.22em', color:slide.accent, marginBottom:8 }}>
            {slide.eyebrow}
          </div>
          <div className="t-display" style={{ fontSize:24, color:'#fff', lineHeight:1.18, marginBottom:10 }}>
            {slide.title}
          </div>
          <div style={{ fontSize:13, color:'rgba(241,241,241,.75)', lineHeight:1.55, marginBottom:18, minHeight:64 }}>
            {slide.body}
          </div>
        </div>

        {!last && (
          <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', gap:10 }}>
            <div style={{ fontSize:10, fontFamily:'var(--f-display)', letterSpacing:'.18em',
              color:'rgba(241,241,241,.5)', display:'flex', alignItems:'center', gap:6 }}>
              <svg width="22" height="12" viewBox="0 0 22 12" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"
                   style={{ animation:'mm-swipe 1.6s ease-in-out infinite' }}>
                <path d="M14 2 L 20 6 L 14 10" /><path d="M2 6 H 20" />
              </svg>
              SWIPE OR TAP
            </div>
            <button onClick={() => setIdx(idx + 1)} style={{
              padding:'10px 18px', borderRadius:999,
              background: `linear-gradient(180deg, ${slide.accent}, ${slide.accent}cc)`,
              border:`1px solid ${slide.accent}`,
              color:'#fff', fontFamily:'var(--f-display)', fontWeight:700, fontSize:12,
              letterSpacing:'.14em', textTransform:'uppercase', cursor:'pointer',
              boxShadow:`0 0 18px ${slide.accent}66`,
            }}>Next →</button>
          </div>
        )}
        {last && <HoldToLaunch onLaunch={onSignIn} />}
      </div>
    </div>
  );
}

// ─── Reusable text input ───
function AuthInput({ label, type='text', value, onChange, placeholder }) {
  return (
    <label style={{ display:'block', marginBottom:14 }}>
      <div className="t-display-x" style={{ fontSize:9, letterSpacing:'.16em', color:'rgba(241,241,241,.55)', marginBottom:6 }}>{label}</div>
      <input type={type} value={value} onChange={(e) => onChange(e.target.value)} placeholder={placeholder}
        style={{
          width:'100%', padding:'12px 14px', borderRadius:10,
          background:'rgba(17,28,78,.55)', border:'1px solid rgba(77,155,255,.35)',
          color:'#fff', fontSize:14, outline:'none', fontFamily:'var(--f-body)',
        }} />
    </label>
  );
}

// ─── Sign-up: name, email, password — plus "Continue as guest" ───
function SignUpScreen({ onSignUp, onGuest, onSignIn, onBack }) {
  const [name, setName] = React.useState('');
  const [email, setEmail] = React.useState('');
  const [pw, setPw] = React.useState('');
  const valid = email.includes('@') && pw.length >= 4;

  return (
    <div style={{ width:'100%', height:'100%', overflow:'auto', background:'#06070d', paddingTop:56, position:'relative' }}>
      <div className="mm-starfield" />
      <div className="mm-stars" />
      <div style={{ position:'relative', padding:'14px 18px 80px', zIndex:4 }}>
        <button onClick={onBack} aria-label="Back" style={{
          background:'rgba(17,28,78,.55)', border:'1px solid rgba(241,241,241,.12)',
          borderRadius:10, width:36, height:36, color:'#fff', display:'grid', placeItems:'center', cursor:'pointer', marginBottom:14,
        }}>
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M10 3 L 4 8 L 10 13"/></svg>
        </button>
        <div className="t-display-x" style={{ fontSize:11, letterSpacing:'.2em', color:'var(--mm-yellow)' }}>NEW CADET</div>
        <div className="t-display" style={{ fontSize:24, color:'#fff', marginTop:4, marginBottom:6 }}>Launch your account</div>
        <div style={{ fontSize:12, color:'rgba(241,241,241,.6)', marginBottom:22 }}>
          Save your streaks, sync across devices, join a squad.
        </div>

        <AuthInput label="CALL SIGN" value={name} onChange={setName} placeholder="Alex Moore" />
        <AuthInput label="EMAIL" type="email" value={email} onChange={setEmail} placeholder="cadet@momentum.app" />
        <AuthInput label="PASSWORD" type="password" value={pw} onChange={setPw} placeholder="••••••••" />

        <button onClick={() => valid && onSignUp({ name, email })} disabled={!valid}
          className={'mm-btn-primary' + (valid ? ' mm-btn-primary--pulse' : '')}
          style={{ width:'100%', marginTop:8, opacity: valid ? 1 : .5, cursor: valid ? 'pointer' : 'default' }}>
          Create Account
        </button>

        <div style={{ display:'flex', alignItems:'center', gap:10, margin:'18px 0' }}>
          <div className="mm-hairline" style={{ flex:1 }} />
          <span style={{ fontSize:10, fontFamily:'var(--f-display)', letterSpacing:'.18em', color:'rgba(241,241,241,.4)' }}>OR</span>
          <div className="mm-hairline" style={{ flex:1 }} />
        </div>

        <button onClick={onGuest} className="mm-btn-ghost" style={{ width:'100%', padding:'14px' }}>
          Skip — Continue as Guest
        </button>
        <div style={{ fontSize:10, color:'rgba(241,241,241,.45)', textAlign:'center', marginTop:8 }}>
          Creates a temporary account · upgrade anytime
        </div>

        <div style={{ textAlign:'center', marginTop:24, fontSize:12, color:'rgba(241,241,241,.6)' }}>
          Already flying? <a onClick={onSignIn} style={{ color:'var(--mm-blue)', cursor:'pointer', fontWeight:600 }}>Sign in</a>
        </div>
      </div>
    </div>
  );
}

// ─── Sign-in ───
function SignInScreen({ onSignIn, onSignUp, onBack }) {
  const [email, setEmail] = React.useState('');
  const [pw, setPw] = React.useState('');
  const valid = email.includes('@') && pw.length >= 4;

  return (
    <div style={{ width:'100%', height:'100%', overflow:'auto', background:'#06070d', paddingTop:56, position:'relative' }}>
      <div className="mm-starfield" />
      <div className="mm-stars" />
      <div style={{ position:'relative', padding:'14px 18px 80px', zIndex:4 }}>
        <button onClick={onBack} aria-label="Back" style={{
          background:'rgba(17,28,78,.55)', border:'1px solid rgba(241,241,241,.12)',
          borderRadius:10, width:36, height:36, color:'#fff', display:'grid', placeItems:'center', cursor:'pointer', marginBottom:14,
        }}>
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M10 3 L 4 8 L 10 13"/></svg>
        </button>
        <div className="t-display-x" style={{ fontSize:11, letterSpacing:'.2em', color:'var(--mm-blue)' }}>RETURNING PILOT</div>
        <div className="t-display" style={{ fontSize:24, color:'#fff', marginTop:4, marginBottom:6 }}>Welcome back</div>
        <div style={{ fontSize:12, color:'rgba(241,241,241,.6)', marginBottom:22 }}>
          Your streaks are waiting.
        </div>

        <AuthInput label="EMAIL" type="email" value={email} onChange={setEmail} placeholder="cadet@momentum.app" />
        <AuthInput label="PASSWORD" type="password" value={pw} onChange={setPw} placeholder="••••••••" />

        <div style={{ textAlign:'right', marginTop:-6, marginBottom:14, fontSize:11 }}>
          <a style={{ color:'var(--mm-blue)', cursor:'pointer' }}>Forgot?</a>
        </div>

        <button onClick={() => valid && onSignIn({ email })} disabled={!valid}
          className={'mm-btn-primary' + (valid ? ' mm-btn-primary--pulse' : '')}
          style={{ width:'100%', opacity: valid ? 1 : .5, cursor: valid ? 'pointer' : 'default' }}>
          Sign In
        </button>

        <div style={{ textAlign:'center', marginTop:22, fontSize:12, color:'rgba(241,241,241,.6)' }}>
          New here? <a onClick={onSignUp} style={{ color:'var(--mm-yellow)', cursor:'pointer', fontWeight:600 }}>Create an account</a>
        </div>
      </div>
    </div>
  );
}

// ─── Container that owns auth-stage state ───
function AuthFlow({ stage, setStage, onAuth }) {
  if (stage === 'intro')   return <IntroScreen   onFinish={() => setStage('signup')} onSignIn={() => setStage('signup')} />;
  if (stage === 'signin')  return <SignInScreen  onBack={() => setStage('signup')}
                                                 onSignUp={() => setStage('signup')}
                                                 onSignIn={(p) => onAuth(mockFirebaseAuth('signin', p))} />;
  // default: signup
  return <SignUpScreen onBack={() => setStage('intro')}
                       onSignIn={() => setStage('signin')}
                       onSignUp={(p) => onAuth(mockFirebaseAuth('signup', p))}
                       onGuest={() => onAuth(mockFirebaseAuth('guest'))} />;
}

Object.assign(window, {
  IntroScreen, SignUpScreen, SignInScreen, AuthFlow, mockFirebaseAuth,
});
