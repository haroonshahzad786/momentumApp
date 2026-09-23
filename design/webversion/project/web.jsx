// web.jsx — Moore Momentum WEB (desktop) shell + flagship Cockpit.
// Responsive: at ≥1000px this desktop shell renders; below that the existing
// mobile screens render full-bleed (the current mobile look is preserved).
//
// Shared building blocks reused as-is: Rocket (rocket.jsx), Icons/PLANETS
// (dashboard.jsx), LogoMark/Wordmark (boot.jsx), styles.css tokens.

const WEB_BREAKPOINT = 900;

// Core vocabulary (matches styles.css --core-* and the check-in cores)
const WEB_CORES = [
  { id: 'mindset',       label: 'Mindset',        short: 'MIND', hex: '#2a7de1', icon: '🧠' },
  { id: 'career',        label: 'Career & Finances', short: 'CAREER', hex: '#FFC629', icon: '💰' },
  { id: 'relationships', label: 'Relationships',  short: 'RELATE', hex: '#ff3d8b', icon: '👥' },
  { id: 'physical',      label: 'Physical Health',short: 'PHYS', hex: '#00a98f', icon: '💪' },
  { id: 'emotional',     label: 'Emotional & Mental', short: 'EMO', hex: '#9b5cff', icon: '🧘' },
];

// Primary destinations for the sidebar
const WEB_NAV = [
  { key: 'cockpit',  label: 'Cockpit',  hint: 'Home',        accent: '#2a7de1' },
  { key: 'routines', label: 'Routines', hint: 'Daily orbit', accent: '#00a98f' },
  { key: 'habits',   label: 'Habits',   hint: 'Golden',      accent: '#ff3d8b' },
  { key: 'tasks',    label: 'Tasks',    hint: 'Missions',    accent: '#FFC629' },
  { key: 'lists',    label: 'Lists',    hint: 'Manifest',    accent: '#2a7de1' },
  { key: 'cantina',  label: 'Cantina',  hint: 'Social',      accent: '#9b5cff' },
  { key: 'trophy',   label: 'Trophy',   hint: 'Room',        accent: '#FFC629' },
];

// ── viewport hook ──
function useIsDesktop() {
  const [d, setD] = React.useState(
    typeof window !== 'undefined' ? window.innerWidth >= WEB_BREAKPOINT : true);
  React.useEffect(() => {
    const on = () => setD(window.innerWidth >= WEB_BREAKPOINT);
    window.addEventListener('resize', on);
    return () => window.removeEventListener('resize', on);
  }, []);
  return d;
}

// ── small nav glyphs (line icons, match the space UI) ──
const WEB_GLYPH = {
  cockpit:  <path d="M12 2 C16 6 18 12 18 18 V22 H6 V18 C6 12 8 6 12 2Z M12 2 M9 22 L7 27 M15 22 L17 27 M12 22 L12 27 M9.5 12 a2.5 2.5 0 1 0 5 0 a2.5 2.5 0 1 0 -5 0" />,
  routines: <path d="M12 4 a8 8 0 1 0 0.01 0 M12 8 V12 L15 14" />,
  habits:   <path d="M4 12 C4 8 7 8 9 10 C11 12 13 16 15 16 C18 16 18 10 15 10 C13 10 11 14 9 14 C7 14 4 14 4 12Z" />,
  tasks:    <path d="M4 8 L7 11 L12 5 M4 16 L7 19 L12 13 M15 8 H20 M15 16 H20" />,
  lists:    <path d="M4 6 H20 M4 12 H20 M4 18 H14" />,
  cantina:  <path d="M4 8 h16 l-1.5 5 a3 3 0 0 1 -3 2.2 h-7 a3 3 0 0 1 -3 -2.2 Z M9 15.5 V20 M15 15.5 V20 M7 20 H17" />,
  trophy:   <path d="M7 4 H17 V9 a5 5 0 0 1 -10 0 Z M7 6 H4 a2.5 2.5 0 0 0 3 3.5 M17 6 H20 a2.5 2.5 0 0 1 -3 3.5 M12 14 V18 M8 20 H16 M9.5 18 H14.5" />,
  profile:  <path d="M12 12 a4 4 0 1 0 0-8 a4 4 0 0 0 0 8 Z M5 21 c0-4 3.5-6 7-6 s7 2 7 6" />,
  copilot:  <path d="M12 2 L14.5 8 L21 9 L16.5 13 L18 20 L12 16.5 L6 20 L7.5 13 L3 9 L9.5 8 Z" />,
};
function GlyphBox({ name, size = 20, color = 'currentColor', sw = 1.7 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none"
         stroke={color} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round">
      {WEB_GLYPH[name]}
    </svg>
  );
}

