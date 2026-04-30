// Stub for non-web platforms — dart:html is not available on mobile/desktop.
class WebTts {
  static Future<void> init() async {}
  static Future<void> speak(String text) async {}
  static void stop() {}
}
