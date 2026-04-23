import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/utils/validation_utils.dart';
import 'api_client.dart';

class NutritionCoachService {
  final ApiClient _client;
  static const int _maxPdfSizeBytes = ValidationUtils.maxPdfUploadBytes;

  NutritionCoachService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Upload Diet PDF
  Future<Map<String, dynamic>> uploadDietPdf(PlatformFile file) async {
    try {
      final extension = (file.extension ?? '').toLowerCase();
      if (extension != 'pdf') {
        return {
          'success': false,
          'message': 'È consentito solo il formato PDF',
        };
      }
      if (file.size <= 0 || file.size > _maxPdfSizeBytes) {
        return {
          'success': false,
          'message': 'File non valido: dimensione massima 10MB',
        };
      }

      // Create FormData
      final fileName = ValidationUtils.sanitizeFileName(file.name);
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
    final safeFoodName = ValidationUtils.sanitizeFreeText(
      foodName,
      maxLength: 80,
    );
    final safeUnit = ValidationUtils.sanitizeFreeText(unit, maxLength: 20);
    if (safeFoodName.isEmpty || safeUnit.isEmpty) {
      throw Exception('Input non valido');
    }
    if (ValidationUtils.containsSuspiciousMarkup(safeFoodName) ||
        ValidationUtils.containsSuspiciousMarkup(safeUnit)) {
      throw Exception('Input contiene contenuto non consentito');
    }

    final response = await _client.post(
      '/nutrition/coach/substitute',
      body: {'food_name': safeFoodName, 'quantity': quantity, 'unit': safeUnit},
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
    int weekIndex = 0,
    bool isPermanent = false,
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
        'week_index': weekIndex,
        'is_permanent': isPermanent,
      },
    );

    return response['success'] == true;
  }

  /// Generate Shopping List
  Future<List<dynamic>> generateShoppingList({
    required int startDay,
    required int endDay,
  }) async {
    final response = await _client.get(
      '/nutrition/coach/shopping-list',
      queryParams: {
        'start_day': startDay.toString(),
        'end_day': endDay.toString(),
      },
    );

    if (response['success'] == true) {
      return response['shopping_list'] ?? [];
    }
    throw Exception(response['message'] ?? 'Failed to generate shopping list');
  }

  /// Regenerate Meal (Returns 3 alternatives)
  Future<List<dynamic>> regenerateMeal({
    required int planId,
    required int dayIndex,
    required int mealIndex,
    int weekIndex = 0,
  }) async {
    final response = await _client.post(
      '/nutrition/coach/regenerate-meal',
      body: {
        'plan_id': planId,
        'day_index': dayIndex,
        'meal_index': mealIndex,
        'week_index': weekIndex,
      },
    );
    if (response['success'] == true) {
      return response['alternatives'] ?? [];
    }
    throw Exception(response['message'] ?? 'Failed to generate alternatives');
  }

  /// Apply Regenerated Meal
  Future<bool> applyRegeneratedMeal({
    required int planId,
    required int dayIndex,
    required int mealIndex,
    required Map<String, dynamic> newMeal,
    int weekIndex = 0,
    bool isPermanent = false,
  }) async {
    final response = await _client.post(
      '/nutrition/coach/regenerate-meal/apply',
      body: {
        'plan_id': planId,
        'day_index': dayIndex,
        'meal_index': mealIndex,
        'new_meal': newMeal,
        'week_index': weekIndex,
        'is_permanent': isPermanent,
      },
    );

    return response['success'] == true;
  }

  /// Restore original plan
  Future<bool> restoreOriginalPlan({
    required int planId,
  }) async {
    final response = await _client.post(
      '/nutrition/coach/plan/restore',
      body: {
        'plan_id': planId,
      },
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
    int weekIndex = 0,
  }) async {
    final safeFoodName = ValidationUtils.sanitizeFreeText(
      foodName,
      maxLength: 80,
    );
    final safeUnit = ValidationUtils.sanitizeFreeText(unit, maxLength: 20);
    if (safeFoodName.isEmpty || safeUnit.isEmpty) {
      return false;
    }
    if (ValidationUtils.containsSuspiciousMarkup(safeFoodName) ||
        ValidationUtils.containsSuspiciousMarkup(safeUnit)) {
      return false;
    }

    final response = await _client.post(
      '/nutrition/coach/extra-meal',
      body: {
        'plan_id': planId,
        'day_index': dayIndex,
        'food_name': safeFoodName,
        'quantity': quantity,
        'unit': safeUnit,
        'week_index': weekIndex,
      },
    );
    return response['success'] == true;
  }

  /// Update Food Quantity
  Future<Map<String, dynamic>> updateFoodQuantity({
    required int planId,
    required int dayIndex,
    required int mealIndex,
    required int foodIndex,
    required double quantity,
    int weekIndex = 0,
  }) async {
    final response = await _client.post(
      '/nutrition/coach/update-quantity',
      body: {
        'plan_id': planId,
        'day_index': dayIndex,
        'meal_index': mealIndex,
        'food_index': foodIndex,
        'quantity': quantity,
        'week_index': weekIndex,
      },
    );
    return response;
  }

  /// Calculate Food Equivalence (AI-powered)
  Future<Map<String, dynamic>> calculateEquivalence({
    required Map<String, dynamic> targetFood,
    required String userFoodName,
    String mode = 'kcal',
  }) async {
    final safeTargetName = ValidationUtils.sanitizeFreeText(
      '${targetFood['name'] ?? ''}',
      maxLength: 80,
    );
    final safeFoodName = ValidationUtils.sanitizeFreeText(
      userFoodName,
      maxLength: 80,
    );
    if (safeTargetName.isEmpty ||
        safeFoodName.isEmpty ||
        ValidationUtils.containsSuspiciousMarkup(safeTargetName) ||
        ValidationUtils.containsSuspiciousMarkup(safeFoodName)) {
      throw Exception('Nome alimento non valido');
    }

    final response = await _client.post(
      '/nutrition/coach/equivalence',
      body: {
        'target_food': {...targetFood, 'name': safeTargetName},
        'user_food_name': safeFoodName,
        'mode': mode,
      },
    );
    if (response['success'] == true) {
      return response['equivalence'] ?? {};
    }
    throw Exception(response['message'] ?? 'Errore nel calcolo equivalenza');
  }
}