// ═══════════════════════════════════════════════════════════════
// SIDEBAR
// ═══════════════════════════════════════════════════════════════
function WebSidebar({ current, onNav, account, streak, planet, level }) {
  const planetName = (PLANETS.find(p => p.id === planet) || { name: 'Mars' }).name;
  return (
    <aside style={{
      width: 264, flexShrink: 0, height: '100vh', position: 'sticky', top: 0,
      display: 'flex', flexDirection: 'column',
      background: 'linear-gradient(180deg, rgba(17,28,78,.72) 0%, rgba(10,17,54,.55) 100%)',
      borderRight: '1px solid rgba(241,241,241,.08)', backdropFilter: 'blur(14px)',
      zIndex: 20 }}>
      {/* brand */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '22px 22px 20px' }}>
        <LogoMark size={40} phase="static" glow={true} idSuffix="side" />
        <div>
          <Wordmark fontSize={13} />
          <div className="t-display-x" style={{ fontSize: 8, letterSpacing: '.28em',
            color: 'rgba(241,241,241,.45)', marginTop: 4 }}>MOMENTUM OS</div>
        </div>
      </div>

      {/* nav */}
      <nav style={{ display: 'flex', flexDirection: 'column', gap: 3, padding: '6px 14px', flex: 1 }}>
        <div className="t-display-x" style={{ fontSize: 8.5, letterSpacing: '.2em',
          color: 'rgba(241,241,241,.35)', padding: '8px 12px 6px' }}>NAVIGATION</div>
        {WEB_NAV.map((it) => {
          const on = current === it.key;
          return (
            <button key={it.key} onClick={() => onNav(it.key)} style={{
              display: 'flex', alignItems: 'center', gap: 12, textAlign: 'left', cursor: 'pointer',
              padding: '10px 12px', borderRadius: 10, position: 'relative',
              background: on ? `linear-gradient(90deg, ${it.accent}26, transparent 90%)` : 'transparent',
              border: `1px solid ${on ? it.accent + '55' : 'transparent'}`,
              color: on ? '#fff' : 'rgba(241,241,241,.66)', transition: 'all .14s' }}>
              {on && <span style={{ position: 'absolute', left: -14, top: '50%', transform: 'translateY(-50%)',
                width: 3, height: 22, borderRadius: 3, background: it.accent, boxShadow: `0 0 10px ${it.accent}` }} />}
              <span style={{ color: on ? it.accent : 'rgba(241,241,241,.55)', display: 'grid', placeItems: 'center', width: 22 }}>
                <GlyphBox name={it.key} size={20} />
              </span>
              <span style={{ flex: 1 }}>
                <span style={{ display: 'block', fontFamily: 'var(--f-display)', fontWeight: 600,
                  fontSize: 13, letterSpacing: '.03em' }}>{it.label}</span>
              </span>
              <span className="t-display-x" style={{ fontSize: 7.5, letterSpacing: '.14em',
                color: on ? it.accent : 'rgba(241,241,241,.3)' }}>{it.hint}</span>
            </button>
          );
        })}
      </nav>

      {/* player card */}
      <button onClick={() => onNav('profile')} style={{
        margin: '10px 14px 16px', padding: '12px 14px', borderRadius: 12, cursor: 'pointer', textAlign: 'left',
        background: 'rgba(17,28,78,.5)', border: `1px solid ${current === 'profile' ? '#9b5cff77' : 'rgba(241,241,241,.1)'}`,
        display: 'flex', alignItems: 'center', gap: 11 }}>
        <div style={{ width: 40, height: 40, borderRadius: 11, flexShrink: 0,
          background: 'radial-gradient(circle at 30% 30%, #b58aff, #6b3df5 65%, #2a7de1)',
          display: 'grid', placeItems: 'center', color: '#fff', fontFamily: 'var(--f-display)',
          fontWeight: 800, fontSize: 15, boxShadow: '0 0 14px rgba(155,92,255,.5)' }}>
          {(account?.name || 'Commander')[0]}
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 13, color: '#fff', fontWeight: 600, whiteSpace: 'nowrap',
            overflow: 'hidden', textOverflow: 'ellipsis' }}>{account?.name || 'Commander'}</div>
          <div className="t-display-x" style={{ fontSize: 8, letterSpacing: '.14em', color: 'var(--mm-yellow)', marginTop: 3 }}>
            {String(level || 'navigator').toUpperCase()} · {planetName.toUpperCase()}
          </div>
        </div>
        <span className="t-display" style={{ fontSize: 12, color: 'var(--mm-red)', display: 'flex', alignItems: 'center', gap: 3 }}>
          🔥<span className="t-num">{streak}</span>
        </span>
      </button>
    </aside>
  );
}

