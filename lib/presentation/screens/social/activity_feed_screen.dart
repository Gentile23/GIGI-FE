import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';
import '../../widgets/clean_widgets.dart';
import 'package:provider/provider.dart';
import '../../../providers/social_provider.dart';

/// Screen per il feed delle attività della community
class ActivityFeedScreen extends StatefulWidget {
  const ActivityFeedScreen({super.key});

  @override
  State<ActivityFeedScreen> createState() => _ActivityFeedScreenState();
}

class _ActivityFeedScreenState extends State<ActivityFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load data from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SocialProvider>(context, listen: false);
      provider.loadFeed();
      provider.loadChallenges();
      provider.loadLeaderboard();
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
              Consumer<SocialProvider>(
                builder: (context, provider, child) {
                  return Text(
                    '${provider.activities.length} attività oggi',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: CleanTheme.textSecondary,
                    ),
                  );
                },
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
    return Consumer<SocialProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.activities.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.activities.isEmpty) {
          return Center(
            child: Text(
              'Nessuna attività recente',
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshFeed,
          color: CleanTheme.primaryColor,
          backgroundColor: CleanTheme.surfaceColor,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            itemCount: provider.activities.length,
            itemBuilder: (context, index) {
              return _buildActivityCard(provider.activities[index]);
            },
          ),
        );
      },
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
          if (activity.type == 'achievement') ...[
            const SizedBox(height: 12),
            _buildAchievementBadge(activity),
          ],
          if (activity.type == 'personalRecord') ...[
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
                onTap: () async {
                  HapticService.lightTap();
                  final provider = Provider.of<SocialProvider>(
                    context,
                    listen: false,
                  );
                  await provider.toggleLike(activity.id);
                  // UI update is handled by provider notification or we canoptimistically update here if provider doesn't re-emit immediately
                },
              ),
              const SizedBox(width: 16),
              // Comment
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: activity.comments.toString(),
                onTap: () {
                  HapticService.lightTap();
                  _showCommentsSheet(activity);
                },
              ),
              const SizedBox(width: 16),
              // Kudos
              _buildActionButton(
                icon: Icons.thumb_up_outlined,
                label: 'Kudos',
                onTap: () {
                  HapticService.celebrationPattern();
                  _sendKudos(activity);
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

  Widget _buildActivityTypeIcon(String type) {
    IconData icon;
    Color color = _getActivityColor(type);

    switch (type) {
      case 'workout':
        icon = Icons.fitness_center;
        break;
      case 'achievement':
        icon = Icons.emoji_events;
        break;
      case 'streak':
        icon = Icons.local_fire_department;
        break;
      case 'personalRecord':
        icon = Icons.trending_up;
        break;
      case 'challenge':
        icon = Icons.flag;
        break;
      default:
        icon = Icons.circle;
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

  Color _getActivityColor(String type) {
    switch (type) {
      case 'workout':
        return CleanTheme.primaryColor;
      case 'achievement':
        return CleanTheme.accentYellow;
      case 'streak':
        return CleanTheme.accentOrange;
      case 'personalRecord':
        return CleanTheme.accentBlue;
      case 'challenge':
        return Colors.purple;
      default:
        return CleanTheme.textSecondary;
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
    return Consumer<SocialProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.activeChallenges.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            // Active challenges
            if (provider.activeChallenges.isNotEmpty) ...[
              CleanSectionHeader(title: 'Sfide Attive'),
              const SizedBox(height: 16),
              ...provider.activeChallenges.map(
                (challenge) => _buildChallengeCard(challenge),
              ),
              const SizedBox(height: 24),
            ],

            // Available challenges
            if (provider.availableChallenges.isNotEmpty) ...[
              CleanSectionHeader(
                title: 'Sfide Disponibili',
                actionText: 'Vedi tutte',
                onAction: () {},
              ),
              const SizedBox(height: 16),
              ...provider.availableChallenges.map(
                (challenge) => _buildAvailableChallengeCard(challenge),
              ),
            ],

            if (provider.activeChallenges.isEmpty &&
                provider.availableChallenges.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    'Nessuna sfida attiva al momento',
                    style: GoogleFonts.inter(color: CleanTheme.textSecondary),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildChallengeCard(ChallengeData challenge) {
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

  Widget _buildAvailableChallengeCard(ChallengeData challenge) {
    return CleanCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  challenge.description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CleanTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${challenge.participants} partecipanti',
                      style: GoogleFonts.inter(
                        color: CleanTheme.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '⚡ ${challenge.reward} XP',
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
              _joinChallenge(challenge);
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

  Future<void> _refreshFeed() async {
    HapticService.lightTap();
    final provider = Provider.of<SocialProvider>(context, listen: false);
    await provider.loadFeed(refresh: true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feed aggiornato!'),
          backgroundColor: CleanTheme.primaryColor,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _showCommentsSheet(ActivityItem activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: CleanTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CleanTheme.borderPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Commenti (${activity.comments})',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Comments list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: activity.comments,
                itemBuilder: (context, index) => _buildCommentItem(index),
              ),
            ),
            // Comment input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CleanTheme.surfaceColor,
                border: const Border(
                  top: BorderSide(color: CleanTheme.borderPrimary),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: GoogleFonts.inter(color: CleanTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Scrivi un commento...',
                        hintStyle: GoogleFonts.inter(
                          color: CleanTheme.textTertiary,
                        ),
                        filled: true,
                        fillColor: CleanTheme.backgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      HapticService.lightTap();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Commento inviato!'),
                          backgroundColor: CleanTheme.primaryColor,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.send,
                      color: CleanTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(int index) {
    final names = ['Marco R.', 'Laura B.', 'Giovanni F.', 'Anna M.', 'Luca P.'];
    final comments = [
      'Grande! Continua così! 💪',
      'Fantastico risultato!',
      'Mi ispiri a fare di più!',
      'Che forza! 🔥',
      'Bravissimo!',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CleanAvatar(
            initials: names[index % names.length][0],
            size: 36,
            backgroundColor: CleanTheme.primaryLight,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  names[index % names.length],
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comments[index % comments.length],
                  style: GoogleFonts.inter(color: CleanTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendKudos(ActivityItem activity) {
    // Optimistic UI update
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kudos inviato a ${activity.userName}! 🎉'),
        backgroundColor: CleanTheme.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );

    final provider = Provider.of<SocialProvider>(context, listen: false);
    provider.sendKudos(
      userId: activity.userId,
      activityId: activity.id,
      type: activity.type,
    );
  }

  void _joinChallenge(ChallengeData challenge) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Unisciti alla sfida',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        content: Text(
          'Vuoi unirti a "${challenge.title}"?\n\nPremio: ${challenge.reward} XP',
          style: GoogleFonts.inter(color: CleanTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Annulla',
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);

              final provider = Provider.of<SocialProvider>(
                context,
                listen: false,
              );
              provider.joinChallenge(challenge.id).then((success) {
                if (success) {
                  HapticService.celebrationPattern();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Ti sei unito a "${challenge.title}"! 🎯',
                        ),
                        backgroundColor: CleanTheme.primaryColor,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Errore: impossibile unirsi alla sfida.'),
                        backgroundColor: CleanTheme.accentRed,
                      ),
                    );
                  }
                }
              });
            },
            child: Text(
              'Unisciti',
              style: GoogleFonts.inter(
                color: CleanTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
