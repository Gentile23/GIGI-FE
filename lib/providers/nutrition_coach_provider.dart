import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../data/services/nutrition_coach_service.dart';
import '../data/services/api_client.dart';

class NutritionCoachProvider extends ChangeNotifier {
  final NutritionCoachService _service;

  Map<String, dynamic>? _activePlan;
  List<dynamic> _shoppingList = [];
  bool _isLoading = false;
  String? _error;

  NutritionCoachProvider([ApiClient? client])
    : _service = NutritionCoachService(client: client);

  // Getters
  Map<String, dynamic>? get activePlan => _activePlan;
  List<dynamic> get shoppingList => _shoppingList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasActivePlan => _activePlan != null;

  /// Load the active diet plan from the backend
  Future<void> loadActivePlan() async {
    _setLoading(true);
    try {
      final response = await _service.getActivePlan();
      if (response['success'] == true) {
        _activePlan = response['plan'];
        _error = null;
      } else {
        // It's okay if no plan exists, just clear local state
        _activePlan = null;
      }
    } catch (e) {
      _error = e.toString();
      _activePlan = null;
    } finally {
      _setLoading(false);
    }
  }

  /// Upload a new diet PDF
  Future<bool> uploadDiet(PlatformFile file) async {
    _setLoading(true);
    try {
      final response = await _service.uploadDietPdf(file);
      if (response['success'] == true) {
        // Immediately set the new plan
        _activePlan = response['plan'];
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = response['message'];
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Regenerate a specific meal
  Future<bool> regenerateMeal({
    required int dayIndex,
    required int mealIndex,
  }) async {
    if (_activePlan == null) return false;

    _setLoading(true);
    try {
      final success = await _service.regenerateMeal(
        planId: _activePlan!['id'],
        dayIndex: dayIndex,
        mealIndex: mealIndex,
      );

      if (success) {
        // Reload to get the updated meal content
        await loadActivePlan();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Add an extra meal
  Future<bool> addExtraMeal({
    required int dayIndex,
    required String foodName,
    required double quantity,
    required String unit,
  }) async {
    if (_activePlan == null) return false;

    _setLoading(true);
    try {
      final success = await _service.addExtraMeal(
        planId: _activePlan!['id'],
        dayIndex: dayIndex,
        foodName: foodName,
        quantity: quantity,
        unit: unit,
      );

      if (success) {
        await loadActivePlan();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Find substitutes for a food
  Future<List<dynamic>> findSubstitutes(
    String foodName,
    double quantity,
    String unit,
  ) async {
    try {
      return await _service.findSubstitute(foodName, quantity, unit);
    } catch (e) {
      // Don't set global error for local utility call
      debugPrint('Error finding substitutes: $e');
      return [];
    }
  }

  /// Apply a substitution
  Future<bool> applySubstitution({
    required int dayIndex,
    required int mealIndex,
    required int foodIndex,
    required Map<String, dynamic> newFood,
  }) async {
    if (_activePlan == null) return false;

    _setLoading(true);
    try {
      final success = await _service.applySubstitution(
        planId: _activePlan!['id'],
        dayIndex: dayIndex,
        mealIndex: mealIndex,
        foodIndex: foodIndex,
        newFood: newFood,
      );

      if (success) {
        await loadActivePlan();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Generate Shopping List
  Future<void> generateShoppingList(int days) async {
    _setLoading(true);
    try {
      final list = await _service.generateShoppingList(days);
      _shoppingList = list;
    } catch (e) {
      _error = e.toString();
      _shoppingList = [];
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Update a food's quantity
  Future<bool> updateFoodQuantity({
    required int dayIndex,
    required int mealIndex,
    required int foodIndex,
    required double quantity,
  }) async {
    if (_activePlan == null) return false;

    _setLoading(true);
    try {
      final response = await _service.updateFoodQuantity(
        planId: _activePlan!['id'],
        dayIndex: dayIndex,
        mealIndex: mealIndex,
        foodIndex: foodIndex,
        quantity: quantity,
      );

      if (response['success'] == true) {
        // Update with the returned plan
        _activePlan = response['plan'];
        notifyListeners();
        return true;
      }
      _error = response['message'];
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
