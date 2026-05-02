/// Thin entry-point widgets that convert existing data → LessonFlowScreen.
/// Each one is a route target — no logic of their own.
import 'package:flutter/material.dart';
import '../data/alphabet.dart';
import '../data/words.dart';
import '../data/counting.dart';
import '../data/sentences.dart';
import '../data/animals_extended.dart';
import '../data/fruits.dart';
import '../data/body_parts.dart';
import '../theme/app_theme.dart';
import 'lesson_flow_screen.dart';

// ── Lesson 1 — Haroof (Alphabet) ─────────────────────────────────────────────

class HaroofLessonScreen extends StatelessWidget {
  const HaroofLessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = FULL_ALPHABET.map((l) => LessonCard(
          mainText: l.urdu,
          name: l.roman,
          transcription: '${l.example} — ${l.exampleMeaning}',
          emoji: l.emoji,
          speakText: '${l.urdu}۔ ${l.roman}۔ مثال: ${l.example}',
          romanTarget: l.roman,
        )).toList();

    return LessonFlowScreen(
      lessonNumber: 1,
      title: 'Urdu Alphabet',
      subtitle: 'Introduction to Urdu Alphabet',
      accentColor: AppTheme.lessonColors[0],
      cards: cards,
    );
  }
}

// ── Lesson 2 — Ginti (Counting 1–100) ────────────────────────────────────────

class GintiLessonScreen extends StatelessWidget {
  const GintiLessonScreen({super.key});

  static const _numberEmojis = [
    '1️⃣','2️⃣','3️⃣','4️⃣','5️⃣','6️⃣','7️⃣','8️⃣','9️⃣','🔟',
    '1️⃣1️⃣','1️⃣2️⃣','1️⃣3️⃣','1️⃣4️⃣','1️⃣5️⃣','1️⃣6️⃣','1️⃣7️⃣','1️⃣8️⃣','1️⃣9️⃣','2️⃣0️⃣',
  ];

  /// For 1-20 use keycap emojis; for 21-99 show the western numeral as text;
  /// 100 gets the 💯 emoji.
  String _emoji(int n) {
    if (n <= 20) return _numberEmojis[n - 1];
    if (n == 100) return '💯';
    return '$n'; // e.g. "24" — displayed in the grey box at top
  }

  @override
  Widget build(BuildContext context) {
    final cards = COUNTING.map((n) => LessonCard(
          mainText: n.numeral,       // Urdu numeral e.g. ٢٤
          name: n.roman,             // e.g. Chaubees
          transcription: n.urdu,     // Urdu word e.g. چوبیس
          emoji: _emoji(n.number),   // visual aid in grey box
          // Use the roman (English) name for TTS — works with any browser voice.
          // Urdu Nastaliq script causes silent failures when no ur-PK voice is loaded.
          speakText: n.roman,
          romanTarget: n.roman,
        )).toList();

    return LessonFlowScreen(
      lessonNumber: 2,
      title: 'Ginti',
      subtitle: 'Counting 1 – 100',
      accentColor: AppTheme.lessonColors[1],
      cards: cards,
    );
  }
}

// ── Lesson 3 — Alfaz (Words) ──────────────────────────────────────────────────

class AlfazLessonScreen extends StatelessWidget {
  const AlfazLessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = WORDS.map((w) => LessonCard(
          mainText: w.urdu,
          name: w.roman,
          transcription: w.english,
          emoji: w.emoji,
          speakText: w.urdu,
          romanTarget: w.roman,
        )).toList();

    return LessonFlowScreen(
      lessonNumber: 3,
      title: 'Alfaz',
      subtitle: 'Urdu Vocabulary',
      accentColor: AppTheme.lessonColors[2],
      cards: cards,
    );
  }
}

// ── Lesson 4 — Jumlay (Sentences) ────────────────────────────────────────────

class JumlaLessonScreen extends StatelessWidget {
  const JumlaLessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = SENTENCES.map((s) => LessonCard(
          mainText: s.urdu,
          name: s.english,
          transcription: s.words.join(' · '),
          emoji: '💬',
          speakText: s.urdu,
          romanTarget: s.english,
        )).toList();

    return LessonFlowScreen(
      lessonNumber: 4,
      title: 'Jumlay',
      subtitle: 'Urdu Sentences',
      accentColor: AppTheme.lessonColors[3],
      cards: cards,
    );
  }
}

// ── Lesson 7 — Janwar (Animals) ───────────────────────────────────────────────

class JanwarLessonScreen extends StatelessWidget {
  const JanwarLessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = ANIMALS.map((w) => LessonCard(
          mainText: w.urdu,
          name: w.roman,
          transcription: w.english,
          emoji: w.emoji,
          speakText: w.urdu,
          romanTarget: w.roman,
        )).toList();

    return LessonFlowScreen(
      lessonNumber: 7,
      title: 'Janwar',
      subtitle: 'Animals in Urdu',
      accentColor: AppTheme.lessonColors[6],
      cards: cards,
    );
  }
}

// ── Lesson 8 — Phal (Fruits) ──────────────────────────────────────────────────

class PhalLessonScreen extends StatelessWidget {
  const PhalLessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = FRUITS.map((w) => LessonCard(
          mainText: w.urdu,
          name: w.roman,
          transcription: w.english,
          emoji: w.emoji,
          speakText: w.urdu,
          romanTarget: w.roman,
        )).toList();

    return LessonFlowScreen(
      lessonNumber: 8,
      title: 'Phal',
      subtitle: 'Fruits in Urdu',
      accentColor: AppTheme.lessonColors[7],
      cards: cards,
    );
  }
}

// ── Quiz 1 — Haroof Quiz (Alphabet, 10 random letters) ───────────────────────
/// Same flashcard design as the lesson but isQuiz=true → shuffled, scores tracked,
/// results shown at the end.

class HaroofQuizEntry extends StatelessWidget {
  const HaroofQuizEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final shuffled = List.of(FULL_ALPHABET)..shuffle();
    final cards = shuffled.take(10).map((l) => LessonCard(
          mainText: l.urdu,
          name: l.roman,
          transcription: '${l.example} — ${l.exampleMeaning}',
          emoji: l.emoji,
          speakText: '${l.urdu}۔ ${l.roman}',
          romanTarget: l.roman,
        )).toList();

    return LessonFlowScreen(
      lessonNumber: 1,
      title: 'Alphabet Quiz',
      subtitle: '10 random letters — pronounce each',
      accentColor: const Color(0xFF9b5de5),
      cards: cards,
      isQuiz: true,
    );
  }
}

// ── Lesson 9 — Jism (Body Parts) ─────────────────────────────────────────────

class JismLessonScreen extends StatelessWidget {
  const JismLessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = BODY_PARTS.map((w) => LessonCard(
          mainText: w.urdu,
          name: w.roman,
          transcription: w.english,
          emoji: w.emoji,
          speakText: w.urdu,
          romanTarget: w.roman,
        )).toList();

    return LessonFlowScreen(
      lessonNumber: 9,
      title: 'Jism',
      subtitle: 'Body Parts in Urdu',
      accentColor: AppTheme.lessonColors[8],
      cards: cards,
    );
  }
}
