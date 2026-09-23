// checkin.jsx — Daily Check-In: Score Your 5 Cores
// Implements Task 1 (Hybrid Scoring: Active vs Maintaining) +
// Task 2 (liquid-fill ScoreSlider with XP message ladder).
//
// Core states: "active" (full habit-by-habit detail) or "maintaining"
// (single quick 1-5 slider, no habit list). No "locked" framing — the brief
// reframes inactive cores as Maintaining, still scoreable at a glance.

// Habit lifecycle stages — drives color-progression dots everywhere
const HABIT_STAGE = {
  bad:     { color: 'var(--state-bad)',     label: 'Bad' },
  forming: { color: 'var(--state-forming)', label: 'Forming' },
  mbms:    { color: 'var(--state-mbm)',     label: 'MBMs attached' },
  formed:  { color: 'var(--state-formed)',  label: 'Formed' },
  trophy:  { color: 'var(--state-trophy)',  label: 'Trophy' },
};

// Per-Core data for the check-in. `mode` is 'active' (detailed scoring) or
// 'maintaining' (single quick slider). The container overrides `mode` based
// on the player's activeCores list / tweak settings.
const CHECKIN_CORES = [
  { id:'mindset',       name:'Mindset',           color:'var(--core-mindset)',
    vision:'I am a focused operator who runs on calm clarity, not panic.',
    habits:[
      { name:'Morning meditation · 10 min', stage:'mbms',    kind:'Routine' },
      { name:'Read 5 pages',                stage:'forming', kind:'Routine' },
    ] },
  { id:'career',        name:'Career & Finances', color:'var(--core-career)',
    vision:'I move with clarity on the work that compounds.',
    habits:[
      { name:'Deep-work block · 90 min', stage:'formed',  kind:'Routine' },
      { name:'Daily review · 5 min',      stage:'mbms',    kind:'Routine' },
      { name:'Money log · weekly',        stage:'forming', kind:'Non-Routine' },
    ] },
  { id:'relationships', name:'Relationships',     color:'var(--core-relationships)',
    vision:'I show up first, fully, for the people who matter.', habits:[] },
  { id:'physical',      name:'Physical Health',   color:'var(--core-physical)',
    vision:'I am an energized, active person who trains 5 days a week.',
    habits:[
      { name:'Strength training', stage:'mbms',    kind:'Routine' },
      { name:'Walk · 8,000 steps', stage:'forming', kind:'Routine' },
      { name:'Hydrate · 3L',       stage:'forming', kind:'Routine' },
    ] },
  { id:'emotional',     name:'Emotional & Mental', color:'var(--core-emotional)',
    vision:'I process, I do not perform.', habits:[] },
];

// ─── Task 2: exact XP message ladder ───
const SCORE_MESSAGES = [
  '',
  { copy: "Tough day? Tomorrow's a fresh start. You showed up — that counts!", xp: 10, tone: 'calm' },
  { copy: "Not your best, but you're tracking. That's momentum building!",     xp: 25, tone: 'calm' },
  { copy: "Solid effort! Consistency beats perfection.",                       xp: 50, tone: 'calm' },
  { copy: "Great day! You're building real momentum.",                         xp: 75, tone: 'celebrate' },
  { copy: "CRUSHING IT! 🔥 This is what growth looks like!",                   xp:100, tone: 'celebrate' },
];

// Resolve a CSS-variable color name to a literal hex/rgb for inline
// box-shadow / glow uses where var() can't be relied on.
const CORE_HEX = {
  mindset: '#2a7de1', career: '#FFC629', relationships: '#ff3d8b',
  physical: '#00a98f', emotional: '#9b5cff',
};

// ─── Habit row (lifecycle dot + name + kind) ───
function HabitRow({ habit, color }) {
  const stage = HABIT_STAGE[habit.stage];
  return (
    <div style={{
      display:'flex', alignItems:'center', gap:10,
      padding:'10px 12px',
      background:'rgba(241,241,241,.04)',
      border:'1px solid rgba(241,241,241,.08)',
      borderLeft:`3px solid ${color}`,
      borderRadius:6,
    }}>
      <div className="mm-dot" style={{ background:stage.color, boxShadow:`0 0 6px ${stage.color}` }} />
      <div style={{ flex:1, minWidth:0 }}>
        <div style={{ fontSize:13, color:'#fff', fontWeight:500 }}>{habit.name}</div>
        <div style={{ fontSize:9, fontFamily:'var(--f-display)', letterSpacing:'.12em',
            color:'rgba(241,241,241,.45)', textTransform:'uppercase', marginTop:2 }}>
          {habit.kind} · {stage.label}
        </div>
      </div>
    </div>
  );
}

