import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/adaptive_training_model.dart';
import '../../../data/services/adaptive_training_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/modern_theme.dart';
import '../../widgets/modern_widgets.dart';
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
      backgroundColor: ModernTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Performance Analysis'),
        backgroundColor: ModernTheme.cardColor,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAnalysis),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analysis == null || !_analysis!.hasData
          ? _buildInsufficientData()
          : RefreshIndicator(
              onRefresh: _loadAnalysis,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
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
            Icon(Icons.analytics_outlined, size: 80, color: Colors.white24),
            const SizedBox(height: 24),
            Text(
              'Insufficient Data',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete at least 3 workouts to see your performance analysis',
              style: Theme.of(context).textTheme.bodyMedium,
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

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _analysis!.burnoutRiskColor.withOpacity(0.2),
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
                      'Burnout Risk',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      riskLevel?.toUpperCase() ?? 'UNKNOWN',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
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
                  fontWeight: FontWeight.bold,
                  color: _analysis!.burnoutRiskColor,
                ),
              ),
            ],
          ),
          if (riskFactors.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Risk Factors:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
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
                      child: Text(factor, style: const TextStyle(fontSize: 13)),
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
        trendColor = Colors.green;
        break;
      case 'decreasing':
        trendIcon = Icons.trending_down;
        trendColor = Colors.red;
        break;
      default:
        trendIcon = Icons.trending_flat;
        trendColor = Colors.blue;
    }

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(trendIcon, color: trendColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Volume Trend',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    Text(
                      trend?.toUpperCase() ?? 'STABLE',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${changePercentage > 0 ? '+' : ''}${changePercentage.toStringAsFixed(1)}%',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: trendColor,
                ),
              ),
            ],
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
      rpeColor = Colors.red;
    } else if (average >= 6) {
      rpeColor = Colors.orange;
    } else {
      rpeColor = Colors.green;
    }

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, color: rpeColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Average RPE',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    Text(
                      '${average.toStringAsFixed(1)}/10',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: rpeColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: rpeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trend?.toUpperCase() ?? 'STABLE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: rpeColor,
                  ),
                ),
              ),
            ],
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
        readinessColor = Colors.green;
        break;
      case 'low':
        readinessColor = Colors.red;
        break;
      default:
        readinessColor = Colors.orange;
    }

    return ModernCard(
      child: Row(
        children: [
          Icon(Icons.favorite, color: readinessColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recovery Score',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                Text(
                  '${(score * 100).toInt()}%',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: readinessColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: readinessColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              readiness.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
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
        Text(
          'Quick Actions',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ModernCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecoveryTrackingScreen(),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Icon(Icons.spa, color: ModernTheme.accentColor, size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      'Track Recovery',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ModernCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RecommendationsScreen(),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: ModernTheme.accentColor,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'View Tips',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
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
              'AI Recommendations',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
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
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${_analysis!.recommendations.length} recommendation${_analysis!.recommendations.length != 1 ? 's' : ''} available',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
