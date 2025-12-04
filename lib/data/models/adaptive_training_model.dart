import 'package:flutter/material.dart';

class TrainingRecommendation {
  final int id;
  final String recommendationType;
  final String reason;
  final Map<String, dynamic>? suggestedChanges;
  final double confidenceScore;
  final bool isApplied;
  final DateTime? appliedAt;
  final DateTime createdAt;

  TrainingRecommendation({
    required this.id,
    required this.recommendationType,
    required this.reason,
    this.suggestedChanges,
    required this.confidenceScore,
    required this.isApplied,
    this.appliedAt,
    required this.createdAt,
  });

  factory TrainingRecommendation.fromJson(Map<String, dynamic> json) {
    return TrainingRecommendation(
      id: json['id'],
      recommendationType: json['recommendation_type'],
      reason: json['reason'],
      suggestedChanges: json['suggested_changes'],
      confidenceScore: (json['confidence_score'] ?? 0).toDouble(),
      isApplied: json['is_applied'] ?? false,
      appliedAt: json['applied_at'] != null
          ? DateTime.parse(json['applied_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get typeLabel {
    switch (recommendationType) {
      case 'deload':
        return 'Deload Week';
      case 'volume_increase':
        return 'Increase Volume';
      case 'volume_decrease':
        return 'Decrease Volume';
      case 'intensity_adjustment':
        return 'Adjust Intensity';
      case 'exercise_swap':
        return 'Exercise Swap';
      default:
        return recommendationType;
    }
  }

  IconData get typeIcon {
    switch (recommendationType) {
      case 'deload':
        return Icons.spa;
      case 'volume_increase':
        return Icons.trending_up;
      case 'volume_decrease':
        return Icons.trending_down;
      case 'intensity_adjustment':
        return Icons.tune;
      case 'exercise_swap':
        return Icons.swap_horiz;
      default:
        return Icons.lightbulb;
    }
  }

  Color get typeColor {
    switch (recommendationType) {
      case 'deload':
        return Colors.orange;
      case 'volume_increase':
        return Colors.green;
      case 'volume_decrease':
        return Colors.blue;
      case 'intensity_adjustment':
        return Colors.purple;
      case 'exercise_swap':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
}

class RecoveryScore {
  final int id;
  final DateTime scoreDate;
  final int? sleepQuality;
  final int? muscleSoreness;
  final int? stressLevel;
  final int? energyLevel;
  final double? calculatedScore;
  final String? readiness;

  RecoveryScore({
    required this.id,
    required this.scoreDate,
    this.sleepQuality,
    this.muscleSoreness,
    this.stressLevel,
    this.energyLevel,
    this.calculatedScore,
    this.readiness,
  });

  factory RecoveryScore.fromJson(Map<String, dynamic> json) {
    return RecoveryScore(
      id: json['id'],
      scoreDate: DateTime.parse(json['score_date']),
      sleepQuality: json['sleep_quality'],
      muscleSoreness: json['muscle_soreness'],
      stressLevel: json['stress_level'],
      energyLevel: json['energy_level'],
      calculatedScore: json['calculated_score']?.toDouble(),
      readiness: json['readiness'],
    );
  }

  Color get readinessColor {
    switch (readiness) {
      case 'high':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'low':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get readinessLabel {
    switch (readiness) {
      case 'high':
        return 'Ready to Train';
      case 'moderate':
        return 'Moderate Recovery';
      case 'low':
        return 'Need Rest';
      default:
        return 'Unknown';
    }
  }
}

class PerformanceAnalysis {
  final String status;
  final Map<String, dynamic>? volumeTrend;
  final Map<String, dynamic>? rpeTrend;
  final Map<String, dynamic>? recoveryScore;
  final Map<String, dynamic>? burnoutRisk;
  final List<TrainingRecommendation> recommendations;

  PerformanceAnalysis({
    required this.status,
    this.volumeTrend,
    this.rpeTrend,
    this.recoveryScore,
    this.burnoutRisk,
    required this.recommendations,
  });

  factory PerformanceAnalysis.fromJson(Map<String, dynamic> json) {
    return PerformanceAnalysis(
      status: json['status'],
      volumeTrend: json['volume_trend'],
      rpeTrend: json['rpe_trend'],
      recoveryScore: json['recovery_score'],
      burnoutRisk: json['burnout_risk'],
      recommendations: json['recommendations'] != null
          ? (json['recommendations'] as List)
                .map((r) => TrainingRecommendation.fromJson(r))
                .toList()
          : [],
    );
  }

  bool get hasData => status == 'success';

  String? get burnoutRiskLevel => burnoutRisk?['risk_level'];

  Color get burnoutRiskColor {
    switch (burnoutRiskLevel) {
      case 'high':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
