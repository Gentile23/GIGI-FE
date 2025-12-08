import 'package:dio/dio.dart';
import 'api_client.dart';
import '../../core/constants/api_config.dart';
import '../models/user_model.dart';

class UserService {
  final ApiClient _apiClient;

  UserService(this._apiClient);

  Future<Map<String, dynamic>> getUser() async {
    try {
      final response = await _apiClient.dio.get(ApiConfig.user);

      if (response.statusCode == 200) {
        return {'success': true, 'user': UserModel.fromJson(response.data)};
      }

      return {'success': false, 'message': 'Failed to fetch user'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to fetch user',
      };
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? gender,
    int? age,
    double? height,
    double? weight,
    String? bodyShape,
    String? goal,
    List<String>? goals,
    String? level,
    int? weeklyFrequency,
    String? location,
    List<String>? equipment,
    List<String>? limitations,
    List<Map<String, dynamic>>? detailedInjuries,
    String? trainingSplit,
    int? sessionDuration,
    String? cardioPreference,
    String? mobilityPreference,
    String? workoutType,
    List<String>? specificMachines,
    // Professional Trainer Fields
    String? trainingHistory,
    List<String>? preferredDays,
    String? timePreference,
    int? sleepHours,
    String? recoveryCapacity,
    String? nutritionApproach,
    String? bodyFatPercentage,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (gender != null) data['gender'] = gender;
      if (age != null) data['age'] = age;
      if (height != null) data['height'] = height;
      if (weight != null) data['weight'] = weight;
      if (bodyShape != null) data['body_shape'] = bodyShape;
      if (goal != null) data['goal'] = goal;
      if (goals != null) data['goals'] = goals;
      if (level != null) data['level'] = level;
      if (weeklyFrequency != null) data['weekly_frequency'] = weeklyFrequency;
      if (location != null) data['location'] = location;
      if (equipment != null) data['equipment'] = equipment;
      if (limitations != null) data['limitations'] = limitations;
      if (detailedInjuries != null) {
        data['detailed_injuries'] = detailedInjuries;
      }
      // New preference fields
      if (trainingSplit != null) data['training_split'] = trainingSplit;
      if (sessionDuration != null) data['session_duration'] = sessionDuration;
      if (cardioPreference != null) {
        data['cardio_preference'] = cardioPreference;
      }
      if (mobilityPreference != null) {
        data['mobility_preference'] = mobilityPreference;
      }
      if (workoutType != null) data['workout_type'] = workoutType;
      if (specificMachines != null) {
        data['specific_machines'] = specificMachines;
      }

      // Professional Trainer Fields
      if (trainingHistory != null) data['training_history'] = trainingHistory;
      if (preferredDays != null) data['preferred_days'] = preferredDays;
      if (timePreference != null) data['time_preference'] = timePreference;
      if (sleepHours != null) data['sleep_hours'] = sleepHours;
      if (recoveryCapacity != null) {
        data['recovery_capacity'] = recoveryCapacity;
      }
      if (nutritionApproach != null) {
        data['nutrition_approach'] = nutritionApproach;
      }
      if (bodyFatPercentage != null) {
        data['body_fat_percentage'] = bodyFatPercentage;
      }

      final response = await _apiClient.dio.post(
        ApiConfig.userProfile,
        data: data,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'user': UserModel.fromJson(response.data)};
      }

      return {'success': false, 'message': 'Failed to update profile'};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data['message'] ?? 'Failed to update profile',
      };
    }
  }
}
