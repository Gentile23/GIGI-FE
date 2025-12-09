import 'dart:math';

/// ═══════════════════════════════════════════════════════════
/// ENHANCED STREAK SYSTEM - Addiction Mechanics
/// Freeze Tokens, XP Multipliers, Streak Insurance
/// ═══════════════════════════════════════════════════════════

class StreakData {
  final int currentStreak;
  final int longestStreak;
  final int freezeTokensRemaining;
  final int freezeTokensUsedThisMonth;
  final double xpMultiplier;
  final List<DateTime> streakHistory;
  final bool isAtRisk;
  final DateTime? lastWorkoutDate;
  final bool hasStreakInsurance; // Premium feature

  const StreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.freezeTokensRemaining = 3,
    this.freezeTokensUsedThisMonth = 0,
    this.xpMultiplier = 1.0,
    this.streakHistory = const [],
    this.isAtRisk = false,
    this.lastWorkoutDate,
    this.hasStreakInsurance = false,
  });

  /// Calculate XP multiplier based on streak length
  static double calculateMultiplier(int streak) {
    if (streak >= 30) return 2.0; // 30+ days = 2x XP
    if (streak >= 14) return 1.75; // 14+ days = 1.75x XP
    if (streak >= 7) return 1.5; // 7+ days = 1.5x XP
    if (streak >= 3) return 1.25; // 3+ days = 1.25x XP
    return 1.0;
  }

  /// Check if streak is at risk (no workout today after 6 PM)
  bool get isCurrentlyAtRisk {
    if (lastWorkoutDate == null) return currentStreak > 0;
    final now = DateTime.now();
    final isToday =
        lastWorkoutDate!.year == now.year &&
        lastWorkoutDate!.month == now.month &&
        lastWorkoutDate!.day == now.day;
    return !isToday && now.hour >= 18 && currentStreak > 0;
  }

  /// Get streak emoji based on length
  String get streakEmoji {
    if (currentStreak >= 100) return '💎';
    if (currentStreak >= 30) return '🔥';
    if (currentStreak >= 14) return '⚡';
    if (currentStreak >= 7) return '✨';
    if (currentStreak >= 3) return '🌟';
    return '💪';
  }

  /// Get streak tier name
  String get streakTier {
    if (currentStreak >= 100) return 'LEGENDARY';
    if (currentStreak >= 30) return 'ON FIRE';
    if (currentStreak >= 14) return 'UNSTOPPABLE';
    if (currentStreak >= 7) return 'CONSISTENT';
    if (currentStreak >= 3) return 'GETTING STARTED';
    return 'BEGINNER';
  }

  StreakData copyWith({
    int? currentStreak,
    int? longestStreak,
    int? freezeTokensRemaining,
    int? freezeTokensUsedThisMonth,
    double? xpMultiplier,
    List<DateTime>? streakHistory,
    bool? isAtRisk,
    DateTime? lastWorkoutDate,
    bool? hasStreakInsurance,
  }) {
    return StreakData(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      freezeTokensRemaining:
          freezeTokensRemaining ?? this.freezeTokensRemaining,
      freezeTokensUsedThisMonth:
          freezeTokensUsedThisMonth ?? this.freezeTokensUsedThisMonth,
      xpMultiplier: xpMultiplier ?? this.xpMultiplier,
      streakHistory: streakHistory ?? this.streakHistory,
      isAtRisk: isAtRisk ?? this.isAtRisk,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
      hasStreakInsurance: hasStreakInsurance ?? this.hasStreakInsurance,
    );
  }

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      freezeTokensRemaining: json['freeze_tokens_remaining'] ?? 3,
      freezeTokensUsedThisMonth: json['freeze_tokens_used_this_month'] ?? 0,
      xpMultiplier: (json['xp_multiplier'] ?? 1.0).toDouble(),
      streakHistory:
          (json['streak_history'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e as String))
              .toList() ??
          [],
      isAtRisk: json['is_at_risk'] ?? false,
      lastWorkoutDate: json['last_workout_date'] != null
          ? DateTime.parse(json['last_workout_date'])
          : null,
      hasStreakInsurance: json['has_streak_insurance'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'freeze_tokens_remaining': freezeTokensRemaining,
      'freeze_tokens_used_this_month': freezeTokensUsedThisMonth,
      'xp_multiplier': xpMultiplier,
      'streak_history': streakHistory.map((e) => e.toIso8601String()).toList(),
      'is_at_risk': isAtRisk,
      'last_workout_date': lastWorkoutDate?.toIso8601String(),
      'has_streak_insurance': hasStreakInsurance,
    };
  }
}

