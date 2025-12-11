import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../presentation/widgets/clean_widgets.dart';
import '../../../presentation/widgets/addiction_mechanics_widgets.dart';
import '../../../presentation/widgets/onboarding_overlay.dart';
import '../../../presentation/widgets/progress/progress_summary_widget.dart';
import '../../../data/models/addiction_mechanics_model.dart';
import '../../../data/services/api_client.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/gamification_provider.dart';
import '../workout/workout_session_screen.dart';
import '../workout/trial_workout_generation_screen.dart';
import '../workout/preferences_review_screen.dart';
import '../form_analysis/form_analysis_screen.dart';
import '../../../data/models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['Tutti', 'Forza', 'Cardio', 'Mobilità'];

  // Progress data
  Map<String, dynamic>? _progressData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstTimeUser();

      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );
      workoutProvider.fetchCurrentPlan();

      final gamificationProvider = Provider.of<GamificationProvider>(
        context,
        listen: false,
      );
      gamificationProvider.refresh();

      // Load progress data
      _loadProgressData();

      workoutProvider.onGenerationComplete = () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Piano generato con successo!'),
              backgroundColor: CleanTheme.accentGreen,
              duration: Duration(seconds: 3),
            ),
          );
        }
      };
    });
  }

  Future<void> _loadProgressData() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get('/progress/summary');
      if (mounted && response.data['success'] == true) {
        setState(() {
          _progressData = response.data['summary'];
        });
      }
    } catch (e) {
      debugPrint('Could not load progress data: $e');
    }
  }

  Future<void> _checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome = prefs.getBool('has_seen_welcome_gigi_v2') ?? false;

    if (!hasSeenWelcome && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (context) => OnboardingOverlay(
          onStartTrial: () {
            prefs.setBool('has_seen_welcome_gigi_v2', true);
            Navigator.pop(context);
            _navigateToTrialWorkout();
          },
          onDismiss: () {
            prefs.setBool('has_seen_welcome_gigi_v2', true);
            Navigator.pop(context);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: SafeArea(
        child: Consumer2<AuthProvider, WorkoutProvider>(
          builder: (context, authProvider, workoutProvider, _) {
            final user = authProvider.user;
            final currentPlan = workoutProvider.currentPlan;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ═══════════════════════════════════════════
                  // HEADER - Travel app style
                  // ═══════════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ciao, ${user?.name ?? 'Atleta'}',
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: CleanTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Benvenuto in GIGI',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: CleanTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        // Avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: CleanTheme.borderPrimary,
                              width: 2,
                            ),
                            image: const DecorationImage(
                              image: AssetImage(
                                'assets/images/gigi_new_logo.png',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ═══════════════════════════════════════════
                  // SEARCH BAR
                  // ═══════════════════════════════════════════
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: CleanSearchBar(
                      hintText: 'Cerca esercizi...',
                      showFilter: true,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ═══════════════════════════════════════════
                  // LIVE ACTIVITY BANNER - Social Proof
                  // ═══════════════════════════════════════════
                  const LiveActivityBanner(),

                  const SizedBox(height: 8),

                  // ═══════════════════════════════════════════
                  // STREAK DISPLAY - Compact
                  // ═══════════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        StreakDisplayWidget(
                          streakData: StreakData(
                            currentStreak: 7,
                            longestStreak: 14,
                            xpMultiplier: StreakData.calculateMultiplier(7),
                          ),
                          compact: true,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: CleanTheme.accentGreen.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Text('⭐', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(
                                '2,450 XP',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: CleanTheme.accentGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ═══════════════════════════════════════════
                  // SECTION: Il Tuo Allenamento
                  // ═══════════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CleanSectionHeader(
                      title: 'Il tuo allenamento',
                      actionText: 'Vedi tutti',
                      onAction: () {},
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Category Chips
                  HorizontalChips(
                    chips: _categories,
                    selectedIndex: _selectedCategoryIndex,
                    onSelected: (index) {
                      setState(() => _selectedCategoryIndex = index);
                    },
                  ),

                  const SizedBox(height: 20),

                  // ═══════════════════════════════════════════
                  // FEATURED WORKOUT CARD
                  // ═══════════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildFeaturedWorkoutCard(
                      user,
                      workoutProvider,
                      currentPlan,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ═══════════════════════════════════════════
                  // SECTION: Programmi Consigliati
                  // ═══════════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CleanSectionHeader(
                      title: 'Programmi consigliati',
                      actionText: 'Vedi tutti',
                      onAction: () {},
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Horizontal scrolling workout cards
                  SizedBox(
                    height: 260,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildWorkoutCard(
                          title: 'Full Body Power',
                          subtitle: '45 min • 8 esercizi',
                          rating: '4.8',
                          category: 'Forza',
                          onTap: () => _navigateToTrialWorkout(),
                        ),
                        const SizedBox(width: 16),
                        _buildWorkoutCard(
                          title: 'HIIT Cardio',
                          subtitle: '30 min • 6 esercizi',
                          rating: '4.6',
                          category: 'Cardio',
                          onTap: () => _navigateToTrialWorkout(),
                        ),
                        const SizedBox(width: 16),
                        _buildWorkoutCard(
                          title: 'Yoga Flow',
                          subtitle: '40 min • 12 pose',
                          rating: '4.9',
                          category: 'Mobilità',
                          onTap: () => _navigateToTrialWorkout(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ═══════════════════════════════════════════
                  // SECTION: Il Tuo Programma (Schedule)
                  // ═══════════════════════════════════════════
                  if (currentPlan != null &&
                      currentPlan.workouts.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: CleanSectionHeader(
                        title: 'Il tuo programma',
                        actionText: 'Modifica',
                        onAction: () {},
                      ),
                    ),

                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: currentPlan.workouts.take(3).map((workout) {
                          final dayIndex =
                              currentPlan.workouts.indexOf(workout) + 1;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildScheduleItem(
                              day: 'Giorno $dayIndex',
                              title: workout.name,
                              duration: '${workout.estimatedDuration} min',
                              exercises: '${workout.exercises.length} esercizi',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WorkoutSessionScreen(
                                      workoutDay: workout,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // ═══════════════════════════════════════════
                  // QUICK ACTIONS
                  // ═══════════════════════════════════════════
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CleanSectionHeader(title: 'Azioni rapide'),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.fitness_center,
                            label: 'Trial Workout',
                            onTap: () => _navigateToTrialWorkout(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.videocam_outlined,
                            label: 'AI Form Check',
                            color: CleanTheme.accentPurple,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const FormAnalysisScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickAction(
                            icon: Icons.auto_awesome,
                            label: 'Genera Piano',
                            onTap: () =>
                                _generatePlan(context, workoutProvider),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ═══════════════════════════════════════════
                  // SECTION: I Tuoi Progressi
                  // ═══════════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CleanSectionHeader(
                      title: 'I tuoi progressi',
                      actionText: 'Dashboard',
                      onAction: () => Navigator.pushNamed(context, '/progress'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ProgressSummaryWidget(
                      latestMeasurements: _progressData?['latest_measurements'],
                      changes: _progressData?['changes'],
                      streak: _progressData?['streak'] ?? 0,
                      totalMeasurements:
                          _progressData?['total_measurements'] ?? 0,
                    ),
                  ),

                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FEATURED WORKOUT CARD
  // ═══════════════════════════════════════════════════════════
  Widget _buildFeaturedWorkoutCard(
    UserModel? user,
    WorkoutProvider workoutProvider,
    dynamic currentPlan,
  ) {
    if (workoutProvider.isLoading) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: CleanTheme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: CleanTheme.borderPrimary),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: CleanTheme.primaryColor),
        ),
      );
    }

    if (workoutProvider.isGenerating ||
        (currentPlan != null && currentPlan.status == 'processing')) {
      return Container(
        height: 280,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: CleanTheme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: CleanTheme.primaryColor),
        ),
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
              'Attendere prego...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CleanTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (currentPlan != null && currentPlan.workouts.isNotEmpty) {
      final nextWorkout = currentPlan.workouts.first;
      return FeaturedImageCard(
        assetImage: 'assets/images/workout_hero.png',
        title: nextWorkout.name,
        badge: 'Prossimo',
        rating: '4.8',
        reviews: '${nextWorkout.exercises.length} esercizi',
        subtitle: '${nextWorkout.estimatedDuration} min • Inizia ora',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  WorkoutSessionScreen(workoutDay: nextWorkout),
            ),
          );
        },
        onFavorite: () {},
      );
    }

    return FeaturedImageCard(
      assetImage: 'assets/images/cardio.png',
      title: 'Inizia il Tuo Percorso',
      badge: 'Nuovo',
      rating: '5.0',
      reviews: 'Consigliato',
      subtitle: 'Prova un allenamento con AI Coach',
      onTap: () => _navigateToTrialWorkout(),
      onFavorite: () {},
    );
  }

  Widget _buildWorkoutCard({
    required String title,
    required String subtitle,
    required String rating,
    required String category,
    required VoidCallback onTap,
  }) {
    return ImageCard(
      title: title,
      subtitle: subtitle,
      rating: rating,
      price: category,
      width: 180,
      imageHeight: 130,
      onTap: onTap,
      onFavorite: () {},
    );
  }

  Widget _buildScheduleItem({
    required String day,
    required String title,
    required String duration,
    required String exercises,
    required VoidCallback onTap,
  }) {
    return CleanCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: CleanTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: CleanTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: CleanTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
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
                  '$duration • $exercises',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: CleanTheme.textSecondary),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final iconColor = color ?? CleanTheme.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: CleanTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CleanTheme.borderPrimary),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: CleanTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTrialWorkout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TrialWorkoutGenerationScreen(),
      ),
    );
  }

  Future<void> _generatePlan(
    BuildContext context,
    WorkoutProvider workoutProvider,
  ) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PreferencesReviewScreen()),
    );
  }
}
