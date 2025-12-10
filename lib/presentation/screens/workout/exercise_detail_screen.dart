import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../presentation/widgets/clean_widgets.dart';
import '../../../data/models/workout_model.dart';
import '../../widgets/workout/anatomical_muscle_view.dart';
import '../../widgets/workout/similar_exercises_sheet.dart';
import '../../widgets/workout/alternative_exercises_sheet.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final WorkoutExercise workoutExercise;

  const ExerciseDetailScreen({super.key, required this.workoutExercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  YoutubePlayerController? _videoController;
  bool _showVideoPlayer = false;

  @override
  void dispose() {
    _videoController?.close();
    super.dispose();
  }

  void _initializeVideoPlayer(String url) {
    final videoId = YoutubePlayerController.convertUrlToId(url);
    if (videoId == null) return;

    // Dispose previous controller if exists
    _videoController?.close();

    _videoController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        mute: false,
        enableCaption: false,
        showFullscreenButton: true,
      ),
    );

    setState(() {
      _showVideoPlayer = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Dettagli Esercizio',
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
            // Exercise Name
            Text(
              widget.workoutExercise.exercise.name,
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: CleanTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),

            // Difficulty Badge
            _buildDifficultyBadge(),
            const SizedBox(height: 24),

            // Similar & Alternative Exercises Buttons
            _buildExerciseOptionsButtons(),
            const SizedBox(height: 24),

            // Anatomical Diagram
            if (widget.workoutExercise.exercise.muscleGroups.isNotEmpty) ...[
              CleanSectionHeader(title: 'Muscoli Coinvolti'),
              const SizedBox(height: 12),
              CleanCard(
                padding: const EdgeInsets.all(16),
                child: AnatomicalMuscleView(
                  muscleGroups: widget.workoutExercise.exercise.muscleGroups,
                  height: 300,
                  highlightColor: CleanTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Sets, Reps, Rest
            _buildWorkoutInfo(),
            const SizedBox(height: 24),

            // Equipment
            if (widget.workoutExercise.exercise.equipment.isNotEmpty) ...[
              CleanSectionHeader(title: 'Attrezzatura Richiesta'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.workoutExercise.exercise.equipment.map((eq) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: CleanTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: CleanTheme.borderPrimary),
                    ),
                    child: Text(
                      eq,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Description
            if (widget.workoutExercise.exercise.description.isNotEmpty) ...[
              CleanSectionHeader(title: 'Come Eseguire'),
              const SizedBox(height: 12),
              CleanCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.workoutExercise.exercise.description,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.6,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Video Player / Thumbnail
            if (widget.workoutExercise.exercise.videoUrl != null &&
                widget.workoutExercise.exercise.videoUrl!.isNotEmpty) ...[
              CleanSectionHeader(title: 'Video Tutorial'),
              const SizedBox(height: 12),
              _buildVideoSection(widget.workoutExercise.exercise.videoUrl!),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Build buttons for similar exercises and alternatives
  Widget _buildExerciseOptionsButtons() {
    final isBodyweight = widget.workoutExercise.exercise.equipment.contains(
      'Bodyweight',
    );

    return Row(
      children: [
        // Similar Exercises Button
        Expanded(
          child: GestureDetector(
            onTap: () {
              SimilarExercisesSheet.show(
                context,
                exercise: widget.workoutExercise.exercise,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: CleanTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CleanTheme.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.compare_arrows,
                    color: CleanTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Esercizi Simili',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Alternative Exercises Button
        Expanded(
          child: GestureDetector(
            onTap: () {
              AlternativeExercisesSheet.show(
                context,
                exercise: widget.workoutExercise.exercise,
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: CleanTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isBodyweight ? Colors.blue : Colors.green).withValues(
                    alpha: 0.3,
                  ),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isBodyweight
                        ? Icons.fitness_center
                        : Icons.accessibility_new,
                    color: isBodyweight ? Colors.blue : Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      isBodyweight ? 'Con Attrezzatura' : 'Corpo Libero',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyBadge() {
    Color badgeColor;
    IconData icon;
    String label;

    switch (widget.workoutExercise.exercise.difficulty.name.toLowerCase()) {
      case 'beginner':
        badgeColor = CleanTheme.accentGreen;
        icon = Icons.star;
        label = 'Principiante';
        break;
      case 'intermediate':
        badgeColor = CleanTheme.accentOrange;
        icon = Icons.star_half;
        label = 'Intermedio';
        break;
      case 'advanced':
        badgeColor = CleanTheme.accentRed;
        icon = Icons.star_border;
        label = 'Avanzato';
        break;
      default:
        badgeColor = CleanTheme.textTertiary;
        icon = Icons.help_outline;
        label = widget.workoutExercise.exercise.difficulty.name;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutInfo() {
    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoColumn(
            icon: Icons.repeat,
            label: 'Serie',
            value: widget.workoutExercise.sets.toString(),
          ),
          _buildInfoColumn(
            icon: Icons.fitness_center_outlined,
            label: 'Ripetizioni',
            value: widget.workoutExercise.reps,
          ),
          _buildInfoColumn(
            icon: Icons.timer_outlined,
            label: 'Recupero',
            value: '${widget.workoutExercise.restSeconds}s',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: CleanTheme.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: CleanTheme.primaryColor, size: 24),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: CleanTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: CleanTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoSection(String url) {
    final videoId = YoutubePlayerController.convertUrlToId(url);
    if (videoId == null) {
      return CleanCard(
        padding: const EdgeInsets.all(16),
        child: Text(
          'URL video non valido',
          style: GoogleFonts.inter(color: CleanTheme.textSecondary),
        ),
      );
    }

    if (_showVideoPlayer && _videoController != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: YoutubePlayer(
            controller: _videoController!,
            aspectRatio: 16 / 9,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _initializeVideoPlayer(url),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black,
          image: DecorationImage(
            image: NetworkImage(
              'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CleanTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
          ),
        ),
      ),
    );
  }
}
