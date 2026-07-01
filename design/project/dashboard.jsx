// dashboard.jsx — Default Rocket Dashboard (Screen 3.1)
// The cockpit / home screen. Hero rocket, streak, stats, planet journey, primary CTA.

const PLANETS = [
  { id: 'earth',   name: 'Earth',   color: '#3aa6ff', sym: '🜨' },
  { id: 'moon',    name: 'Moon',    color: '#cfd2dc' },
  { id: 'mars',    name: 'Mars',    color: '#d76b3a' },
  { id: 'jupiter', name: 'Jupiter', color: '#d9a86b' },
  { id: 'saturn',  name: 'Saturn',  color: '#e8c178' },
  { id: 'pluto',   name: 'Pluto',   color: '#9aa3c7' },
];

// ─── Streak flame — scales 0.6 → 1.4 across 1..365 days
function StreakFlame({ days }) {
  const scale = 0.6 + Math.min(days, 365) / 365 * 0.8;
  const intensity = days >= 30 ? 1 : days >= 7 ? 0.7 : 0.4;
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
      <div style={{
        width: 36, height: 36, position: 'relative',
        transform: `scale(${scale})`, transformOrigin: 'center bottom',
        filter: `drop-shadow(0 0 ${10 * intensity}px #ea002988) drop-shadow(0 0 ${4 * intensity}px #FFC62988)`,
        animation: 'mm-flame 1.4s ease-in-out infinite',
      }}>
        <svg viewBox="0 0 36 36" width="36" height="36">
          <defs>
            <radialGradient id="flame-grad" cx="50%" cy="80%" r="60%">
              <stop offset="0%"  stopColor="#fff" />
              <stop offset="35%" stopColor="#FFC629" />
              <stop offset="75%" stopColor="#ea0029" />
              <stop offset="100%" stopColor="#9b5cff" stopOpacity="0" />
            </radialGradient>
          </defs>
          <path d="M18 4 C 12 12, 8 16, 8 22 C 8 28, 12 32, 18 32 C 24 32, 28 28, 28 22 C 28 18, 24 14, 22 10 C 21 14, 19 16, 17 14 C 17 10, 18 7, 18 4 Z"
                fill="url(#flame-grad)" />
          <path d="M18 14 C 15 18, 13 21, 13 24 C 13 28, 15 30, 18 30 C 21 30, 23 28, 23 24 C 23 22, 21 20, 20 18 C 19 21, 18 22, 18 14 Z"
                fill="#fff" opacity=".6" />
        </svg>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', lineHeight: 1 }}>
        <div className="t-display-x" style={{ fontSize: 11, color: 'var(--mm-yellow)', letterSpacing: '.16em' }}>STREAK</div>
        <div className="t-display t-num" style={{ fontSize: 20, color: '#fff', marginTop: 2 }}>DAY {days}</div>
      </div>
    </div>
  );
}

// ─── Tiny stat row in the top-right stats box ───
function StatLine({ label, value, accent }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 10 }}>
      <span style={{ fontSize: 9, letterSpacing: '.14em', color: 'var(--mm-white-2)', fontFamily: 'var(--f-display)', textTransform: 'uppercase' }}>{label}</span>
      <span className="t-display t-num" style={{ fontSize: 13, color: accent || '#fff' }}>{value}</span>
    </div>
  );
}

// ─── Quick-access icon row above the rocket ───
function QuickIcon({ glyph, label, onClick }) {
  return (
    <button onClick={onClick} style={{
      width: 52, height: 52, borderRadius: 12,
      background: 'rgba(17,28,78,.55)',
      border: '1px solid rgba(77,155,255,.35)',
      backdropFilter: 'blur(10px)',
      color: 'var(--mm-blue)',
      display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
      gap: 2, cursor: 'pointer', padding: 0,
      boxShadow: '0 0 14px rgba(42,125,225,.25)',
    }}>
      <div style={{ fontSize: 18, lineHeight: 1 }}>{glyph}</div>
      <div style={{ fontSize: 7, fontFamily: 'var(--f-display)', letterSpacing: '.08em', color: 'rgba(241,241,241,.7)', textTransform: 'uppercase' }}>{label}</div>
    </button>
  );
}

