import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';
import '../../../presentation/widgets/clean_widgets.dart';
import '../../../presentation/widgets/gamification_stats_widget.dart';
import '../../../presentation/widgets/adaptive_training_widget.dart';
import '../../../presentation/widgets/biometric_widget.dart';
import '../../../presentation/widgets/nutrition_widget.dart';
import '../../../presentation/widgets/form_check_widget.dart';
import '../../../presentation/widgets/engagement/social_proof_widgets.dart';
import '../../../presentation/widgets/engagement/daily_challenge_widget.dart';
import '../../../presentation/widgets/gamification/gamification_widgets.dart';
import '../../../presentation/widgets/celebrations/celebration_overlay.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/gamification_provider.dart';
import '../../../providers/engagement_provider.dart';
import '../workout/trial_workout_generation_screen.dart';
import '../custom_workout/custom_workout_list_screen.dart';
import '../../../data/models/user_model.dart';

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen> {
  bool _showCelebration = false;
  CelebrationStyle _celebrationStyle = CelebrationStyle.confetti;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );
    final gamificationProvider = Provider.of<GamificationProvider>(
      context,
      listen: false,
    );

    workoutProvider.fetchCurrentPlan();
    gamificationProvider.refresh();

    // Load engagement data
    try {
      final engagementProvider = Provider.of<EngagementProvider>(
        context,
        listen: false,
      );
      await engagementProvider.loadHomeData();
    } catch (e) {
      debugPrint('EngagementProvider not available: $e');
    }

    workoutProvider.onGenerationComplete = () {
      if (mounted) {
        _showCelebrationOverlay(CelebrationStyle.confetti);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Piano generato con successo!'),
            backgroundColor: CleanTheme.primaryColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
    };
  }

  void _showCelebrationOverlay(CelebrationStyle style) {
    setState(() {
      _celebrationStyle = style;
      _showCelebration = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showCelebration = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Consumer2<AuthProvider, WorkoutProvider>(
              builder: (context, authProvider, workoutProvider, _) {
                final user = authProvider.user;
                final currentPlan = workoutProvider.currentPlan;

                return RefreshIndicator(
                  onRefresh: _loadData,
                  color: CleanTheme.primaryColor,
                  backgroundColor: CleanTheme.surfaceColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // Enhanced Header
                        _buildHeader(user),

                        const SizedBox(height: 24),

                        // Engagement widgets (Near Miss, Streak Warning)
                        _buildEngagementSection(),

                        // Level Progress
                        _buildLevelProgress(),

                        const SizedBox(height: 20),

                        // Social Proof Counter
                        _buildSocialProof(),

                        const SizedBox(height: 20),

                        // Daily Challenges
                        _buildDailyChallenges(),

                        const SizedBox(height: 20),

                        // Gamification Stats
                        // TODO: Update internal style of this widget
                        const GamificationStatsWidget(),

                        const SizedBox(height: 16),

                        // Adaptive Training
                        const AdaptiveTrainingWidget(),

                        const SizedBox(height: 16),

                        // Biometric
                        const BiometricWidget(),

                        const SizedBox(height: 16),

                        // Nutrition
                        const NutritionWidget(),

                        const SizedBox(height: 16),

                        // Form Check
                        const FormCheckWidget(),

                        const SizedBox(height: 24),

                        // Current Plan or Trial
                        _buildMainActionSection(
                          workoutProvider,
                          currentPlan,
                          user,
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Celebration overlay
          if (_showCelebration)
            CelebrationOverlay(
              style: _celebrationStyle,
              onComplete: () => setState(() => _showCelebration = false),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(UserModel? user) {
    // Try to get personalized greeting
    String greeting = _getTimeBasedGreeting();
    String motivationalMessage = 'Pronto a superare i tuoi limiti?';

    try {
      final engagementProvider = Provider.of<EngagementProvider>(
        context,
        listen: false,
      );
      if (engagementProvider.motivationMessage != null) {
        motivationalMessage = engagementProvider.motivationMessage!;
      }
    } catch (_) {}

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, ${user?.name ?? 'Atleta'} 👋',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                motivationalMessage,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: CleanTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        const CleanAvatar(
          initials: 'FG', // TODO: User initials
          size: 50,
          showBorder: true,
        ),
      ],
    );
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buongiorno';
    if (hour < 18) return 'Buon pomeriggio';
    return 'Buona sera';
  }

  Widget _buildEngagementSection() {
    try {
      return Consumer<EngagementProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Streak Warning (urgente)
              if (provider.hasStreakWarning) ...[
                StreakWarningWidget(
                  currentStreak: provider.getCurrentStreakAtRisk() ?? 0,
                  hoursRemaining: provider.getStreakHoursRemaining() ?? 0,
                  onTap: () {
                    HapticService.mediumTap();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const TrialWorkoutGenerationScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Near Miss (quasi al level up)
              if (provider.hasNearMiss) ...[
                NearMissWidget(
                  xpRemaining: provider.getXpRemaining() ?? 0,
                  nextLevel: 2, // TODO: get from stats
                  onTap: () {
                    HapticService.mediumTap();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const TrialWorkoutGenerationScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ],
          );
        },
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildLevelProgress() {
    return Consumer<GamificationProvider>(
      builder: (context, provider, _) {
        final stats = provider.stats;
        if (stats == null) return const SizedBox.shrink();

        return LevelProgressWidget(
          currentLevel: stats.level,
          currentXP: stats.totalXp % 100,
          xpForNextLevel: 100,
          onTap: () {
            HapticService.lightTap();
            // Navigate to full stats
          },
        );
      },
    );
  }

  Widget _buildSocialProof() {
    try {
      return Consumer<EngagementProvider>(
        builder: (context, provider, _) {
          return SocialProofCounter(
            count: provider.workoutsToday > 0 ? provider.workoutsToday : 127,
            message: 'workout completati oggi',
            animate: true,
          );
        },
      );
    } catch (_) {
      return SocialProofCounter(
        count: 127,
        message: 'workout completati oggi dalla community',
        animate: true,
      );
    }
  }

  Widget _buildDailyChallenges() {
    try {
      return Consumer<EngagementProvider>(
        builder: (context, provider, _) {
          if (provider.dailyChallenges.isEmpty) {
            return _buildDefaultChallenges();
          }

          return DailyChallengesList(
            challenges: provider.dailyChallenges,
            onChallengeTap: (challengeId) async {
              HapticService.mediumTap();
              final success = await provider.completeDailyChallenge(
                challengeId,
              );
              if (success && mounted) {
                _showCelebrationOverlay(CelebrationStyle.sparkles);
              }
            },
          );
        },
      );
    } catch (_) {
      return _buildDefaultChallenges();
    }
  }

  Widget _buildDefaultChallenges() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CleanSectionHeader(title: '🎯 Sfida del Giorno'),
        const SizedBox(height: 12),
        DailyChallengeWidget(
          title: 'Guerriero del Mattino',
          description: 'Completa un workout prima delle 10:00',
          xpReward: 100,
          timeRemaining: endOfDay.difference(now),
          progress: 0.0,
          completedToday: 47,
          onTap: () {
            HapticService.mediumTap();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TrialWorkoutGenerationScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMainActionSection(
    WorkoutProvider workoutProvider,
    dynamic currentPlan,
    UserModel? user,
  ) {
    if (workoutProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (workoutProvider.isGenerating ||
        (currentPlan != null && currentPlan.status == 'processing')) {
      return _buildGeneratingCard();
    }

    return _buildTrialWorkoutCard();
  }

  Widget _buildGeneratingCard() {
    return CleanCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const CircularProgressIndicator(color: CleanTheme.primaryColor),
          const SizedBox(height: 24),
          Text(
            '🤖 AI sta analizzando il tuo profilo',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generazione piano in corso...\nAttendi mentre l\'AI crea il tuo allenamento personalizzato.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CleanTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrialWorkoutCard() {
    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CleanTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: CleanTheme.primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inizia il Tuo Viaggio 🚀',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prova un workout con coach vocale AI!',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // CTA Button
          CleanButton(
            text: 'Inizia Trial Workout',
            icon: Icons.fitness_center,
            width: double.infinity,
            onPressed: () {
              HapticService.mediumTap();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrialWorkoutGenerationScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // Custom Workout Button
          CleanButton(
            text: 'Le Mie Schede 📋',
            icon: Icons.edit_note,
            width: double.infinity,
            isPrimary: false,
            isOutlined: true,
            onPressed: () {
              HapticService.lightTap();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomWorkoutListScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),
          // Social proof
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.people_outline,
                size: 14,
                color: CleanTheme.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                '1,247 persone hanno iniziato questa settimana',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: CleanTheme.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
