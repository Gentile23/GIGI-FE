import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';

/// Immersive workout scaffold with dark gradient background
class ImmersiveWorkoutScaffold extends StatelessWidget {
  final Widget child;
  final Widget? floatingAction;
  final bool showProgress;
  final double progressValue;
  final VoidCallback? onBack;

  const ImmersiveWorkoutScaffold({
    super.key,
    required this.child,
    this.floatingAction,
    this.showProgress = true,
    this.progressValue = 0.0,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.immersiveDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CleanTheme.immersiveDark,
              CleanTheme.immersiveDarkSecondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticService.lightTap();
                        if (onBack != null) {
                          onBack!();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: CleanTheme.textOnPrimary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: CleanTheme.textOnPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                    if (showProgress) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progressValue,
                            backgroundColor: CleanTheme.textOnPrimary
                                .withValues(alpha: 0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              CleanTheme.immersiveAccent,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ] else
                      const Spacer(),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
      floatingActionButton: floatingAction,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

/// Large exercise timer display
class ImmersiveTimer extends StatelessWidget {
  final String time;
  final String? label;
  final bool isActive;

  const ImmersiveTimer({
    super.key,
    required this.time,
    this.label,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          style: GoogleFonts.outfit(
            fontSize: 72,
            fontWeight: FontWeight.w700,
            color: isActive
                ? CleanTheme.immersiveAccent
                : CleanTheme.textOnPrimary.withValues(alpha: 0.6),
            height: 1,
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: CleanTheme.textOnPrimary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }
}

/// Current exercise card for immersive mode
class ImmersiveExerciseCard extends StatelessWidget {
  final String exerciseName;
  final int currentSet;
  final int totalSets;
  final int targetReps;
  final String? notes;

  const ImmersiveExerciseCard({
    super.key,
    required this.exerciseName,
    required this.currentSet,
    required this.totalSets,
    required this.targetReps,
    this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: CleanTheme.textOnPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CleanTheme.textOnPrimary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exerciseName,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: CleanTheme.textOnPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildChip(
                'Serie',
                '$currentSet/$totalSets',
                CleanTheme.immersiveAccent,
              ),
              const SizedBox(width: 12),
              _buildChip('Reps', '$targetReps', CleanTheme.emotionProgress),
            ],
          ),
          if (notes != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CleanTheme.emotionRecovery.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: CleanTheme.emotionRecovery,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notes!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CleanTheme.textOnPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: CleanTheme.textOnPrimary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Action button for immersive mode
class ImmersiveActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const ImmersiveActionButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.mediumTap();
        onPressed();
      },
      child: Container(
        width: double.infinity,
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isPrimary
              ? CleanTheme.immersiveAccent
              : CleanTheme.textOnPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: CleanTheme.immersiveAccent.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: CleanTheme.textOnPrimary, size: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CleanTheme.textOnPrimary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rest timer between sets
class ImmersiveRestTimer extends StatelessWidget {
  final int secondsRemaining;
  final int totalSeconds;
  final VoidCallback? onSkip;

  const ImmersiveRestTimer({
    super.key,
    required this.secondsRemaining,
    required this.totalSeconds,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (totalSeconds - secondsRemaining) / totalSeconds;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '😤 RIPOSO',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: CleanTheme.textOnPrimary.withValues(alpha: 0.6),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 8,
                  color: CleanTheme.textOnPrimary.withValues(alpha: 0.1),
                ),
              ),
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  color: CleanTheme.emotionRecovery,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$secondsRemaining',
                    style: GoogleFonts.outfit(
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      color: CleanTheme.textOnPrimary,
                    ),
                  ),
                  Text(
                    'secondi',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: CleanTheme.textOnPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        if (onSkip != null)
          GestureDetector(
            onTap: onSkip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: CleanTheme.textOnPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Salta riposo →',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textOnPrimary.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Workout summary card for end of session
class ImmersiveWorkoutSummary extends StatelessWidget {
  final int totalExercises;
  final int totalSets;
  final Duration totalTime;
  final int xpEarned;
  final VoidCallback onComplete;

  const ImmersiveWorkoutSummary({
    super.key,
    required this.totalExercises,
    required this.totalSets,
    required this.totalTime,
    required this.xpEarned,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🎉', style: TextStyle(fontSize: 80)),
        const SizedBox(height: 16),
        Text(
          'WORKOUT COMPLETATO!',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: CleanTheme.textOnPrimary,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: CleanTheme.textOnPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat(
                '⏱️',
                '${totalTime.inMinutes}:${(totalTime.inSeconds % 60).toString().padLeft(2, '0')}',
                'Tempo',
              ),
              _stat('💪', '$totalExercises', 'Esercizi'),
              _stat('🔥', '$totalSets', 'Serie'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CleanTheme.emotionProgress,
                CleanTheme.emotionProgress.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚡', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                '+$xpEarned XP',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: CleanTheme.textOnPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        ImmersiveActionButton(
          text: 'CONTINUA',
          icon: Icons.arrow_forward,
          onPressed: onComplete,
        ),
      ],
    );
  }

  Widget _stat(String emoji, String value, String label) => Column(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 28)),
      const SizedBox(height: 8),
      Text(
        value,
        style: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: CleanTheme.textOnPrimary,
        ),
      ),
      Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: CleanTheme.textOnPrimary.withValues(alpha: 0.6),
        ),
      ),
    ],
  );
}

/// Voice coaching indicator - shows when GIGI is speaking
/// This widget provides visual feedback that reinforces the unique value
/// of real-time voice coaching (key differentiator for GIGI)
class VoiceCoachingIndicator extends StatefulWidget {
  final bool isActive;
  final String? currentMessage;
  final VoidCallback? onTap;

  const VoiceCoachingIndicator({
    super.key,
    this.isActive = false,
    this.currentMessage,
    this.onTap,
  });

  @override
  State<VoiceCoachingIndicator> createState() => _VoiceCoachingIndicatorState();
}

class _VoiceCoachingIndicatorState extends State<VoiceCoachingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isActive) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(VoiceCoachingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _animationController.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: widget.isActive
              ? CleanTheme.primaryColor.withValues(alpha: 0.2)
              : CleanTheme.textOnPrimary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isActive
                ? CleanTheme.primaryColor.withValues(alpha: 0.5)
                : CleanTheme.textOnPrimary.withValues(alpha: 0.1),
            width: widget.isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // GIGI avatar/icon with animation
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? CleanTheme.primaryColor
                        : CleanTheme.textOnPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: widget.isActive
                        ? [
                            BoxShadow(
                              color: CleanTheme.primaryColor.withValues(
                                alpha: 0.3 + (_animationController.value * 0.3),
                              ),
                              blurRadius: 12 + (_animationController.value * 8),
                              spreadRadius: _animationController.value * 4,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    widget.isActive ? Icons.mic : Icons.mic_none,
                    color: CleanTheme.textOnPrimary,
                    size: 22,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            // Voice waveform animation
            if (widget.isActive)
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Row(
                    children: List.generate(5, (index) {
                      final delay = index * 0.15;
                      final height =
                          8 +
                          (12 * (((_animationController.value + delay) % 1)));
                      return Container(
                        width: 3,
                        height: height,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          color: CleanTheme.primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  );
                },
              ),
            const SizedBox(width: 12),
            // Status text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.isActive ? 'GIGI sta parlando' : 'Voice Coaching',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.isActive
                          ? CleanTheme.primaryColor
                          : CleanTheme.textOnPrimary.withValues(alpha: 0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (widget.currentMessage != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.currentMessage!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CleanTheme.textOnPrimary.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Status indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: widget.isActive
                    ? CleanTheme.primaryColor
                    : CleanTheme.textOnPrimary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
