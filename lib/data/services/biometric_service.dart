import '../models/biometric_model.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class BiometricService {
  final ApiClient _apiClient;

  BiometricService(this._apiClient);

  /// Sync biometric data from external source
  Future<Map<String, dynamic>?> syncData({
    required String source,
    required List<Map<String, dynamic>> data,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/biometric/sync',
        data: {'source': source, 'data': data},
      );
      return response.data;
    } catch (e) {
      debugPrint('Error syncing biometric data: $e');
      return null;
    }
  }

  /// Get latest biometric data
  Future<Map<String, dynamic>?> getLatest() async {
    try {
      final response = await _apiClient.dio.get('/biometric/latest');
      return response.data['data'];
    } catch (e) {
      debugPrint('Error fetching latest biometric data: $e');
      return null;
    }
  }

  /// Get biometric history
  Future<List<BiometricData>?> getHistory({String? type, int days = 30}) async {
    try {
      final response = await _apiClient.dio.get(
        '/biometric/history',
        queryParameters: {if (type != null) 'type': type, 'days': days},
      );

      return (response.data['data'] as List)
          .map((json) => BiometricData.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching biometric history: $e');
      return null;
    }
  }

  /// Store sleep session
  Future<SleepSession?> storeSleep({
    required DateTime startTime,
    required DateTime endTime,
    required int durationMinutes,
    double? qualityScore,
    int? deepSleepMinutes,
    int? remSleepMinutes,
    int? lightSleepMinutes,
    int? awakeMinutes,
    String source = 'manual',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/biometric/sleep',
        data: {
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'duration_minutes': durationMinutes,
          if (qualityScore != null) 'quality_score': qualityScore,
          if (deepSleepMinutes != null) 'deep_sleep_minutes': deepSleepMinutes,
          if (remSleepMinutes != null) 'rem_sleep_minutes': remSleepMinutes,
          if (lightSleepMinutes != null)
            'light_sleep_minutes': lightSleepMinutes,
          if (awakeMinutes != null) 'awake_minutes': awakeMinutes,
          'source': source,
        },
      );

      return SleepSession.fromJson(response.data['session']);
    } catch (e) {
      debugPrint('Error storing sleep session: $e');
      return null;
    }
  }

  /// Get sleep history
  Future<Map<String, dynamic>?> getSleepHistory({int days = 30}) async {
    try {
      final response = await _apiClient.dio.get(
        '/biometric/sleep/history',
        queryParameters: {'days': days},
      );

      return {
        'sessions': (response.data['sessions'] as List)
            .map((json) => SleepSession.fromJson(json))
            .toList(),
        'statistics': response.data['statistics'],
      };
    } catch (e) {
      debugPrint('Error fetching sleep history: $e');
      return null;
    }
  }

  /// Store heart rate data
  Future<HeartRateData?> storeHeartRate({
    required int heartRate,
    int? hrv,
    DateTime? recordedAt,
    String context = 'resting',
    String source = 'manual',
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/biometric/heart-rate',
        data: {
          'heart_rate': heartRate,
          if (hrv != null) 'hrv': hrv,
          if (recordedAt != null) 'recorded_at': recordedAt.toIso8601String(),
          'context': context,
          'source': source,
        },
      );

      return HeartRateData.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('Error storing heart rate data: $e');
      return null;
    }
  }

  /// Get HRV trend
  Future<HRVTrend?> getHRVTrend({int days = 7}) async {
    try {
      final response = await _apiClient.dio.get(
        '/biometric/hrv/trend',
        queryParameters: {'days': days},
      );

      return HRVTrend.fromJson(response.data['trend']);
    } catch (e) {
      debugPrint('Error fetching HRV trend: $e');
      return null;
    }
  }

  /// Get AI insights from biometric data
  Future<Map<String, dynamic>?> getInsights() async {
    try {
      final response = await _apiClient.dio.get('/biometric/insights');

      if (response.data == null || response.data is List) {
        return null;
      }

      // Safely parse recovery_score
      EnhancedRecoveryScore? recoveryScore;
      if (response.data['recovery_score'] != null &&
          response.data['recovery_score'] is Map) {
        recoveryScore = EnhancedRecoveryScore.fromJson(
          response.data['recovery_score'],
        );
      }

      // Safely parse hrv_trend
      HRVTrend? hrvTrend;
      if (response.data['hrv_trend'] != null &&
          response.data['hrv_trend'] is Map) {
        hrvTrend = HRVTrend.fromJson(response.data['hrv_trend']);
      }

      // Safely parse insights list
      List<BiometricInsight> insights = [];
      if (response.data['insights'] != null &&
          response.data['insights'] is List) {
        insights = (response.data['insights'] as List)
            .map((json) => BiometricInsight.fromJson(json))
            .toList();
      }

      return {
        'recovery_score': recoveryScore,
        'hrv_trend': hrvTrend,
        'insights': insights,
        'latest_data': response.data['latest_data'],
      };
    } catch (e) {
      debugPrint('Error fetching biometric insights: $e');
      return null;
    }
  }

  /// Get biometric settings
  Future<Map<String, dynamic>?> getSettings() async {
    try {
      final response = await _apiClient.dio.get('/biometric/settings');
      return response.data['settings'];
    } catch (e) {
      debugPrint('Error fetching biometric settings: $e');
      return null;
    }
  }

  /// Update biometric settings
  Future<bool> updateSettings({
    bool? appleHealthEnabled,
    bool? googleFitEnabled,
    bool? autoSyncEnabled,
    int? syncIntervalHours,
    List<String>? enabledDataTypes,
  }) async {
    try {
      await _apiClient.dio.put(
        '/biometric/settings',
        data: {
          if (appleHealthEnabled != null)
            'apple_health_enabled': appleHealthEnabled,
          if (googleFitEnabled != null) 'google_fit_enabled': googleFitEnabled,
          if (autoSyncEnabled != null) 'auto_sync_enabled': autoSyncEnabled,
          if (syncIntervalHours != null)
            'sync_interval_hours': syncIntervalHours,
          if (enabledDataTypes != null) 'enabled_data_types': enabledDataTypes,
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error updating biometric settings: $e');
      return false;
    }
  }
}
