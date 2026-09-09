// dash-rocket.jsx — cockpit-interior rocket for the hull reveal.
// Layer order (back → front): engine nozzle, wings, interior frame, core panels,
// core icon badges, nose instrument buttons. Coordinates are % of the interior
// frame's box (470 × 974 native), which is tight-cropped nose-tip to base flange.
// hull-engine.png shares the interior's canvas width + origin, so it top-aligns.

const DASH_FRAME  = { src:'assets/hull-interior.png', nat:[470, 974] };
const DASH_ENGINE = { src:'assets/hull-engine.png',   nat:[470, 1124] };
const DASH_WINGS  = { src:'assets/hull-wings.png',    nat:[332, 558], box:[74,246,259,350] };

// Overlay percentages are the field-tested dashboard values from rocket.jsx / HANDOFF §4.
const DASH_CORES = [
  { id:'mindset',       name:'Mindset',           hex:'#e8744a', center:[50, 37], width:53 },
  { id:'emotional',     name:'Emotional Health',  hex:'#4cc8c2', center:[34, 47], width:32, iconOffset:[0, 4] },
  { id:'relationships', name:'Relationships',     hex:'#d977a0', center:[68, 47], width:32, iconOffset:[0, 4] },
  { id:'physical',      name:'Physical Health',   hex:'#8a5fc4', center:[36, 69], width:32 },
  { id:'career',        name:'Career & Finances', hex:'#5fa86b', center:[65, 69], width:32 },
];
const DASH_BADGE_W = 22;
const DASH_NOSE = [
  { kind:'habits',   src:'assets/icon-habits.png',   center:[50.5, 13], w:15.5 },
  { kind:'lists',    src:'assets/icon-lists.png',    center:[39,   22], w:11 },
  { kind:'routines', src:'assets/icon-routines.png', center:[62,   22], w:11 },
];
const DASH_ASSETS = [DASH_FRAME.src, DASH_ENGINE.src, DASH_WINGS.src,
  ...DASH_CORES.flatMap(c => [`assets/panel-${c.id}-color.png`, `assets/panel-${c.id}-gray.png`, `assets/core-${c.id}.png`]),
  ...DASH_NOSE.map(n => n.src)];

function DashRocket({ width = 240, activeCores = ['mindset','career','physical'], streak = 0, onNav }) {
  const H = width * DASH_FRAME.nat[1] / DASH_FRAME.nat[0];
  const engH = width * DASH_ENGINE.nat[1] / DASH_ENGINE.nat[0];
  const wingW = width * 1.26, ws = wingW / DASH_WINGS.nat[0];
  const wingTop = H * 0.985 - DASH_WINGS.box[3] * ws;
  const isOn = (id) => activeCores.includes(id);

  return (
    <div style={{ position:'relative', width, height: H }}>
      <div style={{ position:'absolute', left:'50%', bottom:'-5%', transform:'translateX(-50%)',
        width:'16%', height:`${14 + Math.min(streak,60)*0.18}%`,
        background:'radial-gradient(ellipse at 50% 20%, #fff5b3 0%, #ffce3a 30%, #ff6a1a 65%, transparent 90%)',
        filter:'blur(2px)', animation:'mm-plume 1.1s ease-in-out infinite', zIndex:0 }}></div>
      <img src={DASH_ENGINE.src} alt="" style={{ position:'absolute', left:0, top:0, width, height:engH, zIndex:1 }} />
      <img src={DASH_WINGS.src} alt="" style={{ position:'absolute', left:'50%', top:wingTop, width:wingW,
        height: DASH_WINGS.nat[1]*ws, transform:'translateX(-50%)', zIndex:1 }} />
      <img src={DASH_FRAME.src} alt="Rocket interior" style={{ position:'absolute', inset:0, width:'100%', height:'100%',
        objectFit:'contain', filter:'drop-shadow(0 8px 18px rgba(0,0,0,.45))', zIndex:2 }} />
      {DASH_CORES.map((c) => { const on = isOn(c.id); const [cx, cy] = c.center;
        const [ox, oy] = c.iconOffset || [0, 0]; const ix = cx + ox, iy = cy + oy; return (
        <React.Fragment key={c.id}>
          <img src={`assets/panel-${c.id}-${on ? 'color' : 'gray'}.png`} alt="" style={{ position:'absolute',
            left:`${cx}%`, top:`${cy}%`, width:`${c.width}%`, transform:'translate(-50%,-50%)', zIndex:3, pointerEvents:'none' }} />
          <div style={{ position:'absolute', left:`${ix}%`, top:`${iy}%`, width:`${DASH_BADGE_W}%`,
            aspectRatio:'1 / 1', transform:'translate(-50%,-50%)', zIndex:4, pointerEvents:'none' }}>
            <img src={`assets/core-${c.id}.png`} alt={c.name} style={{ width:'100%', height:'100%', objectFit:'cover',
              borderRadius:'50%', filter: on ? `drop-shadow(0 0 4px ${c.hex}aa)` : 'grayscale(1) brightness(.5) contrast(.9)' }} />
            {!on && (
              <div style={{ position:'absolute', inset:0, display:'grid', placeItems:'center', animation:'mm-lockPulse 1.8s ease-in-out infinite' }}>
                <svg viewBox="0 0 24 24" width="40%" height="40%" style={{ filter:'drop-shadow(0 0 4px rgba(255,198,41,.7))' }}>
                  <rect x="6" y="11" width="12" height="9" rx="1.5" fill="#FFC629"></rect>
                  <path d="M8 11 V 8 a 4 4 0 0 1 8 0 V 11" stroke="#FFC629" strokeWidth="2" fill="none"></path>
                </svg>
              </div>
            )}
          </div>
        </React.Fragment>
      ); })}
      {DASH_NOSE.map((n) => (
        <button key={n.kind} onClick={() => onNav && onNav(n.kind)} aria-label={n.kind} style={{ position:'absolute',
          left:`${n.center[0]}%`, top:`${n.center[1]}%`, width:`${n.w}%`, aspectRatio:'1 / 1',
          transform:'translate(-50%,-50%)', background:'transparent', border:0, padding:0, cursor:'pointer', zIndex:5 }}>
          <img src={n.src} alt={n.kind} style={{ width:'100%', height:'100%', objectFit:'contain' }} />
        </button>
      ))}
    </div>
  );
}

Object.assign(window, { DashRocket, DASH_FRAME, DASH_ENGINE, DASH_WINGS, DASH_CORES, DASH_NOSE, DASH_ASSETS });
