// src/App.jsx
import { useState, useCallback } from 'react';
import { T } from './theme.js';
import { useLiveClock } from './hooks.js';
import { BadgePopup } from './components/UI.jsx';
import BottomNav from './components/BottomNav.jsx';

import SplashScreen  from './screens/SplashScreen.jsx';
import SetupScreen   from './screens/SetupScreen.jsx';
import HomeScreen    from './screens/HomeScreen.jsx';
import HaroofScreen  from './screens/HaroofScreen.jsx';
import LafzScreen    from './screens/LafzScreen.jsx';
import JumlayScreen  from './screens/JumlayScreen.jsx';
import RangScreen    from './screens/RangScreen.jsx';
import QuizScreen    from './screens/QuizScreen.jsx';

const BADGES = {
  haroof: { icon:'🔤', label:'حروف ماسٹر',   desc:'You completed the Alphabet module!' },
  lafz:   { icon:'📝', label:'الفاظ ماسٹر',   desc:'You completed the Words module!'    },
  jumlay: { icon:'💬', label:'جملے ماسٹر',    desc:'You completed the Sentences module!'},
  rang:   { icon:'🎨', label:'رنگ ماسٹر',     desc:'You completed the Colours module!'  },
  quiz:   { icon:'🏆', label:'کوئز چیمپیئن',  desc:'You completed a Quiz!'              },
};

const SCREENS_WITH_NAV = ['home','haroof','lafz','jumlay','rang','quiz'];

