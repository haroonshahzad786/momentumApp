// phase1.jsx — Phase 1: Foundation Building
// Stage 1 = HHS (Habits Hierarchy System) — 5 sections → Golden Habit
// Stage 2 = MBS (Momentum Boosting System) — 3 MBMs + IF-THEN → Cantina unlock
//
// The brief calls this the "character build" before Phase 2 (daily execution).
// All screens here use Voiceflow-style chat affordances but a single static
// React component per section, since the live chat is wired in production.

const HHS_SECTIONS = [
  { id: 1, key: 'pain',      label: 'Pain Point Scanner',     emoji: '🔍', achievement: 'Truth Seeker',         mp: 10, color: '#ea0029' },
  { id: 2, key: 'core',      label: 'Core Connection',         emoji: '🧠', achievement: 'Core Confirmed',       mp: 15, color: '#2a7de1' },
  { id: 3, key: 'principle', label: 'Universal Principle',     emoji: '📘', achievement: 'Principle Decoder',    mp: 20, color: '#9b5cff' },
  { id: 4, key: 'keystone',  label: 'Keystone Personalizer',   emoji: '🔑', achievement: 'Keystone Forger',      mp: 25, color: '#FFC629' },
  { id: 5, key: 'forge',     label: 'Golden Habit Forge',      emoji: '✨', achievement: 'Golden Habit Architect', mp: 40, color: '#00a98f' },
];

const MBMS = [
  { id: 'obvious', name: 'Make It Obvious',   icon: '🔍', desc: 'Design environmental cues so the habit is impossible to forget.', color: '#FFC629' },
  { id: 'easy',    name: 'Make It Easy',      icon: '⚡', desc: 'Shrink the friction so starting takes under 2 minutes.',         color: '#2a7de1' },
  { id: 'reward',  name: 'Make It Rewarding', icon: '🎉', desc: 'Layer in dopamine — celebrate every rep, even the small ones.',  color: '#ff3d8b' },
];

// ─── The Habits Hierarchy Pyramid (mini-map shown at the top of each section)
// 5 stacked trapezoid bands, each labeled. Section 5 (the tip) shows a tiny
// label and locks until the prior sections are complete. Compact variant
// drops the lock + rocket and shrinks vertically for in-section headers.
const PYRAMID_BANDS = [
  { id: 5, key: 'forge',     label: 'Golden Habit',    fill: '#9aa0ad', fillLocked: '#9aa0ad', textColor: '#fff', short: 'Golden Habit' },
  { id: 4, key: 'keystone',  label: 'Keystone Habit',  fill: '#d99c3a', textColor: '#fff', short: 'Keystone' },
  { id: 3, key: 'principle', label: 'Core Dimension',  fill: '#e87a3c', textColor: '#fff', short: 'Dimension' },
  { id: 2, key: 'core',      label: 'Related Core',    fill: '#e83838', textColor: '#fff', short: 'Core' },
  { id: 1, key: 'pain',      label: 'Pain Point',      fill: '#9c2520', textColor: '#fff', short: 'Pain Point' },
];

