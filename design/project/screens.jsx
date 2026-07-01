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
// Routines  —  Morning / Workday / Evening timelines
// ─────────────────────────────────────────────────────────────
function RoutinesScreen(props) {
  const routines = [
    { name:'Launch Sequence', time:'06:30', items:['Hydrate','10m journal','Stretch','Cold rinse'], done:3, hex:'#00a98f' },
    { name:'Deep Work Block', time:'09:00', items:['Email triage','2h focus','Walk break'], done:1, hex:'#2a7de1' },
    { name:'Re-entry',        time:'21:00', items:['Day review','Read 20m','Lights down'], done:0, hex:'#9b5cff' },
  ];
  return (
    <ScreenShell title="Routines" subtitle="ORBITS · 3" accent="var(--mm-teal)" {...props}>
      <div style={{ display:'flex', flexDirection:'column', gap:12 }}>
        {routines.map((r) => (
          <div key={r.name} className="mm-panel" style={{ padding:14 }}>
            <div style={{ display:'flex', justifyContent:'space-between', alignItems:'baseline', marginBottom:10 }}>
              <div>
                <div style={{ fontSize:14, fontWeight:600, color:'#fff' }}>{r.name}</div>
                <div className="t-mono" style={{ fontSize:11, color:r.hex, marginTop:2 }}>{r.time} · {r.done}/{r.items.length} done</div>
              </div>
              <div style={{ width:32, height:32, borderRadius:'50%', border:`2px solid ${r.hex}`, display:'grid', placeItems:'center', color:r.hex, fontSize:11 }} className="t-num">
                {Math.round((r.done/r.items.length)*100)}
              </div>
            </div>
            <div style={{ display:'flex', flexDirection:'column', gap:6 }}>
              {r.items.map((it, i) => (
                <div key={i} style={{ display:'flex', alignItems:'center', gap:8, fontSize:12, color: i < r.done ? 'rgba(241,241,241,.5)' : '#fff' }}>
                  <div style={{
                    width:14, height:14, borderRadius:4,
                    border:`1.5px solid ${i < r.done ? r.hex : 'rgba(241,241,241,.3)'}`,
                    background: i < r.done ? r.hex : 'transparent',
                    display:'grid', placeItems:'center', flexShrink:0,
                  }}>
                    {i < r.done && (
                      <svg width="8" height="8" viewBox="0 0 8 8" fill="none" stroke="#000" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <path d="M1 4 L 3 6 L 7 2" />
                      </svg>
                    )}
                  </div>
                  <span style={{ textDecoration: i < r.done ? 'line-through' : 'none' }}>{it}</span>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
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

function CantinaScreen(props) {
  return (
    <ScreenShell title="Cantina" subtitle="CREW · 5 ABOARD" accent="var(--mm-teal)" {...props}>
      <div className="mm-panel" style={{ padding:'12px 14px', marginBottom:12 }}>
        <div className="t-display-x" style={{ fontSize:10, letterSpacing:'.18em', color:'rgba(241,241,241,.5)' }}>THIS WEEK'S LEADERBOARD</div>
        <div style={{ display:'flex', flexDirection:'column', gap:8, marginTop:10 }}>
          {CREW.map((c, i) => (
            <button key={c.id} onClick={() => props.onNav?.(c.me ? 'profile' : `crew:${c.id}`)}
              style={{
                display:'flex', alignItems:'center', gap:10,
                padding: c.me ? '6px 8px' : '4px 4px',
                borderRadius:8,
                background: c.me ? 'rgba(255,198,41,.08)' : 'transparent',
                border: c.me ? '1px solid rgba(255,198,41,.3)' : 'none',
                width:'100%', cursor:'pointer', textAlign:'left',
                transition:'background .15s',
              }}
              onMouseOver={(e) => { if (!c.me) e.currentTarget.style.background='rgba(241,241,241,.06)'; }}
              onMouseOut={(e) => { if (!c.me) e.currentTarget.style.background='transparent'; }}>
              <span className="t-display t-num" style={{ fontSize:11, color:'rgba(241,241,241,.5)', width:16 }}>{i+1}</span>
              <div style={{ position:'relative', width:30, height:30, borderRadius:'50%', background:c.hex, display:'grid', placeItems:'center', fontWeight:700, color:'#000', fontSize:13 }}>
                {c.a}
                {c.online && <span style={{ position:'absolute', bottom:-1, right:-1, width:10, height:10, borderRadius:'50%', background:'#00ff88', border:'2px solid #06070d' }} />}
              </div>
              <span style={{ flex:1, fontSize:13, color:'#fff', fontWeight: c.me ? 700 : 500 }}>{c.n}</span>
              <span className="mm-chip t-num">{c.lvl}</span>
              <span className="t-display t-num" style={{ fontSize:12, color:c.hex }}>{c.s.toLocaleString()}</span>
              <svg width="10" height="14" viewBox="0 0 10 14" fill="none" stroke="rgba(241,241,241,.4)" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M2 2 L 8 7 L 2 12" />
              </svg>
            </button>
          ))}
        </div>
      </div>
      <div className="t-display-x" style={{ fontSize:10, letterSpacing:'.18em', color:'rgba(241,241,241,.5)', margin:'4px 4px 8px' }}>SQUAD THREADS · 2</div>
      {THREADS.map((t) => (
        <button key={t.id} onClick={() => props.onNav?.(`thread:${t.id}`)}
          className="mm-panel"
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
// Trophy  —  Achievements grid + planet conquest
// ─────────────────────────────────────────────────────────────
function TrophyScreen(props) {
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
  return (
    <ScreenShell title="Trophy" subtitle="ACHIEVEMENTS · 5/8" accent="var(--mm-yellow)" {...props}>
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
        {['Notifications','Connected calendars','Privacy','Subscription · PRO','Sign out'].map((s, i, arr) => (
          <div key={s} style={{
            display:'flex', alignItems:'center', justifyContent:'space-between',
            padding:'12px 14px',
            borderBottom: i < arr.length - 1 ? '1px solid rgba(241,241,241,.06)' : 'none',
            fontSize:13, color: s === 'Sign out' ? 'var(--mm-red)' : '#fff',
          }}>
            <span>{s}</span>
            <svg width="10" height="14" viewBox="0 0 10 14" fill="none" stroke="rgba(241,241,241,.4)" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
              <path d="M2 2 L 8 7 L 2 12" />
            </svg>
          </div>
        ))}
      </div>
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
    { label:'COCKPIT', items:[
      { k:'dashboard', n:'Dashboard',   hex:'#2a7de1' },
      { k:'checkin',   n:'Daily Check-in', hex:'#FFC629' },
      { k:'summary',   n:'Today\'s Recap',  hex:'#9b5cff' },
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
  CantinaScreen, TrophyScreen, ProfileScreen,
  CrewProfileScreen, ThreadScreen,
  ChatScreen, MenuDrawer, ScreenShell,
});
