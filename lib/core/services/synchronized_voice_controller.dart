import 'dart:async';
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
        'Premi \"Inizia sessione\" quando vuoi cominciare, sarò al tuo fianco!',
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
    dynamic
    voiceCoachingService, // VoiceCoachingService - optional to avoid tight coupling
  }) async {
    if (_isGuidedExecutionPlaying) return; // Prevent double-tap

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

    if (voiceCoachingService != null && scriptToSpeak != null) {
      try {
        debugPrint('🎙️ Generating high-quality audio with ElevenLabs...');
        debugPrint(
          '📝 Script to speak: ${scriptToSpeak.substring(0, scriptToSpeak.length.clamp(0, 100))}...',
        );

        // Call backend to generate TTS audio
        final audioUrl = await voiceCoachingService.generateTTS(scriptToSpeak);

        if (audioUrl != null && audioUrl.isNotEmpty) {
          debugPrint('🎧 Playing high-quality audio: $audioUrl');
          // Use speak() method which waits for completion (via _playUrlAndWait internally)
          await _ttsService.speakUrl(audioUrl);
          playedWithHighQuality = true;

          // Wait for audio to actually finish
          while (_ttsService.isSpeaking) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
          debugPrint('✅ High-quality audio finished');
        } else {
          debugPrint('⚠️ audioUrl is null or empty');
        }
      } catch (e) {
        debugPrint(
          '⚠️ High-quality TTS failed: $e. Falling back to local TTS.',
        );
      }
    }

    // Fallback to local TTS if high-quality failed
    if (!playedWithHighQuality && scriptToSpeak != null) {
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

    // 4. PERSONALIZED CLOSING: Short phrase with user's name
    // This makes the cached audio feel custom-generated for each user
    await _speakPersonalizedClosing(voiceCoachingService);

    _isGuidedExecutionPlaying = false;
    notifyListeners();
  }

  /// Generate and speak a short personalized closing phrase
  /// This creates the illusion that the entire audio was custom-generated
  Future<void> _speakPersonalizedClosing(dynamic voiceCoachingService) async {
    // Build personalized phrase with user's first name
    final closingPhrases = [
      'Perfetto $firstName! Ora tocca a te, dai il massimo!',
      'Ottimo $firstName! Sei pronto, spacca tutto!',
      'Forza $firstName! Adesso mostrami cosa sai fare!',
      'Bravissimo $firstName! Ora inizia le tue serie!',
      'Eccellente $firstName! Concentrati e vai!',
    ];

    // Select based on time for variety
    final index = DateTime.now().second % closingPhrases.length;
    final phrase = closingPhrases[index];

    // Generate TTS for this short phrase (fast because it's short)
    if (voiceCoachingService != null) {
      try {
        final audioUrl = await voiceCoachingService.generateTTS(phrase);
        if (audioUrl != null && audioUrl.isNotEmpty) {
          await _ttsService.speakUrl(audioUrl);
          while (_ttsService.isSpeaking) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
          return;
        }
      } catch (e) {
        debugPrint('⚠️ Personalized closing TTS failed: $e');
      }
    }

    // Fallback to local TTS
    await _speak(phrase);
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
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _cueTimer?.cancel();
    super.dispose();
  }
}
