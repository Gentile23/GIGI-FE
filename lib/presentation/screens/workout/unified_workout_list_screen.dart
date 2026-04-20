import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/utils/next_workout_selector.dart';
import '../../../data/models/custom_workout_model.dart';
import '../../../data/services/custom_workout_service.dart';
import '../../../data/services/api_client.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/workout_log_provider.dart';
import '../../../presentation/widgets/clean_widgets.dart';
import 'workout_session_screen.dart';
import '../custom_workout/create_custom_workout_screen.dart';
import '../questionnaire/unified_questionnaire_screen.dart';
import '../../../data/services/quota_service.dart';
import '../../../data/models/quota_status_model.dart';
import 'package:gigi/l10n/app_localizations.dart';
import '../paywall/paywall_screen.dart';
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
  static const String _customWorkoutOrderKey = 'custom_workout_order_v1';
  late CustomWorkoutService _customWorkoutService;
  late QuotaService _quotaService;
  List<CustomWorkoutPlan> _customPlans = [];
  bool _isLoadingCustom = true;
  bool _showCelebration = false;
  VoidCallback? _onGenerationComplete;

  @override
  void initState() {
    super.initState();
    _customWorkoutService = CustomWorkoutService(ApiClient());
    _quotaService = QuotaService(apiClient: ApiClient());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkoutProvider>(context, listen: false).fetchCurrentPlan();
      Provider.of<WorkoutLogProvider>(
        context,
        listen: false,
      ).fetchWorkoutHistory();
      _loadCustomWorkouts();
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

        final plan = workoutProvider.currentPlan;
        if (plan != null &&
            plan.aiGenerationNotes != null &&
            plan.aiGenerationNotes!.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              _showAIGenerationNotesBottomSheet(plan.aiGenerationNotes!);
            }
          });
        }

        // Refresh other data but not the current plan which is already updated
        _loadCustomWorkouts();
        Provider.of<AuthProvider>(context, listen: false).fetchUser();
      }
    };
    workoutProvider.addGenerationCompleteListener(_onGenerationComplete!);
  }

  /// Map icon string from backend to Flutter IconData
  IconData _mapAnalysisIcon(String iconKey) {
    switch (iconKey) {
      case 'target':
        return Icons.gps_fixed_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  void _showAIGenerationNotesBottomSheet(String notes) {
    // Try to parse structured JSON
    Map<String, dynamic>? structured;
    try {
      structured = jsonDecode(notes) as Map<String, dynamic>;
    } catch (_) {
      structured = null;
    }

    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );
    final workoutLogProvider = Provider.of<WorkoutLogProvider>(
      context,
      listen: false,
    );
    final nextSuggestion = NextWorkoutSelector.resolve(
      aiPlan: workoutProvider.currentPlan,
      customPlans: _customPlans,
      workoutHistory: workoutLogProvider.workoutHistory,
    );
    final nextWorkout = nextSuggestion?.workoutDay;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _GiGiAnalysisSheet(
          structured: structured,
          rawNotes: notes,
          mapIcon: _mapAnalysisIcon,
          onStartTraining: nextWorkout == null
              ? null
              : () {
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          WorkoutSessionScreen(workoutDay: nextWorkout),
                    ),
                  ).then((_) {
                    if (!mounted) return;
                    Provider.of<WorkoutLogProvider>(
                      context,
                      listen: false,
                    ).fetchWorkoutHistory();
                    _loadCustomWorkouts();
                  });
                },
        );
      },
    );
  }

  @override
  void dispose() {
    try {
      if (_onGenerationComplete != null) {
        final workoutProvider = Provider.of<WorkoutProvider>(
          context,
          listen: false,
        );
        workoutProvider.removeGenerationCompleteListener(
          _onGenerationComplete!,
        );
      }
    } catch (_) {}
    super.dispose();
  }

  Future<void> _loadCustomWorkouts() async {
    setState(() => _isLoadingCustom = true);
    final result = await _customWorkoutService.getCustomWorkouts();
    List<CustomWorkoutPlan> nextPlans = _customPlans;
    if (result['success'] == true) {
      final fetchedPlans = (result['plans'] as List<CustomWorkoutPlan>);
      nextPlans = await _applySavedCustomOrder(fetchedPlans);
    }
    if (mounted) {
      setState(() {
        _isLoadingCustom = false;
        _customPlans = nextPlans;
      });
    }
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

  Future<void> _persistCustomWorkoutOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _customWorkoutOrderKey,
      _customPlans.map((plan) => plan.id).toList(),
    );
  }

  Future<void> _onCustomReorder(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final movedPlan = _customPlans.removeAt(oldIndex);
      _customPlans.insert(newIndex, movedPlan);
    });
    await _persistCustomWorkoutOrder();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: CleanTheme.backgroundColor,
          body: SafeArea(
            child: Consumer2<WorkoutProvider, WorkoutLogProvider>(
              builder: (context, workoutProvider, workoutLogProvider, _) {
                final plan = workoutProvider.currentPlan;

                return RefreshIndicator(
                  onRefresh: () async {
                    await workoutProvider.fetchCurrentPlan();
                    await workoutLogProvider.fetchWorkoutHistory(refresh: true);
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
                        _buildHeroNextWorkout(
                          workoutProvider,
                          workoutLogProvider,
                        ),

                        const SizedBox(height: 32),

                        // AI Workouts Section
                        if (plan != null && plan.status != 'failed') ...[
                          _buildSectionTitle(
                            AppLocalizations.of(
                              context,
                            )!.aiWorkoutsSectionTitle,
                            AppLocalizations.of(
                              context,
                            )!.aiWorkoutsSectionSubtitle,
                            action: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (plan.aiGenerationNotes != null &&
                                    plan.aiGenerationNotes!.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      HapticService.lightTap();
                                      _showAIGenerationNotesBottomSheet(
                                        plan.aiGenerationNotes!,
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: CleanTheme.primaryColor
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: CleanTheme.primaryColor
                                              .withValues(alpha: 0.22),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.psychology_outlined,
                                            size: 16,
                                            color: CleanTheme.primaryColor,
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            'AI Insights',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: CleanTheme.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                GestureDetector(
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildAIWorkoutsList(workoutProvider),
                          const SizedBox(height: 32),
                        ],

                        // Custom Workouts Section
                        _buildSectionTitle(
                          _customPlans.isEmpty
                              ? AppLocalizations.of(
                                  context,
                                )!.customWorkoutsSectionTitle
                              : 'Schede personalizzate create da te',
                          AppLocalizations.of(
                            context,
                          )!.customWorkoutsSectionSubtitle,
                          action: _customPlans.isEmpty || _isLoadingCustom
                              ? null
                              : _buildAddCustomWorkoutButton(),
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
      onTap: _openCreateCustomWorkout,
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

  Future<void> _openCreateCustomWorkout() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCustomWorkoutScreen(),
      ),
    );
    if (result == true) {
      _loadCustomWorkouts();
    }
  }

  Widget _buildAddCustomWorkoutButton() {
    return GestureDetector(
      onTap: _openCreateCustomWorkout,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: CleanTheme.primaryColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: CleanTheme.primaryColor.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_rounded,
              size: 16,
              color: CleanTheme.primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              'Aggiungi',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CleanTheme.primaryColor,
              ),
            ),
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
        // debugPrint('Failed to get quota status for dialog: $e');
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
                                      'Il limite del tuo piano è 1 scheda ogni $intervalWeeks settimane.',
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
                  OutlinedButton(
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
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Usa Attuali',
                      style: GoogleFonts.inter(
                        color: CleanTheme.textPrimary,
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
            content: const Text('Si è verificato un errore.'),
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
    final success = await workoutProvider.generatePlan(
      includeHistory: includeHistory,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            workoutProvider.error ??
                'Errore durante la generazione della scheda',
          ),
          backgroundColor: CleanTheme.accentRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildSectionTitle(String title, String subtitle, {Widget? action}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
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
        ),
        if (action != null) ...[
          const SizedBox(width: 12),
          IntrinsicWidth(child: action),
        ],
      ],
    );
  }

  Widget _buildHeroNextWorkout(
    WorkoutProvider workoutProvider,
    WorkoutLogProvider workoutLogProvider,
  ) {
    final plan = workoutProvider.currentPlan;

    // Show generating state only if plan is processing or provider is generating
    final bool isStillGenerating =
        workoutProvider.isGenerating ||
        (plan != null && plan.status == 'processing');

    if (isStillGenerating) {
      return _buildGeneratingHeroCard();
    }

    final nextSuggestion = NextWorkoutSelector.resolve(
      aiPlan: plan,
      customPlans: _customPlans,
      workoutHistory: workoutLogProvider.workoutHistory,
    );
    final nextWorkout = nextSuggestion?.workoutDay;
    final isCustomSuggestion = nextSuggestion?.isCustom ?? false;

    if (nextWorkout == null) {
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
            colors: isCustomSuggestion
                ? [CleanTheme.accentPurple, CleanTheme.primaryColor]
                : [CleanTheme.primaryColor, CleanTheme.steelDark],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color:
                  (isCustomSuggestion
                          ? CleanTheme.accentPurple
                          : CleanTheme.primaryColor)
                      .withValues(alpha: 0.3),
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
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCustomSuggestion
                            ? 'SCHEDA PERSONALIZZATA'
                            : 'PIANO AI',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: CleanTheme.textOnDark.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: CleanTheme.textOnDark.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          AppLocalizations.of(
                            context,
                          )!.nextWorkoutTitle.replaceAll('🔥 ', ''),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CleanTheme.textOnDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                  const SizedBox(height: 18),
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
                            Icon(
                              Icons.play_arrow,
                              color: isCustomSuggestion
                                  ? CleanTheme.accentPurple
                                  : CleanTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.startNow,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isCustomSuggestion
                                    ? CleanTheme.accentPurple
                                    : CleanTheme.primaryColor,
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
        workoutProvider.isGenerating ||
        (plan != null && plan.status == 'processing');
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
      children: [
        ...plan.workoutDays.asMap().entries.map((entry) {
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
        }),
      ],
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

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: _customPlans.length,
      onReorder: (oldIndex, newIndex) {
        unawaited(_onCustomReorder(oldIndex, newIndex));
      },
      itemBuilder: (context, index) {
        final plan = _customPlans[index];
        return KeyedSubtree(
          key: ValueKey('custom_plan_${plan.id}'),
          child: _buildCustomWorkoutCard(
            plan,
            showDragHandle: true,
            dragIndex: index,
          ),
        );
      },
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

  Widget _buildCustomWorkoutCard(
    CustomWorkoutPlan plan, {
    bool showDragHandle = false,
    int? dragIndex,
  }) {
    final workoutDay = NextWorkoutSelector.mapCustomPlanToWorkoutDay(plan);

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
            if (showDragHandle && dragIndex != null)
              ReorderableDragStartListener(
                index: dragIndex,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    color: CleanTheme.textTertiary,
                    size: 20,
                  ),
                ),
              )
            else
              Icon(Icons.chevron_right, color: CleanTheme.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// Premium animated bottom sheet for GiGi's AI Analysis
class _GiGiAnalysisSheet extends StatefulWidget {
  final Map<String, dynamic>? structured;
  final String rawNotes;
  final IconData Function(String) mapIcon;
  final VoidCallback? onStartTraining;

  const _GiGiAnalysisSheet({
    required this.structured,
    required this.rawNotes,
    required this.mapIcon,
    required this.onStartTraining,
  });

  @override
  State<_GiGiAnalysisSheet> createState() => _GiGiAnalysisSheetState();
}

class _GiGiAnalysisSheetState extends State<_GiGiAnalysisSheet>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _fadeAnimations;
  late Animation<double> _ctaScale;

  String _cleanText(Object? value) {
    if (value == null) return '';
    final normalized = value.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return '';

    const placeholders = {
      'null',
      'none',
      'n/a',
      'na',
      '-',
      '--',
      'non disponibile',
      'non disponibile.',
      'not available',
      'not generated',
    };

    if (placeholders.contains(normalized.toLowerCase())) {
      return '';
    }

    return normalized;
  }

  List<Map<String, dynamic>> _validAnalysisPoints(Map<String, dynamic> data) {
    final rawPoints = data['analysis_points'];
    if (rawPoints is! List) return const [];

    final valid = <Map<String, dynamic>>[];
    for (final point in rawPoints) {
      if (point is! Map) continue;
      final map = Map<String, dynamic>.from(point);
      final title = _cleanText(map['title']);
      final detail = _cleanText(map['detail']);
      if (title.isEmpty && detail.isEmpty) continue;

      valid.add({
        'icon': _cleanText(map['icon']),
        'title': title,
        'detail': detail,
      });
    }
    return valid;
  }

  // Total sections: header + greeting + N analysis cards + promise + closing + optional CTA
  int get _totalSections {
    final ctaCount = widget.onStartTraining == null ? 0 : 1;
    if (widget.structured == null) {
      final rawNotes = _cleanText(widget.rawNotes);
      return 1 + (rawNotes.isEmpty ? 0 : 1) + ctaCount;
    }

    final data = widget.structured!;
    final greeting = _cleanText(data['greeting']);
    final points = _validAnalysisPoints(data);
    final rehabNote = _cleanText(data['rehab_note']);
    final promise = _cleanText(data['promise']);
    final closing = _cleanText(data['closing']);

    var total = 1 + ctaCount; // header + optional CTA
    if (greeting.isNotEmpty) total++;
    total += points.length;
    if (rehabNote.isNotEmpty) total++;
    if (promise.isNotEmpty) total++;
    if (closing.isNotEmpty) total++;
    return total;
  }

  @override
  void initState() {
    super.initState();
    final totalMs = _totalSections * 150 + 400;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );

    _fadeAnimations = List.generate(_totalSections, (i) {
      final start = (i * 150) / totalMs;
      final end = ((i * 150) + 400) / totalMs;
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(
          start.clamp(0.0, 1.0),
          end.clamp(0.0, 1.0),
          curve: Curves.easeOut,
        ),
      );
    });

    _ctaScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.8, 1.0, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1C1C1E), Color(0xFF111113)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: bottomPadding + 24,
              ),
              child: widget.structured != null
                  ? _buildStructuredContent()
                  : _buildFallbackContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSection(int index, Widget child) {
    if (index >= _fadeAnimations.length) return child;
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(_fadeAnimations[index]),
        child: child,
      ),
    );
  }

  Widget _buildStructuredContent() {
    final data = widget.structured!;
    final greeting = _cleanText(data['greeting']);
    final points = _validAnalysisPoints(data);
    final promise = _cleanText(data['promise']);
    final closing = _cleanText(data['closing']);
    final rehabNote = _cleanText(data['rehab_note']);

    int sectionIndex = 0;
    final children = <Widget>[
      const SizedBox(height: 16),
      _buildAnimatedSection(sectionIndex++, _buildHeader()),
    ];

    if (greeting.isNotEmpty) {
      children.add(const SizedBox(height: 24));
      children.add(
        _buildAnimatedSection(sectionIndex++, _buildGreeting(greeting)),
      );
    }

    if (points.isNotEmpty) {
      children.add(const SizedBox(height: 20));
      for (final point in points) {
        children.add(
          _buildAnimatedSection(
            sectionIndex++,
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAnalysisCard(
                icon: widget.mapIcon(point['icon'] as String? ?? ''),
                title: point['title'] as String? ?? '',
                detail: point['detail'] as String? ?? '',
              ),
            ),
          ),
        );
      }
    }

    if (rehabNote.isNotEmpty) {
      children.add(const SizedBox(height: 12));
      children.add(
        _buildAnimatedSection(
          sectionIndex++,
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildAnalysisCard(
              icon: Icons.healing_rounded,
              title: 'Protezione Infortuni',
              detail: rehabNote,
              accentColor: const Color(0xFFFF6B6B),
            ),
          ),
        ),
      );
    }

    if (promise.isNotEmpty) {
      children.add(const SizedBox(height: 8));
      children.add(
        _buildAnimatedSection(sectionIndex++, _buildPromise(promise)),
      );
    }

    if (closing.isNotEmpty) {
      children.add(const SizedBox(height: 16));
      children.add(
        _buildAnimatedSection(sectionIndex++, _buildClosing(closing)),
      );
    }

    if (widget.onStartTraining != null) {
      children.add(const SizedBox(height: 28));
      children.add(_buildAnimatedSection(sectionIndex++, _buildCTA()));
      children.add(const SizedBox(height: 12));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFDB515), Color(0xFFFF9500)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFDB515).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "L'Analisi di GiGi",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "La scienza dietro la tua scheda",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFFFDB515),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting(String greeting) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("👋", style: GoogleFonts.inter(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              greeting,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard({
    required IconData icon,
    required String title,
    required String detail,
    Color? accentColor,
  }) {
    final safeTitle = _cleanText(title);
    final safeDetail = _cleanText(detail);
    if (safeTitle.isEmpty && safeDetail.isEmpty) {
      return const SizedBox.shrink();
    }

    final color = accentColor ?? Colors.white;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color.withValues(alpha: 0.8), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (safeTitle.isNotEmpty)
                  Text(
                    safeTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.95),
                      letterSpacing: -0.2,
                    ),
                  ),
                if (safeTitle.isNotEmpty && safeDetail.isNotEmpty)
                  const SizedBox(height: 4),
                if (safeDetail.isNotEmpty)
                  Text(
                    safeDetail,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.65),
                      height: 1.5,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromise(String promise) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFDB515).withValues(alpha: 0.12),
            const Color(0xFFFF9500).withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFDB515).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("🎯", style: GoogleFonts.inter(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              promise,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFFFDB515),
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosing(String closing) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        closing,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.5),
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCTA() {
    final onStartTraining = widget.onStartTraining;
    if (onStartTraining == null) return const SizedBox.shrink();

    return ScaleTransition(
      scale: _ctaScale,
      child: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFDB515), Color(0xFFFF9500)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFDB515).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticService.mediumTap();
                Navigator.pop(context);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  onStartTraining();
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Inizia ad Allenarti",
                      style: GoogleFonts.outfit(
                        fontSize: 17,
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
      ),
    );
  }

  Widget _buildFallbackContent() {
    final safeRawNotes = _cleanText(widget.rawNotes);
    int sectionIndex = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildAnimatedSection(sectionIndex++, _buildHeader()),
        if (safeRawNotes.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildAnimatedSection(
            sectionIndex++,
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Text(
                safeRawNotes,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
        if (widget.onStartTraining != null) ...[
          const SizedBox(height: 28),
          _buildAnimatedSection(sectionIndex++, _buildCTA()),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
