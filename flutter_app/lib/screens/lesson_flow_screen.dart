import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../widgets/mic_recorder_widget.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

// ── Lesson card model ─────────────────────────────────────────────────────────

class LessonCard {
  final String mainText;
  final String name;
  final String transcription;
  final String emoji;
  final String speakText;
  final String? romanTarget;

  const LessonCard({
    required this.mainText,
    required this.name,
    required this.transcription,
    required this.emoji,
    required this.speakText,
    this.romanTarget,
  });
}

// ── Palette ───────────────────────────────────────────────────────────────────

const _kCardTop = Color(0xFFFFF3D6);
const _kTeal    = Color(0xFF26C6DA);
const _kOrange  = Color(0xFFFF7043);
const _kPurple  = Color(0xFF7C3AED);

const _mascotMsgs = [
  'Wow!\nThis is',  'Great!\nMeet',   'Hello!\nI\'m',
  'Look!\nIt\'s',   'Cool!\nThis is', 'Fun!\nMeet',
  'Listen!\nIt\'s', 'Nice!\nThis is', 'Learn!\nMeet',
  'Hey!\nI\'m',
];

// ── Screen ────────────────────────────────────────────────────────────────────

class LessonFlowScreen extends StatefulWidget {
  final int lessonNumber;
  final String title;
  final String subtitle;
  final Color accentColor;
  final List<LessonCard> cards;
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

// Maps lessonNumber to the named route used in lessons_hub_screen
const _lessonRouteMap = <int, String>{
  3: '/alfaz-lesson',
  7: '/animals-lesson',
  8: '/fruits-lesson',
  9: '/body-lesson',
};

class _LessonFlowScreenState extends State<LessonFlowScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  bool _speaking = false;
  double? _lastScore;
  final Map<int, double> _quizScores = {};

