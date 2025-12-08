import 'package:flutter/material.dart';

class UserStats {
  final int totalXp;
  final int currentLevel;
  final int xpToNextLevel;
  final int totalWorkouts;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastWorkoutDate;
  final int totalSetsCompleted;
  final int totalRepsCompleted;
  final double totalWeightLifted;
  final int totalMinutesTrained;

  UserStats({
    required this.totalXp,
    required this.currentLevel,
    required this.xpToNextLevel,
    required this.totalWorkouts,
    required this.currentStreak,
    required this.longestStreak,
    this.lastWorkoutDate,
    required this.totalSetsCompleted,
    required this.totalRepsCompleted,
    required this.totalWeightLifted,
    required this.totalMinutesTrained,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse int from dynamic (int, double, or string)
    int safeParseInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        return int.tryParse(value) ??
            double.tryParse(value)?.toInt() ??
            defaultValue;
      }
      return defaultValue;
    }

    // Helper to safely parse double from dynamic
    double safeParseDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return UserStats(
      totalXp: safeParseInt(json['total_xp']),
      currentLevel: safeParseInt(json['current_level'], 1),
      xpToNextLevel: safeParseInt(json['xp_to_next_level'], 100),
      totalWorkouts: safeParseInt(json['total_workouts']),
      currentStreak: safeParseInt(json['current_streak']),
      longestStreak: safeParseInt(json['longest_streak']),
      lastWorkoutDate: json['last_workout_date'] != null
          ? DateTime.parse(json['last_workout_date'])
          : null,
      totalSetsCompleted: safeParseInt(json['total_sets_completed']),
      totalRepsCompleted: safeParseInt(json['total_reps_completed']),
      totalWeightLifted: safeParseDouble(json['total_weight_lifted']),
      totalMinutesTrained: safeParseInt(json['total_minutes_trained']),
    );
  }

  double get progressToNextLevel {
    if (xpToNextLevel == 0) return 1.0;
    final currentLevelXp = currentLevel * 100;
    final xpInCurrentLevel = totalXp - currentLevelXp;
    return (xpInCurrentLevel / xpToNextLevel).clamp(0.0, 1.0);
  }

  // Alias for compatibility
  int get level => currentLevel;
}

class Achievement {
  final int id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final String rarity;
  final int xpReward;
  final bool isLocked;
  final DateTime? unlockedAt;
  final bool? isClaimed;
  final int? progress;
  final int? target;
  final double? progressPercentage;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.rarity,
    required this.xpReward,
    this.isLocked = false,
    this.unlockedAt,
    this.isClaimed,
    this.progress,
    this.target,
    this.progressPercentage,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    // Safely parse progress which might be a string like "0.00" or an int
    int? parseProgress(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed?.toInt();
      }
      return null;
    }

    return Achievement(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      category: json['category'],
      rarity: json['rarity'],
      xpReward: json['xp_reward'] is String
          ? int.tryParse(json['xp_reward']) ?? 0
          : json['xp_reward'] ?? 0,
      isLocked: json['locked'] ?? false,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'])
          : null,
      isClaimed: json['is_claimed'],
      progress: parseProgress(json['progress']),
      target: parseProgress(json['target']),
      progressPercentage: json['progress_percentage'] != null
          ? (json['progress_percentage'] is String
                ? double.tryParse(json['progress_percentage'])
                : json['progress_percentage']?.toDouble())
          : null,
    );
  }

  Color get rarityColor {
    switch (rarity) {
      case 'common':
        return Colors.grey;
      case 'rare':
        return Colors.blue;
      case 'epic':
        return Colors.purple;
      case 'legendary':
        return Colors.amber;
      default:
        return Colors.white;
    }
  }
}

class LeaderboardEntry {
  final int rank;
  final int userId;
  final String name;
  final int xp;
  final int level;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.xp,
    required this.level,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'],
      userId: json['user_id'],
      name: json['name'],
      xp: json['xp'],
      level: json['level'],
    );
  }
}
