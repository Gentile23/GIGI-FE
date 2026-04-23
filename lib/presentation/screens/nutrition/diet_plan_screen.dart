import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/nutrition_coach_provider.dart';
import '../../../providers/quota_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../paywall/paywall_screen.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/services/quota_service.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/animations/liquid_steel_container.dart';
import '../../widgets/nutrition/food_scale_widget.dart';

class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({super.key});

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  int _currentWeekIndex = 0;

  void _handleTabSelection() {
    if (_tabController?.indexIsChanging == false) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    // Defer loading to post-frame to avoid build conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NutritionCoachProvider>(
        context,
        listen: false,
      );
      if (!provider.hasActivePlan) {
        provider.loadActivePlan();
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NutritionCoachProvider>(
      builder: (context, provider, child) {
        // 1. Loading State
        if (provider.isLoading && !provider.hasActivePlan) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Recupero il tuo piano...'),
                ],
              ),
            ),
          );
        }

        // 2. No Plan State - Design Premium
        if (!provider.hasActivePlan) {
          return Scaffold(
            backgroundColor: CleanTheme.chromeSubtle,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Il Tuo Piano Personalizzato',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Illustrazione/Emoji prominente
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            CleanTheme.steelDark,
                            CleanTheme.primaryColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: CleanTheme.primaryColor.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Text('📋', style: TextStyle(fontSize: 56)),
                    ),
                    const SizedBox(height: 32),

                    // Titolo persuasivo
                    Text(
                      'Trasforma la tua dieta\nin un piano digitale',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: CleanTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sottotitolo benefici
                    Text(
                      'Carica il PDF della tua dieta e l\'AI lo analizzerà in automatico. Avrai il tuo piano sempre a portata di mano!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: CleanTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // CTA principale
                    GestureDetector(
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed('/nutrition/coach/upload'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [CleanTheme.steelMid, CleanTheme.steelDark],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: CleanTheme.primaryColor.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.upload_file_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Carica la tua Dieta',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: CleanTheme.textOnDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Testo di supporto
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.bolt,
                          color: CleanTheme.accentGold,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Analisi AI in pochi secondi',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: CleanTheme.accentGold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 3. Active Plan State
        final planData = provider.activePlan!['content'];

        // Safety check for content structure
        if (planData == null || planData['weeks'] == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Ops!')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: CleanTheme.accentOrange,
                  ),
                  const SizedBox(height: 16),
                  const Text('Errore nel formato della dieta.'),
                  Text(
                    'Dati ricevuti incompleti.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed('/nutrition/coach/upload'),
                    child: const Text('Riprova Upload'),
                  ),
                ],
              ),
            ),
          );
        }

        final weeks = planData['weeks'] as List;
        if (weeks.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Piano Vuoto')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.fastfood_outlined,
                    size: 60,
                    color: CleanTheme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text('Nessun pasto trovato nella dieta analizzata.'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed('/nutrition/coach/upload'),
                    child: const Text('Carica un nuovo PDF'),
                  ),
                ],
              ),
            ),
          );
        }

        final currentWeek = weeks[_currentWeekIndex];
        final days = currentWeek['days'] as List;
        final todayIndex = DateTime.now().weekday - 1; // 0=Mon, 6=Sun

        // Ensure controller is valid
        if (_tabController == null || _tabController!.length != days.length) {
          _tabController?.removeListener(_handleTabSelection);
          _tabController?.dispose();
          _tabController = TabController(
            length: days.length,
            vsync: this,
            initialIndex: todayIndex.clamp(0, days.length - 1),
          );
          _tabController!.addListener(_handleTabSelection);
        }

        return Scaffold(
          backgroundColor: CleanTheme.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              provider.activePlan!['name'] ?? 'Il Tuo Piano',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: CleanTheme.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.restore_rounded,
                  color: CleanTheme.accentOrange,
                ),
                tooltip: 'Ripristina Originale',
                onPressed: () => _showRestorePlanDialog(context, provider),
              ),
              IconButton(
                icon: const Icon(
                  Icons.share_outlined,
                  color: CleanTheme.textPrimary,
                ),
                tooltip: 'Condividi',
                onPressed: () {
                  final currentDay = days[_tabController!.index];
                  _shareDay(currentDay);
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: CleanTheme.textPrimary,
                ),
                onPressed: () {
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  final user = authProvider.user;
                  final isPremium = user?.subscription?.isActive ?? false;

                  if (!isPremium) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const PaywallScreen(),
                      ),
                    );
                  } else {
                    Navigator.of(
                      context,
                    ).pushNamed('/nutrition/coach/shopping-list');
                  }
                },
              ),
            ],
          ),

          body: Stack(
            children: [
              Column(
                children: [
                  // Week Selector (if multiple)
                  if (weeks.length > 1)
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: weeks.length,
                        itemBuilder: (context, index) {
                          final isSelected = _currentWeekIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentWeekIndex = index;
                                _tabController?.animateTo(0);
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(
                                right: 8,
                                top: 8,
                                bottom: 8,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? CleanTheme.steelDark
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? CleanTheme.steelDark
                                      : CleanTheme.borderPrimary,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'SETTIMANA ${index + 1}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : CleanTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  // Day Selector Pills
                  Container(
                    height: 56,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: days.length,
                      itemBuilder: (context, index) {
                        final day = days[index];
                        final isSelected = _tabController!.index == index;
                        final dayName =
                            day['day_name'] ?? 'Giorno ${index + 1}';
                        // Abbreviate for pills
                        final shortName = dayName.length > 3
                            ? dayName.substring(0, 3)
                            : dayName;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _tabController!.animateTo(index);
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? CleanTheme.primaryColor
                                  : CleanTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: isSelected
                                    ? CleanTheme.primaryColor
                                    : CleanTheme.borderPrimary,
                                width: 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: CleanTheme.primaryColor
                                            .withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                shortName.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isSelected
                                      ? CleanTheme.textOnPrimary
                                      : CleanTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Meals Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: days.asMap().entries.map((entry) {
                        return _buildDayView(context, entry.value, entry.key);
                      }).toList(),
                    ),
                  ),
                ],
              ),
              // Loading Overlay
              if (provider.isLoading)
                Positioned.fill(
                  child: Container(
                    color: CleanTheme.primaryColor.withValues(alpha: 0.5),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: CleanTheme.textOnPrimary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'L\'IA sta elaborando...',
                            style: GoogleFonts.outfit(
                              color: CleanTheme.textOnDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayView(
    BuildContext context,
    Map<String, dynamic> day,
    int dayIndex,
  ) {
    final meals = day['meals'] as List;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // Daily Macros Summary Card
        _buildDayMacrosCard(day),
        if (day['daily_notes'] != null &&
            day['daily_notes'].toString().isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildPersonalizedNotesCard(day['daily_notes']),
        ],
        const SizedBox(height: 16),
        // Meals
        ...meals.asMap().entries.map((entry) {
          return _buildMealCard(context, entry.value, dayIndex, entry.key);
        }),
      ],
    );
  }

  Widget _buildFoodMacroRow(Map<String, dynamic> food) {
    if (food['proteins'] == null &&
        food['carbs'] == null &&
        food['fats'] == null) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _buildMinimalMacro(
          'P',
          '${(food['proteins'] ?? 0)}g',
          CleanTheme.accentGreen,
        ),
        _buildMinimalMacro(
          'C',
          '${(food['carbs'] ?? 0)}g',
          CleanTheme.accentGold,
        ),
        _buildMinimalMacro(
          'F',
          '${(food['fats'] ?? 0)}g',
          CleanTheme.accentBlue,
        ),
      ],
    );
  }

  Widget _buildMinimalMacro(String l, String v, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$l: $v',
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: c,
        ),
      ),
    );
  }

  Widget _buildPersonalizedNotesCard(String notes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.chromeSubtle.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CleanTheme.borderPrimary.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sticky_note_2_outlined,
                size: 14,
                color: CleanTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'NOTE DEL GIORNO',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: CleanTheme.textSecondary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notes,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: CleanTheme.textPrimary.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayMacrosCard(Map<String, dynamic> day) {
    // Calculate totals from all meals
    int totalKcal = 0;
    double totalProteins = 0;
    double totalCarbs = 0;
    double totalFats = 0;

    final meals = day['meals'] as List? ?? [];
    for (var meal in meals) {
      final foods = meal['foods'] as List? ?? [];
      final Set<String> countedGroups = {};

      for (var food in foods) {
        final isAlternative = food['is_alternative'] == true;
        final groupId = food['alternative_group_id']?.toString();

        if (isAlternative && groupId != null) {
          if (countedGroups.contains(groupId)) continue;
          countedGroups.add(groupId);
        }

        totalKcal += (food['calories'] as num?)?.toInt() ?? 0;
        totalProteins += (food['proteins'] as num?)?.toDouble() ?? 0;
        totalCarbs += (food['carbs'] as num?)?.toDouble() ?? 0;
        totalFats += (food['fats'] as num?)?.toDouble() ?? 0;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: CleanTheme.steelDark.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: LiquidSteelContainer(
        borderRadius: 32,
        enableShine: true,
        colors: const [
          CleanTheme.steelDark,
          CleanTheme.steelMid,
          CleanTheme.steelLight,
          CleanTheme.steelMid,
          CleanTheme.steelDark,
        ],
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TARGET GIORNALIERO',
                        style: GoogleFonts.outfit(
                          color: CleanTheme.textOnDark.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status Nutrizionale',
                        style: GoogleFonts.outfit(
                          color: CleanTheme.textOnDark,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      color: CleanTheme.accentGold,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMacroItem(
                    'KCAL',
                    totalKcal.toString(),
                    CleanTheme.textOnDark,
                    Icons.local_fire_department_rounded,
                  ),
                  _buildMacroItem(
                    'PROT',
                    '${totalProteins.toStringAsFixed(0)}g',
                    CleanTheme.accentGreen,
                    Icons.fitness_center_rounded,
                  ),
                  _buildMacroItem(
                    'CARB',
                    '${totalCarbs.toStringAsFixed(0)}g',
                    CleanTheme.accentGold,
                    Icons.bakery_dining_rounded,
                  ),
                  _buildMacroItem(
                    'FATS',
                    '${totalFats.toStringAsFixed(0)}g',
                    CleanTheme.accentBlue,
                    Icons.opacity_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMacroItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color.withValues(alpha: 0.7), size: 18),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: CleanTheme.textOnDark.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(
    BuildContext context,
    Map<String, dynamic> meal,
    int dayIndex,
    int mealIndex,
  ) {
    final mealType = meal['type'] ?? 'Pasto';
    final mealIcon = _getMealIcon(mealType);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: CleanTheme.borderPrimary.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal Header - Premium Glassy Look
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              color: CleanTheme.chromeSubtle.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            CleanTheme.primaryColor.withValues(alpha: 0.1),
                            CleanTheme.primaryColor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: CleanTheme.primaryColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Icon(
                        mealIcon,
                        size: 26,
                        color: CleanTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (meal['time'] != null)
                            Text(
                              meal['time'].toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: CleanTheme.accentOrange,
                                letterSpacing: 1.5,
                              ),
                            ),
                          Text(
                            mealType,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: CleanTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (meal['is_substitution'] == true) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: CleanTheme.accentOrange.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: CleanTheme.accentOrange.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '🧊 ',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  Text(
                                    'SOSTITUITO OGGI',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: CleanTheme.accentOrange,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _buildMealKcalBadge(meal),
                  ],
                ),
                if (meal['meal_notes'] != null &&
                    meal['meal_notes'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: CleanTheme.accentGold.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: CleanTheme.accentGold.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 14,
                            color: CleanTheme.accentGold,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              meal['meal_notes'],
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: CleanTheme.textPrimary.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                _buildMealMacroRow(meal),
              ],
            ),
          ),
          // Food Items
          ..._buildFoodItems(
            context,
            meal['foods'] as List,
            dayIndex,
            mealIndex,
          ),
          // Bottom Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: CleanTheme.chromeSubtle.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share_outlined, size: 20),
                    color: CleanTheme.textSecondary,
                    onPressed: () => _shareMeal(meal),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMagicRegenerateButton(
                    context,
                    dayIndex,
                    mealIndex,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealKcalBadge(Map<String, dynamic> meal) {
    int totalKcal = 0;
    final foods = meal['foods'] as List? ?? [];
    for (var f in foods) {
      if (f['is_alternative'] != true) {
        totalKcal += (f['calories'] as num?)?.toInt() ?? 0;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CleanTheme.primaryColor,
            CleanTheme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: CleanTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            '$totalKcal',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            'kcal',
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealMacroRow(Map<String, dynamic> meal) {
    double p = 0;
    double c = 0;
    double f = 0;
    final foods = meal['foods'] as List? ?? [];
    for (var food in foods) {
      if (food['is_alternative'] != true) {
        p += (food['proteins'] as num?)?.toDouble() ?? 0;
        c += (food['carbs'] as num?)?.toDouble() ?? 0;
        f += (food['fats'] as num?)?.toDouble() ?? 0;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CleanTheme.borderPrimary.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTinyMacroIndicator(
            'PROT',
            '${p.toInt()}g',
            CleanTheme.accentGreen,
          ),
          Container(width: 1, height: 12, color: CleanTheme.borderPrimary),
          _buildTinyMacroIndicator(
            'CARB',
            '${c.toInt()}g',
            CleanTheme.accentGold,
          ),
          Container(width: 1, height: 12, color: CleanTheme.borderPrimary),
          _buildTinyMacroIndicator(
            'FATS',
            '${f.toInt()}g',
            CleanTheme.accentBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildTinyMacroIndicator(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: CleanTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CleanTheme.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMagicRegenerateButton(
    BuildContext context,
    int dayIndex,
    int mealIndex,
  ) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [CleanTheme.accentGold, Color(0xFFFFD700)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: CleanTheme.accentGold.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final checkResult = await context.read<QuotaProvider>().canPerform(
              QuotaAction.changeMeal,
            );

            if (!checkResult.canPerform && context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PaywallScreen()),
              );
            } else if (checkResult.canPerform && context.mounted) {
              _showPremiumRegenerateDialog(context, dayIndex, mealIndex);
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 20,
                color: CleanTheme.primaryColor,
              ),
              const SizedBox(width: 10),
              Text(
                'CAMBIA MENÙ ✨',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: CleanTheme.primaryColor,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMealIcon(String type) {
    switch (type.toLowerCase()) {
      case 'colazione':
        return Icons.free_breakfast_outlined;
      case 'pranzo':
        return Icons.lunch_dining_outlined;
      case 'cena':
        return Icons.dinner_dining_outlined;
      case 'spuntino':
      case 'spuntino 1':
      case 'spuntino 2':
      case 'spuntino pre-allenamento':
      case 'post-allenamento':
        return Icons.apple;
      default:
        return Icons.restaurant_outlined;
    }
  }

  List<Widget> _buildFoodItems(
    BuildContext context,
    List foods,
    int dayIndex,
    int mealIndex,
  ) {
    return foods.asMap().entries.map((entry) {
      final foodIndex = entry.key;
      final food = entry.value;

      final isAlternative = food['is_alternative'] == true;
      final groupId = food['alternative_group_id'];

      // Logic to show "OPPURE" before second alternative in a group
      bool showOrLabel = false;
      if (isAlternative && foodIndex > 0) {
        final prevFood = foods[foodIndex - 1];
        if (prevFood['is_alternative'] == true &&
            prevFood['alternative_group_id'] != null &&
            prevFood['alternative_group_id'] == groupId) {
          showOrLabel = true;
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showOrLabel)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              child: Row(
                children: [
                  const Expanded(child: Divider(height: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OPPURE',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: CleanTheme.accentOrange,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(height: 1)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: isAlternative
                  ? CleanTheme.accentOrange.withValues(alpha: 0.02)
                  : Colors.white,
              border: entry.key < foods.length - 1
                  ? Border(
                      bottom: BorderSide(
                        color: CleanTheme.borderPrimary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isAlternative)
                      Container(
                        margin: const EdgeInsets.only(right: 12, top: 2),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: CleanTheme.accentOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.alt_route_rounded,
                          size: 14,
                          color: CleanTheme.accentOrange,
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            food['name'] ?? 'Alimento',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: CleanTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (food['is_substitution'] == true) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: CleanTheme.accentOrange.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: CleanTheme.accentOrange.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '🧊 ',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  Text(
                                    'SOSTITUITO OGGI',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: CleanTheme.accentOrange,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: CleanTheme.primaryColor.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${food['quantity'] ?? ''} ${food['unit'] ?? ''}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: CleanTheme.primaryColor,
                                  ),
                                ),
                              ),
                              if (food['calories'] != null) ...[
                                const SizedBox(width: 10),
                                Text(
                                  '${food['calories']} kcal',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: CleanTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Macro Badge
                    _buildFoodMacroRow(food),
                  ],
                ),
                const SizedBox(height: 20),
                // Action Bar - More Premium & Intuitive
                Row(
                  children: [
                    // Equivalence Action - Secondary
                    _buildFoodActionButton(
                      icon: Icons.compare_arrows_rounded,
                      label: 'Smart Swap',
                      color: CleanTheme.textSecondary,
                      isPrimary: false,
                      onTap: () => _showEquivalenceCalculator(
                        context,
                        food,
                        dayIndex,
                        mealIndex,
                        foodIndex,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Substitution Action - Primary
                    _buildFoodActionButton(
                      icon: Icons.auto_fix_high_rounded,
                      label: 'Unlock AI Alternatives',
                      color: CleanTheme.primaryColor,
                      isPrimary: true,
                      onTap: () async {
                        final checkResult = await context
                            .read<QuotaProvider>()
                            .canPerform(QuotaAction.changeFood);

                        if (!checkResult.canPerform && context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const PaywallScreen(),
                            ),
                          );
                        } else if (checkResult.canPerform && context.mounted) {
                          _showSubstitutionModal(
                            context,
                            food,
                            dayIndex,
                            mealIndex,
                            foodIndex,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildFoodActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(
                  colors: [CleanTheme.steelMid, CleanTheme.steelDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isPrimary
              ? null
              : CleanTheme.chromeSubtle.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: isPrimary
              ? null
              : Border.all(
                  color: CleanTheme.borderPrimary.withValues(alpha: 0.8),
                  width: 1,
                ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: CleanTheme.steelDark.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: isPrimary
                            ? Colors.white
                            : color.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label.toUpperCase(),
                        maxLines: 1,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isPrimary
                              ? Colors.white
                              : color.withValues(alpha: 0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareMeal(Map<String, dynamic> meal) async {
    final buffer = StringBuffer();
    buffer.writeln('🍽️ *${meal['type']}*');

    final foods = meal['foods'] as List;
    for (var food in foods) {
      buffer.writeln('• ${food['name']} (${food['quantity']}${food['unit']})');
    }

    // Add nutrients if available
    // buffer.writeln('\n🔥 ${meal['calories']} kcal');

    await SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  Future<void> _shareDay(Map<String, dynamic> day) async {
    final buffer = StringBuffer();
    buffer.writeln('📅 *Piano per ${day['day_name']}*');
    buffer.writeln('');

    final meals = day['meals'] as List;
    for (var meal in meals) {
      buffer.writeln('🍽️ *${meal['type']}*');
      final foods = meal['foods'] as List;
      for (var food in foods) {
        buffer.writeln(
          '• ${food['name']} (${food['quantity']}${food['unit']})',
        );
      }
      buffer.writeln('');
    }

    await SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  /// PREMIUM UI: Regenerate Meal Dialog
  void _showPremiumRegenerateDialog(
    BuildContext context,
    int dayIndex,
    int mealIndex,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: CleanTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 48,
              color: CleanTheme.accentGold,
            ),
            const SizedBox(height: 16),
            Text(
              'Vuoi cambiare menu?',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'L\'IA analizzerà i tuoi macro e creerà una nuova opzione nutrizionalmente bilanciata per questo pasto.',
              textAlign: TextAlign.center,
              style: TextStyle(color: CleanTheme.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('Annulla'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Capture objects before async gap
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final provider = Provider.of<NutritionCoachProvider>(
                        context,
                        listen: false,
                      );

                      Navigator.pop(ctx);

                      // Check Quota
                      final quotaProvider = context.read<QuotaProvider>();
                      final checkResult = await quotaProvider.canPerform(
                        QuotaAction.changeMeal,
                      );

                      if (!checkResult.canPerform) {
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PaywallScreen(),
                            ),
                          );
                        }
                        return;
                      }

                      final alternatives = await provider.regenerateMeal(
                        dayIndex: dayIndex,
                        mealIndex: mealIndex,
                        weekIndex: _currentWeekIndex,
                      );

                      if (alternatives.isNotEmpty) {
                        await quotaProvider.syncAfterSuccess(
                          QuotaAction.changeMeal,
                        );
                      }

                      if (alternatives.isEmpty && context.mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              provider.error ??
                                  'Impossibile generare alternative. Riprova.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else if (context.mounted) {
                        _showMealAlternativesSheet(
                          context,
                          alternatives,
                          dayIndex,
                          mealIndex,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CleanTheme.accentGold,
                      padding: const EdgeInsets.all(16),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Sorprendimi ✨',
                      style: TextStyle(color: CleanTheme.primaryColor),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMealAlternativesSheet(
    BuildContext context,
    List<dynamic> alternatives,
    int dayIndex,
    int mealIndex,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: CleanTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Header indicator
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CleanTheme.borderPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: CleanTheme.accentGold.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: CleanTheme.accentGold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scegli il tuo Menù',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: CleanTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '3 opzioni bilanciate per te',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: CleanTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: alternatives.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final alt = alternatives[index];
                    final foods = alt['foods'] as List;

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: CleanTheme.borderPrimary),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  alt['name'] ?? 'Opzione ${index + 1}',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: CleanTheme.textPrimary,
                                  ),
                                ),
                              ),
                              _buildAltBadge(foods),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...foods.map(
                            (food) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: CleanTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${food['name']} (${food['quantity']}${food['unit']})',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: CleanTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final isPermanent = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: CleanTheme.surfaceColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    title: Text(
                                      'Applica Menù',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: CleanTheme.textPrimary,
                                      ),
                                    ),
                                    content: Text(
                                      '"Solo Oggi" applica il menù temporaneamente.\n"Per Sempre" rimpiazza definitivamente questo pasto nel piano.',
                                      style: GoogleFonts.inter(
                                        color: CleanTheme.textSecondary,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: Text(
                                          'SOLO OGGI',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            color: CleanTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: Text(
                                          'PER SEMPRE',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            color: CleanTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (isPermanent == null) {
                                  return; // User cancelled
                                }

                                if (!context.mounted) return;
                                final scaffoldMessenger = ScaffoldMessenger.of(
                                  context,
                                );
                                final provider =
                                    Provider.of<NutritionCoachProvider>(
                                      context,
                                      listen: false,
                                    );

                                Navigator.pop(context);

                                final success = await provider
                                    .applyRegeneratedMeal(
                                      dayIndex: dayIndex,
                                      mealIndex: mealIndex,
                                      newMeal: alt,
                                      isPermanent: isPermanent,
                                      weekIndex: _currentWeekIndex,
                                    );

                                if (!success && mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Errore nell\'applicazione del menu.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } else if (success && mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isPermanent
                                            ? 'Menù applicato permanentemente! ✨'
                                            : 'Menù applicato! Tornerà normale domani. 🧊',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      backgroundColor: CleanTheme.accentGreen,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CleanTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const Text('Seleziona questo Menù'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAltBadge(List foods) {
    int kcal = 0;
    for (var f in foods) {
      kcal += (f['calories'] as num?)?.toInt() ?? 0;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: CleanTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$kcal kcal',
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: CleanTheme.primaryColor,
        ),
      ),
    );
  }

  void _showSubstitutionModal(
    BuildContext context,
    Map<String, dynamic> food,
    int day,
    int meal,
    int foodIdx,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => _SubstitutionSheet(
          food: food,
          dayIndex: day,
          mealIndex: meal,
          foodIndex: foodIdx,
          weekIndex: _currentWeekIndex,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showEquivalenceCalculator(
    BuildContext context,
    Map<String, dynamic> food,
    int dayIndex,
    int mealIndex,
    int foodIndex,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => _EquivalenceCalculatorSheet(
          food: food,
          dayIndex: dayIndex,
          mealIndex: mealIndex,
          foodIndex: foodIndex,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showRestorePlanDialog(
    BuildContext context,
    NutritionCoachProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Ripristina Piano Originale',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: CleanTheme.textPrimary,
          ),
        ),
        content: Text(
          'Vuoi eliminare tutte le sostituzioni (sia effimere che permanenti) e ripristinare il piano calcolato inizialmente dall\'AI?',
          style: GoogleFonts.inter(color: CleanTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Annulla',
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CleanTheme.accentOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.restoreOriginalPlan();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Piano ripristinato con successo! ♻️',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: CleanTheme.accentGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Ripristina'),
          ),
        ],
      ),
    );
  }
}

class _SubstitutionSheet extends StatefulWidget {
  final Map<String, dynamic> food;
  final int dayIndex;
  final int mealIndex;
  final int foodIndex;
  final int weekIndex;
  final ScrollController scrollController;

  const _SubstitutionSheet({
    required this.food,
    required this.dayIndex,
    required this.mealIndex,
    required this.foodIndex,
    required this.weekIndex,
    required this.scrollController,
  });

  @override
  State<_SubstitutionSheet> createState() => _SubstitutionSheetState();
}

class _SubstitutionSheetState extends State<_SubstitutionSheet> {
  late Future<List<dynamic>> _substitutesFuture;

  @override
  void initState() {
    super.initState();
    final nutritionProvider = Provider.of<NutritionCoachProvider>(
      context,
      listen: false,
    );
    final quotaProvider = Provider.of<QuotaProvider>(context, listen: false);
    _substitutesFuture = nutritionProvider
        .findSubstitutes(
          widget.food['name'],
          (widget.food['quantity'] as num).toDouble(),
          widget.food['unit'],
        )
        .then((substitutes) async {
          if (substitutes.isNotEmpty) {
            await quotaProvider.syncAfterSuccess(QuotaAction.changeFood);
          }
          return substitutes;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CleanTheme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sostituzioni Smart ✨',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CleanTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            'Alternative bilanciate per ${widget.food['name']}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CleanTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _substitutesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: CleanTheme.textSecondary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nessuna alternativa trovata.',
                          style: GoogleFonts.inter(
                            color: CleanTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  controller: widget.scrollController,
                  itemCount: snapshot.data!.length,
                  physics: const BouncingScrollPhysics(),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = snapshot.data![index];
                    return Container(
                      decoration: BoxDecoration(
                        color: CleanTheme.chromeSubtle.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: CleanTheme.borderPrimary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: CleanTheme.accentGreen.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: CleanTheme.accentGreen,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item['food_name'],
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: CleanTheme.textPrimary,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Text(
                                '${item['calories']} kcal',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: CleanTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(
                                  color: CleanTheme.textSecondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${item['quantity']}${item['unit']}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: CleanTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CleanTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            // Capture provider before async gap
                            final provider =
                                Provider.of<NutritionCoachProvider>(
                                  context,
                                  listen: false,
                                );

                            // Check Quota
                            final checkResult = await context
                                .read<QuotaProvider>()
                                .canPerform(QuotaAction.changeFood);

                            if (!checkResult.canPerform) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PaywallScreen(),
                                  ),
                                );
                              }
                              return;
                            }

                            if (!context.mounted) return;
                            final isPermanent = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: CleanTheme.surfaceColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Text(
                                  'Applica Sostituzione',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: CleanTheme.textPrimary,
                                  ),
                                ),
                                content: Text(
                                  '"Solo Oggi" mantiene la dieta originale da domani.\n"Per Sempre" aggiorna il tuo piano in modo definitivo.',
                                  style: GoogleFonts.inter(
                                    color: CleanTheme.textSecondary,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(
                                      'SOLO OGGI',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        color: CleanTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(
                                      'PER SEMPRE',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        color: CleanTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (isPermanent == null) return; // User cancelled

                            if (context.mounted) {
                              Navigator.pop(context);
                            }

                            final success = await provider.applySubstitution(
                              dayIndex: widget.dayIndex,
                              mealIndex: widget.mealIndex,
                              foodIndex: widget.foodIndex,
                              isPermanent: isPermanent,
                              newFood: {
                                'name': item['food_name'] ?? item['name'],
                                'quantity': item['quantity'],
                                'unit': item['unit'] ?? 'g',
                                'calories': item['calories'],
                                'proteins': item['proteins'],
                                'carbs': item['carbs'],
                                'fats': item['fats'],
                              },
                              weekIndex: widget.weekIndex,
                            );

                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isPermanent
                                        ? 'Sostituzione applicata permanentemente! ✨'
                                        : 'Sostituzione applicata! Tornerà normale domani. 🧊',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  backgroundColor: CleanTheme.accentGreen,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: const Text('Scegli'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EQUIVALENCE CALCULATOR SHEET
// =============================================================================

class _EquivalenceCalculatorSheet extends StatefulWidget {
  final Map<String, dynamic> food;
  final int dayIndex;
  final int mealIndex;
  final int foodIndex;
  final ScrollController scrollController;

  const _EquivalenceCalculatorSheet({
    required this.food,
    required this.dayIndex,
    required this.mealIndex,
    required this.foodIndex,
    required this.scrollController,
  });

  @override
  State<_EquivalenceCalculatorSheet> createState() =>
      _EquivalenceCalculatorSheetState();
}

class _EquivalenceCalculatorSheetState
    extends State<_EquivalenceCalculatorSheet>
    with TickerProviderStateMixin {
  final _foodController = TextEditingController();
  String _mode = 'kcal';
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  late AnimationController _gaugeController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _iconSpinController;

  @override
  void initState() {
    super.initState();
    _gaugeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 12,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);
    _iconSpinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _foodController.dispose();
    _gaugeController.dispose();
    _shakeController.dispose();
    _iconSpinController.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    final foodName = _foodController.text.trim();
    if (foodName.isEmpty) return;

    setState(() {
      _isLoading = true;
      _result = null;
    });
    _iconSpinController.repeat();

    final provider = Provider.of<NutritionCoachProvider>(
      context,
      listen: false,
    );
    final result = await provider.calculateEquivalence(
      targetFood: {
        'name': widget.food['name'] ?? 'Alimento',
        'quantity': (widget.food['quantity'] as num?)?.toDouble() ?? 100.0,
        'calories': (widget.food['calories'] as num?)?.toInt() ?? 0,
        'proteins': (widget.food['proteins'] as num?)?.toDouble() ?? 0.0,
        'carbs': (widget.food['carbs'] as num?)?.toDouble() ?? 0.0,
        'fats': (widget.food['fats'] as num?)?.toDouble() ?? 0.0,
      },
      userFoodName: foodName,
      mode: _mode,
    );

    _iconSpinController.stop();
    _iconSpinController.reset();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _result = result;
    });

    if (result['is_valid'] == true) {
      _gaugeController.forward(from: 0);
    } else {
      _shakeController.forward(from: 0);
    }
  }

  Future<void> _applySubstitution(bool isPermanent) async {
    if (_result == null || _result!['is_valid'] != true) return;

    setState(() => _isLoading = true);

    final provider = Provider.of<NutritionCoachProvider>(
      context,
      listen: false,
    );
    final success = await provider.applySubstitution(
      dayIndex: widget.dayIndex,
      mealIndex: widget.mealIndex,
      foodIndex: widget.foodIndex,
      isPermanent: isPermanent,
      newFood: {
        'name': _result!['equivalent_portion']['name'],
        'quantity': _result!['equivalent_portion']['quantity'],
        'unit': 'g',
        'calories': _result!['equivalent_portion']['kcal'],
        'proteins': _result!['equivalent_portion']['proteins'],
        'carbs': _result!['equivalent_portion']['carbs'],
        'fats': _result!['equivalent_portion']['fats'],
      },
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPermanent
                  ? 'Sostituzione applicata permanentemente! ✨'
                  : 'Sostituzione applicata! Tornerà normale domani. 🧊',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: CleanTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore nell\'applicazione della sostituzione.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CleanTheme.borderPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                RotationTransition(
                  turns: _iconSpinController,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CleanTheme.accentBlue.withValues(alpha: 0.15),
                          CleanTheme.accentGreen.withValues(alpha: 0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.compare_arrows_rounded,
                      color: CleanTheme.accentBlue,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Swap 🧊',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: CleanTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${widget.food['name']} • ${widget.food['quantity']}${widget.food['unit'] ?? 'g'}',
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
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          // Content
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                // Search Input
                Container(
                  decoration: BoxDecoration(
                    color: CleanTheme.chromeSubtle.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CleanTheme.borderPrimary),
                  ),
                  child: TextField(
                    controller: _foodController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _calculate(),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: CleanTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cosa hai in dispensa?',
                      hintStyle: GoogleFonts.inter(
                        color: CleanTheme.textSecondary.withValues(alpha: 0.5),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: CleanTheme.accentBlue,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Mode Toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: CleanTheme.chromeSubtle.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _buildModeTab('kcal', 'Per Calorie ⚡', _mode == 'kcal'),
                      _buildModeTab(
                        'protein',
                        'Per Proteine 💪',
                        _mode == 'protein',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Mode Explanation
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _mode == 'kcal'
                          ? 'L\'AI calcola quanti grammi del nuovo alimento servono per avere esattamente le stesse calorie della porzione originale.'
                          : 'L\'AI ignora le calorie totali e calcola quanti grammi del nuovo alimento servono per pareggiare i grammi di proteine.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: CleanTheme.textSecondary.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Calculate Button
                GestureDetector(
                  onTap: _isLoading ? null : _calculate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isLoading
                            ? [CleanTheme.steelMid, CleanTheme.steelMid]
                            : [CleanTheme.steelDark, CleanTheme.primaryColor],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isLoading
                          ? null
                          : [
                              BoxShadow(
                                color: CleanTheme.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        const SizedBox(width: 10),
                        Text(
                          _isLoading
                              ? 'Calcolo in corso...'
                              : 'Calcola Equivalenza',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Results
                if (_result != null) ...[
                  const SizedBox(height: 24),
                  if (_result!['is_valid'] == true)
                    _buildValidResult()
                  else
                    _buildInvalidResult(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String value, String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? CleanTheme.surfaceColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? CleanTheme.textPrimary
                  : CleanTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValidResult() {
    final score = (_result!['compatibility_score'] as num?)?.toDouble() ?? 0;

    return Column(
      children: [
        FoodScaleWidget(
          originalFood: _result!['target_portion'],
          substituteFood: _result!['equivalent_portion'],
          score: score,
        ),
        const SizedBox(height: 32),
        // Action Buttons Row
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _isLoading ? null : () => _applySubstitution(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: CleanTheme.accentOrange,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'SOLO OGGI',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CleanTheme.accentOrange,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _isLoading ? null : () => _applySubstitution(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        CleanTheme.accentOrange,
                        const Color(0xFFFF7A00),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: CleanTheme.accentOrange.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'PER SEMPRE',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            '"Per Sempre" cambierà il piano originale.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CleanTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvalidResult() {
    final message =
        _result!['validation_message'] as String? ??
        'Alimento non riconosciuto.';
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(sin(_shakeAnimation.value * pi * 2) * 6, 0),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Text('🤔', style: TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 16),
            Text(
              'Hmm...',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: CleanTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Prova con un alimento vero! 🍕',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CleanTheme.accentOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
