import '../models/adaptive_training_model.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class AdaptiveTrainingService {
  final ApiClient _apiClient;

  AdaptiveTrainingService(this._apiClient);

  Future<PerformanceAnalysis?> getAnalysis() async {
    try {
      final response = await _apiClient.dio.get('/adaptive/analysis');
      return PerformanceAnalysis.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching analysis: $e');
      return null;
    }
  }

  Future<List<TrainingRecommendation>?> getRecommendations() async {
    try {
      final response = await _apiClient.dio.get('/adaptive/recommendations');

      return (response.data['recommendations'] as List)
          .map((json) => TrainingRecommendation.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching recommendations: $e');
      return null;
    }
  }

  Future<bool> applyRecommendation(int recommendationId) async {
    try {
      await _apiClient.dio.post(
        '/adaptive/recommendations/$recommendationId/apply',
      );
      return true;
    } catch (e) {
      debugPrint('Error applying recommendation: $e');
      return false;
    }
  }

  Future<bool> dismissRecommendation(int recommendationId) async {
    try {
      await _apiClient.dio.delete(
        '/adaptive/recommendations/$recommendationId',
      );
      return true;
    } catch (e) {
      debugPrint('Error dismissing recommendation: $e');
      return false;
    }
  }

  Future<RecoveryScore?> submitRecoveryData({
    required int sleepQuality,
    required int muscleSoreness,
    required int stressLevel,
    required int energyLevel,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/adaptive/recovery',
        data: {
          'sleep_quality': sleepQuality,
          'muscle_soreness': muscleSoreness,
          'stress_level': stressLevel,
          'energy_level': energyLevel,
        },
      );

      return RecoveryScore.fromJson(response.data['recovery_score']);
    } catch (e) {
      debugPrint('Error submitting recovery data: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getRecoveryHistory({int days = 30}) async {
    try {
      final response = await _apiClient.dio.get(
        '/adaptive/recovery/history',
        queryParameters: {'days': days},
      );

      return {
        'history': (response.data['history'] as List)
            .map((json) => RecoveryScore.fromJson(json))
            .toList(),
        'average_score': response.data['average_score'],
        'average_readiness': response.data['average_readiness'],
      };
    } catch (e) {
      debugPrint('Error fetching recovery history: $e');
      return null;
    }
  }
}
