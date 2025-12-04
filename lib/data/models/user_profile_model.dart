import 'training_preferences_model.dart';
import 'injury_model.dart';

/// User profile enums and types

enum Gender { male, female }

enum BodyShape { skinny, lean, athletic, muscular, overweight, average }

enum FitnessGoal { muscleGain, weightLoss, toning, strength, wellness }

enum ExperienceLevel { beginner, intermediate, advanced }

enum TrainingLocation { gym, home, outdoor }

enum Equipment {
  bench,
  dumbbells,
  barbell,
  resistanceBands,
  machines,
  bodyweight,
}

enum WorkoutType {
  hypertrophy, // Focus sull'ipertrofia muscolare
  strength, // Focus sulla forza massimale
  endurance, // Focus sulla resistenza muscolare
  functional, // Allenamento funzionale
  calisthenics, // Corpo libero/calisthenics
}

/// Professional Trainer Fields - New Enums

enum TrainingHistory {
  veryConsistent, // 3-6 workouts/week, rarely missed
  somewhatConsistent, // 2-4 workouts/week, some breaks
  inconsistent, // 1-2 workouts/week, frequent breaks
  inactive, // Not training for 3+ months
}

enum TimePreference {
  morning, // 6-10am
  afternoon, // 14-18
  evening, // 18-22
}

enum RecoveryCapacity {
  excellent, // Wakes rested, recovers quickly
  good, // Recovers normally, occasional fatigue
  poor, // Struggles to recover, often fatigued
}

enum NutritionApproach {
  fullTracking, // Counts calories & macros
  partialTracking, // Portion control
  intuitive, // Healthy but not tracking
  none, // No tracking
}

enum BodyFatPercentage {
  veryHigh, // 20-25%+ (M) / 30-35%+ (F)
  high, // 15-20% (M) / 25-30% (F)
  average, // 10-15% (M) / 20-25% (F)
  athletic, // 6-10% (M) / 15-20% (F)
  veryLean, // <6% (M) / <15% (F)
}

/// User profile data
class UserProfile {
  final String userId;
  final FitnessGoal? goal;
  final ExperienceLevel? level;
  final int? weeklyFrequency;
  final TrainingLocation? trainingLocation;
  final List<Equipment>? availableEquipment;
  final TrainingPreferences? trainingPreferences;
  final List<InjuryModel> injuries;
  final List<String> limitations;

  final double? height; // in cm
  final double? weight; // in kg
  final Gender? gender;
  final int? age;

  final BodyShape? bodyShape;
  final WorkoutType? workoutType;

  // Professional Trainer Fields
  final TrainingHistory? trainingHistory;
  final List<String>? preferredDays;
  final TimePreference? timePreference;
  final int? sleepHours;
  final RecoveryCapacity? recoveryCapacity;
  final NutritionApproach? nutritionApproach;
  final BodyFatPercentage? bodyFatPercentage;

  UserProfile({
    required this.userId,
    this.height,
    this.weight,
    this.gender,
    this.age,
    this.bodyShape,
    this.workoutType,
    this.goal,
    this.level,
    this.weeklyFrequency,
    this.trainingLocation,
    this.availableEquipment,
    this.trainingPreferences,
    this.injuries = const [],
    this.limitations = const [],
    // Professional Trainer Fields
    this.trainingHistory,
    this.preferredDays,
    this.timePreference,
    this.sleepHours,
    this.recoveryCapacity,
    this.nutritionApproach,
    this.bodyFatPercentage,
  });

