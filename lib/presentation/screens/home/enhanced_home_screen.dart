import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';
import '../../../presentation/widgets/celebrations/celebration_overlay.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/workout_provider.dart';
import '../../../providers/gamification_provider.dart';
import '../workout/trial_workout_generation_screen.dart';

import '../workout/workout_session_screen.dart'; // Added import
import '../custom_workout/custom_workout_list_screen.dart';
import '../../../data/models/user_model.dart';
// import '../custom_workout/exercise_search_screen.dart'; // Removed unused import or comment it out if you plan to use it
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
  int _selectedFilterIndex = 0;
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
          const SnackBar(
            content: Text('🎉 La tua scheda è pronta!'),
            backgroundColor: CleanTheme.accentGreen,
            duration: Duration(seconds: 3),
          ),
        );
      }
    };
  }

  @override
  void dispose() {
    // Clean up callback
    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );
    workoutProvider.onGenerationComplete = null;
    super.dispose();
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
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      16,
                      24,
                      100,
                    ), // Bottom padding for navbar
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Header (Hello, Name + Avatar)
                        _buildCompactHeader(user),

                        const SizedBox(height: 24),

                        // 2. Search Bar
                        _buildSearchBar(),

                        const SizedBox(height: 24),

                        // 3. Filter Chips (Categories)
                        _buildFilterChips(),

                        const SizedBox(height: 32),

                        // 4. Hero Section
                        Text(
                          'Il tuo prossimo workout',
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
                              'I tuoi progressi',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: CleanTheme.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Vedi tutti',
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
                        // 6. Quick Actions
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCardWide(
                                Icons.auto_awesome,
                                'Genera Scheda AI',
                                'Piano su misura',
                                const Color(0xFF00D26A),
                                () {
                                  HapticService.lightTap();
                                  _showGeneratePlanDialog();
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
                                'Community',
                                'Entra nel gruppo',
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
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                Icons.edit_note_rounded,
                                'Le Mie Schede',
                                const Color(0xFF9B59B6),
                                () {
                                  HapticService.lightTap();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const CustomWorkoutListScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionCard(
                                Icons.camera_alt_outlined,
                                'Form Check',
                                CleanTheme.accentPurple,
                                () {
                                  HapticService.lightTap();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FormAnalysisScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
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

  // 2. Search Bar - Pill Shape
  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ricerca globale in arrivo! 🔍'),
                  backgroundColor: CleanTheme.primaryColor,
                  duration: Duration(seconds: 1),
                ),
              );
              HapticService.lightTap();
            },
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100), // Pill shape
                border: Border.all(color: CleanTheme.borderSecondary),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search,
                    color: CleanTheme.textPrimary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Cerca workout...',
                    style: GoogleFonts.inter(
                      color: CleanTheme.textTertiary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _showAdvancedFilters,
          child: Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: CleanTheme.primaryColor, // Black
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  // 3. Filter Chips
  Widget _buildFilterChips() {
    final filters = ['Tutti', 'Cardio', 'Forza', 'Flex', 'HIIT'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedFilterIndex;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedFilterIndex = index);
              HapticService.lightTap();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? CleanTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: isSelected
                    ? null
                    : Border.all(color: CleanTheme.borderSecondary),
              ),
              child: Text(
                filters[index],
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.white : CleanTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Sei mattiniero';
    if (hour < 12) return 'Buongiorno';
    if (hour < 18) return 'Buon pomeriggio';
    return 'Buonasera';
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
                          ? '$streak GIORNI DI FILA'
                          : 'INIZIA LA TUA SERIE',
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
                          ? 'Non fermarti ora! Manca poco al prossimo livello.'
                          : 'Completa un workout oggi per accendere la fiamma.',
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

    final categories = ['Tutti', 'Cardio', 'Forza', 'Flex', 'HIIT'];
    final category = categories[_selectedFilterIndex];

    // Get workouts filtered by category
    final filteredWorkouts = workoutProvider.getWorkoutsByCategory(category);

    // Determine what to show
    String title = '';
    String subtitle = '';
    List<Color> gradientColors = [CleanTheme.primaryColor, Colors.black87];
    VoidCallback? onActionTap;
    String actionLabel = 'Inizia';
    bool showHeart = false;

    if (_selectedFilterIndex != 0) {
      // --- Specific Category Selected ---
      if (filteredWorkouts.isNotEmpty) {
        final workout = filteredWorkouts.first;
        title = workout.name;
        subtitle = '${workout.focus} • ${workout.estimatedDuration} min';
        showHeart = true;

        // Dynamic colors based on category/focus could go here
        if (category == 'Cardio') {
          gradientColors = [const Color(0xFFFF512F), const Color(0xFFDD2476)];
        } else if (category == 'Forza') {
          gradientColors = [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)];
        } else if (category == 'Flex') {
          gradientColors = [const Color(0xFF11998e), const Color(0xFF38ef7d)];
        } else if (category == 'HIIT') {
          gradientColors = [const Color(0xFFED213A), const Color(0xFF93291E)];
        }

        onActionTap = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutSessionScreen(workoutDay: workout),
            ),
          );
        };
      } else {
        // No workout found for this category
        title = 'Nessun workout $category';
        subtitle = 'Genera una scheda personalizzata per questo obiettivo.';
        actionLabel = 'Genera Ora';
        gradientColors = [Colors.grey[800]!, Colors.black];

        onActionTap = _showAdvancedFilters; // Open filters to generate
      }
    } else {
      // --- "Tutti" (Default Dashboard) ---
      final hasActivePlan = workoutProvider.currentPlan != null;
      final currentWorkout =
          hasActivePlan && workoutProvider.currentPlan!.workouts.isNotEmpty
          ? workoutProvider.currentPlan!.workouts.first
          : null;

      if (hasActivePlan && currentWorkout != null) {
        title = currentWorkout.name;
        subtitle =
            '${currentWorkout.exercises.length} Esercizi • ${currentWorkout.estimatedDuration} min';
        gradientColors = [const Color(0xFF1A1A2E), const Color(0xFF16213E)];
        showHeart = true;

        onActionTap = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutSessionScreen(workoutDay: currentWorkout),
            ),
          );
        };
      } else {
        // No active plan
        title = 'Prova Gratuita';
        subtitle = 'Scopri il tuo livello con un workout di prova.';
        gradientColors = [CleanTheme.primaryColor, Colors.black87];

        onActionTap = () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TrialWorkoutGenerationScreen(),
            ),
          );
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
                      _selectedFilterIndex == 0
                          ? 'AI PLAN'
                          : category.toUpperCase(),
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
                'Obiettivo',
                '${stats?.totalWorkouts ?? 0}/5',
                const Color(0xFF00D26A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '🏆',
                'Livello',
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
            const Text('🤖', style: TextStyle(fontSize: 28)),
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
                      'Per risultati migliori, completa prima il Trial Workout',
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

  Future<void> _generatePlanDirectly() async {
    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: CleanTheme.primaryColor),
      ),
    );

    final success = await workoutProvider.generatePlan();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ Scheda generata con successo!'
                : '❌ Errore: ${workoutProvider.error ?? "Riprova"}',
          ),
          backgroundColor: success ? const Color(0xFF00D26A) : Colors.red,
        ),
      );
      if (success) _loadData();
    }
  }

  Widget _buildActionCard(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: CleanTheme.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  // --- Advanced Filters Modal ---
  void _showAdvancedFilters() {
    // Local state variables for the modal content
    int duration = 30;
    String difficulty = 'Intermedio';
    String equipment = 'Corpo Libero';
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      backgroundColor: CleanTheme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setStateModal) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Filtri Avanzati',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 32),

                // Duration Filter
                Text(
                  'Durata (min): $duration',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '15',
                      style: GoogleFonts.inter(color: CleanTheme.textSecondary),
                    ),
                    Text(
                      '30',
                      style: GoogleFonts.inter(color: CleanTheme.textSecondary),
                    ),
                    Text(
                      '45',
                      style: GoogleFonts.inter(color: CleanTheme.textSecondary),
                    ),
                    Text(
                      '60+',
                      style: GoogleFonts.inter(color: CleanTheme.textSecondary),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: CleanTheme.primaryColor,
                    inactiveTrackColor: CleanTheme.borderSecondary,
                    thumbColor: Colors.white,
                    overlayColor: CleanTheme.primaryColor.withValues(
                      alpha: 0.1,
                    ),
                  ),
                  child: Slider(
                    value: duration.toDouble(),
                    min: 15,
                    max: 60,
                    divisions: 3,
                    onChanged: (val) {
                      setStateModal(() => duration = val.toInt());
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // Difficulty Filter
                Text(
                  'Difficoltà',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: ['Principiante', 'Intermedio', 'Avanzato'].map((
                    label,
                  ) {
                    final isSelected = label == difficulty;
                    return GestureDetector(
                      onTap: () => setStateModal(() => difficulty = label),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? CleanTheme.primaryColor
                              : Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: isSelected
                                ? CleanTheme.primaryColor
                                : CleanTheme.borderSecondary,
                          ),
                        ),
                        child: Text(
                          label,
                          style: GoogleFonts.inter(
                            color: isSelected
                                ? Colors.white
                                : CleanTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // Equipment
                Text(
                  'Attrezzatura',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children:
                      ['Manubri', 'Corpo Libero', 'Kettlebell', 'Elastici'].map(
                        (label) {
                          final isSelected = label == equipment;
                          return GestureDetector(
                            onTap: () => setStateModal(() => equipment = label),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? CleanTheme.primaryColor
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: isSelected
                                      ? CleanTheme.primaryColor
                                      : CleanTheme.borderSecondary,
                                ),
                              ),
                              child: Text(
                                label,
                                style: GoogleFonts.inter(
                                  color: isSelected
                                      ? Colors.white
                                      : CleanTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        },
                      ).toList(),
                ),

                const SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(modalContext); // Close modal

                      final provider = Provider.of<WorkoutProvider>(
                        parentContext,
                        listen: false,
                      );

                      // Store reference before async gap
                      final scaffoldMessenger = ScaffoldMessenger.of(
                        parentContext,
                      );

                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Generazione piano personalizzato... 🤖',
                          ),
                          backgroundColor: CleanTheme.primaryColor,
                        ),
                      );

                      // Call backend
                      final success = await provider.generateCustomPlan({
                        'duration': duration,
                        'difficulty': difficulty.toLowerCase(),
                        'equipment': equipment.toLowerCase(),
                      });

                      if (mounted) {
                        if (success) _loadData(); // Refresh UI

                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? '✅ Piano generato!'
                                  : '❌ Errore generazione',
                            ),
                            backgroundColor: success
                                ? const Color(0xFF00D26A)
                                : Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CleanTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Applica Filtri & Genera',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
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
}
