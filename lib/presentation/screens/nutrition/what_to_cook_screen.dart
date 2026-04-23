import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/services/nutrition_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/utils/validation_utils.dart';
import '../../../data/services/quota_service.dart';
import '../../../providers/quota_provider.dart';
import '../../widgets/animations/liquid_steel_container.dart';
import '../../../core/services/haptic_service.dart';
import '../../widgets/quota/quota_banner.dart';
import 'generated_meal_screen.dart';
import 'ingredient_questionnaire_screen.dart';

class WhatToCookScreen extends StatefulWidget {
  const WhatToCookScreen({super.key});

  @override
  State<WhatToCookScreen> createState() => _WhatToCookScreenState();
}

class _WhatToCookScreenState extends State<WhatToCookScreen> {
  late final NutritionService _nutritionService;

  final TextEditingController _ingredientController = TextEditingController();
  final List<String> _ingredients = [];
  final FocusNode _ingredientFocusNode = FocusNode();

  // New state for complete meal
  Map<String, dynamic>? _generatedMeal;
  List<dynamic> _portate = [];
  String _generationMode = 'complete'; // 'single' or 'complete'
  String _mealType = 'fit'; // 'fit' or 'normal'

  bool _isLoading = false;
  bool _hasSearched = false;

  // Track expanded state for each course
  final Map<int, bool> _expandedIngredients = {};
  final Map<int, bool> _expandedSteps = {};

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
    _ingredientFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {}); // Rebuild to update border color dynamically
  }

  @override
  void dispose() {
    _ingredientController.dispose();
    _ingredientFocusNode.removeListener(_onFocusChange);
    _ingredientFocusNode.dispose();
    super.dispose();
  }

  void _resetSearch() {
    setState(() {
      _ingredients.clear();
      _ingredientController.clear();
      _generatedMeal = null;
      _portate = [];
      _hasSearched = false;
      _isLoading = false;
    });
    HapticService.lightTap();
  }

  Future<void> _addIngredient() async {
    final text = ValidationUtils.sanitizeFreeText(
      _ingredientController.text,
      maxLength: ValidationUtils.maxIngredientLength,
    );
    if (text.isNotEmpty && !ValidationUtils.containsSuspiciousMarkup(text)) {
      if (_ingredients.length >= ValidationUtils.maxIngredientsPerChefRequest) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Puoi inserire al massimo 10 ingredienti.'),
            backgroundColor: CleanTheme.accentOrange,
          ),
        );
        return;
      }
      if (_ingredients.contains(text)) {
        _ingredientController.clear();
        return;
      }
      setState(() {
        _ingredients.add(text);
        _ingredientController.clear();
      });
      HapticService.lightTap();
      _ingredientFocusNode.requestFocus();
    }
  }

  Future<void> _searchRecipes() async {
    if (_ingredients.isEmpty || _isLoading) return;

    HapticService.mediumTap();

    final quotaProvider = context.read<QuotaProvider>();
    final quotaCheck = await quotaProvider.canPerform(QuotaAction.recipes);
    if (!mounted) return;
    if (!quotaCheck.canPerform) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(quotaCheck.reason),
          backgroundColor: CleanTheme.accentRed,
        ),
      );
      return;
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
        maxTimeMinutes: 30,
        mode: _generationMode,
        mealType: _mealType,
        step: 'questionnaire',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (result != null &&
            result['success'] == true &&
            result['questions'] != null) {
          setState(() {
            _hasSearched = false;
          });
          HapticService.notificationPattern();
          final questions = (result['questions'] as List)
              .map((e) => e.toString())
              .toList();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IngredientQuestionnaireScreen(
                questions: questions,
                originalIngredients: _ingredients,
                dietType:
                    'standard', // Potrebbe essere dinamico se lo aggiungi all'UI
                mode: _generationMode,
                mealType: _mealType,
                maxTimeMinutes: 30,
                nutritionService: _nutritionService,
              ),
            ),
          );
        } else if (result != null &&
            result['success'] == true &&
            result['meal'] != null) {
          await quotaProvider.syncAfterSuccess(QuotaAction.recipes);
          if (!mounted) return;
          // Caso in cui il questionario viene saltato e il pasto generato direttamente
          HapticService.notificationPattern();
          final mealData = result['meal'] as Map<String, dynamic>;
          final portateList =
              (mealData['portate'] as List?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GeneratedMealScreen(
                generatedMeal: mealData,
                portate: portateList,
              ),
            ),
          );
        } else if (result != null && result['quota_exceeded'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Limite quota raggiunto!'),
              backgroundColor: CleanTheme.accentRed,
            ),
          );
          HapticService.errorPattern();
        } else if (result != null && result['success'] == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Errore durante la generazione',
              ),
              backgroundColor: CleanTheme.accentRed,
            ),
          );
          HapticService.errorPattern();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errore durante la generazione della ricetta'),
            backgroundColor: CleanTheme.accentRed,
          ),
        );
        HapticService.errorPattern();
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
        backgroundColor: CleanTheme.backgroundColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const QuotaBanner(action: QuotaAction.recipes, compact: true),
            const SizedBox(height: 12),

            LiquidSteelContainer(
              borderRadius: 32,
              enableShine: true,
              border: Border.all(
                color: CleanTheme.textOnDark.withValues(alpha: 0.3),
                width: 1,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CleanTheme.steelDark.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: CleanTheme.textOnDark.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Text('🍳', style: TextStyle(fontSize: 40)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cosa cucino oggi?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: CleanTheme.textOnDark,
                        shadows: [
                          Shadow(
                            color: CleanTheme.primaryColor.withValues(
                              alpha: 0.5,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Inserisci gli ingredienti e lascia fare a Chef AI',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CleanTheme.textOnDark.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Fit vs Normal Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: CleanTheme.surfaceColor,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: CleanTheme.borderPrimary),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMealTypeOption(
                    'Pasto Fit',
                    'fit',
                    Icons.fitness_center,
                  ),
                  _buildMealTypeOption(
                    'Pasto Normale',
                    'normal',
                    Icons.restaurant,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: CleanTheme.surfaceColor,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: CleanTheme.borderPrimary),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildToggleOption(
                    'Menu Completo',
                    'complete',
                    Icons.restaurant_menu,
                  ),
                  _buildToggleOption(
                    'Piatto Unico',
                    'single',
                    Icons.restaurant,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'Cosa hai in frigo?',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: CleanTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _ingredientFocusNode.hasFocus
                            ? CleanTheme.primaryColor
                            : CleanTheme.borderPrimary,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: CleanTheme.primaryColor.withValues(
                            alpha: 0.05,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _ingredientController,
                      focusNode: _ingredientFocusNode,
                      enabled: !_isLoading,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Es: pollo, riso, broccoli...',
                        hintStyle: GoogleFonts.inter(
                          color: CleanTheme.textTertiary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add_circle),
                          color: _isLoading
                              ? CleanTheme.textTertiary
                              : CleanTheme.primaryColor,
                          onPressed: _isLoading ? null : _addIngredient,
                        ),
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: _isLoading
                            ? CleanTheme.textSecondary
                            : CleanTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      onSubmitted: (_) => _isLoading ? null : _addIngredient(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (_ingredients.isNotEmpty) ...[
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: _ingredients
                    .map(
                      (ing) => Chip(
                        label: Text(
                          ing,
                          style: GoogleFonts.inter(
                            color: CleanTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: CleanTheme.surfaceColor,
                        deleteIconColor: _isLoading
                            ? CleanTheme.textTertiary
                            : CleanTheme.accentRed,
                        onDeleted: _isLoading
                            ? null
                            : () {
                                setState(() => _ingredients.remove(ing));
                                HapticService.lightTap();
                              },
                        elevation: 2,
                        shadowColor: CleanTheme.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: CleanTheme.borderPrimary),
                        ),
                      ),
                    )
                    .toList(),
              ),
              if ((!_hasSearched || _isLoading) && _generatedMeal == null) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _searchRecipes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CleanTheme.primaryColor,
                      foregroundColor: CleanTheme.textOnPrimary,
                      elevation: 8,
                      shadowColor: CleanTheme.primaryColor.withValues(
                        alpha: 0.4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: CleanTheme.textOnPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        else ...[
                          const Icon(Icons.auto_awesome, size: 20),
                          const SizedBox(width: 8),
                        ],
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _isLoading
                                ? 'Chef AI sta creando...'
                                : (_generationMode == 'single'
                                      ? 'Genera Piatto da Chef'
                                      : 'Genera Menu da Chef'),
                            key: ValueKey<bool>(_isLoading),
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],

            if (_hasSearched) ...[
              const SizedBox(height: 48),
              if (_generatedMeal != null) ...[
                _buildMealHeader(),
                const SizedBox(height: 24),
                ..._portate.asMap().entries.map(
                  (entry) =>
                      _buildCourseCard(entry.value, entry.key, _portate.length),
                ),
                if (_generatedMeal?['consiglio_chef'] != null)
                  _buildChefTip(_generatedMeal!['consiglio_chef']),

                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _resetSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CleanTheme.surfaceColor,
                        foregroundColor: CleanTheme.primaryColor,
                        elevation: 0,
                        side: BorderSide(color: CleanTheme.borderPrimary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                      icon: Icon(
                        Icons.add_rounded,
                        size: 20,
                        color: _isLoading
                            ? CleanTheme.textTertiary
                            : CleanTheme.primaryColor,
                      ),
                      label: Text(
                        'Nuova Ricerca',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _isLoading
                              ? CleanTheme.textTertiary
                              : CleanTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (_generatedMeal == null && !_isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Text('🤔', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 16),
                        Text(
                          'Nessun menu trovato',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: CleanTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Prova con ingredienti diversi o aggiungine altri',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: CleanTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],

            if (_generatedMeal == null && !_isLoading) ...[
              const SizedBox(height: 48),
              Text(
                '✨ Ingredienti suggeriti',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 12,
                children: _suggestedIngredients.map((item) {
                  final name = item.split(' ').last;
                  final isSelected = _ingredients.contains(name);
                  return GestureDetector(
                    onTap: _isLoading
                        ? null
                        : () {
                            HapticService.lightTap();
                            if (!isSelected) {
                              setState(() => _ingredients.add(name));
                            } else {
                              setState(() => _ingredients.remove(name));
                            }
                          },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? CleanTheme.primaryColor
                            : CleanTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isSelected
                              ? CleanTheme.primaryColor
                              : CleanTheme.borderPrimary,
                        ),
                        boxShadow: [
                          if (!isSelected)
                            BoxShadow(
                              color: CleanTheme.primaryColor.withValues(
                                alpha: 0.03,
                              ),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item,
                            style: GoogleFonts.inter(
                              color: isSelected
                                  ? CleanTheme.textOnPrimary
                                  : CleanTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(String label, String value, IconData icon) {
    final isSelected = _generationMode == value;
    return GestureDetector(
      onTap: () {
        setState(() => _generationMode = value);
        HapticService.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? CleanTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? CleanTheme.textOnPrimary
                  : CleanTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? CleanTheme.textOnPrimary
                    : CleanTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeOption(String label, String value, IconData icon) {
    final isSelected = _mealType == value;
    return GestureDetector(
      onTap: () {
        setState(() => _mealType = value);
        HapticService.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? CleanTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? CleanTheme.textOnPrimary
                  : CleanTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? CleanTheme.textOnPrimary
                    : CleanTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
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
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: CleanTheme.textPrimary,
          ),
        ),
        if (_generatedMeal?['descrizione'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _generatedMeal!['descrizione'],
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: CleanTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        const SizedBox(height: 16),
        Divider(color: CleanTheme.borderPrimary, endIndent: 40, indent: 40),
      ],
    );
  }

  Widget _buildChefTip(String tip) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CleanTheme.accentOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CleanTheme.accentOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Text('👨‍🍳', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text(
            'Consiglio dello Chef',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: CleanTheme.accentOrange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tip,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CleanTheme.textPrimary,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course, int index, int total) {
    final type = course['tipo'] ?? 'Piatto';
    final ingredients = course['ingredienti'] as List? ?? [];
    final instructions = course['instructions'] as List? ?? [];

    final isIngredientsExpanded = _expandedIngredients[index] ?? false;
    final isStepsExpanded = _expandedSteps[index] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CleanTheme.borderPrimary),
        boxShadow: [
          BoxShadow(
            color: CleanTheme.primaryColor.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: CleanTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              type.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                color: CleanTheme.primaryColor,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  course['emoji'] ?? '🍽️',
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  course['nome'] ?? 'Ricetta',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
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

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: CleanTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMiniMacro('🥩', '${course['proteine_g']}g'),
                      Container(
                        width: 1,
                        height: 20,
                        color: CleanTheme.borderPrimary,
                      ),
                      _buildMiniMacro('🍞', '${course['carboidrati_g']}g'),
                      Container(
                        width: 1,
                        height: 20,
                        color: CleanTheme.borderPrimary,
                      ),
                      _buildMiniMacro('🥑', '${course['grassi_g']}g'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Divider(color: CleanTheme.borderPrimary),
                const SizedBox(height: 8),

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
                      alignment: WrapAlignment.center,
                      children: ingredients
                          .map(
                            (ing) => Chip(
                              label: Text(
                                ing.toString(),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: CleanTheme.textPrimary,
                                ),
                              ),
                              backgroundColor: CleanTheme.accentGreen
                                  .withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: CleanTheme.accentGreen.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),

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
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: CleanTheme.primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: CleanTheme.primaryColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$stepNum',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  action,
                                  style: GoogleFonts.inter(
                                    color: CleanTheme.textPrimary,
                                    height: 1.5,
                                    fontSize: 14,
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
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          val,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: CleanTheme.textPrimary,
          ),
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
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: CleanTheme.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: child,
          ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CleanTheme.backgroundColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CleanTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CleanTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
