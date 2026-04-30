"""
backend/main.py  -  AI-Powered Urdu Learning FastAPI  (6 real endpoints)
"""
import os, uuid, tempfile, random, math
from contextlib import asynccontextmanager
from datetime import datetime
from typing import List

import numpy as np
from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from sqlalchemy.orm import Session

import database as db_models
from database import engine, get_db

# ── Lazy model cache ──────────────────────────────────────────────────────────
_whisper_processor = None
_whisper_model     = None
_mt5_tokenizer     = None
_mt5_model         = None


def _load_whisper():
    global _whisper_processor, _whisper_model
    if _whisper_model is None:
        try:
            from transformers import WhisperProcessor, WhisperForConditionalGeneration
            print("[INFO] Loading Whisper (openai/whisper-small)…")
            _whisper_processor = WhisperProcessor.from_pretrained("openai/whisper-small")
            _whisper_model     = WhisperForConditionalGeneration.from_pretrained("openai/whisper-small")
            _whisper_model.eval()
            print("[INFO] Whisper ready.")
        except Exception as e:
            print(f"[WARN] Whisper load failed: {e}")
    return _whisper_processor, _whisper_model


def _load_mt5():
    global _mt5_tokenizer, _mt5_model
    if _mt5_model is None:
        try:
            from transformers import MT5ForConditionalGeneration, MT5Tokenizer
            print("[INFO] Loading mT5 (google/mt5-small)…")
            _mt5_tokenizer = MT5Tokenizer.from_pretrained("google/mt5-small")
            _mt5_model     = MT5ForConditionalGeneration.from_pretrained("google/mt5-small")
            _mt5_model.eval()
            print("[INFO] mT5 ready.")
        except Exception as e:
            print(f"[WARN] mT5 load failed: {e}")
    return _mt5_tokenizer, _mt5_model


# ── Lifespan ──────────────────────────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    print("[INFO] Urdu Learning API starting.")
    db_models.Base.metadata.create_all(bind=engine)
    yield
    print("[INFO] Urdu Learning API stopped.")


# ── App ───────────────────────────────────────────────────────────────────────
app = FastAPI(
    title="Urdu Learning API",
    description="AI-Powered Urdu Learning Backend",
    version="1.0.0",
    lifespan=lifespan,
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True,
    allow_methods=["*"], allow_headers=["*"],
)


# ── Pure-Python helpers ───────────────────────────────────────────────────────
def _levenshtein(s: str, t: str) -> int:
    m, n = len(s), len(t)
    dp = [[0]*(n+1) for _ in range(m+1)]
    for i in range(m+1): dp[i][0] = i
    for j in range(n+1): dp[0][j] = j
    for i in range(1, m+1):
        for j in range(1, n+1):
            dp[i][j] = dp[i-1][j-1] if s[i-1]==t[j-1] else 1+min(dp[i-1][j], dp[i][j-1], dp[i-1][j-1])
    return dp[m][n]


def _lev_score(a: str, b: str) -> float:
    a, b = a.lower().strip(), b.lower().strip()
    if not a and not b: return 100.0
    if not a or not b:  return 0.0
    return round((1 - _levenshtein(a, b) / max(len(a), len(b))) * 100, 2)


def _pron_feedback(score: float) -> str:
    if score >= 70: return "شاباش! تلفظ درست ہے"
    if score >= 50: return "قریب ہے، مزید مشق کریں"
    return "غلط تلفظ، دوبارہ سنیں"


def _level(stars: int) -> str:
    if stars >= 150: return "advanced"
    if stars >= 60:  return "intermediate"
    return "beginner"


def _kmeans_cluster(features: List[float]) -> int:
    anchors = [[0.3,0.5,0.7],[0.65,0.65,0.35],[0.9,0.8,0.1]]
    dists = [math.sqrt(sum((f-a)**2 for f,a in zip(features,anc))) for anc in anchors]
    return int(min(range(3), key=lambda i: dists[i]))


