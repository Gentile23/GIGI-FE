import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
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
import '../form_analysis/form_analysis_screen.dart';
import '../../widgets/voice_coaching/mode_selection_sheet.dart';
import '../../../data/models/exercise_intro_model.dart';
import '../../../core/services/gigi_tts_service.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final WorkoutDay workoutDay;

  const WorkoutSessionScreen({super.key, required this.workoutDay});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  final Set<String> _completedExercises = {};
  final Set<String> _completedSections = {};
  final Set<String> _skippedSections = {};

  // Voice Coaching TTS
  late GigiTTSService _gigiTTS;
  CoachingMode _selectedCoachingMode = CoachingMode.voice;

  @override
  void initState() {
    super.initState();
    _gigiTTS = GigiTTSService();
    _gigiTTS.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startWorkoutSession();
    });
  }

  @override
  void dispose() {
    _gigiTTS.dispose();
    super.dispose();
  }

  Future<void> _startWorkoutSession() async {
    final provider = Provider.of<WorkoutLogProvider>(context, listen: false);
    await provider.startWorkout(workoutDayId: widget.workoutDay.id);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.workoutDay.exercises.isEmpty) {
      return Scaffold(
        backgroundColor: CleanTheme.backgroundColor,
        appBar: AppBar(
          title: Text(widget.workoutDay.name),
          backgroundColor: CleanTheme.surfaceColor,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 80,
                  color: CleanTheme.primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  'Nessun Esercizio',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Questo allenamento non ha ancora esercizi.',
                  style: GoogleFonts.inter(color: CleanTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CleanTheme.primaryColor,
                  ),
                  child: const Text('Torna Indietro'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black, // Dark background behind image
      body: Stack(
        children: [
          // 1. Full Screen Image Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage(
                    'assets/images/placeholder_workout.jpg',
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.3),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                      onPressed: () => _confirmExit(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Sliding Content Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.6,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: CleanTheme
                      .scaffoldBackgroundColor, // Light gray for contrast with white cards
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    24,
                    20,
                    100,
                  ), // Bottom padding for floating button
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title & Info
                    Text(
                      widget.workoutDay.name,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatsHeader(),
                    const SizedBox(height: 24),

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
                  ],
                ),
              );
            },
          ),

          // 3. Floating Action Button (Finish)
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _completedExercises.isNotEmpty
                    ? _finishWorkout
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _completedExercises.length ==
                          widget.workoutDay.mainExerciseCount
                      ? CleanTheme.accentGreen
                      : CleanTheme.primaryColor,
                  elevation: 8,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100), // Pill shape
                  ),
                ),
                child: Text(
                  _completedExercises.length ==
                          widget.workoutDay.mainExerciseCount
                      ? 'COMPLETA ALLENAMENTO'
                      : 'TERMINA SESSIONE',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Row(
      children: [
        _buildStatBadge(
          Icons.timer_outlined,
          '${widget.workoutDay.estimatedDuration} min',
        ),
        const SizedBox(width: 12),
        _buildStatBadge(
          Icons.fitness_center,
          '${widget.workoutDay.exercises.length} Esercizi',
        ),
        const SizedBox(width: 12),
        _buildStatBadge(
          Icons.local_fire_department,
          '${widget.workoutDay.estimatedDuration * 7} Kcal',
        ),
      ],
    );
  }

  Widget _buildStatBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CleanTheme.borderSecondary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: CleanTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
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
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CleanTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: CleanTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Prima dell\'allenamento',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.workoutDay.warmupCardio.isNotEmpty)
            _buildNavigationButton(
              id: 'warmupCardio',
              title: 'Riscaldamento Cardio',
              emoji: '🔥',
              color: CleanTheme.accentOrange,
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
              color: CleanTheme.accentBlue,
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
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CleanTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: CleanTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Dopo l\'allenamento',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                      color: CleanTheme.accentBlue,
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
                      color: CleanTheme.accentOrange,
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
      onTap: isSkipped ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCompleted
              ? CleanTheme.accentGreen.withValues(alpha: 0.1)
              : isSkipped
              ? CleanTheme.textTertiary.withValues(alpha: 0.1)
              : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCompleted
                ? CleanTheme.accentGreen
                : isSkipped
                ? CleanTheme.textTertiary
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
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isCompleted
                      ? CleanTheme.accentGreen
                      : isSkipped
                      ? CleanTheme.textTertiary
                      : color,
                  decoration: isSkipped ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (isCompleted)
              const Icon(Icons.check_circle, color: CleanTheme.accentGreen)
            else if (isSkipped)
              IconButton(
                icon: const Icon(Icons.undo, color: CleanTheme.textTertiary),
                onPressed: () {
                  setState(() {
                    _skippedSections.remove(id);
                  });
                },
                tooltip: 'Annulla skip',
              )
            else ...[
              IconButton(
                icon: const Icon(
                  Icons.skip_next,
                  color: CleanTheme.accentOrange,
                ),
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
            backgroundColor: CleanTheme.accentGreen,
          ),
        );
      } else if (result == false) {
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
            backgroundColor: CleanTheme.accentGreen,
          ),
        );
      } else if (result == false) {
        setState(() {
          _skippedSections.add(sectionId);
          _completedSections.remove(sectionId);
        });
      }
    }
  }

  void _navigateToExerciseDetail(WorkoutExercise workoutExercise) {
    Widget detailScreen;

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
      default:
        detailScreen = ExerciseDetailScreen(workoutExercise: workoutExercise);
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => detailScreen));
  }

  /// Start voice coaching for exercise - shows mode selection then plays TTS
  void _startVoiceCoaching(WorkoutExercise exercise) {
    ModeSelectionSheet.show(
      context,
      exerciseName: exercise.exercise.name,
      currentMode: _selectedCoachingMode,
      onModeSelected: (mode, remember) {
        setState(() {
          _selectedCoachingMode = mode;
        });

        // Play intro with TTS
        _playExerciseIntro(exercise, mode);
      },
    );
  }

  /// Play exercise introduction with TTS
  Future<void> _playExerciseIntro(
    WorkoutExercise exercise,
    CoachingMode mode,
  ) async {
    final exerciseName = exercise.exercise.name;
    final sets = exercise.sets;
    final reps = exercise.reps;

    if (mode == CoachingMode.voice) {
      // Full voice mode: detailed intro
      await _gigiTTS.speak(
        'Ottimo! Iniziamo con $exerciseName. '
        'Faremo $sets serie da $reps ripetizioni. '
        'Ricorda di mantenere la forma corretta. Pronti? Via!',
      );
    } else {
      // Music mode: minimal cue
      await _gigiTTS.speak('$exerciseName. $sets serie, $reps reps. Via!');
    }

    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mode == CoachingMode.voice
                ? '🎤 Voice Mode attivo - Gigi ti guida!'
                : '🎵 Music Mode attivo - Buon allenamento!',
          ),
          backgroundColor: CleanTheme.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildDifficultyBadge(ExerciseDifficulty difficulty) {
    Color badgeColor;
    String label;

    switch (difficulty) {
      case ExerciseDifficulty.beginner:
        badgeColor = CleanTheme.accentGreen;
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: CleanTheme.primaryColor),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
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
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CleanTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(WorkoutExercise exercise) {
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

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: CleanTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCompleted
                  ? CleanTheme.accentGreen
                  : CleanTheme.primaryColor,
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
                  color: isCompleted
                      ? CleanTheme.accentGreen
                      : CleanTheme.primaryColor,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : Text(
                          '${widget.workoutDay.exercises.indexOf(exercise) + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.exercise.name,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isCompleted
                          ? CleanTheme.textTertiary
                          : CleanTheme.textPrimary,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CleanTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMiniStat(Icons.repeat, '${exercise.sets}'),
                        const SizedBox(width: 12),
                        _buildMiniStat(Icons.fitness_center, exercise.reps),
                        const SizedBox(width: 12),
                        _buildMiniStat(Icons.timer, '${exercise.restSeconds}s'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
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
                            color: CleanTheme.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: CleanTheme.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            muscle,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: CleanTheme.primaryColor,
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
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: CleanTheme.primaryColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: Container(
                decoration: BoxDecoration(
                  color: CleanTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton.icon(
                  onPressed: () => _navigateToExerciseDetail(exercise),
                  icon: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    'Info',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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
                if (exercise.exerciseType != 'cardio' &&
                    exercise.exerciseType != 'mobility')
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: DualAnatomicalView(
                      muscleGroups: exercise.exercise.muscleGroups,
                      height: 150,
                      highlightColor: CleanTheme.primaryColor,
                    ),
                  ),

                const Divider(color: CleanTheme.borderPrimary),

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
                        backgroundColor: CleanTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),

                // AI Form Check - Premium Feature
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FormAnalysisScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        color: CleanTheme.accentPurple,
                      ),
                      label: Text(
                        'Analizza con Gigi',
                        style: GoogleFonts.inter(
                          color: CleanTheme.accentPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(
                          color: CleanTheme.accentPurple,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),

                const Divider(color: CleanTheme.borderPrimary),

                // Voice Coaching - Inizia con Gigi
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CleanTheme.primaryColor.withValues(alpha: 0.1),
                          CleanTheme.accentPurple.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CleanTheme.primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('🎤', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              'Gigi Voice Coach',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: CleanTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _startVoiceCoaching(exercise),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CleanTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '🎤',
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Inizia con Gigi',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(color: CleanTheme.borderPrimary),

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
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Uscire dall\'allenamento?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        content: Text(
          'Il tuo progresso andrà perso. Sei sicuro di voler uscire?',
          style: GoogleFonts.inter(color: CleanTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annulla',
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'Esci',
              style: GoogleFonts.inter(color: CleanTheme.accentRed),
            ),
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
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Completa Allenamento',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        content: Text(
          'Sei sicuro di voler terminare l\'allenamento? Tutti i progressi verranno salvati.',
          style: GoogleFonts.inter(color: CleanTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annulla',
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(
                    color: CleanTheme.primaryColor,
                  ),
                ),
              );

              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              try {
                await provider.completeWorkout();

                if (!mounted) return;
                navigator.pop(); // Close success dialog or loading

                // ignore: use_build_context_synchronously
                await showDialog(
                  context: navigator.context,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: CleanTheme.surfaceColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      'Allenamento Completato!',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    content: Text(
                      'Ottimo lavoro! Il tuo allenamento è stato registrato con successo.',
                      style: GoogleFonts.inter(color: CleanTheme.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          navigator.pop();
                        },
                        child: Text(
                          'Fantastico!',
                          style: GoogleFonts.inter(
                            color: CleanTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Errore durante il salvataggio: $e'),
                    backgroundColor: CleanTheme.accentRed,
                  ),
                );
              }
            },
            child: Text(
              'Termina',
              style: GoogleFonts.inter(
                color: CleanTheme.accentGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
