import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../presentation/widgets/clean_widgets.dart';
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

  static const Color _mobilityColor = CleanTheme.accentPurple;
  static const Color _breathingColor = CleanTheme.accentGreen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Esercizio Mobilità',
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
            Text(
              workoutExercise.exercise.name,
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: _mobilityColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildTypeBadge(),
            const SizedBox(height: 24),

            if (workoutExercise.exercise.muscleGroups.isNotEmpty) ...[
              CleanSectionHeader(title: 'Aree da Allungare'),
              const SizedBox(height: 12),
              CleanCard(
                padding: const EdgeInsets.all(16),
                child: AnatomicalMuscleView(
                  muscleGroups: workoutExercise.exercise.muscleGroups,
                  height: 280,
                  highlightColor: _mobilityColor,
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
              CleanSectionHeader(title: 'Istruzioni'),
              const SizedBox(height: 12),
              CleanCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  workoutExercise.exercise.description,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.7,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (workoutExercise.exercise.videoUrl != null &&
                workoutExercise.exercise.videoUrl!.isNotEmpty) ...[
              CleanSectionHeader(title: 'Video Dimostrazione'),
              const SizedBox(height: 12),
              _buildVideoPlayer(workoutExercise.exercise.videoUrl!),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _breathingColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _breathingColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.self_improvement, size: 16, color: _breathingColor),
          const SizedBox(width: 6),
          Text(
            'Mobilità & Flessibilità',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _breathingColor,
              fontWeight: FontWeight.w600,
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
        color: _breathingColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _breathingColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _breathingColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.air, color: _breathingColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Guida Respirazione',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _breathingColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildBreathingStep('1', 'Inspira profondamente dal naso'),
          const SizedBox(height: 12),
          _buildBreathingStep('2', 'Mantieni lo stretch dolcemente'),
          const SizedBox(height: 12),
          _buildBreathingStep('3', 'Espira lentamente, approfondendo'),
          const SizedBox(height: 12),
          _buildBreathingStep('4', 'Ripeti con ogni respiro'),
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
            color: _breathingColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: _breathingColor.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _breathingColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CleanTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationCard() {
    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _mobilityColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.timer_outlined, color: _mobilityColor, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Durata',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: CleanTheme.textSecondary,
                ),
              ),
              Text(
                duration!,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _mobilityColor,
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
      return CleanCard(
        padding: const EdgeInsets.all(16),
        child: Text(
          'URL video non valido',
          style: GoogleFonts.inter(color: CleanTheme.textSecondary),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: YoutubePlayer(
        controller: YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
        ),
        showVideoProgressIndicator: true,
        progressIndicatorColor: CleanTheme.primaryColor,
      ),
    );
  }
}