/// ═══════════════════════════════════════════════════════════
/// REWARD CHEST SYSTEM - Variable Rewards (Dopamine Trigger)
/// ═══════════════════════════════════════════════════════════

enum ChestRarity { bronze, silver, gold, legendary }

enum RewardType { xp, avatarItem, discount, featureUnlock, badge, coins }

class Reward {
  final RewardType type;
  final String name;
  final String description;
  final String iconEmoji;
  final dynamic value; // XP amount, discount %, etc.
  final bool isRare;

  const Reward({
    required this.type,
    required this.name,
    required this.description,
    required this.iconEmoji,
    required this.value,
    this.isRare = false,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      type: RewardType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RewardType.xp,
      ),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconEmoji: json['icon_emoji'] ?? '🎁',
      value: json['value'],
      isRare: json['is_rare'] ?? false,
    );
  }
}

class RewardChest {
  final String id;
  final ChestRarity rarity;
  final List<Reward> rewards;
  final DateTime earnedAt;
  final bool isOpened;
  final String? workoutId;

  const RewardChest({
    required this.id,
    required this.rarity,
    required this.rewards,
    required this.earnedAt,
    this.isOpened = false,
    this.workoutId,
  });

  String get rarityEmoji {
    switch (rarity) {
      case ChestRarity.bronze:
        return '🥉';
      case ChestRarity.silver:
        return '🥈';
      case ChestRarity.gold:
        return '🥇';
      case ChestRarity.legendary:
        return '💎';
    }
  }

  String get rarityName {
    switch (rarity) {
      case ChestRarity.bronze:
        return 'Bronzo';
      case ChestRarity.silver:
        return 'Argento';
      case ChestRarity.gold:
        return 'Oro';
      case ChestRarity.legendary:
        return 'Leggendario';
    }
  }

