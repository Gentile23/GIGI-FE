import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/clean_theme.dart';
import '../../../core/constants/subscription_tiers.dart';
import '../../widgets/clean_widgets.dart';
import 'package:gigi/l10n/app_localizations.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  SubscriptionTier _selectedTier = SubscriptionTier.pro;
  bool _isYearly = true; // Default to yearly for better conversion

  // Urgency timer - scade a mezzanotte
  late Duration _timeRemaining;

  @override
  void initState() {
    super.initState();
    _calculateTimeRemaining();
  }

  void _calculateTimeRemaining() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _timeRemaining = midnight.difference(now);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: CleanTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: CleanTheme.surfaceColor,
        elevation: 0,
        title: Text(
          l10n.paywallTitle, // 'Scegli il Piano'
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
            // Header - Emotional, benefit-focused
            Text(
              l10n.paywallSubtitle, // 'Allenati Sempre Con Un Coach'
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: CleanTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.paywallDescription, // 'GIGI ti parla mentre ti alleni...'
              style: GoogleFonts.inter(
                fontSize: 15,
                color: CleanTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 16),

            // Psychological reinforcement - connects to WOW experience
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CleanTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CleanTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: CleanTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.paywallPsychologicalFull, // 'Hai provato il coaching reale...'
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: CleanTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Urgency Timer - creates FOMO
            _buildUrgencyTimer(),

            const SizedBox(height: 16),

            // Social Proof - builds trust
            _buildSocialProof(),

            const SizedBox(height: 24),

            // Billing toggle
            _buildBillingToggle(),

            const SizedBox(height: 24),

            // Subscription tiers - PRICE ANCHORING: Elite first, Pro highlighted, Free last
            _buildTierCard(
              config: SubscriptionTierConfig.elite,
              isPopular: false,
              accentColor: CleanTheme.accentPurple,
            ),

            const SizedBox(height: 16),

            _buildTierCard(
              config: SubscriptionTierConfig.pro,
              isPopular: true,
              accentColor: CleanTheme.primaryColor,
            ),

            const SizedBox(height: 16),

            _buildTierCard(
              config: SubscriptionTierConfig.free,
              isPopular: false,
              accentColor: CleanTheme.textSecondary,
            ),

            const SizedBox(height: 32),

            // Subscribe button
            CleanButton(
              text: _selectedTier == SubscriptionTier.free
                  ? l10n.paywallCurrentPlan
                  : _isYearly
                  ? l10n.paywallSubscribeButtonYearly(
                      _getSelectedConfig().priceYearly.toStringAsFixed(2),
                    )
                  : l10n.paywallSubscribeButtonMonthly(
                      _getSelectedConfig().priceMonthly.toStringAsFixed(2),
                    ),
              onPressed: _selectedTier == SubscriptionTier.free
                  ? null
                  : _handleSubscribe,
              width: double.infinity,
            ),

            const SizedBox(height: 12),

            // Money back guarantee
            if (_selectedTier != SubscriptionTier.free)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: CleanTheme.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: CleanTheme.accentGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.paywallGuarantee, // '7 giorni di prova gratuita'
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: CleanTheme.accentGreen,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Terms
            Text(
              l10n.paywallTerms, // 'Abbonandoti accetti...'
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

  Widget _buildBillingToggle() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearly = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isYearly
                      ? CleanTheme.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.paywallBillingMonthly, // 'Mensile'
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: !_isYearly ? Colors.white : CleanTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearly = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isYearly
                      ? CleanTheme.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.paywallBillingYearly, // 'Annuale'
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isYearly
                            ? Colors.white
                            : CleanTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _isYearly
                            ? Colors.white.withValues(alpha: 0.2)
                            : CleanTheme.accentGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.paywallDiscount, // '-37%'
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _isYearly
                              ? Colors.white
                              : CleanTheme.accentGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard({
    required SubscriptionTierConfig config,
    required bool isPopular,
    required Color accentColor,
  }) {
    final isSelected = _selectedTier == config.tier;
    final price = _isYearly ? config.priceYearly : config.priceMonthly;
    final period = config.tier == SubscriptionTier.free
        ? 'sempre'
        : _isYearly
        ? 'anno'
        : 'mese';

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = config.tier),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config.name,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: CleanTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            config.tagline,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: CleanTheme.textSecondary,
                            ),
                          ),
                        ],
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
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        config.tier == SubscriptionTier.free
                            ? '€0'
                            : '€${price.toStringAsFixed(2)}',
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
                      if (_isYearly &&
                          config.tier != SubscriptionTier.free) ...[
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '€${config.effectiveMonthlyPrice.toStringAsFixed(2)}/mese',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: CleanTheme.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...config.features.take(4).map((feature) {
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
                  if (config.features.length > 4)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${config.features.length - 4} altre funzionalità',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: accentColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
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

  SubscriptionTierConfig _getSelectedConfig() {
    return SubscriptionTierConfig.fromTier(_selectedTier);
  }

  void _handleSubscribe() {
    final l10n = AppLocalizations.of(context)!;
    final config = _getSelectedConfig();
    final price = _isYearly ? config.priceYearly : config.priceMonthly;
    final period = _isYearly ? 'anno' : 'mese';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CleanTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          l10n.paywallActivateTitle(config.name),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.paywallActivateDesc(
                config.name,
                price.toStringAsFixed(2),
                period,
              ),
              style: GoogleFonts.inter(color: CleanTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.paywallRevenueCatWarning,
              style: GoogleFonts.inter(
                color: CleanTheme.accentOrange,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.paywallRevenueCatDesc,
              style: GoogleFonts.inter(
                color: CleanTheme.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
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

  Widget _buildUrgencyTimer() {
    final l10n = AppLocalizations.of(context)!;
    final hours = _timeRemaining.inHours;
    final minutes = (_timeRemaining.inMinutes % 60);
    final seconds = (_timeRemaining.inSeconds % 60);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CleanTheme.accentOrange.withValues(alpha: 0.15),
            CleanTheme.accentOrange.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CleanTheme.accentOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, color: CleanTheme.accentOrange, size: 20),
          const SizedBox(width: 8),
          Text(
            l10n.paywallUrgencyText, // 'Offerta valida ancora per '
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CleanTheme.textSecondary,
            ),
          ),
          Text(
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: CleanTheme.accentOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialProof() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Avatar stack
        SizedBox(
          width: 60,
          height: 28,
          child: Stack(
            children: [
              for (int i = 0; i < 3; i++)
                Positioned(
                  left: i * 16.0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: [
                        CleanTheme.primaryColor,
                        CleanTheme.accentPurple,
                        CleanTheme.accentGreen,
                      ][i],
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(Icons.person, color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          l10n.paywallSocialProofUsers, // '12,847 utenti '
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CleanTheme.textPrimary,
          ),
        ),
        Text(
          l10n.paywallSocialProofAction, // 'sono passati a Pro questo mese'
          style: GoogleFonts.inter(
            fontSize: 13,
            color: CleanTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
