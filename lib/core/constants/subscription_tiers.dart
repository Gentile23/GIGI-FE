/// Subscription Tier Enumeration
enum SubscriptionTier { free, premium, gold, platinum }

/// Subscription Tier Features and Pricing
class SubscriptionTierConfig {
  final SubscriptionTier tier;
  final String name;
  final double priceMonthly; // in euros
  final List<String> features;
  final List<String> restrictions;

  const SubscriptionTierConfig({
    required this.tier,
    required this.name,
    required this.priceMonthly,
    required this.features,
    required this.restrictions,
  });

  static const SubscriptionTierConfig free = SubscriptionTierConfig(
    tier: SubscriptionTier.free,
    name: 'Free',
    priceMonthly: 0.0,
    features: [
      '3 Assessment Workouts',
      '1 Workout Plan every 2 months',
      'Basic History',
      'Exercise Library',
    ],
    restrictions: [
      'No AI Voice Coach',
      'No Pose Detection',
      'Limited Plan Generation',
    ],
  );

  static const SubscriptionTierConfig premium = SubscriptionTierConfig(
    tier: SubscriptionTier.premium,
    name: 'Premium',
    priceMonthly: 9.99,
    features: [
      'Everything in Free',
      'Unlimited Workout Plans',
      'Auto-updating Plans',
      'Detailed Statistics',
      'Progress Tracking',
    ],
    restrictions: ['No AI Voice Coach', 'No Pose Detection'],
  );

  static const SubscriptionTierConfig gold = SubscriptionTierConfig(
    tier: SubscriptionTier.gold,
    name: 'Gold',
    priceMonthly: 19.99,
    features: [
      'Everything in Premium',
      'AI Voice Coach (live)',
      'Basic Pose Detection',
      'Exercise Form Feedback',
      'Real-time Guidance',
    ],
    restrictions: ['Basic pose analysis only'],
  );

  static const SubscriptionTierConfig platinum = SubscriptionTierConfig(
    tier: SubscriptionTier.platinum,
    name: 'Platinum',
    priceMonthly: 29.99,
    features: [
      'Everything in Gold',
      'Advanced Pose Analysis',
      'Detailed Form Corrections',
      'Weekly Performance Reports',
      'Live Q&A with Trainers',
      'Priority Support',
    ],
    restrictions: [],
  );

  static List<SubscriptionTierConfig> get allTiers => [
    free,
    premium,
    gold,
    platinum,
  ];

  static SubscriptionTierConfig fromTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return free;
      case SubscriptionTier.premium:
        return premium;
      case SubscriptionTier.gold:
        return gold;
      case SubscriptionTier.platinum:
        return platinum;
    }
  }

  /// Check if a feature is available for this tier
  bool hasFeature(String feature) {
    // AI Voice Coach
    if (feature == 'voice_coach') {
      return tier == SubscriptionTier.gold || tier == SubscriptionTier.platinum;
    }

    // Pose Detection
    if (feature == 'pose_detection') {
      return tier == SubscriptionTier.gold || tier == SubscriptionTier.platinum;
    }

    // Advanced Pose Analysis
    if (feature == 'advanced_pose') {
      return tier == SubscriptionTier.platinum;
    }

    // Unlimited Plans
    if (feature == 'unlimited_plans') {
      return tier != SubscriptionTier.free;
    }

    // Weekly Reports
    if (feature == 'weekly_reports') {
      return tier == SubscriptionTier.platinum;
    }

    return false;
  }
}
