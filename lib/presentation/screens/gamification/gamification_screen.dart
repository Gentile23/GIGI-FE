import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/gamification_model.dart';
import '../../../data/services/gamification_service.dart';
import '../../../data/services/api_client.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen>
    with SingleTickerProviderStateMixin {
  late final GamificationService _gamificationService;
  late TabController _tabController;

  UserStats? _stats;
  List<Achievement> _unlockedAchievements = [];
  List<Achievement> _lockedAchievements = [];
  List<LeaderboardEntry> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _gamificationService = GamificationService(ApiClient());
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final stats = await _gamificationService.getStats();
    final achievements = await _gamificationService.getAchievements();
    final leaderboard = await _gamificationService.getLeaderboard();

    if (mounted) {
      setState(() {
        _stats = stats;
        _unlockedAchievements = achievements?['unlocked'] ?? [];
        _lockedAchievements = achievements?['locked'] ?? [];
        _leaderboard = leaderboard ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Premi & Livelli',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: CleanTheme.primaryColor,
          labelColor: CleanTheme.primaryColor,
          unselectedLabelColor: CleanTheme.textSecondary,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Stats', icon: Icon(Icons.bar_chart_outlined)),
            Tab(text: 'Premi', icon: Icon(Icons.emoji_events_outlined)),
            Tab(text: 'Classifica', icon: Icon(Icons.leaderboard_outlined)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: CleanTheme.primaryColor),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStatsTab(),
                _buildAchievementsTab(),
                _buildLeaderboardTab(),
              ],
            ),
    );
  }

  Widget _buildStatsTab() {
    if (_stats == null) {
      return const Center(child: Text('Nessuna statistica disponibile'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: CleanTheme.primaryColor,
      backgroundColor: CleanTheme.surfaceColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: CleanTheme.primaryColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: CleanTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Livello ${_stats!.currentLevel}',
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${_stats!.totalXp} XP Totali',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Prossimo Livello',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          Text(
                            '${(_stats!.progressToNextLevel * 100).toInt()}%',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _stats!.progressToNextLevel,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Streak Card
            CleanCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CleanTheme.accentOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      size: 32,
                      color: CleanTheme.accentOrange,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Streak Attuale',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: CleanTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '${_stats!.currentStreak} giorni',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: CleanTheme.accentOrange,
                          ),
                        ),
                        Text(
                          'Record: ${_stats!.longestStreak} giorni',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: CleanTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _buildStatCard(
                  'Workout',
                  '${_stats!.totalWorkouts}',
                  Icons.fitness_center,
                  CleanTheme.accentBlue,
                ),
                _buildStatCard(
                  'Serie',
                  '${_stats!.totalSetsCompleted}',
                  Icons.repeat,
                  CleanTheme.primaryColor,
                ),
                _buildStatCard(
                  'Reps',
                  '${_stats!.totalRepsCompleted}',
                  Icons.trending_up,
                  Colors.purple,
                ),
                _buildStatCard(
                  'Peso (kg)',
                  _stats!.totalWeightLifted.toStringAsFixed(0),
                  Icons.scale,
                  CleanTheme.accentRed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
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
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: CleanTheme.textPrimary,
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

  Widget _buildAchievementsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: CleanTheme.primaryColor,
      backgroundColor: CleanTheme.surfaceColor,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_unlockedAchievements.isNotEmpty) ...[
            CleanSectionHeader(
              title: 'Sbloccati (${_unlockedAchievements.length})',
            ),
            const SizedBox(height: 16),
            ..._unlockedAchievements.map(
              (achievement) =>
                  _buildAchievementCard(achievement, unlocked: true),
            ),
            const SizedBox(height: 24),
          ],
          if (_lockedAchievements.isNotEmpty) ...[
            CleanSectionHeader(
              title: 'Da Sbloccare (${_lockedAchievements.length})',
            ),
            const SizedBox(height: 16),
            ..._lockedAchievements.map(
              (achievement) =>
                  _buildAchievementCard(achievement, unlocked: false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAchievementCard(
    Achievement achievement, {
    required bool unlocked,
  }) {
    return CleanCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: unlocked
                  ? achievement.rarityColor.withValues(alpha: 0.1)
                  : CleanTheme.borderSecondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              achievement.icon,
              style: TextStyle(
                fontSize: 32,
                color: unlocked ? null : Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.name,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: unlocked
                        ? CleanTheme.textPrimary
                        : CleanTheme.textSecondary,
                  ),
                ),
                Text(
                  achievement.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CleanTheme.textSecondary,
                  ),
                ),
                if (!unlocked && achievement.progress != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (achievement.progressPercentage ?? 0) / 100,
                      backgroundColor: CleanTheme.borderSecondary,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        achievement.rarityColor,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${achievement.progress}/${achievement.target}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CleanTheme.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: CleanTheme.accentYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+${achievement.xpReward} XP',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CleanTheme.accentYellow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: CleanTheme.primaryColor,
      backgroundColor: CleanTheme.surfaceColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _leaderboard.length,
        itemBuilder: (context, index) {
          final entry = _leaderboard[index];
          final isTopThree = entry.rank <= 3;

          return CleanCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isTopThree
                        ? _getRankColor(entry.rank).withValues(alpha: 0.1)
                        : CleanTheme.borderSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      isTopThree ? _getRankEmoji(entry.rank) : '#${entry.rank}',
                      style: GoogleFonts.outfit(
                        fontSize: isTopThree ? 24 : 16,
                        fontWeight: FontWeight.bold,
                        color: isTopThree ? null : CleanTheme.textSecondary,
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
                        entry.name,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: CleanTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Livello ${entry.level}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: CleanTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${entry.xp} XP',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CleanTheme.primaryColor,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return CleanTheme.accentYellow;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }
}
