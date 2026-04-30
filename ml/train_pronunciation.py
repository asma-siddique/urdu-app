"""
ml/train_pronunciation.py
=========================
Ablation study: MFCC-BiLSTM  vs  Wav2Vec2-BiLSTM for Urdu pronunciation scoring.
Both models perform binary classification: correct (1) / incorrect (0) pronunciation.

Dataset expected layout
-----------------------
  data/pronunciation/
    correct/   *.wav   (recordings rated correct by native speaker)
    incorrect/ *.wav   (recordings with mispronunciation)

You can bootstrap the dataset from Mozilla Common Voice Urdu:
  - "up-votes >= 2"  → correct
  - "down-votes >= 2" → incorrect

Usage
-----
  python ml/train_pronunciation.py --model mfcc    # baseline
  python ml/train_pronunciation.py --model wav2vec  # main model
  python ml/train_pronunciation.py --model both     # full ablation (default)
"""

import argparse
import os
import random
from pathlib import Path

import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
import torchaudio
import torchaudio.transforms as T
from sklearn.metrics import classification_report, f1_score
from torch.utils.data import DataLoader, Dataset, random_split
from transformers import Wav2Vec2Model, Wav2Vec2FeatureExtractor

# ── Config ─────────────────────────────────────────────────────────────────────
SEED             = 42
SAMPLING_RATE    = 16_000
MFCC_N_MFCC      = 13
MFCC_N_FFT       = 400
MFCC_HOP         = 160
LSTM_HIDDEN      = 256
LSTM_LAYERS      = 2
DROPOUT          = 0.3
BATCH_SIZE       = 32
EPOCHS           = 30
LEARNING_RATE    = 1e-4
PATIENCE         = 5            # early stopping patience
DATA_DIR         = Path("data/pronunciation")
OUTPUT_DIR       = Path("models")
WAV2VEC_MODEL_ID = "facebook/wav2vec2-base"
MAX_AUDIO_LEN    = SAMPLING_RATE * 5   # 5 seconds max

torch.manual_seed(SEED)
random.seed(SEED)
np.random.seed(SEED)
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"[PRON] Device: {DEVICE}")


# ── Dataset ────────────────────────────────────────────────────────────────────
class PronunciationDataset(Dataset):
    """
    Loads WAV files from:
      data/pronunciation/correct/   → label 1
      data/pronunciation/incorrect/ → label 0
    Falls back to synthetic data if the directory doesn't exist.
    """

    def __init__(self, data_dir: Path = DATA_DIR):
        self.samples: list[tuple[Path, int]] = []

        if data_dir.exists():
            for wav in (data_dir / "correct").glob("*.wav"):
                self.samples.append((wav, 1))
            for wav in (data_dir / "incorrect").glob("*.wav"):
                self.samples.append((wav, 0))
            print(f"[PRON] Loaded {len(self.samples)} audio samples from {data_dir}")
        else:
            print(f"[PRON] ⚠️  {data_dir} not found — using synthetic waveforms for smoke-test")
            self._use_synthetic = True
            self._n = 500

    def __len__(self):
        if hasattr(self, "_use_synthetic"):
            return self._n
        return len(self.samples)

    def __getitem__(self, idx):
        if hasattr(self, "_use_synthetic"):
            label = idx % 2
            # Generate distinct synthetic waveforms for each class
            freq  = 440.0 if label == 1 else 220.0
            t     = torch.linspace(0, 1, SAMPLING_RATE)
            wave  = (0.5 * torch.sin(2 * np.pi * freq * t)
                     + 0.05 * torch.randn(SAMPLING_RATE))
            return wave, label

        path, label = self.samples[idx]
        waveform, sr = torchaudio.load(path)
        if sr != SAMPLING_RATE:
            waveform = torchaudio.functional.resample(waveform, sr, SAMPLING_RATE)
        waveform = waveform.mean(dim=0)  # mono

        # Pad or truncate to MAX_AUDIO_LEN
        if waveform.shape[0] > MAX_AUDIO_LEN:
            waveform = waveform[:MAX_AUDIO_LEN]
        else:
            pad = MAX_AUDIO_LEN - waveform.shape[0]
            waveform = torch.nn.functional.pad(waveform, (0, pad))

        return waveform, label


