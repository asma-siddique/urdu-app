import 'package:flutter/material.dart';
import '../data/jor_tor.dart';
import '../widgets/mic_recorder_widget.dart';
import '../services/tts_service.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kCardTop = Color(0xFFFFF3D6);
const _kTeal    = Color(0xFF26C6DA);
const _kOrange  = Color(0xFFFF7043);
const _kPurple  = Color(0xFF7C3AED);
const _kPink    = Color(0xFFf15bb5);
const _kBg      = Color(0xFFFFF8E8);

const _mascotMsgs = [
  'Look!\nJoin\nthem!', 'Cool!\nMix\nthem!', 'Fun!\nRead\nit!',
  'Yes!\nSay\nit!',    'Wow!\nTry\nit!',   'Great!\nSpell\nit!',
];

// ── Screen ────────────────────────────────────────────────────────────────────
class JorTorScreen extends StatefulWidget {
  const JorTorScreen({super.key});
  @override
  State<JorTorScreen> createState() => _JorTorScreenState();
}

class _JorTorScreenState extends State<JorTorScreen>
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
    _fadeAnim  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0.10, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _speak();
    });
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  JorTorItem get _item => JOR_TOR[_index];

  void _goTo(int i) {
    if (i < 0 || i >= JOR_TOR.length) return;
    setState(() => _index = i);
    _anim.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _speak();
    });
  }

  Future<void> _speak() async {
    if (_speaking) return;
    setState(() => _speaking = true);
    final it = _item;
    await TtsService.instance.speak(
      '${it.letterRoman} plus ${it.vowelRoman} makes ${it.resultRoman}. '
      'Example: ${it.exampleMeaning}',
    );
    if (mounted) setState(() => _speaking = false);
  }

  void _openMic() {
    final item = _item;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MicRecorderWidget(
        targetText: item.result,
        targetRoman: item.resultRoman,
        onScore: (score, _) {
          Navigator.pop(context);
          final provider = context.read<AppProvider>();
          provider.recordResult(item.result, score);
          provider.updateLessonProgress('/jor-tor', (_index + 1) / JOR_TOR.length);
          TtsService.instance.speak(
            score >= 70 ? 'شاباش! بہت اچھا!' : 'دوبارہ کوشش کریں۔',
          );
        },
      ),
    );
  }

  // ── Decorative background ─────────────────────────────────────────────────
  List<Widget> _decorStars() {
    const stars = [
      {'top': 80.0,  'left': 10.0,  'size': 16.0, 'op': 0.65},
      {'top': 140.0, 'left': 28.0,  'size': 11.0, 'op': 0.45},
      {'top': 220.0, 'left': 6.0,   'size': 18.0, 'op': 0.55},
      {'top': 80.0,  'right': 8.0,  'size': 14.0, 'op': 0.65},
      {'top': 155.0, 'right': 24.0, 'size': 18.0, 'op': 0.50},
      {'top': 240.0, 'right': 6.0,  'size': 13.0, 'op': 0.55},
    ];
    final List<Widget> w = stars.map<Widget>((d) => Positioned(
      top:   d['top']   as double,
      left:  d.containsKey('left')  ? d['left']  as double : null,
      right: d.containsKey('right') ? d['right'] as double : null,
      child: Opacity(
        opacity: d['op'] as double,
        child: Text('⭐', style: TextStyle(fontSize: d['size'] as double)),
      ),
    )).toList();
    w.addAll([
      const Positioned(top: 56, left: 50,
          child: Opacity(opacity: 0.50, child: Text('☁️', style: TextStyle(fontSize: 26)))),
      const Positioned(top: 60, right: 55,
          child: Opacity(opacity: 0.40, child: Text('☁️', style: TextStyle(fontSize: 20)))),
    ]);
    w.add(Positioned(
      bottom: 0, left: 0, right: 0,
      child: SizedBox(
        height: 26,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List<Widget>.generate(18, (i) => Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
            child: Text(
              i % 3 == 0 ? '🌿' : i % 3 == 1 ? '🌱' : '🌸',
              style: TextStyle(fontSize: i % 2 == 0 ? 17.0 : 13.0),
            ),
          )),
        ),
      ),
    ));
    return w;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final total   = JOR_TOR.length;
    final progress = (_index + 1) / total;
    final msg = _mascotMsgs[_index % _mascotMsgs.length];

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _kPurple,
                _kPurple.withOpacity(0.60),
                const Color(0xFFFFF3E0),
                _kBg,
              ],
              stops: const [0.0, 0.18, 0.48, 1.0],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: <Widget>[
                ..._decorStars(),
                Column(
                  children: [
                    // ── Top bar ───────────────────────────────────────────
                    _JTTopBar(
                      index: _index, total: total,
                      onBack: () => Navigator.pop(context),
                    ),
                    // ── Progress bar ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.88),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Text('🔗', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text('${_index + 1} / $total',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w800,
                                    color: Color(0xFF5D4037))),
                          ]),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress, minHeight: 8,
                              backgroundColor: Colors.white.withOpacity(0.30),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('${(progress * 100).round()}%',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ]),
                    ),
                    // ── Main row: mascot | card | tip ─────────────────────
                    Expanded(
                      child: LayoutBuilder(builder: (ctx, bc) {
                        final isWide = bc.maxWidth > 460;
                        final sideW  = isWide ? 72.0 : 48.0;
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
                                  SizedBox(width: sideW,
                                      child: _MascotSide(message: msg)),
                                  Expanded(
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 300),
                                        child: _buildCard(),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: sideW,
                                      child: _TipSide(item: _item)),
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
                            onTap: _speak,
                          ),
                          const SizedBox(width: 36),
                          _CircleBtn(
                            icon: Icons.mic_rounded,
                            label: 'Speak',
                            color: _kPurple,
                            active: false,
                            onTap: _openMic,
                          ),
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

  // ── Card ─────────────────────────────────────────────────────────────────
  Widget _buildCard() {
    final item = _item;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.18),
          blurRadius: 22, offset: const Offset(0, 8),
        )],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            // ── Emoji banner ─────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [
                      _kPurple.withOpacity(0.18),
                      const Color(0xFFFFF3E0),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    item.emoji == '—' ? '📌' : item.emoji,
                    style: const TextStyle(fontSize: 68),
                  ),
                ),
              ),
            ),
            // ── Result letter in cream box ───────────────────────────────
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
                  child: Text(
                    item.result,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'NotoNastaliqUrdu',
                      fontSize: 60, fontWeight: FontWeight.bold,
                      color: _kPink,
                      height: 1.0,
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
                  ),
                ),
              ),
            ),
            // ── Combination row: Letter + VowelMark = Result ─────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: _kPurple.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kPurple.withOpacity(0.12)),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: _SmallLetterBox(text: item.result,    color: _kPink,   bold: true)),
                      const _OpLbl('='),
                      Flexible(child: _SmallLetterBox(text: item.letter,    color: _kPurple)),
                      const _OpLbl('+'),
                      Flexible(child: _SmallLetterBox(text: item.vowelMark, color: _kTeal)),
                    ],
                  ),
                ),
              ),
            ),
            // ── Info: roman + example ────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(14, 2, 14, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Expanded(child: _InfoCell(
                      label: 'Sound', value: item.resultRoman, color: _kPink)),
                  Container(width: 1, height: 40, color: const Color(0xFFE5E7EB)),
                  Expanded(child: _InfoCell(
                      label: 'Example',
                      value: '${item.exampleWord}  ${item.exampleMeaning}',
                      color: _kPurple)),
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
class _JTTopBar extends StatelessWidget {
  final int index, total;
  final VoidCallback onBack;
  const _JTTopBar({required this.index, required this.total, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 36, height: 36,
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
            const Text('جوڑ توڑ  Jor Tor',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900,
                    color: Colors.white)),
            Text('Letter Combinations · ${index + 1} / $total',
                style: const TextStyle(fontSize: 10, color: Colors.white70)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('🔗 ${index + 1}',
              style: const TextStyle(fontSize: 13,
                  fontWeight: FontWeight.w800, color: Colors.white)),
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
              topLeft: Radius.circular(12), topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10),
                blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Text(message,
              style: const TextStyle(fontSize: 9.0, fontWeight: FontWeight.w800,
                  color: Color(0xFF5D4037)),
              textAlign: TextAlign.center),
        ),
        SizedBox(
          height: 148, width: 80,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: <Widget>[
              Positioned(top: 0, left: 23, child: Container(width: 34, height: 15,
                decoration: BoxDecoration(color: Colors.white,
                  border: Border.all(color: const Color(0xFFD0D0D0)),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(17), topRight: Radius.circular(17))))),
              Positioned(top: 13, left: 20, child: Container(width: 40, height: 5,
                decoration: BoxDecoration(color: Colors.white,
                  border: Border.all(color: const Color(0xFFD0D0D0)),
                  borderRadius: BorderRadius.circular(3)))),
              Positioned(top: 16, left: 22, child: Container(width: 36, height: 36,
                decoration: const BoxDecoration(shape: BoxShape.circle,
                    color: Color(0xFFFFCC80)),
                child: const Center(child: Text('😊', style: TextStyle(fontSize: 20))))),
              Positioned(top: 49, left: 36, child: Container(width: 8, height: 7,
                  color: const Color(0xFFFFCC80))),
              Positioned(top: 54, left: 14, child: Container(width: 52, height: 50,
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(8)))),
              Positioned(top: 54, left: 18, child: Container(width: 44, height: 46,
                decoration: BoxDecoration(color: const Color(0xFF388E3C),
                    borderRadius: BorderRadius.circular(7)))),
              Positioned(top: 56, left: 32, child: Container(width: 16, height: 44,
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(4)))),
              Positioned(top: 58, right: 2, child: Transform.rotate(angle: -0.55,
                child: Container(width: 24, height: 10,
                  decoration: BoxDecoration(color: const Color(0xFFFFCC80),
                      borderRadius: BorderRadius.circular(5))))),
              Positioned(top: 65, left: 4, child: Container(width: 14, height: 10,
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(5)))),
              Positioned(top: 101, left: 18, child: Container(width: 17, height: 38,
                decoration: BoxDecoration(color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(5)))),
              Positioned(top: 101, left: 44, child: Container(width: 17, height: 38,
                decoration: BoxDecoration(color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(5)))),
              Positioned(top: 134, left: 14, child: Container(width: 24, height: 9,
                decoration: BoxDecoration(color: const Color(0xFF4E342E),
                    borderRadius: BorderRadius.circular(5)))),
              Positioned(top: 134, left: 41, child: Container(width: 24, height: 9,
                decoration: BoxDecoration(color: const Color(0xFF4E342E),
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
  final JorTorItem item;
  const _TipSide({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xCECE93D8), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.12),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🔗', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        const Text('Tip', style: TextStyle(fontSize: 10,
            fontWeight: FontWeight.w800, color: Color(0xFF6A1B9A))),
        const SizedBox(height: 5),
        Text('${item.letterRoman}\n+\n${item.vowelRoman}\n=\n${item.resultRoman}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                color: Color(0xFF4A148C), height: 1.4),
            textAlign: TextAlign.center),
      ]),
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
  const _CircleBtn({required this.icon, required this.label,
      required this.color, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 58, height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? color : color.withOpacity(0.14),
            border: Border.all(color: color, width: 2.5),
            boxShadow: [BoxShadow(color: color.withOpacity(0.28),
                blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Icon(icon, color: active ? Colors.white : color, size: 26),
        ),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            color: active ? color : color.withOpacity(0.7))),
      ]),
    );
  }
}

