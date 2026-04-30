// src/components/ProfessorAvatar.jsx
import React from 'react';
import { T } from '../theme.js';

const moods = {
  happy:    { eyeY: 38, mouthD: "M 30 52 Q 40 62 50 52", brow: "M 28 30 Q 33 26 38 30", browR: "M 42 30 Q 47 26 52 30", color: T.yellow },
  sad:      { eyeY: 38, mouthD: "M 30 58 Q 40 50 50 58", brow: "M 28 28 Q 33 32 38 28", browR: "M 42 28 Q 47 32 52 28", color: T.teal },
  neutral:  { eyeY: 38, mouthD: "M 30 55 Q 40 55 50 55", brow: "M 28 30 Q 33 28 38 30", browR: "M 42 30 Q 47 28 52 30", color: T.midGray },
  excited:  { eyeY: 36, mouthD: "M 27 50 Q 40 65 53 50", brow: "M 26 28 Q 33 22 40 28", browR: "M 40 28 Q 47 22 54 28", color: T.orange },
  thinking: { eyeY: 38, mouthD: "M 33 55 Q 38 52 45 55", brow: "M 28 30 Q 33 26 38 30", browR: "M 42 32 Q 47 30 52 32", color: T.purple },
  praise:   { eyeY: 34, mouthD: "M 26 50 Q 40 68 54 50", brow: "M 26 26 Q 33 20 40 26", browR: "M 40 26 Q 47 20 54 26", color: T.green },
  speaking: { eyeY: 38, mouthD: "M 30 52 Q 40 60 50 52", brow: "M 28 30 Q 33 26 38 30", browR: "M 42 30 Q 47 26 52 30", color: T.teal },
};

export default function ProfessorAvatar({ mood = 'neutral', size = 100, floating = false, speaking = false }) {
  const m = moods[mood] || moods.neutral;
  const s = size;
  const scale = s / 100;

  return (
    <div style={{
      width: s, height: s,
      animation: floating ? 'tutorFloat 3s ease-in-out infinite' : undefined,
      display: 'inline-block',
      position: 'relative',
    }}>
      <svg viewBox="0 0 80 100" width={s} height={s}>
        {/* Turban */}
        <ellipse cx="40" cy="20" rx="22" ry="14" fill={T.teal} />
        <ellipse cx="40" cy="14" rx="18" ry="8" fill={T.tealLight} />
        <rect x="18" y="20" width="44" height="6" rx="3" fill={T.teal} />
        {/* Turban knot */}
        <circle cx="40" cy="11" r="4" fill={T.orange} />

        {/* Face */}
        <ellipse cx="40" cy="44" rx="20" ry="22" fill="#FDBCB4" />

        {/* Beard */}
        <ellipse cx="40" cy="62" rx="15" ry="8" fill="#c8a882" />
        <ellipse cx="33" cy="65" rx="6" ry="5" fill="#b8956a" />
        <ellipse cx="47" cy="65" rx="6" ry="5" fill="#b8956a" />
        <ellipse cx="40" cy="67" rx="8" ry="4" fill="#c8a882" />

        {/* Eyes */}
        <ellipse cx="33" cy={m.eyeY} rx="4" ry="4.5" fill="white" />
        <ellipse cx="47" cy={m.eyeY} rx="4" ry="4.5" fill="white" />
        <circle  cx="33" cy={m.eyeY} r="2.5" fill="#2d2d2d" />
        <circle  cx="47" cy={m.eyeY} r="2.5" fill="#2d2d2d" />
        <circle  cx="34" cy={m.eyeY - 1} r="0.8" fill="white" />
        <circle  cx="48" cy={m.eyeY - 1} r="0.8" fill="white" />

        {/* Glasses */}
        <rect x="26" y={m.eyeY - 6} width="12" height="11" rx="3" fill="none" stroke={T.navy} strokeWidth="1.5" />
        <rect x="42" y={m.eyeY - 6} width="12" height="11" rx="3" fill="none" stroke={T.navy} strokeWidth="1.5" />
        <line x1="38" y1={m.eyeY - 1} x2="42" y2={m.eyeY - 1} stroke={T.navy} strokeWidth="1.5" />
        <line x1="20" y1={m.eyeY - 1} x2="26" y2={m.eyeY - 1} stroke={T.navy} strokeWidth="1.5" />
        <line x1="54" y1={m.eyeY - 1} x2="60" y2={m.eyeY - 1} stroke={T.navy} strokeWidth="1.5" />

        {/* Eyebrows */}
        <path d={m.brow}  fill="none" stroke="#5d4037" strokeWidth="2" strokeLinecap="round" />
        <path d={m.browR} fill="none" stroke="#5d4037" strokeWidth="2" strokeLinecap="round" />

        {/* Nose */}
        <ellipse cx="40" cy="48" rx="2.5" ry="2" fill="#e8967a" />

        {/* Mouth */}
        <path d={m.mouthD} fill="none" stroke="#c0694e" strokeWidth="2" strokeLinecap="round" />

        {/* Speaking dots */}
        {speaking && (
          <>
            <circle cx="33" cy="74" r="2.5" fill={T.orange} opacity="0.9">
              <animate attributeName="r" values="2.5;3.5;2.5" dur="0.6s" repeatCount="indefinite" />
            </circle>
            <circle cx="40" cy="76" r="2.5" fill={T.orange} opacity="0.9">
              <animate attributeName="r" values="2.5;3.5;2.5" dur="0.6s" begin="0.2s" repeatCount="indefinite" />
            </circle>
            <circle cx="47" cy="74" r="2.5" fill={T.orange} opacity="0.9">
              <animate attributeName="r" values="2.5;3.5;2.5" dur="0.6s" begin="0.4s" repeatCount="indefinite" />
            </circle>
          </>
        )}

        {/* Body / Robe */}
        <path d="M 20 82 Q 20 72 40 70 Q 60 72 60 82 L 65 100 L 15 100 Z" fill={T.purple} />
        {/* Book */}
        <rect x="15" y="76" width="14" height="16" rx="2" fill={T.orange} />
        <rect x="16" y="77" width="12" height="14" rx="1" fill="#fff3e0" />
        <line x1="22" y1="80" x2="27" y2="80" stroke={T.orange} strokeWidth="1" />
        <line x1="22" y1="83" x2="27" y2="83" stroke={T.orange} strokeWidth="1" />
        <line x1="22" y1="86" x2="27" y2="86" stroke={T.orange} strokeWidth="1" />
        {/* Pointer */}
        <line x1="56" y1="72" x2="68" y2="62" stroke={T.darkGray} strokeWidth="2" strokeLinecap="round" />
        <circle cx="68" cy="61" r="2" fill={T.red} />
      </svg>
    </div>
  );
}
