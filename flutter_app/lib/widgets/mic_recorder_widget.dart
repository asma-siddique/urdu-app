import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/whisper_service.dart';
// Conditional import: real JS interop on web, no-op stub on mobile/desktop
import '../services/web_recorder_stub.dart'
    if (dart.library.html) '../services/web_recorder_web.dart';

/// Pronunciation scorer widget.
///
/// On web (Chrome)   → tries HuggingFace Whisper API first (best Urdu ASR).
///                     Falls back to Web Speech API if Whisper unavailable.
/// On mobile/desktop → uses speech_to_text (Android/iOS native STT).
///
/// Score: 0 if nothing heard. Levenshtein + Urdu phonetic alternatives otherwise.
class MicRecorderWidget extends StatefulWidget {
  final String targetText;   // Urdu text (shown to user)
  final String targetRoman;  // Roman transliteration (used for scoring)
  final Function(double score, String transcript) onScore;

  const MicRecorderWidget({
    Key? key,
    required this.targetText,
    required this.targetRoman,
    required this.onScore,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required String targetText,
    required String targetRoman,
    required Function(double score, String transcript) onScore,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MicRecorderWidget(
        targetText: targetText,
        targetRoman: targetRoman,
        onScore: onScore,
      ),
    );
  }

  @override
  State<MicRecorderWidget> createState() => _MicState();
}

enum _Phase { idle, listening, processing, done }
enum _Engine { whisper, browserStt }

