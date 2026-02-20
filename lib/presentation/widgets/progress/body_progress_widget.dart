import 'package:flutter/material.dart';

import '../../../core/theme/clean_theme.dart';

/// Widget per visualizzare silhouette corporea con muscoli lavorati
class BodyProgressVisualization extends StatefulWidget {
  final Map<String, double> muscleActivity;
  final Map<String, MuscleRecoveryState> recoveryState;

  const BodyProgressVisualization({
    super.key,
    required this.muscleActivity,
    required this.recoveryState,
  });

  @override
  State<BodyProgressVisualization> createState() =>
      _BodyProgressVisualizationState();
}

class _BodyProgressVisualizationState extends State<BodyProgressVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  String? _selectedMuscle;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mappa Muscolare',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              _buildLegend(),
            ],
          ),

          const SizedBox(height: 20),

          // Body visualization
          Row(
            children: [
              // Front view
              Expanded(child: _buildBodyView(isFront: true)),
              const SizedBox(width: 16),
              // Back view
              Expanded(child: _buildBodyView(isFront: false)),
            ],
          ),

          // Selected muscle info
          if (_selectedMuscle != null) ...[
            const SizedBox(height: 16),
            _buildMuscleInfo(_selectedMuscle!),
          ],

          const SizedBox(height: 16),

          // Recovery status summary
          _buildRecoverySummary(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLegendItem('Attivo', CleanTheme.accentGreen),
        const SizedBox(width: 8),
        _buildLegendItem('Recupero', Colors.amber),
        const SizedBox(width: 8),
        _buildLegendItem('Riposo', Colors.red),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildBodyView({required bool isFront}) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Column(
          children: [
            Text(
              isFront ? 'Anteriore' : 'Posteriore',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: CustomPaint(
                painter: _BodyPainter(
                  muscleActivity: widget.muscleActivity,
                  recoveryState: widget.recoveryState,
                  isFront: isFront,
                  pulseValue: _pulseController.value,
                ),
                size: const Size(100, 200),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMuscleInfo(String muscle) {
    final activity = widget.muscleActivity[muscle] ?? 0;
    final recovery = widget.recoveryState[muscle] ?? MuscleRecoveryState.rested;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRecoveryColor(recovery).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fitness_center,
              color: _getRecoveryColor(recovery),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  muscle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _getRecoveryText(recovery),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getRecoveryColor(recovery),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(activity * 100).toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'attività',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecoverySummary() {
    int rested = 0, recovering = 0, fatigued = 0;

    for (final state in widget.recoveryState.values) {
      switch (state) {
        case MuscleRecoveryState.rested:
          rested++;
          break;
        case MuscleRecoveryState.recovering:
          recovering++;
          break;
        case MuscleRecoveryState.fatigued:
          fatigued++;
          break;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildRecoveryCounter('Pronti', rested, CleanTheme.accentGreen),
        _buildRecoveryCounter('Recupero', recovering, Colors.amber),
        _buildRecoveryCounter('Riposo', fatigued, Colors.red),
      ],
    );
  }

  Widget _buildRecoveryCounter(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
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

  Color _getRecoveryColor(MuscleRecoveryState state) {
    switch (state) {
      case MuscleRecoveryState.rested:
        return CleanTheme.accentGreen;
      case MuscleRecoveryState.recovering:
        return Colors.amber;
      case MuscleRecoveryState.fatigued:
        return Colors.red;
    }
  }

  String _getRecoveryText(MuscleRecoveryState state) {
    switch (state) {
      case MuscleRecoveryState.rested:
        return 'Pronto per allenamento';
      case MuscleRecoveryState.recovering:
        return 'In recupero (~24h)';
      case MuscleRecoveryState.fatigued:
        return 'Necessita riposo (~48h)';
    }
  }
}

enum MuscleRecoveryState { rested, recovering, fatigued }

class _BodyPainter extends CustomPainter {
  final Map<String, double> muscleActivity;
  final Map<String, MuscleRecoveryState> recoveryState;
  final bool isFront;
  final double pulseValue;

  _BodyPainter({
    required this.muscleActivity,
    required this.recoveryState,
    required this.isFront,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    // Draw body outline
    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Simplified body shape
    final bodyPath = Path();

    // Head
    canvas.drawCircle(
      Offset(centerX, size.height * 0.08),
      size.width * 0.12,
      outlinePaint,
    );

    // Neck
    bodyPath.moveTo(centerX - 8, size.height * 0.14);
    bodyPath.lineTo(centerX + 8, size.height * 0.14);

    // Shoulders
    bodyPath.moveTo(centerX - 35, size.height * 0.18);
    bodyPath.lineTo(centerX + 35, size.height * 0.18);

    // Torso
    bodyPath.moveTo(centerX - 30, size.height * 0.18);
    bodyPath.lineTo(centerX - 25, size.height * 0.50);
    bodyPath.lineTo(centerX + 25, size.height * 0.50);
    bodyPath.lineTo(centerX + 30, size.height * 0.18);

    canvas.drawPath(bodyPath, outlinePaint);

    // Draw muscle groups with activity
    _drawMuscleGroup(
      canvas,
      'Petto',
      Rect.fromCenter(
        center: Offset(centerX, size.height * 0.28),
        width: 40,
        height: 25,
      ),
      isFront,
    );

    _drawMuscleGroup(
      canvas,
      'Spalle',
      Rect.fromCenter(
        center: Offset(centerX - 32, size.height * 0.20),
        width: 15,
        height: 20,
      ),
      isFront,
    );

    _drawMuscleGroup(
      canvas,
      'Spalle',
      Rect.fromCenter(
        center: Offset(centerX + 32, size.height * 0.20),
        width: 15,
        height: 20,
      ),
      isFront,
    );

    _drawMuscleGroup(
      canvas,
      'Bicipiti',
      Rect.fromCenter(
        center: Offset(centerX - 40, size.height * 0.32),
        width: 12,
        height: 25,
      ),
      isFront,
    );

    _drawMuscleGroup(
      canvas,
      'Bicipiti',
      Rect.fromCenter(
        center: Offset(centerX + 40, size.height * 0.32),
        width: 12,
        height: 25,
      ),
      isFront,
    );

    _drawMuscleGroup(
      canvas,
      'Addominali',
      Rect.fromCenter(
        center: Offset(centerX, size.height * 0.40),
        width: 30,
        height: 35,
      ),
      isFront,
    );

    _drawMuscleGroup(
      canvas,
      'Quadricipiti',
      Rect.fromCenter(
        center: Offset(centerX - 15, size.height * 0.65),
        width: 18,
        height: 50,
      ),
      isFront,
    );

    _drawMuscleGroup(
      canvas,
      'Quadricipiti',
      Rect.fromCenter(
        center: Offset(centerX + 15, size.height * 0.65),
        width: 18,
        height: 50,
      ),
      isFront,
    );
  }

  void _drawMuscleGroup(
    Canvas canvas,
    String name,
    Rect rect,
    bool shouldShow,
  ) {
    if (!shouldShow && !isFront) return;
    if (shouldShow && isFront) return;

    final activity = muscleActivity[name] ?? 0.3;
    final recovery = recoveryState[name] ?? MuscleRecoveryState.rested;

    Color baseColor;
    switch (recovery) {
      case MuscleRecoveryState.rested:
        baseColor = CleanTheme.accentGreen;
        break;
      case MuscleRecoveryState.recovering:
        baseColor = Colors.amber;
        break;
      case MuscleRecoveryState.fatigued:
        baseColor = Colors.red;
        break;
    }

    final opacity = 0.3 + (activity * 0.5) + (pulseValue * 0.2 * activity);

    final paint = Paint()
      ..color = baseColor.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(5));
    canvas.drawRRect(rrect, paint);

    // Border
    final borderPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _BodyPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}

/// Widget compatto per mostrare muscle heat map
class MuscleHeatmapCompact extends StatelessWidget {
  final Map<String, double> activity;

  const MuscleHeatmapCompact({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final sortedMuscles = activity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.steelDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Muscoli Più Allenati',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedMuscles
              .take(5)
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildMuscleBar(entry.key, entry.value),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildMuscleBar(String name, double value) {
    final color = Color.lerp(Colors.blue, Colors.red, value)!;

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            name,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(value * 100).toInt()}%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
