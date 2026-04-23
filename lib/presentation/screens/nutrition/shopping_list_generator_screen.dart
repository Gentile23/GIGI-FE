import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/nutrition_coach_provider.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  int _startDay = 1;
  int _endDay = 3;
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

  Future<void> _shareList(List<dynamic> items) async {
    if (items.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('🛒 Lista della Spesa (GiGi Coach)');
    buffer.writeln('Dal Giorno $_startDay al Giorno $_endDay\n');

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

    // ignore: deprecated_member_use
    await Share.share(
      buffer.toString(),
      subject: 'Lista della Spesa Gigi AI',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Menu di condivisione aperto',
            style: GoogleFonts.inter(color: CleanTheme.textOnDark),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: CleanTheme.steelDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NutritionCoachProvider>(context);
    final groupedItems = _groupItems(provider.shoppingList);

    // Dynamically calculate max days from plan (flatten across all weeks)
    final weeks = provider.activePlan?['content']['weeks'] as List?;
    int totalDays = 0;
    if (weeks != null) {
      for (final week in weeks) {
        totalDays += ((week['days'] as List?)?.length ?? 0);
      }
    }
    final double maxDays = (totalDays > 0 ? totalDays : 7).toDouble();

    // Ensure state is within bounds if plan changed
    if (_startDay > maxDays) _startDay = 1;
    if (_endDay > maxDays) _endDay = maxDays.toInt();
    if (_startDay > _endDay) _startDay = 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lista della Spesa',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
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
              color: CleanTheme.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: CleanTheme.primaryColor.withValues(alpha: 0.05),
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
                    color: CleanTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dal Giorno $_startDay al $_endDay',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: CleanTheme.primaryColor,
                      ),
                    ),
                    Text(
                      '${_endDay - _startDay + 1} Giorni',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CleanTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RangeSlider(
                  values: RangeValues(_startDay.toDouble(), _endDay.toDouble()),
                  min: 1,
                  max: maxDays,
                  divisions: maxDays > 1 ? (maxDays - 1).toInt() : 1,
                  activeColor: CleanTheme.primaryColor,
                  inactiveColor: CleanTheme.chromeSubtle,
                  labels: RangeLabels('Giorno $_startDay', 'Giorno $_endDay'),
                  onChanged: (RangeValues values) {
                    setState(() {
                      _startDay = values.start.round();
                      _endDay = values.end.round();
                    });
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            HapticService.lightTap();
                            await provider.generateShoppingList(
                              startDay: _startDay,
                              endDay: _endDay,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CleanTheme.primaryColor,
                      foregroundColor: CleanTheme.textOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: CleanTheme.textOnPrimary,
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
                          color: CleanTheme.chromeSilver,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Genera la lista per iniziare',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: CleanTheme.textTertiary,
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
                                color: CleanTheme.primaryColor,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: CleanTheme.dividerColor),
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
                                  activeColor: CleanTheme.primaryColor,
                                  checkColor: CleanTheme.textOnPrimary,
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
                                      color: CleanTheme.textSecondary,
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
        color = CleanTheme.accentGreen;
        break;
      case 'Carne e Pesce':
        icon = Icons.restaurant;
        color = CleanTheme.steelLight;
        break;
      case 'Latticini':
        icon = Icons.egg;
        color = CleanTheme.chromeGray;
        break;
      case 'Cereali e Dispensa':
        icon = Icons.breakfast_dining;
        color = CleanTheme.chromeSilver;
        break;
      default:
        icon = Icons.local_grocery_store;
        color = CleanTheme.steelMid;
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
