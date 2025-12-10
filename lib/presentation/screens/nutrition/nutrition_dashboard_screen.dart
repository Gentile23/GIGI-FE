import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/nutrition_model.dart';
import '../../../data/services/nutrition_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
import 'meal_logging_screen.dart';
import 'goal_setup_wizard_screen.dart';
import 'what_to_cook_screen.dart';

class NutritionDashboardScreen extends StatefulWidget {
  const NutritionDashboardScreen({super.key});

  @override
  State<NutritionDashboardScreen> createState() =>
      _NutritionDashboardScreenState();
}

class _NutritionDashboardScreenState extends State<NutritionDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final NutritionService _nutritionService;
  late AnimationController _animationController;
  bool _isLoading = true;
  DailyNutritionLog? _dailyLog;
  List<Meal> _meals = [];
  NutritionGoal? _goal;
  Map<String, dynamic>? _suggestions;

  @override
  void initState() {
    super.initState();
    _nutritionService = NutritionService(ApiClient());
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final summary = await _nutritionService.getDailySummary();
      final goal = await _nutritionService.getGoals();
      final suggestions = await _nutritionService.getSmartSuggestions();

      if (mounted) {
        setState(() {
          if (summary != null) {
            _dailyLog = summary['summary'] as DailyNutritionLog?;
            _meals = (summary['meals'] as List<Meal>?) ?? [];
          }
          _goal = goal;
          _suggestions = suggestions;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: CleanTheme.primaryColor),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: CleanTheme.primaryColor,
              backgroundColor: CleanTheme.surfaceColor,
              child: CustomScrollView(
                slivers: [
                  // Premium App Bar
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: true,
                    pinned: true,
                    backgroundColor: CleanTheme.surfaceColor,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        'Nutrition Coach',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: CleanTheme.textPrimary,
                          fontSize: 20,
                        ),
                      ),
                      centerTitle: true,
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () => _navigateToGoalSetup(),
                      ),
                    ],
                  ),

                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // No goals? Show setup prompt
                        if (_goal == null)
                          _buildSetupPrompt()
                        else ...[
                          // Calorie Ring Card
                          _buildCalorieRingCard(),
                          const SizedBox(height: 20),

                          // Macro Progress Bars
                          _buildMacroProgressCard(),
                          const SizedBox(height: 20),

                          // Quick Actions
                          _buildQuickActions(),
                          const SizedBox(height: 24),

                          // Water Tracker
                          _buildWaterTracker(),
                          const SizedBox(height: 24),

                          // Smart Suggestions
                          if (_suggestions != null &&
                              _suggestions!['suggestions'] != null &&
                              (_suggestions!['suggestions'] as List).isNotEmpty)
                            _buildSmartSuggestions(),

                          const SizedBox(height: 24),

                          // Today's Meals
                          _buildMealsSection(),
                          const SizedBox(height: 100),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _goal != null
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MealLoggingScreen(),
                  ),
                );
                if (result == true) _loadData();
              },
              backgroundColor: CleanTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_a_photo),
              label: Text(
                'Registra Pasto',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }

  Widget _buildSetupPrompt() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CleanTheme.primaryColor.withValues(alpha: 0.1),
            CleanTheme.accentBlue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: CleanTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CleanTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu,
              size: 48,
              color: CleanTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '🎯 Imposta i tuoi obiettivi',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Calcola le calorie e i macro ideali in base ai tuoi obiettivi personali',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: CleanTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          CleanButton(
            text: 'Inizia Setup',
            icon: Icons.arrow_forward,
            onPressed: _navigateToGoalSetup,
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieRingCard() {
    final consumed = _dailyLog?.totalCalories ?? 0;
    final target = _goal?.dailyCalories ?? 2000;
    final remaining = target - consumed;
    final progress = (consumed / target).clamp(0.0, 1.2);

    return CleanCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              // Animated Circular Progress
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background circle
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CircularProgressIndicator(
                            value: 1,
                            strokeWidth: 12,
                            backgroundColor: CleanTheme.borderSecondary,
                            valueColor: const AlwaysStoppedAnimation(
                              Colors.transparent,
                            ),
                          ),
                        ),
                        // Progress circle
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CircularProgressIndicator(
                            value: (progress * _animationController.value)
                                .clamp(0.0, 1.0),
                            strokeWidth: 12,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation(
                              progress > 1.0
                                  ? CleanTheme.accentRed
                                  : CleanTheme.primaryColor,
                            ),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        // Center text
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${(consumed * _animationController.value).toInt()}',
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: CleanTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'kcal',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: CleanTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 24),
              // Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Obiettivo Giornaliero',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '$target kcal',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: remaining > 0
                            ? CleanTheme.accentGreen.withValues(alpha: 0.1)
                            : CleanTheme.accentRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        remaining > 0
                            ? '${remaining.abs()} kcal rimanenti'
                            : '${remaining.abs()} kcal in eccesso',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: remaining > 0
                              ? CleanTheme.accentGreen
                              : CleanTheme.accentRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroProgressCard() {
    return Row(
      children: [
        Expanded(
          child: _buildMacroItem(
            'Proteine',
            _dailyLog?.totalProtein ?? 0,
            (_goal?.proteinGrams ?? 150).toDouble(),
            CleanTheme.accentBlue,
            '🥩',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMacroItem(
            'Carboidrati',
            _dailyLog?.totalCarbs ?? 0,
            (_goal?.carbsGrams ?? 200).toDouble(),
            CleanTheme.accentOrange,
            '🍞',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMacroItem(
            'Grassi',
            _dailyLog?.totalFat ?? 0,
            (_goal?.fatGrams ?? 70).toDouble(),
            CleanTheme.accentPurple,
            '🥑',
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
    String emoji,
  ) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return CleanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CleanTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${current.toInt()}/${target.toInt()}g',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.camera_alt_rounded,
            label: 'Scatta Foto',
            color: CleanTheme.primaryColor,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MealLoggingScreen(),
                ),
              );
              if (result == true) _loadData();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.restaurant_menu,
            label: 'Cosa Cucino?',
            color: CleanTheme.accentOrange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WhatToCookScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterTracker() {
    final waterMl = _dailyLog?.waterMl ?? 0;
    final waterGoal = 2500;
    final progress = (waterMl / waterGoal).clamp(0.0, 1.0);
    final glasses = (waterMl / 250).floor();

    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('💧', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 16),
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
                      '$waterMl / $waterGoal ml ($glasses bicchieri)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _showAddWaterDialog,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.blue.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(Colors.blue),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartSuggestions() {
    final suggestions = _suggestions!['suggestions'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CleanSectionHeader(title: '💡 Suggerimenti Smart'),
        const SizedBox(height: 12),
        ...suggestions.map((suggestion) => _buildSuggestionCard(suggestion)),
      ],
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Row(
        children: [
          Text(
            suggestion['icon'] ?? '💡',
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion['title'] ?? '',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                Text(
                  suggestion['description'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ],
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
        CleanSectionHeader(title: '🍽️ Pasti di Oggi'),
        const SizedBox(height: 12),
        if (_meals.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('🍽️', style: TextStyle(fontSize: 48)),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: meal.mealTypeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(meal.mealTypeIcon, color: meal.mealTypeColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.mealTypeLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                Text(
                  '${meal.totalCalories} kcal • P:${meal.proteinGrams?.toInt() ?? 0}g C:${meal.carbsGrams?.toInt() ?? 0}g F:${meal.fatGrams?.toInt() ?? 0}g',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddWaterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: CleanTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '💧 Aggiungi Acqua',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWaterButton(150, '🥤'),
                _buildWaterButton(250, '🥛'),
                _buildWaterButton(500, '🍶'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWaterButton(750, '🫗'),
                _buildWaterButton(1000, '🧴'),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterButton(int ml, String emoji) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        await _addWater(ml);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              '${ml}ml',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addWater(int ml) async {
    try {
      final success = await _nutritionService.updateWater(waterMl: ml);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('💧 +${ml}ml aggiunto!'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: CleanTheme.accentRed,
          ),
        );
      }
    }
  }

  void _navigateToGoalSetup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GoalSetupWizardScreen()),
    );
    if (result == true) _loadData();
  }
}
