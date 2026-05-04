// src/screens/QuizScreen.jsx — Kid-friendly Quiz
import React, { useState, useEffect, useMemo } from 'react';
import { K, BoyCharacter, SpeechBubble, KidCard, KidWaveform, QuizShell, QuizOption, KidBtn, SectionHeading } from '../components/KidUI.jsx';
import { FULL_ALPHABET, WORDS, MATCH_DATA, FILL_BLANKS } from '../data.js';
import { useTTS, useSpeechRecognition } from '../hooks.js';
import { scorePronunciation } from '../utils.js';

function shuffle(arr) {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) { const j = Math.floor(Math.random() * (i + 1)); [a[i], a[j]] = [a[j], a[i]]; }
  return a;
}

const QUIZ_TYPES = [
  { id: 'mcq',   icon: 'ا',  label: 'Letters Quiz',   desc: 'Pick the right Urdu letter',    accent: K.purple },
  { id: 'match', icon: '🖼️', label: 'Picture Match',  desc: 'Match the picture to the word', accent: K.teal   },
  { id: 'fill',  icon: '✏️', label: 'Fill the Blank', desc: 'Complete the sentence',          accent: K.orange },
  { id: 'speak', icon: '🎤', label: 'Speak & Score',  desc: 'Say the word aloud',             accent: K.green  },
];
const DIFFS = [
  { id: 'easy',   label: '😊 Easy',   accent: K.green  },
  { id: 'medium', label: '🤔 Medium', accent: K.orange },
  { id: 'hard',   label: '🔥 Hard',   accent: K.red    },
];

function SetupView({ onStart }) {
  const [type, setType] = useState('mcq');
  const [diff, setDiff] = useState('easy');
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', background: K.cream, fontFamily: "'Nunito','Segoe UI',sans-serif" }}>
      <div style={{ background: `linear-gradient(135deg,${K.purple},${K.purplePale})`, padding: '14px 16px', textAlign: 'center', boxShadow: `0 3px 14px ${K.purple}55` }}>
        <div style={{ fontSize: 22, fontWeight: 900, color: K.white }}>Quiz Time! 🏆</div>
        <div style={{ fontFamily: "'Noto Nastaliq Urdu',serif", fontSize: 12, color: 'rgba(255,255,255,0.8)', marginTop: 4, direction: 'rtl' }}>کوئز کا انتخاب کریں</div>
      </div>
      <div style={{ flex: 1, overflowY: 'auto', padding: '14px', display: 'flex', flexDirection: 'column', gap: 14 }}>
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 12 }}>
          <div style={{ flexShrink: 0 }}><BoyCharacter mood="praise" size={80} /></div>
          <SpeechBubble><span style={{ fontSize: 12 }}>🎉 Choose a quiz and go!</span></SpeechBubble>
        </div>
        <KidCard style={{ padding: 14 }}>
          <SectionHeading urdu="قسم منتخب کریں" english="Quiz Type" accent={K.purple} />
          <div style={{ marginTop: 10 }} />
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {QUIZ_TYPES.map(q => (
              <button key={q.id} onClick={() => setType(q.id)} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '11px 13px', borderRadius: 14, border: `2.5px solid ${type === q.id ? q.accent : '#E0E0E0'}`, background: type === q.id ? `${q.accent}12` : K.white, cursor: 'pointer', boxShadow: type === q.id ? `0 3px 10px ${q.accent}33` : 'none', transition: 'all 0.15s', fontFamily: 'inherit' }}>
                <span style={{ fontSize: 24, fontFamily: "'Noto Nastaliq Urdu',serif", flexShrink: 0 }}>{q.icon}</span>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 14, fontWeight: 800, color: type === q.id ? q.accent : K.textDark }}>{q.label}</div>
                  <div style={{ fontSize: 11, color: K.textMid, marginTop: 1 }}>{q.desc}</div>
                </div>
                {type === q.id && <div style={{ width: 22, height: 22, borderRadius: '50%', background: q.accent, color: K.white, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 13, fontWeight: 900 }}>✓</div>}
              </button>
            ))}
          </div>
        </KidCard>
        <KidCard style={{ padding: 14 }}>
          <SectionHeading urdu="مشکل سطح" english="Difficulty" accent={K.orange} />
          <div style={{ marginTop: 10 }} />
          <div style={{ display: 'flex', gap: 8 }}>
            {DIFFS.map(d => (
              <button key={d.id} onClick={() => setDiff(d.id)} style={{ flex: 1, padding: '10px 6px', borderRadius: 14, border: `2.5px solid ${diff === d.id ? d.accent : '#E0E0E0'}`, background: diff === d.id ? `${d.accent}14` : K.white, cursor: 'pointer', fontSize: 12, fontWeight: 800, color: diff === d.id ? d.accent : K.textMid, boxShadow: diff === d.id ? `0 3px 10px ${d.accent}33` : 'none', transition: 'all 0.15s', fontFamily: 'inherit' }}>{d.label}</button>
            ))}
          </div>
        </KidCard>
        <button onClick={() => onStart(type, diff)} style={{ padding: '14px 22px', background: `linear-gradient(135deg,${K.orange},${K.orangeLight})`, border: 'none', borderRadius: 18, color: K.white, fontSize: 16, fontWeight: 900, cursor: 'pointer', boxShadow: `0 5px 18px ${K.orange}55`, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, fontFamily: 'inherit' }}>
          🚀 Start Quiz!
        </button>
      </div>
    </div>
  );
}

