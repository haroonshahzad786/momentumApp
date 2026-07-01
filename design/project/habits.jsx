// habits.jsx — Golden Habits list + detail view
// Data shape mirrors saveGoldenHabit in cloud functions:
//   habitId, habitName, coreId, coreLabel,
//   painPoint, backToFutureIdentity, coreDimension,
//   habitType ('routine' | 'non_routine'), where, when, what,
//   cueType, trigger, anchorReminder,
//   obstacleIf, obstacleThen,
//   whyWant, whyCan, whyEffective,
//   startingVersion, displayText
//
// In production wire fetchAllGoldenHabits → REPLACE the MOCK array.
// stage / streak / week-grid are derived locally (not stored on the habit).

// Color tokens per core, matching CORE_DEFS hex values.
const CORE_HEX = {
  mindset_core:           '#2a7de1',
  career_finance_core:    '#FFC629',
  relationships_core:     '#ff3d8b',
  physical_health_core:   '#00a98f',
  emotional_mental_core:  '#9b5cff',
};

// Habit-progression stages from the master brief
//   🔴 bad → 🟠 forming → 🔵 mbms → 🟢 formed → 🏆 trophy
const STAGE_DEFS = {
  bad:     { color: '#ea0029', label: 'Bad'           },
  forming: { color: '#FFC629', label: 'Forming'        },
  mbms:    { color: '#2a7de1', label: 'MBMs attached'  },
  formed:  { color: '#00a98f', label: 'Formed'         },
  trophy:  { color: '#FFC629', label: 'Trophy'         },
};

// ─── MOCK data shaped exactly like Firestore Golden Habit docs ───
// Replace with: fetch('https://…/fetchAllGoldenHabits?secret=…&userId=…')
const MOCK_GOLDEN_HABITS = [
  {
    habitId: 'gh_deep_presence_practice',
    habitName: 'Deep Presence Practice',
    coreId: 'mindset_core',
    coreLabel: 'Mindset Core',
    painPoint: 'I get pulled into anxious looping every morning.',
    backToFutureIdentity: 'I am the calm operator who runs on clarity.',
    coreDimension: 'Focus & Attention',
    habitType: 'routine',
    where: 'On the cushion by my bedroom window',
    when: 'Right after my morning coffee, before phone',
    what: '10 minutes of guided meditation',
    cueType: 'situational',
    trigger: 'Coffee cup placed back on the counter',
    anchorReminder: 'Cushion left out in plain view the night before',
    obstacleIf: 'I feel rushed and want to skip',
    obstacleThen: 'I do the 2-minute version standing — non-zero',
    whyWant: 'Because my best work comes from a steady mind.',
    whyCan: "I've done it 4 days in the last week — proof I can.",
    whyEffective: 'It compounds: every clear morning seeds a clear day.',
    startingVersion: '2 minutes seated · eyes closed · one breath count',
    // local-only fields (UI state — would live in a separate collection in production)
    stage: 'mbms',
    streak: 14,
    week: [1,1,0,1,1,1,1],
    daysFormed: 18, // 14d × 80% = formed threshold
  },
  {
    habitId: 'gh_money_dashboard_review',
    habitName: 'Money Dashboard Review',
    coreId: 'career_finance_core',
    coreLabel: 'Career & Finance Core',
    painPoint: 'I avoid looking at my finances until something breaks.',
    backToFutureIdentity: 'I am the operator who knows my numbers.',
    coreDimension: 'Financial Awareness',
    habitType: 'routine',
    where: 'Kitchen table with laptop open',
    when: 'Sunday at 7pm, before dinner',
    what: 'Open dashboard, check 3 numbers, log to journal',
    cueType: 'situational',
    trigger: 'Sunday calendar alert at 7:00pm',
    anchorReminder: 'Sticky note on laptop lid: "3 numbers"',
    obstacleIf: 'I open dashboard and feel overwhelmed',
    obstacleThen: 'I only check the top number and close it',
    whyWant: 'Because awareness compounds into control.',
    whyCan: "I've done a 3-number scan twice this month.",
    whyEffective: 'Weekly cadence creates rhythm without burnout.',
    startingVersion: '1 number · 60 seconds',
    stage: 'forming',
    streak: 4,
    week: [0,1,1,1,0,1,1],
    daysFormed: 6,
  },
  {
    habitId: 'gh_strength_block',
    habitName: 'Strength Block',
    coreId: 'physical_health_core',
    coreLabel: 'Physical Health Core',
    painPoint: 'My body feels heavy and I avoid the gym after work.',
    backToFutureIdentity: 'I am an energized, active person who trains 5 days a week.',
    coreDimension: 'Strength & Energy',
    habitType: 'routine',
    where: 'Home garage gym',
    when: '6:30pm, immediately after work',
    what: '35 min strength session (push/pull/legs rotation)',
    cueType: 'situational',
    trigger: 'Setting laptop bag down by the door',
    anchorReminder: 'Gym shoes by the door · playlist queued',
    obstacleIf: 'I had a brutal day and want to bail',
    obstacleThen: 'I do the 10-min "showed up" version — non-zero',
    whyWant: 'Because strength bleeds into every other Core.',
    whyCan: 'I trained 5/7 days last week — already there.',
    whyEffective: 'A consistent time-of-day eliminates decision drag.',
    startingVersion: '5 minutes · one compound lift',
    stage: 'formed',
    streak: 32,
    week: [1,1,1,1,1,0,1],
    daysFormed: 42,
  },
];

