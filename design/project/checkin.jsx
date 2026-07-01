// checkin.jsx — Daily Check-In: Score Your 5 Cores (Screen 3.3)
// Full-screen card progression. One Core at a time. Sliders 1-5 with labels.
// Locked Cores show grey + gold lock + "Return to Phase 1" link.

const HABIT_STAGE = {
  bad:     { color: '#ea0029', label: 'Bad' },
  forming: { color: '#FFC629', label: 'Forming' },     // 🟠 Golden Habit forming
  mbms:    { color: '#2a7de1', label: 'MBMs attached' }, // 🔵
  formed:  { color: '#00a98f', label: 'Formed' },       // 🟢
  trophy:  { color: '#FFC629', label: 'Trophy' },       // 🏆
};

// Core data for the check-in. Includes BTTF vision + habits per core.
const CHECKIN_CORES = [
  {
    id: 'mindset', name: 'Mindset', color: '#2a7de1',
    vision: 'I am a focused operator who runs on calm clarity, not panic.',
    habits: [
      { name: 'Morning meditation · 10 min', stage: 'mbms', kind: 'Routine' },
      { name: 'Read 5 pages',                 stage: 'forming', kind: 'Routine' },
    ],
  },
  {
    id: 'career', name: 'Career & Finances', color: '#FFC629',
    vision: 'I move with clarity on the work that compounds.',
    habits: [
      { name: 'Deep-work block · 90 min',    stage: 'formed', kind: 'Routine' },
      { name: 'Daily review · 5 min',         stage: 'mbms',   kind: 'Routine' },
      { name: 'Money log · weekly',           stage: 'forming', kind: 'Non-Routine' },
    ],
  },
  {
    id: 'relationships', name: 'Relationships', color: '#ff3d8b',
    vision: 'I show up first, fully, for the people who matter.',
    habits: [],
    locked: true,
  },
  {
    id: 'physical', name: 'Physical Health', color: '#00a98f',
    vision: 'I am an energized, active person who trains 5 days a week.',
    habits: [
      { name: 'Strength training',           stage: 'mbms',   kind: 'Routine' },
      { name: 'Walk · 8,000 steps',          stage: 'forming', kind: 'Routine' },
      { name: 'Hydrate · 3L',                stage: 'forming', kind: 'Routine' },
    ],
  },
  {
    id: 'emotional', name: 'Emotional & Mental', color: '#9b5cff',
    vision: 'I process, I do not perform.',
    habits: [],
    locked: true,
  },
];

const SCORE_LABELS = [
  '',
  'Completely skipped',
  'Partial',
  'Got through it · struggled',
  'Solid · minor friction',
  'Nailed it',
];

// ─── Habit row with color-progression dot ───
function HabitRow({ habit, color }) {
  const stage = HABIT_STAGE[habit.stage];
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 10,
      padding: '10px 12px',
      background: 'rgba(241,241,241,.04)',
      border: '1px solid rgba(241,241,241,.08)',
      borderLeft: `3px solid ${color}`,
      borderRadius: 6,
    }}>
      <div className="mm-dot" style={{ background: stage.color, boxShadow: `0 0 6px ${stage.color}` }} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 13, color: '#fff', fontWeight: 500 }}>{habit.name}</div>
        <div style={{ fontSize: 9, fontFamily: 'var(--f-display)', letterSpacing: '.12em', color: 'rgba(241,241,241,.45)', textTransform: 'uppercase', marginTop: 2 }}>
          {habit.kind} · {stage.label}
        </div>
      </div>
    </div>
  );
}

