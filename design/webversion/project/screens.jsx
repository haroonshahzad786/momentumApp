// screens.jsx — Lists, Routines, Habits, Tasks, Cantina, Trophy, Profile,
// AI Co-pilot chat, and the slide-out Menu drawer.
// Each screen fills the device viewport (overlaid on the rocket cockpit).

// ─────────────────────────────────────────────────────────────
// Shared chrome — header + scrollable body + bottom-nav slot
// ─────────────────────────────────────────────────────────────
function ScreenShell({ title, subtitle, accent = 'var(--mm-blue)', onBack, onChat, children, hideNav = false, onNav }) {
  return (
    <div style={{
      width:'100%', height:'100%', position:'relative', overflow:'hidden',
      background:'#06070d',
      paddingTop: 56,
    }}>
      <div className="mm-starfield" />
      <div className="mm-stars" />
      <div className="mm-scanlines" />

      {/* header */}
      <div style={{
        position:'relative', zIndex:5, display:'flex', alignItems:'center',
        gap:10, padding:'14px 18px 10px',
      }}>
        <button onClick={onBack} aria-label="Back" style={{
          background:'rgba(17,28,78,.55)', border:'1px solid rgba(241,241,241,.12)',
          borderRadius:10, width:36, height:36, color:'#fff',
          display:'grid', placeItems:'center', cursor:'pointer',
        }}>
          <svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M11 3 L 5 9 L 11 15" />
          </svg>
        </button>
        <div style={{ flex:1 }}>
          <div className="t-display-x" style={{ fontSize:11, letterSpacing:'.18em', color:accent }}>{subtitle || 'COCKPIT'}</div>
          <div className="t-display" style={{ fontSize:22, color:'#fff', marginTop:2 }}>{title}</div>
        </div>
        {onChat && (
          <button onClick={onChat} aria-label="AI Co-pilot" style={{
            background:'linear-gradient(180deg, #4d9bff 0%, #2a7de1 100%)',
            border:'1px solid rgba(155,92,255,.55)',
            borderRadius:10, width:36, height:36, color:'#fff',
            display:'grid', placeItems:'center', cursor:'pointer',
            boxShadow:'0 0 14px rgba(155,92,255,.45)',
          }}>
            <svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
              <path d="M9 1 L 11 5 L 15 6 L 12 9 L 13 14 L 9 11.5 L 5 14 L 6 9 L 3 6 L 7 5 Z" />
            </svg>
          </button>
        )}
      </div>

      {/* body */}
      <div style={{
        position:'relative', zIndex:4, height:'calc(100% - 56px - 64px - 70px)',
        overflow:'auto', padding:'4px 16px 80px',
      }}>
        {children}
      </div>

      {!hideNav && <BottomNav onNav={onNav} />}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Lists  —  Mission objectives, grouped by Core
// ─────────────────────────────────────────────────────────────
function ListsScreen(props) {
  const lists = [
    { name:'Q4 Mission Logs', core:'mindset',       count:12, hex:'#2a7de1' },
    { name:'Promotion Track', core:'career',        count:8,  hex:'#FFC629' },
    { name:'Date Night Ideas',core:'relationships', count:5,  hex:'#ff3d8b' },
    { name:'Gym Programs',    core:'physical',      count:3,  hex:'#00a98f' },
    { name:'Reading Queue',   core:'emotional',     count:14, hex:'#9b5cff' },
  ];
  return (
    <ScreenShell title="Lists" subtitle="MANIFEST · 5" accent="var(--mm-blue)" {...props}>
      <div style={{ display:'flex', flexDirection:'column', gap:10 }}>
        {lists.map((l) => (
          <div key={l.name} className="mm-panel" style={{
            padding:'14px 14px 12px', display:'flex', alignItems:'center', gap:12,
            borderLeft:`3px solid ${l.hex}`,
          }}>
            <div className="mm-dot" style={{ background:l.hex, boxShadow:`0 0 8px ${l.hex}` }} />
            <div style={{ flex:1 }}>
              <div style={{ fontSize:14, fontWeight:600, color:'#fff' }}>{l.name}</div>
              <div className="t-display" style={{ fontSize:9, letterSpacing:'.14em', color:'rgba(241,241,241,.5)', marginTop:3, textTransform:'uppercase' }}>{l.core}</div>
            </div>
            <span className="mm-chip t-num" style={{ color:l.hex }}>{l.count}</span>
          </div>
        ))}
        <button className="mm-btn-ghost" style={{ marginTop:8 }}>+ New Manifest</button>
      </div>
    </ScreenShell>
  );
}

// ─────────────────────────────────────────────────────────────
// Routines  —  The Full Routines List (Decision B2 / C2 / C3)
//   • ROUTINE habits      → the daily schedule. Cluster by time of day,
//     progress 🔴→🟠→🟢, turn GREEN when formed but STAY in the list
//     ("the sea of green").
//   • NON-ROUTINE habits  → identity habits in the daily check-in. When
//     formed (14d · 80%) they GRADUATE to the Trophy Room (by Core).
//   • Manual add (C2): minimal fields = name, Core, routine vs non-routine.
// ─────────────────────────────────────────────────────────────
const ROUTINE_CORES = {
  mindset:       { label:'Mindset',       hex:'#2a7de1', icon:'🧠' },
  career:        { label:'Career',        hex:'#FFC629', icon:'💰' },
  relationships: { label:'Relationships', hex:'#ff3d8b', icon:'👥' },
  physical:      { label:'Physical',      hex:'#00a98f', icon:'💪' },
  emotional:     { label:'Emotional',     hex:'#9b5cff', icon:'🧘' },
};
// The Full Routines List color transformation — most visceral progress signal.
const ROUTINE_STAGES = {
  bad:     { hex:'#ea0029', label:'Bad'     },
  forming: { hex:'#FFC629', label:'Forming' },
  formed:  { hex:'#00a98f', label:'Formed'  },
};
const TIME_BLOCKS = [
  { id:'morning', name:'Launch Sequence', time:'06:30', label:'MORNING' },
  { id:'workday', name:'Deep Work Block', time:'09:00', label:'WORKDAY' },
  { id:'evening', name:'Re-entry',        time:'21:00', label:'EVENING' },
];

// Keyword → Core suggestion (stands in for the Phase-1 AI core assignment).
function suggestCore(name) {
  const n = (name || '').toLowerCase();
  if (/run|gym|lift|walk|stretch|yoga|sleep|hydrate|water|workout|strength|steps/.test(n)) return 'physical';
  if (/money|budget|invoice|work|email|finance|save|invest|client|deep work/.test(n))      return 'career';
  if (/call|text|friend|family|partner|date|connect|reach out|coffee with/.test(n))         return 'relationships';
  if (/journal|gratitude|breath|vent|therapy|mood|feel|rest|reflect/.test(n))               return 'emotional';
  return 'mindset';
}

// ─── Add-habit modal: minimal manual entry (Decision C2) ───
function AddHabitModal({ onSave, onClose }) {
  const [name, setName] = React.useState('');
  const [type, setType] = React.useState('routine');     // routine | non_routine — REQUIRED
  const [block, setBlock] = React.useState('morning');
  const [core, setCore] = React.useState(null);          // null → use AI suggestion
  const suggested = suggestCore(name);
  const activeCore = core || suggested;
  const hex = ROUTINE_CORES[activeCore].hex;
  const canSave = name.trim().length > 0;

  return (
    <div style={{ position:'absolute', inset:0, zIndex:50,
        background:'rgba(6,7,13,.88)', backdropFilter:'blur(8px)',
        display:'flex', flexDirection:'column', padding:'68px 14px 14px' }}>
      <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:14 }}>
        <button onClick={onClose} aria-label="Close" style={{
          background:'rgba(17,28,78,.55)', border:'1px solid rgba(241,241,241,.12)',
          borderRadius:10, width:36, height:36, color:'#fff', display:'grid', placeItems:'center', cursor:'pointer' }}>
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><path d="M3 3 L 11 11 M 11 3 L 3 11"/></svg>
        </button>
        <div className="t-display-x" style={{ fontSize:12, letterSpacing:'.18em', color:hex }}>ADD A HABIT</div>
      </div>

      <div style={{ flex:1, overflow:'auto' }}>
        {/* Name */}
        <label style={{ display:'block', marginBottom:14 }}>
          <div className="t-display-x" style={{ fontSize:9, letterSpacing:'.18em', color:'rgba(241,241,241,.55)', marginBottom:6 }}>HABIT NAME</div>
          <input type="text" value={name} onChange={(e) => setName(e.target.value)} autoFocus
            placeholder="e.g. 10-minute morning walk" style={{
            width:'100%', padding:'12px 14px', borderRadius:10,
            background:'rgba(17,28,78,.55)', border:`1px solid ${hex}66`,
            color:'#fff', fontSize:14, outline:'none' }} />
        </label>

        {/* Routine vs Non-routine — the defining choice */}
        <div style={{ marginBottom:14 }}>
          <div className="t-display-x" style={{ fontSize:9, letterSpacing:'.18em', color:'rgba(241,241,241,.55)', marginBottom:6 }}>HABIT TYPE</div>
          <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:8 }}>
            {[
              { id:'routine',     name:'Routine',     desc:'Daily schedule. Turns green & stays in this list.' },
              { id:'non_routine', name:'Non-routine', desc:'Identity habit. Graduates to the Trophy Room.' },
            ].map((o) => {
              const on = type === o.id;
              return (
                <button key={o.id} type="button" onClick={() => setType(o.id)} style={{
                  textAlign:'left', padding:'11px 12px', borderRadius:10, cursor:'pointer',
                  background: on ? `${hex}1f` : 'rgba(17,28,78,.45)',
                  border: on ? `1.5px solid ${hex}` : '1px solid rgba(241,241,241,.12)',
                  boxShadow: on ? `0 0 12px ${hex}44` : 'none', transition:'all .14s' }}>
                  <div className="t-display" style={{ fontSize:13, color: on ? '#fff' : 'rgba(241,241,241,.8)' }}>{o.name}</div>
                  <div style={{ fontSize:10, color:'rgba(241,241,241,.6)', lineHeight:1.4, marginTop:4 }}>{o.desc}</div>
                </button>
              );
            })}
          </div>
        </div>

        {/* Time block — routine only */}
        {type === 'routine' && (
          <div style={{ marginBottom:14 }}>
            <div className="t-display-x" style={{ fontSize:9, letterSpacing:'.18em', color:'rgba(241,241,241,.55)', marginBottom:6 }}>WHEN · TIME BLOCK</div>
            <div style={{ display:'flex', gap:6 }}>
              {TIME_BLOCKS.map((b) => {
                const on = block === b.id;
                return (
                  <button key={b.id} type="button" onClick={() => setBlock(b.id)} style={{
                    flex:1, padding:'9px 4px', borderRadius:9, cursor:'pointer',
                    background: on ? 'rgba(0,169,143,.18)' : 'rgba(17,28,78,.45)',
                    border: on ? '1.5px solid var(--mm-teal)' : '1px solid rgba(241,241,241,.12)',
                    color: on ? '#fff' : 'rgba(241,241,241,.7)' }}>
                    <div className="t-display-x" style={{ fontSize:8, letterSpacing:'.12em' }}>{b.label}</div>
                    <div className="t-mono" style={{ fontSize:10, marginTop:3, color: on ? 'var(--mm-teal)' : 'rgba(241,241,241,.5)' }}>{b.time}</div>
                  </button>
                );
              })}
            </div>
          </div>
        )}

        {/* Core — AI suggests, player can override */}
        <div style={{ marginBottom:6 }}>
          <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:6 }}>
            <div className="t-display-x" style={{ fontSize:9, letterSpacing:'.18em', color:'rgba(241,241,241,.55)' }}>CORE</div>
            <span style={{ fontSize:9, color:hex, fontFamily:'var(--f-display)', letterSpacing:'.1em' }}>
              ✦ NOVA SUGGESTS {ROUTINE_CORES[suggested].label.toUpperCase()}
            </span>
          </div>
          <div style={{ display:'flex', flexWrap:'wrap', gap:6 }}>
            {Object.entries(ROUTINE_CORES).map(([id, c]) => {
              const on = activeCore === id;
              const isSuggested = !core && suggested === id;
              return (
                <button key={id} type="button" onClick={() => setCore(id)} style={{
                  display:'flex', alignItems:'center', gap:6, padding:'8px 11px', borderRadius:999, cursor:'pointer',
                  background: on ? `${c.hex}22` : 'rgba(17,28,78,.45)',
                  border: on ? `1.5px solid ${c.hex}` : `1px solid ${isSuggested ? c.hex+'77' : 'rgba(241,241,241,.12)'}`,
                  boxShadow: on ? `0 0 10px ${c.hex}55` : 'none',
                  color: on ? '#fff' : 'rgba(241,241,241,.75)', fontSize:12, transition:'all .14s' }}>
                  <span style={{ fontSize:13 }}>{c.icon}</span>{c.label}
                </button>
              );
            })}
          </div>
        </div>

        <div style={{ fontSize:10.5, color:'rgba(241,241,241,.5)', lineHeight:1.5, marginTop:14,
          padding:'10px 12px', borderRadius:9, background:'rgba(17,28,78,.4)', border:'1px solid rgba(241,241,241,.08)' }}>
          Minimal setup — you can run the full <b style={{ color:'rgba(241,241,241,.75)' }}>Golden Habit Forge</b> (Phase 1)
          later to add cues, MBM strategies and your <i>Back-to-the-Future</i> vision.
        </div>
      </div>

      <div style={{ display:'flex', gap:8, paddingTop:12 }}>
        <button onClick={onClose} className="mm-btn-ghost" style={{ flex:1, padding:'13px' }}>Cancel</button>
        <button disabled={!canSave} onClick={() => onSave({
            name: name.trim(), type, core: activeCore,
            block: type === 'routine' ? block : null, stage: 'bad' })}
          className="mm-btn-primary" style={{ flex:1.4, padding:'13px', opacity: canSave ? 1 : .4,
            cursor: canSave ? 'pointer' : 'not-allowed' }}>Add Habit</button>
      </div>
    </div>
  );
}

