import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_session/audio_session.dart';

/// MusicIntegrationService
///
/// Manages audio ducking when Gigi speaks during Music Mode.
/// This allows user's music to continue playing in the background
/// while temporarily lowering volume for voice coaching cues.
class MusicIntegrationService extends ChangeNotifier {
  AudioSession? _audioSession;
  bool _isInitialized = false;
  bool _isDucking = false;

  // Duration to keep ducking before restoring
  static const Duration _duckingDelay = Duration(milliseconds: 500);
  Timer? _restoreTimer;

  bool get isInitialized => _isInitialized;
  bool get isDucking => _isDucking;

  /// Initialize the audio session for music ducking
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _audioSession = await AudioSession.instance;

      // Configure for playback with ducking support
      await _audioSession!.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.mixWithOthers,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          avAudioSessionRouteSharingPolicy:
              AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            flags: AndroidAudioFlags.none,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType:
              AndroidAudioFocusGainType.gainTransientMayDuck,
          androidWillPauseWhenDucked: false,
        ),
      );

      _isInitialized = true;
      notifyListeners();

      debugPrint('MusicIntegrationService initialized');
    } catch (e) {
      debugPrint('Error initializing MusicIntegrationService: $e');
    }
  }

  /// Request audio focus and duck other audio (like Spotify/Apple Music)
  /// Call this before Gigi speaks
  Future<void> duckMusicForVoice() async {
    if (!_isInitialized || _isDucking) return;

    _restoreTimer?.cancel();

    try {
      // Request audio focus with ducking
      final success = await _audioSession?.setActive(true);

      if (success == true) {
        _isDucking = true;
        notifyListeners();
        debugPrint('Audio ducking started');
      }
    } catch (e) {
      debugPrint('Error starting audio duck: $e');
    }
  }

  /// Restore other audio after Gigi finishes speaking
  /// Call this after voice coaching audio completes
  Future<void> restoreMusicVolume({Duration delay = _duckingDelay}) async {
    if (!_isInitialized || !_isDucking) return;

    // Delay slightly before restoring to avoid jarring transition
    _restoreTimer?.cancel();
    _restoreTimer = Timer(delay, () async {
      try {
        // Release audio focus
        await _audioSession?.setActive(false);

        _isDucking = false;
        notifyListeners();
        debugPrint('Audio ducking ended');
      } catch (e) {
        debugPrint('Error restoring audio: $e');
      }
    });
  }

  /// Immediately restore without delay (for urgent situations)
  Future<void> restoreImmediately() async {
    _restoreTimer?.cancel();

    try {
      await _audioSession?.setActive(false);
      _isDucking = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error immediate restore: $e');
    }
  }

  @override
  void dispose() {
    _restoreTimer?.cancel();
    super.dispose();
  }
}

/// Extension methods for convenient usage with WorkoutAudioOrchestrator
extension MusicIntegrationHelpers on MusicIntegrationService {
  /// Wrap voice coaching playback with automatic ducking
  Future<T> withDucking<T>(Future<T> Function() playAudio) async {
    await duckMusicForVoice();
    try {
      final result = await playAudio();
      return result;
    } finally {
      await restoreMusicVolume();
    }
  }
}
