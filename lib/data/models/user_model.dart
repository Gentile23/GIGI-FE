import 'subscription_model.dart';
import 'user_profile_model.dart';
import '../../core/constants/subscription_tiers.dart';

/// User data model
class UserModel {
  final String id;
  final String email;
  final String name;
  final SubscriptionModel? subscription;
  final String? goal;
  final List<String>? goals; // NEW
  final String? experienceLevel;
  final int? weeklyFrequency;
  final String? trainingLocation;
  final List<String>? availableEquipment;
  final String? trainingSplit;
  final int? sessionDuration;
  final String? cardioPreference;
  final String? mobilityPreference;
  final bool voiceCoachingTrialUsed;
  final String? gender;
  final DateTime? dateOfBirth;
  final double? height; // in cm
  final double? weight; // in kg
  final String? bodyShape;
  final String? workoutType;
  final DateTime? createdAt;
  final DateTime?
  lastPlanGeneration; // Track when user last generated a workout plan
  final String? avatarUrl;

  // Professional Trainer Fields
  final TrainingHistory? trainingHistory;
  final List<String>? preferredDays;
  final TimePreference? timePreference;
  final int? sleepHours;
  final RecoveryCapacity? recoveryCapacity;
  final NutritionApproach? nutritionApproach;
  final BodyFatPercentage? bodyFatPercentage;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.subscription,
    this.goal,
    this.goals,
    this.experienceLevel,
    this.weeklyFrequency,
    this.trainingLocation,
    this.availableEquipment,
    this.trainingSplit,
    this.sessionDuration,
    this.cardioPreference,
    this.mobilityPreference,
    this.voiceCoachingTrialUsed = false,
    this.gender,
    this.dateOfBirth,
    this.height,
    this.weight,
    this.bodyShape,
    this.workoutType,
    this.createdAt,
    this.lastPlanGeneration,
    this.avatarUrl,
    // Professional Trainer Fields
    this.trainingHistory,
    this.preferredDays,
    this.timePreference,
    this.sleepHours,
    this.recoveryCapacity,
    this.nutritionApproach,
    this.bodyFatPercentage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;

