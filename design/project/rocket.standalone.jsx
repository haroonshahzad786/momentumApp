// rocket.jsx — Uses the uploaded rocket illustration as the body.
// Core icons are overlaid on top of the 5 painted black portholes.
// Active = full color icon; inactive = greyscale + gold lock.

const CORE_DEFS = [
  { id: 'mindset',       name: 'Mindset',           hex: '#2a7de1', img: window.__resources.coreMindset },
  { id: 'career',        name: 'Career & Finances', hex: '#FFC629', img: window.__resources.coreCareer },
  { id: 'relationships', name: 'Relationships',     hex: '#ff3d8b', img: window.__resources.coreRelationships },
  { id: 'physical',      name: 'Physical Health',   hex: '#00a98f', img: window.__resources.corePhysical },
  { id: 'emotional',     name: 'Emotional Health',  hex: '#9b5cff', img: window.__resources.coreEmotional },
];

// Porthole positions as percentages of the rocket image (1080x1920).
// Order matches the spec: nose→Mindset; upper→Career; mid→Relationships;
// lower→Physical; engine bay→Emotional.
// Porthole positions for the new rocket image (1080x1584).
const PORTHOLE_SIZE = '20.5%';
const PORTHOLES = [
  { left: '50.0%', top: '32.0%', size: PORTHOLE_SIZE, core: CORE_DEFS[0] }, // top
  { left: '33.0%', top: '50.0%', size: PORTHOLE_SIZE, core: CORE_DEFS[1] }, // mid-L  Career
  { left: '67.0%', top: '50.0%', size: PORTHOLE_SIZE, core: CORE_DEFS[2] }, // mid-R  Relationships
  { left: '36.0%', top: '74.0%', size: PORTHOLE_SIZE, core: CORE_DEFS[3] }, // bot-L  Physical
  { left: '64.0%', top: '74.0%', size: PORTHOLE_SIZE, core: CORE_DEFS[4] }, // bot-R  Emotional
];

function Rocket({
  width = 240,
  activeCores = ['mindset', 'career', 'physical'],
  streak = 0,
}) {
  const isActive = (id) => activeCores.includes(id);
  const aspect = 1584 / 1080;
  const h = width * aspect;

  return (
    <div style={{ position: 'relative', width, height: h }}>
      {/* Engine plume — sits behind the rocket, peeks out the bottom */}
      <div style={{
        position: 'absolute', left: '41%', bottom: '-14%',
        transform: 'translateX(-50%)',
        width: '18%', height: `${16 + Math.min(streak, 60) * 0.18}%`,
        background: 'radial-gradient(ellipse at 50% 20%, #fff5b3 0%, #ffce3a 30%, #ff6a1a 65%, transparent 90%)',
        filter: 'blur(2px)',
        animation: 'mm-plume 1.1s ease-in-out infinite',
        zIndex: 0,
      }} />

      {/* Halo behind the rocket */}
      <div style={{
        position: 'absolute', inset: '10% -10% -10% -10%',
        background: 'radial-gradient(ellipse at 50% 45%, rgba(42,125,225,.22) 0%, transparent 60%)',
        filter: 'blur(20px)', pointerEvents: 'none', zIndex: 0,
      }} />

      {/* Rocket image */}
      <img src={window.__resources.rocket} alt="Rocket"
           style={{
             position: 'absolute', inset: 0,
             width: '100%', height: '100%',
             objectFit: 'contain',
             filter: 'drop-shadow(0 8px 18px rgba(0,0,0,.45))',
             zIndex: 1,
           }} />

      {/* Porthole overlays */}
      {PORTHOLES.map((p, i) => {
        const active = isActive(p.core.id);
        return (
          <div key={p.core.id} style={{
            position: 'absolute', left: p.left, top: p.top,
            width: p.size, aspectRatio: '1 / 1',
            transform: 'translate(-50%, -50%)',
            borderRadius: '50%',
            zIndex: 2,
            overflow: 'visible',
          }}>
            {/* Icon (active = color, inactive = greyscale) */}
            <img src={p.core.img} alt={p.core.name}
                 style={{
                   width: '100%', height: '100%',
                   borderRadius: '50%',
                   objectFit: 'cover',
                   filter: active
                     ? `drop-shadow(0 0 3px ${p.core.hex}aa)`
                     : 'grayscale(1) brightness(.55) contrast(.9)',
                   transition: 'filter .3s',
                 }} />
            {/* Active glow ring */}
            {active && (
              <div style={{
                position: 'absolute', inset: '-2%',
                borderRadius: '50%',
                border: `1.5px solid ${p.core.hex}`,
                boxShadow: `0 0 5px ${p.core.hex}99, inset 0 0 4px ${p.core.hex}55`,
                pointerEvents: 'none',
              }} />
            )}
            {/* Lock overlay for inactive */}
            {!active && (
              <div style={{
                position: 'absolute', inset: 0,
                display: 'grid', placeItems: 'center',
                animation: 'mm-lockPulse 1.8s ease-in-out infinite',
                pointerEvents: 'none',
              }}>
                <svg viewBox="0 0 24 24" width="38%" height="38%"
                     style={{ filter: 'drop-shadow(0 0 4px rgba(255,198,41,.7))' }}>
                  <rect x="6" y="11" width="12" height="9" rx="1.5" fill="#FFC629" />
                  <path d="M8 11 V 8 a 4 4 0 0 1 8 0 V 11" stroke="#FFC629" strokeWidth="2" fill="none" />
                </svg>
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}

Object.assign(window, { Rocket, CORE_DEFS });
