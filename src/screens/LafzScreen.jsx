// src/screens/LafzScreen.jsx — Kid-friendly Vocabulary lesson
import React, { useState, useEffect } from 'react';
import {
  K, LessonHeader, BottomBar, KidCard, KidWaveform,
  LessonLayout,
} from '../components/KidUI.jsx';
import { WORDS } from '../data.js';
import { useTTS, useSpeechRecognition } from '../hooks.js';
import { scorePronunciation, scorePhonemes } from '../utils.js';

const CATS = ['All', 'جانور', 'کھانا', 'فطرت', 'چیزیں', 'جسم'];
const CAT_LABELS = { All: 'All', 'جانور': '🐾 Animals', 'کھانا': '🍎 Food', 'فطرت': '🌿 Nature', 'چیزیں': '🎒 Things', 'جسم': '🧍 Body' };

export default function LafzScreen({ onComplete }) {
  const [cat, setCat]               = useState('All');
  const [idx, setIdx]               = useState(0);
  const [score, setScore]           = useState(null);
  const [listening, setListening]   = useState(false);
  const [avatarSpoken, setAvatarSpoken] = useState(false);
  const [phonemeResult, setPhonemeResult] = useState(null);
  const [coins]                     = useState(131);

  const filtered = cat === 'All' ? WORDS : WORDS.filter(w => w.cat === cat);
  const word = filtered[Math.min(idx, filtered.length - 1)];

  const { speak, stop, isSpeaking } = useTTS();
  const { listen }                  = useSpeechRecognition();

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
  const handleListen = () => { if (!isSpeaking) speakWord(word); };

  const handleSpeak = () => {
    if (!avatarSpoken || isSpeaking) return;
    setListening(true);
    setScore(null);
    setPhonemeResult(null);
    listen(word.target, (raw, conf, transcript) => {
      setListening(false);
      const s = raw !== null ? raw : scorePronunciation(transcript, word.target, conf);
      setScore(s);
      setPhonemeResult(scorePhonemes(word.phonemes, s));
      speak(s >= 80 ? 'شاباش! بہت خوب!' : s >= 50 ? 'اچھا ہے!' : 'دوبارہ کوشش کریں۔', null);
    });
  };

  const handleNext = () => {
    setScore(null);
    if (idx < filtered.length - 1) setIdx(i => i + 1);
    else onComplete({ stars: 3, moduleId: 'lafz' });
  };

  const mood = score === null
    ? (isSpeaking ? 'speaking' : 'neutral')
    : score >= 80 ? 'praise' : score >= 50 ? 'happy' : 'sad';

  const charMsg = score !== null
    ? (score >= 80 ? '🌟 Excellent!' : score >= 50 ? '👍 Good job!' : '💪 Try again!')
    : isSpeaking ? '🔊 Listen…'
    : avatarSpoken ? `Say "${word.r}"!`
    : `This is ${word.eng}!`;

  const levelColor = word.level === 'easy' ? K.green : word.level === 'medium' ? K.orange : K.red;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', background: K.cream, fontFamily: "'Nunito','Segoe UI',sans-serif" }}>

      <LessonHeader
        current={idx + 1}
        total={filtered.length}
        title="Words"
        subtitle="اردو الفاظ سیکھیں"
        coins={coins}
        accent={K.teal}
        onBack={idx > 0 ? () => { setScore(null); setIdx(i => i - 1); } : null}
      />

      {/* Category tabs */}
      <div style={{ display: 'flex', gap: 6, overflowX: 'auto', padding: '8px 12px 4px', flexShrink: 0, background: K.white, boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
        {CATS.map(c => (
          <button key={c} onClick={() => handleCatChange(c)} style={{
            padding: '6px 13px', borderRadius: 20, whiteSpace: 'nowrap',
            border: `2px solid ${cat === c ? K.teal : '#E0E0E0'}`,
            background: cat === c ? K.teal : K.white,
            color: cat === c ? K.white : K.textMid,
            fontSize: 12, fontWeight: 800, cursor: 'pointer',
            boxShadow: cat === c ? `0 3px 8px ${K.teal}44` : 'none',
            transition: 'all 0.15s', fontFamily: 'inherit',
          }}>
            {CAT_LABELS[c] || c}
          </button>
        ))}
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: '10px 12px', display: 'flex', flexDirection: 'column', gap: 10 }}>
        <LessonLayout
          characterMsg={charMsg}
          speaking={isSpeaking}
          mood={mood}
          score={score}
          tipContent={
            <>
              Urdu vocabulary — {cat === 'All' ? 'all categories' : CAT_LABELS[cat]}
              <div style={{ marginTop: 6, fontFamily: "'Noto Nastaliq Urdu',serif", fontSize: 11, direction: 'rtl', color: K.textMid }}>
                {word.u} ({word.eng})
              </div>
            </>
          }
        >
          <KidCard style={{ padding: '16px 14px 18px', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8, position: 'relative' }}>

            <div style={{ width: 72, height: 72, borderRadius: 18, background: `linear-gradient(135deg,${K.tealPale},#B2EBF2)`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 44, flexShrink: 0, boxShadow: `0 3px 12px ${K.teal}30`, border: `2px solid ${K.teal}44` }}>
              {word.emoji}
            </div>

            {score !== null && (
              <div style={{ position: 'absolute', top: 10, right: 10, width: 28, height: 28, borderRadius: '50%', background: score >= 80 ? K.green : score >= 50 ? K.orange : K.red, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 15, color: K.white, fontWeight: 900 }}>
                {score >= 80 ? '✓' : score >= 50 ? '~' : '✗'}
              </div>
            )}

            <div style={{ fontFamily: "'Noto Nastaliq Urdu',serif", fontSize: 52, fontWeight: 900, color: K.teal, direction: 'rtl', lineHeight: 1.2 }}>
              {word.u}
            </div>

            <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap', justifyContent: 'center' }}>
              <div style={{ fontSize: 13, fontWeight: 700, color: K.textDark }}>{word.eng}</div>
              <div style={{ background: `${levelColor}20`, borderRadius: 20, padding: '2px 10px', fontSize: 10, fontWeight: 700, color: levelColor }}>{word.level}</div>
            </div>

            <div style={{ width: '80%', height: 1.5, background: '#F5F5F5', borderRadius: 99 }} />

            <div style={{ display: 'flex', justifyContent: 'center', gap: 6, flexWrap: 'wrap' }}>
              {word.phonemes.map((ph, i) => (
                <span key={i} style={{
                  padding: '4px 12px', borderRadius: 10,
                  background: phonemeResult ? (phonemeResult[i] ? `${K.green}25` : `${K.red}18`) : `${K.teal}18`,
                  border: `1.5px solid ${phonemeResult ? (phonemeResult[i] ? K.green : K.red) : K.teal}`,
                  fontSize: 12, fontWeight: 700, color: K.textDark,
                }}>{ph}</span>
              ))}
            </div>

            {listening && <KidWaveform active accent={K.teal} />}

            {score !== null && (
              <div style={{ width: '100%', background: '#F5F5F5', borderRadius: 99, height: 8, overflow: 'hidden' }}>
                <div style={{ width: `${score}%`, height: '100%', borderRadius: 99, background: score >= 80 ? K.green : score >= 50 ? K.orange : K.red, transition: 'width 0.5s ease' }} />
              </div>
            )}
          </KidCard>
        </LessonLayout>
      </div>

      <BottomBar
        onListen={handleListen}
        onSpeak={handleSpeak}
        onNext={handleNext}
        listenDisabled={isSpeaking}
        speakDisabled={!avatarSpoken || listening || isSpeaking}
        listening={listening}
        nextLabel={idx === filtered.length - 1 ? 'Finish' : 'Next'}
        accent={K.teal}
      />
    </div>
  );
}
