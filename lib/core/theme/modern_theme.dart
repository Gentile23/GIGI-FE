import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AGGRESSIVE SPORTY THEME - GIGI LOGO INSPIRED
/// Ultra-Bold, High-Energy, Performance Aesthetic
/// Colors: Neon Green, Electric Gold, Cyber Cyan, Aggressive Red
class ModernTheme {
  // ═══════════════════════════════════════════════════════════
  // LOGO-INSPIRED COLOR PALETTE - VIBRANT & AGGRESSIVE
  // ═══════════════════════════════════════════════════════════

  // Primary - Neon Lime (from logo)
  static const Color primaryColor = Color(0xFF39FF14); // Vibrant neon green

  // Secondary - Electric Gold (from logo)
  static const Color secondaryColor = Color(0xFFFFC700); // Electric gold

  // Accents - Cyber & Aggressive (from logo)
  static const Color accentCyan = Color(0xFF00F0FF); // Cyber cyan
  static const Color accentRed = Color(0xFFFF003C); // Aggressive red
  static const Color accentOrange = Color(0xFFFF6B00); // Energy orange

  // Backward compatibility alias
  static const Color accentColor =
      accentCyan; // Alias for backward compatibility

  // Backgrounds - Pure Black & Dark
  static const Color backgroundColor = Color(0xFF000000); // Pure black
  static const Color surfaceColor = Color(0xFF121212); // Dark surface
  static const Color cardColor = Color(0xFF1A1A1A); // Card background
  static const Color elevatedCard = Color(0xFF252525); // Elevated cards

  // Text Colors - High Contrast
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white
  static const Color textSecondary = Color(0xFFB8B8B8); // Light gray
  static const Color textTertiary = Color(0xFF808080); // Medium gray

  // Border & Divider Colors
  static const Color borderPrimary = Color(0xFF39FF14); // Neon green border
  static const Color borderSecondary = Color(0xFF333333); // Dark border
  static const Color dividerColor = Color(0xFF2A2A2A); // Subtle divider

  // ═══════════════════════════════════════════════════════════
  // THEME DATA
  // ═══════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      primaryColor: primaryColor,

