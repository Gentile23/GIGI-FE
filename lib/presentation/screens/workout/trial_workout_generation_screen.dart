import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/services/trial_workout_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
import 'trial_workout_screen.dart';

class TrialWorkoutGenerationScreen extends StatefulWidget {
  const TrialWorkoutGenerationScreen({super.key});

  @override
  State<TrialWorkoutGenerationScreen> createState() =>
      _TrialWorkoutGenerationScreenState();
}

class _TrialWorkoutGenerationScreenState
    extends State<TrialWorkoutGenerationScreen> {
  bool _isGenerating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateTrialWorkout();
  }

  Future<void> _generateTrialWorkout() async {
    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final apiClient = ApiClient();
      final trialService = TrialWorkoutService(apiClient);

      final trialWorkout = await trialService.generateTrialWorkout();

      if (mounted) {
        if (trialWorkout != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TrialWorkoutScreen(trialWorkout: trialWorkout),
            ),
          );
        } else {
          setState(() {
            _error = 'Impossibile generare il trial workout';
            _isGenerating = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Errore: $e';
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isGenerating) ...[
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CleanTheme.primaryLight,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: CleanTheme.primaryColor,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Generazione Trial Workout',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: CleanTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Stiamo creando il tuo allenamento di prova personalizzato...',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: CleanTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  CleanCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: CleanTheme.accentPurple.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mic_outlined,
                            color: CleanTheme.accentPurple,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '🎤 Voice Coaching GRATIS',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: CleanTheme.accentPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Prova il coach vocale AI durante questo trial!',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: CleanTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ] else if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: CleanTheme.accentRed.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: CleanTheme.accentRed,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Errore',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Text(
                      _error!,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: CleanTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  CleanButton(
                    text: 'Riprova',
                    icon: Icons.refresh,
                    onPressed: _generateTrialWorkout,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
