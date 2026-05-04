// src/screens/JumlayScreen.jsx — Kid-friendly Sentences lesson
import React, { useState, useEffect, useRef } from 'react';
import { K, LessonHeader, BottomBar, KidCard, KidWaveform, LessonLayout } from '../components/KidUI.jsx';
import { SENTENCES } from '../data.js';
import { useTTS, useSpeechRecognition } from '../hooks.js';
import { scorePronunciation } from '../utils.js';

export default function JumlayScreen({ onComplete }) {
  const [idx, setIdx]               = useState(0);
  const [score, setScore]           = useState(null);
  const [listening, setListening]   = useState(false);
  const [avatarSpoken, setAvatarSpoken] = useState(false);
  const [activeWord, setActiveWord] = useState(-1);
  const [coins]                     = useState(131);
  const timersRef                   = useRef([]);

  const sentence = SENTENCES[idx];
  const words    = sentence.u.split(' ');
  const { speak, stop, isSpeaking } = useTTS();
  const { listen }                  = useSpeechRecognition();

  const clearTimers = () => { timersRef.current.forEach(clearTimeout); timersRef.current = []; };

  const speakSentence = () => {
    clearTimers(); setAvatarSpoken(false); setActiveWord(-1);
    words.forEach((_, i) => {
      const t = setTimeout(() => setActiveWord(i), i * 700);
      timersRef.current.push(t);
    });
    const endT = setTimeout(() => setActiveWord(-1), words.length * 700 + 300);
    timersRef.current.push(endT);
    speak(sentence.u, () => setAvatarSpoken(true));
  };

  useEffect(() => {
    setScore(null); setAvatarSpoken(false);
    const t = setTimeout(speakSentence, 500);
    return () => { clearTimeout(t); clearTimers(); stop(); };
  }, [idx]); // eslint-disable-line

  const handleListen = () => { if (!isSpeaking) speakSentence(); };

  const handleSpeak = () => {
    if (!avatarSpoken || isSpeaking) return;
    setListening(true); setScore(null);
    listen(sentence.audio, (raw, conf, transcript) => {
      setListening(false);
      const s = raw !== null ? raw : scorePronunciation(transcript, sentence.audio, conf);
      setScore(s);
      speak(s >= 80 ? 'شاباش! جملہ بالکل صحیح!' : s >= 50 ? 'اچھا ہے!' : 'دوبارہ کوشش کریں۔', null);
    });
  };

  const handleNext = () => {
    setScore(null);
    if (idx < SENTENCES.length - 1) setIdx(i => i + 1);
    else onComplete({ stars: 3, moduleId: 'jumlay' });
  };

  const mood = score === null ? (isSpeaking ? 'speaking' : 'neutral') : score >= 80 ? 'praise' : score >= 50 ? 'happy' : 'sad';
  const charMsg = score !== null ? (score >= 80 ? '🌟 Excellent!' : score >= 50 ? '👍 Good job!' : '💪 Try again!')
    : isSpeaking ? '🔊 Listen carefully…' : avatarSpoken ? 'Now repeat it!' : `Sentence ${idx + 1}!`;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', background: K.cream, fontFamily: "'Nunito','Segoe UI',sans-serif" }}>

      <LessonHeader
        current={idx + 1}
        total={SENTENCES.length}
        title="Sentences"
        subtitle="اردو جملے سیکھیں"
        coins={coins}
        accent={K.purple}
        onBack={idx > 0 ? () => { setScore(null); setIdx(i => i - 1); } : null}
      />

      {/* Progress dots */}
      <div style={{ display: 'flex', justifyContent: 'center', gap: 5, padding: '6px 12px', flexShrink: 0, background: K.white, boxShadow: '0 2px 8px rgba(0,0,0,0.05)' }}>
        {SENTENCES.map((_, i) => (
          <button key={i} onClick={() => { setIdx(i); setScore(null); }} style={{
            width: 10, height: 10, borderRadius: '50%', padding: 0, border: 'none',
            background: i === idx ? K.purple : i < idx ? `${K.purple}66` : '#E0E0E0',
            cursor: 'pointer',
            transform: i === idx ? 'scale(1.3)' : 'scale(1)',
            transition: 'all 0.15s',
          }} />
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
              Read and speak full Urdu sentences!
              <div style={{ marginTop: 6, fontSize: 10, color: K.textMid, fontStyle: 'italic' }}>
                "{sentence.eng}"
              </div>
            </>
          }
        >
          <KidCard style={{ overflow: 'hidden' }}>
            <div style={{ height: 6, background: `linear-gradient(90deg,${K.purple},${K.purplePale})` }} />
            <div style={{ padding: '18px 16px 20px' }}>

              {/* Highlighted words */}
              <div style={{ direction: 'rtl', display: 'flex', flexWrap: 'wrap', gap: 6, justifyContent: 'flex-start', marginBottom: 14 }}>
                {words.map((w, i) => (
                  <span key={i} style={{
                    fontFamily: "'Noto Nastaliq Urdu',serif",
                    fontSize: 26, fontWeight: 800,
                    color: activeWord === i ? K.purple : K.textDark,
                    background: activeWord === i ? `${K.purple}18` : 'transparent',
                    borderRadius: 8, padding: '2px 6px',
                    transition: 'all 0.2s',
                  }}>{w}</span>
                ))}
              </div>

              <div style={{ height: 1.5, background: '#F5F5F5', borderRadius: 99, marginBottom: 10 }} />

              <div style={{ fontSize: 13, color: K.textMid, fontStyle: 'italic', textAlign: 'center' }}>
                "{sentence.eng}"
              </div>

              {score !== null && (
                <div style={{ marginTop: 12, display: 'flex', alignItems: 'center', gap: 10 }}>
                  <div style={{ flex: 1, background: '#F5F5F5', borderRadius: 99, height: 8, overflow: 'hidden' }}>
                    <div style={{ width: `${score}%`, height: '100%', borderRadius: 99, background: score >= 80 ? K.green : score >= 50 ? K.orange : K.red, transition: 'width 0.5s ease' }} />
                  </div>
                  <div style={{ minWidth: 42, textAlign: 'center', fontSize: 14, fontWeight: 900, color: score >= 80 ? K.green : score >= 50 ? K.orange : K.red }}>
                    {score}%
                  </div>
                </div>
              )}

              {listening && (
                <div style={{ marginTop: 10, display: 'flex', justifyContent: 'center' }}>
                  <KidWaveform active accent={K.purple} />
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
        nextLabel={idx === SENTENCES.length - 1 ? 'Finish' : 'Next'}
        accent={K.purple}
      />
    </div>
  );
}
