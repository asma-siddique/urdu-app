// UrduApp.jsx — Complete single-file app (no local imports needed)
import { useState, useEffect, useRef, useCallback, useMemo } from 'react';

// ============================================================
// THEME
// ============================================================
const T = {
  purple:'#9b5de5', purpleLight:'#c77dff', purpleDark:'#7b2d8b',
  pink:'#f15bb5',   pinkLight:'#ff85c2',
  teal:'#00bbf9',   tealLight:'#72efdd',
  orange:'#ff6d00', orangeLight:'#ffa040',
  yellow:'#fee440', green:'#00f5d4', greenDark:'#00bb9f',
  red:'#ef233c',    redLight:'#ff6b6b',
  white:'#ffffff',  offWhite:'#f8f9fa', lightGray:'#e9ecef',
  midGray:'#adb5bd',darkGray:'#495057',
  navy:'#1a1a2e',   navyMid:'#16213e', navyLight:'#0f3460',
  cardBg:'#ffffff', screenBg:'#f0f4ff', navBg:'#ffffff',
  shadow:'rgba(0,0,0,0.10)', shadowMd:'rgba(0,0,0,0.18)',
};

// ============================================================
// DATA
// ============================================================
const FULL_ALPHABET = [
  {u:"ا",r:"Alif",       ex:"اونٹ",  eng:"Camel",      emoji:"🐪"},
  {u:"آ",r:"Alif-Mad",   ex:"آم",    eng:"Mango",      emoji:"🥭"},
  {u:"ب",r:"Bay",        ex:"بلی",   eng:"Cat",        emoji:"🐱"},
  {u:"پ",r:"Pay",        ex:"پانی",  eng:"Water",      emoji:"💧"},
  {u:"ت",r:"Tay",        ex:"تتلی",  eng:"Butterfly",  emoji:"🦋"},
  {u:"ٹ",r:"Ttay",       ex:"ٹوپی",  eng:"Hat",        emoji:"🎩"},
  {u:"ث",r:"Say",        ex:"ثمر",   eng:"Fruit",      emoji:"🍎"},
  {u:"ج",r:"Jeem",       ex:"جہاز",  eng:"Aeroplane",  emoji:"✈️"},
  {u:"چ",r:"Chay",       ex:"چاند",  eng:"Moon",       emoji:"🌙"},
  {u:"ح",r:"Hay",        ex:"حلوہ",  eng:"Halwa",      emoji:"🍮"},
  {u:"خ",r:"Khay",       ex:"خرگوش", eng:"Rabbit",     emoji:"🐰"},
  {u:"د",r:"Daal",       ex:"دودھ",  eng:"Milk",       emoji:"🥛"},
  {u:"ڈ",r:"Ddaal",      ex:"ڈبہ",   eng:"Box",        emoji:"📦"},
  {u:"ذ",r:"Zaal",       ex:"ذہین",  eng:"Intelligent",emoji:"🧠"},
  {u:"ر",r:"Ray",        ex:"ریچھ",  eng:"Bear",       emoji:"🐻"},
  {u:"ڑ",r:"Rray",       ex:"لڑکا",  eng:"Boy",        emoji:"👦"},
  {u:"ز",r:"Zay",        ex:"زیبرا", eng:"Zebra",      emoji:"🦓"},
  {u:"ژ",r:"Zhay",       ex:"ژالہ",  eng:"Hail",       emoji:"🌨️"},
  {u:"س",r:"Seen",       ex:"سیب",   eng:"Apple",      emoji:"🍎"},
  {u:"ش",r:"Sheen",      ex:"شیر",   eng:"Lion",       emoji:"🦁"},
  {u:"ص",r:"Suaad",      ex:"صابن",  eng:"Soap",       emoji:"🧼"},
  {u:"ض",r:"Zuaad",      ex:"ضرور",  eng:"Necessary",  emoji:"✔️"},
  {u:"ط",r:"Toay",       ex:"طوطا",  eng:"Parrot",     emoji:"🦜"},
  {u:"ظ",r:"Zoay",       ex:"ظالم",  eng:"Cruel",      emoji:"😈"},
  {u:"ع",r:"Ain",        ex:"عقاب",  eng:"Eagle",      emoji:"🦅"},
  {u:"غ",r:"Ghain",      ex:"غبارہ", eng:"Balloon",    emoji:"🎈"},
  {u:"ف",r:"Fay",        ex:"فیل",   eng:"Elephant",   emoji:"🐘"},
  {u:"ق",r:"Qaaf",       ex:"قلم",   eng:"Pen",        emoji:"✏️"},
  {u:"ک",r:"Kaaf",       ex:"کتاب",  eng:"Book",       emoji:"📚"},
  {u:"گ",r:"Gaaf",       ex:"گائے",  eng:"Cow",        emoji:"🐄"},
  {u:"ل",r:"Laam",       ex:"لمبا",  eng:"Tall",       emoji:"📏"},
  {u:"م",r:"Meem",       ex:"مچھلی", eng:"Fish",       emoji:"🐟"},
  {u:"ن",r:"Noon",       ex:"ناشتہ", eng:"Breakfast",  emoji:"🍳"},
  {u:"ں",r:"Noon Ghunna",ex:"ہاں",   eng:"Yes",        emoji:"✅"},
  {u:"و",r:"Wow",        ex:"وقت",   eng:"Time",       emoji:"⏰"},
  {u:"ہ",r:"Hay2",       ex:"ہاتھی", eng:"Elephant",   emoji:"🐘"},
  {u:"ھ",r:"Do-Chashmi", ex:"بھالو", eng:"Bear",       emoji:"🐻"},
  {u:"ء",r:"Hamza",      ex:"جزء",   eng:"Part",       emoji:"📌"},
  {u:"ی",r:"Choti Yay",  ex:"یاد",   eng:"Memory",     emoji:"💭"},
  {u:"ے",r:"Bari Yay",   ex:"لڑکے",  eng:"Boys",       emoji:"👦"},
];

const WORDS = [
  {u:"بلی",   r:"Billi",   eng:"Cat",       emoji:"🐱",cat:"جانور",level:"easy",  phonemes:["bi","l","li"],   target:"billi"},
  {u:"کتا",   r:"Kutta",   eng:"Dog",       emoji:"🐶",cat:"جانور",level:"easy",  phonemes:["ku","tt","a"],   target:"kutta"},
  {u:"شیر",   r:"Sher",    eng:"Lion",      emoji:"🦁",cat:"جانور",level:"easy",  phonemes:["sh","er"],       target:"sher"},
  {u:"ہاتھی", r:"Haathi",  eng:"Elephant",  emoji:"🐘",cat:"جانور",level:"medium",phonemes:["haa","th","i"],  target:"haathi"},
  {u:"بندر",  r:"Bandar",  eng:"Monkey",    emoji:"🐒",cat:"جانور",level:"medium",phonemes:["ban","dar"],     target:"bandar"},
  {u:"مچھلی", r:"Machhli", eng:"Fish",      emoji:"🐟",cat:"جانور",level:"medium",phonemes:["mach","hli"],    target:"machhli"},
  {u:"آم",    r:"Aam",     eng:"Mango",     emoji:"🥭",cat:"کھانا",level:"easy",  phonemes:["aa","m"],        target:"aam"},
  {u:"سیب",   r:"Saib",    eng:"Apple",     emoji:"🍎",cat:"کھانا",level:"easy",  phonemes:["sa","ib"],       target:"saib"},
  {u:"دودھ",  r:"Doodh",   eng:"Milk",      emoji:"🥛",cat:"کھانا",level:"easy",  phonemes:["doo","dh"],      target:"doodh"},
  {u:"روٹی",  r:"Roti",    eng:"Bread",     emoji:"🫓",cat:"کھانا",level:"easy",  phonemes:["ro","ti"],       target:"roti"},
  {u:"کیلا",  r:"Kela",    eng:"Banana",    emoji:"🍌",cat:"کھانا",level:"easy",  phonemes:["ke","la"],       target:"kela"},
  {u:"گاجر",  r:"Gajar",   eng:"Carrot",    emoji:"🥕",cat:"کھانا",level:"medium",phonemes:["ga","jar"],      target:"gajar"},
  {u:"سورج",  r:"Suraj",   eng:"Sun",       emoji:"☀️",cat:"فطرت", level:"easy",  phonemes:["su","raj"],      target:"suraj"},
  {u:"چاند",  r:"Chaand",  eng:"Moon",      emoji:"🌙",cat:"فطرت", level:"easy",  phonemes:["chaa","nd"],     target:"chaand"},
  {u:"درخت",  r:"Darakht", eng:"Tree",      emoji:"🌳",cat:"فطرت", level:"medium",phonemes:["da","rakht"],    target:"darakht"},
  {u:"پھول",  r:"Phool",   eng:"Flower",    emoji:"🌸",cat:"فطرت", level:"easy",  phonemes:["phoo","l"],      target:"phool"},
  {u:"کتاب",  r:"Kitaab",  eng:"Book",      emoji:"📚",cat:"چیزیں",level:"easy",  phonemes:["ki","taab"],     target:"kitaab"},
  {u:"قلم",   r:"Qalam",   eng:"Pen",       emoji:"✏️",cat:"چیزیں",level:"easy",  phonemes:["qa","lam"],      target:"qalam"},
  {u:"گھر",   r:"Ghar",    eng:"House",     emoji:"🏠",cat:"چیزیں",level:"easy",  phonemes:["gha","r"],       target:"ghar"},
  {u:"میز",   r:"Mez",     eng:"Table",     emoji:"🪑",cat:"چیزیں",level:"easy",  phonemes:["me","z"],        target:"mez"},
  {u:"ہاتھ",  r:"Haath",   eng:"Hand",      emoji:"✋",cat:"جسم",  level:"easy",  phonemes:["haa","th"],      target:"haath"},
  {u:"آنکھ",  r:"Aankh",   eng:"Eye",       emoji:"👁️",cat:"جسم",  level:"easy",  phonemes:["aan","kh"],      target:"aankh"},
  {u:"کان",   r:"Kaan",    eng:"Ear",       emoji:"👂",cat:"جسم",  level:"easy",  phonemes:["kaa","n"],       target:"kaan"},
  {u:"ناک",   r:"Naak",    eng:"Nose",      emoji:"👃",cat:"جسم",  level:"easy",  phonemes:["naa","k"],       target:"naak"},
  {u:"دل",    r:"Dil",     eng:"Heart",     emoji:"❤️",cat:"جسم",  level:"easy",  phonemes:["di","l"],        target:"dil"},
];

