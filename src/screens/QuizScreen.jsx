// src/screens/QuizScreen.jsx - speaks URDU throughout
import React, { useState, useEffect, useMemo } from 'react';
import ProfessorAvatar from '../components/ProfessorAvatar.jsx';
import { Btn, PBar, StarBadge, Confetti, Waveform, SpeakingNotice } from '../components/UI.jsx';
import { T } from '../theme.js';
import { FULL_ALPHABET, WORDS, MATCH_DATA, FILL_BLANKS } from '../data.js';
import { useTTS, useSpeechRecognition } from '../hooks.js';
import { scorePronunciation } from '../utils.js';

function shuffle(arr) {
  const a=[...arr];
  for(let i=a.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[a[i],a[j]]=[a[j],a[i]];}
  return a;
}

const QUIZ_TYPES = [
  { id:'mcq',   label:'حروف کوئز',  icon:'ا',  desc:'اردو حروف پہچانیں'    },
  { id:'match', label:'تصویر ملاؤ', icon:'🖼️', desc:'تصویر سے لفظ ملائیں' },
  { id:'fill',  label:'خالی جگہ',   icon:'✏️', desc:'جملہ مکمل کریں'        },
  { id:'speak', label:'تلفظ ٹیسٹ', icon:'🎤', desc:'لفظ کا تلفظ کریں'     },
];
const DIFFICULTIES = [
  { id:'easy',   label:'آسان',    color:T.green  },
  { id:'medium', label:'درمیانہ', color:T.orange },
  { id:'hard',   label:'مشکل',   color:T.red    },
];

/* ── Setup ── */
function SetupView({ onStart }) {
  const [type, setType] = useState('mcq');
  const [diff, setDiff] = useState('easy');
  const { speak } = useTTS();
  return (
    <div style={{ flex:1, overflowY:'auto', padding:16, display:'flex', flexDirection:'column', gap:14 }}>
      <div style={{ textAlign:'center', marginBottom:4 }}>
        <ProfessorAvatar mood="excited" size={80} floating />
        <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif",
          fontSize:20, fontWeight:900, color:T.navy, direction:'rtl', marginTop:8 }}>
          کوئز کا انتخاب کریں
        </div>
      </div>
      <div style={{ background:T.white, borderRadius:20, padding:16, display:'flex', flexDirection:'column', gap:10 }}>
        <div style={{ fontSize:13, fontWeight:700, color:T.darkGray, marginBottom:4 }}>کوئز کی قسم</div>
        {QUIZ_TYPES.map(q => (
          <button key={q.id} onClick={() => setType(q.id)} style={{
            display:'flex', alignItems:'center', gap:12,
            padding:'12px 14px', borderRadius:14,
            border:`2px solid ${type===q.id ? T.purple : T.lightGray}`,
            background: type===q.id ? `${T.purple}12` : T.offWhite,
            cursor:'pointer', textAlign:'left' }}>
            <span style={{ fontSize:22, fontFamily:"'Noto Nastaliq Urdu',serif" }}>{q.icon}</span>
            <div>
              <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif", fontSize:15, fontWeight:800,
                color:type===q.id ? T.purple : T.navy, direction:'rtl' }}>{q.label}</div>
              <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif", fontSize:11,
                color:T.darkGray, direction:'rtl' }}>{q.desc}</div>
            </div>
            {type===q.id && <span style={{ marginLeft:'auto', color:T.purple, fontWeight:900 }}>✓</span>}
          </button>
        ))}
      </div>
      <div style={{ background:T.white, borderRadius:20, padding:16 }}>
        <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif", fontSize:13, fontWeight:700,
          color:T.darkGray, direction:'rtl', marginBottom:10 }}>مشکل کی سطح</div>
        <div style={{ display:'flex', gap:8 }}>
          {DIFFICULTIES.map(d => (
            <button key={d.id} onClick={() => setDiff(d.id)} style={{
              flex:1, padding:'10px 6px', borderRadius:12,
              border:`2px solid ${diff===d.id ? d.color : T.lightGray}`,
              background: diff===d.id ? `${d.color}18` : T.offWhite, cursor:'pointer',
              fontFamily:"'Noto Nastaliq Urdu',serif", fontSize:13, fontWeight:800,
              color: diff===d.id ? d.color : T.darkGray }}>{d.label}</button>
          ))}
        </div>
      </div>
      <Btn onClick={() => onStart(type, diff)} color={T.purple} full emoji="🚀">کوئز شروع کریں</Btn>
    </div>
  );
}

