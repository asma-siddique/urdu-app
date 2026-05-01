// Web-only TTS — dispatches a CustomEvent that the JS handler in index.html
// picks up. This is the ONLY reliable way to call speechSynthesis from inside
// Flutter's canvas context on Chrome, because dart:js.callMethod() is
// frequently NOT recognised as a user-gesture origin by the browser.
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class WebTts {
  static String _lang = 'hi-IN';
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;

    final synth = html.window.speechSynthesis;
    if (synth == null) {
      debugPrint('WebTts: speechSynthesis not supported');
      _ready = true;
      return;
    }

    // Trigger voice list load — Chrome populates it asynchronously.
    synth.getVoices();

    // Poll up to 3 s for voices to arrive.
    List<html.SpeechSynthesisVoice> voices = [];
    for (int i = 0; i < 15; i++) {
      voices = synth.getVoices();
      if (voices.isNotEmpty) break;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (voices.isNotEmpty) {
      final langs = voices.map((v) => v.lang ?? '').toList();
      debugPrint('WebTts voices: $langs');
      if (langs.contains('ur-PK')) {
        _lang = 'ur-PK';
      } else if (langs.any((l) => l.startsWith('ur'))) {
        _lang = langs.firstWhere((l) => l.startsWith('ur'));
      } else if (langs.contains('hi-IN')) {
        _lang = 'hi-IN';
      } else if (langs.any((l) => l.startsWith('hi'))) {
        _lang = langs.firstWhere((l) => l.startsWith('hi'));
      }
      debugPrint('WebTts selected lang: $_lang');
    }

    _ready = true;
  }

  /// Dispatch a CustomEvent — the listener in index.html calls
  /// window.flutterSpeak() from the main JS thread (Chrome honours that
  /// as a user-gesture context).
  static Future<void> speak(String text) async {
    if (!_ready) await init();

    // Separator must not appear in Urdu text.
    final detail = '$text|||$_lang';
    try {
      final event = html.CustomEvent(
        'urdu-speak',
        canBubble: true,
        cancelable: false,
        detail: detail,
      );
      html.document.dispatchEvent(event);
      debugPrint('WebTts dispatch urdu-speak: "$text" [$_lang]');
    } catch (e) {
      debugPrint('WebTts dispatch error: $e');
    }
  }

  static void stop() {
    try {
      final event = html.CustomEvent(
        'urdu-speak-stop',
        canBubble: true,
        cancelable: false,
      );
      html.document.dispatchEvent(event);
    } catch (_) {
      html.window.speechSynthesis?.cancel();
    }
  }
}
