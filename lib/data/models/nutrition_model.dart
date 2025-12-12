import 'package:flutter/material.dart';

class NutritionGoal {
  final int id;
  final int dailyCalories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final String goalType;
  final double? tdee;
  final String? activityLevel;

  NutritionGoal({
    required this.id,
    required this.dailyCalories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.goalType,
    this.tdee,
    this.activityLevel,
  });

  factory NutritionGoal.fromJson(Map<String, dynamic> json) {
    return NutritionGoal(
      id: json['id'],
      dailyCalories: json['daily_calories'],
      proteinGrams: json['protein_grams'],
      carbsGrams: json['carbs_grams'],
      fatGrams: json['fat_grams'],
      goalType: json['goal_type'],
      tdee: json['tdee']?.toDouble(),
      activityLevel: json['activity_level'],
    );
  }

  String get goalTypeLabel {
    switch (goalType) {
      case 'muscle_gain':
        return 'Muscle Gain';
      case 'fat_loss':
        return 'Fat Loss';
      case 'recomp':
        return 'Body Recomposition';
      default:
        return 'Maintenance';
    }
  }

  Color get goalTypeColor {
    switch (goalType) {
      case 'muscle_gain':
        return Colors.green;
      case 'fat_loss':
        return Colors.orange;
      case 'recomp':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
}

class Meal {
  final int id;
  final String mealType;
  final DateTime mealDate;
  final DateTime? mealTime;
  final int totalCalories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final double? fiberGrams;
  final String? photoUrl;
  final String? notes;
  final List<FoodItem> foodItems;

  Meal({
    required this.id,
    required this.mealType,
    required this.mealDate,
    this.mealTime,
    required this.totalCalories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    this.fiberGrams,
    this.photoUrl,
    this.notes,
    this.foodItems = const [],
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    final parsedDate = parseNutritionDate(json['meal_date']);
    DateTime? parsedTime;

    if (json['meal_time'] != null) {
      try {
        // Only take the YYYY-MM-DD part to combine with HH:MM:SS
        final dateStr = parsedDate.toIso8601String().substring(0, 10);
        parsedTime = DateTime.parse('$dateStr ${json['meal_time']}');
      } catch (_) {}
    }

    return Meal(
      id: json['id'],
      mealType: json['meal_type'],
      mealDate: parsedDate,
      mealTime: parsedTime,
      totalCalories: json['total_calories'],
      proteinGrams: (json['protein_grams'] ?? 0).toDouble(),
      carbsGrams: (json['carbs_grams'] ?? 0).toDouble(),
      fatGrams: (json['fat_grams'] ?? 0).toDouble(),
      fiberGrams: json['fiber_grams']?.toDouble(),
      photoUrl: json['photo_url'],
      notes: json['notes'],
      foodItems: json['food_items'] != null
          ? (json['food_items'] as List)
                .map((item) => FoodItem.fromJson(item))
                .toList()
          : [],
    );
  }

  String get mealTypeLabel {
    switch (mealType) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'snack':
        return 'Snack';
      case 'pre_workout':
        return 'Pre-Workout';
      case 'post_workout':
        return 'Post-Workout';
      default:
        return mealType;
    }
  }

  IconData get mealTypeIcon {
    switch (mealType) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cookie;
      case 'pre_workout':
        return Icons.fitness_center;
      case 'post_workout':
        return Icons.sports_gymnastics;
      default:
        return Icons.restaurant;
    }
  }

  Color get mealTypeColor {
    switch (mealType) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.blue;
      case 'snack':
        return Colors.purple;
      case 'pre_workout':
        return Colors.red;
      case 'post_workout':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
}

class FoodItem {
  final int id;
  final String foodName;
  final double quantity;
  final String unit;
  final int calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final double? fiberGrams;
  final String source;

  FoodItem({
    required this.id,
    required this.foodName,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    this.fiberGrams,
    required this.source,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'],
      foodName: json['food_name'],
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'],
      calories: json['calories'],
      proteinGrams: (json['protein_grams'] ?? 0).toDouble(),
      carbsGrams: (json['carbs_grams'] ?? 0).toDouble(),
      fatGrams: (json['fat_grams'] ?? 0).toDouble(),
      fiberGrams: json['fiber_grams']?.toDouble(),
      source: json['source'],
    );
  }
}

class DailyNutritionLog {
  final int id;
  final DateTime logDate;
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double? totalFiber;
  final int waterMl;
  final int? goalCalories;
  final double? goalProtein;
  final double? goalCarbs;
  final double? goalFat;

  DailyNutritionLog({
    required this.id,
    required this.logDate,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    this.totalFiber,
    required this.waterMl,
    this.goalCalories,
    this.goalProtein,
    this.goalCarbs,
    this.goalFat,
  });

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime _parseDate(dynamic value) {
    return parseNutritionDate(value);
  }

  factory DailyNutritionLog.fromJson(Map<String, dynamic> json) {
    return DailyNutritionLog(
      id: json['id'] ?? 0,
      logDate: _parseDate(json['log_date']),
      totalCalories: json['total_calories'] is String
          ? int.tryParse(json['total_calories']) ?? 0
          : (json['total_calories'] as num?)?.toInt() ?? 0,
      totalProtein: _parseDouble(json['total_protein']),
      totalCarbs: _parseDouble(json['total_carbs']),
      totalFat: _parseDouble(json['total_fat']),
      totalFiber: _parseDouble(json['total_fiber']),
      waterMl: json['water_ml'] is String
          ? int.tryParse(json['water_ml']) ?? 0
          : (json['water_ml'] as num?)?.toInt() ?? 0,
      goalCalories: json['goal_calories'] is String
          ? int.tryParse(json['goal_calories'])
          : (json['goal_calories'] as num?)?.toInt(),
      goalProtein: _parseDouble(json['goal_protein']),
      goalCarbs: _parseDouble(json['goal_carbs']),
      goalFat: _parseDouble(json['goal_fat']),
    );
  }

  double get calorieProgress {
    if (goalCalories == null || goalCalories == 0) return 0;
    return (totalCalories / goalCalories!) * 100;
  }

  double get proteinProgress {
    if (goalProtein == null || goalProtein == 0) return 0;
    return (totalProtein / goalProtein!) * 100;
  }

  double get carbsProgress {
    if (goalCarbs == null || goalCarbs == 0) return 0;
    return (totalCarbs / goalCarbs!) * 100;
  }

  double get fatProgress {
    if (goalFat == null || goalFat == 0) return 0;
    return (totalFat / goalFat!) * 100;
  }
}

/// Helper for robust date parsing
DateTime parseNutritionDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  if (value is String) {
    try {
      // First, clean up the string - take only the date part if malformed
      String dateStr = value.trim();
      // If it contains a space after the timezone, take only the first part
      if (dateStr.contains('Z ')) {
        dateStr = '${dateStr.split('Z ').first}Z';
      }
      // Try standard ISO parse
      return DateTime.parse(dateStr);
    } catch (_) {
      // Fallback: try to extract just the date YYYY-MM-DD
      try {
        if (value.length >= 10) {
          return DateTime.parse(value.substring(0, 10));
        }
      } catch (_) {}
      return DateTime.now();
    }
  }
  return DateTime.now();
}

class Recipe {
  final int id;
  final String name;
  final String? description;
  final List<dynamic> ingredients;
  final List<dynamic> instructions;
  final int servings;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final String difficulty;
  final int caloriesPerServing;
  final double proteinPerServing;
  final double carbsPerServing;
  final double fatPerServing;
  final List<String> tags;
  final bool isPublic;
  final String? imageUrl;

