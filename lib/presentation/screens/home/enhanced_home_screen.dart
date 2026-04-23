import 'package:flutter/material.dart';

import '../../../core/utils/responsive_utils.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/utils/next_workout_selector.dart';
import '../../../core/services/health_integration_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../presentation/widgets/celebrations/celebration_overlay.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/workout_log_provider.dart';
import '../../../core/constants/gigi_guidance_content.dart';
import '../questionnaire/unified_questionnaire_screen.dart';
import '../../widgets/gigi/gigi_coach_message.dart';
import '../../widgets/clean_widgets.dart';
import 'package:gigi/l10n/app_localizations.dart';
import '../../widgets/animations/liquid_steel_container.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../workout/workout_session_screen.dart';
import '../../../data/models/custom_workout_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/custom_workout_service.dart';

import '../../widgets/skeleton_box.dart';
import '../profile/profile_screen.dart';
import '../form_analysis/form_analysis_screen.dart';
import '../../widgets/insights/health_trends_carousel.dart';
import '../insights/weekly_report_screen.dart';
import '../../navigation/main_tab_navigation.dart';
import '../main_screen.dart';

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

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen>
    with WidgetsBindingObserver {
  static const String _customWorkoutOrderKey = 'custom_workout_order_v1';
  final HealthIntegrationService _healthService = HealthIntegrationService();
  bool _showCelebration = false;
  bool _isHealthConnected = false;
  late final CustomWorkoutService _customWorkoutService;
  List<CustomWorkoutPlan> _customPlans = [];
  Map<String, dynamic>? _overviewStats;
  final CelebrationStyle _celebrationStyle = CelebrationStyle.confetti;
  VoidCallback? _onGenerationComplete;

  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
    }
    return 0;
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _customWorkoutService = CustomWorkoutService(ApiClient());

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

    _onGenerationComplete = () {
      if (mounted) {
        setState(() {
          _showCelebration = true;
        });
        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.snackPlanReady),
            backgroundColor: CleanTheme.surfaceColor,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: CleanTheme.borderPrimary),
            ),
          ),
        );
      }
    };
    workoutProvider.addGenerationCompleteListener(_onGenerationComplete!);
  }

  // ... (keeping other methods intact)

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Clean up callback - use try-catch to avoid deactivated widget error
    try {
      if (_onGenerationComplete != null && mounted) {
        final workoutProvider = Provider.of<WorkoutProvider>(
          context,
          listen: false,
        );
        workoutProvider.removeGenerationCompleteListener(
          _onGenerationComplete!,
        );
      }
    } catch (_) {
      // Widget already disposed, ignore
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshHealthConnectionState();
    }
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
            child: Consumer3<AuthProvider, WorkoutProvider, WorkoutLogProvider>(
              builder:
                  (
                    context,
                    authProvider,
                    workoutProvider,
                    workoutLogProvider,
                    _,
                  ) {
                    final user = authProvider.user;
                    final isLoading =
                        workoutProvider.isLoading ||
                        !workoutProvider.isInitialized;

                    return RefreshIndicator(
                      key: const ValueKey('home_root_refresh'),
                      onRefresh: _loadData,
                      color: CleanTheme.primaryColor,
                      child: SingleChildScrollView(
                        key: const ValueKey('home_root_scroll'),
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          24,
                          16,
                          24,
                          ResponsiveUtils.floatingElementPadding(
                            context,
                            baseHeight: 80,
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: isLoading
                              ? _buildSkeletonLoading(
                                  key: const ValueKey('home_skeleton'),
                                )
                              : Column(
                                  key: const ValueKey('home_content_column'),
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. Header (Hello, Name + Avatar)
                                    _buildCompactHeader(user),

                                    const SizedBox(height: 32),

                                    _buildGigiGuidance(workoutProvider),

                                    // 4. Hero Section
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.homeNextWorkoutTitle,
                                      style: GoogleFonts.outfit(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: CleanTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildHeroWorkoutCard(
                                      workoutProvider,
                                      workoutLogProvider,
                                    ),

                                    const SizedBox(height: 32),

                                    // 5. Weekly Stats (Upcoming tours/stats)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.homeProgressTitle,
                                          style: GoogleFonts.outfit(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: CleanTheme.textPrimary,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            HapticService.lightTap();
                                            final insideMainShell =
                                                context
                                                    .findAncestorWidgetOfExactType<
                                                      MainScreen
                                                    >() !=
                                                null;
                                            if (insideMainShell) {
                                              MainTabNavigation.goTo(3);
                                            } else {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const MainScreen(
                                                        initialIndex: 3,
                                                      ),
                                                ),
                                              );
                                            }
                                          },
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.viewAll,
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
                                            builder: (_) =>
                                                const WeeklyReportScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    if (_isHealthConnected) ...[
                                      const SizedBox(height: 12),
                                      _buildHealthSyncBadge(),
                                    ],
                                    const SizedBox(height: 16),
                                    // 6. Quick Actions
                                    // Row 1: Form Check AI (Full Width)
                                    GestureDetector(
                                      onTap: () {
                                        HapticService.lightTap();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const FormAnalysisScreen(),
                                          ),
                                        );
                                      },
                                      child: LiquidSteelContainer(
                                        borderRadius: 16,
                                        enableShine: true,
                                        border: Border.all(
                                          color: CleanTheme.textOnPrimary
                                              .withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        14,
                                                      ), // Unified with standard
                                                  border: Border.all(
                                                    color: CleanTheme
                                                        .textOnPrimary
                                                        .withValues(alpha: 0.1),
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.camera_alt_outlined,
                                                  color:
                                                      CleanTheme.textOnPrimary,
                                                  size: 26,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      AppLocalizations.of(
                                                        context,
                                                      )!.actionFormCheck,
                                                      style: GoogleFonts.inter(
                                                        // Unified font
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: CleanTheme
                                                            .textOnPrimary,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Analizza con AI',
                                                      style: GoogleFonts.inter(
                                                        fontSize: 12,
                                                        color: CleanTheme
                                                            .textOnPrimary
                                                            .withValues(
                                                              alpha: 0.85,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(
                                                Icons.arrow_forward_ios,
                                                color: CleanTheme.textOnPrimary,
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
              gradient: LinearGradient(
                colors: [CleanTheme.chromeSilver, CleanTheme.textSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) => CleanAvatar(
                size: 48,
                imageUrl: auth.user?.avatarUrl,
                initials: name.isNotEmpty ? name[0].toUpperCase() : 'A',
                backgroundColor: CleanTheme.surfaceColor,
                isPremium: auth.user?.subscription?.isActive ?? false,
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
    final streak = _asInt(_overviewStats?['current_streak']);
    final isActive = streak > 0;

    if (isActive) {
      return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF000000), // Nera come la sidebar
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: CleanTheme.textOnPrimary.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: CleanTheme.accentOrange.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: -2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CleanTheme.accentOrange.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: CleanTheme.accentOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Text('🔥', style: TextStyle(fontSize: 24))
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(duration: 1500.ms, color: Colors.white)
                        .scaleXY(
                          begin: 1.0,
                          end: 1.15,
                          duration: 600.ms,
                          curve: Curves.easeInOut,
                        )
                        .then()
                        .scaleXY(
                          begin: 1.15,
                          end: 1.0,
                          duration: 600.ms,
                          curve: Curves.easeInOut,
                        ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.streakDays(streak),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: CleanTheme.textOnPrimary,
                            letterSpacing: 1.0,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.8),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.streakKeepGoing,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: CleanTheme.textOnPrimary.withValues(
                              alpha: 0.9,
                            ),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .animate()
          .fadeIn(duration: 600.ms, curve: Curves.easeOut)
          .slideY(
            begin: 0.1,
            end: 0,
            duration: 600.ms,
            curve: Curves.easeOutQuint,
          )
          .shimmer(delay: 800.ms, duration: 1500.ms, color: Colors.white10);
    }

    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF000000), // Nera come la sidebar
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: CleanTheme.textOnPrimary.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CleanTheme.textOnPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Text('🔥', style: TextStyle(fontSize: 20))
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .shimmer(duration: 2000.ms, color: Colors.white54),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.streakStart,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: CleanTheme.textOnPrimary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.streakStartToday,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CleanTheme.textOnPrimary.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(
          begin: 0.1,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOutQuint,
        );
  }

  // 4. Immersive Hero Card
  Widget _buildHeroWorkoutCard(
    WorkoutProvider workoutProvider,
    WorkoutLogProvider workoutLogProvider,
  ) {
    final plan = workoutProvider.currentPlan;
    final bool isStillGenerating =
        workoutProvider.isGenerating ||
        (plan != null && plan.status == 'processing');

    if (isStillGenerating) return _buildGeneratingCard();

    // Determine what to show
    String title = '';
    String subtitle = '';
    bool isCustomSuggestion = false;
    // List<Color> gradientColors = [CleanTheme.primaryColor, Colors.black87]; // Removed
    VoidCallback? onActionTap;
    String actionLabel = AppLocalizations.of(context)!.start;

    final nextSuggestion = NextWorkoutSelector.resolve(
      aiPlan: workoutProvider.currentPlan,
      customPlans: _customPlans,
      workoutHistory: workoutLogProvider.workoutHistory,
    );
    final currentWorkout = nextSuggestion?.workoutDay;
    isCustomSuggestion = nextSuggestion?.isCustom ?? false;

    if (currentWorkout != null) {
      title = currentWorkout.name;
      subtitle =
          '${currentWorkout.exercises.length} Esercizi • ${currentWorkout.estimatedDuration} min';
      // gradientColors = [const Color(0xFF1C1C1E), const Color(0xFF000000)]; // Removed

      onActionTap = () async {
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
        title = AppLocalizations.of(context)!.generatePlanCardTitle;
        subtitle = AppLocalizations.of(context)!.generatePlanCardSubtitle;
        // gradientColors = [const Color(0xFF3A3A3C), const Color(0xFF1C1C1E)]; // Removed

        onActionTap = () {
          _generatePlanDirectly();
        };
      } else {
        // Questionario non completo - Mostra prompt per completare profilo
        title = AppLocalizations.of(context)!.welcomeBack;
        subtitle = AppLocalizations.of(context)!.generatePlanCardSubtitle;
        // gradientColors = [const Color(0xFF2C2C2E), const Color(0xFF000000)]; // Removed

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

    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = (screenHeight * 0.38).clamp(280.0, 400.0);

    return SizedBox(
      height: cardHeight,
      width: double.infinity,
      child: GestureDetector(
        onTap: onActionTap,
        child: LiquidSteelContainer(
          borderRadius: 32,
          enableShine: true,
          border: Border.all(
            color: CleanTheme.textOnPrimary.withValues(alpha: 0.3),
            width: 1,
          ),
          child: Stack(
            fit: StackFit.loose,
            children: [
              // Internal Gradient Overlay for depth over the steel
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.4),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Content
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: CleanTheme.textOnPrimary.withValues(
                              alpha: 0.3,
                            ),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          isCustomSuggestion
                              ? 'SCHEDA PERSONALIZZATA'
                              : AppLocalizations.of(context)!.aiPlanBadge,
                          style: GoogleFonts.inter(
                            color: CleanTheme.textOnPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: CleanTheme.textOnPrimary,
                          height: 1.1,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: CleanTheme.textOnPrimary.withValues(
                            alpha: 0.9,
                          ),
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      // Action Button – White High Contrast
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: CleanTheme.textOnPrimary,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 24),
                              child: Text(
                                actionLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Container(
                                height: 40,
                                width: 40,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  color: CleanTheme.textOnPrimary,
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
              ),
            ],
          ), // Stack
        ), // LiquidSteelContainer
      ), // GestureDetector
    ); // SizedBox
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
    final overviewStats = _overviewStats;
    final totalWorkouts = _asInt(overviewStats?['total_workouts']);
    final totalSets = _asInt(overviewStats?['total_sets']);
    final totalMinutes = _asInt(overviewStats?['total_time_minutes']);
    final totalVolume = _asDouble(overviewStats?['total_volume_kg']);
    final timeLabel = totalMinutes >= 60
        ? '${totalMinutes ~/ 60}h ${(totalMinutes % 60)}m'
        : '${totalMinutes}m';

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '🏋️',
            AppLocalizations.of(context)!.progressWorkouts,
            totalWorkouts >= 1000
                ? '${(totalWorkouts / 1000).toStringAsFixed(1)}k'
                : '$totalWorkouts',
            const Color(0xFF000000),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '📊',
            AppLocalizations.of(context)!.progressTotalSets,
            totalSets >= 1000
                ? '${(totalSets / 1000).toStringAsFixed(1)}k'
                : '$totalSets',
            const Color(0xFF3A3A3C),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            totalVolume > 0 ? '🏔️' : '⏱️',
            totalVolume > 0
                ? 'Volume'
                : AppLocalizations.of(context)!.progressTotalTime,
            totalVolume > 0
                ? (totalVolume >= 1000
                      ? '${(totalVolume / 1000).toStringAsFixed(1)}t'
                      : '${totalVolume.toStringAsFixed(0)}kg')
                : timeLabel,
            const Color(0xFF636366),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthSyncBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: CleanTheme.accentRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: CleanTheme.accentRed.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_rounded,
              size: 14,
              color: CleanTheme.accentRed.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 6),
            Text(
              'Dati sincronizzati con Apple Health',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CleanTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CleanTheme.borderSecondary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
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

  Widget _buildSkeletonLoading({Key? key}) {
    return Column(
      key: key,
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
        SkeletonBox(
          width: double.infinity,
          height: (MediaQuery.of(context).size.height * 0.38).clamp(
            280.0,
            400.0,
          ),
          radius: 24,
        ),
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
            messageId: 'home.assessment_complete',
            title: 'Come usare la home',
            message: GigiGuidanceContent.homeAssessmentComplete(),
            emotion: GigiEmotion.celebrating,
          ),
        );
      } else {
        // Questionnaire not done -> prompt to complete profile
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: GigiCoachMessage(
            messageId: 'home.questionnaire_incomplete',
            title: 'Prima configurazione',
            message: GigiGuidanceContent.homeQuestionnaireIncomplete(),
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

    // User HAS a plan
    if (provider.isGenerating || provider.currentPlan?.status == 'processing') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: GigiCoachMessage(
          messageId: 'home.plan_processing',
          title: 'Scheda in preparazione',
          message: GigiGuidanceContent.homePlanProcessing(),
          emotion: GigiEmotion.expert,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GigiCoachMessage(
        messageId: 'home.plan_ready',
        title: 'Pannello rapido',
        message: GigiGuidanceContent.homePlanReady(),
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
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Errore: ${workoutProvider.error ?? "Riprova"}'),
            backgroundColor: const Color(0xFF3A3A3C),
          ),
        );
      }
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    await _refreshHealthConnectionState(updateUi: false);

    // Refresh User Data
    if (!mounted) return;
    await Provider.of<AuthProvider>(context, listen: false).fetchUser();

    // Refresh Workout Data
    if (!mounted) return;
    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );
    await workoutProvider.fetchCurrentPlan();

    if (!mounted) return;
    final workoutLogProvider = Provider.of<WorkoutLogProvider>(
      context,
      listen: false,
    );
    await workoutLogProvider.fetchWorkoutHistory();

    if (!mounted) return;
    await _loadCustomWorkouts();

    final overviewResponse = await ApiClient().dio.get('/stats/overview');
    if (!mounted) return;
    _overviewStats = overviewResponse.data['stats'] is Map<String, dynamic>
        ? overviewResponse.data['stats']
        : null;

    if (mounted) setState(() {});
  }

  Future<void> _refreshHealthConnectionState({bool updateUi = true}) async {
    await _healthService.initialize();
    if (!mounted) return;

    final isConnected = _healthService.isAuthorized;
    if (_isHealthConnected == isConnected) return;

    _isHealthConnected = isConnected;
    if (updateUi) {
      setState(() {});
    }
  }

  Future<void> _loadCustomWorkouts() async {
    final result = await _customWorkoutService.getCustomWorkouts();
    if (result['success'] != true) return;

    final fetchedPlans = result['plans'] as List<CustomWorkoutPlan>;
    final orderedPlans = await _applySavedCustomOrder(fetchedPlans);

    if (!mounted) return;
    setState(() {
      _customPlans = orderedPlans;
    });
  }

  Future<List<CustomWorkoutPlan>> _applySavedCustomOrder(
    List<CustomWorkoutPlan> fetchedPlans,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final savedOrder = prefs.getStringList(_customWorkoutOrderKey) ?? const [];

    if (savedOrder.isEmpty) {
      await prefs.setStringList(
        _customWorkoutOrderKey,
        fetchedPlans.map((plan) => plan.id).toList(),
      );
      return fetchedPlans;
    }

    final remaining = {for (final plan in fetchedPlans) plan.id: plan};
    final ordered = <CustomWorkoutPlan>[];
    for (final planId in savedOrder) {
      final plan = remaining.remove(planId);
      if (plan != null) {
        ordered.add(plan);
      }
    }
    ordered.addAll(remaining.values);

    final normalizedOrder = ordered.map((plan) => plan.id).toList();
    if (!_sameIdOrder(savedOrder, normalizedOrder)) {
      await prefs.setStringList(_customWorkoutOrderKey, normalizedOrder);
    }

    return ordered;
  }

  bool _sameIdOrder(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