def get_dataloaders(dataset):
    n      = len(dataset)
    n_val  = int(0.15 * n)
    n_test = int(0.15 * n)
    n_train = n - n_val - n_test
    train_ds, val_ds, test_ds = random_split(
        dataset, [n_train, n_val, n_test],
        generator=torch.Generator().manual_seed(SEED),
    )
    return (
        DataLoader(train_ds, batch_size=BATCH_SIZE, shuffle=True,  num_workers=2),
        DataLoader(val_ds,   batch_size=BATCH_SIZE, shuffle=False, num_workers=2),
        DataLoader(test_ds,  batch_size=BATCH_SIZE, shuffle=False, num_workers=2),
    )


# ── Model A: MFCC-BiLSTM (Ablation Baseline) ───────────────────────────────────
class MFCCBiLSTM(nn.Module):
    """
    MFCC(13 coefficients) → 2-layer BiLSTM(256) → Linear(2)
    This is the ablation baseline (no pre-trained speech encoder).
    """

    def __init__(self):
        super().__init__()
        self.mfcc = T.MFCC(
            sample_rate=SAMPLING_RATE,
            n_mfcc=MFCC_N_MFCC,
            melkwargs={"n_fft": MFCC_N_FFT, "hop_length": MFCC_HOP},
        )
        self.bilstm = nn.LSTM(
            input_size=MFCC_N_MFCC,
            hidden_size=LSTM_HIDDEN,
            num_layers=LSTM_LAYERS,
            batch_first=True,
            bidirectional=True,
            dropout=DROPOUT,
        )
        self.dropout = nn.Dropout(DROPOUT)
        self.fc = nn.Linear(LSTM_HIDDEN * 2, 2)   # *2 for bidirectional

    def forward(self, waveform: torch.Tensor) -> torch.Tensor:
        # waveform: (B, T)
        mfcc = self.mfcc(waveform)                 # (B, n_mfcc, frames)
        mfcc = mfcc.permute(0, 2, 1)              # (B, frames, n_mfcc)
        out, _ = self.bilstm(mfcc)
        out = out[:, -1, :]                        # last time step
        out = self.dropout(out)
        return self.fc(out)


# ── Model B: Wav2Vec2-BiLSTM (Main Model) ──────────────────────────────────────
class Wav2Vec2BiLSTM(nn.Module):
    """
    Frozen wav2vec2-base → BiLSTM(256) → Linear(2)
    wav2vec2 acts as a deep acoustic feature extractor.
    Only the BiLSTM + head are trained (transfer learning).
    """

    def __init__(self):
        super().__init__()
        self.feature_extractor = Wav2Vec2FeatureExtractor.from_pretrained(WAV2VEC_MODEL_ID)
        self.wav2vec2 = Wav2Vec2Model.from_pretrained(WAV2VEC_MODEL_ID)
        # Freeze wav2vec2 weights
        for param in self.wav2vec2.parameters():
            param.requires_grad = False

        hidden_size = self.wav2vec2.config.hidden_size   # 768 for wav2vec2-base
        self.bilstm = nn.LSTM(
            input_size=hidden_size,
            hidden_size=LSTM_HIDDEN,
            num_layers=LSTM_LAYERS,
            batch_first=True,
            bidirectional=True,
            dropout=DROPOUT,
        )
        self.dropout = nn.Dropout(DROPOUT)
        self.fc = nn.Linear(LSTM_HIDDEN * 2, 2)

    def forward(self, waveform: torch.Tensor) -> torch.Tensor:
        # waveform: (B, T)
        with torch.no_grad():
            outputs = self.wav2vec2(waveform)
        hidden = outputs.last_hidden_state      # (B, frames, 768)
        out, _ = self.bilstm(hidden)
        out = out[:, -1, :]
        out = self.dropout(out)
        return self.fc(out)


