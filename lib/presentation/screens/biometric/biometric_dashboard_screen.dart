import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/biometric_model.dart';
import '../../../data/services/biometric_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';

class BiometricDashboardScreen extends StatefulWidget {
  const BiometricDashboardScreen({super.key});

  @override
  State<BiometricDashboardScreen> createState() =>
      _BiometricDashboardScreenState();
}

class _BiometricDashboardScreenState extends State<BiometricDashboardScreen> {
  late final BiometricService _biometricService;

  EnhancedRecoveryScore? _recoveryScore;
  HRVTrend? _hrvTrend;
  List<BiometricInsight> _insights = [];
  Map<String, dynamic>? _latestData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _biometricService = BiometricService(ApiClient());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final insights = await _biometricService.getInsights();

    if (mounted && insights != null) {
      setState(() {
        _recoveryScore = insights['recovery_score'];
        _hrvTrend = insights['hrv_trend'];
        _insights = insights['insights'] as List<BiometricInsight>;
        _latestData = insights['latest_data'];
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Dati Biometrici',
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
            onTap: _loadData,
            hasBorder: false,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: CleanTheme.primaryColor),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: CleanTheme.primaryColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_recoveryScore != null) ...[
                      _buildRecoveryScoreCard(),
                      const SizedBox(height: 16),
                    ],

                    if (_hrvTrend != null) ...[
                      _buildHRVTrendCard(),
                      const SizedBox(height: 16),
                    ],

                    if (_latestData != null) ...[
                      _buildLatestDataGrid(),
                      const SizedBox(height: 16),
                    ],

                    if (_insights.isNotEmpty) ...[
                      _buildInsightsSection(),
                      const SizedBox(height: 16),
                    ],

                    _buildQuickActions(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRecoveryScoreCard() {
    final score = _recoveryScore!;
    final scorePercentage = (score.score * 100).toInt();

    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: score.readinessColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: score.readinessColor,
                  size: 32,
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
                      '$scorePercentage%',
                      style: GoogleFonts.outfit(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: score.readinessColor,
                      ),
                    ),
                    Text(
                      score.readinessLabel,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: score.readinessColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: CleanTheme.borderPrimary),
          const SizedBox(height: 16),
          Text(
            'Componenti',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...score.components.entries.map((entry) {
            final percentage = (entry.value * 100).toInt();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatComponentName(entry.key),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getScoreColor(entry.value),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHRVTrendCard() {
    final trend = _hrvTrend!;

    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: trend.trendColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(trend.trendIcon, color: trend.trendColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trend HRV (7 giorni)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CleanTheme.textSecondary,
                  ),
                ),
                Text(
                  trend.trend.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: trend.trendColor,
                  ),
                ),
                Text(
                  'Media: ${trend.average.toStringAsFixed(1)} ms',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CleanTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${trend.changePercentage > 0 ? '+' : ''}${trend.changePercentage.toStringAsFixed(1)}%',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: trend.trendColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestDataGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CleanSectionHeader(title: 'Metriche Recenti'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            if (_latestData!['hrv'] != null)
              _buildMetricCard(
                'HRV',
                '${_latestData!['hrv']['value']} ${_latestData!['hrv']['unit']}',
                Icons.monitor_heart_outlined,
                CleanTheme.accentPurple,
              ),
            if (_latestData!['heart_rate'] != null)
              _buildMetricCard(
                'Frequenza Cardiaca',
                '${_latestData!['heart_rate']['value']} ${_latestData!['heart_rate']['unit']}',
                Icons.favorite_outline,
                CleanTheme.accentRed,
              ),
            if (_latestData!['sleep'] != null)
              _buildMetricCard(
                'Sonno',
                '${(_latestData!['sleep']['duration_minutes'] / 60).toStringAsFixed(1)}h',
                Icons.bedtime_outlined,
                CleanTheme.accentBlue,
              ),
            if (_latestData!['steps'] != null)
              _buildMetricCard(
                'Passi',
                '${_latestData!['steps']['value'].toInt()}',
                Icons.directions_walk_outlined,
                CleanTheme.accentGreen,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return CleanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: CleanTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CleanSectionHeader(title: 'AI Insights'),
        const SizedBox(height: 12),
        ..._insights.map(
          (insight) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CleanCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: insight.color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(insight.icon, color: insight.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      insight.message,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
                onTap: () {},
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CleanTheme.accentBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bedtime_outlined,
                        color: CleanTheme.accentBlue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Registra Sonno',
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
                onTap: () {},
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
                        Icons.monitor_heart_outlined,
                        color: CleanTheme.accentPurple,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Registra HRV',
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

  String _formatComponentName(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Color _getScoreColor(double score) {
    if (score >= 0.75) return CleanTheme.accentGreen;
    if (score >= 0.5) return CleanTheme.accentOrange;
    return CleanTheme.accentRed;
  }
}
