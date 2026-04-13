import 'quota_status_model.dart';

class FormAnalysis {
  final int id;
  final int userId;
  final int? exerciseId;
  final String exerciseName;
  final String videoPath;
  final int videoDurationSeconds;
  final Map<String, dynamic> feedback;
  final int? formScore;
  final List<FormError> detectedErrors;
  final List<FormSuggestion> suggestions;
  final String? summary;
  final String status;
  final String? errorMessage;
  final int? processingTimeMs;
  final bool isPremiumAnalysis;
  final DateTime createdAt;

  FormAnalysis({
    required this.id,
    required this.userId,
    this.exerciseId,
    required this.exerciseName,
    required this.videoPath,
    required this.videoDurationSeconds,
    required this.feedback,
    this.formScore,
    required this.detectedErrors,
    required this.suggestions,
    this.summary,
    required this.status,
    this.errorMessage,
    this.processingTimeMs,
    required this.isPremiumAnalysis,
    required this.createdAt,
  });

  factory FormAnalysis.fromJson(Map<String, dynamic> json) {
    final feedback = _asMap(json['feedback']);
    final rawDetectedErrors = _asList(json['detected_errors']);
    final rawSuggestions = _asList(json['suggestions']);

    return FormAnalysis(
      id: _toInt(json['id']) ?? 0,
      userId: _toInt(json['user_id']) ?? 0,
      exerciseId: _toInt(json['exercise_id']),
      exerciseName: _toStr(json['exercise_name']),
      videoPath: _toStr(json['video_path']),
      videoDurationSeconds: _toInt(json['video_duration_seconds']) ?? 0,
      feedback: feedback ?? <String, dynamic>{},
      formScore: _toInt(json['form_score']),
      detectedErrors: rawDetectedErrors
          .map((e) => _asMap(e))
          .whereType<Map<String, dynamic>>()
          .map(FormError.fromJson)
          .toList(),
      suggestions: rawSuggestions
          .map((e) => _asMap(e))
          .whereType<Map<String, dynamic>>()
          .map(FormSuggestion.fromJson)
          .toList(),
      summary: _toNullableStr(json['summary']),
      status: _toStr(json['status'], fallback: 'completed'),
      errorMessage: _toNullableStr(json['error_message']),
      processingTimeMs: _toInt(json['processing_time_ms']),
      isPremiumAnalysis: _toBool(json['is_premium_analysis']),
      createdAt: _toDateTime(json['created_at']) ?? DateTime.now(),
    );
  }

  String get scoreGrade {
    if (formScore == null) return 'N/A';
    if (formScore! >= 9) return 'Excellent';
    if (formScore! >= 7) return 'Good';
    if (formScore! >= 5) return 'Fair';
    return 'Needs Work';
  }

  String get videoUrl => 'https://your-backend.com/storage/$videoPath';
}

class FormError {
  final String issue;
  final String severity; // high, medium, low

  FormError({required this.issue, required this.severity});

  factory FormError.fromJson(Map<String, dynamic> json) {
    return FormError(
      issue: _toStr(json['issue']),
      severity: _toStr(json['severity'], fallback: 'medium'),
    );
  }
}

class FormSuggestion {
  final String improvement;
  final String priority; // high, medium, low

  FormSuggestion({required this.improvement, required this.priority});

  factory FormSuggestion.fromJson(Map<String, dynamic> json) {
    return FormSuggestion(
      improvement: _toStr(json['improvement']),
      priority: _toStr(json['priority'], fallback: 'medium'),
    );
  }
}

class FormAnalysisQuota {
  final bool canAnalyze;
  final int analysesUsed;
  final int limit;
  final int remaining;
  final bool isPremium;
  final String period;

  FormAnalysisQuota({
    required this.canAnalyze,
    required this.analysesUsed,
    required this.limit,
    required this.remaining,
    required this.isPremium,
    required this.period,
  });

  factory FormAnalysisQuota.fromJson(Map<String, dynamic> json) {
    final parsedLimit =
        _toInt(json['limit']) ?? _toInt(json['daily_limit']) ?? 1;
    final parsedCanAnalyze =
        _toBool(json['can_analyze']) || _toBool(json['can_use']);
    return FormAnalysisQuota(
      canAnalyze: parsedCanAnalyze,
      analysesUsed: _toInt(json['analyses_used']) ?? _toInt(json['used']) ?? 0,
      limit: parsedLimit,
      remaining: _toInt(json['remaining']) ?? 0,
      isPremium: _toBool(json['is_premium']),
      period: _toStr(json['period'], fallback: 'week'),
    );
  }

  factory FormAnalysisQuota.fromQuotaUsage({
    required QuotaUsage usage,
    required bool isPremium,
  }) {
    return FormAnalysisQuota(
      canAnalyze: usage.canUse,
      analysesUsed: usage.used,
      limit: usage.limit,
      remaining: usage.remaining,
      isPremium: isPremium,
      period: usage.period,
    );
  }

  bool get isUnlimited => limit == -1;

  // Backward compatibility for UI code still using the old name.
  int get dailyLimit => limit;
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed) ?? double.tryParse(trimmed)?.toInt();
  }
  return null;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}

String _toStr(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

String? _toNullableStr(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

DateTime? _toDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
}
