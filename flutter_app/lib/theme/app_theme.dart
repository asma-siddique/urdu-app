import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color constants
  static const Color purple = Color(0xFF9b5de5);
  static const Color pink = Color(0xFFf15bb5);
  static const Color teal = Color(0xFF00bbf9);
  static const Color orange = Color(0xFFff6d00);
  static const Color yellow = Color(0xFFfee440);
  static const Color green = Color(0xFF00f5d4);
  static const Color navy = Color(0xFF1a1a2e);
  static const Color white = Color(0xFFffffff);
  static const Color lightGray = Color(0xFFe9ecef);

  // Text styles
  static const TextStyle urduBody = TextStyle(
    fontFamily: 'NotoNastaliqUrdu',
    fontSize: 18,
    color: navy,
  );

  static const TextStyle urduTitle = TextStyle(
    fontFamily: 'NotoNastaliqUrdu',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: navy,
  );

  static const TextStyle urduLetter = TextStyle(
    fontFamily: 'NotoNastaliqUrdu',
    fontSize: 64,
    fontWeight: FontWeight.bold,
    color: navy,
  );

  static TextStyle get englishBody => GoogleFonts.roboto(
        fontSize: 14,
        color: navy,
      );

  // Card decoration
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      );

  // Header gradient
  static const LinearGradient headerGradient = LinearGradient(
    colors: [purple, pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: purple,
        primary: purple,
        secondary: pink,
        background: white,
        surface: white,
        brightness: Brightness.light,
      ),

      scaffoldBackgroundColor: lightGray,

      // ✅ FIX: CardTheme → CardThemeData
      cardTheme: CardThemeData(
        color: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: purple,
        foregroundColor: white,
        elevation: 0,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: white,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textTheme: base.textTheme.copyWith(
        bodyLarge: urduBody,
        bodyMedium: GoogleFonts.roboto(fontSize: 14, color: navy),
        titleLarge: urduTitle,
      ),
    );
  }
}