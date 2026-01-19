import 'package:flutter/material.dart';

/// Utility class for responsive design across different screen sizes
class ResponsiveUtils {
  /// Screen width breakpoints
  static const double smallScreenWidth = 360;
  static const double mediumScreenWidth = 600;
  static const double largeScreenWidth = 900;

  /// Base design width (iPhone 13/14 standard)
  static const double baseDesignWidth = 375;

  /// Check if the screen is a small device (e.g., iPhone SE, small Android)
  static bool isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < smallScreenWidth;

  /// Check if the screen is a medium device (standard phone)
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= smallScreenWidth && width < mediumScreenWidth;
  }

  /// Check if the screen is a large device (tablet or large phone)
  static bool isLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= mediumScreenWidth;

  /// Get screen width
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// Get screen height
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Scale a value based on screen width relative to base design
  static double scale(BuildContext context, double value) =>
      value * (screenWidth(context) / baseDesignWidth);

  /// Scale padding based on screen width
  static double scaledPadding(BuildContext context, double basePadding) =>
      basePadding * (screenWidth(context) / baseDesignWidth).clamp(0.8, 1.3);

  /// Get bottom safe area padding (for iOS notch/home indicator)
  static double bottomSafeArea(BuildContext context) =>
      MediaQuery.of(context).viewPadding.bottom;

  /// Get top safe area padding (for iOS notch/Dynamic Island)
  static double topSafeArea(BuildContext context) =>
      MediaQuery.of(context).viewPadding.top;

  /// Calculate dynamic bottom padding for floating elements
  /// Takes into account the safe area and a minimum base height
  static double floatingElementPadding(
    BuildContext context, {
    double baseHeight = 200,
  }) {
    final safeArea = bottomSafeArea(context);
    return baseHeight + safeArea;
  }

  /// Get responsive font size that respects accessibility settings
  static double responsiveFontSize(
    BuildContext context,
    double baseFontSize, {
    double maxScale = 1.3,
  }) {
    final textScaleFactor = MediaQuery.of(context).textScaler.scale(1.0);
    return baseFontSize * textScaleFactor.clamp(0.8, maxScale);
  }

  /// Get responsive horizontal padding based on screen size
  static EdgeInsets responsiveHorizontalPadding(BuildContext context) {
    if (isLargeScreen(context)) {
      return const EdgeInsets.symmetric(horizontal: 32);
    } else if (isSmallScreen(context)) {
      return const EdgeInsets.symmetric(horizontal: 12);
    }
    return const EdgeInsets.symmetric(horizontal: 20);
  }

  /// Get content max width for large screens (prevents overly wide content)
  static double maxContentWidth(BuildContext context) {
    if (isLargeScreen(context)) {
      return 600; // Max width for content on tablets
    }
    return double.infinity;
  }
}
