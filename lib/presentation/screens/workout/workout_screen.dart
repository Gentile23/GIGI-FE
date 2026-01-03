import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/models/workout_model.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/auth_provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../presentation/widgets/clean_widgets.dart';
import 'package:gigi/l10n/app_localizations.dart';
import '../../../presentation/widgets/workout/set_logging_widget.dart';
import '../../../presentation/widgets/workout/anatomical_muscle_view.dart';
import '../../../core/services/gigi_tts_service.dart';
import '../../../core/services/synchronized_voice_controller.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/voice_coaching_service.dart';
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
          AppLocalizations.of(context)!.myWorkoutsTitle,
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
              AppLocalizations.of(context)!.aiAnalyzingProfile,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.aiGeneratingPlanDescription,
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
              AppLocalizations.of(context)!.noWorkoutsTitle,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.generateFirstPlanSubtitle,
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
                AppLocalizations.of(
                  context,
                )!.durationMinutes(workout.estimatedDuration),
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                Icons.fitness_center_outlined,
                AppLocalizations.of(
                  context,
                )!.exercisesCount(workout.exercises.length),
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
      body: SafeArea(
        child: Column(
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
                        AppLocalizations.of(
                          context,
                        )!.durationMinutes(workout.estimatedDuration),
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
                text: AppLocalizations.of(context)!.startWorkout,
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
                    _buildDifficultyBadge(
                      workoutExercise.exercise.difficulty,
                      context,
                    ),
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
                _buildStatItem(
                  AppLocalizations.of(context)!.sets,
                  '${workoutExercise.sets}',
                ),
                _buildDivider(),
                _buildStatItem(
                  AppLocalizations.of(context)!.reps,
                  workoutExercise.reps,
                ),
                _buildDivider(),
                _buildStatItem(
                  AppLocalizations.of(context)!.rest,
                  AppLocalizations.of(
                    context,
                  )!.secondsShort(workoutExercise.restSeconds),
                ),
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

  Widget _buildDifficultyBadge(
    ExerciseDifficulty difficulty,
    BuildContext context,
  ) {
    Color badgeColor;
    String label;

    switch (difficulty) {
      case ExerciseDifficulty.beginner:
        badgeColor = CleanTheme.accentGreen;
        label = AppLocalizations.of(context)!.difficultyBeginner;
        break;
      case ExerciseDifficulty.intermediate:
        badgeColor = CleanTheme.accentOrange;
        label = AppLocalizations.of(context)!.difficultyIntermediate;
        break;
      case ExerciseDifficulty.advanced:
        badgeColor = CleanTheme.accentRed;
        label = AppLocalizations.of(context)!.difficultyAdvanced;
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

  // Synchronized Voice Coaching
  late SynchronizedVoiceController _voiceController;
  late GigiTTSService _gigiTTS;

  @override
  void initState() {
    super.initState();
    _initializeSetData();
    _initializeVideoController();

    // Initialize voice coaching services
    final voiceCoachingService = VoiceCoachingService(ApiClient());
    _gigiTTS = GigiTTSService(voiceCoachingService);
    _voiceController = SynchronizedVoiceController(_gigiTTS);

    // Get user data from AuthProvider after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVoiceCoachingWithUserData();
    });

    _voiceController.addListener(_onVoiceStateChange);
  }

  void _initializeVoiceCoachingWithUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    _voiceController.initialize(
      userName: user?.name ?? AppLocalizations.of(context)!.champion,
      experienceLevel: user?.experienceLevel,
      goal: user?.goal,
    );
  }

  @override
  void dispose() {
    _videoController?.close();
    _voiceController.removeListener(_onVoiceStateChange);
    _voiceController.dispose();
    _gigiTTS.dispose();
    super.dispose();
  }

  void _onVoiceStateChange() {
    if (mounted) setState(() {});
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

    // Show rest timer overlay if resting
    if (_voiceController.isResting) {
      return _buildRestTimerOverlay(currentExercise);
    }

    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(
            context,
          )!.exerciseProgress(_currentExerciseIndex + 1, exercises.length),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
        actions: [
          // Voice Coaching Toggle
          IconButton(
            icon: Icon(
              _voiceController.isEnabled ? Icons.mic : Icons.mic_off,
              color: _voiceController.isEnabled
                  ? CleanTheme.accentGreen
                  : CleanTheme.textTertiary,
            ),
            onPressed: _toggleVoiceCoaching,
            tooltip: _voiceController.isEnabled
                ? AppLocalizations.of(context)!.voiceCoachingDisable
                : AppLocalizations.of(context)!.voiceCoachingEnable,
          ),
          // Info Button
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Voice Coaching Controls Bar
              if (_voiceController.isEnabled) ...[
                _buildVoiceCoachingBar(),
                const SizedBox(height: 16),
              ],

              // Anatomical Muscle View
              if (currentExercise.exerciseType != 'cardio' &&
                  currentExercise.exerciseType != 'mobility') ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: CleanTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: CleanTheme.borderPrimary),
                    ),
                    child: AnatomicalMuscleView(
                      muscleGroups: currentExercise.exercise.muscleGroups,
                      height: 200,
                      highlightColor: CleanTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

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

              const SizedBox(height: 24),

              // Set Logging with Voice Coaching Sync
              _buildSetLoggingWithVoiceCoaching(currentExercise),

              const SizedBox(height: 32),

              // Navigation Buttons
              Row(
                children: [
                  if (_currentExerciseIndex > 0)
                    Expanded(
                      child: CleanButton(
                        text: AppLocalizations.of(context)!.previous,
                        isOutlined: true,
                        onPressed: _goToPreviousExercise,
                      ),
                    ),
                  if (_currentExerciseIndex > 0) const SizedBox(width: 16),
                  Expanded(
                    child: CleanButton(
                      text: _currentExerciseIndex < exercises.length - 1
                          ? AppLocalizations.of(context)!.next
                          : AppLocalizations.of(context)!.finish,
                      onPressed: _goToNextExercise,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // NAVIGATION
  // ==========================================

  void _goToPreviousExercise() {
    setState(() {
      _currentExerciseIndex--;
      _initializeVideoController();
    });
    if (_voiceController.isEnabled) {
      _setVoiceForNewExercise();
    }
  }

  void _goToNextExercise() {
    if (_currentExerciseIndex < widget.workout.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _initializeVideoController();
      });
      if (_voiceController.isEnabled) {
        _setVoiceForNewExercise();
      }
    } else {
      Navigator.pop(context);
    }
  }

  // ==========================================
  // SYNCHRONIZED SET CONTROLS
  // ==========================================

  /// Set logging widget integrated with voice coaching
  Widget _buildSetLoggingWithVoiceCoaching(WorkoutExercise exercise) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Voice Coaching Integration Header
        if (_voiceController.isEnabled)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CleanTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CleanTheme.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.record_voice_over,
                  color: CleanTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Voice coaching sincronizzato - Registra i tuoi dati!',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CleanTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Set Logging Widget
        SetLoggingWidget(
          exercise: exercise,
          exerciseLog: null, // Will be created on first set completion
          onCompletionChanged: (allCompleted) {
            setState(() {
              // Update UI state when exercise fully completed
            });
          },
          onSetCompleted: (setData) {
            // Sync with voice coaching on each individual set
            if (_voiceController.isEnabled) {
              _voiceController.completeSetWithData(
                weightKg: setData.weightKg,
                reps: setData.reps,
                rpe: setData.rpe,
                previousWeightKg: setData.previousWeightKg,
              );
            }
          },
        ),
      ],
    );
  }

  // ==========================================
  // VOICE COACHING METHODS
  // ==========================================

  void _toggleVoiceCoaching() {
    if (_voiceController.isEnabled) {
      _voiceController.deactivate();
    } else {
      _activateVoiceForCurrentExercise();
    }
  }

  void _activateVoiceForCurrentExercise() {
    final exercise = widget.workout.exercises[_currentExerciseIndex];

    _voiceController.loadScriptForExercise(
      exercise.exercise.name,
      exercise.exercise.muscleGroups,
    );

    _voiceController.activateInitial(
      exerciseName: exercise.exercise.name,
      sets: exercise.sets,
      reps: int.tryParse(exercise.reps) ?? 10,
      restSeconds: exercise.restSeconds,
      muscleGroups: exercise.exercise.muscleGroups,
    );
  }

  void _setVoiceForNewExercise() {
    final exercise = widget.workout.exercises[_currentExerciseIndex];
    _voiceController.loadScriptForExercise(
      exercise.exercise.name,
      exercise.exercise.muscleGroups,
    );
    _voiceController.setExercise(
      exerciseName: exercise.exercise.name,
      sets: exercise.sets,
      reps: int.tryParse(exercise.reps) ?? 10,
      restSeconds: exercise.restSeconds,
    );
  }

  Widget _buildVoiceCoachingBar() {
    final phaseText = switch (_voiceController.phase) {
      VoiceCoachingPhase.activated => 'Voice coaching attivo',
      VoiceCoachingPhase.preExercise => 'Premi Inizia Serie',
      VoiceCoachingPhase.explaining => 'Spiegazione in corso...',
      VoiceCoachingPhase.executing => 'Serie in corso',
      VoiceCoachingPhase.postSet => 'Serie completata!',
      VoiceCoachingPhase.resting => 'Riposo...',
      VoiceCoachingPhase.completed => 'Esercizio completato!',
      _ => 'Gigi ti guida',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CleanTheme.primaryColor.withValues(alpha: 0.1),
            CleanTheme.accentGreen.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CleanTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Status Icon
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: CleanTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.record_voice_over,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Status Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎤 Voice Coaching',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                Text(
                  phaseText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Explanation Button
          IconButton(
            icon: const Icon(
              Icons.help_outline,
              color: CleanTheme.primaryColor,
            ),
            onPressed: () => _voiceController.speakExplanation(),
            tooltip: 'Spiegazione esercizio',
          ),
          // Mute Button
          IconButton(
            icon: Icon(
              _voiceController.isMuted ? Icons.volume_off : Icons.volume_up,
              color: _voiceController.isMuted
                  ? CleanTheme.textTertiary
                  : CleanTheme.primaryColor,
            ),
            onPressed: () => _voiceController.toggleMute(),
            tooltip: _voiceController.isMuted ? 'Attiva audio' : 'Muto',
          ),
          // Close Button
          IconButton(
            icon: const Icon(Icons.close, color: CleanTheme.textTertiary),
            onPressed: () => _voiceController.deactivate(),
          ),
        ],
      ),
    );
  }

  Widget _buildRestTimerOverlay(WorkoutExercise exercise) {
    final minutes = _voiceController.restRemaining ~/ 60;
    final seconds = _voiceController.restRemaining % 60;
    final timeString =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Timer Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CleanTheme.primaryColor.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.timer,
                  size: 50,
                  color: CleanTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),

              // Time Display
              Text(
                timeString,
                style: GoogleFonts.outfit(
                  fontSize: 72,
                  fontWeight: FontWeight.w700,
                  color: CleanTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Message
              Text(
                _voiceController.restRemaining <= 10
                    ? 'Preparati per la prossima serie!'
                    : 'Riposa e recupera',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  color: CleanTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 48),

              // Skip Button
              CleanButton(
                text: 'SALTA RIPOSO →',
                isOutlined: true,
                onPressed: () => _voiceController.skipRest(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SetData {
  bool isCompleted = false;
  double? weight;
  int? reps;
}
