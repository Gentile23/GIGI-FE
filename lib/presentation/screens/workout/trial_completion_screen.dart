import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/trial_workout_model.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';

class TrialCompletionScreen extends StatelessWidget {
  final TrialCompletionResponse completionResponse;

  const TrialCompletionScreen({super.key, required this.completionResponse});

  @override
  Widget build(BuildContext context) {
    final analysis = completionResponse.analysis;
    final completionRate = analysis['completion_rate'] as double;
    final avgDifficulty = analysis['average_difficulty'] as double;

    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CleanTheme.primaryLight,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 64,
                    color: CleanTheme.primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Center(
                child: Text(
                  'Trial Completato!',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: CleanTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: Text(
                  completionResponse.summary,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: CleanTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 40),

              CleanCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Le Tue Performance',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildStatRow(
                      context,
                      Icons.check_circle_outline,
                      'Completamento',
                      '${completionRate.toStringAsFixed(0)}%',
                      _getCompletionColor(completionRate),
                    ),

                    const Divider(height: 32, color: CleanTheme.borderPrimary),

                    _buildStatRow(
                      context,
                      Icons.fitness_center_outlined,
                      'Difficoltà Media',
                      '${avgDifficulty.toStringAsFixed(1)}/5',
                      _getDifficultyColor(avgDifficulty),
                    ),

                    if (analysis['fatigue_level'] != null) ...[
                      const Divider(
                        height: 32,
                        color: CleanTheme.borderPrimary,
                      ),
                      _buildStatRow(
                        context,
                        Icons.battery_charging_full_outlined,
                        'Livello Fatica',
                        '${analysis['fatigue_level']}/5',
                        CleanTheme.accentOrange,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              CleanCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CleanTheme.accentPurple.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.mic_outlined,
                            color: CleanTheme.accentPurple,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ti è piaciuto il Voice Coaching?',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: CleanTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Passa a Premium per usarlo sempre!',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: CleanTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CleanButton(
                      text: 'Scopri i Piani Premium',
                      isOutlined: true,
                      width: double.infinity,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Schermata abbonamenti in arrivo!'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              CleanButton(
                text: 'Genera la Mia Scheda',
                icon: Icons.auto_awesome,
                width: double.infinity,
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/main',
                    (route) => false,
                  );
                },
              ),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/main',
                      (route) => false,
                    );
                  },
                  child: Text(
                    'Salta per ora',
                    style: GoogleFonts.inter(color: CleanTheme.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: CleanTheme.textPrimary,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getCompletionColor(double rate) {
    if (rate >= 80) return CleanTheme.accentGreen;
    if (rate >= 50) return CleanTheme.accentOrange;
    return CleanTheme.accentRed;
  }

  Color _getDifficultyColor(double difficulty) {
    if (difficulty > 4) return CleanTheme.accentRed;
    if (difficulty > 3) return CleanTheme.accentOrange;
    if (difficulty < 2) return CleanTheme.accentGreen;
    return CleanTheme.primaryColor;
  }
}
