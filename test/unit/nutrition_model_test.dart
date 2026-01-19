// Unit tests for Nutrition model and calculations
import 'package:flutter_test/flutter_test.dart';

// Mock NutritionGoal class
class NutritionGoal {
  final int dailyCalories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final String goal; // lose_weight, maintain, gain_muscle
  final String dietType; // standard, low_carb, keto, vegetarian, vegan

  NutritionGoal({
    required this.dailyCalories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    this.goal = 'maintain',
    this.dietType = 'standard',
  });

  int get totalMacroCalories {
    // protein: 4 cal/g, carbs: 4 cal/g, fat: 9 cal/g
    return (proteinGrams * 4) + (carbsGrams * 4) + (fatGrams * 9);
  }

  double get proteinPercentage => (proteinGrams * 4) / dailyCalories * 100;
  double get carbsPercentage => (carbsGrams * 4) / dailyCalories * 100;
  double get fatPercentage => (fatGrams * 9) / dailyCalories * 100;

  bool get isMacroBalanced {
    final total = proteinPercentage + carbsPercentage + fatPercentage;
    return total >= 95 && total <= 105; // Allow 5% tolerance
  }

  factory NutritionGoal.calculate({
    required double weight,
    required double height,
    required int age,
    required String gender,
    required String activityLevel,
    required String goal,
  }) {
    // Harris-Benedict BMR calculation
    double bmr;
    if (gender == 'male') {
      bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }

    // Activity multiplier
    double multiplier;
    switch (activityLevel) {
      case 'sedentary':
        multiplier = 1.2;
        break;
      case 'light':
        multiplier = 1.375;
        break;
      case 'moderate':
        multiplier = 1.55;
        break;
      case 'active':
        multiplier = 1.725;
        break;
      case 'very_active':
        multiplier = 1.9;
        break;
      default:
        multiplier = 1.55;
    }

    double tdee = bmr * multiplier;

    // Adjust for goal
    int dailyCalories;
    switch (goal) {
      case 'lose_weight':
        dailyCalories = (tdee * 0.8).round(); // 20% deficit
        break;
      case 'gain_muscle':
        dailyCalories = (tdee * 1.1).round(); // 10% surplus
        break;
      default:
        dailyCalories = tdee.round();
    }

    // Standard macro split: 30% protein, 40% carbs, 30% fat
    int proteinGrams = ((dailyCalories * 0.30) / 4).round();
    int carbsGrams = ((dailyCalories * 0.40) / 4).round();
    int fatGrams = ((dailyCalories * 0.30) / 9).round();

    return NutritionGoal(
      dailyCalories: dailyCalories,
      proteinGrams: proteinGrams,
      carbsGrams: carbsGrams,
      fatGrams: fatGrams,
      goal: goal,
    );
  }
}

// Mock Meal class
class Meal {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final DateTime loggedAt;
  final String? photoUrl;

  Meal({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.loggedAt,
    this.photoUrl,
  });

  int get calculatedCalories {
    return (protein * 4) + (carbs * 4) + (fat * 9);
  }
}

// Mock DailyNutrition class
class DailyNutrition {
  final DateTime date;
  final List<Meal> meals;
  final int waterMl;
  final NutritionGoal goal;

  DailyNutrition({
    required this.date,
    required this.meals,
    required this.waterMl,
    required this.goal,
  });

  int get totalCalories => meals.fold(0, (sum, m) => sum + m.calories);
  int get totalProtein => meals.fold(0, (sum, m) => sum + m.protein);
  int get totalCarbs => meals.fold(0, (sum, m) => sum + m.carbs);
  int get totalFat => meals.fold(0, (sum, m) => sum + m.fat);

  int get caloriesRemaining => goal.dailyCalories - totalCalories;
  int get proteinRemaining => goal.proteinGrams - totalProtein;
  int get carbsRemaining => goal.carbsGrams - totalCarbs;
  int get fatRemaining => goal.fatGrams - totalFat;

  double get caloriesProgress => totalCalories / goal.dailyCalories;
  double get proteinProgress => totalProtein / goal.proteinGrams;
  double get carbsProgress => totalCarbs / goal.carbsGrams;
  double get fatProgress => totalFat / goal.fatGrams;

  int get waterGlasses => (waterMl / 250).floor();
  double get waterProgress => waterMl / 2000; // 2L goal

  bool get isGoalMet => caloriesProgress >= 0.9 && proteinProgress >= 0.8;
}

