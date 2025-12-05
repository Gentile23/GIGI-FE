import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';

/// ═══════════════════════════════════════════════════════════
/// ENHANCED WIDGETS - With psychological colors & animations
/// ═══════════════════════════════════════════════════════════

/// Animated Stat Card with emotional color coding
class AnimatedStatCard extends StatefulWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool animateOnAppear;

  const AnimatedStatCard({
    super.key,
    required this.emoji,
    required this.value,
    required this.label,
    this.color = CleanTheme.primaryColor,
    this.onTap,
    this.animateOnAppear = true,
  });

  @override
  State<AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    if (widget.animateOnAppear) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: () {
          HapticService.lightTap();
          widget.onTap?.call();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CleanTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CleanTheme.borderPrimary),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                widget.value,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: widget.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: CleanTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Streak Badge with fire effect
class StreakBadge extends StatelessWidget {
  final int streak;
  final bool isActive;

  const StreakBadge({super.key, required this.streak, this.isActive = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [
                  CleanTheme.emotionMotivation,
                  CleanTheme.emotionMotivation.withValues(alpha: 0.8),
                ],
              )
            : null,
        color: isActive ? null : CleanTheme.borderSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(isActive ? '🔥' : '💪', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            isActive ? '$streak giorni' : 'Inizia!',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : CleanTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// XP Progress Bar with animation
class XPProgressBar extends StatelessWidget {
  final int currentXP;
  final int xpForNextLevel;
  final int level;

  const XPProgressBar({
    super.key,
    required this.currentXP,
    required this.xpForNextLevel,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentXP / xpForNextLevel;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CleanTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: CleanTheme.emotionProgress.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '⭐ Lvl $level',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.emotionProgress,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '$currentXP / $xpForNextLevel XP',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: CleanTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: CleanTheme.borderSecondary,
              valueColor: AlwaysStoppedAnimation<Color>(
                CleanTheme.emotionProgress,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Achievement Chip with unlock animation
class AchievementChip extends StatelessWidget {
  final String emoji;
  final String title;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const AchievementChip({
    super.key,
    required this.emoji,
    required this.title,
    this.isUnlocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUnlocked
              ? CleanTheme.emotionSuccess.withValues(alpha: 0.1)
              : CleanTheme.borderSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked
                ? CleanTheme.emotionSuccess.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: TextStyle(
                fontSize: 18,
                color: isUnlocked ? null : Colors.grey,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isUnlocked
                    ? CleanTheme.emotionSuccess
                    : CleanTheme.textTertiary,
              ),
            ),
            if (isUnlocked) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.verified,
                color: CleanTheme.emotionSuccess,
                size: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Motivational Message Card
class MotivationalCard extends StatelessWidget {
  final String message;
  final String? emoji;
  final Color? accentColor;

  const MotivationalCard({
    super.key,
    required this.message,
    this.emoji,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? CleanTheme.emotionMotivation;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: CleanTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick Action Button with icon
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CleanTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CleanTheme.borderPrimary),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: CleanTheme.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Day Progress Circle
class DayProgressCircle extends StatelessWidget {
  final String dayLetter;
  final bool isCompleted;
  final bool isToday;

  const DayProgressCircle({
    super.key,
    required this.dayLetter,
    this.isCompleted = false,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          dayLetter,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isToday ? CleanTheme.primaryColor : CleanTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCompleted
                ? CleanTheme.emotionSuccess
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
  }
}

/// Workout Summary Mini Card
class WorkoutSummaryMini extends StatelessWidget {
  final String title;
  final String duration;
  final String exercises;
  final VoidCallback onTap;

  const WorkoutSummaryMini({
    super.key,
    required this.title,
    required this.duration,
    required this.exercises,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              CleanTheme.immersiveDark,
              CleanTheme.immersiveDarkSecondary,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _miniStat(Icons.timer_outlined, duration),
                const SizedBox(width: 16),
                _miniStat(Icons.fitness_center, exercises),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String value) => Row(
    children: [
      Icon(icon, color: Colors.white60, size: 14),
      const SizedBox(width: 4),
      Text(
        value,
        style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
      ),
    ],
  );
}
