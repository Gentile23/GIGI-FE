import 'package:flutter/foundation.dart';
import 'package:gigi/data/models/workout_log_model.dart';
import 'package:gigi/data/services/workout_log_service.dart';
import 'package:gigi/data/services/workout_stats_service.dart';
import 'package:gigi/data/services/api_client.dart';

class WorkoutLogProvider with ChangeNotifier {
  late final WorkoutLogService _logService;
  late final WorkoutStatsService _statsService;

  WorkoutLogProvider(ApiClient apiClient) {
    _logService = WorkoutLogService(apiClient);
    _statsService = WorkoutStatsService(apiClient);
  }

  // Current active session
  WorkoutLog? _currentWorkoutLog;
  bool _isLoading = false;
  String? _error;

  // History and Stats
  List<WorkoutLog> _workoutHistory = [];
  WorkoutStats? _stats;
  List<PersonalRecord> _recentRecords = [];

  // Getters
  WorkoutLog? get currentWorkoutLog => _currentWorkoutLog;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<WorkoutLog> get workoutHistory => _workoutHistory;
  WorkoutStats? get stats => _stats;
  List<PersonalRecord> get recentRecords => _recentRecords;
  bool get hasActiveWorkout =>
      _currentWorkoutLog != null && _currentWorkoutLog!.completedAt == null;

  /// Start a new workout session
  Future<void> startWorkout({
    String? workoutPlanId,
    String? workoutDayId,
  }) async {
    _setLoading(true);
    try {
      debugPrint(
        'DEBUG Provider: Calling startWorkout with dayId=$workoutDayId',
      );
      _currentWorkoutLog = await _logService.startWorkout(
        workoutPlanId: workoutPlanId,
        workoutDayId: workoutDayId,
      );
      debugPrint(
        'DEBUG Provider: Workout log created: ${_currentWorkoutLog?.id}',
      );
      _recentRecords = []; // Reset records for new session
      notifyListeners();
    } catch (e) {
      debugPrint('DEBUG Provider: ERROR in startWorkout: $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Complete the current workout
  Future<void> completeWorkout({String? notes}) async {
    if (_currentWorkoutLog == null) return;

    _setLoading(true);
    try {
      final completedLog = await _logService.completeWorkout(
        _currentWorkoutLog!.id,
        notes: notes,
      );

      // Update history
      _workoutHistory.insert(0, completedLog);
      _currentWorkoutLog = null;

      // Refresh stats
      await fetchOverviewStats();
      await fetchWorkoutHistory(refresh: true);

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Add exercise to current workout
  Future<ExerciseLogModel?> addExerciseLog({
    required String exerciseId,
    required int orderIndex,
    String exerciseType = 'main',
    String? notes,
  }) async {
    if (_currentWorkoutLog == null) return null;

    try {
      final exerciseLog = await _logService.addExerciseLog(
        workoutLogId: _currentWorkoutLog!.id,
        exerciseId: exerciseId,
        orderIndex: orderIndex,
        exerciseType: exerciseType,
        notes: notes,
      );

      // Update local state
      _currentWorkoutLog!.exerciseLogs.add(exerciseLog);
      notifyListeners();

      return exerciseLog;
    } catch (e) {
      debugPrint('Error adding exercise log: $e');
      return null;
    }
  }

  /// Add set to exercise
  Future<void> addSetLog({
    required String exerciseLogId,
    required int setNumber,
    required int reps,
    double? weightKg,
    int? durationSeconds,
    int? rpe,
    bool completed = true,
  }) async {
    try {
      final result = await _logService.addSetLog(
        exerciseLogId: exerciseLogId,
        setNumber: setNumber,
        reps: reps,
        weightKg: weightKg,
        durationSeconds: durationSeconds,
        rpe: rpe,
        completed: completed,
      );

      final setLog = result['set_log'] as SetLogModel;
      final newRecords = result['new_records'] as List<PersonalRecord>;

      // Update local state
      _updateLocalSetLog(exerciseLogId, setLog);

      if (newRecords.isNotEmpty) {
        _recentRecords.addAll(newRecords);
        // Could trigger a notification or toast here
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding set log: $e');
    }
  }

  /// Fetch workout history
  Future<void> fetchWorkoutHistory({bool refresh = false}) async {
    if (_workoutHistory.isNotEmpty && !refresh) return;

    _setLoading(true);
    try {
      _workoutHistory = await _logService.getWorkoutLogs();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch overview stats
  Future<void> fetchOverviewStats({String period = 'all'}) async {
    try {
      _stats = await _statsService.getOverviewStats(period: period);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
  }

  /// Get last performance for an exercise (previous workout data)
  Future<Map<String, dynamic>?> getExerciseLastPerformance(
    String exerciseId,
  ) async {
    return await _logService.getExerciseLastPerformance(exerciseId);
  }

  // Helper to update local state deeply
  void _updateLocalSetLog(String exerciseLogId, SetLogModel setLog) {
    if (_currentWorkoutLog == null) return;

    final exerciseIndex = _currentWorkoutLog!.exerciseLogs.indexWhere(
      (e) => e.id == exerciseLogId,
    );

    if (exerciseIndex != -1) {
      final exerciseLog = _currentWorkoutLog!.exerciseLogs[exerciseIndex];

      // Check if set already exists (update) or is new (add)
      final setIndex = exerciseLog.setLogs.indexWhere((s) => s.id == setLog.id);

      if (setIndex != -1) {
        exerciseLog.setLogs[setIndex] = setLog;
      } else {
        exerciseLog.setLogs.add(setLog);
      }

      // We need to trigger a rebuild of the object tree if we want immutable updates
      // For now, we're mutating the list which works with ChangeNotifier
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }
}
