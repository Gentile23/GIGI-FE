import 'package:flutter/material.dart';
import '../../../data/services/trial_workout_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/modern_theme.dart';
import '../../widgets/modern_widgets.dart';
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
      backgroundColor: ModernTheme.backgroundColor,
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
                      gradient: LinearGradient(
                        colors: [ModernTheme.accentColor, Colors.purple],
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Generazione Trial Workout',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Stiamo creando il tuo allenamento di prova personalizzato...',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ModernTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ModernTheme.accentColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.mic,
                          color: ModernTheme.accentColor,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '🎤 Voice Coaching GRATIS',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: ModernTheme.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Prova il coach vocale AI durante questo trial!',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ] else if (_error != null) ...[
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 24),
                  Text(
                    'Errore',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ModernButton(
                    text: 'Riprova',
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
