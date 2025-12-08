import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';

/// ═══════════════════════════════════════════════════════════
/// COMMUNITY GOALS SCREEN
/// Track collective goals and milestones
/// ═══════════════════════════════════════════════════════════

class CommunityGoalsScreen extends StatefulWidget {
  const CommunityGoalsScreen({super.key});

  @override
  State<CommunityGoalsScreen> createState() => _CommunityGoalsScreenState();
}

class _CommunityGoalsScreenState extends State<CommunityGoalsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: CleanTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CleanTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Obiettivi Community',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Goal
            _buildHeroGoal(),

            const SizedBox(height: 24),

            // Live Stats
            _buildLiveStats(),

            const SizedBox(height: 24),

            // Active Goals
            Text(
              'Obiettivi Attivi',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            _buildGoalCard(
              title: '1 Milione di Squat',
              description: 'La community insieme raggiunge 1M squat',
              current: 742319,
              target: 1000000,
              emoji: '🦵',
              participants: 12847,
              reward: 'Badge "Squat Master" per tutti',
              daysRemaining: 8,
            ),

            const SizedBox(height: 16),

            _buildGoalCard(
              title: '100K Ore di Allenamento',
              description: 'Cronometriamo le nostre ore insieme',
              current: 67854,
              target: 100000,
              emoji: '⏱️',
              participants: 8532,
              reward: '500 XP Bonus per tutti',
              daysRemaining: 15,
            ),

            const SizedBox(height: 16),

            _buildGoalCard(
              title: '50K Push-Up al Giorno',
              description: 'Obiettivo giornaliero ricorrente',
              current: 38420,
              target: 50000,
              emoji: '💪',
              participants: 4215,
              reward: '50 XP Bonus',
              isDaily: true,
            ),

            const SizedBox(height: 24),

            // Completed Goals
            Text(
              'Obiettivi Completati',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            _buildCompletedGoalCard(
              title: '500K Calorie Bruciate',
              completedDate: DateTime.now().subtract(const Duration(days: 3)),
              participants: 9876,
              emoji: '🔥',
            ),

            const SizedBox(height: 12),

            _buildCompletedGoalCard(
              title: 'Novembre Fitness Challenge',
              completedDate: DateTime.now().subtract(const Duration(days: 7)),
              participants: 15234,
              emoji: '🏆',
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroGoal() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CleanTheme.accentPurple,
            CleanTheme.accentPurple.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CleanTheme.accentPurple.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                  '🌍 COMMUNITY GOAL',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Text('🎯', style: TextStyle(fontSize: 20)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '10 Milioni di Workout',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Entro la fine del 2024, la GIGI Community completerà 10 milioni di workout insieme!',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '7,842,156',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '78.4%',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.784,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              color: Colors.white,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.people, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                '156,432 partecipanti',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const Spacer(),
              const Icon(Icons.access_time, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                '24 giorni rimanenti',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Row(
        children: [
          _buildLiveStat('🔥', '4,523', 'oggi'),
          _buildLiveStatDivider(),
          _buildLiveStat('💪', '127', 'ora'),
          _buildLiveStatDivider(),
          _buildLiveStat('📈', '+12%', 'vs ieri'),
        ],
      ),
    );
  }

  Widget _buildLiveStat(String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CleanTheme.textPrimary,
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

  Widget _buildLiveStatDivider() {
    return Container(width: 1, height: 40, color: CleanTheme.borderPrimary);
  }

  Widget _buildGoalCard({
    required String title,
    required String description,
    required int current,
    required int target,
    required String emoji,
    required int participants,
    required String reward,
    int? daysRemaining,
    bool isDaily = false,
  }) {
    final progress = current / target;

    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDaily)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: CleanTheme.accentGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'DAILY',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: CleanTheme.accentGreen,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_formatNumber(current)} / ${_formatNumber(target)}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: CleanTheme.borderSecondary,
                  color: CleanTheme.primaryColor,
                  minHeight: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Footer info
          Row(
            children: [
              Icon(
                Icons.people_outline,
                size: 14,
                color: CleanTheme.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                _formatNumber(participants),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: CleanTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              if (daysRemaining != null) ...[
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: CleanTheme.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  '$daysRemaining giorni',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CleanTheme.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🎁 $reward',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: CleanTheme.accentGreen,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedGoalCard({
    required String title,
    required DateTime completedDate,
    required int participants,
    required String emoji,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.accentGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CleanTheme.accentGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
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
                Text(
                  '${_formatNumber(participants)} partecipanti',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(
                Icons.check_circle,
                color: CleanTheme.accentGreen,
                size: 24,
              ),
              Text(
                _formatDate(completedDate),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: CleanTheme.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Oggi';
    if (diff == 1) return 'Ieri';
    if (diff < 7) return '$diff giorni fa';
    return '${date.day}/${date.month}';
  }
}
