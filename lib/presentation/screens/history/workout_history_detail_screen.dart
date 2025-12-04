import 'package:flutter/material.dart';
import 'package:fitgenius/core/constants/app_colors.dart';
import 'package:fitgenius/core/constants/app_text_styles.dart';
import 'package:fitgenius/data/models/workout_log_model.dart';
import 'package:fitgenius/presentation/screens/history/exercise_history_screen.dart';
import 'package:intl/intl.dart';

class WorkoutHistoryDetailScreen extends StatelessWidget {
  final WorkoutLog workoutLog;

  const WorkoutHistoryDetailScreen({super.key, required this.workoutLog});

  @override
  Widget build(BuildContext context) {
    final date = workoutLog.completedAt ?? workoutLog.startedAt;
    final dateStr = DateFormat('EEEE, MMM d, yyyy').format(date);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(dateStr),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Stats
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.neonGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    workoutLog.workoutDay?.name ?? 'Workout Session',
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.background,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHeaderStat(
                        Icons.timer,
                        workoutLog.durationFormatted,
                        'Duration',
                      ),
                      _buildHeaderStat(
                        Icons.fitness_center,
                        '${workoutLog.totalVolume.toInt()} kg',
                        'Volume',
                      ),
                      _buildHeaderStat(
                        Icons.check_circle_outline,
                        '${workoutLog.totalExercises}',
                        'Exercises',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text('Exercises', style: AppTextStyles.h5),
            const SizedBox(height: 12),

            // Exercise List
            ...workoutLog.exerciseLogs.map((exerciseLog) {
              return _buildExerciseCard(context, exerciseLog);
            }),

            if (workoutLog.notes != null && workoutLog.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Notes', style: AppTextStyles.h5),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  workoutLog.notes!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.background, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.h6.copyWith(
            color: AppColors.background,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.background.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    ExerciseLogModel exerciseLog,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExerciseHistoryScreen(
                exerciseId: exerciseLog.exerciseId,
                exerciseName: exerciseLog.exercise?.name ?? 'Exercise',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exerciseLog.exercise?.name ?? 'Unknown Exercise',
                      style: AppTextStyles.h6,
                    ),
                  ),
                  Text(
                    '${exerciseLog.totalVolume.toInt()} kg',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Sets Table
              Table(
                columnWidths: const {
                  0: FixedColumnWidth(40),
                  1: FlexColumnWidth(),
                  2: FlexColumnWidth(),
                  3: FixedColumnWidth(40),
                },
                children: [
                  TableRow(
                    children: [
                      Text(
                        'Set',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'kg',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Reps',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'RPE',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const TableRow(
                    children: [
                      SizedBox(height: 8),
                      SizedBox(height: 8),
                      SizedBox(height: 8),
                      SizedBox(height: 8),
                    ],
                  ),
                  ...exerciseLog.setLogs.map((set) {
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${set.setNumber}',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${set.weightKg ?? '-'}',
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${set.reps}',
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${set.rpe ?? '-'}',
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
