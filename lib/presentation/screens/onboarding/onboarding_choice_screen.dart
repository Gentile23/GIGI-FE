import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';
import '../progress/body_measurements_screen.dart';
import '../workout/trial_workout_generation_screen.dart';
import '../home/enhanced_home_screen.dart';

/// ═══════════════════════════════════════════════════════════
/// ONBOARDING CHOICE SCREEN - Optional steps after form completion
/// Psychology: Give control back to user + loss aversion messaging
/// ═══════════════════════════════════════════════════════════
class OnboardingChoiceScreen extends StatelessWidget {
  const OnboardingChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 1),

              // Success Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: CleanTheme.accentGreen.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: CleanTheme.accentGreen,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Center(
                child: Text(
                  'Profilo Base Completato! 🎉',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: CleanTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Center(
                child: Text(
                  'Ora puoi scegliere come continuare.\nOgni step aggiuntivo rende la tua scheda più precisa.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: CleanTheme.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(flex: 1),

              // Option Cards
              _buildOptionCard(
                context,
                icon: Icons.fitness_center_rounded,
                emoji: '🏋️',
                title: 'Fai il Trial Workout',
                subtitle: 'Calibra la scheda sul tuo livello reale',
                badge: '🎯 Consigliato',
                badgeColor: CleanTheme.primaryColor,
                onTap: () {
                  HapticService.mediumTap();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TrialWorkoutGenerationScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              _buildOptionCard(
                context,
                icon: Icons.straighten_rounded,
                emoji: '📏',
                title: 'Inserisci le Misure',
                subtitle: 'Traccia i progressi nel tempo',
                badge: '📊 Opzionale',
                badgeColor: CleanTheme.textSecondary,
                onTap: () {
                  HapticService.lightTap();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BodyMeasurementsScreen(
                        isOnboarding: true,
                        onComplete: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EnhancedHomeScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),

              const Spacer(flex: 2),

              // Skip Button
              Center(
                child: TextButton(
                  onPressed: () {
                    HapticService.lightTap();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EnhancedHomeScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Salta per ora →',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: CleanTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Reassurance text
              Center(
                child: Text(
                  'Potrai sempre completare questi step dal tuo profilo',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CleanTheme.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String emoji,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CleanTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CleanTheme.borderPrimary),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: CleanTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
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

            // Arrow
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: CleanTheme.textTertiary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
