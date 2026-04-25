// ignore_for_file: unused_element
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gigi_tts_service.dart';
import 'exercise_scripts_database.dart';
import 'coaching_phrases_database.dart' as phrases;
import '../../data/services/voice_coaching_service.dart';

// Re-export for convenience
export 'exercise_scripts_database.dart';

/// Phases of synchronized voice coaching
enum VoiceCoachingPhase {
  idle, // Not active
  activated, // Just enabled, greeting played
  preExercise, // Waiting to start first set
  explaining, // First set - detailed explanation
  executing, // During set execution
  postSet, // Celebration after set
  resting, // Rest timer active
  completed, // Exercise finished
}

/// User experience level for adaptive coaching
enum UserLevel {
  beginner, // Full explanations + frequent cues
  intermediate, // Brief explanations + occasional cues
  advanced, // Countdown only + celebrations
}

/// User interaction events for Gigi to respond to
enum GigiInteractionEvent {
  setCheckboxToggled, // User completed a set
  exerciseCardOpened, // User tapped on an exercise
  restTimerSkipped, // User skipped rest timer
  exerciseCompleted, // All sets of an exercise done
  workoutStarted, // Workout session began
  workoutCompleted, // Entire workout finished
}

/// Deterministic UI state for guided execution.
enum GuidedExecutionUiState {
  idle,
  loading,
  ready,
  playing,
  paused,
  stopped,
  error,
}

/// Preparation card shown during audio loading
class PreparationCard {
  final String icon;
  final String title;
  final String body;

  const PreparationCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  factory PreparationCard.fromJson(Map<String, dynamic> json) {
    return PreparationCard(
      icon: json['icon'] as String? ?? '🎯',
      title: json['title'] as String? ?? 'Preparazione',
      body: json['body'] as String? ?? '',
    );
  }
}

/// Controller for synchronized voice coaching with full features:
/// - User personalization (name, level)
/// - Volume control
/// - Preferences persistence
/// - Exercise-specific scripts
class SynchronizedVoiceController extends ChangeNotifier {
  final GigiTTSService _ttsService;

  // State
  VoiceCoachingPhase _phase = VoiceCoachingPhase.idle;
  bool _isEnabled = false;
  UserLevel _userLevel = UserLevel.beginner;
  bool _isMuted = false;
  double _volume = 1.0;
  bool _minimalMode = true; // Non-invasive mode by default
  bool _isGuidedExecutionPlaying = false;
  GuidedExecutionUiState _guidedState = GuidedExecutionUiState.idle;
  int _guidedOperationId = 0;
  String? _guidedError;
  bool _isSessionStarted = false;
  List<PreparationCard>? _preparationCards; // Structured cards for UI
  int _currentCardIndex = 0;
  bool _isAudioReady = false; // True when audio URL is obtained
  bool _allCardsShown = false; // True when overlay has shown all cards
  Completer<void>? _skipCompleter; // Resolves when cards are dismissed

  // Exercise context
  String _userName = '';
  String _userGoal =
      'general'; // muscleGain, weightLoss, toning, strength, wellness
  // ignore: unused_field
  String _currentMuscleGroup = '';
  int _currentSet = 0;
  int _totalSets = 0;
  int _restSeconds = 0;
  ExerciseCoachingScript? _currentScript;

  // New: Streak and mood tracking
  int _streakDays = 0;
  // ignore: unused_field
  String _userMood = 'neutral'; // energized, tired, stressed, neutral

  // Rest timer
  Timer? _restTimer;
  int _restRemaining = 0;

  // During-set cue timer
  Timer? _cueTimer;

  // Preferences keys

  static const String _prefKeyMuted = 'voice_coaching_muted';
  static const String _prefKeyVolume = 'voice_coaching_volume';

