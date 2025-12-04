class VoiceCoachingPreparation {
  final String text;
  final int durationSeconds;

  VoiceCoachingPreparation({required this.text, required this.durationSeconds});

  factory VoiceCoachingPreparation.fromJson(Map<String, dynamic> json) {
    return VoiceCoachingPreparation(
      text: json['text'] as String,
      durationSeconds: json['duration_seconds'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'text': text, 'duration_seconds': durationSeconds};
  }
}

class RepetitionInstruction {
  final int repNumber;
  final String entryPhrase;
  final String breathingCue;
  final String muscleActivation;
  final String rhythmCue;

  RepetitionInstruction({
    required this.repNumber,
    required this.entryPhrase,
    required this.breathingCue,
    required this.muscleActivation,
    required this.rhythmCue,
  });

  factory RepetitionInstruction.fromJson(Map<String, dynamic> json) {
    return RepetitionInstruction(
      repNumber: json['rep_number'] as int,
      entryPhrase: json['entry_phrase'] as String,
      breathingCue: json['breathing_cue'] as String,
      muscleActivation: json['muscle_activation'] as String,
      rhythmCue: json['rhythm_cue'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rep_number': repNumber,
      'entry_phrase': entryPhrase,
      'breathing_cue': breathingCue,
      'muscle_activation': muscleActivation,
      'rhythm_cue': rhythmCue,
    };
  }

  /// Get combined instruction text for this repetition
  String get combinedText {
    return '$entryPhrase. $breathingCue. $muscleActivation. $rhythmCue';
  }
}

class VoiceCoachingClosing {
  final String text;
  final int durationSeconds;

  VoiceCoachingClosing({required this.text, required this.durationSeconds});

  factory VoiceCoachingClosing.fromJson(Map<String, dynamic> json) {
    return VoiceCoachingClosing(
      text: json['text'] as String,
      durationSeconds: json['duration_seconds'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'text': text, 'duration_seconds': durationSeconds};
  }
}

class StructuredVoiceCoaching {
  final VoiceCoachingPreparation preparation;
  final List<RepetitionInstruction> executionInstructions;
  final VoiceCoachingClosing closing;

  StructuredVoiceCoaching({
    required this.preparation,
    required this.executionInstructions,
    required this.closing,
  });

  factory StructuredVoiceCoaching.fromJson(Map<String, dynamic> json) {
    return StructuredVoiceCoaching(
      preparation: VoiceCoachingPreparation.fromJson(
        json['preparation'] as Map<String, dynamic>,
      ),
      executionInstructions: (json['execution_instructions'] as List)
          .map((e) => RepetitionInstruction.fromJson(e as Map<String, dynamic>))
          .toList(),
      closing: VoiceCoachingClosing.fromJson(
        json['closing'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preparation': preparation.toJson(),
      'execution_instructions': executionInstructions
          .map((e) => e.toJson())
          .toList(),
      'closing': closing.toJson(),
    };
  }

  /// Get total number of repetitions
  int get totalReps => executionInstructions.length;

  /// Get instruction for a specific repetition (1-based index)
  RepetitionInstruction? getInstructionForRep(int repNumber) {
    if (repNumber < 1 || repNumber > totalReps) return null;
    return executionInstructions[repNumber - 1];
  }

  /// Get estimated total duration in seconds
  int get estimatedDurationSeconds {
    // Preparation + (reps * ~5 seconds per rep) + closing
    return preparation.durationSeconds +
        (totalReps * 5) +
        closing.durationSeconds;
  }
}
