import '../models/gamification_model.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class GamificationService {
  final ApiClient _apiClient;

  GamificationService(this._apiClient);

  Future<UserStats?> getStats() async {
    try {
      final response = await _apiClient.dio.get('/gamification/stats');
      return UserStats.fromJson(response.data['stats']);
    } catch (e) {
      debugPrint('Error fetching stats: $e');
      return null;
    }
  }

  Future<Map<String, List<Achievement>>?> getAchievements() async {
    try {
      final response = await _apiClient.dio.get('/gamification/achievements');

      final unlocked = (response.data['unlocked'] as List)
          .map((json) => Achievement.fromJson(json))
          .toList();

      final locked = (response.data['locked'] as List)
          .map((json) => Achievement.fromJson(json))
          .toList();

      return {'unlocked': unlocked, 'locked': locked};
    } catch (e) {
      debugPrint('Error fetching achievements: $e');
      return null;
    }
  }

  Future<List<LeaderboardEntry>?> getLeaderboard({
    String period = 'weekly',
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/gamification/leaderboard',
        queryParameters: {'period': period},
      );

      return (response.data['leaderboard'] as List)
          .map((json) => LeaderboardEntry.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      return null;
    }
  }
}
