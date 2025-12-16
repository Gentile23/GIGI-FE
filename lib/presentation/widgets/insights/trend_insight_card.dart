import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/health_insights_service.dart';

/// ═══════════════════════════════════════════════════════════
/// TREND INSIGHT CARD
/// Single insight card for the health trends carousel
/// ═══════════════════════════════════════════════════════════
class TrendInsightCard extends StatelessWidget {
  final TrendInsight insight;
  final VoidCallback? onTap;

  const TrendInsightCard({super.key, required this.insight, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(),
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _getAccentColor().withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(insight.emoji, style: const TextStyle(fontSize: 32)),
                if (insight.metric.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      insight.metric,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Title
            Text(
              insight.title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            // Description
            Expanded(
              child: Text(
                insight.description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Type indicator
            Row(
              children: [
                Icon(
                  _getTypeIcon(),
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  _getTypeLabel(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getGradientColors() {
    switch (insight.type) {
      case InsightType.positive:
        return [const Color(0xFF00C853), const Color(0xFF00E676)];
      case InsightType.warning:
        return [const Color(0xFFFF6D00), const Color(0xFFFFAB00)];
      case InsightType.suggestion:
        return [CleanTheme.primaryColor, const Color(0xFF7C4DFF)];
      case InsightType.neutral:
        return [const Color(0xFF455A64), const Color(0xFF78909C)];
    }
  }

  Color _getAccentColor() {
    switch (insight.type) {
      case InsightType.positive:
        return const Color(0xFF00C853);
      case InsightType.warning:
        return const Color(0xFFFF6D00);
      case InsightType.suggestion:
        return CleanTheme.primaryColor;
      case InsightType.neutral:
        return const Color(0xFF455A64);
    }
  }

  IconData _getTypeIcon() {
    switch (insight.type) {
      case InsightType.positive:
        return Icons.check_circle_outline;
      case InsightType.warning:
        return Icons.warning_amber_outlined;
      case InsightType.suggestion:
        return Icons.lightbulb_outline;
      case InsightType.neutral:
        return Icons.info_outline;
    }
  }

  String _getTypeLabel() {
    switch (insight.type) {
      case InsightType.positive:
        return 'OTTIMO';
      case InsightType.warning:
        return 'ATTENZIONE';
      case InsightType.suggestion:
        return 'SUGGERIMENTO';
      case InsightType.neutral:
        return 'INFO';
    }
  }
}
