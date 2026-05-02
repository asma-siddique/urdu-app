import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/tts_service.dart';

class LessonsHubScreen extends StatelessWidget {
  const LessonsHubScreen({super.key});

  static const _darkGreen = Color(0xFF1B4332);
  static const _cream     = Color(0xFFF5F0E8);

  // ── Curriculum lessons (KG / Nursery level) ──────────────────────────────
  static const List<_LessonEntry> _lessons = [
    _LessonEntry(
      number: 1,
      englishTitle: 'Urdu Alphabet (Haroof)',
      urduTitle: 'حروفِ تہجی',
      description: 'Learn all 40 letters — Alif to Bari Yay',
      emoji: '🔤',
      route: '/haroof-lesson',
      color: Color(0xFFF97316),
    ),
    _LessonEntry(
      number: 2,
      englishTitle: 'Counting 1–100 (Ginti)',
      urduTitle: 'گنتی ١ تا ١٠٠',
      description: 'Numbers in Urdu words & numerals',
      emoji: '🔢',
      route: '/ginti-lesson',
      color: Color(0xFF0EA5E9),
    ),
    _LessonEntry(
      number: 3,
      englishTitle: 'Vocabulary (Alfaz)',
      urduTitle: 'الفاظ',
      description: 'Animals, fruits, food, body parts & more',
      emoji: '📖',
      route: '/alfaz-lesson',
      color: Color(0xFF8B5CF6),
    ),
    _LessonEntry(
      number: 4,
      englishTitle: 'Sentences (Jumlay)',
      urduTitle: 'جملے',
      description: 'Simple everyday Urdu sentences',
      emoji: '💬',
      route: '/jumla-lesson',
      color: Color(0xFF10B981),
    ),
    _LessonEntry(
      number: 5,
      englishTitle: 'Phonics (Jor Tor)',
      urduTitle: 'جوڑ توڑ',
      description: 'Letter + vowel sound combinations',
      emoji: '🔗',
      route: '/jor-tor',
      color: Color(0xFFEC4899),
    ),
    _LessonEntry(
      number: 6,
      englishTitle: 'Colors (Rang)',
      urduTitle: 'رنگ',
      description: 'Learn colors in Urdu',
      emoji: '🎨',
      route: '/rang',
      color: Color(0xFFF59E0B),
    ),
    _LessonEntry(
      number: 7,
      englishTitle: 'Animals (Janwar)',
      urduTitle: 'جانور',
      description: 'Wild & domestic animals vocabulary',
      emoji: '🐄',
      route: '/animals-lesson',
      color: Color(0xFF059669),
    ),
    _LessonEntry(
      number: 8,
      englishTitle: 'Fruits (Phal)',
      urduTitle: 'پھل',
      description: 'Common fruits in Urdu',
      emoji: '🍎',
      route: '/fruits-lesson',
      color: Color(0xFFDC2626),
    ),
    _LessonEntry(
      number: 9,
      englishTitle: 'Body Parts (Jism)',
      urduTitle: 'جسمانی اعضاء',
      description: 'Parts of the body in Urdu',
      emoji: '🫀',
      route: '/body-lesson',
      color: Color(0xFF7C3AED),
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
        backgroundColor: _darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Lessons',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded),
            onPressed: () => TtsService.instance.speak('سبق شروع کریں'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Banner ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: _darkGreen,
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
                      'آؤ $name، سبق شروع کریں!',
                      style: const TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${_lessons.length} lessons',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // ── Lesson list ──────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _lessons.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, thickness: 1, indent: 72, color: Color(0xFFEDE8DC)),
              itemBuilder: (ctx, i) => _LessonTile(lesson: _lessons[i]),
            ),
          ),
        ],
      ),
    ));
  }
}

// ── Single lesson tile ────────────────────────────────────────────────────────

class _LessonTile extends StatelessWidget {
  final _LessonEntry lesson;
  const _LessonTile({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, lesson.route),
      splashColor: lesson.color.withOpacity(0.08),
      highlightColor: lesson.color.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ── Icon box ──────────────────────────────────────────────
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: lesson.color,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: lesson.color.withOpacity(0.30),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(lesson.emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 16),

            // ── Text block ────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.englishTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      lesson.urduTitle,
                      style: TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: 14,
                        color: lesson.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Number badge + arrow ───────────────────────────────────
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: lesson.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${lesson.number}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: lesson.color,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(Icons.chevron_right_rounded,
                    color: lesson.color.withOpacity(0.5), size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonEntry {
  final int number;
  final String englishTitle;
  final String urduTitle;
  final String description;
  final String emoji;
  final String route;
  final Color color;

  const _LessonEntry({
    required this.number,
    required this.englishTitle,
    required this.urduTitle,
    required this.description,
    required this.emoji,
    required this.route,
    required this.color,
  });
}
