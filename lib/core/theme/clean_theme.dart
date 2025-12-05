import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// CLEAN MINIMAL THEME - TRAVEL APP INSPIRED
/// Light, Airy, Premium Aesthetic
/// Colors: White background, Black text, Green accent
class CleanTheme {
  // ═══════════════════════════════════════════════════════════
  // CLEAN COLOR PALETTE - MINIMAL & ELEGANT
  // ═══════════════════════════════════════════════════════════

  // Primary - Fresh Green (accent color)
  static const Color primaryColor = Color(0xFF22C55E); // Clean green
  static const Color primaryLight = Color(0xFFDCFCE7); // Light green bg
  static const Color primaryDark = Color(0xFF16A34A); // Darker green

  // Backgrounds - Pure & Clean
  static const Color backgroundColor = Color(0xFFFAFAFA); // Off-white
  static const Color surfaceColor = Color(0xFFFFFFFF); // Pure white
  static const Color cardColor = Color(0xFFFFFFFF); // White cards
  static const Color elevatedCard = Color(0xFFFFFFFF); // White elevated

  // Text Colors - High Readability
  static const Color textPrimary = Color(0xFF1A1A1A); // Near black
  static const Color textSecondary = Color(0xFF6B7280); // Gray
  static const Color textTertiary = Color(0xFF9CA3AF); // Light gray
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White on green

  // Border & Divider Colors
  static const Color borderPrimary = Color(0xFFE5E7EB); // Light border
  static const Color borderSecondary = Color(0xFFF3F4F6); // Very light
  static const Color dividerColor = Color(0xFFF3F4F6); // Subtle divider

  // Accent Colors
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentYellow = Color(0xFFFBBF24);
  static const Color accentGreen = Color(0xFF22C55E); // Same as primary
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentPurple = Color(0xFF8B5CF6);

  // ═══════════════════════════════════════════════════════════
  // PSYCHOLOGICAL COLOR PALETTE - Emotion-driven UX
  // ═══════════════════════════════════════════════════════════

  /// Motivation Orange - For streak flames and urgency (without fear)
  /// Psychology: Energizing, warm, action-oriented
  static const Color emotionMotivation = Color(0xFFFF6B35);
  static const Color emotionMotivationLight = Color(0xFFFEF3ED);

  /// Success Green - For completions, achievements, XP gains
  /// Psychology: Reward, growth, positive reinforcement
  static const Color emotionSuccess = Color(0xFF00D26A);
  static const Color emotionSuccessLight = Color(0xFFE6FAF0);

  /// Urgency Red - For streak warnings (loss aversion trigger)
  /// Psychology: Alert without anxiety, protective instinct
  static const Color emotionUrgency = Color(0xFFE74C3C);
  static const Color emotionUrgencyLight = Color(0xFFFDF2F2);

  /// Progress Purple - For XP, levels, and gamification
  /// Psychology: Premium, mastery, achievement
  static const Color emotionProgress = Color(0xFF9B59B6);
  static const Color emotionProgressLight = Color(0xFFF5F0F7);

  /// Recovery Blue/Cyan - For rest days and recovery suggestions
  /// Psychology: Calm, trust, safety, healing
  static const Color emotionRecovery = Color(0xFF06B6D4);
  static const Color emotionRecoveryLight = Color(0xFFECFEFF);

  /// Immersive Mode - Dark theme for focused workouts
  /// Psychology: Focus, intensity, minimal distraction
  static const Color immersiveDark = Color(0xFF1A1A2E);
  static const Color immersiveDarkSecondary = Color(0xFF16213E);
  static const Color immersiveAccent = Color(0xFF00D26A);

  // ═══════════════════════════════════════════════════════════
  // THEME DATA
  // ═══════════════════════════════════════════════════════════

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,

