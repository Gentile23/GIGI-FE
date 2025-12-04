import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../presentation/widgets/modern_widgets.dart';
import '../../../presentation/widgets/gamification_stats_widget.dart';
import '../../../presentation/widgets/adaptive_training_widget.dart';
import '../../../presentation/widgets/biometric_widget.dart';
import '../../../presentation/widgets/nutrition_widget.dart';
import '../../../presentation/widgets/form_check_widget.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/gamification_provider.dart';
import '../workout/workout_session_screen.dart';
import '../workout/trial_workout_generation_screen.dart';
import '../workout/preferences_review_screen.dart';
import '../../../data/models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );
      workoutProvider.fetchCurrentPlan();

      // Load gamification stats
      final gamificationProvider = Provider.of<GamificationProvider>(
        context,
        listen: false,
      );
      gamificationProvider.refresh();

      // Set callback for when generation completes
      workoutProvider.onGenerationComplete = () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Piano generato con successo!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundColor,
      body: SafeArea(
        child: Consumer2<AuthProvider, WorkoutProvider>(
          builder: (context, authProvider, workoutProvider, _) {
            final user = authProvider.user;
            final currentPlan = workoutProvider.currentPlan;

            // Plan generation restriction logic
            final lastGeneration = user?.lastPlanGeneration;
            final daysSinceLastGeneration = lastGeneration != null
                ? DateTime.now().difference(lastGeneration).inDays
                : null;
            final canGenerate =
                lastGeneration == null ||
                (daysSinceLastGeneration != null &&
                    daysSinceLastGeneration >= 60);
            final daysRemaining = daysSinceLastGeneration != null
                ? 60 - daysSinceLastGeneration
                : 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: ModernTheme.primaryColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/gigi_logo.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Hello, ${user?.name ?? 'Athlete'} 👋',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Ready to crush it?',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: ModernTheme.surfaceColor,
                        child: Icon(
                          Icons.person,
                          color: ModernTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Gamification Stats
                  const GamificationStatsWidget(),

                  const SizedBox(height: 16),

                  // Adaptive Training Insights
                  const AdaptiveTrainingWidget(),

                  const SizedBox(height: 16),

                  // Biometric Recovery Score
                  const BiometricWidget(),

                  const SizedBox(height: 16),

                  // Nutrition Tracking
                  const NutritionWidget(),

                  const SizedBox(height: 16),

                  // AI Form Check
                  const FormCheckWidget(),

                  const SizedBox(height: 24),

                  // Current Plan or Trial Workout
                  if (workoutProvider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (workoutProvider.isGenerating ||
                      (currentPlan != null &&
                          currentPlan.status == 'processing'))
                    ModernCard(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          const CircularProgressIndicator(
                            color: ModernTheme.primaryColor,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            '🤖 AI sta analizzando il tuo profilo',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Generazione piano in corso...\nAttendi mentre l\'AI crea il tuo allenamento personalizzato.',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    )
                  else
                    _buildNoPlanCard(),

                  const SizedBox(height: 32),

                  // Quick Actions
                  _buildSectionHeader('Quick Actions'),
                  const SizedBox(height: 16),

                  // Show trial requirement warning if error exists
                  if (workoutProvider.error == 'trial_required')
                    ModernCard(
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trial Workout Richiesto',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Completa il trial workout prima di generare un piano personalizzato',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (workoutProvider.error == 'trial_required')
                    const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: ModernButton(
                          text: canGenerate
                              ? 'New Plan'
                              : 'New Plan ($daysRemaining days)',
                          icon: Icons.add_circle_outline,
                          backgroundColor:
                              !canGenerate ||
                                  workoutProvider.error == 'trial_required'
                              ? Colors.grey
                              : null, // Use default accent color
                          onPressed: !canGenerate
                              ? null
                              : () async {
                                  if (user != null &&
                                      !user.trialWorkoutCompleted) {
                                    // Show Alert Dialog for Trial Workout
                                    if (context.mounted) {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor:
                                              ModernTheme.cardColor,
                                          title: const Text(
                                            'Consiglio FitGenius',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          content: const Text(
                                            'Sarebbe molto meglio fare il Trial Workout prima di generare la scheda. Questo ci permette di calibrare perfettamente i carichi su di te.',
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                // Proceed with generation anyway
                                                _generatePlan(
                                                  context,
                                                  workoutProvider,
                                                );
                                              },
                                              child: const Text(
                                                'Genera Comunque',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                            ModernButton(
                                              text: 'Vai al Trial',
                                              onPressed: () {
                                                Navigator.pop(context);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const TrialWorkoutGenerationScreen(),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  } else {
                                    // Proceed directly
                                    _generatePlan(context, workoutProvider);
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }

  Widget _buildNextWorkoutCard(dynamic plan) {
    if (plan.workouts.isEmpty) return const SizedBox.shrink();
    final nextWorkout = plan.workouts.first;

    return ModernCard(
      isSelected: true,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutSessionScreen(workoutDay: nextWorkout),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next Up',
                style: GoogleFonts.outfit(
                  color: ModernTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.arrow_forward, color: ModernTheme.primaryColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            nextWorkout.name,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.timer, size: 16, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                '${nextWorkout.estimatedDuration} min',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 16),
              const Icon(Icons.fitness_center, size: 16, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                '${nextWorkout.exercises.length} exercises',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoPlanCard() {
    return ModernCard(
      isSelected: true,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ModernTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_circle_outline,
                  color: ModernTheme.primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inizia il Tuo Trial Workout',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Prova un allenamento personalizzato con coach vocale AI!',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ModernButton(
            text: 'Inizia Trial Workout',
            icon: Icons.fitness_center,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrialWorkoutGenerationScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrialWorkoutButton(UserModel? user) {
    if (user?.trialWorkoutCompleted == true) {
      return const SizedBox.shrink();
    }
    return ModernCard(
      isSelected: true,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ModernTheme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_circle_outline,
                  color: ModernTheme.primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Try Your First Workout',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Start with a beginner-friendly trial workout',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ModernButton(
            text: 'Start Trial Workout',
            icon: Icons.fitness_center,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrialWorkoutGenerationScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _generatePlan(
    BuildContext context,
    WorkoutProvider workoutProvider,
  ) async {
    // Navigate to preferences review screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PreferencesReviewScreen()),
    );
  }
}
