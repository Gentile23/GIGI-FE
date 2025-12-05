import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';

/// ═══════════════════════════════════════════════════════════
/// GAMIFICATION WIDGETS - Engaging reward UI components
/// Psychology: Variable reward patterns, progress visibility
/// ═══════════════════════════════════════════════════════════

/// Animated Level Badge with glow effect
class LevelBadge extends StatelessWidget {
  final int level;
  final double size;

  const LevelBadge({super.key, required this.level, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CleanTheme.emotionProgress,
            CleanTheme.emotionProgress.withValues(alpha: 0.7),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: CleanTheme.emotionProgress.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$level',
          style: GoogleFonts.outfit(
            fontSize: size * 0.45,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// XP Chip for displaying earned experience
class XPChip extends StatelessWidget {
  final int xp;
  final bool isGain;

  const XPChip({super.key, required this.xp, this.isGain = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isGain
            ? CleanTheme.emotionSuccess.withValues(alpha: 0.15)
            : CleanTheme.borderSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚡', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '${isGain ? '+' : ''}$xp XP',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isGain
                  ? CleanTheme.emotionSuccess
                  : CleanTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Achievement Badge with unlock state
class AchievementBadge extends StatelessWidget {
  final String emoji;
  final String name;
  final String description;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementBadge({
    super.key,
    required this.emoji,
    required this.name,
    required this.description,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked
            ? CleanTheme.emotionSuccess.withValues(alpha: 0.08)
            : CleanTheme.borderSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? CleanTheme.emotionSuccess.withValues(alpha: 0.3)
              : CleanTheme.borderPrimary,
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: TextStyle(
              fontSize: 36,
              color: isUnlocked ? null : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isUnlocked
                  ? CleanTheme.textPrimary
                  : CleanTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CleanTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (isUnlocked && unlockedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Sbloccato',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: CleanTheme.emotionSuccess,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Daily Challenge Card
class DailyChallengeCard extends StatelessWidget {
  final String title;
  final String description;
  final int xpReward;
  final double progress;
  final bool isCompleted;
  final VoidCallback? onTap;

  const DailyChallengeCard({
    super.key,
    required this.title,
    required this.description,
    required this.xpReward,
    this.progress = 0,
    this.isCompleted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isCompleted
              ? LinearGradient(
                  colors: [
                    CleanTheme.emotionSuccess.withValues(alpha: 0.1),
                    CleanTheme.emotionSuccess.withValues(alpha: 0.05),
                  ],
                )
              : null,
          color: isCompleted ? null : CleanTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? CleanTheme.emotionSuccess.withValues(alpha: 0.3)
                : CleanTheme.borderPrimary,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                ),
                XPChip(xp: xpReward),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CleanTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: CleanTheme.borderSecondary,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted
                      ? CleanTheme.emotionSuccess
                      : CleanTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Leaderboard Position Card
class LeaderboardCard extends StatelessWidget {
  final int position;
  final String name;
  final String avatarLetter;
  final int xp;
  final bool isCurrentUser;

  const LeaderboardCard({
    super.key,
    required this.position,
    required this.name,
    required this.avatarLetter,
    required this.xp,
    this.isCurrentUser = false,
  });

  Color get _positionColor {
    switch (position) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return CleanTheme.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? CleanTheme.primaryColor.withValues(alpha: 0.08)
            : CleanTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser
              ? CleanTheme.primaryColor.withValues(alpha: 0.3)
              : CleanTheme.borderPrimary,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '#$position',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _positionColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: CleanTheme.primaryColor,
            child: Text(
              avatarLetter,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.w500,
                color: CleanTheme.textPrimary,
              ),
            ),
          ),
          Text(
            '$xp XP',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CleanTheme.emotionProgress,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reward Unlock Animation Container
class RewardUnlockContainer extends StatefulWidget {
  final Widget child;
  final bool showAnimation;
  final VoidCallback? onAnimationComplete;

  const RewardUnlockContainer({
    super.key,
    required this.child,
    this.showAnimation = false,
    this.onAnimationComplete,
  });

  @override
  State<RewardUnlockContainer> createState() => _RewardUnlockContainerState();
}

class _RewardUnlockContainerState extends State<RewardUnlockContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _glowAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    if (widget.showAnimation) {
      _controller.forward().then((_) => widget.onAnimationComplete?.call());
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: CleanTheme.emotionSuccess.withValues(
                  alpha: _glowAnimation.value * 0.5,
                ),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
