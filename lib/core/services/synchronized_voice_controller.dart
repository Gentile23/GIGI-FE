import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gigi_tts_service.dart';
import 'exercise_scripts_database.dart';
import 'coaching_phrases_database.dart' as phrases;

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
  bool _isSessionStarted = false;

  // Exercise context
  String _userName = 'Campione';
  String _userGoal =
      'general'; // muscleGain, weightLoss, toning, strength, wellness
  String _currentMuscleGroup = '';
  int _currentSet = 0;
  int _totalSets = 0;
  int _restSeconds = 0;
  ExerciseCoachingScript? _currentScript;

  // New: Streak and mood tracking
  int _streakDays = 0;
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

  /// Get first name only (never full name)
  String get firstName {
    if (_userName.isEmpty) return 'Campione';
    final parts = _userName.trim().split(' ');
    return parts.first.isNotEmpty ? parts.first : 'Campione';
  }

  SynchronizedVoiceController(this._ttsService);

  /// Initialize with user data and load saved preferences
  Future<void> initialize({
    required String userName,
    String? experienceLevel,
    String? goal,
  }) async {
    // Store full name but always use firstName for greeting
    _userName = userName.isNotEmpty ? userName : 'Campione';
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
  /// Uses pre-cached intro to hide TTS generation delay
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

    // Step 0: Greet user (Restored feature - Full Experience)
    final greeting = _buildPersonalizedGreeting(exerciseName, sets, reps);
    await _speak(greeting);

    // Explanation is NOT played automatically anymore.
    // User must click "Esegui con Gigi" to hear the explanation.
  }

  /// Build goal-based personalized greeting using new phrases database
  String _buildPersonalizedGreeting(String exerciseName, int sets, int reps) {
    final buffer = StringBuffer();

    // Smart greeting based on time of day
    buffer.write(phrases.getTimeBasedGreeting(_userName));
    buffer.write(' ');

    // Streak acknowledgment (if applicable)
    final streakPhrase = phrases.getStreakPhrase(_userName, _streakDays);
    if (streakPhrase != null) {
      buffer.write(streakPhrase);
      buffer.write(' ');
    }

    // Removed: "Oggi alleniamo [muscolo]" as per user request

    // Goal-based motivation from database
    buffer.write(phrases.getGoalMotivation(_userGoal));
    buffer.write(' ');

    // Mood-based encouragement (if set)
    if (_userMood != 'neutral') {
      final moodPhrase = phrases.getMoodEncouragement(_userName, _userMood);
      if (moodPhrase.isNotEmpty) {
        buffer.write(moodPhrase);
        buffer.write(' ');
      }
    }

    // Call to action
    if (_isSessionStarted) {
      buffer.write(
        'Puoi cliccare "Info" per i dettagli dell\'esercizio o "Gigi" per essere aiutato nell\'esecuzione passo-passo.',
      );
    } else {
      buffer.write(
        'Premi "Inizia sessione" quando vuoi cominciare, sarò al tuo fianco!',
      );
    }

    return buffer.toString();
  }

  /// Notify controller that workout session has started
  void notifySessionStarted() {
    _isSessionStarted = true;
    if (_isEnabled && !_isMuted) {
      speakSessionStartGreeting();
    }
    notifyListeners();
  }

  /// Speak greeting specifically when session starts
  Future<void> speakSessionStartGreeting() async {
    if (!_isEnabled || _isMuted) return;

    final buffer = StringBuffer();
    buffer.write('Ottimo ${firstName}, sessione iniziata! ');
    buffer.write(
      'Puoi cliccare "Info" su ogni esercizio per i dettagli, o "Gigi" per essere aiutato nell\'esecuzione passo-passo. ',
    );
    buffer.write('Diamoci dentro!');

    await _speak(buffer.toString());
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
    _ttsService.stop();
    notifyListeners();
  }

  /// Start set (tap "Inizia Serie")
  Future<void> startSet() async {
    _currentSet++;
    _restTimer?.cancel();
    _cueTimer?.cancel();

    _phase = VoiceCoachingPhase.explaining;
    notifyListeners();

    // Speak based on user level and set number
    if (_currentSet == 1) {
      switch (_userLevel) {
        case UserLevel.beginner:
          await _speakFullExplanation();
          break;
        case UserLevel.intermediate:
          await _speakBriefExplanation();
          break;
        case UserLevel.advanced:
          await _speakSetCountdown();
          break;
      }
    } else {
      // Subsequent sets: countdown only for all levels
      await _speakSetCountdown();
    }

    // Start during-set cues based on level
    _startDuringSetCues();

    _phase = VoiceCoachingPhase.executing;
    notifyListeners();
  }

  /// Complete set (tap checkbox) - basic version
  Future<void> completeSet() async {
    await completeSetWithData();
  }

  /// Complete set with performance data for personalized celebration
  Future<void> completeSetWithData({
    double? weightKg,
    int? reps,
    int? rpe,
    double? previousWeightKg,
  }) async {
    _cueTimer?.cancel();
    _phase = VoiceCoachingPhase.postSet;
    notifyListeners();

    // Personalized celebration based on performance
    await _speakPersonalizedCelebration(
      weightKg: weightKg,
      rpe: rpe,
      previousWeightKg: previousWeightKg,
    );

    if (_currentSet < _totalSets) {
      // Start rest timer
      _startRestTimer();
    } else {
      // Exercise completed with summary
      _phase = VoiceCoachingPhase.completed;
      await _speakExerciseComplete(weightKg: weightKg);
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
    // Frequency based on user level
    int intervalSeconds;
    switch (_userLevel) {
      case UserLevel.beginner:
        intervalSeconds = 15; // More frequent for beginners
        break;
      case UserLevel.intermediate:
        intervalSeconds = 25; // Less frequent
        break;
      case UserLevel.advanced:
        return; // No cues for advanced users
    }

    // Add some randomness (±3 seconds)
    final interval = Duration(
      seconds: intervalSeconds + Random().nextInt(7) - 3,
    );

    _cueTimer = Timer.periodic(interval, (timer) {
      if (_phase == VoiceCoachingPhase.executing && _currentScript != null) {
        final cue = _currentScript!.getRandomCue();
        if (cue.isNotEmpty) {
          _speak(cue);
        }
      }
    });
  }

  void _startRestTimer() {
    _restRemaining = _restSeconds;
    _phase = VoiceCoachingPhase.resting;
    notifyListeners();

    // Announce rest start using phrases database
    _speak(phrases.getRestStartPhrase(_restSeconds));

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _restRemaining--;
      notifyListeners();

      // Voice cues at specific intervals
      if (_restRemaining == 30 && _restSeconds >= 45) {
        _speak('30 secondi, preparati!');
      } else if (_restRemaining == 10) {
        _speak('10 secondi!');
      } else if (_restRemaining <= 5 && _restRemaining > 0) {
        _speak('$_restRemaining');
      } else if (_restRemaining == 0) {
        timer.cancel();
        _speak('Via!');
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
    dynamic
    voiceCoachingService, // VoiceCoachingService - optional to avoid tight coupling
  }) async {
    if (_isGuidedExecutionPlaying) return; // Prevent double-tap

    _isGuidedExecutionPlaying = true;
    notifyListeners();

    _isGuidedExecutionPlaying = true;
    notifyListeners();

    // 0. Immediate feedback to mask loading time
    await _speak(
      'Ti spiego questo esercizio con la tecnica corretta... Preparati...',
    );

    String? scriptToSpeak;

    // 1. Try API-generated script if exerciseId is provided
    if (exerciseId != null && voiceCoachingService != null) {
      try {
        scriptToSpeak = await voiceCoachingService.getGuidedExecutionScript(
          exerciseId: exerciseId,
        );
        debugPrint('📢 Got AI-generated script from API');
      } catch (e) {
        debugPrint('⚠️ API script fetch failed: $e');
      }
    }

    // 2. Fallback to local script database
    if (scriptToSpeak == null) {
      _currentScript ??= getScriptForExercise(exerciseName);
      if (_currentScript == null && muscleGroups != null) {
        _currentScript = createGenericScript(
          exerciseName: exerciseName,
          muscleGroups: muscleGroups,
        );
      }

      if (_currentScript != null) {
        scriptToSpeak = _currentScript!.getGuidedExecutionScript(firstName);
      }
    }

    // 3. Final fallback generic guide
    if (scriptToSpeak == null) {
      scriptToSpeak =
          '''
$firstName, eseguiamo insieme 2 ripetizioni perfette di $exerciseName.

Posizionati correttamente, mantieni una postura stabile.

PRIMA RIPETIZIONE:
Esegui il movimento lentamente, concentrandoti sulla tecnica.
Inspira nella fase di allungamento, espira nello sforzo.

... pausa ...

SECONDA RIPETIZIONE:
Stessa tecnica perfetta. Controllo totale del movimento.

Perfetto $firstName! Ora sei pronto per le tue serie!
''';
    }

    // Attempt to use high-quality TTS (ElevenLabs) via API
    bool playedWithHighQuality = false;

    if (voiceCoachingService != null) {
      try {
        debugPrint('🎙️ Generating high-quality audio with ElevenLabs...');
        // Call backend to generate TTS audio
        final audioUrl = await voiceCoachingService.generateTTS(scriptToSpeak);

        if (audioUrl != null) {
          debugPrint('🎧 Playing high-quality audio: $audioUrl');
          await _ttsService.speakUrl(audioUrl);
          playedWithHighQuality = true;

          // Wait for audio to finish (approximate or use completion handler logic in service)
          // Since speakUrl is fire-and-forget in terms of await, we rely on the UI/State in service
        }
      } catch (e) {
        debugPrint(
          '⚠️ High-quality TTS failed: $e. Falling back to local TTS.',
        );
      }
    }

    // Fallback to local TTS if high-quality failed
    if (!playedWithHighQuality) {
      debugPrint('🗣️ using local TTS');
      await _speak(scriptToSpeak);
    }

    // Wait for speaking to finish not strictly needed here as _speak waits,
    // but for URL playback we might want to track state.
    // _isGuidedExecutionPlaying will be reset when speech completes via listeners in UI or manually here?
    // Actually _speak waits, but speakUrl does not necessarily wait for completion in this implementation.
    // However, GigiTTSService handles isSpeaking state.

    // If we used local TTS, we awaited. If we used URL, we didn't await the full duration.
    // Ideally speakUrl should return a Future that completes when audio finishes.
    // For now, let's trust the service state management.

    // Note: The UI won't perform "cleanup" of isGuidedExecutionPlaying until user interaction or we set it false.
    // But wait, the original code sets it false immediately after _speak!
    // Original: await _speak(...); _isGuidedExecutionPlaying = false; notifyListeners();

    // We need to keep it true while playing.
    // For local TTS, _speak waits.
    // For URL TTS, we need to monitor completion.

    if (playedWithHighQuality) {
      // Wait while speaking
      while (_ttsService.isSpeaking) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    _isGuidedExecutionPlaying = false;
    notifyListeners();
  }

  /// Stop guided execution if playing
  void stopGuidedExecution() {
    if (_isGuidedExecutionPlaying) {
      _ttsService.stop();
      _isGuidedExecutionPlaying = false;
      notifyListeners();
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

  /// Handle user interaction events for synchronized voice feedback
  /// Respects minimal mode setting
  Future<void> onUserInteraction(
    GigiInteractionEvent event, {
    int? setNumber,
    int? totalSets,
    String? exerciseName,
  }) async {
    if (!_isEnabled || _isMuted || _isGuidedExecutionPlaying) return;

    switch (event) {
      case GigiInteractionEvent.setCheckboxToggled:
        if (!_minimalMode) {
          // In full mode, celebrate every set
          if (setNumber != null && totalSets != null) {
            final celebration = phrases.getSetCelebration(
              userName: firstName,
              currentSet: setNumber,
              totalSets: totalSets,
            );
            await speakBrief(celebration);
          }
        } else {
          // In minimal mode, only celebrate first and last set
          if (setNumber == 1) {
            await speakBrief('Prima serie fatta!');
          } else if (setNumber == totalSets) {
            await speakBrief('Ottimo! Esercizio completato!');
          }
          // Middle sets: silence
        }
        break;

      case GigiInteractionEvent.exerciseCardOpened:
        // Brief acknowledgment only in full mode
        if (!_minimalMode && exerciseName != null) {
          await speakBrief('$exerciseName. Pronto quando vuoi!');
        }
        break;

      case GigiInteractionEvent.restTimerSkipped:
        if (!_minimalMode) {
          await speakBrief('Ok, niente pausa! Forza!');
        }
        break;

      case GigiInteractionEvent.exerciseCompleted:
        // Always celebrate exercise completion
        await speakBrief('Grande lavoro!');
        break;

      case GigiInteractionEvent.workoutStarted:
        // Greeting when workout starts (already handled by greetUser)
        break;

      case GigiInteractionEvent.workoutCompleted:
        await _speak(phrases.getWorkoutCompletePhrase(firstName));
        break;
    }
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _cueTimer?.cancel();
    super.dispose();
  }
}
