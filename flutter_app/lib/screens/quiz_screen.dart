import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sentences.dart';
import '../data/words.dart';
import '../models/urdu_sentence.dart';
import '../models/urdu_word.dart';
import '../providers/app_provider.dart';
import '../services/tts_service.dart';
import '../widgets/mic_recorder_widget.dart';

const _kBg = Color(0xFFFFF8E8);
const _kCardTop = Color(0xFFFFF3D6);
const _kTeal = Color(0xFF26C6DA);
const _kOrange = Color(0xFFFF7043);
const _kPurple = Color(0xFF7C3AED);

const _mascotMsgs = [
  'Wow!\nThis is',
  'Great!\nMeet',
  'Hello!\nI\'m',
  'Look!\nIt\'s',
  'Cool!\nThis is',
  'Fun!\nMeet',
  'Listen!\nIt\'s',
  'Nice!\nThis is',
  'Learn!\nMeet',
  'Hey!\nI\'m',
];

class _WordCard {
  final String mainText;
  final String roman;
  final String transcription;
  final String emoji;
  final String speakTarget;
  final List<String> choices;
  final int correctIndex;
  final bool speakOnly;

  const _WordCard({
    required this.mainText,
    required this.roman,
    required this.transcription,
    required this.emoji,
    required this.speakTarget,
    required this.choices,
    required this.correctIndex,
    required this.speakOnly,
  });
}

class _SentenceCard {
  final String sentence;
  final String blankWord;
  final String english;
  final List<String> choices;
  final int correctIndex;

  const _SentenceCard({
    required this.sentence,
    required this.blankWord,
    required this.english,
    required this.choices,
    required this.correctIndex,
  });
}

class QuizScreen extends StatefulWidget {
  final List<UrduWord>? wordList;
  final String? screenTitle;

  const QuizScreen({super.key, this.wordList, this.screenTitle});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const int _totalQ = 10;

  final Random _rng = Random();
  late final List<_WordCard> _deck;

  int _index = 0;
  int _score = 0;
  int? _chosen;
  bool _revealed = false;
  bool _speaking = false;
  double? _speakScore;

