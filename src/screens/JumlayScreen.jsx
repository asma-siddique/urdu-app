// src/screens/JumlayScreen.jsx - speaks full Urdu sentence
import React, { useState, useEffect, useRef } from 'react';
import ProfessorAvatar from '../components/ProfessorAvatar.jsx';
import { Btn, Waveform, ScoreDisplay, SpeakingNotice } from '../components/UI.jsx';
import { T } from '../theme.js';
import { SENTENCES } from '../data.js';
import { useTTS, useSpeechRecognition } from '../hooks.js';
import { scorePronunciation } from '../utils.js';

export default function JumlayScreen({ onComplete }) {
  const [idx, setIdx]                   = useState(0);
  const [phase, setPhase]               = useState('read');
  const [score, setScore]               = useState(null);
  const [listening, setListening]       = useState(false);
  const [avatarSpoken, setAvatarSpoken] = useState(false);
  const [activeWord, setActiveWord]     = useState(-1);
  const timersRef                       = useRef([]);

  const sentence = SENTENCES[idx];
  const words    = sentence.u.split(' ');

  const { speak, stop, isSpeaking } = useTTS();
  const { listen }                  = useSpeechRecognition();

  const clearTimers = () => { timersRef.current.forEach(clearTimeout); timersRef.current=[]; };

  const speakSentence = () => {
    clearTimers();
    setAvatarSpoken(false);
    setActiveWord(-1);
    // Highlight each word with timing
    words.forEach((_, i) => {
      const t = setTimeout(() => setActiveWord(i), i*700);
      timersRef.current.push(t);
    });
    const endT = setTimeout(() => setActiveWord(-1), words.length*700+300);
    timersRef.current.push(endT);
    // Speak the full Urdu sentence
    speak(sentence.u, () => { setAvatarSpoken(true); setPhase('speak'); });
  };

  useEffect(() => {
    setPhase('read');
    setScore(null);
    setAvatarSpoken(false);
    const t = setTimeout(speakSentence, 500);
    return () => { clearTimeout(t); clearTimers(); stop(); };
  }, [idx]); // eslint-disable-line

  const handleListen = () => {
    if (!avatarSpoken || isSpeaking) return;
    setListening(true);
    setScore(null);
    listen(sentence.audio, (raw, conf, transcript) => {
      setListening(false);
      const s = raw!==null ? raw : scorePronunciation(transcript, sentence.audio, conf);
      setScore(s);
      setPhase('result');
      speak(s>=80 ? 'شاباش! جملہ بالکل صحیح ہے!' : s>=50 ? 'اچھا ہے!' : 'دوبارہ کوشش کریں۔', null);
    });
  };

  const handleNext = () => {
    if (idx < SENTENCES.length-1) setIdx(i=>i+1);
    else onComplete({ stars:3, moduleId:'jumlay' });
  };

  return (
    <div style={{ flex:1, overflowY:'auto', background:T.screenBg,
      display:'flex', flexDirection:'column', padding:16, gap:12 }}>

      {/* Description - NO Roman Urdu */}
      <div style={{ background:`${T.orange}18`, borderRadius:14, padding:'10px 14px',
        fontFamily:"'Noto Nastaliq Urdu',serif", fontSize:13, color:T.orange,
        textAlign:'right', direction:'rtl' }}>
        اردو جملے - صرف اردو رسم الخط، رومن اردو نہیں
      </div>

      {/* Progress dots */}
      <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center' }}>
        <span style={{ fontSize:12, color:T.darkGray, fontWeight:600 }}>
          {idx+1} / {SENTENCES.length}
        </span>
        <div style={{ display:'flex', gap:4 }}>
          {SENTENCES.map((_,i) => (
            <div key={i} style={{ width:8, height:8, borderRadius:'50%',
              background: i===idx ? T.orange : i<idx ? `${T.orange}66` : T.lightGray }} />
          ))}
        </div>
      </div>

      {/* Sentence card */}
      <div style={{ background:T.white, borderRadius:24, overflow:'hidden',
        boxShadow:`0 4px 20px ${T.shadow}` }}>
        <div style={{ height:6, background:`linear-gradient(90deg,${T.orange},${T.orangeLight})` }} />
        <div style={{ padding:'24px 20px' }}>
          {/* Highlighted words */}
          <div style={{ direction:'rtl', display:'flex', flexWrap:'wrap',
            gap:6, justifyContent:'flex-start', marginBottom:16 }}>
            {words.map((w,i) => (
              <span key={i} style={{
                fontFamily:"'Noto Nastaliq Urdu',serif",
                fontSize:26, fontWeight:800,
                color: activeWord===i ? T.orange : T.navy,
                background: activeWord===i ? `${T.orange}22` : 'transparent',
                borderRadius:8, padding:'2px 6px',
                transition:'all 0.2s' }}>{w}</span>
            ))}
          </div>
          {/* English meaning only */}
          <div style={{ fontSize:14, color:T.darkGray, fontStyle:'italic',
            textAlign:'center', borderTop:`1px solid ${T.lightGray}`, paddingTop:12 }}>
            {sentence.eng}
          </div>
        </div>
      </div>

      {isSpeaking && <SpeakingNotice />}

      {/* Practice panel */}
      <div style={{ background:T.white, borderRadius:20, padding:'16px',
        display:'flex', flexDirection:'column', gap:12 }}>
        <div style={{ display:'flex', alignItems:'center', gap:12 }}>
          <ProfessorAvatar
            mood={score===null
              ? (isSpeaking ? 'speaking' : phase==='speak' ? 'excited' : 'happy')
              : score>=80 ? 'praise' : score>=50 ? 'happy' : 'sad'}
            size={64} speaking={isSpeaking} />
          <div style={{ flex:1 }}>
            {score!==null && <ScoreDisplay score={score} />}
            {listening && <Waveform active color={T.orange} />}
            {!score && !listening && (
              <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif",
                fontSize:13, color:T.darkGray, direction:'rtl' }}>
                {avatarSpoken ? 'اب آپ جملہ بولیں' : 'استاد جی جملہ پڑھ رہے ہیں...'}
              </div>
            )}
          </div>
        </div>
        <div style={{ display:'flex', gap:8 }}>
          <Btn onClick={speakSentence} color={T.orange} sm emoji="🔊">سنیں</Btn>
          <Btn onClick={handleListen} color={T.purple} sm emoji="🎤" full
            disabled={!avatarSpoken||listening||isSpeaking}>
            {listening ? 'سن رہے ہیں...' : 'بولیں'}
          </Btn>
        </div>
        {phase==='result' && score!==null && score<50 && (
          <Btn onClick={() => { setScore(null); setPhase('read'); speakSentence(); }}
            color={T.orange} outline sm>دوبارہ</Btn>
        )}
      </div>

      {/* Navigation */}
      <div style={{ display:'flex', gap:10 }}>
        <Btn onClick={() => setIdx(i=>Math.max(0,i-1))} disabled={idx===0}
          color={T.midGray} outline sm>پچھلا</Btn>
        <Btn onClick={handleNext} color={T.orange} full sm>
          {idx===SENTENCES.length-1 ? 'مکمل' : 'اگلا'}
        </Btn>
      </div>
    </div>
  );
}