/* ── Shell ── */
function QuizShell({ current, total, score, color, children }) {
  return (
    <div style={{ flex:1, display:'flex', flexDirection:'column', overflow:'hidden' }}>
      <div style={{ padding:'12px 16px', background:T.white, borderBottom:`1px solid ${T.lightGray}` }}>
        <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom:6 }}>
          <span style={{ fontSize:12, fontWeight:700, color:T.darkGray }}>{current} / {total}</span>
          <span style={{ fontSize:13, fontWeight:800, color }}>اسکور: {score}%</span>
        </div>
        <PBar value={current} max={total} color={color} height={6} />
      </div>
      <div style={{ flex:1, overflowY:'auto', padding:16, display:'flex', flexDirection:'column', gap:12 }}>
        {children}
      </div>
    </div>
  );
}

/* ── MCQ Quiz ── */
function MCQQuiz({ difficulty, onDone }) {
  const pool = useMemo(() => {
    const n = difficulty==='easy' ? 5 : difficulty==='medium' ? 8 : 12;
    return shuffle(FULL_ALPHABET).slice(0,n).map(item => ({
      item, opts: shuffle([item, ...shuffle(FULL_ALPHABET.filter(x=>x.u!==item.u)).slice(0,3)])
    }));
  }, [difficulty]);

  const [qIdx, setQIdx] = useState(0);
  const [selected, setSel] = useState(null);
  const [answers, setAns] = useState([]);
  const { speak, isSpeaking } = useTTS();
  const q = pool[qIdx];

  useEffect(() => {
    // Speak the Urdu example word (not English)
    speak(`${q.item.u}۔ ${q.item.ex}۔`, null);
  }, [qIdx]); // eslint-disable-line

  const handlePick = (opt) => {
    if (selected!==null) return;
    setSel(opt.u);
    const ok = opt.u===q.item.u;
    setAns(a=>[...a,ok]);
    speak(ok ? 'شاباش!' : `غلط! صحیح جواب ${q.item.u} ہے۔`, null);
  };

  const handleNext = () => {
    setSel(null);
    if (qIdx<pool.length-1) setQIdx(i=>i+1);
    else onDone(Math.round((answers.filter(Boolean).length/pool.length)*100));
  };

  const runScore = pool.length>0 ? Math.round((answers.filter(Boolean).length/pool.length)*100) : 0;

  return (
    <QuizShell current={qIdx+1} total={pool.length} score={runScore} color={T.purple}>
      {isSpeaking && <SpeakingNotice />}
      <div style={{ background:T.white, borderRadius:24, padding:'24px 20px', textAlign:'center',
        boxShadow:`0 4px 20px ${T.shadow}` }}>
        <div style={{ fontSize:56, marginBottom:12 }}>{q.item.emoji}</div>
        <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif", fontSize:22, fontWeight:800,
          color:T.navy, direction:'rtl', marginBottom:4 }}>{q.item.ex}</div>
        <div style={{ fontSize:13, color:T.darkGray }}>کونسا حرف ہے؟</div>
      </div>
      <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:10 }}>
        {q.opts.map(opt => {
          const picked=selected===opt.u, isOk=opt.u===q.item.u;
          let bg=T.white, border=T.lightGray, col=T.navy;
          if (selected!==null) {
            if (isOk)        { bg=`${T.green}22`; border=T.green; col=T.greenDark; }
            else if (picked) { bg=`${T.red}18`;   border=T.red;   col=T.red; }
          }
          return (
            <button key={opt.u} onClick={()=>handlePick(opt)} style={{
              padding:'18px 8px', borderRadius:16, border:`2px solid ${border}`,
              background:bg, cursor:'pointer', transition:'all 0.2s' }}>
              <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif",
                fontSize:36, fontWeight:900, color:col }}>{opt.u}</div>
              <div style={{ fontSize:11, color:T.darkGray, marginTop:4 }}>{opt.r}</div>
              {selected!==null && isOk && <div style={{fontSize:16}}>✅</div>}
              {selected!==null && picked && !isOk && <div style={{fontSize:16}}>❌</div>}
            </button>
          );
        })}
      </div>
      {selected!==null && (
        <Btn onClick={handleNext} color={T.purple} full>
          {qIdx<pool.length-1 ? 'اگلا سوال' : 'مکمل'}
        </Btn>
      )}
    </QuizShell>
  );
}

