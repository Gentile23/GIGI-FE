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
import '../../widgets/gigi/gigi_coach_message.dart';
import 'package:gigi/l10n/app_localizations.dart';
import 'manual_goal_entry_screen.dart';
import 'food_duel_screen.dart';

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

      // Carica info sulla dieta attiva
      await coachProvider.loadActivePlan();

      if (mounted) {
        setState(() {
          if (summary != null) {
            _dailyLog = summary['summary'] as DailyNutritionLog?;
            _meals = (summary['meals'] as List<Meal>?) ?? [];
          } else {
            _dailyLog = null;
            _meals = [];
          }
          _goal = goal;

          // Aggiorna stato dieta attiva
          _hasActiveDiet = coachProvider.hasActivePlan;

          _isLoading = false;
        });
        _animationController.forward(from: 0.0);
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

                        // ══════════════════════════════════════════════════════
                        // ══════════════════════════════════════════════════════
                        // SEZIONE 1: IL TUO PIANO (Entry Point)
                        // ══════════════════════════════════════════════════════
                        if (_hasActiveDiet)
                          _buildActivePlanCard()
                        else ...[
                          GigiCoachMessage(
                            message: 'Hai un piano alimentare dal tuo nutrizionista? Importa il PDF e io analizzerò ogni riga per estrarre macro, obiettivi e pasti giornalieri. Trasformerò la tua dieta cartacea in una guida digitale interattiva! 🧠✨',
                            emotion: GigiEmotion.expert,
                          ),
                          const SizedBox(height: 16),
                          _buildImportDietCard(),
                        ],
                        const SizedBox(height: 32),

                        // ══════════════════════════════════════════════════════
                        // SEZIONE 2: STRATEGIA NUTRIZIONALE E AI TOOLS
                        // ══════════════════════════════════════════════════════
                        _buildGoalSetupCards(),
                        const SizedBox(height: 24),

                        // ══════════════════════════════════════════════════════
                        // SEZIONE 3: DATI GIORNALIERI (Calorie + Macro)
                        // ══════════════════════════════════════════════════════
                        _buildCalorieRingCard(),
                        const SizedBox(height: 16),
                        _buildMacroProgressCard(),
                        const SizedBox(height: 24),


                        // ══════════════════════════════════════════════════════
                        // SEZIONE 6: PASTI DI OGGI
                        // ══════════════════════════════════════════════════════
                        _buildMealsSection(),
                        const SizedBox(height: 32),

                        // ══════════════════════════════════════════════════════
                        // SEZIONE 7: AZIONI FINALI (Aggiungi Pasto)
                        // ══════════════════════════════════════════════════════
                        _buildFinalActionButtons(),
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFinalActionButtons() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            HapticService.lightTap();
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const MealLoggingScreen(isCalculatorMode: false),
              ),
            );
            if (result == true) _loadData();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: CleanTheme.primaryColor,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.addMeal,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // ENTRY POINTS & NAVIGATION
  // ════════════════════════════════════════════════════════════════════════════

  /// Card per importare una nuova dieta (stato: nessuna dieta attiva)
  Widget _buildImportDietCard() {
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        Navigator.pushNamed(context, '/nutrition/coach/upload');
      },
      child: LiquidSteelContainer(
        borderRadius: 20,
        enableShine: true,
        colors: const [
          CleanTheme.steelDark,
          CleanTheme.steelMid,
          CleanTheme.steelLight,
          CleanTheme.steelMid,
          CleanTheme.steelDark,
        ],
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CleanTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: CleanTheme.textOnDark.withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(
                  Icons.upload_file_rounded,
                  color: CleanTheme.textOnDark,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Importa Dieta PDF',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: CleanTheme.textOnDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Carica la tua dieta e ottimizza i risultati',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CleanTheme.textOnDark.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: CleanTheme.textOnDark.withValues(alpha: 0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card con riepilogo piano attivo + azioni rapide inline
  Widget _buildActivePlanCard() {
    final coachProvider = Provider.of<NutritionCoachProvider>(context, listen: false);
    final planName = coachProvider.activePlan?['name'] ?? 'Dieta Personalizzata';

    return Column(
      children: [
        // Header: Piano Attivo
        LiquidSteelContainer(
          borderRadius: 20,
          enableShine: true,
          colors: const [
            CleanTheme.steelDark,
            CleanTheme.steelMid,
            CleanTheme.steelLight,
            CleanTheme.steelMid,
            CleanTheme.steelDark,
          ],
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: CleanTheme.accentGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: CleanTheme.accentGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: CleanTheme.accentGreen.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '✓ PIANO ATTIVO',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: CleanTheme.accentGreen,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            planName,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: CleanTheme.textOnDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Azioni rapide inline
        Row(
          children: [
            Expanded(
              child: _buildQuickAction(
                icon: Icons.calendar_today_rounded,
                label: 'Vedi Piano',
                color: CleanTheme.primaryColor,
                onTap: () {
                  HapticService.lightTap();
                  Navigator.pushNamed(context, '/nutrition/coach/plan');
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickAction(
                icon: Icons.shopping_cart_rounded,
                label: 'Lista Spesa',
                color: CleanTheme.accentGold,
                onTap: () {
                  HapticService.lightTap();
                  Navigator.pushNamed(context, '/nutrition/coach/shopping-list');
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickAction(
                icon: Icons.refresh_rounded,
                label: 'Nuovo Piano',
                color: CleanTheme.accentBlue,
                onTap: () {
                  HapticService.lightTap();
                  Navigator.pushNamed(context, '/nutrition/coach/upload');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: CleanTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card secondarie per impostazione obiettivi (Wizard + Manuale)
  Widget _buildGoalSetupCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: double.infinity),
        Center(
          child: CleanSectionHeader(
            title: AppLocalizations.of(context)!.setupGoals,
          ),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 12),
        GigiCoachMessage(
          message: AppLocalizations.of(context)!.gigiStrategySuggestion,
          emotion: GigiEmotion.expert,
        ),
        const SizedBox(height: 24),
        
        // Pannello Strumenti AI
        _buildTrackCaloriesCompact(),
        const SizedBox(height: 12),
        _buildFoodDuelCard(),
        const SizedBox(height: 12),
        _buildChefAiCard(),
        const SizedBox(height: 24),
        
        Row(
          children: [
            // Card: Wizard (AI - Prominent)
            Expanded(
              child: _buildSmallEntryCard(
                emoji: '🤖',
                title: AppLocalizations.of(context)!.calculateForMe,
                subtitle: AppLocalizations.of(context)!.calculateForMeSubtitle,
                onTap: _navigateToGoalSetup,
                textColor: CleanTheme.primaryColor,
                isAI: true,
              ),
            ),
            const SizedBox(width: 12),
            // Card: Manual (Standard)
            Expanded(
              child: _buildSmallEntryCard(
                emoji: '✏️',
                title: AppLocalizations.of(context)!.customGoal,
                subtitle: AppLocalizations.of(context)!.customGoalSubtitle,
                onTap: _navigateToManualGoalEntry,
                textColor: CleanTheme.textPrimary,
                isAI: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToManualGoalEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManualGoalEntryScreen(
          currentCalories: _goal?.dailyCalories,
          currentProtein: _goal?.proteinGrams,
          currentCarbs: _goal?.carbsGrams,
          currentFat: _goal?.fatGrams,
        ),
      ),
    );
    if (result == true) _loadData();
  }

  Widget _buildSmallEntryCard({
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color textColor,
    bool isAI = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CleanTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isAI
                    ? CleanTheme.primaryColor.withValues(alpha: 0.5)
                    : textColor.withValues(alpha: 0.1),
            width: isAI ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isAI
                      ? CleanTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isAI ? CleanTheme.primaryColor : textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: textColor.withValues(alpha: 0.6),
                height: 1.2,
              ),
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
                      '👨‍🍳 Genius Chef AI',
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

  /// Compact version of Traccia Calorie - Now Calculator Mode
  Widget _buildTrackCaloriesCompact() {
    return GestureDetector(
      onTap: () async {
        HapticService.lightTap();
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const MealLoggingScreen(isCalculatorMode: true),
          ),
        );
        if (result == true) _loadData();
      },
      child: LiquidSteelContainer(
        borderRadius: 16,
        enableShine: true,
        colors: const [
          Color(0xFFE5E5EA), // Chrome Light
          Color(0xFFD1D1D6), // Chrome Mid
          Color(0xFFE5E5EA), // Chrome Light
          Color(0xFFD1D1D6), // Chrome Mid
          Color(0xFFE5E5EA), // Chrome Light
        ],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: CleanTheme.textPrimary.withValues(alpha: 0.1),
          width: 1,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CleanTheme.chromeSilver.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CleanTheme.textPrimary.withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(
                  Icons.calculate_rounded,
                  color: CleanTheme.textPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📸 Snap & Track AI',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.snapAndTrackAiSubtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CleanTheme.textPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: CleanTheme.textPrimary.withValues(alpha: 0.5),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Food Duel AI — Compare two foods head-to-head
  Widget _buildFoodDuelCard() {
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FoodDuelScreen()),
        );
      },
      child: LiquidSteelContainer(
        borderRadius: 16,
        enableShine: true,
        colors: const [
          Color(0xFF1C1C1E),
          Color(0xFF2C2C2E),
          Color(0xFF1C1C1E),
          Color(0xFF2C2C2E),
          Color(0xFF1C1C1E),
        ],
        border: Border.all(
          color: CleanTheme.accentGold.withValues(alpha: 0.3),
          width: 1,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CleanTheme.accentGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CleanTheme.accentGold.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.compare_arrows_rounded,
                  color: CleanTheme.accentGold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚔️ Food Duel AI',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CleanTheme.textOnDark,
                      ),
                    ),
                    Text(
                      'Sfida due alimenti: chi vince a macro?',
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
    final target = _goal?.dailyCalories;
    final remaining = target != null ? target - consumed : 0;
    final progress = target != null && target > 0
        ? (consumed / target).clamp(0.0, 1.2)
        : 0.0;

    return CleanCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_goal != null)
                GestureDetector(
                  onTap: _showDeleteGoalDialog,
                  child: const Icon(
                    Icons.delete_outline,
                    color: CleanTheme.accentRed,
                    size: 20,
                  ),
                )
              else
                _buildAddGoalButton(),
            ],
          ),
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
                      target != null ? '$target kcal' : '--- kcal',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (target != null)
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
                      )
                    else
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
                          AppLocalizations.of(context)!.noGoalsSet,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: CleanTheme.textSecondary,
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

  Widget _buildAddGoalButton() {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'manual') {
          _navigateToManualGoalEntry();
        } else if (value == 'wizard') {
          _navigateToGoalSetup();
        }
      },
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'manual',
          child: Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                color: CleanTheme.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(l10n.customGoal, style: GoogleFonts.inter(fontSize: 14)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'wizard',
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: CleanTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(l10n.calculateForMe, style: GoogleFonts.inter(fontSize: 14)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: CleanTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: CleanTheme.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_circle_outline_rounded,
              size: 16,
              color: CleanTheme.primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.addNutritionalGoal,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: CleanTheme.primaryColor,
              ),
            ),
          ],
        ),
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
            _goal?.proteinGrams.toDouble(),
            CleanTheme.steelDark,
            '🥩',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMacroItem(
            AppLocalizations.of(context)!.carbs,
            _dailyLog?.totalCarbs ?? 0,
            _goal?.carbsGrams.toDouble(),
            CleanTheme.steelDark,
            '🍞',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMacroItem(
            AppLocalizations.of(context)!.fats,
            _dailyLog?.totalFat ?? 0,
            _goal?.fatGrams.toDouble(),
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
    double? target,
    Color color,
    String emoji,
  ) {
    final progress = target != null && target > 0
        ? (current / target).clamp(0.0, 1.0)
        : 0.0;

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
            target != null
                ? '${current.toInt()}/${target.toInt()}g'
                : '${current.toInt()}/---g',
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


  void _navigateToGoalSetup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GoalSetupWizardScreen()),
    );
    if (result == true) _loadData();
  }

  void _showDeleteGoalDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.surfaceColor,
        title: Text(
          '${l10n.delete} ${l10n.goal}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Sei sicuro di voler eliminare il tuo obiettivo nutrizionale? Questa azione non può essere annullata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteGoal();
            },
            child: Text(
              l10n.delete,
              style: GoogleFonts.inter(
                color: CleanTheme.accentRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGoal() async {
    setState(() => _isLoading = true);
    try {
      final success = await _nutritionService.deleteGoals();
      if (success) {
        if (mounted) {
          setState(() {
            _goal = null;
            // Note: keeping dailyLog and meals as they are tracking what was eaten
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Obiettivo eliminato correttamente'),
              backgroundColor: CleanTheme.steelDark,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante l\'eliminazione dell\'obiettivo'),
            backgroundColor: CleanTheme.accentRed,
          ),
        );
      }
    } finally {
      _loadData();
    }
  }
}
