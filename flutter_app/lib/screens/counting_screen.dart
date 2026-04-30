import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/counting.dart';
import '../services/tts_service.dart';
import '../widgets/professor_avatar.dart';
import '../widgets/mic_recorder_widget.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class CountingScreen extends StatefulWidget {
  const CountingScreen({super.key});

  @override
  State<CountingScreen> createState() => _CountingScreenState();
}

class _CountingScreenState extends State<CountingScreen> {
  AvatarEmotion _emotion = AvatarEmotion.happy;
  final Map<int, double> _scores = {};

  Future<void> _speak(UrduNumber num) async {
    setState(() => _emotion = AvatarEmotion.speaking);
    await TtsService.instance.speak('${num.urdu}۔ ${num.roman}');
    if (mounted) setState(() => _emotion = AvatarEmotion.happy);
  }

  void _openMic(int index, UrduNumber num) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MicRecorderWidget(
        targetText: num.urdu,
        targetRoman: num.roman,
        onScore: (score, _) {
          Navigator.pop(context);
          setState(() {
            _scores[index] = score;
            _emotion = score >= 70 ? AvatarEmotion.happy : AvatarEmotion.sad;
          });
          // Record result using urdu word as key
          context.read<AppProvider>().recordResult(num.urdu, score);
          TtsService.instance.speak(
              score >= 70 ? 'شاباش!' : 'دوبارہ کوشش کریں۔');
        },
      ),
    );
  }

  static const List<Color> _cardColors = [
    Color(0xFF0d9488), Color(0xFF0090c7), Color(0xFF9b5de5),
    Color(0xFFf15bb5), Color(0xFFff6d00), Color(0xFF059669),
    Color(0xFF3a86ff), Color(0xFFdc2626), Color(0xFF7c3aed),
    Color(0xFFd97706),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text('گنتی',
              style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 22)),
        ),
        backgroundColor: const Color(0xFF0d9488),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Avatar banner
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF0d9488), Color(0xFF0f766e)]),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
                child: ProfessorAvatar(emotion: _emotion, size: 80)),
          ),
          // Number grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 150,
              ),
              itemCount: COUNTING.length,
              itemBuilder: (ctx, i) {
                final num = COUNTING[i];
                final score = _scores[i];
                final cardColor =
                    _cardColors[i % _cardColors.length];
                final scoreColor = score == null
                    ? Colors.grey
                    : score >= 70
                        ? Colors.green
                        : score >= 50
                            ? Colors.orange
                            : Colors.red;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8,
                          offset: Offset(0, 3))
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Numeral circle
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: cardColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: cardColor, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              num.numeral,
                              style: TextStyle(
                                fontFamily: 'NotoNastaliqUrdu',
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: cardColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Urdu word
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(num.urdu,
                              style: TextStyle(
                                fontFamily: 'NotoNastaliqUrdu',
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.navy,
                              )),
                        ),
                        // Roman
                        Text(num.roman,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.blueGrey)),
                        // Score ring (if attempted)
                        if (score != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: score / 100,
                                    strokeWidth: 3,
                                    backgroundColor:
                                        scoreColor.withOpacity(0.2),
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                            scoreColor),
                                  ),
                                  Text('${score.toInt()}',
                                      style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: scoreColor)),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        // Listen + Speak row
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: () => _speak(num),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.teal
                                      .withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: const Text('🔊',
                                    style: TextStyle(fontSize: 18)),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _openMic(i, num),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.purple
                                      .withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: const Text('🎤',
                                    style: TextStyle(fontSize: 18)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
