import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../data/models/workout_chat_model.dart';
import '../../../data/services/workout_chat_service.dart';
import 'package:gigi/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../providers/gamification_provider.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/services/rest_timer_service.dart';
import '../../../core/constants/subscription_tiers.dart';
import '../paywall/paywall_screen.dart';
import '../../widgets/voice_coaching/gigi_preparation_overlay.dart';

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
  RestTimerService? _restTimerService;

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

  // Workout Chat
  late WorkoutChatService _workoutChatService;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final List<WorkoutChatMessage> _chatMessages = [];
  bool _isChatOpen = false;
  bool _isChatLoading = false;
  String? _chatError;
  String? _chatContextExerciseId;
  bool _hasSeededChatWelcome = false;
  bool _chatIntroOnly = true;

  @override
  void initState() {
    super.initState();
    _initializeUniqueIdMap();

    final apiClient = ApiClient();

    // Initialize services in correct order for dependency injection
    _voiceCoachingService = VoiceCoachingService(apiClient);
    _trialWorkoutService = TrialWorkoutService(apiClient); // [NEW]
    _workoutChatService = WorkoutChatService(apiClient);

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final restTimerService = context.read<RestTimerService>();
    if (_restTimerService == restTimerService) return;

    _restTimerService?.removeListener(_handleRestTimerServiceChanged);
    _restTimerService = restTimerService;
    _restTimerService?.addListener(_handleRestTimerServiceChanged);
    _handleRestTimerServiceChanged();
  }

  void _onVoiceStatusChanged() {
    // Trigger rebuild so the overlay in the Stack updates
    if (mounted) {
      setState(() {});
    }
  }

  void _handleRestTimerServiceChanged() {
    final restTimerService = _restTimerService;
    if (restTimerService == null || !mounted) return;

    final state = restTimerService.state;
    final isCurrentWorkout = state.workoutDayId == widget.workoutDay.id;

    if (state.isActive && isCurrentWorkout && state.exerciseId != null) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {
        _isRestTimerOverlayVisible = true;
        _restingExerciseId = state.exerciseId;
        _restingSetNumber = state.setNumber;
        _restTimerSeconds = restTimerService.remainingSeconds;
        _restTimerTotal = state.totalSeconds;
      });
      return;
    }

    if (state.completed && isCurrentWorkout) {
      setState(() {
        _isRestTimerOverlayVisible = false;
        _restingExerciseId = null;
        _restingSetNumber = 0;
        _restTimerSeconds = 0;
        _restTimerTotal = 0;
      });
      Future.microtask(restTimerService.acknowledgeCompletion);
      return;
    }

    if (_isRestTimerOverlayVisible) {
      setState(() {
        _isRestTimerOverlayVisible = false;
        _restingExerciseId = null;
        _restingSetNumber = 0;
        _restTimerSeconds = 0;
        _restTimerTotal = 0;
      });
    }
  }

  final Map<String, WorkoutExercise> _exerciseByUniqueId = {};

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
    _restTimerService?.removeListener(_handleRestTimerServiceChanged);
    _voiceController.removeListener(_onVoiceStatusChanged);
    _sessionTimer?.cancel();
    _registrationRetryTimer?.cancel();
    _chatController.dispose();
    _chatScrollController.dispose();
    _gigiTTS.dispose();
    _voiceController.dispose();
    super.dispose();
  }

  void _startSession() {
    setState(() {
      _isSessionActive = true;
      _sessionStartTime = DateTime.now();
    });

    _seedWorkoutChatWelcome();

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

  bool get _canShowWorkoutChat =>
      _isSessionActive && !widget.workoutDay.id.startsWith('trial_');

  WorkoutExercise? _getChatContextExercise() {
    if (_chatContextExerciseId != null) {
      for (final exercise in widget.workoutDay.mainWorkout) {
        if (exercise.exercise.id == _chatContextExerciseId) {
          return exercise;
        }
      }
    }

    for (final exercise in widget.workoutDay.mainWorkout) {
      if (!_completedExercises.contains(exercise.exercise.id)) {
        return exercise;
      }
    }

    if (widget.workoutDay.mainWorkout.isNotEmpty) {
      return widget.workoutDay.mainWorkout.first;
    }

    return null;
  }

  void _seedWorkoutChatWelcome() {
    if (_hasSeededChatWelcome || widget.workoutDay.id.startsWith('trial_')) {
      return;
    }

    final focusExercise = _getChatContextExercise();
    final focusName = focusExercise?.exercise.name;

    _chatMessages.clear();
    _chatMessages.add(
      WorkoutChatMessage.assistant(
        content: focusName != null
            ? 'GIGI Chat (AI) è attiva! Partiamo da $focusName: sono qui per assisterti in tempo reale durante tutto l\'allenamento.'
            : 'GIGI Chat (AI) è attiva! Sono qui per assisterti in tempo reale durante tutto l\'allenamento.',
        exerciseId: focusExercise?.exercise.id,
      ),
    );
    _hasSeededChatWelcome = true;
  }

  Future<void> _openWorkoutChat() async {
    if (!_canShowWorkoutChat) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenIntro = prefs.getBool('has_seen_gigi_chat_intro_v2') ?? false;

    _seedWorkoutChatWelcome();
    setState(() {
      _chatIntroOnly = !hasSeenIntro;
      _isChatOpen = true;
    });
    _scrollChatToBottom();
  }

  void _closeWorkoutChat() {
    setState(() {
      _isChatOpen = false;
    });
  }

  Future<void> _startFullWorkoutChat() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_gigi_chat_intro_v2', true);

    setState(() {
      _chatIntroOnly = false;
    });
    _scrollChatToBottom();
  }

  Future<void> _sendWorkoutChatMessage({
    String? prompt,
    String? exerciseId,
  }) async {
    final rawMessage = (prompt ?? _chatController.text).trim();
    if (rawMessage.isEmpty || _isChatLoading || !_canShowWorkoutChat) return;

    final provider = Provider.of<WorkoutLogProvider>(context, listen: false);
    WorkoutExercise? activeExercise;
    if (exerciseId != null) {
      for (final exercise in widget.workoutDay.mainWorkout) {
        if (exercise.exercise.id == exerciseId) {
          activeExercise = exercise;
          break;
        }
      }
    } else {
      activeExercise = _getChatContextExercise();
    }

    setState(() {
      _chatError = null;
      _chatContextExerciseId = activeExercise?.exercise.id ?? exerciseId;
      _chatMessages.add(
        WorkoutChatMessage.user(
          content: rawMessage,
          exerciseId: _chatContextExerciseId,
        ),
      );
      _isChatLoading = true;
    });

    _chatController.clear();
    _scrollChatToBottom();

    try {
      final reply = await _workoutChatService.sendMessage(
        message: rawMessage,
        workoutDayId: widget.workoutDay.id,
        workoutLogId: provider.currentWorkoutLog?.id,
        exerciseId: _chatContextExerciseId,
        elapsedSeconds: _elapsedTime.inSeconds,
        completedExerciseIds: _completedExercises.toList(),
        restTimerActive: _isRestTimerOverlayVisible,
      );

      if (!mounted) return;

      setState(() {
        _chatMessages.add(
          WorkoutChatMessage.assistant(
            content: reply.message,
            exerciseId: reply.exerciseId ?? _chatContextExerciseId,
            suggestions: reply.suggestions,
          ),
        );
        _isChatLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _chatError = e.toString().replaceFirst('Exception: ', '');
        _isChatLoading = false;
      });
    }

    _scrollChatToBottom();
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScrollController.hasClients) return;
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
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
      FocusManager.instance.primaryFocus?.unfocus();
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

  void _initializeUniqueIdMap() {
    _exerciseByUniqueId.clear();

    // Main
    for (int i = 0; i < widget.workoutDay.mainWorkout.length; i++) {
      final e = widget.workoutDay.mainWorkout[i];
      final id = e.id ?? "main_${e.exercise.id}_$i";
      _exerciseByUniqueId[id] = e;
    }

    // Warmup
    final warmup = widget.workoutDay.warmupCardio;
    for (int i = 0; i < warmup.length; i++) {
      final e = warmup[i];
      final id = e.id ?? "warmup_${e.exercise.id}_$i";
      _exerciseByUniqueId[id] = e;
    }

    // Mobility
    final mobility = widget.workoutDay.preWorkoutMobility;
    for (int i = 0; i < mobility.length; i++) {
      final e = mobility[i];
      final id = e.id ?? "mobility_${e.exercise.id}_$i";
      _exerciseByUniqueId[id] = e;
    }

    // Post
    final post = widget.workoutDay.postWorkoutExercises;
    for (int i = 0; i < post.length; i++) {
      final e = post[i];
      final id = e.id ?? "post_${e.exercise.id}_$i";
      _exerciseByUniqueId[id] = e;
    }
  }

  WorkoutExercise? _getExerciseById(String id) {
    return _exerciseByUniqueId[id];
  }

  /// Find the next exercise after the given exerciseId
  WorkoutExercise? _getNextExercise(String currentExerciseId) {
    final mainWorkout = widget.workoutDay.mainWorkout;
    for (int i = 0; i < mainWorkout.length; i++) {
      final id = mainWorkout[i].id ?? "main_${mainWorkout[i].exercise.id}_$i";
      if (id == currentExerciseId) {
        // If there's a next exercise that's not completed, return it
        for (int j = i + 1; j < mainWorkout.length; j++) {
          final nextId = mainWorkout[j].exercise.id;
          if (!_completedExercises.contains(nextId)) {
            return mainWorkout[j];
          }
        }
        return null;
      }
    }
    return null;
  }

  /// Skip the rest timer — closes the overlay and notifies the child widget
  void _skipRestTimerOverlay() {
    context.read<RestTimerService>().skip();
    setState(() {
      _isRestTimerOverlayVisible = false;
      _restingExerciseId = null;
      _restingSetNumber = 0;
      _restTimerSeconds = 0;
      _restTimerTotal = 0;
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
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
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
                      ...widget.workoutDay.mainWorkout.asMap().entries.map((
                        entry,
                      ) {
                        return _buildExerciseCard(
                          entry.value,
                          entry.key,
                          'main',
                        );
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

            // ── GIGI PREPARATION OVERLAY (shown during audio generation) ──
            if (_voiceController.preparationCards != null &&
                _voiceController.preparationCards!.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).padding.bottom + 180,
                child: GigiPreparationOverlay(
                  cards: _voiceController.preparationCards!,
                  isAudioReady: _voiceController.isAudioReady,
                  onClose: () {
                    // X button = stop everything
                    _voiceController.stopGuidedExecution();
                  },
                  onSkip: () {
                    // Salta = dismiss cards, audio continues generating
                    _voiceController.skipPreparationCards();
                  },
                  onAllCardsShown: () {
                    // All cards finished their 3s cycle
                    _voiceController.notifyAllCardsShown();
                  },
                ),
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
                                Flexible(
                                  child: Container(
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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

            if (_canShowWorkoutChat)
              Positioned(
                right: 20,
                bottom:
                    MediaQuery.of(context).padding.bottom +
                    (_isSessionActive ? 210 : 88),
                child: _isChatOpen
                    ? SizedBox(
                        width: MediaQuery.of(context).size.width - 40,
                        child: Material(
                          color: Colors.transparent,
                          child: _buildWorkoutChatPanel(),
                        ),
                      )
                    : _buildWorkoutChatFab(),
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
          exerciseId:
              nextExercise.id ??
              "main_${nextExercise.exercise.id}_${widget.workoutDay.mainWorkout.indexOf(nextExercise)}",
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
    final isWeightInput = label == 'KG';

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
              keyboardType: isWeightInput
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.number,
              inputFormatters: [
                isWeightInput
                    ? FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*([,.]\d*)?$'),
                      )
                    : FilteringTextInputFormatter.digitsOnly,
              ],
              textInputAction: TextInputAction.done,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
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
                Flexible(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildSetDetailOverlayCard(
                            title: 'ULTIMO SET',
                            exerciseId: _restingExerciseId!,
                            setNumber: _restingSetNumber,
                            isNext: false,
                          ),
                          const SizedBox(height: 12),
                          _buildNextSetOverlayCard(),
                        ],
                      ),
                    ),
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
          ...warmupCardio.asMap().entries.map(
            (entry) => _buildExerciseCard(entry.value, entry.key, 'warmup'),
          ),
          // Inline Mobility Exercises
          ...preWorkoutMobility.asMap().entries.map(
            (entry) => _buildExerciseCard(entry.value, entry.key, 'mobility'),
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
          ...postWorkoutExercises.asMap().entries.map(
            (entry) => _buildExerciseCard(entry.value, entry.key, 'post'),
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
    // ── #1 PREMIUM CHECK ──────────────────────────────────────────────────────
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      final tier = SubscriptionTierConfig.fromTier(user.subscriptionTier);
      if (!tier.quotas.voiceCoachingEnabled) {
        _showGigiPaywall();
        return;
      }
    }

    // If already playing, stop
    if (_voiceController.isGuidedExecutionPlaying) {
      _voiceController.stopGuidedExecution();
      HapticService.lightTap();
      return;
    }

    // Haptic feedback on tap — instant confirmation
    HapticFeedback.mediumImpact();

    // Start guided execution (tries API first, then local fallback)
    await _voiceController.speakGuidedExecution(
      exerciseName: exercise.exercise.name,
      exerciseId: exercise.exercise.id,
      muscleGroups: exercise.exercise.muscleGroups,
      voiceCoachingService: _voiceCoachingService,
    );

    // ── #3 MOUNTED CHECK ─────────────────────────────────────────────────────
    if (!mounted) return;
  }

  /// Show paywall dialog for premium Gigi feature
  void _showGigiPaywall() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CleanTheme.steelDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.record_voice_over_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Esegui con GiGi',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: CleanTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'La guida vocale passo-passo è disponibile con il piano Pro o Elite. Passa ora e allena ogni esercizio con un coach AI!',
          style: GoogleFonts.inter(
            color: CleanTheme.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Non ora',
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CleanTheme.steelDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Scopri Pro',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutChatPanel() {
    final contextExercise = _getChatContextExercise();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CleanTheme.borderPrimary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CleanTheme.steelDark,
                  border: Border.all(
                    color: CleanTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GIGI Chat (AI)',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contextExercise != null
                          ? contextExercise.exercise.name
                          : 'Coach contestuale della sessione attiva',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: CleanTheme.accentGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: CleanTheme.accentGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isChatLoading ? 'Sta scrivendo...' : 'Live',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CleanTheme.accentGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: _closeWorkoutChat,
                icon: const Icon(
                  Icons.close_rounded,
                  color: CleanTheme.textSecondary,
                ),
              ),
            ],
          ),
          if (_chatIntroOnly) ...[
            const SizedBox(height: 12),
            _buildWorkoutChatIntro(),
          ],
          if (!_chatIntroOnly) ...[
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 260),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CleanTheme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: CleanTheme.borderPrimary),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      controller: _chatScrollController,
                      itemCount:
                          _chatMessages.length + (_isChatLoading ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (_isChatLoading && index == _chatMessages.length) {
                          return _buildChatBubble(
                            message: WorkoutChatMessage(
                              id: 'loading',
                              role: 'assistant',
                              content: 'Sto analizzando il tuo workout...',
                              createdAt: DateTime.fromMillisecondsSinceEpoch(0),
                            ),
                            isLoading: true,
                          );
                        }

                        return _buildChatBubble(message: _chatMessages[index]);
                      },
                    ),
                  ),
                  if (_chatError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: CleanTheme.accentRed.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: CleanTheme.accentRed,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _chatError!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: CleanTheme.accentRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed:
                                _chatMessages.isNotEmpty &&
                                    _chatMessages.last.role == 'user'
                                ? () => _sendWorkoutChatMessage(
                                    prompt: _chatMessages.last.content,
                                    exerciseId: _chatMessages.last.exerciseId,
                                  )
                                : null,
                            child: const Text('Riprova'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: CleanTheme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: CleanTheme.borderPrimary),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendWorkoutChatMessage(),
                      decoration: InputDecoration(
                        hintText: 'Chiedi un consiglio a GIGI',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: CleanTheme.textSecondary,
                        ),
                        border: InputBorder.none,
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isChatLoading
                        ? null
                        : () => _sendWorkoutChatMessage(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isChatLoading
                            ? CleanTheme.chromeGray
                            : CleanTheme.steelDark,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkoutChatIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: CleanTheme.steelDark,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Come sfruttare al meglio GIGI Chat',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CleanTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Il tuo personal trainer AI è sempre in ascolto!',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.5,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sfrutta questa chat durante l\'allenamento per avere supporto in tempo reale e massimizzare i tuoi risultati su ogni singolo set.',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: CleanTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '💪 Esempi: chiedimi consigli sulla tecnica corretta, tempistiche di recupero, che carico scegliere, o se hai bisogno al volo di un esercizio alternativo.',
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.45,
              color: CleanTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startFullWorkoutChat,
              icon: const Icon(Icons.smart_toy_rounded, size: 18),
              label: Text(
                'Apri chat',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: CleanTheme.steelDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutChatFab() {
    return GestureDetector(
      onTap: _openWorkoutChat,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF2C2C2E), Color(0xFF111111)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.smart_toy_rounded,
          color: Color(0xFFFFD700),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildChatBubble({
    required WorkoutChatMessage message,
    bool isLoading = false,
  }) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isUser ? CleanTheme.steelDark : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isUser ? CleanTheme.steelDark : CleanTheme.borderPrimary,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUser ? 'Tu' : 'GIGI',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isUser
                      ? Colors.white.withValues(alpha: 0.75)
                      : CleanTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message.content,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.45,
                  color: isUser ? Colors.white : CleanTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!isUser && message.suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...message.suggestions.map(
                  (suggestion) => Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              height: 1.4,
                              color: CleanTheme.textPrimary.withValues(
                                alpha: 0.9,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (isLoading) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(
                  minHeight: 3,
                  color: CleanTheme.primaryColor,
                  backgroundColor: CleanTheme.borderPrimary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
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

  Widget _buildExerciseCard(
    WorkoutExercise exercise,
    int orderIndex, [
    String prefix = 'main',
  ]) {
    final uniqueId =
        exercise.id ?? "${prefix}_${exercise.exercise.id}_$orderIndex";
    // Staggered entry animation index
    final animationIndex = widget.workoutDay.mainWorkout.indexOf(exercise);

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
                          uniqueId,
                          () => GlobalKey<SetLoggingWidgetState>(),
                        ),
                        exercise: exercise,
                        restTimerId: uniqueId,
                        workoutDayId: widget.workoutDay.id,
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
                                uniqueId,
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
                      child: ListenableBuilder(
                        listenable: _voiceController,
                        builder: (context, _) {
                          final isPlaying =
                              _voiceController.isGuidedExecutionPlaying;
                          final status = _voiceController.loadingStatus;
                          final baseLabel = isMobilityType
                              ? 'Guida al Movimento'
                              : AppLocalizations.of(context)!.executeWithGigi;
                          return _GigiExecuteButton(
                            onTap: () => _startGuidedExecution(exercise),
                            onPause: () => _voiceController.pauseAudio(),
                            onResume: () => _voiceController.resumeAudio(),
                            label: isPlaying
                                ? (status ?? 'Ascolta...')
                                : baseLabel,
                            isPlaying: isPlaying,
                            isOutlined: isMobilityType,
                            showShimmer: isNext && !isPlaying,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        )
        .animate(delay: (animationIndex * 80).ms)
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
            onPressed: () {
              _gigiTTS.stop();
              _voiceController.deactivate();
              Navigator.pop(context); // close dialog
              setState(() => _allowPop = true);
              Navigator.pop(context); // close screen
            },
            child: Text(
              'Elimina sessione',
              style: GoogleFonts.inter(
                color: CleanTheme.accentRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _finishWorkout(skipConfirmation: true);
            },
            child: Text(
              'Salva sessione',
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

  Future<void> _finishWorkout({bool skipConfirmation = false}) async {
    // [NEW] Trial Workout Handling
    if (widget.workoutDay.id.startsWith('trial_')) {
      _finishTrialWorkout();
      return;
    }

    final provider = Provider.of<WorkoutLogProvider>(context, listen: false);

    if (skipConfirmation) {
      await _completeWorkout(provider);
      return;
    }

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
              await _completeWorkout(provider);
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

  Future<void> _completeWorkout(WorkoutLogProvider provider) async {
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

    final saveErrorMessage = AppLocalizations.of(
      context,
    )!.saveErrorGeneric;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

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
      final completedWorkoutLog = await provider.completeWorkout();
      if (completedWorkoutLog == null) {
        final message = provider.error ?? 'Nessun workout registrato.';
        throw Exception(message);
      }

      try {
        await gamificationProvider.refresh();
      } catch (e, st) {
        debugPrint('WARNING: Failed to refresh gamification stats: $e\n$st');
      }

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

      final workoutLog = completedWorkoutLog;
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

      final avgRpe = rpeCount > 0 ? rpeSum / rpeCount : null;

      // Create summary data
      final summaryData = WorkoutSummaryData(
        workoutName: widget.workoutDay.name,
        duration: _elapsedTime,
        completedExercises: _completedExercises.length.clamp(
          0,
          widget.workoutDay.mainExerciseCount,
        ),
        totalExercises: widget.workoutDay.mainExerciseCount,
        estimatedCalories: (_elapsedTime.inMinutes * 8).clamp(
          0,
          9999,
        ),
        completedSets: realCompletedSets > 0
            ? realCompletedSets
            : _completedExercises.length,
        muscleGroupsWorked: muscleGroups.toList(),
        totalKgLifted: totalKgLifted,
        totalReps: totalReps,
        avgRpe: avgRpe,
      );

      // ignore: use_build_context_synchronously
      await Navigator.of(navigator.context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WorkoutSummaryScreen(summaryData: summaryData),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(saveErrorMessage),
          backgroundColor: CleanTheme.accentRed,
        ),
      );
    }
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
          content: const Text(
            "Si è verificato un errore durante il salvataggio della valutazione.",
          ),
          backgroundColor: CleanTheme.accentRed,
        ),
      );
    }
  }
}

/// Premium "Esegui con Gigi" button – full-width, black, animated shimmer.
/// Shows play state with stop/pause controls when [isPlaying] is true.
class _GigiExecuteButton extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final String label;
  final bool isOutlined;
  final bool isPlaying;
  final bool showShimmer;

  const _GigiExecuteButton({
    required this.onTap,
    required this.label,
    this.onPause,
    this.onResume,
    this.isOutlined = false,
    this.isPlaying = false,
    this.showShimmer = true,
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
    );
    _updateShimmer();
  }

  @override
  void didUpdateWidget(_GigiExecuteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showShimmer != widget.showShimmer ||
        oldWidget.isPlaying != widget.isPlaying) {
      _updateShimmer();
    }
  }

  void _updateShimmer() {
    if (widget.showShimmer && !widget.isPlaying) {
      if (!_shimmerController.isAnimating) _shimmerController.repeat();
    } else {
      _shimmerController.stop();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.isPlaying;
    final contentColor = widget.isOutlined ? Colors.black : Colors.white;

    // Border color shifts to red when playing
    final borderColor = isPlaying
        ? CleanTheme.accentRed.withValues(alpha: 0.8)
        : widget.isOutlined
        ? Colors.black.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.15);

    // Background shifts to deep red tint when playing
    final bgColor = isPlaying
        ? const Color(0xFF1A0000)
        : widget.isOutlined
        ? Colors.transparent
        : Colors.black;

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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 52,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: widget.isOutlined ? 1.5 : 1,
            ),
            boxShadow: isPlaying
                ? [
                    BoxShadow(
                      color: CleanTheme.accentRed.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : widget.isOutlined
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
              // Shimmer sweep (only when enabled and not playing)
              if (widget.showShimmer && !isPlaying)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, _) =>
                          _ShimmerSweep(controller: _shimmerController),
                    ),
                  ),
                ),

              // Content
              Center(
                child: isPlaying
                    // ── PLAYING STATE: label + pause + stop ──
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Spinning loader
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: CleanTheme.accentRed,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              widget.label,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Pause button
                          GestureDetector(
                            onTap: widget.onPause,
                            child: Icon(
                              Icons.pause_rounded,
                              color: Colors.white.withValues(alpha: 0.8),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Stop button
                          GestureDetector(
                            onTap: widget.onTap,
                            child: Icon(
                              Icons.stop_rounded,
                              color: CleanTheme.accentRed,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      )
                    // ── IDLE STATE: mic icon + label ──
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PulsingMicIcon(
                            controller: _shimmerController,
                            color: contentColor,
                            animate: widget.showShimmer,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.label,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: contentColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
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
  final bool animate;

  const _PulsingMicIcon({
    required this.controller,
    this.color,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.white;
    if (!animate) {
      return Container(
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
      );
    }
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
