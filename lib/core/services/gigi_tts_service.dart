import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Gigi TTS Service
///
/// Local text-to-speech service for voice coaching.
/// Uses device's TTS engine to speak Gigi's coaching cues.
class GigiTTSService extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();

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
      // Set Italian language
      await _flutterTts.setLanguage('it-IT');

      // Configure voice settings
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setVolume(_volume);

      // iOS specific
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );

      // Set up handlers
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        notifyListeners();
        onSpeakStart?.call();
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
        onSpeakComplete?.call();
      });

      _flutterTts.setErrorHandler((error) {
        debugPrint('TTS Error: $error');
        _isSpeaking = false;
        notifyListeners();
      });

      _isInitialized = true;
      notifyListeners();

      debugPrint('GigiTTSService initialized with Italian voice');
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  /// Speak text
  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    if (text.isEmpty) return;

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  /// Speak text and wait for completion
  Future<void> speakAndWait(String text) async {
    if (!_isInitialized) await initialize();
    if (text.isEmpty) return;

    final completer = Completer<void>();

    final originalHandler = onSpeakComplete;
    onSpeakComplete = () {
      originalHandler?.call();
      completer.complete();
    };

    await speak(text);
    await completer.future;

    onSpeakComplete = originalHandler;
  }

  /// Stop speaking
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      notifyListeners();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  /// Pause speaking (if supported)
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
      _isSpeaking = false;
      notifyListeners();
    } catch (e) {
      debugPrint('TTS pause error: $e');
    }
  }

  /// Set speech rate (0.0 - 1.0, default 0.5)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    await _flutterTts.setSpeechRate(_speechRate);
    notifyListeners();
  }

  /// Set pitch (0.5 - 2.0, default 1.0)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _flutterTts.setPitch(_pitch);
    notifyListeners();
  }

  /// Set volume (0.0 - 1.0, default 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _flutterTts.setVolume(_volume);
    notifyListeners();
  }

  /// Get available voices
  Future<List<dynamic>> getVoices() async {
    return await _flutterTts.getVoices;
  }

  /// Get available languages
  Future<List<dynamic>> getLanguages() async {
    return await _flutterTts.getLanguages;
  }

  // ============================================
  // COACHING-SPECIFIC METHODS
  // ============================================

  /// Speak exercise intro greeting
  Future<void> speakIntro(String greeting) async {
    await speak(greeting);
  }

  /// Speak pre-set cue (before starting set)
  Future<void> speakPreSet(int setNumber, int totalSets) async {
    await speak('Serie $setNumber di $totalSets. Pronti? Via!');
  }

  /// Speak rep cue
  Future<void> speakRepCue(String cue) async {
    await speak(cue);
  }

  /// Speak rep number only (quick)
  Future<void> speakRepNumber(int repNumber) async {
    await speak('$repNumber');
  }

  /// Speak post-set completion
  Future<void> speakPostSet() async {
    await speak('Ottimo! Serie completata!');
  }

  /// Speak rest countdown
  Future<void> speakCountdown(int seconds) async {
    switch (seconds) {
      case 60:
        await speak('Un minuto di recupero');
        break;
      case 30:
        await speak('Trenta secondi');
        break;
      case 10:
        await speak('Dieci secondi, preparati');
        break;
      case 5:
        await speak('Cinque');
        break;
      case 3:
        await speak('Tre');
        break;
      case 2:
        await speak('Due');
        break;
      case 1:
        await speak('Uno... Via!');
        break;
    }
  }

  /// Speak workout complete
  Future<void> speakWorkoutComplete(String? userName) async {
    final name = userName ?? 'campione';
    await speak('Eccellente $name! Allenamento completato!');
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
