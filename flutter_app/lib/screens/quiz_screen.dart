import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../data/words.dart';
import '../data/sentences.dart';
import '../data/alphabet.dart';
import '../models/urdu_word.dart';
import '../models/urdu_sentence.dart';
import '../providers/app_provider.dart';
import '../services/tts_service.dart';
import '../widgets/mic_recorder_widget.dart';
import '../screens/lesson_flow_screen.dart' show LessonCard;

// ══════════════════════════════════════════════════════════════════════════════
// Generic quiz card model
// ══════════════════════════════════════════════════════════════════════════════

enum _QKind { multiChoice, speakWord, fillBlank }

class _QuizCard {
  final String mainText;         // Urdu word/letter
  final String name;             // Roman name
  final String transcription;    // English meaning / transcription
  final String emoji;
  final String speakTarget;      // for TTS
  final String romanTarget;      // for mic scoring
  final _QKind kind;
  final List<String> choices;    // for multiChoice / fillBlank
  final int correctIndex;
  final String? blankSentence;   // sentence with ___ for fillBlank

  const _QuizCard({
    required this.mainText,
    required this.name,
    required this.transcription,
    required this.emoji,
    required this.speakTarget,
    required this.romanTarget,
    required this.kind,
    this.choices = const [],
    this.correctIndex = 0,
    this.blankSentence,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// QuizScreen — works for words, letters, sentences
// ══════════════════════════════════════════════════════════════════════════════

class QuizScreen extends StatefulWidget {
  final List<UrduWord>? wordList;
  final String? screenTitle;

  const QuizScreen({super.key, this.wordList, this.screenTitle});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  static const _totalQ = 10;
  static const _accentColor = Color(0xFF8B5CF6); // purple for quizzes

  final Random _rng = Random();
  late List<_QuizCard> _deck;

  int _index = 0;
  int _score = 0;
  int? _chosen;        // which choice was tapped (null = not yet)
  bool _revealed = false;
  double? _speakScore;
  bool _speaking = false;

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _slideAnim = Tween<Offset>(
            begin: const Offset(0.15, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    _buildDeck();
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  // ── Build randomised deck ──────────────────────────────────────────────────

  void _buildDeck() {
    final pool = widget.wordList ?? WORDS;
    final shuffled = List.of(pool)..shuffle(_rng);
    final selected = shuffled.take(_totalQ).toList();

    _deck = selected.asMap().entries.map((e) {
      final i = e.key;
      final w = e.value;
      // Alternate question types
      if (i % 3 == 2) return _makeSpeakCard(w, pool);
      if (i % 3 == 1) return _makeMultiChoice(w, pool);
      return _makeMultiChoice(w, pool);
    }).toList();
  }

  _QuizCard _makeMultiChoice(UrduWord w, List<UrduWord> pool) {
    final others = pool.where((x) => x.urdu != w.urdu).toList()..shuffle(_rng);
    final distractors = others.take(3).map((x) => x.urdu).toList();
    final choices = [w.urdu, ...distractors]..shuffle(_rng);
    return _QuizCard(
      mainText: w.urdu, name: w.roman, transcription: w.english,
      emoji: w.emoji, speakTarget: w.urdu, romanTarget: w.roman,
      kind: _QKind.multiChoice,
      choices: choices,
      correctIndex: choices.indexOf(w.urdu),
    );
  }

  _QuizCard _makeSpeakCard(UrduWord w, List<UrduWord> pool) {
    return _QuizCard(
      mainText: w.urdu, name: w.roman, transcription: w.english,
      emoji: w.emoji, speakTarget: w.urdu, romanTarget: w.roman,
      kind: _QKind.speakWord,
    );
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _goNext() {
    if (_index >= _deck.length - 1) {
      _showResults();
      return;
    }
    setState(() {
      _index++;
      _chosen = null;
      _revealed = false;
      _speakScore = null;
    });
    _slideCtrl.forward(from: 0);
    _speakQuestion();
  }

  void _speakQuestion() =>
      TtsService.instance.speak(_deck[_index].speakTarget);

  // ── Choice tap ─────────────────────────────────────────────────────────────

  void _onChoice(int i) {
    if (_revealed) return;
    final correct = _deck[_index].correctIndex;
    if (i == correct) _score++;
    setState(() { _chosen = i; _revealed = true; });
    context.read<AppProvider>()
        .recordResult(_deck[_index].mainText, i == correct ? 100 : 0);
    TtsService.instance.speak(
        i == correct ? 'شاباش! بہت اچھے!' : 'غلط! دوبارہ کوشش کریں');
  }

  // ── Mic score ──────────────────────────────────────────────────────────────

  void _onSpeakScore(double score) {
    if (score >= 70) _score++;
    setState(() { _speakScore = score; _revealed = true; });
    context.read<AppProvider>()
        .recordResult(_deck[_index].mainText, score);
    TtsService.instance.speak(
        score >= 70 ? 'شاباش! تلفظ درست ہے!' : 'غلط تلفظ — دوبارہ کوشش کریں');
  }

  // ── Results ────────────────────────────────────────────────────────────────

  void _showResults() {
    final pct = _score / _totalQ;
    if (pct >= 0.8) {
      TtsService.instance.speak('بہت اچھے! شاندار کارکردگی!');
    } else if (pct >= 0.5) {
      TtsService.instance.speak('اچھا! مزید مشق کریں');
    } else {
      TtsService.instance.speak('ہمت نہ ہاریں! دوبارہ کوشش کریں');
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _ResultsScreen(
          score: _score,
          total: _totalQ,
          title: widget.screenTitle ?? 'Quiz',
          onRestart: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => QuizScreen(
                    wordList: widget.wordList,
                    screenTitle: widget.screenTitle),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final card = _deck[_index];
    final progress = (_index + 1) / _totalQ;
    final color = _accentColor;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppTheme.bgWarm,
        appBar: AppBar(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.screenTitle ?? 'Quiz',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text('${_index + 1} / $_totalQ  ·  ✓ $_score',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
          actions: [
            IconButton(
              icon: const Icon(Icons.volume_up_rounded),
              onPressed: _speakQuestion,
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 4,
            ),
          ),
        ),
        body: LayoutBuilder(builder: (ctx, bc) {
          final w = bc.maxWidth;
          final isWide = w > 600;
          final cardWidth = isWide ? 480.0 : w - 32;

          return Center(
            child: SizedBox(
              width: cardWidth,
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // ── Question card ─────────────────────────────────────
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnim,
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: _QuizFlashCard(
                          card: card,
                          color: color,
                          chosen: _chosen,
                          revealed: _revealed,
                          speakScore: _speakScore,
                          speaking: _speaking,
                          onChoice: _onChoice,
                          onSpeak: () async {
                            setState(() => _speaking = true);
                            await TtsService.instance.speak(card.speakTarget);
                            if (mounted) setState(() => _speaking = false);
                          },
                          onMic: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => MicRecorderWidget(
                              targetText: card.mainText,
                              targetRoman: card.romanTarget,
                              onScore: (score, _) {
                                Navigator.pop(context);
                                _onSpeakScore(score);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Navigation ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_index > 0)
                          _NavBtn(
                            label: '← Back',
                            color: color.withOpacity(0.15),
                            textColor: color,
                            onTap: () {
                              if (_index > 0) {
                                setState(() {
                                  _index--;
                                  _chosen = null;
                                  _revealed = false;
                                  _speakScore = null;
                                });
                                _slideCtrl.forward(from: 0);
                              }
                            },
                          )
                        else
                          const SizedBox(width: 100),

                        _NavBtn(
                          label: _revealed
                              ? (_index == _totalQ - 1 ? 'Finish ✓' : 'Next →')
                              : 'Skip →',
                          color: _revealed ? color : Colors.grey.shade400,
                          textColor: Colors.white,
                          onTap: _goNext,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Quiz flashcard ─────────────────────────────────────────────────────────────

class _QuizFlashCard extends StatelessWidget {
  final _QuizCard card;
  final Color color;
  final int? chosen;
  final bool revealed;
  final double? speakScore;
  final bool speaking;
  final Function(int) onChoice;
  final VoidCallback onSpeak;
  final VoidCallback onMic;

  const _QuizFlashCard({
    required this.card,
    required this.color,
    required this.chosen,
    required this.revealed,
    required this.speakScore,
    required this.speaking,
    required this.onChoice,
    required this.onSpeak,
    required this.onMic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 7)),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Question prompt ──────────────────────────────────────────
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                card.kind == _QKind.speakWord
                    ? 'یہ لفظ بولیں'
                    : 'یہ کیا ہے؟ اردو میں بتائیں',
                style: TextStyle(fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 16, color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 10),

            // ── Emoji ────────────────────────────────────────────────────
            Text(card.emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 8),

            // ── Speak quiz: show Urdu word too ───────────────────────────
            if (card.kind == _QKind.speakWord) ...[
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(card.mainText,
                    style: TextStyle(
                      fontFamily: 'NotoNastaliqUrdu',
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.2,
                    )),
              ),
              Text(card.name,
                  style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 12),
            ],

            // ── Multiple-choice buttons ───────────────────────────────────
            if (card.kind == _QKind.multiChoice)
              ...List.generate(card.choices.length, (i) {
                Color btnColor = Colors.white;
                Color borderColor = color.withOpacity(0.25);
                Color textColor = const Color(0xFF1C1917);
                if (revealed) {
                  if (i == card.correctIndex) {
                    btnColor = Colors.green.shade50;
                    borderColor = Colors.green;
                    textColor = Colors.green.shade800;
                  } else if (i == chosen) {
                    btnColor = Colors.red.shade50;
                    borderColor = Colors.red;
                    textColor = Colors.red.shade800;
                  }
                } else if (chosen == i) {
                  btnColor = color.withOpacity(0.08);
                  borderColor = color;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => onChoice(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: btnColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Flexible(
                              child: Text(card.choices[i],
                                  style: TextStyle(
                                    fontFamily: 'NotoNastaliqUrdu',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  )),
                            ),
                          ),
                          if (revealed && i == card.correctIndex)
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.green, size: 22),
                          if (revealed && i == chosen && i != card.correctIndex)
                            const Icon(Icons.cancel_rounded,
                                color: Colors.red, size: 22),
                        ],
                      ),
                    ),
                  ),
                );
              }),

            // ── Speak question: mic button ────────────────────────────────
            if (card.kind == _QKind.speakWord) ...[
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _CircBtn(icon: Icons.volume_up_rounded,
                    color: color, filled: speaking, onTap: onSpeak),
                const SizedBox(width: 16),
                _CircBtn(icon: Icons.mic_rounded,
                    color: const Color(0xFF8B5CF6),
                    filled: false, onTap: revealed ? null : onMic),
              ]),
              if (speakScore != null) ...[
                const SizedBox(height: 12),
                _ScoreBadge(score: speakScore!),
              ],
            ],

            // ── Correct answer reveal ─────────────────────────────────────
            if (revealed && card.kind == _QKind.multiChoice &&
                chosen != null && chosen != card.correctIndex) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    'درست جواب: ${card.choices[card.correctIndex]}  (${card.transcription})',
                    style: const TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: 15, color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final double score;
  const _ScoreBadge({required this.score});

  Color get _color {
    if (score >= 70) return Colors.green;
    if (score >= 45) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(width: 38, height: 38,
        child: Stack(alignment: Alignment.center, children: [
          CircularProgressIndicator(
            value: score / 100, strokeWidth: 4,
            backgroundColor: _color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(_color),
          ),
          Text('${score.toInt()}',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                  color: _color)),
        ]),
      ),
      const SizedBox(width: 8),
      Text(score >= 70 ? '🌟 شاباش!' : score >= 45 ? '🔸 قریب!' : '❌ غلط',
          style: TextStyle(fontFamily: 'NotoNastaliqUrdu',
              fontSize: 14, fontWeight: FontWeight.w700, color: _color)),
    ]);
  }
}

class _CircBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;
  const _CircBtn({required this.icon, required this.color,
      required this.filled, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 52, height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onTap == null
            ? Colors.grey.shade200
            : filled ? color : color.withOpacity(0.1),
        border: Border.all(
            color: onTap == null ? Colors.grey.shade300 : color, width: 2),
      ),
      child: Icon(icon,
          color: onTap == null
              ? Colors.grey
              : filled ? Colors.white : color,
          size: 24),
    ),
  );
}

class _NavBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  const _NavBtn({required this.label, required this.color,
      required this.textColor, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
      decoration: BoxDecoration(color: color,
          borderRadius: BorderRadius.circular(30)),
      child: Text(label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
              color: textColor)),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// Sentence fill-in-blank quiz
// ══════════════════════════════════════════════════════════════════════════════

class SentenceQuizScreen extends StatefulWidget {
  const SentenceQuizScreen({super.key});
  @override
  State<SentenceQuizScreen> createState() => _SentenceQuizState();
}

class _SentenceQuizState extends State<SentenceQuizScreen>
    with SingleTickerProviderStateMixin {
  static const _total = 10;
  static const _color = Color(0xFF10B981); // emerald

  final Random _rng = Random();
  late List<_FillCard> _deck;

  int _index = 0, _score = 0;
  int? _chosen;
  bool _revealed = false;

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _slideAnim = Tween<Offset>(
            begin: const Offset(0.15, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    _buildDeck();
    _slideCtrl.forward();
    _speakCurrent();
  }

  @override
  void dispose() { _slideCtrl.dispose(); super.dispose(); }

  void _buildDeck() {
    final shuffled = List.of(SENTENCES)..shuffle(_rng);
    _deck = shuffled.take(_total).map((s) {
      final blank = s.blankWord;
      final others = s.words.where((w) => w != blank).toList()..shuffle(_rng);
      final distractors = others.take(3).toList();
      // fill to 4 choices
      if (distractors.length < 3) {
        final extra = WORDS.where((w) => !distractors.contains(w.urdu))
            .toList()..shuffle(_rng);
        while (distractors.length < 3) distractors.add(extra[distractors.length].urdu);
      }
      final choices = [blank, ...distractors.take(3)]..shuffle(_rng);
      return _FillCard(
        sentence: s.urdu,
        blank: blank,
        english: s.english,
        choices: choices,
        correctIndex: choices.indexOf(blank),
      );
    }).toList();
  }

  void _speakCurrent() {
    final card = _deck[_index];
    final spoken = card.sentence.replaceFirst(card.blank, '۔۔۔');
    TtsService.instance.speak('خالی جگہ بھریں: $spoken');
  }

  void _onChoice(int i) {
    if (_revealed) return;
    if (i == _deck[_index].correctIndex) _score++;
    setState(() { _chosen = i; _revealed = true; });
    TtsService.instance.speak(
        i == _deck[_index].correctIndex ? 'شاباش! بہت اچھے!' : 'غلط!');
  }

  void _goNext() {
    if (_index >= _deck.length - 1) {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => _ResultsScreen(
          score: _score, total: _total,
          title: 'Sentence Quiz',
          onRestart: () => Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const SentenceQuizScreen())),
        )),
      );
      return;
    }
    setState(() {
      _index++; _chosen = null; _revealed = false;
    });
    _slideCtrl.forward(from: 0);
    _speakCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final card = _deck[_index];
    final progress = (_index + 1) / _total;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppTheme.bgWarm,
        appBar: AppBar(
          backgroundColor: _color,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Sentence Quiz',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text('${_index + 1} / $_total  ·  ✓ $_score',
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ]),
          actions: [
            IconButton(icon: const Icon(Icons.volume_up_rounded),
                onPressed: _speakCurrent),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 4,
            ),
          ),
        ),
        body: LayoutBuilder(builder: (ctx, bc) {
          final cardWidth = bc.maxWidth > 600 ? 480.0 : bc.maxWidth - 32;
          return Center(
            child: SizedBox(
              width: cardWidth,
              child: Column(children: [
                const SizedBox(height: 16),
                Expanded(
                  child: SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(
                            color: _color.withOpacity(0.12),
                            blurRadius: 18, offset: const Offset(0, 7),
                          )],
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            // ── Label ───────────────────────────────────
                            Directionality(textDirection: TextDirection.rtl,
                              child: Text('خالی جگہ بھریں',
                                  style: TextStyle(fontFamily: 'NotoNastaliqUrdu',
                                      fontSize: 16, color: Colors.grey[500]))),
                            const SizedBox(height: 12),
                            const Text('💬', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),

                            // ── Sentence with blank ──────────────────────
                            Directionality(textDirection: TextDirection.rtl,
                              child: RichText(
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                                text: TextSpan(
                                  style: const TextStyle(
                                      fontFamily: 'NotoNastaliqUrdu',
                                      fontSize: 24,
                                      color: Color(0xFF1C1917),
                                      height: 1.8),
                                  children: _buildSentenceSpan(card),
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),
                            Text(card.english,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 20),

                            // ── 4 choices ────────────────────────────────
                            ...List.generate(card.choices.length, (i) {
                              Color btnColor = Colors.white;
                              Color borderColor = _color.withOpacity(0.25);
                              Color textColor = const Color(0xFF1C1917);
                              if (_revealed) {
                                if (i == card.correctIndex) {
                                  btnColor = Colors.green.shade50;
                                  borderColor = Colors.green;
                                  textColor = Colors.green.shade800;
                                } else if (i == _chosen) {
                                  btnColor = Colors.red.shade50;
                                  borderColor = Colors.red;
                                  textColor = Colors.red.shade800;
                                }
                              }
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GestureDetector(
                                  onTap: () => _onChoice(i),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: btnColor,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: borderColor, width: 2),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Directionality(
                                          textDirection: TextDirection.rtl,
                                          child: Text(card.choices[i],
                                              style: TextStyle(
                                                fontFamily: 'NotoNastaliqUrdu',
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: textColor,
                                              )),
                                        ),
                                        if (_revealed &&
                                            i == card.correctIndex)
                                          const Icon(Icons.check_circle_rounded,
                                              color: Colors.green, size: 20),
                                        if (_revealed &&
                                            i == _chosen &&
                                            i != card.correctIndex)
                                          const Icon(Icons.cancel_rounded,
                                              color: Colors.red, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Nav row ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 100),
                      _NavBtn(
                        label: _revealed
                            ? (_index == _total - 1 ? 'Finish ✓' : 'Next →')
                            : 'Skip →',
                        color: _revealed ? _color : Colors.grey.shade400,
                        textColor: Colors.white,
                        onTap: _goNext,
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          );
        }),
      ),
    );
  }

  List<InlineSpan> _buildSentenceSpan(_FillCard card) {
    final parts = card.sentence.split(card.blank);
    final spans = <InlineSpan>[];
    for (int i = 0; i < parts.length; i++) {
      if (i > 0) {
        final fill = _revealed ? card.blank : '______';
        final fillColor = _revealed ? _color : Colors.grey.shade600;
        spans.add(TextSpan(
          text: fill,
          style: TextStyle(
            fontFamily: 'NotoNastaliqUrdu',
            fontWeight: FontWeight.bold,
            color: fillColor,
            decoration: TextDecoration.underline,
          ),
        ));
      }
      if (parts[i].isNotEmpty) spans.add(TextSpan(text: parts[i]));
    }
    return spans;
  }
}

class _FillCard {
  final String sentence;
  final String blank;
  final String english;
  final List<String> choices;
  final int correctIndex;
  const _FillCard({
    required this.sentence,
    required this.blank,
    required this.english,
    required this.choices,
    required this.correctIndex,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared results screen
// ══════════════════════════════════════════════════════════════════════════════

class _ResultsScreen extends StatelessWidget {
  final int score;
  final int total;
  final String title;
  final VoidCallback onRestart;

  const _ResultsScreen({
    required this.score,
    required this.total,
    required this.title,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final pct = score / total;
    final stars = pct >= 0.8 ? 3 : pct >= 0.5 ? 2 : 1;
    final color = pct >= 0.8
        ? Colors.green
        : pct >= 0.5
            ? Colors.orange
            : Colors.red;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppTheme.bgWarm,
        appBar: AppBar(
          backgroundColor: const Color(0xFF8B5CF6),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text('Results',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('⭐' * stars, style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 16),
              Text(
                '$score / $total',
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900,
                    color: color),
              ),
              const SizedBox(height: 8),
              Directionality(textDirection: TextDirection.rtl,
                child: Text(
                  stars == 3 ? 'بہت اچھے! شاندار! 🎉'
                      : stars == 2 ? 'اچھا! مزید مشق کریں 💪'
                      : 'ہمت نہ ہاریں! دوبارہ کوشش کریں 📚',
                  style: TextStyle(fontFamily: 'NotoNastaliqUrdu',
                      fontSize: 20, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                ElevatedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.popUntil(
                      context, (r) => r.isFirst),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Home',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8B5CF6),
                    side: const BorderSide(
                        color: Color(0xFF8B5CF6), width: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
