// web-screens.jsx — Desktop layouts for the secondary destinations.
// Reuses the space vocabulary (mm-panel, cores, chips) in spacious multi-column
// grids. Rendered inside the WebShell content column at ≥1000px.

// ── shared section header inside a desktop screen ──
function WebSection({ title, meta, accent = '#fff', children, action }) {
  return (
    <section style={{ marginBottom: 30 }}>
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', margin: '0 2px 14px' }}>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 10 }}>
          <span className="t-display-x" style={{ fontSize: 12, letterSpacing: '.16em', color: '#fff' }}>{title}</span>
          {meta && <span className="t-display-x" style={{ fontSize: 9, letterSpacing: '.14em', color: accent }}>{meta}</span>}
        </div>
        {action}
      </div>
      {children}
    </section>
  );
}

const WEB_CORE_HEX = { mindset: '#2a7de1', career: '#FFC629', relationships: '#ff3d8b', physical: '#00a98f', emotional: '#9b5cff' };
const WEB_CORE_ICON = { mindset: '🧠', career: '💰', relationships: '👥', physical: '💪', emotional: '🧘' };

// ═══════════════════════════════════════════════════════════════
// ROUTINES — full routines list (routine vs non-routine), desktop
// ═══════════════════════════════════════════════════════════════
function WebRoutines({ onNav }) {
  const TIME_BLOCKS = [
    { id: 'morning', name: 'Launch Sequence', time: '06:30', label: 'MORNING' },
    { id: 'workday', name: 'Deep Work Block', time: '09:00', label: 'WORKDAY' },
    { id: 'evening', name: 'Re-entry',        time: '21:00', label: 'EVENING' },
  ];
  const STAGE = { bad: { hex: '#ea0029', label: 'Bad' }, forming: { hex: '#FFC629', label: 'Forming' }, formed: { hex: '#00a98f', label: 'Formed' } };
  const [routine, setRoutine] = React.useState([
    { id: 'r1', name: 'Hydrate', core: 'physical', block: 'morning', stage: 'formed' },
    { id: 'r2', name: '10-min journal', core: 'mindset', block: 'morning', stage: 'formed' },
    { id: 'r3', name: 'Stretch', core: 'physical', block: 'morning', stage: 'forming' },
    { id: 'r4', name: 'Email triage', core: 'career', block: 'workday', stage: 'formed' },
    { id: 'r5', name: '2h focus block', core: 'career', block: 'workday', stage: 'forming' },
    { id: 'r6', name: 'Walk break', core: 'physical', block: 'workday', stage: 'forming' },
    { id: 'r7', name: 'Day review', core: 'mindset', block: 'evening', stage: 'forming' },
    { id: 'r8', name: 'Read 20m', core: 'emotional', block: 'evening', stage: 'bad' },
    { id: 'r9', name: 'Lights down', core: 'physical', block: 'evening', stage: 'formed' },
  ]);
  const [nonRoutine, setNonRoutine] = React.useState([
    { id: 'n1', name: 'Strength Block', core: 'physical', stage: 'forming' },
    { id: 'n2', name: 'Weekly friend check-in', core: 'relationships', stage: 'forming' },
    { id: 'n3', name: 'Money dashboard review', core: 'career', stage: 'bad' },
  ]);
  const [adding, setAdding] = React.useState(false);
  const cycle = (list, set) => (id) => {
    const order = ['bad', 'forming', 'formed'];
    set(list.map(h => h.id === id ? { ...h, stage: order[(order.indexOf(h.stage) + 1) % 3] } : h));
  };
  const formed = routine.filter(h => h.stage === 'formed').length;

  const Row = ({ h, onClick }) => {
    const st = STAGE[h.stage]; const isFormed = h.stage === 'formed';
    return (
      <button onClick={onClick} style={{ width: '100%', textAlign: 'left', cursor: 'pointer',
        display: 'flex', alignItems: 'center', gap: 11, padding: '11px 13px', borderRadius: 10,
        background: isFormed ? 'rgba(0,169,143,.13)' : 'rgba(17,28,78,.4)',
        border: `1px solid ${isFormed ? 'rgba(0,169,143,.45)' : 'rgba(241,241,241,.1)'}` }}>
        <span style={{ width: 11, height: 11, borderRadius: '50%', background: st.hex, boxShadow: `0 0 8px ${st.hex}`, flexShrink: 0 }} />
        <span style={{ flex: 1, minWidth: 0 }}>
          <span style={{ display: 'block', fontSize: 13, color: isFormed ? '#fff' : 'rgba(241,241,241,.9)', fontWeight: isFormed ? 600 : 400 }}>{h.name}</span>
          <span className="t-display-x" style={{ fontSize: 8, letterSpacing: '.12em', color: st.hex }}>{st.label.toUpperCase()}{isFormed && ' · GREEN'}</span>
        </span>
        <span style={{ display: 'flex', alignItems: 'center', gap: 5, flexShrink: 0, padding: '4px 8px', borderRadius: 999,
          background: `${WEB_CORE_HEX[h.core]}1a`, border: `1px solid ${WEB_CORE_HEX[h.core]}44` }}>
          <span style={{ fontSize: 11 }}>{WEB_CORE_ICON[h.core]}</span>
        </span>
      </button>
    );
  };

  return (
    <div style={{ padding: '4px 40px 56px' }}>
      <WebSection title="ROUTINE" meta={`${formed}/${routine.length} GREEN · THE SEA OF GREEN`} accent="var(--mm-teal)"
        action={<button className="mm-btn-ghost" onClick={() => setAdding(true)} style={{ padding: '9px 16px' }}>+ Add habit</button>}>
        <div style={{ height: 5, borderRadius: 3, background: 'rgba(241,241,241,.08)', overflow: 'hidden', marginBottom: 18 }}>
          <div style={{ width: `${Math.round(formed / routine.length * 100)}%`, height: '100%',
            background: 'linear-gradient(90deg, var(--mm-teal), #00c9a7)', boxShadow: '0 0 8px rgba(0,169,143,.7)' }} />
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 18 }}>
          {TIME_BLOCKS.map(b => (
            <div key={b.id} className="mm-panel" style={{ padding: 16 }}>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginBottom: 12 }}>
                <span className="t-display" style={{ fontSize: 14, color: '#fff' }}>{b.name}</span>
              </div>
              <div className="t-display-x" style={{ fontSize: 8.5, letterSpacing: '.14em', color: 'var(--mm-teal)', marginBottom: 12 }}>{b.label} · {b.time}</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 7 }}>
                {routine.filter(h => h.block === b.id).map(h => <Row key={h.id} h={h} onClick={() => cycle(routine, setRoutine)(h.id)} />)}
              </div>
            </div>
          ))}
        </div>
      </WebSection>

      <WebSection title="NON-ROUTINE" meta="IDENTITY HABITS → TROPHY ROOM" accent="var(--mm-yellow)">
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 18, alignItems: 'start' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 7 }}>
            <div style={{ fontSize: 12, color: 'rgba(241,241,241,.6)', lineHeight: 1.5, marginBottom: 4 }}>
              Active in your daily check-in. When formed (14d · 80%) they graduate to the Trophy Room.
            </div>
            {nonRoutine.map(h => <Row key={h.id} h={h} onClick={() => cycle(nonRoutine, setNonRoutine)(h.id)} />)}
          </div>
          <button onClick={() => onNav('trophy')} className="mm-panel" style={{ padding: 20, cursor: 'pointer', textAlign: 'left',
            borderColor: 'rgba(255,198,41,.4)', background: 'linear-gradient(135deg, rgba(255,198,41,.12), transparent 70%)' }}>
            <div style={{ fontSize: 30 }}>🏆</div>
            <div style={{ fontSize: 16, color: '#fff', fontWeight: 600, marginTop: 8 }}>2 formed → Trophy Room</div>
            <div style={{ fontSize: 12, color: 'rgba(241,241,241,.6)', marginTop: 4 }}>Permanent identity markers, organized by Core. Tap to view →</div>
          </button>
        </div>
      </WebSection>

      {adding && <WebAddHabit onClose={() => setAdding(false)} onSave={(d) => {
        const rec = { id: 'h' + Date.now(), ...d };
        if (d.type === 'routine') setRoutine(r => [...r, rec]); else setNonRoutine(r => [...r, rec]);
        setAdding(false);
      }} />}
    </div>
  );
}

