import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../providers/nutrition_coach_provider.dart';
import '../../widgets/animations/liquid_steel_container.dart';

class ElitePathManagementScreen extends StatelessWidget {
  const ElitePathManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NutritionCoachProvider>(
      builder: (context, provider, child) {
        final plan = provider.activePlan;
        final planName = plan?['name'] ?? 'Dieta Personalizzata';
        
        return Scaffold(
          backgroundColor: CleanTheme.chromeSubtle,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: CleanTheme.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Gestione Percorso Elite',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: CleanTheme.textPrimary,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan Summary Card
                LiquidSteelContainer(
                  borderRadius: 24,
                  enableShine: true,
                  colors: const [
                    CleanTheme.steelDark,
                    CleanTheme.steelMid,
                    CleanTheme.steelLight,
                    CleanTheme.steelMid,
                    CleanTheme.steelDark,
                  ],
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: CleanTheme.accentGreen.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.check_circle_rounded,
                                color: CleanTheme.accentGreen,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'PIANO ATTIVO',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: CleanTheme.accentGreen,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          planName,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: CleanTheme.textOnDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Analizzato con l\'AI di GiGi',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: CleanTheme.textOnDark.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  'Cosa vuoi fare?',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                _buildActionTile(
                  context: context,
                  icon: Icons.calendar_today_rounded,
                  title: 'Vedi il Piano di Oggi',
                  subtitle: 'Visualizza e modifica i pasti estratti',
                  onTap: () => Navigator.pushNamed(context, '/nutrition/coach/plan'),
                  color: CleanTheme.primaryColor,
                ),
                
                const SizedBox(height: 12),
                
                _buildActionTile(
                  context: context,
                  icon: Icons.shopping_cart_rounded,
                  title: 'Lista della Spesa',
                  subtitle: 'Prodotti necessari per il tuo piano',
                  onTap: () => Navigator.pushNamed(context, '/nutrition/coach/shopping-list'),
                  color: CleanTheme.accentGold,
                ),
                
                const SizedBox(height: 12),
                
                _buildActionTile(
                  context: context,
                  icon: Icons.refresh_rounded,
                  title: 'Carica Nuova Versione',
                  subtitle: 'Aggiorna il piano con un nuovo PDF',
                  onTap: () => Navigator.pushNamed(context, '/nutrition/coach/upload'),
                  color: CleanTheme.accentBlue,
                ),
                
                const SizedBox(height: 40),
                
                // Info Box
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: CleanTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CleanTheme.borderPrimary),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        color: CleanTheme.accentGold,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Percorso Elite',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CleanTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Il percorso Elite trasforma le indicazioni del tuo professionista in un assistente digitale intelligente.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: CleanTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CleanTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CleanTheme.borderPrimary),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CleanTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
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
              Icons.chevron_right_rounded,
              color: CleanTheme.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
