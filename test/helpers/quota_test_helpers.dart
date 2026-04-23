import 'package:gigi/data/models/quota_status_model.dart';
import 'package:gigi/data/services/quota_service.dart';

class FakeQuotaService extends QuotaService {
  FakeQuotaService({required List<QuotaStatus> statuses, this.checkResult})
    : _statuses = List.of(statuses),
      super();

  final List<QuotaStatus> _statuses;
  final QuotaCheckResult? checkResult;
  int statusCalls = 0;
  int checkCalls = 0;

  @override
  Future<QuotaStatus> getQuotaStatus() async {
    statusCalls += 1;
    if (_statuses.length > 1) {
      return _statuses.removeAt(0);
    }
    return _statuses.first;
  }

  @override
  Future<QuotaCheckResult> canPerformAction(QuotaAction action) async {
    checkCalls += 1;
    return checkResult ??
        QuotaCheckResult(
          canPerform: true,
          reason: '',
          upgradeNeeded: false,
          subscriptionTier: 'free',
        );
  }
}

QuotaStatus quotaStatus({
  QuotaUsage? formAnalysis,
  QuotaUsage? recipes,
  QuotaUsage? foodDuel,
}) {
  return QuotaStatus(
    subscriptionTier: 'free',
    limits: const {},
    planLimitsByTier: const {},
    features: QuotaFeatures(voiceCoaching: false),
    usage: QuotaUsageDetails(
      formAnalysis:
          formAnalysis ??
          quotaUsage(action: 'form_analysis', label: 'Form Check AI'),
      mealAnalysis: quotaUsage(
        action: 'meal_analysis',
        label: 'Snap & Track AI',
      ),
      recipes: recipes ?? quotaUsage(action: 'recipes', label: 'Chef AI'),
      customWorkouts: quotaUsage(
        action: 'custom_workout',
        label: 'Workout custom',
      ),
      workoutPlan: WorkoutPlanQuota(
        action: 'workout_plan',
        label: 'Piano workout',
        canGenerate: true,
        canUse: true,
        daysUntilNext: 0,
        intervalWeeks: 0,
        limit: -1,
        period: 'unlimited',
        periodLabel: 'illimitato',
      ),
      executeWithGigi: quotaUsage(action: 'execute_with_gigi'),
      shoppingList: quotaUsage(action: 'shopping_list'),
      changeMeal: quotaUsage(action: 'change_meal'),
      changeFood: quotaUsage(action: 'change_food'),
      foodDuel:
          foodDuel ?? quotaUsage(action: 'food_duel', label: 'Food Duel AI'),
      pdfDiet: quotaUsage(action: 'pdf_diet'),
      workoutChat: quotaUsage(action: 'workout_chat'),
      exerciseAlternatives: quotaUsage(action: 'exercise_alternatives'),
      similarExercises: quotaUsage(action: 'similar_exercises'),
    ),
  );
}

QuotaUsage quotaUsage({
  required String action,
  String label = '',
  int used = 0,
  int limit = 4,
  int remaining = 4,
  bool? canUse,
  String period = 'week',
  String periodLabel = 'a settimana',
}) {
  return QuotaUsage(
    action: action,
    label: label,
    used: used,
    limit: limit,
    remaining: remaining,
    canUse: canUse ?? remaining != 0 || limit == -1,
    period: period,
    periodLabel: periodLabel,
  );
}
