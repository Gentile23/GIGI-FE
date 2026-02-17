import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../data/models/workout_model.dart';
import '../../../data/models/custom_workout_model.dart';
import '../../../data/services/custom_workout_service.dart';
import '../../../data/services/api_client.dart';
import '../../../providers/workout_provider.dart';
import '../../../presentation/widgets/clean_widgets.dart';
import 'workout_session_screen.dart';
import '../custom_workout/create_custom_workout_screen.dart';
import '../questionnaire/unified_questionnaire_screen.dart';
import 'package:gigi/l10n/app_localizations.dart';

/// Unified screen showing both AI-generated and custom workouts
class UnifiedWorkoutListScreen extends StatefulWidget {
  const UnifiedWorkoutListScreen({super.key});

  @override
  State<UnifiedWorkoutListScreen> createState() =>
      _UnifiedWorkoutListScreenState();
}

class _UnifiedWorkoutListScreenState extends State<UnifiedWorkoutListScreen> {
  late CustomWorkoutService _customWorkoutService;
  List<CustomWorkoutPlan> _customPlans = [];
  bool _isLoadingCustom = true;

  @override
  void initState() {
    super.initState();
    _customWorkoutService = CustomWorkoutService(ApiClient());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkoutProvider>(context, listen: false).fetchCurrentPlan();
      _loadCustomWorkouts();
    });
  }

  @override
  void dispose() {
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
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: SafeArea(
        child: Consumer<WorkoutProvider>(
          builder: (context, workoutProvider, _) {
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
                    const SizedBox(height: 24),

                    // Hero Card - Next AI Workout
                    _buildHeroNextWorkout(workoutProvider),

                    const SizedBox(height: 32),

                    // AI Workouts Section
                    _buildSectionTitle(
                      AppLocalizations.of(context)!.aiWorkoutsSectionTitle,
                      AppLocalizations.of(context)!.aiWorkoutsSectionSubtitle,
                    ),
                    const SizedBox(height: 12),
                    _buildAIWorkoutsList(workoutProvider),

                    const SizedBox(height: 32),

                    // Custom Workouts Section
                    _buildSectionTitle(
                      AppLocalizations.of(context)!.customWorkoutsSectionTitle,
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
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutSessionScreen(workoutDay: nextWorkout),
        ),
      ),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              CleanTheme.primaryColor,
              CleanTheme.primaryColor.withValues(alpha: 0.7),
            ],
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
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '🔥 ${AppLocalizations.of(context)!.nextWorkoutTitle.replaceAll('🔥 ', '')}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        nextWorkout.name,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${AppLocalizations.of(context)!.exercisesCount(nextWorkout.exercises.length)} • ${AppLocalizations.of(context)!.durationMinutes(nextWorkout.estimatedDuration)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
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
              color: Colors.white,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.generatingInProgress,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.completingCardioMobility,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UnifiedQuestionnaireScreen(),
            ),
          );
        },
      );
    }

    return Column(
      children: plan.workoutDays.asMap().entries.map((entry) {
        final _ = entry.key;
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

    // If empty, show only the create card (or a more prominent empty state if desired)
    if (_customPlans.isEmpty) {
      return _buildCreateCustomCard();
    }

    return Column(
      children: [
        Column(
          children: _customPlans.map((plan) {
            return _buildWorkoutCard(
              title: plan.name,
              subtitle: '${plan.exercises.length} esercizi',
              duration: '${plan.exercises.length * 5} min',
              isAI: false,
              onTap: () {
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
                      exerciseType: 'strength',
                    );
                  }).toList(),
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        WorkoutSessionScreen(workoutDay: workoutDay),
                  ),
                );
              },
            );
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

  // ignore: unused_element
  Widget _buildEmptyAIState() {
    final currentPlan = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    ).currentPlan;

    if (currentPlan != null && currentPlan.status == 'processing') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: CleanTheme.primaryColor),
            const SizedBox(height: 24),
            Text(
              '🤖 AI sta creando il tuo piano',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ci vorranno pochi minuti...',
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 64, color: CleanTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            'Nessun Piano AI Generato',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CleanTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Genera il tuo primo piano dalla Home',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: CleanTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildEmptyCustomState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: CleanTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_note,
                size: 48,
                color: CleanTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nessuna Scheda Custom',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Crea la tua scheda personalizzata\nselezionando gli esercizi che preferisci',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CleanTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildAIWorkoutCard(
    BuildContext context,
    WorkoutDay workout,
    int index,
  ) {
    return CleanCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutSessionScreen(workoutDay: workout),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: CleanTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: CleanTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workout.focus,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: CleanTheme.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Inizia',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.accentGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                Icons.timer_outlined,
                '${workout.estimatedDuration} min',
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                Icons.fitness_center_outlined,
                '${workout.exercises.length} esercizi',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildCustomWorkoutCard(CustomWorkoutPlan plan) {
    return CleanCard(
      onTap: () {
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
              exerciseType: 'strength',
            );
          }).toList(),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutSessionScreen(workoutDay: workoutDay),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CleanTheme.accentPurple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.edit_note,
                  color: CleanTheme.accentPurple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    if (plan.description != null &&
                        plan.description!.isNotEmpty)
                      Text(
                        plan.description!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: CleanTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: CleanTheme.textSecondary,
                      size: 20,
                    ),
                    onPressed: () async {
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
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: CleanTheme.accentPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Inizia',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.accentPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                Icons.format_list_numbered,
                '${plan.exerciseCount} esercizi',
              ),
              const SizedBox(width: 12),
              _buildInfoChip(
                Icons.timer_outlined,
                '~${plan.estimatedDuration} min',
              ),
            ],
          ),
          if (plan.exercises.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: plan.exercises.take(3).map((we) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: CleanTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    we.exercise.name,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: CleanTheme.borderSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: CleanTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CleanTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
