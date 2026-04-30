// src/components/BottomNav.jsx
import React from 'react';
import { T } from '../theme.js';

const NAV = [
  { id:'home',   label:'گھر',   icon:'🏠' },
  { id:'haroof', label:'حروف',  icon:'ا'  },
  { id:'lafz',   label:'الفاظ', icon:'📝' },
  { id:'jumlay', label:'جملے',  icon:'💬' },
  { id:'rang',   label:'رنگ',   icon:'🎨' },
  { id:'quiz',   label:'کوئز',  icon:'🏆' },
];

export default function BottomNav({ active, onNavigate }) {
  return (
    <div style={{
      display:'flex',
      background: T.navBg,
      borderTop:`1.5px solid ${T.lightGray}`,
      boxShadow:`0 -2px 12px ${T.shadow}`,
      height:60,
    }}>
      {NAV.map(item => {
        const isActive = active === item.id;
        const color = item.id === 'rang' ? T.pink : T.purple;
        return (
          <button
            key={item.id}
            onClick={() => onNavigate(item.id)}
            style={{
              flex:1,
              border:'none',
              background:'none',
              cursor:'pointer',
              display:'flex', flexDirection:'column', alignItems:'center', justifyContent:'center', gap:2,
              padding:'4px 0',
              transition:'all 0.2s',
            }}
          >
            <span style={{
              fontSize: item.id === 'haroof' ? 16 : 18,
              fontFamily: item.id === 'haroof' ? "'Noto Nastaliq Urdu', serif" : undefined,
              filter: isActive ? 'none' : 'grayscale(0.5) opacity(0.6)',
            }}>{item.icon}</span>
            <span style={{
              fontSize:9,
              fontWeight: isActive ? 800 : 500,
              color: isActive ? color : T.darkGray,
              fontFamily:"'Noto Nastaliq Urdu', serif",
            }}>{item.label}</span>
            {isActive && (
              <div style={{ width:4, height:4, borderRadius:'50%', background:color }} />
            )}
          </button>
        );
      })}
    </div>
  );
}
