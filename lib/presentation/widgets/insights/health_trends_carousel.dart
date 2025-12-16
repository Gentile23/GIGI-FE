import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/health_insights_service.dart';
import 'trend_insight_card.dart';

/// ═══════════════════════════════════════════════════════════
/// HEALTH TRENDS CAROUSEL
/// Horizontal scrollable carousel of health insights for dashboard
/// ═══════════════════════════════════════════════════════════
class HealthTrendsCarousel extends StatefulWidget {
  final VoidCallback? onViewAllTap;

  const HealthTrendsCarousel({super.key, this.onViewAllTap});

  @override
  State<HealthTrendsCarousel> createState() => _HealthTrendsCarouselState();
}

class _HealthTrendsCarouselState extends State<HealthTrendsCarousel> {
  final HealthInsightsService _insightsService = HealthInsightsService();
  List<TrendInsight> _insights = [];
  List<CorrelationInsight> _correlations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    try {
      final insights = await _insightsService.getTrendInsights();
      final correlations = await _insightsService.getCorrelationInsights();

      if (mounted) {
        setState(() {
          _insights = insights;
          _correlations = correlations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CleanTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.insights,
                      color: CleanTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'I tuoi Insights',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              if (widget.onViewAllTap != null)
                GestureDetector(
                  onTap: widget.onViewAllTap,
                  child: Text(
                    'Vedi report →',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Insights carousel
        if (_isLoading)
          _buildLoadingState()
        else if (_insights.isEmpty)
          _buildEmptyState()
        else
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _insights.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: TrendInsightCard(
                    insight: _insights[index],
                    onTap: widget.onViewAllTap,
                  ),
                );
              },
            ),
          ),

        // Correlation insights (compact)
        if (_correlations.isNotEmpty && !_isLoading) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildCorrelationsSection(),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 280,
              decoration: BoxDecoration(
                color: CleanTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CleanTheme.primaryColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: CleanTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CleanTheme.borderSecondary),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.health_and_safety_outlined,
              size: 48,
              color: CleanTheme.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              'Connetti Apple Health',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Per vedere insights personalizzati sui tuoi dati di salute',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CleanTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrelationsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CleanTheme.accentPurple.withValues(alpha: 0.1),
            CleanTheme.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CleanTheme.accentPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔮', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Pattern scoperti',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._correlations
              .take(2)
              .map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          c.insight,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: CleanTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