/* ── Match Quiz ── */
function MatchQuiz({ difficulty, onDone }) {
  const pool = useMemo(() => {
    const n = difficulty==='easy' ? 5 : difficulty==='medium' ? 8 : 12;
    return shuffle(MATCH_DATA).slice(0,n);
  }, [difficulty]);

  const [qIdx, setQIdx] = useState(0);
  const [selected, setSel] = useState(null);
  const [answers, setAns] = useState([]);
  const { speak, isSpeaking } = useTTS();
  const q = pool[qIdx];

  useEffect(() => { speak('صحیح اردو لفظ چنیں۔', null); }, [qIdx]); // eslint-disable-line

  const handlePick = (opt) => {
    if (selected!==null) return;
    setSel(opt);
    const ok = opt===q.answer;
    setAns(a=>[...a,ok]);
    speak(ok ? 'شاباش!' : `غلط! صحیح جواب ${q.answer} ہے۔`, null);
  };
  const handleNext = () => {
    setSel(null);
    if (qIdx<pool.length-1) setQIdx(i=>i+1);
    else onDone(Math.round((answers.filter(Boolean).length/pool.length)*100));
  };
  const runScore = pool.length>0 ? Math.round((answers.filter(Boolean).length/pool.length)*100) : 0;

  return (
    <QuizShell current={qIdx+1} total={pool.length} score={runScore} color={T.teal}>
      {isSpeaking && <SpeakingNotice />}
      <div style={{ background:T.white, borderRadius:24, padding:'28px 20px', textAlign:'center',
        boxShadow:`0 4px 20px ${T.shadow}` }}>
        <div style={{ fontSize:80 }}>{q.emoji}</div>
        <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif", fontSize:14, color:T.darkGray,
          marginTop:12, direction:'rtl' }}>صحیح اردو لفظ چنیں</div>
      </div>
      <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:10 }}>
        {q.opts.map(opt => {
          const picked=selected===opt, isOk=opt===q.answer;
          let bg=T.white, border=T.lightGray, col=T.navy;
          if (selected!==null) {
            if (isOk)        { bg=`${T.green}22`; border=T.green; col=T.greenDark; }
            else if (picked) { bg=`${T.red}18`;   border=T.red;   col=T.red; }
          }
          return (
            <button key={opt} onClick={()=>handlePick(opt)} style={{
              padding:'16px 10px', borderRadius:16, border:`2px solid ${border}`,
              background:bg, cursor:'pointer', transition:'all 0.2s' }}>
              <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif",
                fontSize:22, fontWeight:900, color:col, direction:'rtl' }}>{opt}</div>
              {selected!==null && isOk && <div style={{fontSize:14,marginTop:4}}>✅</div>}
              {selected!==null && picked && !isOk && <div style={{fontSize:14,marginTop:4}}>❌</div>}
            </button>
          );
        })}
      </div>
      {selected!==null && (
        <Btn onClick={handleNext} color={T.teal} full>
          {qIdx<pool.length-1 ? 'اگلا سوال' : 'مکمل'}
        </Btn>
      )}
    </QuizShell>
  );
}

/* ── Fill-in-blank Quiz ── */
function FillQuiz({ difficulty, onDone }) {
  const pool = useMemo(() => {
    const n = difficulty==='easy' ? 4 : difficulty==='medium' ? 6 : 8;
    return shuffle(FILL_BLANKS).slice(0,n);
  }, [difficulty]);

  const [qIdx, setQIdx] = useState(0);
  const [selected, setSel] = useState(null);
  const [answers, setAns] = useState([]);
  const { speak, isSpeaking } = useTTS();
  const q = pool[qIdx];

  useEffect(() => {
    const parts = q.sentence.split('___');
    speak(`${parts[0]}۔`, null);
  }, [qIdx]); // eslint-disable-line

  const handlePick = (opt) => {
    if (selected!==null) return;
    setSel(opt);
    const ok = opt===q.answer;
    setAns(a=>[...a,ok]);
    if (ok) speak(`شاباش! ${q.sentence.replace('___',opt)}`, null);
    else    speak(`غلط! صحیح جواب ${q.answer} ہے۔`, null);
  };
  const handleNext = () => {
    setSel(null);
    if (qIdx<pool.length-1) setQIdx(i=>i+1);
    else onDone(Math.round((answers.filter(Boolean).length/pool.length)*100));
  };
  const runScore = pool.length>0 ? Math.round((answers.filter(Boolean).length/pool.length)*100) : 0;

  return (
    <QuizShell current={qIdx+1} total={pool.length} score={runScore} color={T.orange}>
      {isSpeaking && <SpeakingNotice />}
      <div style={{ background:T.white, borderRadius:24, padding:'24px 20px',
        boxShadow:`0 4px 20px ${T.shadow}`, textAlign:'center' }}>
        <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif", fontSize:24, fontWeight:800,
          color:T.navy, direction:'rtl', marginBottom:10 }}>
          {q.sentence.split('___').map((part,i)=>(
            <React.Fragment key={i}>
              {part}
              {i===0 && (
                <span style={{ display:'inline-block', borderBottom:`3px solid ${T.orange}`,
                  minWidth:60, marginInline:6, color:selected?T.orange:'transparent' }}>
                  {selected||'___'}
                </span>
              )}
            </React.Fragment>
          ))}
        </div>
        <div style={{ fontSize:13, color:T.darkGray, fontStyle:'italic' }}>{q.eng}</div>
      </div>
      <div style={{ display:'grid', gridTemplateColumns:'1fr 1fr', gap:10 }}>
        {q.opts.map(opt => {
          const picked=selected===opt, isOk=opt===q.answer;
          let bg=T.white, border=T.lightGray, col=T.navy;
          if (selected!==null) {
            if (isOk)        { bg=`${T.green}22`; border=T.green; col=T.greenDark; }
            else if (picked) { bg=`${T.red}18`;   border=T.red;   col=T.red; }
          }
          return (
            <button key={opt} onClick={()=>handlePick(opt)} style={{
              padding:'16px 10px', borderRadius:16, border:`2px solid ${border}`,
              background:bg, cursor:'pointer' }}>
              <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif",
                fontSize:20, fontWeight:900, color:col, direction:'rtl' }}>{opt}</div>
              {selected!==null && isOk && <div style={{fontSize:14,marginTop:4}}>✅</div>}
              {selected!==null && picked && !isOk && <div style={{fontSize:14,marginTop:4}}>❌</div>}
            </button>
          );
        })}
      </div>
      {selected!==null && (
        <Btn onClick={handleNext} color={T.orange} full>
          {qIdx<pool.length-1 ? 'اگلا سوال' : 'مکمل'}
        </Btn>
      )}
    </QuizShell>
  );
}