// desktop add-habit modal
function WebAddHabit({ onClose, onSave }) {
  const [name, setName] = React.useState('');
  const [type, setType] = React.useState('routine');
  const [block, setBlock] = React.useState('morning');
  const [core, setCore] = React.useState('physical');
  const canSave = name.trim().length > 0;
  return (
    <div onClick={onClose} style={{ position: 'fixed', inset: 0, zIndex: 200, background: 'rgba(6,7,13,.8)',
      backdropFilter: 'blur(8px)', display: 'grid', placeItems: 'center', padding: 24 }}>
      <div onClick={e => e.stopPropagation()} className="mm-panel" style={{ width: 480, maxWidth: '100%', padding: 26,
        background: 'rgba(13,19,48,.96)' }}>
        <div className="t-display-x" style={{ fontSize: 12, letterSpacing: '.18em', color: 'var(--mm-teal)', marginBottom: 18 }}>ADD A HABIT</div>
        <label className="t-display-x" style={{ fontSize: 9, letterSpacing: '.16em', color: 'rgba(241,241,241,.55)' }}>HABIT NAME</label>
        <input autoFocus value={name} onChange={e => setName(e.target.value)} placeholder="e.g. 10-minute morning walk"
          style={{ width: '100%', margin: '6px 0 16px', padding: '12px 14px', borderRadius: 10,
            background: 'rgba(17,28,78,.55)', border: '1px solid rgba(0,169,143,.4)', color: '#fff', fontSize: 14, outline: 'none' }} />
        <div className="t-display-x" style={{ fontSize: 9, letterSpacing: '.16em', color: 'rgba(241,241,241,.55)', marginBottom: 6 }}>TYPE</div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: 16 }}>
          {[['routine', 'Routine', 'Daily schedule. Turns green & stays.'], ['non_routine', 'Non-routine', 'Identity habit. Graduates to Trophy.']].map(([id, nm, ds]) => {
            const on = type === id;
            return (
              <button key={id} onClick={() => setType(id)} style={{ textAlign: 'left', padding: '11px 13px', borderRadius: 10, cursor: 'pointer',
                background: on ? 'rgba(0,169,143,.18)' : 'rgba(17,28,78,.45)', border: on ? '1.5px solid var(--mm-teal)' : '1px solid rgba(241,241,241,.12)' }}>
                <div className="t-display" style={{ fontSize: 13, color: on ? '#fff' : 'rgba(241,241,241,.8)' }}>{nm}</div>
                <div style={{ fontSize: 10, color: 'rgba(241,241,241,.6)', marginTop: 3 }}>{ds}</div>
              </button>
            );
          })}
        </div>
        {type === 'routine' && (
          <div style={{ marginBottom: 16 }}>
            <div className="t-display-x" style={{ fontSize: 9, letterSpacing: '.16em', color: 'rgba(241,241,241,.55)', marginBottom: 6 }}>WHEN</div>
            <div style={{ display: 'flex', gap: 6 }}>
              {[['morning', 'MORNING'], ['workday', 'WORKDAY'], ['evening', 'EVENING']].map(([id, l]) => {
                const on = block === id;
                return <button key={id} onClick={() => setBlock(id)} style={{ flex: 1, padding: '9px', borderRadius: 9, cursor: 'pointer',
                  background: on ? 'rgba(0,169,143,.18)' : 'rgba(17,28,78,.45)', border: on ? '1.5px solid var(--mm-teal)' : '1px solid rgba(241,241,241,.12)',
                  color: on ? '#fff' : 'rgba(241,241,241,.7)', fontFamily: 'var(--f-display)', fontSize: 8.5, letterSpacing: '.12em' }}>{l}</button>;
              })}
            </div>
          </div>
        )}
        <div className="t-display-x" style={{ fontSize: 9, letterSpacing: '.16em', color: 'rgba(241,241,241,.55)', marginBottom: 6 }}>CORE</div>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginBottom: 22 }}>
          {Object.keys(WEB_CORE_HEX).map(id => {
            const on = core === id; const hex = WEB_CORE_HEX[id];
            return <button key={id} onClick={() => setCore(id)} style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '8px 11px', borderRadius: 999, cursor: 'pointer',
              background: on ? `${hex}22` : 'rgba(17,28,78,.45)', border: on ? `1.5px solid ${hex}` : '1px solid rgba(241,241,241,.12)',
              color: on ? '#fff' : 'rgba(241,241,241,.75)', fontSize: 12, textTransform: 'capitalize' }}>{WEB_CORE_ICON[id]} {id}</button>;
          })}
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button onClick={onClose} className="mm-btn-ghost" style={{ flex: 1, padding: 13 }}>Cancel</button>
          <button disabled={!canSave} onClick={() => onSave({ name: name.trim(), type, core, block: type === 'routine' ? block : null, stage: 'bad' })}
            className="mm-btn-primary" style={{ flex: 1.4, padding: 13, opacity: canSave ? 1 : .4, cursor: canSave ? 'pointer' : 'not-allowed' }}>Add Habit</button>
        </div>
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// TROPHY — formed habits by core + achievements
// ═══════════════════════════════════════════════════════════════
function WebTrophy() {
  const formed = [
    { name: 'Morning Hydration', core: 'physical', days: 62 },
    { name: 'Daily Journaling', core: 'mindset', days: 48 },
    { name: 'Inbox Zero', core: 'career', days: 31 },
    { name: 'Evening Wind-down', core: 'physical', days: 22 },
  ];
  const badges = [
    { n: 'First Launch', desc: 'Day 1 check-in', earned: true, hex: '#2a7de1', icon: '🚀' },
    { n: '7-Day Burn', desc: 'Week streak', earned: true, hex: '#ea0029', icon: '🔥' },
    { n: 'Core Balance', desc: 'All 5 cores active', earned: true, hex: '#00a98f', icon: '⚖️' },
    { n: 'Habit Forged', desc: 'First formed habit', earned: true, hex: '#FFC629', icon: '🛠️' },
    { n: 'Navigator', desc: 'Reach Mars', earned: true, hex: '#ff3d8b', icon: '🪐' },
    { n: 'Centurion', desc: '100-day streak', earned: false, hex: '#9b5cff', icon: '💯' },
    { n: 'Constellation', desc: '10 formed habits', earned: false, hex: '#2a7de1', icon: '✨' },
    { n: 'Commander', desc: 'Reach Saturn', earned: false, hex: '#FFC629', icon: '👑' },
  ];
  return (
    <div style={{ padding: '4px 40px 56px' }}>
      <WebSection title="TROPHY ROOM" meta={`${formed.length} FORMED IDENTITY HABITS`} accent="var(--mm-yellow)">
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(230px, 1fr))', gap: 16 }}>
          {formed.map(h => {
            const hex = WEB_CORE_HEX[h.core];
            return (
              <div key={h.name} className="mm-panel" style={{ padding: 18, textAlign: 'center',
                background: `radial-gradient(120% 80% at 50% 0%, ${hex}1e, transparent 65%), rgba(17,28,78,.5)`,
                border: `1px solid ${hex}55` }}>
                <div style={{ fontSize: 34 }}>{WEB_CORE_ICON[h.core]}</div>
                <div style={{ fontSize: 14.5, color: '#fff', fontWeight: 600, marginTop: 10 }}>{h.name}</div>
                <div className="t-display-x" style={{ fontSize: 8.5, letterSpacing: '.14em', color: hex, marginTop: 5 }}>{h.core.toUpperCase()}</div>
                <div style={{ marginTop: 12, paddingTop: 12, borderTop: '1px solid rgba(241,241,241,.08)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6 }}>
                  <span style={{ fontSize: 14 }}>🟢</span>
                  <span className="t-num t-display" style={{ fontSize: 15, color: 'var(--mm-teal)' }}>{h.days}</span>
                  <span style={{ fontSize: 11, color: 'rgba(241,241,241,.5)' }}>days formed</span>
                </div>
              </div>
            );
          })}
        </div>
      </WebSection>

      <WebSection title="ACHIEVEMENTS" meta={`${badges.filter(b => b.earned).length}/${badges.length} EARNED`} accent="var(--mm-blue)">
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(170px, 1fr))', gap: 14 }}>
          {badges.map(b => (
            <div key={b.n} className="mm-panel" style={{ padding: 16, textAlign: 'center', opacity: b.earned ? 1 : .42,
              border: `1px solid ${b.earned ? b.hex + '55' : 'rgba(241,241,241,.1)'}` }}>
              <div style={{ fontSize: 30, filter: b.earned ? 'none' : 'grayscale(1)' }}>{b.icon}</div>
              <div style={{ fontSize: 12.5, color: '#fff', fontWeight: 600, marginTop: 8 }}>{b.n}</div>
              <div style={{ fontSize: 10.5, color: 'rgba(241,241,241,.55)', marginTop: 3 }}>{b.desc}</div>
              {!b.earned && <div className="t-display-x" style={{ fontSize: 7.5, letterSpacing: '.14em', color: 'rgba(241,241,241,.4)', marginTop: 8 }}>LOCKED</div>}
            </div>
          ))}
        </div>
      </WebSection>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// CANTINA — social: leaderboard + tribes + ideas
// ═══════════════════════════════════════════════════════════════
function WebCantina() {
  const board = [
    { r: 1, name: 'Nova_Rey', score: 51200, streak: 128, you: false },
    { r: 2, name: 'AstroKai', score: 44870, streak: 96, you: false },
    { r: 3, name: 'You', score: 42600, streak: 47, you: true },
    { r: 4, name: 'LunaVdB', score: 38150, streak: 61, you: false },
    { r: 5, name: 'OrbitOme', score: 33400, streak: 40, you: false },
  ];
  const tribes = [
    { name: 'Dawn Patrol', members: 14, focus: 'physical', desc: 'Early risers logging before 7am' },
    { name: 'Deep Work Guild', members: 22, focus: 'career', desc: 'Focus-block accountability' },
    { name: 'Mind Gardeners', members: 9, focus: 'mindset', desc: 'Daily journaling + meditation' },
  ];
  const ideas = [
    { txt: 'Habit-stack your journaling right after coffee — cue is already there.', by: 'Nova_Rey', up: 42 },
    { txt: 'I moved my check-in to the evening and my streak finally stuck.', by: 'LunaVdB', up: 31 },
    { txt: 'Treat the mystery box like a real reward — no peeking early!', by: 'AstroKai', up: 27 },
  ];
  return (
    <div style={{ padding: '4px 40px 56px', display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: 24, alignItems: 'start' }}>
      <div>
        <WebSection title="LEADERBOARD" meta="THIS WEEK · MOMENTUM" accent="var(--mm-violet)">
          <div className="mm-panel" style={{ padding: 8 }}>
            {board.map((p, i) => (
              <div key={p.name} style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '13px 14px', borderRadius: 10,
                background: p.you ? 'rgba(155,92,255,.14)' : 'transparent', border: p.you ? '1px solid rgba(155,92,255,.4)' : '1px solid transparent',
                borderTop: i ? '1px solid rgba(241,241,241,.05)' : undefined }}>
                <span className="t-display t-num" style={{ fontSize: 16, width: 26, textAlign: 'center',
                  color: p.r <= 3 ? ['#FFC629', '#cfd8e6', '#e8a35c'][p.r - 1] : 'rgba(241,241,241,.5)' }}>{p.r}</span>
                <div style={{ width: 34, height: 34, borderRadius: 9, flexShrink: 0, display: 'grid', placeItems: 'center', color: '#fff',
                  fontFamily: 'var(--f-display)', fontWeight: 700, background: p.you ? 'radial-gradient(circle at 30% 30%, #b58aff, #6b3df5)' : 'rgba(17,28,78,.7)' }}>{p.name[0]}</div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13.5, color: '#fff', fontWeight: p.you ? 700 : 500 }}>{p.name}</div>
                  <div style={{ fontSize: 10.5, color: 'rgba(241,241,241,.5)' }}>🔥 {p.streak}-day streak</div>
                </div>
                <span className="t-num t-display" style={{ fontSize: 14, color: 'var(--mm-yellow)' }}>{p.score.toLocaleString()}</span>
              </div>
            ))}
          </div>
        </WebSection>

        <WebSection title="IDEAS WELL" meta="COMMUNITY TIPS" accent="var(--mm-teal)">
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            {ideas.map((idea, i) => (
              <div key={i} className="mm-panel" style={{ padding: 16, display: 'flex', gap: 14 }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, color: '#fff', lineHeight: 1.5 }}>“{idea.txt}”</div>
                  <div className="t-display-x" style={{ fontSize: 8.5, letterSpacing: '.14em', color: 'rgba(241,241,241,.5)', marginTop: 8 }}>— {idea.by}</div>
                </div>
                <button style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3, background: 'rgba(0,169,143,.14)',
                  border: '1px solid rgba(0,169,143,.4)', borderRadius: 10, padding: '8px 12px', cursor: 'pointer', color: 'var(--mm-teal)', height: 'fit-content' }}>
                  <svg width="14" height="14" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M7 11 V3 M3 7 L7 3 L11 7" /></svg>
                  <span className="t-num" style={{ fontSize: 12 }}>{idea.up}</span>
                </button>
              </div>
            ))}
          </div>
        </WebSection>
      </div>

      <WebSection title="YOUR TRIBES" meta="ACCOUNTABILITY CREW" accent="var(--mm-magenta)">
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {tribes.map(t => {
            const hex = WEB_CORE_HEX[t.focus];
            return (
              <div key={t.name} className="mm-panel" style={{ padding: 16, borderLeft: `3px solid ${hex}` }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <span style={{ fontSize: 20 }}>{WEB_CORE_ICON[t.focus]}</span>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 14, color: '#fff', fontWeight: 600 }}>{t.name}</div>
                    <div className="t-display-x" style={{ fontSize: 8, letterSpacing: '.14em', color: hex, marginTop: 2 }}>{t.members} MEMBERS</div>
                  </div>
                </div>
                <div style={{ fontSize: 11.5, color: 'rgba(241,241,241,.6)', marginTop: 10, lineHeight: 1.5 }}>{t.desc}</div>
              </div>
            );
          })}
          <button className="mm-btn-ghost">+ Find a tribe</button>
        </div>
      </WebSection>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// HABITS — golden habits with lifecycle
