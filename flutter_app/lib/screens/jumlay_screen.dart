import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../data/sentences.dart';
import '../models/urdu_sentence.dart';
import '../providers/app_provider.dart';
// import '../models/user_model.dart';
import '../services/tts_service.dart';
import '../widgets/professor_avatar.dart';
import '../widgets/mic_recorder_widget.dart';

class JumlaySreen extends StatefulWidget {
  const JumlaySreen({super.key});

  @override
  State<JumlaySreen> createState() => _JumlaySreenState();
}

class _JumlaySreenState extends State<JumlaySreen> {
  AvatarEmotion _emotion = AvatarEmotion.neutral;
  late final PageController _pageController;
  int _currentPage = 0;
  int _highlightedWord = -1; // index of word currently highlighted
  Timer? _highlightTimer;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSpeak(SENTENCES[0]);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _highlightTimer?.cancel();
    super.dispose();
  }

  Future<void> _autoSpeak(UrduSentence sentence) async {
    if (_isSpeaking) return;
    setState(() {
      _isSpeaking = true;
      _emotion = AvatarEmotion.thinking;
      _highlightedWord = -1;
    });
    await TtsService.instance.speak(sentence.urdu);
    _startWordHighlight(sentence);
  }

  void _startWordHighlight(UrduSentence sentence) {
    _highlightTimer?.cancel();
    int wordIndex = 0;
    _highlightTimer =
        Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (wordIndex < sentence.words.length) {
        setState(() => _highlightedWord = wordIndex);
        wordIndex++;
      } else {
        timer.cancel();
        setState(() {
          _highlightedWord = -1;
          _isSpeaking = false;
          _emotion = AvatarEmotion.happy;
        });
      }
    });
  }

  void _openMic(BuildContext context, UrduSentence sentence) {
    final expected = sentence.words.join(' ');
    MicRecorderWidget.show(
      context,
      targetText: sentence.urdu,
      targetRoman: sentence.english,
      onScore: (score, transcript) {
        final provider = context.read<AppProvider>();
        provider.recordResult(sentence.urdu, score);
        if (score >= 70) {
          // progress recorded via recordResult above
          setState(() => _emotion = AvatarEmotion.happy);
        } else {
          setState(() => _emotion = AvatarEmotion.sad);
        }
        Navigator.of(context).pop();
        _showScoreBadge(score);
      },
    );
  }

  void _showScoreBadge(double score) {
    final good = score >= 70;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: good ? Colors.green.shade700 : Colors.red.shade700,
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            good
                ? 'شاباش! ${score.toInt()}%'
                : 'دوبارہ کوشش کریں — ${score.toInt()}%',
            style: const TextStyle(
              fontFamily: 'NotoNastaliqUrdu',
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sentence = SENTENCES[_currentPage];

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'جملے',
            style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 22),
          ),
        ),
        backgroundColor: AppTheme.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentPage + 1} / ${SENTENCES.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Avatar + progress ─────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.teal, AppTheme.teal.withOpacity(0.7)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                ProfessorAvatar(emotion: _emotion, size: 80),
                const SizedBox(height: 12),
                // Progress dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(SENTENCES.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: i == _currentPage ? 18 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: i == _currentPage
                            ? Colors.white
                            : Colors.white54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // ── Sentence PageView ─────────────────────────────────────────
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: SENTENCES.length,
              onPageChanged: (i) {
                _highlightTimer?.cancel();
                setState(() {
                  _currentPage = i;
                  _highlightedWord = -1;
                  _isSpeaking = false;
                });
                _autoSpeak(SENTENCES[i]);
              },
              itemBuilder: (ctx, i) {
                return _SentencePage(
                  sentence: SENTENCES[i],
                  highlightedWordIndex:
                      i == _currentPage ? _highlightedWord : -1,
                  onListen: () => _autoSpeak(SENTENCES[i]),
                  onSpeak: () => _openMic(context, SENTENCES[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SentencePage extends StatelessWidget {
  final UrduSentence sentence;
  final int highlightedWordIndex;
  final VoidCallback onListen;
  final VoidCallback onSpeak;

  const _SentencePage({
    required this.sentence,
    required this.highlightedWordIndex,
    required this.onListen,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // ── White card with sentence ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Word-by-word highlighted sentence
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(sentence.words.length, (wi) {
                      final highlighted = wi == highlightedWordIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: highlighted
                              ? AppTheme.purple
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          sentence.words[wi],
                          style: TextStyle(
                            fontFamily: 'NotoNastaliqUrdu',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: highlighted
                                ? Colors.white
                                : AppTheme.navy,
                            height: 1.6,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 16),

                Divider(color: Colors.grey.shade200),

                const SizedBox(height: 12),

                // English translation
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    sentence.english,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Action buttons ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _BigBtn(
                  icon: '🔊',
                  label: 'سنیں',
                  color: AppTheme.teal,
                  onTap: onListen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _BigBtn(
                  icon: '🎤',
                  label: 'بولیں',
                  color: AppTheme.pink,
                  onTap: onSpeak,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'اگلے جملے کے لیے سوائپ کریں ➡',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _BigBtn extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BigBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'NotoNastaliqUrdu',
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}