import 'package:flutter/material.dart';
import '../../../data/services/nutrition_coach_service.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final NutritionCoachService _service = NutritionCoachService();
  int _days = 3;
  bool _isLoading = false;
  List<dynamic> _shoppingList = [];

  Future<void> _generateList() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final list = await _service.generateShoppingList(_days);
      setState(() {
        _shoppingList = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista della Spesa (Coach)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Per quanti giorni vuoi fare la spesa?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _days.toDouble(),
                            min: 1,
                            max: 7,
                            divisions: 6,
                            label: '$_days Giorni',
                            onChanged: (val) =>
                                setState(() => _days = val.toInt()),
                          ),
                        ),
                        Text('$_days gg'),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _generateList,
                      child: const Text('Genera Lista'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _shoppingList.isEmpty
                ? const Center(child: Text('Genera la lista per iniziare'))
                : ListView.builder(
                    itemCount: _shoppingList.length,
                    itemBuilder: (context, index) {
                      final item = _shoppingList[index];
                      return CheckboxListTile(
                        value: false,
                        onChanged: (val) {},
                        title: Text(item['name']),
                        subtitle: Text('${item['quantity']} ${item['unit']}'),
                        secondary: const Icon(Icons.food_bank),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
