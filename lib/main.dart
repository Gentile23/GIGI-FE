import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/clean_theme.dart';
import 'presentation/screens/auth/welcome_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/dashboard_screen.dart';
import 'presentation/screens/progress/progress_screen.dart';
import 'presentation/screens/workout/exercise_detail_screen.dart';
import 'presentation/screens/nutrition/macro_calculator_screen.dart';
import 'presentation/widgets/main_scaffold.dart';
import 'data/services/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/workout_provider.dart';
import 'providers/workout_log_provider.dart';
import 'providers/gamification_provider.dart';
import 'providers/engagement_provider.dart';
import 'providers/social_provider.dart';

void main() {
  runApp(const GigiApp());
}

// GoRouter configuration
final _router = GoRouter(
  initialLocation: '/welcome',
  routes: [
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(child: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/progress',
              builder: (context, state) => const ProgressScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/exercise',
      builder: (context, state) => const ExerciseDetailScreen(),
    ),
    GoRoute(
      path: '/nutrition',
      builder: (context, state) => const MacroCalculatorScreen(),
    ),
  ],
);

class GigiApp extends StatelessWidget {
  const GigiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => WorkoutProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => WorkoutLogProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
        ChangeNotifierProvider(create: (_) => EngagementProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => SocialProvider(apiClient)),
      ],
      child: MaterialApp.router(
        title: 'GIGI',
        debugShowCheckedModeBanner: false,
        theme: CleanTheme.lightTheme,
        darkTheme: CleanTheme.darkTheme,
        themeMode: ThemeMode.dark, // Start with dark theme
        routerConfig: _router,
      ),
    );
  }
}