// ═══════════════════════════════════════════════════════════════
function WebHabits() {
  const habits = [
    { name: 'Morning Hydration', core: 'physical', stage: 'formed', day: 62, note: 'Glass of water on waking' },
    { name: 'Daily Journaling', core: 'mindset', stage: 'formed', day: 48, note: '3 lines, gratitude + intent' },
    { name: 'Strength Block', core: 'physical', stage: 'forming', day: 9, note: 'MBM: lay out clothes at night' },
    { name: 'Weekly Friend Check-in', core: 'relationships', stage: 'forming', day: 6, note: 'Sunday call' },
    { name: 'Money Dashboard Review', core: 'career', stage: 'bad', day: 2, note: 'Cue: Monday coffee' },
  ];
  const STAGE = { bad: { hex: '#ea0029', l: 'Pain point', dot: '🔴' }, forming: { hex: '#FFC629', l: 'Forming', dot: '🟠' }, formed: { hex: '#00a98f', l: 'Formed', dot: '🟢' } };
  return (
    <div style={{ padding: '4px 40px 56px' }}>
      <WebSection title="GOLDEN HABITS" meta={`${habits.length} IN FORGE`} accent="var(--mm-magenta)"
        action={<button className="mm-btn-ghost" style={{ padding: '9px 16px' }}>+ New golden habit</button>}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: 16 }}>
          {habits.map(h => {
            const st = STAGE[h.stage]; const hex = WEB_CORE_HEX[h.core];
            return (
              <div key={h.name} className="mm-panel" style={{ padding: 18, borderLeft: `3px solid ${st.hex}` }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <span style={{ fontSize: 20 }}>{WEB_CORE_ICON[h.core]}</span>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 14.5, color: '#fff', fontWeight: 600 }}>{h.name}</div>
                    <div className="t-display-x" style={{ fontSize: 8, letterSpacing: '.14em', color: hex, marginTop: 3 }}>{h.core.toUpperCase()}</div>
                  </div>
                  <span style={{ fontSize: 16 }}>{st.dot}</span>
                </div>
                <div style={{ fontSize: 11.5, color: 'rgba(241,241,241,.6)', marginTop: 12, lineHeight: 1.5 }}>{h.note}</div>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 14, paddingTop: 12, borderTop: '1px solid rgba(241,241,241,.07)' }}>
                  <span className="t-display-x" style={{ fontSize: 8.5, letterSpacing: '.14em', color: st.hex }}>{st.l.toUpperCase()}</span>
                  <span style={{ fontSize: 11, color: 'rgba(241,241,241,.6)' }}>Day <span className="t-num" style={{ color: '#fff' }}>{h.day}</span></span>
                </div>
                <div style={{ height: 4, borderRadius: 3, marginTop: 8, background: 'rgba(241,241,241,.1)', overflow: 'hidden' }}>
                  <div style={{ width: `${Math.min(100, h.day / 14 * 100)}%`, height: '100%', background: st.hex }} />
                </div>
              </div>
            );
          })}
        </div>
      </WebSection>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// TASKS — Today / Tomorrow / Later columns
