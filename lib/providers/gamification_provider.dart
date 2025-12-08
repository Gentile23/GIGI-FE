import 'package:flutter/material.dart';
import '../../../data/models/gamification_model.dart';
import '../../../data/services/gamification_service.dart';
import '../../../data/services/api_client.dart';

class GamificationProvider with ChangeNotifier {
  final GamificationService _gamificationService;

  UserStats? _stats;
  List<Achievement> _unlockedAchievements = [];
  List<Achievement> _lockedAchievements = [];
  final List<Achievement> _recentlyUnlocked = [];
  bool _isLoading = false;

  GamificationProvider()
    : _gamificationService = GamificationService(ApiClient());

  UserStats? get stats => _stats;
  List<Achievement> get unlockedAchievements => _unlockedAchievements;
  List<Achievement> get lockedAchievements => _lockedAchievements;
  List<Achievement> get recentlyUnlocked => _recentlyUnlocked;
  bool get isLoading => _isLoading;

  Future<void> loadStats() async {
    _isLoading = true;
    notifyListeners();

    _stats = await _gamificationService.getStats();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAchievements() async {
    final achievements = await _gamificationService.getAchievements();

    if (achievements != null) {
      _unlockedAchievements = achievements['unlocked'] ?? [];
      _lockedAchievements = achievements['locked'] ?? [];
      notifyListeners();
    }
  }

  void addRecentlyUnlocked(List<Achievement> achievements) {
    _recentlyUnlocked.addAll(achievements);
    notifyListeners();
  }

  void clearRecentlyUnlocked() {
    _recentlyUnlocked.clear();
    notifyListeners();
  }

  Future<void> refresh() async {
    await Future.wait([loadStats(), loadAchievements()]);
  }
}
