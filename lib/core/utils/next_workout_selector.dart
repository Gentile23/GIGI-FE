import '../../data/models/custom_workout_model.dart';
import '../../data/models/workout_log_model.dart';
import '../../data/models/workout_model.dart';

enum NextWorkoutSource { ai, custom }

class NextWorkoutSuggestion {
  final WorkoutDay workoutDay;
  final NextWorkoutSource source;

  const NextWorkoutSuggestion({required this.workoutDay, required this.source});

  bool get isCustom => source == NextWorkoutSource.custom;
}

class NextWorkoutSelector {
  const NextWorkoutSelector._();

  static NextWorkoutSuggestion? resolve({
    required WorkoutPlan? aiPlan,
    required List<CustomWorkoutPlan> customPlans,
    required List<WorkoutLog> workoutHistory,
  }) {
    final aiWorkout = aiPlan?.workouts.isNotEmpty == true
        ? aiPlan!.workouts.first
        : null;

    if (customPlans.isEmpty) {
      if (aiWorkout == null) return null;
      return NextWorkoutSuggestion(
        workoutDay: aiWorkout,
        source: NextWorkoutSource.ai,
      );
    }

    final latestCompleted = _latestCompletedWorkout(workoutHistory);
    final latestCustomPlanId = _extractCustomPlanId(latestCompleted);

    if (latestCustomPlanId != null) {
      final currentIndex = customPlans.indexWhere(
        (plan) => plan.id == latestCustomPlanId,
      );

      if (currentIndex >= 0) {
        final nextCustomPlan =
            customPlans[(currentIndex + 1) % customPlans.length];
        return NextWorkoutSuggestion(
          workoutDay: mapCustomPlanToWorkoutDay(nextCustomPlan),
          source: NextWorkoutSource.custom,
        );
      }

      return NextWorkoutSuggestion(
        workoutDay: mapCustomPlanToWorkoutDay(customPlans.first),
        source: NextWorkoutSource.custom,
      );
    }

    if (aiWorkout != null) {
      return NextWorkoutSuggestion(
        workoutDay: aiWorkout,
        source: NextWorkoutSource.ai,
      );
    }

    return NextWorkoutSuggestion(
      workoutDay: mapCustomPlanToWorkoutDay(customPlans.first),
      source: NextWorkoutSource.custom,
    );
  }

  static WorkoutDay mapCustomPlanToWorkoutDay(CustomWorkoutPlan plan) {
    return WorkoutDay(
      id: 'custom_${plan.id}',
      name: plan.name,
      focus: plan.description ?? 'Personalizzata',
      estimatedDuration: plan.estimatedDuration,
      exercises: plan.exercises.map((entry) {
        return WorkoutExercise(
          exercise: entry.exercise,
          sets: entry.sets,
          reps: entry.reps,
          restSeconds: entry.restSeconds,
          restSecondsPerSet: entry.restSecondsPerSet,
          notes: entry.notes,
          position: 'main',
          exerciseType: entry.exerciseType ?? 'strength',
        );
      }).toList(),
    );
  }

  static String? customPlanIdFromWorkoutDayId(String? workoutDayId) {
    if (workoutDayId == null) return null;
    const prefix = 'custom_';
    if (!workoutDayId.startsWith(prefix)) return null;
    final planId = workoutDayId.substring(prefix.length).trim();
    return planId.isEmpty ? null : planId;
  }

  static WorkoutLog? _latestCompletedWorkout(List<WorkoutLog> workoutHistory) {
    WorkoutLog? latest;
    DateTime? latestDate;

    for (final log in workoutHistory) {
      final completedAt = log.completedAt;
      if (completedAt == null) continue;
      if (latestDate == null || completedAt.isAfter(latestDate)) {
        latest = log;
        latestDate = completedAt;
      }
    }

    return latest;
  }

  static String? _extractCustomPlanId(WorkoutLog? workoutLog) {
    if (workoutLog == null) return null;

    final explicit = workoutLog.customWorkoutPlanId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final fromWorkoutDayId = customPlanIdFromWorkoutDayId(
      workoutLog.workoutDayId,
    );
    if (fromWorkoutDayId != null) return fromWorkoutDayId;

    return customPlanIdFromWorkoutDayId(workoutLog.workoutDay?.id);
  }
}