// ═══════════════════════════════════════════════════════════════
function WebTasks() {
  const [tasks, setTasks] = React.useState({
    Today: [{ n: 'Ship dashboard spec', core: 'career', pts: 40, done: false }, { n: 'Call Mom', core: 'relationships', pts: 20, done: true }, { n: '30-min run', core: 'physical', pts: 30, done: false }],
    Tomorrow: [{ n: 'Review Q4 goals', core: 'mindset', pts: 25, done: false }, { n: 'Meal prep', core: 'physical', pts: 20, done: false }],
    Later: [{ n: 'Plan date night', core: 'relationships', pts: 15, done: false }, { n: 'Read 1 chapter', core: 'emotional', pts: 10, done: false }],
  });
  const toggle = (bucket, i) => setTasks(t => ({ ...t, [bucket]: t[bucket].map((x, j) => j === i ? { ...x, done: !x.done } : x) }));
  return (
    <div style={{ padding: '4px 40px 56px' }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 20 }}>
        {Object.entries(tasks).map(([bucket, items]) => (
          <div key={bucket}>
            <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', margin: '0 2px 12px' }}>
              <span className="t-display-x" style={{ fontSize: 11, letterSpacing: '.16em', color: '#fff' }}>{bucket.toUpperCase()}</span>
              <span className="t-display-x t-num" style={{ fontSize: 9, color: 'var(--mm-yellow)' }}>{items.filter(i => !i.done).length} OPEN</span>
            </div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 9 }}>
              {items.map((it, i) => {
                const hex = WEB_CORE_HEX[it.core];
                return (
                  <button key={i} onClick={() => toggle(bucket, i)} className="mm-panel" style={{ padding: '13px 14px', cursor: 'pointer', textAlign: 'left',
                    display: 'flex', alignItems: 'center', gap: 11, opacity: it.done ? .55 : 1 }}>
                    <span style={{ width: 18, height: 18, borderRadius: 6, flexShrink: 0, display: 'grid', placeItems: 'center',
                      background: it.done ? hex : 'transparent', border: `1.5px solid ${it.done ? hex : 'rgba(241,241,241,.3)'}` }}>
                      {it.done && <svg width="10" height="10" viewBox="0 0 10 10" fill="none" stroke="#04130f" strokeWidth="2" strokeLinecap="round"><path d="M1.5 5 L4 7.5 L8.5 2.5" /></svg>}
                    </span>
                    <span style={{ flex: 1, fontSize: 13, color: '#fff', textDecoration: it.done ? 'line-through' : 'none' }}>{it.n}</span>
                    <span className="mm-chip t-num" style={{ color: hex, borderColor: `${hex}44` }}>+{it.pts}</span>
                  </button>
                );
              })}
              <button className="mm-btn-ghost" style={{ marginTop: 2 }}>+ Add task</button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// LISTS — manifest grid
// ═══════════════════════════════════════════════════════════════
function WebLists() {
  const lists = [
    { name: 'Q4 Mission Logs', core: 'mindset', count: 12 },
    { name: 'Promotion Track', core: 'career', count: 8 },
    { name: 'Date Night Ideas', core: 'relationships', count: 5 },
    { name: 'Gym Programs', core: 'physical', count: 3 },
    { name: 'Reading Queue', core: 'emotional', count: 14 },
    { name: 'Home Projects', core: 'career', count: 6 },
  ];
  return (
    <div style={{ padding: '4px 40px 56px' }}>
      <WebSection title="MANIFEST" meta={`${lists.length} LISTS`} accent="var(--mm-blue)"
        action={<button className="mm-btn-ghost" style={{ padding: '9px 16px' }}>+ New manifest</button>}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(250px, 1fr))', gap: 16 }}>
          {lists.map(l => {
            const hex = WEB_CORE_HEX[l.core];
            return (
              <div key={l.name} className="mm-panel" style={{ padding: 18, borderLeft: `3px solid ${hex}`, display: 'flex', alignItems: 'center', gap: 14 }}>
                <span style={{ fontSize: 24 }}>{WEB_CORE_ICON[l.core]}</span>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 14, color: '#fff', fontWeight: 600 }}>{l.name}</div>
                  <div className="t-display-x" style={{ fontSize: 8, letterSpacing: '.14em', color: hex, marginTop: 3 }}>{l.core.toUpperCase()}</div>
                </div>
                <span className="mm-chip t-num" style={{ color: hex, borderColor: `${hex}44` }}>{l.count}</span>
              </div>
            );
          })}
        </div>
      </WebSection>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════
// PROFILE — identity + core radar + lifetime stats
// ═══════════════════════════════════════════════════════════════
function WebProfile({ tweaks, account }) {
  const { streak = 47, momentumScore = 8420, level = 'navigator' } = tweaks;
  const cores = [
    { id: 'mindset', score: 78 }, { id: 'career', score: 64 }, { id: 'relationships', score: 52 },
    { id: 'physical', score: 88 }, { id: 'emotional', score: 46 },
  ];
  // radar geometry
  const cx = 130, cy = 130, R = 96;
  const pts = cores.map((c, i) => {
    const a = -Math.PI / 2 + i * (2 * Math.PI / 5);
    const r = R * c.score / 100;
    return [cx + r * Math.cos(a), cy + r * Math.sin(a)];
  });
  const axis = (i) => { const a = -Math.PI / 2 + i * (2 * Math.PI / 5); return [cx + R * Math.cos(a), cy + R * Math.sin(a)]; };
  return (
    <div style={{ padding: '4px 40px 56px', display: 'grid', gridTemplateColumns: '1fr 1.2fr', gap: 24, alignItems: 'start' }}>
      <div className="mm-panel" style={{ padding: 26, textAlign: 'center' }}>
        <div style={{ width: 84, height: 84, borderRadius: 22, margin: '0 auto', display: 'grid', placeItems: 'center', color: '#fff',
          fontFamily: 'var(--f-display)', fontWeight: 800, fontSize: 34, background: 'radial-gradient(circle at 30% 30%, #b58aff, #6b3df5 65%, #2a7de1)',
          boxShadow: '0 0 26px rgba(155,92,255,.5)' }}>{(account?.name || 'Commander')[0]}</div>
        <div className="t-display" style={{ fontSize: 20, color: '#fff', marginTop: 14 }}>{account?.name || 'Commander'}</div>
        <div className="t-display-x" style={{ fontSize: 9, letterSpacing: '.18em', color: 'var(--mm-yellow)', marginTop: 6 }}>{String(level).toUpperCase()} · MARS ORBIT</div>
        <div style={{ display: 'flex', gap: 12, marginTop: 22 }}>
          <WebStat label="Streak" value={`${streak}d`} accent="var(--mm-red)" />
          <WebStat label="Score" value={momentumScore.toLocaleString()} accent="var(--mm-yellow)" />
        </div>
        <button className="mm-btn-ghost" style={{ width: '100%', marginTop: 12 }}>Edit profile</button>
      </div>

      <div className="mm-panel" style={{ padding: 26 }}>
        <div className="t-display-x" style={{ fontSize: 11, letterSpacing: '.16em', color: '#fff', marginBottom: 6 }}>CORE BALANCE</div>
        <div style={{ fontSize: 12, color: 'rgba(241,241,241,.55)', marginBottom: 10 }}>Your momentum across the 5 Cores</div>
        <div style={{ display: 'flex', gap: 20, alignItems: 'center', flexWrap: 'wrap' }}>
          <svg width="260" height="260" viewBox="0 0 260 260">
            {[0.25, 0.5, 0.75, 1].map(f => (
              <polygon key={f} points={cores.map((_, i) => { const [x, y] = axis(i); return `${cx + (x - cx) * f},${cy + (y - cy) * f}`; }).join(' ')}
                fill="none" stroke="rgba(241,241,241,.1)" strokeWidth="1" />
            ))}
            {cores.map((_, i) => { const [x, y] = axis(i); return <line key={i} x1={cx} y1={cy} x2={x} y2={y} stroke="rgba(241,241,241,.1)" strokeWidth="1" />; })}
            <polygon points={pts.map(p => p.join(',')).join(' ')} fill="rgba(42,125,225,.25)" stroke="var(--mm-blue)" strokeWidth="2" />
            {pts.map((p, i) => <circle key={i} cx={p[0]} cy={p[1]} r="4" fill={WEB_CORE_HEX[cores[i].id]} />)}
          </svg>
          <div style={{ flex: 1, minWidth: 160, display: 'flex', flexDirection: 'column', gap: 10 }}>
            {cores.map(c => {
              const hex = WEB_CORE_HEX[c.id];
              return (
                <div key={c.id} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <span style={{ fontSize: 15, width: 20 }}>{WEB_CORE_ICON[c.id]}</span>
                  <div style={{ flex: 1 }}>
                    <div style={{ height: 6, borderRadius: 3, background: 'rgba(241,241,241,.1)', overflow: 'hidden' }}>
                      <div style={{ width: `${c.score}%`, height: '100%', background: hex, boxShadow: `0 0 8px ${hex}` }} />
                    </div>
                  </div>
                  <span className="t-num t-display" style={{ fontSize: 12, color: hex, width: 26, textAlign: 'right' }}>{c.score}</span>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { WebSection, WebRoutines, WebTrophy, WebCantina, WebHabits, WebTasks, WebLists, WebProfile, WebAddHabit });
