import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/health_insights_service.dart';
import '../../../core/services/haptic_service.dart';
import 'package:intl/intl.dart';

/// ═══════════════════════════════════════════════════════════
/// WEEKLY REPORT SCREEN
/// Full AI-powered weekly health analysis report
/// ═══════════════════════════════════════════════════════════
class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  final HealthInsightsService _insightsService = HealthInsightsService();
  WeeklyHealthReport? _report;
  List<CorrelationInsight> _correlations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    try {
      final report = await _insightsService.generateWeeklyReport();
      final correlations = await _insightsService.getCorrelationInsights();

      if (mounted) {
        setState(() {
          _report = report;
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

  void _shareReport() {
    HapticService.lightTap();

    if (_report == null) return;

    final text =
        '''
📊 Il mio Report Settimanale GIGI

😴 Sonno: ${_report!.sleep.avgHours.toStringAsFixed(1)}h/notte
🚶 Passi: ${_report!.activity.avgDailySteps}/giorno  
💪 Workout: ${_report!.activity.workoutsCompleted} completati
❤️ HR: ${_report!.heartRate.restingAvg} bpm

💡 ${_report!.aiTip}

#GIGI #Fitness #HealthTracking
''';

    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_report == null) {
      return _buildNoDataState();
    }

    return CustomScrollView(
      slivers: [
        // App bar with gradient
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: const Color(0xFF1A1A2E),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Text('📊', style: TextStyle(fontSize: 32)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Report Settimanale',
                                  style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  _formatPeriod(),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: _shareReport,
            ),
          ],
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats grid
                _buildStatsGrid(),

                const SizedBox(height: 24),

                // Sleep chart
                _buildSectionTitle('😴', 'Andamento Sonno'),
                const SizedBox(height: 12),
                _buildSleepChart(),

                const SizedBox(height: 24),

                // Activity summary
                _buildSectionTitle('🚶', 'Attività'),
                const SizedBox(height: 12),
                _buildActivityCard(),

                const SizedBox(height: 24),

                // Insights
                _buildSectionTitle('💡', 'Insights AI'),
                const SizedBox(height: 12),
                _buildInsightsList(),

                const SizedBox(height: 24),

                // Correlations
                _buildSectionTitle('🔮', 'Pattern Discovery'),
                const SizedBox(height: 12),
                _buildCorrelationsList(),

                const SizedBox(height: 24),

                // AI Tip
                _buildAITip(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatPeriod() {
    if (_report == null) return '';
    final dateFormat = DateFormat('d MMM', 'it');
    return '${dateFormat.format(_report!.periodStart)} - ${dateFormat.format(_report!.periodEnd)}';
  }

  Widget _buildStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '😴',
            '${_report!.sleep.avgHours.toStringAsFixed(1)}h',
            'Sonno medio',
            _getTrendIcon(_report!.sleep.trend),
          ),
          _buildDivider(),
          _buildStatItem(
            '🚶',
            '${(_report!.activity.avgDailySteps / 1000).toStringAsFixed(1)}k',
            'Passi/giorno',
            null,
          ),
          _buildDivider(),
          _buildStatItem(
            '💪',
            '${_report!.activity.workoutsCompleted}',
            'Workout',
            null,
          ),
          _buildDivider(),
          _buildStatItem(
            '❤️',
            '${_report!.heartRate.restingAvg}',
            'HR bpm',
            null,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String emoji,
    String value,
    String label,
    Widget? trend,
  ) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: CleanTheme.textPrimary,
              ),
            ),
            if (trend != null) ...[const SizedBox(width: 4), trend],
          ],
        ),
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
    return Container(width: 1, height: 50, color: CleanTheme.borderSecondary);
  }

  Widget? _getTrendIcon(String trend) {
    if (trend == 'up') {
      return const Icon(
        Icons.trending_up,
        size: 16,
        color: CleanTheme.accentGreen,
      );
    } else if (trend == 'down') {
      return const Icon(
        Icons.trending_down,
        size: 16,
        color: CleanTheme.accentOrange,
      );
    }
    return null;
  }

  Widget _buildSectionTitle(String emoji, String title) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSleepChart() {
    // Mock data for chart
    final sleepData = [6.5, 7.2, 5.8, 7.5, 6.9, 8.1, 7.0];
    final days = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    days[value.toInt()],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CleanTheme.textSecondary,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == 5 || value == 10) {
                    return Text(
                      '${value.toInt()}h',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: CleanTheme.textTertiary,
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 2.5,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: CleanTheme.borderSecondary, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (index) {
            final value = sleepData[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: value,
                  color: value >= 7
                      ? CleanTheme.accentGreen
                      : CleanTheme.accentOrange,
                  width: 24,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildActivityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Passi totali',
                style: GoogleFonts.inter(color: CleanTheme.textSecondary),
              ),
              Text(
                '${NumberFormat('#,###').format(_report!.activity.totalSteps)}',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_report!.activity.totalSteps / 70000).clamp(0, 1),
              backgroundColor: CleanTheme.borderSecondary,
              valueColor: const AlwaysStoppedAnimation(CleanTheme.primaryColor),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Obiettivo: 70.000 passi/settimana',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: CleanTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: _report!.insights
            .map(
              (insight) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        color: CleanTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        insight,
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
            )
            .toList(),
      ),
    );
  }

  Widget _buildCorrelationsList() {
    return Column(
      children: _correlations
          .map(
            (c) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CleanTheme.accentPurple.withValues(alpha: 0.1),
                    CleanTheme.primaryColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CleanTheme.accentPurple.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Text(c.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.insight,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: CleanTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Basato su ${c.dataPoints} giorni di dati',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: CleanTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CleanTheme.accentPurple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(c.correlation * 100).round()}%',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.accentPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildAITip() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                'Consiglio di Gigi',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _report!.aiTip,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.95),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.health_and_safety_outlined,
              size: 80,
              color: CleanTheme.textTertiary,
            ),
            const SizedBox(height: 24),
            Text(
              'Nessun dato disponibile',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connetti Apple Health per generare il tuo report settimanale personalizzato.',
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
