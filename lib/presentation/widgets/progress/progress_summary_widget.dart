import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../screens/progress/progress_dashboard_screen.dart';

/// Compact widget showing progress summary for the home screen
class ProgressSummaryWidget extends StatelessWidget {
  final Map<String, dynamic>? latestMeasurements;
  final Map<String, dynamic>? changes;
  final int streak;
  final int totalMeasurements;

  const ProgressSummaryWidget({
    super.key,
    this.latestMeasurements,
    this.changes,
    this.streak = 0,
    this.totalMeasurements = 0,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = latestMeasurements != null || totalMeasurements > 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProgressDashboardScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              CleanTheme.accentBlue.withValues(alpha: 0.15),
              CleanTheme.accentBlue.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: CleanTheme.accentBlue.withValues(alpha: 0.2),
          ),
        ),
        child: hasData ? _buildWithData(context) : _buildEmpty(context),
      ),
    );
  }

  Widget _buildWithData(BuildContext context) {
    final waistChange = changes?['waist_cm'] as num?;
    final bicepChange = changes?['bicep_right_cm'] as num?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CleanTheme.accentBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: CleanTheme.accentBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'I Tuoi Progressi',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: CleanTheme.textSecondary),
          ],
        ),
        const SizedBox(height: 16),

        // Stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              emoji: '🔥',
              value: '$streak',
              label: 'Streak',
              color: CleanTheme.accentRed,
            ),
            _buildDivider(),
            _buildStatItem(
              emoji: '📏',
              value: '$totalMeasurements',
              label: 'Misure',
              color: CleanTheme.primaryColor,
            ),
            if (waistChange != null) ...[
              _buildDivider(),
              _buildStatItem(
                emoji: waistChange < 0 ? '📉' : '📈',
                value:
                    '${waistChange > 0 ? '+' : ''}${waistChange.toStringAsFixed(1)}',
                label: 'Vita',
                color: waistChange < 0
                    ? CleanTheme.accentGreen
                    : CleanTheme.accentRed,
              ),
            ],
            if (bicepChange != null) ...[
              _buildDivider(),
              _buildStatItem(
                emoji: '💪',
                value:
                    '${bicepChange > 0 ? '+' : ''}${bicepChange.toStringAsFixed(1)}',
                label: 'Bicipite',
                color: bicepChange > 0
                    ? CleanTheme.accentGreen
                    : CleanTheme.accentRed,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CleanTheme.accentBlue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('📏', style: TextStyle(fontSize: 24)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Traccia i tuoi progressi',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
              Text(
                'Aggiungi le tue misure → ',
                style: GoogleFonts.inter(
                  color: CleanTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: CleanTheme.textSecondary),
      ],
    );
  }

  Widget _buildStatItem({
    required String emoji,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: CleanTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 30, color: CleanTheme.borderSecondary);
  }
}
