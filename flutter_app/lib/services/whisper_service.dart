import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// HuggingFace Whisper-based Urdu ASR service.
///
/// Set [apiKey] to your free HuggingFace API key from https://huggingface.co/settings/tokens
/// Model: openai/whisper-large-v3 — supports Urdu natively.
///
/// Falls back gracefully if network is unavailable.
class WhisperService {
  WhisperService._();
  static final instance = WhisperService._();

  // ── HuggingFace config ─────────────────────────────────────────────────────
  // TODO: Replace with your free HF token from https://huggingface.co/settings/tokens
  static const String apiKey = 'hf_REPLACE_WITH_YOUR_TOKEN';
  static const String _model = 'openai/whisper-large-v3';
  static const String _baseUrl = 'https://api-inference.huggingface.co/models/$_model';

  bool get isConfigured => apiKey.isNotEmpty && !apiKey.contains('REPLACE');

  /// Transcribe raw audio bytes. mimeType = 'audio/webm' (Chrome MediaRecorder default).
  /// Returns the Urdu/Roman transcript or null on failure.
  Future<String?> transcribe(String base64Audio, String mimeType) async {
    if (!isConfigured) {
      debugPrint('[Whisper] No API key configured — set WhisperService.apiKey');
      return null;
    }
    try {
      final bytes = base64Decode(base64Audio);
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': mimeType.isNotEmpty ? mimeType : 'audio/webm',
        },
        body: bytes,
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = data['text'] as String? ?? '';
        debugPrint('[Whisper] transcript: "$text"');
        return text.trim();
      } else if (response.statusCode == 503) {
        debugPrint('[Whisper] model loading, retry in 20s');
        await Future.delayed(const Duration(seconds: 20));
        return transcribe(base64Audio, mimeType);
      } else {
        debugPrint('[Whisper] error ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[Whisper] exception: $e');
      return null;
    }
  }

  // ── Urdu phonetic alternatives ─────────────────────────────────────────────
  // Maps canonical romanization → accepted STT variants (Whisper outputs one of these)
  // These cover common misrecognitions for Urdu letters and words.
  static const Map<String, List<String>> phoneticAlts = {
    // Alphabet letters
    'alif':        ['alef', 'elif', 'a', 'aa', 'آ', 'اَلِف', 'aleph'],
    'alif-mad':    ['alif maddah', 'alif madda', 'aa', 'آ', 'alif mad'],
    'bay':         ['ba', 'b', 'beh', 'ب', 'be'],
    'pay':         ['pa', 'p', 'peh', 'پ', 'pe'],
    'tay':         ['ta', 't', 'teh', 'ت', 'te', 'taa'],
    'ttay':        ['tta', 'ta', 'taa', 'ٹ', 'te', 'teh'],
    'say':         ['sa', 'sey', 'ث', 'seh', 'se', 'thay'],
    'jeem':        ['jim', 'je', 'ج', 'jeh', 'j', 'gym', 'geem'],
    'chay':        ['cha', 'ch', 'چ', 'che', 'cheh'],
    'hay':         ['ha', 'h', 'ح', 'heh', 'he'],
    'khay':        ['kha', 'kh', 'خ', 'khe', 'kheh', 'khe'],
    'daal':        ['dal', 'da', 'd', 'د', 'del', 'daal'],
    'ddaal':       ['dda', 'da', 'ڈ', 'dal', 'dah'],
    'zaal':        ['zal', 'za', 'ذ', 'zel', 'ze'],
    'ray':         ['ra', 'r', 'ر', 'reh', 're'],
    'rray':        ['rra', 'ra', 'ڑ', 'reh'],
    'zay':         ['za', 'z', 'ز', 'zeh', 'ze'],
    'zhay':        ['zha', 'zh', 'ژ', 'jeh'],
    'seen':        ['sin', 's', 'س', 'se', 'sen'],
    'sheen':       ['shin', 'sh', 'ش', 'she', 'shen'],
    'suaad':       ['swad', 'sad', 'ص', 'saad', 'sad'],
    'zuaad':       ['zwad', 'zad', 'ض', 'zaad'],
    'toay':        ['to', 'ta', 'ط', 'toe', 'toa'],
    'zoay':        ['zo', 'za', 'ظ', 'zoe', 'zoa'],
    'ain':         ['ain', 'a', 'ع', 'ayn', 'en'],
    'ghain':       ['ghin', 'gh', 'غ', 'gain', 'ghayn'],
    'fay':         ['fa', 'f', 'ف', 'feh', 'fe'],
    'qaaf':        ['qa', 'q', 'ق', 'qaf', 'kaf'],
    'kaaf':        ['ka', 'k', 'ک', 'keh', 'kaf'],
    'gaaf':        ['ga', 'g', 'گ', 'gaf', 'ge'],
    'laam':        ['la', 'l', 'ل', 'lam', 'lah'],
    'meem':        ['mi', 'm', 'م', 'mim', 'me'],
    'noon':        ['nu', 'n', 'ن', 'nun', 'ne'],
    'noon ghunna': ['noon', 'n', 'ں', 'nasal n'],
    'wow':         ['w', 'و', 'waw', 'vav', 'wao', 'waaw'],
    'hay (do chashmi)': ['ha', 'h', 'ہ', 'heh', 'he'],
    'do-chashmi':  ['do chashmi', 'dochashmi', 'ھ', 'h'],
    'hamza':       ['hum', 'ء', 'hamzah', 'hamza'],
    'choti yay':   ['ya', 'y', 'ے', 'ye', 'yeh', 'choti ye'],
    'bari yay':    ['ya', 'y', 'ی', 'ye', 'yeh', 'bari ye'],
    // Common words
    'billi':       ['bili', 'bily', 'cat', 'بلی'],
    'kutta':       ['kuta', 'dog', 'کتا'],
    'aik':         ['ek', 'one', '1', 'ایک'],
    'do':          ['two', '2', 'dho', 'دو'],
    'teen':        ['three', '3', 'tin', 'تین'],
    'char':        ['four', '4', 'chaar', 'چار'],
    'panch':       ['five', '5', 'punch', 'پانچ'],
    'chay (6)':    ['six', '6', 'ch', 'چھ'],
    'saat':        ['seven', '7', 'sat', 'سات'],
    'aath':        ['eight', '8', 'ath', 'آٹھ'],
    'nau':         ['nine', '9', 'no', 'نو'],
    'das':         ['ten', '10', 'duss', 'دس'],
  };

  /// Score the heard text against a target with Urdu phonetic awareness.
  /// Returns 0–100.
  static double phoneticScore(String heard, String target) {
    if (heard.isEmpty) return 0;
    final h = _clean(heard);
    final t = _clean(target);
    if (h == t) return 100;

    // Direct Levenshtein
    double best = _levScore(h, t);

    // Check phonetic alternatives
    final tLower = target.toLowerCase();
    final alts = phoneticAlts[tLower] ??
        phoneticAlts.entries
            .where((e) => e.key.split(' ').any((w) => tLower.contains(w)))
            .expand((e) => e.value)
            .toList();

    for (final alt in alts) {
      final altScore = _levScore(h, _clean(alt));
      if (altScore > best) best = altScore;
    }

    // Word-level partial credit
    final hWords = h.split(RegExp(r'\s+'));
    final tWords = t.split(RegExp(r'\s+'));
    int matches = 0;
    for (final hw in hWords) {
      for (final tw in tWords) {
        if (_levScore(hw, tw) >= 70) { matches++; break; }
      }
    }
    if (tWords.isNotEmpty) {
      final partial = (matches / tWords.length * 100).clamp(0.0, 100.0);
      if (partial > best) best = partial;
    }

    return best;
  }

  static String _clean(String s) =>
      s.toLowerCase()
       .replaceAll(RegExp(r'[^؀-ۿa-z0-9\s]'), '')
       .replaceAll(RegExp(r'\s+'), ' ')
       .trim();

  static double _levScore(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 100.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    if (a == b) return 100.0;
    final dist = _levenshtein(a, b);
    final maxLen = max(a.length, b.length);
    return ((1.0 - dist / maxLen) * 100.0).clamp(0.0, 100.0);
  }

  static int _levenshtein(String s, String t) {
    final m = s.length, n = t.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (int i = 0; i <= m; i++) dp[i][0] = i;
    for (int j = 0; j <= n; j++) dp[0][j] = j;
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        dp[i][j] = s[i-1] == t[j-1]
            ? dp[i-1][j-1]
            : 1 + [dp[i-1][j], dp[i][j-1], dp[i-1][j-1]].reduce(min);
      }
    }
    return dp[m][n];
  }
}
