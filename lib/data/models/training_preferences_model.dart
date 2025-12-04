/// Training preferences model for workout customization
class TrainingPreferences {
  final String id;
  final TrainingSplit trainingSplit;
  final int sessionDurationMinutes;
  final CardioPreference cardioPreference;
  final MobilityPreference mobilityPreference;
  final List<String>? additionalNotes;

  TrainingPreferences({
    required this.id,
    required this.trainingSplit,
    required this.sessionDurationMinutes,
    required this.cardioPreference,
    required this.mobilityPreference,
    this.additionalNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainingSplit': trainingSplit.name,
      'sessionDurationMinutes': sessionDurationMinutes,
      'cardioPreference': cardioPreference.name,
      'mobilityPreference': mobilityPreference.name,
      'additionalNotes': additionalNotes,
    };
  }

  factory TrainingPreferences.fromJson(Map<String, dynamic> json) {
    return TrainingPreferences(
      id: json['id'] as String,
      trainingSplit: TrainingSplit.values.firstWhere(
        (e) => e.name == json['trainingSplit'],
      ),
      sessionDurationMinutes: json['sessionDurationMinutes'] as int,
      cardioPreference: CardioPreference.values.firstWhere(
        (e) => e.name == json['cardioPreference'],
      ),
      mobilityPreference: MobilityPreference.values.firstWhere(
        (e) => e.name == json['mobilityPreference'],
      ),
      additionalNotes: json['additionalNotes'] != null
          ? List<String>.from(json['additionalNotes'] as List)
          : null,
    );
  }

  TrainingPreferences copyWith({
    String? id,
    TrainingSplit? trainingSplit,
    int? sessionDurationMinutes,
    CardioPreference? cardioPreference,
    MobilityPreference? mobilityPreference,
    List<String>? additionalNotes,
  }) {
    return TrainingPreferences(
      id: id ?? this.id,
      trainingSplit: trainingSplit ?? this.trainingSplit,
      sessionDurationMinutes:
          sessionDurationMinutes ?? this.sessionDurationMinutes,
      cardioPreference: cardioPreference ?? this.cardioPreference,
      mobilityPreference: mobilityPreference ?? this.mobilityPreference,
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }
}

/// Training split types
enum TrainingSplit {
  monofrequency, // Monofrequenza - ogni muscolo 1x settimana
  multifrequency, // Multifrequenza - ogni muscolo 2-3x settimana
  upperLower, // Upper/Lower split
  pushPullLegs, // Push/Pull/Legs
  fullBody, // Full body ogni sessione
  bodyPartSplit, // Bro split classico
  arnoldSplit, // Arnold split (chest/back, shoulders/arms, legs)
}

/// Cardio preferences
enum CardioPreference {
  none,
  warmUp, // Riscaldamento
  postWorkout, // Fine allenamento
  separateSession, // Sessione a parte
}

/// Mobility and stretching preferences
enum MobilityPreference {
  none, // Nessuna mobilità
  postWorkout, // Stretching post workout
  preWorkout, // Mobilità prima dell'allenamento
  dedicatedSession, // Sessione dedicata
}

/// Extension methods for better UI display
extension TrainingSplitExtension on TrainingSplit {
  String get displayName {
    switch (this) {
      case TrainingSplit.monofrequency:
        return 'Monofrequenza';
      case TrainingSplit.multifrequency:
        return 'Multifrequenza';
      case TrainingSplit.upperLower:
        return 'Upper/Lower';
      case TrainingSplit.pushPullLegs:
        return 'Push/Pull/Legs';
      case TrainingSplit.fullBody:
        return 'Full Body';
      case TrainingSplit.bodyPartSplit:
        return 'Split per Gruppo Muscolare';
      case TrainingSplit.arnoldSplit:
        return 'Arnold Split';
    }
  }

