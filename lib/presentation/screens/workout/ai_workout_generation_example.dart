import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/models/injury_model.dart';
import '../../../data/models/training_preferences_model.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/workout_service.dart';

/// Example screen showing how to use the AI workout plan generation
class AIWorkoutGenerationExample extends StatefulWidget {
  const AIWorkoutGenerationExample({super.key});

  @override
  State<AIWorkoutGenerationExample> createState() =>
      _AIWorkoutGenerationExampleState();
}

class _AIWorkoutGenerationExampleState
    extends State<AIWorkoutGenerationExample> {
  bool _isGenerating = false;
  String? _errorMessage;

  Future<void> _generateWorkoutPlan() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      // Example user data
      final user = UserModel(
        id: '1',
        email: 'user@example.com',
        name: 'Mario Rossi',
        gender: 'Maschio',
        dateOfBirth: DateTime(1990, 1, 1),
        height: 175,
        weight: 75,
        createdAt: DateTime.now(),
      );

      // Example injuries
      final injuries = [
        InjuryModel(
          id: '1',
          category: InjuryCategory.articular,
          area: InjuryArea.knee,
          severity: InjurySeverity.moderate,
          status: InjuryStatus.recovering,
          notes: 'Dolore al ginocchio destro durante squat profondi',
          reportedAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        InjuryModel(
          id: '2',
          category: InjuryCategory.muscular,
          area: InjuryArea.lowerBack,
          severity: InjurySeverity.mild,
          status: InjuryStatus.recovering,
          notes: 'Leggero fastidio lombare',
          reportedAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
      ];

      // Example training preferences
      final trainingPreferences = TrainingPreferences(
        id: '1',
        trainingSplit: TrainingSplit.pushPullLegs,
        sessionDurationMinutes: 60,
        cardioPreference: CardioPreference.none,
        mobilityPreference: MobilityPreference.postWorkout,
        additionalNotes: ['Preferisco allenarmi al mattino'],
      );

      // Example user profile
      final profile = UserProfile(
        userId: user.id,
        goal: FitnessGoal.muscleGain,
        level: ExperienceLevel.intermediate,
        weeklyFrequency: 4,
        trainingLocation: TrainingLocation.gym,
        availableEquipment: [
          Equipment.barbell,
          Equipment.dumbbells,
          Equipment.machines,
          Equipment.bench,
        ],
        limitations: [],
        injuries: injuries,
        trainingPreferences: trainingPreferences,
      );

      // Generate AI workout plan
      final apiClient = ApiClient();
      final workoutService = WorkoutService(apiClient);

      final result = await workoutService.generateAIPlan(
        user: user,
        profile: profile,
        language: Localizations.localeOf(context).languageCode,
      );

      if (result['success'] == true) {
        final plan = result['plan'];
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Scheda generata con successo! ${plan.workouts.length} giorni di allenamento',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Errore sconosciuto';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generazione Scheda AI')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Genera una scheda di allenamento personalizzata',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Utilizziamo AI per creare una scheda su misura per te, considerando i tuoi obiettivi, infortuni e preferenze.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isGenerating ? null : _generateWorkoutPlan,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                ),
                child: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Genera Scheda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
