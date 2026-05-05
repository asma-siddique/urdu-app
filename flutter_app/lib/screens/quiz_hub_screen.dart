import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/tts_service.dart';

class QuizHubScreen extends StatelessWidget {
  const QuizHubScreen({super.key});

  static const List<_QuizEntry> _quizzes = [
    _QuizEntry(
        number: 1,
        englishTitle: 'Alphabet Quiz',
        urduTitle: 'حروف کوئز',
        description: 'Speak each letter aloud',
        icon: Icons.record_voice_over_rounded,
        route: '/haroof-quiz',
        color: Color(0xFF9B5DE5)),
    _QuizEntry(
        number: 2,
        englishTitle: 'Word Quiz',
        urduTitle: 'الفاظ کوئز',
        description: 'Pronounce Urdu words',
        icon: Icons.spellcheck_rounded,
        route: '/words-quiz',
        color: Color(0xFF2563EB)),
    _QuizEntry(
        number: 3,
        englishTitle: 'Sentence Quiz',
        urduTitle: 'جملہ کوئز',
        description: 'Fill in the blank',
        icon: Icons.chat_rounded,
        route: '/sentences-quiz',
        color: Color(0xFF10B981)),
    _QuizEntry(
        number: 4,
        englishTitle: 'Matching Quiz',
        urduTitle: 'ملائیں',
        description: 'Match words with pictures',
        icon: Icons.compare_arrows_rounded,
        route: '/matching-quiz',
        color: Color(0xFFf15bb5)),
    _QuizEntry(
        number: 5,
        englishTitle: 'Colors Quiz',
        urduTitle: 'رنگ کوئز',
        description: 'Identify colors in Urdu',
        icon: Icons.palette_rounded,
        route: '/colors-quiz',
        color: Color(0xFFE07B2A)),
    _QuizEntry(
        number: 6,
        englishTitle: 'Animals Quiz',
        urduTitle: 'جانور کوئز',
        description: 'Name animals in Urdu',
        icon: Icons.pets_rounded,
        route: '/animals-quiz',
        color: Color(0xFF059669)),
    _QuizEntry(
        number: 7,
        englishTitle: 'Fruits Quiz',
        urduTitle: 'پھل کوئز',
        description: 'Name fruits in Urdu',
        icon: Icons.eco_rounded,
        route: '/fruits-quiz',
        color: Color(0xFFDC2626)),
    _QuizEntry(
        number: 8,
        englishTitle: 'Body Parts Quiz',
        urduTitle: 'جسم کوئز',
        description: 'Name body parts',
        icon: Icons.accessibility_new_rounded,
        route: '/body-quiz',
        color: Color(0xFF7C3AED)),
  ];

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AppProvider>().userName;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFBFF),
        body: Column(children: [
          _QuizHeader(name: name, total: _quizzes.length),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quizzes',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1A1A2E))),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4)
                      ],
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('All Quizzes',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151))),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down,
                          size: 16, color: Color(0xFF374151)),
                    ]),
                  ),
                ]),
          ),
          Expanded(
              child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            itemCount: _quizzes.length,
            itemBuilder: (ctx, i) => _QuizRow(quiz: _quizzes[i]),
          )),
        ]),
      ),
    );
  }
}

// ── Colorful header ────────────────────────────────────────────────────────────
class _QuizHeader extends StatelessWidget {
  final String name;
  final int total;
  const _QuizHeader({required this.name, required this.total});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6D28D9), Color(0xFFa855f7)],
        ),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Stack(children: [
        Positioned(
            top: -30,
            right: -20,
            child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    shape: BoxShape.circle))),
        Positioned(
            top: 55,
            right: 55,
            child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle))),
        Padding(
          padding: EdgeInsets.fromLTRB(16, top + 10, 16, 22),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => TtsService.instance.speak('کوئز کھیلیں'),
                child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.volume_up_rounded,
                        color: Colors.white, size: 20)),
              ),
              const SizedBox(width: 8),
              Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.notifications_none_rounded,
                      color: Colors.white, size: 20)),
            ]),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]),
                  child: const Center(
                      child: Text('🧒', style: TextStyle(fontSize: 36)))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Flexible(
                          child: Text('Hi, $name!',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white),
                              overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 4),
                      const Text('🏆', style: TextStyle(fontSize: 18)),
                    ]),
                    const SizedBox(height: 2),
                    const Text("Let's test your Urdu!",
                        style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ])),
              SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(children: [
                    const Positioned(
                        bottom: 0,
                        left: 4,
                        child: Text('🏆', style: TextStyle(fontSize: 38))),
                    const Positioned(
                        top: 0,
                        left: 26,
                        child: Text('⭐', style: TextStyle(fontSize: 18))),
                    const Positioned(
                        top: 4,
                        right: 0,
                        child: Text('✨', style: TextStyle(fontSize: 16))),
                    const Positioned(
                        bottom: 14,
                        right: 4,
                        child: Text('🌟', style: TextStyle(fontSize: 11))),
                  ])),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: Colors.white.withOpacity(0.45), width: 1.2),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('🎯', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 7),
                Text('$total Quizzes  •  Tap to play',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Quiz row ───────────────────────────────────────────────────────────────────
class _QuizRow extends StatelessWidget {
  final _QuizEntry quiz;
  const _QuizRow({required this.quiz});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, quiz.route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: quiz.color.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: quiz.color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: quiz.color.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            child:
                Center(child: Icon(quiz.icon, color: Colors.white, size: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(quiz.englishTitle,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A))),
                const SizedBox(height: 3),
                Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(quiz.urduTitle,
                        style: TextStyle(
                            fontFamily: 'NotoNastaliqUrdu',
                            fontSize: 12,
                            color: quiz.color,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            leadingDistribution:
                                TextLeadingDistribution.even))),
                const SizedBox(height: 3),
                Text(quiz.description,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF))),
              ])),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
                color: quiz.color, borderRadius: BorderRadius.circular(12)),
            child: const Text('Play ▶',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
        ]),
      ),
    );
  }
}

class _QuizEntry {
  final int number;
  final String englishTitle, urduTitle, description, route;
  final IconData icon;
  final Color color;
  const _QuizEntry(
      {required this.number,
      required this.englishTitle,
      required this.urduTitle,
      required this.description,
      required this.icon,
      required this.route,
      required this.color});
}
