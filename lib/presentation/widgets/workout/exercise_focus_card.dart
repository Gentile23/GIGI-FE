import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';
import '../../../data/models/workout_model.dart';

/// ═══════════════════════════════════════════════════════════
/// EXERCISE FOCUS CARD - Full-screen focused exercise display
/// Psychology: Single-task focus increases engagement and completion
/// ═══════════════════════════════════════════════════════════
class ExerciseFocusCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final int currentSet;
  final int totalSets;
  final bool isActive;
  final VoidCallback? onStartWithGigi;
  final VoidCallback? onInfoTap;
  final VoidCallback? onSkip;

  const ExerciseFocusCard({
    super.key,
    required this.exercise,
    required this.currentSet,
    required this.totalSets,
    this.isActive = true,
    this.onStartWithGigi,
    this.onInfoTap,
    this.onSkip,
  });

  @override
  State<ExerciseFocusCard> createState() => _ExerciseFocusCardState();
}

class _ExerciseFocusCardState extends State<ExerciseFocusCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _breatheController;
  late Animation<double> _breatheAnimation;

  @override
  void initState() {
    super.initState();

    // Subtle breathing animation for the card border
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _breatheAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise.exercise;
    final muscleGroups = exercise.muscleGroups.take(3).join(' • ');

    return AnimatedBuilder(
      animation: _breatheAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: CleanTheme.primaryColor.withValues(
                alpha: widget.isActive ? _breatheAnimation.value : 0.3,
              ),
              width: 2,
            ),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: CleanTheme.primaryColor.withValues(
                        alpha: _breatheAnimation.value * 0.3,
                      ),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with difficulty badge
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    _buildDifficultyBadge(exercise.difficulty),
                    const Spacer(),
                    if (widget.onInfoTap != null)
                      GestureDetector(
                        onTap: () {
                          HapticService.lightTap();
                          widget.onInfoTap?.call();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Exercise video/image placeholder - compact
              Container(
                height: 100,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    Icons.fitness_center,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Exercise name
              Text(
                exercise.name.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              // Muscle groups
              Text(
                muscleGroups,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: CleanTheme.accentBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 16),

              // Set indicator dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.totalSets, (index) {
                  final isCompleted = index < widget.currentSet - 1;
                  final isCurrent = index == widget.currentSet - 1;

                  return Container(
                    width: isCurrent ? 24 : 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: isCompleted
                          ? CleanTheme.accentGreen
                          : isCurrent
                          ? CleanTheme.primaryColor
                          : Colors.white.withValues(alpha: 0.2),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: CleanTheme.primaryColor.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // Set info
              Text(
                'SERIE ${widget.currentSet} di ${widget.totalSets}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 16),

              // Reps and rest info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatPill(
                    Icons.repeat,
                    '${widget.exercise.reps}',
                    'reps',
                  ),
                  const SizedBox(width: 12),
                  _buildStatPill(
                    Icons.timer_outlined,
                    '${widget.exercise.restSeconds}s',
                    'rest',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Notes (if any)
              if (widget.exercise.notes != null &&
                  widget.exercise.notes!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CleanTheme.accentOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CleanTheme.accentOrange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: CleanTheme.accentOrange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.exercise.notes!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Skip button for cardio/mobility
              if (widget.onSkip != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: GestureDetector(
                    onTap: () {
                      HapticService.lightTap();
                      widget.onSkip?.call();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.skip_next,
                            color: Colors.white70,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Salta esercizio',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDifficultyBadge(ExerciseDifficulty difficulty) {
    Color color;
    String label;

    switch (difficulty) {
      case ExerciseDifficulty.beginner:
        color = CleanTheme.accentGreen;
        label = 'FACILE';
        break;
      case ExerciseDifficulty.intermediate:
        color = CleanTheme.accentOrange;
        label = 'MEDIO';
        break;
      case ExerciseDifficulty.advanced:
        color = CleanTheme.accentRed;
        label = 'HARD';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildStatPill(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white60, size: 18),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}
