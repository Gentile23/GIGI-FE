import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/workout_provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/models/injury_model.dart';
import '../../../data/models/training_preferences_model.dart';
import '../../../data/models/workout_model.dart';

/// Screen for generating AI-powered workout plan
class AIWorkoutGenerationScreen extends StatefulWidget {
  final UserModel user;
  final UserProfile profile;

  const AIWorkoutGenerationScreen({
    super.key,
    required this.user,
    required this.profile,
  });

  @override
  State<AIWorkoutGenerationScreen> createState() =>
      _AIWorkoutGenerationScreenState();
}

class _AIWorkoutGenerationScreenState extends State<AIWorkoutGenerationScreen> {
  bool _isGenerating = false;
  WorkoutPlan? _generatedPlan;
  String? _errorMessage;

  Future<void> _generatePlan() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedPlan = null;
    });

    try {
      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );

      final success = await workoutProvider.generatePlan();

      if (success) {
        setState(() {
          _generatedPlan = workoutProvider.currentPlan;
        });
      } else {
        setState(() {
          _errorMessage = workoutProvider.error ?? 'Errore sconosciuto';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore durante la generazione: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  // ... (build method remains same)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Genera Scheda AI')),
      body: _generatedPlan != null ? _buildPlanView() : _buildGenerationView(),
    );
  }

  Widget _buildGenerationView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.auto_awesome, size: 60, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Scheda Personalizzata AI',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Profile Summary
          const Text(
            'Riepilogo Profilo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _buildInfoCard(
            icon: Icons.person,
            title: 'Informazioni Base',
            items: [
              'Nome: ${widget.user.name}',
              if (widget.user.gender != null) 'Genere: ${widget.user.gender}',
              if (widget.user.height != null)
                'Altezza: ${widget.user.height} cm',
              if (widget.user.weight != null) 'Peso: ${widget.user.weight} kg',
            ],
          ),

          _buildInfoCard(
            icon: Icons.flag,
            title: 'Obiettivi',
            items: [
              'Obiettivo: ${_getGoalName(widget.profile.goal)}',
              'Livello: ${_getLevelName(widget.profile.level)}',
              'Frequenza: ${widget.profile.weeklyFrequency} giorni/settimana',
              'Luogo: ${widget.profile.location == TrainingLocation.gym ? "Palestra" : "Casa"}',
            ],
          ),

          if (widget.profile.trainingPreferences != null)
            _buildInfoCard(
              icon: Icons.fitness_center,
              title: 'Preferenze Allenamento',
              items: [
                'Split: ${widget.profile.trainingPreferences!.trainingSplit.displayName}',
                'Durata: ${widget.profile.trainingPreferences!.sessionDurationMinutes} min',
                'Cardio: ${widget.profile.trainingPreferences!.cardioPreference.displayName}',
                'Mobilità: ${widget.profile.trainingPreferences!.mobilityPreference.displayName}',
              ],
            ),

          if (widget.profile.injuries.isNotEmpty) _buildInjuriesCard(),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Cooldown Check
          Consumer<WorkoutProvider>(
            builder: (context, workoutProvider, _) {
              final canGenerate = workoutProvider.canGenerateNewPlan(
                widget.user,
              );
              final daysRemaining = workoutProvider.getDaysUntilNextGeneration(
                widget.user,
              );

              if (!canGenerate) {
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: Colors.orange.shade700,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Prossima generazione disponibile tra',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$daysRemaining ${daysRemaining == 1 ? "giorno" : "giorni"}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Generate Button
          Consumer<WorkoutProvider>(
            builder: (context, workoutProvider, _) {
              final canGenerate = workoutProvider.canGenerateNewPlan(
                widget.user,
              );

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isGenerating || !canGenerate)
                      ? null
                      : _generatePlan,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isGenerating
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Generazione in corso...',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome),
                            SizedBox(width: 8),
                            Text(
                              'Genera Scheda AI',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              );
            },
          ),

          if (_isGenerating) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Stiamo creando la tua scheda personalizzata. Questo potrebbe richiedere alcuni secondi...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPlanView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 48, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scheda Generata!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_generatedPlan!.workouts.length} giorni di allenamento',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Plan details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Durata: ${_generatedPlan!.durationWeeks} settimane',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.repeat, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Frequenza: ${_generatedPlan!.weeklyFrequency} giorni/settimana',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Workouts
          const Text(
            'Giorni di Allenamento',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ..._generatedPlan!.workouts.asMap().entries.map((entry) {
            return _buildWorkoutDayCard(entry.value, entry.key + 1);
          }),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _generatedPlan = null;
                      _errorMessage = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Rigenera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Plan is already saved in provider state by generateCustomPlan
                    // We just need to navigate back to home
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Scheda salvata!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Navigate to main screen, removing all previous routes
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/main', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Salva Scheda'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInjuriesCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Infortuni da Considerare',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...widget.profile.injuries.map(
              (injury) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      injury.category.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            injury.area.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${injury.severity.displayName} - ${injury.status.displayName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutDayCard(WorkoutDay day, int dayNumber) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue,
            child: Text(
              '$dayNumber',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            day.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${day.exercises.length} esercizi • ${day.estimatedDuration} min',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (day.focus.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.track_changes,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Focus: ${day.focus}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ...day.exercises.asMap().entries.map((entry) {
                    final exercise = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  exercise.exercise.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildExerciseDetail(
                                Icons.repeat,
                                '${exercise.sets} serie',
                              ),
                              const SizedBox(width: 16),
                              _buildExerciseDetail(
                                Icons.fitness_center,
                                '${exercise.reps} rip',
                              ),
                              const SizedBox(width: 16),
                              _buildExerciseDetail(
                                Icons.timer,
                                '${exercise.restSeconds}s',
                              ),
                            ],
                          ),
                          if (exercise.notes != null &&
                              exercise.notes!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    size: 16,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      exercise.notes!,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  String _getGoalName(FitnessGoal? goal) {
    if (goal == null) return 'Non specificato';
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Perdita peso';
      case FitnessGoal.muscleGain:
        return 'Massa muscolare';
      case FitnessGoal.toning:
        return 'Tonificazione';
      case FitnessGoal.strength:
        return 'Forza';
      case FitnessGoal.wellness:
        return 'Benessere';
    }
  }

  String _getLevelName(ExperienceLevel? level) {
    if (level == null) return 'Non specificato';
    switch (level) {
      case ExperienceLevel.beginner:
        return 'Principiante';
      case ExperienceLevel.intermediate:
        return 'Intermedio';
      case ExperienceLevel.advanced:
        return 'Avanzato';
    }
  }
}
