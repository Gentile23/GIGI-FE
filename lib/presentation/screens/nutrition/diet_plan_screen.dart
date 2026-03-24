import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/nutrition_coach_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../paywall/paywall_screen.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/services/quota_service.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/animations/liquid_steel_container.dart';

class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({super.key});

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  int _currentWeekIndex = 0;

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
          _tabController?.dispose();
          _tabController = TabController(
            length: days.length,
            vsync: this,
            initialIndex: todayIndex.clamp(0, days.length - 1),
          );
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
                              margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: isSelected ? CleanTheme.steelDark : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? CleanTheme.steelDark : CleanTheme.borderPrimary,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'SETTIMANA ${index + 1}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : CleanTheme.textSecondary,
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
                        final dayName = day['day_name'] ?? 'Giorno ${index + 1}';
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
                                        color: CleanTheme.primaryColor.withValues(
                                          alpha: 0.1,
                                        ),
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
        if (day['daily_notes'] != null && day['daily_notes'].toString().isNotEmpty) ...[
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
    if (food['proteins'] == null && food['carbs'] == null && food['fats'] == null) {
      return const SizedBox.shrink();
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _buildMinimalMacro('P', '${(food['proteins'] ?? 0)}g', CleanTheme.accentGreen),
        _buildMinimalMacro('C', '${(food['carbs'] ?? 0)}g', CleanTheme.accentGold),
        _buildMinimalMacro('F', '${(food['fats'] ?? 0)}g', CleanTheme.accentBlue),
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
        border: Border.all(color: CleanTheme.borderPrimary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sticky_note_2_outlined, size: 14, color: CleanTheme.textSecondary),
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

        // If it's an alternative, only count it if we haven't counted this group yet
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

    return LiquidSteelContainer(
      borderRadius: 24,
      enableShine: true,
      colors: const [
        CleanTheme.steelDark,
        CleanTheme.steelMid,
        CleanTheme.steelLight,
        CleanTheme.steelMid,
        CleanTheme.steelDark,
      ],
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: CleanTheme.textOnDark,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'OBIETTIVI GIORNALIERI',
                  style: GoogleFonts.outfit(
                    color: CleanTheme.textOnDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
    );
  }

  Widget _buildMacroItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color.withValues(alpha: 0.6), size: 16),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: CleanTheme.textOnDark.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CleanTheme.borderPrimary, width: 1),
        boxShadow: [
          BoxShadow(
            color: CleanTheme.primaryColor.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CleanTheme.primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        mealIcon,
                        size: 24,
                        color: CleanTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (meal['time'] != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                meal['time'].toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: CleanTheme.accentOrange,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          Text(
                            mealType,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: CleanTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildMealKcalBadge(meal),
                  ],
                ),
                if (meal['meal_notes'] != null && meal['meal_notes'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, left: 4),
                    child: Text(
                      meal['meal_notes'],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _buildMealMacroRow(meal),
              ],
            ),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          // Food Items
          ..._buildFoodItems(
            context,
            meal['foods'] as List,
            dayIndex,
            mealIndex,
          ),
          const SizedBox(height: 8),
          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20),
                  color: CleanTheme.textSecondary,
                  onPressed: () => _shareMeal(meal),
                ),
                const SizedBox(width: 4),
                _buildMagicRegenerateButton(context, dayIndex, mealIndex),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: CleanTheme.primaryColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$totalKcal KCAL',
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
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

    return Row(
      children: [
        _buildTinyMacroIndicator('P', '${p.toInt()}g', CleanTheme.accentGreen),
        const SizedBox(width: 12),
        _buildTinyMacroIndicator('C', '${c.toInt()}g', CleanTheme.accentGold),
        const SizedBox(width: 12),
        _buildTinyMacroIndicator('F', '${f.toInt()}g', CleanTheme.accentBlue),
      ],
    );
  }

  Widget _buildTinyMacroIndicator(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: CleanTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: CleanTheme.textPrimary,
          ),
        ),
      ],
    );
  }  Widget _buildMagicRegenerateButton(BuildContext context, int dayIndex, int mealIndex) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CleanTheme.accentGold.withValues(alpha: 0.15),
            CleanTheme.accentGold.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CleanTheme.accentGold.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: CleanTheme.accentGold.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final quotaService = QuotaService();
            final checkResult = await quotaService.checkAndRecord(
              QuotaAction.changeMeal,
            );

            if (!checkResult.canPerform && context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PaywallScreen(),
                ),
              );
            } else if (checkResult.canPerform && context.mounted) {
              _showPremiumRegenerateDialog(context, dayIndex, mealIndex);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: CleanTheme.accentGold,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cambia Menù ✨',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: CleanTheme.primaryColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isAlternative ? CleanTheme.accentOrange.withValues(alpha: 0.03) : null,
              border: entry.key < foods.length - 1
                  ? Border(
                      bottom: BorderSide(color: CleanTheme.borderPrimary, width: 1),
                    )
                  : null,
            ),
            child: Row(
              children: [
                if (isAlternative)
                  const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.alt_route_rounded,
                      size: 18,
                      color: CleanTheme.accentOrange,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food['name'] ?? 'Alimento',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: CleanTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if ((food['quantity'] ?? '').toString().isNotEmpty || (food['unit'] ?? '').toString().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: CleanTheme.chromeSubtle,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${food['quantity'] ?? ''}${food['unit'] ?? ''}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: CleanTheme.textPrimary,
                                ),
                              ),
                            ),
                          if (food['calories'] != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '• ${food['calories']} kcal',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: CleanTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Individual Food Macros
                      _buildFoodMacroRow(food),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    color: CleanTheme.primaryColor.withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CleanTheme.primaryColor.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () async {
                        final quotaService = QuotaService();
                        final checkResult = await quotaService.checkAndRecord(
                          QuotaAction.changeFood,
                        );

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
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Icon(
                          Icons.auto_fix_high_rounded,
                          size: 18,
                          color: CleanTheme.primaryColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }



  void _shareMeal(Map<String, dynamic> meal) {
    final buffer = StringBuffer();
    buffer.writeln('🍽️ *${meal['type']}*');

    final foods = meal['foods'] as List;
    for (var food in foods) {
      buffer.writeln('• ${food['name']} (${food['quantity']}${food['unit']})');
    }

    // Add nutrients if available
    // buffer.writeln('\n🔥 ${meal['calories']} kcal');

    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  void _shareDay(Map<String, dynamic> day) {
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

    SharePlus.instance.share(ShareParams(text: buffer.toString()));
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
                      final quotaService = QuotaService();
                      final checkResult = await quotaService.checkAndRecord(
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
                      );

                      if (alternatives.isEmpty && mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(provider.error ?? 'Impossibile generare alternative. Riprova.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else if (mounted) {
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
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
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
                          ...foods.map((food) => Padding(
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
                          )),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final scaffoldMessenger = ScaffoldMessenger.of(context);
                                final provider = Provider.of<NutritionCoachProvider>(
                                  context,
                                  listen: false,
                                );
                                
                                Navigator.pop(ctx);
                                
                                final success = await provider.applyRegeneratedMeal(
                                  dayIndex: dayIndex,
                                  mealIndex: mealIndex,
                                  newMeal: alt,
                                );
                                
                                if (!success && mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Errore nell\'applicazione del menu.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CleanTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
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
          scrollController: scrollController,
        ),
      ),
    );
  }

}

class _SubstitutionSheet extends StatefulWidget {
  final Map<String, dynamic> food;
  final int dayIndex;
  final int mealIndex;
  final int foodIndex;
  final ScrollController scrollController;

  const _SubstitutionSheet({
    required this.food,
    required this.dayIndex,
    required this.mealIndex,
    required this.foodIndex,
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
    _substitutesFuture =
        Provider.of<NutritionCoachProvider>(
          context,
          listen: false,
        ).findSubstitutes(
          widget.food['name'],
          (widget.food['quantity'] as num).toDouble(),
          widget.food['unit'],
        );
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
            'Alternative a ${widget.food['name']}',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _substitutesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Nessuna alternativa trovata.'),
                  );
                }

                return ListView.separated(
                  controller: widget.scrollController,
                  itemCount: snapshot.data!.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = snapshot.data![index];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: CleanTheme.accentGreen,
                        child: Icon(Icons.check, color: CleanTheme.textOnDark),
                      ),
                      title: Text(
                        item['food_name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${item['calories']} kcal • ${item['quantity']}${item['unit']}',
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CleanTheme.primaryColor,
                          foregroundColor: CleanTheme.textOnPrimary,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () async {
                          // Capture provider before async gap
                          final provider = Provider.of<NutritionCoachProvider>(
                            context,
                            listen: false,
                          );

                          // Check Quota
                          final quotaService = QuotaService();
                          final checkResult = await quotaService.checkAndRecord(
                            QuotaAction.changeFood, // Fixed typo
                          );

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

                          if (context.mounted) {
                            Navigator.pop(context);
                          }

                          provider.applySubstitution(
                            dayIndex: widget.dayIndex,
                            mealIndex: widget.mealIndex,
                            foodIndex: widget.foodIndex,
                            newFood: item,
                          );
                        },
                        child: const Text('Scegli'),
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
