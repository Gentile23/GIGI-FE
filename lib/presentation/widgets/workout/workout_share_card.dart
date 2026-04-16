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
            if (photoBytes != null)
              Positioned.fill(
                child: Image.memory(
                  photoBytes!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: photoBytes != null
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.black.withValues(alpha: 0.82),
                          ],
                        )
                      : null,
                  color: photoBytes == null ? CleanTheme.backgroundColor : null,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/gigi_new_logo.png',
                        height: 30,
                        errorBuilder: (_, _, _) => Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: photoBytes == null
                                ? CleanTheme.primaryColor
                                : Colors.white,
                            borderRadius: BorderRadius.circular(6),
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
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Allenamento completato',
                    style: GoogleFonts.outfit(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: _textColor,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    summaryData.workoutName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _mutedTextColor,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: photoBytes == null
                          ? CleanTheme.surfaceColor
                          : Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: photoBytes == null
                            ? CleanTheme.borderSecondary
                            : Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildShareStat(
                                label: 'Durata',
                                value: summaryData.formattedDuration,
                              ),
                            ),
                            Expanded(
                              child: _buildShareStat(
                                label: 'Esercizi',
                                value:
                                    '${summaryData.completedExercises}/${summaryData.totalExercises}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildShareStat(
                                label: 'Serie',
                                value: '${summaryData.completedSets}',
                              ),
                            ),
                            Expanded(
                              child: _buildShareStat(
                                label: 'Volume',
                                value: summaryData.totalKgLifted > 0
                                    ? summaryData.formattedKg
                                    : '-',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
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
                        child: Text(
                          userName?.trim().isNotEmpty == true
                              ? userName!.trim()
                              : 'Atleta GIGI',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _textColor =>
      photoBytes == null ? CleanTheme.textPrimary : CleanTheme.textOnDark;

  Color get _mutedTextColor => photoBytes == null
      ? CleanTheme.textSecondary
      : CleanTheme.textOnDark.withValues(alpha: 0.72);

  Widget _buildShareStat({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _mutedTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: _textColor,
          ),
        ),
      ],
    );
  }
}
