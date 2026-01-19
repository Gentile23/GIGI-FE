// Unit tests for Gamification/XP system
import 'package:flutter_test/flutter_test.dart';

// Mock Level class for testing
class Level {
  final int level;
  final String title;
  final int minXp;
  final int maxXp;
  final String badge;

  const Level({
    required this.level,
    required this.title,
    required this.minXp,
    required this.maxXp,
    required this.badge,
  });

  static const List<Level> levels = [
    Level(level: 1, title: 'Beginner', minXp: 0, maxXp: 99, badge: '🌱'),
    Level(level: 2, title: 'Novice', minXp: 100, maxXp: 249, badge: '🌿'),
    Level(level: 3, title: 'Apprentice', minXp: 250, maxXp: 499, badge: '🌳'),
    Level(level: 4, title: 'Athlete', minXp: 500, maxXp: 999, badge: '⭐'),
    Level(level: 5, title: 'Champion', minXp: 1000, maxXp: 1999, badge: '🏆'),
    Level(level: 6, title: 'Master', minXp: 2000, maxXp: 3999, badge: '👑'),
    Level(level: 7, title: 'Legend', minXp: 4000, maxXp: 7999, badge: '🔥'),
    Level(level: 8, title: 'Elite', minXp: 8000, maxXp: 14999, badge: '💎'),
    Level(level: 9, title: 'Titan', minXp: 15000, maxXp: 29999, badge: '🚀'),
    Level(
      level: 10,
      title: 'Immortal',
      minXp: 30000,
      maxXp: 999999,
      badge: '⚡',
    ),
  ];

  static Level fromXp(int xp) {
    for (var i = levels.length - 1; i >= 0; i--) {
      if (xp >= levels[i].minXp) {
        return levels[i];
      }
    }
    return levels.first;
  }

  double progressToNextLevel(int currentXp) {
    if (level == 10) return 1.0; // Max level
    final xpIntoLevel = currentXp - minXp;
    final xpNeededForLevel = maxXp - minXp + 1;
    return xpIntoLevel / xpNeededForLevel;
  }

  int xpToNextLevel(int currentXp) {
    if (level == 10) return 0; // Max level
    return maxXp - currentXp + 1;
  }
}

// Mock Streak class for testing
class Streak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;

  Streak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
  });

  bool get isActiveToday {
    if (lastActivityDate == null) return false;
    final today = DateTime.now();
    return lastActivityDate!.year == today.year &&
        lastActivityDate!.month == today.month &&
        lastActivityDate!.day == today.day;
  }

  bool get shouldResetStreak {
    if (lastActivityDate == null) return true;
    final daysSinceActivity = DateTime.now()
        .difference(lastActivityDate!)
        .inDays;
    return daysSinceActivity > 1;
  }

  Streak recordActivity() {
    final now = DateTime.now();

    if (isActiveToday) {
      return this; // Already recorded today
    }

    int newStreak;
    if (shouldResetStreak) {
      newStreak = 1;
    } else {
      newStreak = currentStreak + 1;
    }

    return Streak(
      currentStreak: newStreak,
      longestStreak: newStreak > longestStreak ? newStreak : longestStreak,
      lastActivityDate: now,
    );
  }
}

// XP Award constants
class XpAwards {
  static const int workoutComplete = 50;
  static const int streakBonus7Days = 100;
  static const int streakBonus30Days = 500;
  static const int challengeComplete = 200;
  static const int mealLogged = 10;
  static const int waterGoalMet = 20;
  static const int profileComplete = 100;
  static const int assessmentComplete = 150;
  static const int firstWorkout = 100;
  static const int kudosSent = 5;
  static const int kudosReceived = 10;

  static int calculateWorkoutXp({
    required int exercisesCompleted,
    required int totalSets,
    required int durationMinutes,
  }) {
    int baseXp = workoutComplete;

    // Bonus for exercises
    baseXp += exercisesCompleted * 5;

    // Bonus for sets
    baseXp += totalSets * 2;

    // Bonus for duration (caps at 60 min)
    baseXp += (durationMinutes.clamp(0, 60)) ~/ 10 * 10;

    return baseXp;
  }
}

