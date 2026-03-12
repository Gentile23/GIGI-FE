import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/services/nutrition_service.dart';
import '../../../core/services/haptic_service.dart';
import '../nutrition/generated_meal_screen.dart';

class IngredientQuestionnaireScreen extends StatefulWidget {
  final List<String> questions;
  final List<String> originalIngredients;
  final String dietType;
  final String mode;
  final String mealType;
  final int maxTimeMinutes;
  final NutritionService nutritionService;

  const IngredientQuestionnaireScreen({
    super.key,
    required this.questions,
    required this.originalIngredients,
    required this.dietType,
    required this.mode,
    required this.mealType,
    required this.maxTimeMinutes,
    required this.nutritionService,
  });

  @override
  State<IngredientQuestionnaireScreen> createState() => _IngredientQuestionnaireScreenState();
}

class _IngredientQuestionnaireScreenState extends State<IngredientQuestionnaireScreen> {
  final Map<String, bool> _answers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize all answers to true (yes) by default to encourage richer recipes
    for (var question in widget.questions) {
      _answers[question] = true;
    }
  }

  Future<void> _generateFinalMeal() async {
    HapticService.lightTap();
    
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await widget.nutritionService.whatToCook(
        ingredients: widget.originalIngredients,
        maxTimeMinutes: widget.maxTimeMinutes,
        dietType: widget.dietType,
        mode: widget.mode,
        mealType: widget.mealType,
        step: 'generate_meal',
        answers: _answers,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result != null && result['success'] == true && result['meal'] != null) {
            // Check quota exceeded
            if (result['quota_exceeded'] == true) {
              _showErrorDialog(
                result['message'] ?? 'Hai raggiunto il limite settimanale di ricette generate.',
              );
              return;
            }

            // Success -> Navigate
            final mealData = result['meal'] as Map<String, dynamic>;
            final portateList = (mealData['portate'] as List?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ?? [];

            HapticService.notificationPattern();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GeneratedMealScreen(
                  generatedMeal: mealData,
                  portate: portateList,
                ),
              ),
            );
        } else {
             _showErrorDialog(result?['message'] ?? "Spiacenti, non è stato possibile generare la ricetta. Riprova scuotendo la testa dello chef o cambiano ingredienti.");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog("Si è verificato un errore di connessione.");
      }
    }
  }
  
  void _showErrorDialog(String message) {
    HapticService.errorPattern();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Ops!',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.outfit(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.outfit(
                color: const Color(0xFFE2F163),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Completa la dispensa',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        'Prima di accendere i fornelli...',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFE2F163),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Per arricchire la tua ricetta, facci sapere quali di questi ingredienti base hai a disposizione.',
                        style: GoogleFonts.outfit(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ...widget.questions.map((question) => _buildQuestionTile(question)),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _generateFinalMeal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE2F163),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          'Cucina Ora',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuestionTile(String question) {
    final bool isYes = _answers[question] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isYes ? const Color(0xFFE2F163).withValues(alpha: 0.3) : Colors.white10,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildChoiceButton(
                  title: 'No',
                  isSelected: !isYes,
                  onTap: () {
                    HapticService.selectionClick();
                    setState(() => _answers[question] = false);
                  },
                  activeColor: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildChoiceButton(
                  title: 'Sì',
                  isSelected: isYes,
                  onTap: () {
                    HapticService.selectionClick();
                    setState(() => _answers[question] = true);
                  },
                  activeColor: const Color(0xFFE2F163),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: GoogleFonts.outfit(
            color: isSelected ? activeColor : Colors.white54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFE2F163).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE2F163)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Lo Chef sta cucinando...',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Stiamo preparando la tua ricetta\ncon gli ingredienti selezionati.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.white54,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