# ── Training loop ──────────────────────────────────────────────────────────────
def train_model(model: nn.Module, train_dl, val_dl, model_name: str) -> nn.Module:
    model = model.to(DEVICE)
    optimizer  = optim.AdamW(filter(lambda p: p.requires_grad, model.parameters()), lr=LEARNING_RATE)
    scheduler  = optim.lr_scheduler.ReduceLROnPlateau(optimizer, patience=2, factor=0.5)
    criterion  = nn.CrossEntropyLoss()

    best_val_f1 = 0.0
    best_state  = None
    no_improve  = 0

    for epoch in range(1, EPOCHS + 1):
        # ── Train ──
        model.train()
        train_loss = 0.0
        for waves, labels in train_dl:
            waves, labels = waves.to(DEVICE), labels.to(DEVICE)
            optimizer.zero_grad()
            logits = model(waves)
            loss   = criterion(logits, labels)
            loss.backward()
            nn.utils.clip_grad_norm_(model.parameters(), 1.0)
            optimizer.step()
            train_loss += loss.item()

        # ── Validate ──
        model.eval()
        val_loss = 0.0
        all_preds, all_labels = [], []
        with torch.no_grad():
            for waves, labels in val_dl:
                waves, labels = waves.to(DEVICE), labels.to(DEVICE)
                logits = model(waves)
                val_loss += criterion(logits, labels).item()
                preds = logits.argmax(dim=1)
                all_preds.extend(preds.cpu().tolist())
                all_labels.extend(labels.cpu().tolist())

        val_f1   = f1_score(all_labels, all_preds, average="weighted")
        avg_train = train_loss / len(train_dl)
        avg_val   = val_loss   / len(val_dl)
        scheduler.step(avg_val)

        print(f"[{model_name}] Epoch {epoch:02d}/{EPOCHS} | "
              f"train_loss={avg_train:.4f} val_loss={avg_val:.4f} val_F1={val_f1:.4f}")

        if val_f1 > best_val_f1:
            best_val_f1 = val_f1
            best_state  = {k: v.clone() for k, v in model.state_dict().items()}
            no_improve  = 0
        else:
            no_improve += 1
            if no_improve >= PATIENCE:
                print(f"[{model_name}] Early stopping at epoch {epoch}")
                break

    if best_state:
        model.load_state_dict(best_state)
    return model


# ── Evaluation ─────────────────────────────────────────────────────────────────
def evaluate_model(model: nn.Module, test_dl, model_name: str) -> dict:
    model.eval()
    all_preds, all_labels = [], []
    with torch.no_grad():
        for waves, labels in test_dl:
            waves  = waves.to(DEVICE)
            logits = model(waves)
            preds  = logits.argmax(dim=1)
            all_preds.extend(preds.cpu().tolist())
            all_labels.extend(labels.cpu().tolist())

    f1  = f1_score(all_labels, all_preds, average="weighted")
    acc = sum(p == l for p, l in zip(all_preds, all_labels)) / len(all_labels)
    report = classification_report(all_labels, all_preds,
                                   target_names=["incorrect", "correct"])
    print(f"\n[{model_name}] ── Test Results ────────────────────────")
    print(f"  Accuracy : {acc*100:.2f}%")
    print(f"  F1 Score : {f1:.4f}")
    print(report)
    print("─" * 50)
    return {"model": model_name, "accuracy": acc, "f1": f1}


# ── Save ────────────────────────────────────────────────────────────────────────
def save_model(model: nn.Module, name: str):
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUTPUT_DIR / f"{name}.pt"
    torch.save(model.state_dict(), path)
    print(f"[PRON] Saved {name} → {path}")


# ── Main ────────────────────────────────────────────────────────────────────────
def main(run_model: str = "both"):
    dataset = PronunciationDataset()
    train_dl, val_dl, test_dl = get_dataloaders(dataset)

    results = []

    if run_model in ("mfcc", "both"):
        print("\n" + "="*55)
        print("  MODEL A — MFCC-BiLSTM  (ablation baseline)")
        print("="*55)
        mfcc_model = train_model(MFCCBiLSTM(), train_dl, val_dl, "MFCC-BiLSTM")
        save_model(mfcc_model, "mfcc_bilstm")
        results.append(evaluate_model(mfcc_model, test_dl, "MFCC-BiLSTM"))

    if run_model in ("wav2vec", "both"):
        print("\n" + "="*55)
        print("  MODEL B — Wav2Vec2-BiLSTM  (main model)")
        print("="*55)
        w2v_model = train_model(Wav2Vec2BiLSTM(), train_dl, val_dl, "Wav2Vec2-BiLSTM")
        save_model(w2v_model, "wav2vec2_bilstm")
        results.append(evaluate_model(w2v_model, test_dl, "Wav2Vec2-BiLSTM"))

    if len(results) == 2:
        print("\n" + "="*55)
        print("  ABLATION STUDY SUMMARY")
        print("="*55)
        print(f"  {'Model':<22} {'Accuracy':>10} {'F1':>10}")
        print(f"  {'-'*22} {'-'*10} {'-'*10}")
        for r in results:
            print(f"  {r['model']:<22} {r['accuracy']*100:>9.2f}% {r['f1']:>10.4f}")
        delta_f1 = results[1]["f1"] - results[0]["f1"]
        print(f"\n  Wav2Vec2-BiLSTM improvement over MFCC-BiLSTM: Δ F1 = {delta_f1:+.4f}")
        print("="*55)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--model",
        choices=["mfcc", "wav2vec", "both"],
        default="both",
        help="Which model(s) to train",
    )
    args = parser.parse_args()
    main(run_model=args.model)
