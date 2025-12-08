import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // ============================================
  // MINIMAL & ELEGANT COLOR PALETTE
  // ============================================

  // Base Colors
  static const Color deepCharcoal = Color(0xFF1A1A1A);
  static const Color softWhite = Color(0xFFFAFAFA);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color warmGray = Color(0xFFE5E5E5);

  // Accent Colors
  static const Color sageGreen = Color(0xFF7C9885);
  static const Color warmBeige = Color(0xFFD4C5B9);
  static const Color softCoral = Color(0xFFE8A598);

  // Semantic Colors
  static const Color success = Color(0xFF6B9080);
  static const Color warning = Color(0xFFD4A574);
  static const Color error = Color(0xFFC97C7C);
  static const Color info = Color(0xFF8B9DC3);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textOnDark = Color(0xFFFAFAFA);

  // Background & Surface
  static const Color background = deepCharcoal;
  static const Color backgroundLight = softWhite;
  static const Color surface = pureWhite;
  static const Color surfaceDark = Color(0xFF2A2A2A);

  // Primary Accent (Sage Green)
  static const Color primary = sageGreen;
  static const Color primaryLight = Color(0xFF9DB5A4);
  static const Color primaryDark = Color(0xFF5A7361);

  // Secondary Accent (Warm Beige)
  static const Color secondary = warmBeige;
  static const Color secondaryLight = Color(0xFFE5D9D0);
  static const Color secondaryDark = Color(0xFFB8A89D);

  // Tertiary Accent (Soft Coral)
  static const Color tertiary = softCoral;
  static const Color tertiaryLight = Color(0xFFF0BDB3);
  static const Color tertiaryDark = Color(0xFFD18A7C);

  // Gradients - Subtle and Elegant
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [sageGreen, Color(0xFF9DB5A4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [warmBeige, Color(0xFFE5D9D0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [softCoral, Color(0xFFF0BDB3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dividers & Borders
  static const Color divider = warmGray;
  static const Color border = Color(0xFFD0D0D0);
  static const Color borderLight = Color(0xFFEEEEEE);

  // Shadows (for BoxShadow)
  static List<BoxShadow> get shadowLight => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowHeavy => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // Difficulty Colors (Refined)
  static const Color difficultyBeginner = Color(0xFF6B9080);
  static const Color difficultyIntermediate = Color(0xFFD4A574);
  static const Color difficultyAdvanced = Color(0xFFC97C7C);

  // Exercise Type Colors (Subtle)
  static const Color strengthColor = sageGreen;
  static const Color mobilityColor = Color(0xFF8B9DC3);
  static const Color cardioColor = softCoral;

  // Overlay Colors
  static Color get overlay => Colors.black.withValues(alpha: 0.5);
  static Color get overlayLight => Colors.black.withValues(alpha: 0.3);

  // ============================================
  // BACKWARD COMPATIBILITY ALIASES
  // ============================================
  // These map old color names to new minimal palette
  // TODO: Remove these after refactoring all screens

  static Color get primaryNeon => primary; // sage green
  static Color get accentBlue => info; // soft blue
  static Color get accentPurple => secondary; // warm beige
  static Color get accentYellow => tertiary; // soft coral
  static Color get accentOrange => warning; // warm amber
  static Color get accentRed => error; // soft red
  static Color get textDark => textPrimary;
  static Color get textLight => textOnDark;
  static Color get cardBackground => surface;
  static Color get shadow => Colors.black.withValues(alpha: 0.1);
  static LinearGradient get neonGradient => primaryGradient;
}