// ─── Task 2: ScoreSlider rebuilt as a liquid vessel ───
//
// FlutterFlow feasibility: liquid-fill + haptics — confirm or fall back to
// glowing-track slider. Snap detents at 1-5, score 4-5 gets a celebratory
// pulse; 1-3 gets a calm acknowledgment (NEVER red/shake).
function ScoreSlider({ value, onChange, coreId = 'mindset', accentVar }) {
  const containerRef = React.useRef(null);
  const accentHex = CORE_HEX[coreId] || '#2a7de1';
  const trackColor = accentVar || `var(--core-${coreId})`;
  const fillPct = ((value - 1) / 4); // 0..1 → fills via scaleY
  const msg = SCORE_MESSAGES[value];
  const isCelebrate = msg.tone === 'celebrate';

  // Pointer-drag scoring: translate y position to a 1-5 value with snap.
  const pickFromPointer = (clientX) => {
    const r = containerRef.current.getBoundingClientRect();
    const x = Math.min(r.width - 1, Math.max(0, clientX - r.left));
    const t = x / r.width;
    const v = Math.round(t * 4) + 1; // 1..5
    if (v !== value) onChange(v);
  };
  const onPointerDown = (e) => {
    pickFromPointer(e.clientX);
    const move = (ev) => pickFromPointer(ev.clientX);
    const up = () => {
      window.removeEventListener('pointermove', move);
      window.removeEventListener('pointerup', up);
    };
    window.addEventListener('pointermove', move);
    window.addEventListener('pointerup', up);
  };

  return (
    <div>
      {/* Liquid vessel */}
      <div ref={containerRef}
           className={`mm-liquid ${isCelebrate ? 'mm-liquid--celebrate' : ''}`}
           style={{
             '--liquid-pct': fillPct,
             '--liquid-c1': accentHex,
             '--liquid-c2': accentHex + 'aa',
           }}
           role="slider" aria-valuemin="1" aria-valuemax="5" aria-valuenow={value}
           onPointerDown={onPointerDown}>
        <div className="mm-liquid__fill" />
        {/* Surface ripple at the waterline */}
        <div style={{
          position:'absolute', left:0, right:0,
          bottom: `${fillPct * 100}%`,
          height: 4,
          background: `radial-gradient(ellipse at 50% 50%, ${accentHex} 0%, transparent 80%)`,
          transform: 'translateY(2px)', opacity:.9, pointerEvents:'none',
          transition: 'bottom .4s cubic-bezier(.22,1,.36,1)',
        }} />
        {/* Detent ticks */}
        <div className="mm-liquid__detents">
          {[1,2,3,4,5].map((n) => (
            <span key={n} className="mm-liquid__detent" data-active={n === value ? '1' : '0'}>{n}</span>
          ))}
        </div>
        {/* Big score in the corner */}
        <div className="mm-liquid__score">{value}</div>
      </div>

      {/* Score-specific feedback card (XP + copy) */}
      <div style={{
        marginTop:10, padding:'10px 14px', borderRadius:8,
        background: isCelebrate
          ? `linear-gradient(135deg, ${accentHex}22, transparent 70%)`
          : 'rgba(241,241,241,.05)',
        border: `1px solid ${isCelebrate ? accentHex + '66' : 'rgba(241,241,241,.1)'}`,
        display:'flex', alignItems:'center', justifyContent:'space-between', gap:10,
        transition:'all .25s',
      }}>
        <div style={{ fontSize:12, color: isCelebrate ? '#fff' : 'rgba(241,241,241,.85)',
                      lineHeight:1.4, flex:1 }}>
          {msg.copy}
        </div>
        <div className="t-display t-num" style={{
          fontSize:14, color:'var(--mm-yellow)',
          textShadow: isCelebrate ? '0 0 10px rgba(255,198,41,.55)' : 'none',
          whiteSpace:'nowrap',
        }}>
          +{msg.xp} XP
        </div>
      </div>
    </div>
  );
}