  late AnimationController _anim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0.10, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
    if (!widget.isQuiz) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _speak();
      });
    }
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  LessonCard get _card => widget.cards[_index];

  void _goTo(int i) {
    if (i < 0 || i >= widget.cards.length) return;
    setState(() { _index = i; _lastScore = null; });
    _anim.forward(from: 0);
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
    final idx  = _index;
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
            if (widget.isQuiz) _quizScores[idx] = score;
          });
          final provider = context.read<AppProvider>();
          provider.recordResult(card.mainText, score);
          final route = _lessonRouteMap[widget.lessonNumber];
          if (route != null) {
            provider.updateLessonProgress(route, (idx + 1) / widget.cards.length);
          }
          TtsService.instance.speak(
              score >= 70 ? 'شاباش! بہت اچھا!' : 'دوبارہ کوشش کریں۔');
        },
      ),
    );
  }

  void _showQuizResults() {
    final correct = _quizScores.values.where((s) => s >= 70).length;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => _QuizResultPage(
        correct: correct,
        total: widget.cards.length,
        color: widget.accentColor,
        title: widget.title,
        onRestart: () => Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => LessonFlowScreen(
            lessonNumber: widget.lessonNumber,
            title: widget.title,
            subtitle: widget.subtitle,
            accentColor: widget.accentColor,
            cards: List.of(widget.cards)..shuffle(),
            isQuiz: true,
          ),
        )),
      ),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final total   = widget.cards.length;
    final color   = widget.accentColor;
    final stars   = context.watch<AppProvider>().currentUser?.totalStars ?? 0;
    final progress = (_index + 1) / total;
    final msg = '${_mascotMsgs[_index % _mascotMsgs.length]} ${_card.name}!';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        body: Container(
          // Full-screen warm gradient: accent → amber → cream
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color,
                color.withOpacity(0.6),
                const Color(0xFFFFF3E0),
                const Color(0xFFFFF8E8),
              ],
              stops: const [0.0, 0.18, 0.48, 1.0],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: <Widget>[
                // ── Decorative floating stars ─────────────────────────────
                ..._decorStars(),

                Column(
                  children: [
                    // ── Top bar ───────────────────────────────────────────
                    _TopBar(
                      lessonNumber: widget.lessonNumber,
                      title: widget.title,
                      subtitle: widget.subtitle,
                      stars: stars,
                      isQuiz: widget.isQuiz,
                      color: color,
                      onBack: () => Navigator.pop(context),
                    ),

                    // ── Progress strip ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(children: [
                        // Counter pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.88),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Text('⭐', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text('${_index + 1} / $total',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF5D4037))),
                          ]),
                        ),
                        const SizedBox(width: 10),
                        // Progress bar
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor:
                                  Colors.white.withOpacity(0.35),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Percent
                        Text('${(progress * 100).round()}%',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ]),
                    ),

                    // ── Main: mascot | card | tip ─────────────────────────
                    Expanded(
                      child: LayoutBuilder(builder: (ctx, bc) {
                        final isWide = bc.maxWidth > 460;
                        final sideW  = isWide ? 72.0 : 48.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                children: [
                                  // Mascot (left)
                                  SizedBox(
                                      width: sideW,
                                      child: _MascotSide(message: msg)),
                                  // Card (center) — constrained width
                                  Expanded(
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 300),
                                        child: _buildCard(color),
                                      ),
                                    ),
                                  ),
                                  // Tip (right)
                                  SizedBox(
                                      width: sideW,
                                      child: _TipSide(
                                          text: _card.transcription)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    // ── Speak score ───────────────────────────────────────
                    if (_lastScore != null)
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 0, 20, 4),
                        child: _ScoreRow(
                          score: _lastScore!,
                          scoreColor: _lastScore! >= 70
                              ? Colors.green
                              : _lastScore! >= 50
                                  ? Colors.orange
                                  : Colors.red,
                        ),
                      ),

                    // ── Listen + Speak circles ─────────────────────────────
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(24, 4, 24, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _CircleBtn(
                            icon: Icons.volume_up_rounded,
                            label: 'Listen',
                            color: _kTeal,
                            active: _speaking,
                            onTap: _speak,
                          ),
                          const SizedBox(width: 36),
                          _CircleBtn(
                            icon: Icons.mic_rounded,
                            label: 'Speak',
                            color: _kPurple,
                            active: false,
                            onTap: _openMic,
                          ),
                        ],
                      ),
                    ),

                    // ── Next button ────────────────────────────────────────
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: _NextBtn(
                        label: _index == total - 1
                            ? (widget.isQuiz
                                ? '🏆  Results'
                                : '✓  Finish')
                            : 'Next  →',
                        color: _kOrange,
                        onTap: _index == total - 1
                            ? (widget.isQuiz
                                ? _showQuizResults
                                : () => Navigator.pop(context))
                            : () => _goTo(_index + 1),
                        hasBack: _index > 0,
                        onBack: () => _goTo(_index - 1),
                        accentColor: color,
                      ),
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

  // ── Decorative background elements ───────────────────────────────────────────
  List<Widget> _decorStars() {
    // Stars
    const stars = [
      {'top': 82.0,  'left': 10.0,  'size': 18.0, 'op': 0.70},
      {'top': 136.0, 'left': 28.0,  'size': 12.0, 'op': 0.50},
      {'top': 220.0, 'left': 6.0,   'size': 22.0, 'op': 0.60},
      {'top': 82.0,  'right': 8.0,  'size': 16.0, 'op': 0.70},
      {'top': 158.0, 'right': 24.0, 'size': 20.0, 'op': 0.55},
      {'top': 250.0, 'right': 6.0,  'size': 14.0, 'op': 0.60},
    ];
    final List<Widget> widgets = stars.map<Widget>((d) => Positioned(
      top:   d['top']   as double,
      left:  d.containsKey('left')  ? d['left']  as double : null,
      right: d.containsKey('right') ? d['right'] as double : null,
      child: Opacity(
        opacity: d['op'] as double,
        child: Text('⭐', style: TextStyle(fontSize: d['size'] as double)),
      ),
    )).toList();

    // Clouds at top
    widgets.addAll([
      const Positioned(top: 58, left: 50,
          child: Opacity(opacity: 0.55, child: Text('☁️', style: TextStyle(fontSize: 28)))),
      const Positioned(top: 62, right: 55,
          child: Opacity(opacity: 0.45, child: Text('☁️', style: TextStyle(fontSize: 22)))),
      const Positioned(top: 48, left: 130,
          child: Opacity(opacity: 0.35, child: Text('☁️', style: TextStyle(fontSize: 18)))),
    ]);

    // Grass strip at bottom
    widgets.add(
      Positioned(
        bottom: 0, left: 0, right: 0,
        child: SizedBox(
          height: 28,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List<Widget>.generate(18, (i) => Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
              child: Text(
                i % 3 == 0 ? '🌿' : i % 3 == 1 ? '🌱' : '🌸',
                style: TextStyle(fontSize: i % 2 == 0 ? 18.0 : 14.0),
              ),
            )),
          ),
        ),
      ),
    );

    return widgets;
  }

  // ── Adaptive font size for the cream text box ────────────────────────────────
  double _adaptiveFontSize(String text) {
    final len = text.replaceAll(' ', '').length; // ignore spaces
    if (len <= 2)  return 64.0;
    if (len <= 4)  return 52.0;
    if (len <= 7)  return 38.0;
    if (len <= 12) return 28.0;
    if (len <= 20) return 22.0;
    return 17.0;
  }

  // ── Card ──────────────────────────────────────────────────────────────────────
  Widget _buildCard(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            // ── Emoji banner at top ────────────────────────────────────
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
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
                child: Center(
                  child: Text(_card.emoji,
                      style: const TextStyle(fontSize: 72)),
                ),
              ),
            ),

            // ── Urdu letter/word/sentence in cream rounded box ─────
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 12),
              constraints: const BoxConstraints(minHeight: 80),
              decoration: BoxDecoration(
                color: _kCardTop,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    _card.mainText,
                    textAlign: TextAlign.center,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'NotoNastaliqUrdu',
                      fontSize: _adaptiveFontSize(_card.mainText),
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.1,
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
                  ),
                ),
              ),
            ),

            // ── Quiz hint ──────────────────────────────────────────────
            if (widget.isQuiz && _lastScore == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('Tap Speak to pronounce',
                    style: TextStyle(
                        fontSize: 11,
                        color: _kPurple.withOpacity(0.8),
                        fontWeight: FontWeight.w600)),
              ),

            // ── Name | Transcription ───────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Expanded(child: _InfoCell(
                      label: 'Name',
                      value: _card.name,
                      color: color)),
                  Container(
                      width: 1, height: 40,
                      color: const Color(0xFFE5E7EB)),
                  Expanded(child: _InfoCell(
                      label: 'Transcription',
                      value: _card.transcription,
                      color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int lessonNumber;
  final String title, subtitle;
  final int stars;
  final bool isQuiz;
  final Color color;
  final VoidCallback onBack;

  const _TopBar({
    required this.lessonNumber, required this.title,
    required this.subtitle, required this.stars,
    required this.isQuiz, required this.color,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(children: [
        // Back button
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
        ),
        // Title
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              isQuiz ? 'Quiz $lessonNumber' : 'Lesson $lessonNumber',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white),
            ),
            Text(subtitle,
                style: const TextStyle(fontSize: 10, color: Colors.white70),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        // Stars badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('⭐', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 3),
            Text('$stars',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ]),
        ),
        const SizedBox(width: 6),
        const Text('🏆', style: TextStyle(fontSize: 20)),
      ]),
    );
  }
}