class _MicState extends State<MicRecorderWidget>
    with SingleTickerProviderStateMixin {

  // ── STT (fallback) ─────────────────────────────────────────────────────────
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _sttAvailable = false;

  // ── Whisper (primary on web) ───────────────────────────────────────────────
  late _Engine _engine;
  Completer<Map<String, String?>>? _audioCompleter;

  // ── State ──────────────────────────────────────────────────────────────────
  _Phase _phase = _Phase.idle;
  String _liveWords = '';
  String _finalWords = '';
  double _score = 0;
  String _engineLabel = '';

  Timer? _listenTimer;
  Timer? _barTimer;
  final List<double> _bars = List.filled(22, 0.1);
  final Random _rng = Random();

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  static const _listenSec = 7;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    if (kIsWeb) {
      final whisperReady = WhisperService.instance.isConfigured && webAudioSupported;
      _engine = whisperReady ? _Engine.whisper : _Engine.browserStt;
      _engineLabel = whisperReady ? '✨ Whisper AI' : '🌐 Browser STT';
      if (!whisperReady) _initStt();
    } else {
      _engine = _Engine.browserStt;
      _engineLabel = '📱 Native STT';
      _initStt();
    }
  }

  Future<void> _initStt() async {
    _sttAvailable = await _stt.initialize(
      onError: (e) => debugPrint('[STT] error: $e'),
    );
    if (mounted) setState(() {});
  }

  // ── Start ──────────────────────────────────────────────────────────────────

  Future<void> _start() async {
    setState(() {
      _phase = _Phase.listening;
      _liveWords = '';
      _finalWords = '';
    });

    _pulseCtrl.repeat(reverse: true);
    _barTimer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (mounted && _phase == _Phase.listening) {
        setState(() {
          for (int i = 0; i < _bars.length; i++) {
            _bars[i] = 0.05 + _rng.nextDouble() * 0.95;
          }
        });
      }
    });

    _listenTimer = Timer(const Duration(seconds: _listenSec), _stop);

    if (_engine == _Engine.whisper) {
      _audioCompleter = Completer<Map<String, String?>>();
      webAudioStart((String? b64, String? mime) {
        if (!(_audioCompleter?.isCompleted ?? true)) {
          _audioCompleter!.complete({'audio': b64, 'mime': mime ?? 'audio/webm'});
        }
      });
    } else {
      if (!_sttAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone not available')),
          );
        }
        _listenTimer?.cancel();
        setState(() => _phase = _Phase.idle);
        return;
      }

      final locales = await _stt.locales();
      final localeIds = locales.map((l) => l.localeId).toList();
      String locale = 'en_US';
      for (final id in ['ur_PK', 'ur-PK', 'ur', 'hi_IN', 'hi-IN', 'hi']) {
        if (localeIds.contains(id)) { locale = id; break; }
      }
      debugPrint('[STT] locale: $locale');

      await _stt.listen(
        localeId: locale,
        listenFor: const Duration(seconds: _listenSec),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        onResult: (result) {
          if (mounted) {
            setState(() => _liveWords = result.recognizedWords);
            if (result.finalResult) _finalWords = result.recognizedWords;
          }
        },
      );
    }
  }

  // ── Stop ───────────────────────────────────────────────────────────────────

  Future<void> _stop() async {
    _listenTimer?.cancel();
    _barTimer?.cancel();
    _pulseCtrl.stop();
    if (!mounted) return;

    setState(() {
      _phase = _Phase.processing;
      _bars.fillRange(0, _bars.length, 0.1);
    });

    String heard = '';

    if (_engine == _Engine.whisper) {
      webAudioStop();
      final result = await (_audioCompleter?.future ?? Future.value(<String, String?>{}))
          .timeout(const Duration(seconds: 20), onTimeout: () => {});
      final b64 = result['audio'];
      final mime = result['mime'] ?? 'audio/webm';

      if (b64 != null && b64.isNotEmpty) {
        final transcript = await WhisperService.instance.transcribe(b64, mime);
        heard = (transcript ?? '').trim().toLowerCase();
        debugPrint('[Whisper] heard: "$heard"');
      }
    } else {
      await _stt.stop();
      await Future.delayed(const Duration(milliseconds: 600));
      heard = (_finalWords.isNotEmpty ? _finalWords : _liveWords)
          .trim()
          .toLowerCase();
      debugPrint('[STT] heard: "$heard"');
    }

    // ── Score ────────────────────────────────────────────────────────────────
    double score = 0;
    if (heard.isNotEmpty) {
      final sr = WhisperService.phoneticScore(heard, widget.targetRoman);
      final su = WhisperService.phoneticScore(heard, widget.targetText);
      score = max(sr, su);
    }

    if (mounted) setState(() { _score = score; _phase = _Phase.done; });
    widget.onScore(score, heard);
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  Color get _scoreColor {
    if (_score >= 70) return Colors.green;
    if (_score >= 45) return Colors.orange;
    return Colors.red;
  }

  String get _statusText {
    switch (_phase) {
      case _Phase.idle:       return 'مائیکروفون دبائیں';
      case _Phase.listening:
        if (_engine == _Engine.whisper) return 'ریکارڈنگ جاری ہے...';
        return _liveWords.isNotEmpty ? '"$_liveWords"' : 'بولیں...';
      case _Phase.processing:
        return _engine == _Engine.whisper ? 'Whisper AI تجزیہ...' : 'تجزیہ...';
      case _Phase.done:
        if (_score >= 70) return '🌟 شاباش! تلفظ درست ہے';
        if (_score >= 45) return '🔸 قریب ہے! مزید مشق کریں';
        return '❌ غلط تلفظ — دوبارہ سنیں';
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF97316);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),

          // Engine badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: _engine == _Engine.whisper
                  ? Colors.purple.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _engine == _Engine.whisper
                    ? Colors.purple.shade200 : Colors.grey.shade300,
              ),
            ),
            child: Text(
              _engineLabel,
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: _engine == _Engine.whisper ? Colors.purple : Colors.grey,
              ),
            ),
          ),

          // Target word (Urdu)
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              widget.targetText,
              style: const TextStyle(
                fontFamily: 'NotoNastaliqUrdu',
                fontSize: 38, fontWeight: FontWeight.bold,
                color: Color(0xFF1C1917),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Text(widget.targetRoman,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 16),

          // Waveform
          SizedBox(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(_bars.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                width: 5,
                height: 6 + (_bars[i] * 38),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _phase == _Phase.listening
                      ? accent.withOpacity(0.4 + _bars[i] * 0.6)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
          ),

          const SizedBox(height: 16),

          // Score ring / processing / mic button
          if (_phase == _Phase.done)
            Column(children: [
              SizedBox(
                width: 84, height: 84,
                child: Stack(alignment: Alignment.center, children: [
                  CircularProgressIndicator(
                    value: _score / 100, strokeWidth: 7,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
                  ),
                  Text('${_score.toInt()}%',
                      style: TextStyle(fontSize: 18,
                          fontWeight: FontWeight.w800, color: _scoreColor)),
                ]),
              ),
              const SizedBox(height: 8),
            ])
          else if (_phase == _Phase.processing)
            SizedBox(
              width: 84, height: 84,
              child: Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 36, height: 36,
                    child: CircularProgressIndicator(
                        strokeWidth: 3, color: Colors.deepPurple)),
                  const SizedBox(height: 4),
                  Text(_engine == _Engine.whisper ? 'AI...' : '...',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              )),
            )
          else
            GestureDetector(
              onTap: _phase == _Phase.idle ? _start
                  : (_phase == _Phase.listening ? _stop : null),
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) => Transform.scale(
                  scale: _phase == _Phase.listening ? _pulseAnim.value : 1.0,
                  child: child,
                ),
                child: Container(
                  width: 84, height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _phase == _Phase.listening ? Colors.red : accent,
                    boxShadow: [BoxShadow(
                      color: (_phase == _Phase.listening ? Colors.red : accent)
                          .withOpacity(0.35),
                      blurRadius: 16, spreadRadius: 2,
                    )],
                  ),
                  child: Icon(
                    _phase == _Phase.listening
                        ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white, size: 36,
                  ),
                ),
              ),
            ),

          // Status text
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              _statusText,
              style: TextStyle(
                fontFamily: 'NotoNastaliqUrdu', fontSize: 15,
                color: _phase == _Phase.done ? _scoreColor : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 10),

          // Retry
          if (_phase == _Phase.done)
            TextButton.icon(
              onPressed: () => setState(() {
                _phase = _Phase.idle; _score = 0;
                _liveWords = ''; _finalWords = '';
                _audioCompleter = null;
              }),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('دوبارہ کوشش کریں',
                  style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 15)),
              style: TextButton.styleFrom(foregroundColor: accent),
            ),

          // No-mic warning
          if (_engine == _Engine.browserStt && !_sttAvailable && _phase == _Phase.idle)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Microphone not available — check browser permissions',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                  textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _listenTimer?.cancel();
    _barTimer?.cancel();
    _pulseCtrl.dispose();
    if (_engine == _Engine.browserStt) _stt.stop();
    if (_engine == _Engine.whisper && _phase == _Phase.listening) webAudioStop();
    super.dispose();
  }
}
