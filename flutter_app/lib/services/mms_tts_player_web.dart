// Web-only — compiled only when dart.library.html is available.
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

class MmsTtsPlayer {
  /// Plays audio bytes (base64-encoded) via the JS Audio API.
  /// mimeType is typically 'audio/flac' (MMS-TTS) or 'audio/wav'.
  static void play(String base64Audio, String mimeType) {
    try {
      js.context.callMethod('playUrduAudio', [base64Audio, mimeType]);
    } catch (e) {
      debugPrint('[MmsTtsPlayer] JS call error: $e');
    }
  }
}
