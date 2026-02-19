import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/services/nutrition_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
import '../../screens/paywall/paywall_screen.dart'; // Import PaywallScreen
import '../../../data/services/quota_service.dart'; // Import QuotaService
import '../../../data/models/quota_status_model.dart'; // Import QuotaStatus

class WhatToCookScreen extends StatefulWidget {
  const WhatToCookScreen({super.key});

  @override
  State<WhatToCookScreen> createState() => _WhatToCookScreenState();
}

class _WhatToCookScreenState extends State<WhatToCookScreen> {
  late final NutritionService _nutritionService;
  late final QuotaService _quotaService; // Add QuotaService

  final TextEditingController _ingredientController = TextEditingController();
  final List<String> _ingredients = [];

  // New state for complete meal
  Map<String, dynamic>? _generatedMeal;
  List<dynamic> _portate = [];
  String _generationMode = 'complete'; // 'single' or 'complete'

  QuotaStatus? _quotaStatus; // Add QuotaStatus

  bool _isLoading = false;
  bool _hasSearched = false;

  // Track expanded state for each course
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
    final apiClient = ApiClient();
    _nutritionService = NutritionService(apiClient);
    _quotaService = QuotaService(apiClient: apiClient); // Init QuotaService
    _loadQuota(); // Load quota on init
  }

  Future<void> _loadQuota() async {
    try {
      final status = await _quotaService.getQuotaStatus();
      if (mounted) {
        setState(() => _quotaStatus = status);
      }
    } catch (e) {
      debugPrint('Error loading quota: $e');
    }
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  Future<void> _addIngredient() async {
    final text = _ingredientController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _ingredients.add(text);
        _ingredientController.clear();
      });
    }
  }

  Future<void> _searchRecipes() async {
    if (_ingredients.isEmpty) return;

    if (_quotaStatus != null) {
      final recipesQuota = _quotaStatus!.usage.recipes;
      if (!recipesQuota.canUse) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Hai raggiunto il limite settimanale di ricette. Passa a Premium!',
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Upgrade',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                );
              },
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _generatedMeal = null;
      _portate = [];
    });

    try {
      final result = await _nutritionService.whatToCook(
        ingredients: _ingredients,
        maxTimeMinutes: 30, // Could be dynamic
        mode: _generationMode, // Pass mode
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result != null && result['meal'] != null) {
            _generatedMeal = result['meal'];
            _portate = _generatedMeal!['portate'] ?? [];
            _loadQuota(); // Refresh quota after generation
          } else if (result != null && result['quota_exceeded'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Limite quota raggiunto!')),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Errore: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Chef AI 👨‍🍳',
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
            // Quota Banner
            if (_quotaStatus != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: CleanTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CleanTheme.borderPrimary),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CleanTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 20,
                        color: CleanTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Generazioni Rimanenti',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: CleanTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value:
                                        _quotaStatus!.usage.recipes.remaining /
                                        (_quotaStatus!.usage.recipes.limit > 0
                                            ? _quotaStatus!.usage.recipes.limit
                                            : 1),
                                    backgroundColor: CleanTheme.backgroundColor,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _quotaStatus!.usage.recipes.remaining <= 1
                                          ? CleanTheme.accentRed
                                          : CleanTheme.primaryColor,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_quotaStatus!.usage.recipes.remaining}/${_quotaStatus!.usage.recipes.limit == -1 ? "∞" : _quotaStatus!.usage.recipes.limit}',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: CleanTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

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
                          'Cosa cucino oggi?',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CleanTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Inserisci gli ingredienti e lascia fare a Chef AI',
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

            // Mode Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: CleanTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CleanTheme.borderPrimary),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _generationMode = 'complete'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _generationMode == 'complete'
                              ? CleanTheme.primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Menu Completo',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _generationMode == 'complete'
                                ? Colors.white
                                : CleanTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _generationMode = 'single'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _generationMode == 'single'
                              ? CleanTheme.primaryColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Piatto Unico',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _generationMode == 'single'
                                ? Colors.white
                                : CleanTheme.textSecondary,
                          ),
                        ),
                      ),
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
                    ? 'Chef AI sta cucinando... 👨‍🍳'
                    : 'Genera 🍽️',
                onPressed: _isLoading ? null : _searchRecipes,
                icon: Icons.auto_awesome,
              ),
            ],

            // Recipes (Meal View)
            if (_hasSearched) ...[
              const SizedBox(height: 24),
              if (_generatedMeal != null) ...[
                _buildMealHeader(),
                const SizedBox(height: 20),
                ..._portate.asMap().entries.map(
                  (entry) =>
                      _buildCourseCard(entry.value, entry.key, _portate.length),
                ),
                if (_generatedMeal?['consiglio_chef'] != null)
                  _buildChefTip(_generatedMeal!['consiglio_chef']),

                const SizedBox(height: 20),
                Center(
                  child: TextButton.icon(
                    onPressed: _searchRecipes,
                    icon: Icon(
                      Icons.refresh,
                      size: 18,
                      color: CleanTheme.primaryColor,
                    ),
                    label: Text(
                      'Rigenera Menu',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CleanTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ] else if (_portate.isEmpty && !_isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Text('🤔', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          'Nessun menu trovato',
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

  Widget _buildMealHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ecco il tuo Menu! 🎉',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: CleanTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _generatedMeal?['nome_pasto'] ?? 'Menu Chef AI',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: CleanTheme.textPrimary,
          ),
        ),
        if (_generatedMeal?['descrizione'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _generatedMeal!['descrizione'],
              style: GoogleFonts.inter(
                fontSize: 15,
                color: CleanTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        const SizedBox(height: 8),
        Divider(color: CleanTheme.borderPrimary),
      ],
    );
  }

  Widget _buildChefTip(String tip) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.accentOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CleanTheme.accentOrange.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('👨‍🍳', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consiglio dello Chef',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: CleanTheme.accentOrange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CleanTheme.textPrimary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course, int index, int total) {
    // Map backend keys to frontend expectations
    final type = course['tipo'] ?? 'Piatto';
    final ingredients = course['ingredienti'] as List? ?? [];
    final instructions = course['instructions'] as List? ?? [];

    // Check expanded state
    final isIngredientsExpanded = _expandedIngredients[index] ?? false;
    final isStepsExpanded = _expandedSteps[index] ?? true;

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
          // Course Header (Primo, Secondo, etc)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: CleanTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Text(
                  type.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: CleanTheme.primaryColor,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.restaurant,
                  size: 16,
                  color: CleanTheme.primaryColor,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and emoji
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['emoji'] ?? '🍽️',
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        course['nome'] ?? 'Ricetta',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: CleanTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Info Chips
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      Icons.timer_outlined,
                      '${course['time_minutes'] ?? 30} min',
                    ),
                    _buildInfoChip(
                      Icons.local_fire_department_outlined,
                      '${course['calorie'] ?? 0} kcal',
                    ),
                  ],
                ),

                // Macros
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CleanTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniMacro('🥩', '${course['proteine_g']}g'),
                      _buildMiniMacro('🍞', '${course['carboidrati_g']}g'),
                      _buildMiniMacro('🥑', '${course['grassi_g']}g'),
                    ],
                  ),
                ),

                // Ingredients
                const SizedBox(height: 20),
                if (ingredients.isNotEmpty)
                  _buildExpandableSection(
                    title: '🧺 Ingredienti',
                    isExpanded: isIngredientsExpanded,
                    onToggle: () => setState(
                      () =>
                          _expandedIngredients[index] = !isIngredientsExpanded,
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ingredients
                          .map(
                            (ing) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: CleanTheme.accentGreen.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
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

                // Preparation
                const SizedBox(height: 16),
                if (instructions.isNotEmpty)
                  _buildExpandableSection(
                    title: '👨‍🍳 Preparazione',
                    isExpanded: isStepsExpanded,
                    onToggle: () => setState(
                      () => _expandedSteps[index] = !isStepsExpanded,
                    ),
                    child: Column(
                      children: instructions.asMap().entries.map((entry) {
                        final step = entry.value;
                        final stepNum = step['step'] ?? entry.key + 1;
                        final action = step['action'] ?? step.toString();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: CleanTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$stepNum',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  action,
                                  style: GoogleFonts.inter(
                                    color: CleanTheme.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMacro(String emoji, String val) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(
          val,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
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
      ],
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
}