// ═══════════════════════════════════════════════════════════════
// TOPBAR (inside content column)
// ═══════════════════════════════════════════════════════════════
function WebTopbar({ title, subtitle, accent, onCheckIn, onChat }) {
  return (
    <header style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      gap: 20, padding: '26px 40px 20px', position: 'sticky', top: 0, zIndex: 15,
      background: 'linear-gradient(180deg, rgba(6,7,13,.85) 60%, transparent)', backdropFilter: 'blur(8px)' }}>
      <div>
        <div className="t-display-x" style={{ fontSize: 11, letterSpacing: '.22em', color: accent }}>{subtitle}</div>
        <h1 className="t-display" style={{ fontSize: 30, color: '#fff', margin: '4px 0 0', fontWeight: 700 }}>{title}</h1>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <div style={{ position: 'relative' }}>
          <input placeholder="Search missions, habits, crew…" style={{
            width: 260, padding: '11px 14px 11px 38px', borderRadius: 10,
            background: 'rgba(17,28,78,.5)', border: '1px solid rgba(241,241,241,.12)',
            color: '#fff', fontSize: 13, outline: 'none' }} />
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="rgba(241,241,241,.5)" strokeWidth="1.6"
            style={{ position: 'absolute', left: 13, top: '50%', transform: 'translateY(-50%)' }}>
            <circle cx="7" cy="7" r="5" /><path d="M11 11 L14 14" strokeLinecap="round" />
          </svg>
        </div>
        <button onClick={onChat} title="AI Co-pilot" style={{
          width: 44, height: 44, borderRadius: 12, cursor: 'pointer', display: 'grid', placeItems: 'center',
          background: 'radial-gradient(circle at 30% 30%, #b58aff, #6b3df5 65%, #2a7de1)',
          border: '1px solid rgba(216,192,255,.55)', color: '#fff',
          boxShadow: '0 0 18px rgba(155,92,255,.5)' }}>
          <GlyphBox name="copilot" size={22} />
        </button>
        <button className="mm-btn-primary" onClick={onCheckIn} style={{ padding: '13px 22px', fontSize: 12 }}>
          Daily Check-in →
        </button>
      </div>
    </header>
  );
}

