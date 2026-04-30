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

class _HaroofScreenState extends State<HaroofScreen> {
  AvatarEmotion _emotion = AvatarEmotion.happy;
  int _selectedIndex = 0;
  late final PageController _pageController;

  // Per-letter pronunciation score (null = not yet attempted)
  final Map<int, double> _scores = {};

  static const List<Color> _circleColors = [
    Color(0xFF9b5de5), Color(0xFFf15bb5), Color(0xFF00bbf9),
    Color(0xFFff6d00), Color(0xFF00f5d4), Color(0xFFfee440),
    Color(0xFF3a86ff), Color(0xFFfb5607),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88, initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color _circleColor(int index) =>
      _circleColors[index % _circleColors.length];

  // ── TTS: only called from explicit tap ─────────────────────────────────
  Future<void> _speakLetter(UrduLetter letter) async {
    setState(() => _emotion = AvatarEmotion.speaking);
    await TtsService.instance.speak('${letter.urdu}۔ ${letter.example}۔');
    if (mounted) setState(() => _emotion = AvatarEmotion.happy);
  }

  // ── Mic: open bottom sheet, show score ─────────────────────────────────
  void _openMic(int index, UrduLetter letter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MicRecorderWidget(
        targetText: letter.urdu,
        targetRoman: letter.roman,
        onScore: (score, transcript) {
          Navigator.pop(context);
          // save score for this letter
          setState(() {
            _scores[index] = score;
            _emotion = score >= 70 ? AvatarEmotion.happy : AvatarEmotion.sad;
          });
          // record to provider for adaptive quiz
          context.read<AppProvider>().recordResult(letter.urdu, score);
          TtsService.instance.speak(
            score >= 70 ? 'شاباش! تلفظ درست ہے۔' : 'دوبارہ کوشش کریں۔',
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'حروف تہجی',
            style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 22),
          ),
        ),
        backgroundColor: AppTheme.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Professor Avatar banner ────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppTheme.headerGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: ProfessorAvatar(emotion: _emotion, size: 90),
            ),
          ),

          const SizedBox(height: 16),

          // ── Letter selector chips ──────────────────────────────────────
          SizedBox(
            height: 40,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: FULL_ALPHABET.length,
                itemBuilder: (ctx, i) {
                  final selected = i == _selectedIndex;
                  return GestureDetector(
                    onTap: () => _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.purple : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppTheme.purple
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        FULL_ALPHABET[i].urdu,
                        style: TextStyle(
                          fontFamily: 'NotoNastaliqUrdu',
                          fontSize: 16,
                          color: selected ? Colors.white : AppTheme.navy,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Letter Cards PageView ──────────────────────────────────────
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: FULL_ALPHABET.length,
              onPageChanged: (i) => setState(() => _selectedIndex = i),
              itemBuilder: (ctx, i) {
                final letter = FULL_ALPHABET[i];
                final isActive = i == _selectedIndex;
                return AnimatedScale(
                  scale: isActive ? 1.0 : 0.88,
                  duration: const Duration(milliseconds: 300),
                  child: _LetterCard(
                    letter: letter,
                    circleColor: _circleColor(i),
                    score: _scores[i],
                    onSpeak: () => _speakLetter(letter),
                    onMic: () => _openMic(i, letter),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // ── Page counter (force LTR so it doesn't flip) ───────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '${_selectedIndex + 1} / ${FULL_ALPHABET.length}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Letter Card ────────────────────────────────────────────────────────────
class _LetterCard extends StatelessWidget {
  final UrduLetter letter;
  final Color circleColor;
  final double? score;       // null = not attempted yet
  final VoidCallback onSpeak;
  final VoidCallback onMic;

  const _LetterCard({
    required this.letter,
    required this.circleColor,
    required this.onSpeak,
    required this.onMic,
    this.score,
  });

  Color get _scoreColor {
    if (score == null) return Colors.grey;
    if (score! >= 70) return Colors.green;
    if (score! >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top row: emoji + letter + name ──────────────────────────
            Row(
              children: [
                // Emoji circle
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: circleColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: circleColor, width: 2),
                  ),
                  child: Center(
                    child: Text(letter.emoji,
                        style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 16),
                // Big Urdu letter
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    letter.urdu,
                    style: TextStyle(
                      fontFamily: 'NotoNastaliqUrdu',
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: circleColor,
                      height: 1.0,
                    ),
                  ),
                ),
                const Spacer(),
                // Roman name + example column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      letter.roman,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        letter.example,
                        style: const TextStyle(
                          fontFamily: 'NotoNastaliqUrdu',
                          fontSize: 20,
                          color: AppTheme.navy,
                        ),
                      ),
                    ),
                    Text(
                      letter.exampleMeaning,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Score badge (shown after mic attempt) ────────────────────
            if (score != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _scoreColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _scoreColor.withOpacity(0.5), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Circular accuracy ring
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: score! / 100,
                            strokeWidth: 5,
                            backgroundColor: _scoreColor.withOpacity(0.2),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(_scoreColor),
                          ),
                          Text(
                            '${score!.toInt()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _scoreColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'تلفظ کی درستگی',
                          style: TextStyle(
                            fontFamily: 'NotoNastaliqUrdu',
                            fontSize: 13,
                            color: _scoreColor,
                            fontWeight: FontWeight.bold,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        Text(
                          'Wav2Vec2 + BiLSTM model',
                          style: TextStyle(
                            fontSize: 10,
                            color: _scoreColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            if (score != null) const SizedBox(height: 12),

            // ── Listen + Speak buttons ───────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSpeak,
                    icon: const Text('🔊',
                        style: TextStyle(fontSize: 18)),
                    label: const Text(
                      'سنیں',
                      style: TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onMic,
                    icon: const Text('🎤',
                        style: TextStyle(fontSize: 18)),
                    label: const Text(
                      'بولیں',
                      style: TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
