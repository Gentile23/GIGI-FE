import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';

import 'package:share_plus/share_plus.dart';

class GeneratedMealScreen extends StatefulWidget {
  final Map<String, dynamic> generatedMeal;
  final List<dynamic> portate;

  const GeneratedMealScreen({
    super.key,
    required this.generatedMeal,
    required this.portate,
  });

  @override
  State<GeneratedMealScreen> createState() => _GeneratedMealScreenState();
}

class _GeneratedMealScreenState extends State<GeneratedMealScreen> {
  final Map<int, bool> _expandedIngredients = {};
  final Map<int, bool> _expandedSteps = {};

  void _shareRecipe() {
    HapticService.mediumTap();
    final mealName = widget.generatedMeal['nome_pasto'] ?? 'Menu Chef AI';
    final text =
        "Guarda cosa ha cucinato per me Chef AI di GIGI! 👨‍🍳🔥\n\n"
        "Oggi per me: $mealName\n\n"
        "Ricetta generata in pochi secondi partendo dai miei ingredienti. Scarica GIGI per rivoluzionare la tua cucina fit! 🚀\n\n"
        "Scarica ora: https://gigi-pt.it";

    SharePlus.instance.share(ShareParams(text: text));
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
            _buildMealHeader(),
            const SizedBox(height: 24),
            ...widget.portate.asMap().entries.map(
              (entry) =>
                  _buildCourseCard(entry.value, entry.key, widget.portate.length),
            ),
            if (widget.generatedMeal['consiglio_chef'] != null)
              _buildChefTip(widget.generatedMeal['consiglio_chef']),

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    HapticService.lightTap();
                    Navigator.pop(context); // Go back to generate a new meal
                  },
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
                  icon: const Icon(
                    Icons.replay_rounded,
                    size: 20,
                    color: CleanTheme.primaryColor,
                  ),
                  label: Text(
                    'Nuova Ricerca',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _shareRecipe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CleanTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: CleanTheme.primaryColor.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.share_rounded, size: 20),
                  label: Text(
                    'Condividi',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
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
          'Ecco il tuo Risultato! 🎉',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: CleanTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.generatedMeal['nome_pasto'] ?? 'Menu Chef AI',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: CleanTheme.textPrimary,
          ),
        ),
        if (widget.generatedMeal['descrizione'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.generatedMeal['descrizione'],
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
                      () => _expandedIngredients[index] = !isIngredientsExpanded,
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
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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
