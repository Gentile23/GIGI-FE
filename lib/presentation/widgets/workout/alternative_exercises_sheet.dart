import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/models/workout_model.dart';
import '../../../data/services/exercise_service.dart';
import '../../../data/services/api_client.dart';
import '../../screens/workout/exercise_detail_screen.dart';

/// Bottom sheet that shows alternative exercises (bodyweight <-> equipment)
class AlternativeExercisesSheet extends StatefulWidget {
  final Exercise currentExercise;
  final Function(Exercise)? onExerciseSelected;

  const AlternativeExercisesSheet({
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
      builder: (context) => AlternativeExercisesSheet(
        currentExercise: exercise,
        onExerciseSelected: onExerciseSelected,
      ),
    );
  }

  @override
  State<AlternativeExercisesSheet> createState() =>
      _AlternativeExercisesSheetState();
}

class _AlternativeExercisesSheetState extends State<AlternativeExercisesSheet> {
  late ExerciseService _exerciseService;
  List<Exercise> _alternatives = [];
  String _currentType = '';

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _exerciseService = ExerciseService(ApiClient());
    _loadAlternatives();
  }

  Future<void> _loadAlternatives() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _exerciseService.getAlternativeExercises(
      widget.currentExercise.id,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _alternatives = result['alternatives'] as List<Exercise>;
          _currentType = result['currentType'] as String;
        } else {
          _error = result['message'] as String?;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBodyweight = _currentType == 'bodyweight';
    final alternativeTypeLabel = isBodyweight
        ? 'Con Attrezzatura'
        : 'A Corpo Libero';
    final currentTypeLabel = isBodyweight ? 'Corpo Libero' : 'Con Attrezzatura';

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
                Row(
                  children: [
                    Icon(
                      isBodyweight ? Icons.swap_horiz : Icons.swap_horiz,
                      color: CleanTheme.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Alternative $alternativeTypeLabel',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Current exercise info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CleanTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CleanTheme.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isBodyweight
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          currentTypeLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isBodyweight ? Colors.green : Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.currentExercise.name,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: CleanTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.grey),
          // Content
          Expanded(child: _buildContent(isBodyweight)),
        ],
      ),
    );
  }

  Widget _buildContent(bool showEquipmentAlternatives) {
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
                onPressed: _loadAlternatives,
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

    if (_alternatives.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                showEquipmentAlternatives
                    ? Icons.fitness_center
                    : Icons.accessibility_new,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                showEquipmentAlternatives
                    ? 'Nessuna alternativa con attrezzatura trovata'
                    : 'Nessuna alternativa a corpo libero trovata',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: CleanTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Prova a cercare esercizi simili invece',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: CleanTheme.textTertiary,
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
      itemCount: _alternatives.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final exercise = _alternatives[index];
        final isBodyweight = exercise.equipment.contains('Bodyweight');

        return _AlternativeCard(
          exercise: exercise,
          isBodyweight: isBodyweight,
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

class _AlternativeCard extends StatelessWidget {
  final Exercise exercise;
  final bool isBodyweight;
  final VoidCallback onTap;

  const _AlternativeCard({
    required this.exercise,
    required this.isBodyweight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CleanTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isBodyweight
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.blue.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Type indicator
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isBodyweight
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isBodyweight ? Icons.accessibility_new : Icons.fitness_center,
                color: isBodyweight ? Colors.green : Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Exercise info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CleanTheme.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isBodyweight
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isBodyweight ? 'Corpo Libero' : 'Attrezzatura',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isBodyweight ? Colors.green : Colors.blue,
                          ),
                        ),
                      ),
                    ],
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
                    children: exercise.equipment.take(3).map((eq) {
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
}
