import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/clean_theme.dart';
import '../../screens/workout/workout_summary_screen.dart';

class WorkoutShareCard extends StatelessWidget {
  final WorkoutSummaryData summaryData;
  final Uint8List? photoBytes;
  final String? userName;

  const WorkoutShareCard({
    super.key,
    required this.summaryData,
    this.photoBytes,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: BoxDecoration(
          color: CleanTheme.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CleanTheme.borderSecondary),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: _buildBackground()),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrandHeader(),
                    const Spacer(),
                    _buildSocialBadge(),
                    const SizedBox(height: 12),
                    Text(
                      'WORKOUT COMPLETATO',
                      style: GoogleFonts.outfit(
                        fontSize: 31,
                        fontWeight: FontWeight.w900,
                        color: _textColor,
                        height: 0.95,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summaryData.workoutName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _mutedTextColor,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _buildHeroStat(),
                    const SizedBox(height: 16),
                    _buildStatGrid(),
                    const SizedBox(height: 14),
                    _buildMusclePills(),
                    const SizedBox(height: 18),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (photoBytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            photoBytes!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.34),
                  Colors.black.withValues(alpha: 0.48),
                  Colors.black.withValues(alpha: 0.86),
                ],
                stops: const [0, 0.42, 1],
              ),
            ),
          ),
        ],
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CleanTheme.surfaceColor,
            CleanTheme.backgroundColor,
            CleanTheme.steelDark.withValues(alpha: 0.42),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -70,
            child: _buildGlow(CleanTheme.accentOrange.withValues(alpha: 0.18)),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: _buildGlow(CleanTheme.accentGreen.withValues(alpha: 0.18)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlow(Color color) {
    return Container(
      width: 210,
      height: 210,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 90, spreadRadius: 25)],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Row(
      children: [
        Image.asset(
          'assets/images/gigi_new_logo.png',
          height: 30,
          errorBuilder: (_, _, _) => Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _textColor,
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'GIGI',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: _textColor,
            letterSpacing: 1,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _panelColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _panelBorderColor),
          ),
          child: Text(
            '${summaryData.completionPercentage.round()}% DONE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: _textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: CleanTheme.accentGreen.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _sessionIntensityLabel,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: CleanTheme.textOnPrimary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildHeroStat() {
    final stat = _heroStat;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _panelBorderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.label.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: _mutedTextColor,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  stat.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: _textColor,
                    height: 0.95,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(stat.icon, size: 36, color: CleanTheme.accentGreen),
        ],
      ),
    );
  }

  Widget _buildStatGrid() {
    final stats = <_ShareStat>[
      _ShareStat('Durata', summaryData.formattedDuration, Icons.timer_rounded),
      _ShareStat('Serie', '${summaryData.completedSets}', Icons.repeat_rounded),
      if (summaryData.totalReps > 0)
        _ShareStat('Reps', '${summaryData.totalReps}', Icons.bolt_rounded),
      if (summaryData.estimatedCalories > 0)
        _ShareStat(
          'Kcal',
          '${summaryData.estimatedCalories}',
          Icons.local_fire_department_rounded,
        ),
      if (summaryData.avgRpe != null)
        _ShareStat(
          'RPE',
          summaryData.avgRpe!.toStringAsFixed(1),
          Icons.speed_rounded,
        ),
      if (_volumePerMinute != null)
        _ShareStat('Kg/min', _volumePerMinute!, Icons.trending_up_rounded),
    ].take(6).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: stats.map(_buildMetricPill).toList(),
    );
  }

  Widget _buildMetricPill(_ShareStat stat) {
    return Container(
      width: 94,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _panelBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(stat.icon, size: 16, color: CleanTheme.accentOrange),
          const SizedBox(height: 7),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            stat.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _mutedTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusclePills() {
    final muscles = summaryData.muscleGroupsWorked.take(3).toList();
    if (muscles.isEmpty) {
      return Text(
        'Sessione tracciata con GIGI',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _mutedTextColor,
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: muscles
          .map(
            (muscle) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: _panelColor,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _panelBorderColor),
              ),
              child: Text(
                muscle.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: _textColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _textColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.person_rounded,
            color: photoBytes == null
                ? CleanTheme.textOnDark
                : CleanTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName?.trim().isNotEmpty == true
                    ? userName!.trim()
                    : 'Atleta GIGI',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _textColor,
                ),
              ),
              Text(
                'Built with GIGI',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _mutedTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  _ShareStat get _heroStat {
    if (summaryData.totalKgLifted > 0) {
      return _ShareStat(
        'Volume totale',
        summaryData.formattedKg,
        Icons.fitness_center_rounded,
      );
    }
    if (summaryData.totalReps > 0) {
      return _ShareStat('Reps totali', '${summaryData.totalReps}', Icons.bolt);
    }
    return _ShareStat(
      'Durata sessione',
      summaryData.formattedDuration,
      Icons.timer_rounded,
    );
  }

  String get _sessionIntensityLabel {
    if (summaryData.avgRpe != null && summaryData.avgRpe! >= 8) {
      return 'HIGH INTENSITY SESSION';
    }
    if (summaryData.totalKgLifted >= 5000) return 'BIG VOLUME DAY';
    if (summaryData.completionPercentage >= 100) return 'FULL SESSION LOCKED';
    return 'TRAINING LOGGED';
  }

  String? get _volumePerMinute {
    final minutes = summaryData.duration.inSeconds / 60;
    if (summaryData.totalKgLifted <= 0 || minutes <= 0) return null;
    final value = summaryData.totalKgLifted / minutes;
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}t';
    return value >= 100 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  Color get _textColor =>
      photoBytes == null ? CleanTheme.textPrimary : CleanTheme.textOnDark;

  Color get _mutedTextColor => photoBytes == null
      ? CleanTheme.textSecondary
      : CleanTheme.textOnDark.withValues(alpha: 0.74);

  Color get _panelColor => photoBytes == null
      ? CleanTheme.surfaceColor.withValues(alpha: 0.94)
      : Colors.black.withValues(alpha: 0.34);

  Color get _panelBorderColor => photoBytes == null
      ? CleanTheme.borderSecondary
      : Colors.white.withValues(alpha: 0.16);
}

class _ShareStat {
  final String label;
  final String value;
  final IconData icon;

  const _ShareStat(this.label, this.value, this.icon);
}
