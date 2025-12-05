import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/audio_manager.dart';

/// Tipi di celebrazione disponibili
enum CelebrationStyle {
  confetti, // Per completamento workout
  fireworks, // Per achievement rari
  goldenShower, // Per level up
  streakFire, // Per streak milestone
  stars, // Per personal record
  sparkles, // Per XP bonus
}

/// Widget overlay per celebrazioni animate
class CelebrationOverlay extends StatefulWidget {
  final CelebrationStyle style;
  final VoidCallback? onComplete;
  final Duration duration;
  final bool autoPlay;

  const CelebrationOverlay({
    super.key,
    required this.style,
    this.onComplete,
    this.duration = const Duration(seconds: 3),
    this.autoPlay = true,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();

  /// Mostra overlay di celebrazione
  static Future<void> show(
    BuildContext context, {
    required CelebrationStyle style,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onComplete,
  }) async {
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => CelebrationOverlay(
        style: style,
        duration: duration,
        onComplete: () {
          entry.remove();
          onComplete?.call();
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _fadeController;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _generateParticles();

    if (widget.autoPlay) {
      _play();
    }
  }

  void _generateParticles() {
    _particles.clear();

    int count;
    switch (widget.style) {
      case CelebrationStyle.confetti:
        count = 100;
        break;
      case CelebrationStyle.fireworks:
        count = 150;
        break;
      case CelebrationStyle.goldenShower:
        count = 80;
        break;
      case CelebrationStyle.streakFire:
        count = 60;
        break;
      case CelebrationStyle.stars:
        count = 50;
        break;
      case CelebrationStyle.sparkles:
        count = 40;
        break;
    }

    for (int i = 0; i < count; i++) {
      _particles.add(
        _Particle(
          style: widget.style,
          random: _random,
          index: i,
          totalCount: count,
        ),
      );
    }
  }

  Future<void> _play() async {
    // Trigger audio e haptic
    _triggerFeedback();

    // Avvia animazione
    await _mainController.forward();

    // Fade out
    await _fadeController.forward();

    // Callback
    widget.onComplete?.call();
  }

  void _triggerFeedback() {
    switch (widget.style) {
      case CelebrationStyle.confetti:
        HapticService.celebrationPattern();
        AudioManager().playCelebration(CelebrationType.workoutComplete);
        break;
      case CelebrationStyle.fireworks:
        HapticService.rareAchievementPattern();
        AudioManager().playCelebration(CelebrationType.achievementUnlock);
        break;
      case CelebrationStyle.goldenShower:
        HapticService.levelUpPattern();
        AudioManager().playCelebration(CelebrationType.levelUp);
        break;
      case CelebrationStyle.streakFire:
        HapticService.streakMilestonePattern(7);
        AudioManager().playCelebration(CelebrationType.streakMilestone);
        break;
      case CelebrationStyle.stars:
        HapticService.personalRecordPattern();
        AudioManager().playCelebration(CelebrationType.personalRecord);
        break;
      case CelebrationStyle.sparkles:
        HapticService.celebrationPattern();
        break;
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_mainController, _fadeController]),
        builder: (context, child) {
          return Opacity(
            opacity: 1.0 - _fadeController.value,
            child: CustomPaint(
              painter: _CelebrationPainter(
                particles: _particles,
                progress: _mainController.value,
                style: widget.style,
              ),
              size: MediaQuery.of(context).size,
            ),
          );
        },
      ),
    );
  }
}

/// Particella singola per le animazioni
class _Particle {
  final CelebrationStyle style;
  final double startX;
  final double startY;
  final double velocityX;
  final double velocityY;
  final double size;
  final Color color;
  final double rotationSpeed;
  final double delay;
  final int shape; // 0: circle, 1: square, 2: star

  _Particle({
    required this.style,
    required Random random,
    required int index,
    required int totalCount,
  }) : startX = random.nextDouble(),
       startY = _getStartY(style, random),
       velocityX = (random.nextDouble() - 0.5) * 2,
       velocityY = _getVelocityY(style, random),
       size = random.nextDouble() * 8 + 4,
       color = _getColor(style, random),
       rotationSpeed = random.nextDouble() * 4 - 2,
       delay = random.nextDouble() * 0.3,
       shape = random.nextInt(3);

  static double _getStartY(CelebrationStyle style, Random random) {
    switch (style) {
      case CelebrationStyle.confetti:
        return -0.1;
      case CelebrationStyle.fireworks:
        return 0.5 + random.nextDouble() * 0.3;
      case CelebrationStyle.goldenShower:
        return -0.2;
      case CelebrationStyle.streakFire:
        return 1.1;
      case CelebrationStyle.stars:
        return random.nextDouble();
      case CelebrationStyle.sparkles:
        return random.nextDouble();
    }
  }

