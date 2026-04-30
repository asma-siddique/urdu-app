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

class _LafzScreenState extends State<LafzScreen> {
  AvatarEmotion _emotion = AvatarEmotion.neutral;
  String _selectedCategory = 'سب';
  late List<UrduWord> _filtered;

  // Collect unique categories from data
  late final List<String> _categories;

  @override
  void initState() {
    super.initState();
    final cats = WORDS.map((w) => w.category).toSet().toList();
    _categories = ['سب', ...cats];
    _applyFilter();
  }

  void _applyFilter() {
    if (_selectedCategory == 'سب') {
      _filtered = List.from(WORDS);
    } else {
      _filtered = WORDS.where((w) => w.category == _selectedCategory).toList();
    }
  }

  Future<void> _speakWord(UrduWord word) async {
    setState(() => _emotion = AvatarEmotion.thinking);
    await TtsService.instance.speak('${word.urdu}۔');
    if (mounted) setState(() => _emotion = AvatarEmotion.happy);
  }

  void _openMic(BuildContext context, UrduWord word) {
    MicRecorderWidget.show(
      context,
      targetText: word.urdu,
      targetRoman: word.target,
      onScore: (score, transcript) {
        final provider = context.read<AppProvider>();
        provider.recordResult(word.urdu, score);
        if (score >= 70) {
          // progress recorded via recordResult above
        }
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                score >= 70
                    ? 'شاباش! آپ کا تلفظ ${score.toInt()}% درست ہے۔'
                    : 'دوبارہ کوشش کریں۔ اسکور: ${score.toInt()}%',
                style: const TextStyle(fontFamily: 'NotoNastaliqUrdu'),
              ),
            ),
            backgroundColor:
                score >= 70 ? Colors.green.shade600 : Colors.red.shade600,
          ),
        );
      },
    );
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'easy':
        return Colors.green.shade600;
      case 'medium':
        return Colors.orange.shade600;
      case 'hard':
        return Colors.red.shade600;
      default:
        return Colors.grey;
    }
  }

  String _levelUrdu(String level) {
    switch (level) {
      case 'easy':
        return 'آسان';
      case 'medium':
        return 'درمیانہ';
      case 'hard':
        return 'مشکل';
      default:
        return level;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'الفاظ',
            style: TextStyle(fontFamily: 'NotoNastaliqUrdu', fontSize: 22),
          ),
        ),
        backgroundColor: AppTheme.pink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Avatar banner ────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.pink, AppTheme.pink.withOpacity(0.7)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(child: ProfessorAvatar(emotion: _emotion, size: 80)),
          ),

          const SizedBox(height: 12),

          // ── Category filter chips ─────────────────────────────────────
          SizedBox(
            height: 44,
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
                      label: Text(
                        cat,
                        style: TextStyle(
                          fontFamily: 'NotoNastaliqUrdu',
                          fontSize: 14,
                          color: selected ? Colors.white : AppTheme.navy,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = cat;
                          _applyFilter();
                        });
                      },
                      selectedColor: AppTheme.pink,
                      backgroundColor: Colors.white,
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: selected ? AppTheme.pink : Colors.grey.shade300,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Word grid ─────────────────────────────────────────────────
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                return _WordCard(
                  word: _filtered[i],
                  onSpeak: () => _speakWord(_filtered[i]),
                  onMic: () => _openMic(context, _filtered[i]),
                  levelColor: _levelColor(_filtered[i].level),
                  levelUrdu: _levelUrdu(_filtered[i].level),
                  onTap: () => _speakWord(_filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final UrduWord word;
  final VoidCallback onSpeak;
  final VoidCallback onMic;
  final VoidCallback onTap;
  final Color levelColor;
  final String levelUrdu;

  const _WordCard({
    required this.word,
    required this.onSpeak,
    required this.onMic,
    required this.onTap,
    required this.levelColor,
    required this.levelUrdu,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Emoji square ──────────────────────────────────────────
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.pink.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: AppTheme.pink.withOpacity(0.3), width: 1.5),
              ),
              child: Center(
                child:
                    Text(word.emoji, style: const TextStyle(fontSize: 44)),
              ),
            ),

            const SizedBox(height: 12),

            // ── Urdu word ─────────────────────────────────────────────
            Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  word.urdu,
                  style: const TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            const SizedBox(height: 6),

            // ── English meaning ───────────────────────────────────────
            Text(
              word.english,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // ── Level badge ───────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: levelColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: levelColor.withOpacity(0.5), width: 1),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  levelUrdu,
                  style: TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: 12,
                    color: levelColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Listen / Speak row ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionBtn(
                      label: 'سنیں',
                      icon: '🔊',
                      color: AppTheme.teal,
                      onTap: onSpeak,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _ActionBtn(
                      label: 'بولیں',
                      icon: '🎤',
                      color: AppTheme.pink,
                      onTap: onMic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final String icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.13),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 3),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'NotoNastaliqUrdu',
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
