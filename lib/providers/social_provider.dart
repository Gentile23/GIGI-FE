import 'package:flutter/foundation.dart';
import '../data/services/api_client.dart';

/// Provider per gestire le social features
class SocialProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  // State
  bool _isLoading = false;
  String? _error;
  List<ActivityItem> _activities = [];
  List<ChallengeData> _activeChallenges = [];
  List<ChallengeData> _availableChallenges = [];
  List<LeaderboardEntry> _leaderboard = [];
  int? _currentUserRank;
  String _leaderboardType = 'global';

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ActivityItem> get activities => _activities;
  List<ChallengeData> get activeChallenges => _activeChallenges;
  List<ChallengeData> get availableChallenges => _availableChallenges;
  List<LeaderboardEntry> get leaderboard => _leaderboard;
  int? get currentUserRank => _currentUserRank;
  String get leaderboardType => _leaderboardType;

  SocialProvider(this._apiClient);

  /// Load activity feed
  Future<void> loadFeed({int page = 1, bool refresh = false}) async {
    if (refresh) {
      _activities = [];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(
        '/social/feed',
        queryParams: {'page': page.toString(), 'per_page': '20'},
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        final newActivities = data
            .map((item) => ActivityItem.fromJson(item))
            .toList();

        if (refresh || page == 1) {
          _activities = newActivities;
        } else {
          _activities.addAll(newActivities);
        }
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading feed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load challenges
  Future<void> loadChallenges() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.get('/social/challenges');

      if (response['success'] == true) {
        final data = response['data'];

        _activeChallenges =
            (data['active'] as List<dynamic>?)
                ?.map((item) => ChallengeData.fromJson(item))
                .toList() ??
            [];

        _availableChallenges =
            (data['available'] as List<dynamic>?)
                ?.map((item) => ChallengeData.fromJson(item))
                .toList() ??
            [];
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading challenges: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Join a challenge
  Future<bool> joinChallenge(String challengeId) async {
    try {
      final response = await _apiClient.post(
        '/social/challenges/$challengeId/join',
      );

      if (response['success'] == true) {
        await loadChallenges(); // Refresh
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error joining challenge: $e');
      return false;
    }
  }

  /// Create a 1v1 challenge
  Future<bool> createChallenge({
    required int opponentId,
    required String type,
    required int durationDays,
    int? xpBet,
  }) async {
    try {
      final response = await _apiClient.post(
        '/social/challenges',
        body: {
          'opponent_id': opponentId,
          'type': type,
          'duration_days': durationDays,
          if (xpBet != null) 'xp_bet': xpBet,
        },
      );

      if (response['success'] == true) {
        await loadChallenges();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating challenge: $e');
      return false;
    }
  }

  /// Load leaderboard
  Future<void> loadLeaderboard({String type = 'global'}) async {
    _isLoading = true;
    _leaderboardType = type;
    notifyListeners();

    try {
      final response = await _apiClient.get(
        '/social/leaderboard',
        queryParams: {'type': type, 'limit': '50'},
      );

      if (response['success'] == true) {
        final data = response['data'];

        _leaderboard =
            (data['leaderboard'] as List<dynamic>?)
                ?.map((item) => LeaderboardEntry.fromJson(item))
                .toList() ??
            [];

        _currentUserRank = data['current_user_rank'];
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading leaderboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send kudos
  Future<bool> sendKudos({
    required int userId,
    String? activityId,
    String type = 'workout',
  }) async {
    try {
      final response = await _apiClient.post(
        '/social/kudos',
        body: {
          'user_id': userId,
          if (activityId != null) 'activity_id': activityId,
          'type': type,
        },
      );

      return response['success'] == true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error sending kudos: $e');
      return false;
    }
  }

  /// Like/unlike activity
  Future<bool> toggleLike(String activityId) async {
    try {
      final response = await _apiClient.post(
        '/social/activities/$activityId/like',
      );

      if (response['success'] == true) {
        // Update local state
        final index = _activities.indexWhere((a) => a.id == activityId);
        if (index >= 0) {
          final activity = _activities[index];
          activity.isLiked = !activity.isLiked;
          activity.likes += activity.isLiked ? 1 : -1;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error toggling like: $e');
      return false;
    }
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadFeed(refresh: true),
      loadChallenges(),
      loadLeaderboard(type: _leaderboardType),
    ]);
  }
}

// ========== Data Models ==========

class ActivityItem {
  final String id;
  final String type;
  final int userId;
  final String userName;
  final String? userAvatar;
  final String message;
  final DateTime timestamp;
  int likes;
  final int comments;
  bool isLiked;
  final int? xpEarned;
  final String? achievementName;
  final String? achievementRarity;
  final int? streakDays;
  final String? recordValue;
  final String? previousRecord;

  ActivityItem({
    required this.id,
    required this.type,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.message,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.isLiked,
    this.xpEarned,
    this.achievementName,
    this.achievementRarity,
    this.streakDays,
    this.recordValue,
    this.previousRecord,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? 'workout',
      userId: json['user_id'] ?? 0,
      userName: json['user_name'] ?? 'Unknown',
      userAvatar: json['user_avatar'],
      message: json['message'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      xpEarned: json['xp_earned'],
      achievementName: json['achievement_name'],
      achievementRarity: json['achievement_rarity'],
      streakDays: json['streak_days'],
      recordValue: json['record_value'],
      previousRecord: json['previous_record'],
    );
  }
}

class ChallengeData {
  final String id;
  final String title;
  final String description;
  final String type;
  final double progress;
  final int reward;
  final DateTime endsAt;
  final bool isCompleted;
  final int participants;
  final bool isPrivate;

  ChallengeData({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.progress,
    required this.reward,
    required this.endsAt,
    this.isCompleted = false,
    this.participants = 0,
    this.isPrivate = false,
  });

  factory ChallengeData.fromJson(Map<String, dynamic> json) {
    return ChallengeData(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'workouts',
      progress: (json['progress'] ?? 0).toDouble(),
      reward: json['reward'] ?? 0,
      endsAt: DateTime.tryParse(json['ends_at'] ?? '') ?? DateTime.now(),
      isCompleted: json['is_completed'] ?? false,
      participants: json['participants'] ?? 0,
      isPrivate: json['is_private'] ?? false,
    );
  }

  int get daysRemaining => endsAt.difference(DateTime.now()).inDays;
}

class LeaderboardEntry {
  final int rank;
  final int userId;
  final String name;
  final int xp;
  final int level;
  final int streak;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.xp,
    this.level = 1,
    this.streak = 0,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      streak: json['streak'] ?? 0,
      isCurrentUser: json['is_current_user'] ?? false,
    );
  }
}
