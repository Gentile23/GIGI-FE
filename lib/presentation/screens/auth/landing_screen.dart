import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
import 'auth_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: Stack(
        children: [
          // Background Aesthetic - Subtle gradient or image
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    CleanTheme.primaryColor.withValues(alpha: 0.05),
                    CleanTheme.accentPurple.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // Logo and Branding
                  Hero(
                    tag: 'gigi_logo',
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: CleanTheme.primaryColor.withValues(
                              alpha: 0.2,
                            ),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            'assets/images/gigi_new_logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.fitness_center,
                                  size: 60,
                                  color: CleanTheme.primaryColor,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // App Title
                  Text(
                    'GIGI',
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      color: CleanTheme.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Slogan
                  Text(
                    'La tua evoluzione fitness,\nguidata dall\'intelligenza.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: CleanTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Action Buttons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CleanButton(
                        text: 'INIZIA ORA',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AuthScreen(
                                initialIsLogin: false,
                                onComplete: () => Navigator.of(context).pop(),
                              ),
                            ),
                          );
                        },
                        isPrimary: true,
                        width: double.infinity,
                      ),
                      const SizedBox(height: 16),
                      CleanButton(
                        text: 'ACCEDI',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AuthScreen(
                                initialIsLogin: true,
                                onComplete: () => Navigator.of(context).pop(),
                              ),
                            ),
                          );
                        },
                        isPrimary: false,
                        isOutlined: true,
                        width: double.infinity,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Footer Info
                  Text(
                    'Allenati con intelligenza. Ottieni risultati.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: CleanTheme.textTertiary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

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
