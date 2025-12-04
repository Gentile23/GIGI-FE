import 'package:flutter/material.dart';
import '../data/models/workout_model.dart';
import '../data/models/user_model.dart';
import '../data/models/user_profile_model.dart';
import '../data/services/api_client.dart';
import '../data/services/workout_service.dart';

class WorkoutProvider with ChangeNotifier {
  final ApiClient _apiClient;
  late final WorkoutService _workoutService;

  List<WorkoutPlan> _workoutPlans = [];
  WorkoutPlan? _currentPlan;
  bool _isLoading = false;
  String? _error;

  WorkoutProvider(this._apiClient) {
    _workoutService = WorkoutService(_apiClient);
  }

  List<WorkoutPlan> get workoutPlans => _workoutPlans;
  WorkoutPlan? get currentPlan => _currentPlan;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchWorkoutPlans() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _workoutService.getWorkoutPlans();

    _isLoading = false;

    if (result['success']) {
      _workoutPlans = result['plans'];
    } else {
      _error = result['message'];
    }
    notifyListeners();
  }

  Future<void> fetchCurrentPlan() async {
    print('DEBUG: fetchCurrentPlan called');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _workoutService.getCurrentPlan();
      print('DEBUG: getCurrentPlan result: ${result['success']}');

      _isLoading = false;

      if (result['success']) {
        _currentPlan = result['plan'];
        print('DEBUG: Current plan loaded: ${_currentPlan?.id}');
        print('DEBUG: Plan status: ${_currentPlan?.status}');
        print('DEBUG: Number of workouts: ${_currentPlan?.workouts.length}');

        if (_currentPlan != null && _currentPlan!.workouts.isNotEmpty) {
          print('DEBUG: First workout: ${_currentPlan!.workouts[0].name}');
          print(
            'DEBUG: First workout exercises: ${_currentPlan!.workouts[0].exercises.length}',
          );
        }

        // If plan is processing, start polling
        if (_currentPlan?.status == 'processing') {
          print('DEBUG: Plan is processing, starting poll');
          _isGenerating = true;
          _pollPlanStatus(_currentPlan!.id);
        }
      } else {
        // No plan found is not an error - it's expected for new users
        print('DEBUG: No current plan found: ${result['message']}');
        _currentPlan = null;
        _error = null; // Don't show error for "no plan found"
      }
    } catch (e) {
      print('ERROR fetching current plan: $e');
      _isLoading = false;
      _currentPlan = null;
      _error = null; // Don't show error for new users without plans
    }

    notifyListeners();
  }

  Future<bool> generatePlan() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _workoutService.generatePlan();

    if (result['success']) {
      final plan = result['plan'];

      // If plan is processing, start polling
      if (plan.status == 'processing') {
        _isLoading =
            false; // Stop global loading, but maybe set a specific generating flag?
        // Actually, let's keep isLoading true or use a separate flag.
        // For better UX, let's use a separate flag so we can show a specific UI.
        _isGenerating = true;
        notifyListeners();
        _pollPlanStatus(plan.id);
        return true;
      }

      _currentPlan = plan;
      _isLoading = false;
      await fetchWorkoutPlans(); // Refresh the list
      notifyListeners();
      return true;
    } else {
      _isLoading = false;
      // Check if error is due to trial requirement
      if (result['trial_required'] == true) {
        _error = 'trial_required';
      } else {
        _error = result['message'];
      }
      notifyListeners();
      return false;
    }
  }

  // Add isGenerating flag
  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  // Callback for when generation completes
  VoidCallback? onGenerationComplete;

  void _pollPlanStatus(String planId) async {
    int attempts = 0;
    const maxAttempts = 40; // 2 minutes (3s * 40)

    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 3));

      try {
        print('Polling attempt $attempts for plan $planId...');

        // Fetch specific plan by ID
        final result = await _workoutService.getPlanById(planId);

        if (result['success']) {
          final plan = result['plan'] as WorkoutPlan?;

          if (plan != null) {
            print('Fetched plan: ${plan.id}, Status: ${plan.status}');

            if (plan.status == 'completed') {
              print('Plan generation completed!');
              _currentPlan = plan;
              _isGenerating = false;
              _isLoading = false;
              await fetchWorkoutPlans();
              notifyListeners();
              // Trigger callback if set
              onGenerationComplete?.call();
              return;
            } else if (plan.status == 'failed') {
              print('Plan generation failed: ${plan.errorMessage}');
              _error = plan.errorMessage ?? 'Generation failed';
              _isGenerating = false;
              _isLoading = false;
              notifyListeners();
              return;
            }
            // If still processing, continue polling
          }
        }
      } catch (e) {
        print('Polling error: $e');
        // Continue polling even if one request fails
      }
      attempts++;
    }

    // Timeout - but check one last time with getCurrentPlan
    try {
      print('Polling timed out, checking current plan one last time...');
      final result = await _workoutService.getCurrentPlan();
      if (result['success'] && result['plan'] != null) {
        _currentPlan = result['plan'];
        _isGenerating = false;
        _isLoading = false;
        notifyListeners();
        return;
      }
    } catch (e) {
      print('Final check failed: $e');
    }

    _error = 'Generation timed out. Please refresh to check status.';
    _isGenerating = false;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> generateCustomPlan({
    required UserModel user,
    required UserProfile profile,
  }) async {
    // This method seems redundant if generatePlan handles everything,
    // but let's update it just in case it's used.
    // Actually, looking at the code, generatePlan calls _workoutService.generatePlan()
    // which calls the endpoint we modified.
    // generateCustomPlan calls _workoutService.generateAIPlan() which might be different?
    // Let's check WorkoutService.
    return generatePlan();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if user can generate a new workout plan (7-day cooldown)
  bool canGenerateNewPlan(UserModel user) {
    if (user.lastPlanGeneration == null) {
      return true; // First time generating
    }

    final daysSinceLastGeneration = DateTime.now()
        .difference(user.lastPlanGeneration!)
        .inDays;
    return daysSinceLastGeneration >= 7;
  }

  /// Get days remaining until next plan generation is allowed
  int getDaysUntilNextGeneration(UserModel user) {
    if (user.lastPlanGeneration == null) {
      return 0; // Can generate immediately
    }

    final daysSinceLastGeneration = DateTime.now()
        .difference(user.lastPlanGeneration!)
        .inDays;
    final daysRemaining = 7 - daysSinceLastGeneration;
    return daysRemaining > 0 ? daysRemaining : 0;
  }
}