  /// Generate a random chest based on workout performance
  static RewardChest generatePostWorkout({
    required String workoutId,
    required int workoutDuration,
    required int exercisesCompleted,
    required int currentStreak,
  }) {
    final random = Random();

    // Calculate rarity chances based on performance
    double legendaryChance = 0.02; // 2% base
    double goldChance = 0.10; // 10% base
    double silverChance = 0.30; // 30% base

    // Bonus chances for streak
    if (currentStreak >= 30) {
      legendaryChance += 0.05;
      goldChance += 0.10;
    } else if (currentStreak >= 7) {
      goldChance += 0.05;
      silverChance += 0.10;
    }

    // Bonus for workout duration
    if (workoutDuration >= 45) {
      goldChance += 0.05;
    }

    final roll = random.nextDouble();
    ChestRarity rarity;
    if (roll < legendaryChance) {
      rarity = ChestRarity.legendary;
    } else if (roll < legendaryChance + goldChance) {
      rarity = ChestRarity.gold;
    } else if (roll < legendaryChance + goldChance + silverChance) {
      rarity = ChestRarity.silver;
    } else {
      rarity = ChestRarity.bronze;
    }

    return RewardChest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rarity: rarity,
      rewards: _generateRewards(
        rarity,
        random,
        workoutDuration: workoutDuration,
        exercisesCompleted: exercisesCompleted,
        currentStreak: currentStreak,
      ),
      earnedAt: DateTime.now(),
      workoutId: workoutId,
    );
  }

  static List<Reward> _generateRewards(
    ChestRarity rarity,
    Random random, {
    int? workoutDuration,
    int? exercisesCompleted,
    int? currentStreak,
  }) {
    final rewards = <Reward>[];

    // XP reward based on rarity
    final xpAmounts = {
      ChestRarity.bronze: [25, 50, 75],
      ChestRarity.silver: [75, 100, 150],
      ChestRarity.gold: [150, 200, 300],
      ChestRarity.legendary: [300, 500, 750],
    };

    final xpOptions = xpAmounts[rarity]!;
    final xpAmount = xpOptions[random.nextInt(xpOptions.length)];

    rewards.add(
      Reward(
        type: RewardType.xp,
        name: '+$xpAmount XP',
        description: 'Esperienza bonus per il tuo profilo',
        iconEmoji: '⭐',
        value: xpAmount,
      ),
    );

    // SURPRISE MEDALS LOGIC (Performance Based)
    // These checks allow medals to appear even in lower tier chests if performance was high
    if (workoutDuration != null && workoutDuration >= 60) {
      if (random.nextDouble() < 0.3) {
        // 30% chance
        rewards.add(
          const Reward(
            type: RewardType.badge,
            name: 'Medaglia Resistenza',
            description: 'Workout durato più di 1 ora!',
            iconEmoji: '🥇',
            value: 'endurance_medal',
            isRare: true,
          ),
        );
      }
    }

    if (exercisesCompleted != null && exercisesCompleted >= 15) {
      if (random.nextDouble() < 0.3) {
        rewards.add(
          const Reward(
            type: RewardType.badge,
            name: 'Medaglia Guerriero',
            description: 'Completati più di 15 esercizi!',
            iconEmoji: '⚔️',
            value: 'warrior_medal',
            isRare: true,
          ),
        );
      }
    }

    // Additional rewards for higher rarities
    if (rarity == ChestRarity.gold || rarity == ChestRarity.legendary) {
      final bonusRewards = [
        const Reward(
          type: RewardType.discount,
          name: '20% Sconto Premium',
          description: 'Valido per 7 giorni',
          iconEmoji: '🎫',
          value: 20,
        ),
        const Reward(
          type: RewardType.featureUnlock,
          name: 'Voice Coaching 24h',
          description: 'Prova gratuita feature premium',
          iconEmoji: '🎙️',
          value: 'voice_coaching_24h',
        ),
        const Reward(
          type: RewardType.avatarItem,
          name: 'Corona Fitness',
          description: 'Accessorio avatar esclusivo',
          iconEmoji: '👑',
          value: 'crown_fitness',
          isRare: true,
        ),
      ];

      // Ensure we don't duplicate if a medal was already added above
      if (rewards.length < 3) {
        rewards.add(bonusRewards[random.nextInt(bonusRewards.length)]);
      }
    }

    if (rarity == ChestRarity.legendary) {
      rewards.add(
        const Reward(
          type: RewardType.badge,
          name: 'Medaglia Leggendaria',
          description: 'Hai trovato un chest leggendario!',
          iconEmoji: '🏆',
          value: 'legendary_finder',
          isRare: true,
        ),
      );
    }

    return rewards;
  }

  factory RewardChest.fromJson(Map<String, dynamic> json) {
    return RewardChest(
      id: json['id'] ?? '',
      rarity: ChestRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => ChestRarity.bronze,
      ),
      rewards:
          (json['rewards'] as List<dynamic>?)
              ?.map((e) => Reward.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      earnedAt: json['earned_at'] != null
          ? DateTime.parse(json['earned_at'])
          : DateTime.now(),
      isOpened: json['is_opened'] ?? false,
      workoutId: json['workout_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rarity': rarity.name,
      'rewards': rewards
          .map(
            (r) => {
              'type': r.type.name,
              'name': r.name,
              'description': r.description,
              'icon_emoji': r.iconEmoji,
              'value': r.value,
              'is_rare': r.isRare,
            },
          )
          .toList(),
      'earned_at': earnedAt.toIso8601String(),
      'is_opened': isOpened,
      'workout_id': workoutId,
    };
  }
}

/// ═══════════════════════════════════════════════════════════
/// REFERRAL SYSTEM - Viral Growth
/// ═══════════════════════════════════════════════════════════

class ReferralData {
  final String referralCode;
  final int totalReferrals;
  final int pendingReferrals;
  final int convertedReferrals;
  final List<ReferralReward> unlockedRewards;
  final List<ReferralReward> nextRewards;
  final DateTime? lastReferralDate;

  const ReferralData({
    required this.referralCode,
    this.totalReferrals = 0,
    this.pendingReferrals = 0,
    this.convertedReferrals = 0,
    this.unlockedRewards = const [],
    this.nextRewards = const [],
    this.lastReferralDate,
  });