void main() {
  group('Level System', () {
    test('Level.fromXp returns correct level', () {
      expect(Level.fromXp(0).level, 1);
      expect(Level.fromXp(50).level, 1);
      expect(Level.fromXp(100).level, 2);
      expect(Level.fromXp(500).level, 4);
      expect(Level.fromXp(1000).level, 5);
      expect(Level.fromXp(30000).level, 10);
    });

    test('Level titles are correct', () {
      expect(Level.fromXp(0).title, 'Beginner');
      expect(Level.fromXp(100).title, 'Novice');
      expect(Level.fromXp(500).title, 'Athlete');
      expect(Level.fromXp(1000).title, 'Champion');
      expect(Level.fromXp(30000).title, 'Immortal');
    });

    test('Level badges are assigned', () {
      expect(Level.fromXp(0).badge, '🌱');
      expect(Level.fromXp(1000).badge, '🏆');
      expect(Level.fromXp(30000).badge, '⚡');
    });

    test('Progress to next level calculation', () {
      final level2 = Level.levels[1]; // 100-249 XP

      expect(level2.progressToNextLevel(100), closeTo(0.0, 0.01));
      expect(level2.progressToNextLevel(175), closeTo(0.5, 0.01));
      expect(level2.progressToNextLevel(249), closeTo(0.99, 0.02));
    });

    test('XP to next level calculation', () {
      final level1 = Level.levels[0]; // 0-99 XP

      expect(level1.xpToNextLevel(0), 100);
      expect(level1.xpToNextLevel(50), 50);
      expect(level1.xpToNextLevel(99), 1);
    });

    test('Max level has full progress', () {
      final maxLevel = Level.levels[9]; // Level 10

      expect(maxLevel.progressToNextLevel(50000), 1.0);
      expect(maxLevel.xpToNextLevel(50000), 0);
    });
  });

  group('Streak System', () {
    test('New streak starts at 0', () {
      final streak = Streak();

      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 0);
      expect(streak.lastActivityDate, null);
    });

    test('Recording activity starts streak', () {
      final streak = Streak();
      final newStreak = streak.recordActivity();

      expect(newStreak.currentStreak, 1);
      expect(newStreak.lastActivityDate, isNotNull);
    });

    test('isActiveToday returns false for no activity', () {
      final streak = Streak();
      expect(streak.isActiveToday, false);
    });

    test('isActiveToday returns true after recording', () {
      final streak = Streak();
      final newStreak = streak.recordActivity();
      expect(newStreak.isActiveToday, true);
    });

    test('Streak resets after 2+ days inactivity', () {
      final oldStreak = Streak(
        currentStreak: 10,
        longestStreak: 10,
        lastActivityDate: DateTime.now().subtract(const Duration(days: 3)),
      );

      expect(oldStreak.shouldResetStreak, true);

      final newStreak = oldStreak.recordActivity();
      expect(newStreak.currentStreak, 1);
      expect(newStreak.longestStreak, 10); // Longest preserved
    });

    test('Streak continues with consecutive days', () {
      final yesterdayStreak = Streak(
        currentStreak: 5,
        longestStreak: 5,
        lastActivityDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(yesterdayStreak.shouldResetStreak, false);

      final newStreak = yesterdayStreak.recordActivity();
      expect(newStreak.currentStreak, 6);
      expect(newStreak.longestStreak, 6);
    });

    test('Longest streak updates when current exceeds it', () {
      final streak = Streak(
        currentStreak: 10,
        longestStreak: 8,
        lastActivityDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      final newStreak = streak.recordActivity();
      expect(newStreak.currentStreak, 11);
      expect(newStreak.longestStreak, 11);
    });
  });

  group('XP Awards', () {
    test('Fixed XP values are correct', () {
      expect(XpAwards.workoutComplete, 50);
      expect(XpAwards.streakBonus7Days, 100);
      expect(XpAwards.streakBonus30Days, 500);
      expect(XpAwards.challengeComplete, 200);
      expect(XpAwards.mealLogged, 10);
    });

    test('Workout XP calculation - basic workout', () {
      final xp = XpAwards.calculateWorkoutXp(
        exercisesCompleted: 5,
        totalSets: 15,
        durationMinutes: 45,
      );

      // 50 base + 5*5 exercises + 15*2 sets + 40 duration = 50+25+30+40 = 145
      expect(xp, 145);
    });

    test('Workout XP calculation - short workout', () {
      final xp = XpAwards.calculateWorkoutXp(
        exercisesCompleted: 2,
        totalSets: 6,
        durationMinutes: 15,
      );

      // 50 base + 2*5 + 6*2 + 10 = 50+10+12+10 = 82
      expect(xp, 82);
    });

    test('Workout XP calculation - long workout caps duration', () {
      final xp = XpAwards.calculateWorkoutXp(
        exercisesCompleted: 10,
        totalSets: 30,
        durationMinutes: 120, // Should cap at 60
      );

      // 50 base + 10*5 + 30*2 + 60 (capped) = 50+50+60+60 = 220
      expect(xp, 220);
    });
  });

  group('Level Progression', () {
    test('Complete level progression path', () {
      // Test that all levels are achievable in sequence
      int xp = 0;

      for (var i = 0; i < Level.levels.length; i++) {
        final level = Level.fromXp(xp);
        expect(level.level, i + 1);
        xp = Level.levels[i].maxXp + 1;
      }
    });

    test('XP boundaries are correct', () {
      // Level 1: 0-99
      expect(Level.fromXp(99).level, 1);
      expect(Level.fromXp(100).level, 2);

      // Level 2: 100-249
      expect(Level.fromXp(249).level, 2);
      expect(Level.fromXp(250).level, 3);
    });
  });
}
