// src/screens/HomeScreen.jsx — Kid-friendly Home
import React from 'react';
import { K, BoyCharacter, SpeechBubble, SectionHeading } from '../components/KidUI.jsx';
import { getGreeting } from '../utils.js';

const MODULES = [
  { id: 'haroof', title: 'حروف تہجی', sub: 'Alphabet',  accent: K.orange,  desc: 'Learn all 40 letters', emoji: '📖', icon: 'ا' },
  { id: 'lafz',   title: 'الفاظ',     sub: 'Words',      accent: K.teal,    desc: '40+ vocabulary words', emoji: '🔤', icon: '📝' },
  { id: 'jumlay', title: 'جملے',      sub: 'Sentences',  accent: K.purple,  desc: '12 everyday sentences', emoji: '🗣️', icon: '💬' },
  { id: 'rang',   title: 'رنگ',       sub: 'Colours',    accent: K.pink,    desc: '14 colours in Urdu',   emoji: '🌈', icon: '🎨' },
  { id: 'quiz',   title: 'کوئز',      sub: 'Quiz',       accent: K.green,   desc: 'Test your knowledge!', emoji: '✅', icon: '🏆' },
];

export default function HomeScreen({ user, completedMap = {}, starsMap = {}, onNavigate }) {
  const hour  = new Date().getHours();
  const greet = getGreeting(hour);
  const totalStars  = Object.values(starsMap).reduce((s, v) => s + (v || 0), 0);
  const doneModules = Object.keys(completedMap).filter(k => completedMap[k]).length;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', background: K.cream, fontFamily: "'Nunito','Segoe UI',sans-serif", overflowY: 'auto' }}>

      {/* Hero banner */}
      <div style={{ background: `linear-gradient(135deg,${K.orange} 0%,${K.orangeLight} 100%)`, padding: '20px 16px 24px', position: 'relative', overflow: 'hidden', boxShadow: `0 4px 20px ${K.orange}44` }}>
        <div style={{ position: 'absolute', top: -30, right: -30, width: 130, height: 130, borderRadius: '50%', background: 'rgba(255,255,255,0.10)' }} />
        <div style={{ position: 'absolute', bottom: -20, left: -20, width: 90, height: 90, borderRadius: '50%', background: 'rgba(255,255,255,0.08)' }} />

        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 14, position: 'relative', zIndex: 1 }}>
          <div style={{ flexShrink: 0 }}><BoyCharacter mood="happy" size={90} /></div>
          <div style={{ flex: 1 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
              <span style={{ fontSize: 16 }}>{greet.emoji}</span>
              <span style={{ color: 'rgba(255,255,255,0.88)', fontSize: 13, fontWeight: 700 }}>{greet.eng}</span>
            </div>
            <div style={{ color: K.white, fontSize: 22, fontWeight: 900, lineHeight: 1.2 }}>{user.name}! 👋</div>
            <div style={{ fontFamily: "'Noto Nastaliq Urdu',serif", color: 'rgba(255,255,255,0.80)', fontSize: 14, direction: 'rtl', marginTop: 3 }}>{greet.urdu}</div>
          </div>
          <div style={{ background: 'rgba(255,255,255,0.92)', borderRadius: 20, padding: '6px 12px', display: 'flex', alignItems: 'center', gap: 5, flexShrink: 0, boxShadow: '0 2px 8px rgba(0,0,0,0.12)' }}>
            <span style={{ fontSize: 18 }}>⭐</span>
            <span style={{ fontSize: 16, fontWeight: 900, color: K.orange }}>{totalStars}</span>
          </div>
        </div>

        {/* Progress strip */}
        <div style={{ background: 'rgba(255,255,255,0.15)', borderRadius: 16, padding: '10px 14px', marginTop: 16, position: 'relative', zIndex: 1 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
            <span style={{ color: 'rgba(255,255,255,0.88)', fontSize: 12, fontWeight: 700 }}>Overall Progress</span>
            <span style={{ color: K.white, fontSize: 12, fontWeight: 800 }}>{doneModules}/{MODULES.length} modules</span>
          </div>
          <div style={{ height: 8, background: 'rgba(255,255,255,0.28)', borderRadius: 99, overflow: 'hidden' }}>
            <div style={{ width: `${Math.round((doneModules / MODULES.length) * 100)}%`, height: '100%', background: K.white, borderRadius: 99, transition: 'width 0.4s ease' }} />
          </div>
        </div>
      </div>

      {/* Module grid */}
      <div style={{ padding: '16px 14px', display: 'flex', flexDirection: 'column', gap: 12 }}>
        <SectionHeading urdu="سبق شروع کریں" english="Start Learning" />

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          {MODULES.map(mod => {
            const done  = !!completedMap[mod.id];
            const stars = starsMap[mod.id] || 0;
            return (
              <button key={mod.id} onClick={() => onNavigate(mod.id)} style={{ background: K.white, border: `2.5px solid ${done ? mod.accent + '66' : K.yellow}`, borderRadius: 22, padding: '18px 12px 14px', cursor: 'pointer', textAlign: 'center', boxShadow: `0 4px 16px ${mod.accent}18`, transition: 'all 0.2s', position: 'relative', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, fontFamily: 'inherit' }}>
                {done && (
                  <div style={{ position: 'absolute', top: 8, right: 8, background: mod.accent, color: K.white, borderRadius: '50%', width: 22, height: 22, fontSize: 12, fontWeight: 900, display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: `0 2px 6px ${mod.accent}55` }}>✓</div>
                )}
                <div style={{ width: 56, height: 56, borderRadius: 18, background: `${mod.accent}18`, border: `2px solid ${mod.accent}33`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: mod.id === 'haroof' ? 28 : 30, fontFamily: mod.id === 'haroof' ? "'Noto Nastaliq Urdu',serif" : undefined, color: mod.id === 'haroof' ? mod.accent : undefined }}>
                  {mod.id === 'haroof' ? mod.icon : mod.emoji}
                </div>
                <div style={{ fontFamily: "'Noto Nastaliq Urdu',serif", fontSize: 16, fontWeight: 800, color: mod.accent, direction: 'rtl' }}>{mod.title}</div>
                <div style={{ fontSize: 11, color: K.textMid, fontWeight: 700 }}>{mod.sub}</div>
                <div style={{ fontSize: 10, color: K.gray, fontWeight: 600, lineHeight: 1.3 }}>{mod.desc}</div>
                {stars > 0 && <div style={{ fontSize: 13 }}>{'⭐'.repeat(stars)}{'☆'.repeat(3 - stars)}</div>}
                <div style={{ marginTop: 4, background: `linear-gradient(135deg,${mod.accent},${mod.accent}CC)`, color: K.white, borderRadius: 12, padding: '4px 14px', fontSize: 11, fontWeight: 800, boxShadow: `0 2px 8px ${mod.accent}44` }}>
                  {done ? 'Review' : 'Start'} →
                </div>
              </button>
            );
          })}
        </div>

        {/* Footer motivator */}
        <div style={{ background: K.white, borderRadius: 18, padding: '12px 16px', border: `2px solid ${K.yellow}`, display: 'flex', alignItems: 'center', gap: 12 }}>
          <span style={{ fontSize: 28, flexShrink: 0 }}>🌟</span>
          <div>
            <div style={{ fontSize: 13, fontWeight: 800, color: K.textDark }}>Keep it up!</div>
            <div style={{ fontFamily: "'Noto Nastaliq Urdu',serif", fontSize: 12, color: K.textMid, direction: 'rtl', marginTop: 2 }}>ہر روز تھوڑا سیکھیں</div>
          </div>
        </div>
      </div>
    </div>
  );
}
