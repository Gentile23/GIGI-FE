import 'package:flutter/material.dart';
import 'home/enhanced_home_screen.dart';
import 'workout/workout_screen.dart';
import 'nutrition/nutrition_dashboard_screen.dart';
import 'social/activity_feed_screen.dart';
import 'gamification/gamification_screen.dart';
import 'profile/profile_screen.dart';
import '../../core/theme/clean_theme.dart';
import '../../core/services/haptic_service.dart';
import '../widgets/clean_widgets.dart';

/// ═══════════════════════════════════════════════════════════
/// MAIN SCREEN - Full 6-tab navigation with all features
/// Restored: Workout, Nutrition, Social tabs
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
    WorkoutListScreen(), // Tab 1: Workout - RESTORED
    NutritionDashboardScreen(), // Tab 2: Nutrition - RESTORED
    ActivityFeedScreen(), // Tab 3: Social - RESTORED
    GamificationScreen(), // Tab 4: Rewards
    ProfileScreen(), // Tab 5: Profile
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: CleanBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          HapticService.lightTap();
          setState(() => _currentIndex = index);
        },
        items: const [
          CleanNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          CleanNavItem(
            icon: Icons.fitness_center_outlined,
            activeIcon: Icons.fitness_center,
            label: 'Workout',
          ),
          CleanNavItem(
            icon: Icons.restaurant_menu_outlined,
            activeIcon: Icons.restaurant_menu,
            label: 'Nutrition',
          ),
          CleanNavItem(
            icon: Icons.people_outline,
            activeIcon: Icons.people,
            label: 'Social',
          ),
          CleanNavItem(
            icon: Icons.emoji_events_outlined,
            activeIcon: Icons.emoji_events,
            label: 'Rewards',
          ),
          CleanNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