// ─── Active-mode card: full habit detail + score + Captain's Log ───
// `onFlag(habitName)` opens the inline Mission Control intervention.
function ActiveCoreCard({ core, scoreValue, onScore, log, onLog, onFlag }) {
  const accent = `var(--core-${core.id})`;
  // Mock: first habit is "struggling" (≤3 for 3+ days) OR the live score is low.
  const struggling = core.struggling || scoreValue <= 2;
  return (
    <div style={{ padding:'4px 18px 20px', height:'100%', overflowY:'auto' }}>
      {/* Core header */}
      <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:8 }}>
        <div style={{
          width:10, height:10, borderRadius:'50%',
          background:accent, boxShadow:`0 0 12px ${accent}`,
        }} />
        <div className="t-display-x" style={{ fontSize:12, color:accent, letterSpacing:'.16em' }}>
          {core.name}
        </div>
        <span className="mm-chip" style={{ fontSize:9, letterSpacing:'.14em', marginLeft:'auto',
            color:accent, borderColor: 'currentColor' }}>ACTIVE</span>
      </div>

      {/* Inline Mission Control flag alert (amber, supportive) */}
      {struggling && (
        <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:12,
            padding:'10px 12px', borderRadius:8,
            background:'rgba(255,198,41,.12)', border:'1px solid rgba(255,198,41,.4)' }}>
          <span style={{ color:'var(--mm-amber)', flexShrink:0, fontSize:14 }}>⚠</span>
          <span style={{ flex:1, fontSize:11.5, color:'#fff', lineHeight:1.4 }}>
            Pattern detected on <b>{core.habits[0]?.name || 'a habit'}</b> — 3 days at or below 3.0.
          </span>
          <button onClick={() => onFlag?.(core.habits[0]?.name || core.name)}
            style={{ background:'var(--mm-amber)', border:0, borderRadius:6, padding:'6px 10px',
              color:'#1a1400', fontFamily:'var(--f-display)', fontSize:10, letterSpacing:'.08em',
              cursor:'pointer', whiteSpace:'nowrap' }}>RESOLVE</button>
        </div>
      )}

      {/* BTTF Vision card */}
      <div style={{
        padding:'12px 14px', borderRadius:6,
        background:`linear-gradient(135deg, ${accent} 0%, transparent 70%)`,
        backgroundColor:'rgba(241,241,241,.04)',
        borderLeft:`2px solid ${accent}`,
        marginBottom:14,
      }}>
        <div style={{ fontSize:8, fontFamily:'var(--f-display)', letterSpacing:'.18em',
            color:'rgba(241,241,241,.45)', textTransform:'uppercase', marginBottom:4 }}>
          BTTF Vision
        </div>
        <div style={{ fontSize:13, color:'#fff', lineHeight:1.5, fontStyle:'italic' }}>
          "{core.vision}"
        </div>
      </div>

      {/* Habit list — each row manually flaggable */}
      <div style={{ display:'flex', flexDirection:'column', gap:6, marginBottom:14 }}>
        {core.habits.map((h, i) => (
          <div key={i} style={{ position:'relative' }}>
            <HabitRow habit={h} color={accent} />
            <button onClick={() => onFlag?.(h.name)} aria-label="Flag habit"
              title="Flag for refinement"
              style={{ position:'absolute', right:8, top:'50%', transform:'translateY(-50%)',
                background:'transparent', border:0, color:'rgba(255,198,41,.7)', cursor:'pointer',
                fontSize:13, padding:4 }}>⚑</button>
          </div>
        ))}
      </div>

      {/* Liquid score slider */}
      <ScoreSlider value={scoreValue} onChange={onScore} coreId={core.id} accentVar={accent} />

      {/* Captain's Log */}
      <div style={{ marginTop:14 }}>
        <div style={{ display:'flex', justifyContent:'space-between', alignItems:'baseline', marginBottom:6 }}>
          <span className="t-display-x" style={{ fontSize:10, color:'rgba(241,241,241,.55)', letterSpacing:'.16em' }}>
            Captain's Log
          </span>
          {log && log.length > 0 && (
            <span style={{ fontSize:10, color:'var(--state-formed)',
                fontFamily:'var(--f-display)', letterSpacing:'.1em' }}>
              ✓ Logged
            </span>
          )}
        </div>
        <textarea value={log || ''} onChange={(e) => onLog(e.target.value)}
          placeholder="What's the data? (optional · unlocks Mystery Box)"
          style={{
            width:'100%', minHeight:56, resize:'none',
            background:'rgba(241,241,241,.04)',
            border:`1px solid ${log ? accent : 'rgba(241,241,241,.1)'}`,
            borderRadius:6, padding:'10px 12px',
            color:'#fff', fontSize:13, fontFamily:'var(--f-body)', outline:'none',
          }} />
      </div>
    </div>
  );
}

