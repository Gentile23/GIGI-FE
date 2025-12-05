import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';

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

    Navigator.pop(context, assessmentData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Valutazione Post-Allenamento',
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
              'Aiutaci a capire meglio il tuo livello',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rispondi a queste domande per creare il piano perfetto per te',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: CleanTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            _buildQuestionCard(
              'Come ti senti dopo l\'allenamento?',
              Column(
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return RadioListTile<int>(
                    title: Text(
                      _getFeelingLabel(value),
                      style: GoogleFonts.inter(color: CleanTheme.textPrimary),
                    ),
                    value: value,
                    groupValue: _overallFeeling,
                    onChanged: (val) => setState(() => _overallFeeling = val!),
                    activeColor: CleanTheme.primaryColor,
                  );
                }),
              ),
            ),

            _buildQuestionCard(
              'Quanto tempo per recuperare il respiro?',
              Column(
                children: [
                  Slider(
                    value: _recoveryTime.toDouble(),
                    min: 1,
                    max: 30,
                    divisions: 29,
                    label: '$_recoveryTime minuti',
                    activeColor: CleanTheme.primaryColor,
                    inactiveColor: CleanTheme.borderSecondary,
                    onChanged: (val) =>
                        setState(() => _recoveryTime = val.toInt()),
                  ),
                  Text(
                    '$_recoveryTime minuti',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            _buildQuestionCard(
              'Hai avuto dolori muscolari?',
              Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'Sì, ho avuto dolori',
                      style: GoogleFonts.inter(color: CleanTheme.textPrimary),
                    ),
                    value: _hadMuscleSoreness,
                    onChanged: (val) =>
                        setState(() => _hadMuscleSoreness = val),
                    activeColor: CleanTheme.primaryColor,
                  ),
                  if (_hadMuscleSoreness) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Intensità del dolore:',
                      style: GoogleFonts.inter(color: CleanTheme.textSecondary),
                    ),
                    Slider(
                      value: _sorenessIntensity.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _getSorenessLabel(_sorenessIntensity),
                      activeColor: CleanTheme.accentOrange,
                      inactiveColor: CleanTheme.borderSecondary,
                      onChanged: (val) =>
                          setState(() => _sorenessIntensity = val.toInt()),
                    ),
                  ],
                ],
              ),
            ),

            _buildQuestionCard(
              'Livello di energia dopo l\'allenamento',
              Column(
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return RadioListTile<int>(
                    title: Text(
                      _getEnergyLabel(value),
                      style: GoogleFonts.inter(color: CleanTheme.textPrimary),
                    ),
                    value: value,
                    groupValue: _energyLevel,
                    onChanged: (val) => setState(() => _energyLevel = val!),
                    activeColor: CleanTheme.primaryColor,
                  );
                }),
              ),
            ),

            _buildQuestionCard(
              'Potevi fare di più?',
              SwitchListTile(
                title: Text(
                  'Sì, potevo continuare',
                  style: GoogleFonts.inter(color: CleanTheme.textPrimary),
                ),
                value: _couldDoMore,
                onChanged: (val) => setState(() => _couldDoMore = val),
                activeColor: CleanTheme.primaryColor,
              ),
            ),

            _buildQuestionCard(
              'Note aggiuntive (opzionale)',
              TextField(
                maxLines: 3,
                style: GoogleFonts.inter(color: CleanTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Es: Ho trovato difficile l\'esercizio X...',
                  hintStyle: GoogleFonts.inter(color: CleanTheme.textTertiary),
                  filled: true,
                  fillColor: CleanTheme.backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: CleanTheme.borderPrimary,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: CleanTheme.borderPrimary,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: CleanTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (val) => _additionalNotes = val,
              ),
            ),

            const SizedBox(height: 32),

            CleanButton(
              text: 'Completa Valutazione',
              icon: Icons.check,
              width: double.infinity,
              onPressed: _submitAssessment,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(String question, Widget content) {
    return CleanCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
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
