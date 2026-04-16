import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/health_insights_service.dart';
import '../../../core/services/haptic_service.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';

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
  bool _isLoading = true;
  bool _isConnecting = false;
  bool _isInstalling = false;
  bool _healthConnectInstalled = true;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    try {
      final isAndroid = _insightsService.isAndroidPlatform;
      final healthConnectInstalled = isAndroid
          ? await _insightsService.isHealthConnectInstalled()
          : true;
      final isConnected = await _insightsService.initialize();
      final report = await _insightsService.generateWeeklyReport();

      if (mounted) {
        setState(() {
          _report = report;
          _healthConnectInstalled = healthConnectInstalled;
          _isConnected = isConnected;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _installHealthConnect() async {
    setState(() => _isInstalling = true);
    await _insightsService.installHealthConnect();
    final installed = await _insightsService.isHealthConnectInstalled();

    if (!mounted) return;

    setState(() {
      _healthConnectInstalled = installed;
      _isInstalling = false;
    });
  }

  Future<void> _connectHealth() async {
    setState(() => _isConnecting = true);

    final authorized = await _insightsService.connectHealth();

    if (!mounted) return;

    setState(() => _isConnecting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          authorized
              ? '${_insightsService.platformName} connesso'
              : 'Permessi Health non concessi',
        ),
        backgroundColor: authorized
            ? CleanTheme.accentGreen
            : CleanTheme.accentOrange,
      ),
    );

    if (authorized) {
      setState(() => _isLoading = true);
      await _loadReport();
    }
  }

  void _shareReport() {
    HapticService.lightTap();

    if (_report == null) return;

    final hasHealthData = _report!.hasHealthData;
    final sleepValue = hasHealthData
        ? '${_report!.sleep.avgHours.toStringAsFixed(1)}h${AppLocalizations.of(context)!.perNight}'
        : AppLocalizations.of(context)!.noDataAvailable;
    final stepsValue = hasHealthData
        ? '${_report!.activity.avgDailySteps}${AppLocalizations.of(context)!.perDay}'
        : AppLocalizations.of(context)!.noDataAvailable;
    final hrValue = hasHealthData
        ? '${_report!.heartRate.restingAvg} bpm'
        : AppLocalizations.of(context)!.noDataAvailable;

    final text =
        '''
📊 ${AppLocalizations.of(context)!.myWeeklyReport}

😴 ${AppLocalizations.of(context)!.sleep}: $sleepValue
🚶 ${AppLocalizations.of(context)!.steps}: $stepsValue  
💪 ${AppLocalizations.of(context)!.workouts}: ${_report!.activity.workoutsCompleted} ${AppLocalizations.of(context)!.completed}
❤️ ${AppLocalizations.of(context)!.heartRate}: $hrValue

💡 ${_report!.aiTip}

#GIGI #Fitness #HealthTracking
''';

    SharePlus.instance.share(ShareParams(text: text));
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
          backgroundColor: CleanTheme.primaryColor,
          iconTheme: const IconThemeData(color: CleanTheme.textOnDark),
          title: Text(
            AppLocalizations.of(context)!.weeklyReport,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              color: CleanTheme.textOnDark,
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [CleanTheme.primaryColor, CleanTheme.primaryLight],
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
                                  AppLocalizations.of(context)!.weeklyReport,
                                  style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: CleanTheme.textOnDark,
                                  ),
                                ),
                                Text(
                                  _formatPeriod(),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: CleanTheme.textOnDark.withValues(
                                      alpha: 0.7,
                                    ),
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
              icon: const Icon(Icons.share, color: CleanTheme.textOnDark),
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
                _buildSectionTitle(
                  '😴',
                  AppLocalizations.of(context)!.sleepTrend,
                ),
                const SizedBox(height: 12),
                _buildSleepChart(),

                const SizedBox(height: 24),

                // Activity summary
                _buildSectionTitle(
                  '🚶',
                  AppLocalizations.of(context)!.activity,
                ),
                const SizedBox(height: 12),
                _buildActivityCard(),

                const SizedBox(height: 24),

                // Insights
                _buildSectionTitle(
                  '💡',
                  AppLocalizations.of(context)!.aiInsights,
                ),
                const SizedBox(height: 12),
                _buildInsightsList(),

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
    final dateFormat = DateFormat(
      'd MMM',
      AppLocalizations.of(context)!.localeName,
    );
    return '${dateFormat.format(_report!.periodStart)} - ${dateFormat.format(_report!.periodEnd)}';
  }

  Widget _buildStatsGrid() {
    final hasHealthData = _report!.hasHealthData;

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
            hasHealthData
                ? '${_report!.sleep.avgHours.toStringAsFixed(1)}h'
                : '-',
            AppLocalizations.of(context)!.avgSleep,
            hasHealthData ? _getTrendIcon(_report!.sleep.trend) : null,
          ),
          _buildDivider(),
          _buildStatItem(
            '🚶',
            hasHealthData
                ? '${(_report!.activity.avgDailySteps / 1000).toStringAsFixed(1)}k'
                : '-',
            AppLocalizations.of(context)!.stepsPerDay,
            null,
          ),
          _buildDivider(),
          _buildStatItem(
            '💪',
            '${_report!.activity.workoutsCompleted}',
            AppLocalizations.of(context)!.workouts,
            null,
          ),
          _buildDivider(),
          _buildStatItem(
            '❤️',
            hasHealthData ? '${_report!.heartRate.restingAvg}' : '-',
            AppLocalizations.of(context)!.hrBpm,
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
    if (!_report!.hasHealthData) {
      return _buildMissingHealthDataCard(
        message: 'Nessun dato sonno disponibile questa settimana.',
      );
    }

    final sleepData = _report!.sleep.dailyHours.values.toList();
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
            final value = index < sleepData.length ? sleepData[index] : 0.0;
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
    if (!_report!.hasHealthData) {
      return _buildMissingHealthDataCard(
        message: 'Nessun dato passi disponibile questa settimana.',
      );
    }

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
                AppLocalizations.of(context)!.totalSteps,
                style: GoogleFonts.inter(color: CleanTheme.textSecondary),
              ),
              Text(
                NumberFormat('#,###').format(_report!.activity.totalSteps),
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
            AppLocalizations.of(context)!.weeklyStepGoal,
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

  Widget _buildAITip() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [CleanTheme.primaryColor, CleanTheme.primaryLight],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CleanTheme.primaryColor.withValues(alpha: 0.4),
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
                AppLocalizations.of(context)!.gigiTip,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textOnDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _report!.aiTip,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: CleanTheme.textOnDark.withValues(alpha: 0.95),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingHealthDataCard({required String message}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: CleanTheme.textTertiary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CleanTheme.textSecondary,
                height: 1.45,
              ),
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
            Icon(
              _isConnected
                  ? Icons.sync_problem_rounded
                  : Icons.health_and_safety_outlined,
              size: 80,
              color: CleanTheme.textTertiary,
            ),
            const SizedBox(height: 24),
            Text(
              _isConnected
                  ? 'Nessun dato trovato'
                  : AppLocalizations.of(context)!.noDataAvailable,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isConnected
                  ? 'Abbiamo i permessi ma non troviamo dati per questa settimana. Assicurati che i dati siano presenti in ${_insightsService.platformName}.'
                  : (_healthConnectInstalled
                      ? (_insightsService.isAndroidPlatform
                          ? AppLocalizations.of(context)!.syncHealthConnect
                          : AppLocalizations.of(context)!.syncAppleHealth)
                      : AppLocalizations.of(context)!.installHealthConnectInfo),
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConnecting || _isInstalling
                    ? null
                    : (_isConnected
                        ? _loadReport
                        : (_healthConnectInstalled
                            ? _connectHealth
                            : _installHealthConnect)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CleanTheme.primaryColor,
                  foregroundColor: CleanTheme.textOnDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isConnecting || _isInstalling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CleanTheme.textOnDark,
                        ),
                      )
                    : Text(
                        _isConnected
                            ? 'Riprova sincronizzazione'
                            : (_healthConnectInstalled
                                ? AppLocalizations.of(
                                    context,
                                  )!.connectTo(_insightsService.platformName)
                                : AppLocalizations.of(
                                    context,
                                  )!.installHealthConnect),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
