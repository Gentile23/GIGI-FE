import 'package:dio/dio.dart';
import 'api_client.dart';
import '../../core/constants/api_config.dart';
import '../models/workout_model.dart';

class ExerciseService {
  final ApiClient _apiClient;

  ExerciseService(this._apiClient);

  Future<Map<String, dynamic>> getExercises({
    String? difficulty,
    String? muscleGroup,
    String? equipment,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (difficulty != null) queryParams['difficulty'] = difficulty;
      if (muscleGroup != null) queryParams['muscle_group'] = muscleGroup;
      if (equipment != null) queryParams['equipment'] = equipment;

      final response = await _apiClient.dio.get(
        ApiConfig.exercises,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final exercises = data.map((json) => Exercise.fromJson(json)).toList();
        return {'success': true, 'exercises': exercises};
      }

      return {'success': false, 'message': 'Failed to fetch exercises'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to fetch exercises',
      };
    }
  }

  Future<Map<String, dynamic>> getExercise(String id) async {
    try {
      final response = await _apiClient.dio.get('${ApiConfig.exercises}/$id');

      if (response.statusCode == 200) {
        return {'success': true, 'exercise': Exercise.fromJson(response.data)};
      }

      return {'success': false, 'message': 'Failed to fetch exercise'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to fetch exercise',
      };
    }
  }
}
