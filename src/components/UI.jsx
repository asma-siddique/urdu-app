// src/components/UI.jsx
import React, { useEffect, useState } from 'react';
import { T } from '../theme.js';

/** Progress bar */
export function PBar({ value, max, color = T.purple, height = 8 }) {
  const pct = Math.round((value / max) * 100);
  return (
    <div style={{ background: T.lightGray, borderRadius: 99, height, overflow: 'hidden', width: '100%' }}>
      <div style={{
        width: `${pct}%`, height: '100%',
        background: color,
        borderRadius: 99,
        transition: 'width 0.4s ease',
      }} />
    </div>
  );
}

/** Star badge */
export function StarBadge({ stars = 0 }) {
  return (
    <div style={{ display:'flex', gap:4, justifyContent:'center' }}>
      {[1,2,3].map(i => (
        <span key={i} style={{ fontSize:22, filter: i <= stars ? 'none' : 'grayscale(1) opacity(0.3)' }}>
          {i <= stars ? '⭐' : '☆'}
        </span>
      ))}
    </div>
  );
}

/** Animated waveform */
export function Waveform({ active = false, score = null, color = T.purple }) {
  const bars = [0.4,0.7,1,0.8,0.6,0.9,0.5,0.7,0.4];
  if (score !== null) {
    const c = score >= 80 ? T.green : score >= 50 ? T.orange : T.red;
    return (
      <div style={{ display:'flex', alignItems:'center', gap:3, height:36 }}>
        {bars.map((h,i) => (
          <div key={i} style={{
            width:5, height: `${h * (score/100) * 32 + 4}px`,
            background: c, borderRadius:3,
          }} />
        ))}
      </div>
    );
  }
  return (
    <div style={{ display:'flex', alignItems:'center', gap:3, height:36 }}>
      {bars.map((h,i) => (
        <div key={i} style={{
          width:5, height: active ? `${h*32+4}px` : '4px',
          background: active ? color : T.midGray,
          borderRadius:3,
          transition:'height 0.15s ease',
          animation: active ? `waveBar 0.6s ease-in-out ${i*0.07}s infinite alternate` : undefined,
        }} />
      ))}
    </div>
  );
}

/** Button */
export function Btn({ children, onClick, color = T.purple, outline = false, disabled = false, full = false, sm = false, emoji = null }) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      style={{
        display:'flex', alignItems:'center', justifyContent:'center', gap:6,
        padding: sm ? '7px 16px' : '11px 22px',
        background: disabled ? T.lightGray : outline ? 'transparent' : color,
        color: disabled ? T.midGray : outline ? color : T.white,
        border: outline ? `2px solid ${color}` : 'none',
        borderRadius: 14,
        fontSize: sm ? 13 : 15,
        fontWeight: 700,
        cursor: disabled ? 'not-allowed' : 'pointer',
        width: full ? '100%' : undefined,
        transition: 'all 0.2s',
        fontFamily: "'Noto Nastaliq Urdu', serif",
        boxShadow: disabled ? 'none' : `0 3px 10px ${color}55`,
      }}
    >
      {emoji && <span style={{ fontSize: sm ? 14 : 18 }}>{emoji}</span>}
      {children}
    </button>
  );
}

/** Confetti */
export function Confetti() {
  const emojis = ['🎉','⭐','🌟','✨','🎊','💫','🌈'];
  const pieces = Array.from({ length: 18 }, (_, i) => ({
    id: i,
    emoji: emojis[i % emojis.length],
    left: `${Math.random()*90}%`,
    delay: `${Math.random()*0.8}s`,
    duration: `${1.2 + Math.random()*0.8}s`,
  }));
  return (
    <div style={{ position:'absolute', inset:0, pointerEvents:'none', overflow:'hidden', zIndex:99 }}>
      {pieces.map(p => (
        <div key={p.id} style={{
          position:'absolute', left: p.left, top:'-10%',
          fontSize:20,
          animation: `confettiFall ${p.duration} ${p.delay} ease-in forwards`,
        }}>{p.emoji}</div>
      ))}
    </div>
  );
}

/** Badge popup */
export function BadgePopup({ badge, onClose }) {
  return (
    <div style={{
      position:'absolute', inset:0,
      background:'rgba(0,0,0,0.55)',
      zIndex:200,
      display:'flex', alignItems:'center', justifyContent:'center',
    }} onClick={onClose}>
      <div style={{
        background: T.white,
        borderRadius:24,
        padding:'32px 28px',
        textAlign:'center',
        animation:'badgePop 0.4s ease',
        maxWidth:280,
        boxShadow:`0 8px 32px ${T.shadowMd}`,
      }}>
        <div style={{ fontSize:56, marginBottom:8 }}>{badge.icon}</div>
        <div style={{ fontSize:20, fontWeight:900, color:T.navy, marginBottom:4 }}>{badge.label}</div>
        <div style={{ fontSize:13, color:T.darkGray, marginBottom:20 }}>{badge.desc}</div>
        <Btn onClick={onClose} color={T.purple} sm>شاباش! 🎉</Btn>
      </div>
    </div>
  );
}

/** Score display */
export function ScoreDisplay({ score, max = 100 }) {
  const pct = Math.round((score / max) * 100);
  const stars = pct >= 80 ? 3 : pct >= 50 ? 2 : 1;
  const feedback = pct >= 80 ? 'شاباش!' : pct >= 50 ? 'اچھا ہے!' : 'محنت کریں!';
  const color = pct >= 80 ? T.green : pct >= 50 ? T.orange : T.red;
  return (
    <div style={{ textAlign:'center' }}>
      <div style={{ fontSize:36, fontWeight:900, color }}>{pct}%</div>
      <StarBadge stars={stars} />
      <div style={{
        fontFamily:"'Noto Nastaliq Urdu', serif",
        fontSize:20, fontWeight:700, color, marginTop:6,
        direction:'rtl',
      }}>{feedback}</div>
    </div>
  );
}

/** Speaking notice banner */
export function SpeakingNotice() {
  return (
    <div style={{
      background: T.orange,
      color: T.white,
      borderRadius: 12,
      padding: '8px 16px',
      fontSize: 13,
      fontWeight: 700,
      textAlign:'center',
      fontFamily:"'Noto Nastaliq Urdu', serif",
      direction:'rtl',
      display:'flex', alignItems:'center', justifyContent:'center', gap:8,
    }}>
      <span>🔊</span>
      <span>اُستاد جی بول رہے ہیں... سنیں!</span>
    </div>
  );
}