      // Color Scheme - Aggressive & Vibrant
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentCyan,
        surface: surfaceColor,
        background: backgroundColor,
        error: accentRed,
        onPrimary: Color(0xFF000000),
        onSecondary: Color(0xFF000000),
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: textPrimary,
      ),

      // ═══════════════════════════════════════════════════════════
      // TYPOGRAPHY - ULTRA BOLD & CONDENSED
      // ═══════════════════════════════════════════════════════════
      textTheme: TextTheme(
        // Display - Bebas Neue (Ultra Condensed, All Caps Style)
        displayLarge: GoogleFonts.bebasNeue(
          fontSize: 56,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 2.0,
          height: 1.0,
        ),
        displayMedium: GoogleFonts.bebasNeue(
          fontSize: 44,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 1.8,
          height: 1.0,
        ),
        displaySmall: GoogleFonts.bebasNeue(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 1.5,
          height: 1.1,
        ),

        // Headlines - Oswald (Condensed, Bold)
        headlineLarge: GoogleFonts.oswald(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 1.2,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.oswald(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 1.0,
          height: 1.2,
        ),
        headlineSmall: GoogleFonts.oswald(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.8,
          height: 1.2,
        ),

        // Titles - Oswald (Medium Weight)
        titleLarge: GoogleFonts.oswald(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.6,
          height: 1.3,
        ),
        titleMedium: GoogleFonts.oswald(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.5,
          height: 1.3,
        ),
        titleSmall: GoogleFonts.oswald(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.4,
          height: 1.3,
        ),

        // Body - Rajdhani (Geometric, Sporty)
        bodyLarge: GoogleFonts.rajdhani(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.3,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.rajdhani(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          letterSpacing: 0.25,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.rajdhani(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textTertiary,
          letterSpacing: 0.2,
          height: 1.5,
        ),

        // Labels - Bebas Neue (Uppercase Style)
        labelLarge: GoogleFonts.bebasNeue(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: backgroundColor,
          letterSpacing: 2.0,
          height: 1.0,
        ),
        labelMedium: GoogleFonts.bebasNeue(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: backgroundColor,
          letterSpacing: 1.8,
          height: 1.0,
        ),
        labelSmall: GoogleFonts.bebasNeue(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: backgroundColor,
          letterSpacing: 1.5,
          height: 1.0,
        ),
      ),

      // ═══════════════════════════════════════════════════════════
      // COMPONENT THEMES - SHARP & AGGRESSIVE
      // ═══════════════════════════════════════════════════════════

      // AppBar - Transparent with Bold Typography
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.bebasNeue(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 2.0,
        ),
        iconTheme: const IconThemeData(color: textPrimary, size: 28),
      ),

      // Card - Angular with Neon Borders
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2), // Ultra sharp
          side: BorderSide(color: borderSecondary, width: 2),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),

      // Elevated Button - Bold & Neon
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: backgroundColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          textStyle: GoogleFonts.bebasNeue(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),

      // Outlined Button - Sharp Borders
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 3),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          textStyle: GoogleFonts.bebasNeue(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),

      // Text Button - Minimal
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.oswald(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
      ),

      // Input Decoration - Angular with Neon Focus
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),

        // Default Border
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0), // Completely sharp
          borderSide: BorderSide(color: borderSecondary, width: 2),
        ),

        // Enabled Border
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: BorderSide(color: borderSecondary, width: 2),
        ),

        // Focused Border - Neon Glow
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: const BorderSide(color: primaryColor, width: 3),
        ),

        // Error Border
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: const BorderSide(color: accentRed, width: 3),
        ),

        // Focused Error Border
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(0),
          borderSide: const BorderSide(color: accentRed, width: 3),
        ),

        // Label Style
        labelStyle: GoogleFonts.oswald(
          color: textSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),

        // Floating Label Style
        floatingLabelStyle: GoogleFonts.oswald(
          color: primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),

        // Hint Style
        hintStyle: GoogleFonts.rajdhani(
          color: textTertiary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),

        // Error Style
        errorStyle: GoogleFonts.rajdhani(
          color: accentRed,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Divider - Subtle
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // Progress Indicator - Neon
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: surfaceColor,
        circularTrackColor: surfaceColor,
      ),

      // Chip - Angular
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        deleteIconColor: textPrimary,
        disabledColor: surfaceColor.withOpacity(0.5),
        selectedColor: primaryColor,
        secondarySelectedColor: secondaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: GoogleFonts.oswald(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        secondaryLabelStyle: GoogleFonts.oswald(
          color: backgroundColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        brightness: Brightness.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: BorderSide(color: borderSecondary, width: 2),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CUSTOM GRADIENTS - VIBRANT & ENERGETIC
  // ═══════════════════════════════════════════════════════════

  // Primary Gradient - Neon Green to Cyan
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, accentCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Secondary Gradient - Gold to Orange
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryColor, accentOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Fire Gradient - Orange to Red
  static const LinearGradient fireGradient = LinearGradient(
    colors: [accentOrange, accentRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Energy Gradient - Full Spectrum
  static const LinearGradient energyGradient = LinearGradient(
    colors: [primaryColor, accentCyan, secondaryColor, accentRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Vertical Gradient - Top to Bottom
  static const LinearGradient verticalGradient = LinearGradient(
    colors: [primaryColor, accentCyan],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ═══════════════════════════════════════════════════════════
  // CUSTOM SHADOWS - NEON GLOW EFFECTS
  // ═══════════════════════════════════════════════════════════

  // Neon Green Glow
  static List<BoxShadow> get neonGlowPrimary => [
    BoxShadow(
      color: primaryColor.withOpacity(0.5),
      blurRadius: 20,
      spreadRadius: 2,
    ),
    BoxShadow(
      color: primaryColor.withOpacity(0.3),
      blurRadius: 40,
      spreadRadius: 4,
    ),
  ];

  // Gold Glow
  static List<BoxShadow> get neonGlowSecondary => [
    BoxShadow(
      color: secondaryColor.withOpacity(0.5),
      blurRadius: 20,
      spreadRadius: 2,
    ),
    BoxShadow(
      color: secondaryColor.withOpacity(0.3),
      blurRadius: 40,
      spreadRadius: 4,
    ),
  ];

  // Cyan Glow
  static List<BoxShadow> get neonGlowCyan => [
    BoxShadow(
      color: accentCyan.withOpacity(0.5),
      blurRadius: 20,
      spreadRadius: 2,
    ),
    BoxShadow(
      color: accentCyan.withOpacity(0.3),
      blurRadius: 40,
      spreadRadius: 4,
    ),
  ];

  // Red Glow
  static List<BoxShadow> get neonGlowRed => [
    BoxShadow(
      color: accentRed.withOpacity(0.5),
      blurRadius: 20,
      spreadRadius: 2,
    ),
    BoxShadow(
      color: accentRed.withOpacity(0.3),
      blurRadius: 40,
      spreadRadius: 4,
    ),
  ];

  // Subtle Elevation
  static List<BoxShadow> get subtleElevation => [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  // ═══════════════════════════════════════════════════════════
  // ANIMATION CURVES - AGGRESSIVE & SNAPPY
  // ═══════════════════════════════════════════════════════════

  static const Curve aggressiveCurve = Curves.easeOutExpo;
  static const Curve snapCurve = Curves.easeOutCubic;
  static const Duration quickDuration = Duration(milliseconds: 200);
  static const Duration normalDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);
}
