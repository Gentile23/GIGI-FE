import 'package:flutter/foundation.dart';
import 'package:gigi/data/models/workout_log_model.dart';
import 'package:gigi/data/services/api_service.dart';

class WorkoutLogService extends ApiService {
  WorkoutLogService(super.apiClient);

  /// Start a new workout session
  Future<WorkoutLog> startWorkout({
    String? workoutPlanId,
    String? workoutDayId,
  }) async {
    final customWorkoutPlanId = _extractCustomWorkoutPlanId(workoutDayId);
    final normalizedWorkoutDayId = customWorkoutPlanId != null
        ? null
        : workoutDayId;

    debugPrint(
      'DEBUG Service: POST workout-logs/start with dayId=$workoutDayId',
    );
    final response = await post(
      'workout-logs/start',
      body: {
        if (workoutPlanId != null) 'workout_plan_id': workoutPlanId,
        if (normalizedWorkoutDayId != null)
          'workout_day_id': normalizedWorkoutDayId,
        if (customWorkoutPlanId != null)
          'custom_workout_plan_id': customWorkoutPlanId,
      },
    );

    debugPrint('DEBUG Service: Response = $response');

    final payload = _extractWorkoutLogPayload(response);
    if (_isSuccessResponse(response) && payload != null) {
      return WorkoutLog.fromJson(payload);
    }

    final error = _extractErrorMessage(
      response,
      fallback: 'Failed to start workout',
    );
    debugPrint('DEBUG Service: API Error = $error');
    throw Exception(error);
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
    debugPrint('DEBUG Service: Complete workout response = $response');

    final payload = _extractWorkoutLogPayload(response);
    if (_isSuccessResponse(response) && payload != null) {
      return WorkoutLog.fromJson(payload);
    }

    // Some backends return success without embedding the full workout log.
    if (_isSuccessResponse(response)) {
      try {
        return await getWorkoutLogDetails(workoutLogId);
      } catch (_) {
        return WorkoutLog(
          id: workoutLogId,
          userId: '0',
          startedAt: DateTime.now(),
          completedAt: DateTime.now(),
          notes: notes,
          exerciseLogs: const [],
        );
      }
    }

    throw Exception(
      _extractErrorMessage(response, fallback: 'Failed to complete workout'),
    );
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

    final payload = _extractExerciseLogPayload(response);
    if (_isSuccessResponse(response) && payload != null) {
      return ExerciseLogModel.fromJson(payload);
    }

    throw Exception(
      _extractErrorMessage(response, fallback: 'Failed to add exercise log'),
    );
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

    final payload = _extractSetLogPayload(response);
    if (_isSuccessResponse(response) && payload != null) {
      final setLog = SetLogModel.fromJson(payload);
      final nestedData = _asMap(response['data']);
      final rawRecords = response['new_records'] ?? nestedData?['new_records'];
      final recordsList = rawRecords is List ? rawRecords : const [];
      final newRecords = recordsList
          .map((e) => _asMap(e))
          .whereType<Map<String, dynamic>>()
          .map(PersonalRecord.fromJson)
          .toList();

      return {'set_log': setLog, 'new_records': newRecords};
    }

    throw Exception(
      _extractErrorMessage(response, fallback: 'Failed to add set log'),
    );
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

    final payload = _extractSetLogPayload(response);
    if (_isSuccessResponse(response) && payload != null) {
      return SetLogModel.fromJson(payload);
    }

    throw Exception(
      _extractErrorMessage(response, fallback: 'Failed to update set log'),
    );
  }

  Future<void> deleteSetLog(String setLogId) async {
    final response = await delete('set-logs/$setLogId');

    if (!_isSuccessResponse(response)) {
      throw Exception(
        _extractErrorMessage(response, fallback: 'Failed to delete set log'),
      );
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
    final rawLogs = response['logs'] ?? response['data'];

    if (rawLogs is List) {
      return rawLogs
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
          'has_previous': true,
          'workout_date': response['workout_date'],
          'sets': response['sets'] as List,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  bool _isSuccessResponse(Map<String, dynamic> response) {
    final success = response['success'];
    if (success is bool) return success;
    final status = response['status'];
    if (status is String) {
      final normalized = status.trim().toLowerCase();
      if (normalized == 'success' || normalized == 'ok') return true;
      if (normalized == 'error' || normalized == 'failed') return false;
    }
    // Many endpoints return payload directly without explicit success flag.
    return true;
  }

  String _extractErrorMessage(
    Map<String, dynamic> response, {
    required String fallback,
  }) {
    final message = response['message'];
    if (message is String && message.trim().isNotEmpty) return message;
    final error = response['error'];
    if (error is String && error.trim().isNotEmpty) return error;
    final nestedData = _asMap(response['data']);
    final nestedMessage = nestedData?['message'];
    if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
      return nestedMessage;
    }
    return fallback;
  }

  Map<String, dynamic>? _extractWorkoutLogPayload(
    Map<String, dynamic> response,
  ) {
    final nestedData = _asMap(response['data']);
    return _asMap(response['workout_log']) ??
        _asMap(response['workoutLog']) ??
        _asMap(response['workout']) ??
        _asMap(nestedData?['workout_log']) ??
        _asMap(nestedData?['workoutLog']) ??
        _asMap(nestedData?['workout']) ??
        (nestedData != null && nestedData['id'] != null ? nestedData : null) ??
        (response['id'] != null ? response : null);
  }

  Map<String, dynamic>? _extractExerciseLogPayload(
    Map<String, dynamic> response,
  ) {
    final nestedData = _asMap(response['data']);
    return _asMap(response['exercise_log']) ??
        _asMap(response['exerciseLog']) ??
        _asMap(nestedData?['exercise_log']) ??
        _asMap(nestedData?['exerciseLog']) ??
        (nestedData != null && nestedData['workout_log_id'] != null
            ? nestedData
            : null);
  }

  Map<String, dynamic>? _extractSetLogPayload(Map<String, dynamic> response) {
    final nestedData = _asMap(response['data']);
    return _asMap(response['set_log']) ??
        _asMap(response['setLog']) ??
        _asMap(nestedData?['set_log']) ??
        _asMap(nestedData?['setLog']) ??
        (nestedData != null && nestedData['set_number'] != null
            ? nestedData
            : null);
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  String? _extractCustomWorkoutPlanId(String? workoutDayId) {
    if (workoutDayId == null) return null;
    const prefix = 'custom_';
    if (!workoutDayId.startsWith(prefix)) return null;
    final customPlanId = workoutDayId.substring(prefix.length).trim();
    return customPlanId.isEmpty ? null : customPlanId;
  }
}
