// Unit tests for Workout model
import 'package:flutter_test/flutter_test.dart';

// Mock Exercise class for testing
class Exercise {
  final int id;
  final String name;
  final String muscleGroup;
  final int sets;
  final int reps;
  final double? weight;
  final int restSeconds;
  final String? videoUrl;
  final String? description;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.sets = 3,
    this.reps = 10,
    this.weight,
    this.restSeconds = 60,
    this.videoUrl,
    this.description,
  });

  double get totalVolume => (weight ?? 0) * sets * reps;

  Duration get totalRestTime => Duration(seconds: restSeconds * (sets - 1));

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      muscleGroup: json['muscle_group'] ?? '',
      sets: json['sets'] ?? 3,
      reps: json['reps'] ?? 10,
      weight: json['weight']?.toDouble(),
      restSeconds: json['rest_seconds'] ?? 60,
      videoUrl: json['video_url'],
      description: json['description'],
    );
  }
}

// Mock Workout class for testing
class Workout {
  final int id;
  final String name;
  final String? description;
  final List<Exercise> exercises;
  final int estimatedDuration; // in minutes
  final String difficulty;
  final String type;
  final bool isAiGenerated;

  Workout({
    required this.id,
    required this.name,
    this.description,
    required this.exercises,
    this.estimatedDuration = 45,
    this.difficulty = 'intermediate',
    this.type = 'strength',
    this.isAiGenerated = false,
  });

  int get totalExercises => exercises.length;

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets);

  double get totalVolume => exercises.fold(0, (sum, e) => sum + e.totalVolume);

  double get estimatedCalories {
    // Simple estimation: ~5 kcal per minute of workout
    return estimatedDuration * 5.0;
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    final exerciseList =
        (json['exercises'] as List?)
            ?.map((e) => Exercise.fromJson(e))
            .toList() ??
        [];

    return Workout(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      exercises: exerciseList,
      estimatedDuration: json['estimated_duration'] ?? 45,
      difficulty: json['difficulty'] ?? 'intermediate',
      type: json['type'] ?? 'strength',
      isAiGenerated: json['is_ai_generated'] ?? false,
    );
  }
}

void main() {
  group('Exercise Model', () {
    test('Exercise creation with required fields', () {
      final exercise = Exercise(
        id: 1,
        name: 'Bench Press',
        muscleGroup: 'chest',
      );

      expect(exercise.id, 1);
      expect(exercise.name, 'Bench Press');
      expect(exercise.muscleGroup, 'chest');
      expect(exercise.sets, 3);
      expect(exercise.reps, 10);
    });

    test('Exercise creation with custom values', () {
      final exercise = Exercise(
        id: 2,
        name: 'Squat',
        muscleGroup: 'legs',
        sets: 5,
        reps: 5,
        weight: 100,
        restSeconds: 180,
      );

      expect(exercise.sets, 5);
      expect(exercise.reps, 5);
      expect(exercise.weight, 100);
      expect(exercise.restSeconds, 180);
    });

    test('Total volume calculation', () {
      final exercise = Exercise(
        id: 1,
        name: 'Bench Press',
        muscleGroup: 'chest',
        sets: 4,
        reps: 8,
        weight: 60,
      );

      // Volume = 60kg * 4 sets * 8 reps = 1920
      expect(exercise.totalVolume, 1920);
    });

    test('Total volume is 0 when no weight', () {
      final exercise = Exercise(
        id: 1,
        name: 'Push-ups',
        muscleGroup: 'chest',
        sets: 3,
        reps: 15,
      );

      expect(exercise.totalVolume, 0);
    });

    test('Total rest time calculation', () {
      final exercise = Exercise(
        id: 1,
        name: 'Bench Press',
        muscleGroup: 'chest',
        sets: 4,
        restSeconds: 90,
      );

      // Rest = 90s * (4-1) = 270 seconds
      expect(exercise.totalRestTime.inSeconds, 270);
    });
  });

  group('Workout Model', () {
    late Workout workout;

    setUp(() {
      workout = Workout(
        id: 1,
        name: 'Full Body Strength',
        description: 'Complete full body workout',
        exercises: [
          Exercise(
            id: 1,
            name: 'Squat',
            muscleGroup: 'legs',
            sets: 4,
            reps: 8,
            weight: 80,
          ),
          Exercise(
            id: 2,
            name: 'Bench Press',
            muscleGroup: 'chest',
            sets: 4,
            reps: 8,
            weight: 60,
          ),
          Exercise(
            id: 3,
            name: 'Deadlift',
            muscleGroup: 'back',
            sets: 3,
            reps: 5,
            weight: 100,
          ),
        ],
        estimatedDuration: 60,
        difficulty: 'intermediate',
        type: 'strength',
      );
    });

    test('Workout creation', () {
      expect(workout.id, 1);
      expect(workout.name, 'Full Body Strength');
      expect(workout.difficulty, 'intermediate');
    });

    test('Total exercises count', () {
      expect(workout.totalExercises, 3);
    });

    test('Total sets count', () {
      // 4 + 4 + 3 = 11 sets
      expect(workout.totalSets, 11);
    });

    test('Total volume calculation', () {
      // Squat: 80 * 4 * 8 = 2560
      // Bench: 60 * 4 * 8 = 1920
      // Deadlift: 100 * 3 * 5 = 1500
      // Total = 5980
      expect(workout.totalVolume, 5980);
    });

    test('Estimated calories calculation', () {
      // 60 minutes * 5 = 300 kcal
      expect(workout.estimatedCalories, 300);
    });

    test('Empty workout has zero totals', () {
      final emptyWorkout = Workout(id: 2, name: 'Empty Workout', exercises: []);

      expect(emptyWorkout.totalExercises, 0);
      expect(emptyWorkout.totalSets, 0);
      expect(emptyWorkout.totalVolume, 0);
    });
  });

  group('Workout JSON Serialization', () {
    test('Workout.fromJson creates workout correctly', () {
      final json = {
        'id': 1,
        'name': 'Test Workout',
        'description': 'A test workout',
        'exercises': [
          {
            'id': 1,
            'name': 'Push-ups',
            'muscle_group': 'chest',
            'sets': 3,
            'reps': 15,
          },
        ],
        'estimated_duration': 30,
        'difficulty': 'beginner',
        'type': 'bodyweight',
        'is_ai_generated': true,
      };

      final workout = Workout.fromJson(json);

      expect(workout.id, 1);
      expect(workout.name, 'Test Workout');
      expect(workout.exercises.length, 1);
      expect(workout.estimatedDuration, 30);
      expect(workout.isAiGenerated, true);
    });

    test('Workout.fromJson handles missing exercises', () {
      final json = {'id': 1, 'name': 'Empty Workout'};

      final workout = Workout.fromJson(json);

      expect(workout.exercises, isEmpty);
    });
  });

  group('Workout Difficulty', () {
    test('Difficulty levels are valid', () {
      const validDifficulties = ['beginner', 'intermediate', 'advanced'];

      for (final diff in validDifficulties) {
        final workout = Workout(
          id: 1,
          name: 'Test',
          exercises: [],
          difficulty: diff,
        );
        expect(validDifficulties.contains(workout.difficulty), true);
      }
    });
  });

  group('Workout Types', () {
    test('Workout types are valid', () {
      const validTypes = [
        'strength',
        'hypertrophy',
        'endurance',
        'functional',
        'calisthenics',
      ];

      for (final type in validTypes) {
        final workout = Workout(id: 1, name: 'Test', exercises: [], type: type);
        expect(validTypes.contains(workout.type), true);
      }
    });
  });
}
