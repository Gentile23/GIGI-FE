import 'package:flutter/material.dart';
import '../data/models/workout_model.dart';
import '../data/models/user_model.dart';
import '../data/models/workout_template_model.dart';
import '../data/services/api_client.dart';
import '../data/services/workout_service.dart';
import '../core/constants/subscription_tiers.dart';

class WorkoutProvider with ChangeNotifier {
  final ApiClient _apiClient;
  late final WorkoutService _workoutService;

  List<WorkoutPlan> _workoutPlans = [];
  WorkoutPlan? _currentPlan;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isFetchingPlan = false;
  String? _activeUserId;
  String? _error;
  int _requestGeneration = 0;

  // Workout Templates (static from DB)
  List<WorkoutTemplate> _workoutTemplates = [];
  bool _isLoadingTemplates = false;

  WorkoutProvider(this._apiClient) {
    _workoutService = WorkoutService(_apiClient);
  }

  List<WorkoutPlan> get workoutPlans => _workoutPlans;
  WorkoutPlan? get currentPlan => _currentPlan;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get activeUserId => _activeUserId;
  String? get error => _error;

  // Templates getters
  List<WorkoutTemplate> get workoutTemplates => _workoutTemplates;
  bool get isLoadingTemplates => _isLoadingTemplates;

  void syncAuthenticatedUser(String? userId) {
    if (_activeUserId == userId) return;

    _activeUserId = userId;
    _resetUserScopedState(isInitialized: userId == null);
    notifyListeners();
  }