  static const Map<int, ReferralReward> milestoneRewards = {
    1: ReferralReward(
      milestone: 1,
      title: '1 Mese Premium Gratis',
      description: 'Per te e il tuo amico',
      iconEmoji: '🎁',
      type: ReferralRewardType.premiumMonth,
      value: 1,
    ),
    3: ReferralReward(
      milestone: 3,
      title: '3 Mesi Premium Gratis',
      description: 'Continua a invitare!',
      iconEmoji: '🌟',
      type: ReferralRewardType.premiumMonth,
      value: 3,
    ),
    5: ReferralReward(
      milestone: 5,
      title: 'Badge Ambassador',
      description: 'Badge esclusivo + 3 mesi Premium',
      iconEmoji: '🏅',
      type: ReferralRewardType.badge,
      value: 'ambassador',
    ),
    10: ReferralReward(
      milestone: 10,
      title: '6 Mesi + Merchandise',
      description: 'Box esclusiva GIGI',
      iconEmoji: '📦',
      type: ReferralRewardType.merchandise,
      value: 'starter_box',
    ),
    25: ReferralReward(
      milestone: 25,
      title: 'Lifetime Premium',
      description: 'Accesso premium per sempre!',
      iconEmoji: '💎',
      type: ReferralRewardType.lifetime,
      value: 'lifetime_premium',
    ),
  };

  int get nextMilestone {
    for (final milestone in milestoneRewards.keys.toList()..sort()) {
      if (convertedReferrals < milestone) return milestone;
    }
    return 25; // Max milestone
  }

  double get progressToNextMilestone {
    final previous = milestoneRewards.keys
        .where((m) => m <= convertedReferrals)
        .fold(0, (a, b) => a > b ? a : b);
    final next = nextMilestone;
    if (next == previous) return 1.0;
    return (convertedReferrals - previous) / (next - previous);
  }

  factory ReferralData.fromJson(Map<String, dynamic> json) {
    return ReferralData(
      referralCode: json['referral_code'] ?? '',
      totalReferrals: json['total_referrals'] ?? 0,
      pendingReferrals: json['pending_referrals'] ?? 0,
      convertedReferrals: json['converted_referrals'] ?? 0,
      lastReferralDate: json['last_referral_date'] != null
          ? DateTime.parse(json['last_referral_date'])
          : null,
    );
  }
}

enum ReferralRewardType { premiumMonth, badge, merchandise, lifetime }

class ReferralReward {
  final int milestone;
  final String title;
  final String description;
  final String iconEmoji;
  final ReferralRewardType type;
  final dynamic value;

  const ReferralReward({
    required this.milestone,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.type,
    required this.value,
  });
}

/// ═══════════════════════════════════════════════════════════
/// LIVE ACTIVITY - Social Proof & FOMO
/// ═══════════════════════════════════════════════════════════

class LiveActivityData {
  final int usersWorkingOutNow;
  final int workoutsCompletedToday;
  final String? recentActivityMessage;
  final DateTime lastUpdated;

  const LiveActivityData({
    this.usersWorkingOutNow = 0,
    this.workoutsCompletedToday = 0,
    this.recentActivityMessage,
    required this.lastUpdated,
  });

  /// Generate realistic-looking live counter
  static LiveActivityData generateMock() {
    final random = Random();
    final hour = DateTime.now().hour;

    // More users during peak hours (7-9am, 5-8pm)
    int baseUsers = 50;
    if ((hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 20)) {
      baseUsers = 150;
    } else if (hour >= 10 && hour <= 16) {
      baseUsers = 80;
    } else if (hour >= 21 || hour <= 6) {
      baseUsers = 30;
    }

    final users = baseUsers + random.nextInt(50);
    final workoutsToday = 2000 + random.nextInt(1000) + (hour * 100);

    final recentActivities = [
      'Marco ha appena battuto il suo record! 💪',
      'Sara ha completato una streak di 30 giorni 🔥',
      'Luca ha sbloccato il badge "Warrior" 🏆',
      'Anna ha finito il suo 100° workout! 🎉',
      'Giuseppe ha perso 5kg questo mese 📉',
    ];

    return LiveActivityData(
      usersWorkingOutNow: users,
      workoutsCompletedToday: workoutsToday,
      recentActivityMessage:
          recentActivities[random.nextInt(recentActivities.length)],
      lastUpdated: DateTime.now(),
    );
  }