// ─── Score slider with labels and lock-in feedback ───
function ScoreSlider({ value, onChange, color }) {
  const fillPct = ((value - 1) / 4) * 100;
  const isHigh = value >= 4;
  const isLow  = value <= 2;
  return (
    <div style={{ position: 'relative' }}>
      {/* Big number */}
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 6 }}>
        <span className="t-display-x" style={{ fontSize: 10, color: 'rgba(241,241,241,.55)', letterSpacing: '.18em' }}>
          Today's Score
        </span>
        <span className="t-display t-num" style={{
          fontSize: 56, lineHeight: 1, color: isHigh ? color : isLow ? '#FFC629' : '#fff',
          textShadow: isHigh ? `0 0 24px ${color}` : 'none',
          transition: 'all .25s',
        }}>
          {value}
        </span>
      </div>

      <input type="range" min="1" max="5" step="1" value={value}
             onChange={(e) => onChange(Number(e.target.value))}
             className="mm-slider"
             style={{
               '--fill-pct': `${fillPct}%`,
               '--track-fill': color,
               '--track-glow': `${color}cc`,
             }} />

      {/* Tick labels */}
      <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: -6 }}>
        {[1,2,3,4,5].map(n => (
          <div key={n} style={{
            fontFamily: 'var(--f-display)', fontSize: 11,
            color: n === value ? '#fff' : 'rgba(241,241,241,.35)',
            fontWeight: n === value ? 700 : 400,
            width: 20, textAlign: 'center',
          }}>{n}</div>
        ))}
      </div>

      {/* Active label */}
      <div style={{
        marginTop: 8, padding: '8px 12px',
        background: isHigh ? `${color}1a` : 'rgba(241,241,241,.05)',
        border: `1px solid ${isHigh ? color + '55' : 'rgba(241,241,241,.1)'}`,
        borderRadius: 6,
        fontSize: 12, color: isHigh ? '#fff' : 'rgba(241,241,241,.7)',
        textAlign: 'center',
        transition: 'all .25s',
      }}>
        {SCORE_LABELS[value]}
        {isHigh && <span style={{ marginLeft: 8 }}>✦</span>}
      </div>
    </div>
  );
}

// ─── Single Core check-in card ───
function CoreCheckInCard({ core, scoreValue, onScore, log, onLog, onSkip }) {
  if (core.locked) {
    return (
      <div style={{
        padding: '40px 24px', textAlign: 'center', height: '100%',
        display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
        gap: 16,
      }}>
        <div style={{ position: 'relative', width: 72, height: 72, opacity: .55, animation: 'mm-lockPulse 2s ease-in-out infinite' }}>
          <svg viewBox="0 0 72 72" width="72" height="72">
            <rect x="20" y="32" width="32" height="28" rx="4" fill="none" stroke="#FFC629" strokeWidth="2" />
            <path d="M26 32 V 22 a 10 10 0 0 1 20 0 V 32" fill="none" stroke="#FFC629" strokeWidth="2" />
            <circle cx="36" cy="46" r="3" fill="#FFC629" />
          </svg>
        </div>
        <div className="t-display-x" style={{ fontSize: 14, color: '#fff' }}>
          {core.name}
        </div>
        <div style={{ fontSize: 13, color: 'rgba(241,241,241,.55)', maxWidth: 240, lineHeight: 1.5 }}>
          Not yet activated. Return to Phase 1 to ignite this Core.
        </div>
        <button className="mm-btn-ghost" style={{ marginTop: 8 }}>
          Return to Phase 1 →
        </button>
        <button onClick={onSkip} style={{
          marginTop: 8, background: 'transparent', border: 0,
          color: 'rgba(241,241,241,.4)', fontSize: 11,
          fontFamily: 'var(--f-display)', letterSpacing: '.16em', textTransform: 'uppercase',
          cursor: 'pointer',
        }}>
          Skip Core →
        </button>
      </div>
    );
  }

  return (
    <div style={{ padding: '4px 18px 20px', height: '100%', overflowY: 'auto' }}>
      {/* Core header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
        <div style={{
          width: 10, height: 10, borderRadius: '50%',
          background: core.color, boxShadow: `0 0 12px ${core.color}`,
        }} />
        <div className="t-display-x" style={{ fontSize: 12, color: core.color, letterSpacing: '.16em' }}>
          {core.name}
        </div>
      </div>

      {/* BTTF Vision quote card */}
      <div style={{
        padding: '12px 14px', borderRadius: 6,
        background: `linear-gradient(135deg, ${core.color}1a, transparent 70%)`,
        borderLeft: `2px solid ${core.color}`,
        marginBottom: 14,
      }}>
        <div style={{ fontSize: 8, fontFamily: 'var(--f-display)', letterSpacing: '.18em', color: 'rgba(241,241,241,.45)', textTransform: 'uppercase', marginBottom: 4 }}>
          BTTF Vision
        </div>
        <div style={{ fontSize: 13, color: '#fff', lineHeight: 1.5, fontStyle: 'italic' }}>
          "{core.vision}"
        </div>
      </div>

      {/* Habit list */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginBottom: 14 }}>
        {core.habits.map((h, i) => <HabitRow key={i} habit={h} color={core.color} />)}
      </div>

      {/* Score slider */}
      <ScoreSlider value={scoreValue} onChange={onScore} color={core.color} />

      {/* Captain's Log */}
      <div style={{ marginTop: 14 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 6 }}>
          <span className="t-display-x" style={{ fontSize: 10, color: 'rgba(241,241,241,.55)', letterSpacing: '.16em' }}>
            Captain's Log
          </span>
          {log && log.length > 0 && (
            <span style={{ fontSize: 10, color: 'var(--mm-teal)', fontFamily: 'var(--f-display)', letterSpacing: '.1em' }}>
              ✓ Logged
            </span>
          )}
        </div>
        <textarea
          value={log || ''}
          onChange={(e) => onLog(e.target.value)}
          placeholder="What's the data? (optional)"
          style={{
            width: '100%', minHeight: 56, resize: 'none',
            background: 'rgba(241,241,241,.04)',
            border: `1px solid ${log ? core.color + '55' : 'rgba(241,241,241,.1)'}`,
            borderRadius: 6,
            padding: '10px 12px',
            color: '#fff', fontSize: 13, fontFamily: 'var(--f-body)',
            outline: 'none',
          }}
        />
      </div>
    </div>
  );
}

