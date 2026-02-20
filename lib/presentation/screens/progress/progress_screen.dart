import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../providers/workout_log_provider.dart';
import 'package:gigi/l10n/app_localizations.dart';

/// ═══════════════════════════════════════════════════════════
/// PROGRESS SCREEN - Unified dashboard for all progress metrics
/// Replaces separate Nutrition and Social tabs
/// Psychology: Single place to see growth = mastery motivation
/// ═══════════════════════════════════════════════════════════
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load real stats from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<WorkoutLogProvider>(context, listen: false);
      provider.fetchOverviewStats();
      provider.fetchWorkoutHistory(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildWorkoutsTab(),
                  _buildNutritionTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<WorkoutLogProvider>(
      builder: (context, provider, _) {
        final stats = provider.stats;
        final weeklyChange = stats != null && stats.totalWorkouts > 0
            ? '+${stats.workoutsThisWeek}'
            : '--';

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context)!.yourProgress,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: CleanTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: CleanTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 16,
                      color: CleanTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$weeklyChange ${AppLocalizations.of(context)!.thisWeek}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: CleanTheme.borderSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: CleanTheme.surfaceColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: CleanTheme.textPrimary,
        unselectedLabelColor: CleanTheme.textTertiary,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: AppLocalizations.of(context)!.overview),
          Tab(text: AppLocalizations.of(context)!.workout),
          Tab(text: AppLocalizations.of(context)!.nutrition),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Summary Card
          _buildWeeklySummaryCard(),
          const SizedBox(height: 20),

          // Stats Grid
          _buildStatsGrid(),
          const SizedBox(height: 24),

          // Weekly Calendar
          Text(
            AppLocalizations.of(context)!.thisWeek,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildWeeklyCalendar(),
          const SizedBox(height: 24),

          // Recent Activity
          Text(
            AppLocalizations.of(context)!.recentActivity,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildWeeklySummaryCard() {
    return Consumer<WorkoutLogProvider>(
      builder: (context, provider, _) {
        final stats = provider.stats;
        final workoutsThisWeek = stats?.workoutsThisWeek ?? 0;
        final totalTimeFormatted = stats?.totalTimeFormatted ?? '0min';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [CleanTheme.primaryColor, CleanTheme.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CleanTheme.textOnDark.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.weeklySummary,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: CleanTheme.textOnDark.withValues(alpha: 0.7),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem(
                    AppLocalizations.of(context)!.workout,
                    '$workoutsThisWeek',
                    '',
                  ),
                  _buildSummaryItem(
                    AppLocalizations.of(context)!.timeLabel,
                    totalTimeFormatted,
                    '',
                  ),
                  _buildSummaryItem(
                    'Volume',
                    stats != null
                        ? '${(stats.totalVolumeKg / 1000).toStringAsFixed(1)}t'
                        : '0',
                    '',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String value, String suffix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: CleanTheme.textOnDark.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: CleanTheme.textOnDark,
              ),
            ),
            if (suffix.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  suffix,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: CleanTheme.textOnDark.withValues(alpha: 0.6),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Consumer<WorkoutLogProvider>(
      builder: (context, provider, _) {
        final stats = provider.stats;
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '🔥',
                AppLocalizations.of(context)!.streakLabel,
                stats != null
                    ? AppLocalizations.of(
                        context,
                      )!.streakDays(stats.currentStreak)
                    : '--',
                CleanTheme.accentOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '💪',
                AppLocalizations.of(context)!.volumeLabel,
                stats != null
                    ? '${stats.totalVolumeKg.toStringAsFixed(0)} kg'
                    : '--',
                CleanTheme.accentGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '🏋️',
                'Totale',
                stats != null ? '${stats.totalWorkouts}' : '--',
                CleanTheme.accentOrange,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
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
              fontSize: 11,
              color: CleanTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendar() {
    return Consumer<WorkoutLogProvider>(
      builder: (context, provider, _) {
        final now = DateTime.now();
        final weekday = now.weekday; // 1 = Monday, 7 = Sunday
        final days = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

        // Determine which days had workouts this week from history
        final completedDays = <int>{};
        for (final log in provider.workoutHistory) {
          if (log.completedAt != null) {
            final logDate = log.startedAt;
            // Check if in the same week
            final daysSinceMonday = now
                .difference(now.subtract(Duration(days: weekday - 1)))
                .inDays;
            if (daysSinceMonday >= 0 && daysSinceMonday < 7) {
              final logWeekday = logDate.weekday;
              if (logDate.isAfter(now.subtract(Duration(days: weekday))) &&
                  logDate.isBefore(now.add(Duration(days: 8 - weekday)))) {
                completedDays.add(logWeekday - 1); // 0-indexed
              }
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CleanTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CleanTheme.borderPrimary),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final isCompleted = completedDays.contains(index);
              final isToday = index == weekday - 1;

              return Column(
                children: [
                  Text(
                    days[index],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isToday
                          ? CleanTheme.primaryColor
                          : CleanTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? CleanTheme.primaryColor
                          : isToday
                          ? CleanTheme.primaryColor.withValues(alpha: 0.1)
                          : CleanTheme.borderSecondary,
                      shape: BoxShape.circle,
                      border: isToday && !isCompleted
                          ? Border.all(color: CleanTheme.primaryColor, width: 2)
                          : null,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : Icons.circle,
                      size: isCompleted ? 18 : 6,
                      color: isCompleted
                          ? CleanTheme.textOnDark
                          : CleanTheme.textTertiary,
                    ),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    return Consumer<WorkoutLogProvider>(
      builder: (context, provider, _) {
        final history = provider.workoutHistory;

        if (history.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: CleanTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CleanTheme.borderPrimary),
            ),
            child: Center(
              child: Text(
                'Nessun allenamento recente',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: CleanTheme.textSecondary,
                ),
              ),
            ),
          );
        }

        // Show last 5 workouts
        final recent = history.take(5).toList();
        return Column(
          children: recent.map((log) {
            final duration = log.completedAt != null
                ? log.completedAt!.difference(log.startedAt)
                : Duration.zero;
            final durationMin = duration.inMinutes;
            final timeAgo = _formatTimeAgo(log.startedAt);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildActivityItem(
                log.workoutDayId ?? 'Allenamento',
                timeAgo,
                '$durationMin min',
                Icons.fitness_center,
                CleanTheme.primaryColor,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Oggi';
    if (diff.inDays == 1) return 'Ieri';
    if (diff.inDays < 7) return '${diff.inDays} giorni fa';
    return '${date.day}/${date.month}';
  }

  Widget _buildActivityItem(
    String title,
    String time,
    String subtitle,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CleanTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutsTab() {
    return Center(
      child: Text(AppLocalizations.of(context)!.workoutProgressComingSoon),
    );
  }

  Widget _buildNutritionTab() {
    return Center(
      child: Text(AppLocalizations.of(context)!.nutritionProgressComingSoon),
    );
  }
}
