import 'package:gigi/data/models/workout_model.dart';

/// Workout log model - represents a completed workout session
class WorkoutLog {
  final String id;
  final String userId;
  final String? workoutPlanId;
  final String? workoutDayId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? durationMinutes;
  final String? notes;
  final WorkoutDay? workoutDay;
  final List<ExerciseLogModel> exerciseLogs;

  WorkoutLog({
    required this.id,
    required this.userId,
    this.workoutPlanId,
    this.workoutDayId,
    required this.startedAt,
    this.completedAt,
    this.durationMinutes,
    this.notes,
    this.workoutDay,
    this.exerciseLogs = const [],
  });

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    return WorkoutLog(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      workoutPlanId: json['workout_plan_id']?.toString(),
      workoutDayId: json['workout_day_id']?.toString(),
      startedAt: DateTime.parse(json['started_at']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      durationMinutes: json['duration_minutes'],
      notes: json['notes'],
      workoutDay: json['workout_day'] != null
          ? WorkoutDay.fromJson(json['workout_day'])
          : null,
      exerciseLogs: json['exercise_logs'] != null
          ? (json['exercise_logs'] as List)
                .map((e) => ExerciseLogModel.fromJson(e))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'workout_plan_id': workoutPlanId,
      'workout_day_id': workoutDayId,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'notes': notes,
    };
  }

  bool get isCompleted => completedAt != null;

  String get durationFormatted {
    if (durationMinutes == null) return '0 min';

    final hours = durationMinutes! ~/ 60;
    final minutes = durationMinutes! % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  int get totalExercises => exerciseLogs.length;

  double get totalVolume {
    return exerciseLogs.fold(0.0, (sum, log) => sum + log.totalVolume);
  }
}

/// Exercise log model - represents an exercise performed in a workout
class ExerciseLogModel {
  final String id;
  final String workoutLogId;
  final String exerciseId;
  final int orderIndex;
  final String exerciseType;
  final String? notes;
  final Exercise? exercise;
  final List<SetLogModel> setLogs;

  ExerciseLogModel({
    required this.id,
    required this.workoutLogId,
    required this.exerciseId,
    required this.orderIndex,
    required this.exerciseType,
    this.notes,
    this.exercise,
    this.setLogs = const [],
  });

  factory ExerciseLogModel.fromJson(Map<String, dynamic> json) {
    return ExerciseLogModel(
      id: json['id'].toString(),
      workoutLogId: json['workout_log_id'].toString(),
      exerciseId: json['exercise_id'].toString(),
      orderIndex: json['order_index'] ?? 0,
      exerciseType: json['exercise_type'] ?? 'main',
      notes: json['notes'],
      exercise: json['exercise'] != null
          ? Exercise.fromJson(json['exercise'])
          : null,
      setLogs: json['set_logs'] != null
          ? (json['set_logs'] as List)
                .map((e) => SetLogModel.fromJson(e))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workout_log_id': workoutLogId,
      'exercise_id': exerciseId,
      'order_index': orderIndex,
      'exercise_type': exerciseType,
      'notes': notes,
    };
  }

  double get totalVolume {
    return setLogs.fold(0.0, (sum, log) => sum + log.volume);
  }

  int get totalReps {
    return setLogs.fold(0, (sum, log) => sum + log.reps);
  }

  double get averageWeight {
    final setsWithWeight = setLogs.where(
      (s) => s.weightKg != null && s.weightKg! > 0,
    );
    if (setsWithWeight.isEmpty) return 0;

    return setsWithWeight.fold(0.0, (sum, log) => sum + log.weightKg!) /
        setsWithWeight.length;
  }

  double get maxWeight {
    if (setLogs.isEmpty) return 0;
    return setLogs.map((s) => s.weightKg ?? 0).reduce((a, b) => a > b ? a : b);
  }
}

/// Set log model - represents a single set performed
class SetLogModel {
  final String id;
  final String exerciseLogId;
  final int setNumber;
  final int reps;
  final double? weightKg;
  final int? durationSeconds;
  final int? rpe;
  final bool completed;

  SetLogModel({
    required this.id,
    required this.exerciseLogId,
    required this.setNumber,
    required this.reps,
    this.weightKg,
    this.durationSeconds,
    this.rpe,
    this.completed = true,
  });

