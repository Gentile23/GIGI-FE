import 'package:flutter/foundation.dart';

import '../data/models/quota_status_model.dart';
import '../data/services/api_client.dart';
import '../data/services/quota_service.dart';

class QuotaProvider extends ChangeNotifier {
  final QuotaService _service;

  QuotaStatus? _status;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastLoadedAt;

  QuotaProvider([ApiClient? apiClient])
    : _service = QuotaService(apiClient: apiClient);

  @visibleForTesting
  QuotaProvider.withService(QuotaService service) : _service = service;

  QuotaStatus? get status => _status;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastLoadedAt => _lastLoadedAt;
  bool get hasStatus => _status != null;

  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      _status = await _service.getQuotaStatus();
      _error = null;
      _lastLoadedAt = DateTime.now();
    } catch (e) {
      _error = e.toString();
      debugPrint('QuotaProvider.refresh error: $e');
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<QuotaCheckResult> canPerform(QuotaAction action) async {
    final result = await _service.canPerformAction(action);
    if (!result.canPerform) {
      await refresh(silent: true);
    }
    return result;
  }

  Future<void> syncAfterSuccess(QuotaAction action) async {
    optimisticConsume(action);
    await refresh(silent: true);
  }

  void optimisticConsume(QuotaAction action) {
    final current = _status;
    if (current == null) return;

    final usage = usageFor(action);
    if (usage == null || usage.isUnlimited) return;

    final used = usage.used + 1;
    final remaining = (usage.remaining - 1).clamp(0, usage.limit);
    final nextUsage = usage.copyWith(
      used: used,
      remaining: remaining,
      canUse: used < usage.limit,
    );

    _status = current.copyWith(
      usage: _replaceUsage(current.usage, action, nextUsage),
    );
    notifyListeners();
  }

  QuotaUsage? usageFor(QuotaAction action) {
    final usage = _status?.usage;
    if (usage == null) return null;

    return switch (action) {
      QuotaAction.formAnalysis => usage.formAnalysis,
      QuotaAction.mealAnalysis => usage.mealAnalysis,
      QuotaAction.recipes => usage.recipes,
      QuotaAction.customWorkout => usage.customWorkouts,
      QuotaAction.executeWithGigi => usage.executeWithGigi,
      QuotaAction.shoppingList => usage.shoppingList,
      QuotaAction.changeMeal => usage.changeMeal,
      QuotaAction.changeFood => usage.changeFood,
      QuotaAction.foodDuel => usage.foodDuel,
      QuotaAction.pdfDiet => usage.pdfDiet,
      QuotaAction.workoutChat => usage.workoutChat,
      QuotaAction.exerciseAlternatives => usage.exerciseAlternatives,
      QuotaAction.similarExercises => usage.similarExercises,
      QuotaAction.workoutPlan => null,
    };
  }

  WorkoutPlanQuota? get workoutPlanUsage => _status?.usage.workoutPlan;

  bool canUseCached(QuotaAction action) {
    if (action == QuotaAction.workoutPlan) {
      return workoutPlanUsage?.canUse ?? false;
    }
    return usageFor(action)?.canUse ?? false;
  }

  String displayUsageFor(QuotaAction action) {
    if (action == QuotaAction.workoutPlan) {
      final workoutPlan = workoutPlanUsage;
      if (workoutPlan == null) return '';
      if (workoutPlan.isUnlimited) return 'Illimitato';
      if (workoutPlan.canUse) return 'Disponibile ${workoutPlan.periodLabel}';
      return 'Disponibile tra ${workoutPlan.daysUntilNext} giorni';
    }

    final usage = usageFor(action);
    if (usage == null) return '';
    if (usage.isUnlimited) return 'Illimitato';
    return '${usage.remaining}/${usage.limit} rimasti ${usage.periodLabel}';
  }

  QuotaUsageDetails _replaceUsage(
    QuotaUsageDetails usage,
    QuotaAction action,
    QuotaUsage nextUsage,
  ) {
    return switch (action) {
      QuotaAction.formAnalysis => usage.copyWith(formAnalysis: nextUsage),
      QuotaAction.mealAnalysis => usage.copyWith(mealAnalysis: nextUsage),
      QuotaAction.recipes => usage.copyWith(recipes: nextUsage),
      QuotaAction.customWorkout => usage.copyWith(customWorkouts: nextUsage),
      QuotaAction.executeWithGigi => usage.copyWith(executeWithGigi: nextUsage),
      QuotaAction.shoppingList => usage.copyWith(shoppingList: nextUsage),
      QuotaAction.changeMeal => usage.copyWith(changeMeal: nextUsage),
      QuotaAction.changeFood => usage.copyWith(changeFood: nextUsage),
      QuotaAction.foodDuel => usage.copyWith(foodDuel: nextUsage),
      QuotaAction.pdfDiet => usage.copyWith(pdfDiet: nextUsage),
      QuotaAction.workoutChat => usage.copyWith(workoutChat: nextUsage),
      QuotaAction.exerciseAlternatives => usage.copyWith(
        exerciseAlternatives: nextUsage,
      ),
      QuotaAction.similarExercises => usage.copyWith(
        similarExercises: nextUsage,
      ),
      QuotaAction.workoutPlan => usage,
    };
  }
}
