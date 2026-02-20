import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A premium animated logo component that supports:
/// 1. Hero transitions
/// 2. Shimmer/Glimmer effects (Metallic look)
/// 3. Breathing/Pulse animations
/// 4. Rive integration (ready for future use)
class AnimatedLogo extends StatelessWidget {
  final double size;
  final bool useHero;
  final String heroTag;
  final bool enableShimmer;
  final bool enableBreathing;

  const AnimatedLogo({
    super.key,
    this.size = 120,
    this.useHero = true,
    this.heroTag = 'gigi_logo',
    this.enableShimmer = true,
    this.enableBreathing = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget logoContent = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      padding: EdgeInsets.all(size * 0.15), // Responsive padding
      child: Image.asset(
        'assets/images/gigi_new_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.fitness_center, size: size * 0.5, color: Colors.black),
      ),
    );

    // 1. Shimmer Effect (Metallic Glimmer)
    if (enableShimmer) {
      logoContent = logoContent
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(
            duration: 3000.ms,
            color: Colors.white.withValues(alpha: 0.8),
            angle: 0.8, // Diagonal shimmer
            curve: Curves.easeInOutQuad,
          );
    }

    // 2. Breathing Animation (Subtle Scale)
    if (enableBreathing) {
      logoContent = logoContent
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scaleXY(end: 1.05, duration: 2000.ms, curve: Curves.easeInOutSine);
    }

    // 3. Hero Wrapper
    if (useHero) {
      return Hero(tag: heroTag, child: logoContent);
    }

    return logoContent;
  }
}
