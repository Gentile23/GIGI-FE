import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/services/nutrition_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../providers/auth_provider.dart';
import 'package:gigi/l10n/app_localizations.dart';

class GoalSetupWizardScreen extends StatefulWidget {
  const GoalSetupWizardScreen({super.key});

  @override
  State<GoalSetupWizardScreen> createState() => _GoalSetupWizardScreenState();
}

class _GoalSetupWizardScreenState extends State<GoalSetupWizardScreen> {
  late final NutritionService _nutritionService;
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _dataLoaded = false;

  // Form data - will be loaded from user profile
  String _goalType = 'maintain';
  String _gender = 'male';
  double _weight = 70;
  double _height = 175;
  int _age = 30;
  String _dietType = 'standard';

  // Calculated results
  Map<String, dynamic>? _tdeeResult;

  // Steps: 0=Goal, 1=Diet, 2=Results (bodyInfo data comes from profile)
  static const int _totalSteps = 3;

  @override
  void initState() {
    super.initState();
    _nutritionService = NutritionService(ApiClient());
    _loadUserDataFromProfile();
  }

  void _loadUserDataFromProfile() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user != null) {
        setState(() {
          // Load existing data from user profile
          if (user.height != null && user.height! > 0) {
            _height = user.height!.toDouble();
          }
          if (user.weight != null && user.weight! > 0) {
            _weight = user.weight!.toDouble();
          }
          // Calculate age from dateOfBirth
          if (user.dateOfBirth != null) {
            final now = DateTime.now();
            int calculatedAge = now.year - user.dateOfBirth!.year;
            if (now.month < user.dateOfBirth!.month ||
                (now.month == user.dateOfBirth!.month &&
                    now.day < user.dateOfBirth!.day)) {
              calculatedAge--;
            }
            if (calculatedAge > 0) {
              _age = calculatedAge;
            }
          }
          if (user.gender != null && user.gender!.isNotEmpty) {
            _gender = user.gender!.toLowerCase();
          }
          _dataLoaded = true;
        });
      } else {
        setState(() => _dataLoaded = true);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataLoaded) {
      return Scaffold(
        backgroundColor: CleanTheme.backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: CleanTheme.primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.appBarTitleGoals,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
      ),
      body: Column(
        children: [
          // User data summary card
          _buildUserDataSummary(),

          // Step indicator
          _buildStepIndicator(),

          // Pages - Only 3 steps now (Goal, Diet, Results)
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildGoalStep(),
                _buildDietStep(),
                _buildResultStep(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a summary of data loaded from user profile
  Widget _buildUserDataSummary() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CleanTheme.accentGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CleanTheme.accentGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: CleanTheme.accentGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppLocalizations.of(
                context,
              )!.profileDataSummary(_height.toInt(), _weight.toInt(), _age),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CleanTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? CleanTheme.primaryColor
                    : CleanTheme.borderSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGoalStep() {
    final l10n = AppLocalizations.of(context)!;
    return _buildStepContainer(
      title: l10n.goalStepTitle,
      subtitle: l10n.goalStepSubtitle,
      child: Column(
        children: [
          _buildGoalOption('lose_weight', '🔥', l10n.goalLoseWeight),
          _buildGoalOption('maintain', '⚖️', l10n.goalMaintain),
          _buildGoalOption('gain_muscle', '💪', l10n.goalGainMuscle),
          _buildGoalOption('gain_weight', '📈', l10n.goalGainWeight),
        ],
      ),
      onNext: () => _goToStep(1),
    );
  }

  Widget _buildGoalOption(String value, String emoji, String title) {
    final isSelected = _goalType == value;
    return GestureDetector(
      onTap: () => setState(() => _goalType = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? CleanTheme.primaryColor.withValues(alpha: 0.1)
              : CleanTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? CleanTheme.primaryColor
                : CleanTheme.borderPrimary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: CleanTheme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildDietStep() {
    final l10n = AppLocalizations.of(context)!;
    return _buildStepContainer(
      title: l10n.dietStepTitle,
      subtitle: l10n.dietStepSubtitle,
      child: Column(
        children: [
          _buildDietOption(
            'standard',
            '🍽️',
            l10n.dietStandard,
            l10n.dietStandardDesc,
          ),
          _buildDietOption(
            'low_carb',
            '🥩',
            l10n.dietLowCarb,
            l10n.dietLowCarbDesc,
          ),
          _buildDietOption(
            'vegetarian',
            '🥬',
            l10n.dietVegetarian,
            l10n.dietVegetarianDesc,
          ),
          _buildDietOption('vegan', '🌱', l10n.dietVegan, l10n.dietVeganDesc),
          _buildDietOption('keto', '🥑', l10n.dietKeto, l10n.dietKetoDesc),
          _buildDietOption(
            'mediterranean',
            '🫒',
            l10n.dietMediterranean,
            l10n.dietMediterraneanDesc,
          ),
        ],
      ),
      onNext: _calculateAndShowResults,
      onBack: () => _goToStep(0),
    );
  }

  Widget _buildDietOption(
    String value,
    String emoji,
    String title,
    String subtitle,
  ) {
    final isSelected = _dietType == value;
    return GestureDetector(
      onTap: () => setState(() => _dietType = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? CleanTheme.primaryColor.withValues(alpha: 0.1)
              : CleanTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? CleanTheme.primaryColor
                : CleanTheme.borderPrimary,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: CleanTheme.textSecondary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle,
                color: CleanTheme.primaryColor,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultStep() {
    if (_tdeeResult == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final calories = _tdeeResult!['target_calories'] ?? 2000;
    final macros = _tdeeResult!['macros'] ?? {};
    final protein = macros['protein_grams'] ?? 150;
    final carbs = macros['carbs_grams'] ?? 200;
    final fat = macros['fat_grams'] ?? 70;

    final l10n = AppLocalizations.of(context)!;
    return _buildStepContainer(
      title: l10n.resultsStepTitle,
      subtitle: l10n.resultsStepSubtitle,
      child: Column(
        children: [
          // Calorie Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [CleanTheme.primaryColor, CleanTheme.steelDark],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text(
                  '$calories',
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: CleanTheme.textOnDark,
                  ),
                ),
                Text(
                  l10n.caloriesPerDay,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: CleanTheme.textOnDark.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Macros
          Row(
            children: [
              Expanded(
                child: _buildMacroResultCard(
                  '🥩',
                  l10n.protein,
                  '${protein}g',
                  CleanTheme.accentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroResultCard(
                  '🍞',
                  l10n.carbs,
                  '${carbs}g',
                  CleanTheme.accentOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroResultCard(
                  '🥑',
                  l10n.fats,
                  '${fat}g',
                  CleanTheme.accentPurple,
                ),
              ),
            ],
          ),
        ],
      ),
      onNext: _saveGoals,
      nextLabel: l10n.saveGoalsButton,
      onBack: () => _goToStep(2),
    );
  }

  Widget _buildMacroResultCard(
    String emoji,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
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
      ),
    );
  }

  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required Widget child,
    VoidCallback? onNext,
    VoidCallback? onBack,
    String? nextLabel,
  }) {
    final defaultNextLabel = AppLocalizations.of(context)!.continueButton;
    final buttonLabel = nextLabel ?? defaultNextLabel;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CleanTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          Expanded(child: SingleChildScrollView(child: child)),

          // Navigation buttons
          Row(
            children: [
              if (onBack != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: CleanTheme.borderPrimary),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.back,
                      style: GoogleFonts.inter(color: CleanTheme.textSecondary),
                    ),
                  ),
                ),
              if (onBack != null) const SizedBox(width: 12),
              Expanded(
                flex: onBack != null ? 2 : 1,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : onNext,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: CleanTheme.primaryColor,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: CleanTheme.textOnDark,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          buttonLabel,
                          style: GoogleFonts.inter(
                            color: CleanTheme.textOnDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _calculateAndShowResults() async {
    setState(() => _isLoading = true);

    try {
      final result = await _nutritionService.calculateTDEE(
        weightKg: _weight,
        heightCm: _height,
        age: _age,
        gender: _gender,
        goalType: _goalType,
      );

      if (mounted) {
        setState(() {
          _tdeeResult = result;
          _isLoading = false;
        });
        _goToStep(3);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: CleanTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _saveGoals() async {
    if (_tdeeResult == null) return;

    setState(() => _isLoading = true);

    try {
      final macros = _tdeeResult!['macros'] ?? {};
      final success = await _nutritionService.setComprehensiveGoals(
        dailyCalories: _tdeeResult!['target_calories'] ?? 2000,
        proteinGrams: macros['protein_grams'] ?? 150,
        carbsGrams: macros['carbs_grams'] ?? 200,
        fatGrams: macros['fat_grams'] ?? 70,
        goalType: _goalType,
        dietType: _dietType,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🎉 ${AppLocalizations.of(context)!.goalsSavedSuccess}',
              ),
              backgroundColor: CleanTheme.accentGreen,
            ),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception(
            AppLocalizations.of(context)!.errorSavingProfile,
          ); // Reusing existing error key or generic error
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: CleanTheme.accentRed,
          ),
        );
      }
    }
  }
}
