import '../models/voice_coaching_model.dart';
import 'api_client.dart';

class VoiceCoachingService {
  final ApiClient _apiClient;

  VoiceCoachingService(this._apiClient);

  /// Get voice coaching for an exercise (returns cached if available)
  Future<VoiceCoaching?> getVoiceCoaching(String exerciseId) async {
    try {
      final response = await _apiClient.dio.get(
        '/exercises/$exerciseId/voice-coaching',
      );

      if (response.statusCode == 200) {
        return VoiceCoaching.fromJson(response.data);
      }

      return null;
    } catch (e) {
      print('Error getting voice coaching: $e');
      return null;
    }
  }

  /// Generate voice coaching for an exercise
  /// Set isTrial to true when calling from trial workout
  /// Provide sets and reps for structured output generation
  Future<VoiceCoaching?> generateVoiceCoaching(
    String exerciseId, {
    bool isTrial = false,
    int sets = 3,
    int reps = 10,
    bool structured = true,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/exercises/$exerciseId/voice-coaching',
        data: {
          'is_trial': isTrial,
          'sets': sets,
          'reps': reps,
          'structured': structured,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return VoiceCoaching.fromJson(response.data);
      }

      return null;
    } catch (e) {
      print('Error generating voice coaching: $e');
      return null;
    }
  }

  /// Regenerate voice coaching for an exercise (force new generation)
  Future<VoiceCoaching?> regenerateVoiceCoaching(String exerciseId) async {
    try {
      final response = await _apiClient.dio.put(
        '/exercises/$exerciseId/voice-coaching',
      );

      if (response.statusCode == 200) {
        return VoiceCoaching.fromJson(response.data);
      }

      return null;
    } catch (e) {
      print('Error regenerating voice coaching: $e');
      return null;
    }
  }

  /// Check if user has access to voice coaching (premium feature)
  Future<bool> hasAccess() async {
    try {
      final response = await _apiClient.dio.get('/user');

      if (response.statusCode == 200) {
        final subscription = response.data['subscription'];
        if (subscription == null) return false;

        final tier = subscription['tier'] as String?;
        final isActive = subscription['is_active'] as bool? ?? false;

        return isActive && (tier == 'pro' || tier == 'elite');
      }

      return false;
    } catch (e) {
      print('Error checking voice coaching access: $e');
      return false;
    }
  }
}
