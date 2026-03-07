import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/models/workout_model.dart';
import '../../../data/models/custom_workout_model.dart';
import '../../../data/services/custom_workout_service.dart';
import '../../../data/services/api_client.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/workout_provider.dart';
import '../../../presentation/widgets/clean_widgets.dart';
import 'workout_session_screen.dart';
import '../custom_workout/create_custom_workout_screen.dart';
import '../questionnaire/unified_questionnaire_screen.dart';
import '../../../data/services/quota_service.dart';
import '../../../data/models/quota_status_model.dart';
import 'package:gigi/l10n/app_localizations.dart';
import '../paywall/paywall_screen.dart';
import 'ai_analysis_loading_screen.dart';
import '../../widgets/animations/liquid_steel_container.dart';
import '../../widgets/celebrations/celebration_overlay.dart';
import '../../../core/services/haptic_service.dart';

/// Unified screen showing both AI-generated and custom workouts
class UnifiedWorkoutListScreen extends StatefulWidget {
  const UnifiedWorkoutListScreen({super.key});

  @override
  State<UnifiedWorkoutListScreen> createState() =>
      _UnifiedWorkoutListScreenState();
}

class _UnifiedWorkoutListScreenState extends State<UnifiedWorkoutListScreen> {
  late CustomWorkoutService _customWorkoutService;
  late QuotaService _quotaService;
  List<CustomWorkoutPlan> _customPlans = [];
  bool _isLoadingCustom = true;
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _customWorkoutService = CustomWorkoutService(ApiClient());
    _quotaService = QuotaService(apiClient: ApiClient());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkoutProvider>(context, listen: false).fetchCurrentPlan();
      _loadCustomWorkouts();
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
        // Refresh data
        workoutProvider.fetchCurrentPlan();
        _loadCustomWorkouts();
        Provider.of<AuthProvider>(context, listen: false).fetchUser();
      }
    };
  }

  @override
  void dispose() {
    try {
      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );
      workoutProvider.onGenerationComplete = null;
    } catch (_) {}
    super.dispose();
  }

  Future<void> _loadCustomWorkouts() async {
    setState(() => _isLoadingCustom = true);
    final result = await _customWorkoutService.getCustomWorkouts();
    if (mounted) {
      setState(() {
        _isLoadingCustom = false;
        if (result['success'] == true) {
          _customPlans = result['plans'] as List<CustomWorkoutPlan>;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: CleanTheme.backgroundColor,
          body: SafeArea(
            child: Consumer<WorkoutProvider>(
              builder: (context, workoutProvider, _) {
                final plan = workoutProvider.currentPlan;
                final bool hasCompletedPlan =
                    plan != null &&
                    plan.status == 'completed' &&
                    plan.workouts.isNotEmpty &&
                    plan.workouts.any((w) => w.exercises.isNotEmpty);

                return RefreshIndicator(
                  onRefresh: () async {
                    await workoutProvider.fetchCurrentPlan();
                    await _loadCustomWorkouts();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.myWorkoutsTitle,
                                  style: GoogleFonts.outfit(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: CleanTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Hero Card - Next AI Workout
                        _buildHeroNextWorkout(workoutProvider),

                        const SizedBox(height: 32),

                        // AI Workouts Section (only show when plans exist and are completed)
                        if (hasCompletedPlan) ...[
                          _buildSectionTitle(
                            AppLocalizations.of(
                              context,
                            )!.aiWorkoutsSectionTitle,
                            AppLocalizations.of(
                              context,
                            )!.aiWorkoutsSectionSubtitle,
                            action: GestureDetector(
                              onTap:
                                  workoutProvider.isGenerating ||
                                      plan.status == 'processing'
                                  ? null
                                  : () {
                                      HapticService.lightTap();
                                      _handleCreateNewPlan();
                                    },
                              child: Opacity(
                                opacity:
                                    workoutProvider.isGenerating ||
                                        plan.status == 'processing'
                                    ? 0.5
                                    : 1.0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        CleanTheme.primaryColor,
                                        CleanTheme.primaryColor.withValues(
                                          alpha: 0.8,
                                        ),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: CleanTheme.primaryColor
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Nuova",
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildAIWorkoutsList(workoutProvider),
                          const SizedBox(height: 32),
                        ],

                        // Custom Workouts Section
                        _buildSectionTitle(
                          AppLocalizations.of(
                            context,
                          )!.customWorkoutsSectionTitle,
                          AppLocalizations.of(
                            context,
                          )!.customWorkoutsSectionSubtitle,
                        ),

                        const SizedBox(height: 12),
                        _buildCustomWorkoutsList(),

                        const SizedBox(height: 100), // Bottom padding for nav
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (_showCelebration)
          CelebrationOverlay(
            style: CelebrationStyle.confetti,
            onComplete: () => setState(() => _showCelebration = false),
          ),
      ],
    );
  }

  Widget _buildCreateCustomCard() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateCustomWorkoutScreen(),
          ),
        );
        if (result == true) {
          _loadCustomWorkouts();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CleanTheme.primaryColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: CleanTheme.primaryColor.withValues(alpha: 0.3),
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
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crea Nuova Scheda',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Costruisci il tuo allenamento personalizzato',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCreateNewPlan() async {
    HapticService.lightTap();
    try {
      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentPlan = workoutProvider.currentPlan;
      final isComplete = authProvider.user?.isQuestionnaireComplete ?? false;

      // Se il questionario non è completo, mandalo lì
      if (!isComplete) {
        final questionnaireResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const UnifiedQuestionnaireScreen(isOnboarding: false),
          ),
        );
        if (questionnaireResult == true && mounted) {
          _generatePlan(includeHistory: false);
        }
        return;
      }

      // Se NON c'è una scheda attiva, vai diretto alla generazione
      if (currentPlan == null ||
          currentPlan.workouts.isEmpty ||
          currentPlan.status == 'failed') {
        _generatePlan(includeHistory: false);
        return;
      }

      // SE C'È GIÀ UNA SCHEDA: Mostra il dialogo di scelta
      final result = await _quotaService.canPerformAction(
        QuotaAction.workoutPlan,
      );

      QuotaStatus? quotaStatus;
      try {
        quotaStatus = await _quotaService.getQuotaStatus();
      } catch (e) {
        debugPrint('Failed to get quota status for dialog: $e');
      }

      if (!mounted) return;

      final Map<String, dynamic>?
      choice = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) {
          final bool isPremium = [
            'premium',
            'pro',
            'elite',
          ].contains(result.subscriptionTier.toLowerCase());
          bool includeHistory =
              isPremium; // Memoria Storica AI attiva di default per i Premium

          final workoutProvider = Provider.of<WorkoutProvider>(
            context,
            listen: false,
          );
          final lastPlanDate = workoutProvider.currentPlan?.generatedAt;
          int intervalWeeks = quotaStatus?.usage.workoutPlan.intervalWeeks ?? 8;

          // Fallback protection in case backend UserSubscriptionData is stale
          bool isBlockedLocally = false;
          if (!isPremium && lastPlanDate != null) {
            final daysSince = DateTime.now().difference(lastPlanDate).inDays;
            if (daysSince < (intervalWeeks * 7)) {
              isBlockedLocally = true;
            }
          }

          final bool actuallyCanPerform =
              isPremium || (result.canPerform && !isBlockedLocally);

          String timeAgoText = '';
          if (lastPlanDate != null) {
            final difference = DateTime.now().difference(lastPlanDate);
            if (difference.inDays == 0) {
              timeAgoText = 'Hai generato la tua ultima scheda oggi.';
            } else if (difference.inDays == 1) {
              timeAgoText = 'Hai generato la tua ultima scheda ieri.';
            } else {
              timeAgoText =
                  'Hai generato la tua ultima scheda ${difference.inDays} giorni fa.';
            }
          }

          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: CleanTheme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text(
                  'Genera Nuova Scheda',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (timeAgoText.isNotEmpty ||
                        (!isPremium && quotaStatus != null))
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (timeAgoText.isNotEmpty)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.history,
                                    size: 18,
                                    color: CleanTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      timeAgoText,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: CleanTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            if (timeAgoText.isNotEmpty && !isPremium)
                              const SizedBox(height: 8),
                            if (!isPremium && quotaStatus != null)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.timer_outlined,
                                    size: 18,
                                    color: CleanTheme.accentOrange,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Limite Free: 1 scheda ogni $intervalWeeks settimane',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: CleanTheme.accentOrange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),

                    Text(
                      'Vuoi aggiornare le tue preferenze (peso, obiettivi, disponibilità) prima di generare la scheda, o usare quelle attuali?',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CleanTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: LiquidSteelContainer(
                        borderRadius: 16,
                        enableShine: true,
                        border: Border.all(
                          color: isPremium
                              ? CleanTheme.primaryColor.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.1),
                          width: isPremium ? 1.5 : 1,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () {
                              if (isPremium) {
                                setState(
                                  () => includeHistory = !includeHistory,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Sblocca Premium per attivare la memoria storica!',
                                    ),
                                    backgroundColor: Colors.redAccent,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              isPremium
                                                  ? Icons.auto_graph
                                                  : Icons.lock_outline,
                                              size: 18,
                                              color: isPremium
                                                  ? CleanTheme.primaryColor
                                                  : Colors.white54,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              isPremium
                                                  ? "Progressive Overload AI"
                                                  : "Memoria Storica AI",
                                              style: GoogleFonts.outfit(
                                                fontWeight: FontWeight.w700,
                                                color: isPremium
                                                    ? Colors.white
                                                    : Colors.white70,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          isPremium
                                              ? "L'AI analizzerà ogni serie del tuo storico per calcolare l'incremento di carico scientificamente perfetto."
                                              : "Senza memoria storica l'AI creerà un set generico. Sbloccala per una progressione infallibile guidata dallo storico.",
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.white.withValues(
                                              alpha: isPremium ? 0.9 : 0.6,
                                            ),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () {
                                      if (!isPremium) {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const PaywallScreen(),
                                          ),
                                        );
                                      }
                                    },
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Switch(
                                          value: isPremium
                                              ? includeHistory
                                              : false,
                                          onChanged: isPremium
                                              ? (val) => setState(
                                                  () => includeHistory = val,
                                                )
                                              : null,
                                          activeThumbColor: Colors.white,
                                          activeTrackColor:
                                              CleanTheme.accentOrange,
                                          inactiveThumbColor: isPremium
                                              ? Colors.white54
                                              : Colors.white24,
                                          inactiveTrackColor: Colors.white10,
                                        ),
                                        if (!isPremium)
                                          const Icon(
                                            Icons.lock,
                                            size: 14,
                                            color: Colors.white70,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      if (!actuallyCanPerform) {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaywallScreen(),
                          ),
                        );
                      } else {
                        Navigator.pop(ctx, {
                          'action': 'current',
                          'includeHistory': includeHistory,
                        });
                      }
                    },
                    child: Text(
                      'Usa Attuali',
                      style: GoogleFonts.inter(
                        color: CleanTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (!actuallyCanPerform) {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaywallScreen(),
                          ),
                        );
                      } else {
                        Navigator.pop(ctx, {
                          'action': 'update',
                          'includeHistory': includeHistory,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CleanTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Aggiorna',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      if (choice == null || !mounted) return;

      final String action = choice['action'];
      final bool includeHistory = choice['includeHistory'] ?? false;
      bool shouldGenerate = false;

      if (action == 'update') {
        final questionnaireResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const UnifiedQuestionnaireScreen(isOnboarding: false),
          ),
        );
        if (questionnaireResult == true) shouldGenerate = true;
      } else {
        shouldGenerate = true;
      }

      if (shouldGenerate && mounted) {
        _generatePlan(includeHistory: includeHistory);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: CleanTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _generatePlan({bool includeHistory = false}) async {
    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AiAnalysisLoadingScreen(
          onGenerate: () async => await workoutProvider.generatePlan(
            includeHistory: includeHistory,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle, {Widget? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CleanTheme.textSecondary,
              ),
            ),
          ],
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _buildHeroNextWorkout(WorkoutProvider workoutProvider) {
    final plan = workoutProvider.currentPlan;

    // Show generating state only if plan is processing AND has no data yet
    final bool isStillGenerating =
        plan != null &&
        plan.status == 'processing' &&
        (plan.workouts.isEmpty ||
            plan.workouts.every((w) => w.exercises.isEmpty));
    if (isStillGenerating) {
      return _buildGeneratingHeroCard();
    }

    final nextWorkout = plan?.workouts.isNotEmpty == true
        ? plan!.workouts.first
        : null;

    if (plan == null || nextWorkout == null) {
      return _buildActionableEmptyState(
        icon: Icons.auto_awesome,
        title: "Inizia la tua Trasformazione",
        subtitle:
            "L'AI creerà un piano scientifico su misura per i tuoi obiettivi",
        buttonText: "Genera la mia Scheda AI",
        onTap: () => _handleCreateNewPlan(),
      );
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutSessionScreen(workoutDay: nextWorkout),
        ),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [CleanTheme.primaryColor, CleanTheme.steelDark],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: CleanTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -30,
              bottom: -30,
              child: Icon(
                Icons.fitness_center,
                size: 150,
                color: CleanTheme.textOnDark.withValues(alpha: 0.1),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: CleanTheme.textOnDark.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '🔥 ${AppLocalizations.of(context)!.nextWorkoutTitle.replaceAll('🔥 ', '')}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CleanTheme.textOnDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        nextWorkout.name,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: CleanTheme.textOnDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppLocalizations.of(context)!.exercisesCount(nextWorkout.exercises.length)} • ${AppLocalizations.of(context)!.durationMinutes(nextWorkout.estimatedDuration)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: CleanTheme.textOnDark.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: CleanTheme.textOnDark,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.play_arrow,
                              color: CleanTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.startNow,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: CleanTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratingHeroCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CleanTheme.primaryColor.withValues(alpha: 0.8),
            CleanTheme.primaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: CleanTheme.textOnDark,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.generatingInProgress,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textOnDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.completingCardioMobility,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CleanTheme.textOnDark.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratingSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: CleanTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            'AI sta completando la scheda...',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CleanTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIWorkoutsList(WorkoutProvider workoutProvider) {
    final plan = workoutProvider.currentPlan;

    // Show generating state only if plan is processing AND has no data yet
    final bool isStillGenerating =
        plan != null &&
        plan.status == 'processing' &&
        (plan.workouts.isEmpty ||
            plan.workouts.every((w) => w.exercises.isEmpty));
    if (isStillGenerating) {
      return _buildGeneratingSection();
    }

    if (plan == null || plan.workoutDays.isEmpty) {
      return _buildActionableEmptyState(
        icon: Icons.auto_awesome,
        title: AppLocalizations.of(context)!.noAiGeneratedPlan,
        subtitle: 'L\'AI creerà un piano su misura per te',
        buttonText: 'Genera Scheda AI',
        onTap: () => _handleCreateNewPlan(),
      );
    }

    return Column(
      children: plan.workoutDays.asMap().entries.map((entry) {
        final workout = entry.value;
        return _buildWorkoutCard(
          title: workout.name,
          subtitle: '${workout.exercises.length} esercizi',
          duration: '${workout.estimatedDuration} min',
          isAI: true,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkoutSessionScreen(workoutDay: workout),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomWorkoutsList() {
    if (_isLoadingCustom) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: CleanTheme.primaryColor),
        ),
      );
    }

    if (_customPlans.isEmpty) {
      return _buildCreateCustomCard();
    }

    return Column(
      children: [
        Column(
          children: _customPlans.map((plan) {
            return _buildCustomWorkoutCard(plan);
          }).toList(),
        ),
        const SizedBox(height: 12),
        _buildCreateCustomCard(),
      ],
    );
  }

  Widget _buildActionableEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CleanTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: CleanTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CleanTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CleanButton(
              text: buttonText,
              onPressed: onTap,
              isPrimary: true,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutCard({
    required String title,
    required String subtitle,
    required String duration,
    required bool isAI,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CleanTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CleanTheme.borderPrimary),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isAI
                    ? CleanTheme.primaryColor.withValues(alpha: 0.1)
                    : CleanTheme.accentOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isAI ? Icons.auto_awesome : Icons.edit_note,
                color: isAI ? CleanTheme.primaryColor : CleanTheme.accentOrange,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: CleanTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(color: CleanTheme.textTertiary),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: CleanTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.durationMinutes(
                          int.tryParse(duration.replaceAll(' min', '')) ?? 0,
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: CleanTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: CleanTheme.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomWorkoutCard(CustomWorkoutPlan plan) {
    final workoutDay = WorkoutDay(
      id: 'custom_${plan.id}',
      name: plan.name,
      focus: plan.description ?? 'Personalizzata',
      estimatedDuration: plan.estimatedDuration,
      exercises: plan.exercises.map((e) {
        return WorkoutExercise(
          exercise: e.exercise,
          sets: e.sets,
          reps: e.reps,
          restSeconds: e.restSeconds,
          notes: e.notes,
          position: 'main',
          exerciseType: e.exerciseType ?? 'strength',
        );
      }).toList(),
    );

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutSessionScreen(workoutDay: workoutDay),
        ),
      ),
      onLongPress: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateCustomWorkoutScreen(existingPlan: plan),
          ),
        );
        if (result == true) {
          _loadCustomWorkouts();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                color: CleanTheme.accentPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.fitness_center,
                color: CleanTheme.accentPurple,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${plan.exerciseCount} esercizi • ~${plan.estimatedDuration} min',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateCustomWorkoutScreen(existingPlan: plan),
                  ),
                );
                if (result == true) {
                  _loadCustomWorkouts();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.settings,
                  color: CleanTheme.textSecondary,
                  size: 20,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: CleanTheme.textTertiary),
          ],
        ),
      ),
    );
  }
}
