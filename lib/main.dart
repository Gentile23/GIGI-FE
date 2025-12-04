import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/modern_theme.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/auth/auth_screen.dart';
import 'presentation/screens/questionnaire/unified_questionnaire_screen.dart';
import 'presentation/screens/main_screen.dart';
import 'data/services/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/workout_provider.dart';
import 'providers/workout_log_provider.dart';
import 'providers/gamification_provider.dart';

void main() {
  runApp(const FitGeniusApp());
}

class FitGeniusApp extends StatelessWidget {
  const FitGeniusApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => WorkoutProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => WorkoutLogProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
      ],
      child: MaterialApp(
        title: 'FitGenius',
        debugShowCheckedModeBanner: false,
        theme: ModernTheme.darkTheme,
        // Start with onboarding, then: auth -> questionnaire -> main app
        home: const AppNavigator(),
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/auth': (context) => const AuthScreen(),
          '/questionnaire': (context) => const UnifiedQuestionnaireScreen(),
          '/main': (context) => const MainScreen(),
        },
      ),
    );
  }
}

/// Simple navigator to demonstrate the flow
/// In production, use go_router or similar
class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  @override
  void initState() {
    super.initState();
    // Check auth status on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Auth provider already checks status in constructor, but we can listen to changes
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    margin: const EdgeInsets.only(bottom: 32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: ModernTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/gigi_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        if (!authProvider.isAuthenticated) {
          return const AuthScreen();
        }

        // Check if user has completed their profile
        final user = authProvider.user;
        if (user != null) {
          // Check if essential profile fields are filled
          final hasCompletedProfile =
              user.goal != null &&
              user.experienceLevel != null &&
              user.weeklyFrequency != null &&
              user.trainingLocation != null;

          if (!hasCompletedProfile) {
            // Redirect to questionnaire if profile is incomplete
            return const UnifiedQuestionnaireScreen();
          }
        }

        // User is authenticated and has completed profile
        return const MainScreen();
      },
    );
  }
}
