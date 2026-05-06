import 'package:flutter/material.dart';
import '../services/tts_service.dart';
import '../widgets/mic_recorder_widget.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kCardTop = Color(0xFFFFF3D6);
const _kTeal = Color(0xFF26C6DA);
const _kOrange = Color(0xFFFF7043);
const _kPurple = Color(0xFF7C3AED);
const _kBg = Color(0xFFFFF8E8);

const _mascotMsgs = [
  'Look!\nThis\ncolor!',
  'Cool!\nWhat\ncolor?',
  'Great!\nName\nit!',
  'Yes!\nSay\nit!',
  'Wow!\nLearn\nit!',
  'Fun!\nTry\nit!',
];

class _ColorData {
  final String urdu;
  final String english;
  final String roman;
  final Color color;
  final List<String> objects;
  const _ColorData(
      {required this.urdu,
      required this.english,
      required this.roman,
      required this.color,
      required this.objects});
}

const List<_ColorData> _COLORS = [
  _ColorData(
      urdu: 'سرخ',
      english: 'Red',
      roman: 'Surkh',
      color: Color(0xFFEF233C),
      objects: ['🍎 سیب', '🍓 اسٹرابیری', '🌹 گلاب', '❤️ دل']),
  _ColorData(
      urdu: 'نیلا',
      english: 'Blue',
      roman: 'Neela',
      color: Color(0xFF0077B6),
      objects: ['🌊 سمندر', '🫐 بیری', '🧢 ٹوپی', '🦋 تتلی']),
  _ColorData(
      urdu: 'سبز',
      english: 'Green',
      roman: 'Sabz',
      color: Color(0xFF2DC653),
      objects: ['🌿 پودا', '🥦 بروکلی', '🐸 مینڈک', '🌳 درخت']),
  _ColorData(
      urdu: 'پیلا',
      english: 'Yellow',
      roman: 'Peela',
      color: Color(0xFFFDD835),
      objects: ['🌻 سورج مکھی', '🍋 لیموں', '🌟 ستارہ', '🐤 چوزہ']),
  _ColorData(
      urdu: 'نارنجی',
      english: 'Orange',
      roman: 'Naranji',
      color: Color(0xFFFF6D00),
      objects: ['🍊 مالٹا', '🎃 کدو', '🦊 لومڑی', '🥕 گاجر']),
  _ColorData(
      urdu: 'بنفشی',
      english: 'Purple',
      roman: 'Banafshi',
      color: Color(0xFF9B5DE5),
      objects: ['🍇 انگور', '🌸 پھول', '🦄 یونیکورن', '🫐 بیری']),
  _ColorData(
      urdu: 'گلابی',
      english: 'Pink',
      roman: 'Gulabi',
      color: Color(0xFFf48fb1),
      objects: ['🌸 پھول', '🦩 فلیمنگو', '🍬 ٹافی', '🎀 ربن']),
  _ColorData(
      urdu: 'سفید',
      english: 'White',
      roman: 'Safaid',
      color: Color(0xFFBDBDBD),
      objects: ['☁️ بادل', '🕊️ کبوتر', '🥛 دودھ', '🏔️ برف']),
  _ColorData(
      urdu: 'کالا',
      english: 'Black',
      roman: 'Kaala',
      color: Color(0xFF424242),
      objects: ['🌑 رات', '🎱 گیند', '🖊️ قلم', '🐈 بلی']),
  _ColorData(
      urdu: 'بھورا',
      english: 'Brown',
      roman: 'Bhoora',
      color: Color(0xFF795548),
      objects: ['🐻 ریچھ', '☕ چائے', '🍫 چاکلیٹ', '🪵 لکڑی']),
  _ColorData(
      urdu: 'آسمانی',
      english: 'Sky Blue',
      roman: 'Aasmani',
      color: Color(0xFF00BBF9),
      objects: ['🌥️ آسمان', '🐦 پرندہ', '💧 پانی', '🧊 برف']),
  _ColorData(
      urdu: 'سنہری',
      english: 'Golden',
      roman: 'Sonehari',
      color: Color(0xFFFFAB00),
      objects: ['👑 تاج', '🏆 ٹرافی', '⭐ ستارہ', '🌾 گندم']),
];