  String get description {
    switch (this) {
      case TrainingSplit.monofrequency:
        return 'Ogni gruppo muscolare allenato 1 volta a settimana';
      case TrainingSplit.multifrequency:
        return 'Ogni gruppo muscolare allenato 2-3 volte a settimana';
      case TrainingSplit.upperLower:
        return 'Alternanza tra parte superiore e inferiore del corpo';
      case TrainingSplit.pushPullLegs:
        return 'Spinta, Trazione, Gambe in rotazione';
      case TrainingSplit.fullBody:
        return 'Tutto il corpo in ogni sessione';
      case TrainingSplit.bodyPartSplit:
        return 'Un gruppo muscolare principale per sessione';
      case TrainingSplit.arnoldSplit:
        return 'Petto/Schiena, Spalle/Braccia, Gambe';
    }
  }

  int get recommendedWeeklyFrequency {
    switch (this) {
      case TrainingSplit.monofrequency:
      case TrainingSplit.bodyPartSplit:
        return 5;
      case TrainingSplit.multifrequency:
      case TrainingSplit.fullBody:
        return 3;
      case TrainingSplit.upperLower:
        return 4;
      case TrainingSplit.pushPullLegs:
        return 6;
      case TrainingSplit.arnoldSplit:
        return 6;
    }
  }

  String get icon {
    switch (this) {
      case TrainingSplit.monofrequency:
        return '1️⃣';
      case TrainingSplit.multifrequency:
        return '🔄';
      case TrainingSplit.upperLower:
        return '⬆️⬇️';
      case TrainingSplit.pushPullLegs:
        return '💪🏋️🦵';
      case TrainingSplit.fullBody:
        return '🎯';
      case TrainingSplit.bodyPartSplit:
        return '📋';
      case TrainingSplit.arnoldSplit:
        return '🏆';
    }
  }
}

extension CardioPreferenceExtension on CardioPreference {
  String get displayName {
    switch (this) {
      case CardioPreference.none:
        return 'Nessuno';
      case CardioPreference.warmUp:
        return 'Riscaldamento (5-10 min)';
      case CardioPreference.postWorkout:
        return 'Post-Workout (15-20 min)';
      case CardioPreference.separateSession:
        return 'Sessione Dedicata';
    }
  }

  String get description {
    switch (this) {
      case CardioPreference.none:
        return 'Solo pesi';
      case CardioPreference.warmUp:
        return 'Per attivare il corpo';
      case CardioPreference.postWorkout:
        return 'Per bruciare extra calorie';
      case CardioPreference.separateSession:
        return 'Focus sulla resistenza';
    }
  }

  String get icon {
    switch (this) {
      case CardioPreference.none:
        return '🚫';
      case CardioPreference.warmUp:
        return '🔥';
      case CardioPreference.postWorkout:
        return '🏃';
      case CardioPreference.separateSession:
        return '🚴';
    }
  }
}

extension MobilityPreferenceExtension on MobilityPreference {
  String get displayName {
    switch (this) {
      case MobilityPreference.none:
        return 'Nessuna';
      case MobilityPreference.postWorkout:
        return 'Stretching Post Workout';
      case MobilityPreference.preWorkout:
        return 'Mobilità Pre-Workout';
      case MobilityPreference.dedicatedSession:
        return 'Sessione Dedicata';
    }
  }

  String get description {
    switch (this) {
      case MobilityPreference.none:
        return 'Nessuna sessione di mobilità';
      case MobilityPreference.postWorkout:
        return 'Allungamento a fine sessione';
      case MobilityPreference.preWorkout:
        return 'Preparazione al movimento';
      case MobilityPreference.dedicatedSession:
        return 'Focus su flessibilità e mobilità';
    }
  }

  String get icon {
    switch (this) {
      case MobilityPreference.none:
        return '🚫';
      case MobilityPreference.postWorkout:
        return '🧘';
      case MobilityPreference.preWorkout:
        return '🤸';
      case MobilityPreference.dedicatedSession:
        return '✨';
    }
  }
}
