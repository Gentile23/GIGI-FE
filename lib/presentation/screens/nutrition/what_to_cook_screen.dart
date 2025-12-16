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

  // Track expanded state for each recipe's ingredients and steps
  final Map<int, bool> _expandedIngredients = {};
  final Map<int, bool> _expandedSteps = {};

  // Suggested ingredients with emojis
  final List<String> _suggestedIngredients = [
    '🍗 Pollo',
    '🍚 Riso',
    '🥚 Uova',
    '🥦 Broccoli',
    '🍝 Pasta',
    '🧀 Formaggio',
    '🥕 Carote',
    '🧅 Cipolla',
    '🍅 Pomodori',
    '🥬 Spinaci',
    '🐟 Salmone',
    '🥔 Patate',
  ];

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
                          'Gigi ti suggerirà ricette perfette per te',
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
                        backgroundColor: CleanTheme.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        deleteIconColor: CleanTheme.primaryColor,
                        onDeleted: () =>
                            setState(() => _ingredients.remove(ing)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: CleanTheme.primaryColor.withValues(
                              alpha: 0.3,
                            ),
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
                    ? 'Gigi sta creando le ricette...'
                    : 'Genera Ricette 🔍',
                onPressed: _isLoading ? null : _searchRecipes,
                icon: Icons.auto_awesome,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Macro rimanenti oggi',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
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
                  ],
                ),
              ),
            ],

            // Recipes
            if (_hasSearched) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    '🍽️ ${_recipes.length} Ricette Generate',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (_recipes.isNotEmpty)
                    TextButton.icon(
                      onPressed: _searchRecipes,
                      icon: Icon(
                        Icons.refresh,
                        size: 18,
                        color: CleanTheme.primaryColor,
                      ),
                      label: Text(
                        'Rigenera',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: CleanTheme.primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
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
                ...List.generate(
                  _recipes.length,
                  (index) => _buildEnhancedRecipeCard(
                    _recipes[index],
                    index + 1,
                    _recipes.length,
                  ),
                ),
            ],

            // Always show suggested ingredients
            const SizedBox(height: 32),
            Text(
              '✨ Ingredienti suggeriti',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tocca per aggiungere',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: CleanTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestedIngredients.map((item) {
                final name = item.split(' ').last;
                final isSelected = _ingredients.contains(name);
                return GestureDetector(
                  onTap: () {
                    if (!isSelected) {
                      setState(() => _ingredients.add(name));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CleanTheme.primaryColor.withValues(alpha: 0.15)
                          : CleanTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? CleanTheme.primaryColor
                            : CleanTheme.borderPrimary,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item,
                          style: GoogleFonts.inter(
                            color: isSelected
                                ? CleanTheme.primaryColor
                                : CleanTheme.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: CleanTheme.primaryColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
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

  Widget _buildEnhancedRecipeCard(
    Map<String, dynamic> recipe,
    int recipeNumber,
    int totalRecipes,
  ) {
    final matchScore = recipe['match_score'] ?? 0;
    final ingredients = recipe['ingredients'] as List? ?? [];
    final instructions = recipe['instructions'] as List? ?? [];
    final isIngredientsExpanded = _expandedIngredients[recipeNumber] ?? false;
    final isStepsExpanded =
        _expandedSteps[recipeNumber] ?? true; // Default expanded

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CleanTheme.borderPrimary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recipe Header with gradient background
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CleanTheme.primaryColor.withValues(alpha: 0.08),
                  CleanTheme.primaryColor.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipe number badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: CleanTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Ricetta $recipeNumber/$totalRecipes',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: matchScore > 85
                            ? CleanTheme.accentGreen.withValues(alpha: 0.15)
                            : CleanTheme.accentOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        matchScore > 85 ? '✨ Perfetta' : '👍 Ottima',
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
                const SizedBox(height: 16),

                // Name and emoji
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe['image_emoji'] ?? '🍽️',
                      style: const TextStyle(fontSize: 44),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe['name'] ?? 'Ricetta',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: CleanTheme.textPrimary,
                            ),
                          ),
                          if (recipe['description'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              recipe['description'],
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: CleanTheme.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Time, servings, difficulty
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      Icons.timer_outlined,
                      '${recipe['time_minutes'] ?? 30} min',
                    ),
                    _buildInfoChip(
                      Icons.people_outline,
                      '${recipe['servings'] ?? 2} porzioni',
                    ),
                    _buildInfoChip(
                      Icons.signal_cellular_alt,
                      recipe['difficulty'] ?? 'facile',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Nutrition row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CleanTheme.backgroundColor.withValues(alpha: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutritionInfo('🔥', '${recipe['calories'] ?? 0}', 'kcal'),
                _buildNutritionInfo(
                  '🥩',
                  '${recipe['protein'] ?? 0}g',
                  'proteine',
                ),
                _buildNutritionInfo('🍞', '${recipe['carbs'] ?? 0}g', 'carb'),
                _buildNutritionInfo('🥑', '${recipe['fat'] ?? 0}g', 'grassi'),
              ],
            ),
          ),

          // Ingredients Section
          if (ingredients.isNotEmpty)
            _buildExpandableSection(
              title: '🧺 Ingredienti (${ingredients.length})',
              isExpanded: isIngredientsExpanded,
              onToggle: () => setState(
                () =>
                    _expandedIngredients[recipeNumber] = !isIngredientsExpanded,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ingredients
                    .map(
                      (ing) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: CleanTheme.accentGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: CleanTheme.accentGreen.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Text(
                          ing.toString(),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: CleanTheme.textPrimary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          // Preparation Steps Section
          if (instructions.isNotEmpty)
            _buildExpandableSection(
              title: '👨‍🍳 Preparazione (${instructions.length} passaggi)',
              isExpanded: isStepsExpanded,
              onToggle: () => setState(
                () => _expandedSteps[recipeNumber] = !isStepsExpanded,
              ),
              child: Column(
                children: instructions.asMap().entries.map((entry) {
                  final step = entry.value;
                  final stepNum = entry.key + 1;

                  // Handle both old simple format and new detailed format
                  final isDetailedStep = step is Map;
                  final actionText = isDetailedStep
                      ? (step['action'] ?? step['azione'] ?? step.toString())
                      : step.toString();
                  final timeText = isDetailedStep
                      ? (step['time'] ?? step['tempo'])
                      : null;
                  final tipText = isDetailedStep
                      ? (step['tip'] ?? step['consiglio'])
                      : null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CleanTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CleanTheme.borderPrimary),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: CleanTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$stepNum',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                actionText,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: CleanTheme.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                              if (timeText != null && timeText.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 14,
                                      color: CleanTheme.accentOrange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      timeText,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: CleanTheme.accentOrange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (tipText != null && tipText.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: CleanTheme.primaryColor.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '💡',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          tipText,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: CleanTheme.primaryColor,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // Chef tips, variation, pairing
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (recipe['chef_tip'] != null)
                  _buildTipCard(
                    '👨‍🍳',
                    'Consiglio dello Chef',
                    recipe['chef_tip'],
                  ),
                if (recipe['variation'] != null)
                  _buildTipCard('🔄', 'Variante', recipe['variation']),
                if (recipe['pairing'] != null)
                  _buildTipCard('🍷', 'Abbinamento', recipe['pairing']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CleanTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: CleanTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget child,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: CleanTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        if (!isExpanded) const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTipCard(String emoji, String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CleanTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CleanTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionInfo(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 15,
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
          // Reset expanded states for new recipes
          _expandedIngredients.clear();
          _expandedSteps.clear();
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
