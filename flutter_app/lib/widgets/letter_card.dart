import 'package:flutter/material.dart';
import '../models/urdu_letter.dart';
import '../theme/app_theme.dart';

class LetterCard extends StatelessWidget {
  final UrduLetter letter;
  final bool isSelected;
  final Color emojiBackground;
  final VoidCallback onTap;
  final VoidCallback onSpeak;

  const LetterCard({
    super.key,
    required this.letter,
    required this.onTap,
    required this.onSpeak,
    this.isSelected = false,
    this.emojiBackground = AppTheme.purple,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.purple : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Emoji circle (own isolated section, no overlap) ────────
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: emojiBackground.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(
                    color: emojiBackground.withOpacity(0.4), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(letter.emoji, style: const TextStyle(fontSize: 30)),
            ),
            const SizedBox(height: 8),
            // ── Urdu letter (own row, huge) ─────────────────────────────
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                letter.urdu,
                style: const TextStyle(
                  fontFamily: 'NotoNastaliqUrdu',
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            // ── Roman name (own row) ────────────────────────────────────
            Text(
              letter.roman,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            // ── Urdu example word (own row) ─────────────────────────────
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                letter.example,
                style: const TextStyle(
                  fontFamily: 'NotoNastaliqUrdu',
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
            // ── English meaning (own row) ────────────────────────────────
            Text(
              letter.exampleMeaning,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            // ── Speak button ─────────────────────────────────────────────
            IconButton(
              onPressed: onSpeak,
              icon: const Text('🔊', style: TextStyle(fontSize: 18)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}
