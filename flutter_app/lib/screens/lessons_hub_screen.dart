import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/professor_avatar.dart';
import '../services/tts_service.dart';

class LessonsHubScreen extends StatefulWidget {
  const LessonsHubScreen({super.key});

  @override
  State<LessonsHubScreen> createState() => _LessonsHubScreenState();
}

class _LessonsHubScreenState extends State<LessonsHubScreen> {
  AvatarEmotion _emotion = AvatarEmotion.happy;

  static const List<_LessonCard> _lessons = [
    _LessonCard(emoji: '🔤', urduTitle: 'حروف تہجی',     englishSub: 'Alphabet',         route: '/haroof',        colors: [Color(0xFF9b5de5), Color(0xFF7b3fc4)]),
    _LessonCard(emoji: '🔗', urduTitle: 'جوڑ توڑ',       englishSub: 'Word Merging',     route: '/jor-tor',       colors: [Color(0xFFf15bb5), Color(0xFFc73d8f)]),
    _LessonCard(emoji: '📝', urduTitle: 'الفاظ',          englishSub: 'Words',            route: '/lafz',          colors: [Color(0xFF00bbf9), Color(0xFF0090c7)]),
    _LessonCard(emoji: '🐄', urduTitle: 'جانور',          englishSub: 'Animals',          route: '/animals-lesson',colors: [Color(0xFF059669), Color(0xFF047857)]),
    _LessonCard(emoji: '🎨', urduTitle: 'رنگ',            englishSub: 'Colors',           route: '/rang',          colors: [Color(0xFFff6d00), Color(0xFFcc5700)]),
    _LessonCard(emoji: '🍎', urduTitle: 'پھل',            englishSub: 'Fruits',           route: '/fruits-lesson', colors: [Color(0xFFdc2626), Color(0xFFb91c1c)]),
    _LessonCard(emoji: '🫀', urduTitle: 'جسمانی اعضاء',   englishSub: 'Body Parts',       route: '/body-lesson',   colors: [Color(0xFF7c3aed), Color(0xFF6d28d9)]),
    _LessonCard(emoji: '🔢', urduTitle: 'گنتی',           englishSub: 'Counting',         route: '/counting',      colors: [Color(0xFF0d9488), Color(0xFF0f766e)]),
    _LessonCard(emoji: '💬', urduTitle: 'جملے',           englishSub: 'Sentences',        route: '/jumlay',        colors: [Color(0xFF3a86ff), Color(0xFF2563eb)]),
    _LessonCard(emoji: '📖', urduTitle: 'واحد جمع',       englishSub: 'Singular Plural',  route: '/grammar',       colors: [Color(0xFFd97706), Color(0xFFb45309)]),
  ];

  Future<void> _onAvatarTap() async {
    setState(() => _emotion = AvatarEmotion.speaking);
    await TtsService.instance.speak('سبق شروع کریں');
    if (mounted) setState(() => _emotion = AvatarEmotion.happy);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'سبق',
            style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 24),
          ),
        ),
        backgroundColor: AppTheme.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppTheme.headerGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: GestureDetector(
                  onTap: _onAvatarTap,
                  child: ProfessorAvatar(emotion: _emotion, size: 90),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                mainAxisExtent: 140,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _buildCard(_lessons[i], ctx),
                childCount: _lessons.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildCard(_LessonCard card, BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, card.route),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: card.colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: card.colors[0].withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(card.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 6),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  card.urduTitle,
                  style: const TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                card.englishSub,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LessonCard {
  final String emoji;
  final String urduTitle;
  final String englishSub;
  final String route;
  final List<Color> colors;

  const _LessonCard({
    required this.emoji,
    required this.urduTitle,
    required this.englishSub,
    required this.route,
    required this.colors,
  });
}
