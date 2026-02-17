import 'package:flutter/foundation.dart';
import '../models/quota_status_model.dart';
import 'api_client.dart';

/// Service per gestione quote utente basate su subscription tier
class QuotaService {
  final ApiClient _apiClient;

  QuotaService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Ottiene lo stato completo delle quote utente
  Future<QuotaStatus> getQuotaStatus() async {
    try {
      final response = await _apiClient.get('/quota/status');

      if (response['success'] == true) {
        return QuotaStatus.fromJson(response);
      }

      throw Exception('Failed to get quota status');
    } catch (e) {
      debugPrint('QuotaService.getQuotaStatus error: $e');
      rethrow;
    }
  }

  /// Verifica se un'azione specifica può essere eseguita
  Future<QuotaCheckResult> canPerformAction(QuotaAction action) async {
    try {
      final response = await _apiClient.post(
        '/quota/check',
        body: {'action': action.value},
      );

      return QuotaCheckResult.fromJson(response);
    } catch (e) {
      debugPrint('QuotaService.canPerformAction error: $e');
      // In caso di errore, permettiamo l'azione (fail-open)
      return QuotaCheckResult(
        canPerform: true,
        reason: '',
        upgradeNeeded: false,
        subscriptionTier: 'free',
      );
    }
  }

  /// Registra l'utilizzo di una quota
  Future<bool> recordUsage(QuotaAction action) async {
    try {
      final response = await _apiClient.post(
        '/quota/record',
        body: {'action': action.value},
      );

      return response['success'] == true;
    } catch (e) {
      debugPrint('QuotaService.recordUsage error: $e');
      return false;
    }
  }

  /// Helper: verifica e registra in un'unica chiamata
  Future<QuotaCheckResult> checkAndRecord(QuotaAction action) async {
    final checkResult = await canPerformAction(action);

    if (checkResult.canPerform) {
      await recordUsage(action);
    }

    return checkResult;
  }
}

/// Tipi di azioni quotate
enum QuotaAction {
  formAnalysis('form_analysis'),
  mealAnalysis('meal_analysis'),
  recipes('recipes'), // Maps to Chef AI
  customWorkout('custom_workout'),
  workoutPlan('workout_plan'),
  executeWithGigi('execute_with_gigi'),
  shoppingList('shopping_list'),
  changeMeal('change_meal'),
  changeFood('change_food');

  final String value;
  const QuotaAction(this.value);
}

/// Risultato controllo quota
class QuotaCheckResult {
  final bool canPerform;
  final String reason;
  final bool upgradeNeeded;
  final String subscriptionTier;

  QuotaCheckResult({
    required this.canPerform,
    required this.reason,
    required this.upgradeNeeded,
    required this.subscriptionTier,
  });

  factory QuotaCheckResult.fromJson(Map<String, dynamic> json) {
    return QuotaCheckResult(
      canPerform: json['can_perform'] ?? false,
      reason: json['reason'] ?? '',
      upgradeNeeded: json['upgrade_needed'] ?? false,
      subscriptionTier: json['subscription_tier'] ?? 'free',
    );
  }
}
