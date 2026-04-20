import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gigi/core/theme/clean_theme.dart';
import 'package:gigi/core/services/workout_refresh_notifier.dart';
import 'package:gigi/data/models/workout_log_model.dart';
import 'package:gigi/presentation/widgets/clean_widgets.dart';
import 'package:gigi/presentation/widgets/history/workout_calendar_widget.dart';
import 'package:gigi/providers/workout_log_provider.dart';
import 'package:provider/provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _selectedPeriod = 'month';
  late final WorkoutRefreshNotifier _workoutRefreshNotifier;

  @override
  void initState() {
    super.initState();
    _workoutRefreshNotifier = Provider.of<WorkoutRefreshNotifier>(
      context,
      listen: false,
    );
    _workoutRefreshNotifier.addListener(_handleWorkoutRefresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchStats(refreshHistory: true);
    });
  }

  @override
  void dispose() {
    _workoutRefreshNotifier.removeListener(_handleWorkoutRefresh);
    super.dispose();
  }

  void _handleWorkoutRefresh() {
    debugPrint(
      'StatsScreen: received workout refresh v${_workoutRefreshNotifier.version}',
    );
    _fetchStats(refreshHistory: true);
  }

  Future<void> _fetchStats({bool refreshHistory = false}) async {
    final provider = Provider.of<WorkoutLogProvider>(context, listen: false);
    await Future.wait([
      provider.fetchOverviewStats(period: _selectedPeriod),
      provider.fetchWorkoutHistory(refresh: refreshHistory),
    ]);
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _startForPeriod(DateTime now) {
    final today = _startOfDay(now);
    switch (_selectedPeriod) {
      case 'week':
        return today.subtract(const Duration(days: 6));
      case 'month':
        return today.subtract(const Duration(days: 29));
      case 'year':
        return DateTime(today.year, today.month - 11, 1);
      case 'all':
      default:
        return DateTime(2000, 1, 1);
    }
  }

  DateTime _effectiveDate(WorkoutLog log) => log.completedAt ?? log.startedAt;

  List<WorkoutLog> _completedHistory(List<WorkoutLog> history) {
    final logs = history.where((log) => log.completedAt != null).toList();
    logs.sort((a, b) => _effectiveDate(a).compareTo(_effectiveDate(b)));
    return logs;
  }

  List<WorkoutLog> _historyForSelectedPeriod(List<WorkoutLog> history) {
    final now = DateTime.now();
    final periodStart = _startForPeriod(now);
    return _completedHistory(history).where((log) {
      final date = _startOfDay(_effectiveDate(log));
      return !date.isBefore(periodStart) && !date.isAfter(_startOfDay(now));
    }).toList();
  }

  int _activeDays(List<WorkoutLog> logs) {
    final uniqueDays = <String>{};
    for (final log in logs) {
      final date = _startOfDay(_effectiveDate(log));
      uniqueDays.add('${date.year}-${date.month}-${date.day}');
    }
    return uniqueDays.length;
  }

  Map<String, int> _calculateMuscleDistribution(List<WorkoutLog> history) {
    final distribution = <String, int>{};
    
    // Localization map for common muscle groups (fallback)
    const muscleMap = {
      'chest': 'Petto',
      'back': 'Schiena',
      'shoulders': 'Spalle',
      'biceps': 'Bicipiti',
      'triceps': 'Tricipiti',
      'quadriceps': 'Quadricipiti',
      'hamstrings': 'Femorali',
      'glutes': 'Glutei',
      'calves': 'Polpacci',
      'abs': 'Addominali',
      'forearms': 'Avambracci',
      'trapezius': 'Trapezio',
      'lats': 'Dorsali',
      'lower back': 'Zona Lombare',
    };

    for (final log in history) {
      for (final exerciseLog in log.exerciseLogs) {
        final exercise = exerciseLog.exercise;
        if (exercise == null) continue;

        // Primary muscle groups
        for (final muscle in exercise.muscleGroups) {
          final normalized = muscle.toLowerCase().trim();
          final localized = muscleMap[normalized] ?? muscle;
          distribution[localized] = (distribution[localized] ?? 0) + 1;
        }

        // Secondary muscle groups
        for (final muscle in exercise.secondaryMuscleGroups) {
          final normalized = muscle.toLowerCase().trim();
          final localized = muscleMap[normalized] ?? muscle;
          distribution[localized] = (distribution[localized] ?? 0) + 1;
        }
      }
    }
    return distribution;
  }

  double _avgWorkoutsPerWeek(List<WorkoutLog> logs) {
    if (logs.isEmpty) return 0;
    final now = DateTime.now();
    final periodStart = _startForPeriod(now);
    final totalDays = math.max(
      1,
      _startOfDay(now).difference(periodStart).inDays + 1,
    );
    final weeks = totalDays / 7.0;
    return logs.length / weeks;
  }

  String _mostActiveWeekday(List<WorkoutLog> logs) {
    if (logs.isEmpty) return '--';
    final counts = List<int>.filled(7, 0);
    for (final log in logs) {
      counts[_effectiveDate(log).weekday - 1] += 1;
    }
    final maxCount = counts.reduce(math.max);
    if (maxCount <= 0) return '--';
    final index = counts.indexOf(maxCount);
    const labels = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    return labels[index];
  }

  int _countLogsInRange(
    List<WorkoutLog> logs,
    DateTime startInclusive,
    DateTime endInclusive,
  ) {
    return logs.where((log) {
      final date = _startOfDay(_effectiveDate(log));
      return !date.isBefore(startInclusive) && !date.isAfter(endInclusive);
    }).length;
  }

  String _weeklyDeltaLabel(List<WorkoutLog> completedLogs) {
    final today = _startOfDay(DateTime.now());
    final currentStart = today.subtract(const Duration(days: 6));
    final previousStart = today.subtract(const Duration(days: 13));
    final previousEnd = today.subtract(const Duration(days: 7));

    final currentCount = _countLogsInRange(completedLogs, currentStart, today);
    final previousCount = _countLogsInRange(
      completedLogs,
      previousStart,
      previousEnd,
    );
    final delta = currentCount - previousCount;
    if (delta > 0) return '+$delta';
    if (delta < 0) return '$delta';
    return '0';
  }

  List<_TrendBucket> _buildTrendBuckets(List<WorkoutLog> completedLogs) {
    final now = _startOfDay(DateTime.now());
    final buckets = <_TrendBucket>[];

    if (_selectedPeriod == 'week') {
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final count = _countLogsInRange(completedLogs, date, date);
        const weekdayLabel = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];
        buckets.add(
          _TrendBucket(
            label: weekdayLabel[date.weekday - 1],
            value: count.toDouble(),
          ),
        );
      }
      return buckets;
    }

    if (_selectedPeriod == 'month') {
      for (int i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final count = _countLogsInRange(completedLogs, date, date);
        final label = date.day % 5 == 0 || i == 0 ? date.day.toString() : '';
        buckets.add(_TrendBucket(label: label, value: count.toDouble()));
      }
      return buckets;
    }

    final monthCounts = <String, int>{};
    for (final log in completedLogs) {
      final date = _effectiveDate(log);
      final key = '${date.year}-${date.month}';
      monthCounts[key] = (monthCounts[key] ?? 0) + 1;
    }

    for (int i = 11; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final key = '${monthDate.year}-${monthDate.month}';
      final count = monthCounts[key] ?? 0;
      final label = _shortMonthLabel(monthDate.month);
      buckets.add(_TrendBucket(label: label, value: count.toDouble()));
    }
    return buckets;
  }

  String _shortMonthLabel(int month) {
    const labels = [
      'Gen',
      'Feb',
      'Mar',
      'Apr',
      'Mag',
      'Giu',
      'Lug',
      'Ago',
      'Set',
      'Ott',
      'Nov',
      'Dic',
    ];
    return labels[(month - 1).clamp(0, 11)];
  }

  String _periodTitle() {
    switch (_selectedPeriod) {
      case 'week':
        return 'Ultimi 7 giorni';
      case 'month':
        return 'Ultimi 30 giorni';
      case 'year':
        return 'Ultimi 12 mesi';
      case 'all':
      default:
        return 'Panoramica completa';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Statistiche',
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
      body: Consumer<WorkoutLogProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.stats == null) {
            return const Center(
              child: CircularProgressIndicator(color: CleanTheme.primaryColor),
            );
          }

          final stats = provider.stats;
          if (stats == null) {
            return Center(
              child: Text(
                'Nessuna statistica disponibile',
                style: GoogleFonts.inter(color: CleanTheme.textSecondary),
              ),
            );
          }

          final completedLogs = _completedHistory(provider.workoutHistory);
          final periodLogs = _historyForSelectedPeriod(provider.workoutHistory);
          final activeDays = _activeDays(periodLogs);
          final sessionsPerActiveDay = activeDays > 0
              ? (periodLogs.length / activeDays)
              : 0.0;
          final weeklyDelta = _weeklyDeltaLabel(completedLogs);
          final avgPerWeek = _avgWorkoutsPerWeek(periodLogs);
          final mostActiveWeekday = _mostActiveWeekday(periodLogs);
          final trendBuckets = _buildTrendBuckets(periodLogs);

          final statsItems = [
            _StatItem(
              label: 'Allenamenti',
              value: stats.totalWorkouts.toString(),
              icon: Icons.fitness_center_outlined,
              color: CleanTheme.primaryColor,
            ),
            _StatItem(
              label: 'Volume totale',
              value: '${(stats.totalVolumeKg / 1000).toStringAsFixed(1)}k kg',
              icon: Icons.monitor_weight_outlined,
              color: CleanTheme.accentBlue,
            ),
            _StatItem(
              label: 'Tempo totale',
              value: stats.totalTimeFormatted,
              icon: Icons.timer_outlined,
              color: CleanTheme.accentOrange,
            ),
            _StatItem(
              label: 'Streak attuale',
              value: '${stats.currentStreak} giorni',
              icon: Icons.local_fire_department_outlined,
              color: CleanTheme.accentRed,
            ),
            _StatItem(
              label: 'Record streak',
              value: '${stats.longestStreak} giorni',
              icon: Icons.emoji_events_outlined,
              color: CleanTheme.accentGreen,
            ),
            _StatItem(
              label: 'Workout settimana',
              value: '${stats.workoutsThisWeek}',
              icon: Icons.calendar_view_week_outlined,
              color: CleanTheme.primaryColor,
            ),
            _StatItem(
              label: 'Workout mese',
              value: '${stats.workoutsThisMonth}',
              icon: Icons.calendar_month_outlined,
              color: CleanTheme.accentPurple,
            ),
            _StatItem(
              label: 'Durata media',
              value: '${stats.averageDurationMinutes.toStringAsFixed(0)} min',
              icon: Icons.schedule_outlined,
              color: CleanTheme.accentBlue,
            ),
            _StatItem(
              label: 'Esercizi tracciati',
              value: '${stats.totalExercises}',
              icon: Icons.list_alt_outlined,
              color: CleanTheme.accentOrange,
            ),
            _StatItem(
              label: 'Giorni attivi',
              value: '$activeDays',
              subtitle: _periodTitle(),
              icon: Icons.event_available_outlined,
              color: CleanTheme.accentGreen,
            ),
            _StatItem(
              label: 'Media workout/settimana',
              value: avgPerWeek.toStringAsFixed(1),
              icon: Icons.trending_up_outlined,
              color: CleanTheme.primaryColor,
            ),
            _StatItem(
              label: 'Delta 7g vs 7g',
              value: weeklyDelta,
              subtitle: 'consistenza',
              icon: Icons.compare_arrows_outlined,
              color: CleanTheme.accentPurple,
            ),
            _StatItem(
              label: 'Giorno più attivo',
              value: mostActiveWeekday,
              icon: Icons.today_outlined,
              color: CleanTheme.accentBlue,
            ),
            _StatItem(
              label: 'Sessioni/giorno attivo',
              value: sessionsPerActiveDay.toStringAsFixed(1),
              icon: Icons.insights_outlined,
              color: CleanTheme.accentOrange,
            ),
          ];

          return RefreshIndicator(
            color: CleanTheme.primaryColor,
            onRefresh: () => _fetchStats(refreshHistory: true),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildPeriodSelector(),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    _periodTitle(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatsGrid(statsItems),
                const SizedBox(height: 28),
                CleanSectionHeader(title: 'Calendario Allenamenti'),
                const SizedBox(height: 12),
                WorkoutCalendarWidget(
                  workoutLogs: provider.workoutHistory,
                  showLegend: true,
                  showMonthlyCount: true,
                ),
                const SizedBox(height: 28),
                CleanSectionHeader(title: 'Trend Attività'),
                const SizedBox(height: 14),
                _buildActivityTrendChart(trendBuckets),
                const SizedBox(height: 28),
                CleanSectionHeader(title: 'Distribuzione Muscolare'),
                const SizedBox(height: 14),
                _buildMuscleDistribution(
                  stats.mostTrainedMuscles.isEmpty
                      ? _calculateMuscleDistribution(provider.workoutHistory)
                      : stats.mostTrainedMuscles,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(List<_StatItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.08,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildStatCard(item);
      },
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return CleanCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: item.color.withValues(alpha: 0.8), size: 32),
          const SizedBox(height: 10),
          Text(
            item.value,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label.toUpperCase(),
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: item.color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          if (item.subtitle != null && item.subtitle!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                item.subtitle!,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: CleanTheme.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityTrendChart(List<_TrendBucket> buckets) {
    if (buckets.isEmpty) {
      return CleanCard(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Nessun dato trend disponibile',
          style: GoogleFonts.inter(
            color: CleanTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      );
    }

    final maxValue = buckets.fold<double>(
      0,
      (prev, bucket) => math.max(prev, bucket.value),
    );
    final maxY = math.max(2.0, maxValue + 1.0);

    return CleanCard(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 14),
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: CleanTheme.borderPrimary, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 26,
                  getTitlesWidget: (value, meta) {
                    if (value % 1 != 0) return const SizedBox.shrink();
                    return Text(
                      value.toInt().toString(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: CleanTheme.textTertiary,
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 20,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= buckets.length) {
                      return const SizedBox.shrink();
                    }
                    final label = buckets[index].label;
                    if (label.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: CleanTheme.textTertiary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  buckets.length,
                  (index) => FlSpot(index.toDouble(), buckets[index].value),
                ),
                isCurved: true,
                color: CleanTheme.primaryColor,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: CleanTheme.primaryColor.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMuscleDistribution(Map<String, int> mostTrainedMuscles) {
    if (mostTrainedMuscles.isEmpty) {
      return CleanCard(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Distribuzione non disponibile',
          style: GoogleFonts.inter(
            color: CleanTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      );
    }

    final sorted = mostTrainedMuscles.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = sorted.take(6).toList();
    final maxCount = topEntries.first.value.toDouble();

    return CleanCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: topEntries.map((entry) {
          final progress = maxCount > 0
              ? (entry.value / maxCount).clamp(0.0, 1.0)
              : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.key,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${entry.value})',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CleanTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    color: CleanTheme.primaryColor,
                    backgroundColor: CleanTheme.borderSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Row(
        children: [
          _buildPeriodButton('Settimana', 'week'),
          _buildPeriodButton('Mese', 'month'),
          _buildPeriodButton('Anno', 'year'),
          _buildPeriodButton('Tutto', 'all'),
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
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? CleanTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isSelected ? Colors.white : CleanTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });
}

class _TrendBucket {
  final String label;
  final double value;

  const _TrendBucket({required this.label, required this.value});
}
