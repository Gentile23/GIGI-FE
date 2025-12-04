import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/workout_model.dart';
import '../../widgets/workout/exercise_video_player.dart';
import '../../widgets/workout/dual_anatomical_view.dart';

class MobilityExerciseScreen extends StatefulWidget {
  final List<WorkoutExercise> mobilityExercises;
  final String title;
  final VoidCallback? onComplete;

  const MobilityExerciseScreen({
    super.key,
    required this.mobilityExercises,
    required this.title,
    this.onComplete,
  });

  @override
  State<MobilityExerciseScreen> createState() => _MobilityExerciseScreenState();
}

class _MobilityExerciseScreenState extends State<MobilityExerciseScreen> {
  final Set<String> _completedExercises = {};
  final Set<String> _skippedExercises = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF00CED1), // Cyan
      ),
      body: Column(
        children: [
          // Distinct Header with Counter
          Container(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF00CED1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00CED1).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: AppTextStyles.h4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.self_improvement,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mobilità',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Large Counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_completedExercises.length}',
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 4),
                      child: Text(
                        '/${widget.mobilityExercises.length}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Esercizi Completati',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                if (_skippedExercises.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${_skippedExercises.length} saltati',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Exercise List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: widget.mobilityExercises.length,
              itemBuilder: (context, index) {
                final exercise = widget.mobilityExercises[index];
                return _buildExerciseCard(exercise);
              },
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        (_completedExercises.length +
                                _skippedExercises.length) ==
                            widget.mobilityExercises.length
                        ? () {
                            if (widget.onComplete != null) {
                              widget.onComplete!();
                            }
                            Navigator.pop(context, true);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00CED1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Completa Sessione',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if ((_completedExercises.length + _skippedExercises.length) !=
                    widget.mobilityExercises.length)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Salta Intera Sessione',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(WorkoutExercise exercise) {
    final isCompleted = _completedExercises.contains(exercise.exercise.id);
    final isSkipped = _skippedExercises.contains(exercise.exercise.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.shade900.withOpacity(0.3)
            : isSkipped
            ? Colors.orange.shade900.withOpacity(0.2)
            : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSkipped ? Colors.orange : const Color(0xFF00CED1),
          width: 2.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Checkbox
            InkWell(
              onTap: () => setState(() {
                if (_completedExercises.contains(exercise.exercise.id)) {
                  _completedExercises.remove(exercise.exercise.id);
                } else {
                  _completedExercises.add(exercise.exercise.id);
                  _skippedExercises.remove(exercise.exercise.id);
                }
              }),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? Colors.green : Colors.transparent,
                  border: Border.all(
                    color: isCompleted ? Colors.green : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise.exercise.name,
                          style: AppTextStyles.h5.copyWith(
                            decoration: isCompleted || isSkipped
                                ? TextDecoration.lineThrough
                                : null,
                            color: isCompleted || isSkipped
                                ? Colors.grey
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isSkipped)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Saltato',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${exercise.sets} sets × ${exercise.reps}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  // Anatomical Muscle Visualization (always shown - both views)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: DualAnatomicalView(
                      muscleGroups: exercise.exercise.muscleGroups,
                      height: 220,
                      highlightColor: const Color(
                        0xFF00CED1,
                      ), // Cyan/Blue for mobility
                    ),
                  ),
                  // Video Player
                  if (exercise.exercise.videoUrl != null &&
                      exercise.exercise.videoUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ExerciseVideoPlayer(
                        videoUrl: exercise.exercise.videoUrl,
                        exerciseName: exercise.exercise.name,
                      ),
                    ),
                  if (exercise.notes != null && exercise.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        exercise.notes!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFF00CED1),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Skip button
            if (!isCompleted && !isSkipped)
              IconButton(
                onPressed: () => setState(() {
                  _skippedExercises.add(exercise.exercise.id);
                  _completedExercises.remove(exercise.exercise.id);
                }),
                icon: const Icon(Icons.skip_next),
                color: Colors.orange,
                tooltip: 'Salta esercizio',
              ),
            // Undo skip button
            if (isSkipped)
              IconButton(
                onPressed: () => setState(() {
                  _skippedExercises.remove(exercise.exercise.id);
                }),
                icon: const Icon(Icons.undo),
                color: Colors.orange,
                tooltip: 'Annulla skip',
              ),
          ],
        ),
      ),
    );
  }
}
