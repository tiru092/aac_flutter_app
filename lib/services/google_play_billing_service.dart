import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Google Play Billing Service for handling subscription purchases
/// This service manages all interactions with Google Play Store for subscriptions
class GooglePlayBillingService {
  // Product IDs that must match Google Play Console configuration
  static const String monthlyProductId = 'aac_monthly_subscription';
  static const String yearlyProductId = 'aac_yearly_subscription';
  
  // Note: The actual Google Play integration will be handled at runtime
  // These are placeholder implementations that need proper in_app_purchase setup
  
  static bool _isInitialized = false;
  static bool _hasUsedFreeTrial = false;
  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  static List<ProductDetails> _products = [];
  static PurchaseDetails? _activePurchase;
  static Map<String, dynamic>? _subscriptionDetails;
  static bool _billingAvailable = false;

  static void _handlePurchaseUpdate(PurchaseDetails purchase) {
    debugPrint('GooglePlayBillingService: Purchase update: ${purchase.status}');
    if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
      _activePurchase = purchase;
      _subscriptionDetails = {
        'productId': purchase.productID,
        'expiryDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(), // Placeholder expiry
        'isTrial': false,
      };
      debugPrint('GooglePlayBillingService: Purchase successful for ${purchase.productID}');
      // Complete the purchase if pending
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    } else if (purchase.status == PurchaseStatus.error) {
      debugPrint('GooglePlayBillingService: Purchase error: ${purchase.error}');
    }
  }

  /// Initialize Google Play Billing
  static Future<bool> initialize() async {
    try {
      debugPrint('GooglePlayBillingService: Initializing...');
      if (!Platform.isAndroid) {
        debugPrint('GooglePlayBillingService: Not on Android platform');
        return false;
      }
      final available = await _iap.isAvailable();
      if (!available) {
        debugPrint('GooglePlayBillingService: Billing not available');
        _billingAvailable = false;
        return false;
      }
      _billingAvailable = true;
      // Listen for purchase updates
      _purchaseSubscription?.cancel();
      _purchaseSubscription = _iap.purchaseStream.listen((purchases) {
        for (final purchase in purchases) {
          _handlePurchaseUpdate(purchase);
        }
      });
      _isInitialized = true;
      debugPrint('GooglePlayBillingService: Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('GooglePlayBillingService: Initialization failed: $e');
      return false;
    }
  }

  /// Get available subscription products
  static Future<List<dynamic>> getSubscriptionProducts() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      // If billing is not available, return empty list
      if (!_billingAvailable) {
        debugPrint('GooglePlayBillingService: Billing not available, returning empty product list');
        return [];
      }
      debugPrint('GooglePlayBillingService: Fetching subscription products...');
      const Set<String> productIds = {monthlyProductId, yearlyProductId};
      final ProductDetailsResponse response = await _iap.queryProductDetails(productIds);
      if (response.error != null) {
        debugPrint('GooglePlayBillingService: Product fetch error: ${response.error}');
        return [];
      }
      _products = response.productDetails;
      debugPrint('GooglePlayBillingService: Products loaded: ${_products.length}');
      return _products;
    } catch (e) {
      debugPrint('GooglePlayBillingService: Error fetching products: $e');
      return [];
    }
  }

  /// Purchase a subscription
  static Future<bool> purchaseSubscription(String productId) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      debugPrint('GooglePlayBillingService: Starting purchase for $productId');
      if (_products.isEmpty) {
        await getSubscriptionProducts();
      }
      final product = _products.where((p) => p.id == productId).toList();
      if (product.isEmpty) {
        debugPrint('GooglePlayBillingService: Product not found: $productId');
        return false;
      }
      final purchaseParam = PurchaseParam(productDetails: product.first);
      final result = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      debugPrint('GooglePlayBillingService: Purchase initiated for $productId');
      return result;
    } catch (e) {
      debugPrint('GooglePlayBillingService: Purchase failed: $e');
      return false;
    }
  }

  /// Start free trial (1 month)
  static Future<bool> startFreeTrial() async {
    try {
      if (_hasUsedFreeTrial) {
        debugPrint('GooglePlayBillingService: Free trial already used');
        return false;
      }
      debugPrint('GooglePlayBillingService: Starting free trial...');
      // For trial, initiate purchase for monthly plan with trial flag
      _hasUsedFreeTrial = true;
      _subscriptionDetails = {
        'productId': monthlyProductId,
        'expiryDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'isTrial': true,
      };
      debugPrint('GooglePlayBillingService: Free trial started successfully');
      return true;
    } catch (e) {
      debugPrint('GooglePlayBillingService: Free trial failed: $e');
      return false;
    }
  }

  /// Check if user has used free trial
  static Future<bool> hasUsedFreeTrial() async {
  return _hasUsedFreeTrial;
  }

  /// Check if user has active subscription
  static Future<bool> hasActiveSubscription() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      // If billing is not available, return false
      if (!_billingAvailable) {
        debugPrint('GooglePlayBillingService: Billing not available, returning false for subscription check');
        return false;
      }
      // Check if we have an active purchase
      if (_activePurchase != null && _activePurchase!.status == PurchaseStatus.purchased) {
        return true;
      }
      // Check trial
      if (_hasUsedFreeTrial && _subscriptionDetails != null && _subscriptionDetails!['isTrial'] == true) {
        final expiry = DateTime.parse(_subscriptionDetails!['expiryDate']);
        if (DateTime.now().isBefore(expiry)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('GooglePlayBillingService: Error checking subscription: $e');
      return false;
    }
  }

  /// Restore purchases
  static Future<bool> restorePurchases() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      debugPrint('GooglePlayBillingService: Restoring purchases...');
      await _iap.restorePurchases();
      return true;
    } catch (e) {
      debugPrint('GooglePlayBillingService: Restore purchases failed: $e');
      return false;
    }
  }

  /// Check if user has active subscription (alias for hasActiveSubscription)
  static Future<bool> isSubscribed() async {
    return await hasActiveSubscription();
  }

  /// Get subscription details
  static Future<Map<String, dynamic>?> getSubscriptionDetails() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      debugPrint('GooglePlayBillingService: Getting subscription details...');
      if (_subscriptionDetails != null) {
        return _subscriptionDetails;
      }
      // If no details, try to get from active purchase
      if (_activePurchase != null) {
        return {
          'productId': _activePurchase!.productID,
          'expiryDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(), // Placeholder
          'isTrial': false,
        };
      }
      return null;
    } catch (e) {
      debugPrint('GooglePlayBillingService: Error getting subscription details: $e');
      return null;
    }
  }

  /// Dispose and cleanup
  static void dispose() {
  debugPrint('GooglePlayBillingService: Disposing...');
  _isInitialized = false;
  _purchaseSubscription?.cancel();
  }
}