// ─── Maintaining-mode card: one quick slider, no habits ───
//
// Task 1: "How's your [Core] today?" — single 1-5 slider, no habit list.
// Reframed from "Locked" (shame) → "Maintaining" (invitation). Still
// scoreable at a glance so the daily ritual stays under ~3 minutes.
function MaintainingCoreCard({ core, scoreValue, onScore }) {
  const accent = `var(--core-${core.id})`;
  return (
    <div style={{ padding:'4px 18px 20px', height:'100%', display:'flex', flexDirection:'column' }}>
      <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:14 }}>
        <div style={{
          width:10, height:10, borderRadius:'50%',
          background:accent, opacity:.55, boxShadow:`0 0 8px ${accent}`,
        }} />
        <div className="t-display-x" style={{ fontSize:12, color:accent, letterSpacing:'.16em' }}>
          {core.name}
        </div>
        <span className="mm-chip" style={{ fontSize:9, letterSpacing:'.14em', marginLeft:'auto',
            color:'rgba(241,241,241,.7)' }}>MAINTAINING</span>
      </div>

      {/* Big quick prompt */}
      <div className="mm-panel" style={{ padding:'18px 16px', marginBottom:14,
          background:`linear-gradient(135deg, ${accent} 0%, transparent 80%)`,
          backgroundColor:'rgba(17,28,78,.45)', borderColor:'rgba(241,241,241,.1)' }}>
        <div className="t-display" style={{ fontSize:18, color:'#fff', lineHeight:1.3 }}>
          How's your<br />{core.name.toLowerCase()} today?
        </div>
        <div style={{ fontSize:11, color:'rgba(241,241,241,.6)', marginTop:8, lineHeight:1.5 }}>
          No active habits yet — just a quick gut-check.
          Add a Golden Habit in Phase 1 when you're ready to level up this Core.
        </div>
      </div>

      <ScoreSlider value={scoreValue} onChange={onScore} coreId={core.id} accentVar={accent} />

      <div style={{ marginTop:18, fontSize:11, color:'rgba(241,241,241,.45)', textAlign:'center',
          fontFamily:'var(--f-display)', letterSpacing:'.14em' }}>
        TAKES ~5 SECONDS · NO PENALTY FOR ANY SCORE
      </div>
    </div>
  );
}

// ─── Single Core check-in card — dispatches by mode ───
function CoreCheckInCard({ core, scoreValue, onScore, log, onLog, onFlag }) {
  if (core.mode === 'maintaining') {
    return <MaintainingCoreCard core={core} scoreValue={scoreValue} onScore={onScore} />;
  }
  return <ActiveCoreCard core={core} scoreValue={scoreValue} onScore={onScore}
                         log={log} onLog={onLog} onFlag={onFlag} />;
}

