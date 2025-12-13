import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/workout_audio_orchestrator.dart';

/// Immersive Coaching Overlay
///
/// Shows what Gigi is saying during workout with:
/// - Animated waveform when speaking
/// - Subtitle text of current cue
/// - Phase indicator (Intro / Rep X / Rest)
/// - Quick mute button
class ImmersiveCoachingOverlay extends StatefulWidget {
  final WorkoutAudioOrchestrator orchestrator;
  final String? currentText;
  final bool isVisible;
  final VoidCallback? onMuteToggle;
  final VoidCallback? onClose;

  const ImmersiveCoachingOverlay({
    super.key,
    required this.orchestrator,
    this.currentText,
    this.isVisible = true,
    this.onMuteToggle,
    this.onClose,
  });

  @override
  State<ImmersiveCoachingOverlay> createState() =>
      _ImmersiveCoachingOverlayState();
}

class _ImmersiveCoachingOverlayState extends State<ImmersiveCoachingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: widget.orchestrator,
      builder: (context, child) {
        final phase = widget.orchestrator.currentPhase;
        if (phase == CoachingPhase.idle) return const SizedBox.shrink();

        return Positioned(
          left: 16,
          right: 16,
          bottom: 120, // Above navigation bar
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CleanTheme.cardColor.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getPhaseColor(phase).withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row
                Row(
                  children: [
                    // Animated wave indicator
                    _buildWaveIndicator(phase),
                    const SizedBox(width: 12),

                    // Phase label
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getPhaseLabel(phase),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getPhaseColor(phase),
                            ),
                          ),
                          if (phase == CoachingPhase.duringRep)
                            Text(
                              'Rep ${widget.orchestrator.currentRep}/${widget.orchestrator.totalReps}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: CleanTheme.textTertiary,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Mute button
                    GestureDetector(
                      onTap:
                          widget.onMuteToggle ??
                          () {
                            widget.orchestrator.toggleMute();
                          },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.orchestrator.isMuted
                              ? CleanTheme.accentRed.withValues(alpha: 0.1)
                              : CleanTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          widget.orchestrator.isMuted
                              ? Icons.volume_off
                              : Icons.volume_up,
                          size: 20,
                          color: widget.orchestrator.isMuted
                              ? CleanTheme.accentRed
                              : CleanTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                // Current text/subtitle
                if (widget.currentText != null &&
                    widget.currentText!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.currentText!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.4,
                      color: CleanTheme.textPrimary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Rest countdown
                if (phase == CoachingPhase.rest) ...[
                  const SizedBox(height: 12),
                  _buildRestCountdown(),
                ],

                // Rep progress
                if (phase == CoachingPhase.duringRep) ...[
                  const SizedBox(height: 12),
                  _buildRepProgress(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveIndicator(CoachingPhase phase) {
    final isActive = phase != CoachingPhase.idle && phase != CoachingPhase.rest;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getPhaseColor(phase).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: isActive
          ? AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _WaveformPainter(
                    progress: _waveController.value,
                    color: _getPhaseColor(phase),
                  ),
                );
              },
            )
          : Icon(
              phase == CoachingPhase.rest ? Icons.timer : Icons.mic,
              color: _getPhaseColor(phase),
              size: 20,
            ),
    );
  }

  Widget _buildRestCountdown() {
    final remaining = widget.orchestrator.restRemaining;
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.timer_outlined, color: CleanTheme.accentBlue, size: 20),
        const SizedBox(width: 8),
        Text(
          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: CleanTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRepProgress() {
    final current = widget.orchestrator.currentRep;
    final total = widget.orchestrator.totalReps;
    final progress = total > 0 ? current / total : 0.0;

    return Column(
      children: [
        // Progress bar
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: CleanTheme.surfaceColor,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: CleanTheme.accentGreen,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$current/$total completate',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: CleanTheme.textTertiary,
          ),
        ),
      ],
    );
  }

  String _getPhaseLabel(CoachingPhase phase) {
    switch (phase) {
      case CoachingPhase.exerciseIntro:
        return '📖 INTRODUZIONE';
      case CoachingPhase.preSet:
        return '🎯 PREPARAZIONE';
      case CoachingPhase.duringRep:
        return '💪 ESECUZIONE';
      case CoachingPhase.postSet:
        return '✅ SET COMPLETATO';
      case CoachingPhase.rest:
        return '⏸️ RIPOSO';
      case CoachingPhase.completed:
        return '🎉 COMPLETATO';
      default:
        return '';
    }
  }

  Color _getPhaseColor(CoachingPhase phase) {
    switch (phase) {
      case CoachingPhase.exerciseIntro:
        return CleanTheme.accentBlue;
      case CoachingPhase.preSet:
        return CleanTheme.accentOrange;
      case CoachingPhase.duringRep:
        return CleanTheme.accentGreen;
      case CoachingPhase.postSet:
        return CleanTheme.accentGreen;
      case CoachingPhase.rest:
        return CleanTheme.accentBlue;
      case CoachingPhase.completed:
        return CleanTheme.primaryColor;
      default:
        return CleanTheme.textSecondary;
    }
  }
}

/// Custom painter for animated waveform
class _WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;

  _WaveformPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final barWidth = 3.0;
    final spacing = 4.0;
    final numBars = 5;
    final totalWidth = numBars * barWidth + (numBars - 1) * spacing;
    final startX = (size.width - totalWidth) / 2;

    for (int i = 0; i < numBars; i++) {
      final x = startX + i * (barWidth + spacing);
      final phase = (progress + i * 0.2) % 1.0;
      final heightFactor =
          0.3 + 0.7 * (0.5 + 0.5 * (phase * 3.14159 * 2).abs().clamp(0.0, 1.0));
      final barHeight = size.height * 0.5 * heightFactor;

      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
