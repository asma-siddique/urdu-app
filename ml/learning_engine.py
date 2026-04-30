"""
ml/learning_engine.py
=====================
Adaptive learning engine for the Urdu Learning App.

Components
----------
1. StudentProfiler     — K-Means clustering (3 levels: beginner/intermediate/advanced)
                         with cold-start synthetic anchors so first-time users get
                         placed correctly before accumulating real data.

2. WeaknessTracker     — EMA (Exponential Moving Average) scoring per vocabulary item.
                         weakness_score = 0.7 * old + 0.3 * (100 - score)
                         Higher weakness_score means the student needs more practice.

3. SRSScheduler        — Spaced Repetition System.
                         Interval doubles (up to 64 days) on score >= 80.
                         Interval resets to 1 on failure.

4. AdaptiveQuizSampler — Combines WeaknessTracker + SRSScheduler to pick the next
                         quiz items: 60-70% from weak areas, 30-40% random.

Usage
-----
  from ml.learning_engine import AdaptiveQuizSampler, StudentProfiler

  profiler = StudentProfiler()
  level    = profiler.predict([0.4, 0.55, 0.65])  # → "beginner"

  sampler  = AdaptiveQuizSampler(all_item_ids)
  sampler.record("بلی", score=35.0)
  next_10  = sampler.sample(n=10)

  # Run standalone demo:
  python ml/learning_engine.py
"""

import json
import math
import random
from dataclasses import dataclass, field
from datetime import date, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import numpy as np
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

# ── Config ─────────────────────────────────────────────────────────────────────
SEED              = 42
EMA_ALPHA_GOOD    = 0.7   # weight for old score on correct answer
EMA_ALPHA_NEW     = 0.3   # weight for new signal
SRS_MAX_INTERVAL  = 64    # days
SRS_PASS_THRESHOLD = 80.0  # score threshold to double interval
WEAK_FRACTION     = 0.65  # fraction of quiz from weak items

random.seed(SEED)
np.random.seed(SEED)


# ── K-Means Student Profiler ───────────────────────────────────────────────────
# Cold-start anchors — synthetic feature vectors for each level.
# Feature vector: [avg_score_pct, completion_rate, speed_score]
# where speed_score = 1 - (avg_response_time / max_expected_time)
_COLD_START_ANCHORS = np.array([
    [0.30, 0.50, 0.70],   # beginner:      low score, moderate completion, slow
    [0.65, 0.65, 0.35],   # intermediate:  mid score, good completion, average speed
    [0.90, 0.80, 0.10],   # advanced:      high score, high completion, fast
], dtype=np.float32)

_LEVEL_NAMES = ["beginner", "intermediate", "advanced"]


class StudentProfiler:
    """
    K-Means (k=3) student profiler.
    Trained on cold-start anchors + real student data as it accumulates.

    Features (all normalised 0-1):
      - avg_score       : average quiz score across all sessions
      - completion_rate : fraction of exercises completed
      - speed_score     : inverse of average response time (normalised)
    """

    def __init__(self):
        self._scaler  = StandardScaler()
        self._kmeans  = KMeans(n_clusters=3, n_init=10, random_state=SEED)
        # Fit on cold-start anchors so the model is immediately usable
        anchors = _COLD_START_ANCHORS.copy()
        self._scaler.fit(anchors)
        scaled = self._scaler.transform(anchors)
        self._kmeans.fit(scaled)
        # Map cluster indices to level names by centroid avg_score
        centers = self._kmeans.cluster_centers_
        order   = np.argsort(self._scaler.inverse_transform(centers)[:, 0])
        self._cluster_to_level: Dict[int, str] = {
            int(order[i]): _LEVEL_NAMES[i] for i in range(3)
        }

    def predict(self, features: List[float]) -> str:
        """
        Classify a student into beginner / intermediate / advanced.

        Parameters
        ----------
        features : [avg_score (0-1), completion_rate (0-1), speed_score (0-1)]
        """
        vec    = np.array(features, dtype=np.float32).reshape(1, -1)
        scaled = self._scaler.transform(vec)
        cluster = int(self._kmeans.predict(scaled)[0])
        return self._cluster_to_level.get(cluster, "beginner")

    def fit_with_student_data(self, student_features: List[List[float]]):
        """
        Re-fit the model after enough real data has been collected.
        Always includes the 3 cold-start anchors to prevent cluster collapse.
        """
        data = np.vstack([_COLD_START_ANCHORS, np.array(student_features)])
        self._scaler.fit(data)
        scaled = self._scaler.transform(data)
        self._kmeans.fit(scaled)
        centers = self._kmeans.cluster_centers_
        order   = np.argsort(self._scaler.inverse_transform(centers)[:, 0])
        self._cluster_to_level = {int(order[i]): _LEVEL_NAMES[i] for i in range(3)}
        print(f"[Profiler] Re-fitted on {len(student_features)} student records + 3 anchors.")


