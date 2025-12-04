import 'package:flutter/material.dart';

class BiometricData {
  final int id;
  final String dataType;
  final double value;
  final String unit;
  final String source;
  final DateTime recordedAt;

  BiometricData({
    required this.id,
    required this.dataType,
    required this.value,
    required this.unit,
    required this.source,
    required this.recordedAt,
  });

  factory BiometricData.fromJson(Map<String, dynamic> json) {
    return BiometricData(
      id: json['id'],
      dataType: json['data_type'],
      value: (json['value'] ?? 0).toDouble(),
      unit: json['unit'],
      source: json['source'],
      recordedAt: DateTime.parse(json['recorded_at']),
    );
  }

  IconData get icon {
    switch (dataType) {
      case 'heart_rate':
        return Icons.favorite;
      case 'hrv':
        return Icons.monitor_heart;
      case 'sleep_quality':
        return Icons.bedtime;
      case 'steps':
        return Icons.directions_walk;
      case 'calories':
        return Icons.local_fire_department;
      default:
        return Icons.analytics;
    }
  }

  Color get color {
    switch (dataType) {
      case 'heart_rate':
        return Colors.red;
      case 'hrv':
        return Colors.purple;
      case 'sleep_quality':
        return Colors.blue;
      case 'steps':
        return Colors.green;
      case 'calories':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class SleepSession {
  final int id;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final double? qualityScore;
  final int? deepSleepMinutes;
  final int? remSleepMinutes;
  final int? lightSleepMinutes;
  final int? awakeMinutes;
  final String source;

  SleepSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.qualityScore,
    this.deepSleepMinutes,
    this.remSleepMinutes,
    this.lightSleepMinutes,
    this.awakeMinutes,
    required this.source,
  });

  factory SleepSession.fromJson(Map<String, dynamic> json) {
    return SleepSession(
      id: json['id'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      durationMinutes: json['duration_minutes'],
      qualityScore: json['quality_score']?.toDouble(),
      deepSleepMinutes: json['deep_sleep_minutes'],
      remSleepMinutes: json['rem_sleep_minutes'],
      lightSleepMinutes: json['light_sleep_minutes'],
      awakeMinutes: json['awake_minutes'],
      source: json['source'],
    );
  }

  double get durationHours => durationMinutes / 60;

  Color get qualityColor {
    if (qualityScore == null) return Colors.grey;
    if (qualityScore! >= 0.8) return Colors.green;
    if (qualityScore! >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String get qualityLabel {
    if (qualityScore == null) return 'Unknown';
    if (qualityScore! >= 0.8) return 'Excellent';
    if (qualityScore! >= 0.6) return 'Good';
    if (qualityScore! >= 0.4) return 'Fair';
    return 'Poor';
  }
}

class HeartRateData {
  final int id;
  final int heartRate;
  final int? hrv;
  final DateTime recordedAt;
  final String context;
  final String source;

  HeartRateData({
    required this.id,
    required this.heartRate,
    this.hrv,
    required this.recordedAt,
    required this.context,
    required this.source,
  });

  factory HeartRateData.fromJson(Map<String, dynamic> json) {
    return HeartRateData(
      id: json['id'],
      heartRate: json['heart_rate'],
      hrv: json['hrv'],
      recordedAt: DateTime.parse(json['recorded_at']),
      context: json['context'],
      source: json['source'],
    );
  }
}

class BiometricInsight {
  final String type; // warning, positive, info
  final String category;
  final String message;
  final String metric;

  BiometricInsight({
    required this.type,
    required this.category,
    required this.message,
    required this.metric,
  });

  factory BiometricInsight.fromJson(Map<String, dynamic> json) {
    return BiometricInsight(
      type: json['type'],
      category: json['category'],
      message: json['message'],
      metric: json['metric'],
    );
  }

  IconData get icon {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'positive':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  Color get color {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'positive':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}

class EnhancedRecoveryScore {
  final double score;
  final String readiness;
  final Map<String, double> components;
  final Map<String, dynamic> biometricData;

  EnhancedRecoveryScore({
    required this.score,
    required this.readiness,
    required this.components,
    required this.biometricData,
  });

  factory EnhancedRecoveryScore.fromJson(Map<String, dynamic> json) {
    return EnhancedRecoveryScore(
      score: (json['score'] ?? 0).toDouble(),
      readiness: json['readiness'] ?? 'moderate',
      components: Map<String, double>.from(
        (json['components'] as Map).map(
          (key, value) => MapEntry(key.toString(), (value ?? 0).toDouble()),
        ),
      ),
      biometricData: json['biometric_data'] ?? {},
    );
  }

  Color get readinessColor {
    switch (readiness) {
      case 'high':
        return Colors.green;
      case 'low':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String get readinessLabel {
    switch (readiness) {
      case 'high':
        return 'Ready to Train';
      case 'low':
        return 'Need Rest';
      default:
        return 'Moderate Recovery';
    }
  }
}

class HRVTrend {
  final String trend; // improving, declining, stable
  final double average;
  final double changePercentage;
  final Map<String, double> data;

  HRVTrend({
    required this.trend,
    required this.average,
    required this.changePercentage,
    required this.data,
  });

  factory HRVTrend.fromJson(Map<String, dynamic> json) {
    // Handle case where data might be null, an empty list, or an empty map
    Map<String, double> parsedData = {};
    if (json['data'] != null &&
        json['data'] is Map &&
        (json['data'] as Map).isNotEmpty) {
      parsedData = Map<String, double>.from(
        (json['data'] as Map).map(
          (key, value) => MapEntry(key.toString(), (value ?? 0).toDouble()),
        ),
      );
    }

    return HRVTrend(
      trend: json['trend'] ?? 'stable',
      average: (json['average'] ?? 0).toDouble(),
      changePercentage: (json['change_percentage'] ?? 0).toDouble(),
      data: parsedData,
    );
  }

  Color get trendColor {
    switch (trend) {
      case 'improving':
        return Colors.green;
      case 'declining':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData get trendIcon {
    switch (trend) {
      case 'improving':
        return Icons.trending_up;
      case 'declining':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }
}
