/// Subscription Tier Enumeration
/// 3 tiers: Free (hook) → Pro (main conversion) → Elite (power users)
enum SubscriptionTier { free, pro, elite }

/// ══════════════════════════════════════════════════════════════════════════
/// SUBSCRIPTION QUOTAS
/// Definisce i limiti per ogni tier
/// ══════════════════════════════════════════════════════════════════════════

class SubscriptionQuotas {
  // ─── WORKOUT PLANS ───────────────────────────────────────────────────────
  /// Numero di settimane tra ogni generazione piano AI
  final int workoutPlanIntervalWeeks;

  // ─── FORM ANALYSIS ───────────────────────────────────────────────────────
  /// Numero di form analysis AI per settimana (-1 = illimitato)
  final int formAnalysisPerWeek;

  // ─── NUTRITION ───────────────────────────────────────────────────────────
  /// Numero di analisi pasto per settimana (-1 = illimitato)
  final int mealAnalysisLimit;

  /// Numero di ricette AI per settimana (-1 = illimitato)
  final int recipesPerWeek;

  // ─── VOICE COACHING ──────────────────────────────────────────────────────
  /// Voice coaching disponibile nei workout
  final bool voiceCoachingEnabled;

  // ─── CUSTOM WORKOUTS ─────────────────────────────────────────────────────
  /// Numero di workout custom per periodo (-1 = illimitato)
  final int customWorkoutsPerPeriod;

  /// Periodo in settimane per i workout custom (0 = no limit)
  final int customWorkoutsPeriodWeeks;

  // ─── NEW FEATURES ────────────────────────────────────────────────────────
  /// Numero di sessioni "Execute with GiGi" a settimana
  final int executeWithGigiPerWeek;

  /// Limite creazione lista spesa (1 = una tantum, -1 = illimitato)
  final int shoppingListLimit;

  /// Cambio pasto a settimana
  final int changeMealPerWeek;

  /// Cambio singolo alimento a settimana
  final int changeFoodItemPerWeek;

  const SubscriptionQuotas({
    required this.workoutPlanIntervalWeeks,
    required this.formAnalysisPerWeek,
    required this.mealAnalysisLimit,
    required this.recipesPerWeek,
    required this.voiceCoachingEnabled,
    required this.customWorkoutsPerPeriod,
    required this.customWorkoutsPeriodWeeks,
    required this.executeWithGigiPerWeek,
    required this.shoppingListLimit,
    required this.changeMealPerWeek,
    required this.changeFoodItemPerWeek,
  });

  /// FREE: Quota generose per hook, ma con limiti che creano desiderio di upgrade
  static const SubscriptionQuotas free = SubscriptionQuotas(
    workoutPlanIntervalWeeks: 8, // 1 piano ogni 8 settimane
    formAnalysisPerWeek: 2, // 2 form check a settimana
    mealAnalysisLimit: 1, // 1 analisi pasto a settimana
    recipesPerWeek: 2, // 2 ricette a settimana
    voiceCoachingEnabled: false, // Solo nel trial
    customWorkoutsPerPeriod: 3, // 3 workout custom
    customWorkoutsPeriodWeeks: 8, // ogni 8 settimane
    executeWithGigiPerWeek: 2,
    shoppingListLimit: 1, // Una tantum
    changeMealPerWeek: 1,
    changeFoodItemPerWeek: 1,
  );

  /// PRO: Limiti generosi che soddisfano la maggior parte degli utenti
  static const SubscriptionQuotas pro = SubscriptionQuotas(
    workoutPlanIntervalWeeks: 2, // Piano ogni 2 settimane
    formAnalysisPerWeek: 20, // 20 form check a settimana
    mealAnalysisLimit: 20, // 20 analisi pasto a settimana
    recipesPerWeek: 20, // 20 ricette a settimana
    voiceCoachingEnabled: true, // Voice coaching attivo
    customWorkoutsPerPeriod: 5, // 5 workout custom
    customWorkoutsPeriodWeeks: 1, // a settimana
    executeWithGigiPerWeek: -1, // Illimitato
    shoppingListLimit: -1, // Illimitato
    changeMealPerWeek: -1, // Illimitato
    changeFoodItemPerWeek: -1, // Illimitato
  );

  /// ELITE: Tutto illimitato per power users
  static const SubscriptionQuotas elite = SubscriptionQuotas(
    workoutPlanIntervalWeeks: 0, // Illimitato (0 = no wait)
    formAnalysisPerWeek: -1, // Illimitato
    mealAnalysisLimit: -1, // Illimitato
    recipesPerWeek: -1, // Illimitato
    voiceCoachingEnabled: true, // Voice coaching attivo
    customWorkoutsPerPeriod: -1, // Illimitato
    customWorkoutsPeriodWeeks: 0, // N/A
    executeWithGigiPerWeek: -1, // Illimitato
    shoppingListLimit: -1, // Illimitato
    changeMealPerWeek: -1, // Illimitato
    changeFoodItemPerWeek: -1, // Illimitato
  );
}

