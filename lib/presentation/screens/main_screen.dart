import 'package:flutter/material.dart';
import 'package:gigi/l10n/app_localizations.dart';
import 'home/enhanced_home_screen.dart';
import 'workout/unified_workout_list_screen.dart';
import 'nutrition/nutrition_dashboard_screen.dart';
import 'progress/progress_dashboard_screen.dart';
import 'profile/profile_screen.dart';
import '../../core/theme/clean_theme.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/ui_preferences_service.dart';
import '../../providers/auth_provider.dart';
import '../widgets/navigation/floating_nav_bar.dart';
import '../navigation/main_tab_navigation.dart';
import 'package:provider/provider.dart';

/// ═══════════════════════════════════════════════════════════
/// MAIN SCREEN - TRIPGLIDE STYLE
/// Stack-based layout with Floating Navigation Bar
/// ═══════════════════════════════════════════════════════════
class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    EnhancedHomeScreen(), // Tab 0: Home
    UnifiedWorkoutListScreen(), // Tab 1: Workout
    NutritionDashboardScreen(), // Tab 2: Nutrition
    ProgressDashboardScreen(), // Tab 3: Progress (was Rewards)
    ProfileScreen(), // Tab 4: Profile
  ];

  @override
  void initState() {
    super.initState();
    final maxIndex = _screens.length - 1;
    final initial = widget.initialIndex < 0
        ? 0
        : (widget.initialIndex > maxIndex ? maxIndex : widget.initialIndex);
    _currentIndex = initial;
    MainTabNavigation.selectedIndex.value = initial;
    MainTabNavigation.selectedIndex.addListener(_handleExternalTabChange);
  }

  @override
  void dispose() {
    MainTabNavigation.selectedIndex.removeListener(_handleExternalTabChange);
    super.dispose();
  }

  void _handleExternalTabChange() {
    final nextIndex = MainTabNavigation.selectedIndex.value;
    if (!mounted || nextIndex == _currentIndex) return;
    setState(() => _currentIndex = nextIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Main Content (Behind Navbar)
          Positioned.fill(
            child: IndexedStack(
              key: const ValueKey('main_content_stack'),
              index: _currentIndex,
              children: _screens,
            ),
          ),

          // 2. Floating Navigation Bar
          Consumer2<AuthProvider, UiPreferencesService>(
            builder: (context, authProvider, uiPreferences, _) {
              final hasActiveProUi =
                  (authProvider.user?.subscription?.isActive ?? false) &&
                  uiPreferences.proBottomBarAccentEnabled;

              return FloatingNavBar(
                currentIndex: _currentIndex,
                showProAccent: hasActiveProUi,
                onTap: (index) {
                  HapticService.lightTap();
                  if (index == _currentIndex) return;
                  setState(() => _currentIndex = index);
                  MainTabNavigation.selectedIndex.value = index;
                },
                items: [
                  FloatingNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: AppLocalizations.of(context)!.home,
                  ),
                  FloatingNavItem(
                    icon: Icons.fitness_center_outlined,
                    activeIcon: Icons.fitness_center,
                    label: AppLocalizations.of(context)!.workout,
                  ),
                  FloatingNavItem(
                    icon: Icons.restaurant_menu_outlined,
                    activeIcon: Icons.restaurant_menu,
                    label: AppLocalizations.of(context)!.nutrition,
                  ),
                  FloatingNavItem(
                    icon: Icons.trending_up_outlined,
                    activeIcon: Icons.trending_up,
                    label: AppLocalizations.of(context)!.progress,
                  ),
                  FloatingNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: AppLocalizations.of(context)!.profile,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
