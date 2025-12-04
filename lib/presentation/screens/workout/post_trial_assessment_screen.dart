import 'package:flutter/material.dart';
import '../../../core/theme/modern_theme.dart';
import '../../widgets/modern_widgets.dart';

class PostTrialAssessmentScreen extends StatefulWidget {
  const PostTrialAssessmentScreen({super.key});

  @override
  State<PostTrialAssessmentScreen> createState() =>
      _PostTrialAssessmentScreenState();
}

class _PostTrialAssessmentScreenState extends State<PostTrialAssessmentScreen> {
  int _overallFeeling = 3;
  int _recoveryTime = 5;
  bool _hadMuscleSoreness = false;
  int _sorenessIntensity = 3;
  int _energyLevel = 3;
  bool _couldDoMore = false;
  String _additionalNotes = '';

  void _submitAssessment() {
    final assessmentData = {
      'overall_feeling': _overallFeeling,
      'recovery_time_minutes': _recoveryTime,
      'had_muscle_soreness': _hadMuscleSoreness,
      'soreness_intensity': _hadMuscleSoreness ? _sorenessIntensity : null,
      'energy_level': _energyLevel,
      'could_do_more': _couldDoMore,
      'additional_notes': _additionalNotes.isNotEmpty ? _additionalNotes : null,
    };

    // Return assessment data to previous screen
    Navigator.pop(context, assessmentData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Valutazione Post-Allenamento'),
        backgroundColor: ModernTheme.cardColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aiutaci a capire meglio il tuo livello',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Rispondi a queste domande per permetterci di creare il piano perfetto per te',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            // Overall Feeling
            _buildQuestionCard(
              'Come ti senti dopo l\'allenamento?',
              Column(
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return RadioListTile<int>(
                    title: Text(_getFeelingLabel(value)),
                    value: value,
                    groupValue: _overallFeeling,
                    onChanged: (val) => setState(() => _overallFeeling = val!),
                    activeColor: ModernTheme.accentColor,
                  );
                }),
              ),
            ),

            // Recovery Time
            _buildQuestionCard(
              'Quanto tempo ti ci è voluto per recuperare il respiro?',
              Column(
                children: [
                  Slider(
                    value: _recoveryTime.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    label: '$_recoveryTime minuti',
                    activeColor: ModernTheme.accentColor,
                    onChanged: (val) =>
                        setState(() => _recoveryTime = val.toInt()),
                  ),
                  Text('$_recoveryTime minuti'),
                ],
              ),
            ),

            // Muscle Soreness
            _buildQuestionCard(
              'Hai avuto dolori muscolari durante o dopo?',
              Column(
                children: [
                  SwitchListTile(
                    title: const Text('Sì, ho avuto dolori'),
                    value: _hadMuscleSoreness,
                    onChanged: (val) =>
                        setState(() => _hadMuscleSoreness = val),
                    activeColor: ModernTheme.accentColor,
                  ),
                  if (_hadMuscleSoreness) ...[
                    const SizedBox(height: 16),
                    Text('Intensità del dolore:'),
                    Slider(
                      value: _sorenessIntensity.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _getSorenessLabel(_sorenessIntensity),
                      activeColor: ModernTheme.accentColor,
                      onChanged: (val) =>
                          setState(() => _sorenessIntensity = val.toInt()),
                    ),
                  ],
                ],
              ),
            ),

            // Energy Level
            _buildQuestionCard(
              'Livello di energia dopo l\'allenamento',
              Column(
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return RadioListTile<int>(
                    title: Text(_getEnergyLabel(value)),
                    value: value,
                    groupValue: _energyLevel,
                    onChanged: (val) => setState(() => _energyLevel = val!),
                    activeColor: ModernTheme.accentColor,
                  );
                }),
              ),
            ),

            // Could Do More
            _buildQuestionCard(
              'Potevi fare di più?',
              SwitchListTile(
                title: const Text('Sì, potevo continuare'),
                value: _couldDoMore,
                onChanged: (val) => setState(() => _couldDoMore = val),
                activeColor: ModernTheme.accentColor,
              ),
            ),

            // Additional Notes
            _buildQuestionCard(
              'Note aggiuntive (opzionale)',
              TextField(
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Es: Ho trovato difficile l\'esercizio X...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => _additionalNotes = val,
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            ModernButton(
              text: 'Completa Valutazione',
              onPressed: _submitAssessment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(String question, Widget content) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  String _getFeelingLabel(int value) {
    switch (value) {
      case 1:
        return '😰 Esausto';
      case 2:
        return '😓 Molto stanco';
      case 3:
        return '😐 Stanco ma ok';
      case 4:
        return '🙂 Bene';
      case 5:
        return '😊 Ottimo';
      default:
        return '';
    }
  }

  String _getSorenessLabel(int value) {
    switch (value) {
      case 1:
        return 'Leggero';
      case 2:
        return 'Moderato';
      case 3:
        return 'Medio';
      case 4:
        return 'Forte';
      case 5:
        return 'Molto forte';
      default:
        return '';
    }
  }

  String _getEnergyLabel(int value) {
    switch (value) {
      case 1:
        return '😴 Completamente scarico';
      case 2:
        return '😓 Molto basso';
      case 3:
        return '😐 Normale';
      case 4:
        return '🙂 Buono';
      case 5:
        return '⚡ Pieno di energia';
      default:
        return '';
    }
  }
}
