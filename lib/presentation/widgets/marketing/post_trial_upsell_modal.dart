import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
import '../../screens/paywall/paywall_screen.dart';

/// Modal che appare dopo il completamento del primo Trial Workout
/// Offre 20% di sconto sul primo mese per massimizzare la conversione
class PostTrialUpsellModal extends StatefulWidget {
  final VoidCallback? onDismiss;
  final VoidCallback? onAccept;
  final Map<String, dynamic>?
  workoutStats; // Stats del workout appena completato

  const PostTrialUpsellModal({
    super.key,
    this.onDismiss,
    this.onAccept,
    this.workoutStats,
  });

  @override
  State<PostTrialUpsellModal> createState() => _PostTrialUpsellModalState();

  /// Mostra il modal come dialog
  static Future<void> show(
    BuildContext context, {
    Map<String, dynamic>? workoutStats,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.7),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return PostTrialUpsellModal(
          workoutStats: workoutStats,
          onDismiss: () => Navigator.pop(context),
          onAccept: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        );
      },
    );
  }
}

class _PostTrialUpsellModalState extends State<PostTrialUpsellModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.elasticOut),
    );
    _confettiController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: CleanTheme.surfaceColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: CleanTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header con gradiente
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CleanTheme.primaryColor,
                          CleanTheme.accentPurple,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Emoji celebrazione
                        const Text('🎉', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context)!.greatJob,
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.completedFirstWorkout,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Stats del workout (se disponibili)
                  if (widget.workoutStats != null) _buildWorkoutStats(),

                  // Contenuto principale
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Proposta valore
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: CleanTheme.accentGreen.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: CleanTheme.accentGreen.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: CleanTheme.accentGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.mic,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.didYouLikeGigi,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: CleanTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Sblocca il Voice Coaching in TUTTI gli allenamenti',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: CleanTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Feature bullets
                        _buildFeatureBullet(
                          Icons.auto_awesome,
                          'Piani AI illimitati',
                          'Generati su misura per te',
                        ),
                        _buildFeatureBullet(
                          Icons.videocam,
                          'AI Form Analysis',
                          'Correggi i tuoi errori',
                        ),
                        _buildFeatureBullet(
                          Icons.restaurant,
                          'Nutrition Tracking',
                          'Traccia calorie e macro',
                        ),

                        const SizedBox(height: 20),

                        // Sconto speciale
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                CleanTheme.accentOrange.withValues(alpha: 0.2),
                                CleanTheme.accentOrange.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: CleanTheme.accentOrange.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🎁', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Text(
                                '20% SCONTO',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: CleanTheme.accentOrange,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'sul primo mese',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: CleanTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // CTA principale
                        CleanButton(
                          text: 'PROVA 7 GIORNI GRATIS',
                          onPressed: widget.onAccept,
                          width: double.infinity,
                        ),

                        const SizedBox(height: 12),

                        // Link secondario
                        TextButton(
                          onPressed: widget.onDismiss,
                          child: Text(
                            'Continua gratis per ora',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: CleanTheme.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutStats() {
    final stats = widget.workoutStats!;
    return Container(
      padding: const EdgeInsets.all(16),
      color: CleanTheme.backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            '${stats['exercises'] ?? 3}',
            'Esercizi',
            Icons.fitness_center,
          ),
          _buildStatItem('${stats['duration'] ?? 5}', 'Minuti', Icons.timer),
          _buildStatItem('${stats['xp'] ?? 50}', 'XP', Icons.star),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: CleanTheme.primaryColor, size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: CleanTheme.textPrimary,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: CleanTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureBullet(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CleanTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: CleanTheme.primaryColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CleanTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: CleanTheme.accentGreen,
            size: 20,
          ),
        ],
      ),
    );
  }
}