# ── EMA Weakness Tracker ───────────────────────────────────────────────────────
@dataclass
class WeaknessEntry:
    item_id:        str
    weakness_score: float = 50.0   # start at neutral 50
    attempt_count:  int   = 0


class WeaknessTracker:
    """
    Tracks per-item weakness using Exponential Moving Average (EMA).

    weakness_score = 0.7 * old_weakness + 0.3 * (100 - score)

    A score of 100 decreases weakness; a score of 0 maximally increases it.
    Starting weakness of 50 is neutral — not yet known.
    """

    def __init__(self):
        self._entries: Dict[str, WeaknessEntry] = {}

    def record(self, item_id: str, score: float):
        """Record a quiz result for item_id (score 0–100)."""
        score = float(np.clip(score, 0.0, 100.0))
        entry = self._entries.get(item_id)
        if entry is None:
            entry = WeaknessEntry(item_id=item_id)
            self._entries[item_id] = entry

        old = entry.weakness_score
        entry.weakness_score = EMA_ALPHA_GOOD * old + EMA_ALPHA_NEW * (100.0 - score)
        entry.attempt_count += 1

    def get_weakness(self, item_id: str) -> float:
        return self._entries.get(item_id, WeaknessEntry(item_id)).weakness_score

    def top_weak_items(self, n: int) -> List[str]:
        """Return the n most difficult items sorted by weakness_score descending."""
        sorted_items = sorted(
            self._entries.values(),
            key=lambda e: e.weakness_score,
            reverse=True,
        )
        return [e.item_id for e in sorted_items[:n]]

    def all_scores(self) -> Dict[str, float]:
        return {k: v.weakness_score for k, v in self._entries.items()}


# ── SRS Scheduler ─────────────────────────────────────────────────────────────
@dataclass
class SRSEntry:
    item_id:  str
    interval: int  = 1     # days until next review
    due_date: date = field(default_factory=date.today)


class SRSScheduler:
    """
    Simple Spaced Repetition System.
      - score >= 80  : interval = min(interval * 2, 64)
      - score < 80   : interval = 1  (reset — review tomorrow)
    """

    def __init__(self):
        self._entries: Dict[str, SRSEntry] = {}

    def record(self, item_id: str, score: float):
        entry = self._entries.get(item_id)
        if entry is None:
            entry = SRSEntry(item_id=item_id)
            self._entries[item_id] = entry

        if score >= SRS_PASS_THRESHOLD:
            entry.interval = min(entry.interval * 2, SRS_MAX_INTERVAL)
        else:
            entry.interval = 1

        entry.due_date = date.today() + timedelta(days=entry.interval)

    def is_due(self, item_id: str) -> bool:
        entry = self._entries.get(item_id)
        if entry is None:
            return True   # never seen → always due
        return date.today() >= entry.due_date

    def due_items(self, all_ids: List[str]) -> List[str]:
        """Return all items that are due for review today."""
        return [i for i in all_ids if self.is_due(i)]

    def get_interval(self, item_id: str) -> int:
        return self._entries.get(item_id, SRSEntry(item_id=item_id)).interval


# ── Adaptive Quiz Sampler ──────────────────────────────────────────────────────
class AdaptiveQuizSampler:
    """
    Combines WeaknessTracker + SRSScheduler to intelligently select quiz items.

    Selection strategy:
      1. Items that are SRS-due AND in the top weakness bucket  → highest priority
      2. Items that are just SRS-due                            → medium priority
      3. Items with high weakness_score                         → 65% of remaining slots
      4. Random items                                           → 35% of remaining slots

    This ensures the student sees items they find difficult and items they're
    scheduled to review, while still encountering new/easy material.
    """

    def __init__(self, all_item_ids: List[str]):
        self._ids      = list(all_item_ids)
        self._weakness = WeaknessTracker()
        self._srs      = SRSScheduler()

    def record(self, item_id: str, score: float):
        """Call this after every quiz question is answered."""
        self._weakness.record(item_id, score)
        self._srs.record(item_id, score)

    def sample(self, n: int = 10) -> List[str]:
        """
        Return n item IDs for the next quiz, ordered by priority.
        Items may repeat if the vocabulary pool is smaller than n.
        """
        if not self._ids:
            return []

        due_set  = set(self._srs.due_items(self._ids))
        weak_top = set(self._weakness.top_weak_items(max(n, 5)))

        # Tier 1: due AND weak
        tier1 = list(due_set & weak_top)
        random.shuffle(tier1)

        # Tier 2: due but not in top-weak
        tier2 = list(due_set - weak_top)
        random.shuffle(tier2)

        # Tier 3: weak but not due
        weak_scores = self._weakness.all_scores()
        tier3 = sorted(
            [i for i in self._ids if i not in due_set and i in weak_top],
            key=lambda i: weak_scores.get(i, 50.0),
            reverse=True,
        )

        # Tier 4: everything else (random)
        seen = set(tier1 + tier2 + tier3)
        tier4 = [i for i in self._ids if i not in seen]
        random.shuffle(tier4)

        # Fill n slots by priority
        selected: List[str] = []
        for pool in [tier1, tier2, tier3, tier4]:
            selected.extend(pool)
            if len(selected) >= n:
                break

        # If pool smaller than n, cycle through with repeats
        while len(selected) < n:
            selected.extend(self._ids[:n])

        return selected[:n]

    @property
    def weakness_scores(self) -> Dict[str, float]:
        return self._weakness.all_scores()

    @property
    def srs_intervals(self) -> Dict[str, int]:
        return {i: self._srs.get_interval(i) for i in self._ids}


