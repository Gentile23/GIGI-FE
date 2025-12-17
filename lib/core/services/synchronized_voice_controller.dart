import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gigi_tts_service.dart';
import 'exercise_scripts_database.dart';

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

  // Exercise context
  String _userName = 'Campione';
  String _userGoal =
      'general'; // muscleGain, weightLoss, toning, strength, wellness
  String _currentMuscleGroup = '';
  int _currentSet = 0;
  int _totalSets = 0;
  int _restSeconds = 0;
  ExerciseCoachingScript? _currentScript;

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

  SynchronizedVoiceController(this._ttsService);

  /// Initialize with user data and load saved preferences
  Future<void> initialize({
    required String userName,
    String? experienceLevel,
    String? goal,
  }) async {
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

  /// Activate voice coaching FIRST TIME (tap mic icon) - says personalized greeting
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
    _phase = VoiceCoachingPhase.activated;
    notifyListeners();

    // Build personalized greeting
    final greeting = _buildPersonalizedGreeting(exerciseName, sets, reps);
    await _speak(greeting);

    _phase = VoiceCoachingPhase.preExercise;
    notifyListeners();
  }

  /// Build goal-based personalized greeting
  String _buildPersonalizedGreeting(String exerciseName, int sets, int reps) {
    final buffer = StringBuffer();

    // Opening
    buffer.write('Ciao $_userName! Sono Gigi, il tuo coach. ');

    // What we're doing
    if (_currentMuscleGroup.isNotEmpty) {
      buffer.write('Oggi alleniamo $_currentMuscleGroup con $exerciseName. ');
    } else {
      buffer.write('Facciamo $exerciseName. ');
    }

    // Goal-based motivation
    buffer.write(_getGoalMotivation());

    // Call to action
    buffer.write(
      'Premi il punto interrogativo per la spiegazione, o inizia quando sei pronto!',
    );

    return buffer.toString();
  }

  /// Get motivational phrase based on user goal
  String _getGoalMotivation() {
    switch (_userGoal.toLowerCase()) {
      case 'musclegain':
      case 'muscle_gain':
        return 'Costruiamo muscolo oggi! ';
      case 'weightloss':
      case 'weight_loss':
        return 'Bruciamo calorie! ';
      case 'toning':
        return 'Definiamoci! ';
      case 'strength':
        return 'Diventiamo più forti! ';
      case 'wellness':
        return 'Prendiamoci cura di noi! ';
      default:
        return '';
    }
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

  /// Personalized celebration based on RPE and weight
  Future<void> _speakPersonalizedCelebration({
    double? weightKg,
    int? rpe,
    double? previousWeightKg,
  }) async {
    final buffer = StringBuffer();

    // Weight increase detection
    if (weightKg != null &&
        previousWeightKg != null &&
        weightKg > previousWeightKg) {
      buffer.write('Fantastico $_userName! Hai aumentato il peso! ');
    } else if (_currentSet == 1) {
      buffer.write('Bene $_userName! Prima serie fatta! ');
    } else if (_currentSet == _totalSets) {
      buffer.write('Grande! Ultima serie completata! ');
    } else {
      buffer.write('Ottimo! $_currentSet su $_totalSets! ');
    }

    // RPE-based feedback
    if (rpe != null) {
      if (rpe <= 5) {
        buffer.write('Troppo facile? Prova ad aumentare!');
      } else if (rpe >= 9) {
        buffer.write('Grande sforzo! Recupera bene.');
      }
    }

    await _speak(buffer.toString());
  }

  /// Exercise complete announcement with stats
  Future<void> _speakExerciseComplete({double? weightKg}) async {
    final buffer = StringBuffer();
    buffer.write('Eccellente $_userName! Esercizio completato! ');

    if (weightKg != null && weightKg > 0) {
      buffer.write(
        '$_totalSets serie a ${weightKg.toStringAsFixed(0)} chili. ',
      );
    }

    buffer.write('Passa al prossimo quando vuoi!');
    await _speak(buffer.toString());
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

    // Announce rest start
    _speak('Riposa $_restSeconds secondi. Recupera.');

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

  @override
  void dispose() {
    _restTimer?.cancel();
    _cueTimer?.cancel();
    super.dispose();
  }
}