function HHSPyramid({ active, completed = [], compact = false }) {
  // Geometry: a tall triangle made of 5 horizontal trapezoid slices.
  // SVG viewBox is 520x720 (full) / 280x150 (compact). Apex x = center.
  const W = compact ? 280 : 520;
  const H = compact ? 150 : 720;
  const apexX = W / 2;
  // Top of band 5 is the apex tip
  const apexY = compact ? 6  : 90;
  const baseY = compact ? 132 : 600;
  const slope = (W - 40) / 2 / (baseY - apexY); // pyramid half-width per unit Y
  const slices = 5;
  const sliceH = (baseY - apexY) / slices;

  // Progress squares + trophy (only in full size, not compact)
  const showHeader = !compact;

  const trapezoidPath = (i) => {
    // i = 0 is the tip, i = 4 is the base
    const yTop = apexY + i * sliceH;
    const yBot = apexY + (i + 1) * sliceH;
    const halfTop = (yTop - apexY) * slope;
    const halfBot = (yBot - apexY) * slope;
    const inset = 2; // visual gap between bands
    return `M ${apexX - halfTop + inset} ${yTop + inset}
            L ${apexX + halfTop - inset} ${yTop + inset}
            L ${apexX + halfBot - inset} ${yBot - inset}
            L ${apexX - halfBot + inset} ${yBot - inset} Z`;
  };

  return (
    <div style={{ width:'100%', display:'flex', flexDirection:'column', alignItems:'center' }}>
      <svg viewBox={`0 0 ${W} ${H}`} width="100%" style={{ maxWidth: compact ? 280 : 360, display:'block' }}>
        <defs>
          <filter id="hhs-shadow" x="-10%" y="-10%" width="120%" height="120%">
            <feDropShadow dx="0" dy="2" stdDeviation="3" floodColor="#000" floodOpacity=".35" />
          </filter>
        </defs>

        {/* Progress squares + trophy header (full size only) */}
        {showHeader && (() => {
          // 4 progress squares (sections 1-4 completed) + trophy for section 5
          const squareSize = 22;
          const gap = 6;
          const totalW = 4 * squareSize + 3 * gap + 16 + 28;
          const startX = (W - totalW) / 2;
          const headerY = 22;
          return (
            <g>
              {[1,2,3,4].map((n, i) => {
                const isDone = completed.includes(n);
                const isActiveSq = n === active;
                return (
                  <rect key={n}
                    x={startX + i * (squareSize + gap)} y={headerY}
                    width={squareSize} height={squareSize} rx={2}
                    fill={isDone ? '#1d8a3a' : isActiveSq ? '#1d8a3a99' : '#d0d3d8'}
                    stroke={isActiveSq ? '#1d8a3a' : 'transparent'}
                    strokeWidth="1.5" />
                );
              })}
              {/* Trophy icon group */}
              <g transform={`translate(${startX + 4 * (squareSize + gap) + 16}, ${headerY - 2})`}>
                <path d="M 4 4 H 22 V 11 a 9 9 0 0 1 -18 0 V 4 Z M 22 5 H 26 V 8 a 4 4 0 0 1 -4 4 M 4 5 H 0 V 8 a 4 4 0 0 0 4 4 M 9 18 H 17 V 24 H 9 Z M 6 24 H 20"
                  fill={completed.includes(5) ? '#FFC629' : '#d0d3d8'}
                  stroke={completed.includes(5) ? '#c98a00' : '#9aa0ad'}
                  strokeWidth="1.2" strokeLinejoin="round" />
              </g>
            </g>
          );
        })()}

        {/* Pyramid bands — tip → base, so labels overlay base-to-tip render order */}
        {PYRAMID_BANDS.map((band, idx) => {
          // band.id 5 = tip (idx 0), band.id 1 = base (idx 4)
          const sliceIdx = 5 - band.id; // 0 = tip, 4 = base
          const isActive = band.id === active;
          const isDone = completed.includes(band.id);
          const isLocked = band.id === 5 && !completed.includes(5);
          const fill = isLocked ? band.fillLocked : band.fill;
          const yMid = apexY + (sliceIdx + 0.5) * sliceH;

          // Text size scales with band width — tip is small, base is large
          const halfMid = (yMid - apexY) * slope;
          const labelSize = compact
            ? Math.max(7, Math.min(11, halfMid * 0.18))
            : Math.max(11, Math.min(22, halfMid * 0.2));

          return (
            <g key={band.id} filter="url(#hhs-shadow)">
              <path d={trapezoidPath(sliceIdx)}
                fill={fill}
                opacity={isLocked ? .55 : 1}
                style={{ animation: isActive ? 'mm-flame 2.2s ease-in-out infinite' : 'none' }} />

              {/* Lock icon on the tip if it's locked */}
              {isLocked && !compact && (
                <g transform={`translate(${apexX}, ${yMid - 16})`} opacity=".85">
                  <rect x="-6" y="-2" width="12" height="9" rx="1.5" fill="#5a5f6b" />
                  <path d="M -4 -2 V -5 a 4 4 0 0 1 8 0 V -2" stroke="#5a5f6b" strokeWidth="1.5" fill="none" />
                </g>
              )}

              {/* Band label — uppercased in compact, title case in full */}
              <text x={apexX} y={yMid + (isLocked && !compact ? 6 : 0)}
                textAnchor="middle" dominantBaseline="middle"
                fontFamily="var(--f-display)"
                fontWeight={band.id === 1 ? 700 : 600}
                fontSize={labelSize}
                letterSpacing={compact ? '1.2' : '0.5'}
                fill={band.textColor}
                style={{ textShadow: '0 1px 2px rgba(0,0,0,.35)' }}>
                {compact ? band.short.toUpperCase() : band.label}
              </text>

              {/* Done checkmark in top-right corner of the band */}
              {isDone && (
                <g transform={`translate(${apexX + halfMid - (compact ? 12 : 22)}, ${yMid})`}>
                  <circle r={compact ? 5 : 9} fill="#1d8a3a" stroke="#fff" strokeWidth="1" />
                  <path d={compact ? "M -2 0 L -.5 2 L 2 -1.5" : "M -3.5 0 L -1 2.5 L 3.5 -2.5"}
                    stroke="#fff" strokeWidth={compact ? 1.5 : 2}
                    fill="none" strokeLinecap="round" strokeLinejoin="round" />
                </g>
              )}
            </g>
          );
        })}

        {/* Rocket sitting at the base — full size only */}
        {!compact && (
          <g transform={`translate(${apexX}, ${baseY + 50})`}>
            <ellipse cx="0" cy="38" rx="22" ry="4" fill="#000" opacity=".25" />
            {/* nose */}
            <path d="M 0 -38 C -14 -28 -16 -8 -16 6 L 16 6 C 16 -8 14 -28 0 -38 Z" fill="#ea3a3a" />
            {/* hull */}
            <path d="M -16 6 L -16 24 L -10 32 L 10 32 L 16 24 L 16 6 Z" fill="#e8eaef" />
            {/* porthole */}
            <circle cx="0" cy="8" r="6" fill="#1f4f99" stroke="#2a7de1" strokeWidth="1.5" />
            {/* fins */}
            <path d="M -16 14 L -26 30 L -16 28 Z" fill="#c41d1d" />
            <path d="M 16 14 L 26 30 L 16 28 Z" fill="#c41d1d" />
            {/* flame */}
            <path d="M -7 32 Q -10 42 0 48 Q 10 42 7 32 Z" fill="#FFC629"
              style={{ animation: 'mm-plume 1.1s ease-in-out infinite', transformOrigin: '0 32px' }} />
          </g>
        )}
      </svg>
    </div>
  );
}

