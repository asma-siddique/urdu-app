// src/hooks/useAdaptiveQuiz.js
// Tracks per-word/letter performance and samples harder items more frequently.
import { useState, useCallback } from 'react';

/**
 * useAdaptiveQuiz(items)
 *
 * items: array of { id, ...anyData }
 *
 * Returns:
 *   nextItem()  - pick next item weighted by weakness
 *   recordResult(id, score) - update weakness score (0-100)
 *   weaknesses  - map of { id: weaknessScore }  (higher = weaker)
 *   profile     - 'beginner' | 'intermediate' | 'advanced'
 */
export function useAdaptiveQuiz(items) {
  // Initial weakness: all equal (50 = unknown)
  const [weaknesses, setWeaknesses] = useState(() =>
    Object.fromEntries(items.map(it => [it.id ?? it.u ?? it.r, 50]))
  );

  const getId = (it) => it.id ?? it.u ?? it.r;

  /** Record a result - shift weakness score based on performance */
  const recordResult = useCallback((id, score) => {
    setWeaknesses(prev => {
      const old = prev[id] ?? 50;
      // Exponential moving average: 70% old + 30% new_weakness
      // weakness = 100 - score  (bad score => high weakness)
      const newWeak = Math.round(0.7 * old + 0.3 * (100 - score));
      return { ...prev, [id]: Math.max(0, Math.min(100, newWeak)) };
    });
  }, []);

  /**
   * nextItem() - weighted random selection.
   * Items with higher weakness score have higher probability of being selected.
   */
  const nextItem = useCallback(() => {
    const weights = items.map(it => {
      const w = weaknesses[getId(it)] ?? 50;
      return Math.max(1, w);  // weight proportional to weakness
    });
    const total = weights.reduce((s, w) => s + w, 0);
    let rand = Math.random() * total;
    for (let i = 0; i < items.length; i++) {
      rand -= weights[i];
      if (rand <= 0) return items[i];
    }
    return items[items.length - 1];
  }, [items, weaknesses]);

  /** Profile student into 3 buckets using mean weakness */
  const meanWeak = Object.values(weaknesses).reduce((s,v)=>s+v,0) /
    (Object.keys(weaknesses).length || 1);

  const profile = meanWeak >= 60 ? 'beginner'
    : meanWeak >= 35 ? 'intermediate'
    : 'advanced';

  /** Top-5 weakest items for targeted review */
  const weakestItems = [...items]
    .sort((a,b) => (weaknesses[getId(b)]??50) - (weaknesses[getId(a)]??50))
    .slice(0, 5);

  return { nextItem, recordResult, weaknesses, profile, weakestItems };
}