// ─── Compact habit card (in list) ───
function HabitCard({ h, onOpen }) {
  const hex = CORE_HEX[h.coreId] || '#fff';
  const stage = STAGE_DEFS[h.stage] || STAGE_DEFS.forming;
  const dayLabels = ['M','T','W','T','F','S','S'];
  return (
    <button onClick={onOpen} className="mm-panel" style={{
      padding:'12px 14px',
      borderLeft:`3px solid ${hex}`,
      width:'100%', textAlign:'left', cursor:'pointer',
      display:'flex', flexDirection:'column', gap:10,
    }}>
      <div style={{ display:'flex', justifyContent:'space-between', alignItems:'flex-start', gap:8 }}>
        <div style={{ minWidth:0, flex:1 }}>
          <div style={{ display:'flex', alignItems:'center', gap:6 }}>
            <div className="mm-dot" style={{ background:stage.color, boxShadow:`0 0 6px ${stage.color}` }} />
            <span className="t-display-x" style={{ fontSize:9, letterSpacing:'.14em', color:stage.color }}>
              {stage.label.toUpperCase()}
            </span>
            <span className="t-display-x" style={{ fontSize:9, letterSpacing:'.12em', color:'rgba(241,241,241,.4)' }}>
              · {h.habitType === 'routine' ? 'ROUTINE' : 'NON-ROUTINE'}
            </span>
          </div>
          <div style={{ fontSize:14, fontWeight:600, color:'#fff', marginTop:4 }}>{h.habitName}</div>
          <div style={{ fontSize:10, color:hex, fontFamily:'var(--f-display)', letterSpacing:'.1em', marginTop:2 }}>
            {h.coreLabel.toUpperCase()}
          </div>
        </div>
        <span className="t-display t-num" style={{ fontSize:14, color:hex }}>{h.streak}🔥</span>
      </div>

      {/* The action line — "what" gives a sense of the habit at a glance */}
      <div style={{ fontSize:12, color:'rgba(241,241,241,.7)', lineHeight:1.45 }}>
        {h.what}
      </div>

      {/* 7-day strip */}
      <div style={{ display:'grid', gridTemplateColumns:'repeat(7, 1fr)', gap:4 }}>
        {h.week.map((v, i) => (
          <div key={i} style={{
            aspectRatio:'1/1', borderRadius:5,
            background: v ? hex : 'rgba(241,241,241,.05)',
            border: v ? `1px solid ${hex}` : '1px solid rgba(241,241,241,.08)',
            boxShadow: v ? `0 0 6px ${hex}55` : 'none',
            display:'grid', placeItems:'center', fontSize:7,
            fontFamily:'var(--f-display)', color: v ? '#000' : 'rgba(241,241,241,.35)',
          }}>{dayLabels[i]}</div>
        ))}
      </div>
    </button>
  );
}