function MCQQuiz({ difficulty, onDone }) {
  const pool = useMemo(() => {
    const n = difficulty === 'easy' ? 5 : difficulty === 'medium' ? 8 : 12;
    return shuffle(FULL_ALPHABET).slice(0, n).map(item => ({ item, opts: shuffle([item, ...shuffle(FULL_ALPHABET.filter(x => x.u !== item.u)).slice(0, 3)]) }));
  }, [difficulty]);
  const [qIdx, setQIdx] = useState(0);
  const [selected, setSel] = useState(null);
  const [answers, setAns] = useState([]);
  const { speak, isSpeaking } = useTTS();
  const q = pool[qIdx];
  useEffect(() => { speak(`${q.item.u}۔ ${q.item.ex}۔`, null); }, [qIdx]); // eslint-disable-line
  const handlePick = (opt) => {
    if (selected !== null) return;
    setSel(opt.u);
    const ok = opt.u === q.item.u;
    setAns(a => [...a, ok]);
    speak(ok ? 'شاباش!' : `غلط! ${q.item.u}`, null);
  };
  const handleNext = () => { setSel(null); if (qIdx < pool.length - 1) setQIdx(i => i + 1); else onDone(Math.round((answers.filter(Boolean).length / pool.length) * 100)); };
  const runScore = pool.length > 0 ? Math.round((answers.filter(Boolean).length / pool.length) * 100) : 0;
  const msg = selected === null ? (isSpeaking ? '🔊 Listen…' : 'Which letter is this?') : selected === q.item.u ? '🌟 Correct!' : '❌ Wrong!';
  return (
    <QuizShell current={qIdx + 1} total={pool.length} score={runScore} accent={K.purple} label="Letters">
      <div style={{ display: 'flex', gap: 10, alignItems: 'flex-end' }}>
        <div style={{ flexShrink: 0 }}><BoyCharacter speaking={isSpeaking} mood={selected === null ? 'neutral' : selected === q.item.u ? 'praise' : 'sad'} size={72} /></div>
        <SpeechBubble>{msg}</SpeechBubble>
      </div>
      <KidCard style={{ padding: '20px 16px', textAlign: 'center' }}>
        <div style={{ fontSize: 56, marginBottom: 10 }}>{q.item.emoji}</div>
        <div style={{ fontFamily: "'Noto Nastaliq Urdu',serif", fontSize: 22, fontWeight: 800, color: K.textDark, direction: 'rtl', marginBottom: 4 }}>{q.item.ex}</div>
        <div style={{ fontSize: 12, color: K.textMid, fontWeight: 600 }}>{q.item.eng} — which letter?</div>
      </KidCard>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        {q.opts.map(opt => <QuizOption key={opt.u} label={opt.u} sublabel={opt.r} selected={selected === opt.u} correct={opt.u === q.item.u} revealed={selected !== null} onClick={() => handlePick(opt)} />)}
      </div>
      {selected !== null && <KidBtn onClick={handleNext} accent={K.purple} full>{qIdx < pool.length - 1 ? 'Next ›' : '✓ Finish'}</KidBtn>}
    </QuizShell>
  );
}

