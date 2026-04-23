/// Model per lo stato completo delle quote utente
class QuotaStatus {
  final String subscriptionTier;
  final Map<String, dynamic> limits;
  final Map<String, Map<String, dynamic>> planLimitsByTier;
  final QuotaUsageDetails usage;
  final QuotaFeatures features;

  QuotaStatus({
    required this.subscriptionTier,
    required this.limits,
    required this.planLimitsByTier,
    required this.usage,
    required this.features,
  });

  factory QuotaStatus.fromJson(Map<String, dynamic> json) {
    return QuotaStatus(
      subscriptionTier: json['subscription_tier'] ?? 'free',
      limits: Map<String, dynamic>.from(json['limits'] ?? {}),
      planLimitsByTier: _parsePlanLimitsByTier(json['plan_limits']),
      usage: QuotaUsageDetails.fromJson(json['usage'] ?? {}),
      features: QuotaFeatures.fromJson(json['features'] ?? {}),
    );
  }

  static Map<String, Map<String, dynamic>> _parsePlanLimitsByTier(
    dynamic rawPlanLimits,
  ) {
    if (rawPlanLimits is! Map) return {};

    final parsed = <String, Map<String, dynamic>>{};
    rawPlanLimits.forEach((key, value) {
      if (key is String && value is Map) {
        parsed[key] = Map<String, dynamic>.from(value);
      }
    });

    return parsed;
  }

  Map<String, dynamic>? limitsForTier(String tier) => planLimitsByTier[tier];

  String get normalizedSubscriptionTier =>
      subscriptionTier == 'premium' ? 'pro' : subscriptionTier;

  bool get isFree => normalizedSubscriptionTier == 'free';
  bool get isPro => normalizedSubscriptionTier == 'pro';
  bool get isElite => normalizedSubscriptionTier == 'elite';
  bool get isPremium => isPro || isElite;

  QuotaStatus copyWith({
    String? subscriptionTier,
    Map<String, dynamic>? limits,
    Map<String, Map<String, dynamic>>? planLimitsByTier,
    QuotaUsageDetails? usage,
    QuotaFeatures? features,
  }) {
    return QuotaStatus(
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      limits: limits ?? this.limits,
      planLimitsByTier: planLimitsByTier ?? this.planLimitsByTier,
      usage: usage ?? this.usage,
      features: features ?? this.features,
    );
  }
}

/// Dettagli utilizzo per ogni tipo di quota
class QuotaUsageDetails {
  final QuotaUsage formAnalysis;
  final QuotaUsage mealAnalysis;
  final QuotaUsage recipes;
  final QuotaUsage customWorkouts;
  final WorkoutPlanQuota workoutPlan;
  // New quotas
  final QuotaUsage executeWithGigi;
  final QuotaUsage shoppingList;
  final QuotaUsage changeMeal;
  final QuotaUsage changeFood;
  final QuotaUsage foodDuel;
  final QuotaUsage pdfDiet;
  final QuotaUsage workoutChat;
  final QuotaUsage exerciseAlternatives;
  final QuotaUsage similarExercises;

  QuotaUsageDetails({
    required this.formAnalysis,
    required this.mealAnalysis,
    required this.recipes,
    required this.customWorkouts,
    required this.workoutPlan,
    required this.executeWithGigi,
    required this.shoppingList,
    required this.changeMeal,
    required this.changeFood,
    required this.foodDuel,
    required this.pdfDiet,
    required this.workoutChat,
    required this.exerciseAlternatives,
    required this.similarExercises,
  });

  factory QuotaUsageDetails.fromJson(Map<String, dynamic> json) {
    return QuotaUsageDetails(
      formAnalysis: QuotaUsage.fromJson(json['form_analysis'] ?? {}),
      mealAnalysis: QuotaUsage.fromJson(json['meal_analysis'] ?? {}),
      recipes: QuotaUsage.fromJson(json['recipes'] ?? {}),
      customWorkouts: QuotaUsage.fromJson(json['custom_workouts'] ?? {}),
      workoutPlan: WorkoutPlanQuota.fromJson(json['workout_plan'] ?? {}),
      executeWithGigi: QuotaUsage.fromJson(json['execute_with_gigi'] ?? {}),
      shoppingList: QuotaUsage.fromJson(json['shopping_list'] ?? {}),
      changeMeal: QuotaUsage.fromJson(json['change_meal'] ?? {}),
      changeFood: QuotaUsage.fromJson(json['change_food'] ?? {}),
      foodDuel: QuotaUsage.fromJson(json['food_duel'] ?? {}),
      pdfDiet: QuotaUsage.fromJson(json['pdf_diet'] ?? {}),
      workoutChat: QuotaUsage.fromJson(json['workout_chat'] ?? {}),
      exerciseAlternatives: QuotaUsage.fromJson(
        json['exercise_alternatives'] ?? {},
      ),
      similarExercises: QuotaUsage.fromJson(json['similar_exercises'] ?? {}),
    );
  }