/// ══════════════════════════════════════════════════════════════════════════
/// SUBSCRIPTION TIER CONFIG
/// Configurazione completa di ogni tier con pricing e features
/// ══════════════════════════════════════════════════════════════════════════

class SubscriptionTierConfig {
  final SubscriptionTier tier;
  final String name;
  final String tagline;
  final double priceMonthly;
  final double priceYearly;
  final List<String> features;
  final List<String> restrictions;
  final SubscriptionQuotas quotas;

  const SubscriptionTierConfig({
    required this.tier,
    required this.name,
    required this.tagline,
    required this.priceMonthly,
    required this.priceYearly,
    required this.features,
    required this.restrictions,
    required this.quotas,
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TIER DEFINITIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// ─── FREE ───────────────────────────────────────────────────────────────
  /// Hook per acquisizione utenti con feature limitate ma utilizzabili
  /// Strategia: far provare il valore, creare desiderio di upgrade
  static const SubscriptionTierConfig free = SubscriptionTierConfig(
    tier: SubscriptionTier.free,
    name: 'Free',
    tagline: 'Inizia il tuo percorso',
    priceMonthly: 0.0,
    priceYearly: 0.0,
    features: [
      'Piano AI ogni 8 settimane',
      '2 Form Analysis AI/settimana',
      '1 Analisi pasto/settimana',
      '1 Ricetta AI/settimana',
      'Libreria 500+ esercizi',
      'Tracking workouts',
      'Gamification (XP, livelli)',
      'Community e Leaderboard',
    ],
    restrictions: [
      'No Voice Coaching',
      'Max 3 workout custom',
      'Statistiche base',
    ],
    quotas: SubscriptionQuotas.free,
  );

  /// ─── PRO ────────────────────────────────────────────────────────────────
  /// Piano di conversione principale - €14.99/mese
  /// Prezzo giustificato dal valore PT digitale reale
  /// Target: utenti che si allenano 3-5 volte a settimana
  static const SubscriptionTierConfig pro = SubscriptionTierConfig(
    tier: SubscriptionTier.pro,
    name: 'Pro',
    tagline: 'Il tuo Coach AI sempre con te',
    priceMonthly: 14.99,
    priceYearly: 99.99, // €8.33/mese - risparmio 44%
    features: [
      'Coaching vocale in OGNI allenamento',
      'Form Check AI (10/settimana)',
      'Piano che si adatta ai tuoi progressi',
      'Nutrizione AI personalizzata',
      'Analytics e progressi dettagliati',
    ],
    restrictions: ['Limiti settimanali sulle AI'],
    quotas: SubscriptionQuotas.pro,
  );

  /// ─── ELITE ──────────────────────────────────────────────────────────────
  /// Massimo valore per power users - €29.99/mese
  /// Tutto illimitato + funzionalità esclusive
  /// Target: atleti seri, personal trainer, fitness influencer
  static const SubscriptionTierConfig elite = SubscriptionTierConfig(
    tier: SubscriptionTier.elite,
    name: 'Elite',
    tagline: 'Come avere un PT digitale',
    priceMonthly: 29.99,
    priceYearly: 199.99, // €16.67/mese - risparmio 44%
    features: [
      'Tutto ILLIMITATO',
      'Form Check AI senza limiti',
      'Coaching prioritario',
      'Report settimanali email',
      'Badge esclusivi',
      'Supporto prioritario 24/7',
    ],
    restrictions: [],
    quotas: SubscriptionQuotas.elite,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  static List<SubscriptionTierConfig> get allTiers => [free, pro, elite];

  static SubscriptionTierConfig fromTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return free;
      case SubscriptionTier.pro:
        return pro;
      case SubscriptionTier.elite:
        return elite;
    }
  }

  /// Risparmio annuale in percentuale
  int get yearlySavingsPercent {
    if (priceMonthly == 0) return 0;
    final monthlyTotal = priceMonthly * 12;
    return ((1 - priceYearly / monthlyTotal) * 100).round();
  }

  /// Prezzo mensile effettivo con abbonamento annuale
  double get effectiveMonthlyPrice => priceYearly / 12;

  /// Verifica disponibilità feature
  bool hasFeature(String feature) {
    switch (feature) {
      case 'voice_coach':
        return quotas.voiceCoachingEnabled;
      case 'form_analysis':
        return quotas.formAnalysisPerWeek != 0;
      case 'unlimited_form_analysis':
        return quotas.formAnalysisPerWeek == -1;
      case 'nutrition':
        return quotas.mealAnalysisLimit != 0;
      case 'unlimited_nutrition':
        return quotas.mealAnalysisLimit == -1;
      case 'recipes':
        return quotas.recipesPerWeek != 0;
      case 'unlimited_recipes':
        return quotas.recipesPerWeek == -1;
      case 'unlimited_plans':
        return quotas.workoutPlanIntervalWeeks == 0;
      case 'custom_workouts':
        return quotas.customWorkoutsPerPeriod != 0;
      case 'unlimited_custom_workouts':
        return quotas.customWorkoutsPerPeriod == -1;
      case 'weekly_reports':
        return tier == SubscriptionTier.elite;
      case 'advanced_analytics':
        return tier != SubscriptionTier.free;
      case 'health_integrations':
        return tier == SubscriptionTier.elite;
      case 'priority_support':
        return tier == SubscriptionTier.elite;
      default:
        return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUOTA CHECK METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Verifica se l'utente può generare un nuovo piano workout
  bool canGenerateWorkoutPlan(DateTime? lastPlanGeneratedAt) {
    if (quotas.workoutPlanIntervalWeeks == 0) return true; // Elite: illimitato
    if (lastPlanGeneratedAt == null) return true;

    final daysSinceLastPlan = DateTime.now()
        .difference(lastPlanGeneratedAt)
        .inDays;
    final requiredDays = quotas.workoutPlanIntervalWeeks * 7;
    return daysSinceLastPlan >= requiredDays;
  }

  /// Giorni rimanenti prima di poter generare un nuovo piano
  int daysUntilNextPlan(DateTime? lastPlanGeneratedAt) {
    if (quotas.workoutPlanIntervalWeeks == 0) return 0;
    if (lastPlanGeneratedAt == null) return 0;

    final daysSinceLastPlan = DateTime.now()
        .difference(lastPlanGeneratedAt)
        .inDays;
    final requiredDays = quotas.workoutPlanIntervalWeeks * 7;
    final remaining = requiredDays - daysSinceLastPlan;
    return remaining > 0 ? remaining : 0;
  }

  /// Verifica se l'utente può fare un form analysis questa settimana
  bool canPerformFormAnalysis(int usedThisWeek) {
    if (quotas.formAnalysisPerWeek == -1) return true;
    if (quotas.formAnalysisPerWeek == 0) return false;
    return usedThisWeek < quotas.formAnalysisPerWeek;
  }

  /// Verifica se l'utente può analizzare un pasto questa settimana
  bool canAnalyzeMeal(int usedThisWeek) {
    if (quotas.mealAnalysisLimit == -1) return true;
    if (quotas.mealAnalysisLimit == 0) return false;
    return usedThisWeek < quotas.mealAnalysisLimit;
  }

  /// Verifica se l'utente può ottenere una ricetta questa settimana
  bool canGetRecipe(int usedThisWeek) {
    if (quotas.recipesPerWeek == -1) return true;
    if (quotas.recipesPerWeek == 0) return false;
    return usedThisWeek < quotas.recipesPerWeek;
  }

  /// Verifica se l'utente può creare un workout custom nel periodo
  bool canCreateCustomWorkout(int usedThisPeriod) {
    if (quotas.customWorkoutsPerPeriod == -1) return true;
    if (quotas.customWorkoutsPerPeriod == 0) return false;
    return usedThisPeriod < quotas.customWorkoutsPerPeriod;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DISPLAY HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Formatta la quota per la visualizzazione
  String formatQuota(int quota, String unit) {
    if (quota == -1) return 'Illimitato';
    if (quota == 0) return 'Non disponibile';
    return '$quota $unit';
  }

  /// Ottiene la stringa per il piano workout
  String get workoutPlanQuotaDisplay {
    if (quotas.workoutPlanIntervalWeeks == 0) return 'Illimitato';
    return 'Ogni ${quotas.workoutPlanIntervalWeeks} settimane';
  }

  /// Ottiene la stringa per form analysis
  String get formAnalysisQuotaDisplay {
    return formatQuota(quotas.formAnalysisPerWeek, '/settimana');
  }

  /// Ottiene la stringa per analisi pasto
  String get mealAnalysisQuotaDisplay {
    return formatQuota(quotas.mealAnalysisLimit, '/settimana');
  }

  /// Ottiene la stringa per ricette
  String get recipesQuotaDisplay {
    return formatQuota(quotas.recipesPerWeek, '/settimana');
  }
}