// ─── SVG icons (custom line+glow, not Lucide/SF symbols) ───
const Icons = {
  steering: (
    <svg width="22" height="22" viewBox="0 0 22 22" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="11" cy="11" r="9" />
      <circle cx="11" cy="11" r="2" />
      <path d="M11 4 V 9" /><path d="M11 13 V 18" /><path d="M4 11 H 9" /><path d="M13 11 H 18" />
    </svg>
  ),
  clock: (
    <svg width="22" height="22" viewBox="0 0 22 22" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="11" cy="11" r="9" />
      <path d="M11 5 V 11 L 15 13" />
    </svg>
  ),
  infinity: (
    <svg width="24" height="22" viewBox="0 0 24 22" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M6 11 C 6 8, 8 6, 11 8 L 13 14 C 16 16, 18 14, 18 11 C 18 8, 16 6, 13 8 L 11 14 C 8 16, 6 14, 6 11 Z" />
    </svg>
  ),
  check: (
    <svg width="22" height="22" viewBox="0 0 22 22" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="4" width="16" height="14" rx="2" />
      <path d="M7 11 L 10 14 L 16 8" />
    </svg>
  ),
  menu: (
    <svg width="22" height="22" viewBox="0 0 22 22" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round">
      <path d="M3 6 H 19" /><path d="M3 11 H 19" /><path d="M3 16 H 13" />
    </svg>
  ),
  trophy: (
    <svg width="22" height="22" viewBox="0 0 22 22" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M6 4 H 16 V 9 a 5 5 0 0 1 -10 0 V 4 Z" />
      <path d="M6 6 H 3 V 8 a 3 3 0 0 0 3 3" />
      <path d="M16 6 H 19 V 8 a 3 3 0 0 1 -3 3" />
      <path d="M9 14 H 13 V 18 H 9 Z" /><path d="M7 18 H 15" />
    </svg>
  ),
  rocket: (
    <svg width="20" height="20" viewBox="0 0 22 22" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M11 2 C 14 5, 16 9, 16 13 V 17 H 6 V 13 C 6 9, 8 5, 11 2 Z" />
      <circle cx="11" cy="10" r="2" /><path d="M6 17 L 4 21" /><path d="M16 17 L 18 21" />
    </svg>
  ),
  cantina: (
    <svg width="20" height="20" viewBox="0 0 22 22" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 9 L 11 4 L 19 9 V 18 H 3 Z" />
      <path d="M9 18 V 13 H 13 V 18" />
    </svg>
  ),
  user: (
    <svg width="20" height="20" viewBox="0 0 22 22" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="11" cy="8" r="4" />
      <path d="M3 19 C 4 15, 7 13, 11 13 C 15 13, 18 15, 19 19" />
    </svg>
  ),
};