  Recipe({
    required this.id,
    required this.name,
    this.description,
    required this.ingredients,
    required this.instructions,
    required this.servings,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    required this.difficulty,
    required this.caloriesPerServing,
    required this.proteinPerServing,
    required this.carbsPerServing,
    required this.fatPerServing,
    required this.tags,
    required this.isPublic,
    this.imageUrl,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      ingredients: json['ingredients'] ?? [],
      instructions: json['instructions'] ?? [],
      servings: json['servings'],
      prepTimeMinutes: json['prep_time_minutes'],
      cookTimeMinutes: json['cook_time_minutes'],
      difficulty: json['difficulty'],
      caloriesPerServing: json['calories_per_serving'],
      proteinPerServing: (json['protein_per_serving'] ?? 0).toDouble(),
      carbsPerServing: (json['carbs_per_serving'] ?? 0).toDouble(),
      fatPerServing: (json['fat_per_serving'] ?? 0).toDouble(),
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      isPublic: json['is_public'] ?? false,
      imageUrl: json['image_url'],
    );
  }

  int get totalTimeMinutes => (prepTimeMinutes ?? 0) + (cookTimeMinutes ?? 0);

  Color get difficultyColor {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'hard':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
}

class NutritionInsight {
  final String type;
  final String category;
  final String message;

  NutritionInsight({
    required this.type,
    required this.category,
    required this.message,
  });

  factory NutritionInsight.fromJson(Map<String, dynamic> json) {
    return NutritionInsight(
      type: json['type'],
      category: json['category'],
      message: json['message'],
    );
  }

  IconData get icon {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'positive':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  Color get color {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'positive':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}