/* ── Speak Quiz ── */
function SpeakQuiz({ difficulty, onDone }) {
  const pool = useMemo(() => {
    const filtered = difficulty==='easy' ? WORDS.filter(w=>w.level==='easy')
      : difficulty==='medium' ? WORDS.filter(w=>w.level!=='hard') : WORDS;
    const n = difficulty==='easy' ? 5 : difficulty==='medium' ? 7 : 10;
    return shuffle(filtered).slice(0,n);
  }, [difficulty]);

  const [qIdx, setQIdx] = useState(0);
  const [score, setScore] = useState(null);
  const [listening, setListening] = useState(false);
  const [avatarSpoken, setAvatarSpoken] = useState(false);
  const [scores, setScores] = useState([]);
  const word = pool[qIdx];

  const { speak, stop, isSpeaking } = useTTS();
  const { listen } = useSpeechRecognition();

  const speakWord = (w) => {
    setAvatarSpoken(false);
    speak(`${w.u}۔`, () => setAvatarSpoken(true));
  };

  useEffect(() => {
    setScore(null);
    setAvatarSpoken(false);
    const t = setTimeout(()=>speakWord(word), 300);
    return ()=>{ clearTimeout(t); stop(); };
  }, [qIdx]); // eslint-disable-line

  const handleListen = () => {
    if (!avatarSpoken||isSpeaking) return;
    setListening(true);
    listen(word.target, (raw,conf,transcript) => {
      setListening(false);
      const s = raw!==null ? raw : scorePronunciation(transcript, word.target, conf);
      setScore(s);
      setScores(sc=>[...sc,s]);
      speak(s>=80 ? 'شاباش! بہت اچھا تلفظ!' : s>=50 ? 'اچھا ہے! جاری رکھیں' : 'دوبارہ کوشش کریں۔', null);
    });
  };

  const handleNext = () => {
    setScore(null);
    if (qIdx<pool.length-1) setQIdx(i=>i+1);
    else {
      const avg = scores.length ? Math.round(scores.reduce((a,b)=>a+b,0)/scores.length) : 0;
      onDone(avg);
    }
  };

  const runScore = scores.length ? Math.round(scores.reduce((a,b)=>a+b,0)/scores.length) : 0;

  return (
    <QuizShell current={qIdx+1} total={pool.length} score={runScore} color={T.pink}>
      {isSpeaking && <SpeakingNotice />}
      <div style={{ background:T.white, borderRadius:24, padding:'24px 20px', textAlign:'center',
        boxShadow:`0 4px 20px ${T.shadow}` }}>
        <div style={{ fontSize:64, marginBottom:14 }}>{word.emoji}</div>
        <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif", fontSize:44, fontWeight:900,
          color:T.pink, direction:'rtl', marginBottom:6 }}>{word.u}</div>
        <div style={{ fontSize:14, color:T.darkGray }}>{word.eng}</div>
      </div>
      <div style={{ background:T.white, borderRadius:20, padding:'14px 16px',
        display:'flex', flexDirection:'column', gap:10 }}>
        <div style={{ display:'flex', alignItems:'center', gap:12 }}>
          <ProfessorAvatar
            mood={score===null
              ? (isSpeaking ? 'speaking' : 'neutral')
              : score>=80 ? 'praise' : score>=50 ? 'happy' : 'sad'}
            size={58} speaking={isSpeaking} />
          <div style={{ flex:1 }}>
            {score!==null && (
              <div style={{ textAlign:'center' }}>
                <div style={{ fontSize:28, fontWeight:900,
                  color:score>=80?T.green:score>=50?T.orange:T.red }}>{score}%</div>
                <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif", fontSize:16, direction:'rtl',
                  color:score>=80?T.green:score>=50?T.orange:T.red }}>
                  {score>=80 ? 'شاباش!' : score>=50 ? 'اچھا ہے!' : 'محنت کریں!'}
                </div>
              </div>
            )}
            {listening && <Waveform active color={T.pink} />}
            {!score && !listening && (
              <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif",
                fontSize:13, color:T.darkGray, direction:'rtl' }}>
                {avatarSpoken ? 'لفظ بولیں' : 'استاد جی کو سنیں...'}
              </div>
            )}
          </div>
        </div>
        <div style={{ display:'flex', gap:8 }}>
          <Btn onClick={()=>speakWord(word)} color={T.teal} sm emoji="🔊">سنیں</Btn>
          <Btn onClick={handleListen} color={T.orange} sm emoji="🎤" full
            disabled={!avatarSpoken||listening||isSpeaking}>
            {listening ? 'سن رہے ہیں...' : 'بولیں'}
          </Btn>
        </div>
        {score!==null && (
          <div style={{ display:'flex', gap:8 }}>
            {score<50 && (
              <Btn onClick={()=>{ setScore(null); speakWord(word); }}
                color={T.orange} outline sm>دوبارہ</Btn>
            )}
            <Btn onClick={handleNext} color={T.pink} full sm>
              {qIdx<pool.length-1 ? 'اگلا' : 'مکمل'}
            </Btn>
          </div>
        )}
      </div>
    </QuizShell>
  );
}

