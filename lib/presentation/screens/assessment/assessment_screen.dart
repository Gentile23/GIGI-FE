import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';

class AssessmentIntroScreen extends StatelessWidget {
  const AssessmentIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Workout di Valutazione',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: CleanTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Completa 3 workout di valutazione per permettere alla nostra AI di capire il tuo livello',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: CleanTheme.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // Info cards
              Expanded(
                child: ListView(
                  children: [
                    _buildInfoCard(
                      icon: Icons.assessment_outlined,
                      title: 'Perché la Valutazione?',
                      description:
                          'Questi workout ci aiutano a capire il tuo livello attuale, i tuoi punti di forza e le aree di miglioramento.',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.timer_outlined,
                      title: 'Quanto Tempo?',
                      description:
                          'Ogni valutazione richiede 20-30 minuti. Puoi completarle al tuo ritmo.',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.fitness_center_outlined,
                      title: 'Cosa Aspettarsi?',
                      description:
                          'Un mix di esercizi di forza, resistenza e mobilità per valutare il tuo fitness generale.',
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Piani Personalizzati',
                      description:
                          'Dopo il completamento, riceverai un piano di allenamento personalizzato.',
                    ),
                  ],
                ),
              ),

              // Progress indicator
              CleanCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Il Tuo Progresso',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: 0 / 3,
                        backgroundColor: CleanTheme.borderSecondary,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          CleanTheme.primaryColor,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '0 di 3 valutazioni completate',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Start button
              CleanButton(
                text: 'Inizia Prima Valutazione',
                width: double.infinity,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const AssessmentWorkoutScreen(assessmentNumber: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return CleanCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: CleanTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: CleanTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CleanTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AssessmentWorkoutScreen extends StatefulWidget {
  final int assessmentNumber;

  const AssessmentWorkoutScreen({super.key, required this.assessmentNumber});

  @override
  State<AssessmentWorkoutScreen> createState() =>
      _AssessmentWorkoutScreenState();
}

class _AssessmentWorkoutScreenState extends State<AssessmentWorkoutScreen> {
  int _currentExerciseIndex = 0;
  final List<Map<String, dynamic>> _exercises = [
    {
      'name': 'Push-ups',
      'description': 'Fai quante più push-up riesci con buona forma',
      'type': 'max_reps',
      'completed': false,
      'result': 0,
    },
    {
      'name': 'Squat a Corpo Libero',
      'description': 'Fai quanti più squat riesci in 60 secondi',
      'type': 'timed',
      'duration': 60,
      'completed': false,
      'result': 0,
    },
    {
      'name': 'Plank',
      'description': 'Mantieni la posizione di plank il più a lungo possibile',
      'type': 'duration',
      'completed': false,
      'result': 0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentExercise = _exercises[_currentExerciseIndex];

    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Valutazione ${widget.assessmentNumber}/3',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
      ),
      body: Column(
        children: [
          // Progress
          ClipRRect(
            child: LinearProgressIndicator(
              value: (_currentExerciseIndex + 1) / _exercises.length,
              backgroundColor: CleanTheme.borderSecondary,
              valueColor: const AlwaysStoppedAnimation<Color>(
                CleanTheme.primaryColor,
              ),
              minHeight: 4,
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise info
                  Text(
                    currentExercise['name'],
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentExercise['description'],
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: CleanTheme.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Video placeholder
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: CleanTheme.borderSecondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 64,
                        color: CleanTheme.textTertiary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Instructions
                  CleanCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Istruzioni',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CleanTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInstruction(
                          '1. Posizionati nella posizione iniziale',
                        ),
                        _buildInstruction('2. Esegui l\'esercizio'),
                        _buildInstruction('3. Registra il tuo risultato'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Result input
                  CleanCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registra il Tuo Risultato',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CleanTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(
                            color: CleanTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: currentExercise['type'] == 'max_reps'
                                ? 'Numero di ripetizioni'
                                : 'Secondi',
                            labelStyle: GoogleFonts.inter(
                              color: CleanTheme.textSecondary,
                            ),
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
                          onChanged: (value) {
                            currentExercise['result'] =
                                int.tryParse(value) ?? 0;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Next button
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: CleanButton(
              text: _currentExerciseIndex == _exercises.length - 1
                  ? 'Completa Valutazione'
                  : 'Esercizio Successivo',
              width: double.infinity,
              onPressed: _nextExercise,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 20,
            color: CleanTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CleanTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextExercise() {
    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() {
        _exercises[_currentExerciseIndex]['completed'] = true;
        _currentExerciseIndex++;
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          '🎉 Valutazione Completata!',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        content: Text(
          widget.assessmentNumber == 3
              ? 'Ottimo lavoro! Hai completato tutte le valutazioni. Il tuo piano personalizzato sta per essere generato.'
              : 'Ottimo lavoro! Valutazione ${widget.assessmentNumber} completata. Ancora ${3 - widget.assessmentNumber} da fare!',
          style: GoogleFonts.inter(color: CleanTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close assessment screen
            },
            child: Text(
              'Fatto',
              style: GoogleFonts.inter(
                color: CleanTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
