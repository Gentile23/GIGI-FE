import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';

class FoodScaleWidget extends StatefulWidget {
  final Map<String, dynamic> originalFood;
  final Map<String, dynamic> substituteFood;
  final double score;

  const FoodScaleWidget({
    super.key,
    required this.originalFood,
    required this.substituteFood,
    required this.score,
  });

  @override
  State<FoodScaleWidget> createState() => _FoodScaleWidgetState();
}

class _FoodScaleWidgetState extends State<FoodScaleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _tiltAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Subtle tilt animation to make it feel "active"
    _tiltAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.03), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.03, end: -0.03), weight: 100),
      TweenSequenceItem(tween: Tween(begin: -0.03, end: 0.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final centerX = constraints.maxWidth / 2;
        const double beamWidth = 260;

        return AnimatedBuilder(
          animation: _tiltAnimation,
          builder: (context, child) {
            final tilt = _tiltAnimation.value;

            return Column(
              children: [
                SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Base Support
                      Positioned(
                        bottom: 0,
                        child: Container(
                          width: 80,
                          height: 8,
                          decoration: BoxDecoration(
                            color: CleanTheme.steelDark,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: Container(
                          width: 6,
                          height: 120,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [CleanTheme.steelMid, CleanTheme.steelDark],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      
                      // The Pivot
                      Positioned(
                        top: 115,
                        left: centerX - 6,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: CleanTheme.steelDark,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                      // The Beam
                      Positioned(
                        top: 119,
                        left: centerX - (beamWidth / 2),
                        child: Transform.rotate(
                          angle: tilt,
                          child: Container(
                            width: beamWidth,
                            height: 4,
                            decoration: BoxDecoration(
                              color: CleanTheme.steelMid,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),

                      // Left Plate (Original)
                      _buildPlate(
                        isLeft: true,
                        food: widget.originalFood,
                        tilt: tilt,
                        centerX: centerX,
                        beamWidth: beamWidth,
                      ),

                      // Right Plate (Substitute)
                      _buildPlate(
                        isLeft: false,
                        food: widget.substituteFood,
                        tilt: tilt,
                        centerX: centerX,
                        beamWidth: beamWidth,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildScoreIndicator(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPlate({
    required bool isLeft,
    required Map<String, dynamic> food,
    required double tilt,
    required double centerX,
    required double beamWidth,
  }) {
    const double plateWidth = 130;
    final double xOffset = isLeft ? -beamWidth / 2 : beamWidth / 2;
    // Calculate vertical movement due to tilt
    final double yOffset = xOffset * sin(tilt);

    return Positioned(
      left: centerX + xOffset - (plateWidth / 2),
      top: 120 + yOffset,
      child: Column(
        children: [
          // Rope to plate
          Container(width: 1.5, height: 30, color: CleanTheme.chromeGray),
          Container(
            width: plateWidth,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isLeft 
                    ? CleanTheme.borderSecondary 
                    : CleanTheme.accentOrange.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  isLeft ? 'ORIGINALE' : 'SOSTITUTO',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: CleanTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  food['name'] ?? 'Alimento',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(food['quantity'] as num?)?.round() ?? 0}g',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isLeft ? CleanTheme.textPrimary : CleanTheme.accentOrange,
                  ),
                ),
                const SizedBox(height: 6),
                _buildMiniMacros(food),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMacros(Map<String, dynamic> food) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _macroDot(CleanTheme.accentGreen),
        const SizedBox(width: 4),
        _macroDot(CleanTheme.accentGold),
        const SizedBox(width: 4),
        _macroDot(CleanTheme.accentBlue),
        const SizedBox(width: 8),
        Text(
          '${(food['calories'] ?? food['kcal'] ?? 0).toInt()} kcal',
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _macroDot(Color color) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildScoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [CleanTheme.steelDark, CleanTheme.primaryColor],
        ),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.balance_rounded,
            color: widget.score > 70 ? CleanTheme.accentGreen : CleanTheme.accentGold,
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            'COMPATIBILITÀ: ${widget.score.toInt()}%',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
