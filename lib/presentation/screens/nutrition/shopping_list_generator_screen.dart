import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/nutrition_coach_provider.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  int _days = 3;

  // Simple keyword-based categorization
  String _getCategory(String name) {
    name = name.toLowerCase();
    if (name.contains('mela') ||
        name.contains('banana') ||
        name.contains('verdura') ||
        name.contains('insalata') ||
        name.contains('pomodoro')) {
      return 'Frutta e Verdura';
    }
    if (name.contains('pollo') ||
        name.contains('manzo') ||
        name.contains('pesce') ||
        name.contains('uova') ||
        name.contains('tonno')) {
      return 'Carne e Pesce';
    }
    if (name.contains('latte') ||
        name.contains('yogurt') ||
        name.contains('formaggio')) {
      return 'Latticini';
    }
    if (name.contains('pasta') ||
        name.contains('riso') ||
        name.contains('pane') ||
        name.contains('cereali')) {
      return 'Cereali e Dispensa';
    }
    return 'Altro';
  }

  Map<String, List<dynamic>> _groupItems(List<dynamic> items) {
    final Map<String, List<dynamic>> grouped = {};
    for (var item in items) {
      final category = _getCategory(item['name']);
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(item);
    }
    return grouped;
  }

  void _shareList(List<dynamic> items) {
    if (items.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('🛒 Lista della Spesa (GiGi Coach)');
    buffer.writeln('Per $_days giorni\n');

    final grouped = _groupItems(items);
    grouped.forEach((category, list) {
      buffer.writeln('📍 $category');
      for (var item in list) {
        buffer.writeln(
          '- [ ] ${item['name']} (${item['quantity']} ${item['unit']})',
        );
      }
      buffer.writeln('');
    });

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lista copiata negli appunti!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NutritionCoachProvider>(context);
    final groupedItems = _groupItems(provider.shoppingList);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lista della Spesa',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: provider.shoppingList.isNotEmpty
                ? () => _shareList(provider.shoppingList)
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Genera lista per:',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Theme.of(context).primaryColor,
                          inactiveTrackColor: Colors.grey[200],
                          thumbColor: Theme.of(context).primaryColor,
                          overlayColor: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.2),
                        ),
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
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_days Giorni',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () => provider.generateShoppingList(_days),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Genera Lista'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.shoppingList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Genera la lista per iniziare',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: groupedItems.length,
                    itemBuilder: (context, index) {
                      final category = groupedItems.keys.elementAt(index);
                      final items = groupedItems[category]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 4,
                            ),
                            child: Text(
                              category.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: items.map((item) {
                                return CheckboxListTile(
                                  value: false,
                                  onChanged: (val) {},
                                  activeColor: Theme.of(context).primaryColor,
                                  title: Text(
                                    item['name'],
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${item['quantity']} ${item['unit']}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  secondary: _getCategoryIcon(category),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _getCategoryIcon(String category) {
    IconData icon;
    Color color;

    switch (category) {
      case 'Frutta e Verdura':
        icon = Icons.eco;
        color = Colors.green;
        break;
      case 'Carne e Pesce':
        icon = Icons.restaurant;
        color = Colors.redAccent;
        break;
      case 'Latticini':
        icon = Icons.egg;
        color = Colors.orangeAccent;
        break;
      case 'Cereali e Dispensa':
        icon = Icons.breakfast_dining;
        color = Colors.brown;
        break;
      default:
        icon = Icons.local_grocery_store;
        color = Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