// ── Screen ────────────────────────────────────────────────────────────────────
class RangScreen extends StatefulWidget {
  const RangScreen({super.key});
  @override
  State<RangScreen> createState() => _RangScreenState();
}

class _RangScreenState extends State<RangScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  bool _speaking = false;

  late AnimationController _anim;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0.10, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _speak();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  _ColorData get _color => _COLORS[_index];

  void _goTo(int i) {
    if (i < 0 || i >= _COLORS.length) return;
    setState(() => _index = i);
    _anim.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _speak();
    });
  }

  Future<void> _speak() async {
    if (_speaking) return;
    setState(() => _speaking = true);
    final c = _color;
    await TtsService.instance.speak('${c.urdu}۔ ${c.roman}۔ ${c.english}');
    if (mounted) setState(() => _speaking = false);
  }

  void _openMic() {
    final c = _color;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MicRecorderWidget(
        targetText: c.urdu,
        targetRoman: c.roman,
        onScore: (score, _) {
          Navigator.pop(context);
          final provider = context.read<AppProvider>();
          provider.recordResult(c.urdu, score);
          provider.updateLessonProgress('/rang', (_index + 1) / _COLORS.length);
          TtsService.instance
              .speak(score >= 70 ? 'شاباش!' : 'دوبارہ کوشش کریں۔');
        },
      ),
    );
  }

  List<Widget> _decorStars(Color col) {
    const stars = [
      {'top': 78.0, 'left': 10.0, 'size': 15.0, 'op': 0.60},
      {'top': 138.0, 'left': 26.0, 'size': 10.0, 'op': 0.42},
      {'top': 210.0, 'left': 6.0, 'size': 17.0, 'op': 0.52},
      {'top': 78.0, 'right': 8.0, 'size': 13.0, 'op': 0.60},
      {'top': 150.0, 'right': 22.0, 'size': 17.0, 'op': 0.48},
      {'top': 230.0, 'right': 5.0, 'size': 12.0, 'op': 0.52},
    ];
    final List<Widget> w = stars
        .map<Widget>((d) => Positioned(
              top: d['top'] as double,
              left: d.containsKey('left') ? d['left'] as double : null,
              right: d.containsKey('right') ? d['right'] as double : null,
              child: Opacity(
                  opacity: d['op'] as double,
                  child: Text('⭐',
                      style: TextStyle(fontSize: d['size'] as double))),
            ))
        .toList();
    w.addAll([
      const Positioned(
          top: 54,
          left: 48,
          child: Opacity(
              opacity: 0.45,
              child: Text('☁️', style: TextStyle(fontSize: 24)))),
      const Positioned(
          top: 58,
          right: 52,
          child: Opacity(
              opacity: 0.36,
              child: Text('☁️', style: TextStyle(fontSize: 18)))),
    ]);
    w.add(Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SizedBox(
          height: 26,
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List<Widget>.generate(
                  18,
                  (i) => Padding(
                      padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                      child: Text(
                          i % 3 == 0
                              ? '🌿'
                              : i % 3 == 1
                                  ? '🌱'
                                  : '🌸',
                          style: TextStyle(
                              fontSize: i % 2 == 0 ? 17.0 : 13.0)))))),
    ));
    return w;
  }

  @override
  Widget build(BuildContext context) {
    final total = _COLORS.length;
    final progress = (_index + 1) / total;
    final c = _color;
    final msg = _mascotMsgs[_index % _mascotMsgs.length];

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                c.color,
                c.color.withOpacity(0.60),
                const Color(0xFFFFF3E0),
                _kBg
              ],
              stops: const [0.0, 0.18, 0.48, 1.0],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: <Widget>[
                ..._decorStars(c.color),
                Column(
                  children: [
                    // ── Top bar ────────────────────────────────────────────
                    _RangTopBar(
                        index: _index,
                        total: total,
                        color: c.color,
                        onBack: () => Navigator.pop(context)),
                    // ── Progress ───────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.88),
                              borderRadius: BorderRadius.circular(20)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Text('🎨', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text('${_index + 1} / $total',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF5D4037))),
                          ]),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: Colors.white.withOpacity(0.30),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${(progress * 100).round()}%',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ]),
                    ),
                    // ── Main: mascot | card | tip ──────────────────────────
                    Expanded(
                      child: LayoutBuilder(builder: (ctx, bc) {
                        final isWide = bc.maxWidth > 460;
                        final sideW = isWide ? 72.0 : 48.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                      width: sideW,
                                      child: _MascotSide(message: msg)),
                                  Expanded(
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints:
                                            const BoxConstraints(maxWidth: 300),
                                        child: _buildCard(c),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      width: sideW, child: _TipSide(data: c)),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    // ── Listen + Speak circles ─────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _CircleBtn(
                              icon: Icons.volume_up_rounded,
                              label: 'Listen',
                              color: _kTeal,
                              active: _speaking,
                              onTap: _speak),
                          const SizedBox(width: 36),
                          _CircleBtn(
                              icon: Icons.mic_rounded,
                              label: 'Speak',
                              color: _kPurple,
                              active: false,
                              onTap: _openMic),
                        ],
                      ),
                    ),
                    // ── Prev / Next button ─────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: _NavBtn(
                        label: _index == total - 1 ? '✓  Finish' : 'Next  →',
                        color: _kOrange,
                        onTap: _index == total - 1
                            ? () => Navigator.pop(context)
                            : () => _goTo(_index + 1),
                        hasBack: _index > 0,
                        onBack: () => _goTo(_index - 1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Card ────────────────────────────────────────────────────────────────────
  Widget _buildCard(_ColorData c) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 22,
              offset: const Offset(0, 8))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            // ── Color banner ───────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c.color, c.color.withOpacity(0.70)],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.25),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.65), width: 3),
                    ),
                    child: Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.color,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 8)
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // ── Urdu name in cream box ─────────────────────────────────
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              constraints: const BoxConstraints(minHeight: 72),
              decoration: BoxDecoration(
                color: _kCardTop,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(c.urdu,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A5F),
                        height: 1.0,
                        leadingDistribution: TextLeadingDistribution.even,
                      )),
                ),
              ),
            ),
            // ── 2×2 objects grid ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 82,
                    child: Row(children: [
                      _ObjBox(obj: c.objects[0], color: c.color),
                      const SizedBox(width: 6),
                      _ObjBox(obj: c.objects[1], color: c.color),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 82,
                    child: Row(children: [
                      _ObjBox(obj: c.objects[2], color: c.color),
                      const SizedBox(width: 6),
                      _ObjBox(obj: c.objects[3], color: c.color),
                    ]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────────
class _RangTopBar extends StatelessWidget {
  final int index, total;
  final Color color;
  final VoidCallback onBack;
  const _RangTopBar(
      {required this.index,
      required this.total,
      required this.color,
      required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
        ),
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Directionality(
              textDirection: TextDirection.rtl,
              child: Text('رنگ  Colors',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ),
            Text('Color Lesson · ${index + 1} / $total',
                style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('🎨 ${index + 1}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ),
      ]),
    );
  }
}

// ── Mascot (full-body boy) ─────────────────────────────────────────────────────
class _MascotSide extends StatelessWidget {
  final String message;
  const _MascotSide({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          margin: const EdgeInsets.only(bottom: 5, right: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Text(message,
              style: const TextStyle(
                  fontSize: 9.0,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5D4037)),
              textAlign: TextAlign.center),
        ),
        SizedBox(
          height: 148,
          width: 80,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: <Widget>[
              Positioned(
                  top: 0,
                  left: 23,
                  child: Container(
                      width: 34,
                      height: 15,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFD0D0D0)),
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(17),
                              topRight: Radius.circular(17))))),
              Positioned(
                  top: 13,
                  left: 20,
                  child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFD0D0D0)),
                          borderRadius: BorderRadius.circular(3)))),
              Positioned(
                  top: 16,
                  left: 22,
                  child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Color(0xFFFFCC80)),
                      child: const Center(
                          child: Text('😊', style: TextStyle(fontSize: 20))))),
              Positioned(
                  top: 49,
                  left: 36,
                  child: Container(
                      width: 8, height: 7, color: const Color(0xFFFFCC80))),
              Positioned(
                  top: 54,
                  left: 14,
                  child: Container(
                      width: 52,
                      height: 50,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8)))),
              Positioned(
                  top: 54,
                  left: 18,
                  child: Container(
                      width: 44,
                      height: 46,
                      decoration: BoxDecoration(
                          color: const Color(0xFF388E3C),
                          borderRadius: BorderRadius.circular(7)))),
              Positioned(
                  top: 56,
                  left: 32,
                  child: Container(
                      width: 16,
                      height: 44,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4)))),
              Positioned(
                  top: 58,
                  right: 2,
                  child: Transform.rotate(
                      angle: -0.55,
                      child: Container(
                          width: 24,
                          height: 10,
                          decoration: BoxDecoration(
                              color: const Color(0xFFFFCC80),
                              borderRadius: BorderRadius.circular(5))))),
              Positioned(
                  top: 65,
                  left: 4,
                  child: Container(
                      width: 14,
                      height: 10,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5)))),
              Positioned(
                  top: 101,
                  left: 18,
                  child: Container(
                      width: 17,
                      height: 38,
                      decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(5)))),
              Positioned(
                  top: 101,
                  left: 44,
                  child: Container(
                      width: 17,
                      height: 38,
                      decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(5)))),
              Positioned(
                  top: 134,
                  left: 14,
                  child: Container(
                      width: 24,
                      height: 9,
                      decoration: BoxDecoration(
                          color: const Color(0xFF4E342E),
                          borderRadius: BorderRadius.circular(5)))),
              Positioned(
                  top: 134,
                  left: 41,
                  child: Container(
                      width: 24,
                      height: 9,
                      decoration: BoxDecoration(
                          color: const Color(0xFF4E342E),
                          borderRadius: BorderRadius.circular(5)))),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Tip side ──────────────────────────────────────────────────────────────────
