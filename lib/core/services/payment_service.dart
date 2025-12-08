import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════
/// PAYMENT SERVICE - RevenueCat Integration
/// Handles subscriptions, purchases, and entitlements
/// ═══════════════════════════════════════════════════════════
///
/// To fully activate, add to pubspec.yaml:
/// dependencies:
///   purchases_flutter: ^6.0.0
///
/// Then configure:
/// 1. RevenueCat dashboard: https://app.revenuecat.com
/// 2. App Store Connect in-app purchases
/// 3. Google Play Console subscriptions

enum SubscriptionPlan { free, premium, gold, platinum }

enum PurchaseStatus { idle, loading, success, error, cancelled }

class ProductInfo {
  final String identifier;
  final String title;
  final String description;
  final double price;
  final String priceString;
  final String currencyCode;
  final bool isSubscription;
  final String? introductoryPrice;
  final String? trialDuration;

  const ProductInfo({
    required this.identifier,
    required this.title,
    required this.description,
    required this.price,
    required this.priceString,
    required this.currencyCode,
    this.isSubscription = true,
    this.introductoryPrice,
    this.trialDuration,
  });

  // GIGI product identifiers (configure in RevenueCat)
  static const String premiumMonthly = 'gigi_premium_monthly';
  static const String premiumYearly = 'gigi_premium_yearly';
  static const String goldMonthly = 'gigi_gold_monthly';
  static const String goldYearly = 'gigi_gold_yearly';
  static const String platinumMonthly = 'gigi_platinum_monthly';
  static const String platinumYearly = 'gigi_platinum_yearly';
  static const String lifetime = 'gigi_lifetime';
}

class PaymentService extends ChangeNotifier {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  bool _isInitialized = false;
  SubscriptionPlan _currentPlan = SubscriptionPlan.free;
  PurchaseStatus _purchaseStatus = PurchaseStatus.idle;
  String? _errorMessage;
  List<ProductInfo> _availableProducts = [];
  DateTime? _expirationDate;
  bool _isTrialActive = false;

  // Getters
  SubscriptionPlan get currentPlan => _currentPlan;
  PurchaseStatus get purchaseStatus => _purchaseStatus;
  String? get errorMessage => _errorMessage;
  List<ProductInfo> get availableProducts => _availableProducts;
  DateTime? get expirationDate => _expirationDate;
  bool get isTrialActive => _isTrialActive;
  bool get isPremium => _currentPlan != SubscriptionPlan.free;
  bool get isGoldOrAbove =>
      _currentPlan == SubscriptionPlan.gold ||
      _currentPlan == SubscriptionPlan.platinum;
  bool get isPlatinum => _currentPlan == SubscriptionPlan.platinum;

  /// Initialize RevenueCat
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // In production:
      // await Purchases.setDebugLogsEnabled(kDebugMode);
      //
      // if (Platform.isIOS) {
      //   await Purchases.configure(
      //     PurchasesConfiguration('appl_YOUR_IOS_API_KEY')
      //   );
      // } else if (Platform.isAndroid) {
      //   await Purchases.configure(
      //     PurchasesConfiguration('goog_YOUR_ANDROID_API_KEY')
      //   );
      // }
      //
      // // Listen to customer info updates
      // Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
      //
      // // Get initial customer info
      // final customerInfo = await Purchases.getCustomerInfo();
      // _updateFromCustomerInfo(customerInfo);
      //
      // // Fetch offerings
      // await _fetchProducts();

      // Mock initialization
      _isInitialized = true;
      _loadMockProducts();

