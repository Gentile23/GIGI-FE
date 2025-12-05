import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../presentation/widgets/clean_widgets.dart';
import '../../../data/models/workout_model.dart';
import '../../widgets/workout/exercise_video_player.dart';

class CardioExerciseScreen extends StatefulWidget {
  final List<WorkoutExercise> cardioExercises;
  final String title;
  final VoidCallback? onComplete;

  const CardioExerciseScreen({
    super.key,
    required this.cardioExercises,
    required this.title,
    this.onComplete,
  });

  @override
  State<CardioExerciseScreen> createState() => _CardioExerciseScreenState();
}

class _CardioExerciseScreenState extends State<CardioExerciseScreen> {
  final Set<String> _completedExercises = {};
  final Set<String> _skippedExercises = {};

  static const Color _cardioColor = CleanTheme.accentRed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: _cardioColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Header with Counter
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: BoxDecoration(
              color: _cardioColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.directions_run,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Cardio',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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
                      style: GoogleFonts.outfit(
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 4),
                      child: Text(
                        '/${widget.cardioExercises.length}',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Esercizi Completati',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                if (_skippedExercises.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${_skippedExercises.length} saltati',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Exercise List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: widget.cardioExercises.length,
              itemBuilder: (context, index) {
                final exercise = widget.cardioExercises[index];
                return _buildExerciseCard(exercise);
              },
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CleanTheme.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                CleanButton(
                  text: 'Completa Sessione',
                  icon: Icons.check,
                  width: double.infinity,
                  onPressed:
                      (_completedExercises.length + _skippedExercises.length) ==
                          widget.cardioExercises.length
                      ? () {
                          if (widget.onComplete != null) {
                            widget.onComplete!();
                          }
                          Navigator.pop(context, true);
                        }
                      : null,
                ),
                if ((_completedExercises.length + _skippedExercises.length) !=
                    widget.cardioExercises.length)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Salta Intera Sessione',
                        style: GoogleFonts.inter(
                          color: CleanTheme.textSecondary,
                          fontSize: 14,
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
            ? CleanTheme.accentGreen.withValues(alpha: 0.08)
            : isSkipped
            ? CleanTheme.accentOrange.withValues(alpha: 0.08)
            : CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? CleanTheme.accentGreen
              : isSkipped
              ? CleanTheme.accentOrange
              : _cardioColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? CleanTheme.accentGreen
                      : Colors.transparent,
                  border: Border.all(
                    color: isCompleted
                        ? CleanTheme.accentGreen
                        : CleanTheme.borderPrimary,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
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
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: isCompleted || isSkipped
                                ? TextDecoration.lineThrough
                                : null,
                            color: isCompleted || isSkipped
                                ? CleanTheme.textTertiary
                                : CleanTheme.textPrimary,
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
                            color: CleanTheme.accentOrange.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Saltato',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: CleanTheme.accentOrange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${exercise.reps}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: CleanTheme.textSecondary,
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
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        exercise.notes!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: _cardioColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Skip/Undo button
            if (!isCompleted && !isSkipped)
              IconButton(
                onPressed: () => setState(() {
                  _skippedExercises.add(exercise.exercise.id);
                  _completedExercises.remove(exercise.exercise.id);
                }),
                icon: const Icon(Icons.skip_next),
                color: CleanTheme.accentOrange,
                tooltip: 'Salta esercizio',
              ),
            if (isSkipped)
              IconButton(
                onPressed: () => setState(() {
                  _skippedExercises.remove(exercise.exercise.id);
                }),
                icon: const Icon(Icons.undo),
                color: CleanTheme.accentOrange,
                tooltip: 'Annulla skip',
              ),
          ],
        ),
      ),
    );
  }
}
