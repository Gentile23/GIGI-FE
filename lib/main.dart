import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gigi/l10n/app_localizations.dart';
import 'core/theme/clean_theme.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/auth/auth_screen.dart';
import 'presentation/screens/auth/landing_screen.dart';
import 'presentation/screens/questionnaire/unified_questionnaire_screen.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/screens/progress/progress_dashboard_screen.dart';
import 'presentation/screens/nutrition/diet_upload_screen.dart';
import 'presentation/screens/nutrition/diet_plan_screen.dart';
import 'presentation/screens/nutrition/shopping_list_generator_screen.dart';
import 'data/services/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/workout_provider.dart';
import 'providers/workout_log_provider.dart';
import 'providers/gamification_provider.dart';
import 'providers/engagement_provider.dart';
import 'providers/social_provider.dart';
import 'providers/nutrition_coach_provider.dart';
import 'core/services/payment_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

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
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider(create: (_) => AuthProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => WorkoutProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => WorkoutLogProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
        ChangeNotifierProvider(create: (_) => EngagementProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => SocialProvider(apiClient)),
        ChangeNotifierProvider(create: (_) => PaymentService()..initialize()),
        ChangeNotifierProvider(
          create: (_) => NutritionCoachProvider(apiClient),
        ),
      ],
      child: MaterialApp(
        title: 'GIGI',
        debugShowCheckedModeBanner: false,
        theme: CleanTheme.lightTheme,
        // Abilita scroll con mouse su web
        scrollBehavior: kIsWeb ? WebScrollBehavior() : null,
        // Localization Configuration
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('it'), // Italian (default)
          Locale('en'), // English
          Locale('de'), // German
          Locale('fr'), // French
          Locale('pt'), // Portuguese
          Locale('ar'), // Arabic (RTL)
        ],
        // Start with onboarding, then: auth -> questionnaire -> main app
        home: const AppNavigator(),
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/auth': (context) => const AuthScreen(),
          '/questionnaire': (context) => const UnifiedQuestionnaireScreen(),
          '/main': (context) => const MainScreen(),
          '/progress': (context) => const ProgressDashboardScreen(),
          '/nutrition/coach/upload': (context) => const DietUploadScreen(),
          '/nutrition/coach/plan': (context) => const DietPlanScreen(),
          '/nutrition/coach/shopping-list': (context) =>
              const ShoppingListScreen(),
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
        Widget child;

        if (authProvider.isInitializing ||
            (authProvider.isLoading && !authProvider.isAuthenticated)) {
          child = Scaffold(
            key: const ValueKey('splash'),
            backgroundColor: CleanTheme.backgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    margin: const EdgeInsets.only(bottom: 32),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
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
        } else if (!authProvider.isAuthenticated) {
          child = const LandingScreen(key: ValueKey('landing'));
        } else {
          final user = authProvider.user;

          // Check if user has completed questionnaire
          if (user != null && !user.isQuestionnaireComplete) {
            // Show the unified questionnaire (which now starts with Gigi welcome)
            child = const UnifiedQuestionnaireScreen(
              key: ValueKey('questionnaire'),
            );
          } else {
            // User is authenticated and has completed questionnaire
            child = const MainScreen(key: ValueKey('main'));
          }
        }

        return child;
      },
    );
  }
}
