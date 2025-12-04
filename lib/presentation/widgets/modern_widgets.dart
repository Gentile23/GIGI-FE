import 'package:flutter/material.dart';
import 'package:fitgenius/core/theme/modern_theme.dart';
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
                  : Colors.white.withOpacity(0.2)),
          width: 2,
        ),
        // Sharp shadow effect
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: (backgroundColor ?? ModernTheme.primaryColor)
                      .withOpacity(0.4),
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
class ModernCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isSelected;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ModernCard({
    super.key,
    required this.child,
    this.onTap,
    this.isSelected = false,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150), // Faster, snappier
        margin: margin,
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? ModernTheme.cardColor : ModernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(4), // Sharp corners
          border: Border.all(
            color: isSelected
                ? ModernTheme.primaryColor
                : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 3 : 2, // Bold borders
          ),
          // Sharp shadow for selected state
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ModernTheme.primaryColor.withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 0, // Sharp shadow
                    spreadRadius: 0,
                  ),
                ]
              : [],
        ),
        child: child,
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
                : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(1), // Almost square
            border: Border.all(
              color: isActive
                  ? ModernTheme.primaryColor
                  : Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
        );
      }),
    );
  }
}