const SENTENCES = [
  {u:"میرا نام احمد ہے۔",   eng:"My name is Ahmed.",        audio:"mera naam ahmad hai"},
  {u:"یہ میری کتاب ہے۔",    eng:"This is my book.",         audio:"yeh meri kitaab hai"},
  {u:"آج موسم اچھا ہے۔",    eng:"The weather is nice today.",audio:"aaj mausam acha hai"},
  {u:"مجھے پانی چاہیے۔",   eng:"I want water.",            audio:"mujhe paani chahiye"},
  {u:"استاد جی سلام۔",      eng:"Hello teacher.",           audio:"ustad ji salaam"},
  {u:"میں اسکول جاتا ہوں۔", eng:"I go to school.",          audio:"mein school jaata hoon"},
  {u:"گھر پر امی ہیں۔",     eng:"Mum is at home.",          audio:"ghar par ami hain"},
  {u:"یہ بلی بہت پیاری ہے۔",eng:"This cat is very cute.",   audio:"yeh billi bohat pyaari hai"},
  {u:"مجھے اردو پسند ہے۔",  eng:"I like Urdu.",             audio:"mujhe urdu pasand hai"},
];

const COLORS = [
  {u:"سرخ",   r:"Surkh",   eng:"Red",    hex:"#e63946",light:"#ffd6d8",emoji:"🍎"},
  {u:"نیلا",  r:"Neela",   eng:"Blue",   hex:"#4361ee",light:"#d6e0ff",emoji:"🫐"},
  {u:"سبز",   r:"Sabz",    eng:"Green",  hex:"#2dc653",light:"#d0f5dc",emoji:"🍃"},
  {u:"پیلا",  r:"Peela",   eng:"Yellow", hex:"#f4d03f",light:"#fff9c4",emoji:"🌻"},
  {u:"سفید",  r:"Safaid",  eng:"White",  hex:"#adb5bd",light:"#e9ecef",emoji:"☁️"},
  {u:"کالا",  r:"Kaala",   eng:"Black",  hex:"#212529",light:"#ced4da",emoji:"🐦"},
  {u:"نارنجی",r:"Naaranji",eng:"Orange", hex:"#fd7e14",light:"#ffe5cc",emoji:"🍊"},
  {u:"گلابی", r:"Gulaabi", eng:"Pink",   hex:"#e91e8c",light:"#ffd6ec",emoji:"🌸"},
  {u:"جامنی", r:"Jaamni",  eng:"Purple", hex:"#7b2d8b",light:"#e8d5f5",emoji:"🍇"},
  {u:"بھورا", r:"Bhoora",  eng:"Brown",  hex:"#795548",light:"#d7ccc8",emoji:"🪵"},
  {u:"سنہری", r:"Sunehri", eng:"Gold",   hex:"#f9c74f",light:"#fff3cd",emoji:"⭐"},
  {u:"آسمانی",r:"Aasmani", eng:"Sky Blue",hex:"#00b4d8",light:"#caf0f8",emoji:"🌤️"},
  {u:"خاکی",  r:"Khaaki",  eng:"Khaki",  hex:"#b5a642",light:"#f0ead2",emoji:"🪨"},
  {u:"سلیٹی", r:"Sileti",  eng:"Grey",   hex:"#6c757d",light:"#dee2e6",emoji:"🌫️"},
];

const FILL_BLANKS = [
  {sentence:"میرا ___ احمد ہے۔",  answer:"نام",  opts:["نام","گھر","کام","دل"],    eng:"My ___ is Ahmed."},
  {sentence:"یہ میری ___ ہے۔",    answer:"کتاب", opts:["کتاب","بلی","میز","گھڑی"], eng:"This is my ___."},
  {sentence:"آج موسم ___ ہے۔",    answer:"اچھا", opts:["اچھا","برا","بڑا","تیز"],  eng:"Weather is ___."},
  {sentence:"مجھے ___ چاہیے۔",    answer:"پانی", opts:["پانی","کھانا","نیند","کتاب"],eng:"I want ___."},
  {sentence:"شیر ایک ___ جانور ہے۔",answer:"بڑا",opts:["بڑا","چھوٹا","پیارا","تیز"],eng:"Lion is a ___ animal."},
  {sentence:"یہ بلی بہت ___ ہے۔", answer:"پیاری",opts:["پیاری","بڑی","تیز","کالی"], eng:"This cat is very ___."},
];

const MATCH_DATA = [
  {emoji:"🐱",answer:"بلی",  opts:["بلی","کتا","شیر","بندر"]},
  {emoji:"🍎",answer:"سیب",  opts:["سیب","آم","کیلا","گاجر"]},
  {emoji:"☀️",answer:"سورج", opts:["سورج","چاند","ستارہ","آسمان"]},
  {emoji:"📚",answer:"کتاب", opts:["کتاب","قلم","میز","گھڑی"]},
  {emoji:"🥛",answer:"دودھ", opts:["دودھ","پانی","چائے","جوس"]},
  {emoji:"🌸",answer:"پھول", opts:["پھول","درخت","پتہ","ندی"]},
  {emoji:"🐘",answer:"ہاتھی",opts:["ہاتھی","شیر","زیبرا","بندر"]},
  {emoji:"🏠",answer:"گھر",  opts:["گھر","دروازہ","کھڑکی","چھت"]},
  {emoji:"✋",answer:"ہاتھ", opts:["ہاتھ","پیر","آنکھ","کان"]},
  {emoji:"🌙",answer:"چاند", opts:["چاند","سورج","ستارہ","رات"]},
];

// ============================================================
// UTILS
// ============================================================
function levenshtein(a,b){
  const m=a.length,n=b.length;
  const dp=Array.from({length:m+1},(_,i)=>Array.from({length:n+1},(_,j)=>i===0?j:j===0?i:0));
  for(let i=1;i<=m;i++)for(let j=1;j<=n;j++)
    dp[i][j]=a[i-1]===b[j-1]?dp[i-1][j-1]:1+Math.min(dp[i-1][j-1],dp[i-1][j],dp[i][j-1]);
  return dp[m][n];
}
function scorePronunciation(transcript,target,conf=0){
  if(!transcript||transcript.trim()==='')return 5;
  const t=transcript.toLowerCase().trim(),g=target.toLowerCase().trim();
  if(/[\u0600-\u06FF]/.test(t))return Math.min(65,35+Math.round(conf*15));
  const maxLen=Math.max(t.length,g.length);
  const sim=maxLen===0?1:Math.max(0,1-levenshtein(t,g)/maxLen);
  return Math.min(100,Math.round(sim*85)+Math.round(conf*15));
}
function simulateScore(onResult){
  setTimeout(()=>onResult(Math.round(10+Math.random()*40),0.2+Math.random()*0.3,''),1200+Math.random()*800);
}
function scorePhonemes(phonemes,score){return phonemes.map(()=>Math.random()*100<score);}
function capitaliseName(n){const s=(n||'').trim();return s?s[0].toUpperCase()+s.slice(1):'';}
function getGreeting(h){
  if(h<12)return{eng:"Good morning", urdu:"صبح بخیر",  emoji:"🌅"};
  if(h<17)return{eng:"Good afternoon",urdu:"دوپہر بخیر",emoji:"☀️"};
  if(h<20)return{eng:"Good evening", urdu:"شام بخیر",  emoji:"🌇"};
  return         {eng:"Good night",   urdu:"شب بخیر",   emoji:"🌙"};
}
function shuffle(arr){const a=[...arr];for(let i=a.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[a[i],a[j]]=[a[j],a[i]];}return a;}

// ============================================================
// TTS HOOK
// ============================================================
let _cachedVoice=null;
function findUrduVoice(){
  if(_cachedVoice)return _cachedVoice;
  const vs=window.speechSynthesis?.getVoices()||[];
  _cachedVoice=vs.find(v=>v.lang==='ur-PK')||vs.find(v=>v.lang.startsWith('ur'))||null;
  return _cachedVoice;
}
function useTTS(){
  const [isSpeaking,setIs]=useState(false);
  const synthRef=useRef(window.speechSynthesis);
  useEffect(()=>{
    const h=()=>{_cachedVoice=null;};
    window.speechSynthesis?.addEventListener('voiceschanged',h);
    return()=>window.speechSynthesis?.removeEventListener('voiceschanged',h);
  },[]);
  const stop=useCallback(()=>{synthRef.current?.cancel();setIs(false);},[]);
  const speak=useCallback((text,onEnd)=>{
    stop();if(!text){onEnd&&onEnd();return;}
    const utt=new SpeechSynthesisUtterance(text);
    utt.lang='ur-PK';utt.rate=0.72;utt.pitch=1.05;
    const v=findUrduVoice();if(v)utt.voice=v;
    utt.onstart=()=>setIs(true);
    utt.onend=()=>{setIs(false);onEnd&&onEnd();};
    utt.onerror=()=>{setIs(false);onEnd&&onEnd();};
    setIs(true);synthRef.current?.speak(utt);
  },[stop]);
  useEffect(()=>()=>stop(),[stop]);
  return{speak,stop,isSpeaking};
}
function useSpeechRecognition(){
  const SR=window.SpeechRecognition||window.webkitSpeechRecognition;
  const listen=useCallback((target,onResult)=>{
    if(!SR){simulateScore(onResult);return;}
    const r=new SR();r.lang='ur-PK';r.interimResults=false;r.maxAlternatives=1;
    r.onresult=e=>{const res=e.results[0][0];onResult(null,res.confidence,res.transcript);};
    r.onerror=()=>simulateScore(onResult);
    r.start();
  },[]);
  return{listen};
}
function useLiveClock(){
  const[now,set]=useState(new Date());
  useEffect(()=>{const id=setInterval(()=>set(new Date()),1000);return()=>clearInterval(id);},[]);
  return now;
}

// ============================================================
// UI COMPONENTS
// ============================================================
const UR={fontFamily:"'Noto Nastaliq Urdu',serif",direction:'rtl'};

