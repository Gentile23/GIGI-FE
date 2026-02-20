import 'workout_model.dart';

/// Model for a custom workout plan created by the user
class CustomWorkoutPlan {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final int estimatedDuration;
  final int exerciseCount;
  final List<CustomWorkoutExercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomWorkoutPlan({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    required this.estimatedDuration,
    required this.exerciseCount,
    required this.exercises,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomWorkoutPlan.fromJson(Map<String, dynamic> json) {
    return CustomWorkoutPlan(
      id: json['id'].toString(),
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      estimatedDuration: json['estimated_duration'] as int? ?? 0,
      exerciseCount: json['exercise_count'] as int? ?? 0,
      exercises:
          (json['exercises'] as List<dynamic>?)
              ?.map(
                (e) =>
                    CustomWorkoutExercise.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive,
      'estimated_duration': estimatedDuration,
      'exercise_count': exerciseCount,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CustomWorkoutPlan copyWith({
    String? id,
    String? name,
    String? description,
    bool? isActive,
    int? estimatedDuration,
    int? exerciseCount,
    List<CustomWorkoutExercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomWorkoutPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      exerciseCount: exerciseCount ?? this.exerciseCount,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Model for an exercise within a custom workout plan
class CustomWorkoutExercise {
  final String id;
  final Exercise exercise;
  final int sets;
  final String reps;
  final int restSeconds;
  final int orderIndex;
  final String? exerciseType;
  final String? position;
  final String? notes;

  CustomWorkoutExercise({
    required this.id,
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.orderIndex,
    this.exerciseType = 'strength',
    this.position = 'main',
    this.notes,
  });

  factory CustomWorkoutExercise.fromJson(Map<String, dynamic> json) {
    return CustomWorkoutExercise(
      id: json['id'].toString(),
      exercise: Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
      sets: json['sets'] as int,
      reps: json['reps'] as String,
      restSeconds: json['rest_seconds'] as int,
      orderIndex: json['order_index'] as int? ?? 0,
      exerciseType: json['exercise_type'] as String? ?? 'strength',
      position: json['position'] as String? ?? 'main',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exercise': exercise.toJson(),
      'sets': sets,
      'reps': reps,
      'rest_seconds': restSeconds,
      'order_index': orderIndex,
      'exercise_type': exerciseType,
      'position': position,
      'notes': notes,
    };
  }

  CustomWorkoutExercise copyWith({
    String? id,
    Exercise? exercise,
    int? sets,
    String? reps,
    int? restSeconds,
    int? orderIndex,
    String? exerciseType,
    String? position,
    String? notes,
  }) {
    return CustomWorkoutExercise(
      id: id ?? this.id,
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restSeconds: restSeconds ?? this.restSeconds,
      orderIndex: orderIndex ?? this.orderIndex,
      exerciseType: exerciseType ?? this.exerciseType,
      position: position ?? this.position,
      notes: notes ?? this.notes,
    );
  }
}

/// Request model for creating/updating a custom workout plan
class CustomWorkoutRequest {
  final String name;
  final String? description;
  final List<CustomWorkoutExerciseRequest> exercises;

  CustomWorkoutRequest({
    required this.name,
    this.description,
    this.exercises = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}

/// Request model for adding an exercise to a custom workout
class CustomWorkoutExerciseRequest {
  final String exerciseId;
  final int sets;
  final String reps;
  final int restSeconds;
  final String? exerciseType;
  final String? position;
  final String? notes;

  CustomWorkoutExerciseRequest({
    required this.exerciseId,
    this.sets = 3,
    this.reps = '10',
    this.restSeconds = 60,
    this.exerciseType = 'strength',
    this.position = 'main',
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'sets': sets,
      'reps': reps,
      'rest_seconds': restSeconds,
      'exercise_type': exerciseType,
      'position': position,
      'notes': notes,
    };
  }
}
