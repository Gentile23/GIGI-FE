import 'package:fitgenius/data/models/workout_log_model.dart';
import 'package:fitgenius/data/services/api_service.dart';

class WorkoutLogService extends ApiService {
  WorkoutLogService(super.apiClient);

  /// Start a new workout session
  Future<WorkoutLog> startWorkout({
    String? workoutPlanId,
    String? workoutDayId,
  }) async {
    final response = await post(
      'workout-logs/start',
      body: {
        if (workoutPlanId != null) 'workout_plan_id': workoutPlanId,
        if (workoutDayId != null) 'workout_day_id': workoutDayId,
      },
    );

    if (response['success'] == true) {
      return WorkoutLog.fromJson(response['workout_log']);
    } else {
      throw Exception('Failed to start workout');
    }
  }

  /// Complete a workout session
  Future<WorkoutLog> completeWorkout(
    String workoutLogId, {
    String? notes,
  }) async {
    final response = await post(
      'workout-logs/$workoutLogId/complete',
      body: {if (notes != null) 'notes': notes},
    );

    if (response['success'] == true) {
      return WorkoutLog.fromJson(response['workout_log']);
    } else {
      throw Exception('Failed to complete workout');
    }
  }

  /// Add an exercise to the workout session
  Future<ExerciseLogModel> addExerciseLog({
    required String workoutLogId,
    required String exerciseId,
    required int orderIndex,
    String exerciseType = 'main',
    String? notes,
  }) async {
    final response = await post(
      'workout-logs/$workoutLogId/exercises',
      body: {
        'exercise_id': exerciseId,
        'order_index': orderIndex,
        'exercise_type': exerciseType,
        if (notes != null) 'notes': notes,
      },
    );

    if (response['success'] == true) {
      return ExerciseLogModel.fromJson(response['exercise_log']);
    } else {
      throw Exception('Failed to add exercise log');
    }
  }

  /// Add a set to an exercise log
  Future<Map<String, dynamic>> addSetLog({
    required String exerciseLogId,
    required int setNumber,
    required int reps,
    double? weightKg,
    int? durationSeconds,
    int? rpe,
    bool completed = true,
  }) async {
    final response = await post(
      'exercise-logs/$exerciseLogId/sets',
      body: {
        'set_number': setNumber,
        'reps': reps,
        if (weightKg != null) 'weight_kg': weightKg,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        if (rpe != null) 'rpe': rpe,
        'completed': completed,
      },
    );

    if (response['success'] == true) {
      final setLog = SetLogModel.fromJson(response['set_log']);
      final newRecords = (response['new_records'] as List)
          .map((e) => PersonalRecord.fromJson(e))
          .toList();

      return {'set_log': setLog, 'new_records': newRecords};
    } else {
      throw Exception('Failed to add set log');
    }
  }

  /// Update a set log
  Future<SetLogModel> updateSetLog(
    String setLogId, {
    int? reps,
    double? weightKg,
    int? durationSeconds,
    int? rpe,
    bool? completed,
  }) async {
    final response = await put(
      'set-logs/$setLogId',
      body: {
        if (reps != null) 'reps': reps,
        if (weightKg != null) 'weight_kg': weightKg,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
        if (rpe != null) 'rpe': rpe,
        if (completed != null) 'completed': completed,
      },
    );

    if (response['success'] == true) {
      return SetLogModel.fromJson(response['set_log']);
    } else {
      throw Exception('Failed to update set log');
    }
  }

  /// Get workout logs list
  Future<List<WorkoutLog>> getWorkoutLogs({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int perPage = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };

    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String();
    }

    final response = await get('workout-logs', queryParameters: queryParams);

    if (response['data'] != null) {
      return (response['data'] as List)
          .map((e) => WorkoutLog.fromJson(e))
          .toList();
    } else {
      return [];
    }
  }

  /// Get a specific workout log with details
  Future<WorkoutLog> getWorkoutLogDetails(String workoutLogId) async {
    final response = await get('workout-logs/$workoutLogId');

    if (response['success'] == true) {
      return WorkoutLog.fromJson(response['workout_log']);
    } else {
      throw Exception('Failed to get workout log details');
    }
  }

  /// Delete a workout log
  Future<void> deleteWorkoutLog(String workoutLogId) async {
    final response = await delete('workout-logs/$workoutLogId');

    if (response['success'] != true) {
      throw Exception('Failed to delete workout log');
    }
  }

  /// Get last performance for an exercise (previous workout data)
  Future<Map<String, dynamic>?> getExerciseLastPerformance(
    String exerciseId,
  ) async {
    try {
      final response = await get('exercises/$exerciseId/last-performance');

      if (response['success'] == true && response['has_previous'] == true) {
        return {
          'workout_date': response['workout_date'],
          'sets': response['sets'] as List,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
