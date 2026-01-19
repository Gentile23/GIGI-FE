import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gigi/l10n/app_localizations.dart';
import '../../core/theme/clean_theme.dart';
import '../../data/models/addiction_mechanics_model.dart';
import 'clean_widgets.dart';

/// ═══════════════════════════════════════════════════════════
/// STREAK WIDGET - Visual Chain Display
/// ═══════════════════════════════════════════════════════════

class StreakDisplayWidget extends StatelessWidget {
  final StreakData streakData;
  final VoidCallback? onFreezeTokenTap;
  final bool compact;

  const StreakDisplayWidget({
    super.key,
    required this.streakData,
    this.onFreezeTokenTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }
    return _buildFull(context);
  }

  Widget _buildCompact(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CleanTheme.accentOrange.withValues(alpha: 0.2),
            CleanTheme.accentRed.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CleanTheme.accentOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(streakData.streakEmoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            '${streakData.currentStreak}',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CleanTheme.accentOrange,
            ),
          ),
          if (streakData.xpMultiplier > 1.0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: CleanTheme.accentGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'x${streakData.xpMultiplier.toStringAsFixed(1)}',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFull(BuildContext context) {
    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    streakData.streakEmoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${streakData.currentStreak} ${AppLocalizations.of(context)!.days}',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: CleanTheme.textPrimary,
                        ),
                      ),
                      Text(
                        streakData.streakTier,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CleanTheme.accentOrange,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // XP Multiplier Badge
              if (streakData.xpMultiplier > 1.0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [CleanTheme.accentGreen, Color(0xFF22C55E)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: CleanTheme.accentGreen.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'x${streakData.xpMultiplier.toStringAsFixed(1)}',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.xpBonus,
                        style: GoogleFonts.inter(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress to next multiplier
          if (streakData.currentStreak < 30) ...[
            _buildNextMultiplierProgress(context),
            const SizedBox(height: 16),
          ],

          // Freeze Tokens
          Row(
            children: [
              const Text('❄️', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                '${streakData.freezeTokensRemaining} ${AppLocalizations.of(context)!.freezeTokens}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: CleanTheme.textSecondary,
                ),
              ),
              const Spacer(),
              if (streakData.freezeTokensRemaining > 0)
                GestureDetector(
                  onTap: onFreezeTokenTap,
                  child: Text(
                    AppLocalizations.of(context)!.use,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.primaryColor,
                    ),
                  ),
                ),
            ],
          ),

          // Streak at risk warning
          if (streakData.isCurrentlyAtRisk) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CleanTheme.accentRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CleanTheme.accentRed.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.streakRisk,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CleanTheme.accentRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNextMultiplierProgress(BuildContext context) {
    int nextMilestone;
    String nextMultiplier;

    if (streakData.currentStreak < 3) {
      nextMilestone = 3;
      nextMultiplier = '1.25x';
    } else if (streakData.currentStreak < 7) {
      nextMilestone = 7;
      nextMultiplier = '1.5x';
    } else if (streakData.currentStreak < 14) {
      nextMilestone = 14;
      nextMultiplier = '1.75x';
    } else {
      nextMilestone = 30;
      nextMultiplier = '2x';
    }

    final progress = streakData.currentStreak / nextMilestone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.nextBonus(nextMultiplier),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: CleanTheme.textSecondary,
              ),
            ),
            Text(
              '${streakData.currentStreak}/$nextMilestone',
              style: GoogleFonts.inter(
                fontSize: 12,
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
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// LIVE ACTIVITY BANNER - Social Proof & FOMO
/// ═══════════════════════════════════════════════════════════

class LiveActivityBanner extends StatefulWidget {
  final LiveActivityData? initialData;

  const LiveActivityBanner({super.key, this.initialData});

  @override
  State<LiveActivityBanner> createState() => _LiveActivityBannerState();
}

class _LiveActivityBannerState extends State<LiveActivityBanner>
    with SingleTickerProviderStateMixin {
  late LiveActivityData _data;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData ?? LiveActivityData.generateMock();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Update data periodically
    Future.delayed(const Duration(seconds: 30), _updateData);
  }

  void _updateData() {
    if (mounted) {
      setState(() {
        _data = LiveActivityData.generateMock();
      });
      Future.delayed(const Duration(seconds: 30), _updateData);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CleanTheme.primaryColor.withValues(alpha: 0.1),
            CleanTheme.accentPurple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CleanTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Pulsing dot
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CleanTheme.accentGreen,
                  boxShadow: [
                    BoxShadow(
                      color: CleanTheme.accentGreen.withValues(
                        alpha: 0.5 * _pulseAnimation.value,
                      ),
                      blurRadius: 8 * _pulseAnimation.value,
                      spreadRadius: 2 * _pulseAnimation.value,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          // Counter
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '🔥 ${_data.usersWorkingOutNow}',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: CleanTheme.primaryColor,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' ${AppLocalizations.of(context)!.peopleWorkingOut}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: CleanTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '📈 ${_formatNumber(_data.workoutsCompletedToday)} ${AppLocalizations.of(context)!.workoutsCompleted}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: CleanTheme.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

/// ═══════════════════════════════════════════════════════════
/// REWARD CHEST WIDGET - Loot Box Display
/// ═══════════════════════════════════════════════════════════

class RewardChestWidget extends StatefulWidget {
  final RewardChest chest;
  final VoidCallback? onOpen;
  final bool showAnimation;

  const RewardChestWidget({
    super.key,
    required this.chest,
    this.onOpen,
    this.showAnimation = true,
  });

  @override
  State<RewardChestWidget> createState() => _RewardChestWidgetState();
}

class _RewardChestWidgetState extends State<RewardChestWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    if (widget.showAnimation && !widget.chest.isOpened) {
      _shakeController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Color get _glowColor {
    switch (widget.chest.rarity) {
      case ChestRarity.bronze:
        return const Color(0xFFCD7F32);
      case ChestRarity.silver:
        return const Color(0xFFC0C0C0);
      case ChestRarity.gold:
        return const Color(0xFFFFD700);
      case ChestRarity.legendary:
        return CleanTheme.accentPurple;
    }
  }

  String get _chestIcon {
    switch (widget.chest.rarity) {
      case ChestRarity.bronze:
        return '📦';
      case ChestRarity.silver:
        return '🎁';
      case ChestRarity.gold:
        return '✨';
      case ChestRarity.legendary:
        return '💎';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.chest.isOpened
          ? null
          : () {
              setState(() => _isOpening = true);
              _shakeController.stop();
              widget.onOpen?.call();
            },
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              widget.chest.isOpened || _isOpening ? 0 : _shakeAnimation.value,
              0,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    CleanTheme.cardColor,
                    _glowColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _glowColor.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: _glowColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chest icon
                  Text(_chestIcon, style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  // Rarity label
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _glowColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _glowColor),
                    ),
                    child: Text(
                      '${AppLocalizations.of(context)!.chestLabel} ${widget.chest.rarityName.toUpperCase()}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _glowColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Open button
                  if (!widget.chest.isOpened && !_isOpening)
                    CleanButton(
                      text: AppLocalizations.of(context)!.openChest,
                      icon: Icons.lock_open,
                      onPressed: () {
                        setState(() => _isOpening = true);
                        _shakeController.stop();
                        widget.onOpen?.call();
                      },
                    )
                  else if (_isOpening)
                    const CircularProgressIndicator(
                      color: CleanTheme.primaryColor,
                    )
                  else
                    // Show rewards
                    Column(
                      children: widget.chest.rewards
                          .map(
                            (reward) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    reward.iconEmoji,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    reward.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: reward.isRare
                                          ? CleanTheme.accentPurple
                                          : CleanTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// CHALLENGE CARD WIDGET
/// ═══════════════════════════════════════════════════════════

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.onTap,
    this.onJoin,
  });

  Color get _typeColor {
    switch (challenge.type) {
      case ChallengeType.daily:
        return CleanTheme.accentBlue;
      case ChallengeType.weekly:
        return CleanTheme.accentGreen;
      case ChallengeType.monthly:
        return CleanTheme.accentOrange;
      case ChallengeType.community:
        return CleanTheme.accentPurple;
      case ChallengeType.oneVsOne:
        return CleanTheme.accentRed;
    }
  }

  String _getTypeLabel(BuildContext context) {
    switch (challenge.type) {
      case ChallengeType.daily:
        return AppLocalizations.of(context)!.challengeDaily;
      case ChallengeType.weekly:
        return AppLocalizations.of(context)!.challengeWeekly;
      case ChallengeType.monthly:
        return AppLocalizations.of(context)!.challengeMonthly;
      case ChallengeType.community:
        return AppLocalizations.of(context)!.challengeCommunity;
      case ChallengeType.oneVsOne:
        return AppLocalizations.of(context)!.challengeOneVsOne;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CleanCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _typeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _getTypeLabel(context),
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _typeColor,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              // Time remaining
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: CleanTheme.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    challenge.timeRemainingFormatted,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CleanTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Title & Description
          Text(
            challenge.title,
            style: GoogleFonts.outfit(
              fontSize: 18,
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

          const SizedBox(height: 16),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${challenge.currentProgress}/${challenge.targetValue}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '${(challenge.progressPercentage * 100).toInt()}%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _typeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: challenge.progressPercentage,
                  backgroundColor: CleanTheme.borderSecondary,
                  color: _typeColor,
                  minHeight: 8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Footer
          Row(
            children: [
              // Participants
              Row(
                children: [
                  const Icon(
                    Icons.people,
                    size: 16,
                    color: CleanTheme.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatNumber(challenge.participantsCount)} partecipanti',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CleanTheme.textTertiary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Rewards preview
              Row(
                children: challenge.rewards.take(3).map((reward) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      reward.iconEmoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

/// ═══════════════════════════════════════════════════════════
/// REFERRAL WIDGET
/// ═══════════════════════════════════════════════════════════

class ReferralWidget extends StatelessWidget {
  final ReferralData referralData;
  final VoidCallback? onShare;
  final VoidCallback? onCopyCode;

  const ReferralWidget({
    super.key,
    required this.referralData,
    this.onShare,
    this.onCopyCode,
  });

  @override
  Widget build(BuildContext context) {
    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CleanTheme.accentPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: CleanTheme.accentPurple,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invita Amici',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Guadagna Premium gratis!',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Referral Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CleanTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CleanTheme.borderPrimary),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Il tuo codice',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: CleanTheme.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        referralData.referralCode,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: CleanTheme.primaryColor,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onCopyCode,
                  icon: const Icon(Icons.copy, color: CleanTheme.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Progress to next reward
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Prossimo premio: ${ReferralData.milestoneRewards[referralData.nextMilestone]?.title ?? ""}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '${referralData.convertedReferrals}/${referralData.nextMilestone}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.accentPurple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: referralData.progressToNextMilestone,
                  backgroundColor: CleanTheme.borderSecondary,
                  color: CleanTheme.accentPurple,
                  minHeight: 6,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Share Buttons
          Row(
            children: [
              Expanded(
                child: CleanButton(
                  text: 'Condividi',
                  icon: Icons.share,
                  onPressed: onShare,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// XP FLOATING ANIMATION WIDGET
/// ═══════════════════════════════════════════════════════════

class XpFloatingText extends StatefulWidget {
  final int xpAmount;
  final Offset startPosition;
  final VoidCallback? onComplete;

  const XpFloatingText({
    super.key,
    required this.xpAmount,
    required this.startPosition,
    this.onComplete,
  });

  @override
  State<XpFloatingText> createState() => _XpFloatingTextState();
}

class _XpFloatingTextState extends State<XpFloatingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _translateAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _translateAnimation = Tween<double>(
      begin: 0,
      end: -80,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
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
      builder: (context, child) {
        return Positioned(
          left: widget.startPosition.dx,
          top: widget.startPosition.dy + _translateAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [CleanTheme.accentGreen, Color(0xFF22C55E)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: CleanTheme.accentGreen.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  '+${widget.xpAmount} XP',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
