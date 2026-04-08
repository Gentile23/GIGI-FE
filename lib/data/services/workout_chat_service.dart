import '../models/workout_chat_model.dart';
import 'api_client.dart';

class WorkoutChatService {
  final ApiClient _apiClient;

  WorkoutChatService(this._apiClient);

  Future<WorkoutChatReply> sendMessage({
    required String message,
    required String workoutDayId,
    String? workoutLogId,
    String? exerciseId,
    required int elapsedSeconds,
    required List<String> completedExerciseIds,
    required bool restTimerActive,
  }) async {
    final workoutDayInt = int.tryParse(workoutDayId);
    if (workoutDayInt == null) {
      throw Exception('Workout day non valido per la chat.');
    }

    final response = await _apiClient.post(
      '/workout-chat/message',
      body: {
        'message': message,
        'workout_day_id': workoutDayInt,
        if (workoutLogId != null) 'workout_log_id': int.tryParse(workoutLogId),
        if (exerciseId != null) 'exercise_id': int.tryParse(exerciseId),
        'elapsed_seconds': elapsedSeconds,
        'completed_exercise_ids': completedExerciseIds
            .map((id) => int.tryParse(id))
            .whereType<int>()
            .toList(),
        'rest_timer_active': restTimerActive,
      },
    );

    if (response['success'] != true) {
      throw Exception(
        response['message']?.toString() ??
            'GIGI non e riuscita a rispondere in questo momento.',
      );
    }

    return WorkoutChatReply.fromJson(response);
  }
}
