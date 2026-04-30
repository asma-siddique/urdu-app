// src/components/TutorBubble.jsx
import React from 'react';
import ProfessorAvatar from './ProfessorAvatar.jsx';
import { T } from '../theme.js';

export default function TutorBubble({ message, mood = 'happy', size = 70, side = 'right', speaking = false }) {
  const isRight = side === 'right';
  return (
    <div style={{ display:'flex', alignItems:'flex-end', gap:8, flexDirection: isRight ? 'row' : 'row-reverse', marginBottom:12 }}>
      <ProfessorAvatar mood={mood} size={size} speaking={speaking} />
      <div style={{
        background: T.white,
        borderRadius: isRight ? '16px 16px 16px 4px' : '16px 16px 4px 16px',
        padding: '10px 14px',
        maxWidth: 220,
        boxShadow: `0 2px 8px ${T.shadow}`,
        border: `1.5px solid ${T.lightGray}`,
        position: 'relative',
      }}>
        <p style={{
          margin: 0,
          fontSize: 13,
          lineHeight: 1.5,
          color: T.navy,
          fontFamily: "'Noto Nastaliq Urdu', serif",
          direction: 'rtl',
        }}>{message}</p>
      </div>
    </div>
  );
}
