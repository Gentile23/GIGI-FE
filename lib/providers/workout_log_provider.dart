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

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  /// Start a new workout session
  Future<void> startWorkout({
    String? workoutPlanId,
    String? workoutDayId,
  }) async {
    _setLoading(true);
    _error = null;
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
      _error = null;
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
  Future<WorkoutLog?> completeWorkout({String? notes}) async {
    if (_currentWorkoutLog == null) return null;

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
      return completedLog;
    } catch (e) {
      _setError(e.toString());
      return null;
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
    if (_currentWorkoutLog == null) {
      _setError(
        'Sessione workout non inizializzata. Impossibile salvare l\'esercizio.',
      );
      return null;
    }

    try {
      _error = null;
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
      _setError(e.toString());
      debugPrint('Error adding exercise log: $e');
      return null;
    }
  }

  /// Add set to exercise
  Future<bool> addSetLog({
    required String exerciseLogId,
    required int setNumber,
    required int reps,
    double? weightKg,
    int? durationSeconds,
    int? rpe,
    bool completed = true,
  }) async {
    try {
      _error = null;
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
      return true;
    } catch (e) {
      _setError(e.toString());
      debugPrint('Error adding set log: $e');
      return false;
    }
  }

  /// Add multiple sets in bulk
  Future<bool> addBulkSets({
    required String exerciseLogId,
    required List<Map<String, dynamic>> sets,
  }) async {
    try {
      _error = null;
      final result = await _logService.addBulkSets(
        exerciseLogId: exerciseLogId,
        sets: sets,
      );

      final List<SetLogModel> setLogs = result['set_logs'];
      final List<PersonalRecord> newRecords = result['new_records'];

      // Update local state for each set
      for (final setLog in setLogs) {
        _updateLocalSetLog(exerciseLogId, setLog);
      }

      if (newRecords.isNotEmpty) {
        _recentRecords.addAll(newRecords);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      debugPrint('Error adding bulk sets: $e');
      return false;
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

  /// Update an existing set log
  Future<void> updateSetLog({
    required String setLogId,
    required String exerciseLogId, // Needed for local state update
    int? reps,
    double? weightKg,
    int? durationSeconds,
    int? rpe,
    bool? completed,
  }) async {
    try {
      _error = null;
      final updatedSet = await _logService.updateSetLog(
        setLogId,
        reps: reps,
        weightKg: weightKg,
        durationSeconds: durationSeconds,
        rpe: rpe,
        completed: completed,
      );

      // Update local state
      _updateLocalSetLog(exerciseLogId, updatedSet);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      debugPrint('Error updating set log: $e');
    }
  }

  Future<void> deleteSetLog({
    required String setLogId,
    required String exerciseLogId,
  }) async {
    try {
      await _logService.deleteSetLog(setLogId);
      _removeLocalSetLog(exerciseLogId, setLogId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting set log: $e');
      rethrow;
    }
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
        // Also check if setNumber already exists to avoid duplicates
        final setNumberIndex = exerciseLog.setLogs.indexWhere(
          (s) => s.setNumber == setLog.setNumber,
        );
        if (setNumberIndex != -1) {
          exerciseLog.setLogs[setNumberIndex] = setLog;
        } else {
          exerciseLog.setLogs.add(setLog);
        }
      }

      // Sort sets by set number to keep UI consistent
      exerciseLog.setLogs.sort((a, b) => a.setNumber.compareTo(b.setNumber));
    }
  }

  void _removeLocalSetLog(String exerciseLogId, String setLogId) {
    if (_currentWorkoutLog == null) return;

    final exerciseIndex = _currentWorkoutLog!.exerciseLogs.indexWhere(
      (e) => e.id == exerciseLogId,
    );

    if (exerciseIndex == -1) return;

    final exerciseLog = _currentWorkoutLog!.exerciseLogs[exerciseIndex];
    exerciseLog.setLogs.removeWhere((setLog) => setLog.id == setLogId);
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
