import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// TRIPGLIDE INSPIRED THEME - GIGI MONOCHROME
/// High Contrast, Pure Glass, Minimalist
/// Colors: White background, Black primary, Silver/Glass accents
class CleanTheme {
  // ═══════════════════════════════════════════════════════════
  // REFINED COLOR PALETTE - MONOCHROME & GLASS
  // ═══════════════════════════════════════════════════════════

  // Primary - Elegant Black
  static const Color primaryColor = Color(0xFF000000); // Pure Black
  static const Color primaryLight = Color(
    0xFFF5F5F7,
  ); // Very light gray (Apple style)
  static const Color primaryDark = Color(0xFF1C1C1E); // Apple Dark Grey

  // Backgrounds - Pristine White
  static const Color backgroundColor = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceColor = Color(0xFFFFFFFF); // Pure White
  static const Color cardColor = Color(0xFFFFFFFF); // Pure White
  static const Color scaffoldBackgroundColor = Color(
    0xFFFFFFFF,
  ); // White for clean look

  // Text Colors - Sharp & Professional
  static const Color textPrimary = Color(0xFF000000); // Pure Black
  static const Color textSecondary = Color(0xFF8E8E93); // Apple Gray
  static const Color textTertiary = Color(0xFFC7C7CC); // Apple Light Gray
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White

  // Border & Divider Colors
  static const Color borderPrimary = Color(0xFFD1D1D6); // Visible separation
  static const Color borderSecondary = Color(0xFFE5E5EA); // Subtle separation
  static const Color dividerColor = Color(0xFFE5E5EA);

  // Accent Colors - Monochromatic/Silver
  // Keeping functional colors but desaturated or specific where needed
  static const Color accentOrange = Color(0xFFFF9500); // Keep for warnings
  static const Color accentRed = Color(0xFFFF3B30); // Errors
  static const Color accentBlue = Color(0xFF000000); // Links/Active -> Black
  static const Color accentGreen = Color(0xFF34C759); // Success
  static const Color accentPurple = Color(0xFFAF52DE);
  static const Color accentTeal = Color(0xFF5AC8FA);

  // Legacy/Additional Accents
  static const Color accentYellow = Color(0xFFFFCC00);
  static const Color immersiveDark = Color(0xFF000000);
  static const Color immersiveDarkSecondary = Color(0xFF1C1C1E);
  static const Color immersiveAccent = Color(0xFF98989D); // Silver

  // Emotion Colors (Gamification) - Refined
  static const Color emotionSuccess = Color(0xFF34C759);
  static const Color emotionProgress = Color(0xFF000000); // Black for progress
  static const Color emotionMotivation = Color(0xFF8E8E93); // Grey
  static const Color emotionRecovery = Color(0xFFFFCC00);

  // Animation Curves & Durations
  static const Duration quickDuration = Duration(milliseconds: 200);
  static const Curve smoothCurve = Curves.easeInOut;

  // Gradients - Subtle or removed for flat clean look
  static const LinearGradient imageOverlayGradient = LinearGradient(
    colors: [Colors.transparent, Colors.black87],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ═══════════════════════════════════════════════════════════
  // SHADOWS - SOFT GLASS EFFECT
  // ═══════════════════════════════════════════════════════════

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get imageCardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 32,
      offset: const Offset(0, 12),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get iconShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // ═══════════════════════════════════════════════════════════
  // THEME DATA
  // ═══════════════════════════════════════════════════════════

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      primaryColor: primaryColor,

      // Font Family
      fontFamily: GoogleFonts.outfit().fontFamily,

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: textPrimary,
        tertiary: textSecondary,
        surface: surfaceColor,
        error: accentRed,
        onPrimary: textOnPrimary,
        onSecondary: surfaceColor,
        onSurface: textPrimary,
        onError: textOnPrimary,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor.withOpacity(0.8), // Glassy
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Text Theme - Outfit (Headings) & Inter (Body)
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -1,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displaySmall: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),

        headlineLarge: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),

        titleLarge: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),

        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textTertiary,
          height: 1.5,
        ),

        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),

      // Card Theme - Glass Effect on White
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: borderSecondary, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor, // Black
          foregroundColor: textOnPrimary, // White
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32), // Pill shape
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primaryLight,
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: textTertiary),
        prefixIconColor: textSecondary,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: textPrimary, size: 24),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // RADIUS CONSTANTS - EXTRA ROUNDED
  // ═══════════════════════════════════════════════════════════

  static const double radiusSm = 12;
  static const double radiusMd = 20;
  static const double radiusLg = 28;
  static const double radiusXl = 32;
  static const double radiusFull = 100;

  static BorderRadius get radiusSmRad => BorderRadius.circular(radiusSm);
  static BorderRadius get radiusMdRad => BorderRadius.circular(radiusMd);
  static BorderRadius get radiusLgRad => BorderRadius.circular(radiusLg);
  static BorderRadius get radiusXlRad => BorderRadius.circular(radiusXl);
  static BorderRadius get radiusFullRad => BorderRadius.circular(radiusFull);
}
