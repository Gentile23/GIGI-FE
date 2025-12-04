// Enhanced Voice Coaching Models for Multi-Phase Structure
// Supports pre_exercise, sets (with pre_set, repetitions, post_set), and post_exercise

/// Pre-exercise cues - Setup, rassicurazione, impostazione ritmo
class PreExerciseCues {
  final String setupInstructions;
  final String reassurance;
  final String rhythmSetup;
  final String objective;
  final int durationSeconds;

  PreExerciseCues({
    required this.setupInstructions,
    required this.reassurance,
    required this.rhythmSetup,
    required this.objective,
    required this.durationSeconds,
  });

  factory PreExerciseCues.fromJson(Map<String, dynamic> json) {
    return PreExerciseCues(
      setupInstructions: json['setup_instructions'] as String,
      reassurance: json['reassurance'] as String,
      rhythmSetup: json['rhythm_setup'] as String,
      objective: json['objective'] as String,
      durationSeconds: json['duration_seconds'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'setup_instructions': setupInstructions,
      'reassurance': reassurance,
      'rhythm_setup': rhythmSetup,
      'objective': objective,
      'duration_seconds': durationSeconds,
    };
  }

  /// Get combined text for this phase
  String get combinedText {
    return '$setupInstructions $reassurance $rhythmSetup $objective';
  }
}

/// Pre-set cues - Preparazione prima di ogni set
class PreSetCues {
  final String setAnnouncement;
  final String mentalPreparation;
  final String techniqueReminder;
  final int durationSeconds;

  PreSetCues({
    required this.setAnnouncement,
    required this.mentalPreparation,
    required this.techniqueReminder,
    required this.durationSeconds,
  });

  factory PreSetCues.fromJson(Map<String, dynamic> json) {
    return PreSetCues(
      setAnnouncement: json['set_announcement'] as String,
      mentalPreparation: json['mental_preparation'] as String,
      techniqueReminder: json['technique_reminder'] as String,
      durationSeconds: json['duration_seconds'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'set_announcement': setAnnouncement,
      'mental_preparation': mentalPreparation,
      'technique_reminder': techniqueReminder,
      'duration_seconds': durationSeconds,
    };
  }

  /// Get combined text for this phase
  String get combinedText {
    return '$setAnnouncement. $mentalPreparation. $techniqueReminder';
  }
}

/// Repetition cues - Tutti i cues per una singola ripetizione
class RepetitionCues {
  final int repNumber;
  final String entryPhrase;
  final String rhythmCue;
  final String breathingCue;
  final String techniqueCue;
  final String motivationCue;
  final int timingOffsetSeconds;

  RepetitionCues({
    required this.repNumber,
    required this.entryPhrase,
    required this.rhythmCue,
    required this.breathingCue,
    required this.techniqueCue,
    required this.motivationCue,
    required this.timingOffsetSeconds,
  });

  factory RepetitionCues.fromJson(Map<String, dynamic> json) {
    return RepetitionCues(
      repNumber: json['rep_number'] as int,
      entryPhrase: json['entry_phrase'] as String,
      rhythmCue: json['rhythm_cue'] as String,
      breathingCue: json['breathing_cue'] as String,
      techniqueCue: json['technique_cue'] as String,
      motivationCue: json['motivation_cue'] as String,
      timingOffsetSeconds: json['timing_offset_seconds'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rep_number': repNumber,
      'entry_phrase': entryPhrase,
      'rhythm_cue': rhythmCue,
      'breathing_cue': breathingCue,
      'technique_cue': techniqueCue,
      'motivation_cue': motivationCue,
      'timing_offset_seconds': timingOffsetSeconds,
    };
  }

  /// Get combined instruction text for this repetition
  String get combinedText {
    return '$entryPhrase. $rhythmCue. $breathingCue. $techniqueCue. $motivationCue';
  }
}

/// Post-set cues - Feedback e istruzioni dopo il set
class PostSetCues {
  final String qualityFeedback;
  final String progressMotivation;
  final String recoveryInstructions;
  final int durationSeconds;

  PostSetCues({
    required this.qualityFeedback,
    required this.progressMotivation,
    required this.recoveryInstructions,
    required this.durationSeconds,
  });

  factory PostSetCues.fromJson(Map<String, dynamic> json) {
    return PostSetCues(
      qualityFeedback: json['quality_feedback'] as String,
      progressMotivation: json['progress_motivation'] as String,
      recoveryInstructions: json['recovery_instructions'] as String,
      durationSeconds: json['duration_seconds'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quality_feedback': qualityFeedback,
      'progress_motivation': progressMotivation,
      'recovery_instructions': recoveryInstructions,
      'duration_seconds': durationSeconds,
    };
  }

  /// Get combined text for this phase
  String get combinedText {
    return '$qualityFeedback. $progressMotivation. $recoveryInstructions';
  }
}

/// Post-exercise cues - Chiusura finale dopo tutti i set
class PostExerciseCues {
  final String progressRecap;
  final String identityReinforcement;
  final String callToAction;
  final int durationSeconds;

