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
    int? grams,
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
        if (grams != null) 'grams': grams,
      });

      final response = await _apiClient.postMultipart(
        '/nutrition/quick-log',
        formData: formData,
      );

      return response;
    } catch (e) {
      debugPrint('Error quick logging: $e');
      return null;
    }
  }

  /// Get nutrition goals
  Future<NutritionGoal?> getGoals() async {
    try {
      final response = await _apiClient.get('/nutrition/goals');
      if (response['goal'] != null) {
        return NutritionGoal.fromJson(response['goal']);
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
      final response = await _apiClient.post(
        '/nutrition/goals',
        body: {'goal_type': goalType, 'activity_level': activityLevel},
      );
      if (response['success'] == true && response['goal'] != null) {
        return NutritionGoal.fromJson(response['goal']);
      }
      return null;
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
      final response = await _apiClient.post(
        '/nutrition/meals',
        body: {
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
      if (response['success'] == true && response['meal'] != null) {
        return Meal.fromJson(response['meal']);
      }
      return null;
    } catch (e) {
      debugPrint('Error logging meal: $e');
      return null;
    }
  }

  /// Get meals for a date
  Future<List<Meal>?> getMeals({String? date}) async {
    try {
      final response = await _apiClient.get(
        '/nutrition/meals',
        queryParams: {if (date != null) 'date': date},
      );
      if (response['success'] == true && response['meals'] != null) {
        return (response['meals'] as List)
            .map((json) => Meal.fromJson(json))
            .toList();
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching meals: $e');
      return null;
    }
  }

  /// Get meal details
  Future<Meal?> getMeal(int mealId) async {
    try {
      final response = await _apiClient.get('/nutrition/meals/$mealId');
      if (response['success'] == true && response['meal'] != null) {
        return Meal.fromJson(response['meal']);
      }
      return null;
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
      final response = await _apiClient.put(
        '/nutrition/meals/$mealId',
        body: {
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
      return response['success'] == true;
    } catch (e) {
      debugPrint('Error updating meal: $e');
      return false;
    }
  }

  /// Delete meal
  Future<bool> deleteMeal(int mealId) async {
    try {
      final response = await _apiClient.delete('/nutrition/meals/$mealId');
      return response['success'] == true;
    } catch (e) {
      debugPrint('Error deleting meal: $e');
      return false;
    }
  }

  /// Get daily summary
  Future<Map<String, dynamic>?> getDailySummary({String? date}) async {
    try {
      final response = await _apiClient.get(
        '/nutrition/daily-summary',
        queryParams: {if (date != null) 'date': date},
      );
      if (response['success'] == true && response['summary'] != null) {
        final summary = response['summary'];
        return {
          'date': summary['date'],
          'summary': DailyNutritionLog.fromJson(summary['summary']),
          'meals': (summary['meals'] as List)
              .map((json) => Meal.fromJson(json))
              .toList(),
          'progress': summary['progress'],
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching daily summary: $e');
      return null;
    }
  }

  /// Get weekly summary
  Future<Map<String, dynamic>?> getWeeklySummary() async {
    try {
      final response = await _apiClient.get('/nutrition/weekly-summary');
      return response['success'] == true ? response['summary'] : null;
    } catch (e) {
      debugPrint('Error fetching weekly summary: $e');
      return null;
    }
  }

  /// Get insights
  Future<List<NutritionInsight>?> getInsights() async {
    try {
      final response = await _apiClient.get('/nutrition/insights');
      if (response['success'] == true && response['insights'] != null) {
        return (response['insights'] as List)
            .map((json) => NutritionInsight.fromJson(json))
            .toList();
      }
      return null;
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
      final queryParams = {
        if (search != null) 'search': search,
        if (difficulty != null) 'difficulty': difficulty,
      };
      // Note: ApiClient.get currently only supports Map<String, String> for queryParams.
      // If tags are needed as a list, we might need to adjust ApiClient or manual stringify here.
      final response = await _apiClient.get(
        '/nutrition/recipes',
        queryParams: queryParams,
      );
      if (response['success'] == true && response['recipes'] != null) {
        return (response['recipes']['data'] as List)
            .map((json) => Recipe.fromJson(json))
            .toList();
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching recipes: $e');
      return null;
    }
  }

  /// Get recipe details
  Future<Recipe?> getRecipe(int recipeId) async {
    try {
      final response = await _apiClient.get('/nutrition/recipes/$recipeId');
      if (response['success'] == true && response['recipe'] != null) {
        return Recipe.fromJson(response['recipe']);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching recipe: $e');
      return null;
    }
  }

  /// Save recipe
  Future<bool> saveRecipe(int recipeId) async {
    try {
      final response = await _apiClient.post(
        '/nutrition/recipes/$recipeId/save',
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('Error saving recipe: $e');
      return false;
    }
  }

  /// Get saved recipes
  Future<List<Recipe>?> getSavedRecipes() async {
    try {
      final response = await _apiClient.get('/nutrition/saved-recipes');
      if (response['success'] == true && response['recipes'] != null) {
        return (response['recipes']['data'] as List)
            .map((json) => Recipe.fromJson(json))
            .toList();
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching saved recipes: $e');
      return null;
    }
  }

  /// Update water intake
  Future<bool> updateWater({required int waterMl, String? date}) async {
    try {
      final response = await _apiClient.post(
        '/nutrition/water',
        body: {'water_ml': waterMl, if (date != null) 'date': date},
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('Error updating water: $e');
      return false;
    }
  }

  /// Calculate TDEE based on user data
  Future<Map<String, dynamic>?> calculateTDEE({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    required String goalType,
  }) async {
    try {
      final response = await _apiClient.post(
        '/nutrition/tdee/calculate',
        body: {
          'weight_kg': weightKg,
          'height_cm': heightCm,
          'age': age,
          'gender': gender,
          'goal_type': goalType,
        },
      );
      return response['success'] == true ? response : null;
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
      final response = await _apiClient.post(
        '/nutrition/goals/comprehensive',
        body: {
          'daily_calories': dailyCalories,
          'protein_grams': proteinGrams,
          'carbs_grams': carbsGrams,
          'fat_grams': fatGrams,
          'goal_type': goalType,
          if (dietType != null) 'diet_type': dietType,
          if (waterGoalMl != null) 'water_goal_ml': waterGoalMl,
        },
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('Error setting comprehensive goals: $e');
      return false;
    }
  }

  /// Get smart meal suggestions based on remaining macros
  Future<Map<String, dynamic>?> getSmartSuggestions() async {
    try {
      final response = await _apiClient.get('/nutrition/suggestions');
      return response['success'] == true ? response : null;
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
    String? mode,
  }) async {
    try {
      final response = await _apiClient.post(
        '/nutrition/what-to-cook',
        body: {
          'ingredients': ingredients,
          if (maxTimeMinutes != null) 'max_time_minutes': maxTimeMinutes,
          if (dietType != null) 'diet_type': dietType,
          if (mode != null) 'mode': mode,
        },
      );
      return response;
    } catch (e) {
      debugPrint('Error getting what to cook: $e');
      return null;
    }
  }

  /// Search foods database
  Future<List<Map<String, dynamic>>?> searchFoods(String query) async {
    try {
      final response = await _apiClient.get(
        '/nutrition/foods/search',
        queryParams: {'query': query},
      );
      if (response['success'] == true && response['results'] != null) {
        return List<Map<String, dynamic>>.from(response['results']);
      }
      return null;
    } catch (e) {
      debugPrint('Error searching foods: $e');
      return null;
    }
  }

  /// Get recent foods logged by user
  Future<List<Map<String, dynamic>>?> getRecentFoods() async {
    try {
      final response = await _apiClient.get('/nutrition/foods/recent');
      if (response['success'] == true && response['recent_foods'] != null) {
        return List<Map<String, dynamic>>.from(response['recent_foods']);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting recent foods: $e');
      return null;
    }
  }
}
