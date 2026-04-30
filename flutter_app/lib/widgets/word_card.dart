import 'package:flutter/material.dart';
import '../models/urdu_word.dart';
import '../theme/app_theme.dart';

class WordCard extends StatelessWidget {
  final UrduWord word;
  final Color emojiBackground;
  final VoidCallback onTap;
  final VoidCallback onSpeak;
  final VoidCallback onRecord;

  const WordCard({
    super.key,
    required this.word,
    required this.onTap,
    required this.onSpeak,
    required this.onRecord,
    this.emojiBackground = const Color(0xFFEDE9FE),
  });

  Color get _levelColor {
    switch (word.level) {
      case 'easy':   return Colors.green;
      case 'medium': return Colors.orange;
      case 'hard':   return Colors.red;
      default:       return Colors.grey;
    }
  }

  String get _levelLabel {
    switch (word.level) {
      case 'easy':   return 'آسان';
      case 'medium': return 'درمیانہ';
      case 'hard':   return 'مشکل';
      default:       return word.level;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Emoji container (own isolated section) ─────────────────
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: emojiBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(word.emoji, style: const TextStyle(fontSize: 44)),
            ),
            const SizedBox(height: 8),
            // ── Urdu word ───────────────────────────────────────────────
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                word.urdu,
                style: const TextStyle(
                  fontFamily: 'NotoNastaliqUrdu',
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
            // ── English meaning ─────────────────────────────────────────
            Text(
              word.english,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            // ── Level badge ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _levelColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _levelLabel,
                style: TextStyle(
                  fontFamily: 'NotoNastaliqUrdu',
                  fontSize: 11,
                  color: _levelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // ── Action buttons ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSpeak,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEDE9FE),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      '🔊 سنیں',
                      style: TextStyle(
                          fontFamily: 'NotoNastaliqUrdu',
                          color: AppTheme.purple,
                          fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onRecord,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.purple,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      '🎤 بولیں',
                      style: TextStyle(
                          fontFamily: 'NotoNastaliqUrdu',
                          color: Colors.white,
                          fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
