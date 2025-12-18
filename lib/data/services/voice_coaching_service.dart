import '../models/voice_coaching_model.dart';
import '../models/exercise_intro_model.dart';
import 'package:flutter/foundation.dart';
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
      debugPrint('Error getting voice coaching: $e');
      return null;
    }
  }

  /// Generate personalized exercise intro with user context
  /// Calls user by name, references goals, injuries, streak, and personal records
  Future<ExerciseIntroScript?> getPersonalizedIntro(String exerciseId) async {
    try {
      final response = await _apiClient.dio.post(
        '/exercises/$exerciseId/voice-coaching/intro',
      );

      if (response.statusCode == 200) {
        return ExerciseIntroScript.fromJson(response.data);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting personalized intro: $e');
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
      debugPrint('Error generating voice coaching: $e');
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
      debugPrint('Error regenerating voice coaching: $e');
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
      debugPrint('Error checking voice coaching access: $e');
      return false;
    }
  }

  /// Get synced voice coaching scripts for workout synchronization
  /// Returns pre-set scripts, rep cues, rest countdown, etc.
  Future<Map<String, dynamic>?> getSyncedCoaching(
    String exerciseId, {
    int sets = 3,
    int reps = 10,
    int restSeconds = 90,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/exercises/$exerciseId/voice-coaching/synced',
        data: {'sets': sets, 'reps': reps, 'rest_seconds': restSeconds},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting synced coaching: $e');
      return null;
    }
  }

  /// Get AI-generated guided execution script for "Esegui con Gigi"
  /// Returns personalized step-by-step guide for 2 perfect reps
  /// with positioning, breathing, errors, visualization, and tips
  Future<String?> getGuidedExecutionScript({required String exerciseId}) async {
    try {
      final response = await _apiClient.dio.post(
        '/exercises/$exerciseId/voice-coaching/guided',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        // Return the full script for TTS
        if (data['success'] == true && data['full_script'] != null) {
          return data['full_script'] as String;
        }

        // If fallback, also return the full_script
        if (data['full_script'] != null) {
          return data['full_script'] as String;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting guided execution script: $e');
      return null;
    }
  }

  /// Generate TTS audio from text using ElevenLabs via backend
  /// Returns audio URL for playback
  Future<String?> generateTTS(String text) async {
    try {
      final response = await _apiClient.dio.post(
        '/voice-coaching/tts',
        data: {'text': text},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        if (data['success'] == true && data['audio_url'] != null) {
          return data['audio_url'] as String;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error generating TTS: $e');
      return null;
    }
  }
}
