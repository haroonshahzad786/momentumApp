// gamification.jsx — G1 Level tracker · G2 Quests & Challenges
//   • LevelTracker  — Cadet → Navigator → Commander, 3 advancement criteria
//   • QuestBoard    — Alien Space Quest + optional Journey Challenge

const G_BLUE = '#2a7de1', G_YELLOW = '#FFC629', G_TEAL = '#00a98f';

// ═══════════════════════════════════════════════════════════════════
// G1 — Level Advancement Tracker
// ═══════════════════════════════════════════════════════════════════
const LEVELS = [
  { id:'cadet',     rank:'Cadet',     mult:'1×',    perks:['Common upgrades','Phase 1 & 2 access'] },
  { id:'navigator', rank:'Navigator', mult:'1.25×', perks:['Rare upgrade tiers','Daily challenges','Space Tribes'] },
  { id:'commander', rank:'Commander', mult:'1.5×',  perks:['Epic upgrade tier','Weekly Arena','Pro analytics'] },
];

function LevelTracker({ tweaks = {}, ...props }) {
  const levelId = tweaks.level || 'navigator';
  const idx = LEVELS.findIndex(l => l.id === levelId);
  const cur = LEVELS[idx];
  const next = LEVELS[idx + 1];

  // 3 simultaneous criteria toward next level (placeholder thresholds)
  const criteria = [
    { label:'Formed Habits',  have:5, need:8,  hex:G_TEAL,   nudge:'3 formed habits from ' + (next?.rank || 'max') },
    { label:'Planet Reached', have:2, need:3,  hex:G_BLUE,   nudge:'Reach Jupiter to advance', unit:'planet',
      labels:['Earth','Moon','Mars','Jupiter','Saturn'] },
    { label:'Streak @ 4.0+',  have:47, need:60, hex:G_YELLOW, nudge:'13 more strong days' },
  ];

  return (
    <ScreenShell title="Rank Progress" subtitle="LEVEL ADVANCEMENT" accent="var(--mm-blue)" {...props}>
      {/* Current level */}
      <div className="mm-panel mm-panel--accent" style={{ padding:'16px 14px', marginBottom:14 }}>
        <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between' }}>
          <div>
            <div className="t-display-x" style={{ fontSize:9, letterSpacing:'.18em', color:'rgba(241,241,241,.55)' }}>CURRENT RANK</div>
            <div className="t-display" style={{ fontSize:24, color:'#fff', marginTop:2 }}>{cur.rank}</div>
          </div>
          <div style={{ textAlign:'right' }}>
            <div className="t-display t-num" style={{ fontSize:22, color:G_YELLOW }}>{cur.mult}</div>
            <div style={{ fontSize:9, color:'rgba(241,241,241,.5)', fontFamily:'var(--f-display)', letterSpacing:'.1em' }}>CREDITS</div>
          </div>
        </div>
        <div style={{ display:'flex', flexWrap:'wrap', gap:6, marginTop:12 }}>
          {cur.perks.map(p => (
            <span key={p} className="mm-chip" style={{ fontSize:9, color:'var(--mm-blue)' }}>{p}</span>
          ))}
        </div>
      </div>

      {/* Permanence reassurance */}
      <div style={{ padding:'8px 12px', borderRadius:8, marginBottom:14,
          background:'rgba(0,169,143,.1)', border:'1px solid rgba(0,169,143,.3)',
          fontSize:11, color:'rgba(241,241,241,.85)', display:'flex', gap:8 }}>
        <span style={{ color:G_TEAL }}>🛡️</span>
        <span>Your rank is <b style={{color:'#fff'}}>permanent</b> — never lost to a missed day or low score.</span>
      </div>

      {next ? (
        <>
          <div className="t-display-x" style={{ fontSize:10, letterSpacing:'.18em',
            color:'rgba(241,241,241,.55)', margin:'0 2px 10px' }}>
            ADVANCE TO {next.rank.toUpperCase()} · ALL 3 REQUIRED
          </div>
          <div style={{ display:'flex', flexDirection:'column', gap:10 }}>
            {criteria.map((c) => {
              const pct = Math.min(100, (c.have / c.need) * 100);
              const done = c.have >= c.need;
              return (
                <div key={c.label} className="mm-panel" style={{ padding:'12px 14px' }}>
                  <div style={{ display:'flex', justifyContent:'space-between', alignItems:'baseline', marginBottom:8 }}>
                    <span className="t-display-x" style={{ fontSize:10, letterSpacing:'.12em', color:c.hex }}>{c.label}</span>
                    <span className="t-num" style={{ fontSize:11, color: done ? G_TEAL : 'rgba(241,241,241,.7)' }}>
                      {c.unit === 'planet'
                        ? `${c.labels[c.have]} → ${c.labels[c.need]}`
                        : `${c.have} / ${c.need}`}
                      {done && ' ✓'}
                    </span>
                  </div>
                  <div style={{ height:6, borderRadius:3, background:'rgba(241,241,241,.08)', overflow:'hidden' }}>
                    <div style={{ width:`${pct}%`, height:'100%',
                      background:`linear-gradient(90deg, ${c.hex}, ${c.hex}aa)`,
                      boxShadow:`0 0 8px ${c.hex}88`, transition:'width .6s' }} />
                  </div>
                  <div style={{ fontSize:11, color:'rgba(241,241,241,.6)', marginTop:7 }}>
                    {done ? '✓ Criterion met' : `You're ${c.nudge}.`}
                  </div>
                </div>
              );
            })}
          </div>
        </>
      ) : (
        <div style={{ textAlign:'center', padding:'30px 20px' }}>
          <div style={{ fontSize:44 }}>👑</div>
          <div className="t-display" style={{ fontSize:18, color:'#fff', marginTop:10 }}>Max Rank Reached</div>
          <div style={{ fontSize:12, color:'rgba(241,241,241,.6)', marginTop:6 }}>
            Commander — the cosmos is yours.
          </div>
        </div>
      )}
    </ScreenShell>
  );
}

