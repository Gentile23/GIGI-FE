import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';
import '../../widgets/clean_widgets.dart';

/// Screen per il feed delle attività della community
class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data - TODO: Replace with real API data
  final List<ActivityItem> _activities = [
    ActivityItem(
      id: '1',
      type: ActivityType.workout,
      userName: 'Marco R.',
      userAvatar: null,
      message: 'ha completato un workout di 45 minuti',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      likes: 12,
      comments: 3,
      isLiked: false,
      xpEarned: 150,
    ),
    ActivityItem(
      id: '2',
      type: ActivityType.achievement,
      userName: 'Laura B.',
      userAvatar: null,
      message: 'ha sbloccato "Guerriero della Settimana" 🏆',
      timestamp: DateTime.now().subtract(const Duration(minutes: 23)),
      likes: 24,
      comments: 8,
      isLiked: true,
      achievementName: 'Guerriero della Settimana',
      achievementRarity: 'rare',
    ),
    ActivityItem(
      id: '3',
      type: ActivityType.streak,
      userName: 'Giovanni F.',
      userAvatar: null,
      message: 'ha raggiunto una streak di 30 giorni! 🔥',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      likes: 45,
      comments: 12,
      isLiked: false,
      streakDays: 30,
    ),
    ActivityItem(
      id: '4',
      type: ActivityType.personalRecord,
      userName: 'Sofia M.',
      userAvatar: null,
      message: 'ha battuto il suo record personale in Panca Piana',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      likes: 18,
      comments: 5,
      isLiked: false,
      recordValue: '85kg',
      previousRecord: '80kg',
    ),
    ActivityItem(
      id: '5',
      type: ActivityType.challenge,
      userName: 'Andrea P.',
      userAvatar: null,
      message: 'ha completato la sfida "Guerriero del Mattino"',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      likes: 8,
      comments: 2,
      isLiked: false,
    ),
  ];

  final List<ChallengeItem> _activeChallenges = [
    ChallengeItem(
      id: '1',
      title: 'Sfida della Settimana',
      description: 'Completa 5 workout questa settimana',
      participants: 127,
      progress: 0.6,
      endsAt: DateTime.now().add(const Duration(days: 3)),
      reward: 500,
    ),
    ChallengeItem(
      id: '2',
      title: '1v1 vs Marco R.',
      description: 'Chi solleva più kg questa settimana?',
      participants: 2,
      progress: 0.45,
      endsAt: DateTime.now().add(const Duration(days: 5)),
      reward: 200,
      isPrivate: true,
    ),
  ];

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
            // Header
            _buildHeader(),

            // Tabs
            _buildTabBar(),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFeedTab(),
                  _buildChallengesTab(),
                  _buildLeaderboardTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: CleanTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Community',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: CleanTheme.textPrimary,
                ),
              ),
              Text(
                '${_activities.length} attività oggi',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: CleanTheme.textSecondary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Notifications
              CleanIconButton(
                icon: Icons.notifications_outlined,
                onTap: () {},
                hasBorder: true,
              ),
              const SizedBox(width: 12),
              // Search
              CleanIconButton(
                icon: Icons.search,
                onTap: () {},
                hasBorder: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: CleanTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: CleanTheme.textSecondary,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'Feed'),
          Tab(text: 'Sfide'),
          Tab(text: 'Classifica'),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Refresh feed
        await Future.delayed(const Duration(seconds: 1));
      },
      color: CleanTheme.primaryColor,
      backgroundColor: CleanTheme.surfaceColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _activities.length,
        itemBuilder: (context, index) {
          return _buildActivityCard(_activities[index]);
        },
      ),
    );
  }

  Widget _buildActivityCard(ActivityItem activity) {
    return CleanCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Avatar
              CleanAvatar(
                initials: activity.userName.substring(0, 1),
                backgroundColor: _getActivityColor(
                  activity.type,
                ).withValues(alpha: 0.1),
              ),
              const SizedBox(width: 12),
              // Name and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.userName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    Text(
                      _formatTimeAgo(activity.timestamp),
                      style: GoogleFonts.inter(
                        color: CleanTheme.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Activity type icon
              _buildActivityTypeIcon(activity.type),
            ],
          ),

          const SizedBox(height: 12),

          // Message
          Text(
            activity.message,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: CleanTheme.textPrimary,
            ),
          ),

          // Extra content based on type
          if (activity.type == ActivityType.achievement) ...[
            const SizedBox(height: 12),
            _buildAchievementBadge(activity),
          ],
          if (activity.type == ActivityType.personalRecord) ...[
            const SizedBox(height: 12),
            _buildRecordComparison(activity),
          ],
          if (activity.xpEarned != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: CleanTheme.accentYellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${activity.xpEarned} XP',
                style: GoogleFonts.inter(
                  color: CleanTheme.accentYellow,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              // Like
              _buildActionButton(
                icon: activity.isLiked ? Icons.favorite : Icons.favorite_border,
                label: activity.likes.toString(),
                color: activity.isLiked ? CleanTheme.accentRed : null,
                onTap: () {
                  HapticService.lightTap();
                  setState(() {
                    activity.isLiked = !activity.isLiked;
                    activity.likes += activity.isLiked ? 1 : -1;
                  });
                },
              ),
              const SizedBox(width: 16),
              // Comment
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: activity.comments.toString(),
                onTap: () {
                  HapticService.lightTap();
                  // TODO: Open comments
                },
              ),
              const SizedBox(width: 16),
              // Kudos
              _buildActionButton(
                icon: Icons.thumb_up_outlined,
                label: 'Kudos',
                onTap: () {
                  HapticService.celebrationPattern();
                  // TODO: Send kudos
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Kudos inviato a ${activity.userName}! 🎉'),
                      backgroundColor: CleanTheme.primaryColor,
                    ),
                  );
                },
              ),
              const Spacer(),
              // Share
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.share_outlined,
                  color: CleanTheme.textTertiary,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? CleanTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color ?? CleanTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTypeIcon(ActivityType type) {
    IconData icon;
    Color color = _getActivityColor(type);

    switch (type) {
      case ActivityType.workout:
        icon = Icons.fitness_center;
        break;
      case ActivityType.achievement:
        icon = Icons.emoji_events;
        break;
      case ActivityType.streak:
        icon = Icons.local_fire_department;
        break;
      case ActivityType.personalRecord:
        icon = Icons.trending_up;
        break;
      case ActivityType.challenge:
        icon = Icons.flag;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.workout:
        return CleanTheme.primaryColor;
      case ActivityType.achievement:
        return CleanTheme.accentYellow;
      case ActivityType.streak:
        return CleanTheme.accentOrange;
      case ActivityType.personalRecord:
        return CleanTheme.accentBlue;
      case ActivityType.challenge:
        return Colors.purple;
    }
  }

  Widget _buildAchievementBadge(ActivityItem activity) {
    final color = activity.achievementRarity == 'legendary'
        ? CleanTheme.accentYellow
        : activity.achievementRarity == 'epic'
        ? Colors.purple
        : CleanTheme.accentBlue;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.achievementName ?? 'Achievement',
                style: GoogleFonts.inter(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                activity.achievementRarity?.toUpperCase() ?? '',
                style: GoogleFonts.inter(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordComparison(ActivityItem activity) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CleanTheme.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                activity.previousRecord ?? '-',
                style: GoogleFonts.inter(
                  color: CleanTheme.textSecondary,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              Text(
                'Prima',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: CleanTheme.textTertiary,
                ),
              ),
            ],
          ),
          const Icon(Icons.arrow_forward, color: CleanTheme.textTertiary),
          Column(
            children: [
              Text(
                activity.recordValue ?? '-',
                style: GoogleFonts.outfit(
                  color: CleanTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                'Nuovo Record!',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: CleanTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Active challenges
        CleanSectionHeader(title: 'Sfide Attive'),
        const SizedBox(height: 16),
        ..._activeChallenges.map((challenge) => _buildChallengeCard(challenge)),

        const SizedBox(height: 24),

        // Available challenges
        CleanSectionHeader(
          title: 'Sfide Disponibili',
          actionText: 'Vedi tutte',
          onAction: () {},
        ),
        const SizedBox(height: 16),
        _buildAvailableChallengeCard(
          title: 'Maratona Settimanale',
          description: '20 workout in 7 giorni',
          participants: 45,
          reward: 1000,
        ),
        const SizedBox(height: 12),
        _buildAvailableChallengeCard(
          title: 'Iron Man',
          description: 'Solleva 10.000kg in una settimana',
          participants: 89,
          reward: 750,
        ),
      ],
    );
  }

  Widget _buildChallengeCard(ChallengeItem challenge) {
    final daysRemaining = challenge.endsAt.difference(DateTime.now()).inDays;

    return CleanCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  challenge.title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
              ),
              if (challenge.isPrivate)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock, size: 12, color: Colors.purple),
                      const SizedBox(width: 4),
                      Text(
                        '1v1',
                        style: GoogleFonts.inter(
                          color: Colors.purple,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            challenge.description,
            style: GoogleFonts.inter(color: CleanTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: challenge.progress,
              backgroundColor: CleanTheme.borderSecondary,
              valueColor: const AlwaysStoppedAnimation(CleanTheme.primaryColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(challenge.progress * 100).toInt()}% completato',
                style: GoogleFonts.inter(
                  color: CleanTheme.textTertiary,
                  fontSize: 12,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: CleanTheme.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$daysRemaining giorni rimasti',
                    style: GoogleFonts.inter(
                      color: daysRemaining <= 1
                          ? CleanTheme.accentRed
                          : CleanTheme.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 16,
                    color: CleanTheme.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${challenge.participants} partecipanti',
                    style: GoogleFonts.inter(
                      color: CleanTheme.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: CleanTheme.accentYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.reward} XP',
                      style: GoogleFonts.inter(
                        color: CleanTheme.accentYellow,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableChallengeCard({
    required String title,
    required String description,
    required int participants,
    required int reward,
  }) {
    return CleanCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CleanTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '$participants partecipanti',
                      style: GoogleFonts.inter(
                        color: CleanTheme.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '⚡ $reward XP',
                      style: GoogleFonts.inter(
                        color: CleanTheme.accentYellow,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          CleanButton(
            text: 'Unisciti',
            onPressed: () {
              HapticService.mediumTap();
              // TODO: Join challenge
            },
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return Center(
      child: Text(
        'Classifica in arrivo...',
        style: GoogleFonts.inter(color: CleanTheme.textSecondary),
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m fa';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h fa';
    } else {
      return '${diff.inDays}g fa';
    }
  }
}

enum ActivityType { workout, achievement, streak, personalRecord, challenge }

class ActivityItem {
  final String id;
  final ActivityType type;
  final String userName;
  final String? userAvatar;
  final String message;
  final DateTime timestamp;
  int likes;
  int comments;
  bool isLiked;
  final int? xpEarned;
  final String? achievementName;
  final String? achievementRarity;
  final int? streakDays;
  final String? recordValue;
  final String? previousRecord;

  ActivityItem({
    required this.id,
    required this.type,
    required this.userName,
    this.userAvatar,
    required this.message,
    required this.timestamp,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    this.xpEarned,
    this.achievementName,
    this.achievementRarity,
    this.streakDays,
    this.recordValue,
    this.previousRecord,
  });
}

class ChallengeItem {
  final String id;
  final String title;
  final String description;
  final int participants;
  final double progress;
  final DateTime endsAt;
  final int reward;
  final bool isPrivate;

  ChallengeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.participants,
    required this.progress,
    required this.endsAt,
    required this.reward,
    this.isPrivate = false,
  });
}
