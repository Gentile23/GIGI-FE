import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';

/// ═══════════════════════════════════════════════════════════
/// LEADERBOARD SCREEN - Rankings & Competition
/// ═══════════════════════════════════════════════════════════

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LeaderboardFilter _currentFilter = LeaderboardFilter.week;

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
      appBar: AppBar(
        backgroundColor: CleanTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CleanTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Classifica',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: CleanTheme.primaryColor,
          unselectedLabelColor: CleanTheme.textSecondary,
          indicatorColor: CleanTheme.primaryColor,
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'XP'),
            Tab(text: 'Workout'),
            Tab(text: 'Streak'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: LeaderboardFilter.values.map((filter) {
                final isSelected = _currentFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _currentFilter = filter);
                      }
                    },
                    selectedColor: CleanTheme.primaryColor,
                    labelStyle: GoogleFonts.inter(
                      color: isSelected
                          ? Colors.white
                          : CleanTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    backgroundColor: CleanTheme.cardColor,
                  ),
                );
              }).toList(),
            ),
          ),

          // Leaderboard content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLeaderboard(LeaderboardType.xp),
                _buildLeaderboard(LeaderboardType.workouts),
                _buildLeaderboard(LeaderboardType.streak),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(LeaderboardType type) {
    final entries = _getMockLeaderboardEntries(type);
    final currentUserRank = 12; // Mock current user position

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: entries.length + 1, // +1 for current user card
      itemBuilder: (context, index) {
        // Show current user position if outside top 10
        if (index == 3 && currentUserRank > 10) {
          return Column(
            children: [
              // Spacer indicating more users
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '•••',
                        style: GoogleFonts.inter(
                          color: CleanTheme.textTertiary,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
              ),
              // Current user card
              _buildCurrentUserCard(type, currentUserRank),
              const SizedBox(height: 8),
              // Continue with other entries
              _buildLeaderboardEntry(entries[index], index),
            ],
          );
        }

        if (index >= entries.length) return const SizedBox.shrink();
        return _buildLeaderboardEntry(entries[index], index);
      },
    );
  }

  Widget _buildLeaderboardEntry(LeaderboardEntry entry, int index) {
    final isTopThree = index < 3;
    final isCurrentUser = entry.isCurrentUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? CleanTheme.primaryColor.withValues(alpha: 0.1)
            : CleanTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser
            ? Border.all(color: CleanTheme.primaryColor, width: 2)
            : isTopThree
            ? Border.all(color: _getRankColor(index), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isTopThree
                  ? _getRankColor(index)
                  : CleanTheme.backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isTopThree
                  ? Text(
                      _getRankEmoji(index),
                      style: const TextStyle(fontSize: 20),
                    )
                  : Text(
                      '${entry.rank}',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          CleanAvatar(
            initials: entry.name[0],
            size: 44,
            backgroundColor: isCurrentUser
                ? CleanTheme.primaryColor
                : CleanTheme.primaryLight,
          ),
          const SizedBox(width: 12),
          // Name & Level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.name,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CleanTheme.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'TU',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  'Livello ${entry.level}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.scoreFormatted,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isTopThree
                      ? _getRankColor(index)
                      : CleanTheme.textPrimary,
                ),
              ),
              Text(
                entry.scoreLabel,
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

  Widget _buildCurrentUserCard(LeaderboardType type, int rank) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CleanTheme.primaryColor.withValues(alpha: 0.1),
            CleanTheme.accentPurple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CleanTheme.primaryColor, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: CleanTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const CleanAvatar(
            initials: 'M',
            size: 44,
            backgroundColor: CleanTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Marco Rossi',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CleanTheme.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'TU',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Livello 15 • Top 5% questa settimana',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_upward,
            color: CleanTheme.accentGreen,
            size: 20,
          ),
          Text(
            '+3',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: CleanTheme.accentGreen,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Gold
      case 1:
        return const Color(0xFFC0C0C0); // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return CleanTheme.textSecondary;
    }
  }

  String _getRankEmoji(int index) {
    switch (index) {
      case 0:
        return '🥇';
      case 1:
        return '🥈';
      case 2:
        return '🥉';
      default:
        return '';
    }
  }

  List<LeaderboardEntry> _getMockLeaderboardEntries(LeaderboardType type) {
    switch (type) {
      case LeaderboardType.xp:
        return [
          LeaderboardEntry(
            rank: 1,
            name: 'Alessandro G.',
            level: 42,
            score: 15420,
            scoreLabel: 'XP',
          ),
          LeaderboardEntry(
            rank: 2,
            name: 'Sofia M.',
            level: 38,
            score: 12850,
            scoreLabel: 'XP',
          ),
          LeaderboardEntry(
            rank: 3,
            name: 'Luca B.',
            level: 35,
            score: 11200,
            scoreLabel: 'XP',
          ),
          LeaderboardEntry(
            rank: 4,
            name: 'Elena R.',
            level: 33,
            score: 10500,
            scoreLabel: 'XP',
          ),
          LeaderboardEntry(
            rank: 5,
            name: 'Marco R.',
            level: 30,
            score: 9800,
            scoreLabel: 'XP',
          ),
          LeaderboardEntry(
            rank: 6,
            name: 'Giulia T.',
            level: 28,
            score: 8750,
            scoreLabel: 'XP',
          ),
          LeaderboardEntry(
            rank: 7,
            name: 'Andrea F.',
            level: 27,
            score: 8200,
            scoreLabel: 'XP',
          ),
          LeaderboardEntry(
            rank: 8,
            name: 'Chiara V.',
            level: 25,
            score: 7650,
            scoreLabel: 'XP',
          ),
          LeaderboardEntry(
            rank: 9,
            name: 'Francesco D.',
            level: 24,
            score: 7100,
            scoreLabel: 'XP',
          ),
          LeaderboardEntry(
            rank: 10,
            name: 'Valentina C.',
            level: 23,
            score: 6800,
            scoreLabel: 'XP',
          ),
        ];
      case LeaderboardType.workouts:
        return [
          LeaderboardEntry(
            rank: 1,
            name: 'Sofia M.',
            level: 38,
            score: 248,
            scoreLabel: 'workout',
          ),
          LeaderboardEntry(
            rank: 2,
            name: 'Alessandro G.',
            level: 42,
            score: 235,
            scoreLabel: 'workout',
          ),
          LeaderboardEntry(
            rank: 3,
            name: 'Andrea F.',
            level: 27,
            score: 198,
            scoreLabel: 'workout',
          ),
          LeaderboardEntry(
            rank: 4,
            name: 'Elena R.',
            level: 33,
            score: 185,
            scoreLabel: 'workout',
          ),
          LeaderboardEntry(
            rank: 5,
            name: 'Luca B.',
            level: 35,
            score: 172,
            scoreLabel: 'workout',
          ),
          LeaderboardEntry(
            rank: 6,
            name: 'Marco R.',
            level: 30,
            score: 156,
            scoreLabel: 'workout',
          ),
          LeaderboardEntry(
            rank: 7,
            name: 'Giulia T.',
            level: 28,
            score: 145,
            scoreLabel: 'workout',
          ),
          LeaderboardEntry(
            rank: 8,
            name: 'Francesco D.',
            level: 24,
            score: 132,
            scoreLabel: 'workout',
          ),
          LeaderboardEntry(
            rank: 9,
            name: 'Chiara V.',
            level: 25,
            score: 128,
            scoreLabel: 'workout',
          ),
          LeaderboardEntry(
            rank: 10,
            name: 'Valentina C.',
            level: 23,
            score: 115,
            scoreLabel: 'workout',
          ),
        ];
      case LeaderboardType.streak:
        return [
          LeaderboardEntry(
            rank: 1,
            name: 'Alessandro G.',
            level: 42,
            score: 365,
            scoreLabel: 'giorni',
          ),
          LeaderboardEntry(
            rank: 2,
            name: 'Sofia M.',
            level: 38,
            score: 248,
            scoreLabel: 'giorni',
          ),
          LeaderboardEntry(
            rank: 3,
            name: 'Elena R.',
            level: 33,
            score: 156,
            scoreLabel: 'giorni',
          ),
          LeaderboardEntry(
            rank: 4,
            name: 'Luca B.',
            level: 35,
            score: 98,
            scoreLabel: 'giorni',
          ),
          LeaderboardEntry(
            rank: 5,
            name: 'Andrea F.',
            level: 27,
            score: 67,
            scoreLabel: 'giorni',
          ),
          LeaderboardEntry(
            rank: 6,
            name: 'Marco R.',
            level: 30,
            score: 45,
            scoreLabel: 'giorni',
          ),
          LeaderboardEntry(
            rank: 7,
            name: 'Giulia T.',
            level: 28,
            score: 38,
            scoreLabel: 'giorni',
          ),
          LeaderboardEntry(
            rank: 8,
            name: 'Francesco D.',
            level: 24,
            score: 28,
            scoreLabel: 'giorni',
          ),
          LeaderboardEntry(
            rank: 9,
            name: 'Chiara V.',
            level: 25,
            score: 21,
            scoreLabel: 'giorni',
          ),
          LeaderboardEntry(
            rank: 10,
            name: 'Valentina C.',
            level: 23,
            score: 14,
            scoreLabel: 'giorni',
          ),
        ];
    }
  }
}

// ═══════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════

enum LeaderboardType { xp, workouts, streak }

enum LeaderboardFilter {
  today('Oggi'),
  week('Settimana'),
  month('Mese'),
  allTime('Sempre');

  final String label;
  const LeaderboardFilter(this.label);
}

class LeaderboardEntry {
  final int rank;
  final String name;
  final int level;
  final int score;
  final String scoreLabel;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.level,
    required this.score,
    required this.scoreLabel,
    this.isCurrentUser = false,
  });

  String get scoreFormatted {
    if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    }
    return score.toString();
  }
}
