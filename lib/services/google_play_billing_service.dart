import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/analytics_service.dart';

/// Google Play Billing Service for handling subscription purchases
/// This service manages all interactions with Google Play Store for subscriptions
class GooglePlayBillingService {
  // Product IDs that must match Google Play Console configuration
  static const String trialProductId = 'aac_trial_subscription';
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
      
      // Calculate expiry based on product type
      String expiryDate;
      bool isTrial = false;
      
      if (purchase.productID == trialProductId) {
        // For trial, set expiry to 30 days from now
        expiryDate = DateTime.now().add(const Duration(days: 30)).toIso8601String();
        isTrial = true;
      } else if (purchase.productID == monthlyProductId) {
        // For monthly, set expiry to 30 days from now
        expiryDate = DateTime.now().add(const Duration(days: 30)).toIso8601String();
      } else if (purchase.productID == yearlyProductId) {
        // For yearly, set expiry to 365 days from now
        expiryDate = DateTime.now().add(const Duration(days: 365)).toIso8601String();
      } else {
        // Default to 30 days
        expiryDate = DateTime.now().add(const Duration(days: 30)).toIso8601String();
      }
      
      _subscriptionDetails = {
        'productId': purchase.productID,
        'expiryDate': expiryDate,
        'isTrial': isTrial,
        'transactionId': purchase.verificationData.localVerificationData,
        'purchaseDate': DateTime.now().toIso8601String(),
      };
      
      debugPrint('GooglePlayBillingService: Purchase successful for ${purchase.productID}');
      
      // Track subscription purchase in analytics
      _trackSubscriptionEvent('subscription_purchased', {
        'product_id': purchase.productID,
        'is_trial': isTrial,
        'expiry_date': expiryDate,
      });
      
