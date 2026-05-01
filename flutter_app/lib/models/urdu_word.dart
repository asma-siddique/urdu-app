class UrduWord {
  final String urdu;
  final String roman;
  final String english;
  final String emoji;
  final String category;
  final String level;   // easy | medium | hard
  final String target;  // romanized target for pronunciation scoring

  const UrduWord({
    required this.urdu,
    required this.roman,
    required this.english,
    required this.emoji,
    required this.category,
    required this.level,
    required this.target,
  });
}