// ─── Top progress bar (5 segments) ───
function CheckInProgress({ idx, cores }) {
  return (
    <div style={{ display:'flex', gap:4, padding:'0 18px', marginTop:4 }}>
      {cores.map((c, i) => (
        <div key={i} style={{
          flex:1, height:3, borderRadius:2,
          background: i <= idx ? `var(--core-${c.id})` : 'rgba(241,241,241,.1)',
          opacity: i <= idx ? (c.mode === 'maintaining' ? .5 : 1) : 1,
          boxShadow: i === idx ? `0 0 6px var(--core-${c.id})` : 'none',
          transition:'all .3s',
        }} />
      ))}
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN: Daily Check-In flow
// ═══════════════════════════════════════════════════════════════════════════
function CheckIn({ tweaks, onComplete, onClose }) {
  const {
    activeCores = ['mindset', 'career', 'physical'],
    scoringMode,                   // optional override from TweaksPanel
  } = tweaks;

  // Resolve each Core to active/maintaining. Tweak override forces all to
  // the same mode for demo.
  const cores = CHECKIN_CORES.map((c) => {
    let mode = activeCores.includes(c.id) ? 'active' : 'maintaining';
    if (scoringMode === 'all-active')     mode = 'active';
    if (scoringMode === 'all-maintaining') mode = 'maintaining';
    return { ...c, mode };
  });

  const [idx, setIdx] = React.useState(0);
  const [scores, setScores] = React.useState({});
  const [logs, setLogs]     = React.useState({});
  const [flagH, setFlagH]   = React.useState(null); // {habitName, coreId} → opens intervention
  const [expToast, setExpToast] = React.useState(null);

  React.useEffect(() => {
    if (!expToast) return undefined;
    const t = setTimeout(() => setExpToast(null), 2400);
    return () => clearTimeout(t);
  }, [expToast]);

  const core = cores[idx];
  const isLast = idx === cores.length - 1;

  const advance = () => {
    if (isLast) onComplete?.({ scores, logs });
    else setIdx(idx + 1);
  };

  return (
    <div style={{
      width:'100%', height:'100%', position:'relative', overflow:'hidden',
      background:'var(--mm-bg)',
      display:'flex', flexDirection:'column',
      paddingTop:56,
    }}>
      <div className="mm-starfield" style={{ opacity:.7 }} />
      <div className="mm-stars" style={{ opacity:.4 }} />
      <div className="mm-scanlines" />

      {/* Header */}
      <div style={{ position:'relative', zIndex:5 }}>
        <div style={{
          display:'flex', alignItems:'center', justifyContent:'space-between',
          padding:'12px 18px 10px',
        }}>
          <button onClick={onClose} style={{
            background:'rgba(241,241,241,.06)', border:'1px solid rgba(241,241,241,.12)',
            color:'#fff', borderRadius:8, width:32, height:32, cursor:'pointer',
            display:'grid', placeItems:'center', fontSize:18, lineHeight:1,
          }}>×</button>
          <div className="t-display-x" style={{ fontSize:12, letterSpacing:'.18em', color:'#fff' }}>
            Daily Check-in
          </div>
          <div className="mm-chip t-display" style={{ fontSize:10, letterSpacing:'.12em' }}>
            {idx + 1} / {cores.length}
          </div>
        </div>
        <CheckInProgress idx={idx} cores={cores} />
      </div>

      {/* Card body */}
      <div style={{ position:'relative', zIndex:4, flex:1, minHeight:0 }}>
        <CoreCheckInCard
          core={core}
          scoreValue={scores[core.id] || 3}
          onScore={(v) => setScores({ ...scores, [core.id]: v })}
          log={logs[core.id]}
          onLog={(v) => setLogs({ ...logs, [core.id]: v })}
          onFlag={(habitName) => setFlagH({ habitName, coreId: core.id })} />
      </div>

      {/* Inline Mission Control intervention — reuses the habits-screen modal */}
      {flagH && typeof MissionControlIntervention !== 'undefined' && (
        <MissionControlIntervention
          h={{ habitName: flagH.habitName, coreId: flagH.coreId }}
          onClose={() => setFlagH(null)}
          onPick={({ path, deeper }) => {
            setFlagH(null);
            const tag = path === 'quick'  ? 'Quick tweak'
                     : path === 'manual' ? 'Manual edit'
                     : `Go Deeper · Path ${deeper}`;
            setExpToast(`🧪 ${tag} · 3-day experiment logged`);
          }} />
      )}

      {/* Experiment toast */}
      {expToast && (
        <div style={{ position:'absolute', left:14, right:14, bottom:90, zIndex:60,
          padding:'10px 14px', borderRadius:10, textAlign:'center',
          background:'rgba(0,169,143,.18)', border:'1px solid rgba(0,169,143,.55)',
          color:'#fff', fontSize:12, boxShadow:'0 8px 24px rgba(0,0,0,.4)' }}>
          {expToast}
        </div>
      )}

      {/* Footer */}
      <div style={{
        position:'relative', zIndex:6,
        padding:'10px 18px 30px',
        background:'linear-gradient(180deg, transparent, rgba(10,13,18,.95) 50%)',
        display:'flex', gap:10,
      }}>
        {idx > 0 && (
          <button onClick={() => setIdx(idx - 1)} className="mm-btn-ghost" style={{ flex:0.5 }}>
            ← Back
          </button>
        )}
        <button onClick={advance} className="mm-btn-primary" style={{ flex:1, padding:'14px' }}>
          {isLast ? 'Lock In Day' : 'Next Core →'}
        </button>
      </div>
    </div>
  );
}

Object.assign(window, { CheckIn, ScoreSlider, SCORE_MESSAGES });
