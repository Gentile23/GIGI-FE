import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../../../data/models/voice_coaching_model.dart';

enum CoachingPlayerState {
  idle,
  playingPreExercise,
  playingDuringExecution,
  playingPostExercise,
  paused,
  stopped,
  error,
}

/// Service to manage multi-phase voice coaching audio playback
class VoiceCoachingPlayer extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  CoachingPlayerState _state = CoachingPlayerState.idle;
  MultiPhaseCoaching? _coaching;
  String? _errorMessage;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  VoiceCoachingPlayer() {
    _setupListeners();
  }

  void _setupListeners() {
    _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (state == PlayerState.completed) {
        _handleAudioComplete();
      }
    });

    _audioPlayer.onPositionChanged.listen((Duration position) {
      _currentPosition = position;
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((Duration duration) {
      _totalDuration = duration;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      _handleAudioComplete();
    });
  }

  void _handleAudioComplete() {
    // Auto-transition or stop based on current phase
    if (_state == CoachingPlayerState.playingPreExercise) {
      // Pre-exercise complete, move to idle (don't auto-play during)
      _state = CoachingPlayerState.idle;
    } else if (_state == CoachingPlayerState.playingDuringExecution) {
      _state = CoachingPlayerState.idle;
    } else if (_state == CoachingPlayerState.playingPostExercise) {
      _state = CoachingPlayerState.stopped;
    }
    notifyListeners();
  }

  // Getters
  CoachingPlayerState get state => _state;
  String? get errorMessage => _errorMessage;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get isPlaying =>
      _state == CoachingPlayerState.playingPreExercise ||
      _state == CoachingPlayerState.playingDuringExecution ||
      _state == CoachingPlayerState.playingPostExercise;
  bool get hasCoaching => _coaching != null;

  /// Initialize coaching data
  void setCoaching(MultiPhaseCoaching? coaching) {
    _coaching = coaching;
    notifyListeners();
  }

  /// Play pre-exercise audio
  Future<void> playPreExercise() async {
    if (_coaching?.preExercise?.audioUrl == null) {
      _setError('Pre-exercise audio not available');
      return;
    }

    try {
      await _audioPlayer.stop();
      _state = CoachingPlayerState.playingPreExercise;
      _errorMessage = null;
      notifyListeners();

      await _audioPlayer.play(UrlSource(_coaching!.preExercise!.audioUrl!));
    } catch (e) {
      _setError('Error playing pre-exercise audio: $e');
    }
  }

  /// Play during-execution audio
  Future<void> playDuringExecution() async {
    if (_coaching?.duringExecution?.audioUrl == null) {
      _setError('During-execution audio not available');
      return;
    }

    try {
      await _audioPlayer.stop();
      _state = CoachingPlayerState.playingDuringExecution;
      _errorMessage = null;
      notifyListeners();

      await _audioPlayer.play(UrlSource(_coaching!.duringExecution!.audioUrl!));
    } catch (e) {
      _setError('Error playing during-execution audio: $e');
    }
  }

  /// Play post-exercise audio
  Future<void> playPostExercise() async {
    if (_coaching?.postExercise?.audioUrl == null) {
      _setError('Post-exercise audio not available');
      return;
    }

    try {
      await _audioPlayer.stop();
      _state = CoachingPlayerState.playingPostExercise;
      _errorMessage = null;
      notifyListeners();

      await _audioPlayer.play(UrlSource(_coaching!.postExercise!.audioUrl!));
    } catch (e) {
      _setError('Error playing post-exercise audio: $e');
    }
  }

  /// Pause current playback
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      _state = CoachingPlayerState.paused;
      notifyListeners();
    } catch (e) {
      _setError('Error pausing audio: $e');
    }
  }

  /// Resume paused playback
  Future<void> resume() async {
    try {
      await _audioPlayer.resume();
      // Restore previous playing state
      if (_state == CoachingPlayerState.paused) {
        _state =
            CoachingPlayerState.playingDuringExecution; // Default assumption
        notifyListeners();
      }
    } catch (e) {
      _setError('Error resuming audio: $e');
    }
  }

  /// Stop all playback
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _state = CoachingPlayerState.stopped;
      _currentPosition = Duration.zero;
      notifyListeners();
    } catch (e) {
      _setError('Error stopping audio: $e');
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      _setError('Error seeking: $e');
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    _state = CoachingPlayerState.error;
    notifyListeners();
    debugPrint('VoiceCoachingPlayer Error: $message');
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
