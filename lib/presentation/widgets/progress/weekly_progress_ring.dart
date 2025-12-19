import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../core/theme/clean_theme.dart';

/// Weekly Progress Ring - Shows workout completion for the week
class WeeklyProgressRing extends StatelessWidget {
  final int completedWorkouts;
  final int totalWorkouts;
  final bool compact;

  const WeeklyProgressRing({
    super.key,
    required this.completedWorkouts,
    required this.totalWorkouts,
    this.compact = false,
  });

  double get progress => totalWorkouts > 0
      ? (completedWorkouts / totalWorkouts).clamp(0.0, 1.0)
      : 0.0;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 80.0 : 120.0;
    final strokeWidth = compact ? 8.0 : 12.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CleanTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: CleanTheme.primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          CustomPaint(
            size: Size(size, size),
            painter: ProgressRingPainter(
              progress: 1.0,
              color: CleanTheme.borderPrimary,
              strokeWidth: strokeWidth,
            ),
          ),

          // Progress ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return CustomPaint(
                size: Size(size, size),
                painter: ProgressRingPainter(
                  progress: value,
                  color: _getProgressColor(),
                  strokeWidth: strokeWidth,
                ),
              );
            },
          ),

          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$completedWorkouts/$totalWorkouts',
                style: GoogleFonts.outfit(
                  fontSize: compact ? 18 : 24,
                  fontWeight: FontWeight.w700,
                  color: CleanTheme.textPrimary,
                ),
              ),
              if (!compact)
                Text(
                  'questa settimana',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: CleanTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getProgressColor() {
    if (progress >= 1.0) return CleanTheme.accentGreen;
    if (progress >= 0.6) return CleanTheme.primaryColor;
    if (progress >= 0.3) return CleanTheme.accentOrange;
    return CleanTheme.accentRed;
  }
}

class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw arc from top (-π/2) clockwise
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(ProgressRingPainter oldDelegate) =>
      progress != oldDelegate.progress || color != oldDelegate.color;
}