class _TipSide extends StatelessWidget {
  final _ColorData data;
  const _TipSide({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xCECE93D8), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.purple.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('💡', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 3),
        const Text('Tip',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6A1B9A))),
        const SizedBox(height: 5),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: data.color,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: data.color.withOpacity(0.4), blurRadius: 6)
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(data.roman,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF4A148C),
                height: 1.3),
            textAlign: TextAlign.center),
        Text(data.english,
            style: const TextStyle(
                fontSize: 9, color: Color(0xFF6A1B9A), height: 1.3),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ── Object tile ───────────────────────────────────────────────────────────────
class _ObjBox extends StatelessWidget {
  final String obj;
  final Color color;
  const _ObjBox({required this.obj, required this.color});

  @override
  Widget build(BuildContext context) {
    final parts = obj.split(' ');
    final emoji = parts.first;
    final word = parts.skip(1).join(' ');
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.28), width: 1.5),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 3),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(word,
                style: const TextStyle(
                  fontFamily: 'NotoNastaliqUrdu',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a1a2e),
                  height: 1.0,
                  leadingDistribution: TextLeadingDistribution.even,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }
}

// ── Circle button ─────────────────────────────────────────────────────────────
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;
  const _CircleBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? color : color.withOpacity(0.14),
            border: Border.all(color: color, width: 2.5),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Icon(icon, color: active ? Colors.white : color, size: 26),
        ),
        const SizedBox(height: 5),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: active ? color : color.withOpacity(0.7))),
      ]),
    );
  }
}

// ── Nav button ────────────────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool hasBack;
  final VoidCallback onBack;
  const _NavBtn(
      {required this.label,
      required this.color,
      required this.onTap,
      required this.hasBack,
      required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (hasBack)
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 50,
            height: 54,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(27),
              border: Border.all(color: color.withOpacity(0.35), width: 2),
            ),
            child: Icon(Icons.arrow_back_rounded, color: color, size: 22),
          ),
        ),
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                    color: color.withOpacity(0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Center(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white))),
          ),
        ),
      ),
    ]);
  }
}
