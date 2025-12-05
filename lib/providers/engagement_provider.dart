import 'package:flutter/foundation.dart';
import '../data/services/api_client.dart';

/// Provider per gestire dati di engagement e UX
class EngagementProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  // State
  Map<String, dynamic>? _homeData;
  Map<String, dynamic>? _nearMiss;
  List<Map<String, dynamic>> _dailyChallenges = [];
  Map<String, dynamic>? _streakWarning;
  Map<String, dynamic>? _communityStats;
  String? _motivationMessage;
  Map<String, dynamic>? _lastReward;
  List<Map<String, dynamic>> _storyAchievements = [];

  bool _isLoading = false;
  String? _error;

  EngagementProvider(this._apiClient);

  // Getters
  Map<String, dynamic>? get homeData => _homeData;
  Map<String, dynamic>? get nearMiss => _nearMiss;
  List<Map<String, dynamic>> get dailyChallenges => _dailyChallenges;
  Map<String, dynamic>? get streakWarning => _streakWarning;
  Map<String, dynamic>? get communityStats => _communityStats;
  String? get motivationMessage => _motivationMessage;
  Map<String, dynamic>? get lastReward => _lastReward;
  List<Map<String, dynamic>> get storyAchievements => _storyAchievements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Computed getters
  bool get hasNearMiss => _nearMiss != null && _nearMiss!['show'] == true;
  bool get hasStreakWarning => _streakWarning != null;
  bool get isStreakUrgent => _streakWarning?['is_urgent'] == true;
  int get workoutsToday => _communityStats?['workouts_today'] ?? 0;
  int get activeUsersNow => _communityStats?['active_users_now'] ?? 0;

  /// Carica dati home personalizzati
  Future<void> loadHomeData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/engagement/home');

      if (response['success'] != false) {
        _homeData = response;
        _nearMiss = response['near_miss'];
        _dailyChallenges = List<Map<String, dynamic>>.from(
          response['daily_challenges']?['challenges'] ?? [],
        );
        _streakWarning = response['streak_warning'];
        _communityStats = response['community_stats'];
        _motivationMessage = response['motivation_message'];
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading home data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Roll reward dopo workout
  Future<Map<String, dynamic>?> rollReward() async {
    try {
      final response = await _apiClient.post('/engagement/roll-reward');

      if (response['success'] == true) {
        _lastReward = response['reward'];
        notifyListeners();
        return _lastReward;
      }
    } catch (e) {
      debugPrint('Error rolling reward: $e');
    }
    return null;
  }

  /// Carica story achievements
  Future<void> loadStoryAchievements() async {
    try {
      final response = await _apiClient.get('/engagement/story-achievements');

      _storyAchievements = List<Map<String, dynamic>>.from(
        response['achievements'] ?? [],
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading story achievements: $e');
    }
  }

  /// Completa daily challenge
  Future<bool> completeDailyChallenge(String challengeId) async {
    try {
      final response = await _apiClient.post(
        '/engagement/complete-challenge',
        body: {'challenge_id': challengeId},
      );

      if (response['success'] == true) {
        // Update local state
        final index = _dailyChallenges.indexWhere(
          (c) => c['id'] == challengeId,
        );
        if (index != -1) {
          _dailyChallenges[index]['completed'] = true;
          _dailyChallenges[index]['progress'] = 1.0;
        }

        // Store bonus reward
        if (response['bonus_reward'] != null) {
          _lastReward = response['bonus_reward'];
        }

        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error completing challenge: $e');
    }
    return false;
  }

  /// Ottieni messaggio near miss
  String? getNearMissMessage() {
    if (!hasNearMiss) return null;
    return _nearMiss!['message'];
  }

  /// Ottieni XP rimanenti al level up
  int? getXpRemaining() {
    if (!hasNearMiss) return null;
    return _nearMiss!['xp_remaining'];
  }

  /// Ottieni ore rimanenti per streak
  int? getStreakHoursRemaining() {
    if (!hasStreakWarning) return null;
    return _streakWarning!['hours_remaining'];
  }

  /// Ottieni streak corrente a rischio
  int? getCurrentStreakAtRisk() {
    if (!hasStreakWarning) return null;
    return _streakWarning!['current_streak'];
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear last reward (dopo averlo mostrato)
  void clearLastReward() {
    _lastReward = null;
    notifyListeners();
  }
}
