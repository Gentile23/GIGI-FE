import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/workout_model.dart';
import '../../../providers/workout_provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'exercise_detail_screen.dart';
import 'mobility_exercise_detail_screen.dart';
import 'cardio_exercise_detail_screen.dart';

class WorkoutListScreen extends StatefulWidget {
  const WorkoutListScreen({super.key});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch current plan when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkoutProvider>(context, listen: false).fetchCurrentPlan();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh plan when screen becomes visible again
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<WorkoutProvider>(context, listen: false).fetchCurrentPlan();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Workouts'),
        backgroundColor: AppColors.background,
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, workoutProvider, _) {
          print('DEBUG UI: isLoading = ${workoutProvider.isLoading}');
          print('DEBUG UI: currentPlan = ${workoutProvider.currentPlan}');
          print(
            'DEBUG UI: currentPlan?.workouts.length = ${workoutProvider.currentPlan?.workouts.length}',
          );

          // Show loading state
          if (workoutProvider.isLoading) {
            print('DEBUG UI: Showing loading state');
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // Get current plan
          final currentPlan = workoutProvider.currentPlan;

          // Show empty state if no plan
          if (currentPlan == null || currentPlan.workouts.isEmpty) {
            print(
              'DEBUG UI: Showing empty state - currentPlan null: ${currentPlan == null}, workouts empty: ${currentPlan?.workouts.isEmpty}',
            );
            return _buildEmptyState();
          }

          // Show workouts
          final workouts = currentPlan.workouts;
          print('DEBUG UI: Showing ${workouts.length} workouts');

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              final workout = workouts[index];
              return _buildWorkoutCard(context, workout, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    // Check if we have a current plan that is processing
    final currentPlan = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    ).currentPlan;
    if (currentPlan != null && currentPlan.status == 'processing') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              '🤖 AI sta analizzando il tuo profilo',
              style: AppTextStyles.h3.copyWith(color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Generazione piano in corso...\nAttendi mentre l\'AI crea il tuo allenamento personalizzato.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Workouts Yet',
              style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              'Generate your first workout plan\nfrom the Home screen',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(
    BuildContext context,
    WorkoutDay workout,
    int index,
  ) {
    print('DEBUG UI: Building workout card $index: ${workout.name}');
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExerciseExecutionScreen(workout: workout),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.neonGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.background,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(workout.name, style: AppTextStyles.h5),
                        const SizedBox(height: 4),
                        Text(
                          workout.focus,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.timer,
                    '${workout.estimatedDuration} min',
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.fitness_center,
                    '${workout.exercises.length} exercises',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutDay workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(workout.name)),
      body: Column(
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(gradient: AppColors.neonGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.focus,
                  style: AppTextStyles.h4.copyWith(color: AppColors.background),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.timer, color: AppColors.background, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${workout.estimatedDuration} minutes',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.background,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Exercise list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _getMockExercises().length,
              itemBuilder: (context, index) {
                final exercise = _getMockExercises()[index];
                return _buildExerciseCard(context, exercise, index + 1);
              },
            ),
          ),

          // Start button
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ExerciseExecutionScreen(workout: workout),
                    ),
                  );
                },
                child: const Text('Start Workout'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    WorkoutExercise workoutExercise,
    int number,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.borderLight, width: 1),
      ),
      color: AppColors.surface,
      child: InkWell(
        onTap: () => _navigateToExerciseDetail(context, workoutExercise),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Number, Name, Difficulty
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Exercise Number
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: AppTextStyles.h6.copyWith(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Exercise Name & Difficulty
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workoutExercise.exercise.name,
                          style: AppTextStyles.h6.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildDifficultyBadge(
                          workoutExercise.exercise.difficulty,
                        ),
                      ],
                    ),
                  ),

                  // Info Button
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton.icon(
                      onPressed: () =>
                          _navigateToExerciseDetail(context, workoutExercise),
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
                ],
              ),

              const SizedBox(height: 16),

              // Sets, Reps, Rest Row
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      Icons.repeat,
                      'Sets',
                      '${workoutExercise.sets}',
                    ),
                    _buildDivider(),
                    _buildStatItem(
                      Icons.fitness_center,
                      'Reps',
                      workoutExercise.reps ?? '-',
                    ),
                    if (workoutExercise.restSeconds != null) ...[
                      _buildDivider(),
                      _buildStatItem(
                        Icons.timer,
                        'Rest',
                        '${workoutExercise.restSeconds}s',
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Muscle Groups
              if (workoutExercise.exercise.muscleGroups.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.accessibility_new,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: workoutExercise.exercise.muscleGroups
                            .take(3)
                            .map((muscle) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  muscle,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ),
                    if (workoutExercise.exercise.muscleGroups.length > 3)
                      Text(
                        '+${workoutExercise.exercise.muscleGroups.length - 3}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Equipment
              if (workoutExercise.exercise.equipment.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.build_circle_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        workoutExercise.exercise.equipment.join(', '),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToExerciseDetail(
    BuildContext context,
    WorkoutExercise workoutExercise,
  ) {
    Widget detailScreen;

    // Route to correct screen based on exercise type
    switch (workoutExercise.exerciseType) {
      case 'mobility':
        detailScreen = MobilityExerciseDetailScreen(
          workoutExercise: workoutExercise,
          duration: workoutExercise.reps,
        );
        break;
      case 'cardio':
        detailScreen = CardioExerciseDetailScreen(
          workoutExercise: workoutExercise,
          duration: workoutExercise.reps,
          intensity: 'Moderate',
        );
        break;
      default: // strength
        detailScreen = ExerciseDetailScreen(workoutExercise: workoutExercise);
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => detailScreen));
  }

  List<WorkoutExercise> _getMockExercises() {
    return [
      WorkoutExercise(
        exercise: Exercise(
          id: '1',
          name: 'Bench Press',
          description: 'Chest compound movement',
          muscleGroups: ['Chest', 'Triceps'],
          difficulty: ExerciseDifficulty.intermediate,
          equipment: ['Barbell', 'Bench'],
        ),
        sets: 4,
        reps: '8',
        restSeconds: 90,
      ),
      WorkoutExercise(
        exercise: Exercise(
          id: '2',
          name: 'Overhead Press',
          description: 'Shoulder compound movement',
          muscleGroups: ['Shoulders', 'Triceps'],
          difficulty: ExerciseDifficulty.intermediate,
          equipment: ['Barbell'],
        ),
        sets: 3,
        reps: '10',
        restSeconds: 90,
      ),
      WorkoutExercise(
        exercise: Exercise(
          id: '3',
          name: 'Tricep Dips',
          description: 'Tricep isolation',
          muscleGroups: ['Triceps'],
          difficulty: ExerciseDifficulty.beginner,
          equipment: ['Bodyweight'],
        ),
        sets: 3,
        reps: '12',
        restSeconds: 60,
      ),
    ];
  }

  Widget _buildDifficultyBadge(ExerciseDifficulty difficulty) {
    Color badgeColor;
    String label;

    switch (difficulty) {
      case ExerciseDifficulty.beginner:
        badgeColor = AppColors.difficultyBeginner;
        label = 'Beginner';
        break;
      case ExerciseDifficulty.intermediate:
        badgeColor = AppColors.difficultyIntermediate;
        label = 'Intermediate';
        break;
      case ExerciseDifficulty.advanced:
        badgeColor = AppColors.difficultyAdvanced;
        label = 'Advanced';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withOpacity(0.5), width: 1),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.h6.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: AppColors.divider);
  }
}

class ExerciseExecutionScreen extends StatefulWidget {
  final WorkoutDay workout;

  const ExerciseExecutionScreen({super.key, required this.workout});

  @override
  State<ExerciseExecutionScreen> createState() =>
      _ExerciseExecutionScreenState();
}

class _ExerciseExecutionScreenState extends State<ExerciseExecutionScreen> {
  int _currentExerciseIndex = 0;
  bool _isResting = false;
  int _restTimeRemaining = 0;

  // Track data for each set: Map<exerciseIndex, Map<setIndex, SetData>>
  // Track data for each set: Map<exerciseIndex, Map<setIndex, SetData>>
  final Map<int, Map<int, SetData>> _setData = {};
  YoutubePlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _initializeSetData();
    _initializeVideoController();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeVideoController() {
    // Dispose previous controller if exists
    _videoController?.dispose();
    _videoController = null;

    final exercises = widget.workout.exercises;
    if (_currentExerciseIndex < exercises.length) {
      final currentExercise = exercises[_currentExerciseIndex];
      final videoUrl = currentExercise.exercise.videoUrl;

      if (videoUrl != null && videoUrl.isNotEmpty) {
        final videoId = YoutubePlayer.convertUrlToId(videoUrl);
        if (videoId != null) {
          _videoController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
          );
        }
      }
    }
  }

  void _initializeSetData() {
    final exercises = widget.workout.exercises;
    for (int i = 0; i < exercises.length; i++) {
      _setData[i] = {};
      for (int j = 0; j < exercises[i].sets; j++) {
        _setData[i]![j] = SetData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercises = widget.workout.exercises;
    final currentExercise = exercises[_currentExerciseIndex];
    final exerciseType = currentExercise.exerciseType;

    // Determine colors based on exercise type
    Color headerColor;
    Color accentColor;
    String typeLabel;
    IconData typeIcon;

    if (exerciseType == 'cardio') {
      headerColor = const Color(0xFFFF6347); // Tomato red
      accentColor = const Color(0xFFFF6347);
      typeLabel = 'Cardio';
      typeIcon = Icons.directions_run;
    } else if (exerciseType == 'mobility') {
      headerColor = const Color(0xFF00CED1); // Cyan
      accentColor = const Color(0xFF00CED1);
      typeLabel = 'Mobilità';
      typeIcon = Icons.self_improvement;
    } else {
      headerColor = AppColors.primaryNeon;
      accentColor = AppColors.primaryNeon;
      typeLabel = 'Forza';
      typeIcon = Icons.fitness_center;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Exercise ${_currentExerciseIndex + 1}/${exercises.length}',
        ),
        backgroundColor: exerciseType == 'cardio' || exerciseType == 'mobility'
            ? headerColor
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Exercise Details',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExerciseDetailScreen(
                    workoutExercise: exercises[_currentExerciseIndex],
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showQuitDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Type indicator banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: headerColor.withValues(alpha: 0.2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(typeIcon, color: headerColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  typeLabel,
                  style: AppTextStyles.h5.copyWith(
                    color: headerColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Progress indicator
          LinearProgressIndicator(
            value: (_currentExerciseIndex + 1) / exercises.length,
            backgroundColor: AppColors.backgroundLight,
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),

          Expanded(
            child: _isResting
                ? _buildRestScreen()
                : _buildExerciseScreen(currentExercise, accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseScreen(WorkoutExercise exercise, Color accentColor) {
    final isCardioOrMobility =
        exercise.exerciseType == 'cardio' ||
        exercise.exerciseType == 'mobility';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise name
          Text(exercise.exercise.name, style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            exercise.exercise.description,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Video Player
          if (_videoController != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: YoutubePlayer(
                controller: _videoController!,
                showVideoProgressIndicator: true,
                progressIndicatorColor: accentColor,
                progressColors: ProgressBarColors(
                  playedColor: accentColor,
                  handleColor: accentColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Skip button for cardio/mobility
          if (isCardioOrMobility) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _skipCurrentExercise,
              icon: const Icon(Icons.skip_next),
              label: const Text('Salta Esercizio'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Sets list
          ...List.generate(exercise.sets, (setIndex) {
            final setData = _setData[_currentExerciseIndex]![setIndex]!;
            final isCompleted = setData.isCompleted;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: isCompleted ? AppColors.backgroundLight : null,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Set number
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? accentColor
                                : AppColors.backgroundLight,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                : Text(
                                    '${setIndex + 1}',
                                    style: AppTextStyles.h5.copyWith(
                                      color: accentColor,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('Set ${setIndex + 1}', style: AppTextStyles.h5),
                        const Spacer(),
                        Text(
                          '${exercise.reps}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    if (!isCompleted) ...[
                      const SizedBox(height: 16),

                      // For cardio/mobility: simplified UI (no weight/feeling)
                      if (isCardioOrMobility) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _completeSet(setIndex),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                            ),
                            child: const Text('Completa'),
                          ),
                        ),
                      ] else ...[
                        // For strength: weight and feeling tracking
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Weight (kg)',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setData.weight = double.tryParse(value);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Feeling selector
                            Text('Feeling:', style: AppTextStyles.bodyMedium),
                            const SizedBox(width: 8),
                            _buildFeelingSelector(setData),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Complete button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _completeSet(setIndex),
                            child: const Text('Complete Set'),
                          ),
                        ),
                      ],
                    ] else ...[
                      const SizedBox(height: 12),
                      if (!isCardioOrMobility)
                        Row(
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${setData.weight?.toStringAsFixed(1) ?? '—'} kg',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            _getFeelingIcon(setData.feeling),
                          ],
                        ),
                    ],
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Next exercise button (only show if all sets completed)
          if (_areAllSetsCompleted(exercise)) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _moveToNextExercise,
                style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                child: Text(
                  _currentExerciseIndex < widget.workout.exercises.length - 1
                      ? 'Next Exercise'
                      : 'Finish Workout',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeelingSelector(SetData setData) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFeelingButton('😊', SetFeeling.happy, setData),
        const SizedBox(width: 4),
        _buildFeelingButton('😐', SetFeeling.neutral, setData),
        const SizedBox(width: 4),
        _buildFeelingButton('😞', SetFeeling.sad, setData),
      ],
    );
  }

  Widget _buildFeelingButton(
    String emoji,
    SetFeeling feeling,
    SetData setData,
  ) {
    final isSelected = setData.feeling == feeling;
    return InkWell(
      onTap: () {
        setState(() {
          setData.feeling = feeling;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryNeon.withValues(alpha: 0.2)
              : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryNeon : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  Widget _getFeelingIcon(SetFeeling feeling) {
    final emoji = feeling == SetFeeling.happy
        ? '😊'
        : feeling == SetFeeling.neutral
        ? '😐'
        : '😞';
    return Text(emoji, style: const TextStyle(fontSize: 20));
  }

  bool _areAllSetsCompleted(WorkoutExercise exercise) {
    final exerciseData = _setData[_currentExerciseIndex]!;
    return exerciseData.values.every((setData) => setData.isCompleted);
  }

  Widget _buildRestScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Rest Time', style: AppTextStyles.h3),
            const SizedBox(height: 32),
            Text(
              '$_restTimeRemaining',
              style: AppTextStyles.h1.copyWith(
                fontSize: 72,
                color: AppColors.primaryNeon,
              ),
            ),
            const SizedBox(height: 8),
            Text('seconds', style: AppTextStyles.bodyLarge),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _skipRest,
                child: const Text('Skip Rest'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _completeSet(int setIndex) {
    final currentExercise = widget.workout.exercises[_currentExerciseIndex];
    final setData = _setData[_currentExerciseIndex]![setIndex]!;

    setState(() {
      setData.isCompleted = true;
    });

    // Check if this is the last set
    final isLastSet = setIndex == currentExercise.sets - 1;

    if (!isLastSet) {
      // Start rest period
      setState(() {
        _isResting = true;
        _restTimeRemaining = currentExercise.restSeconds;
      });

      // Start countdown timer
      _startRestTimer();
    }
  }

  void _startRestTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isResting && _restTimeRemaining > 0) {
        setState(() {
          _restTimeRemaining--;
        });
        if (_restTimeRemaining > 0) {
          _startRestTimer();
        } else {
          setState(() {
            _isResting = false;
          });
        }
      }
    });
  }

  void _moveToNextExercise() {
    if (_currentExerciseIndex < widget.workout.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _isResting = false;
        _initializeVideoController();
      });
    } else {
      // Workout complete
      _showWorkoutCompleteDialog();
    }
  }

  void _skipCurrentExercise() {
    // Mark all sets as completed for this exercise
    final currentExercise = widget.workout.exercises[_currentExerciseIndex];
    for (int i = 0; i < currentExercise.sets; i++) {
      _setData[_currentExerciseIndex]![i]!.isCompleted = true;
    }

    // Move to next exercise
    _moveToNextExercise();
  }

  void _skipRest() {
    setState(() {
      _isResting = false;
    });
  }

  void _showQuitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quit Workout?'),
        content: const Text('Are you sure you want to quit this workout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close workout screen
            },
            child: const Text('Quit'),
          ),
        ],
      ),
    );
  }

  void _showWorkoutCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Workout Complete!'),
        content: const Text('Great job! You completed the workout.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close workout screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

// Data class for tracking set information
class SetData {
  double? weight;
  SetFeeling feeling;
  bool isCompleted;

  SetData({
    this.weight,
    this.feeling = SetFeeling.happy,
    this.isCompleted = false,
  });
}

enum SetFeeling { happy, neutral, sad }
