/// Model for exercise introduction script
/// Used to provide personalized exercise explanations before workouts
class ExerciseIntroScript {
  final String exerciseName;
  final String greeting;
  final String targetMuscles;
  final String setupInstructions;
  final String keyPoints;
  final String commonMistakes;
  final String? injuryWarning;
  final String? encouragement;
  final int estimatedDurationSeconds;
  final String? audioUrl;

  ExerciseIntroScript({
    required this.exerciseName,
    required this.greeting,
    required this.targetMuscles,
    required this.setupInstructions,
    required this.keyPoints,
    required this.commonMistakes,
    this.injuryWarning,
    this.encouragement,
    this.estimatedDurationSeconds = 25,
    this.audioUrl,
  });

  factory ExerciseIntroScript.fromJson(Map<String, dynamic> json) {
    return ExerciseIntroScript(
      exerciseName: json['exercise_name'] ?? '',
      greeting: json['greeting'] ?? '',
      targetMuscles: json['target_muscles'] ?? '',
      setupInstructions: json['setup_instructions'] ?? '',
      keyPoints: json['key_points'] ?? '',
      commonMistakes: json['common_mistakes'] ?? '',
      injuryWarning: json['injury_warning'],
      encouragement: json['encouragement'],
      estimatedDurationSeconds: json['estimated_duration_seconds'] ?? 25,
      audioUrl: json['audio_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_name': exerciseName,
      'greeting': greeting,
      'target_muscles': targetMuscles,
      'setup_instructions': setupInstructions,
      'key_points': keyPoints,
      'common_mistakes': commonMistakes,
      'injury_warning': injuryWarning,
      'encouragement': encouragement,
      'estimated_duration_seconds': estimatedDurationSeconds,
      'audio_url': audioUrl,
    };
  }

  /// Get full script text for TTS or display
  String get fullScript {
    final buffer = StringBuffer();
    buffer.writeln(greeting);
    buffer.writeln();
    buffer.writeln('Oggi lavoriamo su: $exerciseName.');
    buffer.writeln(targetMuscles);
    buffer.writeln();
    buffer.writeln(setupInstructions);
    buffer.writeln();
    buffer.writeln(keyPoints);
    if (injuryWarning != null && injuryWarning!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(injuryWarning);
    }
    buffer.writeln();
    buffer.writeln(commonMistakes);
    if (encouragement != null && encouragement!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(encouragement);
    }
    return buffer.toString().trim();
  }
}

/// Personalized voice coaching script with user context
class PersonalizedVoiceScript {
  final String userName;
  final String greeting;
  final ExerciseIntroScript exerciseIntro;
  final String? goalReminder;
  final String? streakCelebration;
  final String? progressNote;
  final String? personalRecord;
  final List<String> repCues;
  final String setCompletion;
  final String restMessage;
  final String? audioUrl;

  PersonalizedVoiceScript({
    required this.userName,
    required this.greeting,
    required this.exerciseIntro,
    this.goalReminder,
    this.streakCelebration,
    this.progressNote,
    this.personalRecord,
    required this.repCues,
    required this.setCompletion,
    required this.restMessage,
    this.audioUrl,
  });

  factory PersonalizedVoiceScript.fromJson(Map<String, dynamic> json) {
    return PersonalizedVoiceScript(
      userName: json['user_name'] ?? '',
      greeting: json['greeting'] ?? '',
      exerciseIntro: ExerciseIntroScript.fromJson(json['exercise_intro'] ?? {}),
      goalReminder: json['goal_reminder'],
      streakCelebration: json['streak_celebration'],
      progressNote: json['progress_note'],
      personalRecord: json['personal_record'],
      repCues: List<String>.from(json['rep_cues'] ?? []),
      setCompletion: json['set_completion'] ?? '',
      restMessage: json['rest_message'] ?? '',
      audioUrl: json['audio_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_name': userName,
      'greeting': greeting,
      'exercise_intro': exerciseIntro.toJson(),
      'goal_reminder': goalReminder,
      'streak_celebration': streakCelebration,
      'progress_note': progressNote,
      'personal_record': personalRecord,
      'rep_cues': repCues,
      'set_completion': setCompletion,
      'rest_message': restMessage,
      'audio_url': audioUrl,
    };
  }

  /// Get rep cue for specific repetition (1-indexed)
  String? getRepCue(int repNumber) {
    if (repNumber < 1 || repNumber > repCues.length) return null;
    return repCues[repNumber - 1];
  }
}

/// Coaching mode preference
enum CoachingMode {
  voice, // Full voice coaching with per-rep cues
  music, // Music mode with minimal voice interruptions
}

/// User's coaching preferences
class UserCoachingPreferences {
  final CoachingMode preferredMode;
  final bool rememberChoice;
  final bool enableBreathingCues;
  final bool enableMotivation;
  final bool enableFormReminders;
  final bool enableRestCountdown;
  final List<int> countdownIntervals;
  final double voiceVolume;

  UserCoachingPreferences({
    this.preferredMode = CoachingMode.voice,
    this.rememberChoice = false,
    this.enableBreathingCues = true,
    this.enableMotivation = true,
    this.enableFormReminders = true,
    this.enableRestCountdown = true,
    this.countdownIntervals = const [60, 30, 10, 5, 3, 2, 1],
    this.voiceVolume = 1.0,
  });

  factory UserCoachingPreferences.fromJson(Map<String, dynamic> json) {
    return UserCoachingPreferences(
      preferredMode: json['preferred_mode'] == 'music'
          ? CoachingMode.music
          : CoachingMode.voice,
      rememberChoice: json['remember_choice'] ?? false,
      enableBreathingCues: json['enable_breathing_cues'] ?? true,
      enableMotivation: json['enable_motivation'] ?? true,
      enableFormReminders: json['enable_form_reminders'] ?? true,
      enableRestCountdown: json['enable_rest_countdown'] ?? true,
      countdownIntervals: List<int>.from(
        json['countdown_intervals'] ?? [60, 30, 10, 5, 3, 2, 1],
      ),
      voiceVolume: (json['voice_volume'] ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferred_mode': preferredMode == CoachingMode.music ? 'music' : 'voice',
      'remember_choice': rememberChoice,
      'enable_breathing_cues': enableBreathingCues,
      'enable_motivation': enableMotivation,
      'enable_form_reminders': enableFormReminders,
      'enable_rest_countdown': enableRestCountdown,
      'countdown_intervals': countdownIntervals,
      'voice_volume': voiceVolume,
    };
  }

  UserCoachingPreferences copyWith({
    CoachingMode? preferredMode,
    bool? rememberChoice,
    bool? enableBreathingCues,
    bool? enableMotivation,
    bool? enableFormReminders,
    bool? enableRestCountdown,
    List<int>? countdownIntervals,
    double? voiceVolume,
  }) {
    return UserCoachingPreferences(
      preferredMode: preferredMode ?? this.preferredMode,
      rememberChoice: rememberChoice ?? this.rememberChoice,
      enableBreathingCues: enableBreathingCues ?? this.enableBreathingCues,
      enableMotivation: enableMotivation ?? this.enableMotivation,
      enableFormReminders: enableFormReminders ?? this.enableFormReminders,
      enableRestCountdown: enableRestCountdown ?? this.enableRestCountdown,
      countdownIntervals: countdownIntervals ?? this.countdownIntervals,
      voiceVolume: voiceVolume ?? this.voiceVolume,
    );
  }
}
