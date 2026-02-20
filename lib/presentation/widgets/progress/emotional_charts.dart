import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';

/// Grafico emotivo dei progressi con narrativa
class EmotionalProgressChart extends StatefulWidget {
  final List<ProgressDataPoint> dataPoints;
  final String title;
  final String? narrative;
  final Color? color;

  const EmotionalProgressChart({
    super.key,
    required this.dataPoints,
    required this.title,
    this.narrative,
    this.color,
  });

  @override
  State<EmotionalProgressChart> createState() => _EmotionalProgressChartState();
}

class _EmotionalProgressChartState extends State<EmotionalProgressChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _drawAnimation;
  int? _highlightedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _drawAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? CleanTheme.accentGold;
    final maxValue = widget.dataPoints.map((p) => p.value).reduce(math.max);
    final minValue = widget.dataPoints.map((p) => p.value).reduce(math.min);
    final personalBestIndex = widget.dataPoints.indexWhere(
      (p) => p.value == maxValue && p.isPersonalBest,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CleanTheme.steelDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (personalBestIndex >= 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: CleanTheme.accentGold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: CleanTheme.accentGold.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🏆', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text(
                        'Personal Best!',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Narrative
          if (widget.narrative != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.narrative!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Chart
          SizedBox(
            height: 150,
            child: AnimatedBuilder(
              animation: _drawAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ChartPainter(
                    dataPoints: widget.dataPoints,
                    progress: _drawAnimation.value,
                    color: color,
                    highlightedIndex: _highlightedIndex,
                    maxValue: maxValue,
                    minValue: minValue,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),

          // Labels
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: widget.dataPoints.map((point) {
              return Text(
                point.label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              );
            }).toList(),
          ),

          // Stats summary
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Max', maxValue.toStringAsFixed(1), color),
              _buildStatItem('Min', minValue.toStringAsFixed(1), Colors.grey),
              _buildStatItem('Trend', _calculateTrend(), _getTrendColor()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  String _calculateTrend() {
    if (widget.dataPoints.length < 2) return '—';
    final first = widget.dataPoints.first.value;
    final last = widget.dataPoints.last.value;
    final change = ((last - first) / first * 100).toStringAsFixed(1);
    if (last > first) return '+$change%';
    return '$change%';
  }

  Color _getTrendColor() {
    if (widget.dataPoints.length < 2) return Colors.grey;
    final first = widget.dataPoints.first.value;
    final last = widget.dataPoints.last.value;
    return last >= first ? CleanTheme.accentGreen : Colors.red;
  }
}

class _ChartPainter extends CustomPainter {
  final List<ProgressDataPoint> dataPoints;
  final double progress;
  final Color color;
  final int? highlightedIndex;
  final double maxValue;
  final double minValue;

  _ChartPainter({
    required this.dataPoints,
    required this.progress,
    required this.color,
    this.highlightedIndex,
    required this.maxValue,
    required this.minValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final range = maxValue - minValue;
    final effectiveRange = range == 0 ? 1 : range;

    // Draw grid
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Calculate points
    final points = <Offset>[];
    final spacing = size.width / (dataPoints.length - 1);

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * spacing;
      final normalizedValue = (dataPoints[i].value - minValue) / effectiveRange;
      final y =
          size.height -
          (normalizedValue * size.height * 0.9 + size.height * 0.05);
      points.add(Offset(x, y));
    }

    // Draw gradient fill
    if (points.length > 1) {
      final fillPath = Path();
      final animatedLength = (points.length * progress).floor();

      if (animatedLength > 0) {
        fillPath.moveTo(points[0].dx, size.height);
        fillPath.lineTo(points[0].dx, points[0].dy);

        for (int i = 1; i < animatedLength; i++) {
          fillPath.lineTo(points[i].dx, points[i].dy);
        }

        if (animatedLength > 0 && animatedLength < points.length) {
          final lastPoint = points[animatedLength - 1];
          fillPath.lineTo(lastPoint.dx, size.height);
        } else if (animatedLength > 0) {
          fillPath.lineTo(points[animatedLength - 1].dx, size.height);
        }

        fillPath.close();

        final fillPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

        canvas.drawPath(fillPath, fillPaint);
      }
    }

    // Draw line
    if (points.length > 1) {
      final linePath = Path();
      linePath.moveTo(points[0].dx, points[0].dy);

      final animatedLength = (points.length * progress).floor();
      for (int i = 1; i < animatedLength && i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }

      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(linePath, linePaint);
    }

    // Draw points
    final animatedLength = (points.length * progress).floor();
    for (int i = 0; i < animatedLength && i < points.length; i++) {
      final isPersonalBest = dataPoints[i].isPersonalBest;
      final pointColor = isPersonalBest ? const Color(0xFFFFD700) : color;
      final radius = isPersonalBest ? 8.0 : 5.0;

      // Outer glow for personal best
      if (isPersonalBest) {
        final glowPaint = Paint()
          ..color = pointColor.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(points[i], 12, glowPaint);
      }

      // Point
      final pointPaint = Paint()
        ..color = pointColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points[i], radius, pointPaint);

      // Inner white dot
      final innerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points[i], radius * 0.4, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.highlightedIndex != highlightedIndex;
  }
}

class ProgressDataPoint {
  final String label;
  final double value;
  final bool isPersonalBest;
  final DateTime? date;

  ProgressDataPoint({
    required this.label,
    required this.value,
    this.isPersonalBest = false,
    this.date,
  });
}

/// Widget per radar chart delle forze muscolari
class StrengthRadarChart extends StatefulWidget {
  final Map<String, double> muscleStrength;
  final double size;

  const StrengthRadarChart({
    super.key,
    required this.muscleStrength,
    this.size = 200,
  });

  @override
  State<StrengthRadarChart> createState() => _StrengthRadarChartState();
}

class _StrengthRadarChartState extends State<StrengthRadarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CleanTheme.steelDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            'Bilancio Muscolare',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RadarChartPainter(
                  muscleStrength: widget.muscleStrength,
                  progress: _controller.value,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: widget.muscleStrength.keys.map((muscle) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: CleanTheme.accentGold,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    muscle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final Map<String, double> muscleStrength;
  final double progress;

  _RadarChartPainter({required this.muscleStrength, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    final labels = muscleStrength.keys.toList();
    final values = muscleStrength.values.toList();
    final angleStep = 2 * math.pi / labels.length;

    // Draw grid circles
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, radius * i / 5, gridPaint);
    }

    // Draw grid lines
    for (int i = 0; i < labels.length; i++) {
      final angle = -math.pi / 2 + angleStep * i;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), gridPaint);
    }

    // Draw data polygon
    if (values.isNotEmpty) {
      final dataPath = Path();
      final gradientPath = Path();

      for (int i = 0; i < values.length; i++) {
        final angle = -math.pi / 2 + angleStep * i;
        final value = values[i].clamp(0.0, 1.0) * progress;
        final x = center.dx + radius * value * math.cos(angle);
        final y = center.dy + radius * value * math.sin(angle);

        if (i == 0) {
          dataPath.moveTo(x, y);
          gradientPath.moveTo(x, y);
        } else {
          dataPath.lineTo(x, y);
          gradientPath.lineTo(x, y);
        }
      }

      dataPath.close();
      gradientPath.close();

      // Fill
      final fillPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            CleanTheme.accentGold.withValues(alpha: 0.4),
            CleanTheme.accentGold.withValues(alpha: 0.1),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawPath(gradientPath, fillPaint);

      // Stroke
      final strokePaint = Paint()
        ..color = CleanTheme.accentGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(dataPath, strokePaint);

      // Points
      for (int i = 0; i < values.length; i++) {
        final angle = -math.pi / 2 + angleStep * i;
        final value = values[i].clamp(0.0, 1.0) * progress;
        final x = center.dx + radius * value * math.cos(angle);
        final y = center.dy + radius * value * math.sin(angle);

        final pointPaint = Paint()
          ..color = CleanTheme.accentGold
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 4, pointPaint);
      }
    }

    // Draw labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < labels.length; i++) {
      final angle = -math.pi / 2 + angleStep * i;
      final labelRadius = radius + 15;
      final x = center.dx + labelRadius * math.cos(angle);
      final y = center.dy + labelRadius * math.sin(angle);

      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 10,
        ),
      );
      textPainter.layout();

      final offset = Offset(
        x - textPainter.width / 2,
        y - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Widget per confronto before/after con slider
class BeforeAfterSlider extends StatefulWidget {
  final String beforeLabel;
  final String afterLabel;
  final double beforeValue;
  final double afterValue;
  final String unit;
  final String? narrative;

  const BeforeAfterSlider({
    super.key,
    required this.beforeLabel,
    required this.afterLabel,
    required this.beforeValue,
    required this.afterValue,
    this.unit = '',
    this.narrative,
  });

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  double _sliderValue = 0.5;

  @override
  Widget build(BuildContext context) {
    final change = widget.afterValue - widget.beforeValue;
    final percentChange = (change / widget.beforeValue * 100).abs();
    final isPositive = change > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CleanTheme.steelDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prima vs Dopo',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPositive
                      ? CleanTheme.accentGreen.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${percentChange.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: isPositive ? CleanTheme.accentGreen : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          if (widget.narrative != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.narrative!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Values display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildValueColumn(
                widget.beforeLabel,
                widget.beforeValue,
                opacity: 1 - _sliderValue,
              ),
              Icon(
                Icons.arrow_forward,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildValueColumn(
                widget.afterLabel,
                widget.afterValue,
                opacity: _sliderValue,
                highlight: true,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              activeTrackColor: CleanTheme.accentGold,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
              thumbColor: CleanTheme.accentGold,
              overlayColor: CleanTheme.accentGold.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _sliderValue,
              onChanged: (value) {
                setState(() => _sliderValue = value);
                HapticService.selectionClick();
              },
            ),
          ),

          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.beforeLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              Text(
                widget.afterLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueColumn(
    String label,
    double value, {
    double opacity = 1.0,
    bool highlight = false,
  }) {
    return Opacity(
      opacity: 0.3 + opacity * 0.7,
      child: Column(
        children: [
          Text(
            '${value.toStringAsFixed(1)}${widget.unit}',
            style: TextStyle(
              fontSize: highlight ? 32 : 28,
              fontWeight: FontWeight.bold,
              color: highlight ? CleanTheme.accentGreen : Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
