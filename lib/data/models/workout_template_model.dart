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
