// src/components/KidUI.jsx — Shared kid-friendly UI design system
import React from 'react';

/* ═══════════════════════════════════════════════
   DESIGN TOKENS
═══════════════════════════════════════════════ */
export const K = {
  orange:      '#FF8C00',
  orangeLight: '#FFA726',
  orangePale:  '#FFF3E0',
  yellow:      '#FFE082',
  yellowPale:  '#FFF8E7',
  green:       '#43A047',
  greenLight:  '#66BB6A',
  greenPale:   '#E8F5E9',
  teal:        '#00ACC1',
  tealPale:    '#E0F7FA',
  pink:        '#E91E8C',
  pinkPale:    '#FCE4EC',
  purple:      '#7C4DFF',
  purplePale:  '#EDE7F6',
  red:         '#E53935',
  redPale:     '#FFEBEE',
  navy:        '#1A237E',
  white:       '#FFFFFF',
  cream:       '#FFF8E7',
  border:      '#FFE082',
  shadow:      'rgba(0,0,0,0.10)',
  shadowMd:    'rgba(0,0,0,0.18)',
  gray:        '#9E9E9E',
  grayLight:   '#F5F5F5',
  textDark:    '#333333',
  textMid:     '#666666',
};

/* ═══════════════════════════════════════════════
   BOY CHARACTER SVG
═══════════════════════════════════════════════ */
export function BoyCharacter({ speaking = false, mood = 'neutral', size = 110 }) {
  const happy  = mood === 'praise' || mood === 'happy';
  const sad    = mood === 'sad';

  return (
    <svg viewBox="0 0 100 160" width={size} height={size * 1.45} style={{ display: 'block', overflow: 'visible' }}>

      {/* ── SHADOW ── */}
      <ellipse cx="46" cy="156" rx="28" ry="5" fill="rgba(0,0,0,0.12)" />

      {/* ── LEGS (dark brown trousers) ── */}
      <rect x="29" y="112" width="14" height="42" rx="7" fill="#6D4C41" />
      <rect x="51" y="112" width="14" height="42" rx="7" fill="#6D4C41" />
      {/* Trouser crease */}
      <line x1="36" y1="112" x2="36" y2="154" stroke="#5D4037" strokeWidth="1" />
      <line x1="58" y1="112" x2="58" y2="154" stroke="#5D4037" strokeWidth="1" />
      {/* Shoes */}
      <ellipse cx="36" cy="154" rx="11" ry="5" fill="#212121" />
      <ellipse cx="58" cy="154" rx="11" ry="5" fill="#212121" />
      <ellipse cx="33" cy="152" rx="7" ry="3" fill="#424242" />
      <ellipse cx="55" cy="152" rx="7" ry="3" fill="#424242" />

      {/* ── KURTA (white long shirt, base layer) ── */}
      <path d="M 23 70 C 21 100 22 112 33 116 L 61 116 C 72 112 73 100 71 70 Z" fill="#FAFAFA" />
      {/* Kurta collar line */}
      <path d="M 38 70 L 46 80 L 54 70" fill="none" stroke="#E0E0E0" strokeWidth="1" />

      {/* ── GREEN SLEEVELESS VEST ── */}
      {/* Left panel */}
      <path d="M 23 70 C 21 98 25 114 33 116 L 45 116 L 45 70 Z" fill="#43A047" />
      {/* Right panel */}
      <path d="M 71 70 C 73 98 69 114 61 116 L 55 116 L 55 70 Z" fill="#43A047" />
      {/* V-neck white gap */}
      <path d="M 36 70 L 46 86 L 56 70 Z" fill="#FAFAFA" />
      {/* Vest V edge shading */}
      <path d="M 36 70 L 46 85 L 56 70" fill="none" stroke="#2E7D32" strokeWidth="1.5" />
      {/* Center vertical seam */}
      <line x1="46" y1="85" x2="46" y2="116" stroke="#2E7D32" strokeWidth="1" strokeDasharray="3,3" />
      {/* Vest pocket (right side) */}
      <rect x="58" y="86" width="10" height="9" rx="2" fill="none" stroke="#2E7D32" strokeWidth="1.3" />
      <line x1="63" y1="86" x2="63" y2="95" stroke="#2E7D32" strokeWidth="1" />
      {/* Vest bottom hem */}
      <path d="M 23 113 C 25 117 33 119 46 118 C 59 119 67 117 71 113" fill="none" stroke="#2E7D32" strokeWidth="1.2" />

      {/* ── LEFT ARM (hanging naturally at side) ── */}
      {/* Green sleeve */}
      <path d="M 23 74 C 12 84 10 100 12 106" fill="none" stroke="#43A047" strokeWidth="12" strokeLinecap="round" />
      {/* Skin forearm */}
      <path d="M 12 106 C 10 112 13 118 16 116" fill="none" stroke="#FDBCB4" strokeWidth="9" strokeLinecap="round" />
      {/* Left hand */}
      <ellipse cx="15" cy="117" rx="6" ry="5" fill="#FDBCB4" />
      <ellipse cx="12" cy="118" rx="3" ry="2.5" fill="#FDBCB4" />

      {/* ── RIGHT ARM (raised, pointing toward content) ── */}
      {/* Green sleeve going up-right */}
      <path d="M 69 74 C 80 68 86 62 88 56" fill="none" stroke="#43A047" strokeWidth="12" strokeLinecap="round" />
      {/* Skin forearm + hand */}
      <path d="M 88 56 C 91 50 93 44 92 40" fill="none" stroke="#FDBCB4" strokeWidth="9" strokeLinecap="round" />
      {/* Pointing hand */}
      <ellipse cx="91" cy="40" rx="6" ry="5" fill="#FDBCB4" transform="rotate(-40 91 40)" />
      {/* Index finger pointing up-right */}
      <path d="M 93 37 C 95 31 96 25 95 20" fill="none" stroke="#FDBCB4" strokeWidth="5" strokeLinecap="round" />
      {/* Finger tip */}
      <ellipse cx="95" cy="20" rx="3.5" ry="3" fill="#FDBCB4" />

      {/* ── NECK ── */}
      <rect x="39" y="63" width="15" height="11" rx="5" fill="#FDBCB4" />

      {/* ── HEAD ── */}
      <ellipse cx="46" cy="40" rx="26" ry="27" fill="#FDBCB4" />

      {/* ── WHITE TOPI (kufi cap) ── */}
      {/* Cap dome */}
      <path d="M 20 36 C 20 7 72 7 72 36" fill="#FFFFFF" />
      {/* Cap brim band */}
      <rect x="18" y="33" width="56" height="9" rx="4.5" fill="#EEEEEE" />
      {/* Cap brim shadow */}
      <rect x="18" y="38" width="56" height="4" rx="2" fill="#E0E0E0" />
      {/* Embroidery arc */}
      <path d="M 27 22 Q 46 13 65 22" fill="none" stroke="#D8D8D8" strokeWidth="2" />
      {/* Embroidery dots */}
      {[30,38,46,54,62].map(x => (
        <circle key={x} cx={x} cy="30" r="1.2" fill="#D0D0D0" />
      ))}

      {/* ── EARS ── */}
      <ellipse cx="20" cy="42" rx="5.5" ry="6.5" fill="#FDBCB4" />
      <ellipse cx="72" cy="42" rx="5.5" ry="6.5" fill="#FDBCB4" />
      <ellipse cx="20" cy="42" rx="3" ry="4" fill="#e8967a" />
      <ellipse cx="72" cy="42" rx="3" ry="4" fill="#e8967a" />

      {/* ── EYES (big, shiny cartoon eyes) ── */}
      {/* Eye whites */}
      <ellipse cx="33" cy="38" rx="8" ry="9" fill="white" />
      <ellipse cx="59" cy="38" rx="8" ry="9" fill="white" />
      {/* Dark brown iris */}
      <circle cx="34" cy="38" r="5.5" fill="#3E2723" />
      <circle cx="60" cy="38" r="5.5" fill="#3E2723" />
      {/* Pupil */}
      <circle cx="34" cy="38" r="3.5" fill="#1A1A1A" />
      <circle cx="60" cy="38" r="3.5" fill="#1A1A1A" />
      {/* Bright highlight (main) */}
      <circle cx="36" cy="35" r="2.2" fill="white" />
      <circle cx="62" cy="35" r="2.2" fill="white" />
      {/* Secondary small highlight */}
      <circle cx="32.5" cy="40" r="1" fill="white" />
      <circle cx="58.5" cy="40" r="1" fill="white" />
      {/* Eyelid arc (top lash) */}
      <path d="M 25 30 Q 33 25 41 30" fill="none" stroke="#4E342E" strokeWidth="2.5" strokeLinecap="round" />
      <path d="M 51 30 Q 59 25 67 30" fill="none" stroke="#4E342E" strokeWidth="2.5" strokeLinecap="round" />

      {/* ── EYEBROWS ── */}
      <path d={happy ? 'M 25 26 Q 33 21 41 25' : sad ? 'M 25 24 Q 33 28 41 26' : 'M 25 25 Q 33 21 41 25'}
        fill="none" stroke="#5D4037" strokeWidth="2.8" strokeLinecap="round" />
      <path d={happy ? 'M 51 25 Q 59 21 67 26' : sad ? 'M 51 26 Q 59 28 67 24' : 'M 51 25 Q 59 21 67 25'}
        fill="none" stroke="#5D4037" strokeWidth="2.8" strokeLinecap="round" />

      {/* ── NOSE ── */}
      <path d="M 43 50 Q 46 55 49 50" fill="none" stroke="#CC7766" strokeWidth="2" strokeLinecap="round" />
      <ellipse cx="43" cy="50" rx="1.5" ry="1.5" fill="#e8967a" />
      <ellipse cx="49" cy="50" rx="1.5" ry="1.5" fill="#e8967a" />

      {/* ── MOUTH ── */}
      {happy ? (
        <g>
          <path d="M 36 57 Q 46 67 56 57" fill="white" stroke="#c0694e" strokeWidth="2.2" strokeLinecap="round" />
          <path d="M 36 57 Q 46 65 56 57" fill="white" />
          <path d="M 37 58 Q 46 65 55 58" fill="#e8967a" />
        </g>
      ) : sad ? (
        <path d="M 36 63 Q 46 56 56 63" fill="none" stroke="#c0694e" strokeWidth="2.2" strokeLinecap="round" />
      ) : (
        <path d="M 37 59 Q 46 65 55 59" fill="none" stroke="#c0694e" strokeWidth="2.2" strokeLinecap="round" />
      )}

      {/* ── ROSY CHEEKS ── */}
      <ellipse cx="26" cy="52" rx="8" ry="5.5" fill="#FFB5A0" opacity="0.4" />
      <ellipse cx="66" cy="52" rx="8" ry="5.5" fill="#FFB5A0" opacity="0.4" />

      {/* ── SPEAKING DOTS ── */}
      {speaking && (
        <g>
          <circle cx="38" cy="82" r="3" fill={K.orange} opacity="0.9">
            <animate attributeName="r" values="2;4;2" dur="0.6s" repeatCount="indefinite" />
          </circle>
          <circle cx="46" cy="84" r="3" fill={K.orange} opacity="0.9">
            <animate attributeName="r" values="2;4;2" dur="0.6s" begin="0.2s" repeatCount="indefinite" />
          </circle>
          <circle cx="54" cy="82" r="3" fill={K.orange} opacity="0.9">
            <animate attributeName="r" values="2;4;2" dur="0.6s" begin="0.4s" repeatCount="indefinite" />
          </circle>
        </g>
      )}
    </svg>
  );
}

