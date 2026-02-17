import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/models/workout_model.dart';
import 'package:provider/provider.dart';
import '../../../providers/workout_log_provider.dart';
import '../../../data/models/workout_log_model.dart';
import '../../widgets/workout/dual_anatomical_view.dart';
import '../../widgets/workout/set_logging_widget.dart';
import 'exercise_detail_screen.dart';
import 'mobility_exercise_detail_screen.dart';
import 'cardio_exercise_detail_screen.dart';
import '../form_analysis/form_analysis_screen.dart';
import 'workout_summary_screen.dart';
// import '../../widgets/voice_coaching/voice_coaching_toggle.dart'; // Removed
import '../../widgets/voice_coaching/voice_controls_bar.dart';
import '../../../core/services/gigi_tts_service.dart';
import '../../../core/services/synchronized_voice_controller.dart';
import '../../../data/services/api_client.dart';
import 'dart:async';
import '../../../providers/auth_provider.dart';
import '../../../data/services/voice_coaching_service.dart';
import '../../../data/services/trial_workout_service.dart'; // [NEW]
import '../../../data/models/trial_workout_model.dart'; // [NEW]
import 'package:gigi/l10n/app_localizations.dart';

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

  // Trial Workout Local State [NEW]
  // Trial Workout Local State [NEW]

  // Session Timer
  bool _isSessionActive = false;
  DateTime? _sessionStartTime;
  Timer? _sessionTimer;
  Duration _elapsedTime = Duration.zero;

  // Voice Coaching TTS
  late GigiTTSService _gigiTTS;

  // Voice Coaching 2.0 Controller
  late SynchronizedVoiceController _voiceController;

  // Voice Coaching API Service
  late VoiceCoachingService _voiceCoachingService;

  // Trial Service [NEW]
  late TrialWorkoutService _trialWorkoutService;

  @override
  void initState() {
    super.initState();

    final apiClient = ApiClient();

    // Initialize services in correct order for dependency injection
    _voiceCoachingService = VoiceCoachingService(apiClient);
    _trialWorkoutService = TrialWorkoutService(apiClient); // [NEW]

    _gigiTTS = GigiTTSService(_voiceCoachingService);
    _gigiTTS.initialize();

    // Initialize Voice Coaching 2.0 Controller
    _voiceController = SynchronizedVoiceController(_gigiTTS);
    _initializeVoiceCoaching();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startWorkoutSession();
    });

    // Listen for voice coaching status updates
    _voiceController.addListener(_onVoiceStatusChanged);
  }

  void _onVoiceStatusChanged() {
    final status = _voiceController.loadingStatus;

    if (status != null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Text(status),
            ],
          ),
          duration: const Duration(days: 1), // Persistent until cleared
          backgroundColor: CleanTheme.primaryColor,
          behavior: SnackBarBehavior.floating, // Better visibility
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      // Hide snackbar if it was related to loading
      // We don't want to hide other potential snackbars if we can help it,
      // but simpler is to just hide current if we are transitioning out of loading.
      // However, to be safe, we only hide if we were showing one.
      // Since we can't easily check 'which' snackbar is showing, we just hide current.
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    }
  }

  /// Initialize voice coaching with user data
  Future<void> _initializeVoiceCoaching() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    await _voiceController.initialize(
      userName: user?.name ?? 'Campione',
      experienceLevel: user?.experienceLevel,
      goal: user?.goal,
    );
  }

  @override
  void dispose() {
    _voiceController.removeListener(_onVoiceStatusChanged);
    _sessionTimer?.cancel();
    _gigiTTS.dispose();
    _voiceController.dispose();
    super.dispose();
  }

  void _startSession() {
    setState(() {
      _isSessionActive = true;
      _sessionStartTime = DateTime.now();
    });

    // Notify Gigi that session has started (Silent)
    // _voiceController.notifySessionStarted();

    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_sessionStartTime != null) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_sessionStartTime!);
        });
      }
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$minutes:$seconds';
  }

  Widget _buildSessionStat(String emoji, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: Colors.white60),
        ),
      ],
    );
  }

  Future<void> _startWorkoutSession() async {
    final provider = Provider.of<WorkoutLogProvider>(context, listen: false);
    debugPrint(
      'DEBUG: Starting workout session for day ID: ${widget.workoutDay.id}',
    );

    // Skip session registration for trial workouts (they have fake IDs)
    // Trial workouts don't need server-side logging
    if (widget.workoutDay.id.startsWith('trial_')) {
      debugPrint('DEBUG: Skipping session registration for trial workout');
      // Auto-start the session timer for trial workout
      if (!_isSessionActive) {
        _startSession();
      }
      return;
    }

    try {
      await provider.startWorkout(workoutDayId: widget.workoutDay.id);

      if (provider.currentWorkoutLog != null) {
        debugPrint(
          'DEBUG: Workout log created with ID: ${provider.currentWorkoutLog!.id}',
        );
      } else {
        debugPrint('DEBUG: WARNING - Workout log is NULL after startWorkout');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.sessionNotRecorded),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('DEBUG: Error starting workout session: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.sessionStartError(e.toString()),
            ),
            backgroundColor: CleanTheme.accentRed,
          ),
        );
      }
    }
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
                  AppLocalizations.of(context)!.noExercisesTitle,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.noExercisesSubtitle,
                  style: GoogleFonts.inter(color: CleanTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CleanTheme.primaryColor,
                  ),
                  child: Text(AppLocalizations.of(context)!.goBack),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: CleanTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: CleanTheme.textPrimary,
          ),
          onPressed: () => _confirmExit(),
        ),
        title: Text(
          widget.workoutDay.name.split(' - ').first,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 2. Sliding Content Sheet
          // Full Screen Content Sheet (no hero image)
          DraggableScrollableSheet(
            initialChildSize: 1.0,
            minChildSize: 0.85,
            maxChildSize: 1.0,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: CleanTheme
                      .scaffoldBackgroundColor, // Light gray for contrast with white cards
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    24,
                    20,
                    ResponsiveUtils.floatingElementPadding(
                      context,
                      baseHeight: 200,
                    ),
                  ), // Dynamic bottom padding for floating stats + button
                  children: [
                    // Stats Header
                    _buildStatsHeader(),
                    const SizedBox(height: 16),

                    // Pre-Workout Navigation
                    if (widget.workoutDay.warmupCardio.isNotEmpty ||
                        widget.workoutDay.preWorkoutMobility.isNotEmpty) ...[
                      _buildPreWorkoutNavigationCard(),
                      const SizedBox(height: 16),
                    ],

                    // Main Workout Section
                    _buildSectionHeader(
                      AppLocalizations.of(context)!.mainWorkoutSection,
                      '💪',
                    ),
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

          // 3. Floating Action Button - Start Session or Timer Display
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Timer Display when session is active
                if (_isSessionActive)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CleanTheme.primaryColor,
                          CleanTheme.accentPurple,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: CleanTheme.primaryColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Main timer row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left: Recording indicator + Timer
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: CleanTheme.accentRed,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: CleanTheme.accentRed.withValues(
                                          alpha: 0.6,
                                        ),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _formatDuration(_elapsedTime),
                                  style: GoogleFonts.outfit(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                            // Center: Workout type
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.workoutDay.name
                                    .split(' - ')
                                    .last
                                    .toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            // Right: Progress
                            Row(
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_completedExercises.length}/${widget.workoutDay.mainExerciseCount}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: widget.workoutDay.mainExerciseCount > 0
                                ? _completedExercises.length /
                                      widget.workoutDay.mainExerciseCount
                                : 0,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                            valueColor: const AlwaysStoppedAnimation(
                              CleanTheme.accentGreen,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSessionStat(
                              '🔥',
                              '${(_elapsedTime.inMinutes * 8).clamp(0, 999)}',
                              AppLocalizations.of(context)!.statsCalories,
                            ),
                            _buildSessionStat(
                              '💪',
                              '${_completedExercises.length * 3}',
                              AppLocalizations.of(context)!.statsSeries,
                            ),
                            _buildSessionStat(
                              '⏱️',
                              (_elapsedTime.inMinutes /
                                      (widget.workoutDay.mainExerciseCount > 0
                                          ? widget.workoutDay.mainExerciseCount
                                          : 1))
                                  .toStringAsFixed(1),
                              AppLocalizations.of(context)!.statsMinPerEx,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                // Start Session Button (when session not active)
                if (!_isSessionActive && _completedExercises.isEmpty)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _startSession,
                      icon: const Icon(Icons.play_arrow_rounded, size: 28),
                      label: Text(
                        AppLocalizations.of(context)!.startSession,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CleanTheme.accentGreen,
                        elevation: 8,
                        shadowColor: CleanTheme.accentGreen.withValues(
                          alpha: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  ),

                // Finish Workout Button (when session is active)
                if (_isSessionActive) const SizedBox(height: 12),
                if (_isSessionActive)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _finishWorkout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _completedExercises.length ==
                                widget.workoutDay.mainExerciseCount
                            ? CleanTheme.accentGreen
                            : CleanTheme.primaryColor,
                        elevation: 8,
                        shadowColor: Colors.black26,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: Text(
                        _completedExercises.length ==
                                widget.workoutDay.mainExerciseCount
                            ? AppLocalizations.of(context)!.completeWorkout
                            : AppLocalizations.of(context)!.finishSession,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // 4. Floating Voice Coaching Toggle REMOVED

          // 5. Floating Voice Controls Bar (Centered)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Center(
              child: VoiceControlsBar(controller: _voiceController),
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
          '${widget.workoutDay.exercises.length} ${AppLocalizations.of(context)!.exercisesStats}',
        ),
        const SizedBox(width: 12),
        _buildStatBadge(
          Icons.local_fire_department,
          '${widget.workoutDay.estimatedDuration * 7} ${AppLocalizations.of(context)!.kcalStats}',
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
    final warmupCardio = widget.workoutDay.warmupCardio;
    final preWorkoutMobility = widget.workoutDay.preWorkoutMobility;

    if (warmupCardio.isEmpty && preWorkoutMobility.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CleanTheme.primaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CleanTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.play_circle_outline,
                  color: CleanTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.preWorkoutSection,
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Inline Cardio Exercises
          ...warmupCardio.map(
            (exercise) => _buildInlineCardioMobilityExercise(
              exercise: exercise,
              sectionId: 'warmupCardio_${exercise.exercise.id}',
              emoji: '🔥',
              color: CleanTheme.accentOrange,
            ),
          ),
          // Inline Mobility Exercises
          ...preWorkoutMobility.map(
            (exercise) => _buildInlineCardioMobilityExercise(
              exercise: exercise,
              sectionId: 'preWorkoutMobility_${exercise.exercise.id}',
              emoji: '🤸',
              color: CleanTheme.accentBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineCardioMobilityExercise({
    required WorkoutExercise exercise,
    required String sectionId,
    required String emoji,
    required Color color,
  }) {
    final isCompleted = _completedSections.contains(sectionId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isCompleted ? 0.15 : 0.08),
            color.withValues(alpha: isCompleted ? 0.08 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? CleanTheme.accentGreen
              : color.withValues(alpha: 0.3),
          width: isCompleted ? 2 : 1.5,
        ),
      ),
      child: Row(
        children: [
          // Emoji circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          // Exercise info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exercise.name,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? CleanTheme.textSecondary
                        : CleanTheme.textPrimary,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      '${exercise.reps} min',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                    if (exercise.exercise.muscleGroups.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Text(
                        '•',
                        style: TextStyle(color: CleanTheme.textTertiary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          exercise.exercise.muscleGroups.join(', '),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: CleanTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Checkbox
          const SizedBox(width: 8),
          // Info button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Navigate to exercise detail screen
                final exerciseType = exercise.exerciseType;
                if (exerciseType == 'cardio') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CardioExerciseDetailScreen(workoutExercise: exercise),
                    ),
                  );
                } else if (exerciseType == 'mobility') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MobilityExerciseDetailScreen(
                        workoutExercise: exercise,
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ExerciseDetailScreen(workoutExercise: exercise),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.info_outline, color: color, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: isCompleted,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _completedSections.add(sectionId);
                  } else {
                    _completedSections.remove(sectionId);
                  }
                });
              },
              activeColor: CleanTheme.accentGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              side: BorderSide(color: color, width: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostWorkoutNavigationCard() {
    final postWorkoutExercises = widget.workoutDay.postWorkoutExercises;

    if (postWorkoutExercises.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CleanTheme.primaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CleanTheme.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: CleanTheme.accentGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.postWorkoutSection,
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Inline post-workout exercises
          ...postWorkoutExercises.map((exercise) {
            final isCardio = exercise.exerciseType == 'cardio';
            return _buildInlineCardioMobilityExercise(
              exercise: exercise,
              sectionId: 'postWorkout_${exercise.exercise.id}',
              emoji: isCardio ? '🏃' : '🧘',
              color: isCardio ? CleanTheme.accentOrange : CleanTheme.accentBlue,
            );
          }),
        ],
      ),
    );
  }

  // ignore: unused_element
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

  /// Start guided execution with Gigi - "Esegui con Gigi" button
  /// Plays a step-by-step guide for 2 perfect reps
  Future<void> _startGuidedExecution(WorkoutExercise exercise) async {
    // Check if already playing
    if (_voiceController.isGuidedExecutionPlaying) {
      // Stop if already playing
      _voiceController.stopGuidedExecution();
      return;
    }

    // Show snackbar that Gigi is starting

    // Start guided execution (tries API first, then local fallback)
    await _voiceController.speakGuidedExecution(
      exerciseName: exercise.exercise.name,
      exerciseId: exercise.exercise.id,
      muscleGroups: exercise.exercise.muscleGroups,
      voiceCoachingService: _voiceCoachingService,
    );

    // Clear snackbar when done
  }

  Widget _buildDifficultyBadge(ExerciseDifficulty difficulty) {
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

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.12),
                color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
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

        // Determine if this is the next exercise to perform
        final mainWorkout = widget.workoutDay.mainWorkout;
        final firstUncompleted = mainWorkout.firstWhere(
          (e) => !_completedExercises.contains(e.exercise.id),
          orElse: () => mainWorkout.first,
        );
        final isNext =
            _isSessionActive &&
            exercise.exercise.id == firstUncompleted.exercise.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: CleanTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isNext
                  ? CleanTheme.primaryColor
                  : isCompleted
                  ? CleanTheme.accentGreen
                  : CleanTheme.borderPrimary,
              width: (isNext || isCompleted) ? 2 : 1,
            ),
            boxShadow: isNext
                ? [
                    BoxShadow(
                      color: CleanTheme.primaryColor.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Number Badge
                    Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? CleanTheme.accentGreen
                            : CleanTheme.primaryColor,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.white,
                              )
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
                    const SizedBox(width: 12),

                    // 2. Title & Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.exercise.name,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
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
                          Row(
                            children: [
                              _buildDifficultyBadge(
                                exercise.exercise.difficulty,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: CleanTheme.backgroundColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${exercise.sets}×${exercise.reps} • ${exercise.restSeconds}s',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: CleanTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // 3. Anatomical View (Top Right)
                    if (exercise.exerciseType != 'cardio' &&
                        exercise.exerciseType != 'mobility') ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 80,
                        height: 105, // Larger size
                        decoration: BoxDecoration(
                          color: CleanTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: DualAnatomicalView(
                            muscleGroups:
                                exercise.exercise.muscleGroups.isNotEmpty
                                ? exercise.exercise.muscleGroups
                                : [exercise.exercise.name],
                            secondaryMuscleGroups:
                                exercise.exercise.secondaryMuscleGroups,
                            height: 105,
                            highlightColor: const Color(0xFFFF0000),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ALWAYS VISIBLE: Set Logging Widget
              SetLoggingWidget(
                exercise: exercise,
                exerciseLog: exerciseLog?.id.isNotEmpty == true
                    ? exerciseLog
                    : null,
                isTrial: widget.workoutDay.id.startsWith('trial_'),
                onCompletionChanged: (allSetsCompleted) {
                  setState(() {
                    if (allSetsCompleted) {
                      _completedExercises.add(exercise.exercise.id);
                    } else {
                      _completedExercises.remove(exercise.exercise.id);
                    }
                  });
                },
                onSetCompleted: (setData) {
                  // [NEW] Track trial progress locally
                  if (widget.workoutDay.id.startsWith('trial_')) {
                    // We just track that the set was done.
                  }
                },
                onRestTimerSkipped: () {
                  // Voice coaching disabled on rest skip per user request
                },
              ),

              // Divider + Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Divider(
                  color: CleanTheme.borderPrimary.withValues(alpha: 0.5),
                  height: 1,
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.info_outline,
                        label: AppLocalizations.of(context)!.info,
                        color: CleanTheme.primaryColor,
                        onTap: () => _navigateToExerciseDetail(exercise),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.camera_alt_outlined,
                        label: AppLocalizations.of(context)!.aiCheck,
                        color: CleanTheme.accentPurple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FormAnalysisScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildQuickActionButton(
                        icon: Icons.record_voice_over,
                        label: AppLocalizations.of(context)!.executeWithGigi,
                        color: CleanTheme.accentBlue,
                        onTap: () => _startGuidedExecution(exercise),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
          AppLocalizations.of(context)!.exitWorkoutTitle,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.exitWorkoutMessage,
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
              AppLocalizations.of(context)!.confirmExit,
              style: GoogleFonts.inter(color: CleanTheme.accentRed),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finishWorkout() async {
    // [NEW] Trial Workout Handling
    if (widget.workoutDay.id.startsWith('trial_')) {
      _finishTrialWorkout();
      return;
    }

    final provider = Provider.of<WorkoutLogProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context)!.finishWorkoutTitle,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.finishWorkoutMessage,
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

              try {
                debugPrint(
                  'DEBUG: Completing workout, currentLog exists: ${provider.currentWorkoutLog != null}',
                );
                if (provider.currentWorkoutLog != null) {
                  debugPrint(
                    'DEBUG: Workout log ID: ${provider.currentWorkoutLog!.id}',
                  );
                }
                await provider.completeWorkout();

                if (!mounted) return;
                navigator.pop(); // Close loading dialog

                // Collect muscle groups from completed exercises
                final muscleGroups = <String>{};
                for (final exercise in widget.workoutDay.mainWorkout) {
                  if (_completedExercises.contains(exercise.exercise.id)) {
                    muscleGroups.addAll(exercise.exercise.muscleGroups);
                  }
                }

                // Create summary data
                final summaryData = WorkoutSummaryData(
                  workoutName: widget.workoutDay.name,
                  duration: _elapsedTime,
                  completedExercises: _completedExercises.length,
                  totalExercises: widget.workoutDay.mainExerciseCount,
                  estimatedCalories: (_elapsedTime.inMinutes * 8).clamp(
                    0,
                    9999,
                  ),
                  completedSets: _completedExercises.length * 3, // Approximate
                  muscleGroupsWorked: muscleGroups.toList(),
                );

                // Navigate to summary screen
                // ignore: use_build_context_synchronously
                await Navigator.of(navigator.context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) =>
                        WorkoutSummaryScreen(summaryData: summaryData),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                navigator.pop();
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    // ignore: use_build_context_synchronously
                    content: Text(AppLocalizations.of(context)!.saveError(e)),
                    backgroundColor: CleanTheme.accentRed,
                  ),
                );
              }
            },
            child: Text(
              AppLocalizations.of(context)!.finish,
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

  // [NEW] Trial Workout Completion Flow
  void _finishTrialWorkout() {
    // Show assessment dialog to capture fatigue and submit
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _TrialAssessmentDialog(
        onConfirm: (fatigue, difficulty) {
          _submitTrialResults(fatigue, difficulty);
        },
      ),
    );
  }

  Future<void> _submitTrialResults(int fatigue, int difficulty) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: CleanTheme.primaryColor),
      ),
    );

    try {
      // 1. Calculate Stats
      final skippedExercises = widget.workoutDay.exercises
          .where((e) => !_completedExercises.contains(e.exercise.id))
          .map((e) => e.exercise.id)
          .toList();

      // Create difficulty map (using overall difficulty for all completed exercises for now)
      final difficultyMap = <String, int>{};
      for (final exerciseId in _completedExercises) {
        difficultyMap[exerciseId] = difficulty;
      }

      final performanceData = TrialPerformanceData(
        difficultyRatings: difficultyMap,
        skippedExercises: skippedExercises,
        totalRestTime: 0,
        overallFatigue: fatigue,
        formIssues: [],
        feedback: "Trial completed via app",
      );

      // 2. Submit to Backend
      final result = await _trialWorkoutService.submitTrialResults(
        performanceData,
      );

      if (!mounted) return;
      Navigator.pop(context); // Pop loading

      if (result != null) {
        // Success!
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.workoutCompleted),
            backgroundColor: CleanTheme.accentGreen,
          ),
        );

        // Navigate to Home or specific success screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        throw Exception("Failed to submit results");
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Pop loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Errore salvataggio valutazione: $e"),
          backgroundColor: CleanTheme.accentRed,
        ),
      );
    }
  }
}

// [NEW] Simple Assessment Dialog for Trial
class _TrialAssessmentDialog extends StatefulWidget {
  final Function(int fatigue, int difficulty) onConfirm;

  const _TrialAssessmentDialog({required this.onConfirm});

  @override
  State<_TrialAssessmentDialog> createState() => _TrialAssessmentDialogState();
}

class _TrialAssessmentDialogState extends State<_TrialAssessmentDialog> {
  int _fatigue = 3;
  int _difficulty = 3;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: CleanTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        "Completamento Valutazione",
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSlider(
            "Fatica Complessiva (1-5)",
            _fatigue,
            (val) => setState(() => _fatigue = val),
          ),
          const SizedBox(height: 16),
          _buildSlider(
            "Difficoltà Percepita (1-5)",
            _difficulty,
            (val) => setState(() => _difficulty = val),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Annulla",
            style: TextStyle(color: CleanTheme.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onConfirm(_fatigue, _difficulty);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: CleanTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text("Completa", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildSlider(String label, int value, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 14)),
            Text(
              "$value",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 5,
          divisions: 4,
          activeColor: CleanTheme.primaryColor,
          onChanged: (v) => onChanged(v.toInt()),
        ),
      ],
    );
  }
}
