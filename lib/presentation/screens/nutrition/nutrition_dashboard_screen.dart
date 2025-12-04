import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/nutrition_model.dart';
import '../../../data/services/nutrition_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/modern_theme.dart';
import '../../widgets/modern_widgets.dart';
import 'meal_logging_screen.dart';

class NutritionDashboardScreen extends StatefulWidget {
  const NutritionDashboardScreen({super.key});

  @override
  State<NutritionDashboardScreen> createState() =>
      _NutritionDashboardScreenState();
}

class _NutritionDashboardScreenState extends State<NutritionDashboardScreen> {
  late final NutritionService _nutritionService;
  bool _isLoading = true;
  DailyNutritionLog? _dailyLog;
  List<Meal> _meals = [];
  NutritionGoal? _goal;

  @override
  void initState() {
    super.initState();
    _nutritionService = NutritionService(ApiClient());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final summary = await _nutritionService.getDailySummary();
      final goal = await _nutritionService.getGoals();

      if (mounted) {
        setState(() {
          if (summary != null) {
            _dailyLog = summary['summary'] as DailyNutritionLog?;
            _meals = (summary['meals'] as List<Meal>?) ?? [];
          }
          _goal = goal;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading nutrition data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Nutrition Coach',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ModernTheme.cardColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              // Date picker TODO
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCaloriesCard(),
                    const SizedBox(height: 16),
                    _buildMacrosCard(),
                    const SizedBox(height: 24),
                    _buildMealsSection(),
                    const SizedBox(height: 24),
                    _buildWaterTracker(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MealLoggingScreen()),
          );
          if (result == true) {
            _loadData();
          }
        },
        backgroundColor: ModernTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Log Meal'),
      ),
    );
  }

  Widget _buildCaloriesCard() {
    if (_dailyLog == null || _goal == null) {
      return const ModernCard(child: Text('Set your goals to start tracking'));
    }

    final remaining = _goal!.dailyCalories - _dailyLog!.totalCalories;
    final progress = _dailyLog!.totalCalories / _goal!.dailyCalories;

    return ModernCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calories',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Goal: ${_goal!.dailyCalories}',
                    style: TextStyle(color: Colors.white60),
                  ),
                ],
              ),
              Text(
                '${remaining > 0 ? remaining : 0}',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: remaining < 0 ? Colors.red : ModernTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'remaining',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(
                progress > 1.0 ? Colors.red : ModernTheme.primaryColor,
              ),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_dailyLog!.totalCalories} eaten'),
              Text('${(progress * 100).toInt()}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosCard() {
    if (_dailyLog == null || _goal == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _buildMacroItem(
            'Protein',
            _dailyLog!.totalProtein,
            _goal!.proteinGrams.toDouble(),
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMacroItem(
            'Carbs',
            _dailyLog!.totalCarbs,
            _goal!.carbsGrams.toDouble(),
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMacroItem(
            'Fat',
            _dailyLog!.totalFat,
            _goal!.fatGrams.toDouble(),
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroItem(
    String label,
    double current,
    double target,
    Color color,
  ) {
    final progress = target > 0 ? current / target : 0.0;

    return ModernCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '${current.toInt()}/${target.toInt()}g',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Meals',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_meals.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('No meals logged yet'),
            ),
          )
        else
          ..._meals.map((meal) => _buildMealCard(meal)),
      ],
    );
  }

  Widget _buildMealCard(Meal meal) {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: meal.mealTypeColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(meal.mealTypeIcon, color: meal.mealTypeColor),
        ),
        title: Text(
          meal.mealTypeLabel,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${meal.totalCalories} kcal'),
        children: meal.foodItems.map((food) {
          return ListTile(
            dense: true,
            title: Text(food.foodName),
            subtitle: Text('${food.quantity} ${food.unit}'),
            trailing: Text('${food.calories} kcal'),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWaterTracker() {
    return ModernCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Water Intake',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_dailyLog?.waterMl ?? 0} ml',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              // Add water dialog
            },
          ),
        ],
      ),
    );
  }
}
