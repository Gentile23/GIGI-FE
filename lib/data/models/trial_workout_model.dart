class TrialWorkout {
  final String? id;
  final String name;
  final String description;
  final List<TrialExercise> exercises;
  final int durationMinutes;

  TrialWorkout({
    this.id,
    required this.name,
    required this.description,
    required this.exercises,
    required this.durationMinutes,
  });

  factory TrialWorkout.fromJson(Map<String, dynamic> json) {
    return TrialWorkout(
      id: json['id']?.toString(),
      name: json['name'] as String? ?? 'Trial Workout',
      description: json['description'] as String? ?? '',
      exercises:
          (json['exercises'] as List?)
              ?.map((e) => TrialExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      durationMinutes: json['duration_minutes'] as int? ?? 30,
    );
  }
}

class TrialExercise {
  final String? id;
  final String name;
  final int sets;
  final String
  reps; // Changed from int to String to support "10 per gamba", "20 sec", etc.
  final int restSeconds;
  final String? notes;
  final String? voiceCoachingPreUrl;
  final String? voiceCoachingDuringUrl;
  final String? voiceCoachingPostUrl;
  final List<String> muscleGroups;

  TrialExercise({
    this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.notes,
    this.voiceCoachingPreUrl,
    this.voiceCoachingDuringUrl,
    this.voiceCoachingPostUrl,
    this.muscleGroups = const [],
  });

  factory TrialExercise.fromJson(Map<String, dynamic> json) {
    return TrialExercise(
      id: json['id']?.toString(),
      name: json['name'] as String? ?? 'Exercise',
      sets: json['sets'] as int? ?? 3,
      reps: json['reps']?.toString() ?? '10', // Convert to String
      restSeconds: json['rest_seconds'] as int? ?? 60,
      notes: json['notes'] as String?,
      voiceCoachingPreUrl: json['voice_coaching_pre_url'] as String?,
      voiceCoachingDuringUrl: json['voice_coaching_during_url'] as String?,
      voiceCoachingPostUrl: json['voice_coaching_post_url'] as String?,
      muscleGroups:
          (json['muscle_groups'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class TrialPerformanceData {
  final Map<String, int> difficultyRatings;
  final List<String> skippedExercises;
  final int totalRestTime;
  final int overallFatigue;
  final List<String> formIssues;
  final String? feedback;
  final Map<String, List<int>>? actualRepsPerformed;
  final Map<String, List<double>>? weightsUsed;

  TrialPerformanceData({
    required this.difficultyRatings,
    required this.skippedExercises,
    required this.totalRestTime,
    required this.overallFatigue,
    required this.formIssues,
    this.feedback,
    this.actualRepsPerformed,
    this.weightsUsed,
  });

  Map<String, dynamic> toJson() {
    return {
      'difficulty_ratings': difficultyRatings,
      'skipped_exercises': skippedExercises,
      'total_rest_time': totalRestTime,
      'overall_fatigue': overallFatigue,
      'form_issues': formIssues,
      'feedback': feedback,
      'actual_reps_performed': actualRepsPerformed,
      'weights_used': weightsUsed,
    };
  }
}

class TrialCompletionResponse {
  final String message;
  final Map<String, dynamic> analysis;
  final String summary;
  final bool canGeneratePlan;

  TrialCompletionResponse({
    required this.message,
    required this.analysis,
    required this.summary,
    required this.canGeneratePlan,
  });

  factory TrialCompletionResponse.fromJson(Map<String, dynamic> json) {
    return TrialCompletionResponse(
      message: json['message'] as String,
      analysis: json['analysis'] as Map<String, dynamic>,
      summary: json['summary'] as String,
      canGeneratePlan: json['can_generate_plan'] as bool,
    );
  }
}
