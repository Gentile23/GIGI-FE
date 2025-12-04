import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/workout_model.dart';
import '../../widgets/workout/anatomical_muscle_view.dart';

class CardioExerciseDetailScreen extends StatelessWidget {
  final WorkoutExercise workoutExercise;
  final String? duration;
  final String? intensity;

  const CardioExerciseDetailScreen({
    super.key,
    required this.workoutExercise,
    this.duration,
    this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7C2D12),
      appBar: AppBar(
        title: Text('Cardio Exercise', style: AppTextStyles.h5),
        backgroundColor: const Color(0xFF9A3412),
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
                color: const Color(0xFFFCD34D),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            _buildTypeBadge(),
            const SizedBox(height: 24),

            _buildFullBodyDiagram(),
            const SizedBox(height: 24),

            _buildIntensityCard(),
            const SizedBox(height: 24),

            if (workoutExercise.exercise.description.isNotEmpty) ...[
              Text(
                'Instructions',
                style: AppTextStyles.h5.copyWith(
                  color: const Color(0xFFFCD34D),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF9A3412),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  workoutExercise.exercise.description,
                  style: AppTextStyles.bodyLarge.copyWith(
                    height: 1.6,
                    color: const Color(0xFFFEF3C7),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            _buildBenefitsCard(),
            const SizedBox(height: 24),

            if (workoutExercise.exercise.videoUrl != null &&
                workoutExercise.exercise.videoUrl!.isNotEmpty) ...[
              Text(
                'Video Demonstration',
                style: AppTextStyles.h5.copyWith(
                  color: const Color(0xFFFCD34D),
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
        color: const Color(0xFFEF4444).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEF4444)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite, size: 16, color: Color(0xFFEF4444)),
          const SizedBox(width: 6),
          Text(
            'Cardiovascular Training',
            style: AppTextStyles.bodyMedium.copyWith(
              color: const Color(0xFFEF4444),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullBodyDiagram() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF9A3412),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Full Body Activation',
            style: AppTextStyles.h5.copyWith(color: const Color(0xFFFCD34D)),
          ),
          const SizedBox(height: 12),
          AnatomicalMuscleView(
            muscleGroups: const ['Cardio', 'Full Body'],
            height: 280,
            highlightColor: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEF4444).withOpacity(0.3),
            const Color(0xFFF59E0B).withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (intensity != null)
            _buildInfoColumn(
              icon: Icons.local_fire_department,
              label: 'Intensity',
              value: intensity!,
              color: const Color(0xFFEF4444),
            ),
          if (duration != null)
            _buildInfoColumn(
              icon: Icons.timer,
              label: 'Duration',
              value: duration!,
              color: const Color(0xFFF59E0B),
            ),
          _buildInfoColumn(
            icon: Icons.favorite,
            label: 'HR Zone',
            value: '140-160',
            color: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.h4.copyWith(color: const Color(0xFFFCD34D)),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: const Color(0xFFFEF3C7),
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF9A3412),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF10B981),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Benefits',
                style: AppTextStyles.h5.copyWith(
                  color: const Color(0xFFFCD34D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBenefitItem('Improves cardiovascular health'),
          _buildBenefitItem('Burns calories and aids weight loss'),
          _buildBenefitItem('Increases endurance and stamina'),
          _buildBenefitItem('Boosts mood and energy levels'),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.arrow_right, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: const Color(0xFFFEF3C7),
              ),
            ),
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
          color: const Color(0xFF9A3412),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Invalid video URL',
          style: TextStyle(color: Color(0xFFFEF3C7)),
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
