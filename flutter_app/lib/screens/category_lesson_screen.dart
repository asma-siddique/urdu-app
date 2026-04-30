
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
  State<CategoryLessonScreen> createState() => _CategoryLessonScreenState();
}

class _CategoryLessonScreenState extends State<CategoryLessonScreen> {
  AvatarEmotion _emotion = AvatarEmotion.happy;
  final Map<int, double> _scores = {};

  // Function to get the reference words and images for animals and counting numbers
  List<Map<String, String>> getLessonContent(String title) {
    if (title == "Animals") {
      return [
        {"animal": "Lion", "image": "assets/lion.png"},
        {"animal": "Elephant", "image": "assets/elephant.png"},
        {"animal": "Monkey", "image": "assets/monkey.png"},
        {"animal": "Tiger", "image": "assets/tiger.png"},
        {"animal": "Zebra", "image": "assets/zebra.png"},
        {"animal": "Giraffe", "image": "assets/giraffe.png"},
        {"animal": "Bear", "image": "assets/bear.png"},
        {"animal": "Kangaroo", "image": "assets/kangaroo.png"},
        {"animal": "Penguin", "image": "assets/penguin.png"},
        {"animal": "Rabbit", "image": "assets/rabbit.png"},
        // Add more animals as needed
      ];
    } else if (title == "Counting") {
      List<String> numbers = [];
      for (int i = 1; i <= 100; i++) {
        numbers.add(i.toString());
      }
      return numbers.map((num) => {"number": num, "image": "assets/number.png"}).toList();
    }
    return [];
  }

  Future<void> _speak(String text) async {
    await TtsService.instance.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final content = getLessonContent(widget.title);  // Fetch content for the current category

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          // Display the professor avatar
          ProfessorAvatar(emotion: _emotion, size: 150),

          // Display the content (animals or numbers)
          Expanded(
            child: ListView.builder(
              itemCount: content.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 5,
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Image.asset(content[index]['image']!, height: 50),
                        SizedBox(width: 10),
                        Text(
                          widget.title == "Counting" ? content[index]['number']! : content[index]['animal']!,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
