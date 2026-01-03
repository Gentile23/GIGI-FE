import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  '+12%',
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
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
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.of(context)!.weeklySummary,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
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
                '4',
                '/5',
              ),
              _buildSummaryItem(
                AppLocalizations.of(context)!.calories,
                '1,840',
                'kcal',
              ),
              _buildSummaryItem(
                AppLocalizations.of(context)!.timeLabel,
                '3h 20m',
                '',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, String suffix) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
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
                color: Colors.white,
              ),
            ),
            if (suffix.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  suffix,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white60),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '🔥',
            AppLocalizations.of(context)!.streakLabel,
            AppLocalizations.of(context)!.streakDays(7),
            const Color(0xFFFF6B35),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '💪',
            AppLocalizations.of(context)!.volumeLabel,
            '+8%',
            const Color(0xFF00D26A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard('⚡', 'PR', '3', const Color(0xFF9B59B6)),
        ),
      ],
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
    final days = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];
    final completed = [true, true, true, true, false, false, false];
    final today = 4; // 0-indexed, Friday

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
          final isCompleted = completed[index];
          final isToday = index == today;

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
                  color: isCompleted ? Colors.white : CleanTheme.textTertiary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      children: [
        _buildActivityItem(
          'Upper Body',
          'Oggi, 18:30',
          '45 min • 320 kcal',
          Icons.fitness_center,
          CleanTheme.primaryColor,
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          'Lower Body',
          'Ieri, 17:45',
          '50 min • 380 kcal',
          Icons.fitness_center,
          CleanTheme.primaryColor,
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          'Nuovo PR: Squat',
          'Ieri',
          '100kg x 5 reps',
          Icons.emoji_events,
          const Color(0xFFFFD700),
        ),
      ],
    );
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
