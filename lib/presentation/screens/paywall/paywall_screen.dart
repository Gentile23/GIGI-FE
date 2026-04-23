import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/clean_theme.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/legal_links.dart';
import '../../../core/constants/subscription_tiers.dart';
import '../../../core/services/payment_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/quota_provider.dart';
import '../../../data/models/quota_status_model.dart';
import '../../../data/services/quota_service.dart';
import '../../../data/services/subscription_sync_service.dart';
import '../../widgets/clean_widgets.dart';
import 'package:gigi/l10n/app_localizations.dart';
import 'gigi_pro_welcome_screen.dart';

class _PriceDetails {
  final String billedAmount;
  final String billedPeriod;
  final String effectiveMonthlyAmount;

  const _PriceDetails({
    required this.billedAmount,
    required this.billedPeriod,
    required this.effectiveMonthlyAmount,
  });

  String get billedLabel => '$billedAmount/$billedPeriod';
}

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  SubscriptionTier _selectedTier = SubscriptionTier.pro;
  bool _isYearly = true; // Default to yearly for better conversion
  late final QuotaService _quotaService;
  QuotaStatus? _quotaStatus;

  // Urgency timer - scade a mezzanotte
  late Duration _timeRemaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _quotaService = QuotaService();
    _calculateTimeRemaining();
    _startTimer();
    _loadQuotaStatus();
  }

  Future<void> _loadQuotaStatus() async {
    try {
      final status = await _quotaService.getQuotaStatus();
      if (!mounted) return;
      setState(() => _quotaStatus = status);
    } catch (_) {
      // Keep static fallback when backend limits are not available.
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateTimeRemaining();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateTimeRemaining() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _timeRemaining = midnight.difference(now);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final paymentService = context.watch<PaymentService>();
    final isPaidTierSelected = _selectedTier != SubscriptionTier.free;
    final isStoreUnavailable =
        paymentService.isInitialized &&
        isPaidTierSelected &&
        (_selectedStoreProductUnavailable(paymentService) ||
            !paymentService.isStoreReady);

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

            // Subscription tiers - PRICE ANCHORING: Pro emphasized
            // Elite tier removed from UI as requested (manual assignment only)
            _buildTierCard(
              config: SubscriptionTierConfig.pro,
              isPopular: true,
              accentColor: CleanTheme.primaryColor,
              paymentService: paymentService,
            ),

            const SizedBox(height: 16),

            const SizedBox(height: 16),

            _buildTierCard(
              config: SubscriptionTierConfig.free,
              isPopular: false,
              accentColor: CleanTheme.textSecondary,
              paymentService: paymentService,
            ),

            const SizedBox(height: 32),

            if (isStoreUnavailable) ...[
              _buildStoreUnavailableNotice(paymentService),
              const SizedBox(height: 16),
            ],

            // Subscribe button
            CleanButton(
              text: _selectedTier == SubscriptionTier.free
                  ? l10n.paywallCurrentPlan
                  : isStoreUnavailable
                  ? 'Abbonamenti non disponibili'
                  : 'Abbonati - ${_billedPriceLabel(_getSelectedConfig(), paymentService)}',
              onPressed: !isPaidTierSelected || isStoreUnavailable
                  ? null
                  : _handleSubscribe,
              width: double.infinity,
            ),

            const SizedBox(height: 16),

            _buildComplianceSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceSection() {
    final l10n = AppLocalizations.of(context)!;
    final selectedPeriod = _isYearly
        ? l10n.paywallBillingYearly
        : l10n.paywallBillingMonthly;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CleanTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CleanTheme.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${l10n.paywallSubscriptionLengthLabel}: $selectedPeriod',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: CleanTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.paywallAutoRenewNotice,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: CleanTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.paywallTerms,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: CleanTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => _openLegalUrl(privacyPolicyUrl),
                child: Text(l10n.privacyPolicy),
              ),
              OutlinedButton(
                onPressed: () => _openLegalUrl(appleStandardEulaUrl),
                child: Text(l10n.paywallEulaLink),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _handleRestorePurchases,
            child: Text(l10n.paywallRestorePurchases),
          ),
          Text(
            l10n.paywallManageSubscriptionHint,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: CleanTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _openManageSubscriptions,
            child: Text(l10n.paywallManageSubscription),
          ),
        ],
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
                    color: !_isYearly
                        ? CleanTheme.textOnDark
                        : CleanTheme.textSecondary,
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
                            ? CleanTheme.textOnDark
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
                            ? CleanTheme.textOnDark.withValues(alpha: 0.2)
                            : CleanTheme.accentGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '-${SubscriptionTierConfig.pro.yearlySavingsPercent}%',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _isYearly
                              ? CleanTheme.textOnDark
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
    required PaymentService paymentService,
  }) {
    final isSelected = _selectedTier == config.tier;
    final price = _priceDetails(config, paymentService);
    final period = config.tier == SubscriptionTier.free
        ? 'sempre'
        : _isYearly
        ? 'anno'
        : 'mese';

    final displayedFeatures = _resolveFeaturesForTier(config);

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = config.tier),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? CleanTheme.primaryColor.withValues(alpha: 0.02)
                  : CleanTheme.surfaceColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? accentColor : CleanTheme.borderPrimary,
                width: isSelected ? 2.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.2),
                        blurRadius: 40,
                        offset: const Offset(0, 12),
                        spreadRadius: -4,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
                            color: CleanTheme.textOnDark,
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
                            : price.billedAmount,
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
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  if (_isYearly && config.tier != SubscriptionTier.free) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${price.effectiveMonthlyAmount}/mese equivalente',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: CleanTheme.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ...displayedFeatures.map((feature) {
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
          if (isPopular && _isYearly && config.tier != SubscriptionTier.free)
            Positioned(
              top: 0,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [CleanTheme.primaryColor, CleanTheme.primaryLight],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CleanTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'PIÙ VANTAGGIOSO',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.0,
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

  Widget _buildStoreUnavailableNotice(PaymentService paymentService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CleanTheme.accentOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: CleanTheme.accentOrange.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: CleanTheme.accentOrange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              paymentService.errorMessage ??
                  'Gli abbonamenti non sono disponibili in questo momento. Riprova più tardi.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CleanTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _billedPriceLabel(
    SubscriptionTierConfig config,
    PaymentService paymentService,
  ) {
    return _priceDetails(config, paymentService).billedLabel;
  }

  _PriceDetails _priceDetails(
    SubscriptionTierConfig config,
    PaymentService paymentService,
  ) {
    final billedPeriod = _isYearly ? 'anno' : 'mese';
    final staticBilledPrice = _isYearly
        ? config.priceYearly
        : config.priceMonthly;
    final staticEffectiveMonthlyPrice = _isYearly
        ? config.effectiveMonthlyPrice
        : config.priceMonthly;

    return _PriceDetails(
      billedAmount: _formatStaticEuroPrice(staticBilledPrice),
      billedPeriod: billedPeriod,
      effectiveMonthlyAmount: _formatStaticEuroPrice(
        staticEffectiveMonthlyPrice,
      ),
    );
  }

  bool _selectedStoreProductUnavailable(PaymentService paymentService) {
    final productId = _productIdFor(_selectedTier, yearly: _isYearly);
    if (productId == null) return false;
    return paymentService.productInfoFor(productId) == null;
  }

  String? _productIdFor(SubscriptionTier tier, {required bool yearly}) {
    switch (tier) {
      case SubscriptionTier.pro:
        return yearly ? ProductInfo.proYearly : ProductInfo.proMonthly;
      case SubscriptionTier.elite:
        return yearly ? ProductInfo.eliteYearly : ProductInfo.eliteMonthly;
      case SubscriptionTier.free:
        return null;
    }
  }

  String _formatStaticEuroPrice(double price) {
    return '€${price.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  List<String> _resolveFeaturesForTier(SubscriptionTierConfig config) {
    final backendLimits = _getBackendLimitsForTier(config.tier);
    if (backendLimits == null || backendLimits.isEmpty) {
      return config.features;
    }
    return _buildFeaturesFromBackendLimits(backendLimits);
  }

  Map<String, dynamic>? _getBackendLimitsForTier(SubscriptionTier tier) {
    final quota = _quotaStatus;
    if (quota == null) return null;
    final tierKey = _tierKeyForSubscription(tier);
    return quota.limitsForTier(tierKey);
  }

  String _tierKeyForSubscription(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'free';
      case SubscriptionTier.pro:
        return 'pro';
      case SubscriptionTier.elite:
        return 'elite';
    }
  }

  List<String> _buildFeaturesFromBackendLimits(Map<String, dynamic> limits) {
    final workoutPlan = _quotaEntry(limits, 'workout_plan');
    final formAnalysis = _quotaEntry(limits, 'form_analysis');
    final mealAnalysis = _quotaEntry(limits, 'meal_analysis');
    final recipes = _quotaEntry(limits, 'recipes');
    final customWorkout = _quotaEntry(limits, 'custom_workout');
    final executeWithGigi = _quotaEntry(limits, 'execute_with_gigi');
    final shoppingList = _quotaEntry(limits, 'shopping_list');
    final changeMeal = _quotaEntry(limits, 'change_meal');
    final changeFood = _quotaEntry(limits, 'change_food');
    final foodDuel = _quotaEntry(limits, 'food_duel');
    final pdfDiet = _quotaEntry(limits, 'pdf_diet');
    final workoutChat = _quotaEntry(limits, 'workout_chat');
    final exerciseAlternatives = _quotaEntry(limits, 'exercise_alternatives');
    final similarExercises = _quotaEntry(limits, 'similar_exercises');
    final voiceCoaching =
        (limits['voice_coaching'] as Map<String, dynamic>?)?['enabled'] == true;

    return [
      _toInt(workoutPlan['interval_weeks']) == 0
          ? 'Piani workout AI. Il limite del tuo piano è illimitato'
          : 'Piani workout AI. Il limite del tuo piano è 1 ogni ${_weekLabel(_toInt(workoutPlan["interval_weeks"]))}',
      'Form Check AI. Il limite del tuo piano è ${_describeQuota(formAnalysis)}',
      'Snap & Track AI. Il limite del tuo piano è ${_describeQuota(mealAnalysis)}',
      'Chef AI. Il limite del tuo piano è ${_describeQuota(recipes)}',
      _toInt(customWorkout['limit']) == -1
          ? 'Workout custom. Il limite del tuo piano è illimitato'
          : 'Workout custom. Il limite del tuo piano è ${_toInt(customWorkout["limit"])} ogni ${_weekLabel(_toInt(customWorkout["interval_weeks"]))}',
      'Analisi PDF Dieta. Il limite del tuo piano è ${_describeQuota(pdfDiet)}',
      'Chat AI. Il limite del tuo piano è ${_describeQuota(workoutChat)}',
      'Execute con Gigi. Il limite del tuo piano è ${_describeQuota(executeWithGigi)}',
      _toInt(shoppingList['limit']) == -1
          ? 'Lista spesa AI. Il limite del tuo piano è illimitato'
          : 'Lista spesa AI. Il limite del tuo piano è ${_describeQuota(shoppingList)}',
      'Cambio pasto. Il limite del tuo piano è ${_describeQuota(changeMeal)}',
      'Smart Swap. Il limite del tuo piano è ${_describeQuota(changeFood)}',
      'Food Duel AI. Il limite del tuo piano è ${_describeQuota(foodDuel)}',
      'Unlock AI Alternatives. Il limite del tuo piano è ${_describeQuota(exerciseAlternatives)}',
      'Esercizi simili. Il limite del tuo piano è ${_describeQuota(similarExercises)}',
      voiceCoaching
          ? 'Voice Coaching realtime incluso'
          : 'Voice Coaching realtime non incluso',
    ];
  }

  Map<String, dynamic> _quotaEntry(Map<String, dynamic> limits, String key) {
    final value = limits[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  String _limitLabel(int limit) {
    if (limit == -1) return 'illimitate';
    return '$limit';
  }

  String _describeQuota(Map<String, dynamic> entry) {
    final limit = _toInt(entry['limit']);
    final period = (entry['period'] as String?) ?? '';
    final periodLabel = (entry['period_label'] as String?) ?? '';

    if (limit == -1 || period == 'unlimited') return 'illimitato';

    if (periodLabel.isNotEmpty) {
      return '$limit $periodLabel';
    }

    final suffix = switch (period) {
      'day' => 'al giorno',
      'week' => 'a settimana',
      'month' => 'al mese',
      'lifetime' => 'una tantum',
      _ => '',
    };

    return suffix.isEmpty
        ? _limitLabel(limit)
        : '${_limitLabel(limit)} $suffix';
  }

  String _weekLabel(int weeks) {
    if (weeks <= 0) return '1 settimana';
    if (weeks == 1) return '1 settimana';
    return '$weeks settimane';
  }

  Future<void> _handleSubscribe() async {
    final paymentService = Provider.of<PaymentService>(context, listen: false);
    final productId = _productIdFor(_selectedTier, yearly: _isYearly);
    if (productId == null) {
      return;
    }

    if (paymentService.isInitialized &&
        (!paymentService.isStoreReady ||
            paymentService.productInfoFor(productId) == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            paymentService.errorMessage ??
                'Abbonamento non disponibile in questo momento.',
          ),
          backgroundColor: CleanTheme.accentOrange,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: CleanTheme.primaryColor),
      ),
    );

    final success = await paymentService.purchaseProduct(productId);

    // Remove loading indicator
    if (mounted) Navigator.pop(context);

    if (success && mounted) {
      final synced = await _syncBackendAfterPurchase();
      if (!mounted) return;
      if (synced) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GigiProWelcomeScreen()),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Acquisto riuscito, ma sincronizzazione non completata. Usa Ripristina acquisti tra poco.',
          ),
          backgroundColor: CleanTheme.accentOrange,
        ),
      );
    } else if (mounted) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            paymentService.errorMessage ??
                'Errore durante l\'acquisto. Riprova.',
          ),
          backgroundColor: CleanTheme.accentRed,
        ),
      );
    }
  }

  Future<void> _handleRestorePurchases() async {
    final paymentService = Provider.of<PaymentService>(context, listen: false);
    final success = await paymentService.restorePurchases();
    if (!mounted) return;

    if (success) {
      final synced = await _syncBackendAfterPurchase();
      if (!mounted) return;
      if (synced) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GigiProWelcomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ripristino riuscito, ma sincronizzazione non completata. Riprova tra poco.',
            ),
            backgroundColor: CleanTheme.accentOrange,
          ),
        );
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Ripristino completato.'
              : (paymentService.errorMessage ?? 'Ripristino non riuscito.'),
        ),
        backgroundColor: success
            ? CleanTheme.accentGreen
            : CleanTheme.accentOrange,
      ),
    );
  }

  Future<bool> _syncBackendAfterPurchase() async {
    final syncResult = await SubscriptionSyncService().sync();
    if (!syncResult.success) {
      return false;
    }

    if (!mounted) return false;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    for (var attempt = 0; attempt < 3; attempt++) {
      await authProvider.fetchUser();
      final isActive = authProvider.user?.subscription?.isActive ?? false;
      if (isActive) {
        if (mounted) {
          await Provider.of<QuotaProvider>(
            context,
            listen: false,
          ).refresh(silent: true);
        }
        return true;
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    return false;
  }

  Future<void> _openLegalUrl(String value) async {
    final uri = Uri.parse(value);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile aprire il link.')),
      );
    }
  }

  Future<void> _openManageSubscriptions() async {
    final url = defaultTargetPlatform == TargetPlatform.iOS
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions';
    await _openLegalUrl(url);
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
                        CleanTheme.primaryLight,
                        CleanTheme.accentGreen,
                      ][i],
                      border: Border.all(
                        color: CleanTheme.surfaceColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.person,
                      color: CleanTheme.textOnDark,
                      size: 14,
                    ),
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