function PBar({value,max,color=T.purple,height=8}){
  return <div style={{background:T.lightGray,borderRadius:99,height,overflow:'hidden',width:'100%'}}>
    <div style={{width:`${Math.round(value/max*100)}%`,height:'100%',background:color,borderRadius:99,transition:'width 0.4s ease'}}/>
  </div>;
}
function StarBadge({stars=0}){
  return <div style={{display:'flex',gap:4,justifyContent:'center'}}>
    {[1,2,3].map(i=><span key={i} style={{fontSize:22,filter:i<=stars?'none':'grayscale(1) opacity(0.3)'}}>{i<=stars?'⭐':'☆'}</span>)}
  </div>;
}
function Waveform({active=false,color=T.purple}){
  const bars=[0.4,0.7,1,0.8,0.6,0.9,0.5];
  return <div style={{display:'flex',alignItems:'center',gap:3,height:36}}>
    {bars.map((h,i)=><div key={i} style={{width:5,height:active?`${h*32+4}px`:'4px',background:active?color:T.midGray,borderRadius:3,transition:'height 0.15s ease'}}/>)}
  </div>;
}
function Btn({children,onClick,color=T.purple,outline=false,disabled=false,full=false,sm=false,emoji=null}){
  return <button onClick={onClick} disabled={disabled} style={{
    display:'flex',alignItems:'center',justifyContent:'center',gap:6,
    padding:sm?'7px 16px':'11px 22px',
    background:disabled?T.lightGray:outline?'transparent':color,
    color:disabled?T.midGray:outline?color:T.white,
    border:outline?`2px solid ${color}`:'none',
    borderRadius:14,fontSize:sm?13:15,fontWeight:700,
    cursor:disabled?'not-allowed':'pointer',
    width:full?'100%':undefined,
    boxShadow:disabled?'none':`0 3px 10px ${color}55`,
    transition:'all 0.2s',...UR}}>
    {emoji&&<span style={{fontSize:sm?14:18}}>{emoji}</span>}{children}
  </button>;
}
function Confetti(){
  const emojis=['🎉','⭐','🌟','✨','🎊','💫'];
  const pieces=Array.from({length:16},(_,i)=>({id:i,e:emojis[i%emojis.length],l:`${Math.random()*88}%`,d:`${Math.random()*0.8}s`}));
  return <div style={{position:'absolute',inset:0,pointerEvents:'none',overflow:'hidden',zIndex:99}}>
    {pieces.map(p=><div key={p.id} style={{position:'absolute',left:p.l,top:'-10%',fontSize:18,animation:`confettiFall 1.5s ${p.d} ease-in forwards`}}>{p.e}</div>)}
  </div>;
}
function BadgePopup({badge,onClose}){
  return <div style={{position:'absolute',inset:0,background:'rgba(0,0,0,0.55)',zIndex:200,display:'flex',alignItems:'center',justifyContent:'center'}} onClick={onClose}>
    <div style={{background:T.white,borderRadius:24,padding:'32px 28px',textAlign:'center',animation:'badgePop 0.4s ease',maxWidth:280,boxShadow:`0 8px 32px ${T.shadowMd}`}}>
      <div style={{fontSize:56,marginBottom:8}}>{badge.icon}</div>
      <div style={{fontSize:20,fontWeight:900,color:T.navy,marginBottom:4}}>{badge.label}</div>
      <div style={{fontSize:13,color:T.darkGray,marginBottom:20,...UR}}>{badge.desc}</div>
      <Btn onClick={onClose} color={T.purple} sm>شاباش! 🎉</Btn>
    </div>
  </div>;
}
function ScoreDisplay({score}){
  const stars=score>=80?3:score>=50?2:1;
  const color=score>=80?T.green:score>=50?T.orange:T.red;
  return <div style={{textAlign:'center'}}>
    <div style={{fontSize:32,fontWeight:900,color}}>{score}%</div>
    <StarBadge stars={stars}/>
    <div style={{fontSize:18,fontWeight:700,color,marginTop:4,...UR}}>{score>=80?'شاباش!':score>=50?'اچھا ہے!':'محنت کریں!'}</div>
  </div>;
}
function SpeakingNotice(){
  return <div style={{background:T.orange,color:T.white,borderRadius:12,padding:'8px 16px',fontSize:13,fontWeight:700,textAlign:'center',display:'flex',alignItems:'center',justifyContent:'center',gap:8,...UR}}>
    <span>🔊</span><span>اُستاد جی بول رہے ہیں... سنیں!</span>
  </div>;
}

// ============================================================
// PROFESSOR AVATAR
// ============================================================
const MOODS={
  happy:   {ey:38,md:"M 30 52 Q 40 62 50 52"},
  sad:     {ey:38,md:"M 30 58 Q 40 50 50 58"},
  neutral: {ey:38,md:"M 30 55 Q 40 55 50 55"},
  excited: {ey:36,md:"M 27 50 Q 40 65 53 50"},
  praise:  {ey:34,md:"M 26 50 Q 40 68 54 50"},
  speaking:{ey:38,md:"M 30 52 Q 40 60 50 52"},
};
function ProfessorAvatar({mood='neutral',size=100,floating=false,speaking=false}){
  const m=MOODS[mood]||MOODS.neutral;
  return <div style={{width:size,height:size,animation:floating?'tutorFloat 3s ease-in-out infinite':undefined,display:'inline-block'}}>
    <svg viewBox="0 0 80 100" width={size} height={size}>
      <ellipse cx="40" cy="20" rx="22" ry="14" fill={T.teal}/>
      <ellipse cx="40" cy="14" rx="18" ry="8" fill={T.tealLight}/>
      <rect x="18" y="20" width="44" height="6" rx="3" fill={T.teal}/>
      <circle cx="40" cy="11" r="4" fill={T.orange}/>
      <ellipse cx="40" cy="44" rx="20" ry="22" fill="#FDBCB4"/>
      <ellipse cx="40" cy="62" rx="15" ry="8" fill="#c8a882"/>
      <ellipse cx="33" cy={m.ey} rx="4" ry="4.5" fill="white"/>
      <ellipse cx="47" cy={m.ey} rx="4" ry="4.5" fill="white"/>
      <circle cx="33" cy={m.ey} r="2.5" fill="#2d2d2d"/>
      <circle cx="47" cy={m.ey} r="2.5" fill="#2d2d2d"/>
      <rect x="26" y={m.ey-6} width="12" height="11" rx="3" fill="none" stroke={T.navy} strokeWidth="1.5"/>
      <rect x="42" y={m.ey-6} width="12" height="11" rx="3" fill="none" stroke={T.navy} strokeWidth="1.5"/>
      <line x1="38" y1={m.ey-1} x2="42" y2={m.ey-1} stroke={T.navy} strokeWidth="1.5"/>
      <ellipse cx="40" cy="48" rx="2.5" ry="2" fill="#e8967a"/>
      <path d={m.md} fill="none" stroke="#c0694e" strokeWidth="2" strokeLinecap="round"/>
      {speaking&&<>
        <circle cx="33" cy="74" r="2.5" fill={T.orange}><animate attributeName="r" values="2.5;3.5;2.5" dur="0.6s" repeatCount="indefinite"/></circle>
        <circle cx="40" cy="76" r="2.5" fill={T.orange}><animate attributeName="r" values="2.5;3.5;2.5" dur="0.6s" begin="0.2s" repeatCount="indefinite"/></circle>
        <circle cx="47" cy="74" r="2.5" fill={T.orange}><animate attributeName="r" values="2.5;3.5;2.5" dur="0.6s" begin="0.4s" repeatCount="indefinite"/></circle>
      </>}
      <path d="M 20 82 Q 20 72 40 70 Q 60 72 60 82 L 65 100 L 15 100 Z" fill={T.purple}/>
      <rect x="15" y="76" width="14" height="16" rx="2" fill={T.orange}/>
      <rect x="16" y="77" width="12" height="14" rx="1" fill="#fff3e0"/>
    </svg>
  </div>;
}

