import 'dart:math';
import 'package:flutter/material.dart';

/// A premium, subtle animated background.
/// Creates a "living" mesh gradient effect that feels organic and high-end.
class BackgroundMotion extends StatefulWidget {
  final Widget? child;

  const BackgroundMotion({super.key, this.child});

  @override
  State<BackgroundMotion> createState() => _BackgroundMotionState();
}

class _BackgroundMotionState extends State<BackgroundMotion>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated Background Painter
        Positioned.fill(
          child: CustomPaint(
            painter: _MeshGradientPainter(animation: _controller),
          ),
        ),

        // Content
        if (widget.child != null) Positioned.fill(child: widget.child!),
      ],
    );
  }
}

class _MeshGradientPainter extends CustomPainter {
  final Animation<double> animation;

  _MeshGradientPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    // final rect = Offset.zero & size;

    // Premium Color Palette (Subtle Silver/Blue/Purple hints)
    // Adjust these colors to match the "Silver/Metallic" GIGI aesthetic
    final colors = [
      const Color(0xFFF5F5F7), // Light Silver/White base
      const Color(0xFFE8EAF6), // Very light Indigo hint
      const Color(0xFFF3E5F5), // Very light Purple hint
    ];

    // Create moving gradient orbs
    final paint = Paint()..blendMode = BlendMode.srcOver;

    // Orb 1: Top-Left (Slow circular motion)
    final offset1 = Offset(
      size.width * 0.2 + sin(t * 2 * pi) * 50,
      size.height * 0.2 + cos(t * 2 * pi) * 30,
    );
    paint.shader = RadialGradient(
      colors: [
        colors[1].withValues(alpha: 0.6),
        colors[1].withValues(alpha: 0.0),
      ],
      radius: 0.8,
    ).createShader(Rect.fromCircle(center: offset1, radius: size.width * 0.8));
    canvas.drawCircle(offset1, size.width * 0.8, paint);

    // Orb 2: Bottom-Right (Opposite motion)
    final offset2 = Offset(
      size.width * 0.8 + sin(t * 2 * pi + pi) * 50,
      size.height * 0.8 + cos(t * 2 * pi) * 50,
    );
    paint.shader = RadialGradient(
      colors: [
        colors[2].withValues(alpha: 0.6),
        colors[2].withValues(alpha: 0.0),
      ],
      radius: 0.8,
    ).createShader(Rect.fromCircle(center: offset2, radius: size.width * 0.9));
    canvas.drawCircle(offset2, size.width * 0.9, paint);

    // Orb 3: Center pulsing (Silver highlight)
    final pulse = sin(t * 4 * pi) * 0.1 + 0.9;
    final offset3 = Offset(size.width * 0.5, size.height * 0.5);
    paint.shader =
        RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.8),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: offset3, radius: size.width * 0.6 * pulse),
        );
    canvas.drawCircle(offset3, size.width * 0.6 * pulse, paint);
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter oldDelegate) => true;
}