  // Convenience getters for backward compatibility
  TrainingLocation? get location => trainingLocation;
  List<Equipment>? get equipment => availableEquipment;
  ExperienceLevel? get experienceLevel => level;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      height: json['height'] != null
          ? (json['height'] as num).toDouble()
          : null,
      weight: json['weight'] != null
          ? (json['weight'] as num).toDouble()
          : null,
      gender: json['gender'] != null
          ? Gender.values.firstWhere(
              (e) => e.toString().split('.').last == json['gender'],
              orElse: () => Gender.male,
            )
          : null,
      age: json['age'] as int?,
      bodyShape: json['body_shape'] != null
          ? BodyShape.values.firstWhere(
              (e) => e.toString().split('.').last == json['body_shape'],
              orElse: () => BodyShape.average,
            )
          : null,
      workoutType: json['workout_type'] != null
          ? WorkoutType.values.firstWhere(
              (e) => e.toString().split('.').last == json['workout_type'],
              orElse: () => WorkoutType.hypertrophy,
            )
          : null,
      goal: json['goal'] != null
          ? FitnessGoal.values.firstWhere(
              (e) => e.toString().split('.').last == json['goal'],
              orElse: () => FitnessGoal.wellness,
            )
          : null,
      level: json['experience_level'] != null
          ? ExperienceLevel.values.firstWhere(
              (e) => e.toString().split('.').last == json['experience_level'],
              orElse: () => ExperienceLevel.beginner,
            )
          : null,
      weeklyFrequency: json['weekly_frequency'] as int?,
      trainingLocation: json['training_location'] != null
          ? TrainingLocation.values.firstWhere(
              (e) => e.toString().split('.').last == json['training_location'],
              orElse: () => TrainingLocation.gym,
            )
          : null,
      availableEquipment: json['available_equipment'] != null
          ? (json['available_equipment'] as List)
                .map(
                  (e) => Equipment.values.firstWhere(
                    (eq) => eq.toString().split('.').last == e,
                    orElse: () => Equipment.bodyweight,
                  ),
                )
                .toList()
          : null,
      trainingPreferences: json['training_preferences'] != null
          ? TrainingPreferences.fromJson(
              json['training_preferences'] as Map<String, dynamic>,
            )
          : null,
      injuries: json['injuries'] != null
          ? (json['injuries'] as List)
                .map((e) => InjuryModel.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      limitations: json['limitations'] != null
          ? List<String>.from(json['limitations'] as List)
          : [],
      // Professional Trainer Fields
      trainingHistory: json['training_history'] != null
          ? TrainingHistory.values.firstWhere(
              (e) => e.toString().split('.').last == json['training_history'],
              orElse: () => TrainingHistory.somewhatConsistent,
            )
          : null,
      preferredDays: json['preferred_days'] != null
          ? List<String>.from(json['preferred_days'] as List)
          : null,
      timePreference: json['time_preference'] != null
          ? TimePreference.values.firstWhere(
              (e) => e.toString().split('.').last == json['time_preference'],
              orElse: () => TimePreference.afternoon,
            )
          : null,
      sleepHours: json['sleep_hours'] as int?,
      recoveryCapacity: json['recovery_capacity'] != null
          ? RecoveryCapacity.values.firstWhere(
              (e) => e.toString().split('.').last == json['recovery_capacity'],
              orElse: () => RecoveryCapacity.good,
            )
          : null,
      nutritionApproach: json['nutrition_approach'] != null
          ? NutritionApproach.values.firstWhere(
              (e) => e.toString().split('.').last == json['nutrition_approach'],
              orElse: () => NutritionApproach.intuitive,
            )
          : null,
      bodyFatPercentage: json['body_fat_percentage'] != null
          ? BodyFatPercentage.values.firstWhere(
              (e) =>
                  e.toString().split('.').last == json['body_fat_percentage'],
              orElse: () => BodyFatPercentage.average,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'height': height,
      'weight': weight,
      'gender': gender?.toString().split('.').last,
      'age': age,
      'body_shape': bodyShape?.toString().split('.').last,
      'workout_type': workoutType?.toString().split('.').last,
      'goal': goal?.toString().split('.').last,
      'experience_level': level?.toString().split('.').last,
      'weekly_frequency': weeklyFrequency,
      'training_location': trainingLocation?.toString().split('.').last,
      'available_equipment': availableEquipment
          ?.map((e) => e.toString().split('.').last)
          .toList(),
      'training_preferences': trainingPreferences?.toJson(),
      'injuries': injuries.map((e) => e.toJson()).toList(),
      'limitations': limitations,
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
}
