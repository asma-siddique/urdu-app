// src/screens/RangScreen.jsx - 15 colors, speaks URDU
import React, { useState, useEffect } from 'react';
import ProfessorAvatar from '../components/ProfessorAvatar.jsx';
import { Btn, Waveform, ScoreDisplay, SpeakingNotice } from '../components/UI.jsx';
import { T } from '../theme.js';
import { COLORS } from '../data.js';
import { useTTS, useSpeechRecognition } from '../hooks.js';
import { scorePronunciation } from '../utils.js';

export default function RangScreen({ onComplete }) {
  const [idx, setIdx]                   = useState(0);
  const [score, setScore]               = useState(null);
  const [listening, setListening]       = useState(false);
  const [avatarSpoken, setAvatarSpoken] = useState(false);

  const color = COLORS[idx];
  const { speak, stop, isSpeaking } = useTTS();
  const { listen }                  = useSpeechRecognition();

  const speakColor = (c) => {
    setAvatarSpoken(false);
    speak(`${c.u}۔`, () => setAvatarSpoken(true));
  };

  useEffect(() => {
    setScore(null);
    setAvatarSpoken(false);
    const t = setTimeout(() => speakColor(color), 400);
    return () => { clearTimeout(t); stop(); };
  }, [idx]); // eslint-disable-line

  const handleListen = () => {
    if (!avatarSpoken || isSpeaking) return;
    setListening(true);
    setScore(null);
    listen(color.r, (raw, conf, transcript) => {
      setListening(false);
      const s = raw!==null ? raw : scorePronunciation(transcript, color.r, conf);
      setScore(s);
      speak(s>=80 ? 'شاباش! رنگ صحیح بولا!' : s>=50 ? 'اچھا ہے!' : 'دوبارہ کوشش کریں۔', null);
    });
  };

  const handleNext = () => {
    if (idx < COLORS.length-1) setIdx(i=>i+1);
    else onComplete({ stars:3, moduleId:'rang' });
  };

  return (
    <div style={{ flex:1, overflowY:'auto', background:T.screenBg,
      display:'flex', flexDirection:'column', padding:16, gap:12 }}>

      {/* Description */}
      <div style={{ background:`${T.pink}18`, borderRadius:14, padding:'10px 14px',
        fontFamily:"'Noto Nastaliq Urdu',serif", fontSize:13, color:T.pink,
        textAlign:'right', direction:'rtl' }}>
        اردو میں رنگوں کے نام سیکھیں
      </div>

      {/* Color palette dots */}
      <div style={{ display:'flex', gap:4, flexWrap:'wrap', justifyContent:'center' }}>
        {COLORS.map((c,i) => (
          <button key={i} onClick={() => setIdx(i)} title={c.eng} style={{
            width:26, height:26, borderRadius:'50%',
            background:c.hex, border:`3px solid ${i===idx ? T.navy : 'transparent'}`,
            cursor:'pointer', padding:0, transition:'transform 0.15s',
            transform: i===idx ? 'scale(1.3)' : 'scale(1)' }} />
        ))}
      </div>

      {/* Color card - no overlap */}
      <div style={{ background:T.white, borderRadius:24, overflow:'hidden',
        boxShadow:`0 4px 20px ${T.shadow}` }}>

        {/* Large color swatch */}
        <div style={{ height:140, background:color.hex,
          display:'flex', alignItems:'center', justifyContent:'center',
          position:'relative' }}>
          <span style={{ fontSize:60 }}>{color.emoji}</span>
          {/* index badge */}
          <div style={{ position:'absolute', top:10, right:12,
            background:'rgba(0,0,0,0.35)', color:'white',
            borderRadius:20, padding:'2px 10px', fontSize:11, fontWeight:700 }}>
            {idx+1}/{COLORS.length}
          </div>
        </div>

        {/* Text section - completely below the color block */}
        <div style={{ padding:'20px', textAlign:'center',
          display:'flex', flexDirection:'column', alignItems:'center', gap:6 }}>

          <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif",
            fontSize:48, fontWeight:900, direction:'rtl',
            color:color.hex, lineHeight:1.25 }}>
            {color.u}
          </div>

          <div style={{ fontSize:18, fontWeight:800, color:T.navy }}>{color.r}</div>
          <div style={{ fontSize:14, color:T.darkGray }}>{color.eng}</div>

          {/* Light tone sample */}
          <div style={{ marginTop:8, background:color.light,
            border:`3px solid ${color.hex}`, borderRadius:14,
            padding:'6px 24px', fontSize:13, fontWeight:700, color:color.hex }}>
            {color.eng} - light shade
          </div>
        </div>
      </div>

      {isSpeaking && <SpeakingNotice />}

      {/* Practice panel */}
      <div style={{ background:T.white, borderRadius:20, padding:'14px 16px',
        display:'flex', flexDirection:'column', gap:10 }}>
        <div style={{ display:'flex', alignItems:'center', gap:12 }}>
          <ProfessorAvatar
            mood={score===null
              ? (isSpeaking ? 'speaking' : 'neutral')
              : score>=80 ? 'praise' : score>=50 ? 'happy' : 'sad'}
            size={60} speaking={isSpeaking} />
          <div style={{ flex:1 }}>
            {score!==null && <ScoreDisplay score={score} />}
            {listening && <Waveform active color={T.pink} />}
            {!score && !listening && (
              <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif",
                fontSize:13, color:T.darkGray, direction:'rtl' }}>
                {avatarSpoken ? 'رنگ کا نام بولیں' : 'استاد جی کو سنیں...'}
              </div>
            )}
          </div>
        </div>
        <div style={{ display:'flex', gap:8 }}>
          <Btn onClick={() => speakColor(color)} color={T.pink} sm emoji="🔊">سنیں</Btn>
          <Btn onClick={handleListen} color={T.orange} sm emoji="🎤" full
            disabled={!avatarSpoken||listening||isSpeaking}>
            {listening ? 'سن رہے ہیں...' : 'بولیں'}
          </Btn>
        </div>
      </div>

      {/* Navigation */}
      <div style={{ display:'flex', gap:10 }}>
        <Btn onClick={() => setIdx(i=>Math.max(0,i-1))} disabled={idx===0}
          color={T.midGray} outline sm>پچھلا</Btn>
        <Btn onClick={handleNext} color={T.pink} full sm>
          {idx===COLORS.length-1 ? 'مکمل' : 'اگلا'}
        </Btn>
      </div>
    </div>
  );
}