// ─── Reusable section in detail view ───
function DetailSection({ label, color, children }) {
  return (
    <div className="mm-panel" style={{ padding:'12px 14px', marginBottom:8,
      borderLeft: color ? `2px solid ${color}` : undefined }}>
      <div className="t-display-x" style={{ fontSize:9, letterSpacing:'.18em',
        color: color || 'rgba(241,241,241,.5)', marginBottom:6 }}>
        {label}
      </div>
      {children}
    </div>
  );
}

function KV({ k, v }) {
  if (!v) return null;
  return (
    <div style={{ display:'flex', gap:10, marginBottom:6, fontSize:12 }}>
      <span style={{ flex:'0 0 64px', color:'rgba(241,241,241,.5)',
        fontFamily:'var(--f-display)', letterSpacing:'.08em', fontSize:9 }}>{k}</span>
      <span style={{ flex:1, color:'#fff', lineHeight:1.45 }}>{v}</span>
    </div>
  );
}

// ─── Edit modal: lets the user tweak the core Golden Habit fields ───
function HabitEditModal({ h, onSave, onClose }) {
  const [draft, setDraft] = React.useState({
    habitName: h.habitName,
    what: h.what,
    where: h.where,
    when: h.when,
    trigger: h.trigger,
    anchorReminder: h.anchorReminder,
    obstacleIf: h.obstacleIf,
    obstacleThen: h.obstacleThen,
    startingVersion: h.startingVersion,
  });
  const set = (k) => (e) => setDraft({ ...draft, [k]: e.target.value });
  const hex = CORE_HEX[h.coreId] || '#fff';
  const F = ({ label, k, multi }) => (
    <label style={{ display:'block', marginBottom:10 }}>
      <div className="t-display-x" style={{ fontSize:9, letterSpacing:'.18em',
        color:'rgba(241,241,241,.55)', marginBottom:4 }}>{label}</div>
      {multi
        ? <textarea value={draft[k]} onChange={set(k)} rows={2} style={{
            width:'100%', padding:'10px 12px', borderRadius:8, resize:'none',
            background:'rgba(17,28,78,.55)', border:`1px solid ${hex}55`,
            color:'#fff', fontSize:13, outline:'none', fontFamily:'var(--f-body)' }} />
        : <input type="text" value={draft[k]} onChange={set(k)} style={{
            width:'100%', padding:'10px 12px', borderRadius:8,
            background:'rgba(17,28,78,.55)', border:`1px solid ${hex}55`,
            color:'#fff', fontSize:13, outline:'none' }} />
      }
    </label>
  );
  return (
    <div style={{ position:'absolute', inset:0, zIndex:50,
        background:'rgba(6,7,13,.85)', backdropFilter:'blur(8px)',
        display:'flex', flexDirection:'column', padding:56+12 + 'px 14px 14px' }}>
      <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:12 }}>
        <button onClick={onClose} aria-label="Close" style={{
          background:'rgba(17,28,78,.55)', border:'1px solid rgba(241,241,241,.12)',
          borderRadius:10, width:36, height:36, color:'#fff', display:'grid', placeItems:'center', cursor:'pointer' }}>
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M3 3 L 11 11 M 11 3 L 3 11"/></svg>
        </button>
        <div className="t-display-x" style={{ fontSize:12, letterSpacing:'.18em', color:hex }}>EDIT HABIT</div>
      </div>
      <div style={{ flex:1, overflow:'auto' }}>
        <F label="HABIT NAME"     k="habitName" />
        <F label="WHAT"           k="what"          multi />
        <F label="WHERE"          k="where" />
        <F label="WHEN"           k="when" />
        <F label="TRIGGER"        k="trigger" />
        <F label="ANCHOR REMINDER" k="anchorReminder" />
        <F label="IF (obstacle)"  k="obstacleIf"    multi />
        <F label="THEN (fallback)" k="obstacleThen" multi />
        <F label="STARTING VERSION (MVA)" k="startingVersion" multi />
      </div>
      <div style={{ display:'flex', gap:8, paddingTop:10 }}>
        <button onClick={onClose} className="mm-btn-ghost" style={{ flex:1, padding:'12px' }}>Cancel</button>
        <button onClick={() => onSave(draft)} className="mm-btn-primary" style={{ flex:1, padding:'12px' }}>Save</button>
      </div>
    </div>
  );
}

