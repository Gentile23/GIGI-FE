import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../constants/subscription_tiers.dart';

// Use the shared enum from constants
// enum SubscriptionPlan { free, pro, elite } - Using SubscriptionTier instead

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
  // Format: subscriptionId:basePlanId
  static const String proMonthly = 'gigi_pro_monthly:pro-monthly-base';
  static const String proYearly = 'gigi_pro_yearly:pro-yearly-base';
  static const String eliteMonthly = 'gigi_elite_monthly:elite-monthly-base';
  static const String eliteYearly = 'gigi_elite_yearly:elite-yearly-base';
}

class PaymentService extends ChangeNotifier {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  bool _isInitialized = false;
  SubscriptionTier _currentPlan = SubscriptionTier.free;
  PurchaseStatus _purchaseStatus = PurchaseStatus.idle;
  String? _errorMessage;
  List<ProductInfo> _availableProducts = [];
  DateTime? _expirationDate;
  bool _isTrialActive = false;

  // Getters
  // Getters
  SubscriptionTier get currentPlan => _currentPlan;
  PurchaseStatus get purchaseStatus => _purchaseStatus;
  String? get errorMessage => _errorMessage;
  List<ProductInfo> get availableProducts => _availableProducts;
  DateTime? get expirationDate => _expirationDate;
  bool get isTrialActive => _isTrialActive;

  bool get isProOrAbove =>
      _currentPlan == SubscriptionTier.pro ||
      _currentPlan == SubscriptionTier.elite;
  bool get isElite => _currentPlan == SubscriptionTier.elite;

