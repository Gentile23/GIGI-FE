import 'package:flutter/material.dart';
import '../../../data/models/trial_workout_model.dart';
import '../../../core/theme/modern_theme.dart';
import '../../widgets/modern_widgets.dart';

class TrialCompletionScreen extends StatelessWidget {
  final TrialCompletionResponse completionResponse;

  const TrialCompletionScreen({super.key, required this.completionResponse});

  @override
  Widget build(BuildContext context) {
    final analysis = completionResponse.analysis;
    final completionRate = analysis['completion_rate'] as double;
    final avgDifficulty = analysis['average_difficulty'] as double;

    return Scaffold(
      backgroundColor: ModernTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // Success icon
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [ModernTheme.accentColor, Colors.purple],
                    ),
                  ),
                  child: const Icon(Icons.check, size: 64, color: Colors.white),
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Center(
                child: Text(
                  'Trial Completato!',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // Summary
              Center(
                child: Text(
                  completionResponse.summary,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 40),

              // Performance stats
              ModernCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Le Tue Performance',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildStatRow(
                      context,
                      Icons.check_circle,
                      'Completamento',
                      '${completionRate.toStringAsFixed(0)}%',
                      _getCompletionColor(completionRate),
                    ),

                    const Divider(height: 32),

                    _buildStatRow(
                      context,
                      Icons.fitness_center,
                      'Difficoltà Media',
                      '${avgDifficulty.toStringAsFixed(1)}/5',
                      _getDifficultyColor(avgDifficulty),
                    ),

                    if (analysis['fatigue_level'] != null) ...[
                      const Divider(height: 32),
                      _buildStatRow(
                        context,
                        Icons.battery_charging_full,
                        'Livello Fatica',
                        '${analysis['fatigue_level']}/5',
                        ModernTheme.accentColor,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Voice Coaching CTA
              ModernCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ModernTheme.accentColor.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.mic,
                            color: ModernTheme.accentColor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ti è piaciuto il Voice Coaching?',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Passa a Pro per usarlo sempre!',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ModernButton(
                      text: 'Scopri i Piani Premium',
                      isOutlined: true,
                      onPressed: () {
                        // TODO: Navigate to subscription screen
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

              // Generate plan button
              SizedBox(
                width: double.infinity,
                child: ModernButton(
                  text: 'Genera la Mia Scheda',
                  icon: Icons.auto_awesome,
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/main',
                      (route) => false,
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Skip button
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/main',
                      (route) => false,
                    );
                  },
                  child: const Text('Salta per ora'),
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
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getCompletionColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 50) return Colors.orange;
    return Colors.red;
  }

  Color _getDifficultyColor(double difficulty) {
    if (difficulty > 4) return Colors.red;
    if (difficulty > 3) return Colors.orange;
    if (difficulty < 2) return Colors.green;
    return ModernTheme.accentColor;
  }
}