// ─── Planet journey arc ───
function JourneyArc({ planetIdx, progress }) {
  const stops = PLANETS;
  const w = 260, h = 90;
  return (
    <div style={{ position: 'relative', width: w, height: h, margin: '0 auto' }}>
      <svg viewBox={`0 0 ${w} ${h}`} width={w} height={h} style={{ overflow: 'visible' }}>
        <defs>
          <linearGradient id="arc-grad" x1="0" x2="1">
            <stop offset="0%" stopColor="#2a7de1" stopOpacity=".7"/>
            <stop offset="100%" stopColor="#9b5cff" stopOpacity=".5"/>
          </linearGradient>
        </defs>
        <path d={`M 14 ${h-14} Q ${w/2} -10 ${w-14} ${h-14}`}
              fill="none" stroke="url(#arc-grad)" strokeWidth="1.5" strokeDasharray="3 4" opacity=".7" />
        {stops.map((p, i) => {
          const t = i / (stops.length - 1);
          const x = 14 + t * (w - 28);
          // quadratic Bezier y at parameter t for our control points
          const y = (1-t)*(1-t)*(h-14) + 2*(1-t)*t*(-10) + t*t*(h-14);
          const reached = i <= planetIdx;
          return (
            <g key={p.id} transform={`translate(${x}, ${y})`}>
              <circle r={i === planetIdx ? 6 : 4}
                      fill={reached ? p.color : 'transparent'}
                      stroke={reached ? p.color : 'rgba(241,241,241,.3)'}
                      strokeWidth="1.2"
                      style={{ filter: i === planetIdx ? `drop-shadow(0 0 6px ${p.color})` : 'none' }} />
              <text y={i < 2 ? -10 : 18} textAnchor="middle"
                    fontSize="7" fontFamily="var(--f-display)" letterSpacing=".1em"
                    fill={reached ? '#fff' : 'rgba(241,241,241,.5)'}>
                {p.name.toUpperCase()}
              </text>
            </g>
          );
        })}
        {/* ship marker on arc */}
        {(() => {
          const segs = stops.length - 1;
          const t = Math.min(1, (planetIdx + progress) / segs);
          const x = 14 + t * (w - 28);
          const y = (1-t)*(1-t)*(h-14) + 2*(1-t)*t*(-10) + t*t*(h-14);
          return (
            <g transform={`translate(${x}, ${y})`}>
              <circle r="3" fill="#fff" />
              <circle r="8" fill="none" stroke="#fff" strokeWidth=".5" opacity=".4">
                <animate attributeName="r" values="6;14;6" dur="2.4s" repeatCount="indefinite" />
                <animate attributeName="opacity" values=".5;0;.5" dur="2.4s" repeatCount="indefinite" />
              </circle>
            </g>
          );
        })()}
      </svg>
    </div>
  );
}

// ─── Bottom nav ───
function BottomNav({ onNav }) {
  const items = [
    { key: 'habits',   icon: Icons.infinity, label: 'Habits'  },
    { key: 'cantina',  icon: Icons.cantina,  label: 'Cantina' },
    { key: 'trophy',   icon: Icons.trophy,   label: 'Trophy'  },
    { key: 'profile',  icon: Icons.user,     label: 'Profile' },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0,
      paddingBottom: 30, paddingTop: 10,
      background: 'linear-gradient(180deg, rgba(6,7,13,0) 0%, rgba(6,7,13,.85) 50%, rgba(6,7,13,.95) 100%)',
      backdropFilter: 'blur(20px)',
      borderTop: '1px solid rgba(241,241,241,.06)',
      display: 'flex', justifyContent: 'space-around',
    }}>
      {items.map((it) => (
        <button key={it.key} onClick={() => onNav?.(it.key)}
                style={{
                  background: 'transparent', border: 0, color: 'rgba(241,241,241,.5)',
                  display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
                  padding: '6px 12px', cursor: 'pointer',
                }}>
          {it.icon}
          <span style={{ fontSize: 9, fontFamily: 'var(--f-display)', letterSpacing: '.1em', textTransform: 'uppercase' }}>{it.label}</span>
        </button>
      ))}
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN: Default Rocket Dashboard (Screen 3.1)
// ═══════════════════════════════════════════════════════════════════════════
// ─── Asset preloader: waits for the dashboard images so the cockpit reveals
//     all at once instead of popping in piecemeal. Resolves on load OR error.
const DASHBOARD_ASSETS = [
  'assets/rocket.png',
  'assets/panel-mindset-color.png',      'assets/panel-mindset-gray.png',
  'assets/panel-emotional-color.png',    'assets/panel-emotional-gray.png',
  'assets/panel-relationships-color.png','assets/panel-relationships-gray.png',
  'assets/panel-physical-color.png',     'assets/panel-physical-gray.png',
  'assets/panel-career-color.png',       'assets/panel-career-gray.png',
  'assets/core-mindset.png', 'assets/core-emotional.png',
  'assets/core-relationships.png', 'assets/core-physical.png', 'assets/core-career.png',
  'assets/icon-habits.png', 'assets/icon-lists.png', 'assets/icon-routines.png',
];
function useDashboardReady() {
  const [ready, setReady] = React.useState(false);
  React.useEffect(() => {
    let cancelled = false;
    Promise.all(DASHBOARD_ASSETS.map((src) => new Promise((resolve) => {
      const i = new Image();
      i.onload = i.onerror = () => resolve();
      i.src = src;
    }))).then(() => { if (!cancelled) setTimeout(() => setReady(true), 80); });
    return () => { cancelled = true; };
  }, []);
  return ready;
}

