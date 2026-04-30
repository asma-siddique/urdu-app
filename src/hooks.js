// src/hooks.js
import { useState, useEffect, useRef, useCallback } from 'react';
import { simulateAcousticScore } from './utils.js';

/** Live clock -- updates every second */
export function useLiveClock() {
  const [now, setNow] = useState(new Date());
  useEffect(() => {
    const id = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(id);
  }, []);
  return now;
}

// ─── Voice loader (voices load async in browsers) ──────────────────────────
let cachedUrduVoice = null;

function findUrduVoice() {
  if (cachedUrduVoice) return cachedUrduVoice;
  const voices = window.speechSynthesis.getVoices();
  // Priority: exact ur-PK > any ur-* > Google हिन्दी (similar script engine)
  const exact   = voices.find(v => v.lang === 'ur-PK');
  const partial = voices.find(v => v.lang.startsWith('ur'));
  cachedUrduVoice = exact || partial || null;
  return cachedUrduVoice;
}

/** Text-to-Speech hook - speaks PURE URDU (ur-PK), no English fallback voice */
export function useTTS() {
  const [isSpeaking, setIsSpeaking] = useState(false);
  const synthRef = useRef(window.speechSynthesis);
  const [voicesReady, setVoicesReady] = useState(false);

  // Wait for voices to populate (async in Chrome)
  useEffect(() => {
    const load = () => { cachedUrduVoice = null; setVoicesReady(true); };
    if (window.speechSynthesis.getVoices().length > 0) {
      load();
    } else {
      window.speechSynthesis.addEventListener('voiceschanged', load);
      return () => window.speechSynthesis.removeEventListener('voiceschanged', load);
    }
  }, []);

  const stop = useCallback(() => {
    synthRef.current.cancel();
    setIsSpeaking(false);
  }, []);

  /**
   * speak(urduText, onEnd)
   * ALWAYS speaks in ur-PK Urdu.
   * If the browser has no Urdu voice the text still plays - most browsers
   * default to a local TTS which will attempt the Unicode Urdu characters.
   */
  const speak = useCallback((urduText, onEnd) => {
    stop();
    if (!urduText) { onEnd && onEnd(); return; }

    const utt = new SpeechSynthesisUtterance(urduText);
    utt.lang  = 'ur-PK';
    utt.rate  = 0.72;   // slower = clearer Urdu
    utt.pitch = 1.05;

    const voice = findUrduVoice();
    if (voice) utt.voice = voice;

    utt.onstart  = () => setIsSpeaking(true);
    utt.onend    = () => { setIsSpeaking(false); onEnd && onEnd(); };
    utt.onerror  = () => { setIsSpeaking(false); onEnd && onEnd(); };

    setIsSpeaking(true);
    synthRef.current.speak(utt);
  }, [stop, voicesReady]); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => () => stop(), [stop]);

  return { speak, stop, isSpeaking };
}

/** Speech Recognition hook */
export function useSpeechRecognition() {
  const SpeechRecognition =
    window.SpeechRecognition || window.webkitSpeechRecognition;
  const supported = !!SpeechRecognition;

  const listen = useCallback((target, onResult) => {
    if (!supported) {
      simulateAcousticScore(target, (score, conf) => onResult(score, conf, ''));
      return;
    }
    const rec = new SpeechRecognition();
    rec.lang = 'ur-PK';
    rec.interimResults = false;
    rec.maxAlternatives = 1;

    rec.onresult = (e) => {
      const res = e.results[0][0];
      onResult(null, res.confidence, res.transcript);
    };
    rec.onerror = () => {
      simulateAcousticScore(target, (score, conf) => onResult(score, conf, ''));
    };
    rec.start();
  }, [supported]);

  return { supported, listen };
}