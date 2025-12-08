import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/models/addiction_mechanics_model.dart';
import '../../widgets/addiction_mechanics_widgets.dart';
import '../../widgets/clean_widgets.dart';

/// ═══════════════════════════════════════════════════════════
/// CHALLENGES SCREEN - Daily/Weekly/Community Challenges
/// ═══════════════════════════════════════════════════════════

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Challenge> _challenges = Challenge.getSampleChallenges();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      appBar: AppBar(
        backgroundColor: CleanTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Sfide',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: CleanTheme.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: CleanTheme.primaryColor,
          unselectedLabelColor: CleanTheme.textSecondary,
          indicatorColor: CleanTheme.primaryColor,
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Attive'),
            Tab(text: 'Giornaliere'),
            Tab(text: 'Settimanali'),
            Tab(text: 'Community'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveTab(),
          _buildChallengesListByType(ChallengeType.daily),
          _buildChallengesListByType(ChallengeType.weekly),
          _buildChallengesListByType(ChallengeType.community),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    final activeChallenges = _challenges
        .where((c) => c.status == ChallengeStatus.active)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Featured Challenge Banner
          _buildFeaturedChallengeBanner(),

          const SizedBox(height: 24),

          // Active Challenges
          Text(
            'Le tue sfide attive',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          if (activeChallenges.isEmpty)
            _buildEmptyState()
          else
            ...activeChallenges.map(
              (challenge) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ChallengeCard(
                  challenge: challenge,
                  onTap: () => _showChallengeDetails(challenge),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Quick Join Section
          Text(
            'Unisciti a una sfida',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          _buildQuickJoinSection(),
        ],
      ),
    );
  }

  Widget _buildFeaturedChallengeBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CleanTheme.accentPurple,
            CleanTheme.accentPurple.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CleanTheme.accentPurple.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🔥 SFIDA DEL MESE',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '12,847 partecipanti',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '1 Milione di Squat',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Insieme alla community, raggiungiamo 1M squat!',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          // Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '742,319 / 1,000,000',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '74%',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.74,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  color: Colors.white,
                  minHeight: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CleanButton(text: 'Partecipa', onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildQuickJoinSection() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickJoinCard(
            title: '100 Push-Up',
            type: 'Daily',
            emoji: '💪',
            color: CleanTheme.accentBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickJoinCard(
            title: '5 Workout',
            type: 'Weekly',
            emoji: '🔥',
            color: CleanTheme.accentGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickJoinCard(
            title: 'Sfida 1v1',
            type: 'Friend',
            emoji: '⚔️',
            color: CleanTheme.accentRed,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickJoinCard({
    required String title,
    required String type,
    required String emoji,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              type,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengesListByType(ChallengeType type) {
    final filtered = _challenges.where((c) => c.type == type).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ChallengeCard(
            challenge: filtered[index],
            onTap: () => _showChallengeDetails(filtered[index]),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Nessuna sfida attiva',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unisciti a una sfida per iniziare!',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CleanTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showChallengeDetails(Challenge challenge) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ChallengeDetailSheet(challenge: challenge),
    );
  }
}

/// Challenge Detail Bottom Sheet
class _ChallengeDetailSheet extends StatelessWidget {
  final Challenge challenge;

  const _ChallengeDetailSheet({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: CleanTheme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        challenge.title,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: CleanTheme.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CleanTheme.accentGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: CleanTheme.accentGreen,
                        size: 28,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  challenge.description,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: CleanTheme.textSecondary,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),

                // Progress Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: CleanTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progresso',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: CleanTheme.textSecondary,
                            ),
                          ),
                          Text(
                            '${challenge.currentProgress}/${challenge.targetValue}',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: CleanTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: challenge.progressPercentage,
                          backgroundColor: CleanTheme.borderSecondary,
                          color: CleanTheme.primaryColor,
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Rewards Section
                Text(
                  'Premi',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...challenge.rewards.map(
                  (reward) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          reward.iconEmoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reward.name,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: CleanTheme.textPrimary,
                                ),
                              ),
                              Text(
                                reward.description,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: CleanTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Time remaining
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 18,
                      color: CleanTheme.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tempo rimanente: ${challenge.timeRemainingFormatted}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Action Button
                CleanButton(
                  text: 'Vai all\'Allenamento',
                  width: double.infinity,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