      debugPrint('PaymentService initialized');
    } catch (e) {
      debugPrint('Failed to initialize PaymentService: $e');
    }
  }

  /// Load mock products for development
  void _loadMockProducts() {
    _availableProducts = [
      const ProductInfo(
        identifier: ProductInfo.premiumMonthly,
        title: 'Premium Mensile',
        description: 'AI Coach + Voice Coaching',
        price: 9.99,
        priceString: '€9,99',
        currencyCode: 'EUR',
        trialDuration: '7 giorni gratis',
      ),
      const ProductInfo(
        identifier: ProductInfo.premiumYearly,
        title: 'Premium Annuale',
        description: 'Risparmia 58%!',
        price: 49.99,
        priceString: '€49,99',
        currencyCode: 'EUR',
        introductoryPrice: '€4,17/mese',
        trialDuration: '7 giorni gratis',
      ),
      const ProductInfo(
        identifier: ProductInfo.goldMonthly,
        title: 'Gold Mensile',
        description: 'Premium + Nutrition + Form Check',
        price: 14.99,
        priceString: '€14,99',
        currencyCode: 'EUR',
        trialDuration: '7 giorni gratis',
      ),
      const ProductInfo(
        identifier: ProductInfo.goldYearly,
        title: 'Gold Annuale',
        description: 'Risparmia 61%!',
        price: 69.99,
        priceString: '€69,99',
        currencyCode: 'EUR',
        introductoryPrice: '€5,83/mese',
        trialDuration: '7 giorni gratis',
      ),
      const ProductInfo(
        identifier: ProductInfo.platinumMonthly,
        title: 'Platinum Mensile',
        description: 'Tutte le funzionalità + Priority Support',
        price: 19.99,
        priceString: '€19,99',
        currencyCode: 'EUR',
      ),
      const ProductInfo(
        identifier: ProductInfo.platinumYearly,
        title: 'Platinum Annuale',
        description: 'Risparmia 58%!',
        price: 99.99,
        priceString: '€99,99',
        currencyCode: 'EUR',
        introductoryPrice: '€8,33/mese',
      ),
      const ProductInfo(
        identifier: ProductInfo.lifetime,
        title: 'Lifetime',
        description: 'Paga una volta, usa per sempre',
        price: 199.99,
        priceString: '€199,99',
        currencyCode: 'EUR',
        isSubscription: false,
      ),
    ];
  }

  /// Purchase a product
  Future<bool> purchaseProduct(String productId) async {
    _purchaseStatus = PurchaseStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // In production:
      // final offerings = await Purchases.getOfferings();
      // final package = offerings.current?.availablePackages
      //     .firstWhere((p) => p.storeProduct.identifier == productId);
      //
      // if (package == null) {
      //   throw Exception('Product not found');
      // }
      //
      // final customerInfo = await Purchases.purchasePackage(package);
      // _updateFromCustomerInfo(customerInfo);

      // Mock successful purchase
      await Future.delayed(const Duration(seconds: 2));

      // Determine plan based on product
      if (productId.contains('platinum')) {
        _currentPlan = SubscriptionPlan.platinum;
      } else if (productId.contains('gold')) {
        _currentPlan = SubscriptionPlan.gold;
      } else if (productId.contains('premium')) {
        _currentPlan = SubscriptionPlan.premium;
      }

      _expirationDate = DateTime.now().add(
        productId.contains('yearly')
            ? const Duration(days: 365)
            : const Duration(days: 30),
      );

      _purchaseStatus = PurchaseStatus.success;
      notifyListeners();

      debugPrint('Purchase successful: $productId');
      return true;
    } catch (e) {
      _purchaseStatus = PurchaseStatus.error;
      _errorMessage = _translateError(e.toString());
      notifyListeners();

      debugPrint('Purchase failed: $e');
      return false;
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    _purchaseStatus = PurchaseStatus.loading;
    notifyListeners();

    try {
      // In production:
      // final customerInfo = await Purchases.restorePurchases();
      // _updateFromCustomerInfo(customerInfo);

      await Future.delayed(const Duration(seconds: 1));

      _purchaseStatus = PurchaseStatus.success;
      notifyListeners();

      debugPrint('Restore completed');
      return true;
    } catch (e) {
      _purchaseStatus = PurchaseStatus.error;
      _errorMessage = 'Impossibile ripristinare gli acquisti';
      notifyListeners();
      return false;
    }
  }

  /// Check if user has access to a feature
  bool hasAccess(String featureId) {
    switch (featureId) {
      case 'voice_coaching':
      case 'unlimited_workouts':
        return isPremium;
      case 'nutrition_ai':
      case 'form_check':
        return isGoldOrAbove;
      case 'priority_support':
      case 'advanced_analytics':
        return isPlatinum;
      default:
        return false;
    }
  }

  /// Start free trial
  Future<void> startFreeTrial(String productId) async {
    // In production, this would trigger the purchase flow
    // with a free trial attached
    _isTrialActive = true;
    _expirationDate = DateTime.now().add(const Duration(days: 7));
    notifyListeners();
  }

  /// Get formatted expiration date
  String get formattedExpirationDate {
    if (_expirationDate == null) return 'N/A';
    return '${_expirationDate!.day}/${_expirationDate!.month}/${_expirationDate!.year}';
  }

  /// Get days until expiration
  int? get daysUntilExpiration {
    if (_expirationDate == null) return null;
    return _expirationDate!.difference(DateTime.now()).inDays;
  }

  String _translateError(String error) {
    if (error.contains('cancelled')) {
      return 'Acquisto annullato';
    } else if (error.contains('network')) {
      return 'Errore di rete. Riprova.';
    } else if (error.contains('already_purchased')) {
      return 'Prodotto già acquistato';
    }
    return 'Si è verificato un errore. Riprova.';
  }

  /// Identify user for RevenueCat (call after login)
  Future<void> identifyUser(String userId) async {
    // In production:
    // await Purchases.logIn(userId);
    debugPrint('User identified: $userId');
  }

  /// Logout from RevenueCat
  Future<void> logout() async {
    // In production:
    // await Purchases.logOut();
    _currentPlan = SubscriptionPlan.free;
    _expirationDate = null;
    _isTrialActive = false;
    notifyListeners();
  }

  /// Check subscription status
  Future<void> checkSubscriptionStatus() async {
    // In production:
    // final customerInfo = await Purchases.getCustomerInfo();
    // _updateFromCustomerInfo(customerInfo);
  }

  // void _updateFromCustomerInfo(CustomerInfo info) {
  //   if (info.entitlements.active.containsKey('platinum')) {
  //     _currentPlan = SubscriptionPlan.platinum;
  //   } else if (info.entitlements.active.containsKey('gold')) {
  //     _currentPlan = SubscriptionPlan.gold;
  //   } else if (info.entitlements.active.containsKey('premium')) {
  //     _currentPlan = SubscriptionPlan.premium;
  //   } else {
  //     _currentPlan = SubscriptionPlan.free;
  //   }
  //
  //   final activeSubscription = info.activeSubscriptions.firstOrNull;
  //   if (activeSubscription != null) {
  //     _expirationDate = info.allExpirationDates[activeSubscription];
  //   }
  //
  //   notifyListeners();
  // }
}