FALLBACK_WORDS = [
    {"word_id":"1","word_urdu":"پانی","word_roman":"paani"},
    {"word_id":"2","word_urdu":"کتاب","word_roman":"kitaab"},
    {"word_id":"3","word_urdu":"گھر","word_roman":"ghar"},
    {"word_id":"4","word_urdu":"سیب","word_roman":"saib"},
    {"word_id":"5","word_urdu":"دودھ","word_roman":"doodh"},
    {"word_id":"6","word_urdu":"بچہ","word_roman":"bacha"},
    {"word_id":"7","word_urdu":"ماں","word_roman":"maa"},
    {"word_id":"8","word_urdu":"باپ","word_roman":"baap"},
    {"word_id":"9","word_urdu":"اسکول","word_roman":"iskool"},
    {"word_id":"10","word_urdu":"کھانا","word_roman":"khaana"},
]


# ── Pydantic models ───────────────────────────────────────────────────────────
class GrammarCheckRequest(BaseModel):
    sentence: str

class GenerateQuizRequest(BaseModel):
    user_id: str
    weak_areas: List[str] = []
    count: int = 10

class WordAttemptInput(BaseModel):
    word_id: str
    word_urdu: str
    score: float

class ProgressSaveRequest(BaseModel):
    user_id: str
    module: str
    score: float
    stars: int
    duration_s: int
    word_attempts: List[WordAttemptInput] = []

class ProfileStudentRequest(BaseModel):
    user_id: str
    accuracy: float
    speed: float
    mistakes: float


# ── Util ──────────────────────────────────────────────────────────────────────
def _ensure_user(uid: str, db: Session):
    u = db.query(db_models.User).filter(db_models.User.id == uid).first()
    if not u:
        u = db_models.User(id=uid, name="Student")
        db.add(u); db.flush()
    return u


# ── POST /api/assess-pronunciation ───────────────────────────────────────────
@app.post("/api/assess-pronunciation")
async def assess_pronunciation(
    audio: UploadFile = File(...),
    target_roman: str  = Form(...),
    target_urdu: str   = Form(...),
    db: Session = Depends(get_db),
):
    suffix = os.path.splitext(audio.filename or "rec.m4a")[1] or ".m4a"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        tmp.write(await audio.read()); tmp_path = tmp.name

    transcript = ""; confidence = 0.0
    try:
        proc, model = _load_whisper()
        if model is not None:
            import torch, torchaudio
            wv, sr = torchaudio.load(tmp_path)
            if sr != 16000:
                wv = torchaudio.transforms.Resample(sr, 16000)(wv)
            wv = wv.mean(dim=0)
            inp = proc(wv.numpy(), sampling_rate=16000, return_tensors="pt")
            with torch.no_grad():
                fids = proc.get_decoder_prompt_ids(language="ur", task="transcribe")
                gen  = model.generate(inp["input_features"], forced_decoder_ids=fids)
            transcript = proc.batch_decode(gen, skip_special_tokens=True)[0].strip()
            confidence = 0.85
    except Exception as e:
        print(f"[WARN] Whisper error: {e}")
    finally:
        try: os.unlink(tmp_path)
        except OSError: pass

    score    = _lev_score(transcript, target_roman)
    feedback = _pron_feedback(score)
    errors: List[dict] = []
    if score < 100 and transcript:
        tgt = list(target_roman.lower()); hyp = list(transcript.lower())
        for i, ch in enumerate(tgt):
            if i >= len(hyp) or hyp[i] != ch:
                errors.append({"expected": ch, "got": hyp[i] if i < len(hyp) else "", "position": i})
                if len(errors) >= 5: break

    return {"score": score, "transcript": transcript, "feedback_ur": feedback, "phoneme_errors": errors}


# ── POST /api/asr-transcribe ──────────────────────────────────────────────────
@app.post("/api/asr-transcribe")
async def asr_transcribe(audio: UploadFile = File(...)):
    suffix = os.path.splitext(audio.filename or "rec.m4a")[1] or ".m4a"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as tmp:
        tmp.write(await audio.read()); tmp_path = tmp.name
    try:
        proc, model = _load_whisper()
        if model is None:
            raise HTTPException(status_code=503, detail="ASR model unavailable")
        import torch, torchaudio
        wv, sr = torchaudio.load(tmp_path)
        if sr != 16000:
            wv = torchaudio.transforms.Resample(sr, 16000)(wv)
        wv  = wv.mean(dim=0)
        inp = proc(wv.numpy(), sampling_rate=16000, return_tensors="pt")
        with torch.no_grad():
            fids = proc.get_decoder_prompt_ids(language="ur", task="transcribe")
            gen  = model.generate(inp["input_features"], forced_decoder_ids=fids)
        transcript = proc.batch_decode(gen, skip_special_tokens=True)[0].strip()
        return {"transcript": transcript, "language": "ur", "confidence": 0.85}
    except HTTPException: raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        try: os.unlink(tmp_path)
        except OSError: pass


