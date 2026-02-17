import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/services/haptic_service.dart';
import '../../../providers/auth_provider.dart';

/// ═══════════════════════════════════════════════════════════
/// PROFILE COMPLETION BANNER
/// Shows users how to complete their profile for better workout plans
/// Uses loss aversion: "Your plan could be more precise"
/// ═══════════════════════════════════════════════════════════
class ProfileCompletionBanner extends StatelessWidget {
  final VoidCallback? onDismiss;

  const ProfileCompletionBanner({super.key, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;

        // Calculate completion percentage
        final completionData = _calculateCompletion(user);
        if (completionData.percentage >= 1.0) {
          return const SizedBox.shrink(); // Profile complete
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CleanTheme.primaryColor.withValues(alpha: 0.1),
                CleanTheme.accentPurple.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: CleanTheme.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Progress ring
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: completionData.percentage,
                          strokeWidth: 4,
                          backgroundColor: CleanTheme.borderPrimary,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            CleanTheme.primaryColor,
                          ),
                        ),
                        Text(
                          '${(completionData.percentage * 100).round()}%',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: CleanTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎯 Profilo ${(completionData.percentage * 100).round()}% completo',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CleanTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Completa per una scheda più precisa',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: CleanTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dismiss button
                  if (onDismiss != null)
                    GestureDetector(
                      onTap: onDismiss,
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: CleanTheme.textTertiary,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Missing items
              ...completionData.missingItems.take(2).map((item) {
                return _buildMissingItem(
                  context,
                  icon: item.icon,
                  label: item.label,
                  benefit: item.benefit,
                  onTap: item.onTap,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMissingItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String benefit,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          HapticService.lightTap();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: CleanTheme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CleanTheme.borderPrimary),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: CleanTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: CleanTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CleanTheme.textPrimary,
                      ),
                    ),
                    Text(
                      benefit,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CleanTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: CleanTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Vai',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _ProfileCompletion _calculateCompletion(dynamic user) {
    if (user == null) {
      return _ProfileCompletion(percentage: 0.0, missingItems: []);
    }

    int completed = 0;
    int total = 5;
    List<_MissingItem> missing = [];

    // Check if questionnaire is complete
    if (user.isQuestionnaireComplete == true) {
      completed++;
    } else {
      missing.add(
        _MissingItem(
          icon: Icons.quiz,
          label: 'Completa Profilo',
          benefit: 'Configura le tue preferenze',
          onTap: () {}, // Will be overridden
        ),
      );
    }

    // Check height/weight
    if (user.height != null && user.weight != null) {
      completed++;
    } else {
      missing.add(
        _MissingItem(
          icon: Icons.straighten,
          label: 'Altezza e Peso',
          benefit: 'Calcoli precisi su volume',
          onTap: () {},
        ),
      );
    }

    // Check measurements (simplified check)
    completed++; // Assume done for now

    // Check goal
    if (user.goal != null) {
      completed++;
    }

    // Check experience level
    if (user.experienceLevel != null) {
      completed++;
    }

    return _ProfileCompletion(
      percentage: total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0,
      missingItems: missing,
    );
  }
}

class _ProfileCompletion {
  final double percentage;
  final List<_MissingItem> missingItems;

  _ProfileCompletion({required this.percentage, required this.missingItems});
}

class _MissingItem {
  final IconData icon;
  final String label;
  final String benefit;
  final VoidCallback onTap;

  _MissingItem({
    required this.icon,
    required this.label,
    required this.benefit,
    required this.onTap,
  });
}

/// Compact inline version for settings/profile screen
class ProfileCompletionProgress extends StatelessWidget {
  const ProfileCompletionProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;

        // Simple calculation
        int completed = 0;
        int total = 4;

        if (user?.isQuestionnaireComplete == true) completed++;
        if (user?.height != null && user?.weight != null) completed++;
        if (user?.goal != null) completed++;
        if (user?.experienceLevel != null) completed++;

        final percentage = total > 0 ? (completed / total) : 0.0;

        if (percentage >= 1.0) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CleanTheme.accentGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: CleanTheme.accentGreen,
                ),
                const SizedBox(width: 6),
                Text(
                  'Profilo Completo',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.accentGreen,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: CleanTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 2,
                  backgroundColor: CleanTheme.borderPrimary,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    CleanTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(percentage * 100).round()}% Completo',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CleanTheme.primaryColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
