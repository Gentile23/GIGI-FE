import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitgenius/core/theme/clean_theme.dart';
import 'package:fitgenius/providers/workout_log_provider.dart';
import 'package:fitgenius/presentation/widgets/history/workout_stats_card.dart';
import 'package:fitgenius/presentation/screens/history/stats_screen.dart';
import 'package:fitgenius/presentation/screens/history/workout_history_detail_screen.dart';
import 'package:fitgenius/presentation/widgets/history/workout_calendar_widget.dart';
import 'package:fitgenius/presentation/widgets/clean_widgets.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<WorkoutLogProvider>(context, listen: false);
      provider.fetchWorkoutHistory();
      provider.fetchOverviewStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Cronologia',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        actions: [
          CleanIconButton(
            icon: Icons.bar_chart_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatsScreen()),
              );
            },
            hasBorder: false,
          ),
          CleanIconButton(
            icon: Icons.calendar_today_outlined,
            onTap: () => _showCalendarSheet(context),
            hasBorder: false,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<WorkoutLogProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.workoutHistory.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: CleanTheme.primaryColor),
            );
          }

          return RefreshIndicator(
            color: CleanTheme.primaryColor,
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
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: CleanSectionHeader(
                      title: 'Allenamenti Recenti',
                      actionText: 'Filtra',
                      onAction: () {},
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
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: CleanTheme.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.history_outlined,
                              size: 48,
                              color: CleanTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Nessun allenamento',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: CleanTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Inizia un allenamento per vedere la cronologia',
                            style: GoogleFonts.inter(
                              color: CleanTheme.textSecondary,
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

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCalendarSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.only(
          top: 16,
          left: 20,
          right: 20,
          bottom: 32,
        ),
        decoration: const BoxDecoration(
          color: CleanTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: CleanTheme.borderPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Calendario Allenamenti',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
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
  }

  Widget _buildStatsOverview(WorkoutLogProvider provider) {
    final stats = provider.stats;
    if (stats == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: WorkoutStatsCard(
                  label: 'Allenamenti',
                  value: stats.totalWorkouts.toString(),
                  icon: Icons.fitness_center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WorkoutStatsCard(
                  label: 'Tempo',
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
          const SizedBox(height: 16),
          // Streak Card
          CleanCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CleanTheme.accentOrange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: CleanTheme.accentOrange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stats.currentStreak} Giorni di Streak',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Continua così! Record: ${stats.longestStreak}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, dynamic workout) {
    final date = workout.completedAt ?? workout.startedAt;
    final dateStr = DateFormat('d MMM yyyy', 'it').format(date);
    final timeStr = DateFormat('HH:mm').format(date);

    return CleanCard(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                WorkoutHistoryDetailScreen(workoutLog: workout),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: CleanTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                date.day.toString(),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: CleanTheme.primaryColor,
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
                  workout.workoutDay?.name ?? 'Allenamento',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateStr • $timeStr',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CleanTheme.textSecondary,
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
                      '${workout.totalExercises} Es.',
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
          const Icon(
            Icons.chevron_right,
            color: CleanTheme.textTertiary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: CleanTheme.textTertiary),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: CleanTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
