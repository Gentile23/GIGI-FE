import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/subscription_tiers.dart';

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
      appBar: AppBar(title: const Text('Upgrade Your Plan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text('Unlock Your Full Potential', style: AppTextStyles.h2),
            const SizedBox(height: 8),
            Text(
              'Choose the plan that fits your fitness journey',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 32),

            // Subscription tiers
            _buildTierCard(
              tier: SubscriptionTier.free,
              name: 'Free',
              price: '€0',
              period: 'forever',
              features: [
                '1 workout plan every 2 months',
                'Basic exercise library',
                'Manual tracking',
              ],
              isPopular: false,
            ),

            const SizedBox(height: 16),

            _buildTierCard(
              tier: SubscriptionTier.premium,
              name: 'Premium',
              price: '€9.99',
              period: 'month',
              features: [
                'Unlimited workout plans',
                'AI voice coaching',
                'Advanced analytics',
                'Priority support',
              ],
              isPopular: true,
            ),

            const SizedBox(height: 16),

            _buildTierCard(
              tier: SubscriptionTier.gold,
              name: 'Gold',
              price: '€14.99',
              period: 'month',
              features: [
                'Everything in Premium',
                'Pose detection & form analysis',
                'Personalized nutrition plans',
                'Weekly coach check-ins',
              ],
              isPopular: false,
            ),

            const SizedBox(height: 16),

            _buildTierCard(
              tier: SubscriptionTier.platinum,
              name: 'Platinum',
              price: '€24.99',
              period: 'month',
              features: [
                'Everything in Gold',
                '1-on-1 video coaching sessions',
                'Custom meal planning',
                'Advanced body composition tracking',
                '24/7 priority support',
              ],
              isPopular: false,
            ),

            const SizedBox(height: 32),

            // Subscribe button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedTier == SubscriptionTier.free
                    ? null
                    : _handleSubscribe,
                child: Text(
                  _selectedTier == SubscriptionTier.free
                      ? 'Current Plan'
                      : 'Subscribe Now',
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Terms
            Text(
              'By subscribing, you agree to our Terms of Service and Privacy Policy. Subscription automatically renews unless cancelled.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
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
  }) {
    final isSelected = _selectedTier == tier;

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = tier),
      child: Stack(
        children: [
          Card(
            elevation: isSelected ? 4 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected ? AppColors.primaryNeon : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: AppTextStyles.h4),
                      if (isSelected)
                        Icon(Icons.check_circle, color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.primaryNeon,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '/$period',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...features.map((feature) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          if (isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.neonGradient,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Text(
                  'POPULAR',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.background,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleSubscribe() {
    // TODO: Implement subscription logic
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscribe'),
        content: Text(
          'You are about to subscribe to ${_getTierName(_selectedTier)}. This feature is not yet implemented.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
