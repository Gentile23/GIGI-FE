import 'workout_model.dart';

/// Model for static workout templates from database
class WorkoutTemplate {
  final int id;
  final String name;
  final String description;
  final String category;
  final String difficulty;
  final int durationMinutes;
  final String? imageUrl;
  final List<TemplateExercise> exercises;
  final int exerciseCount;

  WorkoutTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.durationMinutes,
    this.imageUrl,
    required this.exercises,
    required this.exerciseCount,
  });

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) {
    return WorkoutTemplate(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? 'intermediate',
      durationMinutes: json['duration_minutes'] ?? 30,
      imageUrl: json['image_url'],
      exercises:
          (json['exercises'] as List<dynamic>?)
              ?.map((e) => TemplateExercise.fromJson(e))
              .toList() ??
          [],
      exerciseCount: json['exercise_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'duration_minutes': durationMinutes,
      'image_url': imageUrl,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'exercise_count': exerciseCount,
    };
  }

  /// Convert template to WorkoutDay for use with WorkoutSessionScreen
  WorkoutDay toWorkoutDay() {
    return WorkoutDay(
      id: 'template_$id',
      name: name,
      focus: category.toUpperCase(),
      estimatedDuration: durationMinutes,
      exercises: exercises.map((templateExercise) {
        return WorkoutExercise(
          exercise: Exercise(
            id: templateExercise.exerciseId.toString(),
            name: templateExercise.exerciseName,
            description: templateExercise.exercise['description'] ?? '',
            videoUrl: templateExercise.exercise['video_url'],
            muscleGroups: _parseList(
              templateExercise.exercise['muscle_groups'],
            ),
            difficulty: _parseDifficulty(
              templateExercise.exercise['difficulty'],
            ),
            equipment: _parseList(templateExercise.exercise['equipment']),
          ),
          sets: templateExercise.sets,
          reps: templateExercise.reps,
          restSeconds: templateExercise.restSeconds,
          exerciseType: category == 'cardio' ? 'cardio' : 'strength',
          position: 'main',
        );
      }).toList(),
    );
  }

  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    if (value is String) return value.split(',').map((e) => e.trim()).toList();
    return [];
  }

  static ExerciseDifficulty _parseDifficulty(dynamic value) {
    if (value == null) return ExerciseDifficulty.intermediate;
    final str = value.toString().toLowerCase();
    if (str == 'beginner') return ExerciseDifficulty.beginner;
    if (str == 'advanced') return ExerciseDifficulty.advanced;
    return ExerciseDifficulty.intermediate;
  }
}

class TemplateExercise {
  final Map<String, dynamic> exercise;
  final int sets;
  final String reps;
  final int restSeconds;

  TemplateExercise({
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.restSeconds,
  });

  factory TemplateExercise.fromJson(Map<String, dynamic> json) {
    return TemplateExercise(
      exercise: json['exercise'] ?? {},
      sets: json['sets'] ?? 3,
      reps: json['reps']?.toString() ?? '10',
      restSeconds: json['rest_seconds'] ?? 60,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise': exercise,
      'sets': sets,
      'reps': reps,
      'rest_seconds': restSeconds,
    };
  }

  String get exerciseName => exercise['name'] ?? 'Unknown';
  int get exerciseId => exercise['id'] ?? 0;
}
