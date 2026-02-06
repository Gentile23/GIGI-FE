import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/nutrition_coach_provider.dart';
// import '../../widgets/clean_widgets.dart'; // Assuming this exists or standard widgets
// If CleanWidgets doesn't exist, I'll stick to standard material/google fonts
// Re-adding imports based on previous file context
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({super.key});

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;

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
            backgroundColor: const Color(0xFFF5F5F7),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Il Tuo Piano Personalizzato',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
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
                          colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withValues(alpha: 0.3),
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
                        color: Colors.black,
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
                        color: Colors.grey[600],
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF8B5CF6,
                              ).withValues(alpha: 0.4),
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
                                color: Colors.white,
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
                          color: Color(0xFFF59E0B),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Analisi AI in pochi secondi',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFF59E0B),
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
                    color: Colors.orange,
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
                    color: Colors.grey,
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

        final days = weeks[0]['days'] as List;
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
          backgroundColor: const Color(0xFFF5F5F7), // CleanTheme primaryLight
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              provider.activePlan!['name'] ?? 'Il Tuo Piano',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.black),
                tooltip: 'Condividi',
                onPressed: () {
                  final currentDay = days[_tabController!.index];
                  _shareDay(currentDay);
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.black,
                ),
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed('/nutrition/coach/shopping-list'),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                _showAddExtraMealDialog(context, _tabController!.index),
            label: Text(
              'Pasto Extra',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
            icon: const Icon(Icons.add),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
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
                          color: isSelected ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isSelected
                                ? Colors.black
                                : const Color(0xFFE5E5EA),
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
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
                              color: isSelected ? Colors.white : Colors.black,
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
              // Loading Overlay
              if (provider.isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            'L\'IA sta elaborando...',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
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
        const SizedBox(height: 12),
        // Meals
        ...meals.asMap().entries.map((entry) {
          return _buildMealCard(context, entry.value, dayIndex, entry.key);
        }),
      ],
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
      for (var food in foods) {
        totalKcal += (food['calories'] as num?)?.toInt() ?? 0;
        totalProteins += (food['proteins'] as num?)?.toDouble() ?? 0;
        totalCarbs += (food['carbs'] as num?)?.toDouble() ?? 0;
        totalFats += (food['fats'] as num?)?.toDouble() ?? 0;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.black, Colors.black.withValues(alpha: 0.85)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Macros del Giorno',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroItem(
                'kcal',
                totalKcal.toString(),
                const Color(0xFFFF6B6B),
              ),
              _buildMacroItem(
                'Prot',
                '${totalProteins.toInt()}g',
                const Color(0xFF4ECDC4),
              ),
              _buildMacroItem(
                'Carb',
                '${totalCarbs.toInt()}g',
                const Color(0xFFFFE66D),
              ),
              _buildMacroItem(
                'Fat',
                '${totalFats.toInt()}g',
                const Color(0xFFA78BFA),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            value,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E5EA), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(mealIcon, size: 22, color: Colors.black),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    mealType,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20),
                  color: const Color(0xFF8E8E93),
                  onPressed: () => _shareMeal(meal),
                ),
                IconButton(
                  icon: const Icon(Icons.auto_awesome, size: 20),
                  color: Colors.amber,
                  tooltip: 'Rigenera con IA',
                  onPressed: () => _showPremiumRegenerateDialog(
                    context,
                    dayIndex,
                    mealIndex,
                  ),
                ),
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
          const SizedBox(height: 8),
        ],
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
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: entry.key < foods.length - 1
              ? const Border(
                  bottom: BorderSide(color: Color(0xFFF5F5F7), width: 1),
                )
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food['name'] ?? 'Alimento',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Tappable quantity
                      GestureDetector(
                        onTap: () => _showEditQuantityDialog(
                          context,
                          food,
                          dayIndex,
                          mealIndex,
                          foodIndex,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${food['quantity'] ?? ''}${food['unit'] ?? ''}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.edit_outlined,
                                size: 14,
                                color: Color(0xFF8E8E93),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (food['calories'] != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          '${food['calories']} kcal',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFFC7C7CC),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded, size: 22),
              color: Colors.black,
              tooltip: 'Sostituisci',
              onPressed: () => _showSubstitutionModal(
                context,
                food,
                dayIndex,
                mealIndex,
                foodIndex,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _showEditQuantityDialog(
    BuildContext context,
    Map<String, dynamic> food,
    int dayIndex,
    int mealIndex,
    int foodIndex,
  ) {
    final currentQty = (food['quantity'] as num?)?.toDouble() ?? 0;
    final unit = food['unit'] ?? 'g';
    final controller = TextEditingController(
      text: currentQty.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Modifica Quantità',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              food['name'] ?? 'Alimento',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: InputDecoration(
                suffixText: unit,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                labelText: 'Nuova quantità',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final newQty = double.tryParse(controller.text);
              if (newQty == null || newQty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Inserisci un valore valido')),
                );
                return;
              }
              Navigator.pop(ctx);

              final provider = Provider.of<NutritionCoachProvider>(
                context,
                listen: false,
              );
              final success = await provider.updateFoodQuantity(
                dayIndex: dayIndex,
                mealIndex: mealIndex,
                foodIndex: foodIndex,
                quantity: newQty,
              );

              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Errore nell\'aggiornamento')),
                );
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 48, color: Colors.amber),
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
              style: TextStyle(color: Colors.grey, fontSize: 16),
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
                      Navigator.pop(ctx);
                      // Capture scaffold messenger before async gap
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      // Trigger Provider
                      final provider = Provider.of<NutritionCoachProvider>(
                        context,
                        listen: false,
                      );
                      final success = await provider.regenerateMeal(
                        dayIndex: dayIndex,
                        mealIndex: mealIndex,
                      );

                      if (!success && mounted) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(provider.error ?? 'Errore'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.all(16),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Sorprendimi ✨',
                      style: TextStyle(color: Colors.black),
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

  void _showAddExtraMealDialog(BuildContext context, int dayIndex) {
    final nameController = TextEditingController();
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aggiungi Pasto Extra'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Le calorie dei pasti successivi verranno ricalcolate.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Cosa mangi?'),
            ),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(labelText: 'Grammi'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = Provider.of<NutritionCoachProvider>(
                context,
                listen: false,
              );
              await provider.addExtraMeal(
                dayIndex: dayIndex,
                foodName: nameController.text,
                quantity: double.tryParse(qtyController.text) ?? 100,
                unit: 'g',
              );
            },
            child: const Text('Aggiungi'),
          ),
        ],
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
      decoration: const BoxDecoration(
        color: Colors.white,
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
                        backgroundColor: Colors.greenAccent,
                        child: Icon(Icons.check, color: Colors.white),
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
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Provider.of<NutritionCoachProvider>(
                            context,
                            listen: false,
                          ).applySubstitution(
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
