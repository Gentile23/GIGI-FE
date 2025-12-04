import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fitgenius/core/constants/app_colors.dart';
import 'package:fitgenius/core/constants/app_text_styles.dart';
import 'package:fitgenius/providers/workout_log_provider.dart';
import 'package:fitgenius/presentation/widgets/history/workout_stats_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _selectedPeriod = 'month'; // week, month, year, all

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchStats();
    });
  }

  Future<void> _fetchStats() async {
    final provider = Provider.of<WorkoutLogProvider>(context, listen: false);
    await provider.fetchOverviewStats(period: _selectedPeriod);
    // Fetch trends if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Consumer<WorkoutLogProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.stats == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = provider.stats;
          if (stats == null) {
            return const Center(child: Text('No statistics available'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Selector
                _buildPeriodSelector(),
                const SizedBox(height: 24),

                // Overview Cards
                Row(
                  children: [
                    Expanded(
                      child: WorkoutStatsCard(
                        label: 'Workouts',
                        value: stats.totalWorkouts.toString(),
                        icon: Icons.fitness_center,
                        iconColor: AppColors.primaryNeon,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: WorkoutStatsCard(
                        label: 'Volume',
                        value:
                            '${(stats.totalVolumeKg / 1000).toStringAsFixed(1)}k',
                        icon: Icons.monitor_weight_outlined,
                        iconColor: AppColors.accentBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: WorkoutStatsCard(
                        label: 'Time',
                        value: stats.totalTimeFormatted,
                        icon: Icons.timer,
                        iconColor: AppColors.accentOrange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: WorkoutStatsCard(
                        label: 'Streak',
                        value: '${stats.currentStreak} days',
                        icon: Icons.local_fire_department,
                        iconColor: AppColors.accentRed,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Volume Chart
                Text('Volume Trend', style: AppTextStyles.h5),
                const SizedBox(height: 16),
                Container(
                  height: 250,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              // Placeholder for dates
                              return Text('', style: AppTextStyles.bodySmall);
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            // Placeholder data
                            const FlSpot(0, 1000),
                            const FlSpot(1, 1500),
                            const FlSpot(2, 1200),
                            const FlSpot(3, 1800),
                            const FlSpot(4, 2000),
                          ],
                          isCurved: true,
                          color: AppColors.primaryNeon,
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primaryNeon.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Muscle Distribution (Placeholder)
                Text('Muscle Distribution', style: AppTextStyles.h5),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      'Muscle distribution chart coming soon',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _buildPeriodButton('Week', 'week'),
          _buildPeriodButton('Month', 'month'),
          _buildPeriodButton('Year', 'year'),
          _buildPeriodButton('All', 'all'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = value;
          });
          _fetchStats();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryNeon : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: isSelected
                  ? AppColors.background
                  : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
