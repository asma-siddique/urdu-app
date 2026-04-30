// src/utils.js

/** Levenshtein distance between two strings */
export function levenshtein(a, b) {
  const m = a.length, n = b.length;
  const dp = Array.from({ length: m + 1 }, (_, i) =>
    Array.from({ length: n + 1 }, (_, j) => (i === 0 ? j : j === 0 ? i : 0))
  );
  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      dp[i][j] = a[i-1] === b[j-1]
        ? dp[i-1][j-1]
        : 1 + Math.min(dp[i-1][j-1], dp[i-1][j], dp[i][j-1]);
    }
  }
  return dp[m][n];
}

/**
 * Score a pronunciation attempt.
 * transcript  - what the speech API heard
 * target      - expected Roman/English phonetic string (e.g. "billi")
 * apiConfidence - 0-1 value from the Web Speech API (optional)
 */
export function scorePronunciation(transcript, target, apiConfidence = 0) {
  if (!transcript || transcript.trim() === '') return 5;

  const t = transcript.toLowerCase().trim();
  const g = target.toLowerCase().trim();

  // If the transcript is in Urdu script, we cannot compare it to Roman target
  const isUrduScript = /[\u0600-\u06FF]/.test(t);
  if (isUrduScript) {
    // Cap at 65% -- partial credit only
    const confBonus = Math.round(apiConfidence * 15);
    return Math.min(65, 35 + confBonus);
  }

  // Roman transcript: Levenshtein similarity
  const maxLen = Math.max(t.length, g.length);
  const dist = levenshtein(t, g);
  const similarity = maxLen === 0 ? 1 : Math.max(0, 1 - dist / maxLen);

  const levenScore = Math.round(similarity * 85);   // primary weight 85%
  const confScore  = Math.round(apiConfidence * 15); // confidence bonus 15%
  return Math.min(100, levenScore + confScore);
}

/**
 * Simulate an acoustic pronunciation score (used as fallback when no API).
 * Returns a value in the range 10-50 to reflect that simulation is NOT accurate.
 */
export function simulateAcousticScore(target, onResult) {
  const delay = 1200 + Math.random() * 800;
  setTimeout(() => {
    const score = Math.round(10 + Math.random() * 40); // 10-50%
    onResult(score, 0.2 + Math.random() * 0.3);
  }, delay);
}

/**
 * Per-phoneme scoring based on overall score.
 * Returns an array of booleans -- true = correct phoneme.
 */
export function scorePhonemes(phonemes, overallScore) {
  return phonemes.map(() => Math.random() * 100 < overallScore);
}

/** Trim & capitalise first letter of a name */
export function capitaliseName(name) {
  const n = (name || '').trim();
  if (!n) return '';
  return n.charAt(0).toUpperCase() + n.slice(1);
}

/** Get greeting based on hour */
export function getGreeting(hour) {
  if (hour < 12) return { eng:"Good morning",  urdu:"صبح بخیر",   emoji:"🌅" };
  if (hour < 17) return { eng:"Good afternoon", urdu:"دوپہر بخیر", emoji:"☀️" };
  if (hour < 20) return { eng:"Good evening",   urdu:"شام بخیر",   emoji:"🌇" };
  return           { eng:"Good night",           urdu:"شب بخیر",    emoji:"🌙" };
}