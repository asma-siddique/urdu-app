import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../data/words.dart';
import '../data/animals_extended.dart';
import '../data/fruits.dart';
import '../models/urdu_word.dart';
import '../providers/app_provider.dart';
import '../services/tts_service.dart';
import '../widgets/professor_avatar.dart';

/// Tap-to-match quiz: left column = emojis, right column = Urdu words.
/// Tap one from each side to attempt a match.
class MatchingQuizScreen extends StatefulWidget {
  const MatchingQuizScreen({super.key});

  @override
  State<MatchingQuizScreen> createState() => _MatchingQuizScreenState();
}

class _MatchingQuizScreenState extends State<MatchingQuizScreen> {
  final Random _rng = Random();
  AvatarEmotion _emotion = AvatarEmotion.neutral;

  late List<UrduWord> _roundWords; // 6 words per round
  int _roundsPlayed = 0;
  int _totalScore = 0;
  static const int _totalRounds = 5;

  // Matching state
  int? _selectedEmoji; // index into _roundWords
  int? _selectedUrdu; // index into _shuffledUrdu
  late List<int> _shuffledUrdu; // permutation indices
  Set<int> _matchedIndices = {}; // correctly matched word indices
  Set<int> _wrongPair = {}; // briefly highlight wrong pair

  bool get _roundComplete =>
      _matchedIndices.length == _roundWords.length;

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  void _startRound() {
    final allWords = [...WORDS, ...ANIMALS, ...FRUITS];
    allWords.shuffle(_rng);
    _roundWords = allWords.take(6).toList();
    _shuffledUrdu = List.generate(_roundWords.length, (i) => i)
      ..shuffle(_rng);
    _matchedIndices = {};
    _wrongPair = {};
    _selectedEmoji = null;
    _selectedUrdu = null;
    TtsService.instance.speak('جوڑیں ملائیں');
  }

  void _onEmojiTap(int wordIndex) {
    if (_matchedIndices.contains(wordIndex)) return;
    setState(() {
      _selectedEmoji = wordIndex;
      _wrongPair = {};
      _tryMatch();
    });
  }

  void _onUrduTap(int shuffleIndex) {
    if (_matchedIndices.contains(_shuffledUrdu[shuffleIndex])) return;
    setState(() {
      _selectedUrdu = shuffleIndex;
      _wrongPair = {};
      _tryMatch();
    });
  }