// ─── Phase 1 Hub: launchpad with both stages and progress ───────────────
function Phase1Hub({ phase1State, onStartStage1, onStartStage2, onBack }) {
  const stage1Done = phase1State?.stage1Completed || false;
  const stage1Progress = phase1State?.stage1Progress || 0; // 0-5
  const stage2Done = phase1State?.stage2Completed || false;

  return (
    <div style={{ width:'100%', height:'100%', overflow:'auto', background:'#06070d',
        paddingTop:56, position:'relative' }}>
      <div className="mm-starfield" />
      <div className="mm-stars" />
      <div className="mm-scanlines" />

      <div style={{ position:'relative', zIndex:5, padding:'14px 18px 30px' }}>
        <button onClick={onBack} aria-label="Back" style={{
          background:'rgba(17,28,78,.55)', border:'1px solid rgba(241,241,241,.12)',
          borderRadius:10, width:36, height:36, color:'#fff', display:'grid', placeItems:'center', cursor:'pointer', marginBottom:14,
        }}>
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M10 3 L 4 8 L 10 13"/></svg>
        </button>

        <div className="t-display-x" style={{ fontSize:11, letterSpacing:'.22em', color:'var(--mm-yellow)' }}>
          PHASE 1 · FOUNDATION
        </div>
        <div className="t-display" style={{ fontSize:24, color:'#fff', marginTop:4 }}>
          Character Build
        </div>
        <div style={{ fontSize:12, color:'rgba(241,241,241,.65)', lineHeight:1.5, marginTop:8 }}>
          Move from vague pain point → personalized Golden Habit, then engineer it to be
          impossible to skip. 3–5 minutes for first-time; 1–2 for returning Captains.
        </div>

        {/* Stage 1 card */}
        <div className="mm-panel" style={{
          padding:'16px 16px 14px', marginTop:18,
          borderLeft:`3px solid ${stage1Done ? 'var(--mm-teal)' : 'var(--mm-yellow)'}`,
          background:`linear-gradient(135deg, ${stage1Done ? 'rgba(0,169,143,.12)' : 'rgba(255,198,41,.10)'}, transparent 70%)`,
        }}>
          <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between' }}>
            <div>
              <div className="t-display-x" style={{ fontSize:10, color:'var(--mm-yellow)', letterSpacing:'.18em' }}>
                STAGE 1 · HHS
              </div>
              <div style={{ fontSize:15, fontWeight:600, color:'#fff', marginTop:4 }}>Habits Hierarchy</div>
            </div>
            {stage1Done && <span style={{ fontSize:12, color:'var(--mm-teal)', fontFamily:'var(--f-display)' }}>✓ COMPLETE</span>}
          </div>

          <div style={{ fontSize:12, color:'rgba(241,241,241,.7)', marginTop:6, lineHeight:1.45 }}>
            5-section AI conversation to surface your top pain point and forge your first Golden Habit.
          </div>

          <HHSPyramid active={stage1Done ? 0 : stage1Progress + 1}
                      completed={Array.from({length: stage1Progress}, (_, i) => i+1)} />

          <button onClick={onStartStage1}
            className={stage1Done ? 'mm-btn-ghost' : 'mm-btn-primary'}
            style={{ width:'100%', padding:'12px', marginTop:8 }}>
            {stage1Done ? 'Forge another Golden Habit →' : stage1Progress > 0 ? 'Continue Stage 1 →' : 'Begin Stage 1 →'}
          </button>
        </div>

        {/* Stage 2 card */}
        <div className="mm-panel" style={{
          padding:'16px 16px 14px', marginTop:12,
          borderLeft:`3px solid ${stage2Done ? 'var(--mm-teal)' : stage1Done ? 'var(--mm-magenta)' : 'rgba(241,241,241,.18)'}`,
          background: stage1Done ? 'linear-gradient(135deg, rgba(255,61,139,.10), transparent 70%)' : 'rgba(241,241,241,.03)',
          opacity: stage1Done ? 1 : .55,
        }}>
          <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between' }}>
            <div>
              <div className="t-display-x" style={{ fontSize:10, color:stage1Done ? 'var(--mm-magenta)' : 'rgba(241,241,241,.4)', letterSpacing:'.18em' }}>
                STAGE 2 · MBS
              </div>
              <div style={{ fontSize:15, fontWeight:600, color:'#fff', marginTop:4 }}>3 Momentum Methods</div>
            </div>
            {stage2Done
              ? <span style={{ fontSize:12, color:'var(--mm-teal)', fontFamily:'var(--f-display)' }}>✓ COMPLETE</span>
              : !stage1Done && <span style={{ fontSize:18, color:'var(--mm-yellow)' }}>🔒</span>}
          </div>

          <div style={{ fontSize:12, color:'rgba(241,241,241,.7)', marginTop:6, lineHeight:1.45 }}>
            Engineer your Golden Habit with Obvious / Easy / Rewarding strategies, then lock in an IF-THEN obstacle plan.
          </div>

          <div style={{ display:'flex', gap:6, marginTop:10 }}>
            {MBMS.map((m) => (
              <div key={m.id} style={{
                flex:1, padding:'8px 6px', borderRadius:6, textAlign:'center',
                background: stage2Done ? `${m.color}22` : 'rgba(241,241,241,.04)',
                border: `1px solid ${stage2Done ? m.color + '66' : 'rgba(241,241,241,.1)'}`,
              }}>
                <div style={{ fontSize:18 }}>{m.icon}</div>
                <div className="t-display-x" style={{ fontSize:7, letterSpacing:'.12em', color: stage2Done ? '#fff' : 'rgba(241,241,241,.5)', marginTop:3 }}>
                  {m.name.replace('Make It ','').toUpperCase()}
                </div>
              </div>
            ))}
          </div>

          <button onClick={() => stage1Done && onStartStage2()}
            disabled={!stage1Done}
            className={stage1Done ? (stage2Done ? 'mm-btn-ghost' : 'mm-btn-primary') : 'mm-btn-ghost'}
            style={{ width:'100%', padding:'12px', marginTop:12,
              opacity: stage1Done ? 1 : .5,
              cursor: stage1Done ? 'pointer' : 'default' }}>
            {!stage1Done ? 'Locked · finish Stage 1 first'
              : stage2Done ? 'Refine MBMs →'
              : 'Begin Stage 2 →'}
          </button>
        </div>

        {/* Rewards strip */}
        <div style={{ marginTop:18, fontSize:10, fontFamily:'var(--f-display)',
          letterSpacing:'.16em', color:'rgba(241,241,241,.5)', textAlign:'center' }}>
          UNLOCKS: COMMAND CENTER · SPACE CANTINA · DAILY COCKPIT
        </div>
      </div>
    </div>
  );
}

