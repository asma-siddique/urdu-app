import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';

class MicRecorderWidget extends StatefulWidget {
  final String targetText;   // Urdu script  e.g. "بلی"
  final String targetRoman;  // Roman target e.g. "billi"
  final Function(double score, String transcript) onScore;

  const MicRecorderWidget({
    super.key,
    required this.targetText,
    required this.targetRoman,
    required this.onScore,
  });

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
  State<MicRecorderWidget> createState() => _MicRecorderWidgetState();
}

enum _RecState { idle, recording, processing, done }

class _MicRecorderWidgetState extends State<MicRecorderWidget>
    with SingleTickerProviderStateMixin {
  // ── Web: speech_to_text ─────────────────────────────────────────────────
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _sttAvailable = false;
  String _webTranscript = '';

  // ── Mobile: audio recorder ──────────────────────────────────────────────
  final AudioRecorder _recorder = AudioRecorder();

  _RecState _state = _RecState.idle;
  double _score = 0;
  String _transcript = '';
  final List<double> _bars = List.filled(20, 0.1);
  Timer? _recordingTimer;
  Timer? _barTimer;
  final Random _random = Random();
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (kIsWeb) _initStt();
  }

  Future<void> _initStt() async {
    _sttAvailable = await _stt.initialize(
      onError: (e) => debugPrint('STT error: $e'),
    );
    debugPrint('STT available: $_sttAvailable');
  }

  // ── START ────────────────────────────────────────────────────────────────
  Future<void> _start() async {
    if (kIsWeb) {
      await _startWeb();
    } else {
      await _startMobile();
    }
  }

  // Web: use speech_to_text
  Future<void> _startWeb() async {
    if (!_sttAvailable) {
      _sttAvailable = await _stt.initialize();
    }
    if (!_sttAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Microphone not available — check browser permissions')),
        );
      }
      return;
    }
    _webTranscript = '';
    setState(() => _state = _RecState.recording);
    _pulseCtrl.repeat(reverse: true);
    _startBarTimer();

    await _stt.listen(
      localeId: 'ur_PK',   // try Urdu first
      listenFor: const Duration(seconds: 6),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      onResult: (result) {
        _webTranscript = result.recognizedWords;
        debugPrint('STT partial: $_webTranscript');
      },
    );

    // Auto-stop after 6 s
    _recordingTimer = Timer(const Duration(seconds: 6), _stopWeb);
  }

  Future<void> _stopWeb() async {
    _recordingTimer?.cancel();
    _barTimer?.cancel();
    _pulseCtrl.stop();
    await _stt.stop();
    setState(() {
      _state = _RecState.processing;
      for (int i = 0; i < _bars.length; i++) {
        _bars[i] = 0.1;
      }
    });
    await Future.delayed(const Duration(milliseconds: 600));
    _scoreWeb();
  }

  void _scoreWeb() {
    final transcript = _webTranscript.trim().toLowerCase();
    debugPrint('STT final transcript: "$transcript"');

    double score;
    if (transcript.isEmpty) {
      // Nothing heard → 0
      score = 0.0;
    } else {
      // Compare transcript against romanized target
      final roman = widget.targetRoman.toLowerCase();
      final scoreRoman = _levenshteinScore(transcript, roman);

      // Also try matching against Urdu script (STT may return Urdu)
      final urdu = widget.targetText;
      final scoreUrdu = _levenshteinScore(transcript, urdu.toLowerCase());

      // Also try English words that sound similar
      score = [scoreRoman, scoreUrdu].reduce(max);
      debugPrint('Score roman=$scoreRoman urdu=$scoreUrdu → $score');
    }

    setState(() {
      _score = score;
      _transcript = _webTranscript.isEmpty ? '(کچھ نہیں سنا)' : _webTranscript;
      _state = _RecState.done;
    });
    widget.onScore(score, _transcript);
  }

  // Mobile: AudioRecorder → API
  Future<void> _startMobile() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/urdu_rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    setState(() => _state = _RecState.recording);
    _pulseCtrl.repeat(reverse: true);
    _startBarTimer();
    _recordingTimer =
        Timer(const Duration(seconds: 5), _stopMobile);
  }

  Future<void> _stopMobile() async {
    _recordingTimer?.cancel();
    _barTimer?.cancel();
    _pulseCtrl.stop();
    final path = await _recorder.stop();
    setState(() {
      _state = _RecState.processing;
      for (int i = 0; i < _bars.length; i++) {
        _bars[i] = 0.1;
      }
    });
    await _processMobile(path);
  }

  Future<void> _processMobile(String? path) async {
    await Future.delayed(const Duration(milliseconds: 600));
    double score = 0.0;
    String transcript = '';
    if (path != null) {
      try {
        final result = await ApiService.instance.assessPronunciation(
          audioPath: path,
          targetUrdu: widget.targetText,
          targetRoman: widget.targetRoman,
        );
        if (result['error'] == null) {
          score = (result['score'] as num).toDouble();
          transcript = result['transcript'] as String? ?? '';
        }
      } catch (e) {
        debugPrint('Mobile API error: $e');
      }
    }
    setState(() {
      _score = score;
      _transcript = transcript;
      _state = _RecState.done;
    });
    widget.onScore(score, transcript);
  }

  // ── Stop (generic) ───────────────────────────────────────────────────────
  Future<void> _stop() async {
    if (kIsWeb) {
      await _stopWeb();
    } else {
      await _stopMobile();
    }
  }

  void _startBarTimer() {
    _barTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted && _state == _RecState.recording) {
        setState(() {
          for (int i = 0; i < _bars.length; i++) {
            _bars[i] = 0.1 + _random.nextDouble() * 0.9;
          }
        });
      }
    });
  }

  // ── Levenshtein ──────────────────────────────────────────────────────────
  double _levenshteinScore(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 100.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    final d = _levenshtein(a, b);
    final maxLen = max(a.length, b.length);
    return ((1 - d / maxLen) * 100).clamp(0.0, 100.0);
  }

  int _levenshtein(String s, String t) {
    final m = s.length, n = t.length;
    final dp = List.generate(m + 1, (i) => List.filled(n + 1, 0));
    for (int i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= n; j++) {
      dp[0][j] = j;
    }
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        dp[i][j] = s[i - 1] == t[j - 1]
            ? dp[i - 1][j - 1]
            : 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce(min);
      }
    }
    return dp[m][n];
  }

  // ── UI helpers ───────────────────────────────────────────────────────────
  String get _statusText {
    switch (_state) {
      case _RecState.recording:   return 'بولیں...';
      case _RecState.processing:  return 'تجزیہ ہو رہا ہے...';
      case _RecState.done:        return _feedbackText;
      default:                    return 'مائیکروفون دبائیں';
    }
  }

  String get _feedbackText {
    if (_score >= 80) return '🌟 بہت اچھا! تلفظ درست ہے!';
    if (_score >= 60) return '👍 قریب ہے! مزید مشق کریں';
    if (_score > 0)   return '❌ دوبارہ کوشش کریں';
    return '🎤 کچھ نہیں سنا — دوبارہ بولیں';
  }

  Color get _scoreColor {
    if (_score >= 80) return Colors.green.shade600;
    if (_score >= 60) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 44, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),

          // Target word
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(widget.targetText,
                style: const TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 40,
                    fontWeight: FontWeight.bold)),
          ),
          Text(widget.targetRoman,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),

          const SizedBox(height: 20),

          // Waveform bars
          SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_bars.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  width: 6,
                  height: 8 + (_bars[i] * 44),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _state == _RecState.recording
                        ? Colors.red.withOpacity(0.4 + _bars[i] * 0.6)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 20),

          // Score ring or mic button
          if (_state == _RecState.done)
            SizedBox(
              width: 90, height: 90,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _score / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(_scoreColor),
                  ),
                  Text('${_score.toInt()}%',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: _scoreColor)),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: _state == _RecState.idle
                  ? _start
                  : (_state == _RecState.recording ? _stop : null),
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (ctx, child) => Transform.scale(
                  scale: _state == _RecState.recording
                      ? 0.93 + _pulseCtrl.value * 0.12
                      : 1.0,
                  child: child,
                ),
                child: Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _state == _RecState.recording
                        ? Colors.red
                        : _state == _RecState.processing
                            ? Colors.orange
                            : const Color(0xFF7C3AED),
                    boxShadow: [
                      BoxShadow(
                        color: (_state == _RecState.recording
                                ? Colors.red
                                : const Color(0xFF7C3AED))
                            .withOpacity(0.35),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _state == _RecState.processing
                        ? Icons.hourglass_top_rounded
                        : _state == _RecState.recording
                            ? Icons.stop_rounded
                            : Icons.mic_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 14),

          // Status text
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              _statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'NotoNastaliqUrdu',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _state == _RecState.done ? _scoreColor : Colors.black87,
              ),
            ),
          ),

          // Transcript (if we got one)
          if (_state == _RecState.done && _transcript.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('"$_transcript"',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic)),
          ],

          // Try again button
          if (_state == _RecState.done) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {
                _state = _RecState.idle;
                _score = 0;
                _transcript = '';
                _webTranscript = '';
              }),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('دوبارہ کوشش کریں',
                  style: TextStyle(
                      fontFamily: 'NotoNastaliqUrdu', fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _recorder.dispose();
    _stt.cancel();
    _recordingTimer?.cancel();
    _barTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }
}