  // Getters
  VoiceCoachingPhase get phase => _phase;
  bool get isEnabled => _isEnabled;
  int get restRemaining => _restRemaining;
  bool get isResting => _phase == VoiceCoachingPhase.resting;
  bool get isMuted => _isMuted;
  double get volume => _volume;
  String get userName => _userName;
  UserLevel get userLevel => _userLevel;
  bool get minimalMode => _minimalMode;
  bool get isGuidedExecutionPlaying => _isGuidedExecutionPlaying;
  GuidedExecutionUiState get guidedState => _guidedState;
  String? get guidedError => _guidedError;
  bool get isGuidedExecutionPaused =>
      _guidedState == GuidedExecutionUiState.paused;
  bool get canPause => _guidedState == GuidedExecutionUiState.playing;
  bool get canResume => _guidedState == GuidedExecutionUiState.paused;
  bool get canStop =>
      _guidedState != GuidedExecutionUiState.idle &&
      _guidedState != GuidedExecutionUiState.stopped;
  List<PreparationCard>? get preparationCards => _preparationCards;
  int get currentCardIndex => _currentCardIndex;
  bool get isAudioReady => _isAudioReady;

  /// Backward-compatible getter: returns current card title or null
  String? get loadingStatus {
    if (_guidedState == GuidedExecutionUiState.loading) {
      return 'Preparazione audio...';
    }
    if (_guidedState == GuidedExecutionUiState.ready) {
      return 'Audio pronto';
    }
    if (_guidedState == GuidedExecutionUiState.paused) {
      return 'In pausa';
    }
    if (_guidedState == GuidedExecutionUiState.error) {
      return _guidedError ?? 'Errore audio';
    }
    if (_preparationCards == null || _preparationCards!.isEmpty) return null;
    final idx = _currentCardIndex.clamp(0, _preparationCards!.length - 1);
    return '${_preparationCards![idx].icon} ${_preparationCards![idx].title}';
  }

  bool _isCurrentOperation(int operationId) =>
      _guidedOperationId == operationId &&
      _guidedState != GuidedExecutionUiState.stopped;

  void _setGuidedState(GuidedExecutionUiState state, {String? error}) {
    _guidedState = state;
    if (error != null) _guidedError = error;
    if (state != GuidedExecutionUiState.error && error == null) {
      _guidedError = null;
    }
    _isGuidedExecutionPlaying =
        state != GuidedExecutionUiState.idle &&
        state != GuidedExecutionUiState.stopped &&
        state != GuidedExecutionUiState.error;
    notifyListeners();
  }

  /// Get first name only (never full name)
  String get firstName {
    if (_userName.isEmpty) return '';
    final parts = _userName.trim().split(' ');
    return parts.first.isNotEmpty ? parts.first : '';
  }

  SynchronizedVoiceController(this._ttsService);

  /// Initialize with user data and load saved preferences
  Future<void> initialize({
    required String userName,
    String? experienceLevel,
    String? goal,
  }) async {
    // Store full name but always use firstName for greeting
    _userName = userName.trim();
    _userLevel = _parseUserLevel(experienceLevel);
    _userGoal = goal ?? 'general';

    // Load saved preferences
    await _loadPreferences();

    // Initialize TTS
    await _ttsService.initialize();

    // Apply saved volume
    await _ttsService.setVolume(_isMuted ? 0.0 : _volume);

    notifyListeners();
  }

  /// Parse experience level string to UserLevel enum
  UserLevel _parseUserLevel(String? level) {
    if (level == null) return UserLevel.beginner;
    final lowered = level.toLowerCase();
    if (lowered.contains('advanced') ||
        lowered.contains('expert') ||
        lowered.contains('avanzato')) {
      return UserLevel.advanced;
    } else if (lowered.contains('intermediate') ||
        lowered.contains('intermedio')) {
      return UserLevel.intermediate;
    }
    return UserLevel.beginner;
  }

