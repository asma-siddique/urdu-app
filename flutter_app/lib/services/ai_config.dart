/// ============================================================
///  AI Models & Dataset Configuration — Urdu Learning App FYP
/// ============================================================
///
///  Dataset
///  -------
///  Mozilla Common Voice 17.0 — Urdu subset
///  Source : https://huggingface.co/datasets/mozilla-foundation/common_voice_17_0
///  Lang   : ur (Urdu)
///  Used for:
///    • Vocabulary word lists (animals, fruits, body parts, sentences)
///    • ASR evaluation — compute Word Error Rate (WER) of Whisper on
///      Common Voice Urdu test split
///
///  Models
///  ------
///  1. openai/whisper-large-v3  (Automatic Speech Recognition)
///     Paper : "Robust Speech Recognition via Large-Scale Weak Supervision"
///             Radford et al., 2022  — https://arxiv.org/abs/2212.04356
///     Data  : 680 000 hours of labelled audio (99 languages, incl. Urdu)
///     Use   : Transcribes the student's microphone recording →
///             compared against target word → pronunciation score 0-100
///
///  2. facebook/mms-tts-urd-script_arabic  (Text-to-Speech, Urdu)
///     Paper : "Scaling Speech Technology to 1,000+ Languages"
///             Pratap et al., 2023 — https://arxiv.org/abs/2305.13516
///     Data  : Meta MMS dataset — religious audio in 1 000+ languages
///     Use   : Speaker button → sends Urdu text → returns native audio
///
///  Setup
///  -----
///  1. Create a FREE HuggingFace account at https://huggingface.co
///  2. Go to https://huggingface.co/settings/tokens → New token (read)
///  3. Paste it below as [hfToken]

class AiConfig {
  AiConfig._();

  // ── HuggingFace token ────────────────────────────────────────────────────
  // Replace with your token — one token works for BOTH models.
  static const String hfToken = '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';

  static bool get isConfigured =>
      hfToken.isNotEmpty && !hfToken.contains('REPLACE');

  // ── Model 1: Whisper Large V3 — ASR ─────────────────────────────────────
  static const String whisperModel    = 'openai/whisper-large-v3';
  static const String whisperEndpoint =
      'https://api-inference.huggingface.co/models/$whisperModel';

  // ── Model 2: MMS-TTS Urdu — TTS ─────────────────────────────────────────
  static const String mmsTtsModel    = 'facebook/mms-tts-urd-script_arabic';
  static const String mmsTtsEndpoint =
      'https://api-inference.huggingface.co/models/$mmsTtsModel';

  // ── Dataset ──────────────────────────────────────────────────────────────
  static const String datasetName    = 'mozilla-foundation/common_voice_17_0';
  static const String datasetLang    = 'ur';
  static const String datasetUrl     =
      'https://huggingface.co/datasets/$datasetName';
}
