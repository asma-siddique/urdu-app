"""
evaluate_whisper_wer.py
=======================
Evaluates openai/whisper-large-v3 on the Mozilla Common Voice 17.0 Urdu
test split and reports Word Error Rate (WER).

This script produces the evaluation results you present to your teacher/examiner
to prove the ASR model's performance on real Urdu speech data.

Models Evaluated
----------------
  openai/whisper-large-v3
  Paper: Radford et al., 2022 — https://arxiv.org/abs/2212.04356

Dataset
-------
  mozilla-foundation/common_voice_17_0  (lang='ur', split='test')
  Source: https://huggingface.co/datasets/mozilla-foundation/common_voice_17_0

Usage
-----
    pip install datasets transformers jiwer torch torchaudio huggingface_hub
    python scripts/evaluate_whisper_wer.py --token hf_YOUR_TOKEN --samples 100

Output
------
    scripts/whisper_wer_results.json   — full results for report
    Printed WER, CER, sample predictions
"""

import argparse
import json
import time
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--token',   required=True, help='HuggingFace read token')
parser.add_argument('--samples', type=int, default=100,
                    help='Number of test samples to evaluate (default 100)')
parser.add_argument('--device',  default='cpu', choices=['cpu', 'cuda'],
                    help='Device to run Whisper on (default cpu)')
args = parser.parse_args()

# ── Imports ───────────────────────────────────────────────────────────────────
try:
    import torch
    from datasets import load_dataset, Audio
    from transformers import pipeline
    from jiwer import wer, cer
    from huggingface_hub import login
except ImportError:
    print("ERROR: Install required packages:")
    print("  pip install datasets transformers jiwer torch torchaudio huggingface_hub")
    exit(1)

# ── Login ─────────────────────────────────────────────────────────────────────
print("[1/5] Logging in to HuggingFace...")
login(token=args.token)

# ── Load Whisper ──────────────────────────────────────────────────────────────
print("[2/5] Loading openai/whisper-large-v3...")
asr = pipeline(
    "automatic-speech-recognition",
    model="openai/whisper-large-v3",
    device=0 if args.device == 'cuda' and torch.cuda.is_available() else -1,
    generate_kwargs={"language": "urdu", "task": "transcribe"},
    chunk_length_s=30,
)
print(f"      Device: {args.device}")

# ── Load Common Voice Urdu test split ─────────────────────────────────────────
print("[3/5] Loading Common Voice 17.0 (Urdu, test split)...")
test_ds = load_dataset(
    "mozilla-foundation/common_voice_17_0",
    "ur",
    split="test",
    token=args.token,
    trust_remote_code=True,
)
# Resample to 16kHz (Whisper requirement)
test_ds = test_ds.cast_column("audio", Audio(sampling_rate=16_000))

n = min(args.samples, len(test_ds))
print(f"      Total test clips : {len(test_ds)}, evaluating: {n}")

# ── Run inference ─────────────────────────────────────────────────────────────
print(f"[4/5] Running Whisper on {n} samples...")

references  = []
hypotheses  = []
sample_rows = []
errors      = 0

for i in range(n):
    row = test_ds[i]
    ref = row['sentence'].strip()
    audio_array = row['audio']['array']
    sr          = row['audio']['sampling_rate']

    try:
        t0  = time.time()
        out = asr({'array': audio_array, 'sampling_rate': sr})
        hyp = out['text'].strip()
        elapsed = time.time() - t0

        references.append(ref)
        hypotheses.append(hyp)

        sample_rows.append({
            'index': i,
            'reference': ref,
            'hypothesis': hyp,
            'correct': ref == hyp,
            'time_s': round(elapsed, 2),
        })

        if i < 5 or i % 20 == 0:
            print(f"  [{i+1}/{n}] REF : {ref}")
            print(f"          HYP : {hyp}")
            print(f"          {'✓' if ref == hyp else '✗'}  ({elapsed:.1f}s)")
    except Exception as e:
        print(f"  [{i+1}/{n}] ERROR: {e}")
        errors += 1

# ── Compute metrics ───────────────────────────────────────────────────────────
print("[5/5] Computing metrics...")

word_error_rate  = wer(references, hypotheses)
char_error_rate  = cer(references, hypotheses)
exact_match      = sum(r == h for r, h in zip(references, hypotheses))
exact_match_pct  = exact_match / len(references) * 100 if references else 0

print(f"\n{'='*55}")
print(f"  MODEL   : openai/whisper-large-v3")
print(f"  DATASET : Common Voice 17.0 — Urdu test split")
print(f"  SAMPLES : {len(references)} evaluated, {errors} errors")
print(f"{'='*55}")
print(f"  WER  (Word Error Rate)  : {word_error_rate*100:.2f}%")
print(f"  CER  (Char Error Rate)  : {char_error_rate*100:.2f}%")
print(f"  Exact Match             : {exact_match_pct:.2f}%  ({exact_match}/{len(references)})")
print(f"{'='*55}")
print(f"\n  FYP Summary (copy this for your report):")
print(f"  'We evaluated openai/whisper-large-v3 on {len(references)} samples")
print(f"   from Mozilla Common Voice 17.0 (Urdu test split) and achieved")
print(f"   a Word Error Rate of {word_error_rate*100:.2f}% and Character Error Rate")
print(f"   of {char_error_rate*100:.2f}%.'")

# ── Save results ──────────────────────────────────────────────────────────────
results = {
    'model': 'openai/whisper-large-v3',
    'paper': 'Radford et al., 2022 — https://arxiv.org/abs/2212.04356',
    'dataset': 'mozilla-foundation/common_voice_17_0',
    'dataset_language': 'ur (Urdu)',
    'dataset_split': 'test',
    'samples_evaluated': len(references),
    'errors': errors,
    'word_error_rate': round(word_error_rate * 100, 2),
    'char_error_rate': round(char_error_rate * 100, 2),
    'exact_match_pct': round(exact_match_pct, 2),
    'sample_predictions': sample_rows[:20],  # first 20 for report
}

out_path = Path(__file__).parent / 'whisper_wer_results.json'
out_path.write_text(json.dumps(results, ensure_ascii=False, indent=2))
print(f"\n  Full results saved to: {out_path}")
