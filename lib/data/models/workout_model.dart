import 'voice_coaching_model.dart';

/// Exercise model
class Exercise {
  final String id;
  final String name;
  final String? nameIt;
  final String description;
  final String? descriptionIt;
  final String? videoUrl;
  final List<String> muscleGroups;
  final List<String> secondaryMuscleGroups;
  final ExerciseDifficulty difficulty;
  final List<String> equipment;
  final VoiceCoaching? voiceCoaching;
  final String? displayName;
  final String? displayDescription;

  Exercise({
    required this.id,
    required this.name,
    this.nameIt,
    required this.description,
    this.descriptionIt,
    this.videoUrl,
    required this.muscleGroups,
    this.secondaryMuscleGroups = const [],
    required this.difficulty,
    required this.equipment,
    this.voiceCoaching,
    this.displayName,
    this.displayDescription,
  });

  /// Returns the localized name (display_name from API, or falls back to name)
  String get localizedName => displayName ?? name;

  /// Returns the localized description
  String get localizedDescription => displayDescription ?? description;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'videoUrl': videoUrl,
      'muscleGroups': muscleGroups,
      'secondaryMuscleGroups': secondaryMuscleGroups,
      'difficulty': difficulty.toString(),
      'equipment': equipment,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    // Parse voice coaching if available
    VoiceCoaching? voiceCoaching;
    if (json.containsKey('voice_coaching') && json['voice_coaching'] != null) {
      if (json['voice_coaching'] is Map<String, dynamic>) {
        voiceCoaching = VoiceCoaching.fromJson(json['voice_coaching']);
      }
    }

    return Exercise(
      id: json['id'].toString(),
      name: json['name'] as String,
      nameIt: json['name_it'] as String?,
      description: json['description'] as String,
      descriptionIt: json['description_it'] as String?,
      videoUrl: json['video_url'] as String?,
      muscleGroups: _parseList(json['muscle_groups']),
      secondaryMuscleGroups: _parseList(json['secondary_muscle_groups']),
      difficulty: ExerciseDifficulty.values.firstWhere(
        (e) => e.toString().split('.').last == json['difficulty'],
        orElse: () => ExerciseDifficulty.beginner,
      ),
      equipment: _parseList(json['equipment']),
      voiceCoaching: voiceCoaching,
      displayName: json['display_name'] as String?,
      displayDescription: json['display_description'] as String?,
    );
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) {
      try {
        // Try to remove brackets and split if it looks like a stringified list
        // Or handle JSON decoding if needed, but simple split is often enough for "Item1, Item2"
        // However, if it's "[\"Item1\", \"Item2\"]", we need to clean it up.
        String cleaned = value.trim();
        if (cleaned.startsWith('[') && cleaned.endsWith(']')) {
          cleaned = cleaned.substring(1, cleaned.length - 1);
          // Handle quoted strings inside
          if (cleaned.contains('"')) {
            cleaned = cleaned.replaceAll('"', '');
          }
          // Handle escaped quotes
          if (cleaned.contains('\\"')) {
            cleaned = cleaned.replaceAll('\\"', '');
          }
        }
        if (cleaned.isEmpty) return [];
        return cleaned.split(',').map((e) => e.trim()).toList();
      } catch (_) {
        return [value];
      }
    }
    return [];
  }
}

enum ExerciseDifficulty { beginner, intermediate, advanced }

/// Workout exercise with sets and reps
class WorkoutExercise {
  final Exercise exercise;
  final int sets;
  final String reps;
  final int restSeconds;
  final String? notes;
  final String exerciseType; // 'strength', 'mobility', 'cardio', 'warmup'
  final String position; // 'warmup', 'pre_workout', 'main', 'post_workout'
  final double? suggestedWeightKg; // AI suggested weight for first-time users

  WorkoutExercise({
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.notes,
    this.exerciseType = 'strength', // Default to strength
    this.position = 'main', // Default to main
    this.suggestedWeightKg,
  });

