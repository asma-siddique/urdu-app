import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/words.dart';
import '../data/animals_extended.dart';
import '../data/fruits.dart';
import '../models/urdu_word.dart';
import '../providers/app_provider.dart';
import '../services/tts_service.dart';
import '../widgets/professor_avatar.dart';

const _kBgM = Color(0xFFFFF8E8);
const _kPink = Color(0xFFf15bb5);
const _kOrgM = Color(0xFFFF7043);

class MatchingQuizScreen extends StatefulWidget {
  const MatchingQuizScreen({super.key});
  @override
  State<MatchingQuizScreen> createState() => _MatchingQuizScreenState();
}

class _MatchingQuizScreenState extends State<MatchingQuizScreen> {
  final Random _rng = Random();
  AvatarEmotion _emotion = AvatarEmotion.neutral;
  late List<UrduWord> _roundWords;
  int _roundsPlayed = 0, _totalScore = 0;
  static const int _totalRounds = 5;
  int? _selectedEmoji, _selectedUrdu;
  late List<int> _shuffledUrdu;
  Set<int> _matchedIndices = {};
  Set<int> _wrongPair = {};
  bool get _roundComplete => _matchedIndices.length == _roundWords.length;

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  void _startRound() {
    final all = [...WORDS, ...ANIMALS, ...FRUITS]..shuffle(_rng);
    _roundWords = all.take(6).toList();
    _shuffledUrdu = List.generate(_roundWords.length, (i) => i)..shuffle(_rng);
    _matchedIndices = {};
    _wrongPair = {};
    _selectedEmoji = null;
    _selectedUrdu = null;
    TtsService.instance.speak('جوڑیں ملائیں');
  }

  void _onEmojiTap(int wi) {
    if (_matchedIndices.contains(wi)) return;
    setState(() {
      _selectedEmoji = wi;
      _wrongPair = {};
      _tryMatch();
    });
  }

  void _onUrduTap(int si) {
    if (_matchedIndices.contains(_shuffledUrdu[si])) return;
    setState(() {
      _selectedUrdu = si;
      _wrongPair = {};
      _tryMatch();
    });
  }

