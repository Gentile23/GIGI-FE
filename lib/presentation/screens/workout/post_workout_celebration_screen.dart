import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/models/addiction_mechanics_model.dart';
import '../../widgets/clean_widgets.dart';

/// ═══════════════════════════════════════════════════════════
/// POST WORKOUT CELEBRATION SCREEN
/// Chest Reward + Stats Summary + XP Gain Animation
/// ═══════════════════════════════════════════════════════════

class PostWorkoutCelebrationScreen extends StatefulWidget {
  final int workoutDurationMinutes;
  final int exercisesCompleted;
  final int setsCompleted;
  final int caloriesBurned;
  final int currentStreak;
  final int xpEarned;

  const PostWorkoutCelebrationScreen({
    super.key,
    required this.workoutDurationMinutes,
    required this.exercisesCompleted,
    required this.setsCompleted,
    this.caloriesBurned = 0,
    this.currentStreak = 1,
    this.xpEarned = 100,
  });

  @override
  State<PostWorkoutCelebrationScreen> createState() =>
      _PostWorkoutCelebrationScreenState();
}

class _PostWorkoutCelebrationScreenState
    extends State<PostWorkoutCelebrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  late RewardChest _chest;
  bool _chestOpened = false;
  bool _showRewards = false;

  @override
  void initState() {
    super.initState();

    // Generate chest based on workout performance
    _chest = RewardChest.generatePostWorkout(
      workoutId: DateTime.now().millisecondsSinceEpoch.toString(),
      workoutDuration: widget.workoutDurationMinutes,
      exercisesCompleted: widget.exercisesCompleted,
      currentStreak: widget.currentStreak,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Celebration Header
                _buildCelebrationHeader(),

                const SizedBox(height: 32),

                // Workout Stats
                _buildWorkoutStats(),

                const SizedBox(height: 32),

                // XP Earned
                _buildXpSection(),

                const SizedBox(height: 32),

                // Reward Chest
                _buildChestSection(),

                const SizedBox(height: 32),

                // Streak Update
                _buildStreakSection(),

                const SizedBox(height: 32),

                // Action Buttons
                _buildActionButtons(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCelebrationHeader() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [CleanTheme.accentGreen, Color(0xFF22C55E)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CleanTheme.accentGreen.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Workout Completato! 🎉',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ottimo lavoro! Continua così.',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: CleanTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutStats() {
    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.timer_outlined,
            value: '${widget.workoutDurationMinutes}',
            label: 'Minuti',
            color: CleanTheme.accentBlue,
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: Icons.fitness_center,
            value: '${widget.exercisesCompleted}',
            label: 'Esercizi',
            color: CleanTheme.accentGreen,
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: Icons.repeat,
            value: '${widget.setsCompleted}',
            label: 'Serie',
            color: CleanTheme.accentOrange,
          ),
          if (widget.caloriesBurned > 0) ...[
            _buildStatDivider(),
            _buildStatItem(
              icon: Icons.local_fire_department,
              value: '${widget.caloriesBurned}',
              label: 'Calorie',
              color: CleanTheme.accentRed,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: CleanTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: CleanTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 50, color: CleanTheme.borderPrimary);
  }

  Widget _buildXpSection() {
    final multiplier = StreakData.calculateMultiplier(widget.currentStreak);
    final bonusXp = (widget.xpEarned * (multiplier - 1)).round();
    final totalXp = widget.xpEarned + bonusXp;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CleanTheme.accentGreen.withValues(alpha: 0.1),
            CleanTheme.accentGreen.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CleanTheme.accentGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⭐', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Text(
                '+$totalXp XP',
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: CleanTheme.accentGreen,
                ),
              ),
            ],
          ),
          if (bonusXp > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: CleanTheme.accentGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '🔥 +$bonusXp bonus streak (x${multiplier.toStringAsFixed(1)})',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChestSection() {
    return Column(
      children: [
        Text(
          'Hai ottenuto un Chest!',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _openChest,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CleanTheme.cardColor,
                  _getChestColor().withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _getChestColor().withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getChestColor().withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                // Chest animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _chestOpened ? 1 : 0),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 1 + (value * 0.2),
                      child: Text(
                        _chestOpened ? '✨' : _getChestEmoji(),
                        style: TextStyle(fontSize: 64 + (value * 20)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getChestColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getChestColor()),
                  ),
                  child: Text(
                    'CHEST ${_chest.rarityName.toUpperCase()}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _getChestColor(),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!_chestOpened)
                  CleanButton(
                    text: 'Apri Chest',
                    icon: Icons.lock_open,
                    onPressed: _openChest,
                  )
                else if (_showRewards)
                  // Show rewards
                  Column(
                    children: _chest.rewards.map((reward) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: reward.isRare
                                ? CleanTheme.accentPurple.withValues(alpha: 0.1)
                                : CleanTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: reward.isRare
                                  ? CleanTheme.accentPurple
                                  : CleanTheme.borderPrimary,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                reward.iconEmoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                reward.name,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: reward.isRare
                                      ? CleanTheme.accentPurple
                                      : CleanTheme.textPrimary,
                                ),
                              ),
                              if (reward.isRare) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: CleanTheme.accentPurple,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'RARE',
                                    style: GoogleFonts.outfit(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakSection() {
    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CleanTheme.accentOrange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Text('🔥', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streak: ${widget.currentStreak} giorni',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                Text(
                  widget.currentStreak == 1
                      ? 'Hai iniziato una nuova streak!'
                      : 'Continua così per bonus XP maggiori!',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: CleanTheme.accentGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'x${StreakData.calculateMultiplier(widget.currentStreak).toStringAsFixed(1)}',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CleanTheme.accentGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        CleanButton(
          text: 'Condividi Risultato',
          icon: Icons.share,
          width: double.infinity,
          onPressed: () {
            // Share functionality
          },
        ),
        const SizedBox(height: 12),
        CleanButton(
          text: 'Torna alla Home',
          width: double.infinity,
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ],
    );
  }

  Color _getChestColor() {
    switch (_chest.rarity) {
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

  String _getChestEmoji() {
    switch (_chest.rarity) {
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

  void _openChest() {
    setState(() {
      _chestOpened = true;
    });

    // Show rewards after animation
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showRewards = true;
        });
      }
    });
  }
}