  @override
  void initState() {
    super.initState();
    _deck = _buildDeck();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _speakQuestion();
    });
  }

  List<_WordCard> _buildDeck() {
    final pool = widget.wordList ?? WORDS;
    if (pool.isEmpty) return const <_WordCard>[];

    final shuffled = List<UrduWord>.of(pool)..shuffle(_rng);
    final selected = shuffled.take(min(_totalQ, shuffled.length)).toList();

    return selected.asMap().entries.map((entry) {
      final word = entry.value;
      if (entry.key % 3 == 2) {
        return _WordCard(
          mainText: word.urdu,
          roman: word.roman,
          transcription: word.english,
          emoji: word.emoji,
          speakTarget: word.urdu,
          choices: const [],
          correctIndex: 0,
          speakOnly: true,
        );
      }

      final distractors = pool
          .where((candidate) => candidate.urdu != word.urdu)
          .map((candidate) => candidate.urdu)
          .toList()
        ..shuffle(_rng);

      final choices = <String>[word.urdu, ...distractors.take(3)]..shuffle(_rng);
      return _WordCard(
        mainText: word.urdu,
        roman: word.roman,
        transcription: word.english,
        emoji: word.emoji,
        speakTarget: word.urdu,
        choices: choices,
        correctIndex: choices.indexOf(word.urdu),
        speakOnly: false,
      );
    }).toList();
  }

  void _speakQuestion() {
    if (_deck.isEmpty) return;
    TtsService.instance.speak(_deck[_index].speakTarget);
  }

  Future<void> _speakCurrentCard() async {
    if (_speaking || _deck.isEmpty) return;
    setState(() => _speaking = true);
    try {
      await TtsService.instance.speak(_deck[_index].speakTarget);
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  void _onChoice(int choiceIndex) {
    if (_revealed || _deck.isEmpty) return;

    final card = _deck[_index];
    final isCorrect = choiceIndex == card.correctIndex;

    if (isCorrect) _score++;

    setState(() {
      _chosen = choiceIndex;
      _revealed = true;
    });

    context.read<AppProvider>().recordResult(card.mainText, isCorrect ? 100 : 0);

    TtsService.instance.speak(
      isCorrect ? 'شاباش! بہت اچھے!' : 'غلط! دوبارہ کوشش کریں',
    );
  }

  void _onSpeakScore(double score) {
    if (_deck.isEmpty) return;

    if (score >= 70) _score++;
    setState(() {
      _speakScore = score;
      _revealed = true;
    });

    context.read<AppProvider>().recordResult(_deck[_index].mainText, score);

    TtsService.instance.speak(
      score >= 70 ? 'شاباش! تلفظ درست ہے!' : 'غلط تلفظ — دوبارہ کوشش کریں',
    );
  }

  void _goNext() {
    if (_deck.isEmpty) return;

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

    _speakQuestion();
  }

  void _goBack() {
    if (_index == 0) return;
    setState(() {
      _index--;
      _chosen = null;
      _revealed = false;
      _speakScore = null;
    });
    _speakQuestion();
  }

  void _showResults() {
    final total = _deck.isEmpty ? 1 : _deck.length;
    const accentColor = _kPurple;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultsScreen(
          score: _score,
          total: total,
          title: widget.screenTitle ?? 'Quiz',
          accentColor: accentColor,
          restartBuilder: (_) => QuizScreen(
            wordList: widget.wordList,
            screenTitle: widget.screenTitle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_deck.isEmpty) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: Text('No quiz items available')),
      );
    }

    final card = _deck[_index];
    final progress = (_index + 1) / _deck.length;
    final message = '${_mascotMsgs[_index % _mascotMsgs.length]} ${card.roman}!';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Stack(
            children: [
              const _DecorativeBackground(accentColor: _kPurple),
              Column(
                children: [
                  _QuizTopBar(
                    title: widget.screenTitle ?? 'Quiz',
                    index: _index,
                    total: _deck.length,
                    score: _score,
                    progress: progress,
                    accentColor: _kPurple,
                    onBack: Navigator.of(context).canPop() ? () => Navigator.pop(context) : null,
                    onSpeak: _speakQuestion,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 640;
                          return Center(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isWide ? 760 : 520,
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        if (isWide)
                                          SizedBox(
                                            width: 88,
                                            child: _MascotSide(message: message),
                                          ),
                                        Expanded(
                                          child: _WordQuizCard(
                                            card: card,
                                            accentColor: _kPurple,
                                            chosen: _chosen,
                                            revealed: _revealed,
                                            speakScore: _speakScore,
                                            speaking: _speaking,
                                            onChoice: _onChoice,
                                            onSpeak: _speakCurrentCard,
                                            onMic: () => MicRecorderWidget.show(
                                              context,
                                              targetText: card.mainText,
                                              targetRoman: card.roman,
                                              onScore: (score, _) {
                                                Navigator.of(context).pop();
                                                _onSpeakScore(score);
                                              },
                                            ),
                                          ),
                                        ),
                                        if (isWide)
                                          SizedBox(
                                            width: 88,
                                            child: _TipSide(text: card.transcription),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 4),
                                    child: Row(
                                      children: [
                                        if (_index > 0)
                                          _PillButton(
                                            label: 'Back',
                                            color: Colors.white,
                                            textColor: const Color(0xFF6B7280),
                                            border: const Color(0xFFE5E7EB),
                                            onTap: _goBack,
                                          )
                                        else
                                          const SizedBox(width: 92),
                                        const Spacer(),
                                        _PillButton(
                                          label: _revealed
                                              ? (_index == _deck.length - 1 ? 'Finish' : 'Next')
                                              : 'Skip',
                                          color: _revealed ? _kOrange : Colors.grey.shade300,
                                          textColor: _revealed ? Colors.white : Colors.grey.shade600,
                                          onTap: _goNext,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
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

class SentenceQuizScreen extends StatefulWidget {
  const SentenceQuizScreen({super.key});

  @override
  State<SentenceQuizScreen> createState() => _SentenceQuizState();
}

class _SentenceQuizState extends State<SentenceQuizScreen> {
  static const int _totalQ = 10;
  static const Color _accentColor = Color(0xFF10B981);

  final Random _rng = Random();
  late final List<_SentenceCard> _deck;

  int _index = 0;
  int _score = 0;
  int? _chosen;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _deck = _buildDeck();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _speakCurrent();
    });
  }

  List<_SentenceCard> _buildDeck() {
    if (SENTENCES.isEmpty) return const <_SentenceCard>[];

    final shuffled = List<UrduSentence>.of(SENTENCES)..shuffle(_rng);
    final selected = shuffled.take(min(_totalQ, shuffled.length)).toList();
    final allWords = WORDS.map((word) => word.urdu).toSet().toList()..shuffle(_rng);

    return selected.map((sentence) {
      final blank = sentence.blankWord;
      final choices = <String>[blank];

      for (final word in sentence.words) {
        if (word != blank && !choices.contains(word)) {
          choices.add(word);
        }
      }

      for (final word in allWords) {
        if (choices.length >= 4) break;
        if (word != blank && !choices.contains(word)) {
          choices.add(word);
        }
      }

      choices.shuffle(_rng);

      return _SentenceCard(
        sentence: sentence.urdu,
        blankWord: blank,
        english: sentence.english,
        choices: choices.take(4).toList(),
        correctIndex: choices.indexOf(blank),
      );
    }).toList();
  }

  void _speakCurrent() {
    if (_deck.isEmpty) return;
    final card = _deck[_index];
    TtsService.instance.speak('خالی جگہ بھریں: ${card.sentence.replaceFirst(card.blankWord, '۔۔۔')}');
  }

  void _onChoice(int choiceIndex) {
    if (_revealed || _deck.isEmpty) return;

    final card = _deck[_index];
    final isCorrect = choiceIndex == card.correctIndex;

    if (isCorrect) _score++;

    setState(() {
      _chosen = choiceIndex;
      _revealed = true;
    });

    context.read<AppProvider>().recordResult(card.sentence, isCorrect ? 100 : 0);

    TtsService.instance.speak(isCorrect ? 'شاباش! بہت اچھے!' : 'غلط!');
  }

  void _goNext() {
    if (_deck.isEmpty) return;

    if (_index >= _deck.length - 1) {
      _showResults();
      return;
    }

    setState(() {
      _index++;
      _chosen = null;
      _revealed = false;
    });

    _speakCurrent();
  }

  void _showResults() {
    final total = _deck.isEmpty ? 1 : _deck.length;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultsScreen(
          score: _score,
          total: total,
          title: 'Sentence Quiz',
          accentColor: _accentColor,
          restartBuilder: (_) => const SentenceQuizScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_deck.isEmpty) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: Text('No sentence quiz items available')),
      );
    }

    final card = _deck[_index];
    final progress = (_index + 1) / _deck.length;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Stack(
            children: [
              const _DecorativeBackground(accentColor: _accentColor),
              Column(
                children: [
                  _QuizTopBar(
                    title: 'Sentence Quiz',
                    index: _index,
                    total: _deck.length,
                    score: _score,
                    progress: progress,
                    accentColor: _accentColor,
                    onBack: Navigator.of(context).canPop() ? () => Navigator.pop(context) : null,
                    onSpeak: _speakCurrent,
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                          child: Column(
                            children: [
                              Expanded(
                                child: _SentenceQuizCard(
                                  card: card,
                                  accentColor: _accentColor,
                                  chosen: _chosen,
                                  revealed: _revealed,
                                  onChoice: _onChoice,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _PillButton(
                                      label: _revealed
                                          ? (_index == _deck.length - 1 ? 'Finish' : 'Next')
                                          : 'Skip',
                                      color: _revealed ? _kOrange : Colors.grey.shade300,
                                      textColor: _revealed ? Colors.white : Colors.grey.shade600,
                                      onTap: _goNext,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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

class QuizResultsScreen extends StatelessWidget {
  final int score;
  final int total;
  final String title;
  final Color accentColor;
  final WidgetBuilder restartBuilder;

  const QuizResultsScreen({
    super.key,
    required this.score,
    required this.total,
    required this.title,
    required this.accentColor,
    required this.restartBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : score / total;
    final stars = pct >= 0.8
        ? 3
        : pct >= 0.5
            ? 2
            : 1;
    final color = pct >= 0.8
        ? Colors.green
        : pct >= 0.5
            ? Colors.orange
            : Colors.red;
    final message = stars == 3
        ? 'بہت اچھے! شاندار!'
        : stars == 2
            ? 'اچھا! مزید مشق کریں'
            : 'ہمت نہ ہاریں! دوبارہ کوشش کریں';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final filled = index < stars;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            filled ? '⭐' : '☆',
                            style: TextStyle(
                              fontSize: filled ? 42 : 32,
                              color: filled ? Colors.amber : Colors.grey.shade300,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: color, width: 5),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.18),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$score/$total',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: color,
                            ),
                          ),
                          const Text(
                            'score',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'NotoNastaliqUrdu',
                          fontSize: 20,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _PillButton(
                      label: 'Try Again',
                      color: accentColor,
                      textColor: Colors.white,
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: restartBuilder),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizTopBar extends StatelessWidget {
  final String title;
  final int index;
  final int total;
  final int score;
  final double progress;
  final Color accentColor;
  final VoidCallback? onBack;
  final VoidCallback onSpeak;

  const _QuizTopBar({
    required this.title,
    required this.index,
    required this.total,
    required this.score,
    required this.progress,
    required this.accentColor,
    required this.onBack,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, top + 10, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              if (onBack != null)
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                )
              else
                const SizedBox(width: 34, height: 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${index + 1} / $total  •  ✓ $score correct',
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onSpeak,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordQuizCard extends StatelessWidget {
  final _WordCard card;
  final Color accentColor;
  final int? chosen;
  final bool revealed;
  final double? speakScore;
  final bool speaking;
  final ValueChanged<int> onChoice;
  final VoidCallback onSpeak;
  final VoidCallback onMic;

  const _WordQuizCard({
    required this.card,
    required this.accentColor,
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
    final isSpeakCard = card.speakOnly;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: const BoxDecoration(
                color: _kCardTop,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💭', style: TextStyle(fontSize: 26)),
                  const SizedBox(height: 8),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      isSpeakCard ? 'یہ لفظ بولیں' : 'یہ کیا ہے؟',
                      style: TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: 12,
                        color: Colors.brown.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.emoji,
                    style: TextStyle(fontSize: isSpeakCard ? 48 : 54),
                  ),
                  const SizedBox(height: 8),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      card.mainText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: isSpeakCard ? 28 : 21,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card.roman,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CircularButton(
                        icon: Icons.volume_up_rounded,
                        label: 'Listen',
                        color: _kTeal,
                        filled: speaking,
                        onTap: onSpeak,
                      ),
                      const SizedBox(width: 20),
                      _CircularButton(
                        icon: Icons.mic_rounded,
                        label: 'Speak',
                        color: _kPurple,
                        filled: false,
                        onTap: revealed ? null : onMic,
                      ),
                    ],
                  ),
                  if (speakScore != null) ...[
                    const SizedBox(height: 10),
                    _ScoreBadge(score: speakScore!),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: isSpeakCard
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        for (int i = 0; i < card.choices.length; i++) ...[
                          _ChoiceTile(
                            text: card.choices[i],
                            accentColor: accentColor,
                            isSelected: chosen == i,
                            isCorrect: revealed && i == card.correctIndex,
                            isWrongChoice: revealed && chosen == i && i != card.correctIndex,
                            onTap: () => onChoice(i),
                          ),
                          if (i != card.choices.length - 1) const SizedBox(height: 10),
                        ],
                        if (revealed && chosen != null && chosen != card.correctIndex) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                'درست جواب: ${card.choices[card.correctIndex]}  (${card.transcription})',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'NotoNastaliqUrdu',
                                  fontSize: 14,
                                  height: 1.35,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SentenceQuizCard extends StatelessWidget {
  final _SentenceCard card;
  final Color accentColor;
  final int? chosen;
  final bool revealed;
  final ValueChanged<int> onChoice;

  const _SentenceQuizCard({
    required this.card,
    required this.accentColor,
    required this.chosen,
    required this.revealed,
    required this.onChoice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              decoration: const BoxDecoration(
                color: _kCardTop,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💬', style: TextStyle(fontSize: 34)),
                  const SizedBox(height: 8),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      'خالی جگہ بھریں',
                      style: TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: 14,
                        color: Colors.brown.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: RichText(
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'NotoNastaliqUrdu',
                          fontSize: 18,
                          color: Color(0xFF1C1917),
                          height: 1.5,
                        ),
                        children: _buildSentenceSpans(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    card.english,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  children: [
                    for (int i = 0; i < card.choices.length; i++) ...[
                      _ChoiceTile(
                        text: card.choices[i],
                        accentColor: accentColor,
                        isSelected: chosen == i,
                        isCorrect: revealed && i == card.correctIndex,
                        isWrongChoice: revealed && chosen == i && i != card.correctIndex,
                        onTap: () => onChoice(i),
                      ),
                      if (i != card.choices.length - 1) const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<InlineSpan> _buildSentenceSpans() {
    final spans = <InlineSpan>[];
    final parts = card.sentence.split(card.blankWord);

    for (int i = 0; i < parts.length; i++) {
      if (i > 0) {
        spans.add(
          TextSpan(
            text: revealed ? card.blankWord : '______',
            style: TextStyle(
              fontFamily: 'NotoNastaliqUrdu',
              fontWeight: FontWeight.bold,
              color: revealed ? accentColor : Colors.grey.shade600,
              decoration: TextDecoration.underline,
              height: 1.2,
            ),
          ),
        );
      }
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(text: parts[i]));
      }
    }

    return spans;
  }
}

class _ChoiceTile extends StatelessWidget {
  final String text;
  final Color accentColor;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrongChoice;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.text,
    required this.accentColor,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrongChoice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Colors.white;
    Color borderColor = const Color(0xFFE5E7EB);
    Color textColor = const Color(0xFF1C1917);

    if (isCorrect) {
      backgroundColor = Colors.green.shade50;
      borderColor = Colors.green;
      textColor = Colors.green.shade800;
    } else if (isWrongChoice) {
      backgroundColor = Colors.red.shade50;
      borderColor = Colors.red;
      textColor = Colors.red.shade800;
    } else if (isSelected) {
      backgroundColor = accentColor.withOpacity(0.08);
      borderColor = accentColor;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (isCorrect)
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20)
            else if (isWrongChoice)
              const Icon(Icons.cancel_rounded, color: Colors.red, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CircularButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;

  const _CircularButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: disabled
                  ? Colors.grey.shade200
                  : filled
                      ? color
                      : color.withOpacity(0.12),
              border: Border.all(
                color: disabled ? Colors.grey.shade300 : color,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: disabled
                  ? Colors.grey
                  : filled
                      ? Colors.white
                      : color,
              size: 22,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final Color? border;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.color,
    required this.textColor,
    this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          border: border != null ? Border.all(color: border!, width: 1.5) : null,
          boxShadow: border == null
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
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
    final label = score >= 70
        ? '🌟 شاباش!'
        : score >= 45
            ? '🔸 قریب!'
            : '❌ غلط';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 4,
                backgroundColor: _color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(_color),
              ),
              Text(
                '${score.toInt()}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: _color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'NotoNastaliqUrdu',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _color,
          ),
        ),
      ],
    );
  }
}

class _MascotSide extends StatelessWidget {
  final String message;

  const _MascotSide({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          margin: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF5D4037),
            ),
          ),
        ),
      ],
    );
  }
}

class _TipSide extends StatelessWidget {
  final String text;

  const _TipSide({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xCECE93D8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          const Text(
            'Tip',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6A1B9A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9.5,
              color: Color(0xFF37474F),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeBackground extends StatelessWidget {
  final Color accentColor;

  const _DecorativeBackground({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 80,
            left: 18,
            child: Text('⭐', style: TextStyle(fontSize: 18, color: accentColor.withOpacity(0.65))),
          ),
          Positioned(
            top: 140,
            right: 22,
            child: Text('⭐', style: TextStyle(fontSize: 14, color: accentColor.withOpacity(0.45))),
          ),
          Positioned(
            top: 220,
            left: 8,
            child: Text('⭐', style: TextStyle(fontSize: 20, color: accentColor.withOpacity(0.55))),
          ),
        ],
      ),
    );
  }
}
