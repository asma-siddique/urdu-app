import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/counting.dart';
import '../services/tts_service.dart';
import '../widgets/professor_avatar.dart';
import '../widgets/mic_recorder_widget.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class CountingScreen extends StatefulWidget {
  const CountingScreen({super.key});

  @override
  State<CountingScreen> createState() => _CountingScreenState();
}

class _CountingScreenState extends State<CountingScreen> {
  AvatarEmotion _emotion = AvatarEmotion.happy;
  final Map<int, double> _scores = {};

  static const Color _teal = Color(0xFF0d9488);

  static const List<Color> _cardColors = [
    Color(0xFF0d9488), Color(0xFF0090c7), Color(0xFF9b5de5),
    Color(0xFFf15bb5), Color(0xFFff6d00), Color(0xFF059669),
    Color(0xFF3a86ff), Color(0xFFdc2626), Color(0xFF7c3aed),
    Color(0xFFd97706),
  ];

  Future<void> _speak(UrduNumber num) async {
    setState(() => _emotion = AvatarEmotion.speaking);
    await TtsService.instance.speak(num.urdu);
    if (mounted) setState(() => _emotion = AvatarEmotion.happy);
  }

  void _openMic(int index, UrduNumber num) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MicRecorderWidget(
        targetText: num.urdu,
        targetRoman: num.roman,
        onScore: (score, _) {
          Navigator.pop(context);
          setState(() {
            _scores[index] = score;
            _emotion = score >= 70 ? AvatarEmotion.happy : AvatarEmotion.sad;
          });
          context.read<AppProvider>().recordResult(num.urdu, score);
          final name = context.read<AppProvider>().userName;
          TtsService.instance.speak(
              score >= 70
                  ? (name.isNotEmpty ? 'شاباش $name!' : 'شاباش!')
                  : 'دوبارہ کوشش کریں۔');
        },
      ),
    );
  }

  /// Groups: 1-10, 11-20, ..., 91-100
  static const List<String> _decadeLabels = [
    '١ تا ١٠',  '١١ تا ٢٠', '٢١ تا ٣٠', '٣١ تا ٤٠', '٤١ تا ٥٠',
    '٥١ تا ٦٠', '٦١ تا ٧٠', '٧١ تا ٨٠', '٨١ تا ٩٠', '٩١ تا ١٠٠',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final name = provider.userName;

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text('گنتی',
              style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 22)),
        ),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // ── Avatar banner ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF0d9488), Color(0xFF0f766e)]),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                children: [
                  ProfessorAvatar(emotion: _emotion, size: 80),
                  if (name.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        'آؤ $name، گنتی سیکھیں!',
                        style: const TextStyle(
                          fontFamily: 'NotoNastaliqUrdu',
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Decade groups ────────────────────────────────────────────
          for (int decade = 0; decade < 10; decade++) ...[
            // Section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _cardColors[decade].withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _cardColors[decade].withOpacity(0.4)),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          _decadeLabels[decade],
                          style: TextStyle(
                            fontFamily: 'NotoNastaliqUrdu',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _cardColors[decade],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 2-column grid for this decade
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (ctx, j) {
                    final i = decade * 10 + j;
                    if (i >= COUNTING.length) return const SizedBox.shrink();
                    final num = COUNTING[i];
                    final score = _scores[i];
                    final cardColor = _cardColors[decade];
                    final scoreColor = score == null
                        ? Colors.grey
                        : score >= 70
                            ? Colors.green
                            : score >= 50
                                ? Colors.orange
                                : Colors.red;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 8,
                              offset: Offset(0, 3))
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Numeral circle
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: cardColor.withOpacity(0.12),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: cardColor, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  num.numeral,
                                  style: TextStyle(
                                    fontFamily: 'NotoNastaliqUrdu',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: cardColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Urdu word
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                num.urdu,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'NotoNastaliqUrdu',
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: cardColor,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            Text(num.roman,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.blueGrey)),
                            // Score ring
                            if (score != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: SizedBox(
                                  width: 26,
                                  height: 26,
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
                                              fontSize: 7,
                                              fontWeight: FontWeight.bold,
                                              color: scoreColor)),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 5),
                            // Action buttons
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: [
                                _ActionBtn(
                                    emoji: '🔊',
                                    color: AppTheme.teal,
                                    onTap: () => _speak(num)),
                                _ActionBtn(
                                    emoji: '🎤',
                                    color: AppTheme.purple,
                                    onTap: () => _openMic(i, num)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: 10,
                ),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 168,
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String emoji;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.emoji, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
