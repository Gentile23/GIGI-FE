import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
import '../../widgets/animations/background_motion.dart';
import '../../widgets/animations/animated_logo.dart';
import 'package:gigi/l10n/app_localizations.dart';
import 'auth_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: Stack(
        children: [
          // 1. Animated Background
          const Positioned.fill(child: BackgroundMotion()),

          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // 2. Animated Logo
                  const AnimatedLogo(
                    size: 240,
                    heroTag: 'gigi_logo',
                    enableBreathing: true,
                    enableShimmer: true,
                  ),

                  const SizedBox(height: 48),

                  // 3. App Title (Animate In)
                  Text(
                        'GIGI',
                        style: GoogleFonts.outfit(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                          color: CleanTheme.textPrimary,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 16),

                  // 4. Slogan (Animate In)
                  Text(
                        AppLocalizations.of(context)!.slogan,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: CleanTheme.textSecondary,
                          height: 1.5,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 400.ms)
                      .slideY(begin: 0.2, end: 0),

                  const Spacer(flex: 2),

                  // 5. Action Buttons (Animate In Staggered)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CleanButton(
                            text: AppLocalizations.of(context)!.startNow,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AuthScreen(initialIsLogin: false),
                                ),
                              );
                            },
                            isPrimary: true,
                            width: double.infinity,
                          )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 600.ms)
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 16),
                      CleanButton(
                            text: AppLocalizations.of(context)!.login,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AuthScreen(initialIsLogin: true),
                                ),
                              );
                            },
                            isPrimary: false,
                            isOutlined: true,
                            width: double.infinity,
                          )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 800.ms)
                          .slideY(begin: 0.2, end: 0),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Footer Info
                  Text(
                    AppLocalizations.of(context)!.sloganSubtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: CleanTheme.textTertiary,
                      fontWeight: FontWeight.w400,
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 1000.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
