import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../presentation/widgets/clean_widgets.dart';
import '../../../data/models/workout_model.dart';
import '../../widgets/workout/anatomical_muscle_view.dart';

class CardioExerciseDetailScreen extends StatefulWidget {
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
  State<CardioExerciseDetailScreen> createState() =>
      _CardioExerciseDetailScreenState();
}

class _CardioExerciseDetailScreenState
    extends State<CardioExerciseDetailScreen> {
  static const Color _cardioColor = CleanTheme.accentRed;
  static const Color _accentColor = CleanTheme.accentOrange;

  YoutubePlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    final videoUrl = widget.workoutExercise.exercise.videoUrl;
    if (videoUrl != null && videoUrl.isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(videoUrl);
      if (videoId != null) {
        _videoController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
        );
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Esercizio Cardio',
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
              widget.workoutExercise.exercise.name,
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: _cardioColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildTypeBadge(),
            const SizedBox(height: 24),

            _buildFullBodyDiagram(),
            const SizedBox(height: 24),

            _buildIntensityCard(),
            const SizedBox(height: 24),

            if (widget.workoutExercise.exercise.description.isNotEmpty) ...[
              CleanSectionHeader(title: 'Istruzioni'),
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

            _buildBenefitsCard(),
            const SizedBox(height: 24),

            if (_videoController != null) ...[
              CleanSectionHeader(title: 'Video Dimostrazione'),
              const SizedBox(height: 12),
              _buildVideoPlayer(),
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
        color: _cardioColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardioColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite, size: 16, color: _cardioColor),
          const SizedBox(width: 6),
          Text(
            'Allenamento Cardiovascolare',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _cardioColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullBodyDiagram() {
    return CleanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Attivazione Corpo Completo',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          AnatomicalMuscleView(
            muscleGroups: const ['Cardio', 'Full Body'],
            height: 280,
            highlightColor: _accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardioColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardioColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (widget.intensity != null)
            _buildInfoColumn(
              icon: Icons.local_fire_department_outlined,
              label: 'Intensità',
              value: widget.intensity!,
              color: _cardioColor,
            ),
          if (widget.duration != null)
            _buildInfoColumn(
              icon: Icons.timer_outlined,
              label: 'Durata',
              value: widget.duration!,
              color: _accentColor,
            ),
          _buildInfoColumn(
            icon: Icons.favorite_outline,
            label: 'Zona FC',
            value: '140-160',
            color: _cardioColor,
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
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
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

  Widget _buildBenefitsCard() {
    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CleanTheme.accentGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: CleanTheme.accentGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Benefici',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBenefitItem('Migliora la salute cardiovascolare'),
          _buildBenefitItem('Brucia calorie e aiuta la perdita di peso'),
          _buildBenefitItem('Aumenta resistenza e stamina'),
          _buildBenefitItem('Migliora umore e livelli di energia'),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.arrow_right, color: _accentColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CleanTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null) {
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
        controller: _videoController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: CleanTheme.primaryColor,
      ),
    );
  }
}
