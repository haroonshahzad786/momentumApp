// summary.jsx — Progress Summary (Screen 3.5)
// Post-check-in reward sequence. Stats reveal one-by-one with brief counter
// animations. Mystery Box has a 10-15% trigger chance.

function CountUp({ to, duration = 900, prefix = '', suffix = '' }) {
  const [n, setN] = React.useState(0);
  React.useEffect(() => {
    let start;
    let frame;
    const tick = (t) => {
      if (!start) start = t;
      const progress = Math.min(1, (t - start) / duration);
      const eased = 1 - Math.pow(1 - progress, 3);
      setN(Math.round(eased * to));
      if (progress < 1) frame = requestAnimationFrame(tick);
    };
    frame = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(frame);
  }, [to, duration]);
  return <span>{prefix}{n.toLocaleString()}{suffix}</span>;
}

// Reveal-row wrapper with sequenced delay
function RevealRow({ delay, children }) {
  return (
    <div className="mm-reveal" style={{ animationDelay: `${delay}ms` }}>
      {children}
    </div>
  );
}

// ─── Big stat row ───
function StatRow({ label, value, accent, delay, suffix }) {
  return (
    <RevealRow delay={delay}>
      <div className="mm-panel" style={{
        padding: '14px 16px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        marginBottom: 8,
      }}>
        <div className="t-display-x" style={{ fontSize: 11, color: 'rgba(241,241,241,.65)', letterSpacing: '.16em' }}>
          {label}
        </div>
        <div className="t-display t-num" style={{ fontSize: 22, color: accent || '#fff', textShadow: accent ? `0 0 14px ${accent}88` : 'none' }}>
          <CountUp to={value} suffix={suffix} />
        </div>
      </div>
    </RevealRow>
  );
}

