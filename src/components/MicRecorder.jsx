// src/components/MicRecorder.jsx
// Full microphone recording UI with real MediaRecorder API.
// Sends blob to /api/assess-pronunciation when a backend URL is configured.
import React, { useState, useRef, useCallback } from 'react';
import { T } from '../theme.js';

const API_BASE = import.meta.env.VITE_API_URL ?? '';   // set in .env: VITE_API_URL=https://your-api.onrender.com

/**
 * Props:
 *   targetUrdu   - Urdu text the user should say
 *   targetRoman  - Roman transliteration for API reference
 *   onResult(score, transcript) - callback with 0-100 score
 *   disabled     - disables the mic button
 */
export default function MicRecorder({ targetUrdu, targetRoman, onResult, disabled = false }) {
  const [state, setState]   = useState('idle'); // idle | recording | processing
  const [volume, setVolume] = useState(0);
  const mediaRef            = useRef(null);
  const chunksRef           = useRef([]);
  const analyserRef         = useRef(null);
  const rafRef              = useRef(null);

  const startRecording = useCallback(async () => {
    if (state !== 'idle' || disabled) return;
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      // Visualise volume
      const ctx  = new AudioContext();
      const src  = ctx.createMediaStreamSource(stream);
      const anal = ctx.createAnalyser();
      anal.fftSize = 256;
      src.connect(anal);
      analyserRef.current = anal;

      const tick = () => {
        const buf = new Uint8Array(anal.frequencyBinCount);
        anal.getByteFrequencyData(buf);
        const avg = buf.reduce((s,v)=>s+v,0)/buf.length;
        setVolume(Math.min(100, Math.round(avg * 2.5)));
        rafRef.current = requestAnimationFrame(tick);
      };
      tick();

      chunksRef.current = [];
      const rec = new MediaRecorder(stream, { mimeType:'audio/webm' });
      rec.ondataavailable = e => { if (e.data.size>0) chunksRef.current.push(e.data); };
      rec.onstop = async () => {
        cancelAnimationFrame(rafRef.current);
        ctx.close();
        setVolume(0);
        setState('processing');
        const blob = new Blob(chunksRef.current, { type:'audio/webm' });
        await sendToAPI(blob);
      };
      rec.start();
      mediaRef.current = rec;
      setState('recording');

      // Auto-stop after 5 seconds
      setTimeout(() => { if (mediaRef.current?.state==='recording') stopRecording(); }, 5000);
    } catch {
      setState('idle');
      onResult && onResult(0, '');
    }
  }, [state, disabled]); // eslint-disable-line

  const stopRecording = useCallback(() => {
    if (mediaRef.current?.state === 'recording') {
      mediaRef.current.stop();
      mediaRef.current.stream.getTracks().forEach(t=>t.stop());
    }
  }, []);

  const sendToAPI = async (blob) => {
    if (!API_BASE) {
      // No backend - simulate
      const score = Math.round(10 + Math.random() * 40);
      setState('idle');
      onResult && onResult(score, '');
      return;
    }
    try {
      const form = new FormData();
      form.append('audio', blob, 'recording.webm');
      form.append('target_roman', targetRoman ?? '');
      form.append('target_urdu', targetUrdu ?? '');
      const res  = await fetch(`${API_BASE}/api/assess-pronunciation`, { method:'POST', body:form });
      const data = await res.json();
      setState('idle');
      onResult && onResult(data.score ?? 0, data.transcript ?? '');
    } catch {
      setState('idle');
      onResult && onResult(0, '');
    }
  };

  const isRecording   = state === 'recording';
  const isProcessing  = state === 'processing';
  const btnColor      = isRecording ? T.red : T.orange;

  // Dynamic bar heights for volume visualiser
  const bars = 7;
  return (
    <div style={{ display:'flex', flexDirection:'column', alignItems:'center', gap:10 }}>
      {/* Volume visualiser */}
      <div style={{ display:'flex', alignItems:'flex-end', gap:3, height:36 }}>
        {Array.from({length:bars},(_,i)=>{
          const h = isRecording
            ? Math.max(4, (volume/100) * (20 + Math.sin(i*1.4)*14) + Math.random()*8)
            : 4;
          return (
            <div key={i} style={{
              width:5, height:h,
              background: isRecording ? T.orange : T.midGray,
              borderRadius:3, transition:'height 0.08s',
            }} />
          );
        })}
      </div>

      {/* Mic button */}
      <button
        onMouseDown={startRecording}
        onTouchStart={startRecording}
        onMouseUp={isRecording ? stopRecording : undefined}
        onTouchEnd={isRecording ? stopRecording : undefined}
        disabled={disabled || isProcessing}
        style={{
          width:64, height:64, borderRadius:'50%',
          background: disabled||isProcessing ? T.lightGray : btnColor,
          border:'none', cursor: disabled||isProcessing ? 'not-allowed' : 'pointer',
          display:'flex', alignItems:'center', justifyContent:'center',
          fontSize:28,
          boxShadow: isRecording ? `0 0 0 8px ${T.red}44` : `0 4px 14px ${btnColor}66`,
          transition:'all 0.2s',
          animation: isRecording ? 'pulse 0.8s ease-in-out infinite' : undefined,
        }}>
        {isProcessing ? '⏳' : isRecording ? '⏹️' : '🎤'}
      </button>

      {/* Status text */}
      <div style={{ fontFamily:"'Noto Nastaliq Urdu',serif", fontSize:12,
        color: isRecording ? T.red : isProcessing ? T.orange : T.darkGray,
        direction:'rtl', fontWeight:600 }}>
        {isProcessing ? 'جانچ ہو رہی ہے...'
          : isRecording ? 'بول رہے ہیں - چھوڑنے پر رکیں'
          : disabled ? 'پہلے استاد جی کو سنیں'
          : 'دبائیں اور بولیں'}
      </div>
    </div>
  );
}
