import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import '../services/subscription_service.dart';
import '../utils/aac_helper.dart';

class EnhancedSubscriptionScreen extends StatefulWidget {
  const EnhancedSubscriptionScreen({super.key});

  @override
  State<EnhancedSubscriptionScreen> createState() => _EnhancedSubscriptionScreenState();
}

class _EnhancedSubscriptionScreenState extends State<EnhancedSubscriptionScreen> {
  SubscriptionStatus? _subscriptionStatus;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      final status = await SubscriptionService.getSubscriptionStatus();
      setState(() {
        _subscriptionStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CupertinoPageScaffold(
        child: Center(
          child: CupertinoActivityIndicator(radius: 20),
        ),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF6C63FF),
        middle: const Text(
          '💎 Subscription',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.back,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF6C63FF).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Status Card
                _buildCurrentStatusCard(),
                
                const SizedBox(height: 24),
                
                // Free Trial Offer (if eligible)
                if (_subscriptionStatus?.canStartTrial == true)
                  _buildFreeTrialOffer(),
                
                // Plan Selection
                if (!(_subscriptionStatus?.isPremium == true))
                  _buildPlanSelection(),
                
                const SizedBox(height: 24),
                
                // Features Comparison
                _buildFeaturesComparison(),
                
                const SizedBox(height: 24),
                
                // Payment Methods
                _buildPaymentMethods(),
                
                const SizedBox(height: 24),
                
                // FAQ
                _buildFAQ(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    final status = _subscriptionStatus!;
    final subscription = status.subscription;
    
    Color cardColor;
    IconData cardIcon;
    String statusText;
    String detailText;
    
    if (status.isTrial) {
      cardColor = const Color(0xFF4ECDC4);
      cardIcon = CupertinoIcons.gift;
      statusText = '🎉 Free Trial Active';
      detailText = '${status.daysRemaining} days remaining';
    } else if (status.isPremium) {
      cardColor = const Color(0xFF6C63FF);
      cardIcon = CupertinoIcons.star_fill;
      statusText = '⭐ Premium Active';
      detailText = subscription?.plan == SubscriptionPlan.yearly 
          ? 'Yearly subscription' 
          : 'Monthly subscription';
    } else {
      cardColor = Colors.grey.shade600;
      cardIcon = CupertinoIcons.person;
      statusText = 'Free Plan';
      detailText = status.canStartTrial 
          ? 'Start your free trial today!' 
          : 'Upgrade to unlock premium features';
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor, cardColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  cardIcon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      detailText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (status.isTrial && status.daysRemaining <= 7) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your trial expires soon. Subscribe now to continue enjoying premium features!',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (subscription?.endDate != null) ...[
            const SizedBox(height: 12),
            Text(
              'Expires: ${_formatDate(subscription!.endDate!)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFreeTrialOffer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4ECDC4)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.gift_fill,
                color: Colors.white,
                size: 32,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎉 Start Your Free Trial',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '30 days of premium features, absolutely free!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '✨ Unlimited symbols & categories\n☁️ Cloud backup & sync\n🎙️ Advanced voice features\n👨‍👩‍👧‍👦 Family sharing\n🆘 Priority support',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              onPressed: _isProcessing ? null : _startFreeTrial,
              child: _isProcessing
                  ? const CupertinoActivityIndicator(color: Color(0xFF6C63FF))
                  : const Text(
                      'Start Free Trial',
                      style: TextStyle(
                        color: Color(0xFF6C63FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          const Text(
            'No payment required • Cancel anytime',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '✨ Choose Your Plan',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Unlock the full potential of AAC communication',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 16),
        
        // Monthly Plan
        _buildPlanCard(SubscriptionPlan.monthly),
        
        const SizedBox(height: 16),
        
        // Yearly Plan (Most Popular)
        _buildPlanCard(SubscriptionPlan.yearly),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isCurrentPlan = _subscriptionStatus?.plan == plan;
    final subscription = Subscription(plan: plan, price: Subscription.prices[plan]!);
    final isPopular = plan == SubscriptionPlan.yearly;
    
    Color primaryColor = plan == SubscriptionPlan.monthly 
        ? const Color(0xFF6C63FF) 
        : const Color(0xFF4ECDC4);
    
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCurrentPlan ? primaryColor : Colors.grey.shade300,
              width: isCurrentPlan ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                        subscription.displayTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subscription.displayPrice,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      if (plan == SubscriptionPlan.yearly)
                        const Text(
                          'Save ₹1,489!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF38A169),
                          ),
                        ),
                    ],
                  ),
                  
                  if (isCurrentPlan)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Current',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Text(
                subscription.displayDescription,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                subscription.displayFeatures,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 20),
              
              if (!isCurrentPlan)
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: _isProcessing ? null : () => _subscribeToPlan(plan),
                    child: _isProcessing
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : const Text(
                            'Subscribe Now',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
        
        if (isPopular)
          Positioned(
            top: -8,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B6B).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                '🔥 Most Popular',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturesComparison() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Feature Comparison',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildFeatureRow('Custom Symbols', '50', 'Unlimited'),
          _buildFeatureRow('Categories', '5', 'Unlimited'),
          _buildFeatureRow('Voice Recordings', '3', 'Unlimited'),
          _buildFeatureRow('Cloud Backup', '❌', '✅'),
          _buildFeatureRow('Family Sharing', '❌', '✅'),
          _buildFeatureRow('Priority Support', '❌', '✅'),
          _buildFeatureRow('Offline Mode', '❌', '✅'),
          _buildFeatureRow('Data Export', '❌', '✅'),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String feature, String free, String premium) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              feature,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          Expanded(
            child: Text(
              free,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              premium,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4ECDC4),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.device_phone_portrait,
                color: Color(0xFF4ECDC4),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Google Play Store Billing',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPaymentIcon('🏪', 'Google Play'),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'All subscriptions are processed securely through Google Play Store using your linked payment method.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentIcon(String emoji, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildFAQ() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.question_circle,
                color: Color(0xFF4ECDC4),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            'How does the free trial work?',
            'Start with 30 days of full premium access. No payment required upfront. Cancel anytime during the trial period.',
          ),
          _buildFAQItem(
            'Can I cancel my subscription?',
            'Yes, you can cancel anytime. Your premium features remain active until the end of your billing cycle.',
          ),
          _buildFAQItem(
            'What happens to my data if I cancel?',
            'Your data remains safe. You can continue using basic features and re-subscribe anytime to restore premium access.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startFreeTrial() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final trialSubscription = await SubscriptionService.startFreeTrial();
      
      if (trialSubscription != null) {
        await AACHelper.speak('Free trial started successfully');
        
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('🎉 Trial Started!'),
              content: const Text('Your 30-day free trial is now active. Enjoy all premium features!'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Awesome!'),
                  onPressed: () {
                    Navigator.pop(context);
                    _loadSubscriptionStatus();
                  },
                ),
              ],
            ),
          );
        }
      } else {
        _showErrorDialog('Failed to start free trial. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Error starting trial: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _subscribeToPlan(SubscriptionPlan plan) async {
    final shouldProceed = await _showGooglePlayBillingDialog();
    
    if (!shouldProceed) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final subscription = await SubscriptionService.subscribeToPlan(
        plan: plan,
      );
      
      if (subscription != null) {
        await AACHelper.speak('Subscription activated successfully');
        
        if (mounted) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('🎉 Success!'),
              content: const Text('Your subscription has been activated. Enjoy premium features!'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Great!'),
                  onPressed: () {
                    Navigator.pop(context);
                    _loadSubscriptionStatus();
                  },
                ),
              ],
            ),
          );
        }
      } else {
        _showErrorDialog('Subscription failed. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Payment failed: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<bool> _showGooglePlayBillingDialog() async {
    return await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Google Play Store'),
        content: const Column(
          children: [
            SizedBox(height: 16),
            Text('🏪', style: TextStyle(fontSize: 40)),
            SizedBox(height: 16),
            Text('This purchase will be processed through Google Play Store for secure billing and subscription management.'),
            SizedBox(height: 12),
            Text('Your payment method linked to your Google account will be used.'),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
