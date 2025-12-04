import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/services/api_client.dart';
import '../data/services/auth_service.dart';
import '../data/services/user_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient;
  late final AuthService _authService;
  late final UserService _userService;

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._apiClient) {
    _authService = AuthService(_apiClient);
    _userService = UserService(_apiClient);
    _checkAuthStatus();
  }

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      await fetchUser();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.register(
      name: name,
      email: email,
      password: password,
    );

    _isLoading = false;

    if (result['success']) {
      _user = result['user'];
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.login(email: email, password: password);

    _isLoading = false;

    if (result['success']) {
      _user = result['user'];
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> fetchUser() async {
    final result = await _userService.getUser();
    if (result['success']) {
      _user = result['user'];
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? gender,
    int? age,
    double? height,
    double? weight,
    String? bodyShape,
    String? goal,
    List<String>? goals,
    String? level,
    int? weeklyFrequency,
    String? location,
    List<String>? equipment,
    List<String>? limitations,
    List<Map<String, dynamic>>? detailedInjuries,
    String? trainingSplit,
    int? sessionDuration,
    String? cardioPreference,
    String? mobilityPreference,
    String? workoutType,
    List<String>? specificMachines,
    // Professional Trainer Fields
    String? trainingHistory,
    List<String>? preferredDays,
    String? timePreference,
    int? sleepHours,
    String? recoveryCapacity,
    String? nutritionApproach,
    String? bodyFatPercentage,
    bool silent = false,
  }) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    final result = await _userService.updateProfile(
      gender: gender,
      age: age,
      height: height,
      weight: weight,
      bodyShape: bodyShape,
      goal: goal,
      goals: goals,
      level: level,
      weeklyFrequency: weeklyFrequency,
      location: location,
      equipment: equipment,
      limitations: limitations,
      detailedInjuries: detailedInjuries,
      trainingSplit: trainingSplit,
      sessionDuration: sessionDuration,
      cardioPreference: cardioPreference,
      mobilityPreference: mobilityPreference,
      workoutType: workoutType,
      specificMachines: specificMachines,
      // Professional Trainer Fields
      trainingHistory: trainingHistory,
      preferredDays: preferredDays,
      timePreference: timePreference,
      sleepHours: sleepHours,
      recoveryCapacity: recoveryCapacity,
      nutritionApproach: nutritionApproach,
      bodyFatPercentage: bodyFatPercentage,
    );

    _isLoading = false;

    if (result['success']) {
      _user = result['user'];
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
