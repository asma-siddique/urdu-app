import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../data/jor_tor.dart';
import '../widgets/professor_avatar.dart';
import '../widgets/mic_recorder_widget.dart';
import '../services/tts_service.dart';
import '../providers/app_provider.dart';

class JorTorScreen extends StatefulWidget {
  const JorTorScreen({super.key});
  @override
  State<JorTorScreen> createState() => _JorTorScreenState();
}

class _JorTorScreenState extends State<JorTorScreen>
    with SingleTickerProviderStateMixin {
  AvatarEmotion _emotion = AvatarEmotion.happy;
  int _idx = 0;
  double? _lastScore;

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
        vsync: this, duration: const Duration(milliseconds: 260));
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
    setState(() {
      _idx = newIdx;
      _lastScore = null;
    });
    _slideCtrl.forward(from: 0);
  }

  Future<void> _speakItem() async {
    final item = JOR_TOR[_idx];
    setState(() => _emotion = AvatarEmotion.speaking);
    await TtsService.instance
        .speak('${item.letter}۔ ${item.vowelMark}۔ ${item.result}۔ جیسے ${item.exampleWord}');
    if (mounted) setState(() => _emotion = AvatarEmotion.happy);
  }

  void _openMic() {
    final item = JOR_TOR[_idx];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MicRecorderWidget(
        targetText: item.result,
        targetRoman: item.resultRoman,
        onScore: (score, _) {
          Navigator.pop(context);
          setState(() {
            _lastScore = score;
            _emotion = score >= 70 ? AvatarEmotion.happy : AvatarEmotion.sad;
          });
          final name = context.read<AppProvider>().userName;
          TtsService.instance.speak(
            score >= 70
                ? (name.isNotEmpty ? 'شاباش $name!' : 'شاباش!')
                : 'دوبارہ کوشش کریں۔',
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = JOR_TOR[_idx];
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: _accent.withOpacity(0.05),
      appBar: AppBar(
        title: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text('جوڑ توڑ',
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
            duration: const Duration(milliseconds: 350),
            width: double.infinity,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(children: [
              ProfessorAvatar(emotion: _emotion, size: 76),
              if (provider.userName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    'آؤ ${provider.userName}، حروف جوڑنا سیکھیں!',
                    style: const TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        color: Colors.white,
                        fontSize: 13),
                  ),
                ),
              ],
            ]),
          ),

          // Progress
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(children: [
              Text('${_idx + 1}/${JOR_TOR.length}',
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_idx + 1) / JOR_TOR.length,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(_accent),
                    minHeight: 5,
                  ),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 8),

          // ── Main card (scrollable so it never overflows) ───────────────
          Expanded(
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _JorTorCard(
                  item: item,
                  accent: _accent,
                  score: _lastScore,
                  onSpeak: _speakItem,
                  onMic: _openMic,
                ),
              ),
            ),
          ),

          // ── Navigation ─────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Row(children: [
              _NavBtn(
                  label: '← پچھلا',
                  enabled: _idx > 0,
                  color: _accent,
                  onTap: () => _goTo(_idx - 1, false)),
              const Spacer(),
              // Vowel group badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _accent.withOpacity(0.3)),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    '${item.letter} + ${item.vowelMark} = ${item.result}',
                    style: TextStyle(
                      fontFamily: 'NotoNastaliqUrdu',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _accent,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              _NavBtn(
                  label: 'اگلا →',
                  enabled: _idx < JOR_TOR.length - 1,
                  color: _accent,
                  onTap: () => _goTo(_idx + 1, true)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────
class _JorTorCard extends StatelessWidget {
  final JorTorItem item;
  final Color accent;
  final double? score;
  final VoidCallback onSpeak;
  final VoidCallback onMic;

  const _JorTorCard({
    required this.item,
    required this.accent,
    required this.score,
    required this.onSpeak,
    required this.onMic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: accent.withOpacity(0.15),
              blurRadius: 18,
              offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Vowel name badge ──────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withOpacity(0.3)),
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                '${item.vowelName} کی آواز',
                style: TextStyle(
                  fontFamily: 'NotoNastaliqUrdu',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Equation row: BIG letter + operator + BIG vowel + = + BIG result ──
          Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _LetterBox(text: item.letter, color: const Color(0xFF7C3AED)),
                _OpText('+'),
                _LetterBox(text: item.vowelMark, color: const Color(0xFF0891B2)),
                _OpText('='),
                _LetterBox(text: item.result, color: accent, highlighted: true),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Roman row
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RomanTag(item.letterRoman, const Color(0xFF7C3AED)),
                const SizedBox(width: 20),
                _RomanTag(item.vowelRoman, const Color(0xFF0891B2)),
                const SizedBox(width: 20),
                _RomanTag(item.resultRoman, accent, bold: true),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Example word ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.emoji == '—' ? '📌' : item.emoji,
                  style: const TextStyle(fontSize: 44),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          item.exampleWord,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'NotoNastaliqUrdu',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: accent,
                            height: 1.4,
                          ),
                        ),
                      ),
                      Text(
                        item.exampleMeaning,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Score ring ────────────────────────────────────────────────
          if (score != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: 60, height: 60,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: score! / 100,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      score! >= 70 ? Colors.green : Colors.orange),
                ),
                Text('${score!.toInt()}%',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: score! >= 70 ? Colors.green : Colors.orange)),
              ]),
            ),
          ],

          const SizedBox(height: 16),

          // ── Buttons ───────────────────────────────────────────────────
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onSpeak,
                icon: const Text('🔊', style: TextStyle(fontSize: 20)),
                label: const Text('سنیں',
                    style: TextStyle(
                        fontFamily: 'NotoNastaliqUrdu', fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onMic,
                icon: const Text('🎤', style: TextStyle(fontSize: 20)),
                label: const Text('بولیں',
                    style: TextStyle(
                        fontFamily: 'NotoNastaliqUrdu', fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _LetterBox extends StatelessWidget {
  final String text;
  final Color color;
  final bool highlighted;
  const _LetterBox({required this.text, required this.color, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: highlighted ? Border.all(color: color, width: 2.5) : null,
      ),
      child: Text(text,
          style: TextStyle(
            fontFamily: 'NotoNastaliqUrdu',
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: color,
            height: 1.1,
          )),
    );
  }
}

class _OpText extends StatelessWidget {
  final String text;
  const _OpText(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Text(text,
        style: const TextStyle(
            fontSize: 30,
            color: Colors.black38,
            fontWeight: FontWeight.bold)),
  );
}

class _RomanTag extends StatelessWidget {
  final String text;
  final Color color;
  final bool bold;
  const _RomanTag(this.text, this.color, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(
            fontSize: bold ? 16 : 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: color,
          )),
    );
  }
}

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
        child: Text(label,
            style: TextStyle(
              fontFamily: 'NotoNastaliqUrdu',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: enabled ? Colors.white : Colors.grey.shade400,
            )),
      ),
    );
  }
}
