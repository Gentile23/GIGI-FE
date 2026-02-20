import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gigi/core/theme/clean_theme.dart';
import 'package:gigi/presentation/widgets/clean_widgets.dart';

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
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.exerciseName,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: CleanTheme.textPrimary),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: CleanTheme.primaryColor),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildChartSection(
                    'Peso Massimo (kg)',
                    _maxWeightSpots,
                    _maxWeight,
                    CleanTheme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  _buildChartSection(
                    'Volume (kg)',
                    _volumeSpots,
                    _maxVolume,
                    CleanTheme.accentBlue,
                  ),

                  const SizedBox(height: 32),
                  CleanSectionHeader(title: 'Record Personali'),
                  const SizedBox(height: 16),
                  _buildPRCard('1RM', '65 kg', DateTime.now()),
                  _buildPRCard(
                    'Volume Max',
                    '1600 kg',
                    DateTime.now().subtract(const Duration(days: 2)),
                  ),
                  const SizedBox(height: 24),
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
    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: CleanTheme.borderPrimary, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: CleanTheme.textTertiary,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
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
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: CleanTheme.textOnDark,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.1),
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
    return CleanCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderColor: CleanTheme.primaryColor.withValues(alpha: 0.3),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CleanTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: CleanTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Raggiunto il ${date.day}/${date.month}/${date.year}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: CleanTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
