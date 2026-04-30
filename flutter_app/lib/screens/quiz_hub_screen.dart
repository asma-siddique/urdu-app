import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/professor_avatar.dart';
import '../services/tts_service.dart';

class QuizHubScreen extends StatefulWidget {
  const QuizHubScreen({super.key});

  @override
  State<QuizHubScreen> createState() => _QuizHubScreenState();
}

class _QuizHubScreenState extends State<QuizHubScreen> {
  AvatarEmotion _emotion = AvatarEmotion.excited;

  static const List<_QuizCard> _quizzes = [
    _QuizCard(emoji: '🎤', urduTitle: 'حروف کوئز',  englishSub: 'Speak & Score',    route: '/haroof-quiz',  colors: [Color(0xFF9b5de5), Color(0xFF7b3fc4)]),
    _QuizCard(emoji: '📝', urduTitle: 'الفاظ کوئز', englishSub: 'Word Quiz',        route: '/words-quiz',   colors: [Color(0xFF3a86ff), Color(0xFF2563eb)]),
    _QuizCard(emoji: '💬', urduTitle: 'جملہ کوئز',  englishSub: 'Sentence Quiz',    route: '/sentences-quiz',colors: [Color(0xFF00bbf9), Color(0xFF0090c7)]),
    _QuizCard(emoji: '🔗', urduTitle: 'ملائیں',     englishSub: 'Matching',         route: '/matching-quiz',colors: [Color(0xFFf15bb5), Color(0xFFc73d8f)]),
    _QuizCard(emoji: '🎨', urduTitle: 'رنگ کوئز',   englishSub: 'Colors Quiz',      route: '/colors-quiz',  colors: [Color(0xFFff6d00), Color(0xFFcc5700)]),
    _QuizCard(emoji: '🐄', urduTitle: 'جانور کوئز', englishSub: 'Animals Quiz',     route: '/animals-quiz', colors: [Color(0xFF059669), Color(0xFF047857)]),
    _QuizCard(emoji: '🍎', urduTitle: 'پھل کوئز',   englishSub: 'Fruits Quiz',      route: '/fruits-quiz',  colors: [Color(0xFFdc2626), Color(0xFFb91c1c)]),
  ];

  Future<void> _onAvatarTap() async {
    setState(() => _emotion = AvatarEmotion.speaking);
    await TtsService.instance.speak('کوئز کھیلیں');
    if (mounted) setState(() => _emotion = AvatarEmotion.excited);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      appBar: AppBar(
        title: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'کوئز',
            style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 24),
          ),
        ),
        backgroundColor: AppTheme.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFf97316), Color(0xFFea580c)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                (ctx, i) => _buildCard(_quizzes[i], ctx),
                childCount: _quizzes.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildCard(_QuizCard card, BuildContext context) {
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

class _QuizCard {
  final String emoji;
  final String urduTitle;
  final String englishSub;
  final String route;
  final List<Color> colors;

  const _QuizCard({
    required this.emoji,
    required this.urduTitle,
    required this.englishSub,
    required this.route,
    required this.colors,
  });
}
