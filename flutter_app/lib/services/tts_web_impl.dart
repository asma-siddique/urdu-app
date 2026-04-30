// Web-only — compiled only when dart.library.html is available.
import 'dart:html' as html;
import 'dart:js' as js;
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

    // Chrome loads voices asynchronously — poll until available (up to ~3 s).
    List<html.SpeechSynthesisVoice> voices = [];
    for (int i = 0; i < 10; i++) {
      voices = synth.getVoices();
      if (voices.isNotEmpty) break;
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (voices.isEmpty) {
      debugPrint('WebTts: no voices found, defaulting to hi-IN');
      _ready = true;
      return;
    }

    final langs = voices.map((v) => v.lang ?? '').toList();
    debugPrint('WebTts available voices: $langs');

    // Preference: ur-PK → any ur-* → hi-IN → any hi-* → en-US
    if (langs.contains('ur-PK')) {
      _lang = 'ur-PK';
    } else if (langs.any((l) => l.startsWith('ur'))) {
      _lang = langs.firstWhere((l) => l.startsWith('ur'));
    } else if (langs.contains('hi-IN')) {
      _lang = 'hi-IN';
    } else if (langs.any((l) => l.startsWith('hi'))) {
      _lang = langs.firstWhere((l) => l.startsWith('hi'));
    } else {
      _lang = 'en-US';
    }

    debugPrint('WebTts selected lang: $_lang');
    _ready = true;
  }

  /// Speak by calling window.flutterSpeak() defined in index.html.
  /// That function runs in JS context and correctly handles Chrome's
  /// silent-pause bug with cancel→resume→speak pattern.
  static Future<void> speak(String text) async {
    if (!_ready) await init();
    try {
      // Call the JS function we injected in index.html
      js.context.callMethod('flutterSpeak', [text, _lang]);
      debugPrint('WebTts.speak → "$text" [$_lang]');
    } catch (e) {
      // Fallback: use dart:html directly
      debugPrint('WebTts js fallback: $e');
      try {
        final synth = html.window.speechSynthesis;
        if (synth == null) return;
        synth.cancel();
        final u = html.SpeechSynthesisUtterance(text);
        u.lang = _lang;
        u.rate = 0.80;
        u.volume = 1.0;
        synth.resume();
        synth.speak(u);
      } catch (e2) {
        debugPrint('WebTts fallback error: $e2');
      }
    }
  }

  static void stop() {
    try {
      js.context.callMethod('flutterSpeakStop', []);
    } catch (_) {
      html.window.speechSynthesis?.cancel();
    }
  }
}
