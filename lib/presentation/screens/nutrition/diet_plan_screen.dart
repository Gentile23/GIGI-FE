import 'package:flutter/material.dart';
import '../../../data/services/nutrition_coach_service.dart';

class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({super.key});

  @override
  State<DietPlanScreen> createState() => _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen>
    with SingleTickerProviderStateMixin {
  final NutritionCoachService _service = NutritionCoachService();
  bool _isLoading = true;
  Map<String, dynamic>? _plan;
  late TabController _tabController;
  List<dynamic> _days = [];

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    try {
      final response = await _service.getActivePlan();
      if (response['success'] == true) {
        final planData = response['plan']['content'];
        // Flatten weeks logic for simplicity - just take first week's days
        final weeks = planData['weeks'] as List;
        if (weeks.isNotEmpty) {
          _days = weeks[0]['days'];
        }

        setState(() {
          _plan = response['plan'];
          _isLoading = false;
          _tabController = TabController(length: _days.length, vsync: this);
        });
      } else {
        // No plan found or error
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSubstitutionModal(
    String foodName,
    num quantity,
    String unit,
    int dayIndex,
    int mealIndex,
    int foodIndex,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SubstitutionModal(
        foodName: foodName,
        quantity: quantity.toDouble(),
        unit: unit,
        service: _service,
        onApply: (newFood) async {
          Navigator.pop(context); // Close modal
          setState(() => _isLoading = true);
          try {
            final success = await _service.applySubstitution(
              planId: _plan!['id'],
              dayIndex: dayIndex,
              mealIndex: mealIndex,
              foodIndex: foodIndex,
              newFood: newFood,
            );
            if (success) {
              await _loadPlan(); // Reload to show changes
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sostituzione applicata!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Errore: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } finally {
            setState(() => _isLoading = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_plan == null || _days.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Il mio Piano')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Nessuna dieta attiva trovata'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/nutrition/coach/upload'),
                child: const Text('Carica Dieta PDF'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_plan!['name'] ?? 'Dieta'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _days.map((day) => Tab(text: day['day_name'])).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.of(
              context,
            ).pushNamed('/nutrition/coach/shopping-list'),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: _days
            .asMap()
            .entries
            .map((entry) => _buildDayView(entry.value, entry.key))
            .toList(),
      ),
    );
  }

  Widget _buildDayView(Map<String, dynamic> day, int dayIndex) {
    final meals = day['meals'] as List;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: meals.length,
      itemBuilder: (context, mealIndex) {
        final meal = meals[mealIndex];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(
                  meal['type'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                tileColor: Colors.grey[100],
              ),
              ..._buildFoodItems(meal['foods'] as List, dayIndex, mealIndex),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildFoodItems(List foods, int dayIndex, int mealIndex) {
    return foods.asMap().entries.map((entry) {
      final foodIndex = entry.key;
      final food = entry.value;
      return ListTile(
        title: Text(food['name']),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${food['quantity']}${food['unit']}'),
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: Colors.blue),
              onPressed: () => _showSubstitutionModal(
                food['name'],
                food['quantity'] ?? 0,
                food['unit'] ?? 'g',
                dayIndex,
                mealIndex,
                foodIndex,
              ),
            ),
          ],
        ),
        subtitle: food['calories'] != null
            ? Text('${food['calories']} kcal')
            : null,
      );
    }).toList();
  }
}

class _SubstitutionModal extends StatefulWidget {
  final String foodName;
  final double quantity;
  final String unit;
  final NutritionCoachService service;
  final Function(Map<String, dynamic>) onApply;

  const _SubstitutionModal({
    required this.foodName,
    required this.quantity,
    required this.unit,
    required this.service,
    required this.onApply,
  });

  @override
  State<_SubstitutionModal> createState() => _SubstitutionModalState();
}

class _SubstitutionModalState extends State<_SubstitutionModal> {
  bool _loading = true;
  List<dynamic> _substitutes = [];

  @override
  void initState() {
    super.initState();
    _fetchSubstitutes();
  }

  Future<void> _fetchSubstitutes() async {
    try {
      final results = await widget.service.findSubstitute(
        widget.foodName,
        widget.quantity,
        widget.unit,
      );
      if (mounted) {
        setState(() {
          _substitutes = results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alternative per: ${widget.foodName}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_substitutes.isEmpty)
            const Text('Nessuna alternativa trovata.')
          else
            Expanded(
              child: ListView.builder(
                itemCount: _substitutes.length,
                itemBuilder: (context, index) {
                  final item = _substitutes[index];
                  return ListTile(
                    leading: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    title: Text(item['food_name']),
                    subtitle: Text(
                      '${item['calories']} kcal - ${item['quantity']}${item['unit']}',
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => widget.onApply(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text(
                        'Sostituisci',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
