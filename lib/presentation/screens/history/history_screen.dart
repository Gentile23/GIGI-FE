import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fitgenius/core/constants/app_colors.dart';
import 'package:fitgenius/core/constants/app_text_styles.dart';
import 'package:fitgenius/providers/workout_log_provider.dart';
import 'package:fitgenius/presentation/widgets/history/workout_stats_card.dart';
import 'package:fitgenius/presentation/screens/history/stats_screen.dart';
import 'package:fitgenius/presentation/screens/history/workout_history_detail_screen.dart';
import 'package:fitgenius/presentation/widgets/history/workout_calendar_widget.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<WorkoutLogProvider>(context, listen: false);
      provider.fetchWorkoutHistory();
      provider.fetchOverviewStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Workout History'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => Container(
                  padding: const EdgeInsets.only(
                    top: 16,
                    left: 16,
                    right: 16,
                    bottom: 32,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text('Workout Calendar', style: AppTextStyles.h5),
                      const SizedBox(height: 16),
                      Consumer<WorkoutLogProvider>(
                        builder: (context, provider, _) {
                          return WorkoutCalendarWidget(
                            workoutLogs: provider.workoutHistory,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<WorkoutLogProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.workoutHistory.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.fetchWorkoutHistory(refresh: true);
              await provider.fetchOverviewStats();
            },
            child: CustomScrollView(
              slivers: [
                // Stats Summary
                SliverToBoxAdapter(child: _buildStatsOverview(provider)),

                // Section Title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Workouts', style: AppTextStyles.h5),
                        TextButton(
                          onPressed: () {
                            // Filter options
                          },
                          child: Text(
                            'Filter',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primaryNeon,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Workout List
                if (provider.workoutHistory.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: AppColors.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No workouts yet',
                            style: AppTextStyles.h6.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a workout to see your history',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final workout = provider.workoutHistory[index];
                      return _buildHistoryCard(context, workout);
                    }, childCount: provider.workoutHistory.length),
                  ),

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsOverview(WorkoutLogProvider provider) {
    final stats = provider.stats;
    if (stats == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: WorkoutStatsCard(
                  label: 'Workouts',
                  value: stats.totalWorkouts.toString(),
                  icon: Icons.fitness_center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WorkoutStatsCard(
                  label: 'Time',
                  value: stats.totalTimeFormatted,
                  icon: Icons.timer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WorkoutStatsCard(
                  label: 'Volume',
                  value: '${(stats.totalVolumeKg / 1000).toStringAsFixed(1)}k',
                  icon: Icons.monitor_weight_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Streak Card
          Card(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.primaryNeon.withOpacity(0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${stats.currentStreak} Day Streak',
                        style: AppTextStyles.h5,
                      ),
                      Text(
                        'Keep it up! Longest: ${stats.longestStreak}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, dynamic workout) {
    // Format date
    final date = workout.completedAt ?? workout.startedAt;
    final dateStr = DateFormat('MMM d, yyyy').format(date);
    final timeStr = DateFormat('HH:mm').format(date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  WorkoutHistoryDetailScreen(workoutLog: workout),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primaryNeon.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    date.day.toString(),
                    style: AppTextStyles.h5.copyWith(
                      color: AppColors.primaryNeon,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.workoutDay?.name ?? 'Workout Session',
                      style: AppTextStyles.h6,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dateStr • $timeStr',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMiniStat(
                          Icons.timer_outlined,
                          workout.durationFormatted,
                        ),
                        const SizedBox(width: 12),
                        _buildMiniStat(
                          Icons.fitness_center,
                          '${workout.totalExercises} Exercises',
                        ),
                        const SizedBox(width: 12),
                        _buildMiniStat(
                          Icons.scale_outlined,
                          '${workout.totalVolume.toInt()} kg',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
