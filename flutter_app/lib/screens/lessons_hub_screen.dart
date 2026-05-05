import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/tts_service.dart';

class LessonsHubScreen extends StatelessWidget {
  const LessonsHubScreen({super.key});

  static const List<_LessonEntry> _lessons = [
    _LessonEntry(number:1, englishTitle:'Urdu Alphabet (Haroof)', urduTitle:'حروفِ تہجی',
        icon:Icons.sort_by_alpha_rounded, route:'/haroof-lesson', color:Color(0xFFF97316)),
    _LessonEntry(number:2, englishTitle:'Counting 1-100 (Ginti)', urduTitle:'گنتی ١ تا ١٠٠',
        icon:Icons.dialpad_rounded, route:'/ginti-lesson', color:Color(0xFF0EA5E9)),
    _LessonEntry(number:3, englishTitle:'Vocabulary (Alfaz)', urduTitle:'الفاظ',
        icon:Icons.menu_book_rounded, route:'/alfaz-lesson', color:Color(0xFF8B5CF6)),
    _LessonEntry(number:4, englishTitle:'Sentences (Jumlay)', urduTitle:'جملے',
        icon:Icons.chat_bubble_rounded, route:'/jumla-lesson', color:Color(0xFF10B981)),
    _LessonEntry(number:5, englishTitle:'Phonics (Jor Tor)', urduTitle:'جوڑ توڑ',
        icon:Icons.link_rounded, route:'/jor-tor', color:Color(0xFFEC4899)),
    _LessonEntry(number:6, englishTitle:'Colors (Rang)', urduTitle:'رنگ',
        icon:Icons.palette_rounded, route:'/rang', color:Color(0xFFF59E0B)),
    _LessonEntry(number:7, englishTitle:'Animals (Janwar)', urduTitle:'جانور',
        icon:Icons.pets_rounded, route:'/animals-lesson', color:Color(0xFF059669)),
    _LessonEntry(number:8, englishTitle:'Fruits (Phal)', urduTitle:'پھل',
        icon:Icons.eco_rounded, route:'/fruits-lesson', color:Color(0xFFDC2626)),
    _LessonEntry(number:9, englishTitle:'Body Parts (Jism)', urduTitle:'جسمانی اعضاء',
        icon:Icons.accessibility_new_rounded, route:'/body-lesson', color:Color(0xFF7C3AED)),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final name = provider.userName;
    final done = (provider.currentUser?.sessionsCompleted ?? 0).clamp(0, _lessons.length);
    final lessonProgress = provider.lessonProgress;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFBFF),
        body: Column(children: [
          _LessonsHeader(name: name, completed: done, total: _lessons.length),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Lessons',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('All Lessons',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF374151)),
                ]),
              ),
            ]),
          ),
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            itemCount: _lessons.length,
            itemBuilder: (ctx, i) {
              // no locking — all lessons accessible
              final isCompleted  = i < done;
              final isInProgress = i == done && done < _lessons.length;
              final progress = lessonProgress[_lessons[i].route] ?? 0.0;
              return _LessonRow(
                lesson: _lessons[i],
                isCompleted: isCompleted,
                isInProgress: isInProgress,
                progress: progress,
              );
            },
          )),
        ]),
      ),
    );
  }
}

// ── Colorful header ────────────────────────────────────────────────────────────
class _LessonsHeader extends StatelessWidget {
  final String name;
  final int completed, total;
  const _LessonsHeader({required this.name, required this.completed, required this.total});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF00BFA5), Color(0xFF26C6DA)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Stack(children: [
        Positioned(top: -30, right: -20, child: Container(width: 120, height: 120,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), shape: BoxShape.circle))),
        Positioned(top: 50, right: 50, child: Container(width: 55, height: 55,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle))),
        Padding(
          padding: EdgeInsets.fromLTRB(16, top + 10, 16, 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // top bar
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => TtsService.instance.speak('سبق شروع کریں'),
                child: Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20)),
              ),
              const SizedBox(width: 8),
              Container(width: 36, height: 36,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20)),
            ]),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              // avatar
              Container(width: 62, height: 62,
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))]),
                child: const Center(child: Text('🧒', style: TextStyle(fontSize: 36)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text('Hi, $name!',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                    overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 4),
                  const Text('👋', style: TextStyle(fontSize: 18)),
                ]),
                const SizedBox(height: 2),
                const Text("Let's continue learning",
                    style: TextStyle(fontSize: 12, color: Colors.white70)),
              ])),
              // books illustration
              const SizedBox(width: 72, height: 72, child: Stack(children: [
                Positioned(bottom: 0, left: 6,  child: Text('📚', style: TextStyle(fontSize: 38))),
                Positioned(top: 0,    left: 24, child: Text('🍎', style: TextStyle(fontSize: 20))),
                Positioned(top: 2,    right: 0, child: Text('✨', style: TextStyle(fontSize: 16))),
                Positioned(bottom: 16, right: 2, child: Text('⭐', style: TextStyle(fontSize: 11))),
              ])),
            ]),
            const SizedBox(height: 14),
            // progress badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.45), width: 1.2),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('⭐', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 7),
                Text('$completed / $total Lessons Completed',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Lesson row ─────────────────────────────────────────────────────────────────
class _LessonRow extends StatelessWidget {
  final _LessonEntry lesson;
  final bool isCompleted;
  final bool isInProgress;
  final double progress;
  const _LessonRow({required this.lesson, required this.isCompleted, required this.isInProgress, this.progress = 0.0});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, lesson.route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
              color: lesson.color.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          // Solid colored square with white icon
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: lesson.color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: lesson.color.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Center(child: Icon(lesson.icon, color: Colors.white, size: 26)),
          ),
          const SizedBox(width: 14),
          // Text + optional progress
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(lesson.englishTitle,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 3),
            Directionality(textDirection: TextDirection.rtl,
              child: Text(lesson.urduTitle,
                style: TextStyle(
                  fontFamily: 'NotoNastaliqUrdu', fontSize: 12,
                  color: lesson.color, fontWeight: FontWeight.w600,
                  height: 1.2, leadingDistribution: TextLeadingDistribution.even))),
           
          ])),
          const SizedBox(width: 10),
          // Right side status
          if (isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 13),
                SizedBox(width: 3),
                Text('Completed',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
              ]),
            )
          else
            Icon(Icons.chevron_right_rounded, color: lesson.color.withOpacity(0.6), size: 24),
        ]),
      ),
    );
  }
}

class _LessonEntry {
  final int number;
  final String englishTitle, urduTitle, route;
  final IconData icon;
  final Color color;
  const _LessonEntry({required this.number, required this.englishTitle, required this.urduTitle,
      required this.icon, required this.route, required this.color});
}