// ── Mascot side — full-body boy ───────────────────────────────────────────────

class _MascotSide extends StatelessWidget {
  final String message;
  const _MascotSide({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Speech bubble
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
              BoxShadow(color: Colors.black.withOpacity(0.10),
                  blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Text(message,
              style: const TextStyle(
                  fontSize: 9.5, fontWeight: FontWeight.w800,
                  color: Color(0xFF5D4037)),
              textAlign: TextAlign.center),
        ),
        // Full-body boy drawn with Containers
        SizedBox(
          height: 148,
          width: 80,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: <Widget>[
              // Topi (white cap)
              Positioned(
                top: 0, left: 23,
                child: Container(
                  width: 34, height: 15,
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
              // Topi brim
              Positioned(
                top: 13, left: 20,
                child: Container(
                  width: 40, height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFD0D0D0)),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // Head (skin)
              Positioned(
                top: 16, left: 22,
                child: Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFCC80),
                  ),
                  child: Stack(children: [
                    // Eyes
                    Positioned(top: 10, left: 7,
                      child: Container(width: 6, height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3E2723),
                          borderRadius: BorderRadius.circular(3),
                        ))),
                    Positioned(top: 10, right: 7,
                      child: Container(width: 6, height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3E2723),
                          borderRadius: BorderRadius.circular(3),
                        ))),
                    // Smile
                    Positioned(
                      bottom: 7, left: 8,
                      child: Container(
                        width: 20, height: 10,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFBF360C), width: 2.5),
                            left:   BorderSide(color: Color(0xFFBF360C), width: 2.5),
                            right:  BorderSide(color: Color(0xFFBF360C), width: 2.5),
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft:  Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              // Neck
              Positioned(
                top: 49, left: 36,
                child: Container(width: 8, height: 7,
                    color: const Color(0xFFFFCC80)),
              ),
              // White kurta body
              Positioned(
                top: 54, left: 14,
                child: Container(
                  width: 52, height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              // Green vest
              Positioned(
                top: 54, left: 18,
                child: Container(
                  width: 44, height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF388E3C),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
              // White kurta centre strip
              Positioned(
                top: 56, left: 32,
                child: Container(
                  width: 16, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Right arm pointing toward card
              Positioned(
                top: 58, right: 2,
                child: Transform.rotate(
                  angle: -0.55,
                  child: Container(
                    width: 24, height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCC80),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
              // Left arm down
              Positioned(
                top: 65, left: 4,
                child: Container(
                  width: 14, height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              // Left leg (shalwar — light grey)
              Positioned(
                top: 101, left: 18,
                child: Container(
                  width: 17, height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              // Right leg
              Positioned(
                top: 101, left: 44,
                child: Container(
                  width: 17, height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              // Left shoe
              Positioned(
                top: 134, left: 14,
                child: Container(
                  width: 24, height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4E342E),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              // Right shoe
              Positioned(
                top: 134, left: 41,
                child: Container(
                  width: 24, height: 9,
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

// ── Tip side (right of card) ──────────────────────────────────────────────────

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
                fontSize: 9.5,
                color: Color(0xFF37474F),
                height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Circle action button ──────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _CircleBtn({
    required this.icon, required this.label,
    required this.color, required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 58, height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? color : color.withOpacity(0.14),
              border: Border.all(color: color, width: 2.5),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Icon(icon,
                color: active ? Colors.white : color, size: 26),
          ),
          const SizedBox(height: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

// ── Score row ─────────────────────────────────────────────────────────────────

class _ScoreRow extends StatelessWidget {
  final double score;
  final Color scoreColor;
  const _ScoreRow({required this.score, required this.scoreColor});

  @override
  Widget build(BuildContext context) {
    final msg = score >= 70
        ? '🌟 شاباش!'
        : score >= 50
            ? '🔸 قریب ہے!'
            : '❌ دوبارہ کوشش!';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(msg,
            style: TextStyle(
              fontFamily: 'NotoNastaliqUrdu',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: scoreColor,
            ),
            textDirection: TextDirection.rtl),
      ]),
    );
  }
}

// ── Info cell ─────────────────────────────────────────────────────────────────

class _InfoCell extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InfoCell(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color),
                textAlign: TextAlign.center),
          ]),
    );
  }
}

// ── Next button ───────────────────────────────────────────────────────────────

class _NextBtn extends StatelessWidget {
  final String label;
  final Color color, accentColor;
  final VoidCallback onTap;
  final bool hasBack;
  final VoidCallback? onBack;

  const _NextBtn({
    required this.label, required this.color,
    required this.onTap, required this.hasBack,
    required this.accentColor, this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
      if (hasBack) ...[
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accentColor.withOpacity(0.4), width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Icon(Icons.arrow_back_rounded,
                color: accentColor, size: 20),
          ),
        ),
        const SizedBox(width: 10),
      ],
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          width: 180,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.40),
                  blurRadius: 12,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Center(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15)),
          ),
        ),
      ),
    ]);
  }
}

// ── Quiz result page ──────────────────────────────────────────────────────────


// ── Quiz result page ──────────────────────────────────────────────────────────

class _QuizResultPage extends StatelessWidget {
  final int correct, total;
  final Color color;
  final String title;
  final VoidCallback onRestart;

  const _QuizResultPage({
    required this.correct, required this.total,
    required this.color, required this.title,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final pct   = total == 0 ? 0 : (correct / total * 100).round();
    final stars = pct >= 80 ? 3 : pct >= 50 ? 2 : 1;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withOpacity(0.4), const Color(0xFFFFF8E8)],
              stops: const [0.0, 0.25, 0.55],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 24),
                    Container(
                      width: 130, height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white,
                        border: Border.all(color: color, width: 4),
                        boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 20)],
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('$pct%', style: TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w900, color: color)),
                        const Text('score', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(i < stars ? '⭐' : '☆',
                            style: TextStyle(
                                fontSize: i < stars ? 40 : 30,
                                color: i < stars ? Colors.amber : Colors.grey.shade300)),
                      )),
                    ),
                    const SizedBox(height: 10),
                    Text('$correct / $total correct',
                        style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280))),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: onRestart,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _kOrange,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(
                                color: _kOrange.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4))],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Try Again', style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                      child: const Text('Back to Home',
                          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
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
