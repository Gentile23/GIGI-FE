import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/nutrition_model.dart';
import '../../../data/services/nutrition_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
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

  Future<void> _showDatePicker() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: CleanTheme.primaryColor,
              onPrimary: Colors.white,
              surface: CleanTheme.surfaceColor,
              onSurface: CleanTheme.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: CleanTheme.surfaceColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null && mounted) {
      // Load data for the selected date
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dati del ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
          ),
          backgroundColor: CleanTheme.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
      // In a real app, reload data for the selected date
      // await _loadDataForDate(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Nutrition Coach',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: _showDatePicker,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: CleanTheme.primaryColor),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: CleanTheme.primaryColor,
              backgroundColor: CleanTheme.surfaceColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
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
                    const SizedBox(height: 80), // Space for FAB
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
        backgroundColor: CleanTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: Text(
          'Aggiungi Pasto',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildCaloriesCard() {
    if (_dailyLog == null || _goal == null) {
      return CleanCard(
        child: Center(
          child: Text(
            'Imposta i tuoi obiettivi per iniziare a tracciare',
            style: GoogleFonts.inter(color: CleanTheme.textSecondary),
          ),
        ),
      );
    }

    final remaining = _goal!.dailyCalories - _dailyLog!.totalCalories;
    final progress = _dailyLog!.totalCalories / _goal!.dailyCalories;

    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calorie',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Obiettivo: ${_goal!.dailyCalories}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${remaining > 0 ? remaining : 0}',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: remaining < 0
                          ? CleanTheme.accentRed
                          : CleanTheme.primaryColor,
                    ),
                  ),
                  Text(
                    'rimanenti',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CleanTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: CleanTheme.borderSecondary,
              valueColor: AlwaysStoppedAnimation(
                progress > 1.0 ? CleanTheme.accentRed : CleanTheme.primaryColor,
              ),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_dailyLog!.totalCalories} assunte',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CleanTheme.textPrimary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textSecondary,
                ),
              ),
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
            'Proteine',
            _dailyLog!.totalProtein,
            _goal!.proteinGrams.toDouble(),
            CleanTheme.accentBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMacroItem(
            'Carboidrati',
            _dailyLog!.totalCarbs,
            _goal!.carbsGrams.toDouble(),
            CleanTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMacroItem(
            'Grassi',
            _dailyLog!.totalFat,
            _goal!.fatGrams.toDouble(),
            CleanTheme.accentOrange,
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

    return CleanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${current.toInt()}/${target.toInt()}g',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: color.withValues(alpha: 0.15),
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
        CleanSectionHeader(title: 'Pasti di Oggi'),
        const SizedBox(height: 16),
        if (_meals.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.restaurant_outlined,
                    size: 48,
                    color: CleanTheme.textTertiary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nessun pasto registrato',
                    style: GoogleFonts.inter(color: CleanTheme.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          ..._meals.map((meal) => _buildMealCard(meal)),
      ],
    );
  }

  Widget _buildMealCard(Meal meal) {
    return CleanCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: meal.mealTypeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(meal.mealTypeIcon, color: meal.mealTypeColor, size: 24),
          ),
          title: Text(
            meal.mealTypeLabel,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            '${meal.totalCalories} kcal',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CleanTheme.textSecondary,
            ),
          ),
          children: meal.foodItems.map((food) {
            return Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: CleanTheme.borderSecondary),
                ),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                title: Text(
                  food.foodName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${food.quantity} ${food.unit}',
                  style: GoogleFonts.inter(color: CleanTheme.textTertiary),
                ),
                trailing: Text(
                  '${food.calories} kcal',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWaterTracker() {
    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop, color: Colors.blue, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acqua',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                Text(
                  '${_dailyLog?.waterMl ?? 0} ml',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          CleanIconButton(
            icon: Icons.add,
            backgroundColor: Colors.blue,
            iconColor: Colors.white,
            hasBorder: false,
            onTap: () {
              // Add water dialog
            },
          ),
        ],
      ),
    );
  }
}