# ── POST /api/grammar-check ───────────────────────────────────────────────────
@app.post("/api/grammar-check")
async def grammar_check(req: GrammarCheckRequest):
    sentence = req.sentence.strip()
    if not sentence:
        raise HTTPException(status_code=400, detail="sentence must not be empty")

    corrected = sentence; changes: List[dict] = []; bleu = 1.0
    try:
        tok, model = _load_mt5()
        if model is None: raise RuntimeError("mT5 unavailable")
        import torch
        inp = tok(f"grammar: {sentence}", return_tensors="pt", max_length=128, truncation=True)
        with torch.no_grad():
            out = model.generate(inp["input_ids"], max_new_tokens=128, num_beams=4, early_stopping=True)
        corrected = tok.decode(out[0], skip_special_tokens=True).strip()
        orig_t = set(sentence.split()); corr_t = set(corrected.split())
        bleu = len(orig_t & corr_t) / len(orig_t) if orig_t else 1.0
        if corrected != sentence:
            for i,(ow,cw) in enumerate(zip(sentence.split(), corrected.split())):
                if ow != cw:
                    changes.append({"position": i, "original": ow, "corrected": cw})
    except Exception as e:
        print(f"[WARN] Grammar check: {e}")
        corrected = sentence; changes = []; bleu = 1.0

    return {"corrected": corrected, "changes": changes, "bleu": round(bleu, 4)}


# ── POST /api/generate-quiz ───────────────────────────────────────────────────
@app.post("/api/generate-quiz")
async def generate_quiz(req: GenerateQuizRequest, db: Session = Depends(get_db)):
    count = max(1, min(req.count, 20))

    attempts = (
        db.query(db_models.WordAttempt)
        .filter(db_models.WordAttempt.user_id == req.user_id)
        .order_by(db_models.WordAttempt.score.asc())
        .limit(20).all()
    )
    db_words = [{"word_id": a.word_id, "word_urdu": a.word_urdu, "word_roman": a.word_id}
                for a in attempts]

    all_words = FALLBACK_WORDS[:]
    for w in db_words:
        if not any(x["word_id"] == w["word_id"] for x in all_words):
            all_words.append(w)
    for wa_str in req.weak_areas:
        if not any(x["word_urdu"] == wa_str for x in all_words):
            all_words.append({"word_id": wa_str, "word_urdu": wa_str, "word_roman": ""})

    weak_pool = db_words[:10] if db_words else all_words
    n_weak    = math.ceil(count * 0.6)
    n_rand    = count - n_weak
    selected  = random.choices(weak_pool, k=min(n_weak, max(1, len(weak_pool)))) + random.choices(all_words, k=n_rand)
    random.shuffle(selected)

    q_types = ["mcq", "fill", "speak"]
    questions = []
    for i, word in enumerate(selected):
        distractors   = [w for w in all_words if w["word_id"] != word["word_id"]]
        distractor_s  = random.sample(distractors, min(3, len(distractors)))
        choices       = [w["word_urdu"] for w in distractor_s]
        correct_index = random.randint(0, len(choices))
        choices.insert(correct_index, word["word_urdu"])
        questions.append({
            "type": q_types[i % 3],
            "word_urdu": word["word_urdu"],
            "word_roman": word.get("word_roman", ""),
            "choices": choices,
            "correct_index": correct_index,
        })
    return {"questions": questions}