/* ═══════════════════════════════════════════════
   SPEECH BUBBLE
═══════════════════════════════════════════════ */
export function SpeechBubble({ children, accent = K.orange }) {
  return (
    <div style={{ position: 'relative' }}>
      <div style={{
        background: K.white,
        borderRadius: 14,
        padding: '8px 10px',
        fontSize: 11,
        fontWeight: 800,
        color: K.textDark,
        textAlign: 'center',
        lineHeight: 1.4,
        boxShadow: '0 3px 12px rgba(0,0,0,0.10)',
        border: `2px solid ${K.yellow}`,
      }}>
        {children}
      </div>
      {/* Tail pointing down */}
      <div style={{
        position: 'absolute',
        bottom: -9,
        left: '50%',
        transform: 'translateX(-50%)',
        width: 0,
        height: 0,
        borderLeft: '8px solid transparent',
        borderRight: '8px solid transparent',
        borderTop: `9px solid ${K.white}`,
        filter: 'drop-shadow(0 2px 1px rgba(0,0,0,0.06))',
      }} />
    </div>
  );
}

/* ═══════════════════════════════════════════════
   TIP BOX
═══════════════════════════════════════════════ */
export function TipBox({ children, accent = K.orange }) {
  return (
    <div style={{
      background: K.orangePale,
      borderRadius: 18,
      padding: '10px 10px',
      border: `2px solid ${K.yellow}`,
      boxShadow: `0 3px 12px rgba(255,140,0,0.12)`,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginBottom: 6 }}>
        <span style={{
          background: accent,
          color: K.white,
          borderRadius: 8,
          padding: '2px 8px',
          fontSize: 10,
          fontWeight: 900,
        }}>Tip</span>
        <span style={{ fontSize: 13 }}>💡</span>
      </div>
      <div style={{ fontSize: 10.5, color: K.textMid, lineHeight: 1.55, fontWeight: 600 }}>
        {children}
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════
   LESSON HEADER (orange gradient)
═══════════════════════════════════════════════ */
export function LessonHeader({
  current, total, title, subtitle,
  coins = 0, onBack, accent = K.orange,
  extraRight = null,
}) {
  return (
    <div style={{
      background: `linear-gradient(135deg, ${accent} 0%, ${K.orangeLight} 100%)`,
      padding: '10px 14px 10px',
      display: 'flex',
      alignItems: 'center',
      gap: 10,
      boxShadow: '0 3px 14px rgba(255,140,0,0.30)',
      flexShrink: 0,
    }}>
      {/* Back button */}
      {onBack && (
        <button onClick={onBack} style={{
          background: 'rgba(255,255,255,0.85)',
          border: 'none',
          borderRadius: 10,
          width: 34,
          height: 34,
          fontSize: 20,
          cursor: 'pointer',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          color: accent,
          fontWeight: 900,
          flexShrink: 0,
        }}>‹</button>
      )}

      {/* Progress + title */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 3 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span style={{ fontSize: 11, fontWeight: 800, color: 'rgba(255,255,255,0.92)' }}>
            {current} / {total}
          </span>
          <span style={{ fontSize: 12, fontWeight: 900, color: '#fff' }}>{title}</span>
        </div>
        {/* Progress bar */}
        <div style={{ height: 8, background: 'rgba(255,255,255,0.28)', borderRadius: 99, overflow: 'hidden' }}>
          <div style={{
            width: `${Math.round((current / total) * 100)}%`,
            height: '100%',
            background: '#ffffff',
            borderRadius: 99,
            transition: 'width 0.4s ease',
          }} />
        </div>
        {subtitle && (
          <div style={{
            fontFamily: "'Noto Nastaliq Urdu', serif",
            fontSize: 10,
            color: 'rgba(255,255,255,0.80)',
            direction: 'rtl',
            textAlign: 'right',
          }}>{subtitle}</div>
        )}
      </div>

      {/* Coins */}
      <div style={{
        background: 'rgba(255,255,255,0.88)',
        borderRadius: 20,
        padding: '4px 10px',
        display: 'flex',
        alignItems: 'center',
        gap: 4,
        flexShrink: 0,
      }}>
        <span style={{ fontSize: 14 }}>⭐</span>
        <span style={{ fontSize: 13, fontWeight: 900, color: accent }}>{coins}</span>
      </div>

      {extraRight}
    </div>
  );
}

/* ═══════════════════════════════════════════════
   BOTTOM BAR
═══════════════════════════════════════════════ */
export function BottomBar({
  onListen, onSpeak, onNext,
  listenDisabled = false,
  speakDisabled = false,
  listening = false,
  nextLabel = 'Next',
  accent = K.orange,
}) {
  return (
    <div style={{
      background: K.white,
      padding: '10px 14px',
      boxShadow: '0 -4px 16px rgba(0,0,0,0.08)',
      display: 'flex',
      gap: 8,
      alignItems: 'center',
      flexShrink: 0,
    }}>
      {/* Listen */}
      <button onClick={onListen} disabled={listenDisabled} style={{
        flex: 1,
        padding: '12px 8px',
        background: listenDisabled
          ? K.grayLight
          : `linear-gradient(135deg, ${accent}, ${K.orangeLight})`,
        border: 'none',
        borderRadius: 16,
        color: listenDisabled ? K.gray : K.white,
        fontSize: 13,
        fontWeight: 900,
        cursor: listenDisabled ? 'not-allowed' : 'pointer',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 6,
        boxShadow: listenDisabled ? 'none' : `0 4px 14px ${accent}55`,
        transition: 'all 0.2s',
        fontFamily: 'inherit',
      }}>
        <span style={{ fontSize: 17 }}>🔊</span> Listen
      </button>

      {/* Speak */}
      <button onClick={onSpeak} disabled={speakDisabled} style={{
        flex: 1,
        padding: '12px 8px',
        background: speakDisabled
          ? K.grayLight
          : `linear-gradient(135deg, ${K.green}, ${K.greenLight})`,
        border: 'none',
        borderRadius: 16,
        color: speakDisabled ? K.gray : K.white,
        fontSize: 13,
        fontWeight: 900,
        cursor: speakDisabled ? 'not-allowed' : 'pointer',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 6,
        boxShadow: speakDisabled ? 'none' : `0 4px 14px ${K.green}55`,
        transition: 'all 0.2s',
        fontFamily: 'inherit',
      }}>
        <span style={{ fontSize: 17 }}>🎤</span>
        {listening ? 'Listening…' : 'Speak'}
      </button>

      {/* Next */}
      <button onClick={onNext} style={{
        padding: '9px 12px',
        background: `linear-gradient(135deg, ${accent}, ${K.orangeLight})`,
        border: 'none',
        borderRadius: 12,
        color: K.white,
        fontSize: 12,
        fontWeight: 900,
        cursor: 'pointer',
        display: 'flex',
        alignItems: 'center',
        gap: 3,
        boxShadow: `0 3px 8px ${accent}44`,
        whiteSpace: 'nowrap',
        flexShrink: 0,
        fontFamily: 'inherit',
      }}>
        {nextLabel} <span style={{ fontSize: 13 }}>›</span>
      </button>
    </div>
  );
}

/* ═══════════════════════════════════════════════
   KID CARD (white card with yellow border)
═══════════════════════════════════════════════ */
export function KidCard({ children, style = {} }) {
  return (
    <div style={{
      background: K.white,
      borderRadius: 24,
      border: `2px solid ${K.yellow}`,
      boxShadow: '0 6px 24px rgba(0,0,0,0.09)',
      ...style,
    }}>
      {children}
    </div>
  );
}

/* ═══════════════════════════════════════════════
   SCORE INDICATOR (small badge)
═══════════════════════════════════════════════ */
export function ScoreBadge({ score }) {
  const color = score >= 80 ? K.green : score >= 50 ? K.orange : K.red;
  const bg    = score >= 80 ? K.greenPale : score >= 50 ? K.orangePale : K.redPale;
  const icon  = score >= 80 ? '✓' : score >= 50 ? '~' : '✗';
  return (
    <div style={{
      background: bg,
      border: `2px solid ${color}`,
      borderRadius: 14,
      padding: '8px 10px',
      textAlign: 'center',
    }}>
      <div style={{ fontSize: 22, fontWeight: 900, color }}>{score}%</div>
      <div style={{ fontSize: 10, fontWeight: 700, color, marginTop: 2 }}>
        {score >= 80 ? '⭐⭐⭐' : score >= 50 ? '⭐⭐' : '⭐'}
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════
   WAVEFORM (animated mic bars)
═══════════════════════════════════════════════ */
export function KidWaveform({ active, accent = K.orange }) {
  const heights = [0.5, 0.8, 1, 0.7, 0.9, 0.6, 1, 0.75, 0.5];
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 3, height: 28 }}>
      {heights.map((h, i) => (
        <div key={i} style={{
          width: 4,
          borderRadius: 3,
          height: active ? `${h * 24 + 4}px` : '4px',
          background: active ? accent : '#ccc',
          transition: 'height 0.15s ease',
          animation: active
            ? `kidWave 0.6s ease-in-out ${i * 0.07}s infinite alternate`
            : undefined,
        }} />
      ))}
      <style>{`@keyframes kidWave{from{transform:scaleY(0.4)}to{transform:scaleY(1)}}`}</style>
    </div>
  );
}

/* ═══════════════════════════════════════════════
   LESSON LAYOUT WRAPPER
   Left: character + bubble | Center: card | Right: tip
═══════════════════════════════════════════════ */
export function LessonLayout({ characterMsg, speaking, mood, tipContent, children, score = null }) {
  return (
    <div style={{ display: 'flex', gap: 10, alignItems: 'stretch', flex: 1, minHeight: 0 }}>

      {/* LEFT — Character */}
      <div style={{
        width: '27%',
        flexShrink: 0,
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 6,
      }}>
        <div style={{ fontSize: 22 }}>⭐</div>
        <SpeechBubble>{characterMsg}</SpeechBubble>
        <div style={{ width: '100%', flex: 1, display: 'flex', alignItems: 'flex-end', justifyContent: 'center' }}>
          <BoyCharacter speaking={speaking} mood={mood} size={100} />
        </div>
      </div>

      {/* CENTER — Main content */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 8 }}>
        {children}
      </div>

      {/* RIGHT — Tip + score */}
      <div style={{
        width: '25%',
        flexShrink: 0,
        display: 'flex',
        flexDirection: 'column',
        gap: 8,
      }}>
        {tipContent && <TipBox>{tipContent}</TipBox>}
        {score !== null && <ScoreBadge score={score} />}
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════
   QUIZ OPTION BUTTON
═══════════════════════════════════════════════ */
export function QuizOption({ label, sublabel, emoji, selected, correct, revealed, onClick }) {
  let bg     = K.white;
  let border = '#E0E0E0';
  let color  = K.textDark;
  let shadow = 'none';

  if (revealed) {
    if (correct)                   { bg = K.greenPale; border = K.green;  color = '#2E7D32'; }
    else if (selected && !correct) { bg = K.redPale;   border = K.red;    color = K.red;     }
  } else if (selected) {
    bg = K.orangePale; border = K.orange; color = K.orange;
    shadow = `0 3px 12px ${K.orange}44`;
  }

  return (
    <button onClick={onClick} disabled={revealed} style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: '10px 12px',
      background: bg, border: `2.5px solid ${border}`,
      borderRadius: 16, color, fontWeight: 800,
      cursor: revealed ? 'default' : 'pointer',
      boxShadow: shadow,
      transition: 'all 0.15s',
      textAlign: 'left',
      fontFamily: 'inherit',
      width: '100%',
    }}>
      {emoji && <span style={{ fontSize: 26, flexShrink: 0 }}>{emoji}</span>}
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 13 }}>{label}</div>
        {sublabel && <div style={{ fontSize: 10, opacity: 0.7, marginTop: 2 }}>{sublabel}</div>}
      </div>
      {revealed && correct && <span style={{ fontSize: 18, color: K.green }}>✓</span>}
      {revealed && selected && !correct && <span style={{ fontSize: 18, color: K.red }}>✗</span>}
    </button>
  );
}

