# Deployment Guide — AI-Powered Urdu Learning App

## Table of Contents
1. [System Architecture](#architecture)
2. [Prerequisites](#prerequisites)
3. [ML Model Training](#ml-training)
4. [Backend Deployment (Render)](#backend-deploy)
5. [Flutter APK / AAB Build](#flutter-build)
6. [Play Store Publishing](#play-store)
7. [Environment Variables](#env-vars)
8. [Testing Plan](#testing)

---

## 1. System Architecture <a name="architecture"></a>

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                        │
│  HomeScreen → HaroofScreen → LafzScreen → JumlaySreen       │
│  RangScreen → QuizScreen                                     │
│                                                              │
│  TtsService (flutter_tts, ur-PK)                            │
│  SpeechService (speech_to_text)                             │
│  ApiService (http, multipart)                               │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTPS REST
┌────────────────────▼────────────────────────────────────────┐
│               FastAPI Backend (Render.com)                   │
│                                                              │
│  POST /api/assess-pronunciation  (Whisper ASR + scoring)     │
│  POST /api/asr-transcribe        (Whisper Urdu)              │
│  POST /api/grammar-check         (mT5-small)                 │
│  POST /api/generate-quiz         (adaptive, weak-area bias)  │
│  POST /api/progress              (save session + EMA)        │
│  GET  /api/progress/{user_id}    (load history)              │
│  POST /api/profile-student       (K-Means clustering)        │
└──────────┬──────────────────────┬───────────────────────────┘
           │                      │
  ┌────────▼──────┐      ┌────────▼──────────┐
  │  Supabase DB  │      │  HuggingFace Hub  │
  │  PostgreSQL   │      │  (model weights)  │
  │  5 tables     │      │  whisper-urdu     │
  └───────────────┘      │  pronunciation    │
                         └───────────────────┘
```

---

## 2. Prerequisites <a name="prerequisites"></a>

| Tool | Version | Install |
|------|---------|---------|
| Flutter SDK | ≥ 3.10.0 | https://docs.flutter.dev/get-started/install |
| Dart SDK | ≥ 3.0.0 | bundled with Flutter |
| Android Studio | ≥ Hedgehog | for emulator + signing |
| Python | ≥ 3.11 | https://python.org |
| CUDA | ≥ 11.8 | for model training (GPU) |
| Docker | ≥ 24.0 | for backend build |
| Git | any | |
| Render account | free tier OK | https://render.com |
| Supabase account | free tier OK | https://supabase.com |
| Google Play Console | $25 one-time | https://play.google.com/console |

---

## 3. ML Model Training <a name="ml-training"></a>

### 3.1 Environment Setup

```bash
cd ml/
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install transformers datasets evaluate jiwer sacrebleu scikit-learn
```

### 3.2 Download Datasets

```bash
# Mozilla Common Voice 13 — Urdu (requires HuggingFace account + acceptance)
huggingface-cli login
python -c "
from datasets import load_dataset
ds = load_dataset('mozilla-foundation/common_voice_13_0', 'ur',
                  split='train', streaming=False, trust_remote_code=True)
ds.save_to_disk('./data/common_voice_ur_train')
"

# OpenSLR SLR79 (Urdu speech)
wget https://www.openslr.org/resources/79/ur_PK_female.zip
wget https://www.openslr.org/resources/79/ur_PK_male.zip
unzip ur_PK_female.zip -d data/openslr/
unzip ur_PK_male.zip   -d data/openslr/

# Pronunciation dataset layout expected by train_pronunciation.py:
# data/pronunciation/correct/   ← WAV files of correct pronunciations
# data/pronunciation/incorrect/ ← WAV files of incorrect pronunciations
```

### 3.3 Train ASR (Whisper fine-tune)

```bash
# GPU recommended: ≥16 GB VRAM (RTX 3090, A100, or Colab A100)
python train_asr.py \
  --model_name openai/whisper-small \
  --epochs 10 \
  --batch_size 16 \
  --lr 1e-4 \
  --output_dir ./models/whisper-urdu \
  --push_to_hub \
  --hub_model_id YOUR_HF_USERNAME/whisper-urdu-fyp

# Expected result: WER drops from ~45% → ~22%
# Training time: ~4 hours on A100
```

### 3.4 Train Pronunciation Model (Ablation Study)

```bash
python train_pronunciation.py \
  --epochs 20 \
  --batch_size 32 \
  --lr 1e-4 \
  --ablation                        # trains both MFCC-BiLSTM and Wav2Vec2-BiLSTM
  --output_dir ./models/pronunciation

# Outputs:
#   models/pronunciation/mfcc_bilstm_best.pt
#   models/pronunciation/wav2vec2_bilstm_best.pt
#   ablation_results.json
```

### 3.5 Train NLP Models

```bash
python train_nlp.py --task both

# Outputs:
#   models/grammar-mt5/
#   models/quizgen-flan-t5/
#   training_results.json  (BLEU scores)
```

### 3.6 Upload Models to HuggingFace Hub

```bash
huggingface-cli login

python -c "
from transformers import WhisperForConditionalGeneration, WhisperProcessor
model = WhisperForConditionalGeneration.from_pretrained('./models/whisper-urdu')
processor = WhisperProcessor.from_pretrained('./models/whisper-urdu')
model.push_to_hub('YOUR_HF_USERNAME/whisper-urdu-fyp')
processor.push_to_hub('YOUR_HF_USERNAME/whisper-urdu-fyp')
"
```

### 3.7 Run Evaluation

```bash
python evaluation/run_eval.py
# Outputs: evaluation/eval_report.json
```

---

## 4. Backend Deployment (Render.com) <a name="backend-deploy"></a>

### 4.1 Supabase Database Setup

```sql
-- Run in Supabase SQL Editor
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  avatar VARCHAR(10),
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  module VARCHAR(50),
  score INTEGER,
  stars INTEGER,
  duration_s INTEGER,
  completed_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE word_attempts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  word_id VARCHAR(100),
  word_urdu VARCHAR(100),
  score FLOAT DEFAULT 50.0,
  attempts INTEGER DEFAULT 0,
  last_seen TIMESTAMP DEFAULT NOW()
);

CREATE TABLE phoneme_scores (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  phoneme VARCHAR(20),
  score FLOAT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE student_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  cluster_id INTEGER,
  features JSONB,
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### 4.2 Deploy to Render

```bash
# 1. Push code to GitHub
git add .
git commit -m "Initial FYP deployment"
git push origin main

# 2. In Render dashboard → New → Web Service
#    Connect your GitHub repo
#    Render auto-detects render.yaml

# 3. Set environment variables in Render dashboard:
#    DATABASE_URL  = postgresql://... (from Supabase → Settings → Database → URI)
#    HF_TOKEN      = hf_...          (from HuggingFace → Settings → Access Tokens)
#    SECRET_KEY    = <random 32-char string>
```

### 4.3 Verify Backend

```bash
curl https://urdu-learning-api.onrender.com/docs      # Swagger UI
curl https://urdu-learning-api.onrender.com/health    # {"status":"ok"}
```

---

## 5. Flutter APK / AAB Build <a name="flutter-build"></a>

### 5.1 Setup

```bash
cd flutter_app/
flutter pub get

# Download NotoNastaliqUrdu font
mkdir -p assets/fonts assets/images
curl -L "https://fonts.google.com/download?family=Noto+Nastaliq+Urdu" \
  -o noto_nastaliq.zip
unzip noto_nastaliq.zip -d /tmp/noto/
cp /tmp/noto/NotoNastaliqUrdu-Regular.ttf assets/fonts/

flutter doctor -v     # ensure Android SDK is found
```

### 5.2 Generate Signing Keystore (one-time)

```bash
cd flutter_app/android/

keytool -genkey -v \
  -keystore upload-keystore.jks \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -dname "CN=Urdu Learning App, OU=FYP, O=University, L=Karachi, S=Sindh, C=PK"

# Create key.properties (NEVER commit this file — it is in .gitignore)
cat > key.properties << 'EOF'
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
EOF
```

### 5.3 Build Debug APK

```bash
cd flutter_app/
flutter build apk --debug \
  --dart-define=API_URL=https://urdu-learning-api.onrender.com

# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### 5.4 Build Release APK

```bash
flutter build apk --release \
  --dart-define=API_URL=https://urdu-learning-api.onrender.com \
  --obfuscate \
  --split-debug-info=build/debug-info/

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### 5.5 Build AAB (Play Store)

```bash
flutter build appbundle --release \
  --dart-define=API_URL=https://urdu-learning-api.onrender.com \
  --obfuscate \
  --split-debug-info=build/debug-info/

# Output: build/app/outputs/bundle/release/app-release.aab
```

### 5.6 Build Flutter Web (optional demo)

```bash
flutter build web --release \
  --dart-define=API_URL=https://urdu-learning-api.onrender.com
# Deploy build/web/ to Render static site or Firebase Hosting
```

---

## 6. Play Store Publishing <a name="play-store"></a>

### 6.1 Required Assets

| Asset | Size | Notes |
|-------|------|-------|
| App Icon | 512×512 PNG | No alpha, no rounded corners |
| Feature Graphic | 1024×500 PNG | Banner shown in store listing |
| Phone Screenshots | min 2, max 8 | 16:9 or 9:16 |
| 7-inch screenshots | optional | recommended |
| Short description | max 80 chars | "بچوں کے لیے AI اردو ٹیوٹر — حروف، الفاظ، جملے" |

### 6.2 Store Listing

**App Name:** اردو سیکھیں — AI ٹیوٹر

**Short Description (80 chars):**
AI اردو ٹیوٹر — حروف، الفاظ، جملے سیکھیں — بچوں کے لیے

**Full Description:**
```
اردو سیکھیں ایک AI سے چلنے والا اردو سیکھنے کا ایپ ہے جو خاص طور
پر بچوں کے لیے بنایا گیا ہے۔

خصوصیات:
• 40 حروف تہجی — بڑی آواز اور تصویر کے ساتھ
• 40 الفاظ — مختلف زمروں میں
• 15 جملے — لفظ بہ لفظ سیکھیں
• 15 رنگ — خوبصورت UI کے ساتھ
• AI تلفظ اسکور — آپ کی آواز کا تجزیہ
• ذہین کوئز — MCQ، match، fill، speak
• پروفیسر اوتار — ہر اسکرین پر
```

### 6.3 Publishing Checklist

```
[ ] Upload app-release.aab to Play Console → Production track
[ ] Set content rating: Everyone (ESRB Everyone / PEGI 3)
[ ] Target API level ≥ 34 (Android 14) — required from Aug 2024
[ ] Add privacy policy URL (required for microphone permission)
[ ] Declare RECORD_AUDIO permission in Data safety section
[ ] Set app category: Education
[ ] Set price: Free
[ ] Add countries: Pakistan, India, UK (Urdu-speaking diaspora)
[ ] Complete app content questionnaire
[ ] Submit for review (usually 1–3 days for first submission)
```

### 6.4 Privacy Policy (Required for Microphone)

Host a privacy policy page and add it to Play Console. Minimum content:
- What data is collected (voice recordings — processed, not stored permanently)
- How it is used (pronunciation assessment only)
- Third-party services (Google TTS, our FastAPI backend)
- Contact email

---

## 7. Environment Variables <a name="env-vars"></a>

### Backend (.env)

| Variable | Example | Description |
|----------|---------|-------------|
| `DATABASE_URL` | `postgresql://user:pass@host:5432/db` | Supabase connection string |
| `HF_TOKEN` | `hf_xxxxxxxxxxxx` | HuggingFace API token for model downloads |
| `SECRET_KEY` | `<random 32 chars>` | JWT signing (future auth) |
| `TRANSFORMERS_CACHE` | `/app/model_cache` | Where HF models are cached on disk |
| `WHISPER_MODEL` | `openai/whisper-small` | Override model name |
| `PORT` | `8000` | Uvicorn listen port |

### Flutter (--dart-define at build time)

| Variable | Default | Description |
|----------|---------|-------------|
| `API_URL` | `https://urdu-learning-api.onrender.com` | Backend base URL |

---

## 8. Testing Plan <a name="testing"></a>

### 8.1 Unit Tests (Flutter)

```bash
cd flutter_app/
flutter test test/

# Key test cases:
# - SpeechService.levenshtein("billi","bili") == 1
# - SpeechService.pronunciationScore("billi","billi") == 100.0
# - AppProvider.recordResult updates weaknessScores via EMA
# - AppProvider.weakestItems returns top-N sorted correctly
# - UserModel.toJson() / fromJson() round-trip
```

`test/unit_test.dart` sample:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:urdu_learning_app/services/speech_service.dart';

void main() {
  group('SpeechService pronunciation scoring', () {
    final service = SpeechService.instance;

    test('identical strings score 100', () {
      expect(service.pronunciationScore('billi', 'billi'), 100.0);
    });

    test('one-char diff scores near 80', () {
      final score = service.pronunciationScore('billi', 'bili');
      expect(score, greaterThan(70.0));
    });

    test('completely different scores near 0', () {
      final score = service.pronunciationScore('xyz', 'abc');
      expect(score, lessThan(50.0));
    });

    test('levenshtein distance', () {
      expect(service.levenshtein('kitten', 'sitting'), 3);
      expect(service.levenshtein('', 'abc'), 3);
      expect(service.levenshtein('abc', ''), 3);
    });
  });
}
```

### 8.2 Integration Tests (API)

```bash
cd backend/
pip install pytest httpx
pytest tests/ -v

# tests/test_api.py covers:
# - POST /api/assess-pronunciation with dummy WAV → score in [0,100]
# - POST /api/grammar-check with Urdu sentence → corrected string returned
# - POST /api/generate-quiz with user_id → 10 questions with correct_index
# - POST /api/progress → 200 OK + {saved: true}
# - GET  /api/progress/{user_id} → sessions list
```

### 8.3 ML Evaluation

```bash
cd ml/
python evaluation/run_eval.py
# Check eval_report.json:
# - ASR WER (fine-tuned) < 25%
# - Pronunciation F1 (wav2vec2) > 0.80
# - Grammar BLEU > 50
# - Quiz generation BLEU > 40
```

### 8.4 Device Testing

```
[ ] Samsung Galaxy A series (mid-range, target market)
[ ] OnePlus / Xiaomi (MIUI — custom TTS engines)
[ ] Android 10, 12, 14 (minimum SDK 21)
[ ] Test Urdu TTS voice: Settings → Accessibility → TTS → install Google TTS + Urdu
[ ] Test with slow internet (3G) — API timeout handling
[ ] Test offline mode — app should work without API (local scoring fallback)
```

---

## Quick-Start Summary

```bash
# 1. Clone and install
git clone https://github.com/YOUR_USERNAME/urdu-learning-fyp.git
cd urdu-learning-fyp

# 2. Train models (GPU machine)
cd ml && python train_asr.py && python train_pronunciation.py --ablation && python train_nlp.py --task both

# 3. Deploy backend
# Push to GitHub → connect Render → set env vars → auto-deploys

# 4. Build Flutter app
cd flutter_app
flutter pub get
flutter build appbundle --release --dart-define=API_URL=https://urdu-learning-api.onrender.com

# 5. Publish to Play Store
# Upload build/app/outputs/bundle/release/app-release.aab
```