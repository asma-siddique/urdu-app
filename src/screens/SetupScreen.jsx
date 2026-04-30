// src/screens/SetupScreen.jsx
import React, { useState } from 'react';
import ProfessorAvatar from '../components/ProfessorAvatar.jsx';
import { Btn } from '../components/UI.jsx';
import { T } from '../theme.js';
import { capitaliseName } from '../utils.js';

const AVATARS = [
  { id:'boy',  emoji:'👦', label:'Boy'  },
  { id:'girl', emoji:'👧', label:'Girl' },
];

export default function SetupScreen({ onDone }) {
  const [step, setStep]       = useState(0); // 0=avatar, 1=name
  const [avatar, setAvatar]   = useState('boy');
  const [nameInput, setName]  = useState('');

  const cleanName = capitaliseName(nameInput);

  const handleFinish = () => {
    if (!cleanName) return;
    onDone({ name: cleanName, avatar });
  };

  return (
    <div style={{
      flex:1, display:'flex', flexDirection:'column',
      background:`linear-gradient(160deg, ${T.purple}ee 0%, ${T.navy} 100%)`,
      padding:'32px 24px 24px',
      gap:20,
    }}>
      {/* Header */}
      <div style={{ textAlign:'center' }}>
        <ProfessorAvatar mood="happy" size={90} floating />
        <div style={{
          marginTop:12,
          fontSize:22, fontWeight:900,
          fontFamily:"'Noto Nastaliq Urdu', serif",
          color:T.white, direction:'rtl',
        }}>خوش آمدید!</div>
        <div style={{ color:'rgba(255,255,255,0.75)', fontSize:13, marginTop:4 }}>
          Welcome! Let's get you set up.
        </div>
      </div>

      {/* Card */}
      <div style={{
        background:T.white, borderRadius:24,
        padding:24, flex:1,
        display:'flex', flexDirection:'column', gap:20,
      }}>
        {step === 0 && (
          <>
            <div style={{ textAlign:'center' }}>
              <div style={{ fontSize:16, fontWeight:700, color:T.navy, marginBottom:16 }}>
                Choose your avatar
              </div>
              <div style={{ display:'flex', gap:16, justifyContent:'center' }}>
                {AVATARS.map(a => (
                  <button
                    key={a.id}
                    onClick={() => setAvatar(a.id)}
                    style={{
                      width:90, height:90,
                      borderRadius:20,
                      border:`3px solid ${avatar === a.id ? T.purple : T.lightGray}`,
                      background: avatar === a.id ? T.purple+'15' : T.offWhite,
                      cursor:'pointer',
                      fontSize:44,
                      transition:'all 0.2s',
                    }}
                  >{a.emoji}</button>
                ))}
              </div>
            </div>
            <Btn onClick={() => setStep(1)} color={T.purple} full>Next</Btn>
          </>
        )}

        {step === 1 && (
          <>
            <div>
              <div style={{ fontSize:16, fontWeight:700, color:T.navy, marginBottom:12 }}>
                What's your name?
              </div>
              <input
                value={nameInput}
                onChange={e => setName(e.target.value)}
                placeholder="Enter your name..."
                maxLength={20}
                style={{
                  width:'100%', padding:'12px 16px',
                  borderRadius:14, fontSize:16,
                  border:`2px solid ${nameInput ? T.purple : T.lightGray}`,
                  outline:'none', fontWeight:600,
                  color:T.navy,
                  boxSizing:'border-box',
                  transition:'border-color 0.2s',
                }}
              />
            </div>

            {cleanName && (
              <div style={{
                background:`${T.purple}12`,
                borderRadius:16, padding:'14px 18px',
                textAlign:'center',
              }}>
                <div style={{ fontSize:13, color:T.darkGray, marginBottom:4 }}>Preview</div>
                <div style={{ fontSize:22, fontWeight:900, color:T.purple }}>
                  {AVATARS.find(a => a.id === avatar)?.emoji} {cleanName}
                </div>
                <div style={{ fontSize:12, color:T.darkGray, marginTop:4 }}>
                  Ready to learn Urdu!
                </div>
              </div>
            )}

            <div style={{ display:'flex', gap:10, marginTop:'auto' }}>
              <Btn onClick={() => setStep(0)} color={T.midGray} outline sm>Back</Btn>
              <Btn onClick={handleFinish} color={T.purple} full disabled={!cleanName}>
                Start Learning!
              </Btn>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
