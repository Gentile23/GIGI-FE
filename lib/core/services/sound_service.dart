import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// ═══════════════════════════════════════════════════════════
/// SOUND SERVICE - Audio feedback for gamification
/// ═══════════════════════════════════════════════════════════

enum SoundType {
  // Positive feedback
  xpGain,
  levelUp,
  achievementUnlock,
  badgeEarned,
  streakContinue,
  workoutComplete,

  // Rewards
  chestBronze,
  chestSilver,
  chestGold,
  chestLegendary,
  rewardClaim,

  // Interactions
  buttonTap,
  toggle,
  swipe,

  // Warnings
  streakWarning,
  error,

  // Challenges
  challengeStart,
  challengeComplete,
  challengeFailed,

  // Workout Timer
  timerTick,
  timerComplete,
  setComplete,
}

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isEnabled = true;
  double _volume = 0.7;

  bool get isEnabled => _isEnabled;
  double get volume => _volume;

  /// Initialize sound service
  Future<void> initialize() async {
    // Preload frequently used sounds
    // In production, you'd cache these
    debugPrint('SoundService initialized');
  }

  /// Play a sound effect
  Future<void> play(SoundType type) async {
    if (!_isEnabled) return;

    try {
      final assetPath = _getAssetPath(type);
      await _player.setVolume(_volume);
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('Failed to play sound: $e');
    }
  }

  /// Play XP gain sound with variable pitch based on amount
  Future<void> playXpGain(int amount) async {
    if (!_isEnabled) return;

    try {
      // Higher XP = higher pitch excitement
      final rate = 1.0 + (amount / 1000).clamp(0, 0.5);
      await _player.setPlaybackRate(rate);
      await play(SoundType.xpGain);
      await _player.setPlaybackRate(1.0);
    } catch (e) {
      debugPrint('Failed to play XP sound: $e');
    }
  }

  /// Play chest opening sequence
  Future<void> playChestOpening(ChestRaritySound rarity) async {
    if (!_isEnabled) return;

    try {
      // Build-up sound
      await play(SoundType.toggle);
      await Future.delayed(const Duration(milliseconds: 300));

      // Opening sound based on rarity
      switch (rarity) {
        case ChestRaritySound.bronze:
          await play(SoundType.chestBronze);
          break;
        case ChestRaritySound.silver:
          await play(SoundType.chestSilver);
          break;
        case ChestRaritySound.gold:
          await play(SoundType.chestGold);
          break;
        case ChestRaritySound.legendary:
          await play(SoundType.chestLegendary);
          break;
      }
    } catch (e) {
      debugPrint('Failed to play chest sound: $e');
    }
  }

  /// Play level up celebration
  Future<void> playLevelUp(int newLevel) async {
    if (!_isEnabled) return;

    try {
      // Special sound for milestone levels
      if (newLevel % 10 == 0) {
        // Milestone level (10, 20, 30...)
        await _player.setVolume(_volume * 1.2);
        await play(SoundType.levelUp);
        await Future.delayed(const Duration(milliseconds: 500));
        await play(SoundType.achievementUnlock);
        await _player.setVolume(_volume);
      } else {
        await play(SoundType.levelUp);
      }
    } catch (e) {
      debugPrint('Failed to play level up sound: $e');
    }
  }

  /// Enable/disable sounds
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Set volume (0.0 to 1.0)
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
  }

  /// Get asset path for sound type
  /// Mapped to actual audio files: success, notification, toggle_on, swipe, tap_heavy, tap_light
  String _getAssetPath(SoundType type) {
    switch (type) {
      // Positive feedback - use "success" sound
      case SoundType.xpGain:
        return 'sounds/tap_light.wav';
      case SoundType.levelUp:
        return 'sounds/success.wav';
      case SoundType.achievementUnlock:
        return 'sounds/success.wav';
      case SoundType.badgeEarned:
        return 'sounds/success.wav';
      case SoundType.streakContinue:
        return 'sounds/success.wav';
      case SoundType.workoutComplete:
        return 'sounds/success.wav';

      // Rewards - use "success" with variations
      case SoundType.chestBronze:
        return 'sounds/tap_heavy.wav';
      case SoundType.chestSilver:
        return 'sounds/tap_heavy.wav';
      case SoundType.chestGold:
        return 'sounds/success.wav';
      case SoundType.chestLegendary:
        return 'sounds/success.wav';
      case SoundType.rewardClaim:
        return 'sounds/success.wav';

      // Interactions
      case SoundType.buttonTap:
        return 'sounds/tap_light.wav';
      case SoundType.toggle:
        return 'sounds/toggle_on.wav';
      case SoundType.swipe:
        return 'sounds/swipe.wav';

      // Warnings - use "notification" sound
      case SoundType.streakWarning:
        return 'sounds/notification.wav';
      case SoundType.error:
        return 'sounds/notification.wav';

      // Challenges
      case SoundType.challengeStart:
        return 'sounds/notification.wav';
      case SoundType.challengeComplete:
        return 'sounds/success.wav';
      case SoundType.challengeFailed:
        return 'sounds/notification.wav';

      // Workout Timer
      case SoundType.timerTick:
        return 'sounds/secondi.mp3';
      case SoundType.timerComplete:
        return 'sounds/tempo-finito.mp3';
      case SoundType.setComplete:
        return 'sounds/success.wav';
    }
  }

  /// Dispose resources
  void dispose() {
    _player.dispose();
  }
}