// ─── Pre-launch splash: starfield + warp lines + tiny spinner ───
function LaunchSplash() {
  return (
    <div style={{
      position:'absolute', inset:0, zIndex:30, overflow:'hidden',
      background:'radial-gradient(ellipse at 50% 40%, #1a2860 0%, #06070d 65%, #02030a 100%)',
      display:'grid', placeItems:'center',
    }}>
      <div className="mm-stars" />
      {[...Array(14)].map((_, i) => (
        <span key={i} style={{
          position:'absolute', width:2, height:50,
          left: `${(i * 13 + 5) % 100}%`,
          top: `${(i * 23) % 100}%`,
          background:'linear-gradient(180deg, transparent, #b58aff, transparent)',
          opacity:.7, borderRadius:2,
          animation:`mm-warp ${1.2 + (i % 4) * .3}s linear ${i * .08}s infinite`,
        }} />
      ))}
      <div style={{ position:'relative', textAlign:'center', zIndex:5 }}>
        <div style={{
          width:64, height:64, borderRadius:'50%',
          border:'2px solid rgba(155,92,255,.25)',
          borderTopColor:'#b58aff',
          margin:'0 auto 14px',
          animation:'mm-spin 1s linear infinite',
        }} />
        <div className="t-display-x" style={{ fontSize:11, letterSpacing:'.28em', color:'#d8c0ff' }}>
          INITIALIZING COCKPIT
        </div>
        <div style={{ fontSize:10, color:'rgba(241,241,241,.45)', marginTop:6, fontFamily:'var(--f-display)', letterSpacing:'.16em' }}>
          IGNITING SYSTEMS…
        </div>
      </div>
    </div>
  );
}

