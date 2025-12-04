import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/workout_model.dart';
import '../../widgets/workout/anatomical_muscle_view.dart';

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
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeVideoPlayer(String url) {
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null) return;

    _videoController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
      ),
    );

    setState(() {
      _showVideoPlayer = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Exercise Details', style: AppTextStyles.h5),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Name
            Text(
              widget.workoutExercise.exercise.name,
              style: AppTextStyles.h3.copyWith(color: const Color(0xFF2563EB)),
            ),
            const SizedBox(height: 8),

            // Difficulty Badge
            _buildDifficultyBadge(),
            const SizedBox(height: 24),

            // Anatomical Diagram
            if (widget.workoutExercise.exercise.muscleGroups.isNotEmpty) ...[
              Text('Muscles Worked', style: AppTextStyles.h5),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: AnatomicalMuscleView(
                  muscleGroups: widget.workoutExercise.exercise.muscleGroups,
                  height: 300,
                  highlightColor: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Sets, Reps, Rest
            if (widget.workoutExercise.sets != null ||
                widget.workoutExercise.reps != null) ...[
              _buildWorkoutInfo(),
              const SizedBox(height: 24),
            ],

            // Equipment
            if (widget.workoutExercise.exercise.equipment.isNotEmpty) ...[
              Text('Equipment Required', style: AppTextStyles.h5),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.workoutExercise.exercise.equipment.map((eq) {
                  return Chip(
                    label: Text(eq),
                    backgroundColor: AppColors.surface,
                    labelStyle: AppTextStyles.bodyMedium,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Description
            if (widget.workoutExercise.exercise.description.isNotEmpty) ...[
              Text('How to Perform', style: AppTextStyles.h5),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.workoutExercise.exercise.description,
                  style: AppTextStyles.bodyLarge.copyWith(height: 1.6),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Video Player / Thumbnail
            if (widget.workoutExercise.exercise.videoUrl != null &&
                widget.workoutExercise.exercise.videoUrl!.isNotEmpty) ...[
              Text('Video Tutorial', style: AppTextStyles.h5),
              const SizedBox(height: 12),
              _buildVideoSection(widget.workoutExercise.exercise.videoUrl!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge() {
    Color badgeColor;
    IconData icon;

    switch (widget.workoutExercise.exercise.difficulty.name.toLowerCase()) {
      case 'beginner':
        badgeColor = Colors.green;
        icon = Icons.star;
        break;
      case 'intermediate':
        badgeColor = Colors.orange;
        icon = Icons.star_half;
        break;
      case 'advanced':
        badgeColor = Colors.red;
        icon = Icons.star_border;
        break;
      default:
        badgeColor = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: badgeColor),
          const SizedBox(width: 6),
          Text(
            widget.workoutExercise.exercise.difficulty.name,
            style: AppTextStyles.bodyMedium.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (widget.workoutExercise.sets != null)
            _buildInfoColumn(
              icon: Icons.repeat,
              label: 'Sets',
              value: widget.workoutExercise.sets.toString(),
            ),
          if (widget.workoutExercise.reps != null)
            _buildInfoColumn(
              icon: Icons.fitness_center,
              label: 'Reps',
              value: widget.workoutExercise.reps!,
            ),
          if (widget.workoutExercise.restSeconds != null)
            _buildInfoColumn(
              icon: Icons.timer,
              label: 'Rest',
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
        Icon(icon, color: const Color(0xFF2563EB), size: 28),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.h4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoSection(String url) {
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Invalid video URL'),
      );
    }

    // Show video player if initialized, otherwise show thumbnail
    if (_showVideoPlayer && _videoController != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: YoutubePlayer(
          controller: _videoController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.primaryNeon,
        ),
      );
    }

    // Show thumbnail with play button overlay
    return GestureDetector(
      onTap: () => _initializeVideoPlayer(url),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
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
              color: Colors.black.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
          ),
        ),
      ),
    );
  }
}