enum ChestRaritySound { bronze, silver, gold, legendary }

/// ═══════════════════════════════════════════════════════════
/// HAPTIC SERVICE EXTENSION
/// Enhanced haptic patterns for gamification
/// ═══════════════════════════════════════════════════════════

class EnhancedHapticService {
  // Import from existing haptic_service.dart and add these patterns:

  /// XP gain haptic - light tap
  static Future<void> xpGain() async {
    // HapticFeedback.lightImpact();
  }

  /// Level up haptic - success pattern
  static Future<void> levelUp() async {
    // Triple tap pattern: ta-da-da!
    // HapticFeedback.heavyImpact();
    // await Future.delayed(const Duration(milliseconds: 100));
    // HapticFeedback.mediumImpact();
    // await Future.delayed(const Duration(milliseconds: 100));
    // HapticFeedback.mediumImpact();
  }

  /// Achievement unlock - celebration pattern
  static Future<void> achievement() async {
    // Rising pattern
    // for (int i = 0; i < 3; i++) {
    //   HapticFeedback.selectionClick();
    //   await Future.delayed(Duration(milliseconds: 50 + i * 20));
    // }
    // HapticFeedback.heavyImpact();
  }

  /// Chest opening - building excitement
  static Future<void> chestOpening() async {
    // Build-up vibration
    // for (int i = 0; i < 5; i++) {
    //   HapticFeedback.lightImpact();
    //   await Future.delayed(Duration(milliseconds: 150 - i * 20));
    // }
    // HapticFeedback.heavyImpact();
  }

  /// Streak warning - attention pattern
  static Future<void> streakWarning() async {
    // Double warning buzz
    // HapticFeedback.mediumImpact();
    // await Future.delayed(const Duration(milliseconds: 200));
    // HapticFeedback.mediumImpact();
  }

  /// Workout complete - triumphant pattern
  static Future<void> workoutComplete() async {
    // Victory pattern
    // HapticFeedback.heavyImpact();
    // await Future.delayed(const Duration(milliseconds: 100));
    // HapticFeedback.lightImpact();
    // HapticFeedback.lightImpact();
    // await Future.delayed(const Duration(milliseconds: 50));
    // HapticFeedback.heavyImpact();
  }

  /// Error feedback
  static Future<void> error() async {
    // Sharp warning
    // HapticFeedback.heavyImpact();
  }

  /// Button press - standard
  static Future<void> buttonTap() async {
    // HapticFeedback.selectionClick();
  }
}
