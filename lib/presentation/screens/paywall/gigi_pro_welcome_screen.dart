import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';

class GigiProWelcomeScreen extends StatelessWidget {
  const GigiProWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [CleanTheme.primaryColor, CleanTheme.accentGold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CleanTheme.primaryColor.withValues(alpha: 0.28),
                      blurRadius: 34,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 46,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Benvenuto in GIGI Pro',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: CleanTheme.textPrimary,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Il tuo coach AI e attivo. Da ora GIGI puo seguirti con allenamenti, nutrizione e feedback piu completi.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: CleanTheme.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              _BenefitRow(
                icon: Icons.record_voice_over_rounded,
                title: 'Coaching vocale realtime',
                subtitle: 'Indicazioni durante i workout e supporto sui set.',
              ),
              _BenefitRow(
                icon: Icons.fitness_center_rounded,
                title: 'Piani che evolvono con te',
                subtitle: 'Progressioni e limiti Pro per allenarti meglio.',
              ),
              _BenefitRow(
                icon: Icons.auto_awesome_rounded,
                title: 'AI fitness e nutrizione',
                subtitle: 'Form check, ricette, swap e strumenti avanzati.',
              ),
              const Spacer(),
              CleanButton(
                text: 'Inizia con GIGI Pro',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                width: double.infinity,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(
                  'Chiudi',
                  style: GoogleFonts.inter(
                    color: CleanTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CleanTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: CleanTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CleanTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CleanTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
