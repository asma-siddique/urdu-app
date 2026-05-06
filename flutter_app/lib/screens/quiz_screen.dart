import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/words.dart';
import '../data/sentences.dart';
import '../models/urdu_word.dart';
import '../providers/app_provider.dart';
import '../services/tts_service.dart';
import '../widgets/mic_recorder_widget.dart';

// ── Palette (matches lesson_flow_screen) ─────────────────────────────────────
const _kBg = Color(0xFFFFF8E8);
const _kCardTop = Color(0xFFFFF3D6);
const _kTeal = Color(0xFF26C6DA);
const _kOrange = Color(0xFFFF7043);
const _kPurple = Color(0xFF7C3AED);

// ── Palette (matches lesson_flow_screen) ─────────────────────────────────────


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

// ══════════════════════════════════════════════════════════════════════════════
// Generic quiz card model
// ══════════════════════════════════════════════════════════════════════════════

enum _QKind { multiChoice, speakWord }

class _QuizCard {
  final String mainText;
  final String name;
  final String transcription;
  final String emoji;
  final String speakTarget;
  final String romanTarget;
  final _QKind kind;
  final List<String> choices;
  final int correctIndex;

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
  static const _accentColor = _kPurple;

  final Random _rng = Random();
  late List<_QuizCard> _deck;