  QuotaUsageDetails copyWith({
    QuotaUsage? formAnalysis,
    QuotaUsage? mealAnalysis,
    QuotaUsage? recipes,
    QuotaUsage? customWorkouts,
    WorkoutPlanQuota? workoutPlan,
    QuotaUsage? executeWithGigi,
    QuotaUsage? shoppingList,
    QuotaUsage? changeMeal,
    QuotaUsage? changeFood,
    QuotaUsage? foodDuel,
    QuotaUsage? pdfDiet,
    QuotaUsage? workoutChat,
    QuotaUsage? exerciseAlternatives,
    QuotaUsage? similarExercises,
  }) {
    return QuotaUsageDetails(
      formAnalysis: formAnalysis ?? this.formAnalysis,
      mealAnalysis: mealAnalysis ?? this.mealAnalysis,
      recipes: recipes ?? this.recipes,
      customWorkouts: customWorkouts ?? this.customWorkouts,
      workoutPlan: workoutPlan ?? this.workoutPlan,
      executeWithGigi: executeWithGigi ?? this.executeWithGigi,
      shoppingList: shoppingList ?? this.shoppingList,
      changeMeal: changeMeal ?? this.changeMeal,
      changeFood: changeFood ?? this.changeFood,
      foodDuel: foodDuel ?? this.foodDuel,
      pdfDiet: pdfDiet ?? this.pdfDiet,
      workoutChat: workoutChat ?? this.workoutChat,
      exerciseAlternatives: exerciseAlternatives ?? this.exerciseAlternatives,
      similarExercises: similarExercises ?? this.similarExercises,
    );
  }
}

/// Utilizzo singola quota
class QuotaUsage {
  final String action;
  final String label;
  final int used;
  final int limit; // -1 = unlimited
  final int remaining; // -1 = unlimited
  final bool canUse;
  final String period;
  final String periodLabel;

  QuotaUsage({
    required this.action,
    required this.label,
    required this.used,
    required this.limit,
    required this.remaining,
    required this.canUse,
    required this.period,
    required this.periodLabel,
  });

  factory QuotaUsage.fromJson(Map<String, dynamic> json) {
    return QuotaUsage(
      action: json['action'] ?? '',
      label: json['label'] ?? '',
      used: _toInt(json['used']),
      limit: _toInt(json['limit']),
      remaining: _toInt(json['remaining']),
      canUse: json['can_use'] ?? false,
      period: json['period'] ?? '',
      periodLabel: json['period_label'] ?? '',
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    // Handle edge case where boolean might be passed
    if (value is bool) return value ? 1 : 0;
    return 0;
  }

  bool get isUnlimited => limit == -1;

  String get displayRemaining {
    if (isUnlimited) return '∞';
    return remaining.toString();
  }

  String get displayUsage {
    if (isUnlimited) return '$used / ∞';
    return '$used / $limit';
  }

  QuotaUsage copyWith({
    String? action,
    String? label,
    int? used,
    int? limit,
    int? remaining,
    bool? canUse,
    String? period,
    String? periodLabel,
  }) {
    return QuotaUsage(
      action: action ?? this.action,
      label: label ?? this.label,
      used: used ?? this.used,
      limit: limit ?? this.limit,
      remaining: remaining ?? this.remaining,
      canUse: canUse ?? this.canUse,
      period: period ?? this.period,
      periodLabel: periodLabel ?? this.periodLabel,
    );
  }
}

/// Quota specifica per workout plan (basata su tempo, non conteggio)
class WorkoutPlanQuota {
  final String action;
  final String label;
  final bool canGenerate;
  final bool canUse;
  final int daysUntilNext;
  final String? lastGeneratedAt;
  final int intervalWeeks;
  final int limit;
  final String period;
  final String periodLabel;

  WorkoutPlanQuota({
    required this.action,
    required this.label,
    required this.canGenerate,
    required this.canUse,
    required this.daysUntilNext,
    this.lastGeneratedAt,
    required this.intervalWeeks,
    required this.limit,
    required this.period,
    required this.periodLabel,
  });

  factory WorkoutPlanQuota.fromJson(Map<String, dynamic> json) {
    return WorkoutPlanQuota(
      action: json['action'] ?? '',
      label: json['label'] ?? '',
      canGenerate: json['can_generate'] ?? true,
      canUse: json['can_use'] ?? json['can_generate'] ?? true,
      daysUntilNext: json['days_until_next'] ?? 0,
      lastGeneratedAt: json['last_generated_at'],
      intervalWeeks: json['interval_weeks'] ?? 0,
      limit: QuotaUsage._toInt(json['limit']),
      period: json['period'] ?? '',
      periodLabel: json['period_label'] ?? '',
    );
  }

  bool get isUnlimited => intervalWeeks == 0;

  WorkoutPlanQuota copyWith({
    String? action,
    String? label,
    bool? canGenerate,
    bool? canUse,
    int? daysUntilNext,
    String? lastGeneratedAt,
    int? intervalWeeks,
    int? limit,
    String? period,
    String? periodLabel,
  }) {
    return WorkoutPlanQuota(
      action: action ?? this.action,
      label: label ?? this.label,
      canGenerate: canGenerate ?? this.canGenerate,
      canUse: canUse ?? this.canUse,
      daysUntilNext: daysUntilNext ?? this.daysUntilNext,
      lastGeneratedAt: lastGeneratedAt ?? this.lastGeneratedAt,
      intervalWeeks: intervalWeeks ?? this.intervalWeeks,
      limit: limit ?? this.limit,
      period: period ?? this.period,
      periodLabel: periodLabel ?? this.periodLabel,
    );
  }
}

/// Features disponibili per il tier
class QuotaFeatures {
  final bool voiceCoaching;

  QuotaFeatures({required this.voiceCoaching});

  factory QuotaFeatures.fromJson(Map<String, dynamic> json) {
    return QuotaFeatures(voiceCoaching: json['voice_coaching'] ?? false);
  }
}
