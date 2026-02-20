import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
      final response = await _apiClient.dio.get(
        ApiConfig.workoutPlans,
        queryParameters: {'language': 'it'},
      );

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
      debugPrint('DEBUG: Calling API: ${ApiConfig.workoutPlansCurrent}');
      final response = await _apiClient.dio.get(
        ApiConfig.workoutPlansCurrent,
        queryParameters: {'language': 'it'},
      );
      debugPrint('DEBUG: API Response status: ${response.statusCode}');
      debugPrint('DEBUG: API Response data type: ${response.data.runtimeType}');

      if (response.statusCode == 200 && response.data != null) {
        final planData =
            response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        debugPrint(
          'DEBUG: Plan data keys: ${planData is Map ? planData.keys : "not a map"}',
        );

        final plan = WorkoutPlan.fromJson(planData);
        debugPrint('DEBUG: Parsed plan ID: ${plan.id}');
        debugPrint(
          'DEBUG: Parsed plan workouts count: ${plan.workouts.length}',
        );

        return {'success': true, 'plan': plan};
      }

      debugPrint('DEBUG: No plan found - status: ${response.statusCode}');
      return {'success': false, 'message': 'No current plan found'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        debugPrint('DEBUG: No current plan found (404)');
        return {'success': false, 'message': 'No current plan found'};
      }
      debugPrint('ERROR: DioException in getCurrentPlan: ${e.message}');
      debugPrint('ERROR: Response data: ${e.response?.data}');
      return {
        'success': false,
        'message':
            e.response?.data['message'] ?? 'Failed to fetch current plan',
      };
    } catch (e) {
      debugPrint('ERROR: Unexpected error in getCurrentPlan: $e');
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  Future<Map<String, dynamic>> generatePlan({
    Map<String, dynamic>? filters,
    String? language,
    bool includeHistory = false,
  }) async {
    try {
      final Map<String, dynamic> data = filters ?? {};
      if (language != null) {
        data['language'] = language;
      }
      data['include_history'] = includeHistory;

      final response = await _apiClient.dio.post(
        ApiConfig.workoutPlansGenerate,
        data: data,
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
        queryParameters: {'language': 'it'},
      );

      if (response.statusCode == 200 && response.data != null) {
        // Backend returns the plan directly
        if (response.data is Map<String, dynamic>) {
          debugPrint(
            'DEBUG: Fetched Plan JSON: ${response.data}',
          ); // DEBUG PRINT
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
    String language = 'it',
  }) async {
    try {
      // Fetch latest body measurements for personalization
      Map<String, dynamic>? bodyMeasurements;
      try {
        final measurementsResponse = await _apiClient.dio.get(
          '/progress/measurements',
        );
        if (measurementsResponse.statusCode == 200 &&
            measurementsResponse.data['success'] == true &&
            measurementsResponse.data['latest'] != null) {
          bodyMeasurements =
              measurementsResponse.data['latest'] as Map<String, dynamic>;
          debugPrint('DEBUG: Found body measurements for AI personalization');
        }
      } catch (e) {
        debugPrint('DEBUG: No body measurements found, continuing without: $e');
      }

      // Generate plan using OpenAI with body measurements
      final aiResponse = await _openAIService.generateWorkoutPlan(
        user: user,
        profile: profile,
        bodyMeasurements: bodyMeasurements,
        language: language,
      );

      // Convert OpenAI response to WorkoutPlan model
      final workoutPlanData = aiResponse['workoutPlan'];

      // Create WorkoutPlan from AI response
      final plan = _convertAIResponseToWorkoutPlan(workoutPlanData, user.id);

      return {
        'success': true,
        'plan': plan,
        'aiGenerated': true,
        'usedMeasurements': bodyMeasurements != null,
      };
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
        id: '${DateTime.now().millisecondsSinceEpoch}_${day['dayName']}',
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