// ═══════════════════════════════════════════════════════════════════
// G2 — Space Quests (alien, planet-tied) + Journey Challenges (optional)
// ═══════════════════════════════════════════════════════════════════
function QuestBoard({ tweaks = {}, ...props }) {
  const [questDone, setQuestDone] = React.useState(false);
  const [challengeState, setChallengeState] = React.useState(null); // 'accepted' | 'skipped'
  const planet = (tweaks.planet || 'mars');
  const planetName = planet.charAt(0).toUpperCase() + planet.slice(1);

  return (
    <ScreenShell title="Missions" subtitle="QUESTS & CHALLENGES" accent="var(--mm-yellow)" {...props}>
      {/* Space Quest — required for full arrival rewards */}
      <div className="mm-panel" style={{ padding:'16px 14px', marginBottom:14,
          borderLeft:`3px solid ${G_YELLOW}`,
          background:'linear-gradient(135deg, rgba(255,198,41,.1), transparent 70%)' }}>
        <div style={{ display:'flex', alignItems:'center', gap:12, marginBottom:10 }}>
          <div style={{ width:48, height:48, borderRadius:'50%', flexShrink:0,
            background:'radial-gradient(circle at 35% 30%, #7ee0db, #16b89c 70%)',
            display:'grid', placeItems:'center', fontSize:24,
            boxShadow:'0 0 16px rgba(0,169,143,.5)' }}>👽</div>
          <div>
            <div className="t-display-x" style={{ fontSize:9, letterSpacing:'.16em', color:G_TEAL }}>
              ALIEN GUIDE · {planetName.toUpperCase()}
            </div>
            <div className="t-display" style={{ fontSize:15, color:'#fff', marginTop:2 }}>Space Quest</div>
          </div>
        </div>
        <div style={{ fontSize:13, color:'rgba(241,241,241,.9)', lineHeight:1.5, marginBottom:6, fontStyle:'italic' }}>
          "Add 3 items to your Obstacles List for your Career Core — name what's slowing you, and we'll clear the path."
        </div>
        <div style={{ display:'flex', gap:8, margin:'10px 0 12px' }}>
          <span className="mm-chip" style={{ color:G_YELLOW }}>💎 +200</span>
          <span className="mm-chip" style={{ color:G_BLUE }}>+50 MP</span>
          <span className="mm-chip" style={{ color:'#9b5cff' }}>🎁 Box chance</span>
        </div>
        <div style={{ fontSize:10, color:'rgba(241,241,241,.5)', marginBottom:10 }}>
          ⚠ Required to receive full {planetName} arrival rewards.
        </div>
        <button onClick={() => setQuestDone(true)} disabled={questDone}
          className={questDone ? 'mm-btn-ghost' : 'mm-btn-primary'}
          style={{ width:'100%', padding:'12px', opacity: questDone ? .7 : 1 }}>
          {questDone ? '✓ Quest Complete' : 'Accept Quest →'}
        </button>
      </div>

      {/* Journey Challenge — optional, no penalty */}
      <div className="mm-panel" style={{ padding:'16px 14px',
          borderLeft:`3px solid ${G_BLUE}` }}>
        <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', marginBottom:8 }}>
          <div className="t-display-x" style={{ fontSize:10, letterSpacing:'.16em', color:G_BLUE }}>
            JOURNEY CHALLENGE
          </div>
          <span className="mm-chip" style={{ fontSize:8, letterSpacing:'.1em', color:'rgba(241,241,241,.6)' }}>OPTIONAL · TODAY</span>
        </div>
        <div style={{ fontSize:13, color:'#fff', lineHeight:1.45, marginBottom:10 }}>
          Don't let any Core score below 3 today.
        </div>
        <div style={{ display:'flex', gap:8, marginBottom:12 }}>
          <span className="mm-chip" style={{ color:G_YELLOW }}>💎 +75</span>
          <span className="mm-chip" style={{ color:G_BLUE }}>+30 MP</span>
          <span className="mm-chip" style={{ color:'#9b5cff' }}>🎁 Variable</span>
        </div>
        {challengeState === 'accepted' ? (
          <div style={{ textAlign:'center', padding:'8px', fontSize:12, color:G_TEAL,
            fontFamily:'var(--f-display)', letterSpacing:'.1em' }}>✓ ACCEPTED · GOOD LUCK, CAPTAIN</div>
        ) : challengeState === 'skipped' ? (
          <div style={{ textAlign:'center', padding:'8px', fontSize:11, color:'rgba(241,241,241,.5)' }}>
            Skipped — no effect on streak or position. 👍
          </div>
        ) : (
          <div style={{ display:'flex', gap:8 }}>
            <button onClick={() => setChallengeState('accepted')} className="mm-btn-primary" style={{ flex:1, padding:'11px' }}>Accept</button>
            <button onClick={() => setChallengeState('skipped')} className="mm-btn-ghost" style={{ flex:1, padding:'11px' }}>Skip</button>
          </div>
        )}
        <div style={{ fontSize:10, color:'rgba(241,241,241,.45)', textAlign:'center', marginTop:10 }}>
          Skipping never affects your streak or rocket position.
        </div>
      </div>
    </ScreenShell>
  );
}

Object.assign(window, { LevelTracker, QuestBoard, LEVELS });
