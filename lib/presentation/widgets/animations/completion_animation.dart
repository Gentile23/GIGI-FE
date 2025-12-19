import 'package:flutter/material.dart';
import '../../../core/theme/clean_theme.dart';

/// Animated checkmark that appears on completion
/// Use with OverlayEntry or showDialog for best effect
class CompletionAnimation extends StatefulWidget {
  final VoidCallback? onComplete;
  final String? message;

  const CompletionAnimation({super.key, this.onComplete, this.message});

  @override
  State<CompletionAnimation> createState() => _CompletionAnimationState();

  /// Show the completion animation as an overlay
  static void show(BuildContext context, {String? message}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => CompletionAnimation(
        message: message,
        onComplete: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _CompletionAnimationState extends State<CompletionAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _checkController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOutCirc,
    );

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) _checkController.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      await _scaleController.reverse();
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: CleanTheme.accentGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CleanTheme.accentGreen.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _checkAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: CheckmarkPainter(
                    progress: _checkAnimation.value,
                    color: Colors.white,
                    strokeWidth: 6,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  CheckmarkPainter({
    required this.progress,
    this.color = Colors.white,
    this.strokeWidth = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final checkSize = size.width * 0.35;

    // Checkmark path points
    final start = Offset(center.dx - checkSize * 0.5, center.dy);
    final mid = Offset(
      center.dx - checkSize * 0.1,
      center.dy + checkSize * 0.4,
    );
    final end = Offset(
      center.dx + checkSize * 0.5,
      center.dy - checkSize * 0.3,
    );

    final path = Path();

    if (progress <= 0.5) {
      // First stroke (down-left to middle)
      final t = progress * 2;
      final currentPoint = Offset.lerp(start, mid, t)!;
      path.moveTo(start.dx, start.dy);
      path.lineTo(currentPoint.dx, currentPoint.dy);
    } else {
      // First stroke complete, second stroke (middle to up-right)
      path.moveTo(start.dx, start.dy);
      path.lineTo(mid.dx, mid.dy);

      final t = (progress - 0.5) * 2;
      final currentPoint = Offset.lerp(mid, end, t)!;
      path.lineTo(currentPoint.dx, currentPoint.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CheckmarkPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
