
import 'package:flutter/material.dart';
import '../widgets/professor_avatar.dart';

class ColorSectionScreen extends StatelessWidget {
  const ColorSectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Colors in Urdu', style: TextStyle(fontSize: 24))),
      body: Column(
        children: [
          // Display the professor avatar
          const ProfessorAvatar(emotion: AvatarEmotion.happy, size: 150),

          // Display color objects with their names
          Expanded(
            child: ListView(
              children: const [
                ColorItem(color: Colors.red, urduName: "Surkh", object: "Apple", imagePath: 'assets/apple.png'),
                ColorItem(color: Colors.green, urduName: "Hara", object: "Tree", imagePath: 'assets/tree.png'),
                ColorItem(color: Colors.blue, urduName: "Neela", object: "Sky", imagePath: 'assets/sky.png'),
                // Add more colors and objects
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ColorItem extends StatelessWidget {
  final Color color;
  final String urduName;
  final String object;
  final String imagePath;

  const ColorItem({super.key, 
    required this.color,
    required this.urduName,
    required this.object,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Image.asset(imagePath, height: 50),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  urduName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  object,
                  style: const TextStyle(fontSize: 22),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