// ── Nav button (Prev / Next) ──────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool hasBack;
  final VoidCallback onBack;
  const _NavBtn({required this.label, required this.color,
      required this.onTap, required this.hasBack, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (hasBack)
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 50, height: 54,
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
              boxShadow: [BoxShadow(color: color.withOpacity(0.30),
                  blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Center(child: Text(label,
                style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w800, color: Colors.white))),
          ),
        ),
      ),
    ]);
  }
}

// ── Small letter box (inside combination row) ─────────────────────────────────
class _SmallLetterBox extends StatelessWidget {
  final String text;
  final Color color;
  final bool bold;
  const _SmallLetterBox({required this.text, required this.color,
      this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bold ? color.withOpacity(0.14) : color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: bold ? color : color.withOpacity(0.35),
            width: bold ? 2.5 : 1.5),
      ),
      child: Text(text,
          style: TextStyle(
            fontFamily: 'NotoNastaliqUrdu',
            fontSize: 32, fontWeight: FontWeight.bold,
            color: color, height: 1.0,
            leadingDistribution: TextLeadingDistribution.even,
          )),
    );
  }
}

// ── Op label ─────────────────────────────────────────────────────────────────
class _OpLbl extends StatelessWidget {
  final String text;
  const _OpLbl(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(text, style: const TextStyle(
        fontSize: 20, color: Colors.grey, fontWeight: FontWeight.bold)),
  );
}

// ── Info cell ─────────────────────────────────────────────────────────────────
class _InfoCell extends StatelessWidget {
  final String label, value;
  final Color color;
  const _InfoCell({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(
            fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                color: color),
            textAlign: TextAlign.center,
            maxLines: 2, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

