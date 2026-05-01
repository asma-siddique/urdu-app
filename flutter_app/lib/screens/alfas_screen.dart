
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/urdu_word.dart';
import '../providers/app_provider.dart';
import '../services/tts_service.dart';
import '../widgets/professor_avatar.dart';
import '../widgets/mic_recorder_widget.dart';

/// Updated lesson screen for specific Urdu letters (Alif, Be, etc.)
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
  State<CategoryLessonScreen> createState() => _CategoryLessonScreenState();
}

class _CategoryLessonScreenState extends State<CategoryLessonScreen> {
  final AvatarEmotion _emotion = AvatarEmotion.happy;
  final Map<int, double> _scores = {};

  // Function to get the reference words and emojis for each letter
  List<Map<String, String>> getLetterWords(String letter) {
    if (letter == "Alif") {
      return [
        {"word": "Angoor", "image": "assets/angoor.png", "emoji": "🍇"},
        {"word": "Anar", "image": "assets/anar.png", "emoji": "🍎"},
        {"word": "Oond", "image": "assets/oond.png", "emoji": "🦄"},
      ];
    }
    // Additional letters can be added here.
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final letterWords = getLetterWords(widget.title);  // Fetch words for the current letter

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          // Display the professor avatar
          ProfessorAvatar(emotion: _emotion, size: 150),

          // Display the lesson's reference words, emojis, and images
          Expanded(
            child: ListView.builder(
              itemCount: letterWords.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // Display the emoji
                        Text(
                          letterWords[index]['emoji']!,
                          style: const TextStyle(fontSize: 40),
                        ),
                        const SizedBox(width: 10),
                        // Display the word and image
                        Image.asset(letterWords[index]['image']!, height: 50),
                        const SizedBox(width: 10),
                        Text(
                          letterWords[index]['word']!,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Navigation buttons (next/previous words or lessons)
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 30),
                  onPressed: () {
                    // Navigate to previous word (implement functionality later)
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 30),
                  onPressed: () {
                    // Navigate to next word (implement functionality later)
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