/// ═══════════════════════════════════════════════════════════
/// PAYWALL TRIGGER SERVICE
/// Strategically trigger paywall at optimal moments
/// ═══════════════════════════════════════════════════════════

class PaywallTriggerService {
  static final PaywallTriggerService _instance =
      PaywallTriggerService._internal();
  factory PaywallTriggerService() => _instance;
  PaywallTriggerService._internal();

  int _workoutsCompleted = 0;
  int _formChecksUsed = 0;
  bool _hasSeenVoiceCoaching = false;

  /// Call after completing a workout
  bool shouldShowPaywallAfterWorkout() {
    _workoutsCompleted++;

    // Show paywall after 3rd workout (high engagement moment)
    if (_workoutsCompleted == 3) {
      return true;
    }

    // Show every 10 workouts after that
    if (_workoutsCompleted > 3 && _workoutsCompleted % 10 == 0) {
      return true;
    }

    return false;
  }

  /// Call when voice coaching is played
  bool shouldShowPaywallAfterVoiceCoaching() {
    if (!_hasSeenVoiceCoaching) {
      _hasSeenVoiceCoaching = true;
      return true; // First time = wow moment
    }
    return false;
  }

  /// Call when streak is at risk
  bool shouldShowPaywallForStreakProtection(int currentStreak) {
    // Show streak protection paywall for streaks >= 7 days
    return currentStreak >= 7;
  }

  /// Call when form check is requested
  bool shouldShowPaywallForFormCheck() {
    _formChecksUsed++;

    // Allow 1 free form check, then show paywall
    return _formChecksUsed > 1;
  }

  /// Call when premium badge is encountered
  bool shouldShowPaywallForPremiumBadge() {
    return true; // Always show for premium badges
  }

  /// Get trigger reason for analytics
  String getTriggerReason(PaywallTrigger trigger) {
    switch (trigger) {
      case PaywallTrigger.workout3:
        return 'after_3rd_workout';
      case PaywallTrigger.voiceCoaching:
        return 'voice_coaching_wow';
      case PaywallTrigger.streakProtection:
        return 'streak_protection';
      case PaywallTrigger.formCheck:
        return 'form_check_limit';
      case PaywallTrigger.premiumBadge:
        return 'premium_badge';
      case PaywallTrigger.manual:
        return 'user_initiated';
    }
  }
}

enum PaywallTrigger {
  workout3,
  voiceCoaching,
  streakProtection,
  formCheck,
  premiumBadge,
  manual,
}