function Dashboard({ tweaks, onCheckIn, onNav, onMenu, onChat }) {
  const ready = useDashboardReady();
  const {
    streak = 47,
    planet = 'mars',
    activeCores = ['mindset', 'career', 'physical'],
    level = 'navigator',
    momentumScore = 8420,
    balance = 78,
  } = tweaks;

  const planetIdx = PLANETS.findIndex(p => p.id === planet);
  // Upgrade visuals derived from level
  const upgrades = {
    cadet:     { wings: 'stub',     armor: 1, thrusters: 'small'  },
    navigator: { wings: 'standard', armor: 2, thrusters: 'medium' },
    commander: { wings: 'epic',     armor: 3, thrusters: 'large'  },
  }[level];

  const planetData = PLANETS[planetIdx] || PLANETS[2];

  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative', overflow: 'hidden',
      background: '#06070d',
      paddingTop: 56, // status bar
    }}>
      {/* Background layers */}
      <div className="mm-starfield" />
      <div className="mm-stars" />
      <div className="mm-scanlines" />

      {/* Distant target planet — faint silhouette in upper-left quadrant */}
      <div style={{
        position: 'absolute', top: 80, right: -50, width: 220, height: 220,
        borderRadius: '50%',
        background: `radial-gradient(circle at 30% 30%, ${planetData.color}aa 0%, ${planetData.color}33 40%, transparent 70%)`,
        filter: 'blur(8px)', opacity: .4, pointerEvents: 'none',
      }} />


      {/* ─── TOP BAR ─── */}
      <div style={{
        position: 'relative', zIndex: 5,
        display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between',
        padding: '12px 18px 0',
      }}>
        {/* left: hamburger + trophy */}
        <div style={{ display: 'flex', gap: 10, paddingTop: 4 }}>
          <button onClick={onMenu} aria-label="Menu" style={{ background:'rgba(17,28,78,.55)', border:'1px solid rgba(241,241,241,.12)', borderRadius:10, width:36, height:36, color:'#fff', display:'grid', placeItems:'center', cursor:'pointer' }}>
            {Icons.menu}
          </button>
          <button onClick={() => onNav?.('trophy')} aria-label="Trophy" style={{ background:'rgba(17,28,78,.55)', border:'1px solid rgba(255,198,41,.35)', borderRadius:10, width:36, height:36, color:'var(--mm-yellow)', display:'grid', placeItems:'center', cursor:'pointer', boxShadow:'0 0 12px rgba(255,198,41,.2)' }}>
            {Icons.trophy}
          </button>
        </div>

        {/* center: streak */}
        <div style={{ paddingTop: 2 }}>
          <StreakFlame days={streak} />
        </div>

        {/* right: stats box */}
        <div className="mm-panel" style={{ padding: '6px 10px', minWidth: 92, display: 'flex', flexDirection: 'column', gap: 3 }}>
          <StatLine label="Planet" value={planetData.name.toUpperCase()} accent={planetData.color} />
          <StatLine label="Score"  value={momentumScore.toLocaleString()} />
          <StatLine label="Balance" value={`${balance}%`} accent="var(--mm-teal)" />
        </div>
      </div>

      {/* ─── QUICK-ACCESS ICON ROW (above rocket) ─ 2 left, 2 right ─── */}
      <div style={{
        position: 'relative', zIndex: 5,
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        padding: '0 14px',
        marginTop: 8,
      }}>
        <div style={{ display: 'flex', gap: 8 }}>
          <QuickIcon onClick={() => onNav?.('lists')}    glyph={<span style={{color:'var(--mm-blue)'}}>{Icons.steering}</span>} label="Lists" />
          <QuickIcon onClick={() => onNav?.('routines')} glyph={<span style={{color:'var(--mm-teal)'}}>{Icons.clock}</span>} label="Routines" />
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <QuickIcon onClick={() => onNav?.('habits')}   glyph={<span style={{color:'var(--mm-magenta)'}}>{Icons.infinity}</span>} label="Habits" />
          <QuickIcon onClick={() => onNav?.('tasks')}    glyph={<span style={{color:'var(--mm-yellow)'}}>{Icons.check}</span>} label="Tasks" />
        </div>
      </div>

      {/* ─── HERO ROCKET ─── */}
      <div style={{
        position: 'relative', zIndex: 4,
        display: 'flex', justifyContent: 'center',
        marginTop: -34, marginBottom: 0,
      }}>
        <div style={{ position: 'relative', minHeight: 360,
            display:'flex', justifyContent:'center', alignItems:'center' }}>

          {/* Shooting stars — always on, gives a sense of forward motion */}
          <div style={{ position:'absolute', inset:'-20% -40%', pointerEvents:'none', overflow:'hidden', zIndex:0 }}>
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

          {/* Real rocket: ALWAYS mounted so the browser loads its images
              into memory immediately. Hidden + non-interactive until ready,
              then revealed with the launch animation. */}
          <div style={{
            position: 'relative',
            visibility: ready ? 'visible' : 'hidden',
            opacity: ready ? 1 : 0,
            pointerEvents: ready ? 'auto' : 'none',
            animation: ready ? 'mm-rocket-launch 1.1s cubic-bezier(.22,1,.36,1) both' : 'none',
          }}>
            <Rocket
              width={230}
              activeCores={activeCores}
              streak={streak}
              onNav={onNav}
            />
            {/* Soft halo behind ship */}
            <div style={{
              position: 'absolute', top: '20%', left: '50%', width: 240, height: 240,
              transform: 'translate(-50%, -10%)',
              background: 'radial-gradient(circle, rgba(42,125,225,.18) 0%, transparent 60%)',
              filter: 'blur(20px)', zIndex: -1, pointerEvents: 'none',
            }} />
          </div>

          {/* Loading placeholder overlay (only while assets warm up) */}
          {!ready && (
            <div style={{ position:'absolute', inset:0, display:'grid', placeItems:'center',
                textAlign:'center', color:'#d8c0ff',
                fontFamily:'var(--f-display)', letterSpacing:'.18em', fontSize:10 }}>
              <div>
                <svg width="48" height="68" viewBox="0 0 24 36" fill="none" stroke="#b58aff"
                     strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"
                     style={{ animation:'mm-bob 1.4s ease-in-out infinite',
                       filter:'drop-shadow(0 0 10px #b58aff)' }}>
                  <path d="M12 2 C 16 6, 18 12, 18 18 V 26 H 6 V 18 C 6 12, 8 6, 12 2 Z" />
                  <circle cx="12" cy="14" r="2.5" />
                  <path d="M6 26 L 3 32 M 18 26 L 21 32 M 9 28 L 9 34 M 15 28 L 15 34" />
                </svg>
                <div style={{ marginTop:10 }}>SYSTEMS WARMING</div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* ─── PLANET JOURNEY ARC ─── */}
      <div style={{ position: 'relative', zIndex: 5, padding: '0 12px' }}>
        <JourneyArc planetIdx={planetIdx} progress={0.38} />
      </div>

      {/* ─── PRIMARY CTA ─── */}
      <div style={{
        position: 'relative', zIndex: 6,
        padding: '24px 20px 72px',
      }}>
        <button className="mm-btn-primary" onClick={onCheckIn}
                style={{ width: '100%' }}>
          Daily Check-in →
        </button>
        <div style={{
          textAlign: 'center', marginTop: 8, fontSize: 10,
          fontFamily: 'var(--f-display)', letterSpacing: '.18em', color: 'rgba(241,241,241,.45)',
          textTransform: 'uppercase',
        }}>
          {activeCores.length}/5 Cores active · {level}
        </div>
      </div>

      {/* ─── FLOATING AI CO-PILOT ─── */}
      <button onClick={onChat} aria-label="Open Co-pilot" style={{
        position:'absolute', right:14, bottom:200, zIndex:7,
        width:62, height:62, borderRadius:'50%',
        background:'radial-gradient(circle at 30% 30%, #b58aff 0%, #6b3df5 60%, #2a7de1 100%)',
        border:'1px solid rgba(216,192,255,.6)',
        boxShadow:'0 0 24px rgba(155,92,255,.6), 0 6px 18px rgba(0,0,0,.4)',
        color:'#fff', display:'grid', placeItems:'center', cursor:'pointer',
        animation:'mm-pulse 2.6s ease-in-out infinite',
        padding:0,
      }}>
        <svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
          <path d="M12 2 L 14.5 8 L 21 9 L 16.5 13 L 18 20 L 12 16.5 L 6 20 L 7.5 13 L 3 9 L 9.5 8 Z" />
        </svg>
      </button>
      <div style={{
        position:'absolute', right:0, bottom:182, zIndex:7,
        width:90, textAlign:'center', pointerEvents:'none',
        fontFamily:'var(--f-display)', fontSize:9, letterSpacing:'.18em',
        color:'#d8c0ff', textShadow:'0 0 8px rgba(155,92,255,.6)',
        whiteSpace:'nowrap',
      }}>CO-PILOT</div>

      {/* Bottom nav removed — destinations are reachable via the hamburger menu */}
    </div>
  );
}

Object.assign(window, { Dashboard, Icons, PLANETS });
