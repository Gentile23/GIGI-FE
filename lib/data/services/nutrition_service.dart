import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/nutrition_model.dart';
import 'api_client.dart';

class NutritionService {
  final ApiClient _apiClient;

  NutritionService(this._apiClient);

  /// Quick log from photo
  Future<Map<String, dynamic>?> quickLog({
    required XFile imageFile,
    required String mealType,
  }) async {
    try {
      MultipartFile photoPart;

      if (kIsWeb) {
        // On Web, use bytes
        photoPart = MultipartFile.fromBytes(
          await imageFile.readAsBytes(),
          filename: 'meal_photo.jpg',
        );
      } else {
        // On Mobile/Desktop, use file path
        photoPart = await MultipartFile.fromFile(
          imageFile.path,
          filename: 'meal_photo.jpg',
        );
      }

      final formData = FormData.fromMap({
        'photo': photoPart,
        'meal_type': mealType,
      });

      final response = await _apiClient.dio.post(
        '/nutrition/quick-log',
        data: formData,
      );

      return response.data;
    } catch (e) {
      debugPrint('Error quick logging: $e');
      return null;
    }
  }

  /// Get nutrition goals
  Future<NutritionGoal?> getGoals() async {
    try {
      final response = await _apiClient.dio.get('/nutrition/goals');
      if (response.data['goal'] != null) {
        return NutritionGoal.fromJson(response.data['goal']);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching nutrition goals: $e');
      return null;
    }
  }

  /// Set nutrition goals
  Future<NutritionGoal?> setGoals({
    required String goalType,
    required String activityLevel,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/nutrition/goals',
        data: {'goal_type': goalType, 'activity_level': activityLevel},
      );
      return NutritionGoal.fromJson(response.data['goal']);
    } catch (e) {
      debugPrint('Error setting nutrition goals: $e');
      return null;
    }
  }

