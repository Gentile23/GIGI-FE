// Unit tests for Social/Community models
import 'package:flutter_test/flutter_test.dart';

// Mock Challenge class
class Challenge {
  final int id;
  final String title;
  final String description;
  final int rewardXp;
  final DateTime startDate;
  final DateTime endDate;
  final int targetValue;
  final int currentValue;
  final bool isJoined;
  final String type; // 'daily', 'weekly', 'community'

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardXp,
    required this.startDate,
    required this.endDate,
    required this.targetValue,
    this.currentValue = 0,
    this.isJoined = false,
    this.type = 'weekly',
  });

  double get progressPercent => (currentValue / targetValue).clamp(0.0, 1.0);

  bool get isCompleted => currentValue >= targetValue;

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  bool get isExpired => DateTime.now().isAfter(endDate);
}

// Mock ActivityFeedItem class
class ActivityFeedItem {
  final int id;
  final String userName;
  final String userAvatar;
  final String action; // 'workout_completed', 'challenge_won', 'new_record'
  final String content;
  final DateTime timestamp;
  final int kudosCount;
  final List<Comment> comments;
  final bool hasGivenKudos;

  ActivityFeedItem({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.action,
    required this.content,
    required this.timestamp,
    this.kudosCount = 0,
    this.comments = const [],
    this.hasGivenKudos = false,
  });

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${(diff.inDays / 7).floor()}w ago';
    }
  }

  String get actionEmoji {
    switch (action) {
      case 'workout_completed':
        return '💪';
      case 'challenge_won':
        return '🏆';
      case 'new_record':
        return '🎉';
      case 'kudos_received':
        return '👏';
      default:
        return '📢';
    }
  }
}

// Mock Comment class
class Comment {
  final int id;
  final String userName;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.userName,
    required this.text,
    required this.timestamp,
  });
}

// Mock Leaderboard class
class LeaderboardEntry {
  final int rank;
  final String userName;
  final String userAvatar;
  final int xp;
  final int workoutsCompleted;
  final int streak;

  LeaderboardEntry({
    required this.rank,
    required this.userName,
    required this.userAvatar,
    required this.xp,
    required this.workoutsCompleted,
    required this.streak,
  });

  String get rankEmoji {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }
}

