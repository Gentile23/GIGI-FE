import 'package:flutter/material.dart';
import '../../../core/theme/clean_theme.dart';

/// Pulsating dot indicator for first-time user guidance
/// Draws attention to specific UI elements
class PulsatingDot extends StatefulWidget {
  final double size;
  final Color? color;
  final bool showPulse;

  const PulsatingDot({
    super.key,
    this.size = 12,
    this.color,
    this.showPulse = true,
  });

  @override
  State<PulsatingDot> createState() => _PulsatingDotState();
}

class _PulsatingDotState extends State<PulsatingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 2.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(
      begin: 0.6,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.showPulse) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(PulsatingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showPulse && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.showPulse && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.color ?? CleanTheme.accentRed;

    return SizedBox(
      width: widget.size * 3,
      height: widget.size * 3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing ring
          if (widget.showPulse)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: widget.size * _scaleAnimation.value,
                  height: widget.size * _scaleAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: dotColor.withValues(
                        alpha: _opacityAnimation.value,
                      ),
                      width: 2,
                    ),
                  ),
                );
              },
            ),

          // Solid dot
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Wrapper to add a pulsating dot indicator to any widget
class WithPulsatingDot extends StatelessWidget {
  final Widget child;
  final bool show;
  final Alignment alignment;
  final double dotSize;
  final Color? dotColor;

  const WithPulsatingDot({
    super.key,
    required this.child,
    this.show = true,
    this.alignment = Alignment.topRight,
    this.dotSize = 10,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: alignment == Alignment.topRight || alignment == Alignment.topLeft
              ? -dotSize / 2
              : null,
          bottom:
              alignment == Alignment.bottomRight ||
                  alignment == Alignment.bottomLeft
              ? -dotSize / 2
              : null,
          right:
              alignment == Alignment.topRight ||
                  alignment == Alignment.bottomRight
              ? -dotSize / 2
              : null,
          left:
              alignment == Alignment.topLeft ||
                  alignment == Alignment.bottomLeft
              ? -dotSize / 2
              : null,
          child: PulsatingDot(size: dotSize, color: dotColor),
        ),
      ],
    );
  }
}
