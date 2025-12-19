import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'core/theme/clean_theme.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/auth/auth_screen.dart';
import 'presentation/screens/auth/landing_screen.dart';
import 'presentation/screens/onboarding/welcome_flow_screen.dart';
import 'presentation/screens/questionnaire/unified_questionnaire_screen.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/progress/progress_dashboard_screen.dart';
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

/// Custom scroll behavior per web - abilita scroll con mouse e touch
class WebScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
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
        // Abilita scroll con mouse su web
        scrollBehavior: kIsWeb ? WebScrollBehavior() : null,
        // Start with onboarding, then: auth -> questionnaire -> main app
        home: const AppNavigator(),
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/auth': (context) => const AuthScreen(),
          '/questionnaire': (context) => const UnifiedQuestionnaireScreen(),
          '/main': (context) => const MainScreen(),
          '/progress': (context) => const ProgressDashboardScreen(),
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
        if (authProvider.isInitializing) {
          return Scaffold(
            backgroundColor: CleanTheme.backgroundColor,
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
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: CleanTheme.primaryColor.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/gigi_new_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const CircularProgressIndicator(
                    color: CleanTheme.primaryColor,
                  ),
                ],
              ),
            ),
          );
        }

        if (!authProvider.isAuthenticated) {
          return const LandingScreen();
        }

        // Check if user has completed their profile
        final user = authProvider.user;
        if (user != null) {
          // Check if user has completed minimal profile (goal + experience)
          final hasMinimalProfile =
              user.goal != null && user.experienceLevel != null;

          if (!hasMinimalProfile) {
            // Show simplified welcome flow for new users
            return const WelcomeFlowScreen();
          }
        }

        // User is authenticated and has completed profile
        return const MainScreen();
      },
    );
  }
}
