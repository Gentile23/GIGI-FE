import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

/// Service per gestire il feedback aptico dell'applicazione
/// Basato su principi di UX neuroscientifica per massimizzare l'engagement
class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  bool _isEnabled = true;

  /// Abilita/Disabilita il feedback aptico
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Tap leggero - per interazioni UI secondarie
  static Future<void> lightTap() async {
    if (!HapticService()._isEnabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Tap medio - per conferme e selezioni
  static Future<void> mediumTap() async {
    if (!HapticService()._isEnabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Tap pesante - per azioni importanti
  static Future<void> heavyTap() async {
    if (!HapticService()._isEnabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Vibrazione di selezione - per toggle e checkbox
  static Future<void> selectionClick() async {
    if (!HapticService()._isEnabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Pattern celebrativo per achievement unlock
  /// Sequenza: Heavy -> pause -> Medium -> pause -> Light
  static Future<void> celebrationPattern() async {
    if (!HapticService()._isEnabled) return;

    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Pattern per level up - più intenso della celebrazione
  static Future<void> levelUpPattern() async {
    if (!HapticService()._isEnabled) return;

    // Sequenza crescente
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));

    // Burst finale
    for (int i = 0; i < 3; i++) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Pattern per streak milestone
  /// Numero di impulsi proporzionale alla streak (max 7)
  static Future<void> streakMilestonePattern(int streak) async {
    if (!HapticService()._isEnabled) return;

    final pulses = min(streak, 7);
    for (int i = 0; i < pulses; i++) {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 80));
    }
    // Finale pesante
    await HapticFeedback.heavyImpact();
  }

  /// Pattern per personal record
  static Future<void> personalRecordPattern() async {
    if (!HapticService()._isEnabled) return;

    // Pattern "esplosivo"
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));

    // Ripple effect
    for (int i = 0; i < 4; i++) {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 60));
    }
  }

  /// Pattern per workout completato
  static Future<void> workoutCompletePattern() async {
    if (!HapticService()._isEnabled) return;

    // Build up
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 40));

    // Climax
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.heavyImpact();
  }

  /// Pattern per rep completata
  static Future<void> repCompletePattern() async {
    if (!HapticService()._isEnabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Pattern per set completato
  static Future<void> setCompletePattern() async {
    if (!HapticService()._isEnabled) return;

    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Pattern per errore/warning
  static Future<void> errorPattern() async {
    if (!HapticService()._isEnabled) return;

    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  /// Pattern per notifica importante
  static Future<void> notificationPattern() async {
    if (!HapticService()._isEnabled) return;

    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    await HapticFeedback.lightImpact();
  }

  /// Pattern per countdown (3-2-1)
  static Future<void> countdownPattern() async {
    if (!HapticService()._isEnabled) return;

    // 3
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(seconds: 1));
    // 2
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(seconds: 1));
    // 1
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(seconds: 1));
    // GO!
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  /// Pattern per XP guadagnati
  static Future<void> xpGainPattern(int xpAmount) async {
    if (!HapticService()._isEnabled) return;

    // Più XP = più impulsi
    final pulses = min((xpAmount / 25).ceil(), 5);
    for (int i = 0; i < pulses; i++) {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  /// Pattern per achievement raro sbloccato
  static Future<void> rareAchievementPattern() async {
    if (!HapticService()._isEnabled) return;

    // Dramatic pause then explosion
    await Future.delayed(const Duration(milliseconds: 300));

    // Triple heavy
    for (int i = 0; i < 3; i++) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 80));
    }

    // Shimmer effect
    for (int i = 0; i < 5; i++) {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 40));
    }
  }

  /// Pattern per achievement leggendario
  static Future<void> legendaryAchievementPattern() async {
    if (!HapticService()._isEnabled) return;

    // Build anticipation
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));

    // EXPLOSION
    for (int i = 0; i < 5; i++) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Echo
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 300));
    await HapticFeedback.lightImpact();
  }
}
