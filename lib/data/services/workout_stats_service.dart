import 'package:gigi/data/models/workout_log_model.dart';
import 'package:gigi/data/services/api_service.dart';

class WorkoutStatsService extends ApiService {
  WorkoutStatsService(super.apiClient);

  /// Get overview statistics
  Future<WorkoutStats> getOverviewStats({String period = 'all'}) async {
    final response = await get(
      'stats/overview',
      queryParameters: {'period': period},
    );

    if (response['success'] == true) {
      return WorkoutStats.fromJson(response['stats']);
    } else {
      throw Exception('Failed to get overview stats');
    }
  }

  /// Get exercise-specific progress
  Future<Map<String, dynamic>> getExerciseProgress(
    String exerciseId, {
    int limit = 20,
  }) async {
    final response = await get(
      'stats/exercise/$exerciseId',
      queryParameters: {'limit': limit.toString()},
    );

    if (response['success'] == true) {
      return {
        'exercise': response['exercise'],
        'progression': response['progression'],
        'personal_records': response['personal_records'],
        'stats': response['stats'],
      };
    } else {
      throw Exception('Failed to get exercise progress');
    }
  }

  /// Get all personal records
  Future<List<Map<String, dynamic>>> getPersonalRecords({String? type}) async {
    final queryParams = <String, String>{};
    if (type != null) queryParams['type'] = type;

    final response = await get(
      'stats/personal-records',
      queryParameters: queryParams,
    );

    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['personal_records']);
    } else {
      throw Exception('Failed to get personal records');
    }
  }

  /// Get muscle group statistics
  Future<List<Map<String, dynamic>>> getMuscleGroupStats({
    String period = 'month',
  }) async {
    final response = await get(
      'stats/muscle-groups',
      queryParameters: {'period': period},
    );

    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['muscle_groups']);
    } else {
      throw Exception('Failed to get muscle group stats');
    }
  }

  /// Get workout trends
  Future<List<Map<String, dynamic>>> getTrends({
    String period = 'month',
    String groupBy = 'day',
  }) async {
    final response = await get(
      'stats/trends',
      queryParameters: {'period': period, 'group_by': groupBy},
    );

    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['trends']);
    } else {
      throw Exception('Failed to get trends');
    }
  }
}
