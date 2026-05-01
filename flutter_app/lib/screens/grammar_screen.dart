import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/tts_service.dart';
import '../widgets/professor_avatar.dart';
import '../widgets/mic_recorder_widget.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class _SingularPlural {
  final String singular;
  final String plural;
  final String english;
  final String emoji;

  const _SingularPlural({
    required this.singular,
    required this.plural,
    required this.english,
    required this.emoji,
  });
}

class GrammarScreen extends StatefulWidget {
  const GrammarScreen({super.key});

  @override
  State<GrammarScreen> createState() => _GrammarScreenState();
}

class _GrammarScreenState extends State<GrammarScreen> {
  AvatarEmotion _emotion = AvatarEmotion.happy;

  // Per-word pronunciation score (singular index)
  final Map<int, double> _scores = {};

  static const List<_SingularPlural> _words = [
    _SingularPlural(singular: 'بچہ',    plural: 'بچے',     english: 'Child / Children',      emoji: '👶'),
    _SingularPlural(singular: 'کتا',    plural: 'کتے',     english: 'Dog / Dogs',             emoji: '🐶'),
    _SingularPlural(singular: 'پھول',   plural: 'پھول',    english: 'Flower / Flowers',       emoji: '🌸'),
    _SingularPlural(singular: 'کتاب',   plural: 'کتابیں',  english: 'Book / Books',           emoji: '📚'),
    _SingularPlural(singular: 'قلم',    plural: 'قلمیں',   english: 'Pen / Pens',             emoji: '✒️'),
    _SingularPlural(singular: 'لڑکا',   plural: 'لڑکے',   english: 'Boy / Boys',             emoji: '👦'),
    _SingularPlural(singular: 'لڑکی',   plural: 'لڑکیاں', english: 'Girl / Girls',           emoji: '👧'),
    _SingularPlural(singular: 'درخت',   plural: 'درخت',    english: 'Tree / Trees',           emoji: '🌳'),
    _SingularPlural(singular: 'گھر',    plural: 'گھر',     english: 'House / Houses',         emoji: '🏠'),
    _SingularPlural(singular: 'کمرہ',   plural: 'کمرے',    english: 'Room / Rooms',           emoji: '🛏️'),
    _SingularPlural(singular: 'استاد',  plural: 'اساتذہ',  english: 'Teacher / Teachers',     emoji: '👨‍🏫'),
    _SingularPlural(singular: 'طالب علم',plural:'طلباء',   english: 'Student / Students',     emoji: '🧑‍🎓'),
    _SingularPlural(singular: 'گائے',   plural: 'گائیں',   english: 'Cow / Cows',             emoji: '🐄'),
    _SingularPlural(singular: 'مرغی',   plural: 'مرغیاں',  english: 'Hen / Hens',             emoji: '🐔'),
    _SingularPlural(singular: 'پرندہ',  plural: 'پرندے',   english: 'Bird / Birds',           emoji: '🐦'),
  ];

  Future<void> _speak(String text) async {
    setState(() => _emotion = AvatarEmotion.speaking);
    await TtsService.instance.speak(text);
    if (mounted) setState(() => _emotion = AvatarEmotion.happy);
  }

  void _openMic(int index, _SingularPlural word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MicRecorderWidget(
        targetText: word.singular,
        targetRoman: word.english.split('/').first.trim(),
        onScore: (score, _) {
          Navigator.pop(context);
          setState(() {
            _scores[index] = score;
            _emotion =
                score >= 70 ? AvatarEmotion.happy : AvatarEmotion.sad;
          });
          context.read<AppProvider>().recordResult(word.singular, score);
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
        title: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text('واحد جمع',
              style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 22)),
        ),
        backgroundColor: const Color(0xFFd97706),
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
                  colors: [Color(0xFFd97706), Color(0xFFb45309)]),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
                child: ProfessorAvatar(emotion: _emotion, size: 80)),
          ),
          // Header row
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text('واحد',
                        style: TextStyle(
                            fontFamily: 'NotoNastaliqUrdu',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFd97706))),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Center(
                    child: Text('جمع',
                        style: TextStyle(
                            fontFamily: 'NotoNastaliqUrdu',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFb45309))),
                  ),
                ),
              ],
            ),
          ),
          // Word list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: _words.length,
              itemBuilder: (ctx, i) {
                final word = _words[i];
                final score = _scores[i];
                final scoreColor = score == null
                    ? Colors.grey
                    : score >= 70
                        ? Colors.green
                        : score >= 50
                            ? Colors.orange
                            : Colors.red;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
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
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        // Emoji
                        Text(word.emoji,
                            style: const TextStyle(fontSize: 30)),
                        const SizedBox(width: 10),
                        // Singular
                        Expanded(
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(word.singular,
                                    style: const TextStyle(
                                        fontFamily: 'NotoNastaliqUrdu',
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFd97706))),
                                Text(word.english.split('/').first.trim(),
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                        // Arrow
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: Colors.grey),
                        ),
                        // Plural
                        Expanded(
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(word.plural,
                                    style: const TextStyle(
                                        fontFamily: 'NotoNastaliqUrdu',
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFb45309))),
                                Text(word.english.split('/').last.trim(),
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                        // Buttons
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () => _speak(
                                  '${word.singular}۔ ${word.plural}'),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.teal.withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: const Text('🔊',
                                    style: TextStyle(fontSize: 18)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => _openMic(i, word),
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
                            if (score != null) ...[
                              const SizedBox(height: 4),
                              SizedBox(
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
                            ],
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
