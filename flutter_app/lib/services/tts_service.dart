import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

// Conditional import: web uses dart:html SpeechSynthesis, stub on mobile/desktop.
import 'tts_stub_impl.dart' if (dart.library.html) 'tts_web_impl.dart';
import 'mms_tts_service.dart';

/// Singleton TTS service.
///
/// Priority chain (web):
///   1. MMS-TTS  — facebook/mms-tts-urd-script_arabic via HuggingFace API
///                 Native Urdu voice, trained on Meta MMS dataset.
///                 Requires AiConfig.hfToken to be set.
///   2. Browser  — window.speechSynthesis (hi-IN or ur-PK if available)
///                 Fallback when API token is missing or network fails.
///
/// On mobile/desktop: flutter_tts with ur-PK voice.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  // Mobile only
  FlutterTts? _mobileTts;
  bool _mobileReady = false;

  // ── init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (kIsWeb) {
      await WebTts.init();
    } else {
      await _mobileInit();
    }
  }

  Future<void> reinit() async {
    _mobileReady = false;
    await init();
  }

  Future<void> _mobileInit() async {
    if (_mobileReady) return;
    try {
      _mobileTts ??= FlutterTts();
      await _mobileTts!.setLanguage('ur-PK');
      await _mobileTts!.setSpeechRate(0.45);
      await _mobileTts!.setPitch(1.05);
      await _mobileTts!.setVolume(1.0);
      _mobileReady = true;
      debugPrint('[TTS] mobile ready (ur-PK)');
    } catch (e) {
      debugPrint('[TTS] mobile init error: $e');
      _mobileReady = true;
    }
  }

  // ── speak ─────────────────────────────────────────────────────────────────
  /// Speak [text] in Urdu.
  ///
  /// On web:
  ///   • Tries MMS-TTS (facebook/mms-tts-urd-script_arabic) first.
  ///   • Falls back to browser speechSynthesis if MMS-TTS fails or is not configured.
  Future<void> speak(String text, {VoidCallback? onDone}) async {
    if (text.trim().isEmpty) return;

    if (kIsWeb) {
      // ── Primary: MMS-TTS (real Urdu ML model) ──────────────────────────
      bool played = false;
      if (MmsTtsService.instance.isConfigured) {
        played = await MmsTtsService.instance.speak(text);
      }

      // ── Fallback: browser Web Speech API ────────────────────────────────
      if (!played) {
        await WebTts.speak(text);
        // Estimate completion for onDone callback
        if (onDone != null) {
          final ms = (text.length * 120).clamp(600, 4000);
          Future.delayed(Duration(milliseconds: ms), onDone);
          return;
        }
      }

      onDone?.call();
    } else {
      // ── Mobile: flutter_tts ───────────────────────────────────────────
      if (!_mobileReady) await _mobileInit();
      try {
        await _mobileTts!.stop();
        if (onDone != null) _mobileTts!.setCompletionHandler(onDone);
        await _mobileTts!.speak(text);
      } catch (e) {
        debugPrint('[TTS] mobile speak error: $e');
      }
    }
  }

  // ── stop ──────────────────────────────────────────────────────────────────
  Future<void> stop() async {
    if (kIsWeb) {
      WebTts.stop();
    } else {
      try { await _mobileTts?.stop(); } catch (_) {}
    }
  }
}