// ─── One row in the Full Routines List ───
function RoutineRow({ h, onCycle }) {
  const core = ROUTINE_CORES[h.core] || ROUTINE_CORES.mindset;
  const st = ROUTINE_STAGES[h.stage] || ROUTINE_STAGES.bad;
  const formed = h.stage === 'formed';
  return (
    <button onClick={onCycle} style={{
      width:'100%', textAlign:'left', cursor:'pointer',
      display:'flex', alignItems:'center', gap:10, padding:'10px 12px', borderRadius:10,
      background: formed ? 'rgba(0,169,143,.14)' : 'rgba(17,28,78,.4)',
      border: `1px solid ${formed ? 'rgba(0,169,143,.5)' : 'rgba(241,241,241,.1)'}`,
      transition:'all .15s' }}>
      <span style={{ width:11, height:11, borderRadius:'50%', flexShrink:0,
        background: st.hex, boxShadow:`0 0 8px ${st.hex}` }} />
      <span style={{ flex:1, minWidth:0 }}>
        <span style={{ display:'block', fontSize:13, color: formed ? '#fff' : 'rgba(241,241,241,.9)',
          fontWeight: formed ? 600 : 400 }}>{h.name}</span>
        <span className="t-display-x" style={{ fontSize:8.5, letterSpacing:'.12em', color: st.hex }}>
          {st.label.toUpperCase()}{formed && ' · GREEN'}
        </span>
      </span>
      <span style={{ display:'flex', alignItems:'center', gap:5, flexShrink:0,
        padding:'4px 8px', borderRadius:999, background:`${core.hex}1a`, border:`1px solid ${core.hex}44` }}>
        <span style={{ fontSize:11 }}>{core.icon}</span>
        <span className="t-display-x" style={{ fontSize:8.5, letterSpacing:'.1em', color:core.hex }}>{core.label.toUpperCase()}</span>
      </span>
    </button>
  );
}

function SegToggle({ value, onChange, options }) {
  return (
    <div style={{ display:'inline-flex', padding:3, borderRadius:999,
      background:'rgba(17,28,78,.55)', border:'1px solid rgba(241,241,241,.12)' }}>
      {options.map((o) => {
        const on = value === o.id;
        return (
          <button key={o.id} type="button" onClick={() => onChange(o.id)} style={{
            padding:'6px 13px', borderRadius:999, cursor:'pointer', border:'none',
            background: on ? 'var(--mm-teal)' : 'transparent',
            color: on ? '#04130f' : 'rgba(241,241,241,.7)',
            fontFamily:'var(--f-display)', fontSize:10, letterSpacing:'.12em', fontWeight:700,
            transition:'all .14s' }}>{o.label}</button>
        );
      })}
    </div>
  );
}

function RoutinesScreen(props) {
  // Local demo state — in production this is fetchAllGoldenHabits filtered by type.
  const [routine, setRoutine] = React.useState([
    { id:'r1', name:'Hydrate',        core:'physical', block:'morning', stage:'formed'  },
    { id:'r2', name:'10-min journal', core:'mindset',  block:'morning', stage:'formed'  },
    { id:'r3', name:'Stretch',        core:'physical', block:'morning', stage:'forming' },
    { id:'r4', name:'Email triage',   core:'career',   block:'workday', stage:'formed'  },
    { id:'r5', name:'2h focus block', core:'career',   block:'workday', stage:'forming' },
    { id:'r6', name:'Walk break',     core:'physical', block:'workday', stage:'forming' },
    { id:'r7', name:'Day review',     core:'mindset',  block:'evening', stage:'forming' },
    { id:'r8', name:'Read 20m',       core:'emotional',block:'evening', stage:'bad'     },
    { id:'r9', name:'Lights down',    core:'physical', block:'evening', stage:'formed'  },
  ]);
  const [nonRoutine, setNonRoutine] = React.useState([
    { id:'n1', name:'Strength Block',        core:'physical',     stage:'forming' },
    { id:'n2', name:'Weekly friend check-in',core:'relationships',stage:'forming' },
    { id:'n3', name:'Money dashboard review',core:'career',       stage:'bad'     },
  ]);
  const [view, setView] = React.useState('time'); // time | core
  const [adding, setAdding] = React.useState(false);
  const [toast, setToast] = React.useState(null);
  React.useEffect(() => {
    if (!toast) return undefined;
    const id = setTimeout(() => setToast(null), 2600);
    return () => clearTimeout(id);
  }, [toast]);

  // demo: tap a row to advance its lifecycle color (bad→forming→formed)
  const cycleStage = (list, setList) => (rid) => {
    const order = ['bad', 'forming', 'formed'];
    setList(list.map((h) => h.id === rid
      ? { ...h, stage: order[(order.indexOf(h.stage) + 1) % order.length] } : h));
  };

  const addHabit = (data) => {
    const rec = { id: 'h' + Date.now(), ...data };
    if (data.type === 'routine') setRoutine((r) => [...r, rec]);
    else setNonRoutine((r) => [...r, rec]);
    setAdding(false);
    setToast(data.type === 'routine'
      ? `Routine added to ${TIME_BLOCKS.find(b => b.id === data.block).label.toLowerCase()} · logged`
      : 'Non-routine added to your daily check-in · logged');
  };

  const formedCount = routine.filter(h => h.stage === 'formed').length;
  const TROPHY_FORMED = 2; // non-routines already graduated to the Trophy Room

  // grouping
  const groups = view === 'time'
    ? TIME_BLOCKS.map(b => ({
        key:b.id, title:b.name, meta:`${b.label} · ${b.time}`, accent:'var(--mm-teal)',
        items: routine.filter(h => h.block === b.id) }))
    : Object.entries(ROUTINE_CORES).map(([id, c]) => ({
        key:id, title:`${c.icon} ${c.label}`, meta:'CORE', accent:c.hex,
        items: routine.filter(h => h.core === id) })).filter(g => g.items.length);

  return (
    <ScreenShell title="Routines" subtitle={`FULL ROUTINES LIST · ${routine.length + nonRoutine.length}`}
      accent="var(--mm-teal)" {...props}>

      {/* Control bar: organisation toggle + add */}
      <div style={{ display:'flex', alignItems:'center', justifyContent:'space-between', gap:8, marginBottom:14 }}>
        <SegToggle value={view} onChange={setView}
          options={[{ id:'time', label:'BY TIME' }, { id:'core', label:'BY CORE' }]} />
        <button onClick={() => setAdding(true)} style={{
          display:'flex', alignItems:'center', gap:6, padding:'8px 13px', borderRadius:999, cursor:'pointer',
          background:'linear-gradient(180deg, #00c9a7 0%, #00a98f 100%)', border:'1px solid rgba(0,169,143,.6)',
          color:'#04130f', fontFamily:'var(--f-display)', fontSize:11, fontWeight:700, letterSpacing:'.1em',
          boxShadow:'0 0 14px rgba(0,169,143,.45)' }}>
          <svg width="13" height="13" viewBox="0 0 13 13" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round"><path d="M6.5 2 V 11 M 2 6.5 H 11"/></svg>
          ADD
        </button>
      </div>

      {/* ROUTINE — the sea of green */}
      <div style={{ display:'flex', alignItems:'baseline', justifyContent:'space-between', margin:'2px 2px 8px' }}>
        <span className="t-display-x" style={{ fontSize:10, letterSpacing:'.18em', color:'#fff' }}>ROUTINE</span>
        <span className="t-display-x t-num" style={{ fontSize:9, letterSpacing:'.12em', color:'var(--mm-teal)' }}>
          {formedCount}/{routine.length} GREEN
        </span>
      </div>
      {/* sea-of-green progress bar */}
      <div style={{ height:5, borderRadius:3, background:'rgba(241,241,241,.08)', overflow:'hidden', marginBottom:12 }}>
        <div style={{ width:`${Math.round((formedCount/routine.length)*100)}%`, height:'100%',
          background:'linear-gradient(90deg, var(--mm-teal), #00c9a7)', boxShadow:'0 0 8px rgba(0,169,143,.7)',
          transition:'width .4s' }} />
      </div>

      <div style={{ display:'flex', flexDirection:'column', gap:14 }}>
        {groups.map((g) => (
          <div key={g.key}>
            <div className="t-display-x" style={{ fontSize:9, letterSpacing:'.16em',
              color:'rgba(241,241,241,.5)', margin:'0 2px 7px', display:'flex', gap:8, alignItems:'baseline' }}>
              <span style={{ color:g.accent }}>{g.title}</span>
              <span style={{ opacity:.7 }}>· {g.meta}</span>
            </div>
            <div style={{ display:'flex', flexDirection:'column', gap:6 }}>
              {g.items.map((h) => (
                <RoutineRow key={h.id} h={h} onCycle={() => cycleStage(routine, setRoutine)(h.id)} />
              ))}
            </div>
          </div>
        ))}
      </div>

      {/* NON-ROUTINE — identity habits → Trophy Room */}
      <div style={{ display:'flex', alignItems:'baseline', justifyContent:'space-between', margin:'22px 2px 4px' }}>
        <span className="t-display-x" style={{ fontSize:10, letterSpacing:'.18em', color:'#fff' }}>NON-ROUTINE</span>
        <span className="t-display-x" style={{ fontSize:9, letterSpacing:'.12em', color:'rgba(241,241,241,.45)' }}>
          IDENTITY HABITS
        </span>
      </div>
      <div style={{ fontSize:11, color:'rgba(241,241,241,.6)', lineHeight:1.5, margin:'0 2px 12px' }}>
        Active in your daily check-in. When formed (14d · 80%) they graduate to the Trophy Room.
      </div>
      <div style={{ display:'flex', flexDirection:'column', gap:6 }}>
        {nonRoutine.map((h) => (
          <RoutineRow key={h.id} h={h} onCycle={() => cycleStage(nonRoutine, setNonRoutine)(h.id)} />
        ))}
      </div>

      {/* graduated → Trophy Room */}
      <button onClick={() => props.onNav?.('trophy')} style={{
        width:'100%', marginTop:10, padding:'12px 14px', borderRadius:10, cursor:'pointer', textAlign:'left',
        display:'flex', alignItems:'center', gap:10,
        background:'linear-gradient(135deg, rgba(255,198,41,.14), transparent 70%)',
        border:'1px solid rgba(255,198,41,.4)' }}>
        <span style={{ fontSize:18 }}>🏆</span>
        <span style={{ flex:1 }}>
          <span style={{ display:'block', fontSize:12.5, color:'#fff', fontWeight:600 }}>{TROPHY_FORMED} formed → Trophy Room</span>
          <span style={{ fontSize:10.5, color:'rgba(241,241,241,.6)' }}>Permanent identity markers, by Core</span>
        </span>
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="var(--mm-yellow)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M5 3 L 9 7 L 5 11"/></svg>
      </button>

      <div style={{ fontSize:9.5, color:'rgba(241,241,241,.35)', textAlign:'center',
        fontFamily:'var(--f-display)', letterSpacing:'.14em', marginTop:16 }}>
        TAP ANY HABIT TO ADVANCE ITS LIFECYCLE · 🔴 → 🟠 → 🟢
      </div>

      {adding && <AddHabitModal onClose={() => setAdding(false)} onSave={addHabit} />}

      {toast && (
        <div style={{ position:'absolute', left:14, right:14, bottom:18, zIndex:60,
          padding:'10px 14px', borderRadius:10,
          background:'rgba(0,169,143,.18)', border:'1px solid rgba(0,169,143,.55)',
          color:'#fff', fontSize:12, textAlign:'center', boxShadow:'0 8px 24px rgba(0,0,0,.4)' }}>
          {toast}
        </div>
      )}
    </ScreenShell>
  );
}

