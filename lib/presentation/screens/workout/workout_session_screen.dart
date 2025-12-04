import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/workout_model.dart';
import 'package:provider/provider.dart';
import '../../../providers/workout_log_provider.dart';
import '../../../data/models/workout_log_model.dart';
import 'mobility_exercise_screen.dart';
import 'cardio_exercise_screen.dart';
import '../../widgets/workout/dual_anatomical_view.dart';
import '../../widgets/workout/set_logging_widget.dart';
import 'exercise_detail_screen.dart';
import 'mobility_exercise_detail_screen.dart';
import 'cardio_exercise_detail_screen.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final WorkoutDay workoutDay;

  const WorkoutSessionScreen({super.key, required this.workoutDay});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  final Set<String> _completedExercises = {};
  final Set<String> _completedSections =
      {}; // Track completed sections (e.g. 'warmupCardio')
  final Set<String> _skippedSections = {}; // Track skipped sections

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startWorkoutSession();
    });
  }

  Future<void> _startWorkoutSession() async {
    final provider = Provider.of<WorkoutLogProvider>(context, listen: false);
    // Assuming workoutDay has a reference to plan id, or we pass it.
    // For now, we'll just pass workoutDayId.
    // Note: The backend expects workout_day_id.
    await provider.startWorkout(workoutDayId: widget.workoutDay.id);
  }

  @override
  Widget build(BuildContext context) {
    // ... (rest of build method same as before until _buildPreWorkoutNavigationCard) ...
    // Add safety check for empty exercises
    if (widget.workoutDay.exercises.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(widget.workoutDay.name)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 80,
                  color: AppColors.primaryNeon,
                ),
                const SizedBox(height: 24),
                Text('No Exercises', style: AppTextStyles.h3),
                const SizedBox(height: 12),
                Text(
                  'This workout doesn\'t have any exercises yet.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.workoutDay.name),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmExit(),
        ),
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.backgroundLight,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.timer, color: AppColors.primaryNeon),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.workoutDay.estimatedDuration} min estimated',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const Spacer(),
                    // Exercise Type Indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNeon.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryNeon,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('💪', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            'Allenamento',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryNeon,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${widget.workoutDay.mainWorkout.where((e) => _completedExercises.contains(e.exercise.id)).length}/${widget.workoutDay.mainExerciseCount} esercizi completati',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNeon,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Exercise List with Navigation Cards
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pre-Workout Navigation
                  if (widget.workoutDay.warmupCardio.isNotEmpty ||
                      widget.workoutDay.preWorkoutMobility.isNotEmpty) ...[
                    _buildPreWorkoutNavigationCard(),
                    const SizedBox(height: 16),
                  ],

                  // Main Workout Section
                  _buildSectionHeader('Allenamento Principale', '💪'),
                  ...widget.workoutDay.mainWorkout.map((exercise) {
                    return _buildExerciseCard(exercise);
                  }),

                  // Post-Workout Navigation
                  if (widget.workoutDay.postWorkoutExercises.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildPostWorkoutNavigationCard(),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Finish Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _completedExercises.isNotEmpty
                    ? _finishWorkout
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _completedExercises.length ==
                          widget.workoutDay.mainExerciseCount
                      ? Colors.green
                      : AppColors.primaryNeon,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _completedExercises.length ==
                          widget.workoutDay.mainExerciseCount
                      ? 'Completa Allenamento'
                      : 'Termina in Anticipo',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreWorkoutNavigationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryNeon.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Prima dell\'allenamento',
                style: AppTextStyles.h5.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.workoutDay.warmupCardio.isNotEmpty)
            _buildNavigationButton(
              id: 'warmupCardio',
              title: 'Riscaldamento Cardio',
              emoji: '🔥',
              color: const Color(0xFFFF6347),
              onTap: () => _navigateToCardio(
                widget.workoutDay.warmupCardio,
                'Riscaldamento Cardio',
                'warmupCardio',
              ),
            ),
          if (widget.workoutDay.warmupCardio.isNotEmpty &&
              widget.workoutDay.preWorkoutMobility.isNotEmpty)
            const SizedBox(height: 8),
          if (widget.workoutDay.preWorkoutMobility.isNotEmpty)
            _buildNavigationButton(
              id: 'preWorkoutMobility',
              title: 'Mobilità Pre-Workout',
              emoji: '🤸',
              color: const Color(0xFF00CED1),
              onTap: () => _navigateToMobility(
                widget.workoutDay.preWorkoutMobility,
                'Mobilità Pre-Workout',
                'preWorkoutMobility',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostWorkoutNavigationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryNeon.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Dopo l\'allenamento',
                style: AppTextStyles.h5.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Group post-workout exercises by type
          ...widget.workoutDay.postWorkoutExercises
              .fold<Map<String, List<WorkoutExercise>>>({}, (map, exercise) {
                final type = exercise.exerciseType;
                if (!map.containsKey(type)) {
                  map[type] = [];
                }
                map[type]!.add(exercise);
                return map;
              })
              .entries
              .map((entry) {
                final sectionId = 'postWorkout_${entry.key}';
                if (entry.key == 'mobility') {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildNavigationButton(
                      id: sectionId,
                      title: 'Mobilità Post-Workout',
                      emoji: '🧘',
                      color: const Color(0xFF00CED1),
                      onTap: () => _navigateToMobility(
                        entry.value,
                        'Mobilità Post-Workout',
                        sectionId,
                      ),
                    ),
                  );
                } else if (entry.key == 'cardio') {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildNavigationButton(
                      id: sectionId,
                      title: 'Cardio Post-Workout',
                      emoji: '🏃',
                      color: const Color(0xFFFF6347),
                      onTap: () => _navigateToCardio(
                        entry.value,
                        'Cardio Post-Workout',
                        sectionId,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required String id,
    required String title,
    required String emoji,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isCompleted = _completedSections.contains(id);
    final isSkipped = _skippedSections.contains(id);

    return InkWell(
      onTap: isSkipped
          ? null
          : onTap, // Disable tap if skipped (or allow to undo?)
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.1)
              : isSkipped
              ? Colors.grey.withValues(alpha: 0.1)
              : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCompleted
                ? Colors.green
                : isSkipped
                ? Colors.grey
                : color,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isCompleted
                      ? Colors.green
                      : isSkipped
                      ? Colors.grey
                      : color,
                  fontWeight: FontWeight.bold,
                  decoration: isSkipped ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (isCompleted)
              const Icon(Icons.check_circle, color: Colors.green)
            else if (isSkipped)
              IconButton(
                icon: const Icon(Icons.undo, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _skippedSections.remove(id);
                  });
                },
                tooltip: 'Annulla skip',
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.orange),
                onPressed: () {
                  setState(() {
                    _skippedSections.add(id);
                  });
                },
                tooltip: 'Salta sezione',
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToMobility(
    List<WorkoutExercise> exercises,
    String title,
    String sectionId,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MobilityExerciseScreen(mobilityExercises: exercises, title: title),
      ),
    );

    if (mounted) {
      if (result == true) {
        setState(() {
          _completedSections.add(sectionId);
          _skippedSections.remove(sectionId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title completata!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (result == false) {
        // User skipped from inside the screen
        setState(() {
          _skippedSections.add(sectionId);
          _completedSections.remove(sectionId);
        });
      }
    }
  }

  Future<void> _navigateToCardio(
    List<WorkoutExercise> exercises,
    String title,
    String sectionId,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CardioExerciseScreen(cardioExercises: exercises, title: title),
      ),
    );

    if (mounted) {
      if (result == true) {
        setState(() {
          _completedSections.add(sectionId);
          _skippedSections.remove(sectionId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title completato!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (result == false) {
        // User skipped from inside the screen
        setState(() {
          _skippedSections.add(sectionId);
          _completedSections.remove(sectionId);
        });
      }
    }
  }

  void _navigateToExerciseDetail(WorkoutExercise workoutExercise) {
    Widget detailScreen;

    // Route to correct screen based on exercise type
    switch (workoutExercise.exerciseType) {
      case 'mobility':
        detailScreen = MobilityExerciseDetailScreen(
          workoutExercise: workoutExercise,
          duration: workoutExercise.reps, // Duration stored in reps field
        );
        break;
      case 'cardio':
        detailScreen = CardioExerciseDetailScreen(
          workoutExercise: workoutExercise,
          duration: workoutExercise.reps,
          intensity: 'Moderate', // Could be derived from notes
        );
        break;
      default: // strength
        detailScreen = ExerciseDetailScreen(workoutExercise: workoutExercise);
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => detailScreen));
  }

  Widget _buildDifficultyBadge(ExerciseDifficulty difficulty) {
    Color badgeColor;
    String label;

    switch (difficulty) {
      case ExerciseDifficulty.beginner:
        badgeColor = Colors.green;
        label = 'Beginner';
        break;
      case ExerciseDifficulty.intermediate:
        badgeColor = Colors.orange;
        label = 'Intermediate';
        break;
      case ExerciseDifficulty.advanced:
        badgeColor = Colors.red;
        label = 'Advanced';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primaryNeon),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String emoji) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.h4.copyWith(color: AppColors.primaryNeon),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(WorkoutExercise exercise) {
    // We need to access the provider to get the current log state
    return Consumer<WorkoutLogProvider>(
      builder: (context, provider, child) {
        final exerciseLog = provider.currentWorkoutLog?.exerciseLogs.firstWhere(
          (e) => e.exerciseId == exercise.exercise.id,
          orElse: () => ExerciseLogModel(
            id: '',
            workoutLogId: '',
            exerciseId: exercise.exercise.id,
            orderIndex: 0,
            exerciseType: 'main',
            setLogs: [],
          ),
        );

        final isCompleted = _completedExercises.contains(exercise.exercise.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: AppColors.backgroundLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isCompleted ? Colors.green : AppColors.primaryNeon,
              width: isCompleted ? 1.0 : 2.0,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.all(16),
              childrenPadding: const EdgeInsets.only(
                bottom: 16,
                left: 16,
                right: 16,
              ),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isCompleted ? null : AppColors.primaryGradient,
                  color: isCompleted ? Colors.green : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : Text(
                          '${widget.workoutDay.exercises.indexOf(exercise) + 1}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.exercise.name,
                    style: AppTextStyles.h6.copyWith(
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: isCompleted ? Colors.grey : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildDifficultyBadge(exercise.exercise.difficulty),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Stats Row
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMiniStat(Icons.repeat, '${exercise.sets}'),
                        const SizedBox(width: 12),
                        _buildMiniStat(Icons.fitness_center, exercise.reps),
                        if (exercise.restSeconds != null) ...[
                          const SizedBox(width: 12),
                          _buildMiniStat(
                            Icons.timer,
                            '${exercise.restSeconds}s',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Muscle Groups
                  if (exercise.exercise.muscleGroups.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: exercise.exercise.muscleGroups.take(3).map((
                        muscle,
                      ) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNeon.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.primaryNeon.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            muscle,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryNeon,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  if (exercise.notes != null && exercise.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        exercise.notes!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryNeon,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryNeon,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton.icon(
                  onPressed: () => _navigateToExerciseDetail(exercise),
                  icon: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'Info',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              children: [
                // Anatomical View
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: DualAnatomicalView(
                    muscleGroups: exercise.exercise.muscleGroups,
                    height: 150,
                    highlightColor: const Color(0xFFFF0000),
                  ),
                ),

                const Divider(color: AppColors.border),

                // Exercise Explanation Button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToExerciseDetail(exercise),
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Vedi Spiegazione Esercizio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNeon,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),

                const Divider(color: AppColors.border),

                // Set Logging
                SetLoggingWidget(
                  exercise: exercise,
                  exerciseLog: exerciseLog?.id.isNotEmpty == true
                      ? exerciseLog
                      : null,
                  onCompletionChanged: (allSetsCompleted) {
                    setState(() {
                      if (allSetsCompleted) {
                        _completedExercises.add(exercise.exercise.id);
                      } else {
                        _completedExercises.remove(exercise.exercise.id);
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmExit() {
    if (_completedExercises.isEmpty) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uscire dall\'allenamento?'),
        content: const Text(
          'Il tuo progresso andrà perso. Sei sicuro di voler uscire?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close screen
            },
            child: const Text('Esci', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _finishWorkout() async {
    final provider = Provider.of<WorkoutLogProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Completa Allenamento'),
        content: const Text(
          'Sei sicuro di voler terminare l\'allenamento? Tutti i progressi verranno salvati.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryNeon,
                  ),
                ),
              );

              try {
                await provider.completeWorkout();

                if (!mounted) return;
                Navigator.pop(context); // Close loading

                // Show success dialog
                await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Allenamento Completato!'),
                    content: const Text(
                      'Ottimo lavoro! Il tuo allenamento è stato registrato con successo.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Close screen
                        },
                        child: const Text('Fantastico!'),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.pop(context); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Errore durante il salvataggio: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Termina', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }
}