function MatchQuiz({ difficulty, onDone }) {
  const pool = useMemo(() => { const n = difficulty === 'easy' ? 5 : difficulty === 'medium' ? 8 : 12; return shuffle(MATCH_DATA).slice(0, n); }, [difficulty]);
  const [qIdx, setQIdx] = useState(0);
  const [selected, setSel] = useState(null);
  const [answers, setAns] = useState([]);
  const { speak, isSpeaking } = useTTS();
  const q = pool[qIdx];
  useEffect(() => { speak('صحیح اردو لفظ چنیں۔', null); }, [qIdx]); // eslint-disable-line
  const handlePick = (opt) => { if (selected !== null) return; setSel(opt); const ok = opt === q.answer; setAns(a => [...a, ok]); speak(ok ? 'شاباش!' : `غلط! ${q.answer}`, null); };
  const handleNext = () => { setSel(null); if (qIdx < pool.length - 1) setQIdx(i => i + 1); else onDone(Math.round((answers.filter(Boolean).length / pool.length) * 100)); };
  const runScore = pool.length > 0 ? Math.round((answers.filter(Boolean).length / pool.length) * 100) : 0;
  const msg = selected === null ? 'Match the picture!' : selected === q.answer ? '🌟 Correct!' : '❌ Wrong!';
  return (
    <QuizShell current={qIdx + 1} total={pool.length} score={runScore} accent={K.teal} label="Match">
      <div style={{ display: 'flex', gap: 10, alignItems: 'flex-end' }}>
        <div style={{ flexShrink: 0 }}><BoyCharacter speaking={isSpeaking} mood={selected === null ? 'neutral' : selected === q.answer ? 'praise' : 'sad'} size={72} /></div>
        <SpeechBubble>{msg}</SpeechBubble>
      </div>
      <KidCard style={{ padding: '20px 16px', textAlign: 'center' }}>
        <div style={{ fontSize: 80 }}>{q.emoji}</div>
        <div style={{ fontSize: 12, color: K.textMid, marginTop: 10, fontWeight: 600 }}>Which Urdu word matches?</div>
      </KidCard>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        {q.opts.map(opt => <QuizOption key={opt} label={opt} selected={selected === opt} correct={opt === q.answer} revealed={selected !== null} onClick={() => handlePick(opt)} />)}
      </div>
      {selected !== null && <KidBtn onClick={handleNext} accent={K.teal} full>{qIdx < pool.length - 1 ? 'Next ›' : '✓ Finish'}</KidBtn>}
    </QuizShell>
  );
}

function FillQuiz({ difficulty, onDone }) {
  const pool = useMemo(() => { const n = difficulty === 'easy' ? 4 : difficulty === 'medium' ? 6 : 8; return shuffle(FILL_BLANKS).slice(0, n); }, [difficulty]);
  const [qIdx, setQIdx] = useState(0);
  const [selected, setSel] = useState(null);
  const [answers, setAns] = useState([]);
  const { speak, isSpeaking } = useTTS();
  const q = pool[qIdx];
  useEffect(() => { speak(`${q.sentence.split('___')[0]}۔`, null); }, [qIdx]); // eslint-disable-line
  const handlePick = (opt) => { if (selected !== null) return; setSel(opt); const ok = opt === q.answer; setAns(a => [...a, ok]); if (ok) speak(`شاباش! ${q.sentence.replace('___', opt)}`, null); else speak(`غلط! ${q.answer}`, null); };
  const handleNext = () => { setSel(null); if (qIdx < pool.length - 1) setQIdx(i => i + 1); else onDone(Math.round((answers.filter(Boolean).length / pool.length) * 100)); };
  const runScore = pool.length > 0 ? Math.round((answers.filter(Boolean).length / pool.length) * 100) : 0;
  const msg = selected === null ? 'Fill the blank!' : selected === q.answer ? '🌟 Correct!' : '❌ Wrong!';
  return (
    <QuizShell current={qIdx + 1} total={pool.length} score={runScore} accent={K.orange} label="Fill">
      <div style={{ display: 'flex', gap: 10, alignItems: 'flex-end' }}>
        <div style={{ flexShrink: 0 }}><BoyCharacter speaking={isSpeaking} mood={selected === null ? 'neutral' : selected === q.answer ? 'praise' : 'sad'} size={72} /></div>
        <SpeechBubble>{msg}</SpeechBubble>
      </div>
      <KidCard style={{ padding: '20px 16px', textAlign: 'center' }}>
        <div style={{ fontFamily: "'Noto Nastaliq Urdu',serif", fontSize: 24, fontWeight: 800, color: K.textDark, direction: 'rtl', marginBottom: 10 }}>
          {q.sentence.split('___').map((part, i) => (
            <React.Fragment key={i}>
              {part}
              {i === 0 && <span style={{ display: 'inline-block', borderBottom: `3px solid ${K.orange}`, minWidth: 60, marginInline: 6, color: selected ? K.orange : 'transparent', fontWeight: 900 }}>{selected || '___'}</span>}
            </React.Fragment>
          ))}
        </div>
        <div style={{ fontSize: 12, color: K.textMid, fontStyle: 'italic' }}>{q.eng}</div>
      </KidCard>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        {q.opts.map(opt => <QuizOption key={opt} label={opt} selected={selected === opt} correct={opt === q.answer} revealed={selected !== null} onClick={() => handlePick(opt)} />)}
      </div>
      {selected !== null && <KidBtn onClick={handleNext} accent={K.orange} full>{qIdx < pool.length - 1 ? 'Next ›' : '✓ Finish'}</KidBtn>}
    </QuizShell>
  );
}

