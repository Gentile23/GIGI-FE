/// Model per lo stato completo delle quote utente
class QuotaStatus {
  final String subscriptionTier;
  final Map<String, int> limits;
  final QuotaUsageDetails usage;
  final QuotaFeatures features;

  QuotaStatus({
    required this.subscriptionTier,
    required this.limits,
    required this.usage,
    required this.features,
  });

  factory QuotaStatus.fromJson(Map<String, dynamic> json) {
    return QuotaStatus(
      subscriptionTier: json['subscription_tier'] ?? 'free',
      limits: Map<String, int>.from(json['limits'] ?? {}),
      usage: QuotaUsageDetails.fromJson(json['usage'] ?? {}),
      features: QuotaFeatures.fromJson(json['features'] ?? {}),
    );
  }

  bool get isFree => subscriptionTier == 'free';
  bool get isPro => subscriptionTier == 'pro';
  bool get isElite => subscriptionTier == 'elite';
  bool get isPremium => isPro || isElite;
}

/// Dettagli utilizzo per ogni tipo di quota
class QuotaUsageDetails {
  final QuotaUsage formAnalysis;
  final QuotaUsage mealAnalysis;
  final QuotaUsage recipes;
  final QuotaUsage customWorkouts;
  final WorkoutPlanQuota workoutPlan;

  QuotaUsageDetails({
    required this.formAnalysis,
    required this.mealAnalysis,
    required this.recipes,
    required this.customWorkouts,
    required this.workoutPlan,
  });

  factory QuotaUsageDetails.fromJson(Map<String, dynamic> json) {
    return QuotaUsageDetails(
      formAnalysis: QuotaUsage.fromJson(json['form_analysis'] ?? {}),
      mealAnalysis: QuotaUsage.fromJson(json['meal_analysis'] ?? {}),
      recipes: QuotaUsage.fromJson(json['recipes'] ?? {}),
      customWorkouts: QuotaUsage.fromJson(json['custom_workouts'] ?? {}),
      workoutPlan: WorkoutPlanQuota.fromJson(json['workout_plan'] ?? {}),
    );
  }
}

/// Utilizzo singola quota
class QuotaUsage {
  final int used;
  final int limit; // -1 = unlimited
  final int remaining; // -1 = unlimited
  final bool canUse;
  final String period;

  QuotaUsage({
    required this.used,
    required this.limit,
    required this.remaining,
    required this.canUse,
    required this.period,
  });

  factory QuotaUsage.fromJson(Map<String, dynamic> json) {
    return QuotaUsage(
      used: json['used'] ?? 0,
      limit: json['limit'] ?? 0,
      remaining: json['remaining'] ?? 0,
      canUse: json['can_use'] ?? false,
      period: json['period'] ?? '',
    );
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
}

/// Quota specifica per workout plan (basata su tempo, non conteggio)
class WorkoutPlanQuota {
  final bool canGenerate;
  final int daysUntilNext;
  final String? lastGeneratedAt;
  final int intervalWeeks;

  WorkoutPlanQuota({
    required this.canGenerate,
    required this.daysUntilNext,
    this.lastGeneratedAt,
    required this.intervalWeeks,
  });

  factory WorkoutPlanQuota.fromJson(Map<String, dynamic> json) {
    return WorkoutPlanQuota(
      canGenerate: json['can_generate'] ?? true,
      daysUntilNext: json['days_until_next'] ?? 0,
      lastGeneratedAt: json['last_generated_at'],
      intervalWeeks: json['interval_weeks'] ?? 0,
    );
  }

  bool get isUnlimited => intervalWeeks == 0;
}

/// Features disponibili per il tier
class QuotaFeatures {
  final bool voiceCoaching;

  QuotaFeatures({required this.voiceCoaching});

  factory QuotaFeatures.fromJson(Map<String, dynamic> json) {
    return QuotaFeatures(voiceCoaching: json['voice_coaching'] ?? false);
  }
}
