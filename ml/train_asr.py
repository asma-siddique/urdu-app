"""
ml/train_asr.py
===============
Fine-tune openai/whisper-small on Mozilla Common Voice 13 — Urdu split.
Target: WER < 25% on the test set.

Usage
-----
  pip install transformers datasets evaluate jiwer accelerate torch torchaudio
  python ml/train_asr.py

  # Push to HuggingFace Hub after training:
  python ml/train_asr.py --push_to_hub --hub_model_id YOUR_HF_USERNAME/urdu-asr-whisper

Environment variables
---------------------
  HF_TOKEN  – HuggingFace token (required for --push_to_hub)
"""

import argparse
import os
import re
from dataclasses import dataclass
from typing import Any, Dict, List, Union

import evaluate
import numpy as np
import torch
from datasets import Audio, DatasetDict, load_dataset
from transformers import (
    EarlyStoppingCallback,
    Seq2SeqTrainer,
    Seq2SeqTrainingArguments,
    WhisperFeatureExtractor,
    WhisperForConditionalGeneration,
    WhisperProcessor,
    WhisperTokenizer,
)

# ── Config ─────────────────────────────────────────────────────────────────────
MODEL_ID          = "openai/whisper-small"
LANGUAGE          = "Urdu"
TASK              = "transcribe"
DATASET_NAME      = "mozilla-foundation/common_voice_13_0"
DATASET_CONFIG    = "ur"          # Urdu locale
SAMPLING_RATE     = 16_000
OUTPUT_DIR        = "models/whisper-urdu-asr"
MAX_STEPS         = 4000
BATCH_SIZE        = 16
GRAD_ACCUM_STEPS  = 2
LEARNING_RATE     = 1e-5
WARMUP_STEPS      = 500
SAVE_STEPS        = 500
EVAL_STEPS        = 500
LOGGING_STEPS     = 25
FP16              = torch.cuda.is_available()


# ── Helpers ────────────────────────────────────────────────────────────────────
def clean_urdu_text(text: str) -> str:
    """Strip non-Urdu characters and normalise whitespace."""
    text = re.sub(r"[^؀-ۿݐ-ݿﭐ-﷿ﹰ-﻿\s]", "", text)
    return re.sub(r"\s+", " ", text).strip()


# ── Dataset ────────────────────────────────────────────────────────────────────
def load_urdu_dataset() -> DatasetDict:
    print("[ASR] Loading Mozilla Common Voice 13 — Urdu…")
    ds = load_dataset(
        DATASET_NAME,
        DATASET_CONFIG,
        split={"train": "train", "validation": "validation", "test": "test"},
        trust_remote_code=True,
    )
    for split in ds:
        drop = [c for c in ds[split].column_names if c not in {"audio", "sentence"}]
        ds[split] = ds[split].remove_columns(drop)
    ds = ds.cast_column("audio", Audio(sampling_rate=SAMPLING_RATE))
    return ds


def make_prepare_fn(feature_extractor, tokenizer):
    def prepare(batch):
        audio = batch["audio"]
        batch["input_features"] = feature_extractor(
            audio["array"],
            sampling_rate=audio["sampling_rate"],
            return_tensors="np",
        ).input_features[0]
        batch["labels"] = tokenizer(clean_urdu_text(batch["sentence"])).input_ids
        return batch
    return prepare


# ── Data collator ──────────────────────────────────────────────────────────────
@dataclass
class DataCollatorSpeechSeq2SeqWithPadding:
    processor: Any
    decoder_start_token_id: int

    def __call__(self, features: List[Dict[str, Union[List[int], torch.Tensor]]]) -> Dict[str, torch.Tensor]:
        input_features = [{"input_features": f["input_features"]} for f in features]
        batch = self.processor.feature_extractor.pad(input_features, return_tensors="pt")

        label_features = [{"input_ids": f["labels"]} for f in features]
        labels_batch = self.processor.tokenizer.pad(label_features, return_tensors="pt")
        labels = labels_batch["input_ids"].masked_fill(labels_batch.attention_mask.ne(1), -100)

        # Strip BOS token if present
        if (labels[:, 0] == self.decoder_start_token_id).all().cpu().item():
            labels = labels[:, 1:]
        batch["labels"] = labels
        return batch