  /// Load saved preferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMuted = prefs.getBool(_prefKeyMuted) ?? false;
      _volume = prefs.getDouble(_prefKeyVolume) ?? 1.0;
    } catch (e) {
      debugPrint('Error loading voice coaching preferences: $e');
    }
  }

  /// Save preferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyMuted, _isMuted);
      await prefs.setDouble(_prefKeyVolume, _volume);
    } catch (e) {
      debugPrint('Error saving voice coaching preferences: $e');
    }
  }

  // =====================================
  // VOLUME CONTROL
  // =====================================

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double newVolume) async {
    _volume = newVolume.clamp(0.0, 1.0);
    if (!_isMuted) {
      await _ttsService.setVolume(_volume);
    }
    await _savePreferences();
    notifyListeners();
  }

  /// Toggle mute
  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _ttsService.setVolume(_isMuted ? 0.0 : _volume);
    await _savePreferences();
    notifyListeners();
  }

  /// Set mute state
  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    await _ttsService.setVolume(_isMuted ? 0.0 : _volume);
    await _savePreferences();
    notifyListeners();
  }

  // =====================================
  // COACHING LIFECYCLE
  // =====================================

  /// Activate voice coaching FIRST TIME (tap mic icon)
  /// Voice coaching is now silent on activation - only speaks during "Esegui con Gigi"
  Future<void> activateInitial({
    required String exerciseName,
    required int sets,
    required int reps,
    required int restSeconds,
    List<String>? muscleGroups,
  }) async {
    _isEnabled = true;
    _currentSet = 0;
    _totalSets = sets;
    _restSeconds = restSeconds;
    _currentScript = getScriptForExercise(exerciseName);
    _currentMuscleGroup = muscleGroups?.isNotEmpty == true
        ? muscleGroups!.first
        : '';
    _phase = VoiceCoachingPhase.preExercise;
    notifyListeners();

    // Silent activation - user must tap "Esegui con Gigi" to hear voice
  }

  /// Build simple greeting for activation (just hello + motivation)
  String _buildPersonalizedGreeting(String exerciseName, int sets, int reps) {
    final buffer = StringBuffer();

    // Smart greeting based on time of day (uses firstName internally)
    buffer.write(phrases.getTimeBasedGreeting(firstName));
    buffer.write(' ');

    // Streak acknowledgment (if applicable)
    final streakPhrase = phrases.getStreakPhrase(firstName, _streakDays);
    if (streakPhrase != null) {
      buffer.write(streakPhrase);
      buffer.write(' ');
    }

    // Goal-based motivation from database
    buffer.write(phrases.getGoalMotivation(_userGoal));
    buffer.write(' ');

    // Call to action depends on session state
    if (_isSessionStarted) {
      // Already in session - no need to explain buttons here
      buffer.write('Sono qui per aiutarti!');
    } else {
      // Not started yet - tell them to start
      buffer.write(
        'Premi "Inizia sessione" quando vuoi cominciare, sarò al tuo fianco!',
      );
    }

    return buffer.toString();
  }

  /// Notify controller that workout session has started
  void notifySessionStarted() {
    _isSessionStarted = true;
    // Silent - no automatic greeting
    notifyListeners();
  }

  /// Session start greeting - now silent (user must use "Esegui con Gigi")
  Future<void> speakSessionStartGreeting() async {
    // Silent - voice only speaks during "Esegui con Gigi"
  }

  /// Set user streak for personalized greetings
  void setStreakDays(int days) {
    _streakDays = days;
  }

  /// Set user mood for adaptive coaching
  void setUserMood(String mood) {
    _userMood = mood;
    notifyListeners();
  }

  /// Change to new exercise WITHOUT greeting (when navigating between exercises)
  void setExercise({
    required String exerciseName,
    required int sets,
    required int reps,
    required int restSeconds,
  }) {
    _currentSet = 0;
    _totalSets = sets;
    _restSeconds = restSeconds;
    _currentScript = getScriptForExercise(exerciseName);
    _phase = VoiceCoachingPhase.preExercise;
    notifyListeners();
  }

  /// Speak detailed explanation (manual button tap)
  Future<void> speakExplanation() async {
    if (_currentScript != null) {
      await _speak(_currentScript!.getFullExplanation(_userName));
    } else {
      await _speak(
        'Esegui il movimento in modo controllato, mantenendo la postura corretta.',
      );
    }
  }

  /// Deactivate voice coaching
  void deactivate() {
    _isEnabled = false;
    _phase = VoiceCoachingPhase.idle;
    _restTimer?.cancel();
    _cueTimer?.cancel();
    _guidedOperationId++;
    _guidedState = GuidedExecutionUiState.idle;
    _guidedError = null;
    _isGuidedExecutionPlaying = false;
    _preparationCards = null;
    _currentCardIndex = 0;
    _isAudioReady = false;
    _allCardsShown = false;
    if (_skipCompleter != null && !_skipCompleter!.isCompleted) {
      _skipCompleter!.complete();
    }
    _skipCompleter = null;
    _ttsService.stop();
    notifyListeners();
  }

  /// Start set (tap "Inizia Serie") - now silent
  Future<void> startSet() async {
    _currentSet++;
    _restTimer?.cancel();
    _cueTimer?.cancel();

    _phase = VoiceCoachingPhase.executing;
    notifyListeners();
    // Silent - no automatic explanations or countdowns
  }

  /// Complete set (tap checkbox) - basic version
  Future<void> completeSet() async {
    await completeSetWithData();
  }

  /// Complete set with performance data - now silent
  Future<void> completeSetWithData({
    double? weightKg,
    int? reps,
    int? rpe,
    double? previousWeightKg,
  }) async {
    _cueTimer?.cancel();
    _phase = VoiceCoachingPhase.postSet;
    notifyListeners();

    // Silent - no automatic celebrations

    if (_currentSet < _totalSets) {
      // Start rest timer (silent)
      _startRestTimer();
    } else {
      // Exercise completed
      _phase = VoiceCoachingPhase.completed;
      notifyListeners();
    }
  }

  /// Personalized celebration based on RPE and weight using phrases database
  Future<void> _speakPersonalizedCelebration({
    double? weightKg,
    int? rpe,
    double? previousWeightKg,
  }) async {
    // Check for personal record
    final isPersonalRecord =
        weightKg != null &&
        previousWeightKg != null &&
        weightKg > previousWeightKg;

    // Get celebration phrase from database
    final celebration = phrases.getSetCelebration(
      userName: _userName,
      currentSet: _currentSet,
      totalSets: _totalSets,
      isPersonalRecord: isPersonalRecord,
      weightKg: weightKg,
    );

    final buffer = StringBuffer(celebration);

    // RPE-based feedback (additional)
    if (rpe != null) {
      if (rpe <= 5) {
        buffer.write(' Troppo facile? Prova ad aumentare!');
      } else if (rpe >= 9) {
        buffer.write(' Grande sforzo! Recupera bene.');
      }
    }

    await _speak(buffer.toString());
  }

  /// Exercise complete announcement with stats
  Future<void> _speakExerciseComplete({double? weightKg}) async {
    final buffer = StringBuffer();

    // Use celebration from database for last set
    buffer.write(
      phrases.getSetCelebration(
        userName: _userName,
        currentSet: _totalSets,
        totalSets: _totalSets,
      ),
    );
    buffer.write(' ');

    if (weightKg != null && weightKg > 0) {
      buffer.write(
        '$_totalSets serie a ${weightKg.toStringAsFixed(0)} chili. ',
      );
    }

    buffer.write('Passa al prossimo quando vuoi!');
    await _speak(buffer.toString());
  }

  /// Speak workout complete phrase
  Future<void> speakWorkoutComplete() async {
    await _speak(phrases.getWorkoutCompletePhrase(_userName));
  }

  /// Skip rest timer
  void skipRest() {
    _restTimer?.cancel();
    _restRemaining = 0;
    _phase = VoiceCoachingPhase.preExercise;
    notifyListeners();
  }

  // =====================================
  // PRIVATE SPEAKING METHODS
  // =====================================

  /// Speak text (respects mute setting)
  Future<void> _speak(String text) async {
    if (!_isMuted) {
      await _ttsService.speak(text);
    }
  }

  Future<void> _speakFullExplanation() async {
    if (_currentScript != null) {
      await _speak(_currentScript!.getFullExplanation(_userName));
    } else {
      // Fallback generic explanation
      await _speak(
        'Pronti per la prima serie $_userName. '
        'Mantieni la postura corretta. '
        '3... 2... 1... Via!',
      );
    }
  }

  Future<void> _speakBriefExplanation() async {
    if (_currentScript != null) {
      await _speak(_currentScript!.getBriefExplanation(_userName));
    } else {
      await _speak(
        'Serie 1 $_userName. Concentrati sulla tecnica. 3... 2... 1... Via!',
      );
    }
  }

  Future<void> _speakSetCountdown() async {
    await _speak('Serie $_currentSet. Stessa tecnica. 3... 2... 1... Via!');
  }

  void _startDuringSetCues() {
    // Disabled - no automatic cues during sets
    // Voice only speaks during "Esegui con Gigi"
  }

  void _startRestTimer() {
    _restRemaining = _restSeconds;
    _phase = VoiceCoachingPhase.resting;
    notifyListeners();

    // Silent rest timer - no voice announcements
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _restRemaining--;
      notifyListeners();

      if (_restRemaining == 0) {
        timer.cancel();
        _phase = VoiceCoachingPhase.preExercise;
        notifyListeners();
      }
    });
  }

  /// Load script for a specific exercise
  void loadScriptForExercise(String exerciseName, List<String> muscleGroups) {
    _currentScript =
        getScriptForExercise(exerciseName) ??
        createGenericScript(
          exerciseName: exerciseName,
          muscleGroups: muscleGroups,
        );
  }

  // =====================================
  // "ESEGUI CON GIGI" - GUIDED EXECUTION
  // =====================================

  /// Speak guided execution for "Esegui con Gigi" button
  /// Provides step-by-step guide for 2 perfect reps
  ///
  /// If [exerciseId] and [voiceCoachingService] are provided, will try to fetch
  /// AI-generated script from OpenAI API first, then fall back to local script.
  Future<void> speakGuidedExecution({
    required String exerciseName,
    String? exerciseId,
    List<String>? muscleGroups,
    VoiceCoachingService? voiceCoachingService,
  }) async {
    if (_isGuidedExecutionPlaying) return;
    final operationId = ++_guidedOperationId;
    _setGuidedState(GuidedExecutionUiState.loading);

    // Load script early so we can show exercise tips during generation
    _currentScript ??= getScriptForExercise(exerciseName);
    if (_currentScript == null && muscleGroups != null) {
      _currentScript = createGenericScript(
        exerciseName: exerciseName,
        muscleGroups: muscleGroups,
      );
    }

    String? scriptToSpeak;
    String? guidedAudioUrl;

    // Show only a neutral loading card until exercise-specific cards arrive.
    _preparationCards = _getLoadingPreparationCard(exerciseName);
    _currentCardIndex = 0;
    _allCardsShown = false;
    _isAudioReady = false;
    notifyListeners();

    // Try API-generated script and cards if exerciseId is provided
    if (exerciseId != null && voiceCoachingService != null) {
      try {
        final responseData = await voiceCoachingService
            .getGuidedExecutionScript(exerciseId: exerciseId);
        if (!_isCurrentOperation(operationId)) return;

        if (responseData != null) {
          scriptToSpeak = responseData['full_script'] as String?;
          guidedAudioUrl = responseData['audio_url'] as String?;

          final apiCards = responseData['preparation_cards'] as List<dynamic>?;
          if (apiCards != null && apiCards.isNotEmpty) {
            _preparationCards = _deduplicatePreparationCards(
              apiCards
                  .map(
                    (item) =>
                        PreparationCard.fromJson(item as Map<String, dynamic>),
                  )
                  .toList(),
            );
            _allCardsShown = false;
            _currentCardIndex = 0;
            notifyListeners();
            debugPrint('📢 Got SPECIFIC preparation cards from API');
          }

          debugPrint('📢 Got AI-generated script from API');
        }
      } catch (e) {
        debugPrint('⚠️ API script fetch failed: $e');
        if (!_isCurrentOperation(operationId)) return;
      }
    }

    if (scriptToSpeak == null) {
      if (_currentScript != null) {
        scriptToSpeak = _currentScript!.getGuidedExecutionScript(firstName);
        _preparationCards = _deduplicatePreparationCards(
          _getPreparationCards(exerciseName),
        );
        _currentCardIndex = 0;
        _allCardsShown = false;
        notifyListeners();
      }
    }

    scriptToSpeak ??=
        '''
${firstName.isNotEmpty ? '$firstName, eseguiamo' : 'Eseguiamo'} insieme 2 ripetizioni perfette di $exerciseName.

Partiamo dalla posizione: ti guido io, un dettaglio alla volta.

Sistema l'appoggio in modo stabile. Trova la presa o il contatto delle mani.
Allunga la schiena, abbassa le spalle, attiva il core e tieni la testa neutra.

Immagina di muoverti dentro due binari: niente scatti, niente slancio, solo controllo.

Prima ripetizione: inspira... parti lento... accompagna il movimento contando uno... due... tre.
Fermati un istante nel punto finale senza perdere la postura.
Ora torna espirando, con spalle e schiena ferme.

... pausa ...

Seconda ripetizione: stesso setup. Se il corpo scappa, rallenta.
Controlla l'andata... senti i muscoli giusti lavorare... ritorna senza rimbalzare.

${firstName.isNotEmpty ? 'Perfetto $firstName.' : 'Ottimo lavoro.'} Questa è la traiettoria. Ora ripeti così nelle tue serie.
''';

    // Attempt to use high-quality TTS (ElevenLabs) via API
    bool playedWithHighQuality = false;

    if (voiceCoachingService != null) {
      try {
        final audioUrl = guidedAudioUrl?.isNotEmpty == true
            ? guidedAudioUrl
            : await voiceCoachingService.generateTTS(scriptToSpeak);
        if (!_isCurrentOperation(operationId)) return;

        if (audioUrl != null && audioUrl.isNotEmpty) {
          debugPrint('🎧 Audio ready: $audioUrl');

          // Signal that audio is ready — shows "Salta ▶" in overlay
          _isAudioReady = true;
          _setGuidedState(GuidedExecutionUiState.ready);
          notifyListeners();

          // Wait for user skip OR all cards shown
          _skipCompleter = Completer<void>();

          // If all cards were already shown, resolve immediately
          if (_allCardsShown) {
            _preparationCards = null;
            _isAudioReady = false;
            notifyListeners();
            _skipCompleter!.complete();
          }

          await _skipCompleter!.future;
          if (!_isCurrentOperation(operationId)) return;
          _skipCompleter = null;

          // Use speak() method which waits for completion (via _playUrlAndWait internally)
          _setGuidedState(GuidedExecutionUiState.playing);
          await _ttsService.speakUrl(audioUrl);
          if (!_isCurrentOperation(operationId)) return;
          playedWithHighQuality = true;
          debugPrint('✅ High-quality audio finished');
        } else {
          debugPrint('⚠️ audioUrl is null or empty');
        }
      } catch (e) {
        debugPrint(
          '⚠️ High-quality TTS failed: $e. Falling back to local TTS.',
        );
        if (!_isCurrentOperation(operationId)) return;
      }
    }

    // Fallback to local TTS if high-quality failed
    if (!playedWithHighQuality) {
      debugPrint('🗣️ using local TTS');
      _preparationCards = null;
      _isAudioReady = false;
      _setGuidedState(GuidedExecutionUiState.playing);
      notifyListeners();
      await _speak(scriptToSpeak);
      if (!_isCurrentOperation(operationId)) return;
    }

    _setGuidedState(GuidedExecutionUiState.idle);
    _preparationCards = null;
    _currentCardIndex = 0;
    _isAudioReady = false;
    _allCardsShown = false;
    _skipCompleter = null;
  }

  /// Build structured preparation cards from exercise script data
  /// These cards are shown during audio generation to mask latency
  List<PreparationCard> _getLoadingPreparationCard(String exerciseName) {
    return [
      PreparationCard(
        icon: '🎧',
        title: 'Guida in preparazione',
        body: 'Sto preparando la guida tecnica per $exerciseName.',
      ),
    ];
  }

  List<PreparationCard> _getPreparationCards(String exerciseName) {
    if (_currentScript != null) {
      return [
        PreparationCard(
          icon: '🎯',
          title: 'Posizionamento',
          body: _currentScript!.positionSetup,
        ),
        PreparationCard(
          icon: '💪',
          title: 'Muscoli Target',
          body: _currentScript!.muscleGroups,
        ),
        PreparationCard(
          icon: '🌬️',
          title: 'Respirazione',
          body: _currentScript!.breathingCue,
        ),
        PreparationCard(
          icon: '🧠',
          title: 'Visualizza',
          body: _currentScript!.visualizationCue,
        ),
        PreparationCard(
          icon: '⚡',
          title: 'Focus',
          body: _currentScript!.getRandomCue(),
        ),
        PreparationCard(
          icon: '🎧',
          title: 'Quasi pronto...',
          body: 'Gigi sta preparando la tua guida vocale',
        ),
      ];
    }
    // Generic fallback cards for exercises without a local script
    return [
      PreparationCard(
        icon: '🎯',
        title: 'Preparazione',
        body: 'Posizionati correttamente per $exerciseName',
      ),
      PreparationCard(
        icon: '🌬️',
        title: 'Respirazione',
        body: 'Inspira nella fase di allungamento, espira nello sforzo',
      ),
      PreparationCard(
        icon: '🧠',
        title: 'Concentrazione',
        body: 'Concentrati sul muscolo che stai allenando',
      ),
      PreparationCard(
        icon: '🎧',
        title: 'Quasi pronto...',
        body: 'Gigi sta preparando la tua guida vocale',
      ),
    ];
  }

  List<PreparationCard> _deduplicatePreparationCards(
    List<PreparationCard> cards,
  ) {
    final seen = <String>{};
    final unique = <PreparationCard>[];

    for (final card in cards) {
      final key = '${card.title}|${card.body}'
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      unique.add(card);
    }

    return unique;
  }

  /// Stop guided execution if playing
  void stopGuidedExecution() {
    _guidedOperationId++;
    _ttsService.stop();
    _preparationCards = null;
    _currentCardIndex = 0;
    _isAudioReady = false;
    _allCardsShown = false;
    // Complete any pending skip to unblock the async flow
    if (_skipCompleter != null && !_skipCompleter!.isCompleted) {
      _skipCompleter!.complete();
    }
    _skipCompleter = null;
    _setGuidedState(GuidedExecutionUiState.stopped);
  }

  /// Skip preparation cards — only works when audio is ready.
  /// Dismisses cards and triggers immediate audio playback.
  void skipPreparationCards() {
    _preparationCards = null;
    _currentCardIndex = 0;
    _isAudioReady = false;
    _allCardsShown = false;
    // Complete the Completer to unblock audio playback
    if (_skipCompleter != null && !_skipCompleter!.isCompleted) {
      _skipCompleter!.complete();
    }
    notifyListeners();
  }

  /// Called by the overlay when all cards have been shown.
  /// If audio is already ready, dismisses cards and plays audio.
  void notifyAllCardsShown() {
    _allCardsShown = true;
    if (_isAudioReady &&
        _skipCompleter != null &&
        !_skipCompleter!.isCompleted) {
      _preparationCards = null;
      _isAudioReady = false;
      notifyListeners();
      _skipCompleter!.complete();
    }
  }

  // =====================================
  // NON-INVASIVE MODE
  // =====================================

  /// Set minimal mode (non-invasive)
  void setMinimalMode(bool enabled) {
    _minimalMode = enabled;
    notifyListeners();
  }

  /// Speak a brief phrase (only if not muted and voice coaching active)
  /// Used for quick feedback on user interactions
  Future<void> speakBrief(String text) async {
    if (!_isEnabled || _isMuted || _isGuidedExecutionPlaying) return;
    await _ttsService.speak(text);
  }

  /// Greet user when activating voice coaching
  /// Uses first name only, never full name
  Future<void> greetUser() async {
    if (_isMuted) return;

    // Build a short, friendly greeting using first name
    final greeting = phrases.getTimeBasedGreeting(firstName);
    await _ttsService.speak(greeting);
  }

  // =====================================
  // INTERACTION TRACKING
  // =====================================

  // =====================================
  // MEDIA CONTROLS
  // =====================================

  /// Pause current audio
  Future<void> pauseAudio() async {
    if (!canPause) return;
    await _ttsService.pause();
    _setGuidedState(GuidedExecutionUiState.paused);
  }

  /// Resume current audio
  Future<void> resumeAudio() async {
    if (!canResume) return;
    await _ttsService.resume();
    _setGuidedState(GuidedExecutionUiState.playing);
  }

  /// Seek audio by offset
  Future<void> seekAudio(Duration offset) async {
    await _ttsService.seekBy(offset);
  }

  // =====================================
  // INTERACTION TRACKING
  // =====================================

  /// Handle user interaction events - now silent
  /// Voice only speaks during "Esegui con Gigi"
  Future<void> onUserInteraction(
    GigiInteractionEvent event, {
    int? setNumber,
    int? totalSets,
    String? exerciseName,
  }) async {
    // Silent - all interaction-based speech removed
    // User must tap "Esegui con Gigi" to hear voice coaching
    return;
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _cueTimer?.cancel();
    super.dispose();
  }
}
