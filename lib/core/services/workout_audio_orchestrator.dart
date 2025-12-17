import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../data/models/exercise_intro_model.dart';
import '../../data/services/voice_coaching_service.dart';

import 'gigi_tts_service.dart';

/// Coaching phases during a workout
enum CoachingPhase {
  idle,
  exerciseIntro, // Personalized intro before exercise
  preSet, // "Pronti per la serie X"
  duringRep, // Cue during repetitions
  postSet, // "Ottimo! Set completato"
  rest, // Rest countdown phase
  completed, // Workout finished
}

/// Events that trigger audio cues
enum WorkoutEvent {
  exerciseSelected,
  setStarted,
  repStarted,
  repCompleted,
  setCompleted,
  restStarted,
  restTick,
  restCompleted,
  workoutCompleted,
  pause,
  resume,
}

/// WorkoutAudioOrchestrator
///
/// The core service that synchronizes voice coaching audio with workout controls.
/// It listens to workout events and plays appropriate audio cues using TTS.
class WorkoutAudioOrchestrator extends ChangeNotifier {
  final VoiceCoachingService _voiceCoachingService;
  final GigiTTSService _ttsService;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Current state
  CoachingPhase _currentPhase = CoachingPhase.idle;
  CoachingMode _coachingMode = CoachingMode.voice;
  bool _isMuted = false;
  bool _isPaused = false;

  // Exercise context
  ExerciseIntroScript? _currentIntro;
  int _currentSet = 0;
  int _totalSets = 0;
  int _currentRep = 0;
  int _totalReps = 0;
  String? _userName;

  // Rest countdown
  Duration _restRemaining = Duration.zero;
  Timer? _restTimer;

  // Countdown intervals for voice announcements (in seconds)
  final List<int> _countdownIntervals = [60, 30, 10, 5, 3, 2, 1];

  WorkoutAudioOrchestrator(
    this._voiceCoachingService, {
    GigiTTSService? ttsService,
  }) : _ttsService = ttsService ?? GigiTTSService() {
    _setupAudioPlayer();
    _ttsService.initialize();
  }

