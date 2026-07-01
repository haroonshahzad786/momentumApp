// rocket.jsx — Hero rocket built on rocket-animation-background.png.
// Each Core gets its own panel-{id}-color.png (active) or panel-{id}-gray.png
// (locked) overlaid on the metal frame, with the Core icon centered on top.
// The 3 nose-cone instruments use habits / lists / routines PNGs and navigate.

const CORE_DEFS = [
  // Hex matches the colored-panel reference; used for icon-badge glow.
  // `center` = panel position; `iconOffset` (optional) nudges the icon
  // within the panel — use it when the panel's visual center isn't its
  // geometric center (e.g. teardrop / curved shapes).
  { id: 'mindset',       name: 'Mindset',           hex: '#e8744a', icon: 'assets/core-mindset.png',       center: [50, 37], width: 53 },
  { id: 'emotional',     name: 'Emotional Health',  hex: '#4cc8c2', icon: 'assets/core-emotional.png',     center: [34, 47], width: 32, iconOffset: [0, 4] },
  { id: 'relationships', name: 'Relationships',     hex: '#d977a0', icon: 'assets/core-relationships.png', center: [68, 47], width: 32, iconOffset: [0, 4] },
  { id: 'physical',      name: 'Physical Health',   hex: '#8a5fc4', icon: 'assets/core-physical.png',      center: [36, 69], width: 32 },
  { id: 'career',        name: 'Career & Finances', hex: '#5fa86b', icon: 'assets/core-career.png',        center: [65, 69], width: 32 },
];

// Uniform badge size for all 5 Core icons (% of rocket image width).
const BADGE_W = 22;

// 3 nose-cone instrument icons — same destinations as the dashboard's quick-icon row
const NOSE_ICONS = [
  { kind: 'habits',   src: 'assets/icon-habits.png',   center: [50.5, 13], w: 15.5 },
  { kind: 'lists',    src: 'assets/icon-lists.png',    center: [39,   22], w: 11 },
  { kind: 'routines', src: 'assets/icon-routines.png', center: [62,   22], w: 11 },
];

function Rocket({
  width = 240,
  activeCores = ['mindset', 'career', 'physical'],
  streak = 0,
  onNav,
}) {
  const isActive = (id) => activeCores.includes(id);
  // Native PNG aspect ratio is 516:980
  const VW = 516, VH = 980;
  const aspect = VH / VW;

  return (
    <div style={{ position:'relative', width, height: width * aspect }}>
      {/* Engine plume — sits behind the rocket */}
      <div style={{
        position:'absolute', left:'41%', bottom:'-6%',
        transform:'translateX(-50%)',
        width:'18%', height:`${16 + Math.min(streak, 60) * 0.18}%`,
        background:'radial-gradient(ellipse at 50% 20%, #fff5b3 0%, #ffce3a 30%, #ff6a1a 65%, transparent 90%)',
        filter:'blur(2px)',
        animation:'mm-plume 1.1s ease-in-out infinite',
        zIndex:0,
      }} />

      {/* Halo behind the rocket */}
      <div style={{
        position:'absolute', inset:'10% -10% -10% -10%',
        background:'radial-gradient(ellipse at 50% 45%, rgba(42,125,225,.22) 0%, transparent 60%)',
        filter:'blur(20px)', pointerEvents:'none', zIndex:0,
      }} />

      {/* Rocket frame */}
      <img src="assets/rocket.png" alt="Rocket"
           style={{
             position:'absolute', inset:0, width:'100%', height:'100%',
             objectFit:'contain',
             filter:'drop-shadow(0 8px 18px rgba(0,0,0,.45))',
             zIndex:1,
           }} />

      {/* 5 Core panel backgrounds + icon badges */}
      {CORE_DEFS.map((c) => {
        const active = isActive(c.id);
        const [cx, cy] = c.center;
        const [ox, oy] = c.iconOffset || [0, 0];
        const ix = cx + ox, iy = cy + oy;
        return (
          <React.Fragment key={c.id}>
            {/* Panel background (colored or gray) */}
            <img
              src={`assets/panel-${c.id}-${active ? 'color' : 'gray'}.png`}
              alt=""
              style={{
                position: 'absolute',
                left: `${cx}%`, top: `${cy}%`,
                width: `${c.width}%`,
                transform: 'translate(-50%, -50%)',
                zIndex: 2,
                pointerEvents: 'none',
                transition: 'opacity .3s',
              }}
            />
            {/* Core icon badge — same size for every Core, centered on its panel */}
            <div style={{
              position: 'absolute',
              left: `${ix}%`, top: `${iy}%`,
              width: `${BADGE_W}%`,
              aspectRatio: '1 / 1',
              transform: 'translate(-50%, -50%)',
              zIndex: 3, pointerEvents: 'none',
            }}>
              <img src={c.icon} alt={c.name}
                style={{
                  width: '100%', height: '100%', objectFit: 'cover',
                  borderRadius: '50%',
                  filter: active
                    ? `drop-shadow(0 0 4px ${c.hex}aa)`
                    : 'grayscale(1) brightness(.5) contrast(.9)',
                  transition: 'filter .3s',
                }} />
              {/* Lock badge for inactive Cores */}
              {!active && (
                <div style={{
                  position: 'absolute', inset: 0,
                  display: 'grid', placeItems: 'center',
                  animation: 'mm-lockPulse 1.8s ease-in-out infinite',
                }}>
                  <svg viewBox="0 0 24 24" width="40%" height="40%"
                       style={{ filter: 'drop-shadow(0 0 4px rgba(255,198,41,.7))' }}>
                    <rect x="6" y="11" width="12" height="9" rx="1.5" fill="#FFC629" />
                    <path d="M8 11 V 8 a 4 4 0 0 1 8 0 V 11" stroke="#FFC629" strokeWidth="2" fill="none" />
                  </svg>
                </div>
              )}
            </div>
          </React.Fragment>
        );
      })}

      {/* 3 nose instrument icons — clickable, route to habits/lists/routines */}
      {NOSE_ICONS.map((n) => (
        <button
          key={n.kind}
          onClick={() => onNav?.(n.kind)}
          aria-label={n.kind}
          style={{
            position: 'absolute',
            left: `${n.center[0]}%`, top: `${n.center[1]}%`,
            width: `${n.w}%`, aspectRatio: '1 / 1',
            transform: 'translate(-50%, -50%)',
            background: 'transparent', border: 0, padding: 0, cursor: 'pointer',
            zIndex: 4,
          }}>
          <img src={n.src} alt={n.kind} style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
        </button>
      ))}
    </div>
  );
}

Object.assign(window, { Rocket, CORE_DEFS });
