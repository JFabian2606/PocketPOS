import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color cream = Color(0xFFF9F6F1); // warm-beige
  static const Color terracotta = Color(0xFFA66D3F); // lumiere-terracotta
  static const Color darkCharcoal = Color(0xFF2D2926); // lumiere-dark
  static const Color gray = Color(0xFF717171); // lumiere-gray
  static const Color border = Color(0xFFE5E1DA); // subtle-border
  static const Color inputBg = Color(0xFFFFFFFF);
  
  static const Color accentBlue = Color(0xFFE1F5FE);
  static const Color accentGreen = Color(0xFFE8F5E9);
  
  // Custom Typography using Google Fonts
  static TextTheme get textTheme {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(color: darkCharcoal, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.inter(color: darkCharcoal, fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.inter(color: darkCharcoal, fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.inter(color: darkCharcoal, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.inter(color: darkCharcoal, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.inter(color: darkCharcoal),
      bodyMedium: GoogleFonts.inter(color: darkCharcoal),
      bodySmall: GoogleFonts.inter(color: gray),
    );
  }

  // ThemeData
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: terracotta,
      scaffoldBackgroundColor: cream,
      textTheme: textTheme,
      colorScheme: ColorScheme.light(
        primary: terracotta,
        secondary: terracotta,
        surface: cream,
        onSurface: darkCharcoal,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        elevation: 0,
        iconTheme: IconThemeData(color: darkCharcoal),
        titleTextStyle: TextStyle(
          color: darkCharcoal,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: terracotta,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: terracotta, width: 2),
        ),
        labelStyle: const TextStyle(color: darkCharcoal, fontWeight: FontWeight.w600),
        hintStyle: const TextStyle(color: Colors.grey),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
