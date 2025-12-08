/// Subscription Tier Enumeration
/// Simplified to 3 tiers for optimal conversion
enum SubscriptionTier { free, pro, elite }

/// Subscription Tier Features and Pricing
/// Pricing Strategy: Free (hook) → Pro €7.99 (main conversion) → Elite €14.99 (power users)
class SubscriptionTierConfig {
  final SubscriptionTier tier;
  final String name;
  final String tagline;
  final double priceMonthly; // in euros
  final double priceYearly; // in euros (with discount)
  final List<String> features;
  final List<String> restrictions;
  final int formAnalysisPerMonth; // -1 = unlimited

  const SubscriptionTierConfig({
    required this.tier,
    required this.name,
    required this.tagline,
    required this.priceMonthly,
    required this.priceYearly,
    required this.features,
    required this.restrictions,
    this.formAnalysisPerMonth = 0,
  });

  /// FREE - Hook per acquisizione utenti
  /// Trial workout una tantum → genera scheda AI ogni 3 mesi
  static const SubscriptionTierConfig free = SubscriptionTierConfig(
    tier: SubscriptionTier.free,
    name: 'Free',
    tagline: 'Inizia il tuo percorso',
    priceMonthly: 0.0,
    priceYearly: 0.0,
    features: [
      'Trial Workout con Voice Coaching',
      '1 Piano AI ogni 3 mesi',
      'Libreria esercizi completa',
      'Tracking workouts',
      'Gamification (XP, livelli, streak)',
      'Community e Leaderboard',
    ],
    restrictions: [
      'No Voice Coaching nei workout',
      'No Form Analysis AI',
      'No Nutrition Tracking',
      'Statistiche base',
    ],
    formAnalysisPerMonth: 0,
  );

  /// PRO - Piano di conversione principale
  /// Prezzo strategico sotto €10 per rimuovere barriera psicologica
  static const SubscriptionTierConfig pro = SubscriptionTierConfig(
    tier: SubscriptionTier.pro,
    name: 'Pro',
    tagline: 'Il tuo Personal Trainer AI',
    priceMonthly: 7.99,
    priceYearly: 59.99, // €5/mese - risparmio 37%
    features: [
      'Tutto il Free +',
      'Piani AI illimitati',
      'AI Voice Coaching in tutti i workout',
      '5 Form Analysis AI/mese',
      'Nutrition tracking (calorie e macro)',
      'Analytics avanzati',
      'Custom workouts illimitati',
      'Export dati',
    ],
    restrictions: ['Form Analysis limitata a 5/mese', 'Nutrition coach base'],
    formAnalysisPerMonth: 5,
  );

  /// ELITE - Massimo valore per power users
  /// Tutto illimitato + funzionalità esclusive
  static const SubscriptionTierConfig elite = SubscriptionTierConfig(
    tier: SubscriptionTier.elite,
    name: 'Elite',
    tagline: 'Performance Totale',
    priceMonthly: 14.99,
    priceYearly: 99.99, // €8.33/mese - risparmio 44%
    features: [
      'Tutto il Pro +',
      'Form Analysis AI illimitata',
      'AI Nutrition Coach completo',
      'Piani pasto personalizzati',
      'Report settimanali email',
      'Integrazioni salute',
      'Badge esclusivi profilo',
      'Supporto prioritario 24/7',
    ],
    restrictions: [],
    formAnalysisPerMonth: -1, // unlimited
  );

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

  /// Get yearly savings percentage
  int get yearlySavingsPercent {
    if (priceMonthly == 0) return 0;
    final monthlyTotal = priceMonthly * 12;
    return ((1 - priceYearly / monthlyTotal) * 100).round();
  }

  /// Get monthly price when paying yearly
  double get effectiveMonthlyPrice => priceYearly / 12;

  /// Check if a feature is available for this tier
  bool hasFeature(String feature) {
    // AI Voice Coach - Pro and Elite
    if (feature == 'voice_coach') {
      return tier == SubscriptionTier.pro || tier == SubscriptionTier.elite;
    }

    // Form Analysis - Pro (limited) and Elite (unlimited)
    if (feature == 'form_analysis') {
      return tier == SubscriptionTier.pro || tier == SubscriptionTier.elite;
    }

    // Unlimited Form Analysis - Elite only
    if (feature == 'unlimited_form_analysis') {
      return tier == SubscriptionTier.elite;
    }

    // Nutrition Tracking - Pro (basic) and Elite (full)
    if (feature == 'nutrition') {
      return tier == SubscriptionTier.pro || tier == SubscriptionTier.elite;
    }

    // AI Nutrition Coach - Elite only
    if (feature == 'nutrition_ai') {
      return tier == SubscriptionTier.elite;
    }

    // Unlimited Plans - Pro and Elite
    if (feature == 'unlimited_plans') {
      return tier != SubscriptionTier.free;
    }

    // Weekly Reports - Elite only
    if (feature == 'weekly_reports') {
      return tier == SubscriptionTier.elite;
    }

    // Advanced Analytics - Pro and Elite
    if (feature == 'advanced_analytics') {
      return tier == SubscriptionTier.pro || tier == SubscriptionTier.elite;
    }

    // Custom Workouts - Pro and Elite
    if (feature == 'custom_workouts') {
      return tier == SubscriptionTier.pro || tier == SubscriptionTier.elite;
    }

    // Health Integrations - Elite only
    if (feature == 'health_integrations') {
      return tier == SubscriptionTier.elite;
    }

    // Priority Support - Elite only
    if (feature == 'priority_support') {
      return tier == SubscriptionTier.elite;
    }

    return false;
  }

  /// Check if user can perform form analysis based on monthly quota
  bool canPerformFormAnalysis(int usedThisMonth) {
    if (formAnalysisPerMonth == -1) return true; // unlimited
    if (formAnalysisPerMonth == 0) return false; // not available
    return usedThisMonth < formAnalysisPerMonth;
  }
}
