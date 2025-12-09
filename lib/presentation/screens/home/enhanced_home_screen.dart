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
import '../workout/workout_screen.dart';
import '../custom_workout/custom_workout_list_screen.dart';
import '../../../data/models/user_model.dart';
import '../custom_workout/exercise_search_screen.dart';
import '../../widgets/skeleton_box.dart';
import '../profile/profile_screen.dart';
import '../social/activity_feed_screen.dart';
import '../form_analysis/form_analysis_screen.dart';

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
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  bool _showCelebration = false;
  final CelebrationStyle _celebrationStyle = CelebrationStyle.confetti;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _breathingController.dispose();
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
      backgroundColor: CleanTheme.backgroundColor,
      body: Stack(
        children: [
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildCompactHeader(user),
                          const SizedBox(height: 24),
                          _buildStreakMotivator(),
                          const SizedBox(height: 24),
                          _buildHeroWorkoutCard(workoutProvider),
                          const SizedBox(height: 24),
                          _buildQuickStatsRow(),
                          const SizedBox(height: 28),
                          _buildWeeklyProgress(),
                          const SizedBox(height: 28),
                          _buildQuickActions(user),
                          const SizedBox(height: 48),
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
      children: [
        GestureDetector(
          onTap: () {
            HapticService.lightTap();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CleanTheme.primaryColor,
                  CleanTheme.primaryColor.withValues(alpha: 0.7),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CleanTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
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
                '$greeting,',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: CleanTheme.textSecondary,
                  height: 1.2,
                ),
              ),
              Text(
                '$name 👋',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: CleanTheme.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        // Search Icon
        GestureDetector(
          onTap: () {
            HapticService.lightTap();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const ExerciseSearchScreen(isSelectionMode: false),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CleanTheme.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: CleanTheme.borderSecondary),
            ),
            child: const Icon(
              Icons.search,
              color: CleanTheme.textSecondary,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Notification Icon
        GestureDetector(
          onTap: () => HapticService.lightTap(),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CleanTheme.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: CleanTheme.borderSecondary),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: CleanTheme.textSecondary,
              size: 24,
            ),
          ),
        ),
      ],
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

  Widget _buildHeroWorkoutCard(WorkoutProvider workoutProvider) {
    if (workoutProvider.isGenerating) return _buildGeneratingCard();

    // Context-Aware Logic
    final hour = DateTime.now().hour;
    final isMorning = hour < 12;
    final isEvening = hour > 18;

    String title = 'Workout del Giorno';
    String subtitle = 'Full Body Power 💪';
    List<Color> gradientColors = [
      const Color(0xFF1A1A2E),
      const Color(0xFF16213E),
    ];

    if (isMorning) {
      title = 'Morning Energy ☀️';
      subtitle = 'Carica la tua giornata';
      gradientColors = [const Color(0xFFFF9966), const Color(0xFFFF5E62)];
    } else if (isEvening) {
      title = 'Evening Decompress 🌙';
      subtitle = 'Rilassati e scarica';
      gradientColors = [const Color(0xFF2B5876), const Color(0xFF4E4376)];
    }

    // Check if user has a trial or active plan
    final hasActivePlan = workoutProvider.currentPlan != null;
    if (!hasActivePlan) {
      title = 'Prova Gratuita';
      subtitle = 'Scopri il tuo livello 🚀';
      gradientColors = [CleanTheme.primaryColor, const Color(0xFF00BFA5)];
    }

    return GestureDetector(
      onTap: () {
        HapticService.mediumTap();
        if (!hasActivePlan) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TrialWorkoutGenerationScreen(),
            ),
          );
        } else {
          // Future: Navigate to actual workout
          // For now, we can show a toast or navigation placeholder
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Navigation to workout plan implementation pending',
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              if (hasActivePlan) // Show stats only if plan exists
                Row(
                  children: [
                    _buildDetail(Icons.timer_outlined, '45 min'),
                    const SizedBox(width: 16),
                    _buildDetail(Icons.local_fire_department, '320 kcal'),
                    const SizedBox(width: 16),
                    _buildDetail(Icons.fitness_center, '12 esercizi'),
                  ],
                )
              else
                Row(
                  children: [
                    _buildDetail(Icons.timer_outlined, '15 min'),
                    const SizedBox(width: 16),
                    _buildDetail(Icons.bolt, 'Intensità Media'),
                  ],
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ScaleTransition(
                  scale: _breathingAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[1].withValues(alpha: 0.4),
                          blurRadius: 15,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasActivePlan ? 'INIZIA ORA' : 'INIZIA PROVA',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
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
      ),
    );
  }

  Widget _buildDetail(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 16, color: Colors.white60),
      const SizedBox(width: 4),
      Text(text, style: GoogleFonts.inter(fontSize: 13, color: Colors.white70)),
    ],
  );

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
            'Ci vorranno pochi secondi...',
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

  Widget _buildWeeklyProgress() {
    final days = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];
    final today = DateTime.now().weekday - 1;
    final completed = [true, true, true, false, false, false, false];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Questa Settimana',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CleanTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CleanTheme.borderPrimary),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final isToday = i == today;
              final isDone = completed[i];
              return Column(
                children: [
                  Text(
                    days[i],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isToday
                          ? CleanTheme.primaryColor
                          : CleanTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDone
                          ? CleanTheme.primaryColor
                          : isToday
                          ? CleanTheme.primaryColor.withValues(alpha: 0.1)
                          : CleanTheme.borderSecondary,
                      shape: BoxShape.circle,
                      border: isToday && !isDone
                          ? Border.all(color: CleanTheme.primaryColor, width: 2)
                          : null,
                    ),
                    child: Icon(
                      isDone ? Icons.check : Icons.circle,
                      size: isDone ? 18 : 6,
                      color: isDone ? Colors.white : CleanTheme.textTertiary,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(UserModel? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Azioni Rapide',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        // Trial Workout Action (only if not completed)
        if (user != null && !user.trialWorkoutCompleted) ...[
          _buildActionCardWide(
            Icons.fitness_center,
            'Trial Workout',
            'Calibra il tuo livello con un test rapido',
            CleanTheme.primaryColor,
            () {
              HapticService.lightTap();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TrialWorkoutGenerationScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
        // First row: Generate AI Plan (full width)
        _buildActionCardWide(
          Icons.auto_awesome,
          'Genera Scheda AI',
          'Crea un piano personalizzato con AI',
          const Color(0xFF00D26A),
          () {
            HapticService.lightTap();
            _showGeneratePlanDialog();
          },
        ),
        const SizedBox(height: 12),
        // Second row: Custom + History
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                Icons.edit_note_rounded,
                'Schede Custom',
                const Color(0xFF9B59B6),
                () {
                  HapticService.lightTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustomWorkoutListScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                Icons.history_rounded,
                'Storico',
                const Color(0xFF3498DB),
                () {
                  HapticService.lightTap();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WorkoutListScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Third row: Community (full width or single)
        _buildActionCardWide(
          Icons.people_alt_rounded,
          'Community',
          'Feed, Sfide e Classifiche',
          CleanTheme.accentOrange,
          () {
            HapticService.lightTap();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ActivityFeedScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        // Fourth row: AI Form Check (Premium feature)
        _buildActionCardWide(
          Icons.camera_alt_outlined,
          'AI Form Check',
          'Analizza la tua esecuzione con Gemini',
          CleanTheme.accentPurple,
          () {
            HapticService.lightTap();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FormAnalysisScreen()),
            );
          },
        ),
      ],
    );
  }

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
