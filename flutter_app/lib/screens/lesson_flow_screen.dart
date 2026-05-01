import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../widgets/mic_recorder_widget.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

// ── Generic lesson card model ──────────────────────────────────────────────

class LessonCard {
  final String mainText;     // Urdu letter / word / numeral
  final String name;         // e.g. "Alif", "Kutta", "Aik"
  final String transcription;// e.g. "a", "Dog", "1"
  final String emoji;        // visual aid
  final String speakText;    // what TTS should say
  final String? romanTarget; // for mic scoring

  const LessonCard({
    required this.mainText,
    required this.name,
    required this.transcription,
    required this.emoji,
    required this.speakText,
    this.romanTarget,
  });
}

// ── Screen ─────────────────────────────────────────────────────────────────

class LessonFlowScreen extends StatefulWidget {
  final int lessonNumber;
  final String title;
  final String subtitle;
  final Color accentColor;
  final List<LessonCard> cards;
  /// true = quiz mode: shuffled, tracks scores, shows results on Finish
  final bool isQuiz;

  const LessonFlowScreen({
    super.key,
    required this.lessonNumber,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.cards,
    this.isQuiz = false,
  });

  @override
  State<LessonFlowScreen> createState() => _LessonFlowScreenState();
}

class _LessonFlowScreenState extends State<LessonFlowScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  bool _speaking = false;
  double? _lastScore;
  // Quiz mode: track per-card mic scores
  final Map<int, double> _quizScores = {};

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _slideAnim = Tween<Offset>(
            begin: const Offset(0.18, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
    // Lessons: auto-speak first card. Quiz: student speaks, not us.
    if (!widget.isQuiz) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _speak();
      });
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  LessonCard get _card => widget.cards[_index];

  void _goTo(int i) {
    if (i < 0 || i >= widget.cards.length) return;
    setState(() {
      _index = i;
      _lastScore = null;
    });
    _slideCtrl.forward(from: 0);
    // Lessons: auto-speak on every card change. Quiz: student drives.
    if (!widget.isQuiz) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _speak();
      });
    }
  }

  Future<void> _speak() async {
    setState(() => _speaking = true);
    await TtsService.instance.speak(_card.speakText);
    if (mounted) setState(() => _speaking = false);
  }

  void _openMic() {
    final card = _card;
    final cardIndex = _index;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MicRecorderWidget(
        targetText: card.mainText,
        targetRoman: card.romanTarget ?? card.name,
        onScore: (score, _) {
          Navigator.pop(context);
          setState(() {
            _lastScore = score;
            if (widget.isQuiz) _quizScores[cardIndex] = score;
          });
          context.read<AppProvider>().recordResult(card.mainText, score);
          TtsService.instance.speak(
              score >= 70 ? 'شاباش! بہت اچھا!' : 'دوبارہ کوشش کریں۔');
        },
      ),
    );
  }

  void _showQuizResults() {
    final correct = _quizScores.values.where((s) => s >= 70).length;
    final total = widget.cards.length;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => _QuizResultPage(
          correct: correct,
          total: total,
          color: widget.accentColor,
          title: widget.title,
          onRestart: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => LessonFlowScreen(
                lessonNumber: widget.lessonNumber,
                title: widget.title,
                subtitle: widget.subtitle,
                accentColor: widget.accentColor,
                cards: List.of(widget.cards)..shuffle(),
                isQuiz: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.cards.length;
    final progress = (_index + 1) / total;
    final color = widget.accentColor;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
      backgroundColor: AppTheme.bgWarm,
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.isQuiz ? 'Quiz ${widget.lessonNumber}' : 'Lesson ${widget.lessonNumber}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800,
                    color: Colors.white)),
            Text(widget.subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
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
      body: LayoutBuilder(builder: (ctx, constraints) {
        final w = constraints.maxWidth;
        final isWide = w > 600;
        final cardWidth = isWide ? 480.0 : w - 32;

        return Center(
          child: SizedBox(
            width: cardWidth,
            child: Column(
              children: [
                const SizedBox(height: 16),

                // ── Counter ──────────────────────────────────────────────
                Text(
                  '${_index + 1} / $total',
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Flashcard ────────────────────────────────────────────
                Expanded(
                  child: SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: _FlashCard(
                        card: _card,
                        color: color,
                        speaking: _speaking,
                        lastScore: _lastScore,
                        onSpeak: _speak,
                        onMic: _openMic,
                        isQuiz: widget.isQuiz,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Navigation row ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back
                      if (_index > 0)
                        _NavButton(
                          label: '← Back',
                          color: color.withOpacity(0.15),
                          textColor: color,
                          onTap: () => _goTo(_index - 1),
                        )
                      else
                        const SizedBox(width: 100),

                      // Finish / Next
                      _NavButton(
                        label: _index == total - 1
                            ? (widget.isQuiz ? 'Results 🏆' : 'Finish ✓')
                            : 'Next →',
                        color: color,
                        textColor: Colors.white,
                        onTap: _index == total - 1
                            ? (widget.isQuiz
                                ? _showQuizResults
                                : () => Navigator.pop(context))
                            : () => _goTo(_index + 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ));
  }
}

// ── Flashcard widget ──────────────────────────────────────────────────────────

class _FlashCard extends StatelessWidget {
  final LessonCard card;
  final Color color;
  final bool speaking;
  final double? lastScore;
  final VoidCallback onSpeak;
  final VoidCallback onMic;
  final bool isQuiz;

  const _FlashCard({
    required this.card,
    required this.color,
    required this.speaking,
    required this.lastScore,
    required this.onSpeak,
    required this.onMic,
    this.isQuiz = false,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = lastScore == null
        ? null
        : lastScore! >= 70
            ? Colors.green
            : lastScore! >= 50
                ? Colors.orange
                : Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Emoji ───────────────────────────────────────────────────
            Text(card.emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 12),

            // ── Main Urdu text ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  card.mainText,
                  style: TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Name + Transcription row ────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _InfoBox(label: 'Name',          value: card.name,          color: color),
                Container(width: 1, height: 44, color: const Color(0xFFE5E7EB)),
                _InfoBox(label: 'Transcription', value: card.transcription, color: color),
              ],
            ),

            const SizedBox(height: 16),

            if (isQuiz) ...[
              // ── QUIZ MODE ───────────────────────────────────────────────
              // Score ring (big, prominent) after speaking
              if (lastScore != null) ...[
                SizedBox(
                  width: 72, height: 72,
                  child: Stack(alignment: Alignment.center, children: [
                    CircularProgressIndicator(
                      value: lastScore! / 100,
                      strokeWidth: 6,
                      backgroundColor: scoreColor!.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    ),
                    Text('${lastScore!.toInt()}%',
                        style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w900, color: scoreColor)),
                  ]),
                ),
                const SizedBox(height: 8),
                Text(
                  lastScore! >= 70
                      ? '🌟 شاباش! درست تلفظ'
                      : lastScore! >= 50
                          ? '🔸 قریب ہے! دوبارہ کوشش کریں'
                          : '❌ غلط — دوبارہ سنیں اور بولیں',
                  style: TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scoreColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ] else ...[
                // No score yet — show call-to-action
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: const Color(0xFF8B5CF6).withOpacity(0.25)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic_rounded,
                          color: Color(0xFF8B5CF6), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Tap mic to pronounce',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Buttons: MIC (big, primary) + Listen (small, secondary)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Big mic — primary action
                  GestureDetector(
                    onTap: onMic,
                    child: Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF8B5CF6),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.35),
                            blurRadius: 14, spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.mic_rounded,
                          color: Colors.white, size: 30),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Small listen — optional
                  Tooltip(
                    message: 'Listen',
                    child: _CircleBtn(
                      icon: Icons.volume_up_rounded,
                      color: color.withOpacity(0.6),
                      filled: speaking,
                      onTap: onSpeak,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // ── LESSON MODE ─────────────────────────────────────────────
              // Small score ring
              if (lastScore != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 38, height: 38,
                      child: Stack(alignment: Alignment.center, children: [
                        CircularProgressIndicator(
                          value: lastScore! / 100,
                          strokeWidth: 4,
                          backgroundColor: scoreColor!.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                        ),
                        Text('${lastScore!.toInt()}',
                            style: TextStyle(fontSize: 9,
                                fontWeight: FontWeight.bold, color: scoreColor)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      lastScore! >= 70 ? '🌟 Great!' : '❌ Try again',
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w700, color: scoreColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Both buttons equal in lesson mode
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CircleBtn(icon: Icons.volume_up_rounded,
                      color: color, filled: speaking, onTap: onSpeak),
                  const SizedBox(width: 16),
                  _CircleBtn(icon: Icons.mic_rounded,
                      color: const Color(0xFF8B5CF6), filled: false, onTap: onMic),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InfoBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w600, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.color,
      required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 52, height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : color.withOpacity(0.1),
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: filled ? Colors.white : color, size: 24),
        ),
      );
}

class _NavButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  const _NavButton(
      {required this.label,
      required this.color,
      required this.textColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: textColor),
        ),
      ),
    );
  }
}

// ── Quiz Results Page ─────────────────────────────────────────────────────────

class _QuizResultPage extends StatelessWidget {
  final int correct;
  final int total;
  final Color color;
  final String title;
  final VoidCallback onRestart;

  const _QuizResultPage({
    required this.correct,
    required this.total,
    required this.color,
    required this.title,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? correct / total : 0.0;
    final stars = pct >= 0.8 ? 3 : pct >= 0.5 ? 2 : 1;
    final starColor = pct >= 0.8 ? Colors.green
        : pct >= 0.5 ? Colors.orange : Colors.red;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppTheme.bgWarm,
        appBar: AppBar(
          backgroundColor: color,
          foregroundColor: Colors.white,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Text('$title — Results',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('⭐' * stars,
                    style: const TextStyle(fontSize: 52)),
                const SizedBox(height: 16),
                Text('$correct / $total',
                    style: TextStyle(
                        fontSize: 52, fontWeight: FontWeight.w900,
                        color: starColor)),
                const SizedBox(height: 6),
                Text('${(pct * 100).round()}% correct',
                    style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 12),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    stars == 3 ? 'بہت اچھے! شاندار! 🎉'
                        : stars == 2 ? 'اچھا! مزید مشق کریں 💪'
                        : 'ہمت نہ ہاریں! دوبارہ کوشش کریں 📚',
                    style: TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: 18, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context)
                      .popUntil((route) => route.isFirst),
                  child: const Text('Back to Home',
                      style: TextStyle(fontSize: 14, color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