// ─── Top progress bar (5 segments) ───
function CheckInProgress({ idx, total, cores }) {
  return (
    <div style={{ display: 'flex', gap: 4, padding: '0 18px', marginTop: 4 }}>
      {cores.map((c, i) => (
        <div key={i} style={{
          flex: 1, height: 3, borderRadius: 2,
          background: i <= idx
            ? (c.locked ? 'rgba(241,241,241,.15)' : c.color)
            : 'rgba(241,241,241,.08)',
          boxShadow: i === idx && !c.locked ? `0 0 6px ${c.color}` : 'none',
          transition: 'background .3s',
        }} />
      ))}
    </div>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN: Daily Check-In flow
// ═══════════════════════════════════════════════════════════════════════════
function CheckIn({ tweaks, onComplete, onClose }) {
  const { activeCores = ['mindset', 'career', 'physical'] } = tweaks;

  // Mark cores active per tweaks
  const cores = CHECKIN_CORES.map(c => ({ ...c, locked: !activeCores.includes(c.id) }));

  const [idx, setIdx] = React.useState(0);
  const [scores, setScores] = React.useState({});
  const [logs, setLogs]     = React.useState({});

  const core = cores[idx];
  const isLast = idx === cores.length - 1;

  const advance = () => {
    if (isLast) onComplete?.({ scores, logs });
    else setIdx(idx + 1);
  };

  return (
    <div style={{
      width: '100%', height: '100%', position: 'relative', overflow: 'hidden',
      background: '#06070d',
      display: 'flex', flexDirection: 'column',
      paddingTop: 56,
    }}>
      <div className="mm-starfield" style={{ opacity: .7 }} />
      <div className="mm-stars" style={{ opacity: .4 }} />
      <div className="mm-scanlines" />

      {/* Header */}
      <div style={{ position: 'relative', zIndex: 5 }}>
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '12px 18px 10px',
        }}>
          <button onClick={onClose} style={{
            background: 'rgba(241,241,241,.06)', border: '1px solid rgba(241,241,241,.12)',
            color: '#fff', borderRadius: 8, width: 32, height: 32, cursor: 'pointer',
            display: 'grid', placeItems: 'center', fontSize: 18, lineHeight: 1,
          }}>×</button>
          <div className="t-display-x" style={{ fontSize: 12, letterSpacing: '.18em', color: '#fff' }}>
            Daily Check-in
          </div>
          <div className="mm-chip t-display" style={{ fontSize: 10, letterSpacing: '.12em' }}>
            {idx + 1} / {cores.length}
          </div>
        </div>
        <CheckInProgress idx={idx} total={cores.length} cores={cores} />
      </div>

      {/* Card body */}
      <div style={{ position: 'relative', zIndex: 4, flex: 1, minHeight: 0 }}>
        <CoreCheckInCard
          core={core}
          scoreValue={scores[core.id] || 3}
          onScore={(v) => setScores({ ...scores, [core.id]: v })}
          log={logs[core.id]}
          onLog={(v) => setLogs({ ...logs, [core.id]: v })}
          onSkip={advance}
        />
      </div>

      {/* Footer */}
      <div style={{
        position: 'relative', zIndex: 6,
        padding: '10px 18px 30px',
        background: 'linear-gradient(180deg, transparent, rgba(6,7,13,.95) 50%)',
        display: 'flex', gap: 10,
      }}>
        {idx > 0 && (
          <button onClick={() => setIdx(idx - 1)} className="mm-btn-ghost" style={{ flex: 0.5 }}>
            ← Back
          </button>
        )}
        <button onClick={advance} className="mm-btn-primary" style={{ flex: 1, padding: '14px' }}>
          {isLast ? 'Lock In Day' : 'Next Core →'}
        </button>
      </div>
    </div>
  );
}

Object.assign(window, { CheckIn });
