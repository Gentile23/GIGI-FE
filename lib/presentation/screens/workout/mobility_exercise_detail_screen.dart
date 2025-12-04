import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/workout_model.dart';
import '../../widgets/workout/anatomical_muscle_view.dart';

class MobilityExerciseDetailScreen extends StatelessWidget {
  final WorkoutExercise workoutExercise;
  final String? duration;

  const MobilityExerciseDetailScreen({
    super.key,
    required this.workoutExercise,
    this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1B4B),
      appBar: AppBar(
        title: Text('Mobility Exercise', style: AppTextStyles.h5),
        backgroundColor: const Color(0xFF312E81),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              workoutExercise.exercise.name,
              style: AppTextStyles.h3.copyWith(
                color: const Color(0xFFA78BFA),
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            _buildTypeBadge(),
            const SizedBox(height: 24),

            if (workoutExercise.exercise.muscleGroups.isNotEmpty) ...[
              Text(
                'Areas to Stretch',
                style: AppTextStyles.h5.copyWith(
                  color: const Color(0xFFA78BFA),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF312E81),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: AnatomicalMuscleView(
                  muscleGroups: workoutExercise.exercise.muscleGroups,
                  height: 280,
                  highlightColor: const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(height: 24),
            ],

            _buildBreathingGuide(),
            const SizedBox(height: 24),

            if (duration != null) ...[
              _buildDurationCard(),
              const SizedBox(height: 24),
            ],

            if (workoutExercise.exercise.description.isNotEmpty) ...[
              Text(
                'Instructions',
                style: AppTextStyles.h5.copyWith(
                  color: const Color(0xFFA78BFA),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF312E81),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  workoutExercise.exercise.description,
                  style: AppTextStyles.bodyLarge.copyWith(
                    height: 1.8,
                    color: const Color(0xFFE0E7FF),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (workoutExercise.exercise.videoUrl != null &&
                workoutExercise.exercise.videoUrl!.isNotEmpty) ...[
              Text(
                'Video Demonstration',
                style: AppTextStyles.h5.copyWith(
                  color: const Color(0xFFA78BFA),
                ),
              ),
              const SizedBox(height: 12),
              _buildVideoPlayer(workoutExercise.exercise.videoUrl!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.self_improvement,
            size: 16,
            color: Color(0xFF10B981),
          ),
          const SizedBox(width: 6),
          Text(
            'Mobility & Flexibility',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFF10B981),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingGuide() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.2),
            const Color(0xFF059669).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.air, color: Color(0xFF10B981), size: 28),
              const SizedBox(width: 12),
              Text(
                'Breathing Guide',
                style: AppTextStyles.h5.copyWith(
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBreathingStep('1', 'Inhale deeply through your nose'),
          const SizedBox(height: 12),
          _buildBreathingStep('2', 'Hold the stretch gently'),
          const SizedBox(height: 12),
          _buildBreathingStep('3', 'Exhale slowly, deepening the stretch'),
          const SizedBox(height: 12),
          _buildBreathingStep('4', 'Repeat with each breath'),
        ],
      ),
    );
  }

  Widget _buildBreathingStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF10B981)),
          ),
          child: Center(
            child: Text(
              number,
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFF10B981),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyLarge.copyWith(
              color: const Color(0xFFE0E7FF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF312E81),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer, color: Color(0xFFA78BFA), size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Duration',
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF9CA3AF),
                ),
              ),
              Text(
                duration!,
                style: AppTextStyles.h3.copyWith(
                  color: const Color(0xFFA78BFA),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(String url) {
    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF312E81),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Invalid video URL',
          style: TextStyle(color: Color(0xFFE0E7FF)),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: YoutubePlayer(
        controller: YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
        ),
        showVideoProgressIndicator: true,
      ),
    );
  }
}