// ─────────────────────────────────────────────────────────────
// Habits → moved to habits.jsx (Golden Habit data shape)
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
// Tasks  —  Today / Tomorrow / Later, with Core tag + points
// ─────────────────────────────────────────────────────────────
function TasksScreen(props) {
  const buckets = [
    { name:'Today', items:[
      { t:'Q3 report draft', core:'career', hex:'#FFC629', pts:30, done:false },
      { t:'10m breathwork',  core:'mindset', hex:'#2a7de1', pts:15, done:true },
      { t:'Grocery run',     core:'physical', hex:'#00a98f', pts:10, done:false },
    ]},
    { name:'Tomorrow', items:[
      { t:'1:1 with Sara', core:'relationships', hex:'#ff3d8b', pts:20, done:false },
      { t:'Yoga class',    core:'physical', hex:'#00a98f', pts:25, done:false },
    ]},
    { name:'Later', items:[
      { t:'Tax filing prep', core:'career', hex:'#FFC629', pts:60, done:false },
    ]},
  ];
  return (
    <ScreenShell title="Tasks" subtitle="MISSIONS · TODAY" accent="var(--mm-yellow)" {...props}>
      {buckets.map((b) => (
        <div key={b.name} style={{ marginBottom:14 }}>
          <div className="t-display-x" style={{ fontSize:10, letterSpacing:'.18em', color:'rgba(241,241,241,.5)', margin:'4px 4px 8px' }}>
            {b.name.toUpperCase()} · {b.items.length}
          </div>
          <div style={{ display:'flex', flexDirection:'column', gap:6 }}>
            {b.items.map((it, i) => (
              <div key={i} className="mm-panel" style={{
                padding:'10px 12px', display:'flex', alignItems:'center', gap:10,
                opacity: it.done ? .55 : 1,
              }}>
                <div style={{
                  width:16, height:16, borderRadius:4, flexShrink:0,
                  border:`1.5px solid ${it.done ? it.hex : 'rgba(241,241,241,.3)'}`,
                  background: it.done ? it.hex : 'transparent',
                  display:'grid', placeItems:'center',
                }}>
                  {it.done && (
                    <svg width="9" height="9" viewBox="0 0 9 9" fill="none" stroke="#000" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M1 4.5 L 3.5 7 L 8 2" />
                    </svg>
                  )}
                </div>
                <div style={{ flex:1, fontSize:13, color:'#fff', textDecoration: it.done ? 'line-through' : 'none' }}>{it.t}</div>
                <span className="mm-dot" style={{ background:it.hex, boxShadow:`0 0 4px ${it.hex}` }} />
                <span className="t-display t-num" style={{ fontSize:10, color:it.hex, letterSpacing:'.06em' }}>+{it.pts}</span>
              </div>
            ))}
          </div>
        </div>
      ))}
    </ScreenShell>
  );
}

// ─────────────────────────────────────────────────────────────
// Cantina  —  Crew / friends leaderboard + chat threads
// ─────────────────────────────────────────────────────────────
const CREW = [
  { id:'maya',  n:'Maya R.',  s:12420, lvl:'CMDR', online:true,  hex:'#ff3d8b', a:'M', streak:84,  planet:'Saturn',  cores:['mindset','career','relationships','physical','emotional'] },
  { id:'devon', n:'Devon T.', s:10115, lvl:'NAV',  online:true,  hex:'#2a7de1', a:'D', streak:62,  planet:'Jupiter', cores:['mindset','career','physical','emotional'] },
  { id:'me',    n:'You',      s:8420,  lvl:'NAV',  online:true,  hex:'#FFC629', a:'Y', streak:47,  planet:'Mars',    cores:['mindset','career','physical'], me:true },
  { id:'aisha', n:'Aisha K.', s:7980,  lvl:'NAV',  online:false, hex:'#00a98f', a:'A', streak:41,  planet:'Mars',    cores:['mindset','career','physical'] },
  { id:'leo',   n:'Leo M.',   s:3210,  lvl:'CDT',  online:false, hex:'#9b5cff', a:'L', streak:12,  planet:'Moon',    cores:['mindset','physical'] },
];
const THREADS = [
  { id:'maya',   n:'Maya R.',         m:'Nice 47-day streak 🔥',           time:'2m', hex:'#ff3d8b',
    crewId:'maya', history:[
      { from:'them', text:"Looked at your dashboard — that's a real streak now." },
      { from:'them', text:'Want to start a 7-day Physical Cores challenge?' },
      { from:'me',   text:"In. Let's go." },
      { from:'them', text:'Nice 47-day streak 🔥' },
    ]},
  { id:'squad',  n:'Squadron Pluto',  m:'Group challenge starts Monday',   time:'1h', hex:'#9b5cff',
    history:[
      { from:'devon', text:'Reminder: weekly recap drops tonight 9pm.' },
      { from:'aisha', text:'I am in.' },
      { from:'devon', text:'Group challenge starts Monday.' },
    ]},
];

// ─── Ideas Well: crowdsourced Golden Habits / MBMs / Tech (Pillar 1) ───
const IDEAS_WELL = [
  { id:1, kind:'habit', core:'physical',      pain:'consistent exercise', title:'Lay gym clothes out the night before', desc:'Cuts morning decisions to zero — shoes by the door, kit on the chair.', up:412, adopted:1180 },
  { id:2, kind:'habit', core:'mindset',       pain:'racing thoughts',     title:'10-min "brain dump" before bed',          desc:'Empty every open loop onto paper so sleep comes faster.', up:388, adopted:902 },
  { id:3, kind:'mbm',   core:'career',        pain:'procrastination',     title:'Make It Easy · 2-minute start rule',       desc:'Commit to just opening the doc. Momentum does the rest.', up:356, adopted:1410 },
  { id:4, kind:'habit', core:'relationships', pain:'staying in touch',    title:'Weekly 1-on-1 coffee, rotate friends',     desc:'One scheduled connection beats ten missed intentions.', up:301, adopted:640 },
  { id:5, kind:'mbm',   core:'physical',      pain:'better sleep',        title:'Make It Obvious · phone charges outside bedroom', desc:'No screen = earlier lights-out, automatically.', up:289, adopted:733 },
  { id:6, kind:'tech',  core:'career',        pain:'auto-saving',         title:'Auto-transfer app · "round-up" savings',   desc:'Rounds every purchase up and banks the difference.', up:254, adopted:521, link:true },
  { id:7, kind:'habit', core:'emotional',     pain:'stress spikes',       title:'Box-breathing on the first deep breath cue', desc:'4-4-4-4 the moment you notice tension in your chest.', up:233, adopted:455 },
  { id:8, kind:'tech',  core:'mindset',       pain:'focus',               title:'Focus-timer app · 25/5 pomodoros',         desc:'Community top pick for deep-work blocks.', up:198, adopted:389, link:true },
];
const IDEAS_CORES = [
  { id:'mindset', n:'Mind', hex:'#2a7de1' }, { id:'career', n:'Career', hex:'#FFC629' },
  { id:'relationships', n:'Rel.', hex:'#ff3d8b' }, { id:'physical', n:'Phys.', hex:'#00a98f' },
  { id:'emotional', n:'Emo.', hex:'#9b5cff' },
];