  /// Initialize RevenueCat
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // In production:
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);

      if (kIsWeb) {
        debugPrint(
          'RevenueCat: RevenueCat is not supported on Web in this configuration.',
        );
        _isInitialized = true;
        return;
      }

      final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
      final isAndroid = defaultTargetPlatform == TargetPlatform.android;

      if (isIOS) {
        await Purchases.configure(
          PurchasesConfiguration('appl_nePauXVrjcKdmdldVWVmBGVLfiH'),
        );
      } else if (isAndroid) {
        await Purchases.configure(
          PurchasesConfiguration('goog_JEcfJpSFtqYfgXvLTyYPyVaJESr'),
        );
      }

      // Listen to customer info updates
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      // Get initial customer info
      final customerInfo = await Purchases.getCustomerInfo();
      _updateFromCustomerInfo(customerInfo);

      // Fetch real products from RevenueCat offerings
      await _fetchProducts();

      _isInitialized = true;

      debugPrint('PaymentService initialized');
    } catch (e) {
      debugPrint('Failed to initialize PaymentService: $e');
    }
  }

  /// Fetch products from RevenueCat Offerings
  Future<void> _fetchProducts() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        final packages = offerings.current!.availablePackages;
        _availableProducts = packages.map((package) {
          final product = package.storeProduct;
          return ProductInfo(
            identifier: product.identifier,
            title: product.title,
            description: product.description,
            price: product.price,
            priceString: product.priceString,
            currencyCode: product.currencyCode,
            trialDuration:
                product.introductoryPrice?.period, // Semplificato per ora
          );
        }).toList();

        debugPrint(
          'RevenueCat: Loaded ${_availableProducts.length} real products',
        );
        for (var p in _availableProducts) {
          debugPrint(' - Product found: ${p.identifier} (${p.priceString})');
        }
      } else {
        debugPrint('RevenueCat: No current offerings found. Check dashboard.');
        if (kDebugMode) {
          _loadMockProducts(); // Fallback to mock only for local UI development
        } else {
          _availableProducts = [];
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('RevenueCat: Error fetching products: $e');
      if (kDebugMode) {
        _loadMockProducts();
      } else {
        _availableProducts = [];
      }
    }
  }

  /// Load mock products for development
  void _loadMockProducts() {
    _availableProducts = [
      const ProductInfo(
        identifier: ProductInfo.proMonthly,
        title: 'GiGi Pro Mensile',
        description: 'Coach Vocale + AI Form Check',
        price: 14.99,
        priceString: '€14,99',
        currencyCode: 'EUR',
        trialDuration: '7 giorni gratis',
      ),
      const ProductInfo(
        identifier: ProductInfo.proYearly,
        title: 'GiGi Pro Annuale',
        description: 'Risparmia 44%!',
        price: 99.99,
        priceString: '€99,99',
        currencyCode: 'EUR',
        introductoryPrice: '€8,33/mese',
        trialDuration: '7 giorni gratis',
      ),
      // Elite removed from user-accessible purchase list as requested.
      // Elite tier remains in system for manual assignment.
    ];
  }

  /// Purchase a product
  Future<bool> purchaseProduct(String productId) async {
    _purchaseStatus = PurchaseStatus.loading;
    _errorMessage = null;
    notifyListeners();

    if (kIsWeb) {
      debugPrint(
        'RevenueCat: Purchases not supported on Web. Simulating success...',
      );
      await Future.delayed(const Duration(seconds: 1));
      _purchaseStatus = PurchaseStatus.success;
      notifyListeners();
      return true;
    }

    try {
      if (!_isInitialized) {
        await initialize();
      }

      // In production:
      final offerings = await Purchases.getOfferings();
      final package = _findPackageForProduct(productId, offerings);

      if (package == null) {
        debugPrint(
          'RevenueCat: Product $productId not found in current offerings.',
        );
        _purchaseStatus = PurchaseStatus.error;
        _errorMessage =
            'Abbonamento non disponibile in questo build. Verifica prodotto, offering e package su RevenueCat/App Store Connect.';
        notifyListeners();
        return false;
      }

      // ignore: deprecated_member_use
      final purchaseResult = await Purchases.purchasePackage(package);
      _updateFromCustomerInfo(purchaseResult.customerInfo);
      _purchaseStatus = PurchaseStatus.success;
      notifyListeners();
      debugPrint(
        'Purchase successful: ${package.storeProduct.identifier} via package ${package.identifier}',
      );
      return true;
    } on PlatformException catch (e) {
      _purchaseStatus = PurchaseStatus.error;
      _errorMessage = _translatePlatformError(e);
      notifyListeners();

      debugPrint('Purchase failed: $e');
      return false;
    } catch (e) {
      _purchaseStatus = PurchaseStatus.error;
      _errorMessage = 'Si è verificato un errore durante l\'acquisto. Riprova.';
      notifyListeners();

      debugPrint('Purchase failed: $e');
      return false;
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    _updateFromCustomerInfo(info);
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
        return isProOrAbove;
      case 'nutrition_ai':
      case 'form_check':
        return isProOrAbove; // Pro includes these now
      case 'priority_support':
      case 'advanced_analytics':
        return isElite;
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

  Package? _findPackageForProduct(String productId, Offerings offerings) {
    final current = offerings.current;
    if (current == null || current.availablePackages.isEmpty) {
      return null;
    }

    final normalizedTarget = _normalizeProductIdentifier(productId);

    for (final package in current.availablePackages) {
      final normalizedStoreId = _normalizeProductIdentifier(
        package.storeProduct.identifier,
      );

      if (package.storeProduct.identifier == productId ||
          normalizedStoreId == normalizedTarget) {
        return package;
      }
    }

    return null;
  }

  String _normalizeProductIdentifier(String productId) {
    final separatorIndex = productId.indexOf(':');
    if (separatorIndex == -1) return productId;
    return productId.substring(0, separatorIndex);
  }

  String _translatePlatformError(PlatformException error) {
    final code = PurchasesErrorHelper.getErrorCode(error);

    switch (code) {
      case PurchasesErrorCode.purchaseCancelledError:
        return 'Acquisto annullato.';
      case PurchasesErrorCode.networkError:
        return 'Errore di rete durante l\'acquisto. Riprova.';
      case PurchasesErrorCode.storeProblemError:
        return 'Lo store non riesce a completare l\'acquisto. Su TestFlight verifica anche che il prodotto sia approvato e disponibile.';
      case PurchasesErrorCode.purchaseNotAllowedError:
        return 'Questo account non puo effettuare acquisti in-app su questo dispositivo.';
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        return 'Questo abbonamento non è disponibile per l\'acquisto in questo momento.';
      case PurchasesErrorCode.configurationError:
        return 'Configurazione acquisti non valida. Controlla RevenueCat, offering e prodotti store.';
      case PurchasesErrorCode.receiptAlreadyInUseError:
        return 'L\'acquisto risulta associato a un altro account.';
      case PurchasesErrorCode.invalidReceiptError:
        return 'La ricevuta di acquisto non è valida. Riprova più tardi.';
      default:
        final message = error.message;
        if (message != null && message.trim().isNotEmpty) {
          return message;
        }
        return 'Si è verificato un errore. Riprova.';
    }
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
    _currentPlan = SubscriptionTier.free;
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

  void _updateFromCustomerInfo(CustomerInfo info) {
    if (info.entitlements.active.containsKey('elite')) {
      _currentPlan = SubscriptionTier.elite;
    } else if (info.entitlements.active.containsKey('pro')) {
      _currentPlan = SubscriptionTier.pro;
    } else {
      _currentPlan = SubscriptionTier.free;
    }

    final activeSubscription = info.activeSubscriptions.firstOrNull;
    if (activeSubscription != null && info.latestExpirationDate != null) {
      _expirationDate = DateTime.tryParse(info.latestExpirationDate!);
    }

    notifyListeners();
  }
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

  /// PROMO: Check if user should see the 7-day trial offer
  bool shouldShowTrialOffer(int workoutsCount, int activeDays) {
    // If user is already pro, don't show
    // (This check should be done outside, but good for safety)
    return (workoutsCount >= 3 || activeDays >= 3);
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
      case PaywallTrigger.specialOffer:
        return 'special_offer_trial';
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
  specialOffer,
  manual,
}
