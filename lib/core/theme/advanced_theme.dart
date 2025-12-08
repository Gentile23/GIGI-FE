import 'package:flutter/material.dart';

/// Tema avanzato con effetti glassmorphism, neon glow e gradienti premium
class AdvancedTheme {
  // ============ COLORI BASE ============
  static const Color backgroundColor = Color(0xFF0A0A0F);
  static const Color surfaceColor = Color(0xFF12121A);
  static const Color cardColor = Color(0xFF1A1A25);

  // Colori primari
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // Colori accent
  static const Color accentCyan = Color(0xFF22D3EE);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentGold = Color(0xFFFFD700);

  // ============ GRADIENTI ============
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [accentCyan, primaryColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fireGradient = LinearGradient(
    colors: [Color(0xFFFF4500), Color(0xFFFF6347), Color(0xFFFFD700)],
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
  );

  static LinearGradient backgroundGradient(double animationValue) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(
          const Color(0xFF0A0A0F),
          const Color(0xFF12121A),
          animationValue,
        )!,
        Color.lerp(
          const Color(0xFF12121A),
          const Color(0xFF0A0A0F),
          animationValue,
        )!,
      ],
    );
  }

  // ============ GLASSMORPHISM ============
  static BoxDecoration glassCard({
    double opacity = 0.1,
    double borderOpacity = 0.2,
    double borderRadius = 24,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: opacity),
          Colors.white.withValues(alpha: opacity * 0.5),
        ],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: Colors.white.withValues(alpha: borderOpacity)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 20,
          spreadRadius: 5,
        ),
      ],
    );
  }

  static BoxDecoration glassCardDark({double borderRadius = 24}) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.02),
        ],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  // ============ NEON GLOW ============
  static List<BoxShadow> neonGlow(Color color, {double intensity = 1.0}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.6 * intensity),
        blurRadius: 20,
        spreadRadius: 2,
      ),
      BoxShadow(
        color: color.withValues(alpha: 0.3 * intensity),
        blurRadius: 40,
        spreadRadius: 4,
      ),
      BoxShadow(
        color: color.withValues(alpha: 0.1 * intensity),
        blurRadius: 60,
        spreadRadius: 8,
      ),
    ];
  }

  static List<BoxShadow> subtleGlow(Color color) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.3),
        blurRadius: 15,
        spreadRadius: 1,
      ),
    ];
  }

  // ============ CARD DECORATIONS ============
  static BoxDecoration premiumCard({
    Color? glowColor,
    double borderRadius = 20,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [cardColor, cardColor.withValues(alpha: 0.8)],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      boxShadow: glowColor != null
          ? subtleGlow(glowColor)
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
    );
  }

  static BoxDecoration achievementCard(String rarity) {
    Color glowColor;
    double glowIntensity;

    switch (rarity.toLowerCase()) {
      case 'legendary':
        glowColor = accentGold;
        glowIntensity = 1.0;
        break;
      case 'epic':
        glowColor = accentPurple;
        glowIntensity = 0.8;
        break;
      case 'rare':
        glowColor = accentCyan;
        glowIntensity = 0.6;
        break;
      default:
        glowColor = Colors.grey;
        glowIntensity = 0.3;
    }

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [glowColor.withValues(alpha: 0.15), cardColor],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: glowColor.withValues(alpha: 0.5), width: 2),
      boxShadow: neonGlow(glowColor, intensity: glowIntensity),
    );
  }

  // ============ BOTTONI ============
  static BoxDecoration primaryButton({bool isPressed = false}) {
    return BoxDecoration(
      gradient: isPressed
          ? const LinearGradient(colors: [primaryDark, primaryColor])
          : primaryGradient,
      borderRadius: BorderRadius.circular(16),
      boxShadow: isPressed
          ? []
          : [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }

  static BoxDecoration outlineButton({Color? color}) {
    final buttonColor = color ?? primaryColor;
    return BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: buttonColor, width: 2),
    );
  }

  // ============ INPUT DECORATIONS ============
  static InputDecoration modernInput({
    String? hintText,
    IconData? prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: Colors.white.withValues(alpha: 0.5))
          : null,
      suffix: suffix,
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  // ============ TEXT STYLES ============
  static TextStyle get headlineLarge => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: -0.5,
  );

  static TextStyle get headlineMedium => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle get titleLarge => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle get bodyLarge =>
      TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.9));

  static TextStyle get bodyMedium =>
      TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7));

  static TextStyle get labelSmall => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Colors.white.withValues(alpha: 0.5),
    letterSpacing: 0.5,
  );

  // ============ ANIMAZIONI ============
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bouncyCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;
}
