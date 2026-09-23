// phase2x.jsx — Phase 2 economy + ritual extensions
//   • ShipBay        (Prompt 3) — Space Credits sink: Wings/Armor/Thrusters
//   • Step0Priming   (Prompt 4) — Mantra + Grateful list before scoring
//   • Celebration    (Prompt 5) — Planet-arrival & Level-up overlays
//   • BalanceMeter   (Prompt 6) — 5-Core rolling avg + "Firing on All Cylinders"

const X_CORE = {
  mindset:'#2a7de1', career:'#FFC629', relationships:'#ff3d8b',
  physical:'#00a98f', emotional:'#9b5cff',
};

// ═══════════════════════════════════════════════════════════════════
// PROMPT 3 — Ship Bay (Upgrades store)
// ═══════════════════════════════════════════════════════════════════
const RARITY = {
  common:   { label:'Common',    color:'#9aa6c2', level:'cadet' },
  rare:     { label:'Rare',      color:'#2a7de1', level:'navigator' },
  veryrare: { label:'Very Rare', color:'#9b5cff', level:'navigator' },
  epic:     { label:'Epic',      color:'#FFC629', level:'commander' },
};
const LEVEL_RANK = { cadet:0, navigator:1, commander:2 };

const UPGRADE_CATS = [
  { id:'wings', name:'Wings', icon:'🪽', accent:'#2a7de1',
    blurb:'Unlock more Momentum Lists + bonus alien content',
    tiers:[
      { tier:1, rarity:'common',   cost:0,    label:'Stub Wings',     owned:true },
      { tier:2, rarity:'rare',     cost:450,  label:'Standard Wings' },
      { tier:3, rarity:'veryrare', cost:1200, label:'Swept Wings' },
      { tier:4, rarity:'epic',     cost:3000, label:'Epic Wings' },
    ] },
  { id:'armor', name:'Armor', icon:'🛡️', accent:'#00a98f',
    blurb:'Protect against missed check-ins (grace periods)',
    tiers:[
      { tier:1, rarity:'common',   cost:0,    label:'Light Plating',  owned:true },
      { tier:2, rarity:'rare',     cost:600,  label:'Reinforced Hull' },
      { tier:3, rarity:'veryrare', cost:1500, label:'Ablative Shield' },
      { tier:4, rarity:'epic',     cost:3600, label:'Aegis Armor' },
    ] },
  { id:'thrusters', name:'Thrusters', icon:'🔥', accent:'#ea0029',
    blurb:'Increase Momentum Points earned per check-in',
    tiers:[
      { tier:1, rarity:'common',   cost:0,    label:'Ion Drive',      owned:true },
      { tier:2, rarity:'rare',     cost:750,  label:'Plasma Drive' },
      { tier:3, rarity:'veryrare', cost:1800, label:'Fusion Drive' },
      { tier:4, rarity:'epic',     cost:4200, label:'Warp Core' },
    ] },
];

