import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';
import '../../../presentation/widgets/celebrations/celebration_overlay.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/gamification_provider.dart';
import '../questionnaire/unified_questionnaire_screen.dart';
import '../../widgets/gigi/gigi_coach_message.dart';
import '../../widgets/clean_widgets.dart';
import 'package:gigi/l10n/app_localizations.dart';

import '../workout/workout_session_screen.dart';
import '../../../data/models/user_model.dart';

import '../../widgets/skeleton_box.dart';
import '../profile/profile_screen.dart';
import '../social/activity_feed_screen.dart';
import '../form_analysis/form_analysis_screen.dart';
import '../../widgets/insights/health_trends_carousel.dart';
import '../insights/weekly_report_screen.dart';

/// ═══════════════════════════════════════════════════════════
/// ENHANCED HOME SCREEN - Single Focus Design
/// Psychology: F-Pattern reading, single CTA above the fold
/// Streak prominente per loss aversion
/// ═══════════════════════════════════════════════════════════
class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen> {
  bool _showCelebration = false;
  final int _currentWorkoutIndex = 0; // Track which workout to show
  final CelebrationStyle _celebrationStyle = CelebrationStyle.confetti;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _setupGenerationCompleteCallback();
    });
  }

  void _setupGenerationCompleteCallback() {
    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );

    workoutProvider.onGenerationComplete = () {
      if (mounted) {
        setState(() {
          _showCelebration = true;
        });
        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.snackPlanReady),
            backgroundColor: CleanTheme.accentGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    };
  }

  // ... (keeping other methods intact)

  @override
  void dispose() {
    // Clean up callback - use try-catch to avoid deactivated widget error
    try {
      if (mounted) {
        final workoutProvider = Provider.of<WorkoutProvider>(
          context,
          listen: false,
        );
        workoutProvider.onGenerationComplete = null;
      }
    } catch (_) {
      // Widget already disposed, ignore
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Color
          Container(color: CleanTheme.scaffoldBackgroundColor),

          SafeArea(
            child: Consumer2<AuthProvider, WorkoutProvider>(
              builder: (context, authProvider, workoutProvider, _) {
                final user = authProvider.user;

                // SKELETON LOADING STATE
                if (workoutProvider.isLoading) {
                  return _buildSkeletonLoading();
                }

                return RefreshIndicator(
                  onRefresh: _loadData,
                  color: CleanTheme.primaryColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      24,
                      16,
                      24,
                      ResponsiveUtils.floatingElementPadding(
                        context,
                        baseHeight: 80,
                      ),
                    ), // Dynamic bottom padding for navbar
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Header (Hello, Name + Avatar)
                        _buildCompactHeader(user),

                        const SizedBox(height: 32),

                        _buildGigiGuidance(workoutProvider),

                        // 4. Hero Section
                        Text(
                          AppLocalizations.of(context)!.homeNextWorkoutTitle,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: CleanTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildHeroWorkoutCard(workoutProvider),

                        const SizedBox(height: 32),

                        // 5. Weekly Stats (Upcoming tours/stats)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.homeProgressTitle,
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: CleanTheme.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                AppLocalizations.of(context)!.viewAll,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: CleanTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildQuickStatsRow(),

                        const SizedBox(height: 24),
                        _buildStreakMotivator(),

                        // Health Insights Section
                        const SizedBox(height: 32),
                        HealthTrendsCarousel(
                          onViewAllTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WeeklyReportScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // 6. Quick Actions
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCardWide(
                                Icons.auto_awesome,
                                AppLocalizations.of(
                                  context,
                                )!.actionGeneratePlan,
                                AppLocalizations.of(
                                  context,
                                )!.actionGeneratePlanDesc,
                                const Color(0xFF00D26A),
                                () {
                                  HapticService.lightTap();
                                  final workoutProvider =
                                      Provider.of<WorkoutProvider>(
                                        context,
                                        listen: false,
                                      );
                                  final authProvider =
                                      Provider.of<AuthProvider>(
                                        context,
                                        listen: false,
                                      );
                                  final user = authProvider.user;
                                  final isQuestionnaireComplete =
                                      user?.isQuestionnaireComplete ?? false;

                                  if (workoutProvider.currentPlan == null) {
                                    if (isQuestionnaireComplete) {
                                      // Questionnaire complete -> generate plan directly
                                      _generatePlanDirectly();
                                    } else {
                                      // Questionnaire not done, go to questionnaire
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const UnifiedQuestionnaireScreen(),
                                        ),
                                      ).then((_) => _loadData());
                                    }
                                  } else {
                                    _showGeneratePlanDialog();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Community & Form Check
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCardWide(
                                Icons.people_alt_rounded,
                                AppLocalizations.of(context)!.actionCommunity,
                                AppLocalizations.of(
                                  context,
                                )!.actionCommunityDesc,
                                CleanTheme.accentOrange,
                                () {
                                  HapticService.lightTap();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ActivityFeedScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Custom & History
                        // Custom & History (Modified)
                        // Premium Form Check Card
                        GestureDetector(
                          onTap: () {
                            HapticService.lightTap();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const FormAnalysisScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFDAA520),
                                  const Color(0xFFFFD700),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFDAA520,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.actionFormCheck,
                                            style: GoogleFonts.outfit(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          /* Lock removed as per user request
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.3,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Icon(
                                              Icons.lock,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                          */
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Analizza la tua esecuzione con l\'AI',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_showCelebration)
            CelebrationOverlay(
              style: _celebrationStyle,
              onComplete: () => setState(() => _showCelebration = false),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader(UserModel? user) {
    final greeting = _getTimeBasedGreeting();
    final name = user?.name ?? 'Atleta';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting,',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: CleanTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              name,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: CleanTheme.textPrimary,
                height: 1.2,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: CleanTheme.borderPrimary, width: 2),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: CleanTheme.primaryColor,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return AppLocalizations.of(context)!.homeTitleGreetingEarly;
    if (hour < 12) {
      return AppLocalizations.of(context)!.homeTitleGreetingMorning;
    }
    if (hour < 18) {
      return AppLocalizations.of(context)!.homeTitleGreetingAfternoon;
    }
    return AppLocalizations.of(context)!.homeTitleGreetingEvening;
  }

  Widget _buildStreakMotivator() {
    return Consumer<GamificationProvider>(
      builder: (context, provider, _) {
        final streak = provider.stats?.currentStreak ?? 0;
        final isActive = streak > 0;

        // Color Psychology
        List<Color> gradientColors;
        if (streak < 3) {
          gradientColors = [const Color(0xFF00D26A), const Color(0xFF00BFA5)];
        } else if (streak < 7) {
          gradientColors = [const Color(0xFFFF9800), const Color(0xFFFF6D00)];
        } else {
          gradientColors = [const Color(0xFFFF3D00), const Color(0xFFD500F9)];
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : CleanTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: isActive
                ? null
                : Border.all(color: CleanTheme.borderSecondary),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: gradientColors[0].withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '🔥',
                  style: TextStyle(fontSize: isActive ? 24 : 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive
                          ? AppLocalizations.of(context)!.streakDays(streak)
                          : AppLocalizations.of(context)!.streakStart,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isActive ? Colors.white : CleanTheme.textPrimary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isActive
                          ? AppLocalizations.of(context)!.streakKeepGoing
                          : AppLocalizations.of(context)!.streakStartToday,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isActive
                            ? Colors.white.withValues(alpha: 0.9)
                            : CleanTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 4. Immersive Hero Card
  Widget _buildHeroWorkoutCard(WorkoutProvider workoutProvider) {
    if (workoutProvider.isGenerating) return _buildGeneratingCard();

    // Determine what to show
    String title = '';
    String subtitle = '';
    List<Color> gradientColors = [CleanTheme.primaryColor, Colors.black87];
    VoidCallback? onActionTap;
    String actionLabel = AppLocalizations.of(context)!.start;
    bool showHeart = false;

    // --- Default Dashboard View ---
    final hasActivePlan = workoutProvider.currentPlan != null;
    final workouts = hasActivePlan ? workoutProvider.currentPlan!.workouts : [];

    // Get next workout based on saved index, with wrap-around
    final safeIndex = workouts.isNotEmpty
        ? _currentWorkoutIndex % workouts.length
        : 0;
    final currentWorkout = workouts.isNotEmpty ? workouts[safeIndex] : null;

    if (hasActivePlan && currentWorkout != null) {
      title = currentWorkout.name;
      subtitle =
          '${currentWorkout.exercises.length} Esercizi • ${currentWorkout.estimatedDuration} min';
      gradientColors = [const Color(0xFF1A1A2E), const Color(0xFF16213E)];
      showHeart = true;

      onActionTap = () async {
        // Increment workout index for next time
        final prefs = await SharedPreferences.getInstance();
        final nextIndex = (safeIndex + 1) % workouts.length;
        await prefs.setInt('next_workout_index', nextIndex);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutSessionScreen(workoutDay: currentWorkout),
            ),
          ).then((_) {
            // Refresh index when returning from workout
            _loadData();
          });
        }
      };
    } else {
      // No active plan - check if questionnaire is complete
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      final isQuestionnaireComplete = user?.isQuestionnaireComplete ?? false;

      if (isQuestionnaireComplete) {
        // Questionario completo -> Genera scheda direttamente
        // Il primo workout farà la calibrazione automatica in background
        title = AppLocalizations.of(context)!.generatePlanCardTitle;
        subtitle = AppLocalizations.of(context)!.generatePlanCardSubtitle;
        gradientColors = [const Color(0xFF00D26A), const Color(0xFF00BFA5)];
        showHeart = false;

        onActionTap = () {
          _generatePlanDirectly();
        };
      } else {
        // Questionario non completo - Mostra prompt per completare profilo
        title = AppLocalizations.of(context)!.welcomeBack;
        subtitle = AppLocalizations.of(context)!.generatePlanCardSubtitle;
        gradientColors = [CleanTheme.primaryColor, Colors.black87];

        onActionTap = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UnifiedQuestionnaireScreen(),
            ),
          ).then((_) => _loadData());
        };
      }
    }

    return GestureDetector(
      onTap: onActionTap,
      child: Container(
        height: 380,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: CleanTheme.cardShadow,
        ),
        child: Stack(
          children: [
            // Background Pattern (removed - asset doesn't exist)
            // Could be replaced with a gradient or other decoration

            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),

            // Heart Icon
            if (showHeart)
              Positioned(
                top: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),

            // Content
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      AppLocalizations.of(context)!.aiPlanBadge,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Button
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: Text(
                            actionLabel,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: CleanTheme.textPrimary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: const BoxDecoration(
                              color: CleanTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: CleanTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: CleanTheme.primaryColor),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.aiCreatingPlan,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.aiCreatingPlanDesc,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CleanTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    return Consumer<GamificationProvider>(
      builder: (context, provider, _) {
        final stats = provider.stats;
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '🎯',
                AppLocalizations.of(context)!.goal,
                '${stats?.totalWorkouts ?? 0}/5',
                const Color(0xFF00D26A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '🏆',
                AppLocalizations.of(context)!.level,
                '${stats?.level ?? 1}',
                const Color(0xFF9B59B6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '⚡',
                'XP',
                '${stats?.totalXp ?? 0}',
                const Color(0xFFFF6B35),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CleanTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
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

  // _buildWeeklyProgress and _buildQuickActions removed as they are unused.

  Widget _buildActionCardWide(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  void _showGeneratePlanDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade100,
              child: ClipOval(
                child: Image.asset(
                  'assets/images/gigi_new_logo.png',
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Genera Scheda AI',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: CleanTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'L\'AI creerà una scheda personalizzata basata sul tuo profilo.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CleanTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFFFF9800),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La calibrazione AI avviene automaticamente durante il primo allenamento',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annulla',
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D26A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _generatePlanDirectly();
            },
            child: Text(
              'Genera Ora',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Header Skeleton
            Row(
              children: [
                const SkeletonBox(width: 48, height: 48, radius: 24),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 100, height: 14),
                    SizedBox(height: 8),
                    SkeletonBox(width: 160, height: 20),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Streak Skeleton
            const SkeletonBox(width: double.infinity, height: 80, radius: 20),
            const SizedBox(height: 24),
            // Hero Card Skeleton
            const SkeletonBox(width: double.infinity, height: 280, radius: 24),
            const SizedBox(height: 24),
            // Stats Row Skeleton
            Row(
              children: List.generate(
                3,
                (index) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index < 2 ? 12.0 : 0),
                    child: const SkeletonBox(
                      width: double.infinity,
                      height: 80,
                      radius: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGigiGuidance(WorkoutProvider provider) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final isQuestionnaireComplete = user?.isQuestionnaireComplete ?? false;

    if (provider.currentPlan == null) {
      // User has NO plan yet
      if (isQuestionnaireComplete) {
        // Questionnaire complete -> can generate plan directly
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: GigiCoachMessage(
            message: AppLocalizations.of(context)!.gigiAssessmentComplete,
            emotion: GigiEmotion.celebrating,
            action: CleanButton(
              text: AppLocalizations.of(context)!.gigiGeneratePlanButton,
              onPressed: () {
                _generatePlanDirectly();
              },
            ),
          ),
        );
      } else {
        // Questionnaire not done -> prompt to complete profile
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: GigiCoachMessage(
            message: AppLocalizations.of(context)!.gigiStartTransformation,
            emotion: GigiEmotion.expert,
            action: CleanButton(
              text: 'Completa il Profilo',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UnifiedQuestionnaireScreen(),
                  ),
                ).then((_) => _loadData());
              },
            ),
          ),
        );
      }
    }

    // User HAS an active plan
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GigiCoachMessage(
        message: AppLocalizations.of(context)!.gigiReadyForWorkout,
        emotion: GigiEmotion.expert,
      ),
    );
  }

  Future<void> _generatePlanDirectly() async {
    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: CleanTheme.primaryColor),
      ),
    );

    final success = await workoutProvider.generatePlan();

    if (mounted) {
      Navigator.pop(context); // Close loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Scheda generata con successo!'),
            backgroundColor: CleanTheme.accentGreen,
          ),
        );
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Errore: ${workoutProvider.error ?? "Riprova"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    // Refresh User Data
    await Provider.of<AuthProvider>(context, listen: false).fetchUser();

    // Refresh Workout Data
    if (!mounted) return;
    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );
    await workoutProvider.fetchCurrentPlan();

    // Refresh Gamification
    if (!mounted) return;
    final gamificationProvider = Provider.of<GamificationProvider>(
      context,
      listen: false,
    );
    gamificationProvider.refresh();

    if (mounted) setState(() {});
  }
}
