import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:gigi/core/theme/modern_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Aggressive Modern Button - Sharp & Bold
class ModernButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isPrimary;
  final IconData? icon;
  final Color? backgroundColor;

  const ModernButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
    this.isPrimary = true,
    this.icon,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
          side: const BorderSide(color: ModernTheme.primaryColor, width: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2), // Sharp corners
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: ModernTheme.primaryColor, size: 22),
              const SizedBox(width: 10),
            ],
            Text(
              text.toUpperCase(),
              style: GoogleFonts.rajdhani(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: ModernTheme.primaryColor,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    // Solid button with sharp edges
    return Container(
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (isPrimary ? ModernTheme.primaryColor : ModernTheme.cardColor),
        borderRadius: BorderRadius.circular(2), // Very sharp
        border: Border.all(
          color:
              backgroundColor ??
              (isPrimary
                  ? ModernTheme.primaryColor
                  : Colors.white.withValues(alpha: 0.2)),
          width: 2,
        ),
        // Sharp shadow effect
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: (backgroundColor ?? ModernTheme.primaryColor)
                      .withValues(alpha: 0.4),
                  offset: const Offset(0, 4),
                  blurRadius: 0, // No blur for sharp shadow
                  spreadRadius: 0,
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isPrimary ? Colors.black : Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
            ],
            Text(
              text.toUpperCase(),
              style: GoogleFonts.rajdhani(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isPrimary ? Colors.black : Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aggressive Modern Card - Angular & Bold
/// Kinetic Modern Card - Glass & Gradient
class ModernCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool enableGlass;

  const ModernCard({
    super.key,
    required this.child,
    this.onTap,
    this.isSelected = false,
    this.padding,
    this.margin,
    this.enableGlass = true,
  });

  @override
  Widget build(BuildContext context) {
    // Kinetic Gradient - aligned with CleanCard but distinct for "Modern" context if needed
    final kineticGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.12),
        Colors.white.withValues(alpha: 0.03),
      ],
      stops: const [0.0, 1.0],
    );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              24,
            ), // Consistent rounded Kinetic shape
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: ModernTheme.primaryColor.withValues(alpha: 0.2),
                      offset: const Offset(0, 8),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Glass Blur
                if (enableGlass)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(color: Colors.transparent),
                    ),
                  ),

                // Content Container
                Container(
                  padding: padding ?? const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ModernTheme.surfaceColor
                        : ModernTheme.cardColor.withValues(
                            alpha: 0.8,
                          ), // Glassy opacity
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? ModernTheme.primaryColor
                          : Colors.white.withValues(alpha: 0.5),
                      width: isSelected ? 2 : 1,
                    ),
                    gradient: enableGlass && !isSelected
                        ? kineticGradient
                        : null,
                  ),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Aggressive Step Indicator - Sharp Rectangles
class ModernStepIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const ModernStepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index <= currentStep;
        final isCurrent = index == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isCurrent ? 32 : (isActive ? 24 : 12), // Angular progression
          height: 12,
          decoration: BoxDecoration(
            color: isActive
                ? ModernTheme.primaryColor
                : Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(1), // Almost square
            border: Border.all(
              color: isActive
                  ? ModernTheme.primaryColor
                  : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        );
      }),
    );
  }
}