function SpeakQuiz({ difficulty, onDone }) {
  const pool = useMemo(() => {
    const filtered = difficulty === 'easy' ? WORDS.filter(w => w.level === 'easy') : difficulty === 'medium' ? WORDS.filter(w => w.level !== 'hard') : WORDS;
    return shuffle(filtered).slice(0, difficulty === 'easy' ? 5 : difficulty === 'medium' ? 7 : 10);
  }, [difficulty]);
  const [qIdx, setQIdx] = useState(0);
  const [score, setScore] = useState(null);
  const [listening, setL] = useState(false);
  const [avatarSpoken, setAS] = useState(false);
  const [scores, setScores] = useState([]);
  const word = pool[qIdx];
  const { speak, stop, isSpeaking } = useTTS();
  const { listen } = useSpeechRecognition();
  const speakWord = (w) => { setAS(false); speak(`${w.u}۔`, () => setAS(true)); };
  useEffect(() => { setScore(null); setAS(false); const t = setTimeout(() => speakWord(word), 300); return () => { clearTimeout(t); stop(); }; }, [qIdx]); // eslint-disable-line
  const handleListen = () => { if (!isSpeaking) speakWord(word); };
  const handleSpeak = () => {
    if (!avatarSpoken || isSpeaking) return;
    setL(true);
    listen(word.target, (raw, conf, transcript) => {
      setL(false);
      const s = raw !== null ? raw : scorePronunciation(transcript, word.target, conf);
      setScore(s); setScores(sc => [...sc, s]);
      speak(s >= 80 ? 'شاباش!' : s >= 50 ? 'اچھا ہے!' : 'دوبارہ کوشش کریں۔', null);
    });
  };
  const handleNext = () => { setScore(null); if (qIdx < pool.length - 1) setQIdx(i => i + 1); else onDone(scores.length ? Math.round(scores.reduce((a, b) => a + b, 0) / scores.length) : 0); };
  const runScore = scores.length ? Math.round(scores.reduce((a, b) => a + b, 0) / scores.length) : 0;
  const mood = score === null ? (isSpeaking ? 'speaking' : 'neutral') : score >= 80 ? 'praise' : score >= 50 ? 'happy' : 'sad';
  const msg = score !== null ? (score >= 80 ? '🌟 Excellent!' : score >= 50 ? '👍 Good!' : '💪 Try again!') : isSpeaking ? '🔊 Listen…' : avatarSpoken ? `Say "${word.r}"!` : `This is ${word.eng}!`;
  return (
    <QuizShell current={qIdx + 1} total={pool.length} score={runScore} accent={K.green} label="Speak">
      <div style={{ display: 'flex', gap: 10, alignItems: 'flex-end' }}>
        <div style={{ flexShrink: 0 }}><BoyCharacter speaking={isSpeaking} mood={mood} size={72} /></div>
        <SpeechBubble>{msg}</SpeechBubble>
      </div>
      <KidCard style={{ padding: '20px 16px', textAlign: 'center', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
        <div style={{ fontSize: 60 }}>{word.emoji}</div>
        <div style={{ fontFamily: "'Noto Nastaliq Urdu',serif", fontSize: 48, fontWeight: 900, color: K.green, direction: 'rtl' }}>{word.u}</div>
        <div style={{ fontSize: 13, color: K.textMid, fontWeight: 600 }}>{word.eng}</div>
        {listening && <KidWaveform active accent={K.green} />}
        {score !== null && (
          <>
            <div style={{ width: '100%', background: '#F5F5F5', borderRadius: 99, height: 8, overflow: 'hidden' }}>
              <div style={{ width: `${score}%`, height: '100%', borderRadius: 99, background: score >= 80 ? K.green : score >= 50 ? K.orange : K.red, transition: 'width 0.5s ease' }} />
            </div>
            <div style={{ fontSize: 22, fontWeight: 900, color: score >= 80 ? K.green : score >= 50 ? K.orange : K.red }}>{score}%</div>
          </>
        )}
      </KidCard>
      <div style={{ display: 'flex', gap: 8 }}>
        <KidBtn onClick={handleListen} accent={K.orange} disabled={isSpeaking}>🔊 Listen</KidBtn>
        <KidBtn onClick={handleSpeak} accent={K.green} disabled={!avatarSpoken || listening || isSpeaking} full>🎤 {listening ? 'Listening…' : 'Speak'}</KidBtn>
      </div>
      {score !== null && <KidBtn onClick={handleNext} accent={K.green} full>{qIdx < pool.length - 1 ? 'Next ›' : '✓ Finish'}</KidBtn>}
    </QuizShell>
  );
}

function ResultScreen({ score, onRetry }) {
  const color = score >= 80 ? K.green : score >= 50 ? K.orange : K.red;
  const stars = score >= 80 ? '⭐⭐⭐' : score >= 50 ? '⭐⭐' : '⭐';
  const msg   = score >= 80 ? 'Excellent! 🎉' : score >= 50 ? 'Good job! 👍' : 'Keep trying! 💪';
  const urdu  = score >= 80 ? 'شاباش! بہت خوب!' : score >= 50 ? 'اچھا ہے! جاری رکھیں' : 'محنت کریں!';
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', background: K.cream, fontFamily: "'Nunito','Segoe UI',sans-serif", alignItems: 'center', justifyContent: 'center', gap: 20, padding: 24 }}>
      <BoyCharacter mood={score >= 80 ? 'praise' : score >= 50 ? 'happy' : 'sad'} size={120} />
      <div style={{ textAlign: 'center' }}>
        <div style={{ fontSize: 64, fontWeight: 900, color }}>{score}%</div>
        <div style={{ fontSize: 28, marginTop: 4 }}>{stars}</div>
        <div style={{ fontSize: 20, fontWeight: 900, color, marginTop: 8 }}>{msg}</div>
        <div style={{ fontFamily: "'Noto Nastaliq Urdu',serif", fontSize: 18, color, direction: 'rtl', marginTop: 6 }}>{urdu}</div>
      </div>
      <KidBtn onClick={onRetry} accent={K.purple} full>🔄 Try Again</KidBtn>
    </div>
  );
}

export default function QuizScreen({ onComplete }) {
  const [stage, setStage]      = useState('setup');
  const [type, setType]        = useState('mcq');
  const [diff, setDiff]        = useState('easy');
  const [finalScore, setFinal] = useState(0);
  const handleDone = (score) => { setFinal(score); setStage('result'); onComplete && onComplete({ stars: score >= 80 ? 3 : score >= 50 ? 2 : 1, moduleId: 'quiz' }); };
  if (stage === 'setup')  return <SetupView onStart={(t, d) => { setType(t); setDiff(d); setStage('quiz'); }} />;
  if (stage === 'result') return <ResultScreen score={finalScore} onRetry={() => setStage('setup')} />;
  if (type === 'mcq')     return <MCQQuiz   difficulty={diff} onDone={handleDone} />;
  if (type === 'match')   return <MatchQuiz difficulty={diff} onDone={handleDone} />;
  if (type === 'fill')    return <FillQuiz  difficulty={diff} onDone={handleDone} />;
  if (type === 'speak')   return <SpeakQuiz difficulty={diff} onDone={handleDone} />;
  return null;
}
