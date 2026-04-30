"""
ml/train_nlp.py
===============
Two NLP fine-tuning pipelines for Urdu:

  Task 1 — Grammar Correction  : google/mt5-small   (seq2seq)
  Task 2 — Quiz Generation     : google/flan-t5-base (seq2seq)

Dataset format (JSON Lines, one record per line)
------------------------------------------------
Grammar (data/nlp/grammar_pairs.jsonl):
  {"incorrect": "میں کتاب پڑھتا", "correct": "میں کتاب پڑھتا ہوں"}

Quiz (data/nlp/quiz_pairs.jsonl):
  {"context": "بلی — Cat", "question": "بلی کا انگریزی ترجمہ کیا ہے؟",
   "options": ["Cat","Dog","Bird","Fish"], "answer": "Cat"}

Usage
-----
  python ml/train_nlp.py --task grammar
  python ml/train_nlp.py --task quiz
  python ml/train_nlp.py --task both        # default
"""

import argparse
import json
import os
import random
from pathlib import Path
from typing import Dict, List, Optional

import torch
from datasets import Dataset
from transformers import (
    AutoTokenizer,
    DataCollatorForSeq2Seq,
    MT5ForConditionalGeneration,
    Seq2SeqTrainer,
    Seq2SeqTrainingArguments,
    T5ForConditionalGeneration,
    T5Tokenizer,
    EarlyStoppingCallback,
)
import evaluate

# ── Config ─────────────────────────────────────────────────────────────────────
SEED                 = 42
MT5_MODEL_ID         = "google/mt5-small"
FLAN_T5_MODEL_ID     = "google/flan-t5-base"
GRAMMAR_DATA         = Path("data/nlp/grammar_pairs.jsonl")
QUIZ_DATA            = Path("data/nlp/quiz_pairs.jsonl")
GRAMMAR_OUTPUT_DIR   = "models/urdu-grammar-mt5"
QUIZ_OUTPUT_DIR      = "models/urdu-quiz-flant5"
MAX_SOURCE_LENGTH    = 128
MAX_TARGET_LENGTH    = 128
BATCH_SIZE           = 16
EPOCHS               = 5
LEARNING_RATE        = 5e-4
GRAD_ACCUM_STEPS     = 2
FP16                 = torch.cuda.is_available()

random.seed(SEED)
torch.manual_seed(SEED)


# ── Synthetic data fallback ────────────────────────────────────────────────────
SYNTHETIC_GRAMMAR = [
    {"incorrect": "میں کتاب پڑھتا",              "correct": "میں کتاب پڑھتا ہوں"},
    {"incorrect": "وہ اسکول جاتا",                "correct": "وہ اسکول جاتا ہے"},
    {"incorrect": "بلی چھت پر بیٹھی",             "correct": "بلی چھت پر بیٹھی ہے"},
    {"incorrect": "میری ماں کھانا پکاتی",          "correct": "میری ماں کھانا پکاتی ہے"},
    {"incorrect": "پرندے آسمان میں اڑتے",          "correct": "پرندے آسمان میں اڑتے ہیں"},
    {"incorrect": "سورج صبح طلوع ہوتا",           "correct": "سورج صبح طلوع ہوتا ہے"},
    {"incorrect": "درخت بہت اونچا",               "correct": "درخت بہت اونچا ہے"},
    {"incorrect": "گائے دودھ دیتی",               "correct": "گائے دودھ دیتی ہے"},
    {"incorrect": "میں پانی پیتا",                 "correct": "میں پانی پیتا ہوں"},
    {"incorrect": "بچے باغ میں کھیل رہے",          "correct": "بچے باغ میں کھیل رہے ہیں"},
    {"incorrect": "کتاب میز پر رکھی",             "correct": "کتاب میز پر رکھی ہے"},
    {"incorrect": "وہ تیز دوڑتا",                  "correct": "وہ تیز دوڑتا ہے"},
    {"incorrect": "پھول بہت خوبصورت",             "correct": "پھول بہت خوبصورت ہیں"},
    {"incorrect": "آج موسم بہت اچھا",             "correct": "آج موسم بہت اچھا ہے"},
    {"incorrect": "میرا نام احمد",                 "correct": "میرا نام احمد ہے"},
] * 40   # repeat to get 600 training examples

