import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/modern_theme.dart';
import '../../../presentation/widgets/modern_widgets.dart';
import 'trial_workout_generation_screen.dart';
import '../home/home_screen.dart';

/// Screen that appears after questionnaire completion
/// Gives users the choice to complete trial workout or skip it
class TrialWorkoutChoiceScreen extends StatelessWidget {
  const TrialWorkoutChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Quasi fatto! 🎉',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ora puoi scegliere come procedere',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 48),

              // Option 1: Complete Trial Workout (Recommended)
              _buildOptionCard(
                context: context,
                title: 'Trial Workout',
                subtitle: 'Consigliato',
                description:
                    'Completa un breve allenamento di prova per aiutarci a creare il piano perfetto per te.',
                icon: Icons.fitness_center,
                iconColor: ModernTheme.primaryColor,
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

              const SizedBox(height: 24),

              // Option 2: Skip Trial Workout
              _buildOptionCard(
                context: context,
                title: 'Salta il Trial',
                subtitle: 'Genera subito',
                description:
                    'Genera il tuo piano di allenamento direttamente, senza il trial workout.',
                icon: Icons.fast_forward,
                iconColor: Colors.orange,
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

              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Il Trial Workout richiede solo 15-20 minuti e migliora significativamente la qualità del tuo piano.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecommended
              ? ModernTheme.primaryColor.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: isRecommended ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
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
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                                color: ModernTheme.primaryColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
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
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Benefits
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
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: ModernButton(
              text: buttonText,
              onPressed: onTap,
              isPrimary: isRecommended,
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
        backgroundColor: ModernTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Text(
              'Sei sicuro?',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
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
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
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
                color: ModernTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ModernTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                '💡 Ti consigliamo vivamente di completare il Trial Workout per ottenere i migliori risultati!',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Torna Indietro',
              style: TextStyle(color: ModernTheme.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
            child: Text(
              'Salta Comunque',
              style: TextStyle(color: Colors.orange),
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
          Icon(Icons.close, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
