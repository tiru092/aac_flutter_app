import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/subscription.dart';
import '../services/google_play_billing_service.dart';

/// Service to manage subscriptions with 1-month free trial
class SubscriptionService {
  static const String _subscriptionKey = 'user_subscription';
  static const String _trialUsedKey = 'free_trial_used';
  static const String _trialStartKey = 'free_trial_start_date';
  
  /// Check if user is eligible for free trial
  static Future<bool> isEligibleForFreeTrial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trialUsed = prefs.getBool(_trialUsedKey) ?? false;
      
      // Check if user has an active subscription
      final currentSubscription = await getCurrentSubscription();
      final hasActiveSubscription = currentSubscription != null && 
          currentSubscription.plan != SubscriptionPlan.free &&
          currentSubscription.isActive && 
          !currentSubscription.isExpired;
      
      return !trialUsed && !hasActiveSubscription;
    } catch (e) {
      debugPrint('SubscriptionService: Error checking trial eligibility: $e');
      return false;
    }
  }
  
  /// Start free trial
  static Future<Subscription?> startFreeTrial() async {
    try {
      final isEligible = await isEligibleForFreeTrial();
      if (!isEligible) {
        throw Exception('User is not eligible for free trial');
      }
      
      final now = DateTime.now();
      final trialEndDate = now.add(const Duration(days: 30)); // 1 month free trial
      
      final trialSubscription = Subscription(
        plan: SubscriptionPlan.trial,
        startDate: now,
        endDate: trialEndDate,
        price: 0.0,
        isActive: true,
        transactionId: 'TRIAL_${now.millisecondsSinceEpoch}',
      );
      
      // Save trial subscription
      await _saveSubscription(trialSubscription);
      
      // Mark trial as used
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_trialUsedKey, true);
      await prefs.setString(_trialStartKey, now.toIso8601String());
      
      debugPrint('SubscriptionService: Free trial started successfully');
      return trialSubscription;
      
    } catch (e) {
      debugPrint('SubscriptionService: Error starting free trial: $e');
      return null;
    }
  }
  
  /// Get current subscription
  static Future<Subscription?> getCurrentSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subscriptionJson = prefs.getString(_subscriptionKey);
      
      if (subscriptionJson != null) {
        final subscriptionMap = jsonDecode(subscriptionJson) as Map<String, dynamic>;
        return Subscription.fromJson(subscriptionMap);
      }
      
      return null;
    } catch (e) {
      debugPrint('SubscriptionService: Error getting current subscription: $e');
      return null;
    }
  }
  
  /// Check if user has active premium subscription
  static Future<bool> hasActivePremium() async {
    try {
      final subscription = await getCurrentSubscription();
      
      if (subscription == null) return false;
      
      // Check if it's a premium plan (not free) and active
      final isPremiumPlan = subscription.plan != SubscriptionPlan.free;
      final isActive = subscription.isActive && !subscription.isExpired;
      
      return isPremiumPlan && isActive;
    } catch (e) {
      debugPrint('SubscriptionService: Error checking premium status: $e');
      return false;
    }
  }
  
  /// Get subscription status with detailed information
  static Future<SubscriptionStatus> getSubscriptionStatus() async {
    try {
      final subscription = await getCurrentSubscription();
      
      if (subscription == null) {
        final isEligibleForTrial = await isEligibleForFreeTrial();
        return SubscriptionStatus(
          plan: SubscriptionPlan.free,
          isActive: false,
          isExpired: false,
          daysRemaining: 0,
          canStartTrial: isEligibleForTrial,
          trialUsed: !isEligibleForTrial,
        );
      }
      
      final now = DateTime.now();
      final isExpired = subscription.endDate != null && now.isAfter(subscription.endDate!);
      final daysRemaining = subscription.endDate != null 
          ? subscription.endDate!.difference(now).inDays.clamp(0, double.infinity).toInt()
          : 0;
      
      final prefs = await SharedPreferences.getInstance();
      final trialUsed = prefs.getBool(_trialUsedKey) ?? false;
      
      return SubscriptionStatus(
        plan: subscription.plan,
        isActive: subscription.isActive && !isExpired,
        isExpired: isExpired,
        daysRemaining: daysRemaining,
        canStartTrial: !trialUsed && subscription.plan == SubscriptionPlan.free,
        trialUsed: trialUsed,
        subscription: subscription,
      );
    } catch (e) {
      debugPrint('SubscriptionService: Error getting subscription status: $e');
      return SubscriptionStatus(
        plan: SubscriptionPlan.free,
        isActive: false,
        isExpired: false,
        daysRemaining: 0,
        canStartTrial: false,
        trialUsed: false,
      );
    }
  }
  
  /// Subscribe to a paid plan
  static Future<Subscription?> subscribeToPlan({
    required SubscriptionPlan plan,
    String? promoCode,
  }) async {
    try {
      if (plan == SubscriptionPlan.free || plan == SubscriptionPlan.trial) {
        throw Exception('Cannot subscribe to free or trial plan');
      }
      
      // Determine Google Play product ID
      String productId;
      switch (plan) {
        case SubscriptionPlan.monthly:
          productId = GooglePlayBillingService.monthlyProductId;
          break;
        case SubscriptionPlan.yearly:
          productId = GooglePlayBillingService.yearlyProductId;
          break;
        default:
          throw Exception('Invalid subscription plan');
      }
      
      // Process payment through Google Play Billing
      final success = await GooglePlayBillingService.purchaseSubscription(productId);
      
      if (!success) {
        throw Exception('Google Play Billing purchase failed');
      }
      
      // Note: The actual subscription creation will be handled by GooglePlayBillingService
      // when the purchase is completed. This method just initiates the purchase.
      
      debugPrint('SubscriptionService: Google Play Billing purchase initiated for ${plan.name}');
      
      // Return a temporary subscription object to indicate purchase was initiated
      return Subscription(
        plan: plan,
        startDate: DateTime.now(),
        endDate: plan == SubscriptionPlan.monthly
            ? DateTime.now().add(const Duration(days: 30))
            : DateTime.now().add(const Duration(days: 365)),
        price: Subscription.prices[plan]!,
        isActive: false, // Will be activated when Google Play confirms purchase
        transactionId: 'pending_${DateTime.now().millisecondsSinceEpoch}',
      );
      
    } catch (e) {
      debugPrint('SubscriptionService: Error subscribing to plan: $e');
      return null;
    }
  }
  
  /// Cancel subscription
  static Future<bool> cancelSubscription() async {
    try {
      final currentSubscription = await getCurrentSubscription();
      
      if (currentSubscription == null || !currentSubscription.isActive) {
        throw Exception('No active subscription to cancel');
      }
      
      // Update subscription to inactive (but keep end date)
      final cancelledSubscription = Subscription(
        plan: currentSubscription.plan,
        startDate: currentSubscription.startDate,
        endDate: currentSubscription.endDate,
        price: currentSubscription.price,
        isActive: false, // Mark as inactive
        transactionId: currentSubscription.transactionId,
      );
      
      await _saveSubscription(cancelledSubscription);
      
      debugPrint('SubscriptionService: Subscription cancelled successfully');
      return true;
      
    } catch (e) {
      debugPrint('SubscriptionService: Error cancelling subscription: $e');
      return false;
    }
  }
  
  /// Restore subscription (for app reinstalls)
  static Future<Subscription?> restoreSubscription() async {
    try {
      // Use Google Play Billing to restore purchases
      await GooglePlayBillingService.initialize();
      
      // Check if user has an active subscription
      final isSubscribed = await GooglePlayBillingService.isSubscribed();
      
      if (isSubscribed) {
        // Get subscription details from Google Play Billing
        final details = await GooglePlayBillingService.getSubscriptionDetails();
        if (details != null) {
          final productId = details['productId'] as String;
          final expiryDate = DateTime.parse(details['expiryDate'] as String);
          
          SubscriptionPlan plan;
          if (productId == GooglePlayBillingService.monthlyProductId) {
            plan = SubscriptionPlan.monthly;
          } else if (productId == GooglePlayBillingService.yearlyProductId) {
            plan = SubscriptionPlan.yearly;
          } else {
            plan = SubscriptionPlan.free;
          }
          
          final subscription = Subscription(
            plan: plan,
            startDate: DateTime.now().subtract(const Duration(days: 30)), // Approximate
            endDate: expiryDate,
            price: Subscription.prices[plan]!,
            isActive: true,
            transactionId: details['purchaseId'] as String? ?? 'restored',
          );
          
          await _saveSubscription(subscription);
          debugPrint('SubscriptionService: Subscription restored successfully');
          return subscription;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('SubscriptionService: Error restoring subscription: $e');
      return null;
    }
  }
  
  /// Check if feature is available for current subscription
  static Future<bool> isFeatureAvailable(PremiumFeature feature) async {
    try {
      final hasActive = await hasActivePremium();
      
      if (!hasActive) {
        // Check if it's a free feature
        return _freeFeatures.contains(feature);
      }
      
      // All features available for premium users
      return true;
    } catch (e) {
      debugPrint('SubscriptionService: Error checking feature availability: $e');
      return false;
    }
  }
  
  /// Get feature limits for current subscription
  static Future<FeatureLimits> getFeatureLimits() async {
    try {
      final hasActive = await hasActivePremium();
      
      if (hasActive) {
        return FeatureLimits.premium();
      } else {
        return FeatureLimits.free();
      }
    } catch (e) {
      debugPrint('SubscriptionService: Error getting feature limits: $e');
      return FeatureLimits.free();
    }
  }
  
  /// Private helper methods
  static Future<void> _saveSubscription(Subscription subscription) async {
    final prefs = await SharedPreferences.getInstance();
    final subscriptionJson = jsonEncode(subscription.toJson());
    await prefs.setString(_subscriptionKey, subscriptionJson);
  }
  
  /// Free features available to all users
  static const Set<PremiumFeature> _freeFeatures = {
    PremiumFeature.basicSymbols,
    PremiumFeature.basicCategories,
    PremiumFeature.basicTTS,
    PremiumFeature.localStorage,
  };
}

/// Subscription status information
class SubscriptionStatus {
  final SubscriptionPlan plan;
  final bool isActive;
  final bool isExpired;
  final int daysRemaining;
  final bool canStartTrial;
  final bool trialUsed;
  final Subscription? subscription;
  
  const SubscriptionStatus({
    required this.plan,
    required this.isActive,
    required this.isExpired,
    required this.daysRemaining,
    required this.canStartTrial,
    required this.trialUsed,
    this.subscription,
  });
  
  bool get isPremium => plan != SubscriptionPlan.free && isActive && !isExpired;
  bool get isTrial => plan == SubscriptionPlan.trial && isActive && !isExpired;
  bool get needsUpgrade => !isPremium && !canStartTrial;
}

/// Premium features enum
enum PremiumFeature {
  basicSymbols,
  basicCategories,
  basicTTS,
  localStorage,
  unlimitedSymbols,
  customCategories,
  cloudBackup,
  voiceRecording,
  advancedTTS,
  familySharing,
  prioritySupport,
  offlineMode,
  analytics,
  exportData,
}

/// Feature limits based on subscription
class FeatureLimits {
  final int maxSymbols;
  final int maxCategories;
  final int maxVoiceRecordings;
  final bool cloudBackupEnabled;
  final bool familySharingEnabled;
  final bool prioritySupportEnabled;
  
  const FeatureLimits({
    required this.maxSymbols,
    required this.maxCategories,
    required this.maxVoiceRecordings,
    required this.cloudBackupEnabled,
    required this.familySharingEnabled,
    required this.prioritySupportEnabled,
  });
  
  factory FeatureLimits.free() => const FeatureLimits(
    maxSymbols: 50,
    maxCategories: 5,
    maxVoiceRecordings: 3,
    cloudBackupEnabled: false,
    familySharingEnabled: false,
    prioritySupportEnabled: false,
  );
  
  factory FeatureLimits.premium() => const FeatureLimits(
    maxSymbols: -1, // Unlimited
    maxCategories: -1, // Unlimited
    maxVoiceRecordings: -1, // Unlimited
    cloudBackupEnabled: true,
    familySharingEnabled: true,
    prioritySupportEnabled: true,
  );
}