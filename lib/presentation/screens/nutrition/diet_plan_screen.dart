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

        // 2. No Plan State
        if (!provider.hasActivePlan) {
          return Scaffold(
            appBar: AppBar(title: const Text('Il mio Piano')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.no_meals, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Nessuna dieta attiva trovata'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamed('/nutrition/coach/upload'),
                    icon: const Icon(Icons.upload),
                    label: const Text('Carica Dieta PDF'),
                  ),
                ],
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

        // Initialize TabController if needed or if length changed
        // Note: In a real app, week switching would be handled.
        // Here we assume 1 week view for simplicity as per original code.
        final todayIndex = DateTime.now().weekday - 1; // 0=Mon, 6=Sun

        // Ensure controller is valid
        if (_tabController == null || _tabController!.length != days.length) {
          _tabController?.dispose(); // Dispose old one if length changed
          _tabController = TabController(
            length: days.length,
            vsync: this,
            initialIndex: todayIndex.clamp(0, days.length - 1),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              provider.activePlan!['name'] ?? 'Piano Settimanale',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              tabs: days.map((day) => Tab(text: day['day_name'])).toList(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                tooltip: 'Condividi Giornata',
                onPressed: () {
                  // Calculate current day index from tab controller
                  final currentDay = days[_tabController!.index];
                  _shareDay(currentDay);
                },
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed('/nutrition/coach/shopping-list'),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                _showAddExtraMealDialog(context, _tabController!.index),
            label: const Text('Pasto Extra'),
            icon: const Icon(Icons.add),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          body: Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: days.asMap().entries.map((entry) {
                  return _buildDayView(context, entry.value, entry.key);
                }).toList(),
              ),
              if (provider.isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'L\'IA sta elaborando...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Padding for FAB
      itemCount: meals.length,
      itemBuilder: (context, mealIndex) {
        final meal = meals[mealIndex];
        return _buildMealCard(context, meal, dayIndex, mealIndex);
      },
    );
  }

  Widget _buildMealCard(
    BuildContext context,
    Map<String, dynamic> meal,
    int dayIndex,
    int mealIndex,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    meal['type'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: _getMealColor(meal['type']),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.share_outlined,
                        color: Colors.grey,
                      ),
                      tooltip: 'Condividi Pasto',
                      onPressed: () =>
                          _shareMeal(meal), // Updated to use helper
                    ),
                    IconButton(
                      icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                      tooltip: 'Rigenera con IA',
                      onPressed: () => _showPremiumRegenerateDialog(
                        context,
                        dayIndex,
                        mealIndex,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            ..._buildFoodItems(
              context,
              meal['foods'] as List,
              dayIndex,
              mealIndex,
            ),
          ],
        ),
      ),
    );
  }

  Color _getMealColor(String type) {
    switch (type.toLowerCase()) {
      case 'colazione':
        return Colors.orange;
      case 'pranzo':
        return Colors.green;
      case 'cena':
        return Colors.blue;
      case 'spuntino':
        return Colors.purple;
      default:
        return Colors.grey;
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
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          food['name'],
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${food['calories'] ?? 0} kcal',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${food['quantity']}${food['unit']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded, color: Colors.blue),
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
