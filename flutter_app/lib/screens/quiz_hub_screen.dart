import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/tts_service.dart';

class QuizHubScreen extends StatelessWidget {
  const QuizHubScreen({super.key});

  static const _headerColor = Color(0xFF1E3A5F);
  static const _cream       = Color(0xFFF5F0E8);

  static const List<_QuizEntry> _quizzes = [
    _QuizEntry(
      number: 1,
      englishTitle: 'Alphabet Quiz (Haroof)',
      urduTitle: 'حروف کوئز',
      description: 'Speak each letter aloud & get scored',
      emoji: '🎤',
      route: '/haroof-quiz',
      color: Color(0xFF9b5de5),
    ),
    _QuizEntry(
      number: 2,
      englishTitle: 'Word Quiz (Alfaz)',
      urduTitle: 'الفاظ کوئز',
      description: 'Pronounce Urdu words correctly',
      emoji: '📝',
      route: '/words-quiz',
      color: Color(0xFF2563EB),
    ),
    _QuizEntry(
      number: 3,
      englishTitle: 'Sentence Quiz (Jumlay)',
      urduTitle: 'جملہ کوئز',
      description: 'Read & speak full sentences',
      emoji: '💬',
      route: '/sentences-quiz',
      color: Color(0xFF00bbf9),
    ),
    _QuizEntry(
      number: 4,
      englishTitle: 'Matching Quiz (Milao)',
      urduTitle: 'ملائیں',
      description: 'Match Urdu words with pictures',
      emoji: '🔗',
      route: '/matching-quiz',
      color: Color(0xFFf15bb5),
    ),
    _QuizEntry(
      number: 5,
      englishTitle: 'Colors Quiz (Rang)',
      urduTitle: 'رنگ کوئز',
      description: 'Identify colors in Urdu',
      emoji: '🎨',
      route: '/colors-quiz',
      color: Color(0xFFE07B2A),
    ),
    _QuizEntry(
      number: 6,
      englishTitle: 'Animals Quiz (Janwar)',
      urduTitle: 'جانور کوئز',
      description: 'Name animals in Urdu',
      emoji: '🐄',
      route: '/animals-quiz',
      color: Color(0xFF059669),
    ),
    _QuizEntry(
      number: 7,
      englishTitle: 'Fruits Quiz (Phal)',
      urduTitle: 'پھل کوئز',
      description: 'Name fruits in Urdu',
      emoji: '🍎',
      route: '/fruits-quiz',
      color: Color(0xFFdc2626),
    ),
    _QuizEntry(
      number: 8,
      englishTitle: 'Body Parts Quiz (Jism)',
      urduTitle: 'جسم کوئز',
      description: 'Name body parts in Urdu',
      emoji: '🫀',
      route: '/body-quiz',
      color: Color(0xFF7c3aed),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AppProvider>().userName;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _headerColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Quizzes',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded),
            onPressed: () => TtsService.instance.speak('کوئز کھیلیں'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Banner ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: _headerColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name.isNotEmpty)
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      'آؤ $name، کوئز کھیلیں!',
                      style: const TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${_quizzes.length} quizzes · Tap to start',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),

          // ── Quiz list ────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _quizzes.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, thickness: 1, indent: 72, color: Color(0xFFEDE8DC)),
              itemBuilder: (ctx, i) => _QuizTile(quiz: _quizzes[i]),
            ),
          ),
        ],
      ),
    ));
  }
}

// ── Single quiz tile ──────────────────────────────────────────────────────────

class _QuizTile extends StatelessWidget {
  final _QuizEntry quiz;
  const _QuizTile({required this.quiz});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, quiz.route),
      splashColor: quiz.color.withOpacity(0.08),
      highlightColor: quiz.color.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // ── Icon box ──────────────────────────────────────────────
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: quiz.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(quiz.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),

            // ── Text ──────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quiz ${quiz.number}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: quiz.color,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    quiz.englishTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      quiz.urduTitle,
                      style: TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: 13,
                        color: quiz.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    quiz.description,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── Start badge ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: quiz.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: quiz.color.withOpacity(0.3)),
              ),
              child: Text(
                'Start',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: quiz.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizEntry {
  final int number;
  final String englishTitle;
  final String urduTitle;
  final String description;
  final String emoji;
  final String route;
  final Color color;

  const _QuizEntry({
    required this.number,
    required this.englishTitle,
    required this.urduTitle,
    required this.description,
    required this.emoji,
    required this.route,
    required this.color,
  });
}
