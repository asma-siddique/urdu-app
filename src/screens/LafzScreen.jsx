// src/screens/LafzScreen.jsx - speaks URDU, fixed overlapping
import React, { useState, useEffect } from 'react';
import ProfessorAvatar from '../components/ProfessorAvatar.jsx';
import { Btn, Waveform, ScoreDisplay, SpeakingNotice } from '../components/UI.jsx';
import { T } from '../theme.js';
import { WORDS } from '../data.js';
import { useTTS, useSpeechRecognition } from '../hooks.js';
import { scorePronunciation, scorePhonemes } from '../utils.js';

const CATS = ['سب','جانور','کھانا','فطرت','چیزیں','جسم'];

export default function LafzScreen({ onComplete }) {
  const [cat, setCat]               = useState('سب');
  const [idx, setIdx]               = useState(0);
  const [score, setScore]           = useState(null);
  const [listening, setListening]   = useState(false);
  const [avatarSpoken, setAvatarSpoken] = useState(false);
  const [phonemeResult, setPhonemeResult] = useState(null);

  const filtered = cat==='سب' ? WORDS : WORDS.filter(w => w.cat===cat);
  const word = filtered[Math.min(idx, filtered.length-1)];

  const { speak, stop, isSpeaking } = useTTS();
  const { listen }                  = useSpeechRecognition();

  // Speak URDU word when it changes
  const speakWord = (w) => {
    setAvatarSpoken(false);
    speak(`${w.u}۔`, () => setAvatarSpoken(true));
  };

  useEffect(() => {
    setScore(null);
    setPhonemeResult(null);
    setAvatarSpoken(false);
    const t = setTimeout(() => speakWord(word), 400);
    return () => { clearTimeout(t); stop(); };
  }, [word]); // eslint-disable-line

  const handleCatChange = (c) => { setCat(c); setIdx(0); };

  const handleListen = () => {
    if (!avatarSpoken || isSpeaking) return;
    setListening(true);
    setScore(null);
    setPhonemeResult(null);
    listen(word.target, (raw, conf, transcript) => {
      setListening(false);
      const s = raw!==null ? raw : scorePronunciation(transcript, word.target, conf);
      setScore(s);
      setPhonemeResult(scorePhonemes(word.phonemes, s));
      speak(s>=80 ? 'شاباش! بہت خوب!' : s>=50 ? 'اچھا ہے!' : 'دوبارہ کوشش کریں۔', null);
    });
  };

  const handleNext = () => {
    if (idx < filtered.length-1) setIdx(i=>i+1);
    else onComplete({ stars:3, moduleId:'lafz' });
  };

  const levelColor = word.level==='easy' ? T.greenDark : word.level==='medium' ? T.orange : T.red;

  return (
    <div style={{ flex:1, overflowY:'auto', background:T.screenBg,
      display:'flex', flexDirection:'column', padding:16, gap:12 }}>

      {/* Description */}
      <div style={{ background:`${T.teal}20`, borderRadius:14, padding:'10px 14px',
        fontFamily:"'Noto Nastaliq Urdu',serif", fontSize:13, color:T.teal,
        textAlign:'right', direction:'rtl' }}>
        اردو الفاظ سیکھیں اور صحیح تلفظ کریں
      </div>

      {/* Category tabs */}
      <div style={{ display:'flex', gap:6, overflowX:'auto', paddingBottom:2 }}>
        {CATS.map(c => (
          <button key={c} onClick={() => handleCatChange(c)} style={{
            padding:'6px 14px', borderRadius:20,
            border:`1.5px solid ${cat===c ? T.teal : T.lightGray}`,
            background: cat===c ? T.teal : T.white,
            color: cat===c ? T.white : T.darkGray,
            fontFamily:"'Noto Nastaliq Urdu',serif",
            fontSize:13, fontWeight:700, cursor:'pointer', whiteSpace:'nowrap' }}>{c}</button>
        ))}
      </div>

      {/* Word card - no overlap */}
      <div style={{ background:T.white, borderRadius:24, overflow:'hidden',
        boxShadow:`0 4px 20px ${T.shadow}` }}>

        {/* Top colour stripe */}
        <div style={{ height:8, background:`linear-gradient(90deg,${T.teal},${T.tealLight})` }} />

        <div style={{ padding:'20px 20px 22px', display:'flex', flexDirection:'column',
          alignItems:'center', gap:0 }}>

          {/* Emoji - fully isolated in its own box */}
          <div style={{ width:88, height:88, borderRadius:24,
            background:`${T.teal}14`,
            display:'flex', alignItems:'center', justifyContent:'center',
            fontSize:52, marginBottom:14, flexShrink:0 }}>
            {word.emoji}
          </div>

          {/* Urdu word - its own row */}
          <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif",
            fontSize:48, fontWeight:900, color:T.teal,
            direction:'rtl', lineHeight:1.3, marginBottom:6 }}>
            {word.u}
          </div>

          {/* English meaning */}
          <div style={{ fontSize:16, fontWeight:600, color:T.darkGray, marginBottom:12 }}>
            {word.eng}
          </div>

          {/* Level badge */}
          <div style={{ background:`${levelColor}18`, borderRadius:20,
            padding:'3px 12px', fontSize:11, fontWeight:700, color:levelColor, marginBottom:14 }}>
            {word.level}
          </div>

          {/* Divider */}
          <div style={{ width:'100%', height:1, background:T.lightGray, marginBottom:14 }} />

          {/* Phoneme tiles RTL */}
          <div style={{ display:'flex', justifyContent:'center', gap:6,
            direction:'rtl', flexWrap:'wrap' }}>
            {word.phonemes.map((ph, i) => (
              <span key={i} style={{
                padding:'5px 12px', borderRadius:10,
                background: phonemeResult
                  ? (phonemeResult[i] ? `${T.green}33` : `${T.red}22`)
                  : `${T.teal}18`,
                border:`1.5px solid ${phonemeResult
                  ? (phonemeResult[i] ? T.green : T.red) : T.teal}`,
                fontSize:13, fontWeight:700, color:T.navy }}>
                {ph}
              </span>
            ))}
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
            {listening && <Waveform active color={T.teal} />}
            {!score && !listening && (
              <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif",
                fontSize:13, color:T.darkGray, direction:'rtl' }}>
                {avatarSpoken ? 'لفظ بولیں' : 'استاد جی کو سنیں...'}
              </div>
            )}
          </div>
        </div>
        <div style={{ display:'flex', gap:8 }}>
          <Btn onClick={() => speakWord(word)} color={T.teal} sm emoji="🔊">سنیں</Btn>
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
        <Btn onClick={handleNext} color={T.teal} full sm>
          {idx===filtered.length-1 ? 'مکمل' : 'اگلا'}
        </Btn>
      </div>
    </div>
  );
}
