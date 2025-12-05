import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'haptic_service.dart';

/// Tipi di suoni UI
enum UISoundType {
  tapLight,
  tapHeavy,
  swipe,
  toggleOn,
  toggleOff,
  success,
  error,
  notification,
}

/// Tipi di suoni achievement
enum AchievementSoundType { common, rare, epic, legendary }

/// Tipi di suoni workout
enum WorkoutSoundType {
  countdown,
  repComplete,
  setComplete,
  exerciseComplete,
  workoutComplete,
  personalRecord,
  restStart,
  restEnd,
}

/// Tipi di celebrazione
enum CelebrationType {
  levelUp,
  streakMilestone,
  personalRecord,
  workoutComplete,
  achievementUnlock,
  challengeWin,
}

/// Manager audio centralizzato per l'app
/// Gestisce tutti i suoni UI, workout e celebrazioni
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _uiPlayer = AudioPlayer();
  final AudioPlayer _achievementPlayer = AudioPlayer();
  final AudioPlayer _workoutPlayer = AudioPlayer();
  final AudioPlayer _ambientPlayer = AudioPlayer();

  bool _isEnabled = true;
  bool _isInitialized = false;
  double _volume = 0.7;

  /// Mappa dei percorsi audio
  static const Map<String, String> _audioAssets = {
    // UI Sounds
    'tap_light': 'audio/ui/tap_light.mp3',
    'tap_heavy': 'audio/ui/tap_heavy.mp3',
    'swipe': 'audio/ui/swipe.mp3',
    'toggle_on': 'audio/ui/toggle_on.mp3',
    'toggle_off': 'audio/ui/toggle_off.mp3',
    'success': 'audio/ui/success.mp3',
    'error': 'audio/ui/error.mp3',
    'notification': 'audio/ui/notification.mp3',

    // Achievement Sounds
    'unlock_common': 'audio/achievements/unlock_common.mp3',
    'unlock_rare': 'audio/achievements/unlock_rare.mp3',
    'unlock_epic': 'audio/achievements/unlock_epic.mp3',
    'unlock_legendary': 'audio/achievements/unlock_legendary.mp3',

    // Workout Sounds
    'countdown': 'audio/workout/countdown.mp3',
    'rep_complete': 'audio/workout/rep_complete.mp3',
    'set_complete': 'audio/workout/set_complete.mp3',
    'exercise_complete': 'audio/workout/exercise_complete.mp3',
    'workout_complete': 'audio/workout/workout_complete.mp3',
    'personal_record': 'audio/workout/personal_record.mp3',
    'rest_start': 'audio/workout/rest_start.mp3',
    'rest_end': 'audio/workout/rest_end.mp3',

    // Ambient
    'focus_mode': 'audio/ambient/focus_mode.mp3',
  };

  /// Inizializza l'audio manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configura i player
      await _uiPlayer.setVolume(_volume);
      await _achievementPlayer.setVolume(_volume);
      await _workoutPlayer.setVolume(_volume);
      await _ambientPlayer.setVolume(_volume * 0.5); // Ambient più basso

      // Imposta la modalità ambient per loop
      await _ambientPlayer.setReleaseMode(ReleaseMode.loop);

      _isInitialized = true;
      debugPrint('AudioManager initialized successfully');
    } catch (e) {
      debugPrint('AudioManager initialization error: $e');
    }
  }

  /// Abilita/Disabilita l'audio
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      stopAll();
    }
  }

  /// Imposta il volume (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _uiPlayer.setVolume(_volume);
    await _achievementPlayer.setVolume(_volume);
    await _workoutPlayer.setVolume(_volume);
    await _ambientPlayer.setVolume(_volume * 0.5);
  }

  /// Riproduci suono UI
  Future<void> playUISound(UISoundType type) async {
    if (!_isEnabled) return;

    String assetKey;
    switch (type) {
      case UISoundType.tapLight:
        assetKey = 'tap_light';
        break;
      case UISoundType.tapHeavy:
        assetKey = 'tap_heavy';
        break;
      case UISoundType.swipe:
        assetKey = 'swipe';
        break;
      case UISoundType.toggleOn:
        assetKey = 'toggle_on';
        break;
      case UISoundType.toggleOff:
        assetKey = 'toggle_off';
        break;
      case UISoundType.success:
        assetKey = 'success';
        break;
      case UISoundType.error:
        assetKey = 'error';
        break;
      case UISoundType.notification:
        assetKey = 'notification';
        break;
    }

    await _playAsset(_uiPlayer, assetKey);
  }

  /// Riproduci suono UI con haptic feedback sincronizzato
  Future<void> playUISoundWithHaptic(UISoundType type) async {
    // Esegui in parallelo per sincronizzazione perfetta
    await Future.wait([playUISound(type), _triggerHapticForUISound(type)]);
  }

  /// Riproduci suono achievement
  Future<void> playAchievementSound(AchievementSoundType type) async {
    if (!_isEnabled) return;

    String assetKey;
    switch (type) {
      case AchievementSoundType.common:
        assetKey = 'unlock_common';
        break;
      case AchievementSoundType.rare:
        assetKey = 'unlock_rare';
        break;
      case AchievementSoundType.epic:
        assetKey = 'unlock_epic';
        break;
      case AchievementSoundType.legendary:
        assetKey = 'unlock_legendary';
        break;
    }

    await _playAsset(_achievementPlayer, assetKey);
  }

  /// Riproduci suono achievement con haptic
  Future<void> playAchievementWithHaptic(AchievementSoundType type) async {
    await Future.wait([
      playAchievementSound(type),
      _triggerHapticForAchievement(type),
    ]);
  }

  /// Riproduci suono workout
  Future<void> playWorkoutSound(WorkoutSoundType type) async {
    if (!_isEnabled) return;

    String assetKey;
    switch (type) {
      case WorkoutSoundType.countdown:
        assetKey = 'countdown';
        break;
      case WorkoutSoundType.repComplete:
        assetKey = 'rep_complete';
        break;
      case WorkoutSoundType.setComplete:
        assetKey = 'set_complete';
        break;
      case WorkoutSoundType.exerciseComplete:
        assetKey = 'exercise_complete';
        break;
      case WorkoutSoundType.workoutComplete:
        assetKey = 'workout_complete';
        break;
      case WorkoutSoundType.personalRecord:
        assetKey = 'personal_record';
        break;
      case WorkoutSoundType.restStart:
        assetKey = 'rest_start';
        break;
      case WorkoutSoundType.restEnd:
        assetKey = 'rest_end';
        break;
    }

    await _playAsset(_workoutPlayer, assetKey);
  }

  /// Riproduci suono workout con haptic
  Future<void> playWorkoutSoundWithHaptic(WorkoutSoundType type) async {
    await Future.wait([playWorkoutSound(type), _triggerHapticForWorkout(type)]);
  }

  /// Celebrazione completa (audio + haptic + delay appropriato)
  Future<void> playCelebration(CelebrationType type) async {
    if (!_isEnabled) return;

    switch (type) {
      case CelebrationType.levelUp:
        await Future.wait([
          playAchievementSound(AchievementSoundType.epic),
          HapticService.levelUpPattern(),
        ]);
        break;

      case CelebrationType.streakMilestone:
        await Future.wait([
          playAchievementSound(AchievementSoundType.rare),
          HapticService.celebrationPattern(),
        ]);
        break;

      case CelebrationType.personalRecord:
        await Future.wait([
          playWorkoutSound(WorkoutSoundType.personalRecord),
          HapticService.personalRecordPattern(),
        ]);
        break;

      case CelebrationType.workoutComplete:
        await Future.wait([
          playWorkoutSound(WorkoutSoundType.workoutComplete),
          HapticService.workoutCompletePattern(),
        ]);
        break;

      case CelebrationType.achievementUnlock:
        await Future.wait([
          playAchievementSound(AchievementSoundType.common),
          HapticService.celebrationPattern(),
        ]);
        break;

      case CelebrationType.challengeWin:
        await Future.wait([
          playAchievementSound(AchievementSoundType.legendary),
          HapticService.legendaryAchievementPattern(),
        ]);
        break;
    }
  }

  /// Avvia musica ambient per focus mode
  Future<void> startFocusMode() async {
    if (!_isEnabled) return;
    await _playAsset(_ambientPlayer, 'focus_mode');
  }

  /// Ferma musica ambient
  Future<void> stopFocusMode() async {
    await _ambientPlayer.stop();
  }

  /// Ferma tutti i suoni
  Future<void> stopAll() async {
    await _uiPlayer.stop();
    await _achievementPlayer.stop();
    await _workoutPlayer.stop();
    await _ambientPlayer.stop();
  }

  /// Dispose dei player
  Future<void> dispose() async {
    await _uiPlayer.dispose();
    await _achievementPlayer.dispose();
    await _workoutPlayer.dispose();
    await _ambientPlayer.dispose();
  }

  /// Helper per riprodurre asset
  Future<void> _playAsset(AudioPlayer player, String assetKey) async {
    try {
      final assetPath = _audioAssets[assetKey];
      if (assetPath != null) {
        await player.play(AssetSource(assetPath));
      }
    } catch (e) {
      debugPrint('Error playing audio $assetKey: $e');
    }
  }

  /// Helper per haptic UI
  Future<void> _triggerHapticForUISound(UISoundType type) async {
    switch (type) {
      case UISoundType.tapLight:
        await HapticService.lightTap();
        break;
      case UISoundType.tapHeavy:
        await HapticService.heavyTap();
        break;
      case UISoundType.swipe:
        await HapticService.lightTap();
        break;
      case UISoundType.toggleOn:
      case UISoundType.toggleOff:
        await HapticService.selectionClick();
        break;
      case UISoundType.success:
        await HapticService.celebrationPattern();
        break;
      case UISoundType.error:
        await HapticService.errorPattern();
        break;
      case UISoundType.notification:
        await HapticService.notificationPattern();
        break;
    }
  }

  /// Helper per haptic achievement
  Future<void> _triggerHapticForAchievement(AchievementSoundType type) async {
    switch (type) {
      case AchievementSoundType.common:
        await HapticService.celebrationPattern();
        break;
      case AchievementSoundType.rare:
        await HapticService.rareAchievementPattern();
        break;
      case AchievementSoundType.epic:
        await HapticService.rareAchievementPattern();
        break;
      case AchievementSoundType.legendary:
        await HapticService.legendaryAchievementPattern();
        break;
    }
  }

  /// Helper per haptic workout
  Future<void> _triggerHapticForWorkout(WorkoutSoundType type) async {
    switch (type) {
      case WorkoutSoundType.countdown:
        // Haptic gestito separatamente nel countdown
        break;
      case WorkoutSoundType.repComplete:
        await HapticService.repCompletePattern();
        break;
      case WorkoutSoundType.setComplete:
        await HapticService.setCompletePattern();
        break;
      case WorkoutSoundType.exerciseComplete:
        await HapticService.celebrationPattern();
        break;
      case WorkoutSoundType.workoutComplete:
        await HapticService.workoutCompletePattern();
        break;
      case WorkoutSoundType.personalRecord:
        await HapticService.personalRecordPattern();
        break;
      case WorkoutSoundType.restStart:
        await HapticService.lightTap();
        break;
      case WorkoutSoundType.restEnd:
        await HapticService.mediumTap();
        break;
    }
  }
}
