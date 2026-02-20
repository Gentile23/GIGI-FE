import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/clean_theme.dart';
import '../../widgets/clean_widgets.dart';
import '../../screens/paywall/paywall_screen.dart';

/// Widget che "blocca" una feature premium con un overlay elegante
/// Usato per creare soft paywalls contestuali
class PremiumGateWidget extends StatelessWidget {
  final String featureName;
  final String description;
  final IconData icon;
  final Widget? lockedPreview;
  final String ctaText;
  final VoidCallback? onUnlock;

  const PremiumGateWidget({
    super.key,
    required this.featureName,
    required this.description,
    required this.icon,
    this.lockedPreview,
    this.ctaText = 'Sblocca con Pro',
    this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Stack(
        children: [
          // Preview blurred (se fornito)
          if (lockedPreview != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ImageFiltered(
                imageFilter: const ColorFilter.mode(
                  Colors.black45,
                  BlendMode.darken,
                ),
                child: lockedPreview,
              ),
            ),

          // Contenuto gate
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icona premium
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        CleanTheme.steelDark.withValues(alpha: 0.2),
                        CleanTheme.accentGold.withValues(alpha: 0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: CleanTheme.accentGold, size: 32),
                ),

                const SizedBox(height: 16),

                // Badge PRO
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [CleanTheme.accentGold, CleanTheme.accentOrange],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'PRO',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Nome feature
                Text(
                  featureName,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: CleanTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Descrizione
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: CleanTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // CTA
                CleanButton(
                  text: ctaText,
                  onPressed:
                      onUnlock ??
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaywallScreen(),
                          ),
                        );
                      },
                  width: double.infinity,
                ),

                const SizedBox(height: 8),

                // Trial reminder
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: CleanTheme.accentGreen,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '7 giorni di prova gratuita',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CleanTheme.accentGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner premium da mostrare nella home (1 volta al giorno)
class DailyPremiumBanner extends StatefulWidget {
  final VoidCallback? onDismiss;

  const DailyPremiumBanner({super.key, this.onDismiss});

  @override
  State<DailyPremiumBanner> createState() => _DailyPremiumBannerState();

  /// Verifica se il banner deve essere mostrato oggi
  static Future<bool> shouldShowToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString('premium_banner_last_shown');

    if (lastShown == null) return true;

    final lastShownDate = DateTime.parse(lastShown);
    final today = DateTime.now();

    // Mostra se è un nuovo giorno
    return today.day != lastShownDate.day ||
        today.month != lastShownDate.month ||
        today.year != lastShownDate.year;
  }

  /// Segna il banner come mostrato oggi
  static Future<void> markAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'premium_banner_last_shown',
      DateTime.now().toIso8601String(),
    );
  }
}

class _DailyPremiumBannerState extends State<DailyPremiumBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Segna come mostrato
    DailyPremiumBanner.markAsShown();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CleanTheme.steelDark,
                CleanTheme.accentGold,
                CleanTheme.steelDark,
              ],
              stops: [0, _shimmerController.value, 1],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: CleanTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaywallScreen()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icona
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Testo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sblocca il tuo potenziale',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Voice Coach • Form Analysis • Nutrition',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // CTA
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '7gg GRATIS',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: CleanTheme.primaryColor,
                        ),
                      ),
                    ),

                    // Close button
                    if (widget.onDismiss != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: widget.onDismiss,
                        child: Icon(
                          Icons.close,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 20,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Piccolo badge "PRO" da sovrapporre alle icone delle feature premium
class ProBadge extends StatelessWidget {
  final double size;

  const ProBadge({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.3,
        vertical: size * 0.15,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [CleanTheme.accentGold, CleanTheme.accentOrange],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: CleanTheme.primaryColor.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'PRO',
        style: GoogleFonts.outfit(
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
