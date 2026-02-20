import 'package:flutter/material.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';

/// Widget per visualizzare level e XP progress in modo premium
class LevelProgressWidget extends StatefulWidget {
  final int currentLevel;
  final int currentXP;
  final int xpForNextLevel;
  final VoidCallback? onTap;

  const LevelProgressWidget({
    super.key,
    required this.currentLevel,
    required this.currentXP,
    required this.xpForNextLevel,
    this.onTap,
  });

  @override
  State<LevelProgressWidget> createState() => _LevelProgressWidgetState();
}

class _LevelProgressWidgetState extends State<LevelProgressWidget>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  double get progress => widget.currentXP / widget.xpForNextLevel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_glowController, _progressController]),
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: CleanTheme.steelDark.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                // Level badge
                _buildLevelBadge(),
                const SizedBox(width: 16),
                // Progress info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Livello ${widget.currentLevel}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${widget.currentXP} / ${widget.xpForNextLevel} XP',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress bar
                      _buildProgressBar(),
                      const SizedBox(height: 8),
                      // XP to next level
                      Text(
                        '${widget.xpForNextLevel - widget.currentXP} XP al prossimo livello',
                        style: TextStyle(
                          fontSize: 11,
                          color: CleanTheme.accentGold.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLevelBadge() {
    final glowIntensity = 0.3 + (_glowController.value * 0.3);

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [CleanTheme.accentGold, CleanTheme.accentOrange],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: CleanTheme.accentGold.withValues(alpha: glowIntensity),
            blurRadius: 15 + (_glowController.value * 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${widget.currentLevel}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          // Background
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          // Progress
          FractionallySizedBox(
            widthFactor: (progress * _progressController.value).clamp(0.0, 1.0),
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [CleanTheme.accentGold, CleanTheme.accentOrange],
                ),
                boxShadow: [
                  BoxShadow(
                    color: CleanTheme.accentGold.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          // Shimmer effect
          if (progress > 0.8)
            Positioned.fill(
              child: ShaderMask(
                shaderCallback: (rect) {
                  return LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    stops: [0.0, _glowController.value, 1.0],
                  ).createShader(rect);
                },
                child: Container(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget per mostrare achievement story
class StoryAchievementCard extends StatefulWidget {
  final String title;
  final String description;
  final String narrative;
  final String icon;
  final String rarity;
  final bool unlocked;
  final int chapter;
  final VoidCallback? onTap;

  const StoryAchievementCard({
    super.key,
    required this.title,
    required this.description,
    required this.narrative,
    required this.icon,
    required this.rarity,
    required this.unlocked,
    required this.chapter,
    this.onTap,
  });

  @override
  State<StoryAchievementCard> createState() => _StoryAchievementCardState();
}

class _StoryAchievementCardState extends State<StoryAchievementCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    if (widget.unlocked && widget.rarity == 'legendary') {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get rarityColor {
    switch (widget.rarity) {
      case 'legendary':
        return CleanTheme.accentGold;
      case 'epic':
        return CleanTheme.accentOrange;
      case 'rare':
        return CleanTheme.accentBlue;
      case 'unique':
        return CleanTheme.accentRed;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.unlocked) {
          HapticService.lightTap();
          widget.onTap?.call();
        }
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: widget.unlocked
                ? BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        rarityColor.withValues(alpha: 0.15),
                        CleanTheme.steelDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: rarityColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: rarityColor.withValues(alpha: 0.6),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  )
                : BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: widget.unlocked
                        ? rarityColor.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: widget.unlocked
                        ? Text(
                            widget.icon,
                            style: const TextStyle(fontSize: 28),
                          )
                        : Icon(
                            Icons.lock,
                            color: Colors.white.withValues(alpha: 0.3),
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: widget.unlocked
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildRarityBadge(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.unlocked ? widget.narrative : widget.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.unlocked
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.4),
                          fontStyle: widget.unlocked ? FontStyle.italic : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Chapter indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'C${widget.chapter}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRarityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: rarityColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: rarityColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        widget.rarity.toUpperCase(),
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: rarityColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Widget per loot box reward animation
class LootBoxRewardWidget extends StatefulWidget {
  final String rarity;
  final Map<String, dynamic> reward;
  final int xpGained;
  final VoidCallback? onClose;

  const LootBoxRewardWidget({
    super.key,
    required this.rarity,
    required this.reward,
    required this.xpGained,
    this.onClose,
  });

  @override
  State<LootBoxRewardWidget> createState() => _LootBoxRewardWidgetState();
}

class _LootBoxRewardWidgetState extends State<LootBoxRewardWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _scaleController.forward();

    // Haptic feedback based on rarity
    _triggerHaptic();
  }

  void _triggerHaptic() {
    switch (widget.rarity) {
      case 'legendary':
        HapticService.legendaryAchievementPattern();
        break;
      case 'epic':
        HapticService.rareAchievementPattern();
        break;
      case 'rare':
        HapticService.rareAchievementPattern();
        break;
      default:
        HapticService.celebrationPattern();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Color get rarityColor {
    switch (widget.rarity) {
      case 'legendary':
        return CleanTheme.accentGold;
      case 'epic':
        return CleanTheme.accentOrange;
      case 'rare':
        return CleanTheme.accentBlue;
      default:
        return Colors.grey[400]!;
    }
  }

  String get rarityEmoji {
    switch (widget.rarity) {
      case 'legendary':
        return '🌟';
      case 'epic':
        return '💎';
      case 'rare':
        return '✨';
      default:
        return '🎁';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _glowController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CleanTheme.steelDark,
                  rarityColor.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: rarityColor.withValues(
                  alpha: 0.5 + _glowController.value * 0.3,
                ),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: rarityColor.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emoji rarity
                Text(rarityEmoji, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                // Rarity label
                Text(
                  widget.rarity.toUpperCase(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: rarityColor,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                // Message
                Text(
                  _getRewardMessage(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // XP gained
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        '+${widget.xpGained} XP',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Close button
                TextButton(
                  onPressed: widget.onClose,
                  child: Text(
                    'Continua',
                    style: TextStyle(
                      color: rarityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getRewardMessage() {
    switch (widget.rarity) {
      case 'legendary':
        return 'LEGGENDARIO! Sei uno su un milione!';
      case 'epic':
        return 'EPICO! Fortuna incredibile!';
      case 'rare':
        return 'RARO! Bel colpo!';
      default:
        return 'Ricompensa sbloccata!';
    }
  }
}