# ── Metrics ────────────────────────────────────────────────────────────────────
def build_compute_metrics(tokenizer):
    wer_metric = evaluate.load("wer")

    def compute_metrics(pred):
        pred_ids   = pred.predictions
        label_ids  = pred.label_ids
        label_ids[label_ids == -100] = tokenizer.pad_token_id
        pred_str   = tokenizer.batch_decode(pred_ids,  skip_special_tokens=True)
        label_str  = tokenizer.batch_decode(label_ids, skip_special_tokens=True)
        return {"wer": round(100 * wer_metric.compute(predictions=pred_str, references=label_str), 2)}

    return compute_metrics


# ── Training ───────────────────────────────────────────────────────────────────
def train(push_to_hub: bool = False, hub_model_id: str = ""):
    print(f"[ASR] Loading model: {MODEL_ID}")
    feature_extractor = WhisperFeatureExtractor.from_pretrained(MODEL_ID)
    tokenizer  = WhisperTokenizer.from_pretrained(MODEL_ID, language=LANGUAGE, task=TASK)
    processor  = WhisperProcessor.from_pretrained(MODEL_ID,  language=LANGUAGE, task=TASK)
    model      = WhisperForConditionalGeneration.from_pretrained(MODEL_ID)

    model.generation_config.language = LANGUAGE.lower()
    model.generation_config.task = TASK
    model.generation_config.forced_decoder_ids = None

    ds = load_urdu_dataset()

    print("[ASR] Preprocessing…")
    prepare_fn = make_prepare_fn(feature_extractor, tokenizer)
    ds = ds.map(prepare_fn, remove_columns=ds["train"].column_names, num_proc=4)

    collator = DataCollatorSpeechSeq2SeqWithPadding(
        processor=processor,
        decoder_start_token_id=model.config.decoder_start_token_id,
    )

    args = Seq2SeqTrainingArguments(
        output_dir=OUTPUT_DIR,
        per_device_train_batch_size=BATCH_SIZE,
        gradient_accumulation_steps=GRAD_ACCUM_STEPS,
        learning_rate=LEARNING_RATE,
        warmup_steps=WARMUP_STEPS,
        max_steps=MAX_STEPS,
        gradient_checkpointing=True,
        fp16=FP16,
        evaluation_strategy="steps",
        per_device_eval_batch_size=8,
        predict_with_generate=True,
        generation_max_length=225,
        save_steps=SAVE_STEPS,
        eval_steps=EVAL_STEPS,
        logging_steps=LOGGING_STEPS,
        report_to=["tensorboard"],
        load_best_model_at_end=True,
        metric_for_best_model="wer",
        greater_is_better=False,
        push_to_hub=push_to_hub,
        hub_model_id=hub_model_id if push_to_hub else None,
    )

    trainer = Seq2SeqTrainer(
        args=args,
        model=model,
        train_dataset=ds["train"],
        eval_dataset=ds["validation"],
        data_collator=collator,
        compute_metrics=build_compute_metrics(tokenizer),
        tokenizer=processor.feature_extractor,
        callbacks=[EarlyStoppingCallback(early_stopping_patience=3)],
    )

    print("[ASR] Training started…")
    trainer.train()

    print("[ASR] Evaluating on test set…")
    metrics = trainer.evaluate(ds["test"])
    wer = metrics.get("eval_wer", 999)
    print(f"\n[ASR] ── Test Results ──────────────────────────")
    print(f"  WER : {wer:.2f}%  (target < 25%)")
    print(f"  Loss: {metrics.get('eval_loss', 0):.4f}")
    print(f"  {'✅ PASS' if wer < 25 else '⚠️  FAIL — increase MAX_STEPS or reduce LR'}")
    print(f"────────────────────────────────────────────────")

    trainer.save_model(OUTPUT_DIR)
    processor.save_pretrained(OUTPUT_DIR)
    print(f"[ASR] Saved → {OUTPUT_DIR}/")

    if push_to_hub:
        trainer.push_to_hub()
        print(f"[ASR] Pushed to Hub → {hub_model_id}")

    return metrics


# ── Entry point ────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--push_to_hub",   action="store_true")
    parser.add_argument("--hub_model_id",  type=str, default="")
    args = parser.parse_args()

    if args.push_to_hub:
        token = os.environ.get("HF_TOKEN")
        if not token:
            raise EnvironmentError("Set HF_TOKEN env var to push to Hub.")
        from huggingface_hub import login
        login(token=token)

    train(push_to_hub=args.push_to_hub, hub_model_id=args.hub_model_id)
