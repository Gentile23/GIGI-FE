import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CleanTheme {
  // New color palette from the design
  static const Color primaryColor = Color(0xFF13EC5B);
  static const Color backgroundLight = Color(0xFFF6F8F6);
  static const Color backgroundDark = Color(0xFF102216);
  static const Color surfaceDark = Color(0xFF152B1D);
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Color(0xFF9DB9A6);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      primaryColor: primaryColor,
      fontFamily: GoogleFonts.lexend().fontFamily,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: primaryColor,
        surface: backgroundLight,
        error: Colors.red,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.black,
        onError: Colors.white,
      ),
      // ... customize other theme properties for light theme
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primaryColor,
      fontFamily: GoogleFonts.lexend().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        surface: surfaceDark,
        error: Colors.red,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textPrimaryDark,
        onError: Colors.black,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark.withOpacity(0.85),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textPrimaryDark),
        titleTextStyle: GoogleFonts.lexend(
          color: textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.lexend(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: textPrimaryDark),
        displayMedium: GoogleFonts.lexend(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: textPrimaryDark),
        displaySmall: GoogleFonts.lexend(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textPrimaryDark),
        headlineMedium: GoogleFonts.lexend(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimaryDark),
        bodyLarge: GoogleFonts.lexend(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: textPrimaryDark),
        bodyMedium: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textSecondaryDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: backgroundDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.lexend(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.lexend(color: textSecondaryDark),
      ),
    );
  }
}
