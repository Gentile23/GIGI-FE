import 'package:flutter/material.dart';

class LiquidSteelContainer extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final bool enableShine;
  final Border? border;

  const LiquidSteelContainer({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.enableShine = true,
    this.border,
  });

  @override
  State<LiquidSteelContainer> createState() => _LiquidSteelContainerState();
}

class _LiquidSteelContainerState extends State<LiquidSteelContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _startAnimationLoop();
  }

  void _startAnimationLoop() async {
    while (mounted) {
      if (widget.enableShine) {
        _controller.reset();
        await _controller.forward();
        // The animation takes Duration(seconds: 4)
        // Increased delay as requested: 4s animation + 6s wait = 10s cycle
        await Future.delayed(const Duration(seconds: 6));
      } else {
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return RepaintBoundary(
          child: Container(
            // Removed fixed maxHeight to allow wrapping content naturally
            constraints: const BoxConstraints(),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border:
                  widget.border ??
                  Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
              gradient: const LinearGradient(
                begin: Alignment(-1, -1),
                end: Alignment(1, 1),
                colors: [
                  Color(0xFF2C2C2E), // Dark Steel
                  Color(0xFF3A3A3C), // Mid Steel
                  Color(0xFF48484A), // Slightly Lighter Steel
                  Color(0xFF3A3A3C), // Mid Steel
                  Color(0xFF2C2C2E), // Dark Steel
                ],
                stops: [0.0, 0.3, 0.5, 0.7, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.loose,
              children: [
                // Liquid Shine Effect overlay
                if (widget.enableShine)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      child: CustomPaint(
                        painter: _LiquidShinePainter(_controller.value),
                      ),
                    ),
                  ),
                widget.child,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LiquidShinePainter extends CustomPainter {
  final double progress;

  _LiquidShinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Determine opacity based on progress to fade in/out at edges
    // Fades in during first 15% and out during last 15%
    double opacity = 1.0;
    if (progress < 0.15) {
      opacity = progress / 0.15;
    } else if (progress > 0.85) {
      opacity = (1.0 - progress) / 0.15;
    }

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(progress * 3 - 2, -1),
        end: Alignment(progress * 3 - 1, 1),
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.15 * opacity),
          Colors.white.withValues(alpha: 0.4 * opacity),
          Colors.white.withValues(alpha: 0.15 * opacity),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_LiquidShinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
