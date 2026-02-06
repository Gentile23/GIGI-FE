import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/nutrition_model.dart';
import '../../../data/services/nutrition_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../providers/nutrition_coach_provider.dart';
import '../../widgets/clean_widgets.dart';
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
  Map<String, dynamic>? _activeDietInfo;

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
          if (_hasActiveDiet && coachProvider.activePlan != null) {
            _activeDietInfo = {
              'name': coachProvider.activePlan!['name'] ?? 'La mia dieta',
              'created_at': coachProvider.activePlan!['created_at'],
            };
          }

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
                        // ══════════════════════════════════════════════════════
                        // SEZIONE 1: LA MIA DIETA (Hero Card se esiste)
                        // ══════════════════════════════════════════════════════
                        if (_hasActiveDiet) ...[
                          _buildMyDietCard(),
                          const SizedBox(height: 20),
                        ] else ...[
                          // CTA prominente per chi non ha dieta
                          _buildGetStartedBanner(),
                          const SizedBox(height: 20),
                        ],

                        // ══════════════════════════════════════════════════════
                        // SEZIONE 2: SETUP OBIETTIVI (se mancano)
                        // ══════════════════════════════════════════════════════
                        if (_goal == null) ...[
                          _buildSetupPrompt(),
                          const SizedBox(height: 20),
                        ],

                        // ══════════════════════════════════════════════════════
                        // SEZIONE 3: DATI GIORNALIERI (Calorie + Macro)
                        // ══════════════════════════════════════════════════════
                        if (_goal != null) ...[
                          _buildCalorieRingCard(),
                          const SizedBox(height: 16),
                          _buildMacroProgressCard(),
                          const SizedBox(height: 24),
                        ],

                        // ══════════════════════════════════════════════════════
                        // SEZIONE 4: AZIONI RAPIDE
                        // ══════════════════════════════════════════════════════
                        _buildQuickActionsRow(),
                        const SizedBox(height: 24),

                        // ══════════════════════════════════════════════════════
                        // SEZIONE 5: FEATURE PREMIUM
                        // ══════════════════════════════════════════════════════
                        _buildPremiumSection(),
                        const SizedBox(height: 24),

                        // ══════════════════════════════════════════════════════
                        // SEZIONE 6: WATER TRACKER
                        // ══════════════════════════════════════════════════════
                        _buildWaterTracker(),
                        const SizedBox(height: 24),

                        // ══════════════════════════════════════════════════════
                        // SEZIONE 7: SUGGERIMENTI SMART
                        // ══════════════════════════════════════════════════════
                        if (_suggestions != null &&
                            _suggestions!['suggestions'] != null &&
                            (_suggestions!['suggestions'] as List).isNotEmpty)
                          _buildSmartSuggestions(),
                        const SizedBox(height: 24),

                        // ══════════════════════════════════════════════════════
                        // SEZIONE 8: PASTI DI OGGI
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
  // NUOVI WIDGET - LA MIA DIETA CARD (HERO)
  // ════════════════════════════════════════════════════════════════════════════

  /// Card prominente che mostra la dieta attiva - permette accesso rapido al piano
  Widget _buildMyDietCard() {
    final dietName = _activeDietInfo?['name'] ?? 'La mia dieta';
    final createdAt = _activeDietInfo?['created_at'];
    String dateText = 'Piano attivo';

    if (createdAt != null) {
      try {
        final date = DateTime.parse(createdAt);
        final now = DateTime.now();
        final diff = now.difference(date).inDays;
        if (diff == 0) {
          dateText = 'Caricato oggi';
        } else if (diff == 1) {
          dateText = 'Caricato ieri';
        } else {
          dateText = 'Caricato $diff giorni fa';
        }
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/nutrition/coach/plan'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF059669), // Emerald 600
              Color(0xFF10B981), // Emerald 500
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icona grande a sinistra
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            // Info centrale
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dietName,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tocca per vedere il tuo piano →',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CTA GET STARTED BANNER (per utenti senza dieta)
  // ════════════════════════════════════════════════════════════════════════════

  /// Banner prominente per invitare a caricare una dieta PDF
  Widget _buildGetStartedBanner() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/nutrition/coach/upload'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7C3AED), // Violet 600
              Color(0xFF8B5CF6), // Violet 500
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji/Icona
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('📋', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            // Testo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hai una dieta dal nutrizionista?',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Caricala e trasformala in un piano digitale con AI!',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SEZIONE PREMIUM FEATURES
  // ════════════════════════════════════════════════════════════════════════════

  /// Sezione che raggruppa le feature premium in modo chiaro
  Widget _buildPremiumSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header sezione
        Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'Potenzia la tua nutrizione',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: CleanTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Grid delle feature premium
        Row(
          children: [
            // Upload Dieta (se non ha dieta attiva)
            if (!_hasActiveDiet)
              Expanded(
                child: _buildPremiumFeatureCard(
                  icon: Icons.upload_file_rounded,
                  title: 'Carica PDF',
                  subtitle: 'Analisi AI',
                  gradientColors: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  onTap: () =>
                      Navigator.pushNamed(context, '/nutrition/coach/upload'),
                ),
              ),
            if (!_hasActiveDiet) const SizedBox(width: 12),
            // Piano AI
            Expanded(
              child: _buildPremiumFeatureCard(
                icon: Icons.auto_awesome,
                title: 'Piano AI',
                subtitle: 'Generazione',
                gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                onTap: () =>
                    Navigator.pushNamed(context, '/nutrition/coach/plan'),
              ),
            ),
            const SizedBox(width: 12),
            // What to Cook
            Expanded(
              child: _buildPremiumFeatureCard(
                icon: Icons.restaurant_menu,
                title: 'Cosa cucino?',
                subtitle: 'Ricette smart',
                gradientColors: const [Color(0xFFEC4899), Color(0xFFDB2777)],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WhatToCookScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Card singola per una feature premium
  Widget _buildPremiumFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupPrompt() {
    return _buildPremiumActionCard(
      title: AppLocalizations.of(context)!.setupGoalsTitle,
      subtitle: AppLocalizations.of(context)!.setupGoalsSubtitle,
      icon: Icons.flag_rounded,
      gradientColors: [
        CleanTheme.primaryColor,
        CleanTheme.primaryColor.withValues(alpha: 0.8),
      ], // Teal/Primary
      boxShadowColor: CleanTheme.primaryColor.withValues(alpha: 0.3),
      onTap: _navigateToGoalSetup,
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
                        color: remaining > 0
                            ? CleanTheme.accentGreen.withValues(alpha: 0.1)
                            : CleanTheme.accentRed.withValues(alpha: 0.1),
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
            AppLocalizations.of(context)!.protein,
            _dailyLog?.totalProtein ?? 0,
            (_goal?.proteinGrams ?? 150).toDouble(),
            CleanTheme.accentBlue,
            '🥩',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMacroItem(
            AppLocalizations.of(context)!.carbs,
            _dailyLog?.totalCarbs ?? 0,
            (_goal?.carbsGrams ?? 200).toDouble(),
            CleanTheme.accentOrange,
            '🍞',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMacroItem(
            AppLocalizations.of(context)!.fats,
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

  Widget _buildQuickActionsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            icon: Icons.camera_alt_rounded,
            label: AppLocalizations.of(context)!.addMeal,
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
            label: AppLocalizations.of(context)!.whatToCook,
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

  Widget _buildPremiumActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required Color boxShadowColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: boxShadowColor,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