function ShipBay({ tweaks = {}, ...props }) {
  const level = tweaks.level || 'navigator';
  const [credits, setCredits] = React.useState(tweaks.credits || 2740);
  // owned tier per category
  const [owned, setOwned] = React.useState({ wings:1, armor:1, thrusters:1 });
  const [flash, setFlash] = React.useState(null);

  const catOrder = ['wings','armor','thrusters'];

  const buy = (catId, tier, cost) => {
    setCredits((c) => c - cost);
    setOwned((o) => ({ ...o, [catId]: tier }));
    setFlash(`${catId}-${tier}`);
    setTimeout(() => setFlash(null), 1400);
  };

  return (
    <ScreenShell title="Ship Bay" subtitle="UPGRADE HANGAR" accent="var(--mm-blue)" {...props}>
      {/* Balance + level */}
      <div className="mm-panel mm-panel--accent" style={{ padding:'12px 14px', marginBottom:14,
          display:'flex', alignItems:'center', justifyContent:'space-between' }}>
        <div>
          <div className="t-display-x" style={{ fontSize:9, letterSpacing:'.18em', color:'rgba(241,241,241,.55)' }}>SPACE CREDITS</div>
          <div className="t-display t-num" style={{ fontSize:24, color:'var(--mm-yellow)',
            textShadow:'0 0 14px rgba(255,198,41,.5)' }}>💎 {credits.toLocaleString()}</div>
        </div>
        <span className="mm-chip t-display" style={{ fontSize:10, letterSpacing:'.12em', color:'var(--mm-blue)',
          textTransform:'uppercase' }}>{level}</span>
      </div>

      {catOrder.map((catId, ci) => {
        const cat = UPGRADE_CATS.find(c => c.id === catId);
        const prevCat = catOrder[ci - 1];
        const prevUpgraded = ci === 0 || owned[prevCat] > 1;
        const cur = owned[catId];
        const next = cat.tiers.find(t => t.tier === cur + 1);
        return (
          <div key={cat.id} className="mm-panel" style={{ padding:'14px', marginBottom:12,
              borderLeft:`3px solid ${cat.accent}` }}>
            <div style={{ display:'flex', alignItems:'center', gap:10, marginBottom:4 }}>
              <span style={{ fontSize:22 }}>{cat.icon}</span>
              <div style={{ flex:1 }}>
                <div className="t-display" style={{ fontSize:15, color:'#fff' }}>{cat.name}</div>
                <div style={{ fontSize:11, color:'rgba(241,241,241,.6)', marginTop:2 }}>{cat.blurb}</div>
              </div>
            </div>

            {/* Tier track */}
            <div style={{ display:'flex', gap:4, margin:'10px 0' }}>
              {cat.tiers.map((t) => {
                const r = RARITY[t.rarity];
                const isOwned = t.tier <= cur;
                return (
                  <div key={t.tier} style={{ flex:1, textAlign:'center' }}>
                    <div style={{ height:5, borderRadius:3,
                      background: isOwned ? r.color : 'rgba(241,241,241,.1)',
                      boxShadow: isOwned ? `0 0 6px ${r.color}` : 'none' }} />
                    <div style={{ fontSize:7, fontFamily:'var(--f-display)', letterSpacing:'.08em',
                      color: isOwned ? r.color : 'rgba(241,241,241,.3)', marginTop:4 }}>
                      {r.label.toUpperCase()}
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Next-tier buy */}
            {next ? (() => {
              const r = RARITY[next.rarity];
              const levelOk = LEVEL_RANK[level] >= LEVEL_RANK[r.level];
              const canAfford = credits >= next.cost;
              const unlocked = levelOk && prevUpgraded && canAfford;
              const just = flash === `${catId}-${cur}`;
              return (
                <div className={just ? 'mm-reveal' : ''}
                     style={{ display:'flex', alignItems:'center', gap:10,
                       padding:'10px 12px', borderRadius:8,
                       background: just ? `${r.color}22` : 'rgba(241,241,241,.04)',
                       border:`1px solid ${unlocked ? r.color+'66' : 'rgba(241,241,241,.1)'}`,
                       animation: just ? 'mm-revealUp .35s ease-out' : 'none' }}>
                  <div style={{ flex:1 }}>
                    <div style={{ fontSize:13, color:'#fff', fontWeight:600 }}>{next.label}</div>
                    <div style={{ fontSize:10, color:r.color, fontFamily:'var(--f-display)', letterSpacing:'.1em', marginTop:2 }}>
                      {r.label.toUpperCase()}
                      {!levelOk && <span style={{ color:'rgba(241,241,241,.5)' }}> · 🔒 {r.level.toUpperCase()}</span>}
                    </div>
                  </div>
                  <button
                    onClick={() => unlocked && buy(catId, next.tier, next.cost)}
                    disabled={!unlocked}
                    style={{
                      padding:'9px 14px', borderRadius:8, border:'none', cursor: unlocked ? 'pointer' : 'default',
                      background: unlocked ? `linear-gradient(180deg, ${cat.accent}, ${cat.accent}cc)` : 'rgba(241,241,241,.08)',
                      color: unlocked ? '#fff' : 'rgba(241,241,241,.4)',
                      fontFamily:'var(--f-display)', fontSize:11, letterSpacing:'.06em', whiteSpace:'nowrap',
                      boxShadow: unlocked ? `0 0 12px ${cat.accent}55` : 'none',
                    }}>
                    {!levelOk ? r.level.toUpperCase()
                     : !prevUpgraded ? `UPGRADE ${prevCat.toUpperCase()} FIRST`
                     : `💎 ${next.cost.toLocaleString()}`}
                  </button>
                </div>
              );
            })() : (
              <div style={{ padding:'10px', textAlign:'center', fontSize:11, color:'var(--mm-teal)',
                fontFamily:'var(--f-display)', letterSpacing:'.12em' }}>✓ MAXED OUT</div>
            )}
          </div>
        );
      })}
    </ScreenShell>
  );
}

// ═══════════════════════════════════════════════════════════════════
// PROMPT 4 — Step 0: Mantra & Grateful List
// ═══════════════════════════════════════════════════════════════════
function Step0Priming({ onBegin, onSkip, onClose }) {
  const [mantra, setMantra] = React.useState('I am the calm operator who runs on clarity, not panic.');
  const [editing, setEditing] = React.useState(false);
  const [grats, setGrats] = React.useState(['', '', '']);

  return (
    <div style={{ width:'100%', height:'100%', position:'relative', overflow:'hidden',
        background:'var(--mm-bg)', paddingTop:56, display:'flex', flexDirection:'column' }}>
      <div className="mm-starfield" style={{ opacity:.7 }} />
      <div className="mm-stars" style={{ opacity:.4 }} />

      {/* header */}
      <div style={{ position:'relative', zIndex:5, display:'flex', alignItems:'center',
          justifyContent:'space-between', padding:'12px 18px 8px' }}>
        <button onClick={onClose} style={{
          background:'rgba(241,241,241,.06)', border:'1px solid rgba(241,241,241,.12)',
          color:'#fff', borderRadius:8, width:32, height:32, cursor:'pointer',
          display:'grid', placeItems:'center', fontSize:18 }}>×</button>
        <div className="t-display-x" style={{ fontSize:12, letterSpacing:'.18em', color:'var(--mm-teal)' }}>
          Pre-Flight
        </div>
        <button onClick={onSkip} style={{ background:'transparent', border:0,
          color:'rgba(241,241,241,.5)', fontSize:11, fontFamily:'var(--f-display)',
          letterSpacing:'.12em', cursor:'pointer' }}>SKIP →</button>
      </div>

      <div style={{ position:'relative', zIndex:4, flex:1, overflow:'auto', padding:'8px 18px 20px' }}>
        {/* Mantra */}
        <div className="t-display-x" style={{ fontSize:9, letterSpacing:'.2em', color:'rgba(241,241,241,.5)', marginBottom:10 }}>
          🕉️ TODAY'S MANTRA
        </div>
        <div className="mm-reveal" style={{ animation:'mm-revealUp .5s ease-out both',
          padding:'24px 18px', borderRadius:12, marginBottom:8,
          background:'linear-gradient(135deg, rgba(0,169,143,.18), rgba(17,28,78,.5))',
          border:'1px solid rgba(0,169,143,.35)' }}>
          {editing ? (
            <textarea value={mantra} onChange={(e) => setMantra(e.target.value)} rows={3}
              onBlur={() => setEditing(false)} autoFocus
              style={{ width:'100%', background:'transparent', border:'none', resize:'none',
                color:'#fff', fontFamily:'var(--f-display)', fontSize:18, lineHeight:1.4,
                outline:'none', textAlign:'center' }} />
          ) : (
            <div className="t-display" style={{ fontSize:18, color:'#fff', lineHeight:1.45,
              textAlign:'center', textShadow:'0 0 16px rgba(0,169,143,.4)' }}>
              "{mantra}"
            </div>
          )}
        </div>
        <button onClick={() => setEditing(true)} style={{ background:'transparent', border:0,
          color:'var(--mm-teal)', fontSize:11, cursor:'pointer', marginBottom:22,
          fontFamily:'var(--f-display)', letterSpacing:'.1em' }}>✎ EDIT MANTRA</button>

        {/* Gratitude */}
        <div className="t-display-x" style={{ fontSize:9, letterSpacing:'.2em', color:'rgba(241,241,241,.5)', marginBottom:10 }}>
          🙏 GRATEFUL LIST <span style={{ color:'rgba(241,241,241,.35)' }}>· OPTIONAL</span>
        </div>
        <div style={{ display:'flex', flexDirection:'column', gap:8 }}>
          {grats.map((g, i) => (
            <div key={i} style={{ display:'flex', alignItems:'center', gap:10,
                background:'rgba(241,241,241,.04)', border:'1px solid rgba(241,241,241,.1)',
                borderRadius:8, padding:'0 12px' }}>
              <span style={{ color:'var(--mm-teal)', fontSize:13, fontFamily:'var(--f-display)' }}>{i+1}</span>
              <input value={g} onChange={(e) => setGrats(grats.map((x,j) => j===i ? e.target.value : x))}
                placeholder="I'm grateful for…"
                style={{ flex:1, background:'transparent', border:'none', padding:'12px 0',
                  color:'#fff', fontSize:13, outline:'none', fontFamily:'var(--f-body)' }} />
            </div>
          ))}
        </div>
      </div>

      <div style={{ position:'relative', zIndex:5, padding:'10px 18px 30px',
          background:'linear-gradient(180deg, transparent, rgba(10,13,18,.95) 50%)' }}>
        <button onClick={onBegin} className="mm-btn-primary" style={{ width:'100%', padding:'14px' }}>
          Begin Check-in →
        </button>
      </div>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════
// PROMPT 5 — Celebration overlays (Planet arrival + Level-up)
// ═══════════════════════════════════════════════════════════════════
const PLANET_INFO = {
  moon:    { name:'Moon',    color:'#cfd2dc', wisdom:'"Small steps echo across the void." — Lunar Sage', credits:200, unlock:'Mantra List' },
  mars:    { name:'Mars',    color:'#d76b3a', wisdom:'"Discipline is the gravity that builds worlds." — Martian Elder', credits:350, unlock:'Gratitude List' },
  jupiter: { name:'Jupiter', color:'#d9a86b', wisdom:'"The largest gains compound silently." — Jovian Oracle', credits:600, unlock:'Top Environments List' },
  saturn:  { name:'Saturn',  color:'#e8c178', wisdom:'"Rings form from patient, repeated orbits." — Ringkeeper', credits:900, unlock:'Daily Bold Tracker' },
  pluto:   { name:'Pluto',   color:'#9aa3c7', wisdom:'"Even at the edge, momentum carries you." — The Distant One', credits:1500, unlock:'Legacy Vault' },
};
const LEVEL_INFO = {
  navigator: { rank:'Navigator', mult:'1.25×', unlocks:['Rare & Very Rare upgrade tiers','Space Cantina Tribes'] },
  commander: { rank:'Commander', mult:'1.5×',  unlocks:['Epic upgrade tier','Weekly Competitions','Pro analytics'] },
};

function Starburst({ color }) {
  return (
    <div style={{ position:'absolute', inset:0, pointerEvents:'none', overflow:'hidden' }}>
      {[...Array(16)].map((_, i) => {
        const a = (i / 16) * Math.PI * 2;
        return (
          <span key={i} style={{
            position:'absolute', left:'50%', top:'42%',
            width:3, height: 40 + (i % 3) * 20,
            background:`linear-gradient(180deg, ${color}, transparent)`,
            transformOrigin:'top center',
            transform:`rotate(${a}rad) translateY(0)`,
            animation:`mm-shoot 1.6s ease-out ${i*0.03}s infinite`,
            opacity:.7,
          }} />
        );
      })}
    </div>
  );
}

function Celebration({ kind = 'planet', planet = 'mars', level = 'navigator', onClose }) {
  if (kind === 'planet') {
    const p = PLANET_INFO[planet] || PLANET_INFO.mars;
    return (
      <div style={{ position:'absolute', inset:0, zIndex:80,
          background:'radial-gradient(ellipse at 50% 40%, #1a2860 0%, #06070d 70%)',
          display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center',
          padding:'40px 24px', textAlign:'center', overflow:'hidden' }}>
        <div className="mm-stars" />
        <Starburst color={p.color} />
        <div className="mm-reveal" style={{ position:'relative', zIndex:2, animation:'mm-revealUp .6s ease-out both' }}>
          <div style={{ width:140, height:140, borderRadius:'50%', margin:'0 auto 20px',
            background:`radial-gradient(circle at 35% 30%, ${p.color}, ${p.color}55 60%, transparent)`,
            boxShadow:`0 0 60px ${p.color}, inset -16px -16px 40px rgba(0,0,0,.4)`,
            animation:'mm-bob 3s ease-in-out infinite' }} />
          <div className="t-display-x" style={{ fontSize:11, letterSpacing:'.28em', color:p.color }}>
            PLANET REACHED
          </div>
          <div className="t-display" style={{ fontSize:32, color:'#fff', marginTop:6,
            textShadow:`0 0 24px ${p.color}` }}>{p.name.toUpperCase()}!</div>

          <div style={{ display:'flex', gap:10, justifyContent:'center', margin:'18px 0' }}>
            <span className="mm-chip" style={{ color:'var(--mm-yellow)' }}>💎 +{p.credits} credits</span>
            <span className="mm-chip" style={{ color:'var(--mm-blue)' }}>🔓 {p.unlock}</span>
          </div>

          <div style={{ maxWidth:280, fontSize:13, color:'rgba(241,241,241,.8)', fontStyle:'italic',
            lineHeight:1.5, margin:'0 auto' }}>{p.wisdom}</div>
        </div>
        <button onClick={onClose} className="mm-btn-primary"
          style={{ position:'relative', zIndex:2, marginTop:28, minWidth:160 }}>Continue →</button>
      </div>
    );
  }
  // Level-up
  const l = LEVEL_INFO[level] || LEVEL_INFO.navigator;
  return (
    <div style={{ position:'absolute', inset:0, zIndex:80,
        background:'radial-gradient(ellipse at 50% 40%, #2a1f00 0%, #06070d 70%)',
        display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center',
        padding:'40px 24px', textAlign:'center', overflow:'hidden' }}>
      <div className="mm-stars" />
      <Starburst color="#FFC629" />
      <div className="mm-reveal" style={{ position:'relative', zIndex:2, animation:'mm-revealUp .6s ease-out both' }}>
        <div style={{ fontSize:72, animation:'mm-bob 2.4s ease-in-out infinite' }}>🚀</div>
        <div className="t-display-x" style={{ fontSize:11, letterSpacing:'.28em', color:'var(--mm-yellow)', marginTop:8 }}>
          RANK ACHIEVED
        </div>
        <div className="t-display" style={{ fontSize:34, color:'#fff', marginTop:6,
          textShadow:'0 0 24px rgba(255,198,41,.6)' }}>{l.rank.toUpperCase()}</div>
        <div className="t-display t-num" style={{ fontSize:16, color:'var(--mm-yellow)', marginTop:10 }}>
          {l.mult} CREDIT MULTIPLIER
        </div>
        <div style={{ marginTop:18, display:'flex', flexDirection:'column', gap:6, maxWidth:280, margin:'18px auto 0' }}>
          {l.unlocks.map((u) => (
            <div key={u} style={{ fontSize:12, color:'rgba(241,241,241,.85)',
              display:'flex', alignItems:'center', gap:8, justifyContent:'center' }}>
              <span style={{ color:'var(--mm-teal)' }}>✓</span> {u}
            </div>
          ))}
        </div>
      </div>
      <button onClick={onClose} className="mm-btn-primary"
        style={{ position:'relative', zIndex:2, marginTop:28, minWidth:160 }}>Onward →</button>
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════
// PROMPT 6 — Balance Meter / "Firing on All Cylinders"
// ═══════════════════════════════════════════════════════════════════
// 7-day rolling averages per Core. `variant`: 'panel' (compact, for dash) or 'full'.
function BalanceMeter({ variant = 'panel', data, ...props }) {
  const cores = data || [
    { id:'mindset',       name:'Mindset',       avg:4.2, neglectDays:0 },
    { id:'career',        name:'Career',        avg:3.8, neglectDays:0 },
    { id:'relationships', name:'Relationships', avg:1.4, neglectDays:5 },
    { id:'physical',      name:'Physical',      avg:4.6, neglectDays:0 },
    { id:'emotional',     name:'Emotional',     avg:3.1, neglectDays:0 },
  ];
  const balanceScore = (cores.reduce((s,c) => s + c.avg, 0) / cores.length).toFixed(1);
  const firing = cores.every(c => c.avg >= 3);
  const neglected = cores.find(c => c.neglectDays >= 5);

  const Bars = () => (
    <div style={{ display:'flex', alignItems:'flex-end', justifyContent:'space-between',
        gap:8, height:120, padding:'0 4px' }}>
      {cores.map((c) => {
        const hex = X_CORE[c.id];
        const h = (c.avg / 5) * 100;
        return (
          <div key={c.id} style={{ flex:1, display:'flex', flexDirection:'column', alignItems:'center', gap:6 }}>
            <div className="t-display t-num" style={{ fontSize:11, color:hex }}>{c.avg.toFixed(1)}</div>
            <div style={{ width:'100%', height:80, borderRadius:6, position:'relative',
                background:'rgba(241,241,241,.06)', overflow:'hidden',
                display:'flex', alignItems:'flex-end' }}>
              <div style={{ width:'100%', height:`${h}%`,
                background:`linear-gradient(180deg, ${hex}, ${hex}88)`,
                boxShadow:`0 0 10px ${hex}88`, borderRadius:6,
                transition:'height .6s cubic-bezier(.22,1,.36,1)' }} />
            </div>
            <div style={{ fontSize:8, fontFamily:'var(--f-display)', letterSpacing:'.06em',
              color: c.neglectDays >= 5 ? 'var(--mm-yellow)' : 'rgba(241,241,241,.6)',
              textTransform:'uppercase', textAlign:'center' }}>
              {c.name.slice(0,6)}
            </div>
          </div>
        );
      })}
    </div>
  );

  const Body = (
    <>
      <div style={{ display:'flex', alignItems:'baseline', justifyContent:'space-between', marginBottom:12 }}>
        <div>
          <div className="t-display-x" style={{ fontSize:9, letterSpacing:'.18em', color:'rgba(241,241,241,.55)' }}>
            5-CORE BALANCE · 7-DAY AVG
          </div>
          <div className="t-display t-num" style={{ fontSize:26, color:'#fff', marginTop:2 }}>
            {balanceScore}<span style={{ fontSize:14, color:'rgba(241,241,241,.4)' }}> / 5</span>
          </div>
        </div>
        {firing && (
          <span className="mm-chip" style={{ color:'var(--mm-teal)', borderColor:'var(--mm-teal)',
            fontSize:9, letterSpacing:'.1em' }}>🔥 ALL CYLINDERS</span>
        )}
      </div>
      <Bars />
      {firing ? (
        <div style={{ marginTop:14, textAlign:'center', fontSize:12, color:'var(--mm-teal)',
          fontFamily:'var(--f-display)', letterSpacing:'.12em' }}>
          FIRING ON ALL CYLINDERS
        </div>
      ) : neglected && (
        <div style={{ marginTop:14, padding:'10px 12px', borderRadius:8,
          background:'rgba(255,198,41,.12)', border:'1px solid rgba(255,198,41,.4)',
          fontSize:12, color:'#fff', lineHeight:1.5, display:'flex', gap:8 }}>
          <span style={{ color:'var(--mm-yellow)', flexShrink:0 }}>⚠</span>
          <span><b>{neglected.name}</b> has been quiet for {neglected.neglectDays} days — a small win here creates a ripple.</span>
        </div>
      )}
    </>
  );

  if (variant === 'full') {
    return (
      <ScreenShell title="Balance" subtitle="FIRING ON ALL CYLINDERS" accent="var(--mm-yellow)" {...props}>
        <div className="mm-panel" style={{ padding:'16px 14px' }}>{Body}</div>
        <div style={{ fontSize:11, color:'rgba(241,241,241,.5)', textAlign:'center', marginTop:14, lineHeight:1.6 }}>
          The Ripple Effect only works when every Core gets attention.<br/>
          Balanced growth beats peak performance in one area.
        </div>
      </ScreenShell>
    );
  }
  return <div className="mm-panel" style={{ padding:'16px 14px', margin:'0 0 12px' }}>{Body}</div>;
}

Object.assign(window, { ShipBay, Step0Priming, Celebration, BalanceMeter });