void main() {
  group('Challenge Model', () {
    test('Challenge creation', () {
      final challenge = Challenge(
        id: 1,
        title: '7-Day Streak',
        description: 'Work out for 7 consecutive days',
        rewardXp: 500,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
        targetValue: 7,
      );

      expect(challenge.title, '7-Day Streak');
      expect(challenge.rewardXp, 500);
      expect(challenge.targetValue, 7);
    });

    test('Progress percent calculation', () {
      final challenge = Challenge(
        id: 1,
        title: 'Test',
        description: 'Test',
        rewardXp: 100,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
        targetValue: 10,
        currentValue: 5,
      );

      expect(challenge.progressPercent, 0.5);
    });

    test('isCompleted check', () {
      final incomplete = Challenge(
        id: 1,
        title: 'Test',
        description: 'Test',
        rewardXp: 100,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
        targetValue: 10,
        currentValue: 5,
      );
      expect(incomplete.isCompleted, false);

      final complete = Challenge(
        id: 2,
        title: 'Test',
        description: 'Test',
        rewardXp: 100,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
        targetValue: 10,
        currentValue: 10,
      );
      expect(complete.isCompleted, true);

      final overComplete = Challenge(
        id: 3,
        title: 'Test',
        description: 'Test',
        rewardXp: 100,
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
        targetValue: 10,
        currentValue: 15,
      );
      expect(overComplete.isCompleted, true);
      expect(overComplete.progressPercent, 1.0); // Capped at 100%
    });

    test('Days remaining calculation', () {
      final future = Challenge(
        id: 1,
        title: 'Test',
        description: 'Test',
        rewardXp: 100,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 10)),
        targetValue: 10,
      );
      expect(future.daysRemaining, greaterThan(0));

      final past = Challenge(
        id: 2,
        title: 'Test',
        description: 'Test',
        rewardXp: 100,
        startDate: DateTime(2020, 1, 1),
        endDate: DateTime(2020, 1, 31),
        targetValue: 10,
      );
      expect(past.daysRemaining, 0);
    });

    test('isActive check', () {
      final active = Challenge(
        id: 1,
        title: 'Test',
        description: 'Test',
        rewardXp: 100,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 10)),
        targetValue: 10,
      );
      expect(active.isActive, true);

      final notStarted = Challenge(
        id: 2,
        title: 'Test',
        description: 'Test',
        rewardXp: 100,
        startDate: DateTime.now().add(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 15)),
        targetValue: 10,
      );
      expect(notStarted.isActive, false);
    });

    test('isExpired check', () {
      final expired = Challenge(
        id: 1,
        title: 'Test',
        description: 'Test',
        rewardXp: 100,
        startDate: DateTime(2020, 1, 1),
        endDate: DateTime(2020, 1, 31),
        targetValue: 10,
      );
      expect(expired.isExpired, true);

      final active = Challenge(
        id: 2,
        title: 'Test',
        description: 'Test',
        rewardXp: 100,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 10)),
        targetValue: 10,
      );
      expect(active.isExpired, false);
    });
  });

  group('ActivityFeedItem Model', () {
    test('ActivityFeedItem creation', () {
      final item = ActivityFeedItem(
        id: 1,
        userName: 'Mario Rossi',
        userAvatar: 'M',
        action: 'workout_completed',
        content: 'Completed Full Body Workout',
        timestamp: DateTime.now(),
        kudosCount: 5,
      );

      expect(item.userName, 'Mario Rossi');
      expect(item.kudosCount, 5);
    });

    test('timeAgo calculation - minutes', () {
      final item = ActivityFeedItem(
        id: 1,
        userName: 'Test',
        userAvatar: 'T',
        action: 'workout_completed',
        content: 'Test',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      expect(item.timeAgo, '30m ago');
    });

    test('timeAgo calculation - hours', () {
      final item = ActivityFeedItem(
        id: 1,
        userName: 'Test',
        userAvatar: 'T',
        action: 'workout_completed',
        content: 'Test',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      );

      expect(item.timeAgo, '5h ago');
    });

    test('timeAgo calculation - days', () {
      final item = ActivityFeedItem(
        id: 1,
        userName: 'Test',
        userAvatar: 'T',
        action: 'workout_completed',
        content: 'Test',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
      );

      expect(item.timeAgo, '3d ago');
    });

    test('timeAgo calculation - weeks', () {
      final item = ActivityFeedItem(
        id: 1,
        userName: 'Test',
        userAvatar: 'T',
        action: 'workout_completed',
        content: 'Test',
        timestamp: DateTime.now().subtract(const Duration(days: 14)),
      );

      expect(item.timeAgo, '2w ago');
    });

    test('Action emoji mapping', () {
      expect(
        ActivityFeedItem(
          id: 1,
          userName: 'Test',
          userAvatar: 'T',
          action: 'workout_completed',
          content: 'Test',
          timestamp: DateTime.now(),
        ).actionEmoji,
        '💪',
      );

      expect(
        ActivityFeedItem(
          id: 2,
          userName: 'Test',
          userAvatar: 'T',
          action: 'challenge_won',
          content: 'Test',
          timestamp: DateTime.now(),
        ).actionEmoji,
        '🏆',
      );

      expect(
        ActivityFeedItem(
          id: 3,
          userName: 'Test',
          userAvatar: 'T',
          action: 'new_record',
          content: 'Test',
          timestamp: DateTime.now(),
        ).actionEmoji,
        '🎉',
      );

      expect(
        ActivityFeedItem(
          id: 4,
          userName: 'Test',
          userAvatar: 'T',
          action: 'unknown_action',
          content: 'Test',
          timestamp: DateTime.now(),
        ).actionEmoji,
        '📢',
      );
    });
  });

  group('LeaderboardEntry Model', () {
    test('LeaderboardEntry creation', () {
      final entry = LeaderboardEntry(
        rank: 1,
        userName: 'Champion',
        userAvatar: 'C',
        xp: 10000,
        workoutsCompleted: 50,
        streak: 30,
      );

      expect(entry.rank, 1);
      expect(entry.xp, 10000);
      expect(entry.streak, 30);
    });

    test('Rank emoji for top 3', () {
      expect(
        LeaderboardEntry(
          rank: 1,
          userName: 'First',
          userAvatar: 'F',
          xp: 10000,
          workoutsCompleted: 50,
          streak: 30,
        ).rankEmoji,
        '🥇',
      );

      expect(
        LeaderboardEntry(
          rank: 2,
          userName: 'Second',
          userAvatar: 'S',
          xp: 9000,
          workoutsCompleted: 45,
          streak: 25,
        ).rankEmoji,
        '🥈',
      );

      expect(
        LeaderboardEntry(
          rank: 3,
          userName: 'Third',
          userAvatar: 'T',
          xp: 8000,
          workoutsCompleted: 40,
          streak: 20,
        ).rankEmoji,
        '🥉',
      );
    });

    test('Rank number for 4+', () {
      expect(
        LeaderboardEntry(
          rank: 4,
          userName: 'Fourth',
          userAvatar: 'F',
          xp: 7000,
          workoutsCompleted: 35,
          streak: 15,
        ).rankEmoji,
        '#4',
      );

      expect(
        LeaderboardEntry(
          rank: 100,
          userName: 'Hundredth',
          userAvatar: 'H',
          xp: 1000,
          workoutsCompleted: 5,
          streak: 1,
        ).rankEmoji,
        '#100',
      );
    });
  });

  group('Comment Model', () {
    test('Comment creation', () {
      final comment = Comment(
        id: 1,
        userName: 'Commenter',
        text: 'Great job!',
        timestamp: DateTime.now(),
      );

      expect(comment.userName, 'Commenter');
      expect(comment.text, 'Great job!');
    });
  });
}
