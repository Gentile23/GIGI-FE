import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/services/nutrition_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';

class WhatToCookScreen extends StatefulWidget {
  const WhatToCookScreen({super.key});

  @override
  State<WhatToCookScreen> createState() => _WhatToCookScreenState();
}

class _WhatToCookScreenState extends State<WhatToCookScreen> {
  late final NutritionService _nutritionService;
  final TextEditingController _ingredientController = TextEditingController();
  final List<String> _ingredients = [];
  List<Map<String, dynamic>> _recipes = [];
  Map<String, dynamic>? _remainingMacros;
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _nutritionService = NutritionService(ApiClient());
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Cosa Cucino?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CleanTheme.accentOrange.withValues(alpha: 0.1),
                    CleanTheme.accentOrange.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: CleanTheme.accentOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Text('🍳', style: TextStyle(fontSize: 40)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inserisci gli ingredienti',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CleanTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Ti suggerirò ricette in base ai tuoi macro',
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
            const SizedBox(height: 24),

            // Ingredient input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ingredientController,
                    decoration: InputDecoration(
                      hintText: 'Es: pollo, riso, broccoli...',
                      hintStyle: GoogleFonts.inter(
                        color: CleanTheme.textTertiary,
                      ),
                      filled: true,
                      fillColor: CleanTheme.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    style: GoogleFonts.inter(color: CleanTheme.textPrimary),
                    onSubmitted: (_) => _addIngredient(),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _addIngredient,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CleanTheme.accentOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ingredient chips
            if (_ingredients.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _ingredients
                    .map(
                      (ing) => Chip(
                        label: Text(
                          ing,
                          style: GoogleFonts.inter(
                            color: CleanTheme.textPrimary,
                          ),
                        ),
                        backgroundColor: CleanTheme.surfaceColor,
                        deleteIconColor: CleanTheme.textSecondary,
                        onDeleted: () =>
                            setState(() => _ingredients.remove(ing)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(
                            color: CleanTheme.borderPrimary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),

              // Search button
              CleanButton(
                text: _isLoading
                    ? 'Gigi sta cercando ricette...'
                    : 'Trova Ricette 🔍',
                onPressed: _isLoading ? null : _searchRecipes,
                icon: Icons.search,
              ),
            ],

            // Remaining macros
            if (_remainingMacros != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CleanTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CleanTheme.borderPrimary),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMacroChip(
                      '🔥',
                      '${_remainingMacros!['calories'] ?? 0}',
                      'kcal',
                    ),
                    _buildMacroChip(
                      '🥩',
                      '${_remainingMacros!['protein'] ?? 0}g',
                      'prot',
                    ),
                    _buildMacroChip(
                      '🍞',
                      '${_remainingMacros!['carbs'] ?? 0}g',
                      'carb',
                    ),
                  ],
                ),
              ),
            ],

            // Recipes
            if (_hasSearched) ...[
              const SizedBox(height: 24),
              CleanSectionHeader(title: '🍽️ Ricette Suggerite'),
              const SizedBox(height: 12),

              if (_recipes.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Text('🤔', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          'Nessuna ricetta trovata',
                          style: GoogleFonts.inter(
                            color: CleanTheme.textSecondary,
                          ),
                        ),
                        Text(
                          'Prova con ingredienti diversi',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: CleanTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._recipes.map((recipe) => _buildRecipeCard(recipe)),
            ],

            // Suggested ingredients
            if (_ingredients.isEmpty && !_hasSearched) ...[
              const SizedBox(height: 32),
              Text(
                'Ingredienti popolari',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                          '🍗 Pollo',
                          '🍚 Riso',
                          '🥚 Uova',
                          '🥦 Broccoli',
                          '🍝 Pasta',
                          '🧀 Formaggio',
                          '🥕 Carote',
                          '🧅 Cipolla',
                        ]
                        .map(
                          (item) => GestureDetector(
                            onTap: () {
                              final name = item.split(' ').last;
                              if (!_ingredients.contains(name)) {
                                setState(() => _ingredients.add(name));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: CleanTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: CleanTheme.borderPrimary,
                                ),
                              ),
                              child: Text(
                                item,
                                style: GoogleFonts.inter(
                                  color: CleanTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMacroChip(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: CleanTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: CleanTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    final matchScore = recipe['match_score'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CleanTheme.borderPrimary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                recipe['image_emoji'] ?? '🍽️',
                style: const TextStyle(fontSize: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe['name'] ?? 'Ricetta',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: CleanTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe['time_minutes'] ?? 30} min',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: CleanTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: matchScore > 85
                                ? CleanTheme.accentGreen.withValues(alpha: 0.1)
                                : CleanTheme.accentOrange.withValues(
                                    alpha: 0.1,
                                  ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            matchScore > 85 ? '✨ Perfect' : '👍 Good',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: matchScore > 85
                                  ? CleanTheme.accentGreen
                                  : CleanTheme.accentOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Nutrition info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutritionInfo('🔥', '${recipe['calories'] ?? 0}', 'kcal'),
              _buildNutritionInfo('🥩', '${recipe['protein'] ?? 0}g', 'prot'),
              _buildNutritionInfo('🍞', '${recipe['carbs'] ?? 0}g', 'carb'),
              _buildNutritionInfo('🥑', '${recipe['fat'] ?? 0}g', 'fat'),
            ],
          ),

          // Instructions preview
          if (recipe['instructions'] != null &&
              (recipe['instructions'] as List).isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Preparazione:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...((recipe['instructions'] as List)
                .take(3)
                .map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: GoogleFonts.inter(
                            color: CleanTheme.primaryColor,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            step.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: CleanTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionInfo(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: CleanTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: CleanTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  void _addIngredient() {
    final text = _ingredientController.text.trim();
    if (text.isNotEmpty && !_ingredients.contains(text)) {
      setState(() {
        _ingredients.add(text);
        _ingredientController.clear();
      });
    }
  }

  Future<void> _searchRecipes() async {
    if (_ingredients.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final result = await _nutritionService.whatToCook(
        ingredients: _ingredients,
      );

      if (mounted && result != null) {
        setState(() {
          _recipes = List<Map<String, dynamic>>.from(result['recipes'] ?? []);
          _remainingMacros = result['remaining_macros'];
          _hasSearched = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: CleanTheme.accentRed,
          ),
        );
      }
    }
  }
}
