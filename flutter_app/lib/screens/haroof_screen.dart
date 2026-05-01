import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../data/alphabet.dart';
import '../models/urdu_letter.dart';
import '../providers/app_provider.dart';
import '../services/tts_service.dart';
import '../widgets/professor_avatar.dart';
import '../widgets/mic_recorder_widget.dart';

class HaroofScreen extends StatefulWidget {
  const HaroofScreen({super.key});
  @override
  State<HaroofScreen> createState() => _HaroofScreenState();
}

class _HaroofScreenState extends State<HaroofScreen>
    with SingleTickerProviderStateMixin {
  AvatarEmotion _emotion = AvatarEmotion.happy;
  int _idx = 0;
  final Map<int, double> _scores = {};

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  static const List<Color> _palette = [
    Color(0xFF7C3AED), Color(0xFFDB2777), Color(0xFF059669),
    Color(0xFFD97706), Color(0xFF2563EB), Color(0xFF0891B2),
    Color(0xFF65A30D), Color(0xFF9333EA), Color(0xFFDC2626),
    Color(0xFF0D9488),
  ];

  Color get _accent => _palette[_idx % _palette.length];

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _slideAnim = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _goTo(int newIdx, bool forward) async {
    _slideAnim = Tween<Offset>(
      begin: Offset(forward ? 1.0 : -1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    setState(() => _idx = newIdx);
    _slideCtrl.forward(from: 0);
  }

  Future<void> _speakLetter() async {
    final letter = FULL_ALPHABET[_idx];
    setState(() => _emotion = AvatarEmotion.speaking);
    // Speak letter name + all example words
    final words = letter.examples.map((e) => e.word).join('۔ ');
    await TtsService.instance.speak('${letter.urdu}۔ ${letter.roman}۔ $words');
    if (mounted) setState(() => _emotion = AvatarEmotion.happy);
  }

  Future<void> _speakExample(LetterExample ex) async {
    setState(() => _emotion = AvatarEmotion.speaking);
    await TtsService.instance.speak(ex.word);
    if (mounted) setState(() => _emotion = AvatarEmotion.happy);
  }

  void _openMic() {
    final letter = FULL_ALPHABET[_idx];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MicRecorderWidget(
        targetText: letter.urdu,
        targetRoman: letter.roman,
        onScore: (score, transcript) {
          Navigator.pop(context);
          setState(() {
            _scores[_idx] = score;
            _emotion = score >= 70 ? AvatarEmotion.happy : AvatarEmotion.sad;
          });
          context.read<AppProvider>().recordResult(letter.urdu, score);
          final name = context.read<AppProvider>().userName;
          TtsService.instance.speak(
            score >= 70
                ? (name.isNotEmpty ? 'شاباش $name!' : 'شاباش! بہت اچھا!')
                : 'دوبارہ کوشش کریں۔',
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final letter = FULL_ALPHABET[_idx];
    final score = _scores[_idx];

    return Scaffold(
      backgroundColor: _accent.withOpacity(0.06),
      appBar: AppBar(
        title: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text('حروف تہجی',
              style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 22)),
        ),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Teacher banner ─────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: double.infinity,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                ProfessorAvatar(emotion: _emotion, size: 80),
                if (provider.userName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      'آؤ ${provider.userName}، حروف سیکھیں!',
                      style: const TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              children: [
                Text('${_idx + 1}/${FULL_ALPHABET.length}',
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (_idx + 1) / FULL_ALPHABET.length,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(_accent),
                      minHeight: 5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Main content (scrollable) ──────────────────────────────────
          Expanded(
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  children: [
                    // ── Big letter card ─────────────────────────────────
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: _accent.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border:
                            Border.all(color: _accent.withOpacity(0.3), width: 2),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      child: Column(
                        children: [
                          // Huge letter
                          Text(
                            letter.urdu,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: 'NotoNastaliqUrdu',
                              fontSize: 110,
                              fontWeight: FontWeight.bold,
                              color: _accent,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Roman name
                          Text(
                            letter.roman,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Score ring
                          if (score != null) ...[
                            SizedBox(
                              width: 64, height: 64,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: score / 100,
                                    strokeWidth: 6,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        score >= 70
                                            ? Colors.green
                                            : Colors.orange),
                                  ),
                                  Text('${score.toInt()}%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: score >= 70
                                            ? Colors.green
                                            : Colors.orange,
                                      )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          // Listen + Speak buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _speakLetter,
                                  icon: const Text('🔊',
                                      style: TextStyle(fontSize: 20)),
                                  label: const Text('سنیں',
                                      style: TextStyle(
                                          fontFamily: 'NotoNastaliqUrdu',
                                          fontSize: 16)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.teal,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _openMic,
                                  icon: const Text('🎤',
                                      style: TextStyle(fontSize: 20)),
                                  label: const Text('بولیں',
                                      style: TextStyle(
                                          fontFamily: 'NotoNastaliqUrdu',
                                          fontSize: 16)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _accent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Example words label ─────────────────────────────
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${letter.urdu} سے شروع ہونے والے الفاظ',
                          style: TextStyle(
                            fontFamily: 'NotoNastaliqUrdu',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _accent,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Example word cards ──────────────────────────────
                    ...letter.examples.map((ex) => _ExampleCard(
                          example: ex,
                          accent: _accent,
                          onSpeak: () => _speakExample(ex),
                        )),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // ── Navigation bar ─────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Row(
              children: [
                _NavBtn(
                  label: '← پچھلا',
                  enabled: _idx > 0,
                  color: _accent,
                  onTap: () => _goTo(_idx - 1, false),
                ),
                const Spacer(),
                // Dot indicators (show up to 12, compressed)
                _DotRow(
                    total: FULL_ALPHABET.length,
                    current: _idx,
                    color: _accent),
                const Spacer(),
                _NavBtn(
                  label: 'اگلا →',
                  enabled: _idx < FULL_ALPHABET.length - 1,
                  color: _accent,
                  onTap: () => _goTo(_idx + 1, true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Example word card ────────────────────────────────────────────────────────
class _ExampleCard extends StatelessWidget {
  final LetterExample example;
  final Color accent;
  final VoidCallback onSpeak;

  const _ExampleCard({
    required this.example,
    required this.accent,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: accent.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onSpeak,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Tap-to-listen hint
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.volume_up_rounded,
                      color: accent, size: 18),
                ),
                const SizedBox(width: 12),
                // Big emoji
                Text(example.emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 14),
                // Word + meaning
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          example.word,
                          style: TextStyle(
                            fontFamily: 'NotoNastaliqUrdu',
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: accent,
                            height: 1.3,
                          ),
                        ),
                      ),
                      Text(
                        example.meaning,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Navigation button ────────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final String label;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;
  const _NavBtn(
      {required this.label,
      required this.enabled,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: enabled ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(22),
          boxShadow: enabled
              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'NotoNastaliqUrdu',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: enabled ? Colors.white : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}

// ─── Dot row ──────────────────────────────────────────────────────────────────
class _DotRow extends StatelessWidget {
  final int total;
  final int current;
  final Color color;
  const _DotRow({required this.total, required this.current, required this.color});

  @override
  Widget build(BuildContext context) {
    // Show at most 7 dots around current position
    const visible = 7;
    int start = (current - visible ~/ 2).clamp(0, total - visible);
    if (start + visible > total) start = (total - visible).clamp(0, total);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(visible.clamp(0, total), (i) {
        final idx = start + i;
        final isActive = idx == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