  void _tryMatch() {
    if (_selectedEmoji == null || _selectedUrdu == null) return;
    final ew = _roundWords[_selectedEmoji!];
    final uwi = _shuffledUrdu[_selectedUrdu!];
    if (ew == _roundWords[uwi]) {
      _matchedIndices.add(_selectedEmoji!);
      _emotion = AvatarEmotion.happy;
      _totalScore++;
      TtsService.instance.speak('شاباش! ${ew.urdu}');
      context.read<AppProvider>().recordResult(ew.urdu, 100);
    } else {
      _wrongPair = {_selectedEmoji!, -1 - _selectedUrdu!};
      _emotion = AvatarEmotion.sad;
      TtsService.instance.speak('غلط! دوبارہ کوشش کریں۔');
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

  Color _cellBg(bool matched, bool selected, bool wrong) {
    if (matched) return Colors.green.shade50;
    if (selected) return _kPink.withOpacity(0.10);
    if (wrong) return Colors.red.shade50;
    return Colors.white;
  }

  Color _cellBorder(bool matched, bool selected, bool wrong) {
    if (matched) return Colors.green;
    if (selected) return _kPink;
    if (wrong) return Colors.red;
    return const Color(0xFFE5E7EB);
  }

  @override
  Widget build(BuildContext context) {
    if (_roundsPlayed >= _totalRounds) return _buildResults();
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _kBgM,
        body: Column(children: [
          _MatchTopBar(
              roundsPlayed: _roundsPlayed,
              totalRounds: _totalRounds,
              totalScore: _totalScore,
              progress: (_roundsPlayed + 1) / _totalRounds),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(children: [
              ProfessorAvatar(emotion: _emotion, size: 44),
              const SizedBox(width: 10),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFECB3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFFFFCC02).withOpacity(0.5))),
                  child: const Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text('صحیح جوڑ ملائیں!',
                          style: TextStyle(
                              fontFamily: 'NotoNastaliqUrdu',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF78350F))))),
            ]),
          ),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(
                  child: Column(
                      children: List.generate(_roundWords.length, (i) {
                final m = _matchedIndices.contains(i),
                    s = _selectedEmoji == i,
                    w = _wrongPair.contains(i);
                return Expanded(
                    child: GestureDetector(
                        onTap: m ? null : () => _onEmojiTap(i),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                                color: _cellBg(m, s, w),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: _cellBorder(m, s, w), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 4)
                                ]),
                            child: Center(
                                child: m
                                    ? const Icon(Icons.check_circle_rounded,
                                        color: Colors.green, size: 26)
                                    : Text(_roundWords[i].emoji,
                                        style:
                                            const TextStyle(fontSize: 28))))));
              }))),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 24),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                          _roundWords.length,
                          (_) => const Text('↔',
                              style: TextStyle(
                                  fontSize: 14, color: Color(0xFFD1D5DB)))))),
              Expanded(
                  child: Column(
                      children: List.generate(_roundWords.length, (si) {
                final wi = _shuffledUrdu[si],
                    m = _matchedIndices.contains(wi),
                    s = _selectedUrdu == si,
                    w = _wrongPair.contains(-1 - si);
                return Expanded(
                    child: GestureDetector(
                        onTap: m ? null : () => _onUrduTap(si),
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                                color: _cellBg(m, s, w),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: _cellBorder(m, s, w), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 4)
                                ]),
                            child: Center(
                                child: m
                                    ? const Icon(Icons.check_circle_rounded,
                                        color: Colors.green, size: 26)
                                    : Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: Text(_roundWords[wi].urdu,
                                            style: const TextStyle(
                                                fontFamily: 'NotoNastaliqUrdu',
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E3A5F)),
                                            textAlign: TextAlign.center))))));
              }))),
            ]),
          )),
          if (_roundComplete)
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                child: GestureDetector(
                    onTap: _nextRound,
                    child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                            color: _kOrgM,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                  color: _kOrgM.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ]),
                        child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                                _roundsPlayed + 1 >= _totalRounds
                                    ? 'نتیجہ دیکھیں  →'
                                    : 'اگلا راؤنڈ  →',
                                style: const TextStyle(
                                    fontFamily: 'NotoNastaliqUrdu',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white),
                                textAlign: TextAlign.center)))))
          else
            const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _buildResults() {
    final pct = (_totalScore / (_totalRounds * 6) * 100).round();
    final stars = pct >= 80
        ? 3
        : pct >= 50
            ? 2
            : 1;
    final excellent = pct >= 80;
    final col = excellent ? Colors.green : _kPink;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _kBgM,
        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    3,
                    (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(i < stars ? '⭐' : '☆',
                            style: TextStyle(
                                fontSize: i < stars ? 40 : 32,
                                color: i < stars
                                    ? Colors.amber
                                    : Colors.grey.shade300))))),
            const SizedBox(height: 16),
            Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: col, width: 4),
                    boxShadow: [
                      BoxShadow(color: col.withOpacity(0.2), blurRadius: 16)
                    ]),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$pct%',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: col)),
                      const Text('score',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ])),
            const SizedBox(height: 16),
            Directionality(
                textDirection: TextDirection.rtl,
                child: Text(excellent ? 'بہت خوب!' : 'اچھی کوشش!',
                    style: TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: col))),
            const SizedBox(height: 8),
            Text('$_totalScore / ${_totalRounds * 6} correct',
                style: const TextStyle(fontSize: 16, color: Color(0xFF6B7280))),
            const SizedBox(height: 36),
            GestureDetector(
                onTap: () => setState(() {
                      _roundsPlayed = 0;
                      _totalScore = 0;
                      _emotion = AvatarEmotion.excited;
                      _startRound();
                    }),
                child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                        color: _kPink, borderRadius: BorderRadius.circular(30)),
                    child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Try Again',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white))
                        ]))),
            const SizedBox(height: 12),
            GestureDetector(
                onTap: () => Navigator.popUntil(context, (r) => r.isFirst),
                child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: const Color(0xFFE5E7EB), width: 2)),
                    child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.home_rounded,
                              color: Color(0xFF6B7280), size: 20),
                          SizedBox(width: 8),
                          Text('Home',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF6B7280)))
                        ]))),
          ]),
        ))),
      ),
    );
  }
}

class _MatchTopBar extends StatelessWidget {
  final int roundsPlayed, totalRounds, totalScore;
  final double progress;
  const _MatchTopBar(
      {required this.roundsPlayed,
      required this.totalRounds,
      required this.totalScore,
      required this.progress});
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFd63384), _kPink]),
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(16, top + 10, 16, 14),
      child: Column(children: [
        Row(children: [
          GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 18))),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Matching Quiz  ملائیں',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                Text('Round ${roundsPlayed + 1} / $totalRounds',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.white70)),
              ])),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('✓ $totalScore',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white))),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white))),
      ]),
    );
  }
}
