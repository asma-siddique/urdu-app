# AI Models & Dataset — FYP Documentation

## What the app actually uses

| Component | Model / Source | Purpose |
|---|---|---|
| **TTS** (speaker button) | `facebook/mms-tts-urd-script_arabic` | Converts Urdu text → native audio |
| **ASR** (mic button) | `openai/whisper-large-v3` | Converts student's speech → text → score |
| **Vocabulary data** | Mozilla Common Voice 17.0 (Urdu) | Real validated Urdu sentences & words |
| **Evaluation** | Common Voice test split | Proves ASR accuracy (WER metric) |

---

## Models

### 1. openai/whisper-large-v3 (ASR)
- **Paper**: "Robust Speech Recognition via Large-Scale Weak Supervision" — Radford et al., 2022
- **Link**: https://arxiv.org/abs/2212.04356
- **Trained on**: 680,000 hours of weakly-supervised multilingual audio (99 languages including Urdu)
- **How we use it**: Student records pronunciation → sent to Whisper API → transcribed text compared to target → score 0–100%

### 2. facebook/mms-tts-urd-script_arabic (TTS)
- **Paper**: "Scaling Speech Technology to 1,000+ Languages" — Pratap et al., 2023
- **Link**: https://arxiv.org/abs/2305.13516
- **Trained on**: Meta MMS religious audio corpus (1,000+ languages, native Urdu speakers)
- **How we use it**: Each lesson card's speaker button calls MMS-TTS → real Urdu audio plays

---

## Dataset

### Mozilla Common Voice 17.0 — Urdu subset
- **Source**: https://huggingface.co/datasets/mozilla-foundation/common_voice_17_0
- **Language**: `ur` (Urdu)
- **Content**: Community-recorded Urdu speech + validated text transcriptions
- **How we use it**:
  - Generate vocabulary word lists (`cv_words.dart`)
  - Generate sentence data (`cv_sentences.dart`)
  - Evaluate Whisper WER on test split

---

## Setup (one-time)

```bash
# 1. Get a free HuggingFace token
#    Go to: https://huggingface.co/settings/tokens → New token (read)

# 2. Set the token in the Flutter app
#    Edit: flutter_app/lib/services/ai_config.dart
#    Change: static const String hfToken = 'hf_YOUR_TOKEN_HERE';

# 3. Install Python dependencies
pip install datasets transformers jiwer torch torchaudio huggingface_hub uroman
```

---

## Running the scripts

### Generate Dart data files from Common Voice
```bash
python scripts/generate_cv_urdu_data.py --token hf_YOUR_TOKEN
```
**Output:**
- `flutter_app/lib/data/cv_words.dart` — top 150 Urdu words from Common Voice
- `flutter_app/lib/data/cv_sentences.dart` — 200 validated sentences
- `scripts/cv_urdu_stats.json` — dataset statistics

### Evaluate Whisper WER on Common Voice test split
```bash
python scripts/evaluate_whisper_wer.py --token hf_YOUR_TOKEN --samples 100
```
**Output:**
- Prints WER%, CER%, exact match% to terminal
- `scripts/whisper_wer_results.json` — full results for your report

---

## What to say to your teacher

**Dataset**: "We used Mozilla Common Voice 17.0 Urdu subset — a community-validated speech corpus with [N] clips — to source our vocabulary data and evaluate our ASR pipeline."

**Model 1 (ASR)**: "We used openai/whisper-large-v3 (Radford et al., 2022) for automatic speech recognition. It was pre-trained on 680,000 hours of multilingual audio. We evaluated it on Common Voice Urdu achieving [X]% WER."

**Model 2 (TTS)**: "For text-to-speech we used facebook/mms-tts-urd-script_arabic (Pratap et al., 2023) — Meta's Massively Multilingual Speech model trained on 1,000+ languages including native Urdu audio."

**Our contribution**: "We built a pronunciation scoring pipeline that combines Whisper's transcription with phonetic alternative matching (Levenshtein distance + Urdu phoneme variants) to give learners a 0–100% accuracy score per word."
