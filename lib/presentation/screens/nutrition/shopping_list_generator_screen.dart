import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/nutrition_coach_provider.dart';
import '../../screens/paywall/paywall_screen.dart'; // Import PaywallScreen
import '../../../data/services/quota_service.dart'; // Import QuotaService

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  int _days = 3;
  final Set<String> _checkedItems = {};

  // Comprehensive Italian food categorization
  String _getCategory(String name) {
    final lower = name.toLowerCase();

    // Frutta e Verdura
    const fruttaVerdura = [
      'mela',
      'banana',
      'arancia',
      'pera',
      'uva',
      'fragola',
      'kiwi',
      'pesca',
      'albicocca',
      'ciliegia',
      'limone',
      'pompelmo',
      'mandarino',
      'anguria',
      'melone',
      'ananas',
      'mango',
      'frutti di bosco',
      'mirtilli',
      'lamponi',
      'verdura',
      'insalata',
      'pomodoro',
      'carota',
      'zucchina',
      'melanzana',
      'peperone',
      'cetriolo',
      'spinaci',
      'lattuga',
      'rucola',
      'broccoli',
      'cavolfiore',
      'cavolo',
      'verza',
      'finocchio',
      'sedano',
      'cipolla',
      'aglio',
      'porro',
      'asparagi',
      'carciofi',
      'funghi',
      'radicchio',
      'bietola',
      'cicoria',
      'piselli',
      'fagiolini',
      'zucca',
    ];

    // Carne e Pesce
    const carnesPesce = [
      'pollo',
      'petto di pollo',
      'tacchino',
      'petto di tacchino',
      'manzo',
      'macinato',
      'vitello',
      'maiale',
      'agnello',
      'coniglio',
      'bresaola',
      'prosciutto',
      'speck',
      'pancetta',
      'salsiccia',
      'hamburger',
      'bistecca',
      'fettina',
      'arrosto',
      'polpette',
      'salmone',
      'tonno',
      'merluzzo',
      'orata',
      'branzino',
      'sogliola',
      'gamberi',
      'calamari',
      'cozze',
      'vongole',
      'pesce',
      'filetto',
      'coscia',
      'ali',
      'petto',
    ];

    // Latticini e Uova
    const latticini = [
      'latte',
      'yogurt',
      'formaggio',
      'mozzarella',
      'parmigiano',
      'grana',
      'ricotta',
      'stracchino',
      'gorgonzola',
      'pecorino',
      'burrata',
      'feta',
      'philadelphia',
      'mascarpone',
      'uova',
      'uovo',
      'albume',
      'tuorlo',
      'panna',
      'burro',
      'fiocchi di latte',
      'skyr',
      'greco',
    ];

    // Cereali e Carboidrati
    const cereali = [
      'pasta',
      'riso',
      'pane',
      'farro',
      'orzo',
      'quinoa',
      'avena',
      'fiocchi',
      'cereali',
      'muesli',
      'corn flakes',
      'crackers',
      'grissini',
      'fette biscottate',
      'gallette',
      'cous cous',
      'gnocchi',
      'polenta',
      'patate',
      'patata',
      'integrale',
      'pancarrè',
      'focaccia',
      'piadina',
      'tortilla',
      'biscotti',
    ];

    // Legumi e Proteine Vegetali
    const legumi = [
      'ceci',
      'fagioli',
      'lenticchie',
      'piselli secchi',
      'fave',
      'soia',
      'edamame',
      'tofu',
      'tempeh',
      'seitan',
      'hummus',
      'lupini',
    ];

    // Condimenti e Altro
    const condimenti = [
      'olio',
      'evo',
      'extra vergine',
      'aceto',
      'sale',
      'pepe',
      'spezie',
      'salsa',
      'ketchup',
      'maionese',
      'senape',
      'pesto',
      'sugo',
      'miele',
      'marmellata',
      'nutella',
      'burro di arachidi',
      'tahina',
      'semi',
      'noci',
      'mandorle',
      'nocciole',
      'pistacchi',
      'anacardi',
      'arachidi',
      'pinoli',
      'frutta secca',
      'whey',
      'proteine',
      'integratore',
    ];

    for (final keyword in fruttaVerdura) {
      if (lower.contains(keyword)) return '🥗 Frutta e Verdura';
    }
    for (final keyword in carnesPesce) {
      if (lower.contains(keyword)) return '🥩 Carne e Pesce';
    }
    for (final keyword in latticini) {
      if (lower.contains(keyword)) return '🥛 Latticini e Uova';
    }
    for (final keyword in cereali) {
      if (lower.contains(keyword)) return '🍞 Cereali e Carboidrati';
    }
    for (final keyword in legumi) {
      if (lower.contains(keyword)) return '🫘 Legumi e Proteine Vegetali';
    }
    for (final keyword in condimenti) {
      if (lower.contains(keyword)) return '🧂 Condimenti e Altro';
    }

    return '📦 Altro';
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
                        : () async {
                            final quotaService = QuotaService();
                            final checkResult = await quotaService
                                .checkAndRecord(QuotaAction.shoppingList);

                            if (!checkResult.canPerform && context.mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PaywallScreen(),
                                ),
                              );
                            } else if (checkResult.canPerform &&
                                context.mounted) {
                              provider.generateShoppingList(_days);
                            }
                          },
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
                                final itemKey =
                                    '${item['name']}_${item['unit']}';
                                final isChecked = _checkedItems.contains(
                                  itemKey,
                                );

                                return CheckboxListTile(
                                  value: isChecked,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _checkedItems.add(itemKey);
                                      } else {
                                        _checkedItems.remove(itemKey);
                                      }
                                    });
                                  },
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
