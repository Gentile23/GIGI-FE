import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'api_client.dart';

class NutritionCoachService {
  final ApiClient _client;

  NutritionCoachService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Upload Diet PDF
  Future<Map<String, dynamic>> uploadDietPdf(PlatformFile file) async {
    try {
      // Create FormData
      String fileName = file.name;
      MultipartFile multipartFile;

      if (file.bytes != null) {
        // Web or in-memory
        multipartFile = MultipartFile.fromBytes(
          file.bytes!,
          filename: fileName,
        );
      } else {
        // Mobile/Desktop file path
        multipartFile = await MultipartFile.fromFile(
          file.path!,
          filename: fileName,
        );
      }

      FormData formData = FormData.fromMap({'pdf_file': multipartFile});

      return await _client.postMultipart(
        '/nutrition/coach/upload-diet',
        formData: formData,
      );
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get Active Diet Plan
  Future<Map<String, dynamic>> getActivePlan() async {
    return await _client.get('/nutrition/coach/plan');
  }

  /// Find Substitute
  Future<List<dynamic>> findSubstitute(
    String foodName,
    double quantity,
    String unit,
  ) async {
    final response = await _client.post(
      '/nutrition/coach/substitute',
      body: {'food_name': foodName, 'quantity': quantity, 'unit': unit},
    );

    if (response['success'] == true) {
      return response['substitutes'] ?? [];
    }
    throw Exception(response['message'] ?? 'Failed to find substitutes');
  }

  /// Apply Substitution
  Future<bool> applySubstitution({
    required int planId,
    required int dayIndex,
    required int mealIndex,
    required int foodIndex,
    required Map<String, dynamic> newFood,
  }) async {
    final response = await _client.post(
      '/nutrition/coach/substitute/apply',
      body: {
        'plan_id': planId,
        'day_index': dayIndex,
        'meal_index': mealIndex,
        'food_index': foodIndex,
        'new_food': {
          'name':
              newFood['food_name'] ?? newFood['name'], // Handle both formats
          'quantity': newFood['quantity'],
          'unit': newFood['unit'],
          'calories': newFood['calories'],
        },
      },
    );

    return response['success'] == true;
  }

  /// Generate Shopping List
  Future<List<dynamic>> generateShoppingList(int days) async {
    final response = await _client.get(
      '/nutrition/coach/shopping-list',
      queryParams: {'days': days.toString()},
    );

    if (response['success'] == true) {
      return response['shopping_list'] ?? [];
    }
    throw Exception(response['message'] ?? 'Failed to generate shopping list');
  }

  /// Regenerate Meal
  Future<bool> regenerateMeal({
    required int planId,
    required int dayIndex,
    required int mealIndex,
  }) async {
    final response = await _client.post(
      '/nutrition/coach/regenerate-meal',
      body: {'plan_id': planId, 'day_index': dayIndex, 'meal_index': mealIndex},
    );
    return response['success'] == true;
  }

  /// Add Extra Meal
  Future<bool> addExtraMeal({
    required int planId,
    required int dayIndex,
    required String foodName,
    required double quantity,
    required String unit,
  }) async {
    final response = await _client.post(
      '/nutrition/coach/extra-meal',
      body: {
        'plan_id': planId,
        'day_index': dayIndex,
        'food_name': foodName,
        'quantity': quantity,
        'unit': unit,
      },
    );
    return response['success'] == true;
  }
}
