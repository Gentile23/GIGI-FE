import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/adaptive_training_model.dart';
import '../../data/services/adaptive_training_service.dart';
import '../../data/services/api_client.dart';
import '../../core/theme/modern_theme.dart';
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _analysis!.burnoutRiskColor.withOpacity(0.3),
              _analysis!.burnoutRiskColor.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _analysis!.burnoutRiskColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: _analysis!.burnoutRiskColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Training Insights',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Burnout Risk: ${burnoutRisk?.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _analysis!.burnoutRiskColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 16),
              ],
            ),
            if (recommendationsCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ModernTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ModernTheme.accentColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: ModernTheme.accentColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$recommendationsCount new recommendation${recommendationsCount != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: ModernTheme.accentColor,
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
