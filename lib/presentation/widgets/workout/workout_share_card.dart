import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../screens/workout/workout_summary_screen.dart';

class WorkoutShareCard extends StatelessWidget {
  final WorkoutSummaryData summaryData;
  final File? photo;
  final String? userName;

  const WorkoutShareCard({
    super.key,
    required this.summaryData,
    this.photo,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16, // Story format
      child: Container(
        decoration: BoxDecoration(
          color: CleanTheme.steelDark,
          borderRadius: BorderRadius.circular(24),
          image: photo != null
              ? DecorationImage(image: FileImage(photo!), fit: BoxFit.cover)
              : const DecorationImage(
                  image: AssetImage('assets/images/workout_hero.png'),
                  fit: BoxFit.cover,
                ),
        ),
        child: Stack(
          children: [
            // Dark Overlay for legibility
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo & Brand
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          'assets/images/gigi_new_logo.png',
                          height: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'GiGi',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Stats Section
                  Text(
                    summaryData.workoutName.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: CleanTheme.accentOrange,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'WORKOUT\nCOMPLETATO',
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Stats Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildShareStat(
                        label: 'DURATA',
                        value: summaryData.formattedDuration,
                      ),
                      _buildShareStat(
                        label: 'KCAL',
                        value: '${summaryData.estimatedCalories}',
                      ),
                      _buildShareStat(
                        label: 'VOLUME',
                        value: summaryData.formattedKg,
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // User Info
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: CleanTheme.accentOrange,
                        ),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName ?? 'ATLETA GIGI',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Ogni set conta.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
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

  Widget _buildShareStat({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.6),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
