import 'package:flutter/material.dart';

/// Bright, playful kids-first color scheme
class AppTheme {
  // ── Primary palette ───────────────────────────────────────────────────────
  static const Color primary   = Color(0xFFF97316); // vivid orange
  static const Color secondary = Color(0xFF0EA5E9); // sky blue
  static const Color accent    = Color(0xFF8B5CF6); // purple
  static const Color success   = Color(0xFF10B981); // emerald
  static const Color danger    = Color(0xFFEF4444); // red
  static const Color warning   = Color(0xFFF59E0B); // amber

  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const Color bgWarm    = Color(0xFFFFFBF4); // warm white
  static const Color bgCard    = Color(0xFFFFFFFF);
  static const Color bgLight   = Color(0xFFFFF7ED); // light orange tint
  static const Color divider   = Color(0xFFE5E7EB);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textDark  = Color(0xFF1C1917); // stone-900
  static const Color textGrey  = Color(0xFF6B7280);
  static const Color textLight = Color(0xFFFFFFFF);

  // ── Legacy aliases (keep screens compiling) ───────────────────────────────
  static const Color purple    = accent;
  static const Color pink      = Color(0xFFEC4899);
  static const Color teal      = Color(0xFF0D9488);
  static const Color orange    = primary;
  static const Color yellow    = warning;
  static const Color green     = success;
  static const Color navy      = Color(0xFF1E293B);
  static const Color white     = bgCard;
  static const Color lightGray = Color(0xFFF3F4F6);

  // ── Lesson card accent colors (one per lesson/section) ───────────────────
  static const List<Color> lessonColors = [
    Color(0xFFF97316), // 1 Haroof  — orange
    Color(0xFF0EA5E9), // 2 Ginti   — sky
    Color(0xFF8B5CF6), // 3 Alfaz   — purple
    Color(0xFF10B981), // 4 Jumlay  — emerald
    Color(0xFFEC4899), // 5 JorTor  — pink
    Color(0xFFF59E0B), // 6 Rang    — amber
    Color(0xFF059669), // 7 Janwar  — green
    Color(0xFFDC2626), // 8 Phal    — red
    Color(0xFF7C3AED), // 9 Jism    — violet
  ];

  // ── Common decorations ────────────────────────────────────────────────────
  static BoxDecoration cardDecoration({Color? shadow}) => BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (shadow ?? Colors.black).withOpacity(0.09),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Text styles ───────────────────────────────────────────────────────────
  static const TextStyle urduBody = TextStyle(
    fontFamily: 'NotoNastaliqUrdu',
    fontSize: 18,
    color: textDark,
  );

  static const TextStyle urduTitle = TextStyle(
    fontFamily: 'NotoNastaliqUrdu',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textDark,
  );

  static const TextStyle urduLetter = TextStyle(
    fontFamily: 'NotoNastaliqUrdu',
    fontSize: 64,
    fontWeight: FontWeight.bold,
    color: textDark,
  );

  // ── Theme data ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: bgCard,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: bgWarm,
      cardTheme: CardThemeData(
        color: bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: textLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textLight,
          letterSpacing: 0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
