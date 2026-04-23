import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/gigi_guidance_content.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/utils/validation_utils.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/nutrition_service.dart';
import '../../../data/services/quota_service.dart';
import '../../../providers/nutrition_coach_provider.dart';
import '../../../providers/quota_provider.dart';
import '../../widgets/animations/liquid_steel_container.dart';
import '../../widgets/clean_widgets.dart';
import '../../widgets/gigi/gigi_coach_message.dart';
import '../../widgets/quota/quota_banner.dart';

/// Food Duel AI - practical food substitution calculator.
class FoodDuelScreen extends StatefulWidget {
  const FoodDuelScreen({super.key});

  @override
  State<FoodDuelScreen> createState() => _FoodDuelScreenState();
}

class _FoodDuelScreenState extends State<FoodDuelScreen>
    with TickerProviderStateMixin {
  final _foodAController = TextEditingController();
  final _foodBController = TextEditingController();
  final _quantityController = TextEditingController(text: '100');
  final _nutritionService = NutritionService(ApiClient());

  Map<String, dynamic>? _result;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _assumptionsConfirmed = false;
  String _unit = 'g';
  late final AnimationController _gaugeController;

  @override
  void initState() {
    super.initState();
    _gaugeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _foodAController.dispose();
    _foodBController.dispose();
    _quantityController.dispose();
    _gaugeController.dispose();
    super.dispose();
  }

  Future<void> _compare() async {
    if (_isLoading) return;

    final foodA = _foodAController.text.trim();
    final foodB = _foodBController.text.trim();
    final quantity = double.tryParse(
      _quantityController.text.trim().replaceAll(',', '.'),
    );

    if (foodA.isEmpty || foodB.isEmpty || quantity == null) {
      _showSnack('Inserisci alimento A, quantità e alimento B.');
      return;
    }
    if (quantity < 1 || quantity > 3000) {
      _showSnack('La quantità deve essere tra 1 e 3000 $_unit.');
      return;
    }
    if (!ValidationUtils.isReasonableAiText(foodA) ||
        !ValidationUtils.isReasonableAiText(foodB)) {
      _showSnack('Inserisci due alimenti validi.');
      return;
    }

    final provider = Provider.of<NutritionCoachProvider>(
      context,
      listen: false,
    );
    final quotaProvider = context.read<QuotaProvider>();
    final quota = await quotaProvider.canPerform(QuotaAction.foodDuel);
    if (!mounted) return;
    if (!quota.canPerform) {
      _showSnack(
        quota.reason.isNotEmpty
            ? quota.reason
            : 'Limite Food Duel AI raggiunto.',
        color: CleanTheme.accentOrange,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
      _assumptionsConfirmed = false;
    });

    try {
      final rawResult = await provider.calculateEquivalence(
        targetFood: {
          'name': foodA,
          'quantity': quantity,
          'unit': _unit,
          'calories': 0,
          'proteins': 0,
          'carbs': 0,
          'fats': 0,
        },
        userFoodName: foodB,
        mode: 'kcal',
      );
      final result = _normalizeResult(rawResult);

      if (!mounted) return;
      if (result['is_valid'] == true) {
        await quotaProvider.syncAfterSuccess(QuotaAction.foodDuel);
        if (!mounted) return;
      }
      setState(() {
        _result = result;
        _isLoading = false;
        _assumptionsConfirmed =
            (result['requires_confirmation'] as bool?) != true;
      });

      if (result['is_valid'] == true) {
        _gaugeController.forward(from: 0);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Errore nel confronto. Riprova tra poco.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: CleanTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: CleanTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Food Duel AI',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: CleanTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          children: [
            GigiCoachMessage(
              messageId: 'nutrition.food_duel.intro',
              title: 'Sostituzione alimenti',
              message: GigiGuidanceContent.foodDuelIntro(),
              emotion: GigiEmotion.expert,
            ),
            const SizedBox(height: 24),
            const QuotaBanner(action: QuotaAction.foodDuel),
            const SizedBox(height: 24),
            _buildInputs(),
            const SizedBox(height: 24),
            _buildAnalyzeButton(),
            if (_result != null) ...[
              const SizedBox(height: 28),
              if (_result!['is_valid'] == true)
                _buildResult()
              else
                _buildInvalidResult(),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputs() {
    return CleanCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFoodInput(
            controller: _foodAController,
            label: 'ALIMENTO DA SOSTITUIRE',
            hint: 'es. petto di pollo',
            color: CleanTheme.accentGreen,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildQuantityInput()),
              const SizedBox(width: 12),
              _buildUnitToggle(),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Divider(height: 1),
          ),
          _buildFoodInput(
            controller: _foodBController,
            label: 'ALTERNATIVA',
            hint: 'es. salmone',
            color: CleanTheme.accentBlue,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 12),
          Text(
            'Pareggio le calorie e ti mostro quanto cambiano proteine, carboidrati e grassi.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: CleanTheme.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color color,
    required TextInputAction textInputAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textInputAction: textInputAction,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: CleanTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: CleanTheme.textTertiary,
              fontWeight: FontWeight.normal,
            ),
            filled: true,
            fillColor: CleanTheme.chromeSubtle.withValues(alpha: 0.28),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: CleanTheme.borderSecondary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: CleanTheme.borderSecondary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: color, width: 1.2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUANTITÀ',
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: CleanTheme.textSecondary,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _quantityController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: CleanTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
          decoration: InputDecoration(
            suffixText: _unit,
            suffixStyle: GoogleFonts.inter(
              color: CleanTheme.textSecondary,
              fontWeight: FontWeight.w800,
            ),
            filled: true,
            fillColor: CleanTheme.chromeSubtle.withValues(alpha: 0.28),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: CleanTheme.borderSecondary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: CleanTheme.borderSecondary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: CleanTheme.accentGold),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitToggle() {
    return Container(
      margin: const EdgeInsets.only(top: 25),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: CleanTheme.chromeSubtle.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CleanTheme.borderSecondary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_buildUnitButton('g'), _buildUnitButton('ml')],
      ),
    );
  }

  Widget _buildUnitButton(String unit) {
    final selected = _unit == unit;
    return GestureDetector(
      onTap: () => setState(() => _unit = unit),
      child: Container(
        width: 44,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? CleanTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          unit,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : CleanTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _compare,
      child: LiquidSteelContainer(
        borderRadius: 28,
        enableShine: true,
        colors: _isLoading
            ? [CleanTheme.chromeSubtle, CleanTheme.chromeSilver]
            : const [Color(0xFFE5E5EA), Color(0xFFD1D1D6), Color(0xFFE5E5EA)],
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: CleanTheme.textPrimary,
                    ),
                  )
                : Text(
                    'CALCOLA SOSTITUZIONE',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: CleanTheme.textPrimary,
                      letterSpacing: 1.4,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    final target = _extractFoodBlock(_result!, 'target_portion');
    final equivalent = _extractFoodBlock(_result!, 'equivalent_portion');
    final targetName = _readString(
      target,
      'name',
      _foodAController.text.trim(),
    );
    final equivalentName = _readString(
      equivalent,
      'name',
      _foodBController.text.trim(),
    );
    final targetQty = _readDouble(target, 'quantity');
    final equivalentQty = _readDouble(equivalent, 'quantity');
    final unit = _readString(equivalent, 'unit', _unit);
    final score = (_result!['compatibility_score'] as num?)?.toInt() ?? 0;
    final verdictLabel =
        (_result!['verdict_label'] as String?) ?? _scoreLabel(score);
    final verdictMessage =
        (_result!['verdict_message'] as String?) ??
        'Calorie pareggiate. Controlla i macro prima di usarlo come sostituzione abituale.';
    final assumptions = _readStringList(_result!['assumptions']);
    final requiresConfirmation =
        (_result!['requires_confirmation'] as bool?) == true;

    return Column(
      children: [
        CleanCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Text(
                'EQUIVALENZA CALORICA',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: CleanTheme.textSecondary,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${_formatQuantity(targetQty)}$unit $targetName',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: CleanTheme.accentGreen,
                ),
              ),
              const SizedBox(height: 6),
              const Icon(
                Icons.keyboard_double_arrow_down_rounded,
                color: CleanTheme.textTertiary,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatQuantity(equivalentQty)}$unit $equivalentName',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: CleanTheme.accentBlue,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 18),
              _buildVerdict(score, verdictLabel, verdictMessage),
            ],
          ),
        ),
        if (requiresConfirmation || assumptions.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildAssumptionCard(assumptions, requiresConfirmation),
        ],
        const SizedBox(height: 14),
        _buildMacroCard(target, equivalent),
        const SizedBox(height: 14),
        _buildSaveButton(requiresConfirmation),
      ],
    );
  }

  Widget _buildVerdict(int score, String label, String message) {
    return Row(
      children: [
        SizedBox(
          width: 62,
          height: 62,
          child: CustomPaint(
            painter: _ReportGaugePainter(
              score: score,
              color: _scoreColor(score),
            ),
            child: Center(
              child: Text(
                '$score',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: _scoreColor(score),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: CleanTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 1.35,
                  color: CleanTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssumptionCard(List<String> assumptions, bool requiresConfirm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.accentGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: CleanTheme.accentGold.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ASSUNZIONI',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: CleanTheme.accentGold,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: assumptions.isEmpty
                ? [_buildAssumptionChip('versione comune stimata')]
                : assumptions.map(_buildAssumptionChip).toList(),
          ),
          if (requiresConfirm) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _assumptionsConfirmed = true),
              child: Row(
                children: [
                  Icon(
                    _assumptionsConfirmed
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: _assumptionsConfirmed
                        ? CleanTheme.accentGreen
                        : CleanTheme.textTertiary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Confermo queste assunzioni',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssumptionChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CleanTheme.borderSecondary),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: CleanTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMacroCard(
    Map<String, dynamic> target,
    Map<String, dynamic> equivalent,
  ) {
    return CleanCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MACRO DELLA PORZIONE',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: CleanTheme.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildMacroRow('Calorie', target, equivalent, 'kcal', 'kcal'),
          const SizedBox(height: 14),
          _buildMacroRow('Proteine', target, equivalent, 'proteins', 'g'),
          const SizedBox(height: 14),
          _buildMacroRow('Carboidrati', target, equivalent, 'carbs', 'g'),
          const SizedBox(height: 14),
          _buildMacroRow('Grassi', target, equivalent, 'fats', 'g'),
        ],
      ),
    );
  }

  Widget _buildMacroRow(
    String label,
    Map<String, dynamic> target,
    Map<String, dynamic> equivalent,
    String key,
    String unit,
  ) {
    final a = _readDouble(target, key);
    final b = _readDouble(equivalent, key);
    final maxValue = max(max(a, b), 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ),
            Text(
              '${_formatMacro(a, unit)} / ${_formatMacro(b, unit)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: CleanTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(4),
                  ),
                  child: LinearProgressIndicator(
                    value: a / maxValue,
                    backgroundColor: CleanTheme.borderSecondary,
                    valueColor: const AlwaysStoppedAnimation(
                      CleanTheme.accentGreen,
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(4),
                ),
                child: LinearProgressIndicator(
                  value: b / maxValue,
                  backgroundColor: CleanTheme.borderSecondary,
                  valueColor: const AlwaysStoppedAnimation(
                    CleanTheme.accentBlue,
                  ),
                  minHeight: 8,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton(bool requiresConfirmation) {
    final disabled =
        _isSaving || (requiresConfirmation && !_assumptionsConfirmed);
    return GestureDetector(
      onTap: disabled ? null : _showAddToDiarySheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: disabled
              ? CleanTheme.chromeSubtle
              : CleanTheme.accentGreen.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSaving)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(
                Icons.add_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            const SizedBox(width: 8),
            Text(
              requiresConfirmation && !_assumptionsConfirmed
                  ? 'CONFERMA LE ASSUNZIONI'
                  : 'AGGIUNGI AL DIARIO',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddToDiarySheet() async {
    var selectedMealType = _suggestedMealType();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: CleanTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aggiungi al diario',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _mealTypes.entries.map((entry) {
                        final selected = selectedMealType == entry.key;
                        return ChoiceChip(
                          label: Text(entry.value),
                          selected: selected,
                          onSelected: (_) {
                            setModalState(() => selectedMealType = entry.key);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _saveEquivalentMeal(selectedMealType);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CleanTheme.accentGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Salva',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveEquivalentMeal(String mealType) async {
    final result = _result;
    if (result == null || _isSaving) return;

    final equivalent = _extractFoodBlock(result, 'equivalent_portion');
    final name = _readString(equivalent, 'name', _foodBController.text.trim());
    final quantity = _readDouble(equivalent, 'quantity');
    final unit = _readString(equivalent, 'unit', _unit);
    final calories = _readDouble(equivalent, 'kcal').round();
    final proteins = _readDouble(equivalent, 'proteins');
    final carbs = _readDouble(equivalent, 'carbs');
    final fats = _readDouble(equivalent, 'fats');

    setState(() => _isSaving = true);
    try {
      final meal = await _nutritionService.logMeal(
        mealType: mealType,
        totalCalories: calories,
        proteinGrams: proteins,
        carbsGrams: carbs,
        fatGrams: fats,
        notes: 'Aggiunto da Food Duel AI',
        foodItems: [
          {
            'food_name': name,
            'quantity': quantity,
            'unit': unit,
            'calories': calories,
            'protein_grams': proteins,
            'carbs_grams': carbs,
            'fat_grams': fats,
            'source': 'manual',
          },
        ],
      );

      if (!mounted) return;
      setState(() => _isSaving = false);
      if (meal != null) {
        _showSnack(
          'Alimento aggiunto al diario.',
          color: CleanTheme.accentGreen,
        );
      } else {
        _showSnack('Errore nel salvataggio.', color: CleanTheme.accentRed);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack('Errore nel salvataggio.', color: CleanTheme.accentRed);
    }
  }

  Widget _buildInvalidResult() {
    final message =
        _result!['validation_message'] as String? ??
        'Alimento non riconosciuto.';
    return GigiCoachMessage(
      messageId: 'nutrition.food_duel.result.invalid',
      title: 'Input da correggere',
      message: '$message ${GigiGuidanceContent.foodDuelInvalid()}',
      emotion: GigiEmotion.expert,
    );
  }

  Map<String, dynamic> _normalizeResult(Map<String, dynamic> raw) {
    final nested = raw['equivalence'];
    if (nested is Map<String, dynamic>) return nested;
    if (nested is Map) return Map<String, dynamic>.from(nested);
    return raw;
  }

  Map<String, dynamic> _extractFoodBlock(
    Map<String, dynamic> payload,
    String key,
  ) {
    final value = payload[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  double _readDouble(Map<String, dynamic> block, String key) {
    final value = block[key];
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }

  String _readString(Map<String, dynamic> block, String key, String fallback) {
    final value = block[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  String _formatQuantity(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }

  String _formatMacro(double value, String unit) {
    if (unit == 'kcal') return '${value.round()} kcal';
    return '${value.toStringAsFixed(1)}$unit';
  }

  String _suggestedMealType() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'breakfast';
    if (hour >= 11 && hour < 15) return 'lunch';
    if (hour >= 15 && hour < 18) return 'snack';
    return 'dinner';
  }

  Map<String, String> get _mealTypes => const {
    'breakfast': 'Colazione',
    'lunch': 'Pranzo',
    'dinner': 'Cena',
    'snack': 'Snack',
  };

  String _scoreLabel(int score) {
    if (score >= 75) return 'Buona sostituzione';
    if (score >= 50) return 'Sostituzione accettabile';
    return 'Non ideale';
  }

  Color _scoreColor(int score) {
    if (score >= 75) return CleanTheme.accentGreen;
    if (score >= 50) return CleanTheme.accentGold;
    return CleanTheme.accentRed;
  }

  void _showSnack(String message, {Color color = CleanTheme.accentRed}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }
}

class _ReportGaugePainter extends CustomPainter {
  final int score;
  final Color color;

  _ReportGaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = CleanTheme.borderSecondary;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      pi * 2,
      false,
      bgPaint,
    );

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      pi * 2 * (score.clamp(0, 100) / 100),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ReportGaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}