// ─── Core balance bars ───
function BalanceMeter({ delay, scores, activeCores }) {
  const cores = [
    { id: 'mindset',       name: 'Mind',  color: '#2a7de1' },
    { id: 'career',        name: 'Career', color: '#FFC629' },
    { id: 'relationships', name: 'Rel.',  color: '#ff3d8b' },
    { id: 'physical',      name: 'Phys.', color: '#00a98f' },
    { id: 'emotional',     name: 'Emo.',  color: '#9b5cff' },
  ];
  return (
    <RevealRow delay={delay}>
      <div className="mm-panel" style={{ padding: '14px 16px', marginBottom: 8 }}>
        <div className="t-display-x" style={{ fontSize: 10, color: 'rgba(241,241,241,.55)', letterSpacing: '.16em', marginBottom: 10 }}>
          5-Core Balance · 7-day rolling
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {cores.map((c) => {
            const active = activeCores.includes(c.id);
            const score = scores[c.id] || 0;
            const pct = active ? (score / 5) * 100 : 0;
            return (
              <div key={c.id} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <div style={{ width: 44, fontSize: 10, fontFamily: 'var(--f-display)', letterSpacing: '.1em', color: active ? '#fff' : 'rgba(241,241,241,.3)', textTransform: 'uppercase' }}>
                  {c.name}
                </div>
                <div style={{ flex: 1, height: 8, background: 'rgba(241,241,241,.08)', borderRadius: 4, position: 'relative', overflow: 'hidden' }}>
                  {active ? (
                    <div style={{
                      width: `${pct}%`, height: '100%',
                      background: `linear-gradient(90deg, ${c.color}aa, ${c.color})`,
                      boxShadow: `0 0 8px ${c.color}`,
                      borderRadius: 4,
                      transition: 'width 600ms cubic-bezier(.22,1,.36,1) 200ms',
                    }} />
                  ) : (
                    <div style={{ position: 'absolute', right: 6, top: -3, color: '#FFC629', fontSize: 12 }}>🔒</div>
                  )}
                </div>
                <div className="t-display t-num" style={{ width: 24, fontSize: 11, textAlign: 'right', color: active ? '#fff' : 'rgba(241,241,241,.3)' }}>
                  {active ? score.toFixed(1) : '—'}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </RevealRow>
  );
}

// ─── Streak callout with growing flame ───
function StreakCallout({ delay, days }) {
  return (
    <RevealRow delay={delay}>
      <div className="mm-panel" style={{
        padding: '12px 16px',
        display: 'flex', alignItems: 'center', gap: 14,
        marginBottom: 8,
        background: 'linear-gradient(135deg, rgba(234,0,41,.18), rgba(255,198,41,.1) 60%, rgba(17,28,78,.55))',
        borderColor: 'rgba(255,198,41,.35)',
      }}>
        <div style={{ width: 44, height: 44, position: 'relative', filter: 'drop-shadow(0 0 12px #ea002988)', animation: 'mm-flame 1.4s ease-in-out infinite' }}>
          <svg viewBox="0 0 36 36" width="44" height="44">
            <defs>
              <radialGradient id="sum-flame" cx="50%" cy="80%" r="60%">
                <stop offset="0%"  stopColor="#fff" />
                <stop offset="35%" stopColor="#FFC629" />
                <stop offset="75%" stopColor="#ea0029" />
                <stop offset="100%" stopColor="#9b5cff" stopOpacity="0" />
              </radialGradient>
            </defs>
            <path d="M18 4 C 12 12, 8 16, 8 22 C 8 28, 12 32, 18 32 C 24 32, 28 28, 28 22 C 28 18, 24 14, 22 10 C 21 14, 19 16, 17 14 C 17 10, 18 7, 18 4 Z" fill="url(#sum-flame)" />
          </svg>
        </div>
        <div style={{ flex: 1 }}>
          <div className="t-display-x" style={{ fontSize: 10, color: 'var(--mm-yellow)', letterSpacing: '.16em' }}>Streak Ignited</div>
          <div className="t-display t-num" style={{ fontSize: 20, color: '#fff', marginTop: 2 }}>Day {days}</div>
        </div>
        <div style={{ textAlign: 'right' }}>
          <div style={{ fontSize: 10, color: 'rgba(241,241,241,.5)', fontFamily: 'var(--f-display)', letterSpacing: '.1em' }}>NEXT MILESTONE</div>
          <div className="t-display t-num" style={{ fontSize: 16, color: '#FFC629' }}>{days < 60 ? 60 : days < 90 ? 90 : days < 180 ? 180 : 365}</div>
        </div>
      </div>
    </RevealRow>
  );
}

// ─── Mystery Box ───
function MysteryBox({ delay, onReveal }) {
  const [revealed, setRevealed] = React.useState(false);
  return (
    <RevealRow delay={delay}>
      <div onClick={() => { if (!revealed) { setRevealed(true); onReveal?.(); } }}
           className="mm-panel"
           style={{
             padding: '16px', marginBottom: 8, cursor: 'pointer',
             background: revealed
               ? 'linear-gradient(135deg, rgba(155,92,255,.25), rgba(255,198,41,.18))'
               : 'linear-gradient(135deg, rgba(155,92,255,.2), rgba(42,125,225,.15))',
             borderColor: 'rgba(255,198,41,.45)',
             boxShadow: '0 0 24px rgba(155,92,255,.3)',
             display: 'flex', alignItems: 'center', gap: 14,
           }}>
        <div style={{
          width: 48, height: 48, position: 'relative',
          animation: revealed ? 'none' : 'mm-flame 2s ease-in-out infinite',
        }}>
          <svg viewBox="0 0 48 48" width="48" height="48">
            <defs>
              <linearGradient id="box-grad" x1="0" y1="0" x2="1" y2="1">
                <stop offset="0%" stopColor="#FFC629" />
                <stop offset="100%" stopColor="#9b5cff" />
              </linearGradient>
            </defs>
            <rect x="8" y="14" width="32" height="26" rx="2" fill="url(#box-grad)" stroke="#FFC629" strokeWidth="1.2" />
            <rect x="6" y="10" width="36" height="8" rx="2" fill="#9b5cff" stroke="#FFC629" strokeWidth="1.2" />
            <path d="M24 8 V 40" stroke="#FFC629" strokeWidth="1.5" />
            <path d="M16 10 C 14 4, 22 4, 24 10 C 26 4, 34 4, 32 10" fill="none" stroke="#FFC629" strokeWidth="1.5" />
          </svg>
        </div>
        <div style={{ flex: 1 }}>
          <div className="t-display-x" style={{ fontSize: 10, color: 'var(--mm-yellow)', letterSpacing: '.16em' }}>
            {revealed ? 'Mystery Box · Opened' : 'Mystery Box · Tap to open'}
          </div>
          <div style={{ fontSize: 13, color: '#fff', marginTop: 4 }}>
            {revealed
              ? <span><span className="t-display t-num" style={{ color: '#FFC629' }}>+150</span> Space Credits · Streak Saver (1)</span>
              : <span style={{ color: 'rgba(241,241,241,.7)' }}>Anticipation building...</span>}
          </div>
        </div>
        <div style={{ fontSize: 18, color: '#FFC629' }}>{revealed ? '✦' : '?'}</div>
      </div>
    </RevealRow>
  );
}

// ─── Today's Focus ───
function TodaysFocus({ delay }) {
  const items = [
    { icon: '⚠️', text: 'Strength training is at 2.3 average — flag for refinement.' },
    { icon: '◇', text: 'Deep-work block hits formed status in 3 more days.' },
    { icon: '◇', text: 'Try the new cue placement Nova suggested for hydration.' },
  ];
  return (
    <RevealRow delay={delay}>
      <div className="mm-panel" style={{ padding: '14px 16px', marginBottom: 8 }}>
        <div className="t-display-x" style={{ fontSize: 10, color: 'rgba(241,241,241,.55)', letterSpacing: '.16em', marginBottom: 10 }}>
          Today's Focus · Nova
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {items.map((it, i) => (
            <div key={i} style={{ display: 'flex', gap: 8, fontSize: 13, color: 'rgba(241,241,241,.85)', lineHeight: 1.5 }}>
              <span style={{ flexShrink: 0, color: it.icon === '⚠️' ? '#FFC629' : 'var(--mm-blue)' }}>{it.icon}</span>
              <span>{it.text}</span>
            </div>
          ))}
        </div>
      </div>
    </RevealRow>
  );
}

// ─── Daily Challenge ───
function DailyChallenge({ delay }) {
  return (
    <RevealRow delay={delay}>
      <div className="mm-panel" style={{
        padding: '14px 16px', marginBottom: 8,
        background: 'linear-gradient(135deg, rgba(0,169,143,.15), rgba(17,28,78,.55))',
        borderColor: 'rgba(0,169,143,.35)',
      }}>
        <div className="t-display-x" style={{ fontSize: 10, color: 'var(--mm-teal)', letterSpacing: '.16em', marginBottom: 6 }}>
          Daily Challenge · +50 MP
        </div>
        <div style={{ fontSize: 14, color: '#fff', lineHeight: 1.4, marginBottom: 12 }}>
          Hit a 4 or 5 on every active Core for the next 3 days.
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="mm-btn-ghost" style={{ flex: 1, color: 'var(--mm-teal)', borderColor: 'rgba(0,169,143,.5)' }}>Accept</button>
          <button className="mm-btn-ghost" style={{ flex: 1 }}>Skip</button>
        </div>
      </div>
    </RevealRow>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN: Progress Summary
// ═══════════════════════════════════════════════════════════════════════════
function Summary({ tweaks, onClose }) {
  const {
    streak = 47,
    activeCores = ['mindset', 'career', 'physical'],
    momentumScore = 8420,
    showMysteryBox = true,
  } = tweaks;

  // Mock per-core scores from the just-completed check-in
  const scores = { mindset: 4, career: 5, physical: 3 };

  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative', overflow: 'hidden',
      background: '#06070d',
      display: 'flex', flexDirection: 'column',
      paddingTop: 56,
    }}>
      <div className="mm-starfield" />
      <div className="mm-stars" style={{ opacity: .5 }} />
      <div className="mm-scanlines" />

      {/* Header */}
      <div style={{ position: 'relative', zIndex: 5, padding: '12px 18px 12px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div className="t-display-x" style={{ fontSize: 13, letterSpacing: '.18em', color: '#fff' }}>
          Mission Recap
        </div>
        <button onClick={onClose} className="mm-btn-ghost" style={{ padding: '6px 10px', fontSize: 10 }}>
          Cockpit →
        </button>
      </div>

      {/* Confirmation banner */}
      <RevealRow delay={0}>
        <div style={{
          margin: '0 18px 10px', padding: '10px 14px',
          background: 'linear-gradient(90deg, rgba(0,169,143,.25), rgba(0,169,143,.05))',
          border: '1px solid rgba(0,169,143,.5)',
          borderRadius: 6,
          display: 'flex', alignItems: 'center', gap: 10,
        }}>
          <div style={{ width: 18, height: 18, borderRadius: 9, background: 'var(--mm-teal)', display: 'grid', placeItems: 'center', flexShrink: 0 }}>
            <svg width="10" height="10" viewBox="0 0 10 10"><path d="M2 5 L 4 7 L 8 3" stroke="#fff" strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round" /></svg>
          </div>
          <div style={{ flex: 1, fontSize: 12, color: '#fff' }}>
            Day logged. Moving on.
          </div>
          <div className="t-display t-num" style={{ fontSize: 12, color: 'var(--mm-teal)' }}>
            {new Date().toLocaleDateString(undefined, { month:'short', day:'numeric' })}
          </div>
        </div>
      </RevealRow>

      {/* Reveal sequence */}
      <div style={{ position: 'relative', zIndex: 4, flex: 1, overflowY: 'auto', padding: '0 18px 30px' }}>
        <StatRow label="Momentum Today" value={125} suffix=" MP" delay={150} accent="var(--mm-blue)" />
        <StatRow label="Total Score"     value={momentumScore + 125} delay={350} />
        <StreakCallout delay={550} days={streak + 1} />
        <StatRow label="Space Credits"   value={2740} suffix=" 💎" delay={750} accent="var(--mm-yellow)" />
        <BalanceMeter delay={950} scores={scores} activeCores={activeCores} />
        <TodaysFocus delay={1150} />
        {showMysteryBox && <MysteryBox delay={1350} />}
        <DailyChallenge delay={showMysteryBox ? 1550 : 1350} />
      </div>
    </div>
  );
}

Object.assign(window, { Summary });
