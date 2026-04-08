class WorkoutChatMessage {
  final String id;
  final String role;
  final String content;
  final DateTime createdAt;
  final String? exerciseId;
  final List<String> suggestions;

  const WorkoutChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.exerciseId,
    this.suggestions = const [],
  });

  factory WorkoutChatMessage.user({
    required String content,
    String? exerciseId,
  }) {
    return WorkoutChatMessage(
      id: 'user_${DateTime.now().microsecondsSinceEpoch}',
      role: 'user',
      content: content,
      createdAt: DateTime.now(),
      exerciseId: exerciseId,
    );
  }

  factory WorkoutChatMessage.assistant({
    required String content,
    String? exerciseId,
    List<String> suggestions = const [],
  }) {
    return WorkoutChatMessage(
      id: 'assistant_${DateTime.now().microsecondsSinceEpoch}',
      role: 'assistant',
      content: content,
      createdAt: DateTime.now(),
      exerciseId: exerciseId,
      suggestions: suggestions,
    );
  }
}

class WorkoutChatReply {
  final String message;
  final List<String> suggestions;
  final String? exerciseId;
  final String? workoutLogId;

  const WorkoutChatReply({
    required this.message,
    this.suggestions = const [],
    this.exerciseId,
    this.workoutLogId,
  });

  factory WorkoutChatReply.fromJson(Map<String, dynamic> json) {
    final suggestionsData = json['suggestions'];
    final context = json['context'] as Map<String, dynamic>?;

    return WorkoutChatReply(
      message: json['message']?.toString() ?? '',
      suggestions: suggestionsData is List
          ? suggestionsData.map((item) => item.toString()).toList()
          : const [],
      exerciseId: context?['exercise_id']?.toString(),
      workoutLogId: context?['workout_log_id']?.toString(),
    );
  }
}
