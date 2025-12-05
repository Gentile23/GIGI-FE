import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/models/workout_model.dart';
import '../../../data/services/exercise_service.dart';
import '../../../data/services/api_client.dart';
import '../../screens/workout/exercise_detail_screen.dart';

/// Bottom sheet that shows exercises targeting the same muscle groups
class SimilarExercisesSheet extends StatefulWidget {
  final Exercise currentExercise;
  final Function(Exercise)? onExerciseSelected;

  const SimilarExercisesSheet({
    super.key,
    required this.currentExercise,
    this.onExerciseSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required Exercise exercise,
    Function(Exercise)? onExerciseSelected,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SimilarExercisesSheet(
        currentExercise: exercise,
        onExerciseSelected: onExerciseSelected,
      ),
    );
  }

  @override
  State<SimilarExercisesSheet> createState() => _SimilarExercisesSheetState();
}

class _SimilarExercisesSheetState extends State<SimilarExercisesSheet> {
  late ExerciseService _exerciseService;
  List<Exercise> _similarExercises = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _exerciseService = ExerciseService(ApiClient());
    _loadSimilarExercises();
  }

  Future<void> _loadSimilarExercises() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _exerciseService.getSimilarExercises(
      widget.currentExercise.id,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _similarExercises = result['exercises'] as List<Exercise>;
        } else {
          _error = result['message'] as String?;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final muscleGroups = widget.currentExercise.muscleGroups.join(', ');

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Esercizi Simili',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Esercizi che stimolano: $muscleGroups',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.grey),
          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: CleanTheme.primaryColor),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: CleanTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSimilarExercises,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CleanTheme.primaryColor,
                ),
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      );
    }

    if (_similarExercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Nessun esercizio simile trovato',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: CleanTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _similarExercises.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final exercise = _similarExercises[index];
        return _ExerciseCard(
          exercise: exercise,
          onTap: () {
            if (widget.onExerciseSelected != null) {
              widget.onExerciseSelected!(exercise);
              Navigator.pop(context);
            } else {
              // Navigate to exercise detail
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseDetailScreen(
                    workoutExercise: WorkoutExercise(
                      exercise: exercise,
                      sets: 3,
                      reps: '10',
                      restSeconds: 60,
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;

  const _ExerciseCard({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CleanTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!, width: 1),
        ),
        child: Row(
          children: [
            // Muscle group indicator
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: CleanTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconForMuscleGroup(exercise.muscleGroups.firstOrNull ?? ''),
                color: CleanTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exercise.muscleGroups.join(' • '),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Equipment chips
                  Wrap(
                    spacing: 6,
                    children: exercise.equipment.take(2).map((eq) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          eq,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: CleanTheme.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }

  IconData _getIconForMuscleGroup(String muscleGroup) {
    switch (muscleGroup.toLowerCase()) {
      case 'chest':
        return Icons.fitness_center;
      case 'back':
        return Icons.accessibility_new;
      case 'shoulders':
        return Icons.sports_gymnastics;
      case 'biceps':
      case 'triceps':
        return Icons.front_hand;
      case 'quadriceps':
      case 'hamstrings':
      case 'glutes':
      case 'calves':
        return Icons.directions_walk;
      case 'abs':
      case 'core':
        return Icons.self_improvement;
      default:
        return Icons.fitness_center;
    }
  }
}
