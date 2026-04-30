import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/jor_tor.dart';
import '../widgets/professor_avatar.dart';
import '../widgets/mic_recorder_widget.dart';
import '../services/tts_service.dart';

class JorTorScreen extends StatefulWidget {
  const JorTorScreen({super.key});

  @override
  State<JorTorScreen> createState() => _JorTorScreenState();
}

class _JorTorScreenState extends State<JorTorScreen> {
  AvatarEmotion _emotion = AvatarEmotion.happy;
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.90, initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _speakItem(JorTorItem item) async {
    setState(() => _emotion = AvatarEmotion.speaking);
    await TtsService.instance.speak(
      '${item.letter}۔ ${item.vowelMark}۔ ${item.result}۔ جیسے ${item.exampleWord}',
    );
    if (mounted) setState(() => _emotion = AvatarEmotion.happy);
  }

  void _openMic(JorTorItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MicRecorderWidget(
        targetText: item.result,
        targetRoman: item.resultRoman,
        onScore: (score, transcript) {
          Navigator.pop(context);
          setState(() {
            _emotion = score >= 70 ? AvatarEmotion.happy : AvatarEmotion.sad;
          });
          TtsService.instance.speak(
            score >= 70 ? 'شاباش! بہت اچھا!' : 'دوبارہ کوشش کریں۔',
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
            'جوڑ توڑ',
            style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 22),
          ),
        ),
        backgroundColor: AppTheme.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Professor banner
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

          // PageView of JorTor cards
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: JOR_TOR.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (ctx, i) {
                final item = JOR_TOR[i];
                final isActive = i == _currentIndex;
                return AnimatedScale(
                  scale: isActive ? 1.0 : 0.88,
                  duration: const Duration(milliseconds: 300),
                  child: _JorTorCard(
                    item: item,
                    onSpeak: () => _speakItem(item),
                    onMic: () => _openMic(item),
                  ),
                );
              },
            ),
          ),

          // Page counter
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '${_currentIndex + 1} / ${JOR_TOR.length}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JorTorCard extends StatelessWidget {
  final JorTorItem item;
  final VoidCallback onSpeak;
  final VoidCallback onMic;

  const _JorTorCard({
    required this.item,
    required this.onSpeak,
    required this.onMic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Letter combination: Letter + "+" + Vowel + "=" + Result
            Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BigLetter(text: item.letter, color: AppTheme.purple),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('+', style: TextStyle(fontSize: 28, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                  _BigLetter(text: item.vowelMark, color: AppTheme.teal),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('=', style: TextStyle(fontSize: 28, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                  _BigLetter(text: item.result, color: AppTheme.pink, highlighted: true),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Roman below
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RomanLabel(item.letterRoman),
                  const SizedBox(width: 24),
                  _RomanLabel(item.vowelRoman),
                  const SizedBox(width: 24),
                  _RomanLabel(item.resultRoman, bold: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Example word
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.purple.withOpacity(0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.purple.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.emoji == '—' ? '📌' : item.emoji,
                      style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          item.exampleWord,
                          style: const TextStyle(
                            fontFamily: 'NotoNastaliqUrdu',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.navy,
                          ),
                        ),
                      ),
                      Text(
                        item.exampleMeaning,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSpeak,
                    icon: const Text('🔊', style: TextStyle(fontSize: 18)),
                    label: const Text(
                      'سنیں',
                      style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onMic,
                    icon: const Text('🎤', style: TextStyle(fontSize: 18)),
                    label: const Text(
                      'بولیں',
                      style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

class _BigLetter extends StatelessWidget {
  final String text;
  final Color color;
  final bool highlighted;

  const _BigLetter({required this.text, required this.color, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: highlighted
          ? BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 2),
            )
          : null,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'NotoNastaliqUrdu',
          fontSize: 52,
          fontWeight: FontWeight.bold,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }
}

class _RomanLabel extends StatelessWidget {
  final String text;
  final bool bold;

  const _RomanLabel(this.text, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: bold ? 16 : 13,
        color: bold ? AppTheme.pink : Colors.grey,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
