// src/screens/RangScreen.jsx — Kid-friendly Colors lesson
import React, { useState, useEffect } from 'react';
import { K, LessonHeader, BottomBar, KidCard, KidWaveform, LessonLayout } from '../components/KidUI.jsx';
import { COLORS } from '../data.js';
import { useTTS, useSpeechRecognition } from '../hooks.js';
import { scorePronunciation } from '../utils.js';

export default function RangScreen({ onComplete }) {
  const [idx, setIdx]               = useState(0);
  const [score, setScore]           = useState(null);
  const [listening, setListening]   = useState(false);
  const [avatarSpoken, setAvatarSpoken] = useState(false);
  const [coins]                     = useState(131);

  const color = COLORS[idx];
  const { speak, stop, isSpeaking } = useTTS();
  const { listen }                  = useSpeechRecognition();

  const speakColor = (c) => { setAvatarSpoken(false); speak(`${c.u}۔`, () => setAvatarSpoken(true)); };

  useEffect(() => {
    setScore(null); setAvatarSpoken(false);
    const t = setTimeout(() => speakColor(color), 400);
    return () => { clearTimeout(t); stop(); };
  }, [idx]); // eslint-disable-line

  const handleListen = () => { if (!isSpeaking) speakColor(color); };

  const handleSpeak = () => {
    if (!avatarSpoken || isSpeaking) return;
    setListening(true); setScore(null);
    listen(color.r, (raw, conf, transcript) => {
      setListening(false);
      const s = raw !== null ? raw : scorePronunciation(transcript, color.r, conf);
      setScore(s);
      speak(s >= 80 ? 'شاباش! رنگ صحیح بولا!' : s >= 50 ? 'اچھا ہے!' : 'دوبارہ کوشش کریں۔', null);
    });
  };

  const handleNext = () => {
    setScore(null);
    if (idx < COLORS.length - 1) setIdx(i => i + 1);
    else onComplete({ stars: 3, moduleId: 'rang' });
  };

  const mood = score === null ? (isSpeaking ? 'speaking' : 'neutral') : score >= 80 ? 'praise' : score >= 50 ? 'happy' : 'sad';
  const charMsg = score !== null ? (score >= 80 ? '🌟 Excellent!' : score >= 50 ? '👍 Good job!' : '💪 Try again!')
    : isSpeaking ? '🔊 Listen…' : avatarSpoken ? `Say "${color.r}"!` : `This color is ${color.eng}!`;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', background: K.cream, fontFamily: "'Nunito','Segoe UI',sans-serif" }}>

      <LessonHeader
        current={idx + 1}
        total={COLORS.length}
        title="Colours"
        subtitle="اردو میں رنگوں کے نام"
        coins={coins}
        accent={color.hex || K.pink}
        onBack={idx > 0 ? () => { setScore(null); setIdx(i => i - 1); } : null}
      />

      {/* Color dot row */}
      <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap', justifyContent: 'center', padding: '8px 12px 6px', flexShrink: 0, background: K.white, boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
        {COLORS.map((c, i) => (
          <button key={i} onClick={() => { setIdx(i); setScore(null); }} style={{
            width: 24, height: 24, borderRadius: '50%', background: c.hex,
            border: `3px solid ${i === idx ? '#333' : 'transparent'}`,
            cursor: 'pointer', padding: 0,
            transform: i === idx ? 'scale(1.35)' : 'scale(1)',
            transition: 'transform 0.15s', flexShrink: 0,
          }} title={c.eng} />
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
              Learn colour names in Urdu!
              <div style={{ marginTop: 6, fontFamily: "'Noto Nastaliq Urdu',serif", fontSize: 11, direction: 'rtl', color: K.textMid }}>
                {color.u} = {color.eng}
              </div>
            </>
          }
        >
          <KidCard style={{ overflow: 'hidden', position: 'relative' }}>
            {/* Color swatch */}
            <div style={{ height: 110, background: color.hex, display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative' }}>
              <span style={{ fontSize: 56 }}>{color.emoji}</span>
              <div style={{ position: 'absolute', top: 8, right: 10, background: 'rgba(0,0,0,0.30)', color: K.white, borderRadius: 20, padding: '2px 10px', fontSize: 11, fontWeight: 800 }}>
                {idx + 1}/{COLORS.length}
              </div>
              {score !== null && (
                <div style={{ position: 'absolute', top: 8, left: 10, width: 28, height: 28, borderRadius: '50%', background: score >= 80 ? K.green : score >= 50 ? K.orange : K.red, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 15, color: K.white, fontWeight: 900 }}>
                  {score >= 80 ? '✓' : score >= 50 ? '~' : '✗'}
                </div>
              )}
            </div>

            {/* Text block */}
            <div style={{ padding: '16px 14px 18px', textAlign: 'center', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
              <div style={{ fontFamily: "'Noto Nastaliq Urdu',serif", fontSize: 52, fontWeight: 900, color: color.hex, direction: 'rtl', lineHeight: 1.2 }}>
                {color.u}
              </div>
              <div style={{ fontSize: 16, fontWeight: 900, color: K.textDark }}>{color.r}</div>
              <div style={{ fontSize: 12, color: K.textMid, fontWeight: 600 }}>{color.eng}</div>

              <div style={{ marginTop: 4, background: color.light || `${color.hex}22`, border: `2.5px solid ${color.hex}`, borderRadius: 14, padding: '5px 20px', fontSize: 12, fontWeight: 700, color: color.hex }}>
                {color.eng} — light shade
              </div>

              {listening && <KidWaveform active accent={color.hex} />}

              {score !== null && (
                <div style={{ width: '100%', background: '#F5F5F5', borderRadius: 99, height: 8, overflow: 'hidden', marginTop: 4 }}>
                  <div style={{ width: `${score}%`, height: '100%', borderRadius: 99, background: score >= 80 ? K.green : score >= 50 ? K.orange : K.red, transition: 'width 0.5s ease' }} />
                </div>
              )}
            </div>
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
        nextLabel={idx === COLORS.length - 1 ? 'Finish' : 'Next'}
        accent={color.hex || K.pink}
      />
    </div>
  );
}