  /// Log a meal
  Future<Meal?> logMeal({
    required String mealType,
    String? mealDate,
    String? mealTime,
    int? totalCalories,
    double? proteinGrams,
    double? carbsGrams,
    double? fatGrams,
    double? fiberGrams,
    String? photoUrl,
    String? notes,
    List<Map<String, dynamic>>? foodItems,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/nutrition/meals',
        data: {
          'meal_type': mealType,
          if (mealDate != null) 'meal_date': mealDate,
          if (mealTime != null) 'meal_time': mealTime,
          if (totalCalories != null) 'total_calories': totalCalories,
          if (proteinGrams != null) 'protein_grams': proteinGrams,
          if (carbsGrams != null) 'carbs_grams': carbsGrams,
          if (fatGrams != null) 'fat_grams': fatGrams,
          if (fiberGrams != null) 'fiber_grams': fiberGrams,
          if (photoUrl != null) 'photo_url': photoUrl,
          if (notes != null) 'notes': notes,
          if (foodItems != null) 'food_items': foodItems,
        },
      );
      return Meal.fromJson(response.data['meal']);
    } catch (e) {
      debugPrint('Error logging meal: $e');
      return null;
    }
  }

  /// Get meals for a date
  Future<List<Meal>?> getMeals({String? date}) async {
    try {
      final response = await _apiClient.dio.get(
        '/nutrition/meals',
        queryParameters: {if (date != null) 'date': date},
      );
      return (response.data['meals'] as List)
          .map((json) => Meal.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching meals: $e');
      return null;
    }
  }

  /// Get meal details
  Future<Meal?> getMeal(int mealId) async {
    try {
      final response = await _apiClient.dio.get('/nutrition/meals/$mealId');
      return Meal.fromJson(response.data['meal']);
    } catch (e) {
      debugPrint('Error fetching meal: $e');
      return null;
    }
  }

  /// Update meal
  Future<bool> updateMeal({
    required int mealId,
    String? mealType,
    String? notes,
    int? totalCalories,
    double? proteinGrams,
    double? carbsGrams,
    double? fatGrams,
    double? fiberGrams,
    List<Map<String, dynamic>>? foodItems,
  }) async {
    try {
      await _apiClient.dio.put(
        '/nutrition/meals/$mealId',
        data: {
          if (mealType != null) 'meal_type': mealType,
          if (notes != null) 'notes': notes,
          if (totalCalories != null) 'total_calories': totalCalories,
          if (proteinGrams != null) 'protein_grams': proteinGrams,
          if (carbsGrams != null) 'carbs_grams': carbsGrams,
          if (fatGrams != null) 'fat_grams': fatGrams,
          if (fiberGrams != null) 'fiber_grams': fiberGrams,
          if (foodItems != null) 'food_items': foodItems,
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error updating meal: $e');
      return false;
    }
  }

  /// Delete meal
  Future<bool> deleteMeal(int mealId) async {
    try {
      await _apiClient.dio.delete('/nutrition/meals/$mealId');
      return true;
    } catch (e) {
      debugPrint('Error deleting meal: $e');
      return false;
    }
  }

  /// Get daily summary
  Future<Map<String, dynamic>?> getDailySummary({String? date}) async {
    try {
      final response = await _apiClient.dio.get(
        '/nutrition/daily-summary',
        queryParameters: {if (date != null) 'date': date},
      );
      return {
        'date': response.data['summary']['date'],
        'summary': DailyNutritionLog.fromJson(
          response.data['summary']['summary'],
        ),
        'meals': (response.data['summary']['meals'] as List)
            .map((json) => Meal.fromJson(json))
            .toList(),
        'progress': response.data['summary']['progress'],
      };
    } catch (e) {
      debugPrint('Error fetching daily summary: $e');
      return null;
    }
  }

  /// Get weekly summary
  Future<Map<String, dynamic>?> getWeeklySummary() async {
    try {
      final response = await _apiClient.dio.get('/nutrition/weekly-summary');
      return response.data['summary'];
    } catch (e) {
      debugPrint('Error fetching weekly summary: $e');
      return null;
    }
  }

  /// Get insights
  Future<List<NutritionInsight>?> getInsights() async {
    try {
      final response = await _apiClient.dio.get('/nutrition/insights');
      return (response.data['insights'] as List)
          .map((json) => NutritionInsight.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching insights: $e');
      return null;
    }
  }

  /// Get recipes
  Future<List<Recipe>?> getRecipes({
    String? search,
    List<String>? tags,
    String? difficulty,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/nutrition/recipes',
        queryParameters: {
          if (search != null) 'search': search,
          if (tags != null) 'tags': tags,
          if (difficulty != null) 'difficulty': difficulty,
        },
      );
      return (response.data['recipes']['data'] as List)
          .map((json) => Recipe.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching recipes: $e');
      return null;
    }
  }

  /// Get recipe details
  Future<Recipe?> getRecipe(int recipeId) async {
    try {
      final response = await _apiClient.dio.get('/nutrition/recipes/$recipeId');
      return Recipe.fromJson(response.data['recipe']);
    } catch (e) {
      debugPrint('Error fetching recipe: $e');
      return null;
    }
  }

  /// Save recipe
  Future<bool> saveRecipe(int recipeId) async {
    try {
      await _apiClient.dio.post('/nutrition/recipes/$recipeId/save');
      return true;
    } catch (e) {
      debugPrint('Error saving recipe: $e');
      return false;
    }
  }

  /// Get saved recipes
  Future<List<Recipe>?> getSavedRecipes() async {
    try {
      final response = await _apiClient.dio.get('/nutrition/saved-recipes');
      return (response.data['recipes']['data'] as List)
          .map((json) => Recipe.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching saved recipes: $e');
      return null;
    }
  }

  /// Update water intake
  Future<bool> updateWater({required int waterMl, String? date}) async {
    try {
      await _apiClient.dio.post(
        '/nutrition/water',
        data: {'water_ml': waterMl, if (date != null) 'date': date},
      );
      return true;
    } catch (e) {
      debugPrint('Error updating water: $e');
      return false;
    }
  }

  /// Calculate TDEE based on user data (activity level is auto-calculated from workout history)
  Future<Map<String, dynamic>?> calculateTDEE({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String goalType,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/nutrition/tdee/calculate',
        data: {
          'weight_kg': weightKg,
          'height_cm': heightCm,
          'age': age,
          'gender': gender,
          'goal_type': goalType,
        },
      );
      return response.data;
    } catch (e) {
      debugPrint('Error calculating TDEE: $e');
      return null;
    }
  }

  /// Set comprehensive nutrition goals
  Future<bool> setComprehensiveGoals({
    required int dailyCalories,
    required int proteinGrams,
    required int carbsGrams,
    required int fatGrams,
    required String goalType,
    String? dietType,
    int? waterGoalMl,
  }) async {
    try {
      await _apiClient.dio.post(
        '/nutrition/goals/comprehensive',
        data: {
          'daily_calories': dailyCalories,
          'protein_grams': proteinGrams,
          'carbs_grams': carbsGrams,
          'fat_grams': fatGrams,
          'goal_type': goalType,
          if (dietType != null) 'diet_type': dietType,
          if (waterGoalMl != null) 'water_goal_ml': waterGoalMl,
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error setting comprehensive goals: $e');
      return false;
    }
  }

  /// Get smart meal suggestions based on remaining macros
  Future<Map<String, dynamic>?> getSmartSuggestions() async {
    try {
      final response = await _apiClient.dio.get('/nutrition/suggestions');
      return response.data;
    } catch (e) {
      debugPrint('Error getting smart suggestions: $e');
      return null;
    }
  }

  /// What to cook - AI recipe suggestions based on ingredients
  Future<Map<String, dynamic>?> whatToCook({
    required List<String> ingredients,
    int? maxTimeMinutes,
    String? dietType,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/nutrition/what-to-cook',
        data: {
          'ingredients': ingredients,
          if (maxTimeMinutes != null) 'max_time_minutes': maxTimeMinutes,
          if (dietType != null) 'diet_type': dietType,
        },
      );
      return response.data;
    } catch (e) {
      debugPrint('Error getting what to cook: $e');
      return null;
    }
  }

  /// Search foods database
  Future<List<Map<String, dynamic>>?> searchFoods(String query) async {
    try {
      final response = await _apiClient.dio.get(
        '/nutrition/foods/search',
        queryParameters: {'query': query},
      );
      return List<Map<String, dynamic>>.from(response.data['results'] ?? []);
    } catch (e) {
      debugPrint('Error searching foods: $e');
      return null;
    }
  }

  /// Get recent foods logged by user
  Future<List<Map<String, dynamic>>?> getRecentFoods() async {
    try {
      final response = await _apiClient.dio.get('/nutrition/foods/recent');
      return List<Map<String, dynamic>>.from(
        response.data['recent_foods'] ?? [],
      );
    } catch (e) {
      debugPrint('Error getting recent foods: $e');
      return null;
    }
  }
}