/* ═══════════════════════════════════════════════
   QUIZ SHELL
═══════════════════════════════════════════════ */
export function QuizShell({ current, total, score, accent = K.purple, label = 'Quiz', children }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', background: K.cream, fontFamily: "'Nunito','Segoe UI',sans-serif" }}>
      <div style={{ background: `linear-gradient(135deg,${accent} 0%,${accent}CC 100%)`, padding: '10px 14px', flexShrink: 0 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 }}>
          <div style={{ color: 'rgba(255,255,255,0.88)', fontSize: 12, fontWeight: 700 }}>{label}</div>
          <div style={{ color: K.white, fontSize: 13, fontWeight: 900 }}>{current} / {total}</div>
        </div>
        <div style={{ height: 6, background: 'rgba(255,255,255,0.28)', borderRadius: 99, overflow: 'hidden' }}>
          <div style={{
            width: `${Math.round((current / total) * 100)}%`, height: '100%',
            background: K.white, borderRadius: 99,
            transition: 'width 0.4s ease',
          }} />
        </div>
      </div>
      <div style={{ flex: 1, overflowY: 'auto', padding: '12px 14px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        {children}
      </div>
    </div>
  );
}

/* ═══════════════════════════════════════════════
   SECTION HEADING  (Urdu label ── line ── English)
═══════════════════════════════════════════════ */
export function SectionHeading({ urdu, english, accent = K.yellow }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
      <div style={{ fontFamily: "'Noto Nastaliq Urdu',serif", fontSize: 16, fontWeight: 800, color: K.textDark, direction: 'rtl', flexShrink: 0 }}>{urdu}</div>
      <div style={{ flex: 1, height: 2, background: accent, borderRadius: 99 }} />
      <div style={{ fontSize: 13, fontWeight: 700, color: K.textMid, flexShrink: 0 }}>{english}</div>
    </div>
  );
}

/* ═══════════════════════════════════════════════
   KID BUTTON
═══════════════════════════════════════════════ */
export function KidBtn({ children, onClick, accent = K.orange, disabled = false, outline = false, full = false, small = false }) {
  return (
    <button onClick={onClick} disabled={disabled} style={{
      padding: small ? '8px 14px' : '11px 20px',
      background: disabled ? K.grayLight : outline ? 'transparent' : `linear-gradient(135deg, ${accent}, ${accent}CC)`,
      border: outline ? `2.5px solid ${accent}` : 'none',
      borderRadius: 14,
      color: disabled ? K.gray : outline ? accent : K.white,
      fontSize: small ? 12 : 13,
      fontWeight: 900,
      cursor: disabled ? 'not-allowed' : 'pointer',
      width: full ? '100%' : undefined,
      maxWidth: full ? 220 : undefined,
      margin: full ? '0 auto' : undefined,
      display: 'flex',
      boxShadow: disabled || outline ? 'none' : `0 3px 10px ${accent}44`,
      transition: 'all 0.2s',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 6,
      fontFamily: 'inherit',
    }}>{children}</button>
  );
}
