import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../constants/api_config.dart';

// Web-specific imports with conditional
import 'dart:js_interop' if (dart.library.io) 'dart:js_interop';
import 'package:web/web.dart'
    if (dart.library.io) 'package:web/web.dart'
    as web;

/// Gigi TTS Service
///
/// Local text-to-speech service for voice coaching.
/// Uses device's TTS engine to speak Gigi's coaching cues.
/// Supports both native platforms (via flutter_tts) and web (via SpeechSynthesis).
class GigiTTSService extends ChangeNotifier {
  FlutterTts? _flutterTts;
  AudioPlayer? _audioPlayer; // For playing remote audio (ElevenLabs)

  bool _isInitialized = false;
  bool _isSpeaking = false;
  double _speechRate = 0.5; // 0.0 - 1.0 (0.5 is normal)
  double _pitch = 1.0; // 0.5 - 2.0 (1.0 is normal)
  double _volume = 1.0; // 0.0 - 1.0

  // Callbacks
  VoidCallback? onSpeakStart;
  VoidCallback? onSpeakComplete;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;

  /// Initialize TTS engine with Italian language
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _audioPlayer = AudioPlayer();

      // Configure audio player handlers
      _audioPlayer!.onPlayerStateChanged.listen((state) {
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

      if (kIsWeb) {
        // ... web init ...
      } else {
        // ... native init ...
        _flutterTts = FlutterTts();

        // ... (existing flutter_tts config) ...
        await _flutterTts!.setLanguage('it-IT');
        await _flutterTts!.setSpeechRate(_speechRate);
        await _flutterTts!.setPitch(_pitch);
        await _flutterTts!.setVolume(_volume);

        // ... (existing handlers) ...
        _flutterTts!.setStartHandler(() {
          _isSpeaking = true;
          notifyListeners();
          onSpeakStart?.call();
        });

        _flutterTts!.setCompletionHandler(() {
          _isSpeaking = false;
          notifyListeners();
          onSpeakComplete?.call();
        });

        _flutterTts!.setErrorHandler((error) {
          debugPrint('TTS Error: $error');
          _isSpeaking = false;
          notifyListeners();
        });
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
      _isInitialized = true;
    }
  }

  /// Speak remote audio from URL (ElevenLabs)
  Future<void> speakUrl(String url) async {
    if (!_isInitialized) await initialize();
    if (url.isEmpty) return;

    try {
      // Stop any current speech
      await stop();

      // Construct full URL if needed
      String fullUrl = url;
      if (!url.startsWith('http')) {
        // Remove leading slash if present to avoid double slash
        final cleanPath = url.startsWith('/') ? url.substring(1) : url;
        // Base Url already ends with /api/, so we need to be careful
        // Actually ApiConfig.baseUrl is https://.../api/
        // And backend returns /api/audio/..., so it duplicates /api/
        // We need the root domain
        final rootDomain = ApiConfig.baseUrl.replaceAll('/api/', '');
        fullUrl = '$rootDomain/$cleanPath';
      }

      debugPrint('Playing remote audio: $fullUrl');
      await _audioPlayer?.setVolume(_volume);
      await _audioPlayer?.play(UrlSource(fullUrl));
    } catch (e) {
      debugPrint('Audio playback error: $e');
      // No fallback here, caller handles it
    }
  }

  /// Speak text (Local TTS)
  Future<void> speak(String text) async {
    // ... existing implementation ...
    // Stop audio player if playing
    await _audioPlayer?.stop();

    if (!_isInitialized) await initialize();
    if (text.isEmpty) return;

    try {
      if (kIsWeb) {
        _speakWeb(text);
      } else {
        await _flutterTts?.speak(text);
      }
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  void _speakWeb(String text) {
    final utterance = web.SpeechSynthesisUtterance(text);
    utterance.rate = _speechRate;
    utterance.pitch = _pitch;
    utterance.volume = _volume;
    utterance.lang = 'it-IT';

    utterance.onstart = (web.Event e) {
      _isSpeaking = true;
      notifyListeners();
      onSpeakStart?.call();
    }.toJS;

    utterance.onend = (web.Event e) {
      _isSpeaking = false;
      notifyListeners();
      onSpeakComplete?.call();
    }.toJS;

    utterance.onerror = (web.Event e) {
      debugPrint('Web TTS Error');
      _isSpeaking = false;
      notifyListeners();
    }.toJS;

    web.window.speechSynthesis.speak(utterance);
  }

  /// Stop speaking (both TTS and AudioPlayer)
  Future<void> stop() async {
    try {
      await _audioPlayer?.stop();

      if (kIsWeb) {
        web.window.speechSynthesis.cancel();
      } else {
        await _flutterTts?.stop();
      }
      _isSpeaking = false;
      notifyListeners();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  /// Pause speaking
  Future<void> pause() async {
    try {
      await _audioPlayer?.pause();

      if (kIsWeb) {
        web.window.speechSynthesis.pause();
      } else {
        await _flutterTts?.pause();
      }
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
      if (kIsWeb) {
        // Web speech synthesis volume is handled in _speakWeb
      } else {
        await _flutterTts?.setVolume(_volume);
      }
      await _audioPlayer?.setVolume(_volume);
    } catch (e) {
      debugPrint('Error setting volume: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    if (!kIsWeb) {
      _flutterTts?.stop();
    }
    super.dispose();
  }
}