// ─── Flag modal: marks a habit for refinement, with reason ───
function HabitFlagModal({ h, onConfirm, onClose }) {
  const [reason, setReason] = React.useState('friction');
  const [note, setNote] = React.useState('');
  const REASONS = [
    { id:'friction', label:'Too much friction' },
    { id:'unclear',  label:'Cue is unclear' },
    { id:'time',     label:'Wrong time of day' },
    { id:'identity', label:"Doesn't fit who I am" },
    { id:'other',    label:'Something else' },
  ];
  const hex = '#FFC629';
  return (
    <div style={{ position:'absolute', inset:0, zIndex:50,
        background:'rgba(6,7,13,.85)', backdropFilter:'blur(8px)',
        display:'flex', flexDirection:'column', padding:56+12 + 'px 14px 14px' }}>
      <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:12 }}>
        <button onClick={onClose} aria-label="Close" style={{
          background:'rgba(17,28,78,.55)', border:'1px solid rgba(241,241,241,.12)',
          borderRadius:10, width:36, height:36, color:'#fff', display:'grid', placeItems:'center', cursor:'pointer' }}>
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M3 3 L 11 11 M 11 3 L 3 11"/></svg>
        </button>
        <div className="t-display-x" style={{ fontSize:12, letterSpacing:'.18em', color:hex }}>FLAG FOR REFINEMENT</div>
      </div>
      <div style={{ fontSize:13, color:'rgba(241,241,241,.85)', marginBottom:14, lineHeight:1.5 }}>
        That's not failure — that's your habit telling you something needs adjusting. Pick what's off, and Nova will pattern-match it.
      </div>
      <div style={{ flex:1, overflow:'auto' }}>
        <div className="t-display-x" style={{ fontSize:9, letterSpacing:'.18em',
          color:'rgba(241,241,241,.55)', marginBottom:6 }}>WHAT'S OFF?</div>
        <div style={{ display:'flex', flexDirection:'column', gap:6, marginBottom:14 }}>
          {REASONS.map((r) => (
            <button key={r.id} onClick={() => setReason(r.id)} style={{
              padding:'10px 12px', borderRadius:8, textAlign:'left',
              background: reason === r.id ? `${hex}22` : 'rgba(241,241,241,.04)',
              border: reason === r.id ? `1px solid ${hex}` : '1px solid rgba(241,241,241,.1)',
              color:'#fff', fontSize:13, cursor:'pointer',
              display:'flex', alignItems:'center', gap:10,
            }}>
              <span style={{ width:14, height:14, borderRadius:'50%',
                border:`1.5px solid ${reason === r.id ? hex : 'rgba(241,241,241,.3)'}`,
                background: reason === r.id ? hex : 'transparent', flexShrink:0,
                display:'grid', placeItems:'center' }}>
                {reason === r.id && <span style={{ width:6, height:6, borderRadius:'50%', background:'#000' }} />}
              </span>
              {r.label}
            </button>
          ))}
        </div>
        <div className="t-display-x" style={{ fontSize:9, letterSpacing:'.18em',
          color:'rgba(241,241,241,.55)', marginBottom:6 }}>OPTIONAL NOTE</div>
        <textarea value={note} onChange={(e) => setNote(e.target.value)} rows={3}
          placeholder="What did you notice? (data, not shame)"
          style={{ width:'100%', padding:'10px 12px', borderRadius:8, resize:'none',
            background:'rgba(17,28,78,.55)', border:'1px solid rgba(255,198,41,.4)',
            color:'#fff', fontSize:13, outline:'none', fontFamily:'var(--f-body)' }} />
      </div>
      <div style={{ display:'flex', gap:8, paddingTop:10 }}>
        <button onClick={onClose} className="mm-btn-ghost" style={{ flex:1, padding:'12px' }}>Cancel</button>
        <button onClick={() => onConfirm({ reason, note })} className="mm-btn-primary" style={{ flex:1, padding:'12px' }}>Flag · Refine</button>
      </div>
    </div>
  );
}

