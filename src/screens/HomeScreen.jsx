// src/screens/HomeScreen.jsx
import React from 'react';
import ProfessorAvatar from '../components/ProfessorAvatar.jsx';
import { PBar } from '../components/UI.jsx';
import { T } from '../theme.js';
import { getGreeting } from '../utils.js';

const MODULES = [
  { id:'haroof', title:'حروف تہجی', sub:'Alphabet',   icon:'ا',   color:T.purple,  desc:'Learn all 40 Urdu letters' },
  { id:'lafz',   title:'الفاظ',     sub:'Words',       icon:'📝',  color:T.teal,    desc:'40+ vocabulary words'       },
  { id:'jumlay', title:'جملے',      sub:'Sentences',   icon:'💬',  color:T.orange,  desc:'12 everyday sentences'      },
  { id:'rang',   title:'رنگ',       sub:'Colours',     icon:'🎨',  color:T.pink,    desc:'14 colours in Urdu'         },
  { id:'quiz',   title:'کوئز',      sub:'Quiz',        icon:'🏆',  color:T.green,   desc:'Test your knowledge!'       },
];

export default function HomeScreen({ user, completedMap = {}, starsMap = {}, onNavigate }) {
  const now     = new Date();
  const hour    = now.getHours();
  const greet   = getGreeting(hour);

  const totalModules   = MODULES.length;
  const doneModules    = Object.keys(completedMap).filter(k => completedMap[k]).length;
  const totalStars     = Object.values(starsMap).reduce((s, v) => s + (v || 0), 0);

  return (
    <div style={{
      flex:1, overflowY:'auto',
      background:T.screenBg,
      display:'flex', flexDirection:'column',
    }}>
      {/* Hero banner */}
      <div style={{
        background:`linear-gradient(135deg, ${T.purple} 0%, ${T.navyLight} 100%)`,
        padding:'24px 20px 28px',
        position:'relative', overflow:'hidden',
      }}>
        {/* Decorative circles */}
        <div style={{ position:'absolute', top:-30, right:-30, width:120, height:120, borderRadius:'50%', background:'rgba(255,255,255,0.06)' }} />
        <div style={{ position:'absolute', bottom:-20, left:-20, width:80,  height:80,  borderRadius:'50%', background:'rgba(255,255,255,0.06)' }} />

        <div style={{ display:'flex', alignItems:'center', gap:14, position:'relative', zIndex:1 }}>
          <ProfessorAvatar mood="happy" size={72} floating />
          <div>
            {/* Greeting line */}
            <div style={{ display:'flex', alignItems:'center', gap:6, marginBottom:2 }}>
              <span style={{ fontSize:15, lineHeight:1 }}>{greet.emoji}</span>
              <span style={{ color:'rgba(255,255,255,0.80)', fontSize:12, fontWeight:600 }}>
                {greet.eng}
              </span>
            </div>
            {/* Name */}
            <div style={{ color:T.white, fontSize:22, fontWeight:900, lineHeight:1.2 }}>
              {user.name}!
            </div>
            {/* Urdu greeting phrase */}
            <div style={{
              fontFamily:"'Noto Nastaliq Urdu', serif",
              color:'rgba(255,255,255,0.75)',
              fontSize:14, direction:'rtl', marginTop:2,
            }}>
              {greet.urdu}
            </div>
          </div>
        </div>

        {/* Progress strip */}
        <div style={{
          background:'rgba(255,255,255,0.12)',
          borderRadius:14, padding:'10px 14px',
          marginTop:16, position:'relative', zIndex:1,
          display:'flex', alignItems:'center', gap:12,
        }}>
          <div style={{ flex:1 }}>
            <div style={{ display:'flex', justifyContent:'space-between', marginBottom:5 }}>
              <span style={{ color:'rgba(255,255,255,0.8)', fontSize:11, fontWeight:600 }}>
                Progress
              </span>
              <span style={{ color:T.yellow, fontSize:11, fontWeight:700 }}>
                {doneModules}/{totalModules} modules
              </span>
            </div>
            <PBar value={doneModules} max={totalModules} color={T.yellow} height={7} />
          </div>
          <div style={{ textAlign:'center' }}>
            <div style={{ fontSize:18 }}>⭐</div>
            <div style={{ color:T.yellow, fontWeight:900, fontSize:13 }}>{totalStars}</div>
          </div>
        </div>
      </div>

      {/* Modules grid */}
      <div style={{ padding:'20px 16px', display:'flex', flexDirection:'column', gap:12 }}>
        <div style={{
          fontFamily:"'Noto Nastaliq Urdu', serif",
          fontSize:16, fontWeight:800,
          color:T.navy, direction:'rtl',
          marginBottom:4,
        }}>سبق شروع کریں</div>

        <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:12 }}>
          {MODULES.map(mod => {
            const done  = !!completedMap[mod.id];
            const stars = starsMap[mod.id] || 0;
            return (
              <button
                key={mod.id}
                onClick={() => onNavigate(mod.id)}
                style={{
                  background:T.white,
                  border:`2px solid ${done ? mod.color + '66' : T.lightGray}`,
                  borderRadius:20,
                  padding:'16px 12px',
                  cursor:'pointer',
                  textAlign:'center',
                  boxShadow:`0 2px 10px ${T.shadow}`,
                  transition:'all 0.2s',
                  position:'relative',
                }}
              >
                {done && (
                  <div style={{
                    position:'absolute', top:8, right:8,
                    background:mod.color, color:'white',
                    borderRadius:'50%', width:20, height:20,
                    fontSize:11, fontWeight:900,
                    display:'flex', alignItems:'center', justifyContent:'center',
                  }}>✓</div>
                )}
                <div style={{
                  fontSize: mod.id === 'haroof' ? 26 : 30,
                  fontFamily: mod.id === 'haroof' ? "'Noto Nastaliq Urdu', serif" : undefined,
                  color: mod.id === 'haroof' ? mod.color : undefined,
                  marginBottom:8,
                }}>{mod.icon}</div>
                <div style={{
                  fontFamily:"'Noto Nastaliq Urdu', serif",
                  fontSize:16, fontWeight:800,
                  color:mod.color, direction:'rtl',
                  marginBottom:2,
                }}>{mod.title}</div>
                <div style={{ fontSize:11, color:T.darkGray, fontWeight:600 }}>{mod.sub}</div>
                {stars > 0 && (
                  <div style={{ marginTop:6, fontSize:12 }}>
                    {'⭐'.repeat(stars)}{'☆'.repeat(3-stars)}
                  </div>
                )}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}
