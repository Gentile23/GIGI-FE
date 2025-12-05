import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/nutrition_model.dart';
import '../../data/services/nutrition_service.dart';
import '../../data/services/api_client.dart';
import '../../core/theme/clean_theme.dart';
import '../screens/nutrition/nutrition_dashboard_screen.dart';
import 'clean_widgets.dart';

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

    return CleanCard(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      child: InkWell(
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
                color: CleanTheme.accentGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                color: CleanTheme.accentGreen,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nutrizione Oggi',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CleanTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_dailyLog!.totalCalories} / ${_goal!.dailyCalories} kcal',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: caloriesProgress > 1.0
                          ? CleanTheme.accentRed
                          : CleanTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    remaining > 0
                        ? '$remaining kcal rimanenti'
                        : 'Eccesso di ${-remaining} kcal',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: remaining > 0
                          ? CleanTheme.textTertiary
                          : CleanTheme.accentRed,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: CleanTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
