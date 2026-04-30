// src/screens/HaroofScreen.jsx  - speaks URDU, fixed overlapping layout
import React, { useState, useEffect } from 'react';
import ProfessorAvatar from '../components/ProfessorAvatar.jsx';
import { Btn, Waveform, ScoreDisplay, SpeakingNotice, PBar } from '../components/UI.jsx';
import { T } from '../theme.js';
import { FULL_ALPHABET } from '../data.js';
import { useTTS, useSpeechRecognition } from '../hooks.js';
import { scorePronunciation } from '../utils.js';

export default function HaroofScreen({ onComplete }) {
  const [idx, setIdx]                   = useState(0);
  const [score, setScore]               = useState(null);
  const [listening, setListening]       = useState(false);
  const [avatarSpoken, setAvatarSpoken] = useState(false);
  const [showAll, setShowAll]           = useState(false);
  const [phase, setPhase]               = useState('learn');

  const letter = FULL_ALPHABET[idx];
  const { speak, stop, isSpeaking } = useTTS();
  const { listen }                  = useSpeechRecognition();

  // Speak URDU when letter changes: "ا ۔ اونٹ"
  const speakLetter = (l) => {
    setAvatarSpoken(false);
    // Speak: letter name (roman kept for guidance), then Urdu example word
    speak(`${l.u}۔ ${l.ex}۔`, () => setAvatarSpoken(true));
  };

  useEffect(() => {
    setScore(null);
    setAvatarSpoken(false);
    setPhase('learn');
    const t = setTimeout(() => speakLetter(letter), 450);
    return () => { clearTimeout(t); stop(); };
  }, [idx]); // eslint-disable-line

  const handleListen = () => {
    if (!avatarSpoken || isSpeaking) return;
    setListening(true);
    setScore(null);
    listen(letter.r, (raw, conf, transcript) => {
      setListening(false);
      const s = raw !== null ? raw : scorePronunciation(transcript, letter.r, conf);
      setScore(s);
      setPhase('result');
      speak(s >= 80 ? 'شاباش! بہت خوب!' : s >= 50 ? 'اچھا ہے!' : 'دوبارہ کوشش کریں۔', null);
    });
  };

  const handleNext = () => {
    if (idx < FULL_ALPHABET.length - 1) setIdx(i => i + 1);
    else onComplete({ stars: 3, moduleId: 'haroof' });
  };

  return (
    <div style={{ flex:1, overflowY:'auto', background:T.screenBg,
      display:'flex', flexDirection:'column', padding:16, gap:12 }}>

      {/* Module description */}
      <div style={{ background:`${T.purple}18`, borderRadius:14, padding:'10px 14px',
        fontFamily:"'Noto Nastaliq Urdu',serif", fontSize:13, color:T.purple,
        textAlign:'right', direction:'rtl' }}>
        اردو کے چالیس حروف سیکھیں اور ادا کریں
      </div>

      {/* Progress bar + toggle */}
      <div style={{ display:'flex', alignItems:'center', gap:10 }}>
        <div style={{ flex:1 }}>
          <PBar value={idx+1} max={FULL_ALPHABET.length} color={T.purple} height={7} />
        </div>
        <span style={{ fontSize:11, fontWeight:700, color:T.darkGray, whiteSpace:'nowrap' }}>
          {idx+1}/{FULL_ALPHABET.length}
        </span>
        <button onClick={() => setShowAll(s => !s)} style={{
          background:'none', border:`1.5px solid ${T.purple}`,
          borderRadius:10, padding:'4px 10px',
          fontSize:11, color:T.purple, cursor:'pointer', fontWeight:700, whiteSpace:'nowrap' }}>
          {showAll ? 'کارڈ' : 'سب'}
        </button>
      </div>

      {showAll ? (
        /* ── Grid view RTL ── */
        <div style={{ background:T.white, borderRadius:20, padding:16,
          display:'flex', flexWrap:'wrap', gap:8, direction:'rtl' }}>
          {FULL_ALPHABET.map((l, i) => (
            <button key={i} onClick={() => { setIdx(i); setShowAll(false); }} style={{
              width:46, height:46, borderRadius:10,
              border:`2px solid ${i===idx ? T.purple : T.lightGray}`,
              background: i===idx ? T.purple : T.offWhite,
              color: i===idx ? T.white : T.navy,
              fontFamily:"'Noto Nastaliq Urdu',serif",
              fontSize:20, fontWeight:800, cursor:'pointer',
              display:'flex', alignItems:'center', justifyContent:'center' }}>
              {l.u}
            </button>
          ))}
        </div>
      ) : (
        <>
          {/* ── Letter card - NO OVERLAPPING ── */}
          <div style={{ background:T.white, borderRadius:24, overflow:'hidden',
            boxShadow:`0 4px 20px ${T.shadow}` }}>

            {/* Colour stripe at top */}
            <div style={{ height:8, background:`linear-gradient(90deg,${T.purple},${T.purpleLight})` }} />

            <div style={{ padding:'20px 20px 24px', display:'flex', flexDirection:'column',
              alignItems:'center', gap:0 }}>

              {/* Big Urdu letter - top, standalone */}
              <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif",
                fontSize:96, fontWeight:900, color:T.purple, lineHeight:1.1,
                marginBottom:4 }}>{letter.u}</div>

              {/* Roman name badge */}
              <div style={{ background:`${T.purple}18`, borderRadius:20, padding:'3px 14px',
                fontSize:13, fontWeight:800, color:T.purple, marginBottom:16 }}>
                {letter.r}
              </div>

              {/* Divider */}
              <div style={{ width:'100%', height:1, background:T.lightGray, marginBottom:16 }} />

              {/* Example block - emoji LEFT, Urdu word RIGHT, fully separate */}
              <div style={{ width:'100%', display:'flex', alignItems:'center',
                justifyContent:'center', gap:16 }}>
                {/* Emoji in its own box */}
                <div style={{ width:64, height:64, borderRadius:16,
                  background:`${T.purple}12`, display:'flex',
                  alignItems:'center', justifyContent:'center',
                  fontSize:36, flexShrink:0 }}>
                  {letter.emoji}
                </div>
                {/* Word info to the right */}
                <div style={{ textAlign:'right', direction:'rtl' }}>
                  <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif",
                    fontSize:28, fontWeight:900, color:T.navy, lineHeight:1.2 }}>
                    {letter.ex}
                  </div>
                  <div style={{ fontSize:13, color:T.darkGray, fontWeight:600, marginTop:2 }}>
                    {letter.eng}
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Speaking notice */}
          {isSpeaking && <SpeakingNotice />}

          {/* Practice panel */}
          <div style={{ background:T.white, borderRadius:20, padding:'14px 16px',
            display:'flex', flexDirection:'column', gap:10 }}>

            <div style={{ display:'flex', alignItems:'center', gap:12 }}>
              <ProfessorAvatar
                mood={score===null
                  ? (isSpeaking ? 'speaking' : 'neutral')
                  : score>=80 ? 'praise' : score>=50 ? 'happy' : 'sad'}
                size={64} speaking={isSpeaking} />
              <div style={{ flex:1 }}>
                {score !== null && <ScoreDisplay score={score} />}
                {listening && <Waveform active color={T.purple} />}
                {!score && !listening && (
                  <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif",
                    fontSize:13, color:T.darkGray, direction:'rtl' }}>
                    {avatarSpoken ? 'مائک بٹن دبائیں اور حرف ادا کریں' : 'استاد جی کو سنیں...'}
                  </div>
                )}
              </div>
            </div>

            <div style={{ display:'flex', gap:8 }}>
              <Btn onClick={() => speakLetter(letter)} color={T.teal} sm emoji="🔊">سنیں</Btn>
              <Btn onClick={handleListen} color={T.orange} sm emoji="🎤" full
                disabled={!avatarSpoken || listening || isSpeaking}>
                {listening ? 'سن رہے ہیں...' : 'بولیں'}
              </Btn>
            </div>

            {phase==='result' && score!==null && score<50 && (
              <Btn onClick={() => { setScore(null); setPhase('learn'); speakLetter(letter); }}
                color={T.purple} outline sm>دوبارہ</Btn>
            )}
          </div>

          {/* Navigation */}
          <div style={{ display:'flex', gap:10 }}>
            <Btn onClick={() => setIdx(i=>Math.max(0,i-1))} disabled={idx===0}
              color={T.midGray} outline sm>پچھلا</Btn>
            <Btn onClick={handleNext} color={T.purple} full sm>
              {idx===FULL_ALPHABET.length-1 ? 'مکمل' : 'اگلا'}
            </Btn>
          </div>
        </>
      )}
    </div>
  );
}
