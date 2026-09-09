// hull-sequence.jsx — hull open/close cinematic.
// Plays a straight frame sequence: closed shell → armor plates in order → dashboard rocket
// (with all its buttons). CLOSE plays the exact same frames in reverse.
// Frames come from different source arts, so each carries its measured alpha bounding box
// (nat/box) and is registered on the rocket BODY — the silhouette stays put between frames.
// Add 01/02 to the front of HULL_FRAMES (with their bbox) when those files arrive.

const HULL_FRAMES = [
  { src:'assets/rocket-journey.png', nat:[320,608], box:[15,14,308,575] },
  { src:'assets/armor-1.png',        nat:[430,775], box:[51,24,376,695], wings:true },
  { src:'assets/armor-2.png',        nat:[430,775], box:[51,24,376,695], wings:true },
  { src:'assets/armor-3.png',        nat:[430,775], box:[51,24,376,695], wings:true },
];
// the armor arts ship without wings — this layer sits behind them
const HULL_WINGS = { src:'assets/hull-wings.png', nat:[332,558], box:[74,246,259,350] };
const HULL_DASH = { src:'assets/rocket.png', nat:[330,627], box:[16,16,317,593] };   // dashboard cockpit rocket
const HULL_LAYERS = HULL_FRAMES;
const HULL_STEP_MS = 780;
const HULL_PRELOAD = [...HULL_FRAMES.map(f => f.src), HULL_DASH.src, HULL_WINGS.src];

function HullPreload() { return null; }   // frames are mounted by HullSequence itself

// scale + translate that puts a frame's body bbox at `sil` px tall, centred in the box
function hullFit(f, sil) {
  const [nw, nh] = f.nat, [x0, y0, x1, y1] = f.box;
  const s = sil / (y1 - y0 + 1);
  return {
    w: nw * s, h: nh * s,
    dx: (nw / 2 - (x0 + x1) / 2) * s,
    dy: (nh / 2 - (y0 + y1) / 2) * s,
  };
}

// `stop` = how many armor frames this arrival traverses on the way in. The sequence ALWAYS
// terminates on the cockpit dashboard (index N) — the armor plates are the reveal, not the endpoint.
function HullSequence({ height = 520, dir = 'open', stop, activeCores, streak = 0, onNav, onDone }) {
  const N = HULL_FRAMES.length;                     // frame index N === dashboard cockpit rocket
  const depth = Math.max(1, Math.min(N, stop == null ? N : stop));
  const [frame, setFrame] = React.useState(dir === 'open' ? 0 : N);

  React.useEffect(() => {
    const armor = Array.from({ length: depth }, (_, i) => i);   // 0 … depth-1
    const open = [...armor, N];
    const order = dir === 'open' ? open : [...open].reverse();
    setFrame(order[0]);
    if (order.length < 2) { const t = setTimeout(() => onDone && onDone(), 0); return () => clearTimeout(t); }
    let i = 0, id = 0;
    const advance = () => {
      i += 1;
      if (i >= order.length) { onDone && onDone(); return; }
      setFrame(order[i]);
      id = setTimeout(advance, HULL_STEP_MS);
    };
    id = setTimeout(advance, HULL_STEP_MS);
    return () => clearTimeout(id);
  }, [dir, depth]);

  const sil = height * 0.9;
  const dash = hullFit(HULL_DASH, sil);
  // wings: scaled to the hull's body width, bottoms sitting on the hull's base
  const wf = HULL_FRAMES[1], wfit = hullFit(wf, sil);
  const bodyW = (wf.box[2] - wf.box[0] + 1) * (sil / (wf.box[3] - wf.box[1] + 1));
  const ws = (bodyW * 1.04) / (HULL_WINGS.box[2] - HULL_WINGS.box[0] + 1);
  const wingW = HULL_WINGS.nat[0] * ws, wingH = HULL_WINGS.nat[1] * ws;
  const wingTop = height/2 + sil/2 - sil*0.045 - HULL_WINGS.box[3] * ws;
  const showWings = !!(HULL_FRAMES[frame] && HULL_FRAMES[frame].wings);
  return (
    <div style={{ position:'relative', width: height * 1.2, height, display:'grid', placeItems:'center' }}>
      <div style={{ position:'absolute', inset:'8% 18%', borderRadius:'50%',
        background:'radial-gradient(ellipse at 50% 50%, rgba(42,125,225,.3), transparent 68%)',
        filter:'blur(24px)', zIndex:0, pointerEvents:'none' }}></div>
      <img src={HULL_WINGS.src} alt="" style={{ position:'absolute', left:'50%', top: wingTop,
        width: wingW, height: wingH, transform:'translateX(-50%)', zIndex:5, pointerEvents:'none',
        opacity: showWings ? 1 : 0, visibility: showWings ? 'visible' : 'hidden',
        filter:'drop-shadow(0 8px 18px rgba(0,0,0,.5))' }} />
      {/* final frame — the dashboard cockpit rocket with all its buttons */}
      <div style={{ position:'absolute', left:'50%', top:'50%',
        transform:`translate(-50%,-50%) translate(${dash.dx}px,${dash.dy}px)`, width: dash.w,
        zIndex:10, opacity: frame === N ? 1 : 0, transition:'opacity .18s linear',
        pointerEvents: frame === N ? 'auto' : 'none' }}>
        <Rocket width={dash.w} activeCores={activeCores} streak={streak} onNav={onNav} />
      </div>
      {/* armor frames — one visible at a time, mounted once so replays never refetch */}
      {HULL_FRAMES.map((f, i) => { const fit = hullFit(f, sil); return (
        <img key={f.src} src={f.src} alt="" style={{
          position:'absolute', left:'50%', top:'50%', width: fit.w, height: fit.h,
          transform:`translate(-50%,-50%) translate(${fit.dx}px,${fit.dy}px)`,
          objectFit:'contain', zIndex:20,
          opacity: frame === i ? 1 : 0, visibility: frame === i ? 'visible' : 'hidden',
          pointerEvents:'none', filter:'drop-shadow(0 10px 26px rgba(0,0,0,.55))',
        }} />
      ); })}
    </div>
  );
}

Object.assign(window, { HullSequence, HullPreload, HULL_FRAMES, HULL_DASH, HULL_WINGS, HULL_LAYERS, HULL_PRELOAD, HULL_STEP_MS });
