import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'api_client.dart';
import '../../core/constants/api_config.dart';
import '../models/workout_model.dart';

class ExerciseService {
  final ApiClient _apiClient;

  ExerciseService(this._apiClient);

  /// Get the current device locale code (e.g., 'it' or 'en')
  String _getLocale() {
    if (kIsWeb) {
      // On web we can't use Platform.localeName
      return 'it'; // Default to 'it' for this app, or could use Locale logic if passed
    }
    final locale = Platform.localeName;
    if (locale.startsWith('it')) return 'it';
    return 'en';
  }

  Future<Map<String, dynamic>> getExercises({
    String? difficulty,
    String? muscleGroup,
    String? equipment,
    String? locale,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (difficulty != null) queryParams['difficulty'] = difficulty;
      if (muscleGroup != null) queryParams['muscle_group'] = muscleGroup;
      if (equipment != null) queryParams['equipment'] = equipment;
      // Add locale for translations
      queryParams['locale'] = locale ?? _getLocale();

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
    } catch (e, stackTrace) {
      debugPrint('Error in getExercises: $e');
      debugPrint('StackTrace: $stackTrace');
      return {
        'success': false,
        'message': e is DioException
            ? (e.response?.data['message'] ?? 'Failed to fetch exercises')
            : 'Error parsing exercises data: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getExercise(String id) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConfig.exercises}/$id',
        queryParameters: {'locale': _getLocale()},
      );

      if (response.statusCode == 200) {
        return {'success': true, 'exercise': Exercise.fromJson(response.data)};
      }

      return {'success': false, 'message': 'Failed to fetch exercise'};
    } catch (e) {
      return {
        'success': false,
        'message': e is DioException
            ? (e.response?.data['message'] ?? 'Failed to fetch exercise')
            : 'Error parsing exercise data',
      };
    }
  }

  /// Get similar exercises that target the same muscle groups
  Future<Map<String, dynamic>> getSimilarExercises(String exerciseId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConfig.exercises}/$exerciseId/similar',
        queryParameters: {'locale': _getLocale()},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final exercises = data.map((json) => Exercise.fromJson(json)).toList();
        return {'success': true, 'exercises': exercises};
      }

      return {'success': false, 'message': 'Failed to fetch similar exercises'};
    } catch (e) {
      return {
        'success': false,
        'message': e is DioException
            ? (e.response?.data['message'] ??
                  'Failed to fetch similar exercises')
            : 'Error parsing similar exercises',
      };
    }
  }

  /// Get alternative exercises (bodyweight <-> equipment)
  Future<Map<String, dynamic>> getAlternativeExercises(
    String exerciseId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConfig.exercises}/$exerciseId/alternatives',
        queryParameters: {'locale': _getLocale()},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final alternatives = (data['alternatives'] as List<dynamic>)
            .map((json) => Exercise.fromJson(json))
            .toList();
        return {
          'success': true,
          'currentType': data['current_type'] as String,
          'currentEquipment': List<String>.from(
            data['current_equipment'] ?? [],
          ),
          'alternatives': alternatives,
        };
      }

      return {
        'success': false,
        'message': 'Failed to fetch alternative exercises',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e is DioException
            ? (e.response?.data['message'] ??
                  'Failed to fetch alternative exercises')
            : 'Error parsing alternative exercises',
      };
    }
  }
}
