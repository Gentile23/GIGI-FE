import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../../../core/theme/clean_theme.dart';
import 'package:gigi/l10n/app_localizations.dart';

/// Data class for workout summary statistics
class WorkoutSummaryData {
  final String workoutName;
  final Duration duration;
  final int completedExercises;
  final int totalExercises;
  final int estimatedCalories;
  final int completedSets;
  final List<String> muscleGroupsWorked;

  WorkoutSummaryData({
    required this.workoutName,
    required this.duration,
    required this.completedExercises,
    required this.totalExercises,
    required this.estimatedCalories,
    required this.completedSets,
    required this.muscleGroupsWorked,
  });

  double get completionPercentage =>
      totalExercises > 0 ? (completedExercises / totalExercises) * 100 : 0;

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

/// Full-screen workout summary shown after finishing a session
class WorkoutSummaryScreen extends StatefulWidget {
  final WorkoutSummaryData summaryData;

  const WorkoutSummaryScreen({super.key, required this.summaryData});

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    // Play confetti if they completed at least one exercise
    if (widget.summaryData.completedExercises > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confettiController.play();
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.summaryData;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  CleanTheme.primaryColor.withValues(alpha: 0.15),
                  CleanTheme.backgroundColor,
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Trophy/Success Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CleanTheme.primaryColor,
                          CleanTheme.accentPurple,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: CleanTheme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    data.completedExercises > 0
                        ? l10n.workoutCompletedTitle
                        : 'Sessione Terminata',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: CleanTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.workoutName,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: CleanTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Main Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.timer_outlined,
                          value: data.formattedDuration,
                          label: l10n.durationLabel,
                          color: CleanTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.local_fire_department_rounded,
                          value: '${data.estimatedCalories}',
                          label: l10n.caloriesLabel,
                          color: CleanTheme.accentOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.fitness_center_rounded,
                          value:
                              '${data.completedExercises}/${data.totalExercises}',
                          label: l10n.exercisesLabel,
                          color: CleanTheme.accentGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.repeat_rounded,
                          value: '${data.completedSets}',
                          label: l10n.totalSetsLabel,
                          color: CleanTheme.accentBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Completion Progress
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: CleanTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: CleanTheme.borderPrimary),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Completamento',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: CleanTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '${data.completionPercentage.toStringAsFixed(0)}%',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: CleanTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: data.completionPercentage / 100,
                            backgroundColor: CleanTheme.primaryColor.withValues(
                              alpha: 0.15,
                            ),
                            valueColor: AlwaysStoppedAnimation(
                              data.completionPercentage >= 100
                                  ? CleanTheme.accentGreen
                                  : CleanTheme.primaryColor,
                            ),
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Muscle Groups Worked
                  if (data.muscleGroupsWorked.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: CleanTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: CleanTheme.borderPrimary),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Muscoli Allenati',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: CleanTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: data.muscleGroupsWorked.map((muscle) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: CleanTheme.primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: CleanTheme.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  muscle,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: CleanTheme.primaryColor,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Motivational Message
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CleanTheme.accentPurple.withValues(alpha: 0.15),
                          CleanTheme.primaryColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('💪', style: TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(
                          _getMotivationalMessage(data),
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: CleanTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Done Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CleanTheme.primaryColor,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: Text(
                        'Chiudi',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [
                CleanTheme.primaryColor,
                CleanTheme.accentGreen,
                CleanTheme.accentOrange,
                CleanTheme.accentPurple,
                CleanTheme.accentBlue,
              ],
              numberOfParticles: 30,
              gravity: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CleanTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getMotivationalMessage(WorkoutSummaryData data) {
    if (data.completionPercentage >= 100) {
      return 'Allenamento completato al 100%! Sei una macchina! 🔥';
    } else if (data.completionPercentage >= 75) {
      return 'Ottimo lavoro! Hai dato il massimo oggi!';
    } else if (data.completionPercentage >= 50) {
      return 'Buon allenamento! Ogni passo conta verso i tuoi obiettivi.';
    } else if (data.completedExercises > 0) {
      return 'Hai iniziato e questo è già un successo! Continua così!';
    } else {
      return 'Preparazione completata. La prossima volta spacchi tutto! 💪';
    }
  }
}