  factory LiveActivityData.fromJson(Map<String, dynamic> json) {
    return LiveActivityData(
      usersWorkingOutNow: json['users_working_out_now'] ?? 0,
      workoutsCompletedToday: json['workouts_completed_today'] ?? 0,
      recentActivityMessage: json['recent_activity_message'],
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : DateTime.now(),
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// CHALLENGE SYSTEM - Engagement & Competition
/// ═══════════════════════════════════════════════════════════

enum ChallengeType { daily, weekly, monthly, community, oneVsOne }

enum ChallengeStatus { upcoming, active, completed, failed }

class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeStatus status;
  final int targetValue;
  final int currentProgress;
  final DateTime startDate;
  final DateTime endDate;
  final List<Reward> rewards;
  final int participantsCount;
  final String? opponentId;
  final String? opponentName;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.targetValue,
    this.currentProgress = 0,
    required this.startDate,
    required this.endDate,
    required this.rewards,
    this.participantsCount = 0,
    this.opponentId,
    this.opponentName,
  });

  double get progressPercentage =>
      targetValue > 0 ? (currentProgress / targetValue).clamp(0.0, 1.0) : 0.0;

  Duration get timeRemaining => endDate.difference(DateTime.now());

  String get timeRemainingFormatted {
    final remaining = timeRemaining;
    if (remaining.isNegative) return 'Terminata';
    if (remaining.inDays > 0) {
      return '${remaining.inDays}g ${remaining.inHours % 24}h';
    }
    if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    }
    return '${remaining.inMinutes}m';
  }

  bool get isActive => status == ChallengeStatus.active;

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: ChallengeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChallengeType.daily,
      ),
      status: ChallengeStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ChallengeStatus.active,
      ),
      targetValue: json['target_value'] ?? 0,
      currentProgress: json['current_progress'] ?? 0,
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      rewards:
          (json['rewards'] as List<dynamic>?)
              ?.map((e) => Reward.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      participantsCount: json['participants_count'] ?? 0,
      opponentId: json['opponent_id'],
      opponentName: json['opponent_name'],
    );
  }

  /// Generate sample challenges
  static List<Challenge> getSampleChallenges() {
    final now = DateTime.now();
    return [
      Challenge(
        id: 'daily_pushups',
        title: '100 Push-Up Challenge',
        description: 'Completa 100 push-up oggi',
        type: ChallengeType.daily,
        status: ChallengeStatus.active,
        targetValue: 100,
        currentProgress: 45,
        startDate: DateTime(now.year, now.month, now.day),
        endDate: DateTime(now.year, now.month, now.day, 23, 59),
        rewards: [
          const Reward(
            type: RewardType.xp,
            name: '+100 XP',
            description: 'Bonus completamento',
            iconEmoji: '⭐',
            value: 100,
          ),
        ],
        participantsCount: 1247,
      ),
      Challenge(
        id: 'weekly_workouts',
        title: '5 Workout Questa Settimana',
        description: 'Completa 5 workout entro domenica',
        type: ChallengeType.weekly,
        status: ChallengeStatus.active,
        targetValue: 5,
        currentProgress: 2,
        startDate: now.subtract(Duration(days: now.weekday - 1)),
        endDate: now.add(Duration(days: 7 - now.weekday)),
        rewards: [
          const Reward(
            type: RewardType.xp,
            name: '+250 XP',
            description: 'Bonus completamento',
            iconEmoji: '⭐',
            value: 250,
          ),
          const Reward(
            type: RewardType.badge,
            name: 'Badge Consistenza',
            description: 'Sei un atleta costante',
            iconEmoji: '🏆',
            value: 'consistency_badge',
          ),
        ],
        participantsCount: 3521,
      ),
      Challenge(
        id: 'community_squats',
        title: '1 Milione di Squat',
        description: 'Insieme alla community, raggiungiamo 1M squat!',
        type: ChallengeType.community,
        status: ChallengeStatus.active,
        targetValue: 1000000,
        currentProgress: 742319,
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 7)),
        rewards: [
          const Reward(
            type: RewardType.badge,
            name: 'Badge Community Hero',
            description: 'Hai contribuito alla vittoria!',
            iconEmoji: '🦸',
            value: 'community_hero',
          ),
        ],
        participantsCount: 12847,
      ),
    ];
  }
}
