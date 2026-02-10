import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'api_client.dart';
import '../../core/constants/api_config.dart';
import '../models/custom_workout_model.dart';

class CustomWorkoutService {
  final ApiClient _apiClient;

  CustomWorkoutService(this._apiClient);

  /// Get all custom workout plans for the current user
  Future<Map<String, dynamic>> getCustomWorkouts() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.customWorkouts);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final plans = data
            .map((json) => CustomWorkoutPlan.fromJson(json))
            .toList();
        return {'success': true, 'plans': plans};
      }

      return {'success': false, 'message': 'Failed to fetch custom workouts'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data['message'] ?? 'Failed to fetch custom workouts',
      };
    }
  }

  /// Create a new custom workout plan
  Future<Map<String, dynamic>> createCustomWorkout(
    CustomWorkoutRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.customWorkouts,
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'plan': CustomWorkoutPlan.fromJson(response.data),
        };
      }

      return {'success': false, 'message': 'Failed to create custom workout'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data['message'] ?? 'Failed to create custom workout',
      };
    }
  }

  /// Get a specific custom workout plan
  Future<Map<String, dynamic>> getCustomWorkout(String id) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConfig.customWorkouts}/$id',
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'plan': CustomWorkoutPlan.fromJson(response.data),
        };
      }

      return {'success': false, 'message': 'Failed to fetch custom workout'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data['message'] ?? 'Failed to fetch custom workout',
      };
    }
  }

  /// Update a custom workout plan
  Future<Map<String, dynamic>> updateCustomWorkout(
    String id,
    CustomWorkoutRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConfig.customWorkouts}/$id',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'plan': CustomWorkoutPlan.fromJson(response.data),
        };
      }

      return {'success': false, 'message': 'Failed to update custom workout'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data['message'] ?? 'Failed to update custom workout',
      };
    }
  }

  /// Delete a custom workout plan
  Future<Map<String, dynamic>> deleteCustomWorkout(String id) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiConfig.customWorkouts}/$id',
      );

      if (response.statusCode == 200) {
        return {'success': true};
      }

      return {'success': false, 'message': 'Failed to delete custom workout'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data['message'] ?? 'Failed to delete custom workout',
      };
    }
  }

  /// Upload Workout PDF
  Future<Map<String, dynamic>> uploadWorkoutPdf(PlatformFile file) async {
    try {
      String fileName = file.name;
      MultipartFile multipartFile;

      if (file.bytes != null) {
        multipartFile = MultipartFile.fromBytes(
          file.bytes!,
          filename: fileName,
        );
      } else {
        multipartFile = await MultipartFile.fromFile(
          file.path!,
          filename: fileName,
        );
      }

      FormData formData = FormData.fromMap({'pdf_file': multipartFile});

      final response = await _apiClient.dio.post(
        '${ApiConfig.customWorkouts}/upload-pdf',
        data: formData,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'plan': CustomWorkoutPlan.fromJson(response.data['plan']),
        };
      }

      return {'success': false, 'message': 'Upload failed'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Upload failed',
      };
    }
  }

  /// Add an exercise to a custom workout plan
  Future<Map<String, dynamic>> addExercise(
    String planId,
    CustomWorkoutExerciseRequest request,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConfig.customWorkouts}/$planId/exercises',
        data: request.toJson(),
      );

      if (response.statusCode == 201) {
        return {'success': true, 'exercise': response.data};
      }

      return {'success': false, 'message': 'Failed to add exercise'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to add exercise',
      };
    }
  }

  /// Update an exercise in a custom workout plan
  Future<Map<String, dynamic>> updateExercise(
    String planId,
    String exerciseId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConfig.customWorkouts}/$planId/exercises/$exerciseId',
        data: updates,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'exercise': response.data};
      }

      return {'success': false, 'message': 'Failed to update exercise'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to update exercise',
      };
    }
  }

  /// Remove an exercise from a custom workout plan
  Future<Map<String, dynamic>> removeExercise(
    String planId,
    String exerciseId,
  ) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiConfig.customWorkouts}/$planId/exercises/$exerciseId',
      );

      if (response.statusCode == 200) {
        return {'success': true};
      }

      return {'success': false, 'message': 'Failed to remove exercise'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to remove exercise',
      };
    }
  }

  /// Reorder exercises in a custom workout plan
  Future<Map<String, dynamic>> reorderExercises(
    String planId,
    List<String> exerciseIds,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConfig.customWorkouts}/$planId/reorder',
        data: {'exercise_ids': exerciseIds},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'plan': CustomWorkoutPlan.fromJson(response.data),
        };
      }

      return {'success': false, 'message': 'Failed to reorder exercises'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to reorder exercises',
      };
    }
  }
}
