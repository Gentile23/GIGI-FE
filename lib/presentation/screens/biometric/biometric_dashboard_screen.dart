import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/biometric_model.dart';
import '../../../data/services/biometric_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/modern_theme.dart';
import '../../widgets/modern_widgets.dart';

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
      backgroundColor: ModernTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Biometric Dashboard'),
        backgroundColor: ModernTheme.cardColor,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
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
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRecoveryScoreCard() {
    final score = _recoveryScore!;
    final scorePercentage = (score.score * 100).toInt();

    return ModernCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: score.readinessColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite,
                  color: score.readinessColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recovery Score',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    Text(
                      '$scorePercentage%',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: score.readinessColor,
                      ),
                    ),
                    Text(
                      score.readinessLabel,
                      style: TextStyle(
                        fontSize: 14,
                        color: score.readinessColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'Components:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          ...score.components.entries.map((entry) {
            final percentage = (entry.value * 100).toInt();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatComponentName(entry.key),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(entry.value),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildHRVTrendCard() {
    final trend = _hrvTrend!;

    return ModernCard(
      child: Row(
        children: [
          Icon(trend.trendIcon, color: trend.trendColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HRV Trend (7 days)',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                Text(
                  trend.trend.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: trend.trendColor,
                  ),
                ),
                Text(
                  'Avg: ${trend.average.toStringAsFixed(1)} ms',
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
              ],
            ),
          ),
          Text(
            '${trend.changePercentage > 0 ? '+' : ''}${trend.changePercentage.toStringAsFixed(1)}%',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
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
        Text(
          'Latest Metrics',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            if (_latestData!['hrv'] != null)
              _buildMetricCard(
                'HRV',
                '${_latestData!['hrv']['value']} ${_latestData!['hrv']['unit']}',
                Icons.monitor_heart,
                Colors.purple,
              ),
            if (_latestData!['resting_heart_rate'] != null)
              _buildMetricCard(
                'Resting HR',
                '${_latestData!['resting_heart_rate']['value']} ${_latestData!['resting_heart_rate']['unit']}',
                Icons.favorite,
                Colors.red,
              ),
            if (_latestData!['sleep'] != null)
              _buildMetricCard(
                'Sleep',
                '${(_latestData!['sleep']['duration_minutes'] / 60).toStringAsFixed(1)}h',
                Icons.bedtime,
                Colors.blue,
              ),
            if (_latestData!['steps'] != null)
              _buildMetricCard(
                'Steps',
                '${_latestData!['steps']['value'].toInt()}',
                Icons.directions_walk,
                Colors.green,
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
    return ModernCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Insights',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._insights.map(
          (insight) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ModernCard(
              child: Row(
                children: [
                  Icon(insight.icon, color: insight.color, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      insight.message,
                      style: const TextStyle(fontSize: 14),
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
                  // Navigate to sleep tracking
                },
                child: Column(
                  children: [
                    Icon(
                      Icons.bedtime,
                      color: ModernTheme.accentColor,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Log Sleep',
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
                  // Navigate to HRV tracking
                },
                child: Column(
                  children: [
                    Icon(
                      Icons.monitor_heart,
                      color: ModernTheme.accentColor,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Log HRV',
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

  String _formatComponentName(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Color _getScoreColor(double score) {
    if (score >= 0.75) return Colors.green;
    if (score >= 0.5) return Colors.orange;
    return Colors.red;
  }
}