  // Getters
  CoachingPhase get currentPhase => _currentPhase;
  CoachingMode get coachingMode => _coachingMode;
  bool get isMuted => _isMuted;
  bool get isPaused => _isPaused;
  int get currentSet => _currentSet;
  int get totalSets => _totalSets;
  int get currentRep => _currentRep;
  int get totalReps => _totalReps;
  Duration get restRemaining => _restRemaining;
  ExerciseIntroScript? get currentIntro => _currentIntro;
  GigiTTSService get ttsService => _ttsService;

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerComplete.listen((_) {
      _onAudioComplete();
    });
  }

  /// Set user name for personalized greetings
  void setUserName(String? name) {
    _userName = name;
  }

  /// Set coaching mode (voice or music)
  void setCoachingMode(CoachingMode mode) {
    _coachingMode = mode;
    notifyListeners();
  }

  /// Toggle mute
  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _audioPlayer.setVolume(0);
      _ttsService.setVolume(0);
    } else {
      _audioPlayer.setVolume(1);
      _ttsService.setVolume(1);
    }
    notifyListeners();
  }

  /// Handle workout events
  Future<void> onWorkoutEvent(
    WorkoutEvent event, {
    Map<String, dynamic>? data,
  }) async {
    if (_isMuted) return;

    switch (event) {
      case WorkoutEvent.exerciseSelected:
        await _onExerciseSelected(data?['exerciseId'] as String?);
        break;
      case WorkoutEvent.setStarted:
        await _onSetStarted(
          data?['setNumber'] as int? ?? 1,
          data?['totalSets'] as int? ?? 3,
          data?['totalReps'] as int? ?? 10,
        );
        break;
      case WorkoutEvent.repStarted:
        await _onRepStarted(data?['repNumber'] as int? ?? 1);
        break;
      case WorkoutEvent.repCompleted:
        await _onRepCompleted(data?['repNumber'] as int? ?? 1);
        break;
      case WorkoutEvent.setCompleted:
        await _onSetCompleted();
        break;
      case WorkoutEvent.restStarted:
        await _onRestStarted(
          Duration(seconds: data?['restSeconds'] as int? ?? 90),
        );
        break;
      case WorkoutEvent.restTick:
        _onRestTick();
        break;
      case WorkoutEvent.restCompleted:
        await _onRestCompleted();
        break;
      case WorkoutEvent.workoutCompleted:
        await _onWorkoutCompleted();
        break;
      case WorkoutEvent.pause:
        _onPause();
        break;
      case WorkoutEvent.resume:
        _onResume();
        break;
    }
  }

  /// Called when new exercise is selected
  Future<void> _onExerciseSelected(String? exerciseId) async {
    if (exerciseId == null) return;

    _currentPhase = CoachingPhase.exerciseIntro;
    notifyListeners();

    // Fetch and speak personalized intro
    try {
      _currentIntro = await _voiceCoachingService.getPersonalizedIntro(
        exerciseId,
      );
      notifyListeners();

      // Speak the intro greeting using TTS
      if (_coachingMode == CoachingMode.voice && _currentIntro != null) {
        await _ttsService.speakIntro(_currentIntro!.greeting);
      }
    } catch (e) {
      debugPrint('Error fetching personalized intro: $e');
    }
  }

  /// Called when a set starts
  Future<void> _onSetStarted(
    int setNumber,
    int totalSets,
    int totalReps,
  ) async {
    _currentSet = setNumber;
    _totalSets = totalSets;
    _totalReps = totalReps;
    _currentRep = 0;
    _currentPhase = CoachingPhase.preSet;
    notifyListeners();

    // Speak pre-set announcement using TTS
    if (_coachingMode == CoachingMode.voice) {
      await _ttsService.speakPreSet(setNumber, totalSets);
    }
  }

  /// Called when a rep starts (user taps to begin rep)
  Future<void> _onRepStarted(int repNumber) async {
    _currentRep = repNumber;
    _currentPhase = CoachingPhase.duringRep;
    notifyListeners();

    // In Voice Mode, speak rep number
    if (_coachingMode == CoachingMode.voice) {
      await _ttsService.speakRepNumber(repNumber);
    }
  }

  /// Called when user completes a rep
  Future<void> _onRepCompleted(int repNumber) async {
    _currentRep = repNumber;
    notifyListeners();

    // Check if this was the last rep
    if (repNumber >= _totalReps) {
      await _onSetCompleted();
    }
  }

  /// Called when set is completed
  Future<void> _onSetCompleted() async {
    _currentPhase = CoachingPhase.postSet;
    notifyListeners();

    // Speak set completion (both modes)
    await _ttsService.speakPostSet();
  }

  /// Called when rest period starts
  Future<void> _onRestStarted(Duration duration) async {
    _restRemaining = duration;
    _currentPhase = CoachingPhase.rest;
    notifyListeners();

    // Start rest countdown timer
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _onRestTick();
    });
  }

  /// Called every second during rest
  void _onRestTick() {
    if (_restRemaining.inSeconds <= 0) {
      _restTimer?.cancel();
      _onRestCompleted();
      return;
    }

    _restRemaining = _restRemaining - const Duration(seconds: 1);
    notifyListeners();

    // Check if we should announce countdown
    final seconds = _restRemaining.inSeconds;

    // In Music Mode, only announce 10, 5, 3, 2, 1
    final intervalsToAnnounce = _coachingMode == CoachingMode.music
        ? [10, 5, 3, 2, 1]
        : _countdownIntervals;

    if (intervalsToAnnounce.contains(seconds)) {
      _announceCountdown(seconds);
    }
  }

  /// Announce countdown number using TTS
  void _announceCountdown(int seconds) {
    _ttsService.speakCountdown(seconds);
  }

  /// Called when rest is completed
  Future<void> _onRestCompleted() async {
    _restTimer?.cancel();
    _currentPhase = CoachingPhase.preSet;
    _restRemaining = Duration.zero;
    notifyListeners();

    // Announce next set is ready
    await _ttsService.speak('Pronti per la prossima serie!');
  }

  /// Called when entire workout is completed
  Future<void> _onWorkoutCompleted() async {
    _currentPhase = CoachingPhase.completed;
    _restTimer?.cancel();
    notifyListeners();

    // Speak workout completion
    await _ttsService.speakWorkoutComplete(_userName);
  }

  /// Pause audio and timers
  void _onPause() {
    _isPaused = true;
    _audioPlayer.pause();
    _ttsService.pause();
    _restTimer?.cancel();
    notifyListeners();
  }

  /// Resume audio and timers
  void _onResume() {
    _isPaused = false;
    _audioPlayer.resume();

    // Restart rest timer if we were in rest phase
    if (_currentPhase == CoachingPhase.rest && _restRemaining.inSeconds > 0) {
      _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _onRestTick();
      });
    }
    notifyListeners();
  }

  /// Called when audio playback completes
  void _onAudioComplete() {
    // Handle phase transitions after audio completes
    switch (_currentPhase) {
      case CoachingPhase.exerciseIntro:
        _currentPhase = CoachingPhase.preSet;
        break;
      case CoachingPhase.preSet:
        _currentPhase = CoachingPhase.duringRep;
        break;
      case CoachingPhase.postSet:
        // Transition to rest or next exercise
        break;
      default:
        break;
    }
    notifyListeners();
  }

  /// Load cached audio URLs for an exercise (placeholder for future use)
  Future<void> loadExerciseAudio(
    String exerciseId, {
    String? preUrl,
    String? duringUrl,
    String? postUrl,
  }) async {
    // Future: cache pre-recorded audio URLs for fallback
    // Currently all audio is handled via TTS
  }

  /// Reset orchestrator state
  void reset() {
    _restTimer?.cancel();
    _audioPlayer.stop();
    _ttsService.stop();
    _currentPhase = CoachingPhase.idle;
    _currentIntro = null;
    _currentSet = 0;
    _totalSets = 0;
    _currentRep = 0;
    _totalReps = 0;
    _restRemaining = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _audioPlayer.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}
