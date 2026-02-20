import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/nutrition_model.dart';
import '../../../data/services/nutrition_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../providers/nutrition_coach_provider.dart';
import '../../widgets/clean_widgets.dart';
import '../../widgets/animations/liquid_steel_container.dart';
import '../../../core/services/haptic_service.dart';
import 'meal_logging_screen.dart';
import 'goal_setup_wizard_screen.dart';
import 'what_to_cook_screen.dart';
import 'package:gigi/l10n/app_localizations.dart';

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

  // Stato per la dieta attiva
  bool _hasActiveDiet = false;

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

    // Ottieni il provider PRIMA degli await per evitare use_build_context_synchronously
    final coachProvider = Provider.of<NutritionCoachProvider>(
      context,
      listen: false,
    );

    try {
      final summary = await _nutritionService.getDailySummary();
      final goal = await _nutritionService.getGoals();
      final suggestions = await _nutritionService.getSmartSuggestions();

      // Carica info sulla dieta attiva
      await coachProvider.loadActivePlan();

      if (mounted) {
        setState(() {
          if (summary != null) {
            _dailyLog = summary['summary'] as DailyNutritionLog?;
            _meals = (summary['meals'] as List<Meal>?) ?? [];
          }
          _goal = goal;
          _suggestions = suggestions;

          // Aggiorna stato dieta attiva
          _hasActiveDiet = coachProvider.hasActivePlan;

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
              color: CleanTheme.chromeGray,
              backgroundColor: CleanTheme.surfaceColor,
              child: CustomScrollView(
                slivers: [
                  // Premium App Bar
                  SliverAppBar(
                    expandedHeight: 100,
                    floating: true,
                    pinned: true,
                    backgroundColor: CleanTheme.surfaceColor,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        AppLocalizations.of(context)!.nutritionCoachTitle,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          color: CleanTheme.textPrimary,
                          fontSize: 20,
                        ),
                      ),
                      centerTitle: true,
                    ),
                    actions: const [], // Settings removed
                  ),

                  // Content
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ══════════════════════════════════════════════════════
                        // SEZIONE 1: DUE CARD PRINCIPALI (Entry Points)
                        // ══════════════════════════════════════════════════════
                        _buildTwoMainCards(),
                        const SizedBox(height: 24),

                        // ══════════════════════════════════════════════════════
                        // SEZIONE 2: TRACCIA CALORIE (compatta, sotto le main cards)
                        // ══════════════════════════════════════════════════════
                        _buildTrackCaloriesCompact(),
                        const SizedBox(height: 16),

                        // ══════════════════════════════════════════════════════
                        // SEZIONE 3: CHEF AI (sempre visibile)
                        // ══════════════════════════════════════════════════════
                        _buildChefAiCard(),
                        const SizedBox(height: 24),

                        // ══════════════════════════════════════════════════════
                        // SEZIONE 4: DATI GIORNALIERI (Calorie + Macro)
                        // ══════════════════════════════════════════════════════
                        if (_goal != null) ...[
                          _buildCalorieRingCard(),
                          const SizedBox(height: 16),
                          _buildMacroProgressCard(),
                          const SizedBox(height: 24),
                        ],

                        // ══════════════════════════════════════════════════════
                        // SEZIONE 5: WATER TRACKER
                        // ══════════════════════════════════════════════════════
                        _buildWaterTracker(),
                        const SizedBox(height: 24),

                        // ══════════════════════════════════════════════════════
                        // SEZIONE 6: SUGGERIMENTI SMART
                        // ══════════════════════════════════════════════════════
                        if (_suggestions != null &&
                            _suggestions!['suggestions'] != null &&
                            (_suggestions!['suggestions'] as List).isNotEmpty)
                          _buildSmartSuggestions(),
                        const SizedBox(height: 24),

                        // ══════════════════════════════════════════════════════
                        // SEZIONE 7: PASTI DI OGGI
                        // ══════════════════════════════════════════════════════
                        _buildMealsSection(),
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  // ════════════════════════════════════════════════════════════════════════════
  // DUE CARD PRINCIPALI - Entry Points
  // ════════════════════════════════════════════════════════════════════════════

  /// Due card principali per separare i due use case: Piano vs Tracking
  Widget _buildTwoMainCards() {
    return Column(
      children: [
        // Card 1: Il Tuo Piano
        _buildMainEntryCard(
          emoji: '📋',
          title: 'Il Tuo Piano',
          subtitle: _hasActiveDiet
              ? 'Visualizza la tua dieta'
              : 'Carica la dieta dal nutrizionista',
          gradientColors: const [CleanTheme.steelMid, CleanTheme.steelDark],
          onTap: () => _hasActiveDiet
              ? Navigator.pushNamed(context, '/nutrition/coach/plan')
              : Navigator.pushNamed(context, '/nutrition/coach/upload'),
          badge: _hasActiveDiet ? '✓ Attivo' : null,
        ),
        const SizedBox(height: 12),
        // Card 2: Imposta i Tuoi Obiettivi (versione grande)
        _buildMainEntryCard(
          emoji: '🎯',
          title: AppLocalizations.of(context)!.setupGoalsTitle,
          subtitle: AppLocalizations.of(context)!.setupGoalsSubtitle,
          gradientColors: const [CleanTheme.steelLight, CleanTheme.steelMid],
          onTap: _navigateToGoalSetup,
          badge: null,
        ),
      ],
    );
  }

  /// Card singola per entry point principale
  Widget _buildMainEntryCard({
    required String emoji,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CleanTheme.steelSilver, width: 1),
          boxShadow: [
            BoxShadow(
              color: CleanTheme.primaryColor.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji grande a sinistra
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CleanTheme.textOnDark.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 16),
            // Info centrale
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CleanTheme.textOnDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CleanTheme.textOnDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: CleanTheme.textOnDark.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: CleanTheme.textOnDark,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CHEF AI CARD
  // ════════════════════════════════════════════════════════════════════════════

  /// Card per Chef AI - accessibile sempre
  Widget _buildChefAiCard() {
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WhatToCookScreen()),
        );
      },
      child: LiquidSteelContainer(
        borderRadius: 16,
        enableShine: true,
        border: Border.all(
          color: CleanTheme.textOnDark.withValues(alpha: 0.3),
          width: 1,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CleanTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CleanTheme.textOnDark.withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(
                  Icons.soup_kitchen_rounded,
                  color: CleanTheme.textOnDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '👨‍🍳 Chef AI',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CleanTheme.textOnDark,
                      ),
                    ),
                    Text(
                      'Cosa cucino oggi?',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CleanTheme.textOnDark.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: CleanTheme.textOnDark.withValues(alpha: 0.7),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact version of Traccia Calorie - same style as Chef AI card
  Widget _buildTrackCaloriesCompact() {
    return GestureDetector(
      onTap: () async {
        HapticService.lightTap();
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MealLoggingScreen()),
        );
        if (result == true) _loadData();
      },
      child: LiquidSteelContainer(
        borderRadius: 16,
        enableShine: true,
        border: Border.all(
          color: CleanTheme.textOnDark.withValues(alpha: 0.3),
          width: 1,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CleanTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CleanTheme.textOnDark.withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: CleanTheme.textOnDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📸 Scan AI',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CleanTheme.textOnDark,
                      ),
                    ),
                    Text(
                      'Scansiona pasto con Intelligenza Artificiale',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CleanTheme.textOnDark.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: CleanTheme.textOnDark.withValues(alpha: 0.7),
                size: 14,
              ),
            ],
          ),
        ),
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
                                  ? CleanTheme.steelDark
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
                      AppLocalizations.of(context)!.dailyGoal,
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
                        color: CleanTheme.chromeSubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        remaining > 0
                            ? AppLocalizations.of(
                                context,
                              )!.kcalRemaining(remaining.abs())
                            : AppLocalizations.of(
                                context,
                              )!.kcalExcess(remaining.abs()),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CleanTheme.textPrimary,
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
            AppLocalizations.of(context)!.protein,
            _dailyLog?.totalProtein ?? 0,
            (_goal?.proteinGrams ?? 150).toDouble(),
            CleanTheme.steelDark,
            '🥩',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMacroItem(
            AppLocalizations.of(context)!.carbs,
            _dailyLog?.totalCarbs ?? 0,
            (_goal?.carbsGrams ?? 200).toDouble(),
            CleanTheme.steelDark,
            '🍞',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMacroItem(
            AppLocalizations.of(context)!.fats,
            _dailyLog?.totalFat ?? 0,
            (_goal?.fatGrams ?? 70).toDouble(),
            CleanTheme.steelDark,
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
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: CleanTheme.chromeSubtle,
              valueColor: const AlwaysStoppedAnimation(CleanTheme.steelDark),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterTracker() {
    final waterMl = _dailyLog?.waterMl ?? 0;
    const waterGoal = 2500;
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
                  color: CleanTheme.chromeSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CleanTheme.borderPrimary),
                ),
                child: const Text('💧', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.water,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.waterGlassesCount(waterMl, waterGoal, glasses),
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
                    color: CleanTheme.steelDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: CleanTheme.textOnPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: CleanTheme.chromeSubtle,
              valueColor: const AlwaysStoppedAnimation(CleanTheme.steelLight),
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
        CleanSectionHeader(
          title: AppLocalizations.of(context)!.smartSuggestions,
        ),
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
        CleanSectionHeader(title: AppLocalizations.of(context)!.todayMeals),
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
                    AppLocalizations.of(context)!.noMealsLogged,
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
              color: CleanTheme.chromeSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CleanTheme.chromeSilver),
            ),
            child: Icon(
              meal.mealTypeIcon,
              color: const Color(0xFF3A3A3C),
              size: 24,
            ),
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
                  '${meal.totalCalories} kcal • P:${meal.proteinGrams.toInt()}g C:${meal.carbsGrams.toInt()}g F:${meal.fatGrams.toInt()}g',
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
              AppLocalizations.of(context)!.addWater,
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
          color: CleanTheme.chromeSubtle,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CleanTheme.chromeSilver),
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
                color: CleanTheme.steelDark,
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
            backgroundColor: CleanTheme.steelDark,
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
