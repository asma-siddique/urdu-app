// src/screens/SplashScreen.jsx
import React, { useEffect } from 'react';
import ProfessorAvatar from '../components/ProfessorAvatar.jsx';
import { T } from '../theme.js';

export default function SplashScreen({ onDone }) {
  useEffect(() => {
    const t = setTimeout(onDone, 2800);
    return () => clearTimeout(t);
  }, [onDone]);

  return (
    <div style={{
      flex:1, display:'flex', flexDirection:'column',
      alignItems:'center', justifyContent:'center',
      background:`linear-gradient(160deg, ${T.purple} 0%, ${T.navyMid} 100%)`,
      gap:24,
    }}>
      <div style={{ animation:'tutorFloat 2.5s ease-in-out infinite' }}>
        <ProfessorAvatar mood="excited" size={130} />
      </div>

      <div style={{ textAlign:'center' }}>
        <div style={{
          fontSize:38, fontWeight:900,
          fontFamily:"'Noto Nastaliq Urdu', serif",
          color:T.white, direction:'rtl',
          marginBottom:6,
        }}>
          اردو سیکھیں
        </div>
        <div style={{ fontSize:16, color:'rgba(255,255,255,0.75)', fontWeight:600 }}>
          AI-Powered Urdu Learning
        </div>
      </div>

      <div style={{ display:'flex', gap:8, marginTop:8 }}>
        {[0,1,2].map(i => (
          <div key={i} style={{
            width:8, height:8, borderRadius:'50%',
            background:`rgba(255,255,255,${0.4 + i*0.2})`,
            animation:`pulse 1.2s ease-in-out ${i*0.3}s infinite`,
          }} />
        ))}
      </div>
    </div>
  );
}
