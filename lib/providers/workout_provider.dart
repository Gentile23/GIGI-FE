import 'package:flutter/material.dart';
import '../data/models/workout_model.dart';
import '../data/models/user_model.dart';
import '../data/models/workout_template_model.dart';
import '../data/services/api_client.dart';
import '../data/services/workout_service.dart';

class WorkoutProvider with ChangeNotifier {
  final ApiClient _apiClient;
  late final WorkoutService _workoutService;

  List<WorkoutPlan> _workoutPlans = [];
  WorkoutPlan? _currentPlan;
  bool _isLoading = false;
  String? _error;

  // Workout Templates (static from DB)
  List<WorkoutTemplate> _workoutTemplates = [];
  bool _isLoadingTemplates = false;

  WorkoutProvider(this._apiClient) {
    _workoutService = WorkoutService(_apiClient);
  }

  List<WorkoutPlan> get workoutPlans => _workoutPlans;
  WorkoutPlan? get currentPlan => _currentPlan;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Templates getters
  List<WorkoutTemplate> get workoutTemplates => _workoutTemplates;
  bool get isLoadingTemplates => _isLoadingTemplates;

  /// Fetch workout templates from database
  Future<void> fetchWorkoutTemplates({String? category}) async {
    _isLoadingTemplates = true;
    notifyListeners();

    try {
      String url = '/workout-templates';
      if (category != null && category.toLowerCase() != 'tutti') {
        url += '?category=${category.toLowerCase()}';
      }

      final response = await _apiClient.get(url);

      if (response['success'] == true) {
        final List<dynamic> templatesJson = response['templates'] ?? [];
        _workoutTemplates = templatesJson
            .map((json) => WorkoutTemplate.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching workout templates: $e');
    }

    _isLoadingTemplates = false;
    notifyListeners();
  }

  /// Get templates by category
  List<WorkoutTemplate> getTemplatesByCategory(String category) {
    if (category.toLowerCase() == 'tutti') return _workoutTemplates;
    return _workoutTemplates
        .where((t) => t.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

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
    debugPrint('DEBUG: fetchCurrentPlan called');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _workoutService.getCurrentPlan();
      debugPrint('DEBUG: getCurrentPlan result: ${result['success']}');

      _isLoading = false;

      if (result['success']) {
        _currentPlan = result['plan'];
        debugPrint('DEBUG: Current plan loaded: ${_currentPlan?.id}');
        debugPrint('DEBUG: Plan status: ${_currentPlan?.status}');
        debugPrint(
          'DEBUG: Number of workouts: ${_currentPlan?.workouts.length}',
        );

        if (_currentPlan != null && _currentPlan!.workouts.isNotEmpty) {
          debugPrint('DEBUG: First workout: ${_currentPlan!.workouts[0].name}');
          debugPrint(
            'DEBUG: First workout exercises: ${_currentPlan!.workouts[0].exercises.length}',
          );
        }

        // If plan is processing, start polling (but only if not already polling)
        if (_currentPlan?.status == 'processing' && !_isGenerating) {
          debugPrint('DEBUG: Plan is processing, starting poll');
          _isGenerating = true;
          _pollPlanStatus(_currentPlan!.id);
        }
      } else {
        // No plan found is not an error - it's expected for new users
        debugPrint('DEBUG: No current plan found: ${result['message']}');
        _currentPlan = null;
        _error = null; // Don't show error for "no plan found"
      }
    } catch (e) {
      debugPrint('ERROR fetching current plan: $e');
      _isLoading = false;
      _currentPlan = null;
      _error = null; // Don't show error for new users without plans
    }

    notifyListeners();
  }

  Future<bool> generatePlan({String? language}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _workoutService.generatePlan(language: language);

    if (result['success']) {
      final plan = result['plan'];
      _currentPlan = plan;

      // If plan is processing, start polling
      if (plan.status == 'processing') {
        _isGenerating = true;
        _pollPlanStatus(plan.id);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> generateCustomPlan(
    Map<String, dynamic> filters, {
    String? language,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    debugPrint('DEBUG: Generating custom plan with filters: $filters');
    final result = await _workoutService.generatePlan(
      filters: filters,
      language: language,
    );

    if (result['success']) {
      final plan = result['plan'];
      _currentPlan = plan;
      // If plan is processing, start polling
      if (plan.status == 'processing') {
        _isGenerating = true;
        _pollPlanStatus(plan.id);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _error = result['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Filter existing workouts by category
  List<WorkoutDay> getWorkoutsByCategory(String category) {
    if (_currentPlan == null) return [];

    // Normalize category
    final cat = category.toLowerCase().trim();
    if (cat == 'tutti' || cat.isEmpty) return _currentPlan!.workouts;

    return _currentPlan!.workouts.where((workout) {
      final name = workout.name.toLowerCase();
      final focus = workout.focus.toLowerCase();

      // Basic matching logic
      if (cat == 'cardio' &&
          (focus.contains('cardio') || name.contains('cardio'))) {
        return true;
      }
      if (cat == 'forza' &&
          (focus.contains('forza') ||
              focus.contains('strength') ||
              name.contains('strength'))) {
        return true;
      }
      if (cat == 'flex' &&
          (focus.contains('mobility') ||
              focus.contains('yoga') ||
              name.contains('flex'))) {
        return true;
      }
      if (cat == 'hiit' &&
          (focus.contains('hiit') || name.contains('tabata'))) {
        return true;
      }

      return false;
    }).toList();
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
        debugPrint('Polling attempt $attempts for plan $planId...');

        // Fetch specific plan by ID
        final result = await _workoutService.getPlanById(planId);

        if (result['success']) {
          final plan = result['plan'] as WorkoutPlan?;

          if (plan != null) {
            debugPrint('Fetched plan: ${plan.id}, Status: ${plan.status}');

            if (plan.status == 'completed') {
              debugPrint('Plan generation completed!');
              _currentPlan = plan;
              _isGenerating = false;
              _isLoading = false;
              await fetchWorkoutPlans();
              notifyListeners();
              // Trigger callback if set
              onGenerationComplete?.call();
              return;
            } else if (plan.status == 'failed') {
              debugPrint('Plan generation failed: ${plan.errorMessage}');
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
        debugPrint('Polling error: $e');
        // Continue polling even if one request fails
      }
      attempts++;
    }

    // Timeout - but check one last time with getCurrentPlan
    try {
      debugPrint('Polling timed out, checking current plan one last time...');
      final result = await _workoutService.getCurrentPlan();
      if (result['success'] && result['plan'] != null) {
        _currentPlan = result['plan'];
        _isGenerating = false;
        _isLoading = false;
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('Final check failed: $e');
    }

    _error = 'Generation timed out. Please refresh to check status.';
    _isGenerating = false;
    _isLoading = false;
    notifyListeners();
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