  void _tryMatch() {
    if (_selectedEmoji == null || _selectedUrdu == null) return;

    final emojiWord = _roundWords[_selectedEmoji!];
    final urduWordIndex = _shuffledUrdu[_selectedUrdu!];
    final urduWord = _roundWords[urduWordIndex];

    if (emojiWord == urduWord) {
      // Correct match!
      _matchedIndices.add(_selectedEmoji!);
      _emotion = AvatarEmotion.happy;
      _totalScore++;
      TtsService.instance.speak('شاباش! ${emojiWord.urdu}');
      context.read<AppProvider>().recordResult(emojiWord.urdu, 100);
    } else {
      // Wrong match
      _wrongPair = {_selectedEmoji!, -1 - _selectedUrdu!};
      _emotion = AvatarEmotion.sad;
      TtsService.instance.speak('غلط! دوبارہ کوشش کریں۔');
      // Clear wrong pair after 600ms
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _wrongPair = {});
      });
    }
    _selectedEmoji = null;
    _selectedUrdu = null;
  }

  void _nextRound() {
    setState(() {
      _roundsPlayed++;
      if (_roundsPlayed < _totalRounds) {
        _startRound();
        _emotion = AvatarEmotion.excited;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_roundsPlayed >= _totalRounds) {
      return _buildResults();
    }
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: Text(
          'Matching  ${_roundsPlayed + 1} / $_totalRounds   ✓ $_totalScore',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: const Color(0xFFf15bb5),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_roundsPlayed + 1) / _totalRounds,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 4,
          ),
        ),
      ),
      body: Column(
        children: [
          // Compact avatar banner
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFFf15bb5), Color(0xFFc73d8f)]),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(child: ProfessorAvatar(emotion: _emotion, size: 52)),
          ),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'صحیح جوڑ ملائیں',
              style: const TextStyle(
                fontFamily: 'NotoNastaliqUrdu',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.navy,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Main matching area — items use Expanded so they NEVER overflow
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: Emoji column
                  Expanded(
                    child: Column(
                      children: List.generate(_roundWords.length, (i) {
                        final matched = _matchedIndices.contains(i);
                        final selected = _selectedEmoji == i;
                        final wrong = _wrongPair.contains(i);
                        Color bg = Colors.white;
                        Color border = Colors.grey.shade300;
                        if (matched)        { bg = Colors.green.shade50;  border = Colors.green; }
                        else if (selected)  { bg = const Color(0xFFf15bb5).withOpacity(0.12); border = const Color(0xFFf15bb5); }
                        else if (wrong)     { bg = Colors.red.shade50;    border = Colors.red; }
                        return Expanded(
                          child: GestureDetector(
                            onTap: matched ? null : () => _onEmojiTap(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 0),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: border, width: 2),
                                boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 3)],
                              ),
                              child: Center(
                                child: matched
                                    ? const Icon(Icons.check_circle, color: Colors.green, size: 24)
                                    : Text(_roundWords[i].emoji,
                                        style: const TextStyle(fontSize: 26)),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Center divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Right: Urdu words column (shuffled)
                  Expanded(
                    child: Column(
                      children: List.generate(_roundWords.length, (shuffleIdx) {
                        final wordIdx = _shuffledUrdu[shuffleIdx];
                        final matched = _matchedIndices.contains(wordIdx);
                        final selected = _selectedUrdu == shuffleIdx;
                        final wrong = _wrongPair.contains(-1 - shuffleIdx);
                        Color bg = Colors.white;
                        Color border = Colors.grey.shade300;
                        if (matched)        { bg = Colors.green.shade50;  border = Colors.green; }
                        else if (selected)  { bg = const Color(0xFFf15bb5).withOpacity(0.12); border = const Color(0xFFf15bb5); }
                        else if (wrong)     { bg = Colors.red.shade50;    border = Colors.red; }
                        return Expanded(
                          child: GestureDetector(
                            onTap: matched ? null : () => _onUrduTap(shuffleIdx),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: border, width: 2),
                                boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 3)],
                              ),
                              child: Center(
                                child: matched
                                    ? const Icon(Icons.check_circle, color: Colors.green, size: 24)
                                    : Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: Text(
                                          _roundWords[wordIdx].urdu,
                                          style: const TextStyle(
                                            fontFamily: 'NotoNastaliqUrdu',
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.navy,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Next round button
          if (_roundComplete)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ElevatedButton.icon(
                onPressed: _nextRound,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    _roundsPlayed + 1 >= _totalRounds
                        ? 'نتیجہ دیکھیں'
                        : 'اگلا راؤنڈ',
                    style: const TextStyle(
                        fontFamily: 'NotoNastaliqUrdu', fontSize: 18),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFf15bb5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    )); // closes Directionality + Scaffold
  }

  Widget _buildResults() {
    final pct = (_totalScore / (_totalRounds * 6) * 100).round();
    final excellent = pct >= 80;
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: const Text('نتیجہ',
            style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 22)),
        backgroundColor: const Color(0xFFf15bb5),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(excellent ? '🎉' : '💪',
                  style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  excellent ? 'بہت خوب!' : 'اچھی کوشش!',
                  style: const TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$_totalScore / ${_totalRounds * 6}',
                style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.purple),
              ),
              Text('$pct% درستگی',
                  style: const TextStyle(
                      fontFamily: 'NotoNastaliqUrdu',
                      fontSize: 20,
                      color: Colors.grey)),
              const SizedBox(height: 36),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _roundsPlayed = 0;
                    _totalScore = 0;
                    _emotion = AvatarEmotion.excited;
                    _startRound();
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('دوبارہ کھیلیں',
                    style: TextStyle(
                        fontFamily: 'NotoNastaliqUrdu', fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFf15bb5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('واپس جائیں',
                    style: TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: 16,
                        color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