// ============================================================
// BOTTOM NAV
// ============================================================
const NAV=[{id:'home',label:'گھر',icon:'🏠'},{id:'haroof',label:'حروف',icon:'ا'},{id:'lafz',label:'الفاظ',icon:'📝'},{id:'jumlay',label:'جملے',icon:'💬'},{id:'rang',label:'رنگ',icon:'🎨'},{id:'quiz',label:'کوئز',icon:'🏆'}];
function BottomNav({active,onNavigate}){
  return <div style={{display:'flex',background:T.navBg,borderTop:`1.5px solid ${T.lightGray}`,height:60}}>
    {NAV.map(item=>{
      const isA=active===item.id,c=item.id==='rang'?T.pink:T.purple;
      return <button key={item.id} onClick={()=>onNavigate(item.id)} style={{flex:1,border:'none',background:'none',cursor:'pointer',display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',gap:2,padding:'4px 0'}}>
        <span style={{fontSize:item.id==='haroof'?16:18,fontFamily:item.id==='haroof'?"'Noto Nastaliq Urdu',serif":undefined,filter:isA?'none':'grayscale(0.5) opacity(0.6)'}}>{item.icon}</span>
        <span style={{fontSize:9,fontWeight:isA?800:500,color:isA?c:T.darkGray,...UR}}>{item.label}</span>
        {isA&&<div style={{width:4,height:4,borderRadius:'50%',background:c}}/>}
      </button>;
    })}
  </div>;
}

// ============================================================
// SCREENS
// ============================================================

// -- SPLASH --
function SplashScreen({onDone}){
  useEffect(()=>{const t=setTimeout(onDone,2600);return()=>clearTimeout(t);},[onDone]);
  return <div style={{flex:1,display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',background:`linear-gradient(160deg,${T.purple} 0%,${T.navyMid} 100%)`,gap:24}}>
    <div style={{animation:'tutorFloat 2.5s ease-in-out infinite'}}><ProfessorAvatar mood="excited" size={130}/></div>
    <div style={{textAlign:'center'}}>
      <div style={{fontSize:36,fontWeight:900,color:T.white,...UR}}>اردو سیکھیں</div>
      <div style={{fontSize:15,color:'rgba(255,255,255,0.75)',fontWeight:600,marginTop:6}}>AI-Powered Urdu Learning</div>
    </div>
    <div style={{display:'flex',gap:8}}>
      {[0,1,2].map(i=><div key={i} style={{width:8,height:8,borderRadius:'50%',background:`rgba(255,255,255,${0.4+i*0.2})`,animation:`pulse 1.2s ease-in-out ${i*0.3}s infinite`}}/>)}
    </div>
  </div>;
}

// -- SETUP --
function SetupScreen({onDone}){
  const[step,setStep]=useState(0);
  const[avatar,setAvatar]=useState('boy');
  const[nameInput,setName]=useState('');
  const clean=capitaliseName(nameInput);
  return <div style={{flex:1,display:'flex',flexDirection:'column',background:`linear-gradient(160deg,${T.purple}ee 0%,${T.navy} 100%)`,padding:'32px 24px 24px',gap:20}}>
    <div style={{textAlign:'center'}}>
      <ProfessorAvatar mood="happy" size={88} floating/>
      <div style={{marginTop:12,fontSize:22,fontWeight:900,color:T.white,...UR}}>خوش آمدید!</div>
      <div style={{color:'rgba(255,255,255,0.75)',fontSize:13,marginTop:4}}>Welcome! Let's get started.</div>
    </div>
    <div style={{background:T.white,borderRadius:24,padding:24,flex:1,display:'flex',flexDirection:'column',gap:20}}>
      {step===0&&<>
        <div style={{textAlign:'center'}}>
          <div style={{fontSize:16,fontWeight:700,color:T.navy,marginBottom:16}}>Choose your avatar</div>
          <div style={{display:'flex',gap:16,justifyContent:'center'}}>
            {[{id:'boy',e:'👦'},{id:'girl',e:'👧'}].map(a=><button key={a.id} onClick={()=>setAvatar(a.id)} style={{width:90,height:90,borderRadius:20,border:`3px solid ${avatar===a.id?T.purple:T.lightGray}`,background:avatar===a.id?`${T.purple}15`:T.offWhite,cursor:'pointer',fontSize:44}}>
              {a.e}
            </button>)}
          </div>
        </div>
        <Btn onClick={()=>setStep(1)} color={T.purple} full>Next</Btn>
      </>}
      {step===1&&<>
        <div>
          <div style={{fontSize:16,fontWeight:700,color:T.navy,marginBottom:12}}>What's your name?</div>
          <input value={nameInput} onChange={e=>setName(e.target.value)} placeholder="Enter your name..." maxLength={20} style={{width:'100%',padding:'12px 16px',borderRadius:14,fontSize:16,border:`2px solid ${nameInput?T.purple:T.lightGray}`,outline:'none',fontWeight:600,color:T.navy,boxSizing:'border-box'}}/>
        </div>
        {clean&&<div style={{background:`${T.purple}12`,borderRadius:16,padding:'14px 18px',textAlign:'center'}}>
          <div style={{fontSize:22,fontWeight:900,color:T.purple}}>{{boy:'👦',girl:'👧'}[avatar]} {clean}</div>
          <div style={{fontSize:12,color:T.darkGray,marginTop:4}}>Ready to learn Urdu!</div>
        </div>}
        <div style={{display:'flex',gap:10,marginTop:'auto'}}>
          <Btn onClick={()=>setStep(0)} color={T.midGray} outline sm>Back</Btn>
          <Btn onClick={()=>onDone({name:clean,avatar})} color={T.purple} full disabled={!clean}>Start Learning!</Btn>
        </div>
      </>}
    </div>
  </div>;
}

// -- HOME --
function HomeScreen({user,completedMap={},starsMap={},onNavigate}){
  const clock=useLiveClock();
  const greet=getGreeting(clock.getHours());
  const MODS=[
    {id:'haroof',title:'حروف تہجی',sub:'Alphabet',  icon:'ا',  color:T.purple},
    {id:'lafz',  title:'الفاظ',    sub:'Words',      icon:'📝', color:T.teal},
    {id:'jumlay',title:'جملے',     sub:'Sentences',  icon:'💬', color:T.orange},
    {id:'rang',  title:'رنگ',      sub:'Colours',    icon:'🎨', color:T.pink},
    {id:'quiz',  title:'کوئز',     sub:'Quiz',       icon:'🏆', color:T.green},
  ];
  const done=Object.values(completedMap).filter(Boolean).length;
  const totalStars=Object.values(starsMap).reduce((s,v)=>s+(v||0),0);
  return <div style={{flex:1,overflowY:'auto',background:T.screenBg,display:'flex',flexDirection:'column'}}>
    <div style={{background:`linear-gradient(135deg,${T.purple} 0%,${T.navyLight} 100%)`,padding:'24px 20px 28px',position:'relative',overflow:'hidden'}}>
      <div style={{position:'absolute',top:-30,right:-30,width:120,height:120,borderRadius:'50%',background:'rgba(255,255,255,0.06)'}}/>
      <div style={{display:'flex',alignItems:'center',gap:14,position:'relative',zIndex:1}}>
        <ProfessorAvatar mood="happy" size={72} floating/>
        <div>
          <div style={{display:'flex',alignItems:'center',gap:6,marginBottom:2}}>
            <span style={{fontSize:15}}>{greet.emoji}</span>
            <span style={{color:'rgba(255,255,255,0.80)',fontSize:12,fontWeight:600}}>{greet.eng}</span>
          </div>
          <div style={{color:T.white,fontSize:22,fontWeight:900}}>{user.name}!</div>
          <div style={{color:'rgba(255,255,255,0.70)',fontSize:14,...UR}}>{greet.urdu}</div>
        </div>
      </div>
      <div style={{background:'rgba(255,255,255,0.12)',borderRadius:14,padding:'10px 14px',marginTop:16,position:'relative',zIndex:1,display:'flex',alignItems:'center',gap:12}}>
        <div style={{flex:1}}>
          <div style={{display:'flex',justifyContent:'space-between',marginBottom:5}}>
            <span style={{color:'rgba(255,255,255,0.8)',fontSize:11,fontWeight:600}}>Progress</span>
            <span style={{color:T.yellow,fontSize:11,fontWeight:700}}>{done}/{MODS.length} modules</span>
          </div>
          <PBar value={done} max={MODS.length} color={T.yellow} height={7}/>
        </div>
        <div style={{textAlign:'center'}}>
          <div style={{fontSize:18}}>⭐</div>
          <div style={{color:T.yellow,fontWeight:900,fontSize:13}}>{totalStars}</div>
        </div>
      </div>
    </div>
    <div style={{padding:'20px 16px',display:'grid',gridTemplateColumns:'1fr 1fr',gap:12}}>
      {MODS.map(mod=>{
        const d=!!completedMap[mod.id],st=starsMap[mod.id]||0;
        return <button key={mod.id} onClick={()=>onNavigate(mod.id)} style={{background:T.white,border:`2px solid ${d?mod.color+'66':T.lightGray}`,borderRadius:20,padding:'16px 12px',cursor:'pointer',textAlign:'center',boxShadow:`0 2px 10px ${T.shadow}`,position:'relative'}}>
          {d&&<div style={{position:'absolute',top:8,right:8,background:mod.color,color:'white',borderRadius:'50%',width:20,height:20,fontSize:11,fontWeight:900,display:'flex',alignItems:'center',justifyContent:'center'}}>✓</div>}
          <div style={{fontSize:mod.id==='haroof'?26:30,fontFamily:mod.id==='haroof'?"'Noto Nastaliq Urdu',serif":undefined,color:mod.id==='haroof'?mod.color:undefined,marginBottom:8}}>{mod.icon}</div>
          <div style={{fontSize:16,fontWeight:800,color:mod.color,...UR,marginBottom:2}}>{mod.title}</div>
          <div style={{fontSize:11,color:T.darkGray,fontWeight:600}}>{mod.sub}</div>
          {st>0&&<div style={{marginTop:6,fontSize:12}}>{'⭐'.repeat(st)}{'☆'.repeat(3-st)}</div>}
        </button>;
      })}
    </div>
  </div>;
}

// -- HAROOF --
function HaroofScreen({onComplete}){
  const[idx,setIdx]=useState(0);
  const[score,setScore]=useState(null);
  const[listening,setListening]=useState(false);
  const[avatarSpoken,setAS]=useState(false);
  const[showAll,setShowAll]=useState(false);
  const letter=FULL_ALPHABET[idx];
  const{speak,stop,isSpeaking}=useTTS();
  const{listen}=useSpeechRecognition();
  const speakL=useCallback((l)=>{setAS(false);speak(`${l.u}۔ ${l.ex}۔`,()=>setAS(true));},[speak]);
  useEffect(()=>{setScore(null);setAS(false);const t=setTimeout(()=>speakL(letter),450);return()=>{clearTimeout(t);stop();};},[idx]);
  const handleListen=()=>{
    if(!avatarSpoken||isSpeaking)return;
    setListening(true);setScore(null);
    listen(letter.r,(raw,conf,tr)=>{setListening(false);const s=raw!==null?raw:scorePronunciation(tr,letter.r,conf);setScore(s);speak(s>=80?'شاباش! بہت خوب!':s>=50?'اچھا ہے!':'دوبارہ کوشش کریں۔',null);});
  };
  return <div style={{flex:1,overflowY:'auto',background:T.screenBg,display:'flex',flexDirection:'column',padding:16,gap:12}}>
    <div style={{background:`${T.purple}18`,borderRadius:14,padding:'10px 14px',fontSize:13,color:T.purple,...UR}}>اردو کے چالیس حروف سیکھیں اور ادا کریں</div>
    <div style={{display:'flex',alignItems:'center',gap:10}}>
      <div style={{flex:1}}><PBar value={idx+1} max={FULL_ALPHABET.length} color={T.purple} height={7}/></div>
      <span style={{fontSize:11,fontWeight:700,color:T.darkGray,whiteSpace:'nowrap'}}>{idx+1}/{FULL_ALPHABET.length}</span>
      <button onClick={()=>setShowAll(s=>!s)} style={{background:'none',border:`1.5px solid ${T.purple}`,borderRadius:10,padding:'4px 10px',fontSize:11,color:T.purple,cursor:'pointer',fontWeight:700}}>{showAll?'کارڈ':'سب'}</button>
    </div>
    {showAll?<div style={{background:T.white,borderRadius:20,padding:16,display:'flex',flexWrap:'wrap',gap:8,direction:'rtl'}}>
      {FULL_ALPHABET.map((l,i)=><button key={i} onClick={()=>{setIdx(i);setShowAll(false);}} style={{width:46,height:46,borderRadius:10,border:`2px solid ${i===idx?T.purple:T.lightGray}`,background:i===idx?T.purple:T.offWhite,color:i===idx?T.white:T.navy,fontFamily:"'Noto Nastaliq Urdu',serif",fontSize:20,fontWeight:800,cursor:'pointer',display:'flex',alignItems:'center',justifyContent:'center'}}>{l.u}</button>)}
    </div>:<>
      <div style={{background:T.white,borderRadius:24,overflow:'hidden',boxShadow:`0 4px 20px ${T.shadow}`}}>
        <div style={{height:8,background:`linear-gradient(90deg,${T.purple},${T.purpleLight})`}}/>
        <div style={{padding:'20px 20px 24px',display:'flex',flexDirection:'column',alignItems:'center',gap:0}}>
          <div style={{fontFamily:"'Noto Nastaliq Urdu',serif",fontSize:96,fontWeight:900,color:T.purple,lineHeight:1.1,marginBottom:4}}>{letter.u}</div>
          <div style={{background:`${T.purple}18`,borderRadius:20,padding:'3px 14px',fontSize:13,fontWeight:800,color:T.purple,marginBottom:16}}>{letter.r}</div>
          <div style={{width:'100%',height:1,background:T.lightGray,marginBottom:16}}/>
          <div style={{width:'100%',display:'flex',alignItems:'center',justifyContent:'center',gap:16}}>
            <div style={{width:64,height:64,borderRadius:16,background:`${T.purple}12`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:36,flexShrink:0}}>{letter.emoji}</div>
            <div style={{textAlign:'right',direction:'rtl'}}>
              <div style={{fontFamily:"'Noto Nastaliq Urdu',serif",fontSize:28,fontWeight:900,color:T.navy,lineHeight:1.2}}>{letter.ex}</div>
              <div style={{fontSize:13,color:T.darkGray,fontWeight:600,marginTop:2}}>{letter.eng}</div>
            </div>
          </div>
        </div>
      </div>
      {isSpeaking&&<SpeakingNotice/>}
      <div style={{background:T.white,borderRadius:20,padding:'14px 16px',display:'flex',flexDirection:'column',gap:10}}>
        <div style={{display:'flex',alignItems:'center',gap:12}}>
          <ProfessorAvatar mood={score===null?(isSpeaking?'speaking':'neutral'):score>=80?'praise':score>=50?'happy':'sad'} size={64} speaking={isSpeaking}/>
          <div style={{flex:1}}>
            {score!==null&&<ScoreDisplay score={score}/>}
            {listening&&<Waveform active color={T.purple}/>}
            {!score&&!listening&&<div style={{fontSize:13,color:T.darkGray,...UR}}>{avatarSpoken?'مائک بٹن دبائیں اور حرف ادا کریں':'استاد جی کو سنیں...'}</div>}
          </div>
        </div>
        <div style={{display:'flex',gap:8}}>
          <Btn onClick={()=>speakL(letter)} color={T.teal} sm emoji="🔊">سنیں</Btn>
          <Btn onClick={handleListen} color={T.orange} sm emoji="🎤" full disabled={!avatarSpoken||listening||isSpeaking}>{listening?'سن رہے ہیں...':'بولیں'}</Btn>
        </div>
      </div>
      <div style={{display:'flex',gap:10}}>
        <Btn onClick={()=>setIdx(i=>Math.max(0,i-1))} disabled={idx===0} color={T.midGray} outline sm>پچھلا</Btn>
        <Btn onClick={()=>idx<FULL_ALPHABET.length-1?setIdx(i=>i+1):onComplete({stars:3,moduleId:'haroof'})} color={T.purple} full sm>{idx===FULL_ALPHABET.length-1?'مکمل':'اگلا'}</Btn>
      </div>
    </>}
  </div>;
}

// -- LAFZ --
const CATS=['سب','جانور','کھانا','فطرت','چیزیں','جسم'];
function LafzScreen({onComplete}){
  const[cat,setCat]=useState('سب');
  const[idx,setIdx]=useState(0);
  const[score,setScore]=useState(null);
  const[listening,setListening]=useState(false);
  const[avatarSpoken,setAS]=useState(false);
  const[phonemeResult,setPR]=useState(null);
  const filtered=cat==='سب'?WORDS:WORDS.filter(w=>w.cat===cat);
  const word=filtered[Math.min(idx,filtered.length-1)];
  const{speak,stop,isSpeaking}=useTTS();
  const{listen}=useSpeechRecognition();
  const speakW=useCallback((w)=>{setAS(false);speak(`${w.u}۔`,()=>setAS(true));},[speak]);
  useEffect(()=>{setScore(null);setPR(null);setAS(false);const t=setTimeout(()=>speakW(word),400);return()=>{clearTimeout(t);stop();};},[word]);
  const handleListen=()=>{
    if(!avatarSpoken||isSpeaking)return;
    setListening(true);setScore(null);setPR(null);
    listen(word.target,(raw,conf,tr)=>{setListening(false);const s=raw!==null?raw:scorePronunciation(tr,word.target,conf);setScore(s);setPR(scorePhonemes(word.phonemes,s));speak(s>=80?'شاباش!':s>=50?'اچھا ہے!':'دوبارہ کوشش کریں۔',null);});
  };
  const lc=word.level==='easy'?T.greenDark:word.level==='medium'?T.orange:T.red;
  return <div style={{flex:1,overflowY:'auto',background:T.screenBg,display:'flex',flexDirection:'column',padding:16,gap:12}}>
    <div style={{background:`${T.teal}20`,borderRadius:14,padding:'10px 14px',fontSize:13,color:T.teal,...UR}}>اردو الفاظ سیکھیں اور صحیح تلفظ کریں</div>
    <div style={{display:'flex',gap:6,overflowX:'auto',paddingBottom:2}}>
      {CATS.map(c=><button key={c} onClick={()=>{setCat(c);setIdx(0);}} style={{padding:'6px 14px',borderRadius:20,border:`1.5px solid ${cat===c?T.teal:T.lightGray}`,background:cat===c?T.teal:T.white,color:cat===c?T.white:T.darkGray,fontFamily:"'Noto Nastaliq Urdu',serif",fontSize:13,fontWeight:700,cursor:'pointer',whiteSpace:'nowrap'}}>{c}</button>)}
    </div>
    <div style={{background:T.white,borderRadius:24,overflow:'hidden',boxShadow:`0 4px 20px ${T.shadow}`}}>
      <div style={{height:8,background:`linear-gradient(90deg,${T.teal},${T.tealLight})`}}/>
      <div style={{padding:'20px 20px 22px',display:'flex',flexDirection:'column',alignItems:'center',gap:0}}>
        <div style={{width:88,height:88,borderRadius:24,background:`${T.teal}14`,display:'flex',alignItems:'center',justifyContent:'center',fontSize:52,marginBottom:14,flexShrink:0}}>{word.emoji}</div>
        <div style={{fontFamily:"'Noto Nastaliq Urdu',serif",fontSize:48,fontWeight:900,color:T.teal,direction:'rtl',lineHeight:1.3,marginBottom:6}}>{word.u}</div>
        <div style={{fontSize:16,fontWeight:600,color:T.darkGray,marginBottom:12}}>{word.eng}</div>
        <div style={{background:`${lc}18`,borderRadius:20,padding:'3px 12px',fontSize:11,fontWeight:700,color:lc,marginBottom:14}}>{word.level}</div>
        <div style={{width:'100%',height:1,background:T.lightGray,marginBottom:14}}/>
        <div style={{display:'flex',justifyContent:'center',gap:6,direction:'rtl',flexWrap:'wrap'}}>
          {word.phonemes.map((ph,i)=><span key={i} style={{padding:'5px 12px',borderRadius:10,background:phonemeResult?(phonemeResult[i]?`${T.green}33`:`${T.red}22`):`${T.teal}18`,border:`1.5px solid ${phonemeResult?(phonemeResult[i]?T.green:T.red):T.teal}`,fontSize:13,fontWeight:700,color:T.navy}}>{ph}</span>)}
        </div>
      </div>
    </div>
    {isSpeaking&&<SpeakingNotice/>}
    <div style={{background:T.white,borderRadius:20,padding:'14px 16px',display:'flex',flexDirection:'column',gap:10}}>
      <div style={{display:'flex',alignItems:'center',gap:12}}>
        <ProfessorAvatar mood={score===null?(isSpeaking?'speaking':'neutral'):score>=80?'praise':score>=50?'happy':'sad'} size={60} speaking={isSpeaking}/>
        <div style={{flex:1}}>
          {score!==null&&<ScoreDisplay score={score}/>}
          {listening&&<Waveform active color={T.teal}/>}
          {!score&&!listening&&<div style={{fontSize:13,color:T.darkGray,...UR}}>{avatarSpoken?'لفظ بولیں':'استاد جی کو سنیں...'}</div>}
        </div>
      </div>
      <div style={{display:'flex',gap:8}}>
        <Btn onClick={()=>speakW(word)} color={T.teal} sm emoji="🔊">سنیں</Btn>
        <Btn onClick={handleListen} color={T.orange} sm emoji="🎤" full disabled={!avatarSpoken||listening||isSpeaking}>{listening?'سن رہے ہیں...':'بولیں'}</Btn>
      </div>
    </div>
    <div style={{display:'flex',gap:10}}>
      <Btn onClick={()=>setIdx(i=>Math.max(0,i-1))} disabled={idx===0} color={T.midGray} outline sm>پچھلا</Btn>
      <Btn onClick={()=>idx<filtered.length-1?setIdx(i=>i+1):onComplete({stars:3,moduleId:'lafz'})} color={T.teal} full sm>{idx===filtered.length-1?'مکمل':'اگلا'}</Btn>
    </div>
  </div>;
}

// -- JUMLAY --
function JumlayScreen({onComplete}){
  const[idx,setIdx]=useState(0);
  const[score,setScore]=useState(null);
  const[listening,setListening]=useState(false);
  const[avatarSpoken,setAS]=useState(false);
  const[activeWord,setAW]=useState(-1);
  const timersRef=useRef([]);
  const sentence=SENTENCES[idx];
  const words=sentence.u.split(' ');
  const{speak,stop,isSpeaking}=useTTS();
  const{listen}=useSpeechRecognition();
  const clearT=()=>{timersRef.current.forEach(clearTimeout);timersRef.current=[];};
  const speakS=useCallback(()=>{
    clearT();setAS(false);setAW(-1);
    words.forEach((_,i)=>{const t=setTimeout(()=>setAW(i),i*700);timersRef.current.push(t);});
    const e=setTimeout(()=>setAW(-1),words.length*700+300);timersRef.current.push(e);
    speak(sentence.u,()=>setAS(true));
  },[sentence,speak]);
  useEffect(()=>{setScore(null);setAS(false);const t=setTimeout(speakS,500);return()=>{clearTimeout(t);clearT();stop();};},[idx]);
  const handleListen=()=>{
    if(!avatarSpoken||isSpeaking)return;
    setListening(true);setScore(null);
    listen(sentence.audio,(raw,conf,tr)=>{setListening(false);const s=raw!==null?raw:scorePronunciation(tr,sentence.audio,conf);setScore(s);speak(s>=80?'شاباش! جملہ بالکل صحیح ہے!':s>=50?'اچھا ہے!':'دوبارہ کوشش کریں۔',null);});
  };
  return <div style={{flex:1,overflowY:'auto',background:T.screenBg,display:'flex',flexDirection:'column',padding:16,gap:12}}>
    <div style={{background:`${T.orange}18`,borderRadius:14,padding:'10px 14px',fontSize:13,color:T.orange,...UR}}>اردو جملے -- صرف اردو رسم الخط، رومن اردو نہیں</div>
    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center'}}>
      <span style={{fontSize:12,color:T.darkGray,fontWeight:600}}>{idx+1} / {SENTENCES.length}</span>
      <div style={{display:'flex',gap:4}}>{SENTENCES.map((_,i)=><div key={i} style={{width:8,height:8,borderRadius:'50%',background:i===idx?T.orange:i<idx?`${T.orange}66`:T.lightGray}}/>)}</div>
    </div>
    <div style={{background:T.white,borderRadius:24,overflow:'hidden',boxShadow:`0 4px 20px ${T.shadow}`}}>
      <div style={{height:6,background:`linear-gradient(90deg,${T.orange},${T.orangeLight})`}}/>
      <div style={{padding:'24px 20px'}}>
        <div style={{direction:'rtl',display:'flex',flexWrap:'wrap',gap:6,justifyContent:'flex-start',marginBottom:16}}>
          {words.map((w,i)=><span key={i} style={{fontFamily:"'Noto Nastaliq Urdu',serif",fontSize:26,fontWeight:800,color:activeWord===i?T.orange:T.navy,background:activeWord===i?`${T.orange}22`:'transparent',borderRadius:8,padding:'2px 6px',transition:'all 0.2s'}}>{w}</span>)}
        </div>
        <div style={{fontSize:14,color:T.darkGray,fontStyle:'italic',textAlign:'center',borderTop:`1px solid ${T.lightGray}`,paddingTop:12}}>{sentence.eng}</div>
      </div>
    </div>
    {isSpeaking&&<SpeakingNotice/>}
    <div style={{background:T.white,borderRadius:20,padding:'16px',display:'flex',flexDirection:'column',gap:12}}>
      <div style={{display:'flex',alignItems:'center',gap:12}}>
        <ProfessorAvatar mood={score===null?(isSpeaking?'speaking':'excited'):score>=80?'praise':score>=50?'happy':'sad'} size={64} speaking={isSpeaking}/>
        <div style={{flex:1}}>
          {score!==null&&<ScoreDisplay score={score}/>}
          {listening&&<Waveform active color={T.orange}/>}
          {!score&&!listening&&<div style={{fontSize:13,color:T.darkGray,...UR}}>{avatarSpoken?'اب آپ جملہ بولیں':'استاد جی جملہ پڑھ رہے ہیں...'}</div>}
        </div>
      </div>
      <div style={{display:'flex',gap:8}}>
        <Btn onClick={speakS} color={T.orange} sm emoji="🔊">سنیں</Btn>
        <Btn onClick={handleListen} color={T.purple} sm emoji="🎤" full disabled={!avatarSpoken||listening||isSpeaking}>{listening?'سن رہے ہیں...':'بولیں'}</Btn>
      </div>
    </div>
    <div style={{display:'flex',gap:10}}>
      <Btn onClick={()=>setIdx(i=>Math.max(0,i-1))} disabled={idx===0} color={T.midGray} outline sm>پچھلا</Btn>
      <Btn onClick={()=>idx<SENTENCES.length-1?setIdx(i=>i+1):onComplete({stars:3,moduleId:'jumlay'})} color={T.orange} full sm>{idx===SENTENCES.length-1?'مکمل':'اگلا'}</Btn>
    </div>
  </div>;
}

// -- RANG --
function RangScreen({onComplete}){
  const[idx,setIdx]=useState(0);
  const[score,setScore]=useState(null);
  const[listening,setListening]=useState(false);
  const[avatarSpoken,setAS]=useState(false);
  const color=COLORS[idx];
  const{speak,stop,isSpeaking}=useTTS();
  const{listen}=useSpeechRecognition();
  const speakC=useCallback((c)=>{setAS(false);speak(`${c.u}۔`,()=>setAS(true));},[speak]);
  useEffect(()=>{setScore(null);setAS(false);const t=setTimeout(()=>speakC(color),400);return()=>{clearTimeout(t);stop();};},[idx]);
  const handleListen=()=>{
    if(!avatarSpoken||isSpeaking)return;
    setListening(true);setScore(null);
    listen(color.r,(raw,conf,tr)=>{setListening(false);const s=raw!==null?raw:scorePronunciation(tr,color.r,conf);setScore(s);speak(s>=80?'شاباش! رنگ صحیح بولا!':s>=50?'اچھا ہے!':'دوبارہ کوشش کریں۔',null);});
  };
  return <div style={{flex:1,overflowY:'auto',background:T.screenBg,display:'flex',flexDirection:'column',padding:16,gap:12}}>
    <div style={{background:`${T.pink}18`,borderRadius:14,padding:'10px 14px',fontSize:13,color:T.pink,...UR}}>اردو میں رنگوں کے نام سیکھیں</div>
    <div style={{display:'flex',gap:4,flexWrap:'wrap',justifyContent:'center'}}>
      {COLORS.map((c,i)=><button key={i} onClick={()=>setIdx(i)} title={c.eng} style={{width:26,height:26,borderRadius:'50%',background:c.hex,border:`3px solid ${i===idx?T.navy:'transparent'}`,cursor:'pointer',padding:0,transform:i===idx?'scale(1.3)':'scale(1)',transition:'transform 0.15s'}}/>)}
    </div>
    <div style={{background:T.white,borderRadius:24,overflow:'hidden',boxShadow:`0 4px 20px ${T.shadow}`}}>
      <div style={{height:140,background:color.hex,display:'flex',alignItems:'center',justifyContent:'center',position:'relative'}}>
        <span style={{fontSize:60}}>{color.emoji}</span>
        <div style={{position:'absolute',top:10,right:12,background:'rgba(0,0,0,0.35)',color:'white',borderRadius:20,padding:'2px 10px',fontSize:11,fontWeight:700}}>{idx+1}/{COLORS.length}</div>
      </div>
      <div style={{padding:'20px',textAlign:'center',display:'flex',flexDirection:'column',alignItems:'center',gap:6}}>
        <div style={{fontFamily:"'Noto Nastaliq Urdu',serif",fontSize:48,fontWeight:900,direction:'rtl',color:color.hex,lineHeight:1.25}}>{color.u}</div>
        <div style={{fontSize:18,fontWeight:800,color:T.navy}}>{color.r}</div>
        <div style={{fontSize:14,color:T.darkGray}}>{color.eng}</div>
        <div style={{marginTop:8,background:color.light,border:`3px solid ${color.hex}`,borderRadius:14,padding:'6px 24px',fontSize:13,fontWeight:700,color:color.hex}}>{color.eng} shade</div>
      </div>
    </div>
    {isSpeaking&&<SpeakingNotice/>}
    <div style={{background:T.white,borderRadius:20,padding:'14px 16px',display:'flex',flexDirection:'column',gap:10}}>
      <div style={{display:'flex',alignItems:'center',gap:12}}>
        <ProfessorAvatar mood={score===null?(isSpeaking?'speaking':'neutral'):score>=80?'praise':score>=50?'happy':'sad'} size={60} speaking={isSpeaking}/>
        <div style={{flex:1}}>
          {score!==null&&<ScoreDisplay score={score}/>}
          {listening&&<Waveform active color={T.pink}/>}
          {!score&&!listening&&<div style={{fontSize:13,color:T.darkGray,...UR}}>{avatarSpoken?'رنگ کا نام بولیں':'استاد جی کو سنیں...'}</div>}
        </div>
      </div>
      <div style={{display:'flex',gap:8}}>
        <Btn onClick={()=>speakC(color)} color={T.pink} sm emoji="🔊">سنیں</Btn>
        <Btn onClick={handleListen} color={T.orange} sm emoji="🎤" full disabled={!avatarSpoken||listening||isSpeaking}>{listening?'سن رہے ہیں...':'بولیں'}</Btn>
      </div>
    </div>
    <div style={{display:'flex',gap:10}}>
      <Btn onClick={()=>setIdx(i=>Math.max(0,i-1))} disabled={idx===0} color={T.midGray} outline sm>پچھلا</Btn>
      <Btn onClick={()=>idx<COLORS.length-1?setIdx(i=>i+1):onComplete({stars:3,moduleId:'rang'})} color={T.pink} full sm>{idx===COLORS.length-1?'مکمل':'اگلا'}</Btn>
    </div>
  </div>;
}

// -- QUIZ --
function QuizScreen({onComplete}){
  const[stage,setStage]=useState('setup');
  const[type,setType]=useState('mcq');
  const[diff,setDiff]=useState('easy');
  const[finalScore,setFinal]=useState(0);
  const QT=[{id:'mcq',label:'حروف کوئز',icon:'ا',desc:'اردو حروف پہچانیں'},{id:'match',label:'تصویر ملاؤ',icon:'🖼️',desc:'تصویر سے لفظ ملائیں'},{id:'fill',label:'خالی جگہ',icon:'✏️',desc:'جملہ مکمل کریں'},{id:'speak',label:'تلفظ ٹیسٹ',icon:'🎤',desc:'لفظ کا تلفظ کریں'}];
  const DF=[{id:'easy',label:'آسان',color:T.green},{id:'medium',label:'درمیانہ',color:T.orange},{id:'hard',label:'مشکل',color:T.red}];
  const handleDone=(s)=>{setFinal(s);setStage('result');onComplete&&onComplete({stars:s>=80?3:s>=50?2:1,moduleId:'quiz'});};
  if(stage==='result')return <div style={{flex:1,display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',padding:'32px 24px',gap:20,position:'relative'}}>
    {finalScore>=80&&<Confetti/>}
    <ProfessorAvatar mood={finalScore>=80?'praise':finalScore>=50?'happy':'sad'} size={100} floating/>
    <div style={{textAlign:'center'}}>
      <div style={{fontSize:56,fontWeight:900,color:finalScore>=80?T.green:finalScore>=50?T.orange:T.red}}>{finalScore}%</div>
      <StarBadge stars={finalScore>=80?3:finalScore>=50?2:1}/>
      <div style={{fontSize:22,fontWeight:900,color:finalScore>=80?T.green:finalScore>=50?T.orange:T.red,...UR,marginTop:10}}>{finalScore>=80?'شاباش! بہت خوب!':finalScore>=50?'اچھا ہے!':'محنت کریں!'}</div>
    </div>
    <Btn onClick={()=>setStage('setup')} color={T.purple} full>دوبارہ کوشش</Btn>
  </div>;
  if(stage==='quiz'){
    if(type==='mcq')  return <MCQQuiz   diff={diff} onDone={handleDone}/>;
    if(type==='match')return <MatchQuiz diff={diff} onDone={handleDone}/>;
    if(type==='fill') return <FillQuiz  diff={diff} onDone={handleDone}/>;
    if(type==='speak')return <SpeakQuiz diff={diff} onDone={handleDone}/>;
  }
  return <div style={{flex:1,overflowY:'auto',padding:16,display:'flex',flexDirection:'column',gap:14}}>
    <div style={{textAlign:'center',marginBottom:4}}>
      <ProfessorAvatar mood="excited" size={80} floating/>
      <div style={{fontSize:20,fontWeight:900,color:T.navy,...UR,marginTop:8}}>کوئز کا انتخاب کریں</div>
    </div>
    <div style={{background:T.white,borderRadius:20,padding:16,display:'flex',flexDirection:'column',gap:10}}>
      <div style={{fontSize:13,fontWeight:700,color:T.darkGray,marginBottom:4}}>کوئز کی قسم</div>
      {QT.map(q=><button key={q.id} onClick={()=>setType(q.id)} style={{display:'flex',alignItems:'center',gap:12,padding:'12px 14px',borderRadius:14,border:`2px solid ${type===q.id?T.purple:T.lightGray}`,background:type===q.id?`${T.purple}12`:T.offWhite,cursor:'pointer',textAlign:'left'}}>
        <span style={{fontSize:22,fontFamily:"'Noto Nastaliq Urdu',serif"}}>{q.icon}</span>
        <div>
          <div style={{fontFamily:"'Noto Nastaliq Urdu',serif",fontSize:15,fontWeight:800,color:type===q.id?T.purple:T.navy,direction:'rtl'}}>{q.label}</div>
          <div style={{fontFamily:"'Noto Nastaliq Urdu',serif",fontSize:11,color:T.darkGray,direction:'rtl'}}>{q.desc}</div>
        </div>
        {type===q.id&&<span style={{marginLeft:'auto',color:T.purple,fontWeight:900}}>✓</span>}
      </button>)}
    </div>
    <div style={{background:T.white,borderRadius:20,padding:16}}>
      <div style={{fontFamily:"'Noto Nastaliq Urdu',serif",fontSize:13,fontWeight:700,color:T.darkGray,direction:'rtl',marginBottom:10}}>مشکل کی سطح</div>
      <div style={{display:'flex',gap:8}}>
        {DF.map(d=><button key={d.id} onClick={()=>setDiff(d.id)} style={{flex:1,padding:'10px 6px',borderRadius:12,border:`2px solid ${diff===d.id?d.color:T.lightGray}`,background:diff===d.id?`${d.color}18`:T.offWhite,cursor:'pointer',fontFamily:"'Noto Nastaliq Urdu',serif",fontSize:13,fontWeight:800,color:diff===d.id?d.color:T.darkGray}}>{d.label}</button>)}
      </div>
    </div>
    <Btn onClick={()=>setStage('quiz')} color={T.purple} full emoji="🚀">کوئز شروع کریں</Btn>
  </div>;
}

function QuizShell({current,total,score,color,children}){
  return <div style={{flex:1,display:'flex',flexDirection:'column',overflow:'hidden'}}>
    <div style={{padding:'12px 16px',background:T.white,borderBottom:`1px solid ${T.lightGray}`}}>
      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:6}}>
        <span style={{fontSize:12,fontWeight:700,color:T.darkGray}}>{current}/{total}</span>
        <span style={{fontSize:13,fontWeight:800,color}}>اسکور: {score}%</span>
      </div>
      <PBar value={current} max={total} color={color} height={6}/>
    </div>
    <div style={{flex:1,overflowY:'auto',padding:16,display:'flex',flexDirection:'column',gap:12}}>{children}</div>
  </div>;
}

function MCQQuiz({diff,onDone}){
  const pool=useMemo(()=>{const n=diff==='easy'?5:diff==='medium'?8:12;return shuffle(FULL_ALPHABET).slice(0,n).map(item=>({item,opts:shuffle([item,...shuffle(FULL_ALPHABET.filter(x=>x.u!==item.u)).slice(0,3)])}));},[diff]);
  const[qIdx,setQ]=useState(0);const[sel,setSel]=useState(null);const[ans,setAns]=useState([]);
  const{speak,isSpeaking}=useTTS();const q=pool[qIdx];
  useEffect(()=>{speak(`${q.item.u}۔ ${q.item.ex}۔`,null);},[qIdx]);
  const pick=(opt)=>{if(sel)return;setSel(opt.u);const ok=opt.u===q.item.u;setAns(a=>[...a,ok]);speak(ok?'شاباش!':`غلط! صحیح جواب ${q.item.u} ہے۔`,null);};
  const next=()=>{setSel(null);if(qIdx<pool.length-1)setQ(i=>i+1);else onDone(Math.round(([...ans,ans.length>0].filter(Boolean).length/pool.length)*100));};
  const rs=pool.length>0?Math.round((ans.filter(Boolean).length/pool.length)*100):0;
  return <QuizShell current={qIdx+1} total={pool.length} score={rs} color={T.purple}>
    {isSpeaking&&<SpeakingNotice/>}
    <div style={{background:T.white,borderRadius:24,padding:'24px 20px',textAlign:'center',boxShadow:`0 4px 20px ${T.shadow}`}}>
      <div style={{fontSize:56,marginBottom:12}}>{q.item.emoji}</div>
      <div style={{fontFamily:"'Noto Nastaliq Urdu',serif",fontSize:22,fontWeight:800,color:T.navy,direction:'rtl',marginBottom:4}}>{q.item.ex}</div>
      <div style={{fontSize:13,color:T.darkGray,...UR}}>کونسا حرف ہے؟</div>
    </div>
    <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
      {q.opts.map(opt=>{const picked=sel===opt.u,ok=opt.u===q.item.u;let bg=T.white,border=T.lightGray,col=T.navy;if(sel){if(ok){bg=`${T.green}22`;border=T.green;col=T.greenDark;}else if(picked){bg=`${T.red}18`;border=T.red;col=T.red;}}return <button key={opt.u} onClick={()=>pick(opt)} style={{padding:'18px 8px',borderRadius:16,border:`2px solid ${border}`,background:bg,cursor:'pointer',transition:'all 0.2s'}}>
        <div style={{fontFamily:"'Noto Nastaliq Urdu',serif",fontSize:36,fontWeight:900,color:col}}>{opt.u}</div>
        <div style={{fontSize:11,color:T.darkGray,marginTop:4}}>{opt.r}</div>
        {sel&&ok&&<div style={{fontSize:16}}>✅</div>}{sel&&picked&&!ok&&<div style={{fontSize:16}}>❌</div>}
      </button>;})}
    </div>
    {sel&&<Btn onClick={next} color={T.purple} full>{qIdx<pool.length-1?'اگلا سوال':'مکمل'}</Btn>}
  </QuizShell>;
}

function MatchQuiz({diff,onDone}){
  const pool=useMemo(()=>shuffle(MATCH_DATA).slice(0,diff==='easy'?5:diff==='medium'?8:10),[diff]);
  const[qIdx,setQ]=useState(0);const[sel,setSel]=useState(null);const[ans,setAns]=useState([]);
  const{speak,isSpeaking}=useTTS();const q=pool[qIdx];
  useEffect(()=>{speak('صحیح اردو لفظ چنیں۔',null);},[qIdx]);
  const pick=(opt)=>{if(sel)return;setSel(opt);const ok=opt===q.answer;setAns(a=>[...a,ok]);speak(ok?'شاباش!':`غلط! صحیح جواب ${q.answer} ہے۔`,null);};
  const next=()=>{setSel(null);if(qIdx<pool.length-1)setQ(i=>i+1);else onDone(Math.round((ans.filter(Boolean).length/pool.length)*100));};
  const rs=pool.length>0?Math.round((ans.filter(Boolean).length/pool.length)*100):0;
  return <QuizShell current={qIdx+1} total={pool.length} score={rs} color={T.teal}>
    {isSpeaking&&<SpeakingNotice/>}
    <div style={{background:T.white,borderRadius:24,padding:'28px 20px',textAlign:'center',boxShadow:`0 4px 20px ${T.shadow}`}}>
      <div style={{fontSize:80}}>{q.emoji}</div>
      <div style={{fontSize:13,color:T.darkGray,marginTop:12,...UR}}>صحیح اردو لفظ چنیں</div>
    </div>
    <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
      {q.opts.map(opt=>{const picked=sel===opt,ok=opt===q.answer;let bg=T.white,border=T.lightGray,col=T.navy;if(sel){if(ok){bg=`${T.green}22`;border=T.green;col=T.greenDark;}else if(picked){bg=`${T.red}18`;border=T.red;col=T.red;}}return <button key={opt} onClick={()=>pick(opt)} style={{padding:'16px 10px',borderRadius:16,border:`2px solid ${border}`,background:bg,cursor:'pointer',transition:'all 0.2s'}}>
        <div style={{fontFamily:"'Noto Nastaliq Urdu',serif",fontSize:22,fontWeight:900,color:col,direction:'rtl'}}>{opt}</div>
        {sel&&ok&&<div style={{fontSize:14,marginTop:4}}>✅</div>}{sel&&picked&&!ok&&<div style={{fontSize:14,marginTop:4}}>❌</div>}
      </button>;})}
    </div>
    {sel&&<Btn onClick={next} color={T.teal} full>{qIdx<pool.length-1?'اگلا سوال':'مکمل'}</Btn>}
  </QuizShell>;
}

function FillQuiz({diff,onDone}){
  const pool=useMemo(()=>shuffle(FILL_BLANKS).slice(0,diff==='easy'?4:diff==='medium'?5:6),[diff]);
  const[qIdx,setQ]=useState(0);const[sel,setSel]=useState(null);const[ans,setAns]=useState([]);
  const{speak,isSpeaking}=useTTS();const q=pool[qIdx];
  useEffect(()=>{speak(q.sentence.split('___')[0]+'۔',null);},[qIdx]);
  const pick=(opt)=>{if(sel)return;setSel(opt);const ok=opt===q.answer;setAns(a=>[...a,ok]);speak(ok?`شاباش! ${q.sentence.replace('___',opt)}`:`غلط! صحیح جواب ${q.answer} ہے۔`,null);};
  const next=()=>{setSel(null);if(qIdx<pool.length-1)setQ(i=>i+1);else onDone(Math.round((ans.filter(Boolean).length/pool.length)*100));};
  const rs=pool.length>0?Math.round((ans.filter(Boolean).length/pool.length)*100):0;
  return <QuizShell current={qIdx+1} total={pool.length} score={rs} color={T.orange}>
    {isSpeaking&&<SpeakingNotice/>}
    <div style={{background:T.white,borderRadius:24,padding:'24px 20px',boxShadow:`0 4px 20px ${T.shadow}`,textAlign:'center'}}>
      <div style={{fontFamily:"'Noto Nastaliq Urdu',serif",fontSize:24,fontWeight:800,color:T.navy,direction:'rtl',marginBottom:10}}>
        {q.sentence.split('___').map((part,i)=><React.Fragment key={i}>{part}{i===0&&<span style={{display:'inline-block',borderBottom:`3px solid ${T.orange}`,minWidth:60,marginInline:6,color:sel?T.orange:'transparent'}}>{sel||'___'}</span>}</React.Fragment>)}
      </div>
      <div style={{fontSize:13,color:T.darkGray,fontStyle:'italic'}}>{q.eng}</div>
    </div>
    <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10}}>
      {q.opts.map(opt=>{const picked=sel===opt,ok=opt===q.answer;let bg=T.white,border=T.lightGray,col=T.navy;if(sel){if(ok){bg=`${T.green}22`;border=T.green;col=T.greenDark;}else if(picked){bg=`${T.red}18`;border=T.red;col=T.red;}}return <button key={opt} onClick={()=>pick(opt)} style={{padding:'16px 10px',borderRadius:16,border:`2px solid ${border}`,background:bg,cursor:'pointer'}}>
        <div style={{fontFamily:"'Noto Nastaliq Urdu',serif",fontSize:20,fontWeight:900,color:col,direction:'rtl'}}>{opt}</div>
        {sel&&ok&&<div style={{fontSize:14,marginTop:4}}>✅</div>}{sel&&picked&&!ok&&<div style={{fontSize:14,marginTop:4}}>❌</div>}
      </button>;})}
    </div>
    {sel&&<Btn onClick={next} color={T.orange} full>{qIdx<pool.length-1?'اگلا سوال':'مکمل'}</Btn>}
  </QuizShell>;
}

function SpeakQuiz({diff,onDone}){
  const pool=useMemo(()=>{const f=diff==='easy'?WORDS.filter(w=>w.level==='easy'):diff==='medium'?WORDS.filter(w=>w.level!=='hard'):WORDS;return shuffle(f).slice(0,diff==='easy'?5:diff==='medium'?7:10);},[diff]);
  const[qIdx,setQ]=useState(0);const[score,setScore]=useState(null);const[listening,setL]=useState(false);const[avatarSpoken,setAS]=useState(false);const[scores,setScores]=useState([]);
  const word=pool[qIdx];
  const{speak,stop,isSpeaking}=useTTS();const{listen}=useSpeechRecognition();
  const speakW=useCallback((w)=>{setAS(false);speak(`${w.u}۔`,()=>setAS(true));},[speak]);
  useEffect(()=>{setScore(null);setAS(false);const t=setTimeout(()=>speakW(word),300);return()=>{clearTimeout(t);stop();};},[qIdx]);
  const handleL=()=>{if(!avatarSpoken||isSpeaking)return;setL(true);setScore(null);listen(word.target,(raw,conf,tr)=>{setL(false);const s=raw!==null?raw:scorePronunciation(tr,word.target,conf);setScore(s);setScores(sc=>[...sc,s]);speak(s>=80?'شاباش! بہت اچھا تلفظ!':s>=50?'اچھا ہے!':'دوبارہ کوشش کریں۔',null);});};
  const handleNext=()=>{setScore(null);if(qIdx<pool.length-1)setQ(i=>i+1);else{const avg=scores.length?Math.round(scores.reduce((a,b)=>a+b,0)/scores.length):0;onDone(avg);}};
  const rs=scores.length?Math.round(scores.reduce((a,b)=>a+b,0)/scores.length):0;
  return <QuizShell current={qIdx+1} total={pool.length} score={rs} color={T.pink}>
    {isSpeaking&&<SpeakingNotice/>}
    <div style={{background:T.white,borderRadius:24,padding:'24px 20px',textAlign:'center',boxShadow:`0 4px 20px ${T.shadow}`}}>
      <div style={{fontSize:64,marginBottom:14}}>{word.emoji}</div>
      <div style={{fontFamily:"'Noto Nastaliq Urdu',serif",fontSize:44,fontWeight:900,color:T.pink,direction:'rtl',marginBottom:6}}>{word.u}</div>
      <div style={{fontSize:14,color:T.darkGray}}>{word.eng}</div>
    </div>
    <div style={{background:T.white,borderRadius:20,padding:'14px 16px',display:'flex',flexDirection:'column',gap:10}}>
      <div style={{display:'flex',alignItems:'center',gap:12}}>
        <ProfessorAvatar mood={score===null?(isSpeaking?'speaking':'neutral'):score>=80?'praise':score>=50?'happy':'sad'} size={58} speaking={isSpeaking}/>
        <div style={{flex:1}}>
          {score!==null&&<div style={{textAlign:'center'}}><div style={{fontSize:28,fontWeight:900,color:score>=80?T.green:score>=50?T.orange:T.red}}>{score}%</div><div style={{fontSize:16,...UR,color:score>=80?T.green:score>=50?T.orange:T.red}}>{score>=80?'شاباش!':score>=50?'اچھا ہے!':'محنت کریں!'}</div></div>}
          {listening&&<Waveform active color={T.pink}/>}
          {!score&&!listening&&<div style={{fontSize:13,color:T.darkGray,...UR}}>{avatarSpoken?'لفظ بولیں':'استاد جی کو سنیں...'}</div>}
        </div>
      </div>
      <div style={{display:'flex',gap:8}}>
        <Btn onClick={()=>speakW(word)} color={T.teal} sm emoji="🔊">سنیں</Btn>
        <Btn onClick={handleL} color={T.orange} sm emoji="🎤" full disabled={!avatarSpoken||listening||isSpeaking}>{listening?'سن رہے ہیں...':'بولیں'}</Btn>
      </div>
      {score!==null&&<div style={{display:'flex',gap:8}}>
        {score<50&&<Btn onClick={()=>{setScore(null);speakW(word);}} color={T.orange} outline sm>دوبارہ</Btn>}
        <Btn onClick={handleNext} color={T.pink} full sm>{qIdx<pool.length-1?'اگلا':'مکمل'}</Btn>
      </div>}
    </div>
  </QuizShell>;
}

// ============================================================
// APP ROOT
// ============================================================
const BADGES={haroof:{icon:'🔤',label:'حروف ماسٹر',desc:'آپ نے حروف تہجی مکمل کی!'},lafz:{icon:'📝',label:'الفاظ ماسٹر',desc:'آپ نے الفاظ مکمل کیے!'},jumlay:{icon:'💬',label:'جملے ماسٹر',desc:'آپ نے جملے مکمل کیے!'},rang:{icon:'🎨',label:'رنگ ماسٹر',desc:'آپ نے رنگ مکمل کیے!'},quiz:{icon:'🏆',label:'کوئز چیمپیئن',desc:'آپ نے کوئز مکمل کیا!'}};

export default function App(){
  const[stage,setStage]=useState('splash');
  const[screen,setScreen]=useState('home');
  const[user,setUser]=useState(null);
  const[completedMap,setCompleted]=useState({});
  const[starsMap,setStars]=useState({});
  const[badge,setBadge]=useState(null);
  const clock=useLiveClock();
  const hh=String(clock.getHours()).padStart(2,'0');
  const mm=String(clock.getMinutes()).padStart(2,'0');
  const handleComplete=useCallback(({stars=3,moduleId})=>{
    setCompleted(m=>({...m,[moduleId]:true}));
    setStars(m=>({...m,[moduleId]:Math.max(m[moduleId]||0,stars)}));
    if(BADGES[moduleId])setBadge(BADGES[moduleId]);
    setScreen('home');
  },[]);
  return <>
    <style>{`
      @import url('https://fonts.googleapis.com/css2?family=Noto+Nastaliq+Urdu:wght@400;700;900&display=swap');
      *{box-sizing:border-box;margin:0;padding:0;}
      body{background:#1a1a2e;display:flex;justify-content:center;align-items:center;min-height:100vh;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;}
      button{font-family:inherit;}input{font-family:inherit;}
      @keyframes tutorFloat{0%,100%{transform:translateY(0)}50%{transform:translateY(-8px)}}
      @keyframes confettiFall{0%{transform:translateY(-20px) rotate(0);opacity:1}100%{transform:translateY(900px) rotate(360deg);opacity:0}}
      @keyframes badgePop{0%{transform:scale(0.6);opacity:0}70%{transform:scale(1.08)}100%{transform:scale(1);opacity:1}}
      @keyframes pulse{0%,100%{opacity:0.4;transform:scale(1)}50%{opacity:1;transform:scale(1.3)}}
    `}</style>
    <div style={{width:390,height:780,background:T.white,borderRadius:44,overflow:'hidden',boxShadow:'0 24px 80px rgba(0,0,0,0.5)',display:'flex',flexDirection:'column',position:'relative'}}>
      {stage==='app'&&<div style={{height:36,background:`linear-gradient(90deg,${T.purple} 0%,${T.navyLight} 100%)`,display:'flex',alignItems:'center',justifyContent:'space-between',padding:'0 20px',flexShrink:0}}>
        <span style={{color:'rgba(255,255,255,0.85)',fontSize:13,fontWeight:700}}>{hh}:{mm}</span>
        <div style={{display:'flex',gap:4,alignItems:'center'}}>
          {[3,5,7,9].map((h,i)=><div key={i} style={{width:3,height:h,background:`rgba(255,255,255,${0.4+i*0.15})`,borderRadius:2}}/>)}
          <div style={{width:20,height:10,borderRadius:3,border:'1.5px solid rgba(255,255,255,0.7)',marginLeft:4,position:'relative',overflow:'hidden'}}>
            <div style={{width:'70%',height:'100%',background:T.green,borderRadius:2}}/>
          </div>
        </div>
      </div>}
      <div style={{flex:1,display:'flex',flexDirection:'column',overflow:'hidden',position:'relative'}}>
        {stage==='splash'&&<SplashScreen onDone={()=>setStage('setup')}/>}
        {stage==='setup'&&<SetupScreen onDone={(u)=>{setUser(u);setStage('app');}}/>}
        {stage==='app'&&<>
          <div style={{background:`linear-gradient(90deg,${T.purple} 0%,${T.navyLight} 100%)`,padding:'10px 16px',display:'flex',alignItems:'center',justifyContent:'space-between',flexShrink:0}}>
            <div style={{fontFamily:"'Noto Nastaliq Urdu',serif",color:T.white,fontSize:16,fontWeight:800,direction:'rtl'}}>
              {screen==='home'&&'اردو سیکھیں'}{screen==='haroof'&&'حروف تہجی'}{screen==='lafz'&&'الفاظ'}{screen==='jumlay'&&'جملے'}{screen==='rang'&&'رنگ'}{screen==='quiz'&&'کوئز'}
            </div>
            {screen!=='home'&&<button onClick={()=>setScreen('home')} style={{background:'rgba(255,255,255,0.18)',border:'none',borderRadius:10,color:T.white,padding:'4px 10px',fontSize:12,fontWeight:700,cursor:'pointer'}}>Home</button>}
          </div>
          <div style={{flex:1,display:'flex',flexDirection:'column',overflow:'hidden'}}>
            {screen==='home'  &&<HomeScreen   user={user} completedMap={completedMap} starsMap={starsMap} onNavigate={setScreen}/>}
            {screen==='haroof'&&<HaroofScreen onComplete={handleComplete}/>}
            {screen==='lafz'  &&<LafzScreen   onComplete={handleComplete}/>}
            {screen==='jumlay'&&<JumlayScreen onComplete={handleComplete}/>}
            {screen==='rang'  &&<RangScreen   onComplete={handleComplete}/>}
            {screen==='quiz'  &&<QuizScreen   onComplete={handleComplete}/>}
          </div>
          <BottomNav active={screen} onNavigate={setScreen}/>
          {badge&&<BadgePopup badge={badge} onClose={()=>setBadge(null)}/>}
        </>}
      </div>
    </div>
  </>;
}
