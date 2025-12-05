import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/adaptive_training_model.dart';
import '../../../data/services/adaptive_training_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';

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
            content: Text('Recupero registrato! ${score.readinessLabel}'),
            backgroundColor: score.readinessColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Tracciamento Recupero',
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
            if (_todayScore != null) ...[
              _buildRecoveryScoreCard(_todayScore!),
              const SizedBox(height: 24),
            ],

            Text(
              'Come ti senti oggi?',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Traccia il tuo recupero per raccomandazioni personalizzate',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: CleanTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            _buildSlider(
              'Qualità Sonno',
              Icons.bedtime_outlined,
              _sleepQuality,
              (value) => setState(() => _sleepQuality = value),
              ['Scarsa', 'Sufficiente', 'Buona', 'Ottima', 'Eccellente'],
              CleanTheme.accentBlue,
            ),
            const SizedBox(height: 16),

            _buildSlider(
              'Dolori Muscolari',
              Icons.fitness_center_outlined,
              _muscleSoreness,
              (value) => setState(() => _muscleSoreness = value),
              ['Nessuno', 'Leggeri', 'Moderati', 'Forti', 'Severi'],
              CleanTheme.accentOrange,
            ),
            const SizedBox(height: 16),

            _buildSlider(
              'Livello Stress',
              Icons.psychology_outlined,
              _stressLevel,
              (value) => setState(() => _stressLevel = value),
              ['Molto Basso', 'Basso', 'Moderato', 'Alto', 'Molto Alto'],
              CleanTheme.accentPurple,
            ),
            const SizedBox(height: 16),

            _buildSlider(
              'Livello Energia',
              Icons.bolt_outlined,
              _energyLevel,
              (value) => setState(() => _energyLevel = value),
              ['Molto Basso', 'Basso', 'Moderato', 'Alto', 'Molto Alto'],
              CleanTheme.accentGreen,
            ),
            const SizedBox(height: 32),

            CleanButton(
              text: 'Invia Dati Recupero',
              icon: Icons.check_circle_outline,
              width: double.infinity,
              onPressed: _isSubmitting ? null : _submitRecovery,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRecoveryScoreCard(RecoveryScore score) {
    final scorePercentage = ((score.calculatedScore ?? 0) * 100).toInt();

    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: score.readinessColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_rounded,
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
                  'Punteggio Recupero',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CleanTheme.textSecondary,
                  ),
                ),
                Text(
                  '$scorePercentage%',
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: score.readinessColor,
                  ),
                ),
                Text(
                  score.readinessLabel,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: score.readinessColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
    Color accentColor,
  ) {
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
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor,
              inactiveTrackColor: CleanTheme.borderSecondary,
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: labels[value - 1],
              onChanged: (val) => onChanged(val.toInt()),
            ),
          ),
          Center(
            child: Text(
              labels[value - 1],
              style: GoogleFonts.inter(
                fontSize: 14,
                color: accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
