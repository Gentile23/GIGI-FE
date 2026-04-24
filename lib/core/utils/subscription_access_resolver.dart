import '../../data/models/quota_status_model.dart';
import '../../data/models/user_model.dart';
import '../constants/subscription_tiers.dart';
import '../services/payment_service.dart';

class EffectiveSubscriptionAccess {
  final SubscriptionTier tier;
  final bool hasBackendPremium;
  final bool hasRevenueCatPremium;
  final bool hasQuotaPremium;

  const EffectiveSubscriptionAccess({
    required this.tier,
    required this.hasBackendPremium,
    required this.hasRevenueCatPremium,
    required this.hasQuotaPremium,
  });

  bool get hasPremiumAccess =>
      hasBackendPremium || hasRevenueCatPremium || hasQuotaPremium;

  bool get isSyncPending =>
      !hasBackendPremium && (hasRevenueCatPremium || hasQuotaPremium);
}

class SubscriptionAccessResolver {
  static EffectiveSubscriptionAccess resolve({
    required UserModel? user,
    required PaymentService paymentService,
    required QuotaStatus? quotaStatus,
  }) {
    final backendTier = user?.subscription?.tier ?? SubscriptionTier.free;
    final backendPremium = user?.subscription?.isActive ?? false;
    final revenueCatTier = paymentService.currentPlan;
    final revenueCatPremium = paymentService.isProOrAbove;
    final quotaTier = _quotaTier(quotaStatus);
    final quotaPremium = quotaStatus?.isPremium ?? false;

    final effectiveTier = [
      backendTier,
      revenueCatTier,
      quotaTier,
    ].reduce(_higherTier);

    return EffectiveSubscriptionAccess(
      tier: effectiveTier,
      hasBackendPremium: backendPremium,
      hasRevenueCatPremium: revenueCatPremium,
      hasQuotaPremium: quotaPremium,
    );
  }

  static SubscriptionTier _quotaTier(QuotaStatus? quotaStatus) {
    if (quotaStatus == null) return SubscriptionTier.free;
    if (quotaStatus.isElite) return SubscriptionTier.elite;
    if (quotaStatus.isPro) return SubscriptionTier.pro;
    return SubscriptionTier.free;
  }

  static SubscriptionTier _higherTier(
    SubscriptionTier left,
    SubscriptionTier right,
  ) {
    return _tierWeight(left) >= _tierWeight(right) ? left : right;
  }

  static int _tierWeight(SubscriptionTier tier) {
    return switch (tier) {
      SubscriptionTier.free => 0,
      SubscriptionTier.pro => 1,
      SubscriptionTier.elite => 2,
    };
  }
}
