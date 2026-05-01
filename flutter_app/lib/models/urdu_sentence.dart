class UrduSentence {
  final String urdu;
  final String english;
  final List<String> words;    // individual Urdu words for word-by-word highlight
  final String blankWord;      // word removed for fill-in-the-blank quiz

  const UrduSentence({
    required this.urdu,
    required this.english,
    required this.words,
    required this.blankWord,
  });
}
