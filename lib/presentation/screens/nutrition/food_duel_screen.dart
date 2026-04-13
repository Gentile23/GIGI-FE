import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/nutrition_coach_provider.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/animations/liquid_steel_container.dart';
import '../../widgets/clean_widgets.dart';
import '../../widgets/gigi/gigi_coach_message.dart';
import '../../../core/constants/gigi_guidance_content.dart';

/// Food Duel AI — Compare any two foods head-to-head
/// AI-powered nutritional comparison with Gigi Monochrome aesthetic
class FoodDuelScreen extends StatefulWidget {
  const FoodDuelScreen({super.key});

  @override
  State<FoodDuelScreen> createState() => _FoodDuelScreenState();
}

class _FoodDuelScreenState extends State<FoodDuelScreen>
    with TickerProviderStateMixin {
  final _foodAController = TextEditingController();
  final _foodBController = TextEditingController();
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  late AnimationController _gaugeController;
  late AnimationController _vsController;
  String _mode = 'kcal'; // 'kcal' or 'protein'

  @override
  void initState() {
    super.initState();
    _gaugeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _vsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _foodAController.dispose();
    _foodBController.dispose();
    _gaugeController.dispose();
    _vsController.dispose();
    super.dispose();
  }

  Future<void> _compare() async {
    final foodA = _foodAController.text.trim();
    final foodB = _foodBController.text.trim();
    if (foodA.isEmpty || foodB.isEmpty) return;

    setState(() {
      _isLoading = true;
      _result = null;
    });

    final provider = Provider.of<NutritionCoachProvider>(
      context,
      listen: false,
    );

    // Use equivalence endpoint: food A as target (100g baseline), food B as user food
    final rawResult = await provider.calculateEquivalence(
      targetFood: {
        'name': foodA,
        'quantity': 100,
        'calories': 0, // AI will estimate
        'proteins': 0,
        'carbs': 0,
        'fats': 0,
      },
      userFoodName: foodB,
      mode: _mode,
    );
    final result = _normalizeResult(rawResult);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _result = result;
    });

    if (result['is_valid'] == true) {
      _gaugeController.forward(from: 0);
      _vsController.forward(from: 0);
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
          'Analisi Comparativa',
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
            // Coach Intro
            GigiCoachMessage(
              messageId: 'nutrition.food_duel.intro',
              title: 'Confronto alimenti',
              message: GigiGuidanceContent.foodDuelIntro(),
              emotion: GigiEmotion.expert,
            ),
            const SizedBox(height: 24),

            // Inputs Row
            Row(
              children: [
                Expanded(
                  child: _buildFoodInput(
                    controller: _foodAController,
                    label: 'ALIMENTO A',
                    hint: 'es. Pollo',
                    color: CleanTheme.accentGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFoodInput(
                    controller: _foodBController,
                    label: 'ALIMENTO B',
                    hint: 'es. Salmone',
                    color: CleanTheme.accentBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Mode Selection Table-like
            Container(
              decoration: BoxDecoration(
                color: CleanTheme.chromeSubtle.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CleanTheme.borderSecondary),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildModeTab('kcal', 'Per Calorie ⚡', _mode == 'kcal'),
                  _buildModeTab(
                    'protein',
                    'Per Proteine 💪',
                    _mode == 'protein',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Mode Explanation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _mode == 'kcal'
                      ? 'L\'AI calcola quanti grammi del secondo alimento servono per avere le stesse calorie del primo.'
                      : 'L\'AI ignora le calorie e calcola quanti grammi servono per pareggiare le proteine.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CleanTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Analysis Button
            GestureDetector(
              onTap: _isLoading ? null : _compare,
              child: LiquidSteelContainer(
                borderRadius: 28,
                enableShine: true,
                colors: _isLoading
                    ? [CleanTheme.chromeSubtle, CleanTheme.chromeSilver]
                    : const [
                        Color(0xFFE5E5EA),
                        Color(0xFFD1D1D6),
                        Color(0xFFE5E5EA),
                      ],
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
                            'ESEGUI ANALISI',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: CleanTheme.textPrimary,
                              letterSpacing: 2,
                            ),
                          ),
                  ),
                ),
              ),
            ),

            // Results Section
            if (_result != null) ...[
              const SizedBox(height: 32),
              if (_result!['is_valid'] == true)
                _buildReportResult()
              else
                _buildInvalidResult(),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1.5,
            ),
          ),
        ),
        CleanCard(
          padding: EdgeInsets.zero,
          borderRadius: 16,
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.next,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: CleanTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: CleanTheme.textTertiary,
                fontWeight: FontWeight.normal,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeTab(String mode, String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _mode = mode;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? CleanTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : CleanTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportResult() {
    final targetFood = _extractFoodBlock(
      _result!,
      primaryKey: 'target_food',
      fallbackKeys: const ['target_food_per_100g', 'target', 'food_a'],
    );
    final userFoodPer100g = _extractFoodBlock(
      _result!,
      primaryKey: 'user_food_per_100g',
      fallbackKeys: const ['user_food', 'food_b', 'comparison_food'],
    );
    final score = (_result!['compatibility_score'] as num?)?.toInt() ?? 0;
    final curiosity = _result!['curiosity'] as String? ?? '';
    final summary = _result!['summary'] as String? ?? '';

    final foodAName = _foodAController.text.trim();
    final foodBName = _foodBController.text.trim();
    final foodAKcal = _readNutrientInt(targetFood, const [
      'kcal',
      'calories',
      'cal',
    ]);
    final foodBKcal = _readNutrientInt(userFoodPer100g, const [
      'kcal',
      'calories',
      'cal',
    ]);

    return Column(
      children: [
        // AI Summary Message
        GigiCoachMessage(
          messageId: 'nutrition.food_duel.result.summary',
          title: 'Come leggere il risultato',
          message: summary.isEmpty
              ? GigiGuidanceContent.foodDuelResult()
              : '$summary\n\n${GigiGuidanceContent.foodDuelResult()}',
          emotion: score >= 70 ? GigiEmotion.happy : GigiEmotion.expert,
        ),
        const SizedBox(height: 24),

        // Comparison Report Card
        CleanCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'REPORT NUTRIZIONALE',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: CleanTheme.textSecondary,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'Valori per 100g',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: CleanTheme.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Header Alimenti
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          foodAName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: CleanTheme.accentGreen,
                          ),
                        ),
                        Text(
                          '$foodAKcal kcal',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.swap_horiz_rounded,
                      color: CleanTheme.textTertiary,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          foodBName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: CleanTheme.accentBlue,
                          ),
                        ),
                        Text(
                          '$foodBKcal kcal',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(height: 1),
              ),

              // Macro Rows
              _buildReportMacroRow(
                'Proteine',
                _readNutrientDouble(targetFood, const [
                  'proteins',
                  'protein',
                  'prot',
                ]),
                _readNutrientDouble(userFoodPer100g, const [
                  'proteins',
                  'protein',
                  'prot',
                ]),
                CleanTheme.accentGreen,
                CleanTheme.accentBlue,
              ),
              const SizedBox(height: 24),
              _buildReportMacroRow(
                'Carboidrati',
                _readNutrientDouble(targetFood, const [
                  'carbs',
                  'carb',
                  'carbohydrates',
                ]),
                _readNutrientDouble(userFoodPer100g, const [
                  'carbs',
                  'carb',
                  'carbohydrates',
                ]),
                CleanTheme.accentGreen,
                CleanTheme.accentBlue,
              ),
              const SizedBox(height: 24),
              _buildReportMacroRow(
                'Grassi',
                _readNutrientDouble(targetFood, const ['fats', 'fat']),
                _readNutrientDouble(userFoodPer100g, const ['fats', 'fat']),
                CleanTheme.accentGreen,
                CleanTheme.accentBlue,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Score Card — Simple & Pro
        CleanCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CustomPaint(
                  painter: _ReportGaugePainter(
                    score: score,
                    color: _getScoreColor(score),
                  ),
                  child: Center(
                    child: Text(
                      '$score%',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _getScoreColor(score),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMPATIBILITÀ',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: CleanTheme.textSecondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getScoreLabel(score),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Curiosity Insight
        if (curiosity.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CleanTheme.accentGold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: CleanTheme.accentGold.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ANALISI COACH GIGI',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: CleanTheme.accentGold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        curiosity,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: CleanTheme.textPrimary,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReportMacroRow(
    String label,
    double valA,
    double valB,
    Color colorA,
    Color colorB,
  ) {
    final maxVal = [valA, valB, 1.0].reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: CleanTheme.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            Row(
              children: [
                Text(
                  valA.toStringAsFixed(1),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorA,
                  ),
                ),
                const Text(
                  ' / ',
                  style: TextStyle(
                    fontSize: 10,
                    color: CleanTheme.textTertiary,
                  ),
                ),
                Text(
                  valB.toStringAsFixed(1),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorB,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
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
                    value: valA / maxVal,
                    backgroundColor: CleanTheme.borderSecondary,
                    valueColor: AlwaysStoppedAnimation(colorA),
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
                  value: valB / maxVal,
                  backgroundColor: CleanTheme.borderSecondary,
                  valueColor: AlwaysStoppedAnimation(colorB),
                  minHeight: 8,
                ),
              ),
            ),
          ],
        ),
      ],
    );
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
    if (nested is Map<String, dynamic>) {
      return nested;
    }
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    return raw;
  }

  Map<String, dynamic> _extractFoodBlock(
    Map<String, dynamic> payload, {
    required String primaryKey,
    List<String> fallbackKeys = const [],
  }) {
    final keys = [primaryKey, ...fallbackKeys];
    for (final key in keys) {
      final value = payload[key];
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
    }
    return const {};
  }

  int _readNutrientInt(Map<String, dynamic> block, List<String> keys) {
    return _readNutrientDouble(block, keys).round();
  }

  double _readNutrientDouble(Map<String, dynamic> block, List<String> keys) {
    for (final key in keys) {
      final value = block[key];
      final parsed = _toDouble(value);
      if (parsed != null) return parsed;
    }
    return 0;
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.trim().replaceAll(',', '.');
      if (normalized.isEmpty) return null;
      return double.tryParse(normalized);
    }
    return null;
  }

  String _getScoreLabel(int score) {
    if (score >= 85) return 'Profilo quasi identico';
    if (score >= 70) return 'Ottima compatibilità';
    if (score >= 50) return 'Discreta affinità';
    if (score >= 30) return 'Valori divergenti';
    return 'Profili incompatibili';
  }

  Color _getScoreColor(int score) {
    if (score >= 75) return CleanTheme.accentGreen;
    if (score >= 50) return CleanTheme.accentGold;
    return CleanTheme.accentRed;
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
      (score / 100) * pi * 2,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ReportGaugePainter oldDelegate) =>
      oldDelegate.score != score;
}
