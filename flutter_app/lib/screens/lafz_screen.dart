import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../data/words.dart';
import '../models/urdu_word.dart';
import '../providers/app_provider.dart';
import '../services/tts_service.dart';
import '../widgets/professor_avatar.dart';
import '../widgets/mic_recorder_widget.dart';

class LafzScreen extends StatefulWidget {
  const LafzScreen({super.key});

  @override
  State<LafzScreen> createState() => _LafzScreenState();
}

class _LafzScreenState extends State<LafzScreen>
    with SingleTickerProviderStateMixin {
  AvatarEmotion _emotion = AvatarEmotion.happy;
  String _selectedCategory = 'سب';
  late List<UrduWord> _filtered;
  late final List<String> _categories;
  int _idx = 0;
  double? _lastScore;

  late final AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  static const List<Color> _accentColors = [
    Color(0xFF7C3AED), Color(0xFFDB2777), Color(0xFF059669),
    Color(0xFFD97706), Color(0xFF2563EB), Color(0xFF7C3AED),
    Color(0xFFDC2626), Color(0xFF0891B2), Color(0xFF65A30D),
    Color(0xFF9333EA),
  ];

  Color get _accent => _accentColors[_idx % _accentColors.length];

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _slideAnim = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    final cats = WORDS.map((w) => w.category).toSet().toList();
    _categories = ['سب', ...cats];
    _applyFilter();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    if (_selectedCategory == 'سب') {
      _filtered = List.from(WORDS);
    } else {
      _filtered = WORDS.where((w) => w.category == _selectedCategory).toList();
    }
    _idx = 0;
    _lastScore = null;
  }

  Future<void> _animateTo(int newIdx, bool toRight) async {
    _slideAnim = Tween<Offset>(
      begin: Offset(toRight ? 1.0 : -1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    setState(() {
      _idx = newIdx;
      _lastScore = null;
    });
    _slideCtrl.forward(from: 0);
  }

  Future<void> _speakWord() async {
    if (_filtered.isEmpty) return;
    final word = _filtered[_idx];
    setState(() => _emotion = AvatarEmotion.speaking);
    await TtsService.instance.speak(word.urdu);
    if (mounted) setState(() => _emotion = AvatarEmotion.happy);
  }

  void _openMic() {
    if (_filtered.isEmpty) return;
    final word = _filtered[_idx];
    MicRecorderWidget.show(
      context,
      targetText: word.urdu,
      targetRoman: word.target,
      onScore: (score, transcript) {
        final provider = context.read<AppProvider>();
        provider.recordResult(word.urdu, score);
        Navigator.of(context).pop();
        setState(() {
          _lastScore = score;
          _emotion = score >= 70 ? AvatarEmotion.happy : AvatarEmotion.sad;
        });
        final name = provider.userName;
        TtsService.instance.speak(
          score >= 70
              ? (name.isNotEmpty ? 'شاباش $name!' : 'شاباش!')
              : 'دوبارہ کوشش کریں۔',
        );
      },
    );
  }

  String _levelLabel(String level) {
    switch (level) {
      case 'easy':   return 'آسان';
      case 'medium': return 'درمیانہ';
      case 'hard':   return 'مشکل';
      default:       return level;
    }
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'easy':   return Colors.green.shade600;
      case 'medium': return Colors.orange.shade600;
      default:       return Colors.red.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text('الفاظ',
              style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 22)),
        ),
        backgroundColor: AppTheme.pink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Avatar banner ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.pink, AppTheme.pink.withOpacity(0.75)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                ProfessorAvatar(emotion: _emotion, size: 80),
                const SizedBox(height: 6),
                if (provider.userName.isNotEmpty)
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      'آؤ ${provider.userName}، آج کچھ نئے الفاظ سیکھیں!',
                      style: const TextStyle(
                        fontFamily: 'NotoNastaliqUrdu',
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Category filter chips ──────────────────────────────────────
          SizedBox(
            height: 42,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _categories.length,
                itemBuilder: (ctx, i) {
                  final cat = _categories[i];
                  final selected = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(cat,
                          style: TextStyle(
                            fontFamily: 'NotoNastaliqUrdu',
                            fontSize: 13,
                            color: selected ? Colors.white : AppTheme.navy,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          )),
                      selected: selected,
                      onSelected: (_) => setState(() {
                        _selectedCategory = cat;
                        _applyFilter();
                      }),
                      selectedColor: AppTheme.pink,
                      backgroundColor: Colors.white,
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                          color: selected ? AppTheme.pink : Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Word counter ───────────────────────────────────────────────
          if (_filtered.isNotEmpty)
            Text(
              '${_idx + 1} / ${_filtered.length}',
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),

          const SizedBox(height: 8),

          // ── Main word card ─────────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text('کوئی لفظ نہیں',
                        style: TextStyle(
                            fontFamily: 'NotoNastaliqUrdu', fontSize: 18)))
                : SlideTransition(
                    position: _slideAnim,
                    child: _WordCard(
                      word: _filtered[_idx],
                      accent: _accent,
                      score: _lastScore,
                      levelLabel: _levelLabel(_filtered[_idx].level),
                      levelColor: _levelColor(_filtered[_idx].level),
                      onSpeak: _speakWord,
                      onMic: _openMic,
                    ),
                  ),
          ),

          // ── Navigation row ─────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Row(
              children: [
                // Previous
                _NavBtn(
                  label: '← پچھلا',
                  enabled: _idx > 0,
                  color: _accent,
                  onTap: () => _animateTo(_idx - 1, false),
                ),
                // Dot indicators (up to 10 dots)
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(
                          _filtered.length > 20 ? 20 : _filtered.length,
                          (i) {
                            final realIdx = _filtered.length > 20
                                ? (i * (_filtered.length / 20)).round()
                                : i;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: realIdx == _idx ? 18 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: realIdx == _idx
                                    ? _accent
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                // Next
                _NavBtn(
                  label: 'اگلا →',
                  enabled: _idx < _filtered.length - 1,
                  color: _accent,
                  onTap: () => _animateTo(_idx + 1, true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Word card ────────────────────────────────────────────────────────────────
class _WordCard extends StatelessWidget {
  final UrduWord word;
  final Color accent;
  final double? score;
  final String levelLabel;
  final Color levelColor;
  final VoidCallback onSpeak;
  final VoidCallback onMic;

  const _WordCard({
    required this.word,
    required this.accent,
    required this.score,
    required this.levelLabel,
    required this.levelColor,
    required this.onSpeak,
    required this.onMic,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: accent.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Level badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: levelColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: levelColor.withOpacity(0.4)),
              ),
              child: Text(
                levelLabel,
                style: TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 12,
                    color: levelColor,
                    fontWeight: FontWeight.bold),
              ),
            ),

            // Big emoji
            Text(word.emoji, style: const TextStyle(fontSize: 90)),

            // Urdu word
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                word.urdu,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoNastaliqUrdu',
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: accent,
                  height: 1.3,
                ),
              ),
            ),

            // Roman + English
            Column(
              children: [
                Text(word.roman,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
                const SizedBox(height: 2),
                Text(word.english,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
              ],
            ),

            // Score ring (if attempted)
            if (score != null)
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: score! / 100,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        score! >= 70 ? Colors.green : Colors.orange,
                      ),
                    ),
                    Text('${score!.toInt()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: score! >= 70 ? Colors.green : Colors.orange,
                        )),
                  ],
                ),
              ),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onSpeak,
                      icon: const Text('🔊', style: TextStyle(fontSize: 20)),
                      label: const Text('سنیں',
                          style: TextStyle(
                              fontFamily: 'NotoNastaliqUrdu', fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onMic,
                      icon: const Text('🎤', style: TextStyle(fontSize: 20)),
                      label: const Text('بولیں',
                          style: TextStyle(
                              fontFamily: 'NotoNastaliqUrdu', fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nav button ───────────────────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final String label;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;
  const _NavBtn(
      {required this.label,
      required this.enabled,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: enabled ? color.withOpacity(0.4) : Colors.grey.shade200),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'NotoNastaliqUrdu',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: enabled ? color : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
