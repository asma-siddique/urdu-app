import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/urdu_word.dart';
import '../providers/app_provider.dart';
import '../services/tts_service.dart';
import '../widgets/professor_avatar.dart';
import '../widgets/mic_recorder_widget.dart';

/// Generic lesson screen for any word category (Animals, Fruits, Body Parts…)
class CategoryLessonScreen extends StatefulWidget {
  final String title;
  final String emoji;
  final List<UrduWord> words;
  final Color accentColor;

  const CategoryLessonScreen({
    super.key,
    required this.title,
    required this.emoji,
    required this.words,
    required this.accentColor,
  });

  @override
  State<CategoryLessonScreen> createState() =>
      _CategoryLessonScreenState();
}

class _CategoryLessonScreenState extends State<CategoryLessonScreen> {
  AvatarEmotion _emotion = AvatarEmotion.happy;
  final Map<int, double> _scores = {};

  Future<void> _speak(String text) async {
    setState(() => _emotion = AvatarEmotion.speaking);
    await TtsService.instance.speak(text);
    if (mounted) setState(() => _emotion = AvatarEmotion.happy);
  }

  void _openMic(int index, UrduWord word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MicRecorderWidget(
        targetText: word.urdu,
        targetRoman: word.roman,
        onScore: (score, _) {
          Navigator.pop(context);
          setState(() {
            _scores[index] = score;
            _emotion =
                score >= 70 ? AvatarEmotion.happy : AvatarEmotion.sad;
          });
          context.read<AppProvider>().recordResult(word.urdu, score);
          TtsService.instance.speak(
              score >= 70 ? 'شاباش!' : 'دوبارہ کوشش کریں۔');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(widget.title,
              style: const TextStyle(
                  fontFamily: 'NotoNastaliqUrdu', fontSize: 22)),
        ),
        backgroundColor: widget.accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Avatar banner
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                widget.accentColor,
                widget.accentColor.withOpacity(0.7)
              ]),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
                child: ProfessorAvatar(emotion: _emotion, size: 80)),
          ),
          // Word list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.words.length,
              itemBuilder: (ctx, i) {
                final word = widget.words[i];
                final score = _scores[i];
                final scoreColor = score == null
                    ? Colors.grey
                    : score >= 70
                        ? Colors.green
                        : score >= 50
                            ? Colors.orange
                            : Colors.red;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8,
                          offset: Offset(0, 3))
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Emoji
                        Text(word.emoji,
                            style: const TextStyle(fontSize: 40)),
                        const SizedBox(width: 14),
                        // Urdu + English
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text(word.urdu,
                                    style: const TextStyle(
                                        fontFamily: 'NotoNastaliqUrdu',
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.navy,
                                        height: 1.1)),
                              ),
                              Text(word.english,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey)),
                              Text(word.roman,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.blueGrey)),
                            ],
                          ),
                        ),
                        // Score ring
                        if (score != null) ...[
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: score / 100,
                                  strokeWidth: 4,
                                  backgroundColor:
                                      scoreColor.withOpacity(0.2),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          scoreColor),
                                ),
                                Text('${score.toInt()}%',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: scoreColor)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Listen + Speak buttons
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () => _speak(
                                  '${word.urdu}۔ ${word.english}'),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.teal
                                      .withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: const Text('🔊',
                                    style: TextStyle(fontSize: 20)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () => _openMic(i, word),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.purple
                                      .withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                                child: const Text('🎤',
                                    style: TextStyle(fontSize: 20)),
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