// small stat + reusable card bits shared with web-screens
function WebStat({ label, value, accent = '#fff', sub }) {
  return (
    <div className="mm-panel" style={{ padding: '16px 18px', flex: 1 }}>
      <div className="t-display-x" style={{ fontSize: 9, letterSpacing: '.16em', color: 'rgba(241,241,241,.5)' }}>{label}</div>
      <div className="t-display t-num" style={{ fontSize: 28, color: accent, marginTop: 6, lineHeight: 1 }}>{value}</div>
      {sub && <div style={{ fontSize: 11, color: 'rgba(241,241,241,.5)', marginTop: 5 }}>{sub}</div>}
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// FLAGSHIP: DESKTOP COCKPIT
// ═══════════════════════════════════════════════════════════════
function WebCockpit({ tweaks, onNav, onCheckIn }) {
  const { streak = 47, planet = 'mars', activeCores = ['mindset', 'career', 'physical'],
    level = 'navigator', momentumScore = 8420, balance = 78 } = tweaks;
  const planetIdx = PLANETS.findIndex(p => p.id === planet);
  const planetData = PLANETS[planetIdx] || PLANETS[2];
  const isActive = (id) => activeCores.includes(id);

  const CoreCard = ({ c }) => {
    const on = isActive(c.id);
    return (
      <div className="mm-panel" style={{
        padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 13,
        borderLeft: `3px solid ${on ? c.hex : 'rgba(241,241,241,.15)'}`,
        opacity: on ? 1 : .58 }}>
        <div style={{ width: 38, height: 38, borderRadius: 10, display: 'grid', placeItems: 'center',
          fontSize: 19, background: on ? `${c.hex}22` : 'rgba(241,241,241,.05)',
          border: `1px solid ${on ? c.hex + '66' : 'rgba(241,241,241,.12)'}`,
          boxShadow: on ? `0 0 14px ${c.hex}44` : 'none' }}>{c.icon}</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 13.5, color: '#fff', fontWeight: 600 }}>{c.label}</div>
          <div className="t-display-x" style={{ fontSize: 8, letterSpacing: '.14em', marginTop: 3,
            color: on ? c.hex : 'rgba(241,241,241,.4)' }}>{on ? 'ACTIVE' : 'DORMANT'}</div>
        </div>
        {on && (
          <div style={{ width: 46, textAlign: 'right' }}>
            <div className="t-num t-display" style={{ fontSize: 16, color: c.hex }}>{60 + (c.id.length * 4) % 38}</div>
            <div style={{ height: 3, borderRadius: 3, marginTop: 4, background: 'rgba(241,241,241,.1)', overflow: 'hidden' }}>
              <div style={{ width: `${60 + (c.id.length * 4) % 38}%`, height: '100%', background: c.hex }} />
            </div>
          </div>
        )}
      </div>
    );
  };

  return (
    <div style={{ padding: '4px 40px 56px', display: 'grid',
      gridTemplateColumns: 'minmax(240px, 1fr) minmax(360px, 1.5fr) minmax(240px, 1fr)',
      gap: 24, alignItems: 'start' }}>

      {/* LEFT — cores */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        <div className="t-display-x" style={{ fontSize: 10, letterSpacing: '.18em', color: '#fff', margin: '2px 2px 2px' }}>
          THE 5 CORES
        </div>
        {WEB_CORES.map((c) => <CoreCard key={c.id} c={c} />)}
        <button className="mm-btn-ghost" onClick={() => onNav('habits')} style={{ marginTop: 4 }}>
          Manage cores →
        </button>
      </div>

      {/* CENTER — rocket stage */}
      <div style={{ position: 'relative', minHeight: 640, borderRadius: 20, overflow: 'hidden',
        background: 'radial-gradient(ellipse 90% 60% at 50% 8%, rgba(42,125,225,.16), transparent 60%), rgba(10,17,54,.35)',
        border: '1px solid rgba(241,241,241,.08)',
        display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '26px 20px 30px' }}>
        <div className="mm-stars" style={{ opacity: .7 }} />

        {/* target planet halo */}
        <div style={{ position: 'absolute', top: 30, right: 30, width: 150, height: 150, borderRadius: '50%',
          background: `radial-gradient(circle at 35% 35%, ${planetData.color}cc, ${planetData.color}22 45%, transparent 70%)`,
          filter: 'blur(4px)', opacity: .7, pointerEvents: 'none' }} />

        {/* shooting stars */}
        <div style={{ position: 'absolute', inset: 0, overflow: 'hidden', pointerEvents: 'none' }}>
          {[{ t: '12%', d: '0s', c: '#b58aff' }, { t: '40%', d: '1.3s', c: '#FFC629' }, { t: '68%', d: '2.2s', c: '#2a7de1' }].map((s, i) => (
            <div key={i} style={{ position: 'absolute', top: s.t, left: '-15%', width: '50%', height: 1,
              background: `linear-gradient(90deg, transparent, ${s.c}, transparent)`, boxShadow: `0 0 4px ${s.c}`,
              transform: 'rotate(12deg)', animation: `mm-shoot 4s ease-in-out ${s.d} infinite` }} />
          ))}
        </div>

        <div className="t-display-x" style={{ position: 'relative', fontSize: 10, letterSpacing: '.22em',
          color: 'rgba(216,192,255,.85)', zIndex: 2 }}>MISSION IN PROGRESS</div>

        <div style={{ position: 'relative', zIndex: 2, marginTop: 14, animation: 'mm-rocket-launch 1.1s cubic-bezier(.22,1,.36,1) both' }}>
          <Rocket width={272} activeCores={activeCores} streak={streak} onNav={onNav} />
          <div style={{ position: 'absolute', top: '18%', left: '50%', width: 300, height: 300,
            transform: 'translate(-50%,-10%)', background: 'radial-gradient(circle, rgba(42,125,225,.2), transparent 60%)',
            filter: 'blur(24px)', zIndex: -1 }} />
        </div>

        {/* journey arc */}
        <div style={{ position: 'relative', zIndex: 2, width: '100%', marginTop: 10 }}>
          <JourneyArc planetIdx={planetIdx} progress={0.38} />
        </div>

        <button className="mm-btn-primary mm-btn-primary--pulse" onClick={onCheckIn}
          style={{ position: 'relative', zIndex: 2, marginTop: 20, width: '80%' }}>
          Daily Check-in →
        </button>
      </div>

      {/* RIGHT — stats + quests */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        <div className="t-display-x" style={{ fontSize: 10, letterSpacing: '.18em', color: '#fff', margin: '2px 2px 2px' }}>
          FLIGHT DATA
        </div>
        <div style={{ display: 'flex', gap: 12 }}>
          <WebStat label="Streak" value={`${streak}d`} accent="var(--mm-red)" />
          <WebStat label="Balance" value={`${balance}%`} accent="var(--mm-teal)" />
        </div>
        <WebStat label="Momentum Score" value={momentumScore.toLocaleString()} accent="var(--mm-yellow)"
          sub={`Next planet in ${Math.max(0, 12000 - momentumScore).toLocaleString()} pts`} />

        {/* momentum progress */}
        <div className="mm-panel" style={{ padding: '16px 18px' }}>
          <div className="t-display-x" style={{ fontSize: 9, letterSpacing: '.16em', color: 'rgba(241,241,241,.5)', marginBottom: 10 }}>
            TODAY'S TRAJECTORY
          </div>
          {[['Check-in logged', true], ['3 routines complete', true], ['Golden habit forming', false]].map(([t, done], i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '7px 0',
              borderTop: i ? '1px solid rgba(241,241,241,.06)' : 'none' }}>
              <span style={{ width: 16, height: 16, borderRadius: 5, display: 'grid', placeItems: 'center',
                background: done ? 'var(--mm-teal)' : 'transparent', border: `1.5px solid ${done ? 'var(--mm-teal)' : 'rgba(241,241,241,.3)'}` }}>
                {done && <svg width="9" height="9" viewBox="0 0 9 9" fill="none" stroke="#04130f" strokeWidth="2" strokeLinecap="round"><path d="M1 4.5 L3.5 7 L8 2" /></svg>}
              </span>
              <span style={{ fontSize: 12.5, color: done ? 'rgba(241,241,241,.55)' : '#fff', textDecoration: done ? 'line-through' : 'none' }}>{t}</span>
            </div>
          ))}
        </div>

        {/* active quest */}
        <button onClick={() => onNav('trophy')} className="mm-panel" style={{ padding: '16px 18px', cursor: 'pointer', textAlign: 'left',
          borderColor: 'rgba(255,198,41,.35)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
            <span style={{ fontSize: 16 }}>🎯</span>
            <span className="t-display-x" style={{ fontSize: 9, letterSpacing: '.16em', color: 'var(--mm-yellow)' }}>ACTIVE QUEST</span>
          </div>
          <div style={{ fontSize: 13.5, color: '#fff', fontWeight: 600 }}>Reach a 50-day streak</div>
          <div style={{ height: 5, borderRadius: 3, marginTop: 10, background: 'rgba(241,241,241,.1)', overflow: 'hidden' }}>
            <div style={{ width: `${Math.min(100, (streak / 50) * 100)}%`, height: '100%',
              background: 'linear-gradient(90deg, var(--mm-red), var(--mm-yellow))' }} />
          </div>
          <div style={{ fontSize: 10.5, color: 'rgba(241,241,241,.5)', marginTop: 6 }}>{streak}/50 days</div>
        </button>
      </div>
    </div>
  );
}

Object.assign(window, { useIsDesktop, WebSidebar, WebTopbar, WebCockpit, WebStat, GlyphBox, WEB_CORES, WEB_NAV, WEB_BREAKPOINT });
