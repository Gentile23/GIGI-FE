import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/clean_theme.dart';
import 'presentation/screens/auth/welcome_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/dashboard_screen.dart';
import 'presentation/screens/progress/progress_screen.dart';
import 'presentation/screens/workout/exercise_detail_screen.dart';
import 'presentation/screens/nutrition/macro_calculator_screen.dart';
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
      child: MaterialApp(
        title: 'GIGI',
        debugShowCheckedModeBanner: false,
        theme: CleanTheme.lightTheme,
        darkTheme: CleanTheme.darkTheme,
        themeMode: ThemeMode.dark, // Start with dark theme
        home: const WelcomeScreen(), // Start with the new welcome screen
        routes: {
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/progress': (context) => const ProgressScreen(),
          '/exercise': (context) => const ExerciseDetailScreen(),
          '/nutrition': (context) => const MacroCalculatorScreen(),
        },
      ),
    );
  }
}
