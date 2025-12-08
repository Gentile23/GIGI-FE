import '../models/trial_workout_model.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class TrialWorkoutService {
  final ApiClient _apiClient;

  TrialWorkoutService(this._apiClient);

  /// Generate trial workout for user
  Future<TrialWorkout?> generateTrialWorkout() async {
    try {
      final response = await _apiClient.dio.post('/trial-workout/generate');

      if (response.statusCode == 200) {
        return TrialWorkout.fromJson(response.data);
      }

      return null;
    } catch (e) {
      debugPrint('Error generating trial workout: $e');
      return null;
    }
  }

  /// Submit trial workout results
  Future<TrialCompletionResponse?> submitTrialResults(
    TrialPerformanceData performanceData,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '/trial-workout/complete',
        data: performanceData.toJson(),
      );

      if (response.statusCode == 200) {
        return TrialCompletionResponse.fromJson(response.data);
      }

      return null;
    } catch (e) {
      debugPrint('Error submitting trial results: $e');
      return null;
    }
  }

  /// Get trial workout status
  Future<Map<String, dynamic>?> getTrialStatus() async {
    try {
      final response = await _apiClient.dio.get('/trial-workout/status');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting trial status: $e');
      return null;
    }
  }
}
