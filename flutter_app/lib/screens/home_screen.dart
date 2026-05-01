import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/tts_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _greetUser());
  }

  Future<void> _greetUser() async {
    final name = context.read<AppProvider>().userName;
    if (name.isNotEmpty && name != 'طالب علم') {
      await TtsService.instance.speak('خوش آمدید $name!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AppProvider>().userName;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SafeArea(child: _HomeBody(userName: name)),
      bottomNavigationBar: _BottomNav(
        onProfileTap: () => Navigator.pushNamed(context, '/profile'),
      ),
    );
  }
}

// ── Body ────────────────────────────────────────────────────────────────────

class _HomeBody extends StatelessWidget {
  final String userName;
  const _HomeBody({required this.userName});

  static const _darkGreen  = Color(0xFF1B5E4B);
  static const _blueGreen  = Color(0xFF0d9488);
  static const _amber      = Color(0xFFD97706);
  static const _blue       = Color(0xFF2563EB);
  static const _orange     = Color(0xFFE07B2A);

  @override
  Widget build(BuildContext context) {
    final greeting = userName.isNotEmpty ? 'خوش آمدید، $userName!' : 'خوش آمدید';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),

            // ── Header ────────────────────────────────────────────────
            const Text(
              'Welcome',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                greeting,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'NotoNastaliqUrdu',
                  fontSize: 20,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── 2 × 2 grid ────────────────────────────────────────────
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                _Tile(
                  label: 'Lessons',
                  urduLabel: 'سبق',
                  icon: Icons.menu_book_rounded,
                  bg: _darkGreen,
                  routeName: '/lessons-hub',
                ),
                _Tile(
                  label: 'Quizzes',
                  urduLabel: 'کوئز',
                  icon: Icons.quiz_rounded,
                  bg: _blue,
                  routeName: '/quiz-hub',
                ),
                _Tile(
                  label: 'Vocabulary',
                  urduLabel: 'لغت',
                  icon: Icons.library_books_rounded,
                  bg: _amber,
                  routeName: '/vocabulary-bank',
                ),
                _Tile(
                  label: 'Progress',
                  urduLabel: 'پیش رفت',
                  icon: Icons.bar_chart_rounded,
                  bg: _orange,
                  routeName: '/progress',
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Quick-access strip ─────────────────────────────────────
            const _SectionHeader('Quick Lessons'),
            const SizedBox(height: 10),
            _QuickStrip(items: const [
              _QuickItem('حروف', '🔤', '/haroof',         _darkGreen),
              _QuickItem('گنتی',  '🔢', '/counting',       _blueGreen),
              _QuickItem('الفاظ', '📖', '/lafz',           _blue),
              _QuickItem('جملے', '💬', '/jumlay',          _amber),
              _QuickItem('جوڑ توڑ','🔗','/jor-tor',       Color(0xFF7c3aed)),
              _QuickItem('رنگ',   '🎨', '/rang',           _orange),
            ]),

            const SizedBox(height: 28),

            // ── Quick quiz strip ───────────────────────────────────────
            const _SectionHeader('Quick Quizzes'),
            const SizedBox(height: 10),
            _QuickStrip(items: const [
              _QuickItem('حروف',  '🎤', '/haroof-quiz',    Color(0xFF9b5de5)),
              _QuickItem('الفاظ', '📝', '/words-quiz',     _blue),
              _QuickItem('ملائیں','🔗', '/matching-quiz',  Color(0xFFf15bb5)),
              _QuickItem('جانور', '🐄', '/animals-quiz',   Color(0xFF059669)),
              _QuickItem('پھل',   '🍎', '/fruits-quiz',    Color(0xFFdc2626)),
            ]),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Tile card ────────────────────────────────────────────────────────────────

class _Tile extends StatelessWidget {
  final String label;
  final String urduLabel;
  final IconData icon;
  final Color bg;
  final String routeName;

  const _Tile({
    required this.label,
    required this.urduLabel,
    required this.icon,
    required this.bg,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, routeName),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: bg.withOpacity(0.38),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                urduLabel,
                style: const TextStyle(
                  fontFamily: 'NotoNastaliqUrdu',
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 18, color: const Color(0xFF1B5E4B),
            margin: const EdgeInsets.only(right: 8)),
        Text(text, style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A1A),
          letterSpacing: 0.3,
        )),
      ],
    );
  }
}

// ── Quick horizontal strip ───────────────────────────────────────────────────

class _QuickStrip extends StatelessWidget {
  final List<_QuickItem> items;
  const _QuickStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(ctx, item.route),
            child: Container(
              width: 72,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: item.color.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 4),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: 12,
                        color: item.color,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickItem {
  final String label;
  final String emoji;
  final String route;
  final Color color;
  const _QuickItem(this.label, this.emoji, this.route, this.color);
}

// ── Bottom nav ───────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final VoidCallback onProfileTap;
  const _BottomNav({required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F0E8),
        border: Border(top: BorderSide(color: Color(0xFFDDD8CC), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBtn(icon: Icons.home_rounded,   label: 'Home',    isActive: true,  onTap: () {}),
              _NavBtn(icon: Icons.person_rounded, label: 'Profile', isActive: false, onTap: onProfileTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF1B5E4B) : const Color(0xFF9CA3AF);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 18, height: 2,
                decoration: BoxDecoration(color: color,
                    borderRadius: BorderRadius.circular(1)),
              ),
          ],
        ),
      ),
    );
  }
}
