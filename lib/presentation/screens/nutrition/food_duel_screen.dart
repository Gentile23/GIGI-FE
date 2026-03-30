import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/nutrition_coach_provider.dart';
import '../../../core/theme/clean_theme.dart';

/// Food Duel AI — Compare any two foods head-to-head
/// AI-powered nutritional comparison with wow factor
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
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
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
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12).chain(
      CurveTween(curve: Curves.elasticIn),
    ).animate(_shakeController);
  }

  @override
  void dispose() {
    _foodAController.dispose();
    _foodBController.dispose();
    _gaugeController.dispose();
    _vsController.dispose();
    _shakeController.dispose();
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

    final provider = Provider.of<NutritionCoachProvider>(context, listen: false);

    // Use equivalence endpoint: food A as target (100g baseline), food B as user food
    final result = await provider.calculateEquivalence(
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

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _result = result;
    });

    if (result['is_valid'] == true) {
      _gaugeController.forward(from: 0);
      _vsController.forward(from: 0);
    } else {
      _shakeController.forward(from: 0);
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Food Duel AI',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: CleanTheme.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Hero Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    CleanTheme.steelDark,
                    CleanTheme.steelMid,
                    CleanTheme.steelDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: CleanTheme.steelDark.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('⚔️', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(
                    'Sfida Nutrizionale',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Confronta due alimenti e scopri\nchi vince a colpi di macro!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Food A Input
            _buildFoodInput(
              controller: _foodAController,
              label: 'ALIMENTO A',
              hint: 'es. Pollo alla griglia',
              emoji: '🥊',
              color: CleanTheme.accentGreen,
            ),
            const SizedBox(height: 12),

            // VS Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: CleanTheme.steelDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'VS',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Food B Input
            _buildFoodInput(
              controller: _foodBController,
              label: 'ALIMENTO B',
              hint: 'es. Salmone al forno',
              emoji: '🥊',
              color: CleanTheme.accentBlue,
            ),
            const SizedBox(height: 24),

            // Mode Selection
            Container(
              decoration: BoxDecoration(
                color: CleanTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CleanTheme.borderPrimary),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildModeTab('kcal', 'Per Calorie ⚡', _mode == 'kcal'),
                  _buildModeTab('protein', 'Per Proteine 💪', _mode == 'protein'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Mode Explanation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _mode == 'kcal'
                      ? 'L\'AI calcola quanti grammi del nuovo alimento servono per avere esattamente le stesse calorie della porzione originale.'
                      : 'L\'AI ignora le calorie totali e calcola quanti grammi del nuovo alimento servono per pareggiare i grammi di proteine.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CleanTheme.textSecondary.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Battle Button
            GestureDetector(
              onTap: _isLoading ? null : _compare,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLoading
                        ? [CleanTheme.chromeGray, CleanTheme.chromeGray]
                        : [CleanTheme.steelDark, CleanTheme.primaryColor],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _isLoading
                      ? null
                      : [
                          BoxShadow(
                            color: CleanTheme.primaryColor.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Text('⚔️', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Text(
                      _isLoading ? 'Analisi in corso...' : 'INIZIA IL DUELLO!',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Results
            if (_result != null) ...[
              const SizedBox(height: 32),
              if (_result!['is_valid'] == true)
                _buildDuelResult()
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
    required String emoji,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          TextField(
            controller: controller,
            textInputAction: TextInputAction.next,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: CleanTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: CleanTheme.textSecondary.withValues(alpha: 0.4),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            ),
          ),
        ],
      ),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? CleanTheme.steelDark : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : CleanTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDuelResult() {
    final targetFood = _result!['target_food'] as Map<String, dynamic>? ?? {};
    final userFoodPer100g = _result!['user_food_per_100g'] as Map<String, dynamic>? ?? {};
    final score = (_result!['compatibility_score'] as num?)?.toInt() ?? 0;
    final curiosity = _result!['curiosity'] as String? ?? '';
    final summary = _result!['summary'] as String? ?? '';

    final foodAName = _foodAController.text.trim();
    final foodBName = _foodBController.text.trim();
    final foodAKcal = (targetFood['calories'] as num?)?.toInt() ?? 0;
    final foodBKcal = (userFoodPer100g['kcal'] as num?)?.toInt() ?? 0;

    return AnimatedBuilder(
      animation: _vsController,
      builder: (context, child) {
        final progress = Curves.easeOutBack.transform(_vsController.value);
        return Opacity(
          opacity: _vsController.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.8 + (0.2 * progress),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          // Head-to-head card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CleanTheme.steelDark,
                  CleanTheme.steelMid.withValues(alpha: 0.95),
                  CleanTheme.steelDark,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: CleanTheme.steelDark.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // VS Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            foodAName.length > 12
                                ? '${foodAName.substring(0, 12)}...'
                                : foodAName,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: CleanTheme.accentGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$foodAKcal kcal',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'per 100g',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '⚡',
                        style: GoogleFonts.outfit(fontSize: 20),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            foodBName.length > 12
                                ? '${foodBName.substring(0, 12)}...'
                                : foodBName,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: CleanTheme.accentBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$foodBKcal kcal',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'per 100g',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Macro comparison bars
                _buildDuelMacroBar(
                  'Proteine',
                  (targetFood['proteins'] as num?)?.toDouble() ?? 0,
                  (userFoodPer100g['proteins'] as num?)?.toDouble() ?? 0,
                  CleanTheme.accentGreen,
                  CleanTheme.accentBlue,
                ),
                const SizedBox(height: 14),
                _buildDuelMacroBar(
                  'Carboidrati',
                  (targetFood['carbs'] as num?)?.toDouble() ?? 0,
                  (userFoodPer100g['carbs'] as num?)?.toDouble() ?? 0,
                  CleanTheme.accentGreen,
                  CleanTheme.accentBlue,
                ),
                const SizedBox(height: 14),
                _buildDuelMacroBar(
                  'Grassi',
                  (targetFood['fats'] as num?)?.toDouble() ?? 0,
                  (userFoodPer100g['fats'] as num?)?.toDouble() ?? 0,
                  CleanTheme.accentGreen,
                  CleanTheme.accentBlue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Compatibility Score
          AnimatedBuilder(
            animation: _gaugeController,
            builder: (context, _) {
              final animScore = (score * _gaugeController.value).toInt();
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CleanTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: CleanTheme.borderPrimary),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CustomPaint(
                        painter: _MiniGaugePainter(
                          score: animScore,
                          color: _getScoreColor(score),
                        ),
                        child: Center(
                          child: Text(
                            '$animScore',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: _getScoreColor(score),
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
                            'SIMILARITÀ NUTRIZIONALE',
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
                              fontWeight: FontWeight.w700,
                              color: _getScoreColor(score),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Summary
          if (summary.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CleanTheme.chromeSubtle.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CleanTheme.borderPrimary.withValues(alpha: 0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📊', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      summary,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CleanTheme.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Curiosity Card
          if (curiosity.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    CleanTheme.accentGold.withValues(alpha: 0.12),
                    CleanTheme.accentGreen.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: CleanTheme.accentGold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LO SAPEVI?',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: CleanTheme.accentGold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          curiosity,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: CleanTheme.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDuelMacroBar(
    String label,
    double valueA,
    double valueB,
    Color colorA,
    Color colorB,
  ) {
    final maxVal = [valueA, valueB, 1.0].reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${valueA.toStringAsFixed(1)}g',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: colorA,
              ),
            ),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 1.5,
              ),
            ),
            Text(
              '${valueB.toStringAsFixed(1)}g',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: colorB,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            // Bar A (right-aligned)
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: valueA / maxVal,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation(colorA),
                    minHeight: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Bar B (left-aligned)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: valueB / maxVal,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation(colorB),
                  minHeight: 10,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvalidResult() {
    final message = _result!['validation_message'] as String? ?? 'Alimento non riconosciuto.';
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(sin(_shakeAnimation.value * pi * 2) * 6, 0),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Text('🤔', style: TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 16),
            Text(
              'Hmm...',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: CleanTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Inserisci alimenti veri! 🍕',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CleanTheme.accentOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getScoreLabel(int score) {
    if (score >= 85) return 'Praticamente gemelli!';
    if (score >= 70) return 'Ottimi sostituti';
    if (score >= 50) return 'Abbastanza simili';
    if (score >= 30) return 'Piuttosto diversi';
    return 'Mondi diversi!';
  }

  Color _getScoreColor(int score) {
    if (score >= 75) return CleanTheme.accentGreen;
    if (score >= 50) return CleanTheme.accentGold;
    if (score >= 25) return CleanTheme.accentOrange;
    return CleanTheme.accentRed;
  }
}

/// Mini gauge painter for the score circle
class _MiniGaugePainter extends CustomPainter {
  final int score;
  final Color color;

  _MiniGaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = CleanTheme.chromeSubtle
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.75,
      pi * 1.5,
      false,
      bgPaint,
    );

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = color;

    final sweepAngle = (score / 100) * pi * 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.75,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniGaugePainter oldDelegate) =>
      oldDelegate.score != score || oldDelegate.color != color;
}