    return UserModel(
      id: json['id'].toString(),
      email: json['email'] as String,
      name: json['name'] as String,
      subscription: json['subscription'] != null
          ? SubscriptionModel.fromJson(
              json['subscription'] as Map<String, dynamic>,
            )
          : null,
      goal: profile?['goal'] as String? ?? json['goal'] as String?,
      experienceLevel:
          profile?['level'] as String? ??
          profile?['experience_level'] as String? ??
          json['experience_level'] as String?,
      weeklyFrequency:
          _parseInt(profile?['weekly_frequency']) ??
          _parseInt(json['weekly_frequency']),
      trainingLocation:
          profile?['location'] as String? ??
          profile?['training_location'] as String? ??
          json['training_location'] as String?,
      availableEquipment: profile?['equipment'] != null
          ? List<String>.from(profile!['equipment'] as List)
          : (profile?['available_equipment'] != null
                ? List<String>.from(profile!['available_equipment'] as List)
                : (json['available_equipment'] != null
                      ? List<String>.from(json['available_equipment'] as List)
                      : null)),
      trainingSplit:
          profile?['training_split'] as String? ??
          json['training_split'] as String?,
      sessionDuration:
          _parseInt(profile?['session_duration']) ??
          _parseInt(json['session_duration']),
      cardioPreference:
          profile?['cardio_preference'] as String? ??
          json['cardio_preference'] as String?,
      mobilityPreference:
          profile?['mobility_preference'] as String? ??
          json['mobility_preference'] as String?,
      voiceCoachingTrialUsed:
          profile?['voice_coaching_trial_used'] as bool? ??
          json['voice_coaching_trial_used'] as bool? ??
          false,
      gender: json['gender'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      height: _parseDouble(profile?['height']) ?? _parseDouble(json['height']),
      weight: _parseDouble(profile?['weight']) ?? _parseDouble(json['weight']),
      bodyShape:
          profile?['body_shape'] as String? ?? json['body_shape'] as String?,
      workoutType:
          profile?['workout_type'] as String? ??
          json['workout_type'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      lastPlanGeneration: json['last_plan_generation'] != null
          ? DateTime.parse(json['last_plan_generation'] as String)
          : null,
      avatarUrl: json['avatar_url'] as String?,
      // Professional Trainer Fields
      trainingHistory: profile?['training_history'] != null
          ? TrainingHistory.values.firstWhere(
              (e) =>
                  e.toString().split('.').last == profile!['training_history'],
              orElse: () => TrainingHistory.somewhatConsistent,
            )
          : (json['training_history'] != null
                ? TrainingHistory.values.firstWhere(
                    (e) =>
                        e.toString().split('.').last ==
                        json['training_history'],
                    orElse: () => TrainingHistory.somewhatConsistent,
                  )
                : null),
      preferredDays: profile?['preferred_days'] != null
          ? List<String>.from(profile!['preferred_days'] as List)
          : (json['preferred_days'] != null
                ? List<String>.from(json['preferred_days'] as List)
                : null),
      timePreference: profile?['time_preference'] != null
          ? TimePreference.values.firstWhere(
              (e) =>
                  e.toString().split('.').last == profile!['time_preference'],
              orElse: () => TimePreference.afternoon,
            )
          : (json['time_preference'] != null
                ? TimePreference.values.firstWhere(
                    (e) =>
                        e.toString().split('.').last == json['time_preference'],
                    orElse: () => TimePreference.afternoon,
                  )
                : null),
      sleepHours:
          _parseInt(profile?['sleep_hours']) ?? _parseInt(json['sleep_hours']),
      recoveryCapacity: profile?['recovery_capacity'] != null
          ? RecoveryCapacity.values.firstWhere(
              (e) =>
                  e.toString().split('.').last == profile!['recovery_capacity'],
              orElse: () => RecoveryCapacity.good,
            )
          : (json['recovery_capacity'] != null
                ? RecoveryCapacity.values.firstWhere(
                    (e) =>
                        e.toString().split('.').last ==
                        json['recovery_capacity'],
                    orElse: () => RecoveryCapacity.good,
                  )
                : null),
      nutritionApproach: profile?['nutrition_approach'] != null
          ? NutritionApproach.values.firstWhere(
              (e) =>
                  e.toString().split('.').last ==
                  profile!['nutrition_approach'],
              orElse: () => NutritionApproach.intuitive,
            )
          : (json['nutrition_approach'] != null
                ? NutritionApproach.values.firstWhere(
                    (e) =>
                        e.toString().split('.').last ==
                        json['nutrition_approach'],
                    orElse: () => NutritionApproach.intuitive,
                  )
                : null),
      bodyFatPercentage: profile?['body_fat_percentage'] != null
          ? BodyFatPercentage.values.firstWhere(
              (e) =>
                  e.toString().split('.').last ==
                  profile!['body_fat_percentage'],
              orElse: () => BodyFatPercentage.average,
            )
          : (json['body_fat_percentage'] != null
                ? BodyFatPercentage.values.firstWhere(
                    (e) =>
                        e.toString().split('.').last ==
                        json['body_fat_percentage'],
                    orElse: () => BodyFatPercentage.average,
                  )
                : null),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Convenience getter for subscription tier
  SubscriptionTier get subscriptionTier =>
      subscription?.tier ?? SubscriptionTier.free;

  /// Check if user has completed the full questionnaire
  /// Required fields for workout plan generation:
  /// - goal (obiettivo)
  /// - experienceLevel (livello)
  /// - weeklyFrequency (frequenza settimanale)
  /// - trainingLocation (luogo allenamento)
  /// - availableEquipment (attrezzatura)
  /// - trainingSplit (split allenamento)
  /// - sessionDuration (durata sessione)
  bool get isQuestionnaireComplete {
    return goal != null &&
        goal!.isNotEmpty &&
        experienceLevel != null &&
        experienceLevel!.isNotEmpty &&
        weeklyFrequency != null &&
        weeklyFrequency! > 0 &&
        trainingLocation != null &&
        trainingLocation!.isNotEmpty &&
        availableEquipment != null &&
        availableEquipment!.isNotEmpty &&
        trainingSplit != null &&
        trainingSplit!.isNotEmpty &&
        sessionDuration != null &&
        sessionDuration! > 0;
  }

  /// Get list of missing questionnaire fields for user feedback
  List<String> get missingQuestionnaireFields {
    final missing = <String>[];
    if (goal == null || goal!.isEmpty) missing.add('Obiettivo');
    if (experienceLevel == null || experienceLevel!.isEmpty) {
      missing.add('Livello esperienza');
    }
    if (weeklyFrequency == null || weeklyFrequency! <= 0) {
      missing.add('Frequenza settimanale');
    }
    if (trainingLocation == null || trainingLocation!.isEmpty) {
      missing.add('Luogo allenamento');
    }
    if (availableEquipment == null || availableEquipment!.isEmpty) {
      missing.add('Attrezzatura disponibile');
    }
    if (trainingSplit == null || trainingSplit!.isEmpty) {
      missing.add('Tipo di split');
    }
    if (sessionDuration == null || sessionDuration! <= 0) {
      missing.add('Durata sessione');
    }
    return missing;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'subscription': subscription?.toJson(),
      'goal': goal,
      'experience_level': experienceLevel,
      'weekly_frequency': weeklyFrequency,
      'training_location': trainingLocation,
      'available_equipment': availableEquipment,
      'training_split': trainingSplit,
      'session_duration': sessionDuration,
      'cardio_preference': cardioPreference,
      'mobility_preference': mobilityPreference,
      'voice_coaching_trial_used': voiceCoachingTrialUsed,
      'gender': gender,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'height': height,
      'weight': weight,
      'body_shape': bodyShape,
      'workout_type': workoutType,
      'created_at': createdAt?.toIso8601String(),
      'last_plan_generation': lastPlanGeneration?.toIso8601String(),
      'avatar_url': avatarUrl,
      // Professional Trainer Fields
      'training_history': trainingHistory?.toString().split('.').last,
      'preferred_days': preferredDays,
      'time_preference': timePreference?.toString().split('.').last,
      'sleep_hours': sleepHours,
      'recovery_capacity': recoveryCapacity?.toString().split('.').last,
      'nutrition_approach': nutritionApproach?.toString().split('.').last,
      'body_fat_percentage': bodyFatPercentage?.toString().split('.').last,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    SubscriptionModel? subscription,
    String? goal,
    List<String>? goals,
    String? experienceLevel,
    int? weeklyFrequency,
    String? trainingLocation,
    List<String>? availableEquipment,
    String? trainingSplit,
    int? sessionDuration,
    String? cardioPreference,
    String? mobilityPreference,
    bool? voiceCoachingTrialUsed,
    String? gender,
    DateTime? dateOfBirth,
    double? height,
    double? weight,
    String? bodyShape,
    String? workoutType,
    DateTime? createdAt,
    DateTime? lastPlanGeneration,
    String? avatarUrl,
    // Professional Trainer Fields
    TrainingHistory? trainingHistory,
    List<String>? preferredDays,
    TimePreference? timePreference,
    int? sleepHours,
    RecoveryCapacity? recoveryCapacity,
    NutritionApproach? nutritionApproach,
    BodyFatPercentage? bodyFatPercentage,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      subscription: subscription ?? this.subscription,
      goal: goal ?? this.goal,
      goals: goals ?? this.goals,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      weeklyFrequency: weeklyFrequency ?? this.weeklyFrequency,
      trainingLocation: trainingLocation ?? this.trainingLocation,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      trainingSplit: trainingSplit ?? this.trainingSplit,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      cardioPreference: cardioPreference ?? this.cardioPreference,
      mobilityPreference: mobilityPreference ?? this.mobilityPreference,
      voiceCoachingTrialUsed:
          voiceCoachingTrialUsed ?? this.voiceCoachingTrialUsed,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bodyShape: bodyShape ?? this.bodyShape,
      workoutType: workoutType ?? this.workoutType,
      createdAt: createdAt ?? this.createdAt,
      lastPlanGeneration: lastPlanGeneration ?? this.lastPlanGeneration,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      trainingHistory: trainingHistory ?? this.trainingHistory,
      preferredDays: preferredDays ?? this.preferredDays,
      timePreference: timePreference ?? this.timePreference,
      sleepHours: sleepHours ?? this.sleepHours,
      recoveryCapacity: recoveryCapacity ?? this.recoveryCapacity,
      nutritionApproach: nutritionApproach ?? this.nutritionApproach,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
    );
  }
}