void main() {
  group('NutritionGoal Model', () {
    test('NutritionGoal creation', () {
      final goal = NutritionGoal(
        dailyCalories: 2000,
        proteinGrams: 150,
        carbsGrams: 200,
        fatGrams: 67,
      );

      expect(goal.dailyCalories, 2000);
      expect(goal.proteinGrams, 150);
      expect(goal.carbsGrams, 200);
      expect(goal.fatGrams, 67);
    });

    test('Total macro calories calculation', () {
      final goal = NutritionGoal(
        dailyCalories: 2000,
        proteinGrams: 150, // 600 cal
        carbsGrams: 200, // 800 cal
        fatGrams: 67, // 603 cal
      );

      // 150*4 + 200*4 + 67*9 = 600 + 800 + 603 = 2003
      expect(goal.totalMacroCalories, 2003);
    });

    test('Macro percentages calculation', () {
      final goal = NutritionGoal(
        dailyCalories: 2000,
        proteinGrams: 150,
        carbsGrams: 200,
        fatGrams: 67,
      );

      expect(goal.proteinPercentage, closeTo(30, 1));
      expect(goal.carbsPercentage, closeTo(40, 1));
      expect(goal.fatPercentage, closeTo(30, 2));
    });

    test('Macro balance check', () {
      final balancedGoal = NutritionGoal(
        dailyCalories: 2000,
        proteinGrams: 150,
        carbsGrams: 200,
        fatGrams: 67,
      );

      expect(balancedGoal.isMacroBalanced, true);
    });
  });

  group('NutritionGoal Calculation', () {
    test('Calculate goal for male weight loss', () {
      final goal = NutritionGoal.calculate(
        weight: 80,
        height: 180,
        age: 30,
        gender: 'male',
        activityLevel: 'moderate',
        goal: 'lose_weight',
      );

      // BMR ~1835, TDEE ~2844, with 20% deficit ~2275
      expect(goal.dailyCalories, greaterThan(2000));
      expect(goal.dailyCalories, lessThan(2500));
      expect(goal.goal, 'lose_weight');
    });

    test('Calculate goal for female muscle gain', () {
      final goal = NutritionGoal.calculate(
        weight: 60,
        height: 165,
        age: 25,
        gender: 'female',
        activityLevel: 'active',
        goal: 'gain_muscle',
      );

      expect(goal.dailyCalories, greaterThan(2200));
      expect(goal.goal, 'gain_muscle');
    });

    test('Activity level affects calories', () {
      final sedentary = NutritionGoal.calculate(
        weight: 70,
        height: 175,
        age: 30,
        gender: 'male',
        activityLevel: 'sedentary',
        goal: 'maintain',
      );

      final veryActive = NutritionGoal.calculate(
        weight: 70,
        height: 175,
        age: 30,
        gender: 'male',
        activityLevel: 'very_active',
        goal: 'maintain',
      );

      expect(veryActive.dailyCalories, greaterThan(sedentary.dailyCalories));
    });
  });

  group('Meal Model', () {
    test('Meal creation', () {
      final meal = Meal(
        name: 'Chicken Salad',
        calories: 450,
        protein: 40,
        carbs: 30,
        fat: 15,
        loggedAt: DateTime.now(),
      );

      expect(meal.name, 'Chicken Salad');
      expect(meal.calories, 450);
    });

    test('Calculated calories from macros', () {
      final meal = Meal(
        name: 'Test Meal',
        calories: 500,
        protein: 30, // 120 cal
        carbs: 50, // 200 cal
        fat: 20, // 180 cal
        loggedAt: DateTime.now(),
      );

      // 30*4 + 50*4 + 20*9 = 120 + 200 + 180 = 500
      expect(meal.calculatedCalories, 500);
    });
  });

  group('DailyNutrition Model', () {
    late NutritionGoal goal;
    late DailyNutrition dailyNutrition;

    setUp(() {
      goal = NutritionGoal(
        dailyCalories: 2000,
        proteinGrams: 150,
        carbsGrams: 200,
        fatGrams: 67,
      );

      dailyNutrition = DailyNutrition(
        date: DateTime.now(),
        meals: [
          Meal(
            name: 'Breakfast',
            calories: 500,
            protein: 30,
            carbs: 60,
            fat: 15,
            loggedAt: DateTime.now(),
          ),
          Meal(
            name: 'Lunch',
            calories: 700,
            protein: 50,
            carbs: 70,
            fat: 25,
            loggedAt: DateTime.now(),
          ),
          Meal(
            name: 'Dinner',
            calories: 600,
            protein: 45,
            carbs: 50,
            fat: 20,
            loggedAt: DateTime.now(),
          ),
        ],
        waterMl: 1500,
        goal: goal,
      );
    });

    test('Total calculations', () {
      expect(dailyNutrition.totalCalories, 1800);
      expect(dailyNutrition.totalProtein, 125);
      expect(dailyNutrition.totalCarbs, 180);
      expect(dailyNutrition.totalFat, 60);
    });

    test('Remaining calculations', () {
      expect(dailyNutrition.caloriesRemaining, 200);
      expect(dailyNutrition.proteinRemaining, 25);
      expect(dailyNutrition.carbsRemaining, 20);
      expect(dailyNutrition.fatRemaining, 7);
    });

    test('Progress calculations', () {
      expect(dailyNutrition.caloriesProgress, closeTo(0.9, 0.01));
      expect(dailyNutrition.proteinProgress, closeTo(0.83, 0.01));
    });

    test('Water tracking', () {
      expect(dailyNutrition.waterGlasses, 6);
      expect(dailyNutrition.waterProgress, 0.75);
    });

    test('Goal met check', () {
      expect(dailyNutrition.isGoalMet, true);
    });

    test('Empty day has zero totals', () {
      final emptyDay = DailyNutrition(
        date: DateTime.now(),
        meals: [],
        waterMl: 0,
        goal: goal,
      );

      expect(emptyDay.totalCalories, 0);
      expect(emptyDay.caloriesRemaining, 2000);
      expect(emptyDay.isGoalMet, false);
    });
  });
}
