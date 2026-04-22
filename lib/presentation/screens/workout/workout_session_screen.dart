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
import '../../../core/services/sound_service.dart';
import '../../../core/services/rest_timer_service.dart';
import '../../../core/services/workout_refresh_notifier.dart';
import '../../../core/services/workout_lock_screen_service.dart';
import '../../../core/utils/anatomical_muscle_svg.dart';
import '../../../data/services/quota_service.dart';
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
  bool _restTimerCompleted = false;
  int _restTimerSeconds = 0;
  int _restTimerTotal = 0;
  String? _restingExerciseId;
  int _restingSetNumber = 0;
  RestTimerService? _restTimerService;
  final WorkoutLockScreenService _lockScreenService =
      WorkoutLockScreenService();
  String? _lockScreenBodyImageKey;
  String? _lockScreenBodyImageBase64;
  final Map<String, TextEditingController> _overlayWeightControllers = {};
  final Map<String, TextEditingController> _overlayRepsControllers = {};
  final Map<String, TextEditingController> _overlayDifficultyControllers = {};
  final Map<String, FocusNode> _overlayFocusNodes = {};

  // Keys to communicate with SetLoggingWidgets
  final Map<String, GlobalKey<SetLoggingWidgetState>> _setLoggingKeys = {};
  final Map<String, int> _runtimeSetCounts = {};
  final Set<String> _bulkCompletingExerciseIds = {};

  // Session registration tracking
  bool _sessionRegistered = false;
  bool _registrationInProgress = false;
  Timer? _registrationRetryTimer;
  String? _sessionRegistrationError;

  // Flag to allow pop (bypass PopScope)
  bool _allowPop = false;

  // Voice Coaching TTS
  late GigiTTSService _gigiTTS;

  // Voice Coaching 2.0 Controller
  late SynchronizedVoiceController _voiceController;
  List<String> _guidedMuscleGroups = const [];
  List<String> _guidedSecondaryMuscleGroups = const [];

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
    unawaited(_lockScreenService.initialize());
    unawaited(_lockScreenService.clear());

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
      final nextSeconds = restTimerService.remainingSeconds;
      final isOverlayOpening = !_isRestTimerOverlayVisible;
      if (isOverlayOpening) {
        FocusManager.instance.primaryFocus?.unfocus();
      }

      final requiresUpdate =
          isOverlayOpening ||
          _restingExerciseId != state.exerciseId ||
          _restingSetNumber != state.setNumber ||
          _restTimerSeconds != nextSeconds ||
          _restTimerTotal != state.totalSeconds;

      if (requiresUpdate) {
        setState(() {
          _isRestTimerOverlayVisible = true;
          _restTimerCompleted = false;
          _restingExerciseId = state.exerciseId;
          _restingSetNumber = state.setNumber;
          _restTimerSeconds = nextSeconds;
          _restTimerTotal = state.totalSeconds;
        });
      }
      unawaited(_updateLockScreenWidget(isTick: true));
      return;
    }

    if (state.completed && isCurrentWorkout) {
      final requiresUpdate =
          !_isRestTimerOverlayVisible ||
          !_restTimerCompleted ||
          _restTimerSeconds != 0 ||
          _restingExerciseId != state.exerciseId ||
          _restingSetNumber != state.setNumber ||
          _restTimerTotal != state.totalSeconds;
      if (requiresUpdate) {
        setState(() {
          _isRestTimerOverlayVisible = true;
          _restTimerCompleted = true;
          _restingExerciseId = state.exerciseId;
          _restingSetNumber = state.setNumber;
          _restTimerSeconds = 0;
          _restTimerTotal = state.totalSeconds;
        });
      }
      unawaited(_updateLockScreenWidget());
      return;
    }

    if (_isRestTimerOverlayVisible) {
      _disposeOverlayInputControllers();
      setState(() {
        _isRestTimerOverlayVisible = false;
        _restTimerCompleted = false;
        _restingExerciseId = null;
        _restingSetNumber = 0;
        _restTimerSeconds = 0;
        _restTimerTotal = 0;
      });
      unawaited(_updateLockScreenWidget());
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
    unawaited(_lockScreenService.clear());
    _disposeOverlayInputControllers();
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
    unawaited(_updateLockScreenWidget());

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

    for (final pointer in _getOrderedExercisePointers()) {
      if (!_completedExercises.contains(pointer.exerciseId)) {
        return pointer.exercise;
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
        completedExerciseIds: _getCompletedBaseExerciseIds().toList(),
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

  _LockSetPointer? _resolveCurrentSetPointer() {
    final isResting =
        _isRestTimerOverlayVisible &&
        _restingExerciseId != null &&
        _restingSetNumber > 0;
    if (isResting) {
      final exercise = _getExerciseById(_restingExerciseId!);
      if (exercise != null) {
        return _LockSetPointer(
          exerciseId: _restingExerciseId!,
          setNumber: _restingSetNumber.clamp(1, exercise.sets),
        );
      }
    }

    for (final pointer in _getOrderedExercisePointers()) {
      final exercise = _getExerciseById(pointer.exerciseId) ?? pointer.exercise;
      if (_completedExercises.contains(pointer.exerciseId)) {
        continue;
      }
      final nextPendingSet = _resolveNextPendingSetNumber(
        pointer.exerciseId,
        exercise,
      );
      return _LockSetPointer(
        exerciseId: pointer.exerciseId,
        setNumber: nextPendingSet,
      );
    }

    return null;
  }

  _LockSetPointer? _resolveNextSetPointer(_LockSetPointer current) {
    final currentExercise = _getExerciseById(current.exerciseId);
    if (currentExercise == null) return null;

    if (current.setNumber < currentExercise.sets) {
      return _LockSetPointer(
        exerciseId: current.exerciseId,
        setNumber: current.setNumber + 1,
      );
    }

    final nextExercise = _getNextExercisePointer(current.exerciseId);
    if (nextExercise == null) return null;
    return _LockSetPointer(exerciseId: nextExercise.exerciseId, setNumber: 1);
  }

  int _resolveNextPendingSetNumber(String uniqueId, WorkoutExercise exercise) {
    final state = _setLoggingKeys[uniqueId]?.currentState;
    if (state == null) return 1;

    final completedSetNumbers = state
        .getCompletedSetEntries()
        .map((entry) => entry.setNumber)
        .toSet();
    for (int setNumber = 1; setNumber <= exercise.sets; setNumber++) {
      if (!completedSetNumbers.contains(setNumber)) {
        return setNumber;
      }
    }
    return exercise.sets;
  }

  Future<void> _updateLockScreenWidget({bool isTick = false}) async {
    if (!_isSessionActive) {
      await _lockScreenService.clear();
      return;
    }

    final currentPointer = _resolveCurrentSetPointer();
    final nextPointer = currentPointer == null
        ? null
        : _resolveNextSetPointer(currentPointer);

    final currentExercise = currentPointer == null
        ? null
        : _getExerciseById(currentPointer.exerciseId);
    final nextExercise = nextPointer == null
        ? null
        : _getExerciseById(nextPointer.exerciseId);

    final restTimerState = _restTimerService?.state;
    final isResting =
        _isRestTimerOverlayVisible &&
        !_restTimerCompleted &&
        _restingExerciseId != null &&
        _restTimerSeconds > 0;
    final restCompleted =
        _isRestTimerOverlayVisible &&
        _restTimerCompleted &&
        restTimerState?.workoutDayId == widget.workoutDay.id;
    final bodyImageBase64 = await _resolveLockScreenBodyImageBase64(
      currentExercise,
    );

    final snapshot = WorkoutLockScreenSnapshot(
      sessionActive: true,
      workoutName: widget.workoutDay.name,
      currentExerciseName:
          currentExercise?.exercise.name ?? 'Allenamento completato',
      currentSetNumber: currentPointer?.setNumber ?? 1,
      currentSetTotal: currentExercise?.sets ?? 1,
      currentTargetReps: currentExercise != null && currentPointer != null
          ? _getTargetReps(currentExercise, currentPointer.setNumber)
          : null,
      currentMuscleGroups: currentExercise?.exercise.muscleGroups ?? const [],
      currentSecondaryMuscleGroups:
          currentExercise?.exercise.secondaryMuscleGroups ?? const [],
      nextExerciseName: nextExercise?.exercise.name,
      nextSetNumber: nextPointer?.setNumber,
      nextSetTotal: nextExercise?.sets,
      nextTargetReps: nextExercise != null && nextPointer != null
          ? _getTargetReps(nextExercise, nextPointer.setNumber)
          : null,
      isResting: isResting,
      restRemainingSeconds: isResting ? _restTimerSeconds : null,
      restTotalSeconds: isResting ? _restTimerTotal : null,
      restEndsAt: isResting || restCompleted ? restTimerState?.endsAt : null,
      restCompleted: restCompleted,
      bodyImageBase64: bodyImageBase64,
    );

    await _lockScreenService.updateSession(snapshot, isTick: isTick);
  }

  Future<String?> _resolveLockScreenBodyImageBase64(
    WorkoutExercise? currentExercise,
  ) async {
    final primary = currentExercise?.exercise.muscleGroups ?? const <String>[];
    final secondary =
        currentExercise?.exercise.secondaryMuscleGroups ?? const <String>[];
    final key = '${primary.join('|')}::${secondary.join('|')}';
    if (_lockScreenBodyImageKey == key) return _lockScreenBodyImageBase64;

    _lockScreenBodyImageKey = key;
    _lockScreenBodyImageBase64 =
        await AnatomicalMuscleSvg.buildHighlightedPngBase64(
          primaryMuscleGroups: primary,
          secondaryMuscleGroups: secondary,
        );
    return _lockScreenBodyImageBase64;
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
      final isOverlayOpening = !_isRestTimerOverlayVisible;
      if (isOverlayOpening) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
      final uniqueKey = exerciseId;
      setState(() {
        _isRestTimerOverlayVisible = true;
        _restTimerCompleted = false;
        _restingExerciseId = uniqueKey;
        _restingSetNumber = setNumber;
        _restTimerSeconds = secondsRemaining;
        _restTimerTotal = totalSeconds;
      });
      unawaited(_updateLockScreenWidget(isTick: true));
    } else {
      _disposeOverlayInputControllers();
      setState(() {
        _isRestTimerOverlayVisible = false;
        _restTimerCompleted = false;
      });
      unawaited(_updateLockScreenWidget());
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
    final exercise = _exerciseByUniqueId[id];
    if (exercise == null) return null;

    final runtimeSets = _runtimeSetCounts[id];
    if (runtimeSets == null || runtimeSets == exercise.sets) {
      return exercise;
    }

    return WorkoutExercise(
      id: exercise.id,
      exercise: exercise.exercise,
      sets: runtimeSets,
      reps: exercise.reps,
      restSeconds: exercise.restSeconds,
      restSecondsPerSet: exercise.restSecondsPerSet,
      notes: exercise.notes,
      exerciseType: exercise.exerciseType,
      position: exercise.position,
    );
  }

  String _normalizeExerciseType(String exerciseType) {
    switch (exerciseType.trim().toLowerCase()) {
      case 'strength':
        return 'main';
      case 'main':
      case 'cardio':
      case 'mobility':
      case 'warmup':
        return exerciseType.trim().toLowerCase();
      default:
        return 'main';
    }
  }

  int _getExerciseOrderIndex(String uniqueId) {
    final orderedExercises = _getOrderedExercisePointers();
    final index = orderedExercises.indexWhere(
      (entry) => entry.exerciseId == uniqueId,
    );
    return index >= 0 ? index : 0;
  }

  ExerciseLogModel? _findExerciseLogForEntry(
    WorkoutLogProvider provider,
    String uniqueId,
    WorkoutExercise exercise,
  ) {
    final logs = provider.currentWorkoutLog?.exerciseLogs;
    if (logs == null) return null;

    final orderIndex = _getExerciseOrderIndex(uniqueId);
    for (final log in logs) {
      if (log.exerciseId == exercise.exercise.id &&
          log.orderIndex == orderIndex &&
          _normalizeExerciseType(log.exerciseType) ==
              _normalizeExerciseType(exercise.exerciseType)) {
        return log;
      }
    }

    return null;
  }

  List<_OrderedExercisePointer> _getOrderedExercisePointers() {
    final pointers = <_OrderedExercisePointer>[];

    for (int i = 0; i < widget.workoutDay.warmupCardio.length; i++) {
      final exercise = widget.workoutDay.warmupCardio[i];
      pointers.add(
        _OrderedExercisePointer(
          exerciseId: exercise.id ?? "warmup_${exercise.exercise.id}_$i",
          exercise: exercise,
        ),
      );
    }

    for (int i = 0; i < widget.workoutDay.preWorkoutMobility.length; i++) {
      final exercise = widget.workoutDay.preWorkoutMobility[i];
      pointers.add(
        _OrderedExercisePointer(
          exerciseId: exercise.id ?? "mobility_${exercise.exercise.id}_$i",
          exercise: exercise,
        ),
      );
    }

    for (int i = 0; i < widget.workoutDay.mainWorkout.length; i++) {
      final exercise = widget.workoutDay.mainWorkout[i];
      pointers.add(
        _OrderedExercisePointer(
          exerciseId: exercise.id ?? "main_${exercise.exercise.id}_$i",
          exercise: exercise,
        ),
      );
    }

    for (int i = 0; i < widget.workoutDay.postWorkoutExercises.length; i++) {
      final exercise = widget.workoutDay.postWorkoutExercises[i];
      pointers.add(
        _OrderedExercisePointer(
          exerciseId: exercise.id ?? "post_${exercise.exercise.id}_$i",
          exercise: exercise,
        ),
      );
    }

    return pointers;
  }

  Future<void> _changeExerciseSets(String uniqueId, int delta) async {
    final exercise = _getExerciseById(uniqueId);
    final baseExercise = _exerciseByUniqueId[uniqueId];
    final setLoggingState = _setLoggingKeys[uniqueId]?.currentState;
    if (exercise == null || baseExercise == null || setLoggingState == null) {
      return;
    }

    final currentSets = exercise.sets;
    final nextSets = (currentSets + delta).clamp(1, 20);
    if (nextSets == currentSets) return;

    if (nextSets < currentSets) {
      final removed = await setLoggingState.removeLastSet();
      if (!removed || !mounted) return;
    }

    setState(() {
      if (nextSets == baseExercise.sets) {
        _runtimeSetCounts.remove(uniqueId);
      } else {
        _runtimeSetCounts[uniqueId] = nextSets;
      }
    });

    HapticService.selectionClick();
    unawaited(_updateLockScreenWidget());
  }

  void _handleExerciseCompletionChanged(
    String exerciseId,
    bool allSetsCompleted,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final isAlreadyCompleted = _completedExercises.contains(exerciseId);
      if (isAlreadyCompleted == allSetsCompleted) {
        return;
      }

      // Ensure timer/session always starts when user checks an exercise as completed,
      // even if completion did not come through onSetCompleted callback.
      if (allSetsCompleted) {
        _autoStartSessionIfNeeded();
      }

      setState(() {
        if (allSetsCompleted) {
          _completedExercises.add(exerciseId);
        } else {
          _completedExercises.remove(exerciseId);
        }
      });
      unawaited(_updateLockScreenWidget());
    });
  }

  Set<String> _getCompletedBaseExerciseIds() {
    return _getOrderedExercisePointers()
        .where((entry) => _completedExercises.contains(entry.exerciseId))
        .map((entry) => entry.exercise.exercise.id)
        .toSet();
  }

  /// Find the next uncompleted exercise after the given exerciseId
  _OrderedExercisePointer? _getNextExercisePointer(String currentExerciseId) {
    final orderedExercises = _getOrderedExercisePointers();
    for (int i = 0; i < orderedExercises.length; i++) {
      if (orderedExercises[i].exerciseId != currentExerciseId) {
        continue;
      }

      for (int j = i + 1; j < orderedExercises.length; j++) {
        final nextExercise = orderedExercises[j];
        if (!_completedExercises.contains(nextExercise.exerciseId)) {
          return nextExercise;
        }
      }

      return null;
    }

    return null;
  }

  /// Skip the rest timer — closes the overlay and notifies the child widget
  void _skipRestTimerOverlay() {
    context.read<RestTimerService>().skip();
    _disposeOverlayInputControllers();
    setState(() {
      _isRestTimerOverlayVisible = false;
      _restTimerCompleted = false;
      _restingExerciseId = null;
      _restingSetNumber = 0;
      _restTimerSeconds = 0;
      _restTimerTotal = 0;
    });
    unawaited(_updateLockScreenWidget());
  }

  void _acknowledgeRestCompletionOverlay() {
    context.read<RestTimerService>().acknowledgeCompletion();
    _disposeOverlayInputControllers();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isRestTimerOverlayVisible = false;
      _restTimerCompleted = false;
      _restingExerciseId = null;
      _restingSetNumber = 0;
      _restTimerSeconds = 0;
      _restTimerTotal = 0;
    });
    unawaited(_updateLockScreenWidget());
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
      _sessionRegistrationError = null;
    });

    final provider = Provider.of<WorkoutLogProvider>(context, listen: false);
    provider.clearError();
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
              _sessionRegistrationError = null;
            });
          }
          return; // Success
        }
      } catch (e) {
        debugPrint('Session registration failed (attempt $attempt): $e');
      }
      // Exponential backoff
      if (attempt < 3 && mounted) {
        await Future.delayed(Duration(seconds: 1 << (attempt - 1)));
      }
    }

    // All retries exhausted — start background retry every 10 seconds
    if (mounted) {
      final providerError = provider.error?.trim() ?? '';
      setState(() {
        _registrationInProgress = false;
        _sessionRegistrationError = providerError.isNotEmpty
            ? providerError
            : 'Impossibile registrare la sessione workout sul server.';
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
      final provider = Provider.of<WorkoutLogProvider>(context, listen: false);
      try {
        provider.clearError();
        await provider.startWorkout(workoutDayId: widget.workoutDay.id);
        if (provider.currentWorkoutLog != null) {
          if (mounted) {
            setState(() {
              _sessionRegistered = true;
              _sessionRegistrationError = null;
            });
          }
          timer.cancel();
        }
      } catch (e) {
        if (mounted) {
          final providerError = provider.error?.trim() ?? '';
          setState(() {
            _sessionRegistrationError = providerError.isNotEmpty
                ? providerError
                : e.toString().replaceFirst('Exception: ', '').trim();
          });
        }
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
        resizeToAvoidBottomInset: !_isRestTimerOverlayVisible,
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
            AbsorbPointer(
              absorbing: _isRestTimerOverlayVisible,
              child: Stack(
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
                                            : _sessionRegistrationError
                                                      ?.trim()
                                                      .isNotEmpty ==
                                                  true
                                            ? _sessionRegistrationError!.trim()
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
                                    if (!_registrationInProgress)
                                      TextButton(
                                        onPressed: _registerSessionWithBackend,
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              CleanTheme.accentOrange,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          minimumSize: const Size(0, 32),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Riprova',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
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
                                widget
                                    .workoutDay
                                    .preWorkoutMobility
                                    .isNotEmpty) ...[
                              _buildPreWorkoutNavigationCard(),
                              const SizedBox(height: 16),
                            ],

                            // Main Workout Section
                            _buildSectionHeader(
                              AppLocalizations.of(context)!.mainWorkoutSection,
                              '💪',
                            ),
                            ...widget.workoutDay.mainWorkout
                                .asMap()
                                .entries
                                .map((entry) {
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
                        muscleGroups: _guidedMuscleGroups,
                        secondaryMuscleGroups: _guidedSecondaryMuscleGroups,
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                            color: CleanTheme.textOnDark
                                                .withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                            color: CleanTheme.textOnDark
                                                .withValues(alpha: 0.7),
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
                                      value:
                                          widget.workoutDay.mainExerciseCount >
                                              0
                                          ? _completedExercises.length /
                                                widget
                                                    .workoutDay
                                                    .mainExerciseCount
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildSessionStat(
                                        '🔥',
                                        '${(_elapsedTime.inMinutes * 8).clamp(0, 999)}',
                                        AppLocalizations.of(
                                          context,
                                        )!.statsCalories,
                                      ),
                                      _buildSessionStat(
                                        '💪',
                                        '${_completedExercises.length * 3}',
                                        AppLocalizations.of(
                                          context,
                                        )!.statsSeries,
                                      ),
                                      _buildSessionStat(
                                        '⏱️',
                                        (_elapsedTime.inMinutes /
                                                (widget
                                                            .workoutDay
                                                            .mainExerciseCount >
                                                        0
                                                    ? widget
                                                          .workoutDay
                                                          .mainExerciseCount
                                                    : 1))
                                            .toStringAsFixed(1),
                                        AppLocalizations.of(
                                          context,
                                        )!.statsMinPerEx,
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
                                icon: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 28,
                                ),
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
                                  shadowColor: CleanTheme.accentGreen
                                      .withValues(alpha: 0.5),
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
                                  shadowColor: CleanTheme.primaryColor
                                      .withValues(alpha: 0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                                child: Text(
                                  _completedExercises.length ==
                                          widget.workoutDay.mainExerciseCount
                                      ? AppLocalizations.of(
                                          context,
                                        )!.completeWorkout
                                      : AppLocalizations.of(
                                          context,
                                        )!.finishSession,
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
                ],
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
    final sourceWeightController = setLoggingState?.getWeightController(
      setNumber,
    );
    final sourceRepsController = setLoggingState?.getRepsController(setNumber);
    final weightFocusNode = _getOverlayWeightFocusNode(
      exerciseId: exerciseId,
      setNumber: setNumber,
    );
    final repsFocusNode = _getOverlayRepsFocusNode(
      exerciseId: exerciseId,
      setNumber: setNumber,
    );
    final difficultyFocusNode = _getOverlayDifficultyFocusNode(
      exerciseId: exerciseId,
      setNumber: setNumber,
    );
    final overlayWeightController = _getOverlayWeightController(
      exerciseId: exerciseId,
      setNumber: setNumber,
      sourceController: sourceWeightController,
    );
    final overlayRepsController = _getOverlayRepsController(
      exerciseId: exerciseId,
      setNumber: setNumber,
      sourceController: sourceRepsController,
    );
    final currentRpe = setLoggingState?.getRpe(setNumber) ?? 7;
    final difficultyController = _getOverlayDifficultyController(
      exerciseId: exerciseId,
      setNumber: setNumber,
      currentRpe: currentRpe,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: CleanTheme.steelDark.withValues(alpha: isNext ? 0.4 : 0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: CleanTheme.textOnDark.withValues(alpha: isNext ? 0.15 : 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: isNext
                      ? CleanTheme.accentBlue
                      : CleanTheme.textOnDark.withValues(alpha: 0.4),
                ),
              ),
              const Spacer(),
              if (!isNext)
                const Icon(
                  Icons.check_circle_rounded,
                  color: CleanTheme.accentGreen,
                  size: 12,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            exercise.exercise.name,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: CleanTheme.textOnDark,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Set $setNumber di ${exercise.sets}',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: CleanTheme.textOnDark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildOverlayMetricField(
                    label: 'KG',
                    controller: overlayWeightController,
                    focusNode: weightFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*([,.]\d*)?$'),
                      ),
                    ],
                    textInputAction: TextInputAction.next,
                    readOnly: sourceWeightController == null,
                    onChanged: (value) {
                      _syncOverlayMetricValue(
                        value: value,
                        sourceController: sourceWeightController,
                      );
                    },
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: CleanTheme.textOnDark.withValues(alpha: 0.1),
                ),
                Expanded(
                  child: _buildOverlayMetricField(
                    label: 'REPS',
                    controller: overlayRepsController,
                    focusNode: repsFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.next,
                    readOnly: sourceRepsController == null,
                    onChanged: (value) {
                      _syncOverlayMetricValue(
                        value: value,
                        sourceController: sourceRepsController,
                      );
                    },
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: CleanTheme.textOnDark.withValues(alpha: 0.1),
                ),
                Expanded(
                  child: _buildOverlayDifficultyField(
                    controller: difficultyController,
                    focusNode: difficultyFocusNode,
                    setLoggingState: setLoggingState,
                    setNumber: setNumber,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.ads_click_rounded,
                size: 10,
                color: CleanTheme.textOnDark.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 4),
              Text(
                'Target: ${_getTargetReps(exercise, setNumber)} reps',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textOnDark.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
      final nextExercise = _getNextExercisePointer(_restingExerciseId!);
      if (nextExercise != null) {
        return _buildSetDetailOverlayCard(
          title: 'PROSSIMO SET',
          exerciseId: nextExercise.exerciseId,
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

  Widget _buildOverlayMetricField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required TextInputType keyboardType,
    required List<TextInputFormatter> inputFormatters,
    required TextInputAction textInputAction,
    required bool readOnly,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: CleanTheme.textOnDark.withValues(alpha: 0.4),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 34,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              textInputAction: textInputAction,
              readOnly: readOnly,
              onTap: () {
                if (!readOnly) {
                  _selectAllText(controller);
                }
              },
              onChanged: onChanged,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: CleanTheme.textOnDark,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                fillColor: Colors.transparent,
              ),
              cursorColor: CleanTheme.accentBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayDifficultyField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required SetLoggingWidgetState? setLoggingState,
    required int setNumber,
  }) {
    final rpeColor = _getOverlayRpeColor(controller.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'RPE',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: CleanTheme.textOnDark.withValues(alpha: 0.4),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => focusNode.requestFocus(),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rpeColor.withValues(alpha: 0.2),
              border: Border.all(color: rpeColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: rpeColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              onTap: () => _selectAllText(controller),
              onSubmitted: (value) {
                _syncOverlayDifficultyValue(
                  value: value,
                  controller: controller,
                  setLoggingState: setLoggingState,
                  setNumber: setNumber,
                );
                FocusManager.instance.primaryFocus?.unfocus();
              },
              onChanged: (value) {
                _syncOverlayDifficultyValue(
                  value: value,
                  controller: controller,
                  setLoggingState: setLoggingState,
                  setNumber: setNumber,
                );
              },
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: CleanTheme.textOnDark,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                fillColor: Colors.transparent,
              ),
              cursorColor: CleanTheme.accentBlue,
            ),
          ),
        ),
      ],
    );
  }

  Color _getOverlayRpeColor(String rawValue) {
    final parsed = int.tryParse(rawValue);
    if (parsed == null) return CleanTheme.textPrimary;
    if (parsed <= 4) return CleanTheme.accentGreen;
    if (parsed <= 6) return CleanTheme.accentGold;
    if (parsed <= 8) return CleanTheme.accentOrange;
    return CleanTheme.accentRed;
  }

  TextEditingController _getOverlayWeightController({
    required String exerciseId,
    required int setNumber,
    required TextEditingController? sourceController,
  }) {
    final key = '${exerciseId}_$setNumber';
    return _getOrCreateOverlayController(
      map: _overlayWeightControllers,
      key: key,
      focusNode: _getOverlayWeightFocusNode(
        exerciseId: exerciseId,
        setNumber: setNumber,
      ),
      sourceController: sourceController,
    );
  }

  TextEditingController _getOverlayRepsController({
    required String exerciseId,
    required int setNumber,
    required TextEditingController? sourceController,
  }) {
    final key = '${exerciseId}_$setNumber';
    return _getOrCreateOverlayController(
      map: _overlayRepsControllers,
      key: key,
      focusNode: _getOverlayRepsFocusNode(
        exerciseId: exerciseId,
        setNumber: setNumber,
      ),
      sourceController: sourceController,
    );
  }

  TextEditingController _getOverlayDifficultyController({
    required String exerciseId,
    required int setNumber,
    required int currentRpe,
  }) {
    final key = '${exerciseId}_$setNumber';
    final focusNode = _getOverlayDifficultyFocusNode(
      exerciseId: exerciseId,
      setNumber: setNumber,
    );
    final existingController = _overlayDifficultyControllers[key];
    if (existingController != null) {
      if (!focusNode.hasFocus) {
        final nextValue = currentRpe.toString();
        if (existingController.text != nextValue) {
          existingController.value = TextEditingValue(
            text: nextValue,
            selection: TextSelection.collapsed(offset: nextValue.length),
          );
        }
      }
      return existingController;
    }
    final controller = TextEditingController(text: currentRpe.toString());
    _overlayDifficultyControllers[key] = controller;
    return controller;
  }

  FocusNode _getOverlayWeightFocusNode({
    required String exerciseId,
    required int setNumber,
  }) {
    return _getOrCreateOverlayFocusNode('weight_${exerciseId}_$setNumber');
  }

  FocusNode _getOverlayRepsFocusNode({
    required String exerciseId,
    required int setNumber,
  }) {
    return _getOrCreateOverlayFocusNode('reps_${exerciseId}_$setNumber');
  }

  FocusNode _getOverlayDifficultyFocusNode({
    required String exerciseId,
    required int setNumber,
  }) {
    return _getOrCreateOverlayFocusNode('difficulty_${exerciseId}_$setNumber');
  }

  FocusNode _getOrCreateOverlayFocusNode(String key) {
    final existing = _overlayFocusNodes[key];
    if (existing != null) return existing;
    final node = FocusNode(debugLabel: 'rest_overlay_$key');
    node.addListener(() {
      if (!node.hasFocus) return;
      _selectAllForOverlayFocusKey(key);
    });
    _overlayFocusNodes[key] = node;
    return node;
  }

  TextEditingController _getOrCreateOverlayController({
    required Map<String, TextEditingController> map,
    required String key,
    required FocusNode focusNode,
    required TextEditingController? sourceController,
  }) {
    final existingController = map[key];
    final sourceValue = sourceController?.text ?? '';
    if (existingController != null) {
      if (sourceController != null &&
          !focusNode.hasFocus &&
          existingController.text != sourceValue) {
        existingController.value = TextEditingValue(
          text: sourceValue,
          selection: TextSelection.collapsed(offset: sourceValue.length),
        );
      }
      return existingController;
    }

    final controller = TextEditingController(text: sourceValue);
    map[key] = controller;
    return controller;
  }

  void _selectAllForOverlayFocusKey(String focusKey) {
    const weightPrefix = 'weight_';
    const repsPrefix = 'reps_';
    const difficultyPrefix = 'difficulty_';

    if (focusKey.startsWith(weightPrefix)) {
      final key = focusKey.substring(weightPrefix.length);
      final controller = _overlayWeightControllers[key];
      if (controller != null) {
        _selectAllText(controller);
      }
      return;
    }

    if (focusKey.startsWith(repsPrefix)) {
      final key = focusKey.substring(repsPrefix.length);
      final controller = _overlayRepsControllers[key];
      if (controller != null) {
        _selectAllText(controller);
      }
      return;
    }

    if (focusKey.startsWith(difficultyPrefix)) {
      final key = focusKey.substring(difficultyPrefix.length);
      final controller = _overlayDifficultyControllers[key];
      if (controller != null) {
        _selectAllText(controller);
      }
    }
  }

  void _selectAllText(TextEditingController controller) {
    final text = controller.text;
    if (text.isEmpty) return;
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: text.length,
    );
  }

  void _disposeOverlayInputControllers() {
    for (final controller in _overlayWeightControllers.values) {
      controller.dispose();
    }
    _overlayWeightControllers.clear();

    for (final controller in _overlayRepsControllers.values) {
      controller.dispose();
    }
    _overlayRepsControllers.clear();

    for (final controller in _overlayDifficultyControllers.values) {
      controller.dispose();
    }
    _overlayDifficultyControllers.clear();

    for (final focusNode in _overlayFocusNodes.values) {
      focusNode.dispose();
    }
    _overlayFocusNodes.clear();
  }

  void _syncOverlayMetricValue({
    required String value,
    required TextEditingController? sourceController,
  }) {
    if (sourceController == null || sourceController.text == value) return;
    sourceController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _syncOverlayDifficultyValue({
    required String value,
    required TextEditingController controller,
    required SetLoggingWidgetState? setLoggingState,
    required int setNumber,
  }) {
    if (value.isEmpty || setLoggingState == null) return;
    final parsed = int.tryParse(value);
    if (parsed == null) return;

    final clamped = parsed.clamp(1, 10);
    if (clamped.toString() != value) {
      final text = clamped.toString();
      controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    if (setLoggingState.getRpe(setNumber) != clamped) {
      HapticService.selectionClick();
      setLoggingState.updateRpe(setNumber, clamped);
    }
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
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardInset > 0;
    final progress = _restTimerTotal > 0
        ? _restTimerSeconds / _restTimerTotal
        : 0.0;
    final minutes = _restTimerSeconds ~/ 60;
    final seconds = _restTimerSeconds % 60;
    final isUrgent = _restTimerSeconds <= 3 && _restTimerSeconds > 0;
    final statusColor = _restTimerCompleted
        ? CleanTheme.accentGreen
        : isUrgent
        ? CleanTheme.accentRed
        : CleanTheme.accentBlue;
    final currentExercise = _restingExerciseId != null
        ? _getExerciseById(_restingExerciseId!)
        : null;
    final currentType = currentExercise?.exerciseType.toLowerCase();
    final showSetDetails = currentType != 'cardio' && currentType != 'mobility';

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
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  ),
                ),
                AnimatedPadding(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(bottom: keyboardInset),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: isKeyboardOpen ? 6 : 16),

                      // Label
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _restTimerCompleted
                                ? 'RECUPERO FINITO'
                                : 'RECUPERO',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 4,
                              color: CleanTheme.textOnDark.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isKeyboardOpen ? 8 : 20),

                      // Huge Timer
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: GoogleFonts.outfit(
                          fontSize: isKeyboardOpen ? 58 : 72,
                          fontWeight: FontWeight.w800,
                          color: _restTimerCompleted
                              ? CleanTheme.accentGreen
                              : isUrgent
                              ? CleanTheme.accentRed
                              : CleanTheme.textOnDark,
                          letterSpacing: 4,
                        ),
                        child: Text(
                          '$minutes:${seconds.toString().padLeft(2, '0')}',
                        ),
                      ),

                      SizedBox(height: isKeyboardOpen ? 8 : 16),

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
                              statusColor,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isKeyboardOpen ? 10 : 24),

                      if (showSetDetails) ...[
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: isKeyboardOpen
                                ? SingleChildScrollView(
                                    keyboardDismissBehavior:
                                        ScrollViewKeyboardDismissBehavior
                                            .onDrag,
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 150,
                                          child: _buildSetDetailOverlayCard(
                                            title: 'ULTIMO SET',
                                            exerciseId: _restingExerciseId!,
                                            setNumber: _restingSetNumber,
                                            isNext: false,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          height: 150,
                                          child: _buildNextSetOverlayCard(),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    children: [
                                      Expanded(
                                        child: _buildSetDetailOverlayCard(
                                          title: 'ULTIMO SET',
                                          exerciseId: _restingExerciseId!,
                                          setNumber: _restingSetNumber,
                                          isNext: false,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Expanded(
                                        child: _buildNextSetOverlayCard(),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        SizedBox(height: isKeyboardOpen ? 8 : 16),
                      ],

                      // Completion/skip button
                      TextButton(
                        onPressed: _restTimerCompleted
                            ? _acknowledgeRestCompletionOverlay
                            : _skipRestTimerOverlay,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                            side: BorderSide(
                              color: CleanTheme.textOnDark.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _restTimerCompleted
                                  ? 'Inizia prossimo set'
                                  : 'Salta',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: CleanTheme.textOnDark.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _restTimerCompleted
                                  ? Icons.play_arrow_rounded
                                  : Icons.skip_next_rounded,
                              size: 20,
                              color: CleanTheme.textOnDark.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isKeyboardOpen ? 6 : 16),
                    ],
                  ),
                ),
                if (isKeyboardOpen)
                  Positioned(
                    top: 10,
                    right: 15,
                    child: IconButton(
                      onPressed: () =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      icon: const Icon(
                        Icons.keyboard_hide_rounded,
                        color: CleanTheme.textOnDark,
                        size: 28,
                      ),
                    ),
                  ),
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
    // ── #1 BACKEND ELIGIBILITY CHECK ─────────────────────────────────────────
    try {
      final quotaStatus = await QuotaService().getQuotaStatus();
      if (!quotaStatus.features.voiceCoaching) {
        _showGigiPaywall();
        return;
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verifica accesso non riuscita. Controlla connessione e riprova.',
          ),
          backgroundColor: CleanTheme.accentRed,
        ),
      );
      return;
    }

    // If already playing, stop
    if (_voiceController.isGuidedExecutionPlaying) {
      _voiceController.stopGuidedExecution();
      HapticService.lightTap();
      return;
    }

    // Haptic feedback on tap — instant confirmation
    HapticFeedback.mediumImpact();
    _guidedMuscleGroups = exercise.exercise.muscleGroups;
    _guidedSecondaryMuscleGroups = exercise.exercise.secondaryMuscleGroups;

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat_bubble_rounded,
              color: Color(0xFFFFD700),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              'CHAT',
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFFFD700),
                letterSpacing: 0.6,
              ),
            ),
          ],
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

  Widget _buildCompleteExerciseButton({
    required bool isCompleted,
    required bool isCompleting,
    required VoidCallback onTap,
  }) {
    final backgroundColor = isCompleted
        ? CleanTheme.accentGreen.withValues(alpha: 0.08)
        : CleanTheme.accentGreen;
    final borderColor = isCompleted
        ? CleanTheme.accentGreen.withValues(alpha: 0.26)
        : CleanTheme.accentGreen;
    final foregroundColor = isCompleted
        ? CleanTheme.accentGreen
        : CleanTheme.textOnPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isCompleted || isCompleting ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: isCompleted
                ? null
                : [
                    BoxShadow(
                      color: CleanTheme.accentGreen.withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: isCompleting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: foregroundColor,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.done_all_rounded,
                        size: 20,
                        color: foregroundColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCompleted
                            ? 'Esercizio completato'
                            : 'Completa esercizio',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: foregroundColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _showExerciseCompletionSnackBar(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_rounded,
                color: CleanTheme.textOnPrimary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: CleanTheme.textOnPrimary,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: isError
              ? CleanTheme.accentRed
              : CleanTheme.accentGreen,
          duration: const Duration(milliseconds: 2200),
        ),
      );
  }

  Future<void> _completeExerciseQuick(
    String uniqueId,
    WorkoutExercise exercise,
  ) async {
    if (_bulkCompletingExerciseIds.contains(uniqueId)) return;

    final setLoggingState = _setLoggingKeys[uniqueId]?.currentState;
    if (setLoggingState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile completare ora. Riprova tra un attimo.'),
          backgroundColor: CleanTheme.accentOrange,
        ),
      );
      return;
    }

    final pendingSets = setLoggingState.getPendingSetsCount();
    if (pendingSets > 1) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: CleanTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Segnare tutto come eseguito?',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              color: CleanTheme.textPrimary,
            ),
          ),
          content: Text(
            'Verranno completati $pendingSets set mancanti per ${exercise.exercise.name}.',
            style: GoogleFonts.inter(color: CleanTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Annulla',
                style: GoogleFonts.inter(color: CleanTheme.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Conferma',
                style: GoogleFonts.inter(
                  color: CleanTheme.accentGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    _autoStartSessionIfNeeded();

    setState(() {
      _bulkCompletingExerciseIds.add(uniqueId);
    });

    try {
      await setLoggingState.completeAllSetsQuick();
      if (!mounted) return;
      HapticService.mediumTap();
      unawaited(_updateLockScreenWidget());
      // Success snackbar removed as per user request
    } catch (e) {
      if (!mounted) return;
      _showExerciseCompletionSnackBar(
        'Errore completamento esercizio: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _bulkCompletingExerciseIds.remove(uniqueId);
        });
      }
    }
  }

  Widget _buildExerciseCard(
    WorkoutExercise exercise,
    int orderIndex, [
    String prefix = 'main',
  ]) {
    final uniqueId =
        exercise.id ?? "${prefix}_${exercise.exercise.id}_$orderIndex";
    final animationIndex = orderIndex;

    // All exercise types now use the full card renderer
    final type = exercise.exerciseType.toLowerCase();

    final isMobilityType =
        type == 'mobility' || type == 'warmup' || type == 'cardio';

    return Consumer<WorkoutLogProvider>(
          builder: (context, provider, child) {
            final displayExercise = _getExerciseById(uniqueId) ?? exercise;
            final exerciseLog = _findExerciseLogForEntry(
              provider,
              uniqueId,
              displayExercise,
            );

            final isCompleted = _completedExercises.contains(uniqueId);

            // Determine if this is the next exercise to perform
            final orderedExercises = _getOrderedExercisePointers();
            final firstUncompleted = orderedExercises.firstWhere(
              (entry) => !_completedExercises.contains(entry.exerciseId),
              orElse: () => _OrderedExercisePointer(
                exerciseId: uniqueId,
                exercise: exercise,
              ),
            );
            final isNext =
                _isSessionActive && uniqueId == firstUncompleted.exerciseId;
            final isCompleting = _bulkCompletingExerciseIds.contains(uniqueId);

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
                                      '${orderIndex + 1}',
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
                                  displayExercise.exercise.name,
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
                                      '${displayExercise.restSeconds}s',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: CleanTheme.accentOrange,
                                      ),
                                    ),
                                    if (displayExercise
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
                                          displayExercise.exercise.muscleGroups
                                              .join(', '),
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
                                      displayExercise
                                          .exercise
                                          .muscleGroups
                                          .isNotEmpty
                                      ? displayExercise.exercise.muscleGroups
                                      : [displayExercise.exercise.name],
                                  secondaryMuscleGroups: displayExercise
                                      .exercise
                                      .secondaryMuscleGroups,
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
                        exercise: displayExercise,
                        restTimerId: uniqueId,
                        workoutDayId: widget.workoutDay.id,
                        exerciseLog: exerciseLog?.id.isNotEmpty == true
                            ? exerciseLog
                            : null,
                        isTrial: widget.workoutDay.id.startsWith('trial_'),
                        onCompletionChanged: (allSetsCompleted) {
                          _handleExerciseCompletionChanged(
                            uniqueId,
                            allSetsCompleted,
                          );
                        },
                        onSetCompleted: (setData) {
                          _autoStartSessionIfNeeded();
                          if (widget.workoutDay.id.startsWith('trial_')) {}
                          unawaited(_updateLockScreenWidget());
                        },
                        onRemoveSet: () => _changeExerciseSets(uniqueId, -1),
                        onAddSet: () => _changeExerciseSets(uniqueId, 1),
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

                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: _buildCompleteExerciseButton(
                        isCompleted: isCompleted,
                        isCompleting: isCompleting,
                        onTap: () =>
                            _completeExerciseQuick(uniqueId, displayExercise),
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
                              onTap: () =>
                                  _navigateToExerciseDetail(displayExercise),
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
                                  displayExercise.exercise.id,
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FormAnalysisScreen(
                                      exerciseName:
                                          displayExercise.exercise.name,
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
                          final state = _voiceController.guidedState;
                          final isPlaying =
                              _voiceController.isGuidedExecutionPlaying;
                          final isPaused =
                              _voiceController.isGuidedExecutionPaused;
                          final isLoading =
                              state == GuidedExecutionUiState.loading ||
                              state == GuidedExecutionUiState.ready;
                          final baseLabel = AppLocalizations.of(
                            context,
                          )!.executeWithGigi;
                          return _GigiExecuteButton(
                            onTap: () => _startGuidedExecution(displayExercise),
                            onPause: () => _voiceController.pauseAudio(),
                            onResume: () => _voiceController.resumeAudio(),
                            isLoading: isLoading,
                            isPlaying: isPlaying,
                            isPaused: isPaused,
                            label: switch (state) {
                              GuidedExecutionUiState.loading =>
                                'Preparazione audio...',
                              GuidedExecutionUiState.ready => 'Audio pronto',
                              GuidedExecutionUiState.paused => 'In pausa',
                              GuidedExecutionUiState.error =>
                                _voiceController.guidedError ?? 'Errore audio',
                              _ => (isPlaying ? 'Ascolta...' : baseLabel),
                            },
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
      unawaited(_lockScreenService.clear());
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
              unawaited(_lockScreenService.clear());
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
        child: CircularProgressIndicator(color: CleanTheme.primaryColor),
      ),
    );

    final navigator = Navigator.of(context);
    final workoutRefreshNotifier = Provider.of<WorkoutRefreshNotifier>(
      context,
      listen: false,
    );

    final saveErrorMessage = AppLocalizations.of(context)!.saveErrorGeneric;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      debugPrint(
        'DEBUG: Completing workout, currentLog exists: ${provider.currentWorkoutLog != null}',
      );

      await _ensureSessionAndSyncPendingLogs(provider);

      // ANTICIPATION: Play workout complete sound IMMEDIATELY on confirmation
      SoundService().play(SoundType.workoutComplete);

      if (provider.currentWorkoutLog != null) {
        debugPrint('DEBUG: Workout log ID: ${provider.currentWorkoutLog!.id}');
      }
      final completedWorkoutLog = await provider.completeWorkout();
      if (completedWorkoutLog == null) {
        final message = provider.error ?? 'Nessun workout registrato.';
        throw Exception(message);
      }

      debugPrint('WorkoutSessionScreen: emitting workout refresh event');
      workoutRefreshNotifier.notifyWorkoutCompleted();

      if (!mounted) return;
      navigator.pop(); // Close loading dialog

      // Collect muscle groups from completed exercises
      final muscleGroups = <String>{};
      for (final pointer in _getOrderedExercisePointers()) {
        if (_completedExercises.contains(pointer.exerciseId)) {
          muscleGroups.addAll(pointer.exercise.exercise.muscleGroups);
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
        estimatedCalories: (_elapsedTime.inMinutes * 8).clamp(0, 9999),
        completedSets: realCompletedSets > 0
            ? realCompletedSets
            : _completedExercises.length,
        muscleGroupsWorked: muscleGroups.toList(),
        totalKgLifted: totalKgLifted,
        totalReps: totalReps,
        avgRpe: avgRpe,
      );

      // ignore: use_build_context_synchronously
      await _lockScreenService.clear();
      // ignore: use_build_context_synchronously
      await Navigator.of(navigator.context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WorkoutSummaryScreen(summaryData: summaryData),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      navigator.pop();
      final rawError = e.toString().replaceFirst('Exception: ', '').trim();
      final providerError = provider.error?.trim() ?? '';
      final message = rawError.isNotEmpty
          ? rawError
          : providerError.isNotEmpty
          ? providerError
          : saveErrorMessage;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: CleanTheme.accentRed),
      );
    }
  }

  Future<void> _ensureSessionAndSyncPendingLogs(
    WorkoutLogProvider provider,
  ) async {
    if (provider.currentWorkoutLog == null) {
      debugPrint(
        'WorkoutSessionScreen: no active workout log, attempting late registration for workoutDayId=${widget.workoutDay.id}',
      );
      provider.clearError();
      await provider.startWorkout(workoutDayId: widget.workoutDay.id);
    }

    if (provider.currentWorkoutLog == null) {
      final providerError = provider.error?.trim() ?? '';
      throw Exception(
        providerError.isNotEmpty
            ? providerError
            : 'Sessione workout non disponibile per il salvataggio. workoutDayId=${widget.workoutDay.id}',
      );
    }

    await _syncPendingCompletedSets(provider);
  }

  Future<void> _syncPendingCompletedSets(WorkoutLogProvider provider) async {
    final entries = _setLoggingKeys.entries.toList();

    for (final entry in entries) {
      final uniqueId = entry.key;
      final setState = entry.value.currentState;
      if (setState == null) continue;

      final exercise = _getExerciseById(uniqueId);
      if (exercise == null) continue;

      final completedSets = setState.getCompletedSetEntries();
      if (completedSets.isEmpty) continue;

      var exerciseLog = _findExerciseLogForEntry(provider, uniqueId, exercise);

      if (exerciseLog == null) {
        final orderIndex = _getExerciseOrderIndex(uniqueId);
        final newLog = await provider.addExerciseLog(
          exerciseId: exercise.exercise.id,
          orderIndex: orderIndex,
          exerciseType: exercise.exerciseType,
        );
        if (newLog == null) {
          throw Exception(
            provider.error?.trim().isNotEmpty == true
                ? provider.error!.trim()
                : 'Impossibile salvare i dati per ${exercise.exercise.name}.',
          );
        }
        exerciseLog = newLog;
      }

      final existingSetNumbers = exerciseLog.setLogs
          .map((setLog) => setLog.setNumber)
          .toSet();

      for (final setEntry in completedSets) {
        if (existingSetNumbers.contains(setEntry.setNumber)) continue;

        final reps = _resolveSafeRepsForSave(
          exercise: exercise,
          setNumber: setEntry.setNumber,
          reps: setEntry.reps,
        );

        final added = await provider.addSetLog(
          exerciseLogId: exerciseLog.id,
          setNumber: setEntry.setNumber,
          reps: reps,
          weightKg: setEntry.weightKg,
          rpe: setEntry.rpe,
          completed: true,
        );

        if (!added) {
          throw Exception(
            provider.error?.trim().isNotEmpty == true
                ? provider.error!.trim()
                : 'Errore nel salvataggio dei set completati.',
          );
        }

        existingSetNumbers.add(setEntry.setNumber);
      }
    }
  }

  int _resolveSafeRepsForSave({
    required WorkoutExercise exercise,
    required int setNumber,
    required int? reps,
  }) {
    if (reps != null && reps > 0) return reps;
    final target = _getTargetReps(exercise, setNumber);
    final parsed = int.tryParse(
      RegExp(r'(\d+)').firstMatch(target)?.group(1) ?? '',
    );
    return (parsed ?? 1).clamp(1, 999);
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
      final completedExerciseIds = _getCompletedBaseExerciseIds();
      final skippedExercises = widget.workoutDay.exercises
          .where((e) => !completedExerciseIds.contains(e.exercise.id))
          .map((e) => e.exercise.id)
          .toList();

      // Create difficulty map (using overall difficulty for all completed exercises for now)
      final difficultyMap = <String, int>{};
      for (final exerciseId in completedExerciseIds) {
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
        await _lockScreenService.clear();
        if (!mounted) return;
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

class _LockSetPointer {
  final String exerciseId;
  final int setNumber;

  const _LockSetPointer({required this.exerciseId, required this.setNumber});
}

class _OrderedExercisePointer {
  final String exerciseId;
  final WorkoutExercise exercise;

  const _OrderedExercisePointer({
    required this.exerciseId,
    required this.exercise,
  });
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
  final bool isPaused;
  final bool isLoading;
  final bool showShimmer;

  const _GigiExecuteButton({
    required this.onTap,
    required this.label,
    this.onPause,
    this.onResume,
    this.isOutlined = false,
    this.isPlaying = false,
    this.isPaused = false,
    this.isLoading = false,
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
    final isPaused = widget.isPaused;
    final isLoading = widget.isLoading;
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
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: isLoading
                                ? CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: CleanTheme.accentRed,
                                  )
                                : Icon(
                                    isPaused
                                        ? Icons.play_arrow_rounded
                                        : Icons.graphic_eq_rounded,
                                    color: CleanTheme.accentRed,
                                    size: 18,
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
                            onTap: isPaused ? widget.onResume : widget.onPause,
                            child: Icon(
                              isPaused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
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