  Map<String, dynamic> toJson() {
    return {
      'exercise': exercise.toJson(),
      'sets': sets,
      'reps': reps,
      'restSeconds': restSeconds,
      'notes': notes,
      'exerciseType': exerciseType,
      'position': position,
      'suggestedWeightKg': suggestedWeightKg,
    };
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    // Handle missing exercise data safely
    final exerciseData = json['exercise'];
    final exercise = exerciseData != null
        ? Exercise.fromJson(exerciseData as Map<String, dynamic>)
        : Exercise(
            id: 'unknown',
            name: 'Unknown Exercise',
            description: 'Exercise data missing',
            muscleGroups: [],
            difficulty: ExerciseDifficulty.beginner,
            equipment: [],
          );

    return WorkoutExercise(
      exercise: exercise,
      sets: _parseInt(json['sets']) ?? 3,
      reps: json['reps']?.toString() ?? '10',
      restSeconds: _parseInt(json['rest_seconds']) ?? 60,
      notes: json['notes'] as String?,
      exerciseType: json['exercise_type'] as String? ?? 'strength',
      position: json['position'] as String? ?? 'main',
      suggestedWeightKg: _parseDouble(json['suggested_weight_kg']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      // Handle ranges like "12-15" by taking the first number
      final match = RegExp(r'(\d+)').firstMatch(value);
      if (match != null) {
        return int.parse(match.group(1)!);
      }
    }
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Workout day
class WorkoutDay {
  final String id;
  final String name;
  final String focus;
  final List<WorkoutExercise> exercises;
  final int estimatedDuration; // in minutes

  WorkoutDay({
    required this.id,
    required this.name,
    required this.focus,
    required this.exercises,
    required this.estimatedDuration,
  });

  // Computed properties for exercise categorization
  List<WorkoutExercise> get warmupExercises =>
      exercises.where((e) => e.exerciseType == 'warmup').toList();

  List<WorkoutExercise> get mainExercises =>
      exercises.where((e) => e.exerciseType == 'strength').toList();

  List<WorkoutExercise> get mobilityExercises =>
      exercises.where((e) => e.exerciseType == 'mobility').toList();

  List<WorkoutExercise> get cardioExercises =>
      exercises.where((e) => e.exerciseType == 'cardio').toList();

  // Position-based categorization for dynamic ordering
  List<WorkoutExercise> get warmupCardio =>
      exercises.where((e) => e.position == 'warmup').toList();

  List<WorkoutExercise> get preWorkoutMobility =>
      exercises.where((e) => e.position == 'pre_workout').toList();

  List<WorkoutExercise> get mainWorkout =>
      exercises.where((e) => e.position == 'main').toList();

  List<WorkoutExercise> get postWorkoutExercises =>
      exercises.where((e) => e.position == 'post_workout').toList();

  // Ordered exercises based on position
  List<WorkoutExercise> get orderedExercises {
    final List<WorkoutExercise> ordered = [];
    ordered.addAll(warmupCardio);
    ordered.addAll(preWorkoutMobility);
    ordered.addAll(mainWorkout);
    ordered.addAll(postWorkoutExercises);
    return ordered;
  }

  // Count only main strength exercises
  int get mainExerciseCount => mainExercises.length;

  // Check if workout has optional sections
  bool get hasWarmup => warmupExercises.isNotEmpty || warmupCardio.isNotEmpty;
  bool get hasMobility => mobilityExercises.isNotEmpty;
  bool get hasCardio => cardioExercises.isNotEmpty;
  bool get hasPreWorkoutMobility => preWorkoutMobility.isNotEmpty;
  bool get hasPostWorkoutExercises => postWorkoutExercises.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'focus': focus,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'estimatedDuration': estimatedDuration,
    };
  }

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String,
      focus: json['focus'] as String,
      exercises:
          (json['workout_exercises'] as List?)
              ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      estimatedDuration: json['estimated_duration'] as int,
    );
  }
}

/// Complete workout plan
class WorkoutPlan {
  final String id;
  final String userId;
  final DateTime generatedAt;
  final int durationWeeks;
  final int weeklyFrequency;
  final List<WorkoutDay> workouts;
  final String status;
  final String? errorMessage;

  WorkoutPlan({
    required this.id,
    required this.userId,
    required this.generatedAt,
    required this.durationWeeks,
    required this.weeklyFrequency,
    required this.workouts,
    this.status = 'completed',
    this.errorMessage,
  });

  // Getter for backward compatibility
  List<WorkoutDay> get workoutDays => workouts;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'generatedAt': generatedAt.toIso8601String(),
      'durationWeeks': durationWeeks,
      'weeklyFrequency': weeklyFrequency,
      'workouts': workouts.map((w) => w.toJson()).toList(),
      'status': status,
      'errorMessage': errorMessage,
    };
  }

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : DateTime.now(),
      durationWeeks: json['duration_weeks'] ?? 4,
      weeklyFrequency: json['weekly_frequency'] ?? 3,
      workouts:
          (json['workout_days'] as List?)
              ?.map((w) => WorkoutDay.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      status: json['status'] ?? 'completed',
      errorMessage: json['error_message'],
    );
  }
}