// ─── Chat bubble (used inside HHS sections) ─────────────────────────────
function Bubble({ from, text }) {
  return (
    <div style={{
      alignSelf: from === 'me' ? 'flex-end' : 'flex-start',
      maxWidth: '85%',
      padding:'9px 12px',
      borderRadius: from === 'me' ? '14px 14px 4px 14px' : '14px 14px 14px 4px',
      background: from === 'me'
        ? 'linear-gradient(180deg, #3a8dff 0%, #1f5fb8 100%)'
        : 'rgba(17,28,78,.7)',
      border: from === 'me' ? '1px solid rgba(77,155,255,.5)' : '1px solid rgba(155,92,255,.3)',
      color:'#fff', fontSize:13, lineHeight:1.45,
    }}>{text}</div>
  );
}

// ─── HHS Section: one of 5 conversation screens ─────────────────────────
function HHSSectionScreen({ section, onComplete, onBack, completed, sectionIdx }) {
  const [phase, setPhase] = React.useState('intro'); // intro → answering → reward
  const [answer, setAnswer] = React.useState('');
  const [picked, setPicked] = React.useState(null);

  // Section-specific prompts, options, and reframe
  const CONTENT = {
    pain: {
      prompt: "What's the one thing holding you back from being your best self right now?",
      suggestions: [
        "I get stuck in scarcity thinking",
        "I avoid difficult conversations",
        "I keep skipping workouts",
        "I overspend impulsively",
      ],
      reframe: 'PRIMARY CHALLENGE',
    },
    core: {
      prompt: "This sounds like it lives mostly in your Mindset Core. Want to confirm or adjust?",
      options: [
        { id:'mindset',  label:'🧠 Mindset',         hex:'#2a7de1' },
        { id:'career',   label:'💰 Career & Finances', hex:'#FFC629' },
        { id:'relationships', label:'👥 Relationships',  hex:'#ff3d8b' },
        { id:'physical', label:'💪 Physical Health',  hex:'#00a98f' },
        { id:'emotional',label:'🧘 Emotional & Mental', hex:'#9b5cff' },
      ],
      reframe: 'PRIMARY CORE',
    },
    principle: {
      prompt: "Three Universal Principles seem to fit your pattern. Which lands hardest?",
      options: [
        { id:'positivity', label:'🪐 Law of Positivity',     desc:'"What you focus on expands." — Robin Sharma' },
        { id:'acknowledge',label:'🪐 Principle of Acknowledgment', desc:'"Recognition is the antidote to invisibility."' },
        { id:'gratitude',  label:'🪐 The Compounding Effect',  desc:'"Small, repeated practice rewires the brain."' },
      ],
      reframe: 'UNIVERSAL PRINCIPLE',
    },
    keystone: {
      prompt: "When in your day do you feel most able to start a new habit?",
      options: [
        { id:'morning', label:'🌅 Morning ritual',   desc:'Stacked onto coffee or shower' },
        { id:'midday',  label:'☀️ Midday reset',     desc:'After lunch or between blocks' },
        { id:'evening', label:'🌙 Evening wind-down', desc:'Before bed' },
        { id:'flexible',label:'❌⏰ Anywhere (non-routine)', desc:'Trigger is internal — emotion, urge, situation' },
      ],
      reframe: 'KEYSTONE CATEGORY',
    },
    forge: {
      prompt: "I'm pulling everything together into your first Golden Habit. Lock it in?",
      output: {
        name: 'Morning Mindset Ritual',
        type: '✅⏰ ROUTINE',
        where: 'Bathroom · ~7:00 AM',
        when: 'Right after turning on the shower',
        what: 'Recite a 60-second gratitude mantra while stretching, with music playing',
        ifthen: 'IF I oversleep → THEN one breath + one affirmation before touching my phone',
        why: 'WANT (music + movement = energy) · CAN (stacked onto existing cue) · EFFECTIVE (rewires scarcity → abundance)',
      },
      reframe: 'GOLDEN HABIT',
    },
  };
  const c = CONTENT[section.key];
  const sectionColor = section.color;

  const submit = () => {
    if (section.key === 'pain' && !answer.trim() && !picked) return;
    if (section.key !== 'pain' && !picked) return;
    setPhase('reward');
  };

  return (
    <div style={{ width:'100%', height:'100%', overflow:'hidden', background:'#06070d',
        paddingTop:56, position:'relative', display:'flex', flexDirection:'column' }}>
      <div className="mm-starfield" />
      <div className="mm-stars" />

      {/* header with mini pyramid */}
      <div style={{ position:'relative', zIndex:5, padding:'10px 14px 6px',
          borderBottom:`1px solid ${sectionColor}33`,
          background:`linear-gradient(180deg, ${sectionColor}11, transparent)` }}>
        <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:6 }}>
          <button onClick={onBack} aria-label="Back" style={{
            background:'rgba(17,28,78,.55)', border:'1px solid rgba(241,241,241,.12)',
            borderRadius:10, width:32, height:32, color:'#fff', display:'grid', placeItems:'center', cursor:'pointer' }}>
            <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 2 L 4 7 L 9 12"/></svg>
          </button>
          <div style={{ flex:1, textAlign:'center' }}>
            <div className="t-display-x" style={{ fontSize:9, color:sectionColor, letterSpacing:'.2em' }}>
              STAGE 1 · SECTION {section.id}/5
            </div>
            <div className="t-display" style={{ fontSize:13, color:'#fff' }}>
              {section.emoji} {section.label}
            </div>
          </div>
          <span className="mm-chip t-num" style={{ color:sectionColor }}>+{section.mp} MP</span>
        </div>
        <HHSPyramid active={section.id} completed={completed} compact />
      </div>

      {/* body */}
      <div style={{ position:'relative', zIndex:4, flex:1, overflow:'auto',
          padding:'14px', display:'flex', flexDirection:'column', gap:10 }}>
        <Bubble from="ai" text={c.prompt} />

        {phase === 'intro' && (
          <>
            {/* Section 1: free text */}
            {section.key === 'pain' && (
              <>
                <div style={{ display:'flex', flexDirection:'column', gap:6 }}>
                  {c.suggestions.map((s) => (
                    <button key={s} onClick={() => { setAnswer(s); setPicked(s); }} style={{
                      textAlign:'left', padding:'10px 12px', borderRadius:8,
                      background: picked === s ? `${sectionColor}22` : 'rgba(241,241,241,.04)',
                      border: `1px solid ${picked === s ? sectionColor : 'rgba(241,241,241,.1)'}`,
                      color:'#fff', fontSize:12, cursor:'pointer',
                    }}>{s}</button>
                  ))}
                </div>
                <textarea value={answer} onChange={(e) => { setAnswer(e.target.value); setPicked(e.target.value); }}
                  placeholder="…or type your own"
                  rows={2}
                  style={{ background:'rgba(17,28,78,.55)', border:`1px solid ${sectionColor}55`,
                    borderRadius:8, padding:'10px 12px', color:'#fff', fontSize:13, outline:'none',
                    fontFamily:'var(--f-body)', resize:'none', marginTop:6 }} />
              </>
            )}

            {/* Sections 2-4: choice list */}
            {['core','principle','keystone'].includes(section.key) && (
              <div style={{ display:'flex', flexDirection:'column', gap:6 }}>
                {c.options.map((o) => (
                  <button key={o.id} onClick={() => setPicked(o.id)} style={{
                    textAlign:'left', padding:'10px 12px', borderRadius:8,
                    background: picked === o.id ? `${o.hex || sectionColor}22` : 'rgba(241,241,241,.04)',
                    border: `1px solid ${picked === o.id ? (o.hex || sectionColor) : 'rgba(241,241,241,.1)'}`,
                    color:'#fff', fontSize:13, cursor:'pointer',
                  }}>
                    <div>{o.label}</div>
                    {o.desc && <div style={{ fontSize:11, color:'rgba(241,241,241,.55)', marginTop:3 }}>{o.desc}</div>}
                  </button>
                ))}
              </div>
            )}

            {/* Section 5: Golden Habit summary card */}
            {section.key === 'forge' && (
              <div className="mm-panel" style={{
                padding:'14px 16px', marginTop:6,
                background:`linear-gradient(135deg, ${sectionColor}22, transparent 70%)`,
                borderColor:`${sectionColor}77`,
              }}>
                <div className="t-display-x" style={{ fontSize:9, letterSpacing:'.18em',
                  color:'var(--mm-yellow)', marginBottom:6 }}>✨ GOLDEN HABIT</div>
                <div className="t-display" style={{ fontSize:16, color:'#fff' }}>{c.output.name}</div>
                <div style={{ fontSize:10, color:'rgba(241,241,241,.5)', marginTop:2,
                  fontFamily:'var(--f-display)', letterSpacing:'.14em' }}>{c.output.type}</div>
                <div style={{ display:'flex', flexDirection:'column', gap:6, marginTop:10, fontSize:12, color:'rgba(241,241,241,.85)' }}>
                  <div><b style={{color:sectionColor, fontSize:9, letterSpacing:'.14em', marginRight:8, fontFamily:'var(--f-display)'}}>WHEN</b>{c.output.when}</div>
                  <div><b style={{color:sectionColor, fontSize:9, letterSpacing:'.14em', marginRight:8, fontFamily:'var(--f-display)'}}>WHERE</b>{c.output.where}</div>
                  <div><b style={{color:sectionColor, fontSize:9, letterSpacing:'.14em', marginRight:8, fontFamily:'var(--f-display)'}}>WHAT</b>{c.output.what}</div>
                  <div><b style={{color:'#FFC629', fontSize:9, letterSpacing:'.14em', marginRight:8, fontFamily:'var(--f-display)'}}>IF-THEN</b>{c.output.ifthen}</div>
                  <div><b style={{color:'#ff3d8b', fontSize:9, letterSpacing:'.14em', marginRight:8, fontFamily:'var(--f-display)'}}>WHY</b>{c.output.why}</div>
                </div>
              </div>
            )}
          </>
        )}

        {phase === 'reward' && (
          <div className="mm-reveal" style={{ alignSelf:'center', textAlign:'center', padding:'20px 14px',
              animation:'mm-revealUp .5s ease-out both' }}>
            <div style={{ fontSize:48 }}>🏆</div>
            <div className="t-display-x" style={{ fontSize:10, color:sectionColor, letterSpacing:'.22em', marginTop:6 }}>
              ACHIEVEMENT UNLOCKED
            </div>
            <div className="t-display" style={{ fontSize:18, color:'#fff', marginTop:4 }}>
              {section.achievement}
            </div>
            <div className="t-display t-num" style={{ fontSize:22, color:'var(--mm-yellow)', marginTop:8,
              textShadow:'0 0 12px rgba(255,198,41,.6)' }}>
              +{section.mp} MP
            </div>
            <div style={{ fontSize:11, color:'rgba(241,241,241,.55)', marginTop:8, lineHeight:1.5 }}>
              Tagged to your Momentum Lists.<br />
              {section.id < 5 ? `Moving to Section ${section.id+1} of 5.` : 'Stage 1 complete — Command Center unlocks next.'}
            </div>
          </div>
        )}
      </div>

      {/* footer */}
      <div style={{ position:'relative', zIndex:5, padding:'10px 14px 24px',
          background:'rgba(6,7,13,.85)', borderTop:'1px solid rgba(241,241,241,.06)' }}>
        {phase === 'intro' && (
          <button onClick={submit}
            disabled={section.key === 'pain' ? (!answer.trim() && !picked) : !picked}
            className="mm-btn-primary"
            style={{ width:'100%', padding:'12px',
              opacity: ((section.key === 'pain' ? (answer.trim() || picked) : picked) ? 1 : .4),
              cursor: ((section.key === 'pain' ? (answer.trim() || picked) : picked) ? 'pointer' : 'default') }}>
            Confirm →
          </button>
        )}
        {phase === 'reward' && (
          <button onClick={onComplete} className="mm-btn-primary mm-btn-primary--pulse"
            style={{ width:'100%', padding:'12px' }}>
            {section.id < 5 ? `Continue · Section ${section.id+1} →` : 'Unlock Command Center 🔓'}
          </button>
        )}
      </div>
    </div>
  );
}

