import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fitgenius/core/constants/app_colors.dart';
import 'package:fitgenius/core/constants/app_text_styles.dart';
import 'package:fitgenius/providers/workout_log_provider.dart';

class ExerciseHistoryScreen extends StatefulWidget {
  final String exerciseId;
  final String exerciseName;

  const ExerciseHistoryScreen({
    super.key,
    required this.exerciseId,
    required this.exerciseName,
  });

  @override
  State<ExerciseHistoryScreen> createState() => _ExerciseHistoryScreenState();
}

class _ExerciseHistoryScreenState extends State<ExerciseHistoryScreen> {
  bool _isLoading = true;
  List<FlSpot> _volumeSpots = [];
  List<FlSpot> _maxWeightSpots = [];
  double _maxVolume = 0;
  double _maxWeight = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // In a real app, we would fetch specific exercise history here
    // For now, we'll simulate it or filter from existing history if available
    // Or we can add a method to WorkoutLogProvider to fetch exercise stats

    // Simulating data fetch for now as we didn't implement specific exercise history endpoint yet
    // But we have the structure ready in backend (WorkoutStatsController.exerciseProgress)

    setState(() {
      _isLoading = false;
      // Mock data for demonstration
      _volumeSpots = [
        const FlSpot(0, 1000),
        const FlSpot(1, 1200),
        const FlSpot(2, 1100),
        const FlSpot(3, 1400),
        const FlSpot(4, 1600),
      ];
      _maxWeightSpots = [
        const FlSpot(0, 50),
        const FlSpot(1, 55),
        const FlSpot(2, 55),
        const FlSpot(3, 60),
        const FlSpot(4, 65),
      ];
      _maxVolume = 2000;
      _maxWeight = 80;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.exerciseName),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildChartSection(
                    'Max Weight (kg)',
                    _maxWeightSpots,
                    _maxWeight,
                    AppColors.primaryNeon,
                  ),
                  const SizedBox(height: 24),
                  _buildChartSection(
                    'Volume (kg)',
                    _volumeSpots,
                    _maxVolume,
                    AppColors.accentBlue,
                  ),

                  const SizedBox(height: 32),
                  Text('Personal Records', style: AppTextStyles.h5),
                  const SizedBox(height: 16),
                  _buildPRCard('1RM', '65 kg', DateTime.now()),
                  _buildPRCard(
                    'Max Volume',
                    '1600 kg',
                    DateTime.now().subtract(const Duration(days: 2)),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildChartSection(
    String title,
    List<FlSpot> spots,
    double maxY,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h6),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: spots.length.toDouble() - 1,
                minY: 0,
                maxY: maxY * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.1),
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

  Widget _buildPRCard(String label, String value, DateTime date) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primaryNeon.withOpacity(0.5)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryNeon.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.emoji_events, color: AppColors.primary),
        ),
        title: Text(label, style: AppTextStyles.h6),
        subtitle: Text(
          'Achieved on ${date.day}/${date.month}/${date.year}',
          style: AppTextStyles.bodySmall,
        ),
        trailing: Text(
          value,
          style: AppTextStyles.h5.copyWith(
            color: AppColors.primaryNeon,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
