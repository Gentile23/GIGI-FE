import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/constants/subscription_tiers.dart';
import '../../widgets/clean_widgets.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  SubscriptionTier _selectedTier = SubscriptionTier.premium;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        title: Text(
          'Scegli il Piano',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: CleanIconButton(
          icon: Icons.close,
          onTap: () => Navigator.pop(context),
          hasBorder: false,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Sblocca il Tuo Potenziale',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scegli il piano perfetto per il tuo percorso fitness',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: CleanTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 32),

            // Subscription tiers
            _buildTierCard(
              tier: SubscriptionTier.free,
              name: 'Free',
              price: '€0',
              period: 'sempre',
              features: [
                '1 piano ogni 2 mesi',
                'Libreria esercizi base',
                'Tracking manuale',
              ],
              isPopular: false,
              accentColor: CleanTheme.textSecondary,
            ),

            const SizedBox(height: 16),

            _buildTierCard(
              tier: SubscriptionTier.premium,
              name: 'Premium',
              price: '€9.99',
              period: 'mese',
              features: [
                'Piani illimitati',
                'AI Voice Coaching',
                'Analytics avanzati',
                'Supporto prioritario',
              ],
              isPopular: true,
              accentColor: CleanTheme.primaryColor,
            ),

            const SizedBox(height: 16),

            _buildTierCard(
              tier: SubscriptionTier.gold,
              name: 'Gold',
              price: '€14.99',
              period: 'mese',
              features: [
                'Tutto in Premium',
                'Analisi postura AI',
                'Piani nutrizionali',
                'Check-in settimanali',
              ],
              isPopular: false,
              accentColor: CleanTheme.accentOrange,
            ),

            const SizedBox(height: 16),

            _buildTierCard(
              tier: SubscriptionTier.platinum,
              name: 'Platinum',
              price: '€24.99',
              period: 'mese',
              features: [
                'Tutto in Gold',
                'Video coaching 1-to-1',
                'Meal planning personalizzato',
                'Body composition tracking',
                'Supporto 24/7',
              ],
              isPopular: false,
              accentColor: CleanTheme.accentPurple,
            ),

            const SizedBox(height: 32),

            // Subscribe button
            CleanButton(
              text: _selectedTier == SubscriptionTier.free
                  ? 'Piano Attuale'
                  : 'Abbonati Ora',
              onPressed: _selectedTier == SubscriptionTier.free
                  ? null
                  : _handleSubscribe,
              width: double.infinity,
            ),

            const SizedBox(height: 16),

            // Terms
            Text(
              'Abbonandoti accetti i nostri Termini di Servizio e Privacy Policy. L\'abbonamento si rinnova automaticamente.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: CleanTheme.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard({
    required SubscriptionTier tier,
    required String name,
    required String price,
    required String period,
    required List<String> features,
    required bool isPopular,
    required Color accentColor,
  }) {
    final isSelected = _selectedTier == tier;

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = tier),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: CleanTheme.surfaceColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? accentColor : CleanTheme.borderPrimary,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: CleanTheme.textPrimary,
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '/$period',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: CleanTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...features.map((feature) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: CleanTheme.accentGreen.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: CleanTheme.accentGreen,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              feature,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: CleanTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          if (isPopular)
            Positioned(
              top: 0,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: CleanTheme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  'CONSIGLIATO',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleSubscribe() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Abbonamento',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        content: Text(
          'Stai per abbonarti a ${_getTierName(_selectedTier)}. Funzionalità non ancora implementata.',
          style: GoogleFonts.inter(color: CleanTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                color: CleanTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTierName(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.premium:
        return 'Premium';
      case SubscriptionTier.gold:
        return 'Gold';
      case SubscriptionTier.platinum:
        return 'Platinum';
    }
  }
}
