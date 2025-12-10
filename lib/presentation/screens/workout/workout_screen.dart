import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/models/workout_model.dart';
import '../../../providers/workout_provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../presentation/widgets/clean_widgets.dart';
import '../../../presentation/widgets/workout/set_logging_widget.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkoutProvider>(context, listen: false).fetchCurrentPlan();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<WorkoutProvider>(context, listen: false).fetchCurrentPlan();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'I Miei Workout',
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
      body: Consumer<WorkoutProvider>(
        builder: (context, workoutProvider, _) {
          if (workoutProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: CleanTheme.primaryColor),
            );
          }

          final currentPlan = workoutProvider.currentPlan;

          if (currentPlan == null || currentPlan.workouts.isEmpty) {
            return _buildEmptyState();
          }

          final workouts = currentPlan.workouts;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
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
    final currentPlan = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    ).currentPlan;

    if (currentPlan != null && currentPlan.status == 'processing') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: CleanTheme.primaryColor),
            const SizedBox(height: 24),
            Text(
              '🤖 AI sta analizzando il tuo profilo',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Generazione piano in corso...\nAttendi mentre l\'AI crea il tuo allenamento personalizzato.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CleanTheme.textSecondary,
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: CleanTheme.surfaceColor,
                shape: BoxShape.circle,
                boxShadow: CleanTheme.cardShadow,
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 48,
                color: CleanTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nessun Workout',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Genera il tuo primo piano di allenamento dalla Home',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CleanTheme.textSecondary,
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
    return CleanCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseExecutionScreen(workout: workout),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: CleanTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: CleanTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workout.focus,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: CleanTheme.textTertiary),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                Icons.timer_outlined,
                '${workout.estimatedDuration} min',
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                Icons.fitness_center_outlined,
                '${workout.exercises.length} esercizi',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: CleanTheme.borderSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: CleanTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CleanTheme.textSecondary,
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
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          workout.name,
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
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: CleanTheme.surfaceColor,
              border: const Border(
                bottom: BorderSide(color: CleanTheme.borderPrimary),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.focus,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: CleanTheme.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${workout.estimatedDuration} minuti',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: CleanTheme.textSecondary,
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
              padding: const EdgeInsets.all(20),
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
            child: CleanButton(
              text: 'Inizia Workout',
              width: double.infinity,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ExerciseExecutionScreen(workout: workout),
                  ),
                );
              },
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
    return CleanCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () => _navigateToExerciseDetail(context, workoutExercise),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Number, Name, Difficulty
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exercise Number
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: CleanTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: CleanTheme.primaryColor,
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
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildDifficultyBadge(workoutExercise.exercise.difficulty),
                  ],
                ),
              ),

              // Info Button
              GestureDetector(
                onTap: () =>
                    _navigateToExerciseDetail(context, workoutExercise),
                child: const Icon(
                  Icons.info_outline,
                  color: CleanTheme.textTertiary,
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sets, Reps, Rest Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CleanTheme.borderSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Sets', '${workoutExercise.sets}'),
                _buildDivider(),
                _buildStatItem('Reps', workoutExercise.reps),
                _buildDivider(),
                _buildStatItem('Rest', '${workoutExercise.restSeconds}s'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Muscle Groups
          if (workoutExercise.exercise.muscleGroups.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: workoutExercise.exercise.muscleGroups.take(3).map((
                muscle,
              ) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: CleanTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: CleanTheme.borderPrimary),
                  ),
                  child: Text(
                    muscle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
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
        badgeColor = CleanTheme.primaryColor;
        label = 'Principiante';
        break;
      case ExerciseDifficulty.intermediate:
        badgeColor = CleanTheme.accentOrange;
        label = 'Intermedio';
        break;
      case ExerciseDifficulty.advanced:
        badgeColor = CleanTheme.accentRed;
        label = 'Avanzato';
        break;
    }

    return CleanBadge(
      text: label,
      backgroundColor: badgeColor.withValues(alpha: 0.1),
      textColor: badgeColor,
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: CleanTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 30, color: CleanTheme.borderPrimary);
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
    _videoController?.close();
    super.dispose();
  }

  void _initializeVideoController() {
    _videoController?.close();
    _videoController = null;

    final exercises = widget.workout.exercises;
    if (_currentExerciseIndex < exercises.length) {
      final currentExercise = exercises[_currentExerciseIndex];
      final videoUrl = currentExercise.exercise.videoUrl;

      if (videoUrl != null && videoUrl.isNotEmpty) {
        final videoId = YoutubePlayerController.convertUrlToId(videoUrl);
        if (videoId != null) {
          _videoController = YoutubePlayerController.fromVideoId(
            videoId: videoId,
            autoPlay: false,
            params: const YoutubePlayerParams(
              showControls: true,
              mute: false,
              showFullscreenButton: true,
            ),
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

    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Esercizio ${_currentExerciseIndex + 1}/${exercises.length}',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video Player
            if (_videoController != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: YoutubePlayer(
                    controller: _videoController!,
                    aspectRatio: 16 / 9,
                  ),
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: CleanTheme.borderSecondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 48,
                    color: CleanTheme.textTertiary,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Exercise Info
            Text(
              currentExercise.exercise.name,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currentExercise.exercise.description,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: CleanTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 32),

            // Sets - Use SetLoggingWidget for full logging
            SetLoggingWidget(
              exercise: currentExercise,
              onCompletionChanged: (completed) {
                // Optionally track overall exercise completion
              },
            ),

            const SizedBox(height: 32),

            // Navigation Buttons
            Row(
              children: [
                if (_currentExerciseIndex > 0)
                  Expanded(
                    child: CleanButton(
                      text: 'Precedente',
                      isOutlined: true,
                      onPressed: () {
                        setState(() {
                          _currentExerciseIndex--;
                          _initializeVideoController();
                        });
                      },
                    ),
                  ),
                if (_currentExerciseIndex > 0) const SizedBox(width: 16),
                Expanded(
                  child: CleanButton(
                    text: _currentExerciseIndex < exercises.length - 1
                        ? 'Prossimo'
                        : 'Termina',
                    onPressed: () {
                      if (_currentExerciseIndex < exercises.length - 1) {
                        setState(() {
                          _currentExerciseIndex++;
                          _initializeVideoController();
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetRow(int index, WorkoutExercise exercise) {
    final setData = _setData[_currentExerciseIndex]?[index];
    final isCompleted = setData?.isCompleted ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? CleanTheme.primaryLight : CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? CleanTheme.primaryColor
              : CleanTheme.borderPrimary,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted
                  ? CleanTheme.primaryColor
                  : CleanTheme.borderSecondary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.white : CleanTheme.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  '${exercise.reps} reps',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                Text('—', style: TextStyle(color: CleanTheme.textTertiary)),
                Text(
                  '${exercise.restSeconds}s rest',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: CleanTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Checkbox(
            value: isCompleted,
            activeColor: CleanTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (val) {
              setState(() {
                setData?.isCompleted = val ?? false;
              });
            },
          ),
        ],
      ),
    );
  }
}

class SetData {
  bool isCompleted = false;
  double? weight;
  int? reps;
}