  factory SetLogModel.fromJson(Map<String, dynamic> json) {
    return SetLogModel(
      id: json['id'].toString(),
      exerciseLogId: json['exercise_log_id'].toString(),
      setNumber: json['set_number'],
      reps: json['reps'],
      weightKg: json['weight_kg'] != null
          ? double.parse(json['weight_kg'].toString())
          : null,
      durationSeconds: json['duration_seconds'],
      rpe: json['rpe'],
      completed: json['completed'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_log_id': exerciseLogId,
      'set_number': setNumber,
      'reps': reps,
      'weight_kg': weightKg,
      'duration_seconds': durationSeconds,
      'rpe': rpe,
      'completed': completed,
    };
  }

  double get volume {
    if (weightKg == null) return 0;
    return weightKg! * reps;
  }

  String get weightFormatted {
    if (weightKg == null) return 'Bodyweight';
    return '${weightKg!.toStringAsFixed(1)} kg';
  }

  String? get durationFormatted {
    if (durationSeconds == null) return null;

    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;

    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }
}

/// Personal record model
class PersonalRecord {
  final String id;
  final String userId;
  final String exerciseId;
  final String recordType;
  final double value;
  final DateTime achievedAt;
  final String? setLogId;
  final Exercise? exercise;

  PersonalRecord({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.recordType,
    required this.value,
    required this.achievedAt,
    this.setLogId,
    this.exercise,
  });

  factory PersonalRecord.fromJson(Map<String, dynamic> json) {
    return PersonalRecord(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      exerciseId: json['exercise_id'].toString(),
      recordType: json['record_type'],
      value: double.parse(json['value'].toString()),
      achievedAt: DateTime.parse(json['achieved_at']),
      setLogId: json['set_log_id']?.toString(),
      exercise: json['exercise'] != null
          ? Exercise.fromJson(json['exercise'])
          : null,
    );
  }

  String get formattedValue {
    switch (recordType) {
      case 'max_weight':
        return '${value.toStringAsFixed(1)} kg';
      case 'max_reps':
        return '${value.toInt()} reps';
      case 'max_volume':
        return '${value.toStringAsFixed(1)} kg';
      default:
        return value.toString();
    }
  }

  String get typeLabel {
    switch (recordType) {
      case 'max_weight':
        return 'Max Weight';
      case 'max_reps':
        return 'Max Reps';
      case 'max_volume':
        return 'Max Volume';
      default:
        return recordType;
    }
  }
}

/// Workout statistics model
class WorkoutStats {
  final int totalWorkouts;
  final int totalTimeMinutes;
  final int totalExercises;
  final double totalVolumeKg;
  final int currentStreak;
  final int longestStreak;
  final int workoutsThisWeek;
  final int workoutsThisMonth;
  final double averageDurationMinutes;
  final Map<String, int> mostTrainedMuscles;

  WorkoutStats({
    required this.totalWorkouts,
    required this.totalTimeMinutes,
    required this.totalExercises,
    required this.totalVolumeKg,
    required this.currentStreak,
    required this.longestStreak,
    required this.workoutsThisWeek,
    required this.workoutsThisMonth,
    required this.averageDurationMinutes,
    required this.mostTrainedMuscles,
  });

  factory WorkoutStats.fromJson(Map<String, dynamic> json) {
    return WorkoutStats(
      totalWorkouts: json['total_workouts'] ?? 0,
      totalTimeMinutes: json['total_time_minutes'] ?? 0,
      totalExercises: json['total_exercises'] ?? 0,
      totalVolumeKg: double.parse(json['total_volume_kg']?.toString() ?? '0'),
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      workoutsThisWeek: json['workouts_this_week'] ?? 0,
      workoutsThisMonth: json['workouts_this_month'] ?? 0,
      averageDurationMinutes: double.parse(
        json['average_duration_minutes']?.toString() ?? '0',
      ),
      mostTrainedMuscles: json['most_trained_muscles'] != null
          ? Map<String, int>.from(json['most_trained_muscles'])
          : {},
    );
  }

  String get totalTimeFormatted {
    final hours = totalTimeMinutes ~/ 60;
    final minutes = totalTimeMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }
}
