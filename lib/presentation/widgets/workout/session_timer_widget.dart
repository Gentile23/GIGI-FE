import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';

/// ═══════════════════════════════════════════════════════════
/// SESSION TIMER WIDGET - Live workout duration with stats
/// Psychology: Progress visibility increases completion rates
/// ═══════════════════════════════════════════════════════════
class SessionTimerWidget extends StatefulWidget {
  final DateTime startTime;
  final int currentExercise;
  final int totalExercises;
  final int estimatedCaloriesPerMinute;
  final bool isPaused;
  final VoidCallback? onPauseTap;

  const SessionTimerWidget({
    super.key,
    required this.startTime,
    required this.currentExercise,
    required this.totalExercises,
    this.estimatedCaloriesPerMinute = 7,
    this.isPaused = false,
    this.onPauseTap,
  });

  @override
  State<SessionTimerWidget> createState() => _SessionTimerWidgetState();
}

class _SessionTimerWidgetState extends State<SessionTimerWidget>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for live indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!widget.isPaused && mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(widget.startTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int get _estimatedCalories =>
      (_elapsed.inMinutes * widget.estimatedCaloriesPerMinute).clamp(0, 9999);

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalExercises > 0
        ? widget.currentExercise / widget.totalExercises
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CleanTheme.surfaceColor.withValues(alpha: 0.9),
            CleanTheme.surfaceColor.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Live indicator + Timer
                Expanded(
                  child: Row(
                    children: [
                      // Live pulse indicator
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: CleanTheme.accentRed.withValues(
                                alpha: _pulseAnimation.value,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: CleanTheme.accentRed.withValues(
                                    alpha: _pulseAnimation.value * 0.5,
                                  ),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      // Timer
                      Text(
                        _formatDuration(_elapsed),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: CleanTheme.textOnPrimary,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats badges
                _buildStatBadge(
                  Icons.local_fire_department_rounded,
                  '$_estimatedCalories',
                  'kcal',
                  CleanTheme.accentOrange,
                ),
                const SizedBox(width: 12),
                _buildStatBadge(
                  Icons.fitness_center_rounded,
                  '${widget.currentExercise}',
                  '/${widget.totalExercises}',
                  CleanTheme.primaryColor,
                ),

                // Pause button (optional)
                if (widget.onPauseTap != null) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: widget.onPauseTap,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CleanTheme.textOnPrimary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isPaused ? Icons.play_arrow : Icons.pause,
                        color: CleanTheme.textOnPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: CleanTheme.textOnPrimary.withValues(
                  alpha: 0.2,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  CleanTheme.accentGreen,
                ),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(
    IconData icon,
    String value,
    String unit,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: CleanTheme.textOnPrimary,
            ),
          ),
          Text(
            unit,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CleanTheme.textOnPrimary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
