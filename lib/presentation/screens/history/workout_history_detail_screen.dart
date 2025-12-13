import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gigi/core/theme/clean_theme.dart';
import 'package:gigi/presentation/widgets/clean_widgets.dart';
import 'package:gigi/data/models/workout_log_model.dart';
import 'package:gigi/presentation/screens/history/exercise_history_screen.dart';
import 'package:intl/intl.dart';

class WorkoutHistoryDetailScreen extends StatelessWidget {
  final WorkoutLog workoutLog;

  const WorkoutHistoryDetailScreen({super.key, required this.workoutLog});

  @override
  Widget build(BuildContext context) {
    final date = workoutLog.completedAt ?? workoutLog.startedAt;
    final dateStr = DateFormat('EEEE, d MMM yyyy', 'it').format(date);

    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          dateStr,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Stats
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CleanTheme.primaryColor,
                    CleanTheme.primaryColor.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    workoutLog.workoutDay?.name ?? 'Sessione Allenamento',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderStat(
                        Icons.timer_outlined,
                        workoutLog.durationFormatted,
                        'Durata',
                      ),
                      _buildHeaderStat(
                        Icons.fitness_center_outlined,
                        '${workoutLog.totalVolume.toInt()} kg',
                        'Volume',
                      ),
                      _buildHeaderStat(
                        Icons.check_circle_outline,
                        '${workoutLog.totalExercises}',
                        'Esercizi',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            CleanSectionHeader(title: 'Esercizi'),
            const SizedBox(height: 12),

            // Exercise List
            ...workoutLog.exerciseLogs.map((exerciseLog) {
              return _buildExerciseCard(context, exerciseLog);
            }),

            if (workoutLog.notes != null && workoutLog.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              CleanSectionHeader(title: 'Note'),
              const SizedBox(height: 12),
              CleanCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  workoutLog.notes!,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: CleanTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    ExerciseLogModel exerciseLog,
  ) {
    return CleanCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseHistoryScreen(
              exerciseId: exerciseLog.exerciseId,
              exerciseName: exerciseLog.exercise?.name ?? 'Esercizio',
            ),
          ),
        );
      },
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exerciseLog.exercise?.name ?? 'Esercizio Sconosciuto',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: CleanTheme.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${exerciseLog.totalVolume.toInt()} kg',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Sets Table Header
          Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  'Set',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CleanTheme.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'kg',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CleanTheme.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'Reps',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CleanTheme.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  'RPE',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CleanTheme.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: CleanTheme.borderPrimary),
          // Sets Data
          ...exerciseLog.setLogs.map((set) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${set.setNumber}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${set.weightKg ?? '-'}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CleanTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${set.reps}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CleanTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${set.rpe ?? '-'}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CleanTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
