import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
// uuid used in welcome_screen.dart

import 'providers/app_provider.dart';
import 'services/tts_service.dart';
import 'services/speech_service.dart';
import 'theme/app_theme.dart';
// UserModel used in welcome_screen.dart
import 'screens/home_screen.dart';
import 'screens/haroof_screen.dart';
import 'screens/lafz_screen.dart';
import 'screens/jumlay_screen.dart';
import 'screens/rang_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/counting_screen.dart';
import 'screens/grammar_screen.dart';
import 'screens/matching_quiz_screen.dart';
import 'screens/lessons_hub_screen.dart';
import 'screens/quiz_hub_screen.dart';
import 'screens/jor_tor_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/vocabulary_bank_screen.dart';
import 'screens/poetry_bank_screen.dart';
import 'screens/lesson_entries.dart';
import 'screens/profile_screen.dart';
import 'data/animals_extended.dart';
import 'data/fruits.dart';
import 'data/body_parts.dart';
import 'data/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const UrduLearningApp(),
    ),
  );
}

class UrduLearningApp extends StatelessWidget {
  const UrduLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اردو سیکھیں',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ur', 'PK'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ur', 'PK'),
      home: const AppWrapper(),
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          return MaterialPageRoute(builder: (_) => const HomeScreen());
        }
        return null;
      },
      routes: {
        // ── Core lessons ───────────────────────────────────────────────
        '/haroof':        (_) => const HaroofScreen(),
        '/lafz':          (_) => const LafzScreen(),
        '/jumlay':        (_) => const JumlaySreen(),
        '/rang':          (_) => const RangScreen(),
        '/jor-tor':       (_) => const JorTorScreen(),
        '/counting':      (_) => const CountingScreen(),
        '/grammar':       (_) => const GrammarScreen(),

        // ── Lesson flow entries ─────────────────────────────────────────
        '/haroof-lesson':   (_) => const HaroofLessonScreen(),
        '/ginti-lesson':    (_) => const GintiLessonScreen(),
        '/alfaz-lesson':    (_) => const AlfazLessonScreen(),
        '/jumla-lesson':    (_) => const JumlaLessonScreen(),
        '/animals-lesson':  (_) => const JanwarLessonScreen(),
        '/fruits-lesson':   (_) => const PhalLessonScreen(),
        '/body-lesson':     (_) => const JismLessonScreen(),

        // ── Hubs ───────────────────────────────────────────────────────
        '/lessons-hub':   (_) => const LessonsHubScreen(),
        '/quiz-hub':      (_) => const QuizHubScreen(),
        '/home':          (_) => const HomeScreen(),
        '/progress':      (_) => const ProgressScreen(),
        '/profile':       (_) => const ProfileScreen(),
        '/vocabulary-bank': (_) => const VocabularyBankScreen(),
        '/poetry-bank':   (_) => const PoetryBankScreen(),

        // ── Quizzes ────────────────────────────────────────────────────
        '/quiz':          (_) => const QuizScreen(),
        '/haroof-quiz':   (_) => const HaroofQuizEntry(), // flashcard quiz
        '/words-quiz':    (_) => const QuizScreen(
              screenTitle: 'الفاظ کوئز',
            ),
        '/sentences-quiz':(_) => const SentenceQuizScreen(),
        '/matching-quiz': (_) => const MatchingQuizScreen(),
        '/animals-quiz':  (_) => QuizScreen(
              wordList: ANIMALS,
              screenTitle: 'جانور کوئز',
            ),
        '/fruits-quiz':   (_) => QuizScreen(
              wordList: FRUITS,
              screenTitle: 'پھل کوئز',
            ),
        '/body-quiz':     (_) => QuizScreen(
              wordList: BODY_PARTS,
              screenTitle: 'جسم کوئز',
            ),
        '/colors-quiz':   (_) => QuizScreen(
              wordList: COLORS_WORDS,
              screenTitle: 'رنگ کوئز',
            ),
      },
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});
  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await Future.wait([
        TtsService.instance.reinit(), // reinit so voice detection runs fresh
        SpeechService.instance.init(),
      ]);

      if (!mounted) return;
      final provider = context.read<AppProvider>();
      await provider.loadUser();

      // No default user — WelcomeScreen handles first-time name entry.
    } catch (e) {
      debugPrint('Bootstrap error: $e');
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      // Splash screen while loading
      return const Scaffold(
        backgroundColor: Color(0xFF4a0080),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('اردو', style: TextStyle(
                fontFamily: 'NotoNastaliqUrdu',
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              )),
              SizedBox(height: 12),
              Text('سیکھیں', style: TextStyle(
                fontFamily: 'NotoNastaliqUrdu',
                fontSize: 28,
                color: Colors.white70,
              )),
              SizedBox(height: 40),
              CircularProgressIndicator(color: Color(0xFFf15bb5)),
            ],
          ),
        ),
      );
    }

    final provider = context.read<AppProvider>();
    // If no user name saved, show welcome/onboarding screen
    if (provider.currentUser == null ||
        provider.currentUser!.name == 'طالب علم') {
      return const WelcomeScreen();
    }
    return const HomeScreen();
  }
}