SYNTHETIC_QUIZ = [
    {"context": "بلی — Cat",     "question": "بلی کا انگریزی ترجمہ کیا ہے؟",    "options": ["Cat","Dog","Bird","Fish"],     "answer": "Cat"},
    {"context": "کتا — Dog",     "question": "کتا کا مطلب کیا ہے؟",              "options": ["Cat","Dog","Horse","Cow"],     "answer": "Dog"},
    {"context": "شیر — Lion",    "question": "شیر کا انگریزی لفظ کیا ہے؟",       "options": ["Tiger","Lion","Bear","Wolf"],  "answer": "Lion"},
    {"context": "آم — Mango",    "question": "آم کا انگریزی ترجمہ کیا ہے؟",      "options": ["Apple","Mango","Grape","Pear"],"answer": "Mango"},
    {"context": "سورج — Sun",    "question": "سورج کو انگریزی میں کیا کہتے ہیں؟","options": ["Moon","Star","Sun","Sky"],     "answer": "Sun"},
    {"context": "پانی — Water",  "question": "پانی کا انگریزی لفظ کیا ہے؟",      "options": ["Fire","Water","Air","Earth"],  "answer": "Water"},
    {"context": "کتاب — Book",   "question": "کتاب کا انگریزی ترجمہ کیا ہے؟",    "options": ["Pen","Book","Table","Chair"],  "answer": "Book"},
    {"context": "گھر — House",   "question": "گھر کو انگریزی میں کیا کہتے ہیں؟", "options": ["School","Home","House","Room"],"answer": "House"},
    {"context": "درخت — Tree",   "question": "درخت کا انگریزی لفظ کیا ہے؟",      "options": ["Flower","Tree","Grass","Leaf"],"answer": "Tree"},
    {"context": "چاند — Moon",   "question": "چاند کو انگریزی میں کیا کہتے ہیں؟","options": ["Moon","Sun","Star","Cloud"],   "answer": "Moon"},
] * 30   # 300 examples


# ── Data loading ───────────────────────────────────────────────────────────────
def load_jsonl(path: Path, fallback: List[Dict]) -> List[Dict]:
    if path.exists():
        records = []
        with open(path) as f:
            for line in f:
                line = line.strip()
                if line:
                    records.append(json.loads(line))
        print(f"[NLP] Loaded {len(records)} records from {path}")
        return records
    else:
        print(f"[NLP] ⚠️  {path} not found — using {len(fallback)} synthetic examples")
        return fallback


# ── Task 1: Grammar Correction ─────────────────────────────────────────────────
def prepare_grammar_dataset(records: List[Dict], tokenizer, split_ratio=0.9):
    """Convert grammar pairs to HuggingFace Dataset with seq2seq format."""
    inputs  = [f"درست کریں: {r['incorrect']}" for r in records]
    targets = [r["correct"] for r in records]

    def tokenize_fn(examples):
        model_inputs = tokenizer(
            examples["input"], max_length=MAX_SOURCE_LENGTH,
            truncation=True, padding="max_length",
        )
        with tokenizer.as_target_tokenizer():
            labels = tokenizer(
                examples["target"], max_length=MAX_TARGET_LENGTH,
                truncation=True, padding="max_length",
            )
        labels_ids = [
            [(t if t != tokenizer.pad_token_id else -100) for t in l]
            for l in labels["input_ids"]
        ]
        model_inputs["labels"] = labels_ids
        return model_inputs

    raw = Dataset.from_dict({"input": inputs, "target": targets})
    raw = raw.shuffle(seed=SEED)
    split = raw.train_test_split(test_size=1 - split_ratio, seed=SEED)
    tokenized = split.map(tokenize_fn, batched=True, remove_columns=["input", "target"])
    return tokenized["train"], tokenized["test"]


def train_grammar():
    print("\n" + "="*55)
    print("  TASK 1 — Grammar Correction (mT5-small)")
    print("="*55)

    records   = load_jsonl(GRAMMAR_DATA, SYNTHETIC_GRAMMAR)
    tokenizer = AutoTokenizer.from_pretrained(MT5_MODEL_ID)
    model     = MT5ForConditionalGeneration.from_pretrained(MT5_MODEL_ID)

    train_ds, eval_ds = prepare_grammar_dataset(records, tokenizer)
    collator = DataCollatorForSeq2Seq(tokenizer, model=model, padding=True)

    bleu_metric = evaluate.load("sacrebleu")

    def compute_metrics(eval_preds):
        preds, labels = eval_preds
        if isinstance(preds, tuple):
            preds = preds[0]
        decoded_preds   = tokenizer.batch_decode(preds,   skip_special_tokens=True)
        labels[labels == -100] = tokenizer.pad_token_id
        decoded_labels  = tokenizer.batch_decode(labels, skip_special_tokens=True)
        decoded_preds   = [p.strip() for p in decoded_preds]
        decoded_labels  = [[l.strip()] for l in decoded_labels]
        result = bleu_metric.compute(predictions=decoded_preds, references=decoded_labels)
        return {"bleu": round(result["score"], 2)}

    args = Seq2SeqTrainingArguments(
        output_dir=GRAMMAR_OUTPUT_DIR,
        num_train_epochs=EPOCHS,
        per_device_train_batch_size=BATCH_SIZE,
        per_device_eval_batch_size=BATCH_SIZE,
        gradient_accumulation_steps=GRAD_ACCUM_STEPS,
        learning_rate=LEARNING_RATE,
        fp16=FP16,
        evaluation_strategy="epoch",
        save_strategy="epoch",
        predict_with_generate=True,
        generation_max_length=MAX_TARGET_LENGTH,
        load_best_model_at_end=True,
        metric_for_best_model="bleu",
        greater_is_better=True,
        logging_steps=10,
        report_to=["tensorboard"],
    )

    trainer = Seq2SeqTrainer(
        model=model,
        args=args,
        train_dataset=train_ds,
        eval_dataset=eval_ds,
        tokenizer=tokenizer,
        data_collator=collator,
        compute_metrics=compute_metrics,
        callbacks=[EarlyStoppingCallback(early_stopping_patience=2)],
    )

    trainer.train()
    metrics = trainer.evaluate()
    print(f"\n[Grammar] BLEU score: {metrics.get('eval_bleu', 'N/A')}")
    trainer.save_model(GRAMMAR_OUTPUT_DIR)
    tokenizer.save_pretrained(GRAMMAR_OUTPUT_DIR)
    print(f"[Grammar] Saved → {GRAMMAR_OUTPUT_DIR}/")
    return metrics


