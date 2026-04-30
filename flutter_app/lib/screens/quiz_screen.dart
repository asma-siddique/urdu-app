import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../data/words.dart';
import '../data/sentences.dart';
import '../models/urdu_word.dart';
import '../models/urdu_sentence.dart';
import '../providers/app_provider.dart';
import '../services/tts_service.dart';
import '../widgets/professor_avatar.dart';
import '../widgets/mic_recorder_widget.dart';

// ── Enums ──────────────────────────────────────────────────────────────────
enum _Phase { loading, question, correct, wrong, results }

enum _Difficulty { easy, medium, hard }

enum _QType { imageToUrdu, urduToEnglish, fillBlank, speakWord }

// ── Question model ─────────────────────────────────────────────────────────
class _Question {
  final UrduWord word;
  final _QType type;
  final List<String> choices; // shown to user
  final int correctIndex;
  final UrduSentence? sentence; // only for fillBlank

  const _Question({
    required this.word,
    required this.type,
    required this.choices,
    required this.correctIndex,
    this.sentence,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
class QuizScreen extends StatefulWidget {
  /// Optional custom word pool (e.g. animals, fruits, colors).
  /// Falls back to the global WORDS list when null.
  final List<UrduWord>? wordList;
  final String? screenTitle;

  const QuizScreen({super.key, this.wordList, this.screenTitle});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with TickerProviderStateMixin {
  // ── Config ──────────────────────────────────────────────────────────────
  static const int _totalQ = 10;

  // ── Adaptive difficulty ─────────────────────────────────────────────────
  _Difficulty _difficulty = _Difficulty.easy;
  int _streakCorrect = 0;
  int _streakWrong = 0;

  // ── Quiz state ──────────────────────────────────────────────────────────
  _Phase _phase = _Phase.loading;
  int _qNum = 0;
  int _score = 0;
  late _Question _current;
  int? _selectedIndex;       // which button user tapped
  bool _tryAgain = false;    // user is retrying after wrong
  double? _speakScore;       // pronunciation accuracy (0–100) from mic

  // ── Avatar ──────────────────────────────────────────────────────────────
  AvatarEmotion _emotion = AvatarEmotion.neutral;

  // ── Animation ───────────────────────────────────────────────────────────
  late AnimationController _feedbackCtrl;
  late Animation<double> _feedbackScale;
  late AnimationController _starCtrl;

  final Random _rng = Random();

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _feedbackCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _feedbackScale = CurvedAnimation(
        parent: _feedbackCtrl, curve: Curves.elasticOut);
    _starCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    WidgetsBinding.instance.addPostFrameCallback((_) => _nextQuestion());
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    _starCtrl.dispose();
    super.dispose();
  }

  // ── Word pool — weighted toward weak items ──────────────────────────────
  List<UrduWord> _buildPool() {
    final provider = context.read<AppProvider>();
    final weakIds = provider.weakestItems(10).toSet();
    final allWords = widget.wordList ?? WORDS;

    // Filter by difficulty level
    final levelStr = _difficulty == _Difficulty.easy
        ? 'easy'
        : _difficulty == _Difficulty.medium
            ? 'medium'
            : 'hard';

    var levelWords = allWords.where((w) => w.level == levelStr).toList();
    if (levelWords.isEmpty) levelWords = List.of(allWords);

    // 60% from weak items, 40% fresh
    final weak = levelWords.where((w) => weakIds.contains(w.urdu)).toList();
    final fresh = levelWords.where((w) => !weakIds.contains(w.urdu)).toList();

    final pool = <UrduWord>[];
    for (int i = 0; i < 6; i++) {
      pool.add(weak.isNotEmpty
          ? weak[_rng.nextInt(weak.length)]
          : levelWords[_rng.nextInt(levelWords.length)]);
    }
    for (int i = 0; i < 4; i++) {
      pool.add(fresh.isNotEmpty
          ? fresh[_rng.nextInt(fresh.length)]
          : levelWords[_rng.nextInt(levelWords.length)]);
    }
    pool.shuffle(_rng);
    return pool;
  }

  // ── Pick question type for current difficulty ───────────────────────────
  _QType _pickType() {
    switch (_difficulty) {
      case _Difficulty.easy:
        return _qNum % 3 == 2 ? _QType.speakWord : _QType.imageToUrdu;
      case _Difficulty.medium:
        final types = [_QType.urduToEnglish, _QType.imageToUrdu, _QType.speakWord];
        return types[_qNum % types.length];
      case _Difficulty.hard:
        final types = [_QType.fillBlank, _QType.urduToEnglish, _QType.speakWord];
        return types[_qNum % types.length];
    }
  }

  // ── Build a question object ─────────────────────────────────────────────
  _Question _makeQuestion(UrduWord word) {
    final type = _pickType();

    switch (type) {
      case _QType.imageToUrdu:
        // Show emoji → pick correct Urdu word
        final allW = widget.wordList ?? WORDS;
        final wrong = allW
            .where((w) => w.urdu != word.urdu && w.level == word.level)
            .toList()
          ..shuffle(_rng);
        // Fall back to any word if not enough same-level distractors
        final wrongAny = allW.where((w) => w.urdu != word.urdu).toList()..shuffle(_rng);
        final needed = _difficulty == _Difficulty.easy ? 1 : 3;
        final distList = wrong.take(needed).toList();
        while (distList.length < needed && wrongAny.length > distList.length) {
          final candidate = wrongAny[distList.length];
          if (!distList.any((d) => d.urdu == candidate.urdu)) distList.add(candidate);
        }
        final distractors = distList.map((w) => w.urdu).toList();
        final choices = [word.urdu, ...distractors]..shuffle(_rng);
        return _Question(
          word: word,
          type: type,
          choices: choices,
          correctIndex: choices.indexOf(word.urdu),
        );

      case _QType.urduToEnglish:
        // Show Urdu word → pick correct English
        final allW2 = widget.wordList ?? WORDS;
        final wrong = allW2
            .where((w) => w.english != word.english)
            .toList()
          ..shuffle(_rng);
        final distractors = wrong.take(3).map((w) => w.english).toList();
        final choices = [word.english, ...distractors]..shuffle(_rng);
        return _Question(
          word: word,
          type: type,
          choices: choices,
          correctIndex: choices.indexOf(word.english),
        );

      case _QType.fillBlank:
        // Sentence fill-in-the-blank
        final sentences = SENTENCES.where((s) =>
            s.words.contains(word.urdu) || s.urdu.contains(word.urdu)).toList();
        final sentence = sentences.isNotEmpty
            ? sentences[_rng.nextInt(sentences.length)]
            : SENTENCES[_rng.nextInt(SENTENCES.length)];
        final correct = sentence.blankWord;
        final wrongWords = sentence.words.where((w) => w != correct).toList();
        final distractors = wrongWords.take(2).toList();
        if (distractors.length < 2) {
          final allForFill = widget.wordList ?? WORDS;
          final extra = allForFill.where((w) => w.urdu != correct).toList()
            ..shuffle(_rng);
          while (distractors.length < 2) {
            distractors.add(extra[distractors.length].urdu);
          }
        }
        final choices = [correct, ...distractors]..shuffle(_rng);
        return _Question(
          word: word,
          type: type,
          choices: choices,
          correctIndex: choices.indexOf(correct),
          sentence: sentence,
        );

      case _QType.speakWord:
        // No choices — handled separately via mic
        return _Question(
          word: word,
          type: type,
          choices: const [],
          correctIndex: 0,
        );
    }
  }

  // ── Load next question ──────────────────────────────────────────────────
  void _nextQuestion() {
    if (_qNum >= _totalQ) {
      setState(() {
        _phase = _Phase.results;
        _emotion = _score >= 7 ? AvatarEmotion.excited : AvatarEmotion.happy;
      });
      _speakResult();
      return;
    }

    final pool = _buildPool();
    final word = pool[_rng.nextInt(pool.length)];
    final question = _makeQuestion(word);

    setState(() {
      _current = question;
      _phase = _Phase.question;
      _selectedIndex = null;
      _tryAgain = false;
      _speakScore = null;
      _emotion = AvatarEmotion.neutral;
    });

    _feedbackCtrl.reset();
    _speakQuestion(question);
  }

  // ── TTS: speak question ─────────────────────────────────────────────────
  void _speakQuestion(_Question q) {
    switch (q.type) {
      case _QType.imageToUrdu:
        TtsService.instance.speak('یہ کیا ہے؟');
      case _QType.urduToEnglish:
        TtsService.instance.speak('${q.word.urdu}۔ اس کا مطلب کیا ہے؟');
      case _QType.fillBlank:
        if (q.sentence != null) {
          final blank = q.sentence!.urdu.replaceFirst(q.sentence!.blankWord, '۔۔۔');
          TtsService.instance.speak('خالی جگہ بھریں: $blank');
        }
      case _QType.speakWord:
        TtsService.instance.speak('یہ لفظ بولیں: ${q.word.urdu}');
    }
  }

  // ── Handle choice tap ───────────────────────────────────────────────────
  void _onChoiceTap(int index) {
    if (_phase != _Phase.question) return;
    setState(() => _selectedIndex = index);

    if (index == _current.correctIndex) {
      _handleCorrect();
    } else {
      _handleWrong();
    }
  }

  void _handleCorrect() {
    _score++;
    _streakCorrect++;
    _streakWrong = 0;
    _maybeRaiseDifficulty();

    context.read<AppProvider>().recordResult(_current.word.urdu, 100.0);
    TtsService.instance.speak('شاباش! بہت اچھے!');

    setState(() {
      _phase = _Phase.correct;
      _emotion = AvatarEmotion.excited;
    });
    _feedbackCtrl.forward();
    _starCtrl.forward(from: 0);
  }

  void _handleWrong() {
    _streakWrong++;
    _streakCorrect = 0;
    _maybeLowerDifficulty();

    context.read<AppProvider>().recordResult(_current.word.urdu, 0.0);
    TtsService.instance.speak(
        'غلط! درست جواب ہے: ${_current.type == _QType.urduToEnglish ? _current.word.english : _current.word.urdu}');

    setState(() {
      _phase = _Phase.wrong;
      _emotion = AvatarEmotion.sad;
    });
    _feedbackCtrl.forward();
  }

  // ── Handle speak question result ────────────────────────────────────────
  void _onSpeakScore(double score) {
    setState(() => _speakScore = score);
    if (score >= 70) {
      _handleCorrect();
    } else {
      _handleWrong();
    }
  }

  // ── Difficulty adaptation ───────────────────────────────────────────────
  void _maybeRaiseDifficulty() {
    if (_streakCorrect >= 3 && _difficulty != _Difficulty.hard) {
      setState(() {
        _difficulty = _difficulty == _Difficulty.easy
            ? _Difficulty.medium
            : _Difficulty.hard;
        _streakCorrect = 0;
      });
    }
  }

  void _maybeLowerDifficulty() {
    if (_streakWrong >= 2 && _difficulty != _Difficulty.easy) {
      setState(() {
        _difficulty = _difficulty == _Difficulty.hard
            ? _Difficulty.medium
            : _Difficulty.easy;
        _streakWrong = 0;
      });
    }
  }

  void _speakResult() {
    final ratio = _score / _totalQ;
    if (ratio >= 0.8) {
      TtsService.instance.speak('بہت اچھے! آپ نے شاندار کارکردگی دکھائی۔');
    } else if (ratio >= 0.5) {
      TtsService.instance.speak('اچھا کیا! مزید مشق سے اور بہتر ہوں گے۔');
    } else {
      TtsService.instance.speak('ہمت نہ ہاریں! دوبارہ کوشش کریں۔');
    }
  }

  int get _stars {
    if (_score >= 8) return 3;
    if (_score >= 5) return 2;
    return 1;
  }

  // ── Difficulty badge ────────────────────────────────────────────────────
  Color get _diffColor {
    switch (_difficulty) {
      case _Difficulty.easy:   return Colors.green;
      case _Difficulty.medium: return Colors.orange;
      case _Difficulty.hard:   return Colors.red;
    }
  }

  String get _diffLabel {
    switch (_difficulty) {
      case _Difficulty.easy:   return 'آسان';
      case _Difficulty.medium: return 'درمیانہ';
      case _Difficulty.hard:   return 'مشکل';
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_phase == _Phase.results) return _buildResults();

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── Avatar strip ───────────────────────────────────────────────
          Container(
            color: AppTheme.purple.withOpacity(0.08),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ProfessorAvatar(emotion: _emotion, size: 72),
                const SizedBox(width: 12),
                // Difficulty badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _diffColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _diffColor, width: 1.5),
                  ),
                  child: Text(
                    _diffLabel,
                    style: TextStyle(
                      fontFamily: 'NotoNastaliqUrdu',
                      fontSize: 14,
                      color: _diffColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
          ),

          // ── Progress bar ───────────────────────────────────────────────
          LinearProgressIndicator(
            value: _qNum / _totalQ,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(_diffColor),
          ),

          // ── Main content ───────────────────────────────────────────────
          Expanded(
            child: _phase == _Phase.question
                ? _buildQuestion()
                : _buildFeedback(),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    final title = widget.screenTitle ?? 'کوئز';
    return AppBar(
      title: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          '$title  $_qNum / $_totalQ   ✓ $_score',
          style: const TextStyle(fontSize: 16),
        ),
      ),
      backgroundColor: AppTheme.purple,
      foregroundColor: Colors.white,
      actions: [
        // Repeat question TTS
        IconButton(
          icon: const Icon(Icons.volume_up),
          onPressed: () => _speakQuestion(_current),
        ),
      ],
    );
  }

  // ── Question view ───────────────────────────────────────────────────────
  Widget _buildQuestion() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildQuestionCard(),
          const SizedBox(height: 20),
          if (_current.type == _QType.speakWord)
            _buildSpeakQuestion()
          else
            _buildChoices(),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x18000000), blurRadius: 12, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Question label
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              _questionLabel,
              style: TextStyle(
                fontFamily: 'NotoNastaliqUrdu',
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Big emoji (always shown)
          Text(_current.word.emoji,
              style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 8),

          // For urduToEnglish: also show the Urdu word
          if (_current.type == _QType.urduToEnglish ||
              _current.type == _QType.speakWord)
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                _current.word.urdu,
                style: const TextStyle(
                  fontFamily: 'NotoNastaliqUrdu',
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                  height: 1.1,
                ),
              ),
            ),

          // For fillBlank: show sentence with blank
          if (_current.type == _QType.fillBlank && _current.sentence != null)
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                _current.sentence!.urdu
                    .replaceFirst(_current.sentence!.blankWord, '______'),
                style: const TextStyle(
                  fontFamily: 'NotoNastaliqUrdu',
                  fontSize: 24,
                  color: AppTheme.navy,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  String get _questionLabel {
    switch (_current.type) {
      case _QType.imageToUrdu:   return 'یہ کیا ہے؟ اردو میں بتائیں';
      case _QType.urduToEnglish: return 'اس کا انگریزی مطلب کیا ہے؟';
      case _QType.fillBlank:     return 'خالی جگہ بھریں';
      case _QType.speakWord:     return 'یہ لفظ بولیں — مائیکروفون دبائیں';
    }
  }

  Widget _buildChoices() {
    return Column(
      children: List.generate(_current.choices.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _onChoiceTap(i),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.navy,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  _current.choices[i],
                  style: const TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSpeakQuestion() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () =>
              TtsService.instance.speak(_current.word.urdu),
          icon: const Text('🔊', style: TextStyle(fontSize: 20)),
          label: const Text('سنیں',
              style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => MicRecorderWidget(
              targetText: _current.word.urdu,
              targetRoman: _current.word.target,
              onScore: (score, _) {
                Navigator.pop(context);
                _onSpeakScore(score);
              },
            ),
          ),
          icon: const Text('🎤', style: TextStyle(fontSize: 20)),
          label: const Text('بولیں',
              style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // ── Feedback view (correct / wrong) ─────────────────────────────────────
  Widget _buildFeedback() {
    final isCorrect = _phase == _Phase.correct;
    final bgColor = isCorrect
        ? const Color(0xFF00C853)
        : const Color(0xFFD50000);

    return ScaleTransition(
      scale: _feedbackScale,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: bgColor.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // ── Big result icon ──────────────────────────────────────────
            Text(
              isCorrect ? '✅' : '❌',
              style: const TextStyle(fontSize: 52),
            ),
            const SizedBox(height: 8),

            // ── Appreciation / Error text ────────────────────────────────
            Text(
              isCorrect ? 'شاباش! 🌟' : 'غلط!',
              style: const TextStyle(
                fontFamily: 'NotoNastaliqUrdu',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textDirection: TextDirection.rtl,
            ),

            const SizedBox(height: 12),

            // ── Big word emoji (visual of the object) ────────────────────
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(_current.word.emoji,
                    style: const TextStyle(fontSize: 52)),
              ),
            ),

            const SizedBox(height: 8),

            // ── Word in Urdu + English ───────────────────────────────────
            Text(
              _current.word.urdu,
              style: const TextStyle(
                fontFamily: 'NotoNastaliqUrdu',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.1,
              ),
              textDirection: TextDirection.rtl,
            ),
            Text(
              _current.word.english,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),

            // ── Pronunciation accuracy badge (speak questions only) ───────
            if (_speakScore != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.6), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🎤', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'تلفظ کی درستگی: ${_speakScore!.toInt()}%',
                      style: const TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(width: 8),
                    // Circular score indicator
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: _speakScore! / 100,
                            strokeWidth: 4,
                            backgroundColor: Colors.white30,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _speakScore! >= 70
                                  ? Colors.white
                                  : Colors.yellow,
                            ),
                          ),
                          Text(
                            '${_speakScore!.toInt()}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Stars (correct only) ─────────────────────────────────────
            if (isCorrect) ...[
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _starCtrl,
                builder: (_, __) => Opacity(
                  opacity: _starCtrl.value,
                  child: const Text('⭐⭐⭐',
                      style: TextStyle(fontSize: 28)),
                ),
              ),
            ],

            // ── Wrong: show correct answer ───────────────────────────────
            if (!isCorrect) ...[
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'درست جواب: ${_current.type == _QType.urduToEnglish ? _current.word.english : _current.word.urdu}',
                  style: const TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 18,
                    color: Colors.white,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Action buttons ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isCorrect)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ElevatedButton.icon(
                      onPressed: _retryQuestion,
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        'دوبارہ کوشش',
                        style: TextStyle(
                            fontFamily: 'NotoNastaliqUrdu', fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: bgColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _advance,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text(
                    'اگلا سوال',
                    style: TextStyle(
                        fontFamily: 'NotoNastaliqUrdu', fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: bgColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
    );
  }

  void _retryQuestion() {
    setState(() {
      _phase = _Phase.question;
      _selectedIndex = null;
      _emotion = AvatarEmotion.neutral;
    });
    _feedbackCtrl.reset();
    _speakQuestion(_current);
  }

  void _advance() {
    setState(() => _qNum++);
    _nextQuestion();
  }

  // ── Results screen ───────────────────────────────────────────────────────
  Widget _buildResults() {
    final s = _stars;
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: const Text('نتیجہ',
            style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 22)),
        backgroundColor: AppTheme.purple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ProfessorAvatar(emotion: _emotion, size: 120),
              const SizedBox(height: 24),
              Text('⭐' * s, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  '$_score / $_totalQ سوال درست',
                  style: const TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  s == 3
                      ? 'بہت اچھے! آپ نے شاندار کارکردگی دکھائی! 🎉'
                      : s == 2
                          ? 'اچھا! مزید مشق سے بہتری آئے گی۔ 💪'
                          : 'ہمت نہ ہاریں! دوبارہ کوشش کریں۔ 📚',
                  style: TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 18,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // Final difficulty reached
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _diffColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _diffColor),
                ),
                child: Text(
                  'سطح: $_diffLabel',
                  style: TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 16,
                    color: _diffColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _qNum = 0;
                        _score = 0;
                        _streakCorrect = 0;
                        _streakWrong = 0;
                        _difficulty = _Difficulty.easy;
                        _phase = _Phase.loading;
                      });
                      _nextQuestion();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('دوبارہ کھیلیں',
                        style: TextStyle(
                            fontFamily: 'NotoNastaliqUrdu', fontSize: 16)),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.purple,
                      side: const BorderSide(color: AppTheme.purple),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('گھر جائیں',
                        style: TextStyle(
                            fontFamily: 'NotoNastaliqUrdu', fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