export default function App() {
  const [stage, setStage]           = useState('splash'); // splash|setup|app
  const [screen, setScreen]         = useState('home');
  const [user, setUser]             = useState(null);
  const [completedMap, setCompleted] = useState({});
  const [starsMap, setStars]        = useState({});
  const [badge, setBadge]           = useState(null);

  const clock = useLiveClock();
  const hh = String(clock.getHours()).padStart(2,'0');
  const mm = String(clock.getMinutes()).padStart(2,'0');

  const handleSplashDone = () => setStage('setup');

  const handleSetupDone = (userData) => {
    setUser(userData);
    setStage('app');
  };

  const handleComplete = useCallback(({ stars = 3, moduleId }) => {
    setCompleted(m => ({ ...m, [moduleId]: true }));
    setStars(m => ({ ...m, [moduleId]: Math.max(m[moduleId]||0, stars) }));
    if (BADGES[moduleId]) {
      setBadge(BADGES[moduleId]);
    }
    setScreen('home');
  }, []);

  const navigate = useCallback((id) => setScreen(id), []);

  const showNav = SCREENS_WITH_NAV.includes(screen);

  return (
    <>
      {/* Global CSS */}
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Noto+Nastaliq+Urdu:wght@400;700;900&display=swap');

        * { box-sizing:border-box; margin:0; padding:0; }

        body {
          background: #1a1a2e;
          display: flex;
          justify-content: center;
          align-items: center;
          min-height: 100vh;
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        }

        @keyframes tutorFloat {
          0%,100% { transform: translateY(0px); }
          50%      { transform: translateY(-8px); }
        }
        @keyframes tutorBounce {
          0%,100% { transform: scale(1); }
          50%      { transform: scale(1.06); }
        }
        @keyframes bubblePop {
          0%   { transform: scale(0.7); opacity:0; }
          70%  { transform: scale(1.05); }
          100% { transform: scale(1);    opacity:1; }
        }
        @keyframes confettiFall {
          0%   { transform: translateY(-20px) rotate(0deg); opacity:1; }
          100% { transform: translateY(900px) rotate(360deg); opacity:0; }
        }
        @keyframes badgePop {
          0%   { transform: scale(0.6); opacity:0; }
          70%  { transform: scale(1.08); }
          100% { transform: scale(1);    opacity:1; }
        }
        @keyframes waveBar {
          from { transform: scaleY(0.4); }
          to   { transform: scaleY(1.0); }
        }
        @keyframes pulse {
          0%,100% { opacity:0.4; transform: scale(1); }
          50%      { opacity:1;   transform: scale(1.3); }
        }

        button { font-family: inherit; }
        input  { font-family: inherit; }
      `}</style>

      {/* Phone shell */}
      <div style={{
        width:390, height:780,
        background:T.white,
        borderRadius:44,
        overflow:'hidden',
        boxShadow:'0 24px 80px rgba(0,0,0,0.5)',
        display:'flex', flexDirection:'column',
        position:'relative',
      }}>
        {/* Status bar */}
        {stage === 'app' && (
          <div style={{
            height:36,
            background:`linear-gradient(90deg, ${T.purple} 0%, ${T.navyLight} 100%)`,
            display:'flex', alignItems:'center',
            justifyContent:'space-between',
            padding:'0 20px',
            flexShrink:0,
          }}>
            <span style={{ color:'rgba(255,255,255,0.85)', fontSize:13, fontWeight:700 }}>
              {hh}:{mm}
            </span>
            <div style={{ display:'flex', gap:4, alignItems:'center' }}>
              {/* Signal bars */}
              {[3,5,7,9].map((h,i) => (
                <div key={i} style={{
                  width:3, height:h,
                  background:`rgba(255,255,255,${0.4 + i*0.15})`,
                  borderRadius:2,
                }} />
              ))}
              {/* Battery */}
              <div style={{
                width:20, height:10, borderRadius:3,
                border:'1.5px solid rgba(255,255,255,0.7)',
                marginLeft:4, position:'relative', overflow:'visible',
              }}>
                <div style={{
                  width:'70%', height:'100%',
                  background:T.green, borderRadius:2,
                }} />
                <div style={{
                  position:'absolute', right:-4, top:'50%',
                  transform:'translateY(-50%)',
                  width:3, height:5,
                  background:'rgba(255,255,255,0.7)',
                  borderRadius:'0 2px 2px 0',
                }} />
              </div>
            </div>
          </div>
        )}

        {/* Screen content */}
        <div style={{ flex:1, display:'flex', flexDirection:'column', overflow:'hidden', position:'relative' }}>
          {stage === 'splash' && <SplashScreen onDone={handleSplashDone} />}
          {stage === 'setup'  && <SetupScreen  onDone={handleSetupDone} />}

          {stage === 'app' && (
            <>
              {/* Page title bar */}
              <div style={{
                background:`linear-gradient(90deg, ${T.purple} 0%, ${T.navyLight} 100%)`,
                padding:'10px 16px',
                display:'flex', alignItems:'center', justifyContent:'space-between',
                flexShrink:0,
              }}>
                <div style={{
                  fontFamily:"'Noto Nastaliq Urdu', serif",
                  color:T.white, fontSize:16, fontWeight:800,
                  direction:'rtl',
                }}>
                  {screen === 'home'   && 'اردو سیکھیں'}
                  {screen === 'haroof' && 'حروف تہجی'}
                  {screen === 'lafz'   && 'الفاظ'}
                  {screen === 'jumlay' && 'جملے'}
                  {screen === 'rang'   && 'رنگ'}
                  {screen === 'quiz'   && 'کوئز'}
                </div>
                {screen !== 'home' && (
                  <button onClick={() => setScreen('home')} style={{
                    background:'rgba(255,255,255,0.18)',
                    border:'none', borderRadius:10,
                    color:T.white, padding:'4px 10px',
                    fontSize:12, fontWeight:700, cursor:'pointer',
                  }}>Home</button>
                )}
              </div>

              {/* Main screen */}
              <div style={{ flex:1, display:'flex', flexDirection:'column', overflow:'hidden' }}>
                {screen === 'home'   && <HomeScreen   user={user} completedMap={completedMap} starsMap={starsMap} onNavigate={navigate} />}
                {screen === 'haroof' && <HaroofScreen onComplete={handleComplete} />}
                {screen === 'lafz'   && <LafzScreen   onComplete={handleComplete} />}
                {screen === 'jumlay' && <JumlayScreen onComplete={handleComplete} />}
                {screen === 'rang'   && <RangScreen   onComplete={handleComplete} />}
                {screen === 'quiz'   && <QuizScreen   onComplete={handleComplete} />}
              </div>

              {/* Bottom nav */}
              {showNav && <BottomNav active={screen} onNavigate={navigate} />}

              {/* Badge popup */}
              {badge && <BadgePopup badge={badge} onClose={() => setBadge(null)} />}
            </>
          )}
        </div>
      </div>
    </>
  );
}