  PostExerciseCues({
    required this.progressRecap,
    required this.identityReinforcement,
    required this.callToAction,
    required this.durationSeconds,
  });

  factory PostExerciseCues.fromJson(Map<String, dynamic> json) {
    return PostExerciseCues(
      progressRecap: json['progress_recap'] as String,
      identityReinforcement: json['identity_reinforcement'] as String,
      callToAction: json['call_to_action'] as String,
      durationSeconds: json['duration_seconds'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'progress_recap': progressRecap,
      'identity_reinforcement': identityReinforcement,
      'call_to_action': callToAction,
      'duration_seconds': durationSeconds,
    };
  }

  /// Get combined text for this phase
  String get combinedText {
    return '$progressRecap $identityReinforcement $callToAction';
  }
}

/// Set coaching - Contiene pre_set, repetitions, post_set
class SetCoaching {
  final int setNumber;
  final PreSetCues preSet;
  final List<RepetitionCues> repetitions;
  final PostSetCues postSet;

  SetCoaching({
    required this.setNumber,
    required this.preSet,
    required this.repetitions,
    required this.postSet,
  });

  factory SetCoaching.fromJson(Map<String, dynamic> json) {
    return SetCoaching(
      setNumber: json['set_number'] as int,
      preSet: PreSetCues.fromJson(json['pre_set'] as Map<String, dynamic>),
      repetitions: (json['repetitions'] as List)
          .map((e) => RepetitionCues.fromJson(e as Map<String, dynamic>))
          .toList(),
      postSet: PostSetCues.fromJson(json['post_set'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'set_number': setNumber,
      'pre_set': preSet.toJson(),
      'repetitions': repetitions.map((e) => e.toJson()).toList(),
      'post_set': postSet.toJson(),
    };
  }

  /// Get total number of repetitions in this set
  int get totalReps => repetitions.length;

  /// Get cues for a specific repetition (1-based index)
  RepetitionCues? getCuesForRep(int repNumber) {
    if (repNumber < 1 || repNumber > totalReps) return null;
    return repetitions[repNumber - 1];
  }

  /// Get estimated duration for this set in seconds
  int get estimatedDurationSeconds {
    return preSet.durationSeconds +
        (totalReps * 5) + // ~5 seconds per rep
        postSet.durationSeconds;
  }
}

/// Enhanced Structured Voice Coaching - Complete multi-phase structure
class EnhancedStructuredVoiceCoaching {
  final PreExerciseCues preExercise;
  final List<SetCoaching> sets;
  final PostExerciseCues postExercise;

  EnhancedStructuredVoiceCoaching({
    required this.preExercise,
    required this.sets,
    required this.postExercise,
  });

  factory EnhancedStructuredVoiceCoaching.fromJson(Map<String, dynamic> json) {
    return EnhancedStructuredVoiceCoaching(
      preExercise: PreExerciseCues.fromJson(
        json['pre_exercise'] as Map<String, dynamic>,
      ),
      sets: (json['sets'] as List)
          .map((e) => SetCoaching.fromJson(e as Map<String, dynamic>))
          .toList(),
      postExercise: PostExerciseCues.fromJson(
        json['post_exercise'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pre_exercise': preExercise.toJson(),
      'sets': sets.map((e) => e.toJson()).toList(),
      'post_exercise': postExercise.toJson(),
    };
  }

  /// Get total number of sets
  int get totalSets => sets.length;

  /// Get total number of repetitions across all sets
  int get totalReps => sets.fold(0, (sum, set) => sum + set.totalReps);

  /// Get set by number (1-based index)
  SetCoaching? getSet(int setNumber) {
    if (setNumber < 1 || setNumber > totalSets) return null;
    return sets[setNumber - 1];
  }

  /// Get cues for a specific set and repetition
  RepetitionCues? getCuesForSetAndRep(int setNumber, int repNumber) {
    final set = getSet(setNumber);
    return set?.getCuesForRep(repNumber);
  }

  /// Get estimated total duration in seconds
  int get estimatedDurationSeconds {
    return preExercise.durationSeconds +
        sets.fold<int>(0, (sum, set) => sum + set.estimatedDurationSeconds) +
        postExercise.durationSeconds;
  }

  /// Get all cues for a specific phase
  String getCuesForPhase(VoiceCoachingPhase phase) {
    switch (phase) {
      case VoiceCoachingPhase.preExercise:
        return preExercise.combinedText;
      case VoiceCoachingPhase.postExercise:
        return postExercise.combinedText;
      default:
        return '';
    }
  }
}

/// Enum for voice coaching phases
enum VoiceCoachingPhase {
  preExercise,
  preSet,
  repetition,
  postSet,
  postExercise,
}
