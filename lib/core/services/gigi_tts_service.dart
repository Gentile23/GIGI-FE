import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../constants/api_config.dart';
import '../../data/services/voice_coaching_service.dart';

/// Gigi TTS Service (Pure ElevenLabs)
///
/// Uses ElevenLabs API exclusively via [VoiceCoachingService].
/// No local TTS fallback.
class GigiTTSService extends ChangeNotifier {
  final VoiceCoachingService _voiceCoachingService;
  final AudioPlayer _audioPlayer;

  bool _isInitialized = false;
  bool _isSpeaking = false;
  double _volume = 1.0;

  // Callbacks
  VoidCallback? onSpeakStart;
  VoidCallback? onSpeakComplete;

  GigiTTSService(this._voiceCoachingService) : _audioPlayer = AudioPlayer();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  double get volume => _volume;

  /// Initialize Audio Player
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure audio player handlers
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.playing) {
          if (!_isSpeaking) {
            _isSpeaking = true;
            notifyListeners();
            onSpeakStart?.call();
          }
        } else if (state == PlayerState.completed ||
            state == PlayerState.stopped) {
          if (_isSpeaking) {
            _isSpeaking = false;
            notifyListeners();
            onSpeakComplete?.call();
          }
        }
      });

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
      _isInitialized = true;
    }
  }

  /// Speak text using ElevenLabs API
  ///
  /// 1. Calls API to get Audio URL
  /// 2. Plays Audio URL
  /// 3. WAITS for audio to complete before returning
  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    if (text.isEmpty) return;

    // Stop any current speech
    await stop();

    try {
      debugPrint('🎙️ Converting to Speech (ElevenLabs): "$text"');

      final audioUrl = await _voiceCoachingService.generateTTS(text);

      if (audioUrl != null) {
        await _playUrlAndWait(audioUrl);
      } else {
        debugPrint('⚠️ TTS Generation failed or returned null');
        // No fallback as requested by user
      }
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  /// Helper to play URL AND WAIT for completion
  /// Uses Completer to await the onPlayerComplete event
  Future<void> _playUrlAndWait(String url) async {
    String fullUrl = url;
    if (!url.startsWith('http')) {
      try {
        final baseUri = Uri.parse(ApiConfig.baseUrl);
        final rootDomain =
            '${baseUri.scheme}://${baseUri.host}:${baseUri.port}';
        final cleanPath = url.startsWith('/') ? url.substring(1) : url;
        fullUrl = '$rootDomain/$cleanPath';
      } catch (e) {
        debugPrint('Error parsing base URL: $e');
        fullUrl = '${ApiConfig.baseUrl.replaceAll('/api/', '')}/$url';
      }
    }

    debugPrint('🎧 Playing audio (with wait): $fullUrl');

    // Create completer to await completion
    final completer = Completer<void>();

    // Listen for completion
    late StreamSubscription<PlayerState> subscription;
    subscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        if (!completer.isCompleted) {
          completer.complete();
        }
        subscription.cancel();
      }
    });

    _isSpeaking = true;
    notifyListeners();
    onSpeakStart?.call();

    try {
      await _audioPlayer.setVolume(_volume);
      await _audioPlayer.play(UrlSource(fullUrl));

      // Wait for audio to complete (with timeout)
      await completer.future.timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          debugPrint('⚠️ Audio playback timeout');
          subscription.cancel();
        },
      );
    } catch (e) {
      debugPrint('Error playing audio: $e');
      if (!completer.isCompleted) {
        completer.complete();
      }
      subscription.cancel();
    } finally {
      _isSpeaking = false;
      notifyListeners();
      onSpeakComplete?.call();
    }
  }

  // speakUrl method - now waits for audio completion
  Future<void> speakUrl(String url) async {
    if (!_isInitialized) await initialize();
    if (url.isEmpty) return;
    await stop();
    await _playUrlAndWait(url);
  }

  // Legacy method signature compatibility
  Future<void> speakIntro(String text) async => speak(text);
  Future<void> speakPreSet(int current, int total) async =>
      speak('Serie $current di $total. Pronti?');
  Future<void> speakRepNumber(int rep) async => speak('$rep');
  Future<void> speakPostSet() async =>
      speak('Serie completata. Ottimo lavoro!');
  Future<void> speakCountdown(int seconds) async => speak('$seconds');
  Future<void> speakWorkoutComplete(String? name) async =>
      speak('Allenamento completato! Grande ${name ?? "atleta"}!');

  /// Stop speaking
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isSpeaking = false;
      notifyListeners();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  /// Pause speaking
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      _isSpeaking = false;
      notifyListeners();
    } catch (e) {
      debugPrint('TTS pause error: $e');
    }
  }

  /// Set volume (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    try {
      await _audioPlayer.setVolume(_volume);
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  /// Resume playback
  Future<void> resume() async {
    try {
      if (!_isSpeaking && _isInitialized) {
        await _audioPlayer.resume();
        _isSpeaking = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('TTS resume error: $e');
    }
  }

  /// Seek by offset (e.g. +10s or -10s)
  Future<void> seekBy(Duration offset) async {
    try {
      final position = await _audioPlayer.getCurrentPosition();
      if (position != null) {
        final newPosition = position + offset;
        // Clamp between 0 and duration is handled by player mostly, but safe to do
        await _audioPlayer.seek(newPosition);
      }
    } catch (e) {
      debugPrint('TTS seek error: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