function IdeasWell() {
  const [core, setCore] = React.useState(null);
  const [kind, setKind] = React.useState('habit');
  const [votes, setVotes] = React.useState({});
  const [adopt, setAdopt] = React.useState(null);
  const [toast, setToast] = React.useState(null);

  React.useEffect(() => {
    if (!toast) return undefined;
    const t = setTimeout(() => setToast(null), 2000); return () => clearTimeout(t);
  }, [toast]);

  const kindOf = kind === 'habit' ? 'habit' : kind === 'mbm' ? 'mbm' : 'tech';
  const feed = IDEAS_WELL
    .filter(x => x.kind === kindOf)
    .filter(x => !core || x.core === core)
    .map(x => ({ ...x, up: x.up + (votes[x.id] ? 1 : 0) }))
    .sort((a,b) => b.up - a.up);

  const hexOf = (id) => IDEAS_CORES.find(c => c.id === id)?.hex || '#fff';

  return (
    <div>
      {/* Core filter */}
      <div style={{ display:'flex', gap:5, marginBottom:8 }}>
        <button onClick={() => setCore(null)} style={{
          flex:'0 0 auto', padding:'6px 10px', borderRadius:999, cursor:'pointer',
          background: core===null ? 'rgba(255,255,255,.14)' : 'rgba(241,241,241,.04)',
          border:`1px solid ${core===null ? '#fff' : 'rgba(241,241,241,.12)'}`,
          color:'#fff', fontSize:10, fontFamily:'var(--f-display)', letterSpacing:'.06em' }}>ALL</button>
        {IDEAS_CORES.map(c => (
          <button key={c.id} onClick={() => setCore(core===c.id ? null : c.id)} style={{
            flex:1, padding:'6px 4px', borderRadius:999, cursor:'pointer',
            background: core===c.id ? `${c.hex}33` : 'rgba(241,241,241,.04)',
            border:`1px solid ${core===c.id ? c.hex : 'rgba(241,241,241,.12)'}`,
            color: core===c.id ? '#fff' : 'rgba(241,241,241,.7)', fontSize:10,
            fontFamily:'var(--f-display)', letterSpacing:'.04em' }}>{c.n}</button>
        ))}
      </div>

      {/* Kind toggle */}
      <div style={{ display:'flex', gap:4, padding:3, borderRadius:8,
          background:'rgba(241,241,241,.06)', marginBottom:12 }}>
        {[['habit','Habits'],['mbm','MBMs'],['tech','Tech/Apps']].map(([k,l]) => (
          <button key={k} onClick={() => setKind(k)} style={{
            flex:1, padding:'7px', borderRadius:6, border:'none', cursor:'pointer',
            background: kind===k ? 'linear-gradient(180deg,#16b89c,#0c7d6a)' : 'transparent',
            color: kind===k ? '#fff' : 'rgba(241,241,241,.6)',
            fontFamily:'var(--f-display)', fontSize:10, letterSpacing:'.08em', textTransform:'uppercase' }}>{l}</button>
        ))}
      </div>

      {/* Feed */}
      <div style={{ display:'flex', flexDirection:'column', gap:8 }}>
        {feed.map(x => {
          const hex = hexOf(x.core);
          const voted = votes[x.id];
          return (
            <div key={x.id} className="mm-panel" style={{ padding:'12px 12px', borderLeft:`3px solid ${hex}` }}>
              <div style={{ display:'flex', gap:10 }}>
                {/* upvote */}
                <button onClick={() => setVotes(v => ({ ...v, [x.id]: !v[x.id] }))}
                  style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:2,
                    background:'transparent', border:0, cursor:'pointer', flexShrink:0, width:34 }}>
                  <svg width="16" height="14" viewBox="0 0 16 14" fill={voted ? hex : 'none'}
                    stroke={voted ? hex : 'rgba(241,241,241,.5)'} strokeWidth="1.6" strokeLinejoin="round">
                    <path d="M8 2 L 14 11 L 2 11 Z" />
                  </svg>
                  <span className="t-num" style={{ fontSize:11, color: voted ? hex : 'rgba(241,241,241,.7)' }}>{x.up}</span>
                </button>
                <div style={{ flex:1, minWidth:0 }}>
                  <div style={{ display:'flex', alignItems:'center', gap:6, marginBottom:3 }}>
                    <span className="mm-chip" style={{ fontSize:8, letterSpacing:'.1em', color:hex, borderColor:`${hex}66` }}>
                      {IDEAS_CORES.find(c=>c.id===x.core)?.n.toUpperCase()}
                    </span>
                    <span style={{ fontSize:9, color:'rgba(241,241,241,.4)' }}>· {x.pain}</span>
                  </div>
                  <div style={{ fontSize:13, fontWeight:600, color:'#fff', lineHeight:1.3 }}>{x.title}</div>
                  <div style={{ fontSize:11, color:'rgba(241,241,241,.65)', marginTop:4, lineHeight:1.4 }}>{x.desc}</div>
                  <div style={{ display:'flex', alignItems:'center', gap:10, marginTop:8 }}>
                    <span style={{ fontSize:10, color:'rgba(241,241,241,.45)', fontFamily:'var(--f-mono)' }}>
                      {x.adopted.toLocaleString()} adopted
                    </span>
                    {x.link
                      ? <span style={{ fontSize:10, color:hex, fontFamily:'var(--f-display)', letterSpacing:'.06em' }}>↗ OPEN APP</span>
                      : <button onClick={() => setAdopt(x)} style={{
                          marginLeft:'auto', padding:'5px 10px', borderRadius:6, cursor:'pointer',
                          background:`${hex}22`, border:`1px solid ${hex}66`, color:'#fff',
                          fontSize:10, fontFamily:'var(--f-display)', letterSpacing:'.06em' }}>＋ ADD</button>}
                    {x.link && <button onClick={() => setAdopt(x)} style={{
                        marginLeft:'auto', padding:'5px 10px', borderRadius:6, cursor:'pointer',
                        background:`${hex}22`, border:`1px solid ${hex}66`, color:'#fff',
                        fontSize:10, fontFamily:'var(--f-display)', letterSpacing:'.06em' }}>＋ ADD</button>}
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Adopt customize sheet */}
      {adopt && (
        <div style={{ position:'absolute', inset:0, zIndex:40, background:'rgba(6,7,13,.85)',
            backdropFilter:'blur(8px)', display:'flex', flexDirection:'column', justifyContent:'flex-end' }}
          onClick={() => setAdopt(null)}>
          <div onClick={(e) => e.stopPropagation()} style={{
            background:'var(--mm-navy)', borderTop:`2px solid ${hexOf(adopt.core)}`,
            borderRadius:'16px 16px 0 0', padding:'18px 18px 28px' }}>
            <div className="t-display-x" style={{ fontSize:10, letterSpacing:'.16em',
              color:hexOf(adopt.core), marginBottom:10 }}>ADOPT &amp; CUSTOMIZE</div>
            <label style={{ display:'block', marginBottom:12 }}>
              <div style={{ fontSize:9, fontFamily:'var(--f-display)', letterSpacing:'.12em', color:'rgba(241,241,241,.5)', marginBottom:5 }}>NAME</div>
              <input defaultValue={adopt.title} style={{ width:'100%', padding:'10px 12px', borderRadius:8,
                background:'rgba(241,241,241,.05)', border:'1px solid rgba(241,241,241,.15)', color:'#fff',
                fontSize:13, outline:'none' }} />
            </label>
            <label style={{ display:'block', marginBottom:16 }}>
              <div style={{ fontSize:9, fontFamily:'var(--f-display)', letterSpacing:'.12em', color:'rgba(241,241,241,.5)', marginBottom:5 }}>FREQUENCY</div>
              <input defaultValue="Daily" style={{ width:'100%', padding:'10px 12px', borderRadius:8,
                background:'rgba(241,241,241,.05)', border:'1px solid rgba(241,241,241,.15)', color:'#fff',
                fontSize:13, outline:'none' }} />
            </label>
            <button onClick={() => { setToast(`✓ Added "${adopt.title.slice(0,24)}…" to your system`); setAdopt(null); }}
              className="mm-btn-primary" style={{ width:'100%', padding:'13px' }}>Add to my system →</button>
          </div>
        </div>
      )}

      {toast && (
        <div style={{ position:'absolute', left:14, right:14, bottom:18, zIndex:50,
          padding:'10px 14px', borderRadius:10, textAlign:'center',
          background:'rgba(0,169,143,.18)', border:'1px solid rgba(0,169,143,.55)',
          color:'#fff', fontSize:12, boxShadow:'0 8px 24px rgba(0,0,0,.4)' }}>{toast}</div>
      )}
    </div>
  );
}

// ─── Cantina hub: four-pillar segmented nav ───
function CantinaScreen(props) {
  const [tab, setTab] = React.useState('ideas');
  const TABS = [['ideas','Ideas Well'],['tribes','Tribes'],['board','Leaderboard'],['arena','Arena']];

  return (
    <ScreenShell title="Cantina" subtitle="COSMIC SOCIAL HUB" accent="var(--mm-teal)" {...props}>
      {/* Four-pillar nav */}
      <div style={{ display:'flex', gap:3, padding:3, borderRadius:9,
          background:'rgba(241,241,241,.06)', marginBottom:14 }}>
        {TABS.map(([k,l]) => (
          <button key={k} onClick={() => setTab(k)} style={{
            flex:1, padding:'8px 2px', borderRadius:7, border:'none', cursor:'pointer',
            background: tab===k ? 'linear-gradient(180deg,#16b89c,#0c7d6a)' : 'transparent',
            color: tab===k ? '#fff' : 'rgba(241,241,241,.55)',
            fontFamily:'var(--f-display)', fontSize:9, letterSpacing:'.04em', textTransform:'uppercase' }}>{l}</button>
        ))}
      </div>

      {tab === 'ideas' && <IdeasWell />}

      {tab === 'board' && (
        <>
          <div className="mm-panel" style={{ padding:'12px 14px', marginBottom:12 }}>
            <div className="t-display-x" style={{ fontSize:10, letterSpacing:'.18em', color:'rgba(241,241,241,.5)' }}>THIS WEEK'S TRIBE BOARD</div>
            <div style={{ display:'flex', flexDirection:'column', gap:8, marginTop:10 }}>
              {CREW.map((c, i) => (
                <button key={c.id} onClick={() => props.onNav?.(c.me ? 'profile' : `crew:${c.id}`)}
                  style={{ display:'flex', alignItems:'center', gap:10,
                    padding: c.me ? '6px 8px' : '4px 4px', borderRadius:8,
                    background: c.me ? 'rgba(255,198,41,.08)' : 'transparent',
                    border: c.me ? '1px solid rgba(255,198,41,.3)' : 'none',
                    width:'100%', cursor:'pointer', textAlign:'left' }}>
                  <span className="t-display t-num" style={{ fontSize:11, color:'rgba(241,241,241,.5)', width:16 }}>{i+1}</span>
                  <div style={{ position:'relative', width:30, height:30, borderRadius:'50%', background:c.hex, display:'grid', placeItems:'center', fontWeight:700, color:'#000', fontSize:13 }}>
                    {c.a}
                    {c.online && <span style={{ position:'absolute', bottom:-1, right:-1, width:10, height:10, borderRadius:'50%', background:'#00ff88', border:'2px solid #06070d' }} />}
                  </div>
                  <div style={{ flex:1, minWidth:0 }}>
                    <span style={{ fontSize:13, color:'#fff', fontWeight: c.me ? 700 : 500 }}>{c.n}</span>
                    <div style={{ fontSize:9, color:'rgba(241,241,241,.45)', fontFamily:'var(--f-mono)' }}>
                      {c.streak}🔥 · {c.cores.length} cores · {c.planet}
                    </div>
                  </div>
                  <span style={{ color:'#00ff88', fontSize:11 }}>▲</span>
                  <span className="t-display t-num" style={{ fontSize:12, color:c.hex }}>{c.s.toLocaleString()}</span>
                </button>
              ))}
            </div>
          </div>
          <div style={{ fontSize:10, color:'rgba(241,241,241,.4)', textAlign:'center',
            fontFamily:'var(--f-display)', letterSpacing:'.1em', lineHeight:1.6 }}>
            EVERY PILOT RISES · NO SHAME, JUST RIPPLES<br/>
            <span style={{ opacity:.7 }}>Tap a pilot to adopt their top habits</span>
          </div>
        </>
      )}

      {tab === 'tribes' && (
        <>
          <div className="t-display-x" style={{ fontSize:10, letterSpacing:'.18em', color:'rgba(241,241,241,.5)', margin:'0 2px 8px' }}>SQUAD THREADS · {THREADS.length}</div>
          {THREADS.map((t) => (
            <button key={t.id} onClick={() => props.onNav?.(`thread:${t.id}`)} className="mm-panel"
              style={{ padding:'12px 14px', display:'flex', gap:10, alignItems:'center', marginBottom:6,
                width:'100%', cursor:'pointer', textAlign:'left', border:'1px solid rgba(241,241,241,.08)' }}>
              <div style={{ width:32, height:32, borderRadius:'50%', background:t.hex, display:'grid', placeItems:'center', fontWeight:700, color:'#000' }}>{t.n[0]}</div>
              <div style={{ flex:1 }}>
                <div style={{ fontSize:13, fontWeight:600, color:'#fff' }}>{t.n}</div>
                <div style={{ fontSize:11, color:'rgba(241,241,241,.6)', marginTop:2 }}>{t.m}</div>
              </div>
              <span className="t-mono" style={{ fontSize:10, color:'rgba(241,241,241,.4)' }}>{t.time}</span>
            </button>
          ))}
          <button className="mm-btn-ghost" style={{ width:'100%', marginTop:8, padding:'12px' }}>+ Discover Tribes</button>
        </>
      )}

      {tab === 'arena' && (
        <div style={{ textAlign:'center', padding:'50px 20px' }}>
          <div style={{ fontSize:52 }}>⚔️</div>
          <div className="t-display" style={{ fontSize:18, color:'#fff', marginTop:12 }}>Weekly Arena</div>
          <div style={{ fontSize:12, color:'rgba(241,241,241,.6)', marginTop:8, lineHeight:1.5, maxWidth:240, margin:'8px auto 0' }}>
            Tribe-vs-tribe competitions, Core Sprints, and real-life rewards.
          </div>
          <span className="mm-chip" style={{ marginTop:16, display:'inline-block', color:'var(--mm-yellow)' }}>🚀 LAUNCHING SOON</span>
        </div>
      )}
    </ScreenShell>
  );
}

// ─── Crew member profile (read-only view of another Captain) ───
function CrewProfileScreen({ crewId, ...props }) {
  const c = CREW.find(x => x.id === crewId) || CREW[0];
  const cores = [
    { id:'mindset',       name:'Mind',     hex:'#2a7de1' },
    { id:'career',        name:'Career',   hex:'#FFC629' },
    { id:'relationships', name:'Connect',  hex:'#ff3d8b' },
    { id:'physical',      name:'Physical', hex:'#00a98f' },
    { id:'emotional',     name:'Emotion',  hex:'#9b5cff' },
  ];
  return (
    <ScreenShell title={c.n} subtitle={`${c.lvl} · ${c.online ? 'ONLINE' : 'OFFLINE'}`} accent={c.hex} {...props}>
      <div className="mm-panel mm-panel--accent" style={{ padding:'16px 14px', display:'flex', gap:12, alignItems:'center', marginBottom:14, borderColor:`${c.hex}66` }}>
        <div style={{
          width:60, height:60, borderRadius:'50%',
          background: c.hex,
          display:'grid', placeItems:'center', fontFamily:'var(--f-display)', fontSize:24, color:'#000', fontWeight:800,
          boxShadow:`0 0 16px ${c.hex}88`,
        }}>{c.a}</div>
        <div style={{ flex:1 }}>
          <div className="t-display" style={{ fontSize:16, color:'#fff' }}>{c.n}</div>
          <div className="t-display-x" style={{ fontSize:10, color:c.hex, letterSpacing:'.16em', marginTop:2 }}>
            {c.lvl} · ON {c.planet.toUpperCase()}
          </div>
          <div style={{ display:'flex', gap:6, marginTop:8 }}>
            <span className="mm-chip" style={{ color:'var(--mm-teal)' }}>{c.streak}🔥</span>
            <span className="mm-chip" style={{ color:'var(--mm-yellow)' }}>{c.s.toLocaleString()} MS</span>
          </div>
        </div>
      </div>

      <div className="mm-panel" style={{ padding:14, marginBottom:12 }}>
        <div className="t-display-x" style={{ fontSize:10, letterSpacing:'.18em', color:'rgba(241,241,241,.5)', marginBottom:10 }}>
          ACTIVE CORES · {c.cores.length}/5
        </div>
        <div style={{ display:'grid', gridTemplateColumns:'repeat(5, 1fr)', gap:6 }}>
          {cores.map((co) => {
            const on = c.cores.includes(co.id);
            return (
              <div key={co.id} style={{
                aspectRatio:'1/1', borderRadius:8,
                background: on ? `radial-gradient(circle at 30% 30%, ${co.hex}55, transparent 70%)` : 'rgba(241,241,241,.04)',
                border:`1px solid ${on ? co.hex+'77' : 'rgba(241,241,241,.1)'}`,
                display:'grid', placeItems:'center',
                fontSize:8, fontFamily:'var(--f-display)', letterSpacing:'.08em',
                color: on ? '#fff' : 'rgba(241,241,241,.3)',
                boxShadow: on ? `0 0 8px ${co.hex}55` : 'none',
              }}>{co.name.toUpperCase()}</div>
            );
          })}
        </div>
      </div>

      {/* Action row */}
      <div style={{ display:'flex', gap:8, marginBottom:14 }}>
        <button onClick={() => props.onNav?.(`thread:${c.id}`)} className="mm-btn-ghost" style={{ flex:1, padding:'12px', borderColor:`${c.hex}66`, color:c.hex }}>
          Message
        </button>
        <button className="mm-btn-ghost" style={{ flex:1, padding:'12px' }}>
          Challenge
        </button>
      </div>

      <div className="mm-panel" style={{ padding:14 }}>
        <div className="t-display-x" style={{ fontSize:10, letterSpacing:'.18em', color:'rgba(241,241,241,.5)', marginBottom:10 }}>RECENT TROPHIES</div>
        <div style={{ display:'flex', gap:6, flexWrap:'wrap' }}>
          {['🚀','🌙','🔥','⚡','🪐'].slice(0, Math.min(5, 1 + Math.floor(c.streak/14))).map((e, i) => (
            <div key={i} style={{
              width:42, height:42, borderRadius:8,
              background:`radial-gradient(circle at 30% 30%, ${c.hex}33, transparent 70%)`,
              border:`1px solid ${c.hex}55`, display:'grid', placeItems:'center', fontSize:18,
            }}>{e}</div>
          ))}
        </div>
      </div>
    </ScreenShell>
  );
}

// ─── Squad thread view (a 1:1 / group chat) ───
function ThreadScreen({ threadId, ...props }) {
  // If it's a crew member, find their thread; fall back to the thread list.
  let t = THREADS.find(x => x.id === threadId);
  if (!t) {
    const c = CREW.find(x => x.id === threadId);
    if (c) {
      t = { id: c.id, n: c.n, hex: c.hex, history: [
        { from:'them', text:`Hey ${c.me ? '' : '— this is ' + c.n.split(' ')[0]}` },
      ]};
    }
  }
  if (!t) t = THREADS[0];

  const [msgs, setMsgs] = React.useState(t.history);
  const [draft, setDraft] = React.useState('');
  const send = () => {
    if (!draft.trim()) return;
    setMsgs([...msgs, { from:'me', text: draft.trim() }]);
    setDraft('');
  };

  return (
    <div style={{ width:'100%', height:'100%', position:'relative', overflow:'hidden',
        background:'#06070d', paddingTop:56, display:'flex', flexDirection:'column' }}>
      <div className="mm-starfield" />
      <div className="mm-stars" />

      {/* header */}
      <div style={{ position:'relative', zIndex:5, display:'flex', alignItems:'center', gap:10,
          padding:'12px 18px 10px', borderBottom:`1px solid ${t.hex}33` }}>
        <button onClick={props.onBack} aria-label="Back" style={{
          background:'rgba(17,28,78,.55)', border:'1px solid rgba(241,241,241,.12)',
          borderRadius:10, width:36, height:36, color:'#fff', display:'grid', placeItems:'center', cursor:'pointer',
        }}>
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M10 3 L 4 8 L 10 13"/></svg>
        </button>
        <div style={{ width:34, height:34, borderRadius:'50%', background:t.hex, display:'grid', placeItems:'center', fontWeight:700, color:'#000' }}>
          {t.n[0]}
        </div>
        <div style={{ flex:1 }}>
          <div className="t-display" style={{ fontSize:14, color:'#fff' }}>{t.n}</div>
          <div style={{ fontSize:10, color:t.hex, letterSpacing:'.1em', fontFamily:'var(--f-display)' }}>SQUAD CHANNEL</div>
        </div>
      </div>

      {/* messages */}
      <div style={{ flex:1, overflow:'auto', padding:'14px',
          display:'flex', flexDirection:'column', gap:8, position:'relative', zIndex:4 }}>
        {msgs.map((m, i) => (
          <div key={i} style={{
            alignSelf: m.from === 'me' ? 'flex-end' : 'flex-start', maxWidth:'82%',
            padding:'9px 12px',
            borderRadius: m.from === 'me' ? '14px 14px 4px 14px' : '14px 14px 14px 4px',
            background: m.from === 'me'
              ? 'linear-gradient(180deg, #3a8dff 0%, #1f5fb8 100%)'
              : 'rgba(17,28,78,.7)',
            border: m.from === 'me' ? '1px solid rgba(77,155,255,.5)' : `1px solid ${t.hex}55`,
            color:'#fff', fontSize:13, lineHeight:1.4,
          }}>{m.text}</div>
        ))}
      </div>

      {/* composer */}
      <div style={{ padding:'10px 14px 24px', borderTop:'1px solid rgba(241,241,241,.06)',
          background:'rgba(6,7,13,.85)', display:'flex', gap:8, position:'relative', zIndex:5 }}>
        <input type="text" value={draft}
          onChange={(e) => setDraft(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && send()}
          placeholder="Message..."
          style={{ flex:1, background:'rgba(17,28,78,.6)', border:`1px solid ${t.hex}55`,
            borderRadius:999, padding:'10px 14px', color:'#fff', fontSize:13, outline:'none' }} />
        <button onClick={send} style={{
          width:40, height:40, borderRadius:'50%',
          background:'linear-gradient(180deg, #3a8dff, #1f5fb8)',
          border:`1px solid ${t.hex}66`, color:'#fff', display:'grid', placeItems:'center', cursor:'pointer',
        }}>
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M2 8 L 14 8 M 8 2 L 14 8 L 8 14" />
          </svg>
        </button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Trophy  —  Trophy Room (formed habits) + Achievements (badges)
// ─────────────────────────────────────────────────────────────
// Formed Golden Habits (14+ days @ 80%+) grouped by Core. Identity payoff.
const FORMED_HABITS = [
  { core:'mindset',       name:'Morning Mindset Ritual', days:62, date:'Apr 2' },
  { core:'mindset',       name:'Evening brain-dump',     days:31, date:'May 4' },
  { core:'career',        name:'Deep-work block · 90m',  days:88, date:'Mar 7' },
  { core:'physical',      name:'Strength training',      days:44, date:'Apr 20' },
  { core:'physical',      name:'8,000 steps',            days:21, date:'May 14' },
];
const TROPHY_CORES = [
  { id:'mindset',       name:'Mindset',            hex:'#2a7de1' },
  { id:'career',        name:'Career & Finances',  hex:'#FFC629' },
  { id:'relationships', name:'Relationships',      hex:'#ff3d8b' },
  { id:'physical',      name:'Physical Health',    hex:'#00a98f' },
  { id:'emotional',     name:'Emotional & Mental', hex:'#9b5cff' },
];

function TrophyScreen(props) {
  const [tab, setTab] = React.useState('trophies');
  const achievements = [
    { n:'First Launch',  desc:'Day 1 check-in', earned:true,  hex:'#2a7de1', icon:'🚀' },
    { n:'7-Day Burn',    desc:'Week streak',    earned:true,  hex:'#ea0029', icon:'🔥' },
    { n:'Moon Walker',   desc:'Reached Moon',   earned:true,  hex:'#cfd2dc', icon:'🌙' },
    { n:'Mars Lander',   desc:'Reached Mars',   earned:true,  hex:'#d76b3a', icon:'🔴' },
    { n:'Triple Core',   desc:'3 cores active', earned:true,  hex:'#FFC629', icon:'⚡' },
    { n:'Centurion',     desc:'100-day streak', earned:false, hex:'#9b5cff', icon:'💯' },
    { n:'Full Crew',     desc:'All 5 cores',    earned:false, hex:'#ff3d8b', icon:'⭐' },
    { n:'Pluto Pioneer', desc:'Reach Pluto',    earned:false, hex:'#00a98f', icon:'🛸' },
  ];
  const totalFormed = FORMED_HABITS.length;

  return (
    <ScreenShell title="Trophy Room" subtitle={tab === 'trophies' ? `FORMED · ${totalFormed}` : 'ACHIEVEMENTS · 5/8'}
      accent="var(--mm-yellow)" {...props}>
      {/* Segmented toggle */}
      <div style={{ display:'flex', gap:4, padding:3, borderRadius:10,
          background:'rgba(241,241,241,.06)', marginBottom:14 }}>
        {[['trophies','Trophy Room'],['badges','Achievements']].map(([k, lbl]) => (
          <button key={k} onClick={() => setTab(k)} style={{
            flex:1, padding:'9px', borderRadius:8, border:'none', cursor:'pointer',
            background: tab === k ? 'linear-gradient(180deg,#3a8dff,#1f5fb8)' : 'transparent',
            color: tab === k ? '#fff' : 'rgba(241,241,241,.6)',
            fontFamily:'var(--f-display)', fontSize:11, letterSpacing:'.1em', textTransform:'uppercase',
            boxShadow: tab === k ? '0 0 12px rgba(42,125,225,.4)' : 'none',
            transition:'all .2s',
          }}>{lbl}</button>
        ))}
      </div>

      {tab === 'trophies' && (
        <>
          {/* Summary */}
          <div className="mm-panel mm-panel--accent" style={{ padding:14, marginBottom:14 }}>
            <div className="t-display-x" style={{ fontSize:10, letterSpacing:'.18em', color:'var(--mm-yellow)' }}>FORMED HABITS</div>
            <div className="t-display t-num" style={{ fontSize:30, color:'#fff', marginTop:4 }}>{totalFormed}</div>
            <div style={{ fontSize:12, color:'rgba(241,241,241,.7)', marginTop:4, lineHeight:1.4 }}>
              {totalFormed} habits are now simply <b style={{color:'#fff'}}>who you are</b>.
            </div>
          </div>

          {/* Grouped by Core */}
          <div style={{ display:'flex', flexDirection:'column', gap:14 }}>
            {TROPHY_CORES.map((core) => {
              const items = FORMED_HABITS.filter(h => h.core === core.id);
              return (
                <div key={core.id}>
                  <div style={{ display:'flex', alignItems:'center', gap:8, marginBottom:8 }}>
                    <div className="mm-dot" style={{ background:core.hex, boxShadow:`0 0 6px ${core.hex}` }} />
                    <div className="t-display-x" style={{ fontSize:10, letterSpacing:'.16em', color:core.hex }}>
                      {core.name.toUpperCase()}
                    </div>
                    <div style={{ flex:1, height:1, background:`${core.hex}33` }} />
                    <span className="t-num" style={{ fontSize:10, color:'rgba(241,241,241,.4)' }}>{items.length}</span>
                  </div>
                  {items.length === 0 ? (
                    <div style={{ padding:'14px', borderRadius:8, textAlign:'center',
                        border:`1px dashed ${core.hex}33`, background:'rgba(241,241,241,.02)',
                        fontSize:11, color:'rgba(241,241,241,.45)' }}>
                      No trophies yet — keep building
                    </div>
                  ) : (
                    <div style={{ display:'flex', flexDirection:'column', gap:8 }}>
                      {items.map((h) => (
                        <div key={h.name} className="mm-panel" style={{
                          padding:'12px 14px', borderLeft:`3px solid ${core.hex}`,
                          display:'flex', alignItems:'center', gap:12,
                          boxShadow:`0 0 14px ${core.hex}22`,
                        }}>
                          <div style={{ width:38, height:38, borderRadius:'50%',
                            background:`radial-gradient(circle at 30% 30%, ${core.hex}, ${core.hex}66)`,
                            display:'grid', placeItems:'center', fontSize:18, flexShrink:0,
                            boxShadow:`0 0 12px ${core.hex}88` }}>🏆</div>
                          <div style={{ flex:1, minWidth:0 }}>
                            <div style={{ fontSize:13, fontWeight:600, color:'#fff' }}>{h.name}</div>
                            <div style={{ fontSize:10, color:'rgba(241,241,241,.5)', marginTop:3,
                              fontFamily:'var(--f-display)', letterSpacing:'.08em' }}>
                              FORMED {h.date.toUpperCase()} · {h.days} DAYS
                            </div>
                          </div>
                          <span className="mm-chip" style={{ color:'var(--state-formed)',
                            borderColor:'var(--state-formed)', fontSize:9, letterSpacing:'.1em' }}>FORMED</span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </>
      )}

      {tab === 'badges' && (
        <>
          <div className="mm-panel mm-panel--accent" style={{ padding:14, marginBottom:14 }}>
            <div className="t-display-x" style={{ fontSize:10, letterSpacing:'.18em', color:'var(--mm-yellow)' }}>PLANET CONQUEST</div>
            <div className="t-display t-num" style={{ fontSize:26, color:'#fff', marginTop:4 }}>3 / 7</div>
            <div style={{ height:6, borderRadius:3, background:'rgba(241,241,241,.1)', marginTop:10, overflow:'hidden' }}>
              <div style={{ height:'100%', width:'42%', background:'linear-gradient(90deg, var(--mm-blue), var(--mm-yellow))', boxShadow:'0 0 8px var(--mm-yellow)' }} />
            </div>
            <div style={{ fontSize:11, color:'rgba(241,241,241,.6)', marginTop:8 }}>Next target: <b style={{color:'#d9a86b'}}>Jupiter</b> · 33 days to arrival</div>
          </div>
          <div style={{ display:'grid', gridTemplateColumns:'repeat(2, 1fr)', gap:10 }}>
            {achievements.map((a) => (
              <div key={a.n} className="mm-panel" style={{
                padding:14, textAlign:'center',
                opacity: a.earned ? 1 : .35,
                borderColor: a.earned ? `${a.hex}66` : 'rgba(241,241,241,.08)',
                boxShadow: a.earned ? `0 0 16px ${a.hex}33` : 'none',
              }}>
                <div style={{ fontSize:28, filter: a.earned ? `drop-shadow(0 0 8px ${a.hex})` : 'grayscale(1)' }}>{a.icon}</div>
                <div className="t-display" style={{ fontSize:11, color:a.earned ? '#fff' : 'rgba(241,241,241,.5)', marginTop:6, letterSpacing:'.06em' }}>{a.n}</div>
                <div style={{ fontSize:9, color:'rgba(241,241,241,.5)', marginTop:2 }}>{a.desc}</div>
              </div>
            ))}
          </div>
        </>
      )}
    </ScreenShell>
  );
}

// ─────────────────────────────────────────────────────────────
// Profile  —  Identity card + lifetime stats + 5-core radar
// ─────────────────────────────────────────────────────────────
function ProfileScreen({ tweaks, ...props }) {
  const cores = [
    { id:'mindset', name:'MIND',    score:78, hex:'#2a7de1' },
    { id:'career',  name:'CAREER',  score:65, hex:'#FFC629' },
    { id:'relationships', name:'CONNECT', score:42, hex:'#ff3d8b' },
    { id:'physical',name:'PHYSICAL',score:81, hex:'#00a98f' },
    { id:'emotional',name:'EMOTION',score:54, hex:'#9b5cff' },
  ];
  // Radar geometry
  const cx = 110, cy = 110, R = 80, n = cores.length;
  const pts = cores.map((c, i) => {
    const a = -Math.PI/2 + (i / n) * Math.PI * 2;
    const r = (c.score/100) * R;
    return [cx + Math.cos(a)*r, cy + Math.sin(a)*r];
  });
  const ringPts = (mult) => cores.map((_, i) => {
    const a = -Math.PI/2 + (i / n) * Math.PI * 2;
    return [cx + Math.cos(a)*R*mult, cy + Math.sin(a)*R*mult].join(',');
  }).join(' ');

  return (
    <ScreenShell title="Profile" subtitle="CMDR · ALEX MOORE" accent="var(--mm-yellow)" {...props}>
      {/* identity */}
      <div className="mm-panel mm-panel--accent" style={{ padding:'16px 14px', display:'flex', gap:12, alignItems:'center', marginBottom:14 }}>
        <div style={{
          width:60, height:60, borderRadius:'50%',
          background:'radial-gradient(circle at 30% 30%, #FFC629, #ea0029)',
          display:'grid', placeItems:'center', fontFamily:'var(--f-display)', fontSize:24, color:'#000', fontWeight:800,
          boxShadow:'0 0 16px rgba(255,198,41,.55)',
        }}>A</div>
        <div style={{ flex:1 }}>
          <div className="t-display" style={{ fontSize:16, color:'#fff' }}>Alex Moore</div>
          <div className="t-display-x" style={{ fontSize:10, color:'var(--mm-yellow)', letterSpacing:'.16em', marginTop:2 }}>NAVIGATOR · LVL 12</div>
          <div style={{ display:'flex', gap:6, marginTop:8 }}>
            <span className="mm-chip" style={{ color:'var(--mm-teal)' }}>47🔥</span>
            <span className="mm-chip" style={{ color:'var(--mm-yellow)' }}>8,420 MS</span>
          </div>
        </div>
      </div>

      {/* radar */}
      <div className="mm-panel" style={{ padding:14, marginBottom:14 }}>
        <div className="t-display-x" style={{ fontSize:10, letterSpacing:'.18em', color:'rgba(241,241,241,.5)', marginBottom:8 }}>5-CORE BALANCE</div>
        <div style={{ display:'flex', justifyContent:'center' }}>
          <svg viewBox="0 0 220 220" width="220" height="220">
            {[0.25, 0.5, 0.75, 1].map((m, i) => (
              <polygon key={i} points={ringPts(m)} fill="none" stroke="rgba(241,241,241,.1)" strokeWidth=".5" />
            ))}
            {cores.map((c, i) => {
              const a = -Math.PI/2 + (i / n) * Math.PI * 2;
              return <line key={i} x1={cx} y1={cy} x2={cx + Math.cos(a)*R} y2={cy + Math.sin(a)*R} stroke="rgba(241,241,241,.08)" strokeWidth=".5" />;
            })}
            <polygon points={pts.map(p => p.join(',')).join(' ')}
                     fill="rgba(42,125,225,.18)" stroke="var(--mm-blue)" strokeWidth="1.5" />
            {pts.map(([x,y], i) => (
              <circle key={i} cx={x} cy={y} r="3" fill={cores[i].hex} style={{ filter:`drop-shadow(0 0 4px ${cores[i].hex})` }} />
            ))}
            {cores.map((c, i) => {
              const a = -Math.PI/2 + (i / n) * Math.PI * 2;
              const lx = cx + Math.cos(a)*(R+18), ly = cy + Math.sin(a)*(R+18);
              return (
                <text key={i} x={lx} y={ly} textAnchor="middle" dominantBaseline="middle"
                      fontSize="8" fontFamily="var(--f-display)" letterSpacing="1" fill={c.hex}>
                  {c.name} {c.score}
                </text>
              );
            })}
          </svg>
        </div>
      </div>

      {/* settings */}
      <div className="mm-panel" style={{ padding:'4px 0' }}>
        {[
          { label:'Notifications',       screen:'settings:notifications' },
          { label:'Connected calendars', screen:'settings:calendars' },
          { label:'Privacy',             screen:'settings:privacy' },
          { label:'Subscription · PRO',  screen:'settings:subscription' },
          { label:'Sign out',            screen:'signout' },
        ].map((s, i, arr) => (
          <button key={s.label}
            onClick={() => s.screen === 'signout' ? props.onSignOut?.() : props.onNav?.(s.screen)}
            style={{
              width:'100%', display:'flex', alignItems:'center', justifyContent:'space-between',
              padding:'12px 14px', background:'transparent',
              border:'none', textAlign:'left', cursor:'pointer',
              borderBottom: i < arr.length - 1 ? '1px solid rgba(241,241,241,.06)' : 'none',
              fontSize:13, color: s.screen === 'signout' ? 'var(--mm-red)' : '#fff',
            }}>
            <span>{s.label}</span>
            <svg width="10" height="14" viewBox="0 0 10 14" fill="none" stroke="rgba(241,241,241,.4)" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
              <path d="M2 2 L 8 7 L 2 12" />
            </svg>
          </button>
        ))}
      </div>
    </ScreenShell>
  );
}

// ─── Settings detail (generic, content per key) ───
function SettingsScreen({ settingsKey, ...props }) {
  const META = {
    notifications: { title:'Notifications', accent:'var(--mm-blue)', rows:[
      ['Daily check-in reminder', 'toggle', true],
      ['Streak-at-risk alert',    'toggle', true],
      ['Mystery Box drops',       'toggle', true],
      ['Tribe activity',          'toggle', false],
      ['Reminder time',           'time',  '7:00 AM'],
    ] },
    calendars: { title:'Connected Calendars', accent:'var(--mm-teal)', rows:[
      ['Google Calendar', 'value', 'Connected ✓'],
      ['Apple Calendar',  'value', 'Connect →'],
      ['Two-way sync',    'toggle', true],
      ['Auto-block habit time', 'toggle', false],
    ] },
    privacy: { title:'Privacy', accent:'var(--mm-violet)', rows:[
      ['Hide me from leaderboard', 'toggle', false],
      ['Share habits with tribe',  'toggle', true],
      ['Captain\u2019s Log encryption', 'value', 'On'],
      ['Export my data',           'value', 'Request →'],
      ['Delete account',           'value', 'Manage →'],
    ] },
    subscription: { title:'Subscription', accent:'var(--mm-yellow)', rows:[
      ['Current plan',     'value', 'PRO · Annual'],
      ['Renews',           'value', 'Mar 7, 2027'],
      ['Credit multiplier','value', '1.25×'],
      ['Manage billing',   'value', 'Open →'],
      ['Restore purchases','value', 'Restore →'],
    ] },
  };
  const m = META[settingsKey] || META.notifications;
  const [toggles, setToggles] = React.useState(
    Object.fromEntries(m.rows.filter(r => r[1] === 'toggle').map(r => [r[0], r[2]]))
  );
  const [times, setTimes] = React.useState(
    Object.fromEntries(m.rows.filter(r => r[1] === 'time').map(r => [r[0], r[2]]))
  );
  const [picker, setPicker] = React.useState(null); // row label currently editing

  const TIME_OPTIONS = [];
  for (let h = 5; h <= 22; h++) {
    for (const mm of ['00','30']) {
      const ap = h < 12 ? 'AM' : 'PM';
      const hh = h % 12 === 0 ? 12 : h % 12;
      TIME_OPTIONS.push(`${hh}:${mm} ${ap}`);
    }
  }

  return (
    <ScreenShell title={m.title} subtitle="SETTINGS" accent={m.accent} {...props}>
      <div className="mm-panel" style={{ padding:'4px 0' }}>
        {m.rows.map((r, i) => (
          <div key={r[0]} style={{
            display:'flex', alignItems:'center', justifyContent:'space-between',
            padding:'14px', fontSize:13, color:'#fff',
            borderBottom: i < m.rows.length - 1 ? '1px solid rgba(241,241,241,.06)' : 'none',
          }}>
            <span>{r[0]}</span>
            {r[1] === 'toggle' ? (
              <button onClick={() => setToggles(t => ({ ...t, [r[0]]: !t[r[0]] }))}
                style={{ width:42, height:24, borderRadius:999, border:'none', cursor:'pointer', position:'relative',
                  background: toggles[r[0]] ? m.accent : 'rgba(241,241,241,.18)', transition:'background .2s' }}>
                <span style={{ position:'absolute', top:3, left: toggles[r[0]] ? 21 : 3, width:18, height:18,
                  borderRadius:'50%', background:'#fff', transition:'left .2s', boxShadow:'0 1px 3px rgba(0,0,0,.3)' }} />
              </button>
            ) : r[1] === 'time' ? (
              <button onClick={() => setPicker(r[0])}
                style={{ display:'flex', alignItems:'center', gap:6, background:'rgba(241,241,241,.06)',
                  border:`1px solid ${m.accent}55`, borderRadius:8, padding:'6px 12px', cursor:'pointer',
                  color:m.accent, fontFamily:'var(--f-display)', fontSize:12, letterSpacing:'.04em' }}>
                {times[r[0]]}
                <svg width="10" height="6" viewBox="0 0 10 6" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M1 1 L 5 5 L 9 1"/></svg>
              </button>
            ) : (
              <span style={{ fontSize:12, color: m.accent, fontFamily:'var(--f-display)', letterSpacing:'.04em' }}>{r[2]}</span>
            )}
          </div>
        ))}
      </div>
      <div style={{ fontSize:11, color:'rgba(241,241,241,.4)', textAlign:'center', marginTop:16, lineHeight:1.5 }}>
        Settings are illustrative in this prototype.
      </div>

      {/* Time picker sheet */}
      {picker && (
        <div onClick={() => setPicker(null)} style={{ position:'absolute', inset:0, zIndex:40,
            background:'rgba(6,7,13,.85)', backdropFilter:'blur(8px)',
            display:'flex', flexDirection:'column', justifyContent:'flex-end' }}>
          <div onClick={(e) => e.stopPropagation()} style={{
            background:'var(--mm-navy)', borderTop:`2px solid ${m.accent}`,
            borderRadius:'16px 16px 0 0', padding:'16px 14px 24px', maxHeight:'62%',
            display:'flex', flexDirection:'column' }}>
            <div className="t-display-x" style={{ fontSize:10, letterSpacing:'.16em', color:m.accent,
              marginBottom:12, textAlign:'center' }}>{picker.toUpperCase()}</div>
            <div style={{ overflowY:'auto', display:'flex', flexDirection:'column', gap:4 }}>
              {TIME_OPTIONS.map((opt) => {
                const sel = times[picker] === opt;
                return (
                  <button key={opt} onClick={() => { setTimes(t => ({ ...t, [picker]: opt })); setPicker(null); }}
                    style={{ padding:'12px', borderRadius:8, cursor:'pointer', textAlign:'center',
                      background: sel ? `${m.accent}22` : 'transparent',
                      border: sel ? `1px solid ${m.accent}` : '1px solid transparent',
                      color: sel ? '#fff' : 'rgba(241,241,241,.7)',
                      fontFamily:'var(--f-display)', fontSize:14, letterSpacing:'.04em' }}>
                    {opt}{sel && '  ✓'}
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      )}
    </ScreenShell>
  );
}

// ─────────────────────────────────────────────────────────────
// AI Co-pilot  —  Chat overlay (Haiku-powered)
// ─────────────────────────────────────────────────────────────
function ChatScreen({ onBack }) {
  const [messages, setMessages] = React.useState([
    { role:'ai', text:"I'm your Co-pilot. I see you're 47 days deep and crushing Mindset & Physical. What do you want to work on right now?" },
  ]);
  const [draft, setDraft] = React.useState('');
  const [thinking, setThinking] = React.useState(false);
  const scrollRef = React.useRef(null);

  React.useEffect(() => {
    if (scrollRef.current) scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
  }, [messages, thinking]);

  const send = async () => {
    const text = draft.trim();
    if (!text || thinking) return;
    setMessages((m) => [...m, { role:'me', text }]);
    setDraft('');
    setThinking(true);
    try {
      const system = "You are Co-pilot, the AI assistant inside Moore Momentum — a gamified self-development app built around 5 Cores (Mindset, Career & Finances, Relationships, Physical Health, Emotional Health), streaks, planets, and a Momentum Score. Be warm, sharp, and concise (2-4 sentences). Reference Cores and the rocket metaphor when natural. Never use markdown.";
      const reply = await window.claude.complete({
        messages: [
          { role:'user', content: `${system}\n\nUser: ${text}` },
        ],
      });
      setMessages((m) => [...m, { role:'ai', text: reply }]);
    } catch (e) {
      setMessages((m) => [...m, { role:'ai', text:'Signal lost. Try again in a moment.' }]);
    }
    setThinking(false);
  };

  const suggestions = ['Plan my day', 'Why did I miss yesterday?', 'How do I level up?', 'Boost Relationships'];

  return (
    <div style={{
      width:'100%', height:'100%', position:'relative', overflow:'hidden',
      background:'#06070d', paddingTop:56, display:'flex', flexDirection:'column',
    }}>
      <div className="mm-starfield" />
      <div className="mm-stars" />

      {/* header */}
      <div style={{
        position:'relative', zIndex:5, display:'flex', alignItems:'center',
        gap:10, padding:'14px 18px 12px', borderBottom:'1px solid rgba(155,92,255,.18)',
      }}>
        <button onClick={onBack} aria-label="Close" style={{
          background:'rgba(17,28,78,.55)', border:'1px solid rgba(241,241,241,.12)',
          borderRadius:10, width:36, height:36, color:'#fff', display:'grid', placeItems:'center', cursor:'pointer',
        }}>
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M4 4 L 12 12 M 12 4 L 4 12" />
          </svg>
        </button>
        <div style={{ display:'flex', alignItems:'center', gap:10, flex:1 }}>
          <div style={{
            width:36, height:36, borderRadius:'50%',
            background:'radial-gradient(circle at 30% 30%, #b58aff, #2a7de1 70%)',
            display:'grid', placeItems:'center',
            boxShadow:'0 0 14px rgba(155,92,255,.7)',
          }}>
            <svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke="#fff" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
              <path d="M9 1 L 11 5 L 15 6 L 12 9 L 13 14 L 9 11.5 L 5 14 L 6 9 L 3 6 L 7 5 Z" />
            </svg>
          </div>
          <div>
            <div className="t-display" style={{ fontSize:14, color:'#fff' }}>Co-pilot</div>
            <div style={{ fontSize:10, color:'#00ff88', display:'flex', alignItems:'center', gap:4 }}>
              <span style={{ width:6, height:6, borderRadius:'50%', background:'#00ff88', boxShadow:'0 0 6px #00ff88' }} />
              ONLINE · HAIKU
            </div>
          </div>
        </div>
      </div>

      {/* messages */}
      <div ref={scrollRef} style={{
        flex:1, overflow:'auto', padding:'14px 14px 8px',
        display:'flex', flexDirection:'column', gap:10, position:'relative', zIndex:4,
      }}>
        {messages.map((m, i) => (
          <div key={i} style={{
            alignSelf: m.role === 'me' ? 'flex-end' : 'flex-start',
            maxWidth:'82%',
            padding:'10px 14px',
            borderRadius: m.role === 'me' ? '14px 14px 4px 14px' : '14px 14px 14px 4px',
            background: m.role === 'me'
              ? 'linear-gradient(180deg, #3a8dff 0%, #1f5fb8 100%)'
              : 'rgba(17,28,78,.7)',
            border: m.role === 'me' ? '1px solid rgba(77,155,255,.5)' : '1px solid rgba(155,92,255,.3)',
            color:'#fff', fontSize:13, lineHeight:1.45,
            boxShadow: m.role === 'me'
              ? '0 0 12px rgba(42,125,225,.4)'
              : '0 0 12px rgba(155,92,255,.15)',
          }}>
            {m.text}
          </div>
        ))}
        {thinking && (
          <div style={{ alignSelf:'flex-start', padding:'10px 14px', borderRadius:'14px 14px 14px 4px',
            background:'rgba(17,28,78,.7)', border:'1px solid rgba(155,92,255,.3)',
            display:'flex', gap:5 }}>
            {[0,1,2].map(i => (
              <span key={i} style={{
                width:6, height:6, borderRadius:'50%', background:'#9b5cff',
                animation:`mm-flame 1s ease-in-out ${i*0.15}s infinite`,
                boxShadow:'0 0 6px #9b5cff',
              }} />
            ))}
          </div>
        )}
      </div>

      {/* quick suggestions */}
      {messages.length < 3 && (
        <div style={{ display:'flex', gap:6, overflowX:'auto', padding:'4px 14px 8px', position:'relative', zIndex:5 }}>
          {suggestions.map((s) => (
            <button key={s} onClick={() => setDraft(s)} style={{
              flexShrink:0, padding:'6px 10px', borderRadius:999,
              background:'rgba(155,92,255,.12)', border:'1px solid rgba(155,92,255,.4)',
              color:'#d8c0ff', fontSize:11, cursor:'pointer', whiteSpace:'nowrap',
            }}>{s}</button>
          ))}
        </div>
      )}

      {/* composer */}
      <div style={{
        padding:'10px 14px 24px', borderTop:'1px solid rgba(241,241,241,.06)',
        background:'rgba(6,7,13,.85)', backdropFilter:'blur(10px)',
        display:'flex', gap:8, position:'relative', zIndex:5,
      }}>
        <input type="text" value={draft}
               onChange={(e) => setDraft(e.target.value)}
               onKeyDown={(e) => e.key === 'Enter' && send()}
               placeholder="Ask Co-pilot anything..."
               style={{
                 flex:1, background:'rgba(17,28,78,.6)', border:'1px solid rgba(155,92,255,.3)',
                 borderRadius:999, padding:'10px 14px', color:'#fff', fontSize:13, outline:'none',
                 fontFamily:'var(--f-body)',
               }} />
        <button onClick={send} disabled={!draft.trim() || thinking} style={{
          width:40, height:40, borderRadius:'50%',
          background: draft.trim() ? 'linear-gradient(180deg, #b58aff, #6b3df5)' : 'rgba(155,92,255,.2)',
          border:'1px solid rgba(155,92,255,.5)',
          color:'#fff', display:'grid', placeItems:'center', cursor: draft.trim() ? 'pointer' : 'default',
          boxShadow: draft.trim() ? '0 0 14px rgba(155,92,255,.55)' : 'none',
        }}>
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M2 8 L 14 8 M 8 2 L 14 8 L 8 14" />
          </svg>
        </button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Menu drawer  —  Slide-out from hamburger; deep navigation
// ─────────────────────────────────────────────────────────────
function MenuDrawer({ onNav, onClose, onChat, account, onAuth, onSignOut }) {
  const groups = [
    { label:'PHASE 1 · BUILD', items:[
      { k:'phase1', n:'Foundation Hub', hex:'#FFC629' },
    ]},
    { label:'COCKPIT', items:[
      { k:'dashboard', n:'Dashboard',   hex:'#2a7de1' },
      { k:'checkin',   n:'Daily Check-in', hex:'#FFC629' },
      { k:'summary',   n:'Today\'s Recap',  hex:'#9b5cff' },
      { k:'balance',   n:'Balance Meter', hex:'#FFC629' },
      { k:'level',     n:'Rank Progress', hex:'#2a7de1' },
      { k:'quests',    n:'Missions',     hex:'#FFC629' },
      { k:'upgrades',  n:'Ship Bay',     hex:'#2a7de1' },
    ]},
    { label:'WORK', items:[
      { k:'lists',    n:'Lists',     hex:'#2a7de1' },
      { k:'routines', n:'Routines',  hex:'#00a98f' },
      { k:'habits',   n:'Habits',    hex:'#ff3d8b' },
      { k:'tasks',    n:'Tasks',     hex:'#FFC629' },
    ]},
    { label:'CREW', items:[
      { k:'cantina',  n:'Cantina',   hex:'#00a98f' },
      { k:'trophy',   n:'Trophy Room', hex:'#FFC629' },
      { k:'profile',  n:'Profile',   hex:'#FFC629' },
    ]},
  ];
  return (
    <div style={{
      position:'absolute', inset:0, zIndex:60,
      display:'flex',
    }}>
      <div style={{
        width:'80%', height:'100%', background:'rgba(6,7,13,.96)',
        backdropFilter:'blur(24px)',
        borderRight:'1px solid rgba(77,155,255,.3)',
        padding:'56px 0 20px',
        overflow:'auto',
        animation:'mm-revealUp .35s ease-out',
        boxShadow:'8px 0 40px rgba(0,0,0,.6)',
      }}>
        <div style={{ padding:'8px 20px 16px', display:'flex', alignItems:'center', justifyContent:'space-between' }}>
          <div className="t-display-x" style={{ fontSize:13, color:'var(--mm-yellow)', letterSpacing:'.18em' }}>MOORE MOMENTUM</div>
          <button onClick={onClose} aria-label="Close menu" style={{
            background:'transparent', border:'1px solid rgba(241,241,241,.2)',
            borderRadius:8, width:30, height:30, color:'#fff', cursor:'pointer',
            display:'grid', placeItems:'center',
          }}>
            <svg width="12" height="12" viewBox="0 0 12 12" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
              <path d="M2 2 L 10 10 M 10 2 L 2 10" />
            </svg>
          </button>
        </div>

        <button onClick={() => { onClose(); onChat(); }} style={{
          margin:'8px 16px 18px', padding:'14px',
          width:'calc(100% - 32px)', display:'flex', alignItems:'center', gap:12,
          background:'linear-gradient(180deg, rgba(155,92,255,.3), rgba(42,125,225,.2))',
          border:'1px solid rgba(155,92,255,.5)', borderRadius:12, color:'#fff', cursor:'pointer',
          boxShadow:'0 0 18px rgba(155,92,255,.35)',
        }}>
          <div style={{
            width:38, height:38, borderRadius:'50%',
            background:'radial-gradient(circle at 30% 30%, #b58aff, #2a7de1)',
            display:'grid', placeItems:'center',
          }}>
            <svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke="#fff" strokeWidth="1.8" strokeLinejoin="round">
              <path d="M9 1 L 11 5 L 15 6 L 12 9 L 13 14 L 9 11.5 L 5 14 L 6 9 L 3 6 L 7 5 Z" />
            </svg>
          </div>
          <div style={{ textAlign:'left' }}>
            <div className="t-display" style={{ fontSize:13, color:'#fff' }}>Ask Co-pilot</div>
            <div style={{ fontSize:10, color:'rgba(216,192,255,.8)', marginTop:2 }}>AI mission assistant</div>
          </div>
        </button>

        {groups.map((g) => (
          <div key={g.label} style={{ marginBottom:14 }}>
            <div className="t-display-x" style={{ fontSize:10, color:'rgba(241,241,241,.45)', letterSpacing:'.18em', padding:'0 20px 6px' }}>{g.label}</div>
            {g.items.map((it) => (
              <button key={it.k} onClick={() => { onClose(); onNav(it.k); }} style={{
                width:'100%', display:'flex', alignItems:'center', gap:10,
                padding:'10px 20px', background:'transparent', border:'none',
                color:'#fff', textAlign:'left', cursor:'pointer', fontSize:13,
              }}>
                <span className="mm-dot" style={{ background:it.hex, boxShadow:`0 0 6px ${it.hex}` }} />
                {it.n}
              </button>
            ))}
          </div>
        ))}

        {/* Account footer */}
        <div style={{ borderTop:'1px solid rgba(241,241,241,.08)', marginTop:10, padding:'14px 20px 4px' }}>
          <div className="t-display-x" style={{ fontSize:10, color:'rgba(241,241,241,.45)', letterSpacing:'.18em', marginBottom:8 }}>ACCOUNT</div>
          {!account && (
            <button onClick={onAuth} style={{
              width:'100%', display:'flex', alignItems:'center', gap:10, padding:'10px 0',
              background:'transparent', border:'none', color:'var(--mm-yellow)', cursor:'pointer', fontSize:13, textAlign:'left',
            }}>
              <span className="mm-dot" style={{ background:'var(--mm-yellow)', boxShadow:'0 0 6px var(--mm-yellow)' }} />
              Sign in / Create account
            </button>
          )}
          {account && (
            <>
              <div style={{ display:'flex', alignItems:'center', gap:10, padding:'4px 0 10px' }}>
                <div style={{ width:30, height:30, borderRadius:'50%',
                  background: account.isGuest ? 'rgba(241,241,241,.18)' : 'radial-gradient(circle at 30% 30%, #FFC629, #ea0029)',
                  display:'grid', placeItems:'center', fontWeight:700, color: account.isGuest ? '#fff' : '#000', fontSize:12 }}>
                  {account.displayName[0].toUpperCase()}
                </div>
                <div style={{ flex:1, minWidth:0 }}>
                  <div style={{ fontSize:13, color:'#fff', fontWeight:600, overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap' }}>{account.displayName}</div>
                  <div style={{ fontSize:10, color: account.isGuest ? 'var(--mm-yellow)' : 'rgba(241,241,241,.5)', marginTop:2, fontFamily:'var(--f-display)', letterSpacing:'.12em' }}>
                    {account.isGuest ? 'GUEST · TEMPORARY' : (account.email || 'SIGNED IN')}
                  </div>
                </div>
              </div>
              {account.isGuest && (
                <button onClick={onAuth} style={{
                  width:'100%', display:'flex', alignItems:'center', gap:10, padding:'10px 0',
                  background:'transparent', border:'none', color:'var(--mm-yellow)', cursor:'pointer', fontSize:13, textAlign:'left',
                }}>
                  <span className="mm-dot" style={{ background:'var(--mm-yellow)', boxShadow:'0 0 6px var(--mm-yellow)' }} />
                  Create permanent account
                </button>
              )}
              <button onClick={onSignOut} style={{
                width:'100%', display:'flex', alignItems:'center', gap:10, padding:'10px 0',
                background:'transparent', border:'none', color:'var(--mm-red)', cursor:'pointer', fontSize:13, textAlign:'left',
              }}>
                <span className="mm-dot" style={{ background:'var(--mm-red)', boxShadow:'0 0 6px var(--mm-red)' }} />
                Sign out
              </button>
            </>
          )}
        </div>
      </div>
      <div onClick={onClose} style={{ flex:1, background:'rgba(0,0,0,.5)', cursor:'pointer' }} />
    </div>
  );
}

Object.assign(window, {
  ListsScreen, RoutinesScreen, TasksScreen,
  CantinaScreen, TrophyScreen, ProfileScreen, SettingsScreen,
  CrewProfileScreen, ThreadScreen,
  ChatScreen, MenuDrawer, ScreenShell,
});