  void _resetUserScopedState({required bool isInitialized}) {
    _requestGeneration++;
    _workoutPlans = [];
    _currentPlan = null;
    _isLoading = false;
    _isInitialized = isInitialized;
    _isFetchingPlan = false;
    _isGenerating = false;
    _error = null;
  }

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
    final userId = _activeUserId;
    final requestGeneration = _requestGeneration;
    if (userId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _workoutService.getWorkoutPlans();

    if (!_isCurrentUserRequest(userId, requestGeneration)) return;

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
    final userId = _activeUserId;
    final requestGeneration = _requestGeneration;
    if (userId == null) {
      _resetUserScopedState(isInitialized: true);
      notifyListeners();
      return;
    }

    // Prevent concurrent fetches - if already fetching, skip
    if (_isFetchingPlan) {
      debugPrint('DEBUG: fetchCurrentPlan already in progress, skipping');
      return;
    }
    _isFetchingPlan = true;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _workoutService.getCurrentPlan();
      if (!_isCurrentUserRequest(userId, requestGeneration)) return;

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

        // If plan is processing, start polling until fully completed
        if (_currentPlan?.status == 'processing' && !_isGenerating) {
          debugPrint('DEBUG: Plan is processing, starting poll');
          _isGenerating = true;
          _pollPlanStatus(
            _currentPlan!.id,
            userId: userId,
            requestGeneration: requestGeneration,
          );
        }
      } else {
        // No plan found is not an error - it's expected for new users
        debugPrint('DEBUG: No current plan found: ${result['message']}');
        _currentPlan = null;
        _isGenerating = false;
        _error = null; // Don't show error for "no plan found"
      }
    } catch (e) {
      if (!_isCurrentUserRequest(userId, requestGeneration)) return;

      debugPrint('ERROR fetching current plan: $e');
      _isLoading = false;
      _currentPlan = null;
      _isGenerating = false;
      _error = null; // Don't show error for new users without plans
    } finally {
      if (_isCurrentUserRequest(userId, requestGeneration)) {
        _isInitialized = true;
        _isFetchingPlan = false;
      }
    }

    notifyListeners();
  }

  Future<bool> generatePlan({
    String? language,
    bool includeHistory = false,
  }) async {
    final userId = _activeUserId;
    final requestGeneration = _requestGeneration;
    if (userId == null) return false;

    _isLoading = true;
    _error = null;
    Future.microtask(() => notifyListeners());

    final result = await _workoutService.generatePlan(
      language: language,
      includeHistory: includeHistory,
    );

    if (!_isCurrentUserRequest(userId, requestGeneration)) return false;

    if (result['success']) {
      final plan = result['plan'];
      _currentPlan = plan;

      // If plan is processing, start polling
      if (plan.status == 'processing') {
        _isGenerating = true;
        _pollPlanStatus(
          plan.id,
          userId: userId,
          requestGeneration: requestGeneration,
        );
      }

      _isLoading = false;
      Future.microtask(() => notifyListeners());
      return true;
    } else {
      _error = result['message'];
      _isLoading = false;
      Future.microtask(() => notifyListeners());
      return false;
    }
  }

  Future<bool> generateCustomPlan(
    Map<String, dynamic> filters, {
    String? language,
  }) async {
    final userId = _activeUserId;
    final requestGeneration = _requestGeneration;
    if (userId == null) return false;

    _isLoading = true;
    _error = null;
    Future.microtask(() => notifyListeners());

    debugPrint('DEBUG: Generating custom plan with filters: $filters');
    final result = await _workoutService.generatePlan(
      filters: filters,
      language: language,
    );

    if (!_isCurrentUserRequest(userId, requestGeneration)) return false;

    if (result['success']) {
      final plan = result['plan'];
      _currentPlan = plan;
      // If plan is processing, start polling
      if (plan.status == 'processing') {
        _isGenerating = true;
        _pollPlanStatus(
          plan.id,
          userId: userId,
          requestGeneration: requestGeneration,
        );
      }
      _isLoading = false;
      Future.microtask(() => notifyListeners());
      return true;
    } else {
      _error = result['message'];
      _isLoading = false;
      Future.microtask(() => notifyListeners());
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

  // Callback listeners for when generation completes
  final List<VoidCallback> _generationCompleteListeners = [];

  void addGenerationCompleteListener(VoidCallback callback) {
    _generationCompleteListeners.add(callback);
  }

  void removeGenerationCompleteListener(VoidCallback callback) {
    _generationCompleteListeners.remove(callback);
  }

  void _notifyGenerationComplete() {
    for (final listener in List.of(_generationCompleteListeners)) {
      listener();
    }
  }

  void _pollPlanStatus(
    String planId, {
    required String userId,
    required int requestGeneration,
  }) async {
    int attempts = 0;
    const maxAttempts = 100; // 5 minutes (3s * 100)

    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 3));
      if (!_isCurrentUserRequest(userId, requestGeneration)) return;

      try {
        debugPrint('Polling attempt $attempts for plan $planId...');

        // Fetch specific plan by ID
        final result = await _workoutService.getPlanById(planId);
        if (!_isCurrentUserRequest(userId, requestGeneration)) return;

        if (result['success']) {
          final plan = result['plan'] as WorkoutPlan?;

          if (plan != null && plan.userId == userId) {
            debugPrint('Fetched plan: ${plan.id}, Status: ${plan.status}');

            if (plan.status == 'completed') {
              debugPrint('Plan generation completed!');
              _currentPlan = plan;
              _isGenerating = false;
              _isLoading = false;
              notifyListeners();
              // Refresh full list in background
              fetchWorkoutPlans();
              // Trigger listeners
              _notifyGenerationComplete();
              return;
            } else if (plan.status == 'failed') {
              debugPrint('Plan generation failed: ${plan.errorMessage}');
              _error = plan.errorMessage ?? 'Generation failed';
              _isGenerating = false;
              _isLoading = false;
              notifyListeners();
              return;
            }
            // If still processing, continue polling — wait for FinalizeWorkoutPlan
            // to mark status as 'completed' before showing to user
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
      if (!_isCurrentUserRequest(userId, requestGeneration)) return;

      if (result['success'] && result['plan'] != null) {
        final plan = result['plan'] as WorkoutPlan;
        if (plan.userId != userId) return;

        _currentPlan = plan;
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

  bool _isCurrentUserRequest(String userId, int requestGeneration) {
    return _activeUserId == userId && _requestGeneration == requestGeneration;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if user can generate a new workout plan
  bool canGenerateNewPlan(UserModel user) {
    // Elite users always can
    // Using SubscriptionTierConfig logic which handles "0" as unlimited
    final config = SubscriptionTierConfig.fromTier(user.subscriptionTier);

    // If interval is 0, it's unlimited
    if (config.quotas.workoutPlanIntervalWeeks == 0) return true;

    if (user.lastPlanGeneration == null) {
      return true; // First time generating
    }

    final daysSinceLastGeneration = DateTime.now()
        .difference(user.lastPlanGeneration!)
        .inDays;

    final requiredDays = config.quotas.workoutPlanIntervalWeeks * 7;
    return daysSinceLastGeneration >= requiredDays;
  }

  /// Get days remaining until next plan generation is allowed
  int getDaysUntilNextGeneration(UserModel user) {
    if (user.lastPlanGeneration == null) {
      return 0; // Can generate immediately
    }

    final config = SubscriptionTierConfig.fromTier(user.subscriptionTier);
    if (config.quotas.workoutPlanIntervalWeeks == 0) return 0;

    final daysSinceLastGeneration = DateTime.now()
        .difference(user.lastPlanGeneration!)
        .inDays;

    final requiredDays = config.quotas.workoutPlanIntervalWeeks * 7;
    final remaining = requiredDays - daysSinceLastGeneration;

    return remaining > 0 ? remaining : 0;
  }
}
