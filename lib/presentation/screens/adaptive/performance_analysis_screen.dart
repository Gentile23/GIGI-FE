import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/adaptive_training_model.dart';
import '../../../data/services/adaptive_training_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
import 'recommendations_screen.dart';
import 'recovery_tracking_screen.dart';

class PerformanceAnalysisScreen extends StatefulWidget {
  const PerformanceAnalysisScreen({super.key});

  @override
  State<PerformanceAnalysisScreen> createState() =>
      _PerformanceAnalysisScreenState();
}

class _PerformanceAnalysisScreenState extends State<PerformanceAnalysisScreen> {
  late final AdaptiveTrainingService _adaptiveService;
  PerformanceAnalysis? _analysis;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _adaptiveService = AdaptiveTrainingService(ApiClient());
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    setState(() => _isLoading = true);

    final analysis = await _adaptiveService.getAnalysis();

    if (mounted) {
      setState(() {
        _analysis = analysis;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Analisi Performance',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
        actions: [
          CleanIconButton(
            icon: Icons.refresh_outlined,
            onTap: _loadAnalysis,
            hasBorder: false,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: CleanTheme.primaryColor),
            )
          : _analysis == null || !_analysis!.hasData
          ? _buildInsufficientData()
          : RefreshIndicator(
              onRefresh: _loadAnalysis,
              color: CleanTheme.primaryColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBurnoutRiskCard(),
                    const SizedBox(height: 16),
                    _buildVolumeTrendCard(),
                    const SizedBox(height: 16),
                    _buildRPETrendCard(),
                    const SizedBox(height: 16),
                    _buildRecoveryCard(),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                    if (_analysis!.recommendations.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildRecommendationsPreview(),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInsufficientData() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: CleanTheme.textTertiary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.analytics_outlined,
                size: 64,
                color: CleanTheme.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Dati Insufficienti',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completa almeno 3 allenamenti per vedere l\'analisi delle tue performance',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: CleanTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBurnoutRiskCard() {
    final burnoutRisk = _analysis!.burnoutRisk;
    if (burnoutRisk == null) return const SizedBox.shrink();

    final riskLevel = burnoutRisk['risk_level'] as String?;
    final riskScore = burnoutRisk['risk_score'] as int? ?? 0;
    final riskFactors =
        (burnoutRisk['risk_factors'] as List?)?.cast<String>() ?? [];

    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _analysis!.burnoutRiskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: _analysis!.burnoutRiskColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rischio Burnout',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                    Text(
                      riskLevel?.toUpperCase() ?? 'SCONOSCIUTO',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: _analysis!.burnoutRiskColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$riskScore%',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: _analysis!.burnoutRiskColor,
                ),
              ),
            ],
          ),
          if (riskFactors.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: CleanTheme.borderPrimary),
            const SizedBox(height: 12),
            Text(
              'Fattori di Rischio:',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...riskFactors.map(
              (factor) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 6,
                      color: _analysis!.burnoutRiskColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        factor,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: CleanTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVolumeTrendCard() {
    final volumeTrend = _analysis!.volumeTrend;
    if (volumeTrend == null) return const SizedBox.shrink();

    final trend = volumeTrend['trend'] as String?;
    final changePercentage = volumeTrend['change_percentage'] as num? ?? 0;

    IconData trendIcon;
    Color trendColor;

    switch (trend) {
      case 'increasing':
        trendIcon = Icons.trending_up;
        trendColor = CleanTheme.accentGreen;
        break;
      case 'decreasing':
        trendIcon = Icons.trending_down;
        trendColor = CleanTheme.accentRed;
        break;
      default:
        trendIcon = Icons.trending_flat;
        trendColor = CleanTheme.accentBlue;
    }

    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(trendIcon, color: trendColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trend Volume',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CleanTheme.textSecondary,
                  ),
                ),
                Text(
                  trend?.toUpperCase() ?? 'STABILE',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: trendColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${changePercentage > 0 ? '+' : ''}${changePercentage.toStringAsFixed(1)}%',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: trendColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRPETrendCard() {
    final rpeTrend = _analysis!.rpeTrend;
    if (rpeTrend == null) return const SizedBox.shrink();

    final average = rpeTrend['average'] as num? ?? 0;
    final trend = rpeTrend['trend'] as String?;

    Color rpeColor;
    if (average >= 8) {
      rpeColor = CleanTheme.accentRed;
    } else if (average >= 6) {
      rpeColor = CleanTheme.accentOrange;
    } else {
      rpeColor = CleanTheme.accentGreen;
    }

    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: rpeColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fitness_center_outlined,
              color: rpeColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RPE Medio',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CleanTheme.textSecondary,
                  ),
                ),
                Text(
                  '${average.toStringAsFixed(1)}/10',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: rpeColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: rpeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              trend?.toUpperCase() ?? 'STABILE',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: rpeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryCard() {
    final recoveryScore = _analysis!.recoveryScore;
    if (recoveryScore == null) return const SizedBox.shrink();

    final score = recoveryScore['score'] as num? ?? 0.7;
    final readiness = recoveryScore['readiness'] as String? ?? 'moderate';

    Color readinessColor;
    switch (readiness) {
      case 'high':
        readinessColor = CleanTheme.accentGreen;
        break;
      case 'low':
        readinessColor = CleanTheme.accentRed;
        break;
      default:
        readinessColor = CleanTheme.accentOrange;
    }

    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: readinessColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_outline,
              color: readinessColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Punteggio Recupero',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CleanTheme.textSecondary,
                  ),
                ),
                Text(
                  '${(score * 100).toInt()}%',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: readinessColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: readinessColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              readiness.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: readinessColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CleanSectionHeader(title: 'Azioni Rapide'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CleanCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecoveryTrackingScreen(),
                    ),
                  );
                },
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CleanTheme.accentPurple.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.spa_outlined,
                        color: CleanTheme.accentPurple,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Traccia Recupero',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CleanCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecommendationsScreen(),
                    ),
                  );
                },
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CleanTheme.accentOrange.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline,
                        color: CleanTheme.accentOrange,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Vedi Consigli',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendationsPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Raccomandazioni AI',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RecommendationsScreen(),
                  ),
                );
              },
              child: Text(
                'Vedi Tutte',
                style: GoogleFonts.inter(
                  color: CleanTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${_analysis!.recommendations.length} raccomandazion${_analysis!.recommendations.length != 1 ? 'i' : 'e'} disponibil${_analysis!.recommendations.length != 1 ? 'i' : 'e'}',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: CleanTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
