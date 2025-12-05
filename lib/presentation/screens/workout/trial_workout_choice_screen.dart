import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../presentation/widgets/clean_widgets.dart';
import 'trial_workout_generation_screen.dart';
import '../home/home_screen.dart';

class TrialWorkoutChoiceScreen extends StatelessWidget {
  const TrialWorkoutChoiceScreen({super.key});

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
              Text(
                'Quasi fatto! 🎉',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: CleanTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ora puoi scegliere come procedere',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: CleanTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              _buildOptionCard(
                context: context,
                title: 'Trial Workout',
                subtitle: 'Consigliato',
                description:
                    'Completa un breve allenamento di prova per creare il piano perfetto per te.',
                icon: Icons.fitness_center,
                iconColor: CleanTheme.primaryColor,
                benefits: [
                  'Piano personalizzato al 100%',
                  'Voice Coaching GRATIS',
                  'Esercizi adatti al tuo livello',
                  'Solo 1 serie per esercizio',
                ],
                buttonText: 'Inizia Trial Workout',
                isRecommended: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const TrialWorkoutGenerationScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              _buildOptionCard(
                context: context,
                title: 'Salta il Trial',
                subtitle: 'Genera subito',
                description:
                    'Genera il tuo piano direttamente, senza il trial workout.',
                icon: Icons.fast_forward,
                iconColor: CleanTheme.accentOrange,
                benefits: [
                  'Piano generato immediatamente',
                  'Basato sul questionario',
                  'Meno personalizzato',
                ],
                buttonText: 'Salta e Genera Piano',
                isRecommended: false,
                onTap: () => _showSkipConfirmation(context),
              ),

              const Spacer(),

              CleanCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CleanTheme.accentBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: CleanTheme.accentBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Il Trial Workout richiede solo 15-20 minuti e migliora la qualità del tuo piano.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: CleanTheme.textSecondary,
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
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color iconColor,
    required List<String> benefits,
    required String buttonText,
    required bool isRecommended,
    required VoidCallback onTap,
  }) {
    return CleanCard(
      padding: EdgeInsets.zero,
      borderColor: isRecommended ? CleanTheme.primaryColor : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: CleanTheme.textPrimary,
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: CleanTheme.primaryColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                subtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: benefits
                  .map(
                    (benefit) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: iconColor, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              benefit,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: CleanTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.all(20),
            child: CleanButton(
              text: buttonText,
              onPressed: onTap,
              isOutlined: !isRecommended,
              width: double.infinity,
            ),
          ),
        ],
      ),
    );
  }

  void _showSkipConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CleanTheme.accentOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: CleanTheme.accentOrange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sei sicuro?',
              style: GoogleFonts.outfit(
                color: CleanTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saltando il Trial Workout:',
              style: GoogleFonts.outfit(
                color: CleanTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildWarningPoint('Il piano sarà meno personalizzato'),
            _buildWarningPoint('Non potrai provare il Voice Coaching gratis'),
            _buildWarningPoint('Gli esercizi potrebbero non essere ottimali'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CleanTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '💡 Ti consigliamo vivamente di completare il Trial Workout!',
                style: GoogleFonts.inter(
                  color: CleanTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Torna Indietro',
              style: GoogleFonts.inter(
                color: CleanTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
            child: Text(
              'Salta Comunque',
              style: GoogleFonts.inter(
                color: CleanTheme.accentOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.close, color: CleanTheme.accentRed, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: CleanTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