      // Save subscription data to Firestore
      _saveSubscriptionData();
      
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
      // Track initialization in analytics
      _trackSubscriptionEvent('billing_initialized', {});
      return true;
    } catch (e) {
      debugPrint('GooglePlayBillingService: Initialization failed: $e');
      // Track initialization error in analytics
      _trackSubscriptionEvent('billing_initialization_failed', {
        'error': e.toString(),
      });
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
      debugPrint('GooglePlayBillingService: Requesting product IDs: [monthlyProductId: $monthlyProductId, yearlyProductId: $yearlyProductId]');
      const Set<String> productIds = {monthlyProductId, yearlyProductId};
      debugPrint('GooglePlayBillingService: Querying product details for: $productIds');
      final ProductDetailsResponse response = await _iap.queryProductDetails(productIds);
      debugPrint('GooglePlayBillingService: Received response from queryProductDetails');
      if (response.error != null) {
        debugPrint('GooglePlayBillingService: Product fetch error: ${response.error}');
        debugPrint('GooglePlayBillingService: Error code: ${response.error?.code}');
        debugPrint('GooglePlayBillingService: Error message: ${response.error?.message}');
        return [];
      }
      debugPrint('GooglePlayBillingService: Response has no error');
      debugPrint('GooglePlayBillingService: Product details count: ${response.productDetails.length}');
      for (var product in response.productDetails) {
        debugPrint('GooglePlayBillingService: Product - ID: ${product.id}, Title: ${product.title}, Price: ${product.price}');
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
      debugPrint('=== GOOGLE PLAY BILLING PURCHASE DEBUG ===');
      debugPrint('GooglePlayBillingService: Starting purchase for product: $productId');
      debugPrint('GooglePlayBillingService: Platform.isAndroid: ${Platform.isAndroid}');
      debugPrint('GooglePlayBillingService: _isInitialized: $_isInitialized');
      debugPrint('GooglePlayBillingService: _billingAvailable: $_billingAvailable');
      
      if (!_isInitialized) {
        debugPrint('GooglePlayBillingService: Not initialized, initializing...');
        final initialized = await initialize();
        debugPrint('GooglePlayBillingService: Initialization result: $initialized');
        if (!initialized) {
          debugPrint('GooglePlayBillingService: ❌ Failed to initialize billing');
          return false;
        }
      }
      
      if (!_billingAvailable) {
        debugPrint('GooglePlayBillingService: ❌ Billing not available - this is expected in debug mode');
        debugPrint('GooglePlayBillingService: 💡 To test purchases, use signed release build with Play Console setup');
        return false;
      }
      
      debugPrint('GooglePlayBillingService: Current products count: ${_products.length}');
      for (var product in _products) {
        debugPrint('GooglePlayBillingService: Available product - ID: ${product.id}, Title: ${product.title}');
      }
      if (_products.isEmpty) {
        debugPrint('GooglePlayBillingService: No products available, fetching...');
        await getSubscriptionProducts();
        debugPrint('GooglePlayBillingService: After fetching, products count: ${_products.length}');
        for (var product in _products) {
          debugPrint('GooglePlayBillingService: Available product - ID: ${product.id}, Title: ${product.title}');
        }
      }
      final product = _products.where((p) => p.id == productId).toList();
      if (product.isEmpty) {
        debugPrint('GooglePlayBillingService: ❌ Product not found: $productId');
        debugPrint('GooglePlayBillingService: Available product IDs: ${_products.map((p) => p.id).toList()}');
        debugPrint('GooglePlayBillingService: 💡 This usually means products are not configured in Google Play Console');
        return false;
      }
      debugPrint('GooglePlayBillingService: ✅ Found product: ${product.first.title} (${product.first.price})');
      final purchaseParam = PurchaseParam(productDetails: product.first);
      // For subscriptions, we use buyNonConsumable as subscriptions are non-consumable products
      debugPrint('GooglePlayBillingService: 🚀 Initiating purchase with Google Play Store...');
      final result = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      debugPrint('GooglePlayBillingService: Purchase initiated for $productId, result: $result');
      debugPrint('=== END PURCHASE DEBUG ===');
      return result;
    } catch (e) {
      debugPrint('GooglePlayBillingService: Purchase failed: $e');
      // Track purchase error in analytics
      _trackSubscriptionEvent('subscription_purchase_failed', {
        'product_id': productId,
        'error': e.toString(),
      });
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
      // Track free trial start in analytics
      _trackSubscriptionEvent('free_trial_started', {});
      return true;
    } catch (e) {
      debugPrint('GooglePlayBillingService: Free trial failed: $e');
      // Track free trial error in analytics
      _trackSubscriptionEvent('free_trial_failed', {
        'error': e.toString(),
      });
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
      // Check active purchase
      if (_activePurchase != null) {
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
      debugPrint('GooglePlayBillingService: Error checking active subscription: $e');
      return false;
    }
  }

  /// Save subscription data to Firestore
  static Future<void> _saveSubscriptionData() async {
    try {
      if (_subscriptionDetails == null) return;
      
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Save to Firestore
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('subscriptions').doc(user.uid).set({
        'userId': user.uid,
        'productId': _subscriptionDetails!['productId'],
        'purchaseDate': _subscriptionDetails!['purchaseDate'],
        'expiryDate': _subscriptionDetails!['expiryDate'],
        'isTrial': _subscriptionDetails!['isTrial'],
        'transactionId': _subscriptionDetails!['transactionId'],
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      debugPrint('GooglePlayBillingService: Subscription data saved to Firestore');
    } catch (e) {
      debugPrint('GooglePlayBillingService: Error saving subscription data: $e');
    }
  }

  /// Track subscription events in analytics
  static Future<void> _trackSubscriptionEvent(String eventName, Map<String, dynamic> properties) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final analyticsService = AnalyticsService();
      await analyticsService.logEvent(
        AnalyticsEvent(
          name: eventName,
          userId: user.uid,
          properties: {
            'timestamp': DateTime.now().toIso8601String(),
            ...properties,
          },
          priority: EventPriority.high,
        ),
      );
      
      debugPrint('GooglePlayBillingService: Tracked event $eventName');
    } catch (e) {
      debugPrint('GooglePlayBillingService: Error tracking event $eventName: $e');
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