  static double _getVelocityY(CelebrationStyle style, Random random) {
    switch (style) {
      case CelebrationStyle.confetti:
        return random.nextDouble() * 2 + 1;
      case CelebrationStyle.fireworks:
        return (random.nextDouble() - 0.5) * 4;
      case CelebrationStyle.goldenShower:
        return random.nextDouble() * 1.5 + 0.5;
      case CelebrationStyle.streakFire:
        return -(random.nextDouble() * 2 + 1);
      case CelebrationStyle.stars:
        return 0;
      case CelebrationStyle.sparkles:
        return (random.nextDouble() - 0.5) * 0.5;
    }
  }

  static Color _getColor(CelebrationStyle style, Random random) {
    switch (style) {
      case CelebrationStyle.confetti:
        return [
          const Color(0xFFFF6B6B),
          const Color(0xFF4ECDC4),
          const Color(0xFFFFE66D),
          const Color(0xFF95E1D3),
          const Color(0xFFF38181),
          const Color(0xFFAA96DA),
        ][random.nextInt(6)];

      case CelebrationStyle.fireworks:
        final hue = random.nextDouble() * 360;
        return HSLColor.fromAHSL(1.0, hue, 1.0, 0.6).toColor();

      case CelebrationStyle.goldenShower:
        return [
          const Color(0xFFFFD700),
          const Color(0xFFFFA500),
          const Color(0xFFFFEC8B),
          const Color(0xFFDAA520),
        ][random.nextInt(4)];

      case CelebrationStyle.streakFire:
        return [
          const Color(0xFFFF4500),
          const Color(0xFFFF6347),
          const Color(0xFFFF8C00),
          const Color(0xFFFFD700),
        ][random.nextInt(4)];

      case CelebrationStyle.stars:
        return [
          Colors.white,
          const Color(0xFFFFD700),
          const Color(0xFFADD8E6),
        ][random.nextInt(3)];

      case CelebrationStyle.sparkles:
        return [
          Colors.white,
          const Color(0xFFE0E0E0),
          const Color(0xFFB0B0B0),
        ][random.nextInt(3)];
    }
  }
}

/// Painter per le celebrazioni
class _CelebrationPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final CelebrationStyle style;

  _CelebrationPainter({
    required this.particles,
    required this.progress,
    required this.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final adjustedProgress = (progress - particle.delay).clamp(0.0, 1.0);
      if (adjustedProgress <= 0) continue;

      final x =
          size.width *
          (particle.startX + particle.velocityX * adjustedProgress);
      final y =
          size.height *
          (particle.startY + particle.velocityY * adjustedProgress);

      // Gravity effect for some styles
      final gravity =
          style == CelebrationStyle.confetti ||
              style == CelebrationStyle.goldenShower
          ? adjustedProgress * adjustedProgress * size.height * 0.5
          : 0.0;

      final finalY = y + gravity;

      // Alpha fade
      final alpha =
          style == CelebrationStyle.stars || style == CelebrationStyle.sparkles
          ? (sin(adjustedProgress * pi * 2) * 0.5 + 0.5)
          : (1.0 - adjustedProgress * 0.5);

      final paint = Paint()
        ..color = particle.color.withValues(alpha: alpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      // Rotation
      canvas.save();
      canvas.translate(x, finalY);
      canvas.rotate(particle.rotationSpeed * adjustedProgress * 2 * pi);

      // Draw based on shape
      final particleSize = particle.size * (1.0 - adjustedProgress * 0.3);

      switch (particle.shape) {
        case 0: // Circle
          canvas.drawCircle(Offset.zero, particleSize, paint);
          break;
        case 1: // Square
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particleSize * 2,
              height: particleSize * 2,
            ),
            paint,
          );
          break;
        case 2: // Star
          _drawStar(canvas, particleSize, paint);
          break;
      }

      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, double size, Paint paint) {
    final path = Path();
    const points = 5;
    const innerRadius = 0.5;

    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? size : size * innerRadius;
      final angle = (i * pi / points) - pi / 2;
      final x = radius * cos(angle);
      final y = radius * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Widget per quick celebrazioni
class QuickCelebration extends StatelessWidget {
  final Widget child;
  final CelebrationStyle style;
  final bool showCelebration;
  final VoidCallback? onCelebrationComplete;

  const QuickCelebration({
    super.key,
    required this.child,
    required this.style,
    this.showCelebration = false,
    this.onCelebrationComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (showCelebration)
          Positioned.fill(
            child: CelebrationOverlay(
              style: style,
              onComplete: onCelebrationComplete,
            ),
          ),
      ],
    );
  }
}
