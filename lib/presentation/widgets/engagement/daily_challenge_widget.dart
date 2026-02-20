import 'package:flutter/material.dart';
import '../../../../core/theme/clean_theme.dart';
import '../animations/liquid_steel_container.dart';

/// Widget per Daily Challenge con countdown timer
class DailyChallengeWidget extends StatefulWidget {
  final String title;
  final String description;
  final int xpReward;
  final Duration timeRemaining;
  final double progress;
  final int completedToday;
  final VoidCallback? onTap;

  const DailyChallengeWidget({
    super.key,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.timeRemaining,
    this.progress = 0.0,
    this.completedToday = 0,
    this.onTap,
  });

  @override
  State<DailyChallengeWidget> createState() => _DailyChallengeWidgetState();
}

class _DailyChallengeWidgetState extends State<DailyChallengeWidget>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _urgencyController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _urgencyController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Se meno di 2 ore, attiva animazione urgenza
    if (widget.timeRemaining.inHours < 2) {
      _urgencyController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _urgencyController.dispose();
    super.dispose();
  }

  String _formatTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = widget.timeRemaining.inHours < 2;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_shimmerController, _urgencyController]),
        builder: (context, child) {
          return LiquidSteelContainer(
            enableShine: true,
            borderRadius: 20,
            border: Border.all(
              color: isUrgent
                  ? CleanTheme.accentRed.withValues(alpha: 0.5)
                  : CleanTheme.borderPrimary,
              width: isUrgent ? 2 : 1,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      // Badge sfida
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              CleanTheme.primaryColor,
                              CleanTheme.primaryColor.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.flash_on, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'SFIDA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Timer
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isUrgent
                              ? CleanTheme.accentRed.withValues(alpha: 0.2)
                              : CleanTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer,
                              color: isUrgent ? Colors.red : Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(widget.timeRemaining),
                              style: TextStyle(
                                color: isUrgent
                                    ? CleanTheme.accentRed
                                    : CleanTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Titolo
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Descrizione
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: widget.progress.clamp(0.0, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  CleanTheme.accentGreen,
                                  CleanTheme.accentGreen.withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Footer
                  Row(
                    children: [
                      // XP reward
                      _buildRewardChip(),
                      const Spacer(),
                      // Social proof
                      if (widget.completedToday > 0)
                        Text(
                          '${widget.completedToday} persone l\'hanno completata',
                          style: TextStyle(
                            fontSize: 11,
                            color: CleanTheme.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRewardChip() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CleanTheme.accentYellow.withValues(alpha: 0.3),
                CleanTheme.accentYellow.withValues(
                  alpha: 0.1 + _shimmerController.value * 0.2,
                ),
                CleanTheme.accentYellow.withValues(alpha: 0.3),
              ],
              stops: [0.0, _shimmerController.value, 1.0],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: CleanTheme.accentYellow.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚡', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                '+${widget.xpReward} XP',
                style: const TextStyle(
                  color: CleanTheme.accentYellow,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Lista di sfide giornaliere
class DailyChallengesList extends StatelessWidget {
  final List<Map<String, dynamic>> challenges;
  final Function(String challengeId)? onChallengeTap;

  const DailyChallengesList({
    super.key,
    required this.challenges,
    this.onChallengeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                '🎯 Sfide del Giorno',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CleanTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CleanTheme.accentGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${challenges.where((c) => c['completed'] == true).length}/${challenges.length}',
                  style: const TextStyle(
                    color: CleanTheme.accentGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Challenges
        ...challenges.map((challenge) {
          final timeRemaining = challenge['expires_at'] != null
              ? (challenge['expires_at'] as DateTime).difference(DateTime.now())
              : const Duration(hours: 12);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
            child: DailyChallengeWidget(
              title: challenge['title'] ?? '',
              description: challenge['description'] ?? '',
              xpReward: challenge['xp_reward'] ?? 0,
              timeRemaining: timeRemaining,
              progress: (challenge['progress'] ?? 0.0).toDouble(),
              completedToday: challenge['completed_by'] ?? 0,
              onTap: () => onChallengeTap?.call(challenge['id']),
            ),
          );
        }),
      ],
    );
  }
}
