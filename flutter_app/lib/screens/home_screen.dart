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
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFBF4),
        body: SafeArea(child: _HomeBody(userName: name)),
        bottomNavigationBar: _BottomNav(
          onProfileTap: () => Navigator.pushNamed(context, '/profile'),
        ),
      ),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _HomeBody extends StatelessWidget {
  final String userName;
  const _HomeBody({required this.userName});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    // On desktop/tablet, cap content at 520 px and centre it
    final contentW = screenW.clamp(0.0, 520.0);

    return SingleChildScrollView(
      child: Center(
        child: SizedBox(
          width: contentW,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 28),

                // ── Header ──────────────────────────────────────────────
                const Text(
                  'Welcome',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C1917),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    userName.isNotEmpty ? 'خوش آمدید، $userName!' : 'خوش آمدید',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'NotoNastaliqUrdu',
                      fontSize: 20,
                      color: Color(0xFF44403C),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── 2 × 2 tile grid ─────────────────────────────────────
                // Force exact 2-column layout regardless of screen width
                _TileGrid(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 2×2 tile grid (always 2 columns) ─────────────────────────────────────────

class _TileGrid extends StatelessWidget {
  const _TileGrid();

  static const _tiles = [
    _TileData('Lessons',    'سبق',     Icons.menu_book_rounded,    Color(0xFF1B5E4B), '/lessons-hub'),
    _TileData('Quizzes',    'کوئز',    Icons.quiz_rounded,          Color(0xFF2563EB), '/quiz-hub'),
    _TileData('Vocabulary', 'لغت',     Icons.library_books_rounded, Color(0xFFD97706), '/vocabulary-bank'),
    _TileData('Progress',   'پیش رفت', Icons.bar_chart_rounded,     Color(0xFFE07B2A), '/progress'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, bc) {
      final gap = 14.0;
      final tileW = (bc.maxWidth - gap) / 2;
      final tileH = tileW * 0.78; // slightly shorter than square

      return Column(
        children: [
          Row(
            children: [
              _Tile(data: _tiles[0], width: tileW, height: tileH),
              SizedBox(width: gap),
              _Tile(data: _tiles[1], width: tileW, height: tileH),
            ],
          ),
          SizedBox(height: gap),
          Row(
            children: [
              _Tile(data: _tiles[2], width: tileW, height: tileH),
              SizedBox(width: gap),
              _Tile(data: _tiles[3], width: tileW, height: tileH),
            ],
          ),
        ],
      );
    });
  }
}

class _TileData {
  final String label;
  final String urduLabel;
  final IconData icon;
  final Color bg;
  final String route;
  const _TileData(this.label, this.urduLabel, this.icon, this.bg, this.route);
}

class _Tile extends StatelessWidget {
  final _TileData data;
  final double width;
  final double height;
  const _Tile({required this.data, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, data.route),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: data.bg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: data.bg.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: height * 0.36,
              height: height * 0.36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(data.icon, color: Colors.white, size: height * 0.2),
            ),
            SizedBox(height: height * 0.07),
            Text(
              data.label,
              style: TextStyle(
                color: Colors.white,
                fontSize: (height * 0.12).clamp(12, 17),
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: height * 0.02),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                data.urduLabel,
                style: TextStyle(
                  fontFamily: 'NotoNastaliqUrdu',
                  color: Colors.white70,
                  fontSize: (height * 0.10).clamp(10, 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom nav ────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final VoidCallback onProfileTap;
  const _BottomNav({required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
          boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8)],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBtn(icon: Icons.home_rounded,   label: 'Home',    isActive: true,  onTap: () {}),
                _NavBtn(icon: Icons.person_rounded, label: 'Profile', isActive: false, onTap: onProfileTap),
              ],
            ),
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
    final color = isActive ? const Color(0xFFF97316) : const Color(0xFF9CA3AF);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.normal)),
        ],
      ),
    );
  }
}
