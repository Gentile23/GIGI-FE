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
}

/// Cardio preferences
enum CardioPreference {
  none,
  warmUp, // Riscaldamento
  postWorkout, // Fine allenamento
  preAndPost, // NEW
  separateSession, // Sessione a parte
}

/// Mobility and stretching preferences
enum MobilityPreference {
  none, // Nessuna mobilità
  postWorkout, // Stretching post workout
  preWorkout, // Mobilità prima dell'allenamento
  preAndPost, // NEW
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
    }
  }

  int get recommendedWeeklyFrequency {
    switch (this) {
      case TrainingSplit.monofrequency:
        return 5;
      case TrainingSplit.multifrequency:
      case TrainingSplit.fullBody:
        return 3;
      case TrainingSplit.upperLower:
        return 4;
      case TrainingSplit.pushPullLegs:
        return 6;
    }
  }

  String get icon {
    switch (this) {
      case TrainingSplit.monofrequency:
        return '🗓️';
      case TrainingSplit.multifrequency:
        return '📑';
      case TrainingSplit.upperLower:
        return '⚖️';
      case TrainingSplit.pushPullLegs:
        return '🔄';
      case TrainingSplit.fullBody:
        return '🌍';
    }
  }
}

extension CardioPreferenceExtension on CardioPreference {
  String get displayName {
    switch (this) {
      case CardioPreference.none:
        return 'Nessuno';
      case CardioPreference.warmUp:
        return 'Solo Riscaldamento';
      case CardioPreference.postWorkout:
        return 'Solo Fine Allenamento';
      case CardioPreference.preAndPost:
        return 'Sia Prima che Dopo';
      case CardioPreference.separateSession:
        return 'Sessione Separata';
    }
  }

  String get description {
    switch (this) {
      case CardioPreference.none:
        return 'Solo pesi';
      case CardioPreference.warmUp:
        return '10-15 min prima della forza.';
      case CardioPreference.postWorkout:
        return '15-30 min dopo la forza.';
      case CardioPreference.preAndPost:
        return 'Breve riscaldamento e cardio finale.';
      case CardioPreference.separateSession:
        return 'In giorni o orari diversi.';
    }
  }

  String get icon {
    switch (this) {
      case CardioPreference.none:
        return '🚫';
      case CardioPreference.warmUp:
        return '🏃‍♂️';
      case CardioPreference.postWorkout:
        return '🏁';
      case CardioPreference.preAndPost:
        return '🔄';
      case CardioPreference.separateSession:
        return '📅';
    }
  }
}

extension MobilityPreferenceExtension on MobilityPreference {
  String get displayName {
    switch (this) {
      case MobilityPreference.none:
        return 'Nessuna';
      case MobilityPreference.preWorkout:
        return 'Pre-Workout (Dinamica)';
      case MobilityPreference.postWorkout:
        return 'Post-Workout (Statica)';
      case MobilityPreference.preAndPost:
        return 'Sia Prima che Dopo';
      case MobilityPreference.dedicatedSession:
        return 'Sessione Dedicata';
    }
  }

  String get description {
    switch (this) {
      case MobilityPreference.none:
        return 'Nessuna sessione di mobilità';
      case MobilityPreference.preWorkout:
        return 'Focus sulla mobilità articolare.';
      case MobilityPreference.postWorkout:
        return 'Focus su stretching e rilascio.';
      case MobilityPreference.preAndPost:
        return 'Mobilità dinamica e stretching finale.';
      case MobilityPreference.dedicatedSession:
        return 'Allenamento completo di mobilità.';
    }
  }

  String get icon {
    switch (this) {
      case MobilityPreference.none:
        return '🚫';
      case MobilityPreference.preWorkout:
        return '🤸‍♂️';
      case MobilityPreference.postWorkout:
        return '🧘‍♂️';
      case MobilityPreference.preAndPost:
        return '🔄';
      case MobilityPreference.dedicatedSession:
        return '🧘';
    }
  }
}