// ─── Stage 2 · MBS: pick strategies for each of the 3 MBMs ─────────────
function MBSStage2Screen({ onComplete, onBack }) {
  // 3 MBM picks + 1 IF-THEN, then unlock Space Cantina
  const [step, setStep] = React.useState(0);
  const [picks, setPicks] = React.useState({});

  const STRATEGIES = {
    obvious: [
      'Place gym shoes by the bedroom door tonight',
      'Add a sticky note to my laptop: "3 numbers first"',
      'Set a 7:00 AM alarm labeled "rocket fuel"',
    ],
    easy: [
      '2-minute version: just one breath + one affirmation',
      'Pre-fill the water bottle the night before',
      'Lay the journal open to today\'s page',
    ],
    reward: [
      'Log it in MM for the MP burst + flame growth',
      'Queue my favorite playlist as a tied-in reward',
      'Streak Saver auto-redeemed at 7-day milestones',
    ],
  };

  // step 0..2 = MBMs, step 3 = IF-THEN, step 4 = complete
  if (step >= MBMS.length + 1) {
    return (
      <div style={{ width:'100%', height:'100%', overflow:'hidden', background:'#06070d',
          paddingTop:56, position:'relative', display:'grid', placeItems:'center' }}>
        <div className="mm-starfield" />
        <div className="mm-stars" />
        <div style={{ position:'relative', zIndex:5, padding:'24px', textAlign:'center', maxWidth:320 }}>
          <div style={{ fontSize:64, animation:'mm-flame 2s ease-in-out infinite' }}>🛸</div>
          <div className="t-display-x" style={{ fontSize:11, letterSpacing:'.22em', color:'var(--mm-yellow)', marginTop:14 }}>
            SPACE CANTINA UNLOCKED
          </div>
          <div className="t-display" style={{ fontSize:22, color:'#fff', marginTop:6 }}>
            Welcome, Captain
          </div>
          <div style={{ fontSize:12, color:'rgba(241,241,241,.7)', lineHeight:1.6, marginTop:10 }}>
            Your Golden Habit is now Momentified — engineered for friction-free execution.
            The Space Cantina opens: Ideas Well, Tribes, Leaderboards, and Weekly Challenges.
          </div>
          <div className="mm-panel" style={{ padding:'10px 12px', marginTop:14, textAlign:'left',
              background:'linear-gradient(135deg, rgba(0,169,143,.18), transparent 70%)',
              borderColor:'rgba(0,169,143,.4)' }}>
            <div className="t-display-x" style={{ fontSize:9, letterSpacing:'.18em',
              color:'var(--mm-teal)', marginBottom:6 }}>✓ MOMENTIFIED HABIT</div>
            <div style={{ fontSize:12, color:'#fff' }}>Morning Mindset Ritual</div>
            <div style={{ fontSize:10, color:'rgba(241,241,241,.6)', marginTop:4 }}>
              + Make It Obvious · + Make It Easy · + Make It Rewarding · IF-THEN locked
            </div>
          </div>
          <button onClick={onComplete} className="mm-btn-primary mm-btn-primary--pulse"
            style={{ width:'100%', padding:'14px', marginTop:18 }}>
            Enter the Cockpit 🚀
          </button>
        </div>
      </div>
    );
  }

  // IF-THEN obstacle plan
  if (step === MBMS.length) {
    const fallback = picks.ifthen;
    const options = [
      'IF I oversleep → THEN do the 30-second version',
      'IF I\'m traveling → THEN swap for 2 deep breaths + 1 affirmation',
      'IF I\'m emotionally drained → THEN just say the mantra, skip stretching',
    ];
    return (
      <div style={{ width:'100%', height:'100%', overflow:'hidden', background:'#06070d',
          paddingTop:56, position:'relative', display:'flex', flexDirection:'column' }}>
        <div className="mm-starfield" />
        <div className="mm-stars" />
        <div style={{ position:'relative', zIndex:5, display:'flex', alignItems:'center', gap:10,
            padding:'10px 14px 12px', borderBottom:'1px solid rgba(255,198,41,.2)' }}>
          <button onClick={() => setStep(step-1)} aria-label="Back" style={{
            background:'rgba(17,28,78,.55)', border:'1px solid rgba(241,241,241,.12)',
            borderRadius:10, width:32, height:32, color:'#fff', display:'grid', placeItems:'center', cursor:'pointer' }}>
            <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M9 2 L 4 7 L 9 12"/></svg>
          </button>
          <div style={{ flex:1, textAlign:'center' }}>
            <div className="t-display-x" style={{ fontSize:9, color:'var(--mm-yellow)', letterSpacing:'.2em' }}>
              STAGE 2 · STEP 4/4
            </div>
            <div className="t-display" style={{ fontSize:13, color:'#fff' }}>⚠️ IF-THEN Obstacle Plan</div>
          </div>
          <span style={{ width:32 }} />
        </div>

        <div style={{ flex:1, overflow:'auto', padding:'14px', position:'relative', zIndex:4 }}>
          <Bubble from="ai" text="Last step. Pick the most likely obstacle and lock in a 'non-zero' fallback. The IF-THEN is your safety net when life happens." />
          <div style={{ display:'flex', flexDirection:'column', gap:6, marginTop:10 }}>
            {options.map((o, i) => {
              const isOn = fallback === o;
              return (
                <button key={i} type="button"
                  onClick={() => setPicks((p) => ({ ...p, ifthen: o }))}
                  style={{
                    textAlign:'left', padding:'12px', borderRadius:8,
                    background: isOn ? 'rgba(255,198,41,.25)' : 'rgba(241,241,241,.04)',
                    border: isOn ? '2px solid var(--mm-yellow)' : '1px solid rgba(241,241,241,.12)',
                    color:'#fff', fontSize:12, lineHeight:1.5, cursor:'pointer',
                    boxShadow: isOn ? '0 0 14px rgba(255,198,41,.45)' : 'none',
                    display:'flex', alignItems:'center', gap:10,
                    transition:'all .15s',
                  }}>
                  <span style={{
                    width:16, height:16, borderRadius:'50%', flexShrink:0,
                    border:`1.5px solid ${isOn ? 'var(--mm-yellow)' : 'rgba(241,241,241,.4)'}`,
                    background: isOn ? 'var(--mm-yellow)' : 'transparent',
                    display:'grid', placeItems:'center',
                  }}>
                    {isOn && <svg width="9" height="9" viewBox="0 0 9 9" fill="none" stroke="#000" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 4.5 L 3.5 7 L 8 2"/></svg>}
                  </span>
                  <span style={{ flex:1 }}>{o}</span>
                </button>
              );
            })}
          </div>
        </div>

        <div style={{ position:'relative', zIndex:5, padding:'10px 14px 24px',
            background:'rgba(6,7,13,.85)', borderTop:'1px solid rgba(241,241,241,.06)' }}>
          <button onClick={() => setStep(step+1)} disabled={!fallback}
            className="mm-btn-primary"
            style={{ width:'100%', padding:'12px',
              opacity: fallback ? 1 : .4, cursor: fallback ? 'pointer' : 'default' }}>
            Lock it in 🔒
          </button>
        </div>
      </div>
    );
  }

  // MBM step
  const mbm = MBMS[step];
  const picked = picks[mbm.id];

  return (
    <div style={{ width:'100%', height:'100%', overflow:'hidden', background:'#06070d',
        paddingTop:56, position:'relative', display:'flex', flexDirection:'column' }}>
      <div className="mm-starfield" />
      <div className="mm-stars" />

      <div style={{ position:'relative', zIndex:5, display:'flex', alignItems:'center', gap:10,
          padding:'10px 14px 12px', borderBottom:`1px solid ${mbm.color}33`,
          background:`linear-gradient(180deg, ${mbm.color}15, transparent)` }}>
        <button onClick={step === 0 ? onBack : () => setStep(step-1)} aria-label="Back" style={{
          background:'rgba(17,28,78,.55)', border:'1px solid rgba(241,241,241,.12)',
          borderRadius:10, width:32, height:32, color:'#fff', display:'grid', placeItems:'center', cursor:'pointer' }}>
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M9 2 L 4 7 L 9 12"/></svg>
        </button>
        <div style={{ flex:1, textAlign:'center' }}>
          <div className="t-display-x" style={{ fontSize:9, color:mbm.color, letterSpacing:'.2em' }}>
            STAGE 2 · STEP {step+1}/4
          </div>
          <div className="t-display" style={{ fontSize:13, color:'#fff' }}>{mbm.icon} {mbm.name}</div>
        </div>
        <span style={{ width:32 }} />
      </div>

      {/* MBM track indicator */}
      <div style={{ display:'flex', gap:4, padding:'8px 14px', position:'relative', zIndex:5 }}>
        {MBMS.map((m, i) => (
          <div key={m.id} style={{
            flex:1, height:3, borderRadius:2,
            background: i < step ? m.color
                      : i === step ? `linear-gradient(90deg, ${m.color}, #fff)`
                      : 'rgba(241,241,241,.1)',
            boxShadow: i === step ? `0 0 6px ${m.color}` : 'none',
          }} />
        ))}
        <div style={{ flex:1, height:3, borderRadius:2,
          background: step > MBMS.length-1 ? 'var(--mm-yellow)' : 'rgba(241,241,241,.1)' }} />
      </div>

      <div style={{ flex:1, overflow:'auto', padding:'14px', position:'relative', zIndex:4 }}>
        <Bubble from="ai" text={mbm.desc} />
        <Bubble from="ai" text={`Based on your Momentum Lists, here are 3 ${mbm.name} strategies. Pick the one that fits your life.`} />

        <div style={{ display:'flex', flexDirection:'column', gap:6, marginTop:10 }}>
          {STRATEGIES[mbm.id].map((s, i) => {
            const isOn = picked === s;
            return (
              <button key={i} type="button"
                onClick={() => setPicks((p) => ({ ...p, [mbm.id]: s }))}
                style={{
                  textAlign:'left', padding:'12px', borderRadius:8,
                  background: isOn ? `${mbm.color}33` : 'rgba(241,241,241,.04)',
                  border: isOn ? `2px solid ${mbm.color}` : '1px solid rgba(241,241,241,.12)',
                  color:'#fff', fontSize:12, lineHeight:1.5, cursor:'pointer',
                  display:'flex', alignItems:'center', gap:10,
                  boxShadow: isOn ? `0 0 14px ${mbm.color}55` : 'none',
                  transition:'all .15s',
                }}>
                <span style={{
                  width:16, height:16, borderRadius:'50%', flexShrink:0,
                  border:`1.5px solid ${isOn ? mbm.color : 'rgba(241,241,241,.4)'}`,
                  background: isOn ? mbm.color : 'transparent',
                  display:'grid', placeItems:'center',
                }}>
                  {isOn && <svg width="9" height="9" viewBox="0 0 9 9" fill="none" stroke="#000" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M1 4.5 L 3.5 7 L 8 2"/></svg>}
                </span>
                <span style={{ flex:1 }}>{s}</span>
              </button>
            );
          })}
        </div>
      </div>

      <div style={{ position:'relative', zIndex:5, padding:'10px 14px 24px',
          background:'rgba(6,7,13,.85)', borderTop:'1px solid rgba(241,241,241,.06)' }}>
        <button onClick={() => setStep(step+1)} disabled={!picked}
          className="mm-btn-primary"
          style={{ width:'100%', padding:'12px',
            opacity: picked ? 1 : .4, cursor: picked ? 'pointer' : 'default' }}>
          {step === MBMS.length-1 ? 'On to IF-THEN →' : `Next MBM (${MBMS[step+1].name}) →`}
        </button>
      </div>
    </div>
  );
}

// ─── Command Center Unlock (between Stage 1 and Stage 2) ────────────────
function CommandCenterUnlockScreen({ onContinue }) {
  const lists = [
    { name: 'Back to the Future',  emoji: '🚀🔮', desc: 'Aspirational identity across all 5 Cores' },
    { name: 'Routines',            emoji: '⏰🔄', desc: 'Daily schedule incl. your new Golden Habit' },
    { name: 'Obstacles',           emoji: '🛑',   desc: 'Internal & external blockers + IF-THEN fallbacks' },
    { name: 'Passions',            emoji: '🎮🕺', desc: 'What energizes and motivates you' },
    { name: 'Strengths',           emoji: '🛠️💪', desc: 'Natural talents & adaptive traits' },
    { name: 'Top Environments',    emoji: '📍',   desc: 'Spaces that shape your focus' },
    { name: 'Lifestyle Factors',   emoji: '🏠⏰', desc: 'Real-world constraints' },
  ];

  return (
    <div style={{ width:'100%', height:'100%', overflow:'auto', background:'#06070d',
        paddingTop:56, position:'relative' }}>
      <div className="mm-starfield" />
      <div className="mm-stars" />

      <div style={{ position:'relative', zIndex:5, padding:'20px 18px 30px' }}>
        <div style={{ textAlign:'center' }}>
          <div style={{ fontSize:56 }}>🔓</div>
          <div className="t-display-x" style={{ fontSize:11, color:'var(--mm-yellow)', letterSpacing:'.22em', marginTop:8 }}>
            COMMAND CENTER UNLOCKED
          </div>
          <div className="t-display" style={{ fontSize:22, color:'#fff', marginTop:4 }}>
            Your Personal Database
          </div>
          <div style={{ fontSize:12, color:'rgba(241,241,241,.7)', lineHeight:1.5, marginTop:10 }}>
            Everything you shared has been routed into 7 Momentum Lists. The AI cross-references
            these in every future interaction.
          </div>
        </div>

        <div style={{ display:'flex', flexDirection:'column', gap:6, marginTop:18 }}>
          {lists.map((l, i) => (
            <div key={l.name} className="mm-panel mm-reveal" style={{
              padding:'10px 12px', display:'flex', alignItems:'center', gap:10,
              animation:`mm-revealUp .5s ease-out ${i*120}ms both`,
            }}>
              <span style={{ fontSize:20 }}>{l.emoji}</span>
              <div style={{ flex:1 }}>
                <div style={{ fontSize:12, fontWeight:600, color:'#fff' }}>{l.name}</div>
                <div style={{ fontSize:10, color:'rgba(241,241,241,.55)', marginTop:2 }}>{l.desc}</div>
              </div>
              <span style={{ color:'var(--mm-teal)', fontSize:14 }}>✓</span>
            </div>
          ))}
        </div>

        <div style={{ marginTop:20, padding:'14px', borderRadius:10,
            background:'linear-gradient(135deg, rgba(42,125,225,.18), rgba(155,92,255,.12))',
            border:'1px solid rgba(77,155,255,.4)', textAlign:'center' }}>
          <div className="t-display" style={{ fontSize:14, color:'#fff' }}>Level 1 Complete 🚀</div>
          <div style={{ fontSize:11, color:'rgba(241,241,241,.7)', marginTop:4 }}>
            Lift-off ready. Continue to Stage 2 to engineer your habit for friction-free execution.
          </div>
        </div>

        <button onClick={onContinue} className="mm-btn-primary mm-btn-primary--pulse"
          style={{ width:'100%', padding:'14px', marginTop:18 }}>
          Continue to Stage 2 →
        </button>
      </div>
    </div>
  );
}

// ─── Container that owns the Phase 1 flow state ─────────────────────────
function Phase1Flow({ phase1State, setPhase1State, onComplete, onBack, onExitToCockpit }) {
  // sub-screens: hub → hhs-section-N → command-center-unlock → mbs → done
  const [view, setView] = React.useState(phase1State?.lastView || 'hub');
  const [section, setSection] = React.useState(phase1State?.stage1Progress
    ? Math.min(phase1State.stage1Progress + 1, 5) : 1);

  const completed = Array.from({ length: phase1State?.stage1Progress || 0 }, (_, i) => i + 1);

  const startStage1 = () => {
    const next = (phase1State?.stage1Progress || 0) + 1;
    setSection(Math.min(next, 5));
    setView('section');
  };
  const startStage2 = () => setView('mbs');

  const completeSection = () => {
    const completedCount = section; // we just completed `section`
    setPhase1State({ ...phase1State, stage1Progress: completedCount });
    if (section === 5) {
      setPhase1State({ ...phase1State, stage1Progress: 5, stage1Completed: true });
      setView('command-center');
    } else {
      setSection(section + 1);
      // stay on `section`
    }
  };

  const completeMBS = () => {
    setPhase1State({ ...phase1State, stage1Completed: true, stage1Progress: 5, stage2Completed: true });
    onExitToCockpit();
  };

  if (view === 'hub') {
    return <Phase1Hub
      phase1State={phase1State}
      onBack={onBack}
      onStartStage1={startStage1}
      onStartStage2={startStage2} />;
  }
  if (view === 'section') {
    const s = HHS_SECTIONS[section - 1];
    return <HHSSectionScreen
      section={s}
      sectionIdx={section}
      completed={completed}
      onBack={() => setView('hub')}
      onComplete={completeSection} />;
  }
  if (view === 'command-center') {
    return <CommandCenterUnlockScreen
      onContinue={() => setView('mbs')} />;
  }
  if (view === 'mbs') {
    return <MBSStage2Screen
      onBack={() => setView('hub')}
      onComplete={completeMBS} />;
  }
  return null;
}

Object.assign(window, {
  Phase1Flow, Phase1Hub, HHSPyramid, HHS_SECTIONS, MBMS,
});