# ── Task 2: Quiz Generation ────────────────────────────────────────────────────
def prepare_quiz_dataset(records: List[Dict], tokenizer, split_ratio=0.9):
    """Format quiz records as instruction prompts for Flan-T5."""

    def format_input(r):
        opts = " | ".join(r["options"])
        return (
            f"Generate Urdu quiz answer.\n"
            f"Context: {r['context']}\n"
            f"Question: {r['question']}\n"
            f"Options: {opts}\n"
            f"Answer:"
        )

    inputs  = [format_input(r) for r in records]
    targets = [r["answer"] for r in records]

    def tokenize_fn(examples):
        model_inputs = tokenizer(
            examples["input"],
            max_length=MAX_SOURCE_LENGTH,
            truncation=True,
            padding="max_length",
        )
        labels = tokenizer(
            examples["target"],
            max_length=64,
            truncation=True,
            padding="max_length",
        )
        labels_ids = [
            [(t if t != tokenizer.pad_token_id else -100) for t in l]
            for l in labels["input_ids"]
        ]
        model_inputs["labels"] = labels_ids
        return model_inputs

    raw = Dataset.from_dict({"input": inputs, "target": targets})
    raw = raw.shuffle(seed=SEED)
    split = raw.train_test_split(test_size=1 - split_ratio, seed=SEED)
    tokenized = split.map(tokenize_fn, batched=True, remove_columns=["input", "target"])
    return tokenized["train"], tokenized["test"]


def train_quiz():
    print("\n" + "="*55)
    print("  TASK 2 — Quiz Generation (Flan-T5-base)")
    print("="*55)

    records   = load_jsonl(QUIZ_DATA, SYNTHETIC_QUIZ)
    tokenizer = T5Tokenizer.from_pretrained(FLAN_T5_MODEL_ID)
    model     = T5ForConditionalGeneration.from_pretrained(FLAN_T5_MODEL_ID)

    train_ds, eval_ds = prepare_quiz_dataset(records, tokenizer)
    collator = DataCollatorForSeq2Seq(tokenizer, model=model, padding=True)

    args = Seq2SeqTrainingArguments(
        output_dir=QUIZ_OUTPUT_DIR,
        num_train_epochs=EPOCHS,
        per_device_train_batch_size=BATCH_SIZE,
        per_device_eval_batch_size=BATCH_SIZE,
        gradient_accumulation_steps=GRAD_ACCUM_STEPS,
        learning_rate=LEARNING_RATE,
        fp16=FP16,
        evaluation_strategy="epoch",
        save_strategy="epoch",
        predict_with_generate=True,
        generation_max_length=64,
        load_best_model_at_end=True,
        metric_for_best_model="eval_loss",
        greater_is_better=False,
        logging_steps=10,
        report_to=["tensorboard"],
    )

    trainer = Seq2SeqTrainer(
        model=model,
        args=args,
        train_dataset=train_ds,
        eval_dataset=eval_ds,
        tokenizer=tokenizer,
        data_collator=collator,
        callbacks=[EarlyStoppingCallback(early_stopping_patience=2)],
    )

    trainer.train()
    metrics = trainer.evaluate()
    print(f"\n[Quiz] Eval loss: {metrics.get('eval_loss', 'N/A'):.4f}")
    trainer.save_model(QUIZ_OUTPUT_DIR)
    tokenizer.save_pretrained(QUIZ_OUTPUT_DIR)
    print(f"[Quiz] Saved → {QUIZ_OUTPUT_DIR}/")
    return metrics


# ── Entry point ────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--task",
        choices=["grammar", "quiz", "both"],
        default="both",
        help="Which NLP task to train",
    )
    args = parser.parse_args()

    if args.task in ("grammar", "both"):
        train_grammar()
    if args.task in ("quiz", "both"):
        train_quiz()

    print("\n[NLP] All tasks complete. Models saved to models/ directory.")