      // Color Scheme - Clean & Fresh
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: textSecondary,
        tertiary: accentBlue,
        surface: surfaceColor,
        error: accentRed,
        onPrimary: textOnPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onError: textOnPrimary,
      ),

      // ═══════════════════════════════════════════════════════════
      // TYPOGRAPHY - CLEAN & MODERN
      // ═══════════════════════════════════════════════════════════
      textTheme: TextTheme(
        // Display - Large Headlines
        displayLarge: GoogleFonts.outfit(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -1.0,
          height: 1.1,
        ),
        displayMedium: GoogleFonts.outfit(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displaySmall: GoogleFonts.outfit(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.25,
          height: 1.2,
        ),

        // Headlines - Section Titles
        headlineLarge: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.25,
          height: 1.3,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0,
          height: 1.3,
        ),
        headlineSmall: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0,
          height: 1.4,
        ),

        // Titles
        titleLarge: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0,
          height: 1.4,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0,
          height: 1.4,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0,
          height: 1.4,
        ),

        // Body - Readable Text
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          letterSpacing: 0,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          letterSpacing: 0,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textTertiary,
          letterSpacing: 0,
          height: 1.5,
        ),

        // Labels - Buttons & Chips
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.1,
          height: 1.0,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          letterSpacing: 0.5,
          height: 1.0,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textTertiary,
          letterSpacing: 0.5,
          height: 1.0,
        ),
      ),

      // ═══════════════════════════════════════════════════════════
      // COMPONENT THEMES - ROUNDED & SOFT
      // ═══════════════════════════════════════════════════════════

      // AppBar - Clean & Minimal
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0.5,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0,
        ),
        iconTheme: const IconThemeData(color: textPrimary, size: 24),
      ),

      // Card - Rounded with subtle shadow
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderPrimary, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),

      // Elevated Button - Rounded & Filled
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: textPrimary,
          foregroundColor: surfaceColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),

      // Outlined Button - Rounded Border
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),

      // Text Button - Subtle
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),

      // Input Decoration - Rounded & Clean
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        // Default Border
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderPrimary, width: 1),
        ),

        // Enabled Border
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderPrimary, width: 1),
        ),

        // Focused Border
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: textPrimary, width: 1.5),
        ),

        // Error Border
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentRed, width: 1.5),
        ),

        // Label Style
        labelStyle: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),

        // Floating Label Style
        floatingLabelStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),

        // Hint Style
        hintStyle: GoogleFonts.inter(
          color: textTertiary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),

        // Error Style
        errorStyle: GoogleFonts.inter(
          color: accentRed,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),

        // Prefix/Suffix Icon Color
        prefixIconColor: textTertiary,
        suffixIconColor: textTertiary,
      ),

      // Divider - Very Subtle
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: borderSecondary,
        circularTrackColor: borderSecondary,
      ),

      // Chip - Rounded Pills
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        deleteIconColor: textSecondary,
        disabledColor: borderSecondary,
        selectedColor: textPrimary,
        secondarySelectedColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          color: surfaceColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderPrimary, width: 1),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: textPrimary,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: textPrimary,
        foregroundColor: surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: textPrimary, size: 24),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CUSTOM SHADOWS - SOFT & SUBTLE
  // ═══════════════════════════════════════════════════════════

  // Card Shadow - Soft elevation
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // Elevated Shadow - For modals and overlays
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 48,
      offset: const Offset(0, 16),
      spreadRadius: 0,
    ),
  ];

  // Image Card Shadow - For cards with images
  static List<BoxShadow> get imageCardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  // ═══════════════════════════════════════════════════════════
  // GRADIENTS - SUBTLE & ELEGANT
  // ═══════════════════════════════════════════════════════════

  // Image Overlay Gradient - For text on images
  static const LinearGradient imageOverlayGradient = LinearGradient(
    colors: [Colors.transparent, Color(0xCC000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.4, 1.0],
  );

  // Primary Gradient - Green tones
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ═══════════════════════════════════════════════════════════
  // BORDER RADIUS PRESETS
  // ═══════════════════════════════════════════════════════════

  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radius2xl = 24;
  static const double radiusFull = 999;

  // ═══════════════════════════════════════════════════════════
  // SPACING PRESETS
  // ═══════════════════════════════════════════════════════════

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 20;
  static const double space2xl = 24;
  static const double space3xl = 32;

  // ═══════════════════════════════════════════════════════════
  // ANIMATION CURVES - SMOOTH & NATURAL
  // ═══════════════════════════════════════════════════════════

  static const Curve smoothCurve = Curves.easeOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Duration quickDuration = Duration(milliseconds: 200);
  static const Duration normalDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 450);
}
