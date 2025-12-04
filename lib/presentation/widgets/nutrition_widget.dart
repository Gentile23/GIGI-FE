import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/nutrition_model.dart';
import '../../data/services/nutrition_service.dart';
import '../../data/services/api_client.dart';
import '../screens/nutrition/nutrition_dashboard_screen.dart';
import 'modern_widgets.dart';

class NutritionWidget extends StatefulWidget {
  const NutritionWidget({super.key});

  @override
  State<NutritionWidget> createState() => _NutritionWidgetState();
}

class _NutritionWidgetState extends State<NutritionWidget> {
  final NutritionService _nutritionService = NutritionService(ApiClient());
  DailyNutritionLog? _dailyLog;
  NutritionGoal? _goal;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final summary = await _nutritionService.getDailySummary();
      final goal = await _nutritionService.getGoals();

      if (mounted) {
        setState(() {
          if (summary != null) {
            _dailyLog = summary['summary'] as DailyNutritionLog?;
          }
          _goal = goal;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _dailyLog == null || _goal == null) {
      return const SizedBox.shrink();
    }

    final caloriesProgress = _dailyLog!.totalCalories / _goal!.dailyCalories;
    final remaining = _goal!.dailyCalories - _dailyLog!.totalCalories;

    return ModernCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NutritionDashboardScreen(),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withValues(alpha: 0.3),
                  Colors.blue.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant_menu,
              color: Colors.green,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nutrition Today',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_dailyLog!.totalCalories} / ${_goal!.dailyCalories} kcal',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: caloriesProgress > 1.0 ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  remaining > 0
                      ? '$remaining kcal remaining'
                      : 'Over by ${-remaining} kcal',
                  style: TextStyle(
                    fontSize: 12,
                    color: remaining > 0 ? Colors.white70 : Colors.red.shade300,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white30),
        ],
      ),
    );
  }
}
