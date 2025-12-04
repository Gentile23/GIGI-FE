import 'package:dio/dio.dart';
import 'api_client.dart';
import 'openai_service.dart';
import '../../core/constants/api_config.dart';
import '../models/workout_model.dart';
import '../models/user_model.dart';
import '../models/user_profile_model.dart';

class WorkoutService {
  final ApiClient _apiClient;
  final OpenAIService _openAIService;

  WorkoutService(this._apiClient) : _openAIService = OpenAIService();

  Future<Map<String, dynamic>> getWorkoutPlans() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.workoutPlans);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final plans = data.map((json) => WorkoutPlan.fromJson(json)).toList();
        return {'success': true, 'plans': plans};
      }

      return {'success': false, 'message': 'Failed to fetch workout plans'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message':
            e.response?.data['message'] ?? 'Failed to fetch workout plans',
      };
    }
  }

  Future<Map<String, dynamic>> getCurrentPlan() async {
    try {
      print('DEBUG: Calling API: ${ApiConfig.workoutPlansCurrent}');
      final response = await _apiClient.dio.get(ApiConfig.workoutPlansCurrent);
      print('DEBUG: API Response status: ${response.statusCode}');
      print('DEBUG: API Response data type: ${response.data.runtimeType}');

      if (response.statusCode == 200 && response.data != null) {
        final planData =
            response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        print(
          'DEBUG: Plan data keys: ${planData is Map ? planData.keys : "not a map"}',
        );

        final plan = WorkoutPlan.fromJson(planData);
        print('DEBUG: Parsed plan ID: ${plan.id}');
        print('DEBUG: Parsed plan workouts count: ${plan.workouts.length}');

        return {'success': true, 'plan': plan};
      }

      print('DEBUG: No plan found - status: ${response.statusCode}');
      return {'success': false, 'message': 'No current plan found'};
    } on DioException catch (e) {
      print('ERROR: DioException in getCurrentPlan: ${e.message}');
      print('ERROR: Response data: ${e.response?.data}');
      return {
        'success': false,
        'message':
            e.response?.data['message'] ?? 'Failed to fetch current plan',
      };
    } catch (e) {
      print('ERROR: Unexpected error in getCurrentPlan: $e');
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  Future<Map<String, dynamic>> generatePlan() async {
    try {
      final response = await _apiClient.dio.post(
        ApiConfig.workoutPlansGenerate,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final planData =
            response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        return {'success': true, 'plan': WorkoutPlan.fromJson(planData)};
      }

      return {'success': false, 'message': 'Failed to generate plan'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to generate plan',
      };
    }
  }

  Future<Map<String, dynamic>> getPlanById(String planId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConfig.workoutPlans}/$planId',
      );

      if (response.statusCode == 200 && response.data != null) {
        // Backend returns the plan directly
        if (response.data is Map<String, dynamic>) {
          print('DEBUG: Fetched Plan JSON: ${response.data}'); // DEBUG PRINT
          return {'success': true, 'plan': WorkoutPlan.fromJson(response.data)};
        }
      }

      return {'success': false, 'message': 'Plan not found'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to fetch plan',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error fetching plan: $e'};
    }
  }

  /// Generate AI-powered workout plan using OpenAI
  Future<Map<String, dynamic>> generateAIPlan({
    required UserModel user,
    required UserProfile profile,
  }) async {
    try {
      // Generate plan using OpenAI
      final aiResponse = await _openAIService.generateWorkoutPlan(
        user: user,
        profile: profile,
      );

      // Convert OpenAI response to WorkoutPlan model
      final workoutPlanData = aiResponse['workoutPlan'];

      // Create WorkoutPlan from AI response
      final plan = _convertAIResponseToWorkoutPlan(workoutPlanData, user.id);

      return {'success': true, 'plan': plan, 'aiGenerated': true};
    } catch (e) {
      return {'success': false, 'message': 'Failed to generate AI plan: $e'};
    }
  }

  /// Convert OpenAI response to WorkoutPlan model
  WorkoutPlan _convertAIResponseToWorkoutPlan(
    Map<String, dynamic> aiData,
    String userId,
  ) {
    final weeklySchedule = aiData['weeklySchedule'] as List<dynamic>;

    // Convert to WorkoutDay list
    final workoutDays = weeklySchedule.map((day) {
      final exercisesData = day['exercises'] as List<dynamic>;
      final focusAreas = day['focusAreas'] != null
          ? List<String>.from(day['focusAreas'] as List)
          : <String>[];

      final workoutExercises = exercisesData.map((ex) {
        // Create Exercise object
        final exercise = Exercise(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: ex['name'] as String,
          description: ex['notes'] as String? ?? '',
          muscleGroups: focusAreas,
          difficulty: ExerciseDifficulty.intermediate,
          equipment: [],
        );

        // Create WorkoutExercise with sets/reps
        return WorkoutExercise(
          exercise: exercise,
          sets: ex['sets'] as int,
          reps: ex['reps'].toString(),
          restSeconds: _parseRestSeconds(ex['rest'] as String),
          notes: ex['notes'] as String?,
        );
      }).toList();

      // Calculate estimated duration
      final estimatedDuration = _calculateDuration(workoutExercises);

      return WorkoutDay(
        id:
            DateTime.now().millisecondsSinceEpoch.toString() +
            '_' +
            day['dayName'],
        name: day['dayName'] as String,
        focus: focusAreas.join(', '),
        exercises: workoutExercises,
        estimatedDuration: estimatedDuration,
      );
    }).toList();

    return WorkoutPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      generatedAt: DateTime.now(),
      durationWeeks: aiData['durationWeeks'] as int,
      weeklyFrequency: workoutDays.length,
      workouts: workoutDays,
    );
  }

  /// Parse rest time string to seconds
  int _parseRestSeconds(String restString) {
    final match = RegExp(r'(\d+)').firstMatch(restString);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 60; // Default 60 seconds
  }

  /// Calculate estimated duration based on exercises
  int _calculateDuration(List<WorkoutExercise> exercises) {
    int totalSeconds = 0;
    for (final ex in exercises) {
      // Time per set: ~30 seconds + rest time
      totalSeconds += (ex.sets * (30 + ex.restSeconds));
    }
    // Add 10 minutes for warmup/cooldown
    return (totalSeconds ~/ 60) + 10;
  }
}
