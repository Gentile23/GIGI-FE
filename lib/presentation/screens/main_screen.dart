import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home/enhanced_home_screen.dart';
import 'gamification/gamification_screen.dart';
import 'profile/profile_screen.dart';
import 'progress/progress_screen.dart';
import 'workout/workout_screen.dart';
import 'workout/trial_workout_generation_screen.dart';
import 'custom_workout/custom_workout_list_screen.dart';
import '../../core/theme/clean_theme.dart';
import '../../core/services/haptic_service.dart';
import '../widgets/navigation/fab_bottom_nav_bar.dart';

/// ═══════════════════════════════════════════════════════════
/// MAIN SCREEN - Redesigned with 4 tabs + Central FAB
/// Psychology: Reduced cognitive load (Hick's Law)
/// FAB provides clear primary action affordance
/// ═══════════════════════════════════════════════════════════
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    EnhancedHomeScreen(), // Tab 0: Home
    ProgressScreen(), // Tab 1: Progress (replaces Nutrition + Social)
    GamificationScreen(), // Tab 2: Rewards
    ProfileScreen(), // Tab 3: Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: FABBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          HapticService.lightTap();
          setState(() => _currentIndex = index);
        },
        onFABPressed: _showWorkoutOptions,
        items: const [
          FABNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),
          FABNavItem(
            icon: Icons.insights_outlined,
            activeIcon: Icons.insights_rounded,
            label: 'Progressi',
          ),
          FABNavItem(
            icon: Icons.emoji_events_outlined,
            activeIcon: Icons.emoji_events_rounded,
            label: 'Rewards',
          ),
          FABNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person_rounded,
            label: 'Profilo',
          ),
        ],
      ),
    );
  }

  void _showWorkoutOptions() {
    HapticService.mediumTap();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _WorkoutOptionsSheet(
        onStartWorkout: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WorkoutListScreen()),
          );
        },
        onTrialWorkout: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TrialWorkoutGenerationScreen(),
            ),
          );
        },
        onCustomWorkout: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomWorkoutListScreen()),
          );
        },
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════
/// WORKOUT OPTIONS SHEET - Bottom sheet for workout selection
/// Psychology: Progressive disclosure - reveal options when needed
/// ═══════════════════════════════════════════════════════════
class _WorkoutOptionsSheet extends StatelessWidget {
  final VoidCallback onStartWorkout;
  final VoidCallback onTrialWorkout;
  final VoidCallback onCustomWorkout;

  const _WorkoutOptionsSheet({
    required this.onStartWorkout,
    required this.onTrialWorkout,
    required this.onCustomWorkout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: CleanTheme.borderSecondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inizia un Workout',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scegli come vuoi allenarti oggi',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: CleanTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Option: Continue Plan
                _buildOption(
                  icon: Icons.play_circle_filled,
                  iconColor: const Color(0xFF00D26A),
                  title: 'Continua Piano',
                  subtitle: 'Riprendi dal tuo programma personalizzato',
                  onTap: onStartWorkout,
                ),
                const SizedBox(height: 16),

                // Option: Trial Workout
                _buildOption(
                  icon: Icons.flash_on_rounded,
                  iconColor: const Color(0xFFFF6B35),
                  title: 'Workout Rapido',
                  subtitle: 'Allenamento veloce con voice coaching',
                  onTap: onTrialWorkout,
                ),
                const SizedBox(height: 16),

                // Option: Custom Workout
                _buildOption(
                  icon: Icons.edit_note_rounded,
                  iconColor: const Color(0xFF9B59B6),
                  title: 'Scheda Custom',
                  subtitle: 'Crea o usa una scheda personalizzata',
                  onTap: onCustomWorkout,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticService.lightTap();
        onTap();
      },
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
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 26),
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
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: CleanTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
