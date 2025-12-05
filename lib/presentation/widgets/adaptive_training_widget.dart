import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/adaptive_training_model.dart';
import '../../data/services/adaptive_training_service.dart';
import '../../data/services/api_client.dart';
import '../../core/theme/clean_theme.dart';
import '../screens/adaptive/performance_analysis_screen.dart';

class AdaptiveTrainingWidget extends StatefulWidget {
  const AdaptiveTrainingWidget({super.key});

  @override
  State<AdaptiveTrainingWidget> createState() => _AdaptiveTrainingWidgetState();
}

class _AdaptiveTrainingWidgetState extends State<AdaptiveTrainingWidget> {
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
    if (_isLoading || _analysis == null || !_analysis!.hasData) {
      return const SizedBox.shrink();
    }

    final burnoutRisk = _analysis!.burnoutRiskLevel;
    final recommendationsCount = _analysis!.recommendations.length;

    if (burnoutRisk == 'low' && recommendationsCount == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PerformanceAnalysisScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CleanTheme.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _analysis!.burnoutRiskColor.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _analysis!.burnoutRiskColor.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _analysis!.burnoutRiskColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.psychology_outlined,
                    color: _analysis!.burnoutRiskColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Training Insights',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: CleanTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Rischio Burnout: ${burnoutRisk?.toUpperCase()}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _analysis!.burnoutRiskColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: CleanTheme.textTertiary,
                  size: 20,
                ),
              ],
            ),
            if (recommendationsCount > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: CleanTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: CleanTheme.primaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$recommendationsCount nuove raccomandazioni',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
