// src/screens/HaroofScreen.jsx — Kid-friendly Alphabet lesson
import React, { useState, useEffect } from 'react';
import {
  K, BoyCharacter, SpeechBubble, TipBox, LessonHeader,
  BottomBar, KidCard, ScoreBadge, KidWaveform, LessonLayout, SectionHeading,
} from '../components/KidUI.jsx';
import { FULL_ALPHABET } from '../data.js';
import { useTTS, useSpeechRecognition } from '../hooks.js';
import { scorePronunciation } from '../utils.js';

export default function HaroofScreen({ onComplete }) {
  const [idx, setIdx]               = useState(0);
  const [score, setScore]           = useState(null);
  const [listening, setListening]   = useState(false);
  const [avatarSpoken, setAvatarSpoken] = useState(false);
  const [coins]                     = useState(131);
  const [showAll, setShowAll]       = useState(false);

  const letter = FULL_ALPHABET[idx];
  const { speak, stop, isSpeaking } = useTTS();
  const { listen }                  = useSpeechRecognition();

  const speakLetter = (l) => {
    setAvatarSpoken(false);
    speak(`${l.u}۔ ${l.ex}۔`, () => setAvatarSpoken(true));
  };

  useEffect(() => {
    setScore(null);
    setAvatarSpoken(false);
    const t = setTimeout(() => speakLetter(letter), 450);
    return () => { clearTimeout(t); stop(); };
  }, [idx]); // eslint-disable-line

  const handleListen = () => { if (!isSpeaking) speakLetter(letter); };

  const handleSpeak = () => {
    if (!avatarSpoken || isSpeaking) return;
    setListening(true);
    setScore(null);
    listen(letter.r, (raw, conf, transcript) => {
      setListening(false);
      const s = raw !== null ? raw : scorePronunciation(transcript, letter.r, conf);
      setScore(s);
      speak(s >= 80 ? 'شاباش! بہت خوب!' : s >= 50 ? 'اچھا ہے!' : 'دوبارہ کوشش کریں۔', null);
    });
  };

  const handleNext = () => {
    setScore(null);
    if (idx < FULL_ALPHABET.length - 1) setIdx(i => i + 1);
    else onComplete({ stars: 3, moduleId: 'haroof' });
  };

  const mood = score === null
    ? (isSpeaking ? 'speaking' : 'neutral')
    : score >= 80 ? 'praise' : score >= 50 ? 'happy' : 'sad';

  const charMsg = score !== null
    ? (score >= 80 ? '🌟 Excellent!' : score >= 50 ? '👍 Good job!' : '💪 Try again!')
    : isSpeaking
    ? '🔊 Listen carefully…'
    : avatarSpoken
    ? `Now say "${letter.r}"!`
    : `This is ${letter.r}!`;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', background: K.cream, fontFamily: "'Nunito','Segoe UI',sans-serif" }}>

      {/* Header */}
      <LessonHeader
        current={idx + 1}
        total={FULL_ALPHABET.length}
        title={`Lesson ${idx + 1}`}
        subtitle="اردو حروفِ تہجی"
        coins={coins}
        onBack={idx > 0 ? () => { setScore(null); setIdx(i => i - 1); } : null}
        extraRight={
          <button onClick={() => setShowAll(s => !s)} style={{
            background: showAll ? K.white : 'rgba(255,255,255,0.25)',
            border: 'none', borderRadius: 10, padding: '5px 10px',
            fontSize: 11, fontWeight: 900,
            color: showAll ? K.orange : K.white,
            cursor: 'pointer', flexShrink: 0,
          }}>
            {showAll ? 'Card' : 'All'}
          </button>
        }
      />

      {/* Scrollable content */}
      <div style={{ flex: 1, overflowY: 'auto', padding: '10px 12px', display: 'flex', flexDirection: 'column', gap: 10 }}>

        {showAll ? (
          /* ── All-letters grid ── */
          <SectionHeading urdu="تمام حروف" english="All Letters" accent={K.orange} />
          <KidCard style={{ padding: 14 }}>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, direction: 'rtl' }}>
              {FULL_ALPHABET.map((l, i) => (
                <button key={i} onClick={() => { setIdx(i); setShowAll(false); }} style={{
                  width: 48, height: 48, borderRadius: 12,
                  border: `2.5px solid ${i === idx ? K.orange : '#E0E0E0'}`,
                  background: i === idx ? K.orange : K.cream,
                  color: i === idx ? K.white : K.textDark,
                  fontFamily: "'Noto Nastaliq Urdu', serif",
                  fontSize: 22, fontWeight: 800, cursor: 'pointer',
                  boxShadow: i === idx ? `0 3px 10px ${K.orange}44` : 'none',
                  transition: 'all 0.15s',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  {l.u}
                </button>
              ))}
            </div>
          </KidCard>
        ) : (
          <LessonLayout
            characterMsg={charMsg}
            speaking={isSpeaking}
            mood={mood}
            score={score}
            tipContent={
              <>
                All 40 letters of the Urdu alphabet.
                <div style={{ marginTop: 6, fontFamily: "'Noto Nastaliq Urdu',serif", fontSize: 11, direction: 'rtl', color: K.textMid }}>
                  {letter.r} سے {letter.ex} ({letter.eng})
                </div>
              </>
            }
          >
            {/* Letter card */}
            <KidCard style={{ padding: '16px 14px 18px', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8, position: 'relative' }}>

              {/* Animal emoji */}
              <div style={{
                width: 72, height: 72, borderRadius: 18,
                background: 'linear-gradient(135deg,#FFF3E0,#FFE0B2)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 44,
                boxShadow: `0 3px 12px ${K.orange}30`,
                border: `2px solid ${K.yellow}`,
                flexShrink: 0,
              }}>
                {letter.emoji}
              </div>

              {/* Correct / wrong badge */}
              {score !== null && (
                <div style={{
                  position: 'absolute', top: 10, right: 10,
                  width: 28, height: 28, borderRadius: '50%',
                  background: score >= 80 ? K.green : score >= 50 ? K.orange : K.red,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 15, color: K.white, fontWeight: 900,
                }}>
                  {score >= 80 ? '✓' : score >= 50 ? '~' : '✗'}
                </div>
              )}

              {/* Big Urdu letter */}
              <div style={{
                fontFamily: "'Noto Nastaliq Urdu', serif",
                fontSize: 82, fontWeight: 900,
                color: K.red,
                lineHeight: 1,
                textShadow: `0 3px 0 ${K.red}30`,
              }}>
                {letter.u}
              </div>

              {/* Divider */}
              <div style={{ width: '80%', height: 1.5, background: '#F5F5F5', borderRadius: 99 }} />

              {/* Name + transcription */}
              <div style={{ display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap', justifyContent: 'center' }}>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: 15, fontWeight: 900, color: K.textDark }}>{letter.r}</div>
                  <div style={{ fontSize: 10, color: K.gray, fontWeight: 600 }}>Name</div>
                </div>
                <div style={{ width: 1.5, height: 28, background: '#EEE' }} />
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontFamily: "'Noto Nastaliq Urdu',serif", fontSize: 14, fontWeight: 800, color: K.textDark, direction: 'rtl' }}>
                    {letter.ex}
                  </div>
                  <div style={{ fontSize: 10, color: K.gray, fontWeight: 600 }}>
                    {letter.exR} – {letter.eng}
                  </div>
                </div>
              </div>

              {/* Listening waveform */}
              {listening && (
                <div style={{ marginTop: 4 }}>
                  <KidWaveform active accent={K.orange} />
                </div>
              )}

              {/* Score bar */}
              {score !== null && (
                <div style={{ width: '100%', background: '#F5F5F5', borderRadius: 99, height: 8, overflow: 'hidden' }}>
                  <div style={{
                    width: `${score}%`, height: '100%', borderRadius: 99,
                    background: score >= 80 ? K.green : score >= 50 ? K.orange : K.red,
                    transition: 'width 0.5s ease',
                  }} />
                </div>
              )}
            </KidCard>
          </LessonLayout>
        )}
      </div>

      {/* Bottom bar */}
      <BottomBar
        onListen={handleListen}
        onSpeak={handleSpeak}
        onNext={handleNext}
        listenDisabled={isSpeaking}
        speakDisabled={!avatarSpoken || listening || isSpeaking}
        listening={listening}
        nextLabel={idx === FULL_ALPHABET.length - 1 ? 'Finish' : 'Next'}
      />
    </div>
  );
}
