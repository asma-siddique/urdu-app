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
      description: 'Learn all 40 Urdu letters with examples',
      emoji: '🔤',
      route: '/haroof',
      color: Color(0xFF1B4332),
    ),
    _LessonEntry(
      number: 2,
      englishTitle: 'Counting 1–100 (Ginti)',
      urduTitle: 'گنتی ١ تا ١٠٠',
      description: 'Numbers in Urdu words & numerals',
      emoji: '🔢',
      route: '/counting',
      color: Color(0xFF0d9488),
    ),
    _LessonEntry(
      number: 3,
      englishTitle: 'Vocabulary (Alfaz)',
      urduTitle: 'الفاظ',
      description: 'Animals, fruits, food, body parts & more',
      emoji: '📖',
      route: '/lafz',
      color: Color(0xFF2563EB),
    ),
    _LessonEntry(
      number: 4,
      englishTitle: 'Sentences (Jumlay)',
      urduTitle: 'جملے',
      description: 'Simple everyday Urdu sentences',
      emoji: '💬',
      route: '/jumlay',
      color: Color(0xFF7c3aed),
    ),
    _LessonEntry(
      number: 5,
      englishTitle: 'Phonics (Jor Tor)',
      urduTitle: 'جوڑ توڑ',
      description: 'Letter + vowel combinations with sound',
      emoji: '🔗',
      route: '/jor-tor',
      color: Color(0xFFf15bb5),
    ),
    _LessonEntry(
      number: 6,
      englishTitle: 'Colors (Rang)',
      urduTitle: 'رنگ',
      description: 'Learn colors in Urdu',
      emoji: '🎨',
      route: '/rang',
      color: Color(0xFFE07B2A),
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
      color: Color(0xFFdc2626),
    ),
    _LessonEntry(
      number: 9,
      englishTitle: 'Body Parts (Jism)',
      urduTitle: 'جسمانی اعضاء',
      description: 'Parts of the body in Urdu',
      emoji: '🫀',
      route: '/body-lesson',
      color: Color(0xFF9b5de5),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AppProvider>().userName;

    return Scaffold(
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
                  '${_lessons.length} lessons · KG / Nursery',
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
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // ── Icon box ──────────────────────────────────────────────
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: lesson.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(lesson.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),

            // ── Text block ────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lesson ${lesson.number}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: lesson.color,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lesson.englishTitle,
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
                      lesson.urduTitle,
                      style: TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: 13,
                        color: lesson.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lesson.description,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF6B7280),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── Arrow ─────────────────────────────────────────────────
            Icon(Icons.chevron_right_rounded,
                color: lesson.color.withOpacity(0.6), size: 22),
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