  int _index = 0;
  int _score = 0;
  int? _chosen;
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
    _slideAnim = Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    _buildDeck();
    _slideCtrl.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _speakQuestion();
    });
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

    _deck = selected.map((w) => _makeMultiChoice(w, pool)).toList();
  }

  _QuizCard _makeMultiChoice(UrduWord w, List<UrduWord> pool) {
    final others = pool.where((x) => x.urdu != w.urdu).toList()..shuffle(_rng);
    final distractors = others.take(3).map((x) => x.urdu).toList();
    final choices = [w.urdu, ...distractors]..shuffle(_rng);
    return _QuizCard(
      mainText: w.urdu,
      name: w.roman,
      transcription: w.english,
      emoji: w.emoji,
      speakTarget: w.urdu,
      romanTarget: w.roman,
      kind: _QKind.multiChoice,
      choices: choices,
      correctIndex: choices.indexOf(w.urdu),
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

  void _speakQuestion() => TtsService.instance.speak(_deck[_index].speakTarget);

  // ── Choice tap ─────────────────────────────────────────────────────────────

  void _onChoice(int i) {
    if (_revealed) return;
    final correct = _deck[_index].correctIndex;
    if (i == correct) _score++;
    setState(() {
      _chosen = i;
      _revealed = true;
    });
    context
        .read<AppProvider>()
        .recordResult(_deck[_index].mainText, i == correct ? 100 : 0);
    TtsService.instance
        .speak(i == correct ? 'شاباش! بہت اچھے!' : 'غلط! دوبارہ کوشش کریں');
  }

  // ── Mic score ──────────────────────────────────────────────────────────────

  void _onSpeakScore(double score) {
    if (score >= 70) _score++;
    setState(() {
      _speakScore = score;
      _revealed = true;
    });
    context.read<AppProvider>().recordResult(_deck[_index].mainText, score);
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
        builder: (_) => QuizResultsScreen(
          score: _score,
          total: _totalQ,
          title: widget.screenTitle ?? 'Quiz',
          accentColor: _accentColor,
          accentColor: _accentColor,
          restartBuilder: (_) => QuizScreen(
            wordList: widget.wordList,
            screenTitle: widget.screenTitle,
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final card = _deck[_index];
    final progress = (_index + 1) / _totalQ;
    final msg = '${_mascotMsgs[_index % _mascotMsgs.length]} ${card.name}!';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _accentColor,
                _accentColor.withOpacity(0.6),
                const Color(0xFFFFF3E0),
                const Color(0xFFFFF8E8),
              ],
              stops: const [0.0, 0.18, 0.48, 1.0],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                ..._decorStars(),
                Column(
                  children: [
                    // ── Custom top bar ────────────────────────────────────────────
                    _QuizTopBar(
                      title: widget.screenTitle ?? 'Quiz',
                      index: _index,
                      total: _totalQ,
                      score: _score,
                      progress: progress,
                      accentColor: _accentColor,
                      onBack: () => Navigator.pop(context),
                      onSpeak: _speakQuestion,
                    ),
        backgroundColor: _kBg,
        body: Column(
          children: [
            // ── Custom top bar ────────────────────────────────────────────
            _QuizTopBar(
              title: widget.screenTitle ?? 'Quiz',
              index: _index,
              total: _totalQ,
              score: _score,
              progress: progress,
              accentColor: _accentColor,
              onBack: () => Navigator.pop(context),
              onSpeak: _speakQuestion,
        backgroundColor: _kBg,
        body: Column(
          children: [
            // ── Custom top bar ────────────────────────────────────────────
            _QuizTopBar(
              title: widget.screenTitle ?? 'Quiz',
              index: _index,
              total: _totalQ,
              score: _score,
              progress: progress,
              accentColor: _accentColor,
              onBack: () => Navigator.pop(context),
              onSpeak: _speakQuestion,
            ),

                    // ── Content ───────────────────────────────────────────────────
                    Expanded(
                      child: LayoutBuilder(builder: (ctx, bc) {
                        final isWide = bc.maxWidth > 460;
                        final sideW = isWide ? 72.0 : 44.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: sideW,
                                          child: _MascotSide(message: msg),
                                        ),
                                        Expanded(
                                          child: Center(
                                            child: SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.75,
                                              child: ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                        maxWidth: 300),
                                                child: _QuizFlashCard(
                                                  card: card,
                                                  color: _accentColor,
                                                  chosen: _chosen,
                                                  revealed: _revealed,
                                                  speakScore: _speakScore,
                                                  speaking: _speaking,
                                                  onChoice: _onChoice,
                                                  onSpeak: () async {
                                                    setState(
                                                        () => _speaking = true);
                                                    await TtsService.instance
                                                        .speak(
                                                            card.speakTarget);
                                                    if (mounted) {
                                                      setState(() =>
                                                          _speaking = false);
                                                    }
                                                  },
                                                  onMic: () =>
                                                      showModalBottomSheet(
                                                    context: context,
                                                    isScrollControlled: true,
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    builder: (_) =>
                                                        MicRecorderWidget(
                                                      targetText: card.mainText,
                                                      targetRoman:
                                                          card.romanTarget,
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
                                        ),
                                        SizedBox(
                                          width: sideW,
                                          child: _TipSide(
                                            text: card.transcription,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: LayoutBuilder(builder: (ctx, bc) {
                final w = bc.maxWidth;
                final isWide = w > 600;
                final cardWidth = isWide ? 480.0 : w - 32;

            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: LayoutBuilder(builder: (ctx, bc) {
                final w = bc.maxWidth;
                final isWide = w > 600;
                final cardWidth = isWide ? 480.0 : w - 32;

                return Center(
                  child: SizedBox(
                    width: cardWidth,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                return Center(
                  child: SizedBox(
                    width: cardWidth,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // ── Question card ─────────────────────────────────
                        Expanded(
                          child: SlideTransition(
                            position: _slideAnim,
                            child: FadeTransition(
                              opacity: _fadeAnim,
                              child: _QuizFlashCard(
                                card: card,
                                color: _accentColor,
                                chosen: _chosen,
                                revealed: _revealed,
                                speakScore: _speakScore,
                                speaking: _speaking,
                                onChoice: _onChoice,
                                onSpeak: () async {
                                  setState(() => _speaking = true);
                                  await TtsService.instance
                                      .speak(card.speakTarget);
                                  if (mounted) {
                                    setState(() => _speaking = false);
                                  }
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
                        // ── Question card ─────────────────────────────────
                        Expanded(
                          child: SlideTransition(
                            position: _slideAnim,
                            child: FadeTransition(
                              opacity: _fadeAnim,
                              child: _QuizFlashCard(
                                card: card,
                                color: _accentColor,
                                chosen: _chosen,
                                revealed: _revealed,
                                speakScore: _speakScore,
                                speaking: _speaking,
                                onChoice: _onChoice,
                                onSpeak: () async {
                                  setState(() => _speaking = true);
                                  await TtsService.instance
                                      .speak(card.speakTarget);
                                  if (mounted) {
                                    setState(() => _speaking = false);
                                  }
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

                                  // ── Navigation ────────────────────────────────────
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 8, 0, 20),
                                    child: Row(
                                      children: [
                                        if (_index > 0)
                                          _PillBtn(
                                            label: '← Back',
                                            color: Colors.white,
                                            textColor: const Color(0xFF6B7280),
                                            border: const Color(0xFFE5E7EB),
                                            onTap: () {
                                              setState(() {
                                                _index--;
                                                _chosen = null;
                                                _revealed = false;
                                                _speakScore = null;
                                              });
                                              _slideCtrl.forward(from: 0);
                                            },
                                          )
                                        else
                                          const SizedBox(width: 100),
                                        const Spacer(),
                                        _PillBtn(
                                          label: _revealed
                                              ? (_index == _totalQ - 1
                                                  ? 'Finish ✓'
                                                  : 'Next →')
                                              : 'Skip →',
                                          color: _revealed
                                              ? _kOrange
                                              : Colors.grey.shade300,
                                          textColor: _revealed
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                          onTap: _goNext,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
        ),
                        // ── Navigation ────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 20),
                          child: Row(
                            children: [
                              if (_index > 0)
                                _PillBtn(
                                  label: '← Back',
                                  color: Colors.white,
                                  textColor: const Color(0xFF6B7280),
                                  border: const Color(0xFFE5E7EB),
                                  onTap: () {
                                    setState(() {
                                      _index--;
                                      _chosen = null;
                                      _revealed = false;
                                      _speakScore = null;
                                    });
                                    _slideCtrl.forward(from: 0);
                                  },
                                )
                              else
                                const SizedBox(width: 100),
                              const Spacer(),
                              _PillBtn(
                                label: _revealed
                                    ? (_index == _totalQ - 1
                                        ? 'Finish ✓'
                                        : 'Next →')
                                    : 'Skip →',
                                color: _revealed ? _kOrange : Colors.grey.shade300,
                                textColor: _revealed
                                    ? Colors.white
                                    : Colors.grey.shade600,
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
          ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _decorStars() {
    const stars = [
      {'top': 80.0, 'left': 10.0, 'size': 18.0, 'op': 0.7},
      {'top': 136.0, 'left': 28.0, 'size': 12.0, 'op': 0.5},
      {'top': 220.0, 'left': 6.0, 'size': 22.0, 'op': 0.6},
      {'top': 82.0, 'right': 8.0, 'size': 16.0, 'op': 0.7},
      {'top': 158.0, 'right': 24.0, 'size': 20.0, 'op': 0.55},
      {'top': 250.0, 'right': 6.0, 'size': 14.0, 'op': 0.6},
    ];

    final widgets = stars
        .map<Widget>((d) => Positioned(
              top: d['top'] as double,
              left: d.containsKey('left') ? d['left'] as double : null,
              right: d.containsKey('right') ? d['right'] as double : null,
              child: Opacity(
                opacity: d['op'] as double,
                child:
                    Text('⭐', style: TextStyle(fontSize: d['size'] as double)),
              ),
            ))
        .toList();

    widgets.addAll([
      const Positioned(
        top: 58,
        left: 50,
        child: Opacity(
          opacity: 0.55,
          child: Text('☁️', style: TextStyle(fontSize: 28)),
        ),
      ),
      const Positioned(
        top: 62,
        right: 55,
        child: Opacity(
          opacity: 0.45,
          child: Text('☁️', style: TextStyle(fontSize: 22)),
        ),
      ),
      const Positioned(
        top: 48,
        left: 130,
        child: Opacity(
          opacity: 0.35,
          child: Text('☁️', style: TextStyle(fontSize: 18)),
        ),
      ),
    ]);

    widgets.add(
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: SizedBox(
          height: 28,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List<Widget>.generate(
                18,
                (i) => Padding(
                      padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                      child: Text(
                        i % 3 == 0
                            ? '🌿'
                            : i % 3 == 1
                                ? '🌱'
                                : '🌸',
                        style: TextStyle(fontSize: i % 2 == 0 ? 18.0 : 14.0),
                      ),
                    )),
          ),
        ),
      ),
    );

    return widgets;
  }
}

// ── Custom quiz top bar ───────────────────────────────────────────────────────

class _QuizTopBar extends StatelessWidget {
  final String title;
  final int index;
  final int total;
  final int score;
  final double progress;
  final Color accentColor;
  final VoidCallback onBack;
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
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        )),
                    Text(
                      '${index + 1} / $total  •  ✓ $score correct',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onSpeak,
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.volume_up_rounded,
                      color: Colors.white, size: 18),
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

// ── Quiz flash card ───────────────────────────────────────────────────────────
// ── Custom quiz top bar ───────────────────────────────────────────────────────

class _QuizTopBar extends StatelessWidget {
  final String title;
  final int index;
  final int total;
  final int score;
  final double progress;
  final Color accentColor;
  final VoidCallback onBack;
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
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        )),
                    Text(
                      '${index + 1} / $total  •  ✓ $score correct',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.white70),
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
                  child: const Icon(Icons.volume_up_rounded,
                      color: Colors.white, size: 18),
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

// ── Quiz flash card ───────────────────────────────────────────────────────────

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
    final isSpeakCard = card.kind == _QKind.speakWord;

    Widget choiceButton(int i) {
      Color btnColor = Colors.white;
      Color borderColor = const Color(0xFFE5E7EB);
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
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () => onChoice(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: btnColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Directionality(
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.13),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
          BoxShadow(
            color: color.withOpacity(0.13),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Card top (warm peach) ─────────────────────────────────────
          Flexible(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _kCardTop,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Prompt label
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Transform.translate(
                      offset: const Offset(0, -1.5),
                      child: Text(
                        card.choices[i],
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'NotoNastaliqUrdu',
                          fontSize: 18,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (revealed && i == card.correctIndex)
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.green, size: 20),
                if (revealed && i == chosen && i != card.correctIndex)
                  const Icon(Icons.cancel_rounded, color: Colors.red, size: 20),
              ],
            ),
          ),
        ),
      );
    }

    Widget speakControls() {
      return Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CircBtn(
                    icon: Icons.volume_up_rounded,
                    label: 'Listen',
                    color: _kTeal,
                    filled: speaking,
                    onTap: onSpeak,
                  ),
                  const SizedBox(width: 28),
                  _CircBtn(
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
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.18),
                      const Color(0xFFFFF3E0),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.84),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text('💭', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(height: 6),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Transform.translate(
                        offset: const Offset(0, -1),
                        child: Text(
                          card.kind == _QKind.speakWord
                              ? 'یہ لفظ بولیں'
                              : 'یہ کیا ہے؟',
                          style: TextStyle(
                            fontFamily: 'NotoNastaliqUrdu',
                            fontSize: 12,
                            color: Colors.brown.shade400,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      card.emoji,
                      style: TextStyle(
                        fontSize: isSpeakCard ? 48 : 54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                color: const Color(0xFFFEF9D7),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
                constraints: const BoxConstraints(minHeight: 140),
                clipBehavior: Clip.none,
                child: Center(
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      card.mainText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: isSpeakCard ? 30 : 21,
                        fontWeight: FontWeight.bold,
                        color: color,
                        height: 1.8,
                        leadingDistribution: TextLeadingDistribution.even,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: card.kind == _QKind.multiChoice
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...List.generate(card.choices.length, choiceButton),
                          if (revealed &&
                              chosen != null &&
                              chosen != card.correctIndex) ...[
                            const SizedBox(height: 2),
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
                                child: Transform.translate(
                                  offset: const Offset(0, -1),
                                  child: Text(
                                    'درست جواب: ${card.choices[card.correctIndex]}  (${card.transcription})',
                                    style: const TextStyle(
                                      fontFamily: 'NotoNastaliqUrdu',
                                      fontSize: 14,
                                      height: 1.35,
                                      color: Colors.green,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      )
                    : speakControls(),
                    child: Text(
                      card.kind == _QKind.speakWord
                          ? 'یہ لفظ بولیں'
                          : 'یہ کیا ہے؟',
                      style: TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: 14,
                        color: Colors.brown.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Emoji
                  Text(card.emoji,
                      style: const TextStyle(fontSize: 52)),
                  const SizedBox(height: 6),
                  // For speak cards also show the Urdu word
                  if (card.kind == _QKind.speakWord) ...[
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(card.mainText,
                          style: TextStyle(
                            fontFamily: 'NotoNastaliqUrdu',
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: color,
                            height: 1.2,
                          )),
                    ),
                    Text(card.name,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 6),
                    // Listen + Speak buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _CircBtn(
                            icon: Icons.volume_up_rounded,
                            color: _kTeal,
                            filled: speaking,
                            onTap: onSpeak),
                        const SizedBox(width: 14),
                        _CircBtn(
                            icon: Icons.mic_rounded,
                            color: _kPurple,
                            filled: false,
                            onTap: revealed ? null : onMic),
                      ],
                    ),
                    if (speakScore != null) ...[
                      const SizedBox(height: 8),
                      _ScoreBadge(score: speakScore!),
                    ],
                  ],
                ],
              ),
            ),
          ),

          // ── Card bottom (white — choices) ─────────────────────────────
          Flexible(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Multiple-choice options
                  if (card.kind == _QKind.multiChoice)
                    ...List.generate(card.choices.length, (i) {
                      Color btnColor = Colors.white;
                      Color borderColor = const Color(0xFFE5E7EB);
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
                        padding: const EdgeInsets.only(bottom: 9),
                        child: GestureDetector(
                          onTap: () => onChoice(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 13, horizontal: 14),
                            decoration: BoxDecoration(
                              color: btnColor,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: borderColor, width: 2),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Flexible(
                                    child: Text(card.choices[i],
                                        style: TextStyle(
                                          fontFamily: 'NotoNastaliqUrdu',
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                        )),
                                  ),
                                ),
                                if (revealed && i == card.correctIndex)
                                  const Icon(Icons.check_circle_rounded,
                                      color: Colors.green, size: 20),
                                if (revealed &&
                                    i == chosen &&
                                    i != card.correctIndex)
                                  const Icon(Icons.cancel_rounded,
                                      color: Colors.red, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
      child: Column(
        children: [
          // ── Card top (warm peach) ─────────────────────────────────────
          Flexible(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _kCardTop,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                  // Prompt label
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      card.kind == _QKind.speakWord
                          ? 'یہ لفظ بولیں'
                          : 'یہ کیا ہے؟',
                      style: TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: 14,
                        color: Colors.brown.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Emoji
                  Text(card.emoji,
                      style: const TextStyle(fontSize: 52)),
                  const SizedBox(height: 6),
                  // For speak cards also show the Urdu word
                  if (card.kind == _QKind.speakWord) ...[
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(card.mainText,
                            style: TextStyle(
                              fontFamily: 'NotoNastaliqUrdu',
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: color,
                              height: 1.2,
                            )),
                      ),
                    ),
                    Text(card.name,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 6),
                    // Listen + Speak buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _CircBtn(
                            icon: Icons.volume_up_rounded,
                            color: _kTeal,
                            filled: speaking,
                            onTap: onSpeak),
                        const SizedBox(width: 14),
                        _CircBtn(
                            icon: Icons.mic_rounded,
                            color: _kPurple,
                            filled: false,
                            onTap: revealed ? null : onMic),
                      ],
                    ),
                    if (speakScore != null) ...[
                      const SizedBox(height: 8),
                      _ScoreBadge(score: speakScore!),
                    ],
                  ],
                ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Card bottom (white — choices) ─────────────────────────────
          Flexible(
            flex: 6,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Multiple-choice options
                  if (card.kind == _QKind.multiChoice)
                    ...List.generate(card.choices.length, (i) {
                      Color btnColor = Colors.white;
                      Color borderColor = const Color(0xFFE5E7EB);
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
                        padding: const EdgeInsets.only(bottom: 9),
                        child: GestureDetector(
                          onTap: () => onChoice(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 13, horizontal: 14),
                            decoration: BoxDecoration(
                              color: btnColor,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: borderColor, width: 2),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(
                                      card.choices[i],
                                      style: TextStyle(
                                        fontFamily: 'NotoNastaliqUrdu',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (revealed && i == card.correctIndex)
                                  const Icon(Icons.check_circle_rounded,
                                      color: Colors.green, size: 20),
                                if (revealed &&
                                    i == chosen &&
                                    i != card.correctIndex)
                                  const Icon(Icons.cancel_rounded,
                                      color: Colors.red, size: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                  // Correct answer hint (when wrong)
                  if (revealed &&
                      card.kind == _QKind.multiChoice &&
                      chosen != null &&
                      chosen != card.correctIndex) ...[
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
                              fontSize: 14,
                              color: Colors.green),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        ],
                  // Correct answer hint (when wrong)
                  if (revealed &&
                      card.kind == _QKind.multiChoice &&
                      chosen != null &&
                      chosen != card.correctIndex) ...[
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
                              fontSize: 14,
                              color: Colors.green),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ),
    );
  }
}

// ── Score badge ───────────────────────────────────────────────────────────────

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
      SizedBox(
        width: 38, height: 38,
      SizedBox(
        width: 38,
        height: 38,
        child: Stack(alignment: Alignment.center, children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 4,
            backgroundColor: _color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(_color),
          ),
          Text('${score.toInt()}',
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.bold, color: _color)),
        ]),
      ),
      const SizedBox(width: 8),
      Text(
        score >= 70
            ? '🌟 شاباش!'
            : score >= 45
                ? '🔸 قریب!'
                : '❌ غلط',
        style: TextStyle(
          fontFamily: 'NotoNastaliqUrdu',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
      Text(
        score >= 70 ? '🌟 شاباش!' : score >= 45 ? '🔸 قریب!' : '❌ غلط',
        style: TextStyle(
          fontFamily: 'NotoNastaliqUrdu',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    ]);
  }
}

// ── Circle button ─────────────────────────────────────────────────────────────

class _CircBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;
  const _CircBtn(
      {required this.icon,
      required this.color,
      required this.filled,
      this.onTap});
  const _CircBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.filled,
      this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onTap == null
                    ? Colors.grey.shade200
                    : filled
                        ? color
                        : color.withOpacity(0.12),
                border: Border.all(
                  color: onTap == null ? Colors.grey.shade300 : color,
                  width: 2,
                ),
              ),
              child: Icon(icon,
                  color: onTap == null
                      ? Colors.grey
                      : filled
                          ? Colors.white
                          : color,
                  size: 22),
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
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 50, height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onTap == null
                ? Colors.grey.shade200
                : filled
                    ? color
                    : color.withOpacity(0.12),
            border: Border.all(
              color: onTap == null ? Colors.grey.shade300 : color,
              width: 2,
            ),
          ),
          child: Icon(icon,
              color: onTap == null
                  ? Colors.grey
                  : filled
                      ? Colors.white
                      : color,
              size: 22),
        ),
      );
}

// ── Pill button ───────────────────────────────────────────────────────────────

class _PillBtn extends StatelessWidget {
// ── Pill button ───────────────────────────────────────────────────────────────

class _PillBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final Color? border;
  final VoidCallback onTap;

  const _PillBtn({
    required this.label,
    required this.color,
    required this.textColor,
    this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
            border:
                border != null ? Border.all(color: border!, width: 1.5) : null,
            boxShadow: border == null
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: textColor)),
        ),
      );
}

// ── Mascot side (alphabet-style) ─────────────────────────────────────────────

class _MascotSide extends StatelessWidget {
  final String message;
  const _MascotSide({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          margin: const EdgeInsets.only(bottom: 5, right: 2),
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
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Text(message,
              style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5D4037)),
              textAlign: TextAlign.center),
        ),
        SizedBox(
          height: 148,
          width: 80,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: 0,
                left: 23,
                child: Container(
                  width: 34,
                  height: 15,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFD0D0D0)),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(17),
                      topRight: Radius.circular(17),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 13,
                left: 20,
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFD0D0D0)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 22,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFCC80),
                  ),
                  child: Stack(children: [
                    Positioned(
                        top: 10,
                        left: 7,
                        child: Container(
                            width: 6,
                            height: 7,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3E2723),
                              borderRadius: BorderRadius.circular(3),
                            ))),
                    Positioned(
                        top: 10,
                        right: 7,
                        child: Container(
                            width: 6,
                            height: 7,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3E2723),
                              borderRadius: BorderRadius.circular(3),
                            ))),
                    Positioned(
                      bottom: 7,
                      left: 8,
                      child: Container(
                        width: 20,
                        height: 10,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Color(0xFFBF360C), width: 2.5),
                            left: BorderSide(
                                color: Color(0xFFBF360C), width: 2.5),
                            right: BorderSide(
                                color: Color(0xFFBF360C), width: 2.5),
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              Positioned(
                top: 49,
                left: 36,
                child: Container(
                    width: 8, height: 7, color: const Color(0xFFFFCC80)),
              ),
              Positioned(
                top: 54,
                left: 14,
                child: Container(
                  width: 52,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Positioned(
                top: 54,
                left: 18,
                child: Container(
                  width: 44,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF388E3C),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
              Positioned(
                top: 56,
                left: 32,
                child: Container(
                  width: 16,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Positioned(
                top: 58,
                right: 2,
                child: Transform.rotate(
                  angle: -0.55,
                  child: Container(
                    width: 24,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCC80),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 65,
                left: 4,
                child: Container(
                  width: 14,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              Positioned(
                top: 101,
                left: 18,
                child: Container(
                  width: 17,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              Positioned(
                top: 101,
                left: 44,
                child: Container(
                  width: 17,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              Positioned(
                top: 134,
                left: 14,
                child: Container(
                  width: 24,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4E342E),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              Positioned(
                top: 134,
                left: 41,
                child: Container(
                  width: 24,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4E342E),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Tip side (alphabet-style) ───────────────────────────────────────────────

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
          const Text('Tip',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6A1B9A))),
          const SizedBox(height: 6),
          Text(
            text,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 9.5, color: Color(0xFF37474F), height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
            border: border != null
                ? Border.all(color: border!, width: 1.5)
                : null,
            boxShadow: border == null
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
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
    _slideAnim = Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    _buildDeck();
    _slideCtrl.forward();
    _speakCurrent();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _buildDeck() {
    final shuffled = List.of(SENTENCES)..shuffle(_rng);
    _deck = shuffled.take(_total).map((s) {
      final blank = s.blankWord;
      final others =
          s.words.where((w) => w != blank).toList()..shuffle(_rng);
      final others = s.words.where((w) => w != blank).toList()..shuffle(_rng);
      final distractors = others.take(3).toList();
      if (distractors.length < 3) {
        final extra = WORDS
            .where((w) => !distractors.contains(w.urdu))
            .toList()
          ..shuffle(_rng);
        while (distractors.length < 3) {
          distractors.add(extra[distractors.length].urdu);
        }
        final extra = WORDS.where((w) => !distractors.contains(w.urdu)).toList()
          ..shuffle(_rng);
        while (distractors.length < 3) {
          distractors.add(extra[distractors.length].urdu);
        }
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
    setState(() {
      _chosen = i;
      _revealed = true;
    });
    setState(() {
      _chosen = i;
      _revealed = true;
    });
    TtsService.instance
        .speak(i == _deck[_index].correctIndex ? 'شاباش! بہت اچھے!' : 'غلط!');
  }

  void _goNext() {
    if (_index >= _deck.length - 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultsScreen(
            score: _score,
            total: _total,
            title: 'Sentence Quiz',
            accentColor: _color,
            onRestart: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const SentenceQuizScreen()),
            ),
          ),
        ),
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultsScreen(
            score: _score,
            total: _total,
            title: 'Sentence Quiz',
            accentColor: _color,
            restartBuilder: (_) => const SentenceQuizScreen(),
          ),
        ),
      );
      return;
    }
    setState(() {
      _index++;
      _chosen = null;
      _revealed = false;
    });
    _slideCtrl.forward(from: 0);
    _speakCurrent();
  }

  @override
  Widget build(BuildContext context) {
    final card = _deck[_index];
    final progress = (_index + 1) / _total;
    const msg = 'Fun!\nMeet\nSentence';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _color,
                _color.withOpacity(0.6),
                const Color(0xFFFFF3E0),
                const Color(0xFFFFF8E8),
              ],
              stops: const [0.0, 0.18, 0.48, 1.0],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                ..._decorStars(),
                Column(
                  children: [
                    _QuizTopBar(
                      title: 'Sentence Quiz',
                      index: _index,
                      total: _total,
                      score: _score,
                      progress: progress,
                      accentColor: _color,
                      onBack: () => Navigator.pop(context),
                      onSpeak: _speakCurrent,
                    ),
                    Expanded(
                      child: LayoutBuilder(builder: (ctx, bc) {
                        final isWide = bc.maxWidth > 460;
                        final sideW = isWide ? 72.0 : 44.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: sideW,
                                          child: _MascotSide(message: msg),
                                        ),
                                        Expanded(
                                          child: Center(
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                  maxWidth: 300),
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(28),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.18),
                                                      blurRadius: 22,
                                                      offset:
                                                          const Offset(0, 8),
                                                    ),
                                                  ],
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(28),
                                                  child: Column(
                                                    children: [
                                                      Flexible(
                                                        flex: 2,
                                                        child: Container(
                                                          width:
                                                              double.infinity,
                                                          padding:
                                                              const EdgeInsets
                                                                  .fromLTRB(16,
                                                                  14, 16, 10),
                                                          decoration:
                                                              const BoxDecoration(
                                                            color: _kCardTop,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .only(
                                                              topLeft: Radius
                                                                  .circular(28),
                                                              topRight: Radius
                                                                  .circular(28),
                                                            ),
                                                          ),
                                                          child:
                                                              SingleChildScrollView(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        6),
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                const Text('💬',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            32)),
                                                                const SizedBox(
                                                                    height: 4),
                                                                Directionality(
                                                                  textDirection:
                                                                      TextDirection
                                                                          .rtl,
                                                                  child: Text(
                                                                    'خالی جگہ بھریں',
                                                                    style:
                                                                        TextStyle(
                                                                      fontFamily:
                                                                          'NotoNastaliqUrdu',
                                                                      fontSize:
                                                                          12,
                                                                      color: Colors
                                                                          .brown
                                                                          .shade400,
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 2),
                                                                Padding(
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          8),
                                                                  child:
                                                                      FittedBox(
                                                                    fit: BoxFit
                                                                        .scaleDown,
                                                                    child:
                                                                        SizedBox(
                                                                      width:
                                                                          220,
                                                                      child:
                                                                          Directionality(
                                                                        textDirection:
                                                                            TextDirection.rtl,
                                                                        child:
                                                                            RichText(
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                          textDirection:
                                                                              TextDirection.rtl,
                                                                          text:
                                                                              TextSpan(
                                                                            style:
                                                                                const TextStyle(
                                                                              fontFamily: 'NotoNastaliqUrdu',
                                                                              fontSize: 16,
                                                                              color: Color(0xFF1C1917),
                                                                              height: 1.15,
                                                                            ),
                                                                            children:
                                                                                _buildSentenceSpan(card),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    height: 2),
                                                                Text(
                                                                  card.english,
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    color: Colors
                                                                        .grey,
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  maxLines: 2,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Flexible(
                                                        flex: 5,
                                                        child:
                                                            SingleChildScrollView(
                                                          padding:
                                                              const EdgeInsets
                                                                  .fromLTRB(16,
                                                                  14, 16, 12),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children:
                                                                List.generate(
                                                                    card.choices
                                                                        .length,
                                                                    (i) {
                                                              Color btnColor =
                                                                  Colors.white;
                                                              Color
                                                                  borderColor =
                                                                  const Color(
                                                                      0xFFE5E7EB);
                                                              Color textColor =
                                                                  const Color(
                                                                      0xFF1C1917);
                                                              if (_revealed) {
                                                                if (i ==
                                                                    card
                                                                        .correctIndex) {
                                                                  btnColor = Colors
                                                                      .green
                                                                      .shade50;
                                                                  borderColor =
                                                                      Colors
                                                                          .green;
                                                                  textColor = Colors
                                                                      .green
                                                                      .shade800;
                                                                } else if (i ==
                                                                    _chosen) {
                                                                  btnColor = Colors
                                                                      .red
                                                                      .shade50;
                                                                  borderColor =
                                                                      Colors
                                                                          .red;
                                                                  textColor = Colors
                                                                      .red
                                                                      .shade800;
                                                                }
                                                              }
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        bottom:
                                                                            9),
                                                                child:
                                                                    GestureDetector(
                                                                  onTap: () =>
                                                                      _onChoice(
                                                                          i),
                                                                  child:
                                                                      AnimatedContainer(
                                                                    duration: const Duration(
                                                                        milliseconds:
                                                                            200),
                                                                    width: double
                                                                        .infinity,
                                                                    padding: const EdgeInsets
                                                                        .symmetric(
                                                                        vertical:
                                                                            11,
                                                                        horizontal:
                                                                            14),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color:
                                                                          btnColor,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              14),
                                                                      border: Border.all(
                                                                          color:
                                                                              borderColor,
                                                                          width:
                                                                              2),
                                                                    ),
                                                                    child: Row(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Expanded(
                                                                          child:
                                                                              Directionality(
                                                                            textDirection:
                                                                                TextDirection.rtl,
                                                                            child:
                                                                                Text(
                                                                              card.choices[i],
                                                                              textAlign: TextAlign.right,
                                                                              maxLines: 2,
                                                                              overflow: TextOverflow.ellipsis,
                                                                              style: TextStyle(
                                                                                fontFamily: 'NotoNastaliqUrdu',
                                                                                fontSize: 17,
                                                                                fontWeight: FontWeight.w700,
                                                                                color: textColor,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                10),
                                                                        if (_revealed &&
                                                                            i ==
                                                                                card
                                                                                    .correctIndex)
                                                                          const Icon(
                                                                              Icons.check_circle_rounded,
                                                                              color: Colors.green,
                                                                              size: 20),
                                                                        if (_revealed &&
                                                                            i ==
                                                                                _chosen &&
                                                                            i !=
                                                                                card
                                                                                    .correctIndex)
                                                                          const Icon(
                                                                              Icons.cancel_rounded,
                                                                              color: Colors.red,
                                                                              size: 20),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            }),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: sideW,
                                          child: _TipSide(text: card.english),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 8, 0, 20),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        _PillBtn(
                                          label: _revealed
                                              ? (_index == _total - 1
                                                  ? 'Finish ✓'
                                                  : 'Next →')
                                              : 'Skip →',
                                          color: _revealed
                                              ? _kOrange
                                              : Colors.grey.shade300,
                                          textColor: _revealed
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                          onTap: _goNext,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        backgroundColor: _kBg,
        body: Column(
          children: [
            _QuizTopBar(
              title: 'Sentence Quiz',
              index: _index,
              total: _total,
              score: _score,
              progress: progress,
              accentColor: _color,
              onBack: () => Navigator.pop(context),
              onSpeak: _speakCurrent,
        backgroundColor: _kBg,
        body: Column(
          children: [
            _QuizTopBar(
              title: 'Sentence Quiz',
              index: _index,
              total: _total,
              score: _score,
              progress: progress,
              accentColor: _color,
              onBack: () => Navigator.pop(context),
              onSpeak: _speakCurrent,
            ),
            Expanded(
              child: LayoutBuilder(builder: (ctx, bc) {
                final cardWidth =
                    bc.maxWidth > 600 ? 480.0 : bc.maxWidth - 32;
                return Center(
                  child: SizedBox(
                    width: cardWidth,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Expanded(
                          child: SlideTransition(
                            position: _slideAnim,
                            child: FadeTransition(
                              opacity: _fadeAnim,
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _color.withOpacity(0.12),
                                      blurRadius: 18,
                                      offset: const Offset(0, 7),
                                    )
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Top warm section
                                    Flexible(
                                      flex: 3,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 18, 16, 14),
                                        decoration: const BoxDecoration(
                                          color: _kCardTop,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(24),
                                            topRight: Radius.circular(24),
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text('💬',
                                                style: TextStyle(
                                                    fontSize: 40)),
                                            const SizedBox(height: 8),
                                            Directionality(
                                              textDirection:
                                                  TextDirection.rtl,
                                              child: Text(
                                                'خالی جگہ بھریں',
                                                style: TextStyle(
                                                  fontFamily:
                                                      'NotoNastaliqUrdu',
                                                  fontSize: 16,
                                                  color: Colors
                                                      .brown.shade400,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            // Sentence with blank
                                            Directionality(
                                              textDirection:
                                                  TextDirection.rtl,
                                              child: RichText(
                                                textAlign:
                                                    TextAlign.center,
                                                textDirection:
                                                    TextDirection.rtl,
                                                text: TextSpan(
                                                  style: const TextStyle(
                                                    fontFamily:
                                                        'NotoNastaliqUrdu',
                                                    fontSize: 22,
                                                    color:
                                                        Color(0xFF1C1917),
                                                    height: 1.8,
                                                  ),
                                                  children:
                                                      _buildSentenceSpan(
                                                          card),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              card.english,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Bottom white — choices
                                    Flexible(
                                      flex: 5,
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 14, 16, 12),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: List.generate(
                                              card.choices.length, (i) {
                                            Color btnColor = Colors.white;
                                            Color borderColor =
                                                const Color(0xFFE5E7EB);
                                            Color textColor =
                                                const Color(0xFF1C1917);
                                            if (_revealed) {
                                              if (i ==
                                                  card.correctIndex) {
                                                btnColor =
                                                    Colors.green.shade50;
                                                borderColor = Colors.green;
                                                textColor =
                                                    Colors.green.shade800;
                                              } else if (i == _chosen) {
                                                btnColor =
                                                    Colors.red.shade50;
                                                borderColor = Colors.red;
                                                textColor =
                                                    Colors.red.shade800;
                                              }
                                            }
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.only(
                                                      bottom: 9),
                                              child: GestureDetector(
                                                onTap: () => _onChoice(i),
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 200),
                                                  width: double.infinity,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 13,
                                                      horizontal: 14),
                                                  decoration: BoxDecoration(
                                                    color: btnColor,
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(14),
                                                    border: Border.all(
                                                        color: borderColor,
                                                        width: 2),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Directionality(
                                                        textDirection:
                                                            TextDirection
                                                                .rtl,
                                                        child: Flexible(
                                                          child: Text(
                                                            card.choices[i],
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'NotoNastaliqUrdu',
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color:
                                                                  textColor,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      if (_revealed &&
                                                          i ==
                                                              card.correctIndex)
                                                        const Icon(
                                                            Icons
                                                                .check_circle_rounded,
                                                            color:
                                                                Colors.green,
                                                            size: 20),
                                                      if (_revealed &&
                                                          i == _chosen &&
                                                          i !=
                                                              card.correctIndex)
                                                        const Icon(
                                                            Icons
                                                                .cancel_rounded,
                                                            color:
                                                                Colors.red,
                                                            size: 20),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
            Expanded(
              child: LayoutBuilder(builder: (ctx, bc) {
                final cardWidth =
                    bc.maxWidth > 600 ? 480.0 : bc.maxWidth - 32;
                return Center(
                  child: SizedBox(
                    width: cardWidth,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Expanded(
                          child: SlideTransition(
                            position: _slideAnim,
                            child: FadeTransition(
                              opacity: _fadeAnim,
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _color.withOpacity(0.12),
                                      blurRadius: 18,
                                      offset: const Offset(0, 7),
                                    )
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Top warm section
                                    Flexible(
                                      flex: 3,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 18, 16, 14),
                                        decoration: const BoxDecoration(
                                          color: _kCardTop,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(24),
                                            topRight: Radius.circular(24),
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text('💬',
                                                style: TextStyle(
                                                    fontSize: 40)),
                                            const SizedBox(height: 8),
                                            Directionality(
                                              textDirection:
                                                  TextDirection.rtl,
                                              child: Text(
                                                'خالی جگہ بھریں',
                                                style: TextStyle(
                                                  fontFamily:
                                                      'NotoNastaliqUrdu',
                                                  fontSize: 16,
                                                  color: Colors
                                                      .brown.shade400,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            // Sentence with blank
                                            Directionality(
                                              textDirection:
                                                  TextDirection.rtl,
                                              child: RichText(
                                                textAlign:
                                                    TextAlign.center,
                                                textDirection:
                                                    TextDirection.rtl,
                                                text: TextSpan(
                                                  style: const TextStyle(
                                                    fontFamily:
                                                        'NotoNastaliqUrdu',
                                                    fontSize: 22,
                                                    color:
                                                        Color(0xFF1C1917),
                                                    height: 1.8,
                                                  ),
                                                  children:
                                                      _buildSentenceSpan(
                                                          card),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              card.english,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Bottom white — choices
                                    Flexible(
                                      flex: 5,
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 14, 16, 12),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: List.generate(
                                              card.choices.length, (i) {
                                            Color btnColor = Colors.white;
                                            Color borderColor =
                                                const Color(0xFFE5E7EB);
                                            Color textColor =
                                                const Color(0xFF1C1917);
                                            if (_revealed) {
                                              if (i ==
                                                  card.correctIndex) {
                                                btnColor =
                                                    Colors.green.shade50;
                                                borderColor = Colors.green;
                                                textColor =
                                                    Colors.green.shade800;
                                              } else if (i == _chosen) {
                                                btnColor =
                                                    Colors.red.shade50;
                                                borderColor = Colors.red;
                                                textColor =
                                                    Colors.red.shade800;
                                              }
                                            }
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.only(
                                                      bottom: 9),
                                              child: GestureDetector(
                                                onTap: () => _onChoice(i),
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                      milliseconds: 200),
                                                  width: double.infinity,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      vertical: 13,
                                                      horizontal: 14),
                                                  decoration: BoxDecoration(
                                                    color: btnColor,
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(14),
                                                    border: Border.all(
                                                        color: borderColor,
                                                        width: 2),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Directionality(
                                                          textDirection:
                                                              TextDirection.rtl,
                                                          child: Text(
                                                            card.choices[i],
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'NotoNastaliqUrdu',
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color:
                                                                  textColor,
                                                            ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            textAlign:
                                                                TextAlign.right,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      if (_revealed &&
                                                          i ==
                                                              card.correctIndex)
                                                        const Icon(
                                                            Icons
                                                                .check_circle_rounded,
                                                            color:
                                                                Colors.green,
                                                            size: 20),
                                                      if (_revealed &&
                                                          i == _chosen &&
                                                          i !=
                                                              card.correctIndex)
                                                        const Icon(
                                                            Icons
                                                                .cancel_rounded,
                                                            color:
                                                                Colors.red,
                                                            size: 20),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Nav row
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(0, 8, 0, 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _PillBtn(
                                label: _revealed
                                    ? (_index == _total - 1
                                        ? 'Finish ✓'
                                        : 'Next →')
                                    : 'Skip →',
                                color: _revealed
                                    ? _kOrange
                                    : Colors.grey.shade300,
                                textColor: _revealed
                                    ? Colors.white
                                    : Colors.grey.shade600,
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
          ],
        ),
                        // Nav row
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(0, 8, 0, 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _PillBtn(
                                label: _revealed
                                    ? (_index == _total - 1
                                        ? 'Finish ✓'
                                        : 'Next →')
                                    : 'Skip →',
                                color: _revealed
                                    ? _kOrange
                                    : Colors.grey.shade300,
                                textColor: _revealed
                                    ? Colors.white
                                    : Colors.grey.shade600,
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
          ],
        ),
      ),
    );
  }

  List<Widget> _decorStars() {
    const stars = [
      {'top': 82.0, 'left': 10.0, 'size': 18.0, 'op': 0.7},
      {'top': 136.0, 'left': 28.0, 'size': 12.0, 'op': 0.5},
      {'top': 220.0, 'left': 6.0, 'size': 22.0, 'op': 0.6},
      {'top': 82.0, 'right': 8.0, 'size': 16.0, 'op': 0.7},
      {'top': 158.0, 'right': 24.0, 'size': 20.0, 'op': 0.55},
      {'top': 250.0, 'right': 6.0, 'size': 14.0, 'op': 0.6},
    ];
    final List<Widget> widgets = stars
        .map<Widget>((d) => Positioned(
              top: d['top'] as double,
              left: d.containsKey('left') ? d['left'] as double : null,
              right: d.containsKey('right') ? d['right'] as double : null,
              child: Opacity(
                opacity: d['op'] as double,
                child:
                    Text('⭐', style: TextStyle(fontSize: d['size'] as double)),
              ),
            ))
        .toList();

    widgets.addAll([
      const Positioned(
          top: 58,
          left: 50,
          child: Opacity(
              opacity: 0.55,
              child: Text('☁️', style: TextStyle(fontSize: 28)))),
      const Positioned(
          top: 62,
          right: 55,
          child: Opacity(
              opacity: 0.45,
              child: Text('☁️', style: TextStyle(fontSize: 22)))),
      const Positioned(
          top: 48,
          left: 130,
          child: Opacity(
              opacity: 0.35,
              child: Text('☁️', style: TextStyle(fontSize: 18)))),
    ]);

    widgets.add(
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: SizedBox(
          height: 28,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List<Widget>.generate(
                18,
                (i) => Padding(
                      padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                      child: Text(
                        i % 3 == 0
                            ? '🌿'
                            : i % 3 == 1
                                ? '🌱'
                                : '🌸',
                        style: TextStyle(fontSize: i % 2 == 0 ? 18.0 : 14.0),
                      ),
                    )),
          ),
        ),
      ),
    );

    return widgets;
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
            height: 1.2,
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
    required this.sentence, required this.blank,
    required this.english, required this.choices,
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

class QuizResultsScreen extends StatelessWidget {
  final int score;
  final int total;
  final String title;
  final Color accentColor;
  final Color accentColor;
  final WidgetBuilder restartBuilder;

  const QuizResultsScreen({
    super.key,
    required this.score, required this.total,
    required this.title, required this.accentColor,
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
    final pct = score / total;
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
    final topMsg = stars == 3
        ? 'بہت اچھے! شاندار! U0001F389'
        : stars == 2
            ? 'اچھا! مزید مشق کریں U0001F4AA'
            : 'ہمت نہ ہاریں! دوبارہ کوشش کریں U0001F4DA';
    final color = pct >= 0.8 ? Colors.green : pct >= 0.5 ? Colors.orange : Colors.red;
    final topMsg = stars == 3
        ? 'بہت اچھے! شاندار! 🎉'
        : stars == 2
            ? 'اچھا! مزید مشق کریں 💪'
            : 'ہمت نہ ہاریں! دوبارہ کوشش کریں';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(i < stars ? '⭐' : '☆',
                        style: TextStyle(
                            fontSize: i < stars ? 44 : 34,
                            color: i < stars ? Colors.amber : Colors.grey.shade300)),
                  )),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: Colors.white,
                    border: Border.all(color: color, width: 5),
                    boxShadow: [BoxShadow(color: color.withOpacity(0.20), blurRadius: 20)],
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('$score/$total',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
                    const Text('score', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ]),
                ),
                const SizedBox(height: 16),
                Directionality(textDirection: TextDirection.rtl,
                  child: Text(topMsg,
                      style: TextStyle(fontFamily: 'NotoNastaliqUrdu',
                          fontSize: 20, color: Colors.grey[700]),
                      textAlign: TextAlign.center)),
                const SizedBox(height: 36),
                GestureDetector(
                  onTap: onRestart,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(color: accentColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(
                            color: accentColor.withOpacity(0.25),
                            blurRadius: 10, offset: const Offset(0, 4))]),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Try Again', style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                    ]),
        backgroundColor: _kBg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            3,
                            (i) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: Text(
                                i < stars ? '⭐' : '☆',
                                style: TextStyle(
                                  fontSize: i < stars ? 44 : 34,
                                  color: i < stars
                                      ? Colors.amber
                                      : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Icon(Icons.stars_rounded, color: color, size: 32),
                        const SizedBox(height: 12),
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: color, width: 5),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.20),
                                blurRadius: 20,
                              )
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
                                style:
                                    TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              topMsg,
                              style: TextStyle(
                                fontFamily: 'NotoNastaliqUrdu',
                                fontSize: 20,
                                color: Colors.grey[700],
                                height: 1.35,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.8,
                    child: Material(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(30),
                      elevation: 0,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: restartBuilder),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh_rounded,
                                  color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Try Again',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 2)),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.home_rounded, color: Color(0xFF6B7280), size: 20),
                      SizedBox(width: 8),
                      Text('Home', style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF6B7280))),
                    ]),
                const SizedBox(height: 12),
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.8,
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.popUntil(context, (r) => r.isFirst),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                              color: const Color(0xFFE5E7EB), width: 2),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home_rounded,
                                color: Color(0xFF6B7280), size: 20),
                            SizedBox(width: 8),
                            Text('Home',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6B7280))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
