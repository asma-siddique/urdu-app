import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

// Conditional import: uses dart:html on web, stub on mobile/desktop.
import 'tts_stub_impl.dart' if (dart.library.html) 'tts_web_impl.dart';

/// Singleton TTS service.
///
/// On web  → uses dart:html SpeechSynthesis directly (bypasses flutter_tts web
///            which returns null on speak()).
/// On mobile → uses flutter_tts with ur-PK voice.
///
/// IMPORTANT: always call speak() from a user-gesture handler on Chrome.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  // Mobile only
  FlutterTts? _mobileTts;
  bool _mobileReady = false;

  // ── init ──────────────────────────────────────────────────────────────
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
      debugPrint('TtsService mobile ready (ur-PK)');
    } catch (e) {
      debugPrint('TtsService mobile init error: $e');
      _mobileReady = true;
    }
  }

  // ── speak ─────────────────────────────────────────────────────────────
  Future<void> speak(String text, {VoidCallback? onDone}) async {
    if (kIsWeb) {
      await WebTts.speak(text);
      // Web Speech API has no reliable completion callback in this setup;
      // call onDone after an estimated delay based on text length.
      if (onDone != null) {
        final ms = (text.length * 120).clamp(600, 4000);
        Future.delayed(Duration(milliseconds: ms), onDone);
      }
    } else {
      if (!_mobileReady) await _mobileInit();
      try {
        await _mobileTts!.stop();
        if (onDone != null) _mobileTts!.setCompletionHandler(onDone);
        await _mobileTts!.speak(text);
      } catch (e) {
        debugPrint('TtsService.speak error: $e');
      }
    }
  }

  // ── stop ──────────────────────────────────────────────────────────────
  Future<void> stop() async {
    if (kIsWeb) {
      WebTts.stop();
    } else {
      try { await _mobileTts?.stop(); } catch (_) {}
    }
  }
}