/* ── Result ── */
function ResultScreen({ score, onRetry }) {
  const stars = score>=80?3:score>=50?2:1;
  const color = score>=80?T.green:score>=50?T.orange:T.red;
  return (
    <div style={{ flex:1, display:'flex', flexDirection:'column', alignItems:'center',
      justifyContent:'center', padding:'32px 24px', gap:20, position:'relative' }}>
      {score>=80 && <Confetti />}
      <ProfessorAvatar mood={score>=80?'praise':score>=50?'happy':'sad'} size={100} floating />
      <div style={{ textAlign:'center' }}>
        <div style={{ fontSize:56, fontWeight:900, color }}>{score}%</div>
        <StarBadge stars={stars} />
        <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif", fontSize:24, fontWeight:900,
          color, direction:'rtl', marginTop:10 }}>
          {score>=80 ? 'شاباش! بہت خوب!' : score>=50 ? 'اچھا ہے! محنت جاری رکھیں' : 'محنت کریں!'}
        </div>
      </div>
      <Btn onClick={onRetry} color={T.purple} full>دوبارہ کوشش</Btn>
    </div>
  );
}

/* ── Main ── */
export default function QuizScreen({ onComplete }) {
  const [stage, setStage]     = useState('setup');
  const [type, setType]       = useState('mcq');
  const [diff, setDiff]       = useState('easy');
  const [finalScore, setFinal] = useState(0);

  const handleDone = (score) => {
    setFinal(score);
    setStage('result');
    onComplete && onComplete({ stars:score>=80?3:score>=50?2:1, moduleId:'quiz' });
  };

  if (stage==='setup')  return <SetupView onStart={(t,d)=>{ setType(t); setDiff(d); setStage('quiz'); }} />;
  if (stage==='result') return <ResultScreen score={finalScore} onRetry={()=>setStage('setup')} />;
  if (type==='mcq')     return <MCQQuiz   difficulty={diff} onDone={handleDone} />;
  if (type==='match')   return <MatchQuiz difficulty={diff} onDone={handleDone} />;
  if (type==='fill')    return <FillQuiz  difficulty={diff} onDone={handleDone} />;
  if (type==='speak')   return <SpeakQuiz difficulty={diff} onDone={handleDone} />;
  return null;
}
