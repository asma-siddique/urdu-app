import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'ai_config.dart';

// Conditional import: web uses dart:js Audio element, stub on mobile.
import 'mms_tts_player_stub.dart'
    if (dart.library.html) 'mms_tts_player_web.dart';

/// Text-to-Speech service using Meta's MMS-TTS Urdu model.
///
/// Model : facebook/mms-tts-urd-script_arabic
/// Dataset: Trained on Meta MMS religious audio corpus (1,000+ languages)
/// Paper : Pratap et al., 2023 — https://arxiv.org/abs/2305.13516
///
/// Sends Urdu text → HuggingFace Inference API → receives audio bytes →
/// plays natively in the browser via HTML Audio element.
///
/// Audio is cached in-memory so repeated taps on the same word are instant.
class MmsTtsService {
  MmsTtsService._();
  static final MmsTtsService instance = MmsTtsService._();

  bool get isConfigured => AiConfig.isConfigured;

  // In-memory cache: Urdu text → base64-encoded audio bytes
  final Map<String, String> _cache = {};
  bool _busy = false;

  /// Speak [text] (Urdu script).
  /// Returns true if audio was played successfully, false to trigger fallback.
  Future<bool> speak(String text) async {
    if (!isConfigured || text.trim().isEmpty) return false;
    if (_busy) return false; // don't queue — caller will fallback

    _busy = true;
    try {
      // ── Cache hit ──────────────────────────────────────────────────────
      if (_cache.containsKey(text)) {
        debugPrint('[MMS-TTS] cache hit: "$text"');
        MmsTtsPlayer.play(_cache[text]!, 'audio/flac');
        await Future.delayed(_estimatedDuration(text));
        return true;
      }

      // ── API call ───────────────────────────────────────────────────────
      debugPrint('[MMS-TTS] requesting: "$text"');
      final response = await http.post(
        Uri.parse(AiConfig.mmsTtsEndpoint),
        headers: {
          'Authorization': 'Bearer ${AiConfig.hfToken}',
          'Content-Type': 'application/json',
          'Accept': 'audio/flac',
        },
        body: jsonEncode({'inputs': text}),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        // Detect mime type from response headers (usually audio/flac)
        final mime = response.headers['content-type'] ?? 'audio/flac';
        final b64  = base64Encode(response.bodyBytes);
        _cache[text] = b64; // cache for instant replay
        MmsTtsPlayer.play(b64, mime);
        debugPrint('[MMS-TTS] ✓ playing "${text}" [${response.bodyBytes.length} bytes, $mime]');
        await Future.delayed(_estimatedDuration(text));
        return true;

      } else if (response.statusCode == 503) {
        // HuggingFace is loading the model — wait then retry once
        final msg = jsonDecode(response.body);
        final wait = (msg['estimated_time'] as num?)?.toInt() ?? 10;
        debugPrint('[MMS-TTS] model loading, retry in ${wait}s...');
        await Future.delayed(Duration(seconds: wait.clamp(3, 20)));
        _busy = false;
        return speak(text); // single retry

      } else {
        debugPrint('[MMS-TTS] error ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[MMS-TTS] exception: $e');
      return false;
    } finally {
      _busy = false;
    }
  }

  /// Estimate how long the audio will play so callers can await properly.
  Duration _estimatedDuration(String text) {
    // MMS-TTS generates roughly 100-150ms per Urdu character.
    final ms = (text.length * 130).clamp(800, 6000);
    return Duration(milliseconds: ms);
  }

  /// Pre-warm: fetch audio for [texts] in background before user needs them.
  /// Call this when a lesson screen loads to prefetch the first few cards.
  Future<void> prefetch(List<String> texts) async {
    if (!isConfigured) return;
    for (final t in texts.take(5)) {
      if (!_cache.containsKey(t)) {
        await speak(t); // speak() auto-caches
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }
}
