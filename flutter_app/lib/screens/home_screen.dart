import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';
import '../services/tts_service.dart';
import '../widgets/professor_avatar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AvatarEmotion _emotion = AvatarEmotion.happy;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _greetUser());
  }

  Future<void> _greetUser() async {
    final user = context.read<AppProvider>().currentUser;
    final name = (user?.name ?? '').isEmpty ? '' : user!.name;
    if (name.isNotEmpty && name != 'طالب علم') {
      setState(() => _emotion = AvatarEmotion.speaking);
      await TtsService.instance.speak('صبح بخیر $name! آج کیا سیکھیں گے؟');
      if (mounted) setState(() => _emotion = AvatarEmotion.happy);
    }
  }

  Future<void> _onAvatarTap() async {
    final user = context.read<AppProvider>().currentUser;
    final name = (user?.name ?? 'دوست');
    setState(() => _emotion = AvatarEmotion.speaking);
    await TtsService.instance.speak('$name، اردو سیکھنے میں خوش آمدید!');
    if (mounted) setState(() => _emotion = AvatarEmotion.happy);
  }

  static const List<_Item> _lessons = [
    _Item(emoji: '🔤', urdu: 'حروف',        sub: 'Alphabet',       route: '/haroof',         colors: [Color(0xFF9b5de5), Color(0xFF7b3fc4)]),
    _Item(emoji: '🔗', urdu: 'جوڑ توڑ',     sub: 'Word Building',  route: '/jor-tor',        colors: [Color(0xFFf15bb5), Color(0xFFc73d8f)]),
    _Item(emoji: '📝', urdu: 'الفاظ',        sub: 'Words',          route: '/lafz',           colors: [Color(0xFF00bbf9), Color(0xFF0090c7)]),
    _Item(emoji: '💬', urdu: 'جملے',         sub: 'Sentences',      route: '/jumlay',         colors: [Color(0xFF3a86ff), Color(0xFF2563eb)]),
    _Item(emoji: '🐄', urdu: 'جانور',        sub: 'Animals',        route: '/animals-lesson', colors: [Color(0xFF059669), Color(0xFF047857)]),
    _Item(emoji: '🎨', urdu: 'رنگ',          sub: 'Colors',         route: '/rang',           colors: [Color(0xFFff6d00), Color(0xFFcc5700)]),
    _Item(emoji: '🍎', urdu: 'پھل',          sub: 'Fruits',         route: '/fruits-lesson',  colors: [Color(0xFFdc2626), Color(0xFFb91c1c)]),
    _Item(emoji: '🫀', urdu: 'جسمانی اعضاء', sub: 'Body Parts',     route: '/body-lesson',    colors: [Color(0xFF7c3aed), Color(0xFF6d28d9)]),
    _Item(emoji: '🔢', urdu: 'گنتی',          sub: 'Counting',       route: '/counting',       colors: [Color(0xFF0d9488), Color(0xFF0f766e)]),
    _Item(emoji: '📖', urdu: 'واحد جمع',      sub: 'Singular Plural',route: '/grammar',        colors: [Color(0xFFd97706), Color(0xFFb45309)]),
  ];

  static const List<_Item> _quizzes = [
    _Item(emoji: '🎤', urdu: 'حروف کوئز',  sub: 'Speak Letters',   route: '/haroof-quiz',    colors: [Color(0xFF9b5de5), Color(0xFF7b3fc4)]),
    _Item(emoji: '📝', urdu: 'الفاظ کوئز', sub: 'Words Quiz',      route: '/words-quiz',     colors: [Color(0xFF3a86ff), Color(0xFF2563eb)]),
    _Item(emoji: '💬', urdu: 'جملہ کوئز',  sub: 'Sentence Quiz',   route: '/sentences-quiz', colors: [Color(0xFF00bbf9), Color(0xFF0090c7)]),
    _Item(emoji: '🔗', urdu: 'ملائیں',     sub: 'Matching',        route: '/matching-quiz',  colors: [Color(0xFFf15bb5), Color(0xFFc73d8f)]),
    _Item(emoji: '🎨', urdu: 'رنگ کوئز',   sub: 'Colors Quiz',     route: '/colors-quiz',    colors: [Color(0xFFff6d00), Color(0xFFcc5700)]),
    _Item(emoji: '🐄', urdu: 'جانور کوئز', sub: 'Animals Quiz',    route: '/animals-quiz',   colors: [Color(0xFF059669), Color(0xFF047857)]),
    _Item(emoji: '🍎', urdu: 'پھل کوئز',   sub: 'Fruits Quiz',     route: '/fruits-quiz',    colors: [Color(0xFFdc2626), Color(0xFFb91c1c)]),
    _Item(emoji: '🫀', urdu: 'جسم کوئز',   sub: 'Body Parts Quiz', route: '/body-quiz',      colors: [Color(0xFF7c3aed), Color(0xFF6d28d9)]),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    final totalStars = user?.totalStars ?? 0;
    const maxStars = 100;
    final progress = (totalStars / maxStars).clamp(0.0, 1.0);
    final userName = user?.name ?? 'طالب علم';

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      body: CustomScrollView(
        slivers: [

          // ── Header ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.headerGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _onAvatarTap,
                            child: ProfessorAvatar(
                                emotion: _emotion, size: 76),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('صبح بخیر، $userName',
                                      style: const TextStyle(
                                          fontFamily: 'NotoNastaliqUrdu',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  const Text('آپ کا ذہین استاد',
                                      style: TextStyle(
                                          fontFamily: 'NotoNastaliqUrdu',
                                          fontSize: 13,
                                          color: Colors.white70)),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(children: [
                              const Text('⭐',
                                  style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 4),
                              Text('$totalStars',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor:
                              Colors.white.withOpacity(0.3),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(
                                  AppTheme.yellow),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Lessons ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(
              emoji: '📚',
              title: 'سبق',
              actionLabel: 'سب دیکھیں',
              onAction: () =>
                  Navigator.pushNamed(context, '/lessons-hub'),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _lessons.length,
                itemBuilder: (ctx, i) => _SmallCard(item: _lessons[i]),
              ),
            ),
          ),

          // ── Quiz ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SectionHeader(
              emoji: '🎮',
              title: 'کوئز',
              actionLabel: 'سب دیکھیں',
              onAction: () =>
                  Navigator.pushNamed(context, '/quiz-hub'),
              color: AppTheme.orange,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 120,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _BigCard(item: _quizzes[i]),
                childCount: _quizzes.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String emoji, title, actionLabel;
  final VoidCallback onAction;
  final Color color;
  const _SectionHeader({
    required this.emoji,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.color = AppTheme.purple,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontFamily: 'NotoNastaliqUrdu',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy)),
          const Spacer(),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel,
                style: TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 13,
                    color: color)),
          ),
        ],
      ),
    );
  }
}

// ── Small card (lessons row) ──────────────────────────────────────────────────
class _SmallCard extends StatelessWidget {
  final _Item item;
  const _SmallCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, item.route),
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: item.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: item.colors[0].withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(item.urdu,
                style: const TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl),
          ],
        ),
      ),
    );
  }
}

// ── Big card (quiz grid) ──────────────────────────────────────────────────────
class _BigCard extends StatelessWidget {
  final _Item item;
  const _BigCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, item.route),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: item.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: item.colors[0].withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 34)),
            const SizedBox(height: 6),
            Text(item.urdu,
                style: const TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                textDirection: TextDirection.rtl),
            Text(item.sub,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _Item {
  final String emoji, urdu, sub, route;
  final List<Color> colors;
  const _Item(
      {required this.emoji,
      required this.urdu,
      required this.sub,
      required this.route,
      required this.colors});
}
