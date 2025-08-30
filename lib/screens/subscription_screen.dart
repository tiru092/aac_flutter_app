import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../models/subscription.dart';
import '../utils/aac_helper.dart';
import '../services/google_play_billing_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Subscription _currentSubscription = const Subscription(
    plan: SubscriptionPlan.free,
    price: 0.0,
  );
  bool _isLoading = true;
  bool _canShowFreeTrial = false;
  List<ProductDetails> _products = [];
  
  @override
  void initState() {
    super.initState();
    _initializeBilling();
  }
  
  Future<void> _initializeBilling() async {
    try {
      await GooglePlayBillingService.initialize();
      
      final isSubscribed = await GooglePlayBillingService.isSubscribed();
      final hasTrialUsed = await GooglePlayBillingService.hasUsedFreeTrial();
      
      // Load subscription products
      final products = await GooglePlayBillingService.getSubscriptionProducts();
      
      if (mounted) {
        setState(() {
          _canShowFreeTrial = !hasTrialUsed && !isSubscribed;
          _products = List<ProductDetails>.from(products);
          
          if (isSubscribed) {
            _loadCurrentSubscription();
          }
          // Always set loading to false after initialization
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error initializing billing: $e');
      // Set loading to false even if there's an error
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadCurrentSubscription() async {
    // Load actual subscription data
    try {
      final subscriptionDetails = await GooglePlayBillingService.getSubscriptionDetails();
      if (subscriptionDetails != null && mounted) {
        final productId = subscriptionDetails['productId'];
        final isTrial = subscriptionDetails['isTrial'] ?? false;
        
        SubscriptionPlan plan;
        double price = 0.0;
        
        if (isTrial) {
          plan = SubscriptionPlan.trial;
        } else if (productId == GooglePlayBillingService.monthlyProductId) {
          plan = SubscriptionPlan.monthly;
          price = Subscription.prices[SubscriptionPlan.monthly] ?? 249.0;
        } else if (productId == GooglePlayBillingService.yearlyProductId) {
          plan = SubscriptionPlan.yearly;
          price = Subscription.prices[SubscriptionPlan.yearly] ?? 2499.0;
        } else {
          plan = SubscriptionPlan.free;
        }
        
        final expiryDateStr = subscriptionDetails['expiryDate'] as String?;
        final startDateStr = subscriptionDetails['purchaseDate'] as String?;
        
        setState(() {
          _currentSubscription = Subscription(
            plan: plan,
            price: price,
            isActive: true,
            startDate: startDateStr != null ? DateTime.parse(startDateStr) : DateTime.now(),
            endDate: expiryDateStr != null ? DateTime.parse(expiryDateStr) : DateTime.now().add(Duration(days: isTrial ? 30 : (plan == SubscriptionPlan.monthly ? 30 : 365))),
            transactionId: subscriptionDetails['transactionId'] as String?,
          );
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading subscription: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _purchaseSubscription(String productId) async {
    try {
      final success = await GooglePlayBillingService.purchaseSubscription(productId);
      if (success && mounted) {
        // Refresh subscription status
        await _loadCurrentSubscription();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscription purchased successfully!')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription purchase failed')),
        );
      }
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription purchase failed')),
        );
      }
    }
  }
  
  Future<void> _startFreeTrial() async {
    try {
      final success = await GooglePlayBillingService.startFreeTrial();
      if (success && mounted) {
        // Refresh subscription status
        await _loadCurrentSubscription();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Free trial started successfully!')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start free trial')),
        );
      }
    } catch (e) {
      debugPrint('Error starting free trial: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start free trial')),
        );
      }
    }
  }

  Future<void> _showManageSubscriptionDialog() async {
    if (!mounted) return;
    
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Manage Subscription'),
          content: const Text('You can manage your subscription, cancel auto-renewal, or restore purchases from the Google Play Store app.'),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              child: const Text('Restore Purchases'),
              onPressed: () async {
                Navigator.pop(context);
                final success = await GooglePlayBillingService.restorePurchases();
                if (success && mounted) {
                  await _loadCurrentSubscription();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Purchases restored successfully!')),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to restore purchases')),
                  );
                }
              },
            ),
            CupertinoDialogAction(
              child: const Text('Open Play Store'),
              onPressed: () {
                Navigator.pop(context);
                // In a real implementation, you would open the Play Store subscription management page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please open Google Play Store to manage your subscription')),
                );
              },
            ),
            CupertinoDialogAction(
              child: const Text('Cancel'),
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFF6C63FF),
        middle: Text(
          '💎 Premium Plans',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      child: _isLoading
          ? const Center(child: CupertinoActivityIndicator(radius: 20))
          : _currentSubscription.isPremium
              ? _buildActiveSubscriptionView()
              : _buildSubscriptionPlansView(),
    );
  }
  
  Widget _buildActiveSubscriptionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Icon(
              Icons.verified,
              size: 60,
              color: Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Premium Active',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _currentSubscription.displayTitle,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Benefits',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_currentSubscription.displayFeatures),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_currentSubscription.endDate != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Renews on:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${_currentSubscription.endDate!.day}/${_currentSubscription.endDate!.month}/${_currentSubscription.endDate!.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          // Show expiration warning if subscription is expiring soon
          if (_currentSubscription.endDate != null && _currentSubscription.daysRemaining <= 7)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _currentSubscription.daysRemaining <= 3 ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                border: Border.all(color: _currentSubscription.daysRemaining <= 3 ? Colors.red : Colors.orange),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _currentSubscription.daysRemaining <= 3 ? Icons.error_outline : Icons.warning_amber_outlined,
                    color: _currentSubscription.daysRemaining <= 3 ? Colors.red : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _currentSubscription.daysRemaining <= 0
                          ? 'Your subscription has expired!'
                          : 'Your subscription expires in ${_currentSubscription.daysRemaining} day${_currentSubscription.daysRemaining == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: _currentSubscription.daysRemaining <= 3 ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Center(
            child: CupertinoButton(
              onPressed: () {
                // Handle manage subscription
                _showManageSubscriptionDialog();
              },
              color: const Color(0xFF6C63FF),
              child: const Text('Manage Subscription'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubscriptionPlansView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Choose Your Plan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Unlock all premium features',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_canShowFreeTrial)
            _buildPlanCard(
              plan: SubscriptionPlan.trial,
              price: 'Free for 30 days',
              features: Subscription.features[SubscriptionPlan.trial]!,
              isRecommended: true,
              onTap: _startFreeTrial,
            ),
          const SizedBox(height: 16),
          _buildPlanCard(
            plan: SubscriptionPlan.monthly,
            price: '₹249/month',
            features: Subscription.features[SubscriptionPlan.monthly]!,
            isRecommended: false,
            onTap: () => _purchaseSubscription(GooglePlayBillingService.monthlyProductId),
          ),
          const SizedBox(height: 16),
          _buildPlanCard(
            plan: SubscriptionPlan.yearly,
            price: '₹2499/year',
            features: Subscription.features[SubscriptionPlan.yearly]!,
            isRecommended: true,
            onTap: () => _purchaseSubscription(GooglePlayBillingService.yearlyProductId),
          ),
          const SizedBox(height: 24),
          const Text(
            'All plans include:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Unlimited symbols\n'
            '• All categories\n'
            '• Cloud backup & sync\n'
            '• Advanced TTS voices\n'
            '• Unlimited voice recordings\n'
            '• Priority support',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'By subscribing, you agree to our Terms of Service and Privacy Policy. Subscription renews automatically until canceled.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlanCard({
    required SubscriptionPlan plan,
    required String price,
    required String features,
    required bool isRecommended,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRecommended ? const Color(0xFF6C63FF) : Colors.grey.shade300,
          width: isRecommended ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFF6C63FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: const Center(
                child: Text(
                  'RECOMMENDED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Subscription.planTitles[plan]!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Subscription.planDescriptions[plan]!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isRecommended ? const Color(0xFF6C63FF) : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  features,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    onPressed: onTap,
                    color: isRecommended ? const Color(0xFF6C63FF) : Colors.grey.shade300,
                    child: Text(
                      plan == SubscriptionPlan.trial ? 'Start Free Trial' : 'Subscribe',
                      style: TextStyle(
                        color: isRecommended ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