// ─── Habit detail view (mirrors Screen 3.10 from the brief) ───
function HabitDetail({ h: hIn, onBack }) {
  const [h, setH] = React.useState(hIn);
  const [modal, setModal] = React.useState(null); // 'edit' | 'flag' | null
  const [toast, setToast] = React.useState(null);
  React.useEffect(() => {
    if (!toast) return undefined;
    const t = setTimeout(() => setToast(null), 2200);
    return () => clearTimeout(t);
  }, [toast]);
  const hex = CORE_HEX[h.coreId] || '#fff';
  const stage = STAGE_DEFS[h.stage] || STAGE_DEFS.forming;
  // Progress toward "Formed" — brief says 14d × 80% triggers Trophy Room.
  const FORMED_THRESHOLD = 14;
  const pctToFormed = Math.min(100, Math.round((h.daysFormed / FORMED_THRESHOLD) * 100));

  return (
    <div style={{ width:'100%', height:'100%', position:'relative', overflow:'hidden',
        background:'#06070d', paddingTop:56 }}>
      <div className="mm-starfield" />
      <div className="mm-stars" />

      {/* header */}
      <div style={{ position:'relative', zIndex:5, display:'flex', alignItems:'center',
          gap:10, padding:'14px 18px 10px' }}>
        <button onClick={onBack} aria-label="Back" style={{
          background:'rgba(17,28,78,.55)', border:'1px solid rgba(241,241,241,.12)',
          borderRadius:10, width:36, height:36, color:'#fff', display:'grid', placeItems:'center', cursor:'pointer',
        }}>
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M10 3 L 4 8 L 10 13"/></svg>
        </button>
        <div style={{ flex:1, minWidth:0 }}>
          <div style={{ display:'flex', alignItems:'center', gap:6 }}>
            <div className="mm-dot" style={{ background:stage.color, boxShadow:`0 0 6px ${stage.color}` }} />
            <span className="t-display-x" style={{ fontSize:10, letterSpacing:'.16em', color:stage.color }}>
              {stage.label.toUpperCase()}
            </span>
            <span className="t-display-x" style={{ fontSize:10, letterSpacing:'.14em', color:'rgba(241,241,241,.5)' }}>
              · {h.habitType === 'routine' ? 'ROUTINE' : 'NON-ROUTINE'}
            </span>
          </div>
          <div className="t-display" style={{ fontSize:18, color:'#fff', marginTop:2, overflow:'hidden',
            textOverflow:'ellipsis', whiteSpace:'nowrap' }}>{h.habitName}</div>
          <div style={{ fontSize:10, color:hex, fontFamily:'var(--f-display)', letterSpacing:'.1em', marginTop:2 }}>
            {h.coreLabel.toUpperCase()} {h.coreDimension && `· ${h.coreDimension.toUpperCase()}`}
          </div>
        </div>
        <div style={{ textAlign:'right' }}>
          <div className="t-display t-num" style={{ fontSize:20, color:hex }}>{h.streak}🔥</div>
          <div style={{ fontSize:9, fontFamily:'var(--f-display)', letterSpacing:'.14em', color:'rgba(241,241,241,.5)' }}>DAYS</div>
        </div>
      </div>

      {/* body */}
      <div style={{ position:'relative', zIndex:4, height:'calc(100% - 124px)',
          overflow:'auto', padding:'0 16px 80px' }}>

        {/* Progress to Formed */}
        <div className="mm-panel" style={{ padding:'12px 14px', marginBottom:10,
          borderLeft:`2px solid ${hex}`,
          background:`linear-gradient(135deg, ${hex}15, transparent 70%)` }}>
          <div style={{ display:'flex', justifyContent:'space-between', alignItems:'baseline' }}>
            <span className="t-display-x" style={{ fontSize:10, letterSpacing:'.16em', color:'rgba(241,241,241,.65)' }}>
              PROGRESS TO FORMED
            </span>
            <span className="t-display t-num" style={{ fontSize:12, color:hex }}>{h.daysFormed} / {FORMED_THRESHOLD} d</span>
          </div>
          <div style={{ height:5, borderRadius:3, background:'rgba(241,241,241,.08)', marginTop:8, overflow:'hidden' }}>
            <div style={{ width:`${pctToFormed}%`, height:'100%',
              background:`linear-gradient(90deg, ${hex}, ${hex}cc)`,
              boxShadow:`0 0 6px ${hex}88`, transition:'width .4s' }} />
          </div>
        </div>

        {/* BTTF Vision */}
        {h.backToFutureIdentity && (
          <div className="mm-panel" style={{ padding:'12px 14px', marginBottom:10,
            borderLeft:`2px solid ${hex}`, fontStyle:'italic',
            background:`linear-gradient(135deg, ${hex}10, transparent 70%)` }}>
            <div className="t-display-x" style={{ fontSize:9, letterSpacing:'.18em',
              color:'rgba(241,241,241,.45)', marginBottom:4 }}>BTTF VISION</div>
            <div style={{ fontSize:13, color:'#fff', lineHeight:1.5 }}>"{h.backToFutureIdentity}"</div>
          </div>
        )}

        {h.painPoint && (
          <DetailSection label="PAIN POINT" color="rgba(234,0,41,.7)">
            <div style={{ fontSize:13, color:'rgba(241,241,241,.85)', lineHeight:1.5 }}>{h.painPoint}</div>
          </DetailSection>
        )}

        {/* The habit mechanics */}
        <DetailSection label="THE HABIT" color={hex}>
          <KV k="WHAT"   v={h.what} />
          <KV k="WHERE"  v={h.where} />
          <KV k="WHEN"   v={h.when} />
        </DetailSection>

        {/* Cue */}
        {(h.trigger || h.cueType || h.anchorReminder) && (
          <DetailSection label="CUE" color="var(--mm-blue)">
            <KV k="TYPE"    v={h.cueType ? h.cueType.replace(/_/g,' ').toUpperCase() : null} />
            <KV k="TRIGGER" v={h.trigger} />
            <KV k="ANCHOR"  v={h.anchorReminder} />
          </DetailSection>
        )}

        {/* IF-THEN plan */}
        {(h.obstacleIf || h.obstacleThen) && (
          <DetailSection label="IF · THEN OBSTACLE PLAN" color="var(--mm-yellow)">
            <KV k="IF"   v={h.obstacleIf} />
            <KV k="THEN" v={h.obstacleThen} />
          </DetailSection>
        )}

        {/* Why it works */}
        {(h.whyWant || h.whyCan || h.whyEffective) && (
          <DetailSection label="WHY IT WORKS" color="var(--mm-magenta)">
            <KV k="WANT IT"   v={h.whyWant} />
            <KV k="CAN DO IT" v={h.whyCan} />
            <KV k="EFFECTIVE" v={h.whyEffective} />
          </DetailSection>
        )}

        {/* Starting (MVA) version */}
        {h.startingVersion && (
          <DetailSection label="STARTING VERSION (MVA)" color="var(--mm-teal)">
            <div style={{ fontSize:13, color:'#fff', lineHeight:1.45 }}>{h.startingVersion}</div>
            <div style={{ fontSize:11, color:'rgba(241,241,241,.5)', marginTop:6, lineHeight:1.4 }}>
              Fall back to this when friction is high. Non-zero beats perfect.
            </div>
          </DetailSection>
        )}

        {/* CTAs */}
        <div style={{ display:'flex', gap:8, marginTop:10 }}>
          <button onClick={() => setModal('edit')} className="mm-btn-ghost"
            style={{ flex:1, padding:'12px', borderColor:`${hex}66`, color:hex }}>Edit</button>
          <button onClick={() => setModal('flag')} className="mm-btn-ghost"
            style={{ flex:1, padding:'12px', borderColor:'rgba(255,198,41,.5)', color:'var(--mm-yellow)' }}>⚠ Flag</button>
        </div>
      </div>

      {/* Modals */}
      {modal === 'edit' && (
        <HabitEditModal h={h} onClose={() => setModal(null)}
          onSave={(draft) => {
            setH({ ...h, ...draft });
            setModal(null);
            setToast('Habit saved · logged to Captain\u2019s Log');
            // TODO: POST to saveGoldenHabit with merged payload
          }} />
      )}
      {modal === 'flag' && (
        <HabitFlagModal h={h} onClose={() => setModal(null)}
          onConfirm={({ reason, note }) => {
            setH({ ...h, flagged: true, flagReason: reason, flagNote: note });
            setModal(null);
            setToast('Flagged · Nova will pattern-match this');
          }} />
      )}

      {/* Toast */}
      {toast && (
        <div style={{ position:'absolute', left:14, right:14, bottom:18, zIndex:60,
          padding:'10px 14px', borderRadius:10,
          background:'rgba(0,169,143,.18)', border:'1px solid rgba(0,169,143,.55)',
          color:'#fff', fontSize:12, textAlign:'center',
          boxShadow:'0 8px 24px rgba(0,0,0,.4)' }}>
          {toast}
        </div>
      )}
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN: Habits screen — list of Golden Habits, tap to see detail
// ═══════════════════════════════════════════════════════════════════════════
function HabitsScreen(props) {
  // In production: replace this with a fetch to a fetchAllGoldenHabits cloud
  // function (same pattern as fetchAllMomentumLists / fetchAllCoreListItems).
  //
  //   const [habits, setHabits] = React.useState([]);
  //   React.useEffect(() => {
  //     fetch(`${BASE}/fetchAllGoldenHabits?secret=${SECRET}&userId=${uid}`)
  //       .then(r => r.json()).then(d => setHabits(d.habits || []));
  //   }, []);
  const habits = MOCK_GOLDEN_HABITS;
  const [openId, setOpenId] = React.useState(null);
  const open = habits.find(h => h.habitId === openId);

  if (open) {
    return <HabitDetail h={open} onBack={() => setOpenId(null)} />;
  }

  return (
    <ScreenShell title="Habits" subtitle={`GOLDEN HABITS · ${habits.length}`}
      accent="var(--mm-magenta)" {...props}>
      <div style={{ display:'flex', flexDirection:'column', gap:10 }}>
        {habits.map((h) => (
          <HabitCard key={h.habitId} h={h} onOpen={() => setOpenId(h.habitId)} />
        ))}
        <button onClick={() => props.onChat?.()} className="mm-btn-ghost" style={{ marginTop:6, padding:'14px' }}>
          + Forge new Golden Habit
        </button>
        <div style={{ fontSize:10, color:'rgba(241,241,241,.4)', textAlign:'center',
          fontFamily:'var(--f-display)', letterSpacing:'.16em', marginTop:4 }}>
          POWERED BY GOLDEN HABIT FORGE (PHASE 1)
        </div>
      </div>
    </ScreenShell>
  );
}

Object.assign(window, { HabitsScreen, MOCK_GOLDEN_HABITS, CORE_HEX, STAGE_DEFS });