# ── POST /api/progress ────────────────────────────────────────────────────────
@app.post("/api/progress")
async def save_progress(req: ProgressSaveRequest, db: Session = Depends(get_db)):
    _ensure_user(req.user_id, db)

    db.add(db_models.Session(
        id=str(uuid.uuid4()), user_id=req.user_id,
        module=req.module, score=req.score, stars=req.stars,
        duration_s=req.duration_s, completed_at=datetime.utcnow(),
    ))

    EMA = 0.3
    for wa in req.word_attempts:
        ex = (db.query(db_models.WordAttempt)
              .filter(db_models.WordAttempt.user_id==req.user_id,
                      db_models.WordAttempt.word_id==wa.word_id).first())
        if ex:
            ex.score    = EMA*wa.score + (1-EMA)*ex.score
            ex.attempts += 1
            ex.last_seen = datetime.utcnow()
        else:
            db.add(db_models.WordAttempt(
                id=str(uuid.uuid4()), user_id=req.user_id,
                word_id=wa.word_id, word_urdu=wa.word_urdu,
                score=wa.score, attempts=1, last_seen=datetime.utcnow(),
            ))
    db.commit()

    all_sess   = db.query(db_models.Session).filter(db_models.Session.user_id==req.user_id).all()
    total_stars = sum(s.stars for s in all_sess)
    return {"saved": True, "new_stars": req.stars, "total_stars": total_stars, "level": _level(total_stars)}


# ── GET /api/progress/{user_id} ───────────────────────────────────────────────
@app.get("/api/progress/{user_id}")
async def get_progress(user_id: str, db: Session = Depends(get_db)):
    sessions = (db.query(db_models.Session)
                .filter(db_models.Session.user_id==user_id)
                .order_by(db_models.Session.completed_at.desc()).limit(50).all())
    attempts = (db.query(db_models.WordAttempt)
                .filter(db_models.WordAttempt.user_id==user_id)
                .order_by(db_models.WordAttempt.score.asc()).all())

    total_stars = sum(s.stars for s in sessions)
    return {
        "sessions": [{"id":s.id,"module":s.module,"score":s.score,"stars":s.stars,
                       "duration_s":s.duration_s,"completed_at":s.completed_at.isoformat() if s.completed_at else None}
                      for s in sessions],
        "weak_areas": [a.word_urdu for a in attempts[:5]],
        "total_stars": total_stars,
        "level": _level(total_stars),
        "word_attempts": [{"word_id":a.word_id,"word_urdu":a.word_urdu,"score":a.score,
                            "attempts":a.attempts,"last_seen":a.last_seen.isoformat() if a.last_seen else None}
                           for a in attempts],
    }


# ── POST /api/profile-student ─────────────────────────────────────────────────
@app.post("/api/profile-student")
async def profile_student(req: ProfileStudentRequest, db: Session = Depends(get_db)):
    features   = [float(req.accuracy), float(req.speed), float(req.mistakes)]
    cluster_id = _kmeans_cluster(features)
    names      = ["beginner", "intermediate", "advanced"]
    level      = names[cluster_id]

    recs = {
        "beginner":     ["حروف تہجی کی مشق روزانہ کریں", "بنیادی الفاظ سیکھیں", "استاد کی آواز دہرائیں"],
        "intermediate": ["جملے بنانے کی مشق کریں", "روزمرہ الفاظ یاد کریں", "تلفظ کا تجزیہ کریں"],
        "advanced":     ["پیچیدہ جملوں پر توجہ دیں", "گرامر کی گہری سمجھ بوجھ حاصل کریں", "روانی کے لیے بات چیت کریں"],
    }

    _ensure_user(req.user_id, db)
    feat_json = {"accuracy": req.accuracy, "speed": req.speed, "mistakes": req.mistakes}
    prof = db.query(db_models.StudentProfile).filter(db_models.StudentProfile.user_id==req.user_id).first()
    if prof:
        prof.cluster_id = cluster_id; prof.features = feat_json; prof.updated_at = datetime.utcnow()
    else:
        db.add(db_models.StudentProfile(user_id=req.user_id, cluster_id=cluster_id,
                                         features=feat_json, updated_at=datetime.utcnow()))
    db.commit()
    return {"cluster": cluster_id, "level": level, "recommendations": recs[level]}


# ── Health ────────────────────────────────────────────────────────────────────
@app.get("/")
def root(): return {"status": "ok", "app": "Urdu Learning API", "version": "1.0.0"}

@app.get("/health")
def health(): return {"status": "ok", "whisper": _whisper_model is not None, "mt5": _mt5_model is not None}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)