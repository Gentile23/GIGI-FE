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
    return FormAnalysis(
      id: json['id'],
      userId: json['user_id'],
      exerciseId: json['exercise_id'],
      exerciseName: json['exercise_name'],
      videoPath: json['video_path'],
      videoDurationSeconds: json['video_duration_seconds'],
      feedback: json['feedback'] ?? {},
      formScore: json['form_score'],
      detectedErrors:
          (json['detected_errors'] as List?)
              ?.map((e) => FormError.fromJson(e))
              .toList() ??
          [],
      suggestions:
          (json['suggestions'] as List?)
              ?.map((e) => FormSuggestion.fromJson(e))
              .toList() ??
          [],
      summary: json['summary'],
      status: json['status'],
      errorMessage: json['error_message'],
      processingTimeMs: json['processing_time_ms'],
      isPremiumAnalysis: json['is_premium_analysis'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
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
      issue: json['issue'] ?? '',
      severity: json['severity'] ?? 'medium',
    );
  }
}

class FormSuggestion {
  final String improvement;
  final String priority; // high, medium, low

  FormSuggestion({required this.improvement, required this.priority});

  factory FormSuggestion.fromJson(Map<String, dynamic> json) {
    return FormSuggestion(
      improvement: json['improvement'] ?? '',
      priority: json['priority'] ?? 'medium',
    );
  }
}

class FormAnalysisQuota {
  final bool canAnalyze;
  final int analysesUsed;
  final int dailyLimit;
  final int remaining;
  final bool isPremium;

  FormAnalysisQuota({
    required this.canAnalyze,
    required this.analysesUsed,
    required this.dailyLimit,
    required this.remaining,
    required this.isPremium,
  });

  factory FormAnalysisQuota.fromJson(Map<String, dynamic> json) {
    return FormAnalysisQuota(
      canAnalyze: json['can_analyze'] ?? false,
      analysesUsed: json['analyses_used'] ?? 0,
      dailyLimit: json['daily_limit'] ?? 3,
      remaining: json['remaining'] ?? 0,
      isPremium: json['is_premium'] ?? false,
    );
  }
}