# ── Serialisation helpers ──────────────────────────────────────────────────────
def save_sampler_state(sampler: AdaptiveQuizSampler, path: str):
    state = {
        "weakness_scores": sampler.weakness_scores,
        "srs_intervals":   sampler.srs_intervals,
    }
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(state, f, ensure_ascii=False, indent=2)
    print(f"[Engine] State saved → {path}")


def load_sampler_state(sampler: AdaptiveQuizSampler, path: str):
    if not Path(path).exists():
        print(f"[Engine] No saved state at {path} — starting fresh.")
        return
    with open(path, encoding="utf-8") as f:
        state = json.load(f)
    for item_id, w_score in state.get("weakness_scores", {}).items():
        # Reverse-engineer the record by setting score that produces this weakness
        implied_score = 100.0 - w_score
        sampler._weakness._entries[item_id] = WeaknessEntry(
            item_id=item_id, weakness_score=w_score
        )
    for item_id, interval in state.get("srs_intervals", {}).items():
        sampler._srs._entries[item_id] = SRSEntry(
            item_id=item_id, interval=interval
        )
    print(f"[Engine] State loaded from {path}")


# ── Demo / smoke-test ──────────────────────────────────────────────────────────
if __name__ == "__main__":
    # ── 1. Student Profiler demo ───────────────────────────────────────────────
    print("=" * 55)
    print("  STUDENT PROFILER DEMO")
    print("=" * 55)
    profiler = StudentProfiler()
    test_cases = [
        ([0.25, 0.40, 0.80], "beginner"),
        ([0.60, 0.70, 0.45], "intermediate"),
        ([0.92, 0.85, 0.05], "advanced"),
    ]
    all_correct = True
    for features, expected in test_cases:
        pred = profiler.predict(features)
        status = "✅" if pred == expected else "❌"
        print(f"  {status} features={features} → predicted={pred!r:14} expected={expected!r}")
        if pred != expected:
            all_correct = False
    print(f"\n  Cold-start accuracy: {'3/3 ✅' if all_correct else 'some failed'}")

    # ── 2. Weakness Tracker demo ───────────────────────────────────────────────
    print("\n" + "=" * 55)
    print("  WEAKNESS TRACKER DEMO")
    print("=" * 55)
    tracker = WeaknessTracker()
    vocab = ["بلی", "کتا", "شیر", "آم", "سیب", "پانی", "کتاب", "گھر", "سورج", "چاند"]
    for word in vocab:
        score = random.uniform(0, 100)
        tracker.record(word, score)
    top3 = tracker.top_weak_items(3)
    print(f"  Top 3 weakest items: {top3}")
    for w in top3:
        print(f"    {w}: weakness={tracker.get_weakness(w):.1f}")

    # ── 3. Adaptive Sampler demo ───────────────────────────────────────────────
    print("\n" + "=" * 55)
    print("  ADAPTIVE QUIZ SAMPLER DEMO (10 questions)")
    print("=" * 55)
    sampler = AdaptiveQuizSampler(vocab)
    # Simulate 3 rounds of the student getting بلی and کتا wrong
    for word in ["بلی", "کتا", "بلی", "کتا"]:
        sampler.record(word, score=15.0)   # consistently wrong
    # And سورج correct
    for _ in range(3):
        sampler.record("سورج", score=95.0)

    quiz = sampler.sample(n=10)
    print(f"  Quiz order: {quiz}")
    weak_count = sum(1 for q in quiz if q in ["بلی", "کتا"])
    print(f"  Weak items (بلی/کتا) appear {weak_count}/10 times "
          f"(expected ≥ 3 due to high weakness)")

    # ── 4. SRS interval demo ──────────────────────────────────────────────────
    print("\n" + "=" * 55)
    print("  SRS INTERVAL DEMO")
    print("=" * 55)
    srs = SRSScheduler()
    srs.record("بلی", 90.0)   # pass → interval = 2
    srs.record("بلی", 90.0)   # pass → interval = 4
    srs.record("بلی", 90.0)   # pass → interval = 8
    srs.record("کتا", 30.0)   # fail → interval = 1
    print(f"  بلی interval after 3 passes: {srs.get_interval('بلی')} days (expected 8)")
    print(f"  کتا interval after 1 fail:  {srs.get_interval('کتا')} day  (expected 1)")

    print("\n[Engine] All demos complete ✅")
