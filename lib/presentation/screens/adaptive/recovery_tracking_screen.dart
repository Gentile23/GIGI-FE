import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/adaptive_training_model.dart';
import '../../../data/services/adaptive_training_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/modern_theme.dart';
import '../../widgets/modern_widgets.dart';

class RecoveryTrackingScreen extends StatefulWidget {
  const RecoveryTrackingScreen({super.key});

  @override
  State<RecoveryTrackingScreen> createState() => _RecoveryTrackingScreenState();
}

class _RecoveryTrackingScreenState extends State<RecoveryTrackingScreen> {
  late final AdaptiveTrainingService _adaptiveService;

  int _sleepQuality = 3;
  int _muscleSoreness = 3;
  int _stressLevel = 3;
  int _energyLevel = 3;
  bool _isSubmitting = false;
  RecoveryScore? _todayScore;

  @override
  void initState() {
    super.initState();
    _adaptiveService = AdaptiveTrainingService(ApiClient());
  }

  Future<void> _submitRecovery() async {
    setState(() => _isSubmitting = true);

    final score = await _adaptiveService.submitRecoveryData(
      sleepQuality: _sleepQuality,
      muscleSoreness: _muscleSoreness,
      stressLevel: _stressLevel,
      energyLevel: _energyLevel,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _todayScore = score;
      });

      if (score != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recovery tracked! ${score.readinessLabel}'),
            backgroundColor: score.readinessColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Recovery Tracking'),
        backgroundColor: ModernTheme.cardColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_todayScore != null) ...[
              _buildRecoveryScoreCard(_todayScore!),
              const SizedBox(height: 24),
            ],

            Text(
              'How are you feeling today?',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your recovery to get personalized recommendations',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            _buildSlider(
              'Sleep Quality',
              Icons.bedtime,
              _sleepQuality,
              (value) => setState(() => _sleepQuality = value),
              ['Poor', 'Fair', 'Good', 'Great', 'Excellent'],
            ),
            const SizedBox(height: 24),

            _buildSlider(
              'Muscle Soreness',
              Icons.fitness_center,
              _muscleSoreness,
              (value) => setState(() => _muscleSoreness = value),
              ['None', 'Light', 'Moderate', 'High', 'Severe'],
            ),
            const SizedBox(height: 24),

            _buildSlider(
              'Stress Level',
              Icons.psychology,
              _stressLevel,
              (value) => setState(() => _stressLevel = value),
              ['Very Low', 'Low', 'Moderate', 'High', 'Very High'],
            ),
            const SizedBox(height: 24),

            _buildSlider(
              'Energy Level',
              Icons.bolt,
              _energyLevel,
              (value) => setState(() => _energyLevel = value),
              ['Very Low', 'Low', 'Moderate', 'High', 'Very High'],
            ),
            const SizedBox(height: 40),

            ModernButton(
              text: 'Submit Recovery Data',
              icon: Icons.check_circle,
              onPressed: _isSubmitting ? null : _submitRecovery,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecoveryScoreCard(RecoveryScore score) {
    final scorePercentage = ((score.calculatedScore ?? 0) * 100).toInt();

    return ModernCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: score.readinessColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite,
                  color: score.readinessColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recovery Score',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '$scorePercentage%',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: score.readinessColor,
                      ),
                    ),
                    Text(
                      score.readinessLabel,
                      style: TextStyle(
                        fontSize: 14,
                        color: score.readinessColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    IconData icon,
    int value,
    Function(int) onChanged,
    List<String> labels,
  ) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ModernTheme.accentColor),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: ModernTheme.accentColor,
            label: labels[value - 1],
            onChanged: (val) => onChanged(val.toInt()),
          ),
          Text(
            labels[value - 1],
            style: TextStyle(
              fontSize: 14,
              color: ModernTheme.accentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
