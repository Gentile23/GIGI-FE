import 'package:flutter/material.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/utils/responsive_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/models/workout_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import '../../../providers/gamification_provider.dart';
import '../../../core/services/sound_service.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final WorkoutDay workoutDay;

  const WorkoutSessionScreen({super.key, required this.workoutDay});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  final Set<String> _completedExercises = {};

  // Trial Workout Local State [NEW]

  // Session Timer
  bool _isSessionActive = false;
  DateTime? _sessionStartTime;
  Timer? _sessionTimer;
  Duration _elapsedTime = Duration.zero;

  // Fullscreen Rest Timer Overlay
  bool _isRestTimerOverlayVisible = false;
  int _restTimerSeconds = 0;
  int _restTimerTotal = 0;
  String? _restingExerciseId;
  int _restingSetNumber = 0;

  // Keys to communicate with SetLoggingWidgets
  final Map<String, GlobalKey<SetLoggingWidgetState>> _setLoggingKeys = {};

  // Session registration tracking
  bool _sessionRegistered = false;
  bool _registrationInProgress = false;
  Timer? _registrationRetryTimer;

  // Flag to allow pop (bypass PopScope)
  bool _allowPop = false;

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

    // Listen for voice coaching status updates
    _voiceController.addListener(_onVoiceStatusChanged);

    // [NEW] Background session registration - register as soon as screen opens
    // This allows logging sets immediately if needed and removes the warning banner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _registerSessionWithBackend();
      }
    });
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
                  color: CleanTheme.textOnDark,
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
    _registrationRetryTimer?.cancel();
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

  /// Auto-start the session the first time any exercise is completed.
  void _autoStartSessionIfNeeded() {
    if (!_isSessionActive) {
      _startWorkoutSession();
    }
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
            color: CleanTheme.textOnDark,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: CleanTheme.textOnDark.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  /// Called by SetLoggingWidget when rest timer starts/stops
  void _onRestTimerStateChanged(
    String exerciseId,
    bool isActive,
    int secondsRemaining,
    int totalSeconds,
    int setNumber,
  ) {
    if (isActive) {
      final uniqueKey = exerciseId;
      setState(() {
        _isRestTimerOverlayVisible = true;
        _restingExerciseId = uniqueKey;
        _restingSetNumber = setNumber;
        _restTimerSeconds = secondsRemaining;
        _restTimerTotal = totalSeconds;
      });
    } else {
      setState(() {
        _isRestTimerOverlayVisible = false;
      });
    }
  }

  WorkoutExercise? _getExerciseById(String id) {
    try {
      return widget.workoutDay.mainWorkout.firstWhere(
        (e) => e.exercise.id == id,
      );
    } catch (_) {
      return null;
    }
  }

  /// Find the next exercise after the given exerciseId
  WorkoutExercise? _getNextExercise(String currentExerciseId) {
    final mainWorkout = widget.workoutDay.mainWorkout;
    for (int i = 0; i < mainWorkout.length; i++) {
      if (mainWorkout[i].exercise.id == currentExerciseId) {
        // If there's a next exercise that's not completed, return it
        for (int j = i + 1; j < mainWorkout.length; j++) {
          if (!_completedExercises.contains(mainWorkout[j].exercise.id)) {
            return mainWorkout[j];
          }
        }
        // If current is last or all following are completed, check uncompleted before
        for (int j = 0; j < i; j++) {
          if (!_completedExercises.contains(mainWorkout[j].exercise.id)) {
            return mainWorkout[j];
          }
        }
        return null; // All completed
      }
    }
    return null;
  }

  /// Skip the rest timer — closes the overlay and notifies the child widget
  void _skipRestTimerOverlay() {
    if (_restingExerciseId != null) {
      _setLoggingKeys[_restingExerciseId]?.currentState?.skipRestTimer();
    }
    setState(() {
      _isRestTimerOverlayVisible = false;
      _restingExerciseId = null;
    });
  }

  Future<void> _startWorkoutSession() async {
    // Only start the timer here if not already active
    if (!_isSessionActive) {
      _startSession();
    }

    // If session is already registered or in progress, we don't need to do anything else here
    // registration happens automatically in initState
    if (_sessionRegistered) {
      debugPrint('DEBUG: Session already registered');
      return;
    }

    if (_registrationInProgress) {
      debugPrint('DEBUG: Session registration already in progress');
      return;
    }

    // If we're here and not registered, something might have failed.
    // We can trigger a manual retry.
    _registerSessionWithBackend();
  }

  /// Register the session with the backend independently of the timer
  Future<void> _registerSessionWithBackend() async {
    if (_sessionRegistered || _registrationInProgress) return;

    // Skip session registration for trial workouts (they have fake IDs)
    if (widget.workoutDay.id.startsWith('trial_')) {
      debugPrint('DEBUG: Skipping session registration for trial workout');
      setState(() {
        _sessionRegistered = true; // Mark as registered for trial
      });
      return;
    }

    setState(() {
      _registrationInProgress = true;
    });

    final provider = Provider.of<WorkoutLogProvider>(context, listen: false);
    debugPrint(
      'DEBUG: Registering workout session for day ID: ${widget.workoutDay.id}',
    );

    // Register session with backend — retry silently up to 3 times
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        await provider.startWorkout(workoutDayId: widget.workoutDay.id);
        if (provider.currentWorkoutLog != null) {
          if (mounted) {
            setState(() {
              _sessionRegistered = true;
              _registrationInProgress = false;
            });
          }
          return; // Success
        }
      } catch (e) {
        debugPrint('Session registration failed (attempt $attempt)');
      }
      // Exponential backoff
      if (attempt < 3 && mounted) {
        await Future.delayed(Duration(seconds: 1 << (attempt - 1)));
      }
    }

    // All retries exhausted — start background retry every 10 seconds
    if (mounted) {
      setState(() {
        _registrationInProgress = false;
      });
      _startRegistrationRetryLoop();
    }
  }

  /// Background retry loop: tries to register the session every 10 seconds
  void _startRegistrationRetryLoop() {
    _registrationRetryTimer?.cancel();
    _registrationRetryTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      if (!mounted || _sessionRegistered) {
        timer.cancel();
        return;
      }
      try {
        final provider = Provider.of<WorkoutLogProvider>(
          context,
          listen: false,
        );
        await provider.startWorkout(workoutDayId: widget.workoutDay.id);
        if (provider.currentWorkoutLog != null) {
          if (mounted) {
            setState(() {
              _sessionRegistered = true;
            });
          }
          timer.cancel();
        }
      } catch (e) {
        // Silent background fail
      }
    });
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

    return PopScope(
      canPop: _allowPop || (!_isSessionActive && _completedExercises.isEmpty),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmExit();
      },
      child: Scaffold(
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
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
                      // Session not registered warning banner
                      if (!_sessionRegistered &&
                          !widget.workoutDay.id.startsWith('trial_'))
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: CleanTheme.accentOrange.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: CleanTheme.accentOrange.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _registrationInProgress
                                    ? Icons.sync_rounded
                                    : Icons.cloud_off_rounded,
                                size: 18,
                                color: CleanTheme.accentOrange,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _registrationInProgress
                                      ? "Registrazione sessione in corso..."
                                      : AppLocalizations.of(
                                          context,
                                        )!.sessionNotRecorded,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: CleanTheme.accentOrange,
                                  ),
                                ),
                              ),
                              if (_registrationInProgress)
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: CleanTheme.accentOrange,
                                  ),
                                ),
                            ],
                          ),
                        ),

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
                      if (widget
                          .workoutDay
                          .postWorkoutExercises
                          .isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildPostWorkoutNavigationCard(),
                      ],
                    ],
                  ),
                );
              },
            ),

            // 3. Floating Action Button - Start Session or Timer Display
            if (MediaQuery.of(context).viewInsets.bottom == 0)
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
                              CleanTheme.steelDark,
                              CleanTheme.primaryColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: CleanTheme.primaryColor.withValues(
                                alpha: 0.4,
                              ),
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
                                            color: CleanTheme.accentRed
                                                .withValues(alpha: 0.6),
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
                                        color: CleanTheme.textOnDark,
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
                                    color: CleanTheme.textOnDark.withValues(
                                      alpha: 0.2,
                                    ),
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
                                      color: CleanTheme.textOnDark,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                // Right: Progress
                                Row(
                                  children: [
                                    Icon(
                                      Icons.fitness_center,
                                      color: CleanTheme.textOnDark.withValues(
                                        alpha: 0.7,
                                      ),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_completedExercises.length}/${widget.workoutDay.mainExerciseCount}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: CleanTheme.textOnDark,
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
                                backgroundColor: CleanTheme.textOnDark
                                    .withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation(
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
                                          (widget.workoutDay.mainExerciseCount >
                                                  0
                                              ? widget
                                                    .workoutDay
                                                    .mainExerciseCount
                                              : 1))
                                      .toStringAsFixed(1),
                                  AppLocalizations.of(context)!.statsMinPerEx,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    // Start Session Button (when session not active and nothing done yet)
                    if (!_isSessionActive && _completedExercises.isEmpty)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _startWorkoutSession,
                          icon: const Icon(Icons.play_arrow_rounded, size: 28),
                          label: Text(
                            AppLocalizations.of(context)!.startSession,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: CleanTheme.textOnDark,
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
                            shadowColor: CleanTheme.primaryColor.withValues(
                              alpha: 0.3,
                            ),
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
                              color: CleanTheme.textOnDark,
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

            // 6. FULLSCREEN REST TIMER OVERLAY
            if (_isRestTimerOverlayVisible) _buildFullscreenRestTimerOverlay(),
          ],
        ),
      ),
    );
  }

  /// Immersive fullscreen rest timer — fills the entire screen
  Widget _buildSetDetailOverlayCard({
    required String title,
    required String exerciseId,
    required int setNumber,
    required bool isNext,
  }) {
    final exercise = _getExerciseById(exerciseId);
    if (exercise == null) return const SizedBox.shrink();

    final setLoggingState = _setLoggingKeys[exerciseId]?.currentState;
    final weightController = setLoggingState?.getWeightController(setNumber);
    final repsController = setLoggingState?.getRepsController(setNumber);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.textOnDark.withValues(alpha: isNext ? 0.12 : 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: CleanTheme.textOnDark.withValues(alpha: isNext ? 0.2 : 0.1),
          width: isNext ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: isNext
                      ? CleanTheme.accentBlue
                      : CleanTheme.textOnDark.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              if (!isNext)
                const Icon(
                  Icons.check_circle_rounded,
                  color: CleanTheme.accentGreen,
                  size: 14,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            exercise.exercise.name,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: CleanTheme.textOnDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Set $setNumber di ${exercise.sets}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CleanTheme.textOnDark.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 16),
          _buildOverlayInputField(
            label: 'KG',
            controller: weightController,
            isNext: isNext,
            exerciseId: exerciseId,
            setNumber: setNumber,
          ),
          const SizedBox(height: 8),
          _buildOverlayInputField(
            label: 'REPS',
            controller: repsController,
            isNext: isNext,
            exerciseId: exerciseId,
            setNumber: setNumber,
            targetValue: _getTargetReps(exercise, setNumber),
          ),
          if (!isNext) ...[
            const SizedBox(height: 16),
            _buildRpeOverlaySelector(
              exerciseId: exerciseId,
              setNumber: setNumber,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNextSetOverlayCard() {
    // Determine the next set
    final currentExercise = _getExerciseById(_restingExerciseId!);
    if (currentExercise == null) return const SizedBox.shrink();

    if (_restingSetNumber < currentExercise.sets) {
      // Next set is in the SAME exercise
      return _buildSetDetailOverlayCard(
        title: 'PROSSIMO SET',
        exerciseId: _restingExerciseId!,
        setNumber: _restingSetNumber + 1,
        isNext: true,
      );
    } else {
      // Next set is in the NEXT exercise
      final nextExercise = _getNextExercise(_restingExerciseId!);
      if (nextExercise != null) {
        return _buildSetDetailOverlayCard(
          title: 'PROSSIMO SET',
          exerciseId: nextExercise.id ?? nextExercise.exercise.id,
          setNumber: 1,
          isNext: true,
        );
      } else {
        // No more exercises
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CleanTheme.accentGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: CleanTheme.accentGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.celebration_rounded,
                color: CleanTheme.accentGreen,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'FINE ALLENAMENTO!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: CleanTheme.accentGreen,
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildOverlayInputField({
    required String label,
    required TextEditingController? controller,
    required bool isNext,
    required String exerciseId,
    required int setNumber,
    String? targetValue,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CleanTheme.textOnDark.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CleanTheme.textOnDark.withValues(alpha: isNext ? 0.3 : 0.1),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: CleanTheme.textOnDark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              key: ValueKey(
                'overlay_input_${label}_${exerciseId}_$setNumber',
              ), // Added Key
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              cursorColor: CleanTheme.accentBlue,
            ),
          ),
          if (targetValue != null && targetValue.isNotEmpty) ...[
            const SizedBox(width: 12),
            Flexible(
              flex: 3,
              child: Text(
                'Obiettivo: $targetValue',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textOnDark.withValues(alpha: 0.4),
                ),
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRpeOverlaySelector({
    required String exerciseId,
    required int setNumber,
  }) {
    final setLoggingState = _setLoggingKeys[exerciseId]?.currentState;
    if (setLoggingState == null) return const SizedBox.shrink();

    final currentRpe = setLoggingState.getRpe(setNumber);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'DIFFICOLTÀ (RPE)',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: CleanTheme.textOnDark.withValues(alpha: 0.5),
              ),
            ),
            const Spacer(),
            Text(
              currentRpe.toString(),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: CleanTheme.accentBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(10, (index) {
              final val = index + 1;
              final isSelected = val == currentRpe;
              return GestureDetector(
                onTap: () {
                  HapticService.selectionClick();
                  setLoggingState.updateRpe(setNumber, val);
                },
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? CleanTheme.accentBlue
                        : CleanTheme.textOnDark.withValues(alpha: 0.1),
                    border: Border.all(
                      color: isSelected
                          ? CleanTheme.accentBlue
                          : CleanTheme.textOnDark.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      val.toString(),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.black
                            : CleanTheme.textOnDark,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  String _getTargetReps(WorkoutExercise exercise, int setNumber) {
    try {
      final repsList = exercise.reps.split(',').map((s) => s.trim()).toList();
      if (repsList.isEmpty) return '10';
      return setNumber <= repsList.length
          ? repsList[setNumber - 1]
          : repsList.last;
    } catch (e) {
      return '10';
    }
  }

  Widget _buildFullscreenRestTimerOverlay() {
    final progress = _restTimerTotal > 0
        ? _restTimerSeconds / _restTimerTotal
        : 0.0;
    final minutes = _restTimerSeconds ~/ 60;
    final seconds = _restTimerSeconds % 60;
    final isUrgent = _restTimerSeconds <= 3 && _restTimerSeconds > 0;

    return Positioned.fill(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: 1.0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                CleanTheme.steelDark,
                CleanTheme.primaryColor.withValues(alpha: 0.95),
                CleanTheme.steelDark,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isUrgent
                            ? CleanTheme.accentRed
                            : CleanTheme.accentBlue,
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isUrgent
                                        ? CleanTheme.accentRed
                                        : CleanTheme.accentBlue)
                                    .withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'RECUPERO',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: CleanTheme.textOnDark.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Huge Timer
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.outfit(
                    fontSize: 80,
                    fontWeight: FontWeight.w800,
                    color: isUrgent
                        ? CleanTheme.accentRed
                        : CleanTheme.textOnDark,
                    letterSpacing: 4,
                  ),
                  child: Text('$minutes:${seconds.toString().padLeft(2, '0')}'),
                ),

                const SizedBox(height: 24),

                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: CleanTheme.textOnDark.withValues(
                        alpha: 0.1,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isUrgent ? CleanTheme.accentRed : CleanTheme.accentBlue,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Set Details View (Previous and Next)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Previous Set Card
                      Expanded(
                        child: _buildSetDetailOverlayCard(
                          title: 'ULTIMO SET',
                          exerciseId: _restingExerciseId!,
                          setNumber: _restingSetNumber,
                          isNext: false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Next Set Card
                      Expanded(child: _buildNextSetOverlayCard()),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Skip Button
                TextButton(
                  onPressed: _skipRestTimerOverlay,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                      side: BorderSide(
                        color: CleanTheme.textOnDark.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Salta',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: CleanTheme.textOnDark.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.skip_next_rounded,
                        size: 20,
                        color: CleanTheme.textOnDark.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CleanTheme.borderSecondary, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: CleanTheme.steelDark),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
              letterSpacing: -0.2,
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
          ...warmupCardio.map((exercise) => _buildExerciseCard(exercise)),
          // Inline Mobility Exercises
          ...preWorkoutMobility.map((exercise) => _buildExerciseCard(exercise)),
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
          ...postWorkoutExercises.map(
            (exercise) => _buildExerciseCard(exercise),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element

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

  Widget _buildSectionHeader(String title, String emoji) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: CleanTheme.primaryColor,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [CleanTheme.chromeSubtle, Colors.transparent],
              ),
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
    bool isPrimary = false,
    bool isOutlined = false,
  }) {
    final bgColor = isOutlined
        ? Colors.transparent
        : (isPrimary ? CleanTheme.steelDark : CleanTheme.surfaceColor);
    final iconColor = isOutlined
        ? CleanTheme.textPrimary
        : (isPrimary ? CleanTheme.textOnDark : color);
    final textColor = isOutlined
        ? CleanTheme.textPrimary
        : (isPrimary ? CleanTheme.textOnDark : CleanTheme.textSecondary);
    final borderColor = isOutlined
        ? CleanTheme.textPrimary.withValues(alpha: 0.8)
        : (isPrimary ? CleanTheme.steelDark : CleanTheme.borderSecondary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: isOutlined ? 1.5 : 1),
            boxShadow: isOutlined
                ? null
                : (isPrimary
                      ? [
                          BoxShadow(
                            color: CleanTheme.steelDark.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: iconColor),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: isPrimary || isOutlined
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(WorkoutExercise exercise) {
    // Staggered entry animation index
    final index = widget.workoutDay.mainWorkout.indexOf(exercise);

    // All exercise types now use the full card renderer
    final type = exercise.exerciseType.toLowerCase();

    final isMobilityType =
        type == 'mobility' || type == 'warmup' || type == 'cardio';

    return Consumer<WorkoutLogProvider>(
          builder: (context, provider, child) {
            final exerciseLog = provider.currentWorkoutLog?.exerciseLogs
                .firstWhere(
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

            final isCompleted = _completedExercises.contains(
              exercise.exercise.id,
            );

            // Determine if this is the next exercise to perform
            final mainWorkout = widget.workoutDay.mainWorkout;
            final firstUncompleted = mainWorkout.isEmpty
                ? exercise
                : mainWorkout.firstWhere(
                    (e) => !_completedExercises.contains(e.exercise.id),
                    orElse: () =>
                        mainWorkout.isNotEmpty ? mainWorkout.first : exercise,
                  );
            final isNext =
                _isSessionActive &&
                exercise.exercise.id == firstUncompleted.exercise.id;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: CleanTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCompleted
                      ? CleanTheme.accentGreen.withValues(alpha: 0.5)
                      : isNext
                      ? CleanTheme.steelDark
                      : CleanTheme.borderSecondary,
                  width: isNext ? 1.5 : 1,
                ),
                boxShadow: isNext
                    ? [
                        BoxShadow(
                          color: CleanTheme.steelDark.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : isCompleted
                    ? [
                        BoxShadow(
                          color: CleanTheme.accentGreen.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top accent strip for "next" exercise
                    if (isNext)
                      Container(
                        height: 3,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [CleanTheme.steelDark, CleanTheme.steelMid],
                          ),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Number Badge
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            width: 34,
                            height: 34,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? CleanTheme.accentGreen
                                  : CleanTheme.steelDark,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isCompleted
                                              ? CleanTheme.accentGreen
                                              : CleanTheme.steelDark)
                                          .withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: isCompleted
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: CleanTheme.textOnDark,
                                    )
                                  : Text(
                                      '${widget.workoutDay.exercises.indexOf(exercise) + 1}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: CleanTheme.textOnDark,
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
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: isCompleted
                                        ? CleanTheme.textTertiary
                                        : CleanTheme.textPrimary,
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 14,
                                      color: CleanTheme.accentOrange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${exercise.restSeconds}s',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: CleanTheme.accentOrange,
                                      ),
                                    ),
                                    if (exercise
                                        .exercise
                                        .muscleGroups
                                        .isNotEmpty) ...[
                                      const SizedBox(width: 10),
                                      Text(
                                        '•',
                                        style: TextStyle(
                                          color: CleanTheme.textTertiary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          exercise.exercise.muscleGroups.join(
                                            ', ',
                                          ),
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: CleanTheme.textSecondary,
                                            fontWeight: FontWeight.w500,
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

                          // 3. Anatomical View (Top Right)
                          if (true) ...[
                            const SizedBox(width: 4),
                            Container(
                              width: 76,
                              height: 100,
                              decoration: BoxDecoration(
                                color: CleanTheme.chromeSubtle.withValues(
                                  alpha: 0.4,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: DualAnatomicalView(
                                  muscleGroups:
                                      exercise.exercise.muscleGroups.isNotEmpty
                                      ? exercise.exercise.muscleGroups
                                      : [exercise.exercise.name],
                                  secondaryMuscleGroups:
                                      exercise.exercise.secondaryMuscleGroups,
                                  height: 100,
                                  highlightColor: CleanTheme.steelDark,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Set Logging Widget
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SetLoggingWidget(
                        key: _setLoggingKeys.putIfAbsent(
                          exercise.id ?? exercise.exercise.id,
                          () => GlobalKey<SetLoggingWidgetState>(),
                        ),
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
                          _autoStartSessionIfNeeded();
                          if (widget.workoutDay.id.startsWith('trial_')) {}
                        },
                        onRestTimerSkipped: () {},
                        onRestTimerStateChanged:
                            (
                              isActive,
                              secondsRemaining,
                              totalSeconds,
                              setNumber,
                            ) {
                              _onRestTimerStateChanged(
                                exercise.id ?? exercise.exercise.id,
                                isActive,
                                secondsRemaining,
                                totalSeconds,
                                setNumber,
                              );
                            },
                      ),
                    ),

                    // Quick Actions row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionButton(
                              icon: Icons.info_outline_rounded,
                              label: AppLocalizations.of(context)!.info,
                              color: CleanTheme.chromeGray,
                              onTap: () => _navigateToExerciseDetail(exercise),
                              isOutlined: isMobilityType,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildQuickActionButton(
                              icon: Icons.camera_alt_outlined,
                              label: AppLocalizations.of(context)!.aiCheck,
                              color: CleanTheme.steelDark,
                              isPrimary: !isMobilityType,
                              isOutlined: isMobilityType,
                              onTap: () {
                                final exerciseId = int.tryParse(
                                  exercise.exercise.id,
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FormAnalysisScreen(
                                      exerciseName: exercise.exercise.name,
                                      exerciseId: exerciseId,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── ESEGUI CON GIGI – Premium CTA ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      child: _GigiExecuteButton(
                        onTap: () => _startGuidedExecution(exercise),
                        label: AppLocalizations.of(context)!.executeWithGigi,
                        isOutlined: isMobilityType,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        )
        .animate(delay: (index * 80).ms)
        .fade(duration: 500.ms, curve: Curves.easeOut)
        .slideY(begin: 0.15, duration: 500.ms, curve: Curves.easeOutCubic)
        .shimmer(
          duration: 1500.ms,
          color: CleanTheme.steelMid.withValues(alpha: 0.2),
          angle: 1.2,
        );
  }

  void _confirmExit() {
    if (!_isSessionActive && _completedExercises.isEmpty) {
      _gigiTTS.stop(); // Stop audio immediately before exit
      _voiceController.deactivate();
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
              _gigiTTS.stop(); // Stop audio immediately on exit confirmation
              _voiceController.deactivate();
              Navigator.pop(context); // close dialog
              setState(() => _allowPop = true);
              Navigator.pop(context); // close screen
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
              final gamificationProvider = Provider.of<GamificationProvider>(
                context,
                listen: false,
              );

              try {
                debugPrint(
                  'DEBUG: Completing workout, currentLog exists: ${provider.currentWorkoutLog != null}',
                );

                // ANTICIPATION: Play workout complete sound IMMEDIATELY on confirmation
                SoundService().play(SoundType.workoutComplete);

                if (provider.currentWorkoutLog != null) {
                  debugPrint(
                    'DEBUG: Workout log ID: ${provider.currentWorkoutLog!.id}',
                  );
                }
                await provider.completeWorkout();

                // Refresh gamification stats so home screen updates
                gamificationProvider.refresh();

                if (!mounted) return;
                navigator.pop(); // Close loading dialog

                // Collect muscle groups from completed exercises
                final muscleGroups = <String>{};
                for (final exercise in widget.workoutDay.mainWorkout) {
                  if (_completedExercises.contains(exercise.exercise.id)) {
                    muscleGroups.addAll(exercise.exercise.muscleGroups);
                  }
                }

                // Calcola statistiche reali dai set loggati
                double totalKgLifted = 0;
                int totalReps = 0;
                int realCompletedSets = 0;
                double rpeSum = 0;
                int rpeCount = 0;

                final workoutLog = provider.currentWorkoutLog;
                if (workoutLog != null) {
                  for (final exLog in workoutLog.exerciseLogs) {
                    for (final setLog in exLog.setLogs) {
                      if (setLog.completed) {
                        realCompletedSets++;
                        final weight = setLog.weightKg ?? 0;
                        final reps = setLog.reps;
                        totalKgLifted += weight * reps;
                        totalReps += reps;
                        if (setLog.rpe != null && setLog.rpe! > 0) {
                          rpeSum += setLog.rpe!;
                          rpeCount++;
                        }
                      }
                    }
                  }
                }

                final avgRpe = rpeCount > 0 ? rpeSum / rpeCount : null;

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
                  completedSets: realCompletedSets > 0
                      ? realCompletedSets
                      : _completedExercises.length * 3,
                  muscleGroupsWorked: muscleGroups.toList(),
                  totalKgLifted: totalKgLifted,
                  totalReps: totalReps,
                  avgRpe: avgRpe,
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
                    content: Text(AppLocalizations.of(context)!.saveErrorGeneric),
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
          content: const Text("Si è verificato un errore durante il salvataggio della valutazione."),
          backgroundColor: CleanTheme.accentRed,
        ),
      );
    }
  }
}

/// Premium "Esegui con Gigi" button – full-width, black, animated shimmer.
class _GigiExecuteButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;
  final bool isOutlined;

  const _GigiExecuteButton({
    required this.onTap,
    required this.label,
    this.isOutlined = false,
  });

  @override
  State<_GigiExecuteButton> createState() => _GigiExecuteButtonState();
}

class _GigiExecuteButtonState extends State<_GigiExecuteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return Container(
              height: 52,
              decoration: BoxDecoration(
                color: widget.isOutlined ? Colors.transparent : Colors.black,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.isOutlined
                      ? Colors.black.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.15),
                  width: widget.isOutlined ? 1.5 : 1,
                ),
                boxShadow: widget.isOutlined
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Stack(
                children: [
                  // Shimmer sweep (hidden for outlined)
                  if (!widget.isOutlined)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _ShimmerSweep(controller: _shimmerController),
                      ),
                    ),
                  // Content
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pulsing mic icon
                        _PulsingMicIcon(
                          controller: _shimmerController,
                          color: widget.isOutlined
                              ? Colors.black
                              : Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.label,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: widget.isOutlined
                                ? Colors.black
                                : Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Diagonal shimmer sweep overlay.
class _ShimmerSweep extends StatelessWidget {
  final AnimationController controller;

  const _ShimmerSweep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        // Sweep from -0.3 to 1.3 of width
        final sweepX = (t * 1.6) - 0.3;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(sweepX - 0.3, 0),
            end: Alignment(sweepX + 0.3, 0),
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ).createShader(bounds),
          child: Container(color: Colors.white),
        );
      },
    );
  }
}

/// Softly pulsing mic icon.
class _PulsingMicIcon extends StatelessWidget {
  final AnimationController controller;
  final Color? color;

  const _PulsingMicIcon({required this.controller, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.white;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Pulse: 0→1→0 mapped to scale 1.0→1.25→1.0
        final pulse = (controller.value * 2 * 3.14159).abs();
        final scale =
            1.0 +
            0.18 *
                ((pulse).abs() % (2 * 3.14159) < 3.14159
                    ? (pulse % 3.14159) / 3.14159
                    : 1.0 - (pulse % 3.14159) / 3.14159);
        return Transform.scale(
          scale: scale.clamp(1.0, 1.18),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: effectiveColor.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.record_voice_over_rounded,
              color: effectiveColor,
              size: 18,
            ),
          ),
        );
      },
    );
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
