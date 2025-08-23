import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription.dart';
import '../utils/aac_helper.dart';
import '../services/payment_service.dart';

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
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF6C63FF),
        middle: const Text(
          '💎 Premium Plans',
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
                // Current Plan Status
                _buildCurrentPlanCard(),
                
                const SizedBox(height: 24),
                
                // Plan Selection
                _buildPlanSelectionHeader(),
                
                const SizedBox(height: 16),
                
                // Free Plan
                _buildPlanCard(SubscriptionPlan.free),
                
                const SizedBox(height: 16),
                
                // Monthly Plan
                _buildPlanCard(SubscriptionPlan.monthly),
                
                const SizedBox(height: 16),
                
                // Yearly Plan (Most Popular)
                _buildPlanCard(SubscriptionPlan.yearly),
                
                const SizedBox(height: 32),
                
                // Payment Methods
                _buildPaymentMethodsSection(),
                
                const SizedBox(height: 32),
                
                // FAQ Section
                _buildFAQSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard() {
    final isActive = _currentSubscription.isActive;
    final planName = _currentSubscription.plan.name.toUpperCase();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive 
              ? [const Color(0xFF6C63FF), const Color(0xFF4ECDC4)]
              : [Colors.grey.shade300, Colors.grey.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isActive ? const Color(0xFF6C63FF) : Colors.grey).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isActive ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.info_circle,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Current Plan: $planName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          if (_currentSubscription.plan != SubscriptionPlan.free) ...[
            Text(
              'Price: ₹${_currentSubscription.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            
            if (_currentSubscription.endDate != null)
              Text(
                'Expires: ${_formatDate(_currentSubscription.endDate!)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
          ] else
            const Text(
              'Upgrade to unlock premium features!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanSelectionHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '✨ Choose Your Plan',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Unlock the full potential of AAC communication',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final isCurrentPlan = _currentSubscription.plan == plan;
    final price = Subscription.prices[plan]!;
    final features = Subscription.features[plan]!;
    final isPopular = plan == SubscriptionPlan.yearly;
    
    Color primaryColor;
    String planTitle;
    String priceText;
    
    switch (plan) {
      case SubscriptionPlan.free:
        primaryColor = Colors.grey.shade600;
        planTitle = 'Free Plan';
        priceText = 'Free';
        break;
      case SubscriptionPlan.monthly:
        primaryColor = const Color(0xFF6C63FF);
        planTitle = 'Monthly Plan';
        priceText = '₹${price.toStringAsFixed(0)}/month';
        break;
      case SubscriptionPlan.yearly:
        primaryColor = const Color(0xFF4ECDC4);
        planTitle = 'Yearly Plan';
        priceText = '₹${price.toStringAsFixed(0)}/year';
        break;
    }
    
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
                        planTitle,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        priceText,
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
              
              // Features
              Text(
                features,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Action Button
              if (!isCurrentPlan)
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: plan == SubscriptionPlan.free 
                        ? null 
                        : () => _subscribeToPlan(plan),
                    child: _isLoading
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : Text(
                            plan == SubscriptionPlan.free 
                                ? 'Current Plan' 
                                : 'Subscribe Now',
                            style: const TextStyle(
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
        
        // Popular Badge
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

  Widget _buildPaymentMethodsSection() {
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
                CupertinoIcons.creditcard,
                color: Color(0xFF4ECDC4),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Secure Payment Methods',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Payment Method Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPaymentMethodIcon('💳', 'UPI'),
              _buildPaymentMethodIcon('📱', 'GPay'),
              _buildPaymentMethodIcon('☎️', 'PhonePe'),
              _buildPaymentMethodIcon('💰', 'Paytm'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            '• 256-bit SSL encryption\n• Secure payment gateway\n• Instant activation\n• 7-day money back guarantee',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodIcon(String emoji, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
            ),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
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

  Widget _buildFAQSection() {
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
            'Can I cancel anytime?',
            'Yes, you can cancel your subscription at any time. Your premium features will remain active until the end of your billing cycle.',
          ),
          
          _buildFAQItem(
            'Is there a family plan?',
            'The yearly plan includes family sharing, allowing up to 5 family members to use premium features.',
          ),
          
          _buildFAQItem(
            'What about refunds?',
            'We offer a 7-day money-back guarantee for all premium plans. Contact support for refund requests.',
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

  Future<void> _subscribeToPlan(SubscriptionPlan plan) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Show payment method selection
      final paymentMethod = await _showPaymentMethodSelection();
      
      if (paymentMethod != null) {
        // Process payment
        final success = await _processPayment(plan, paymentMethod);
        
        if (success) {
          setState(() {
            _currentSubscription = Subscription(
              plan: plan,
              price: Subscription.prices[plan]!,
              startDate: DateTime.now(),
              endDate: plan == SubscriptionPlan.monthly 
                  ? DateTime.now().add(const Duration(days: 30))
                  : DateTime.now().add(const Duration(days: 365)),
              isActive: true,
              transactionId: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
            );
          });
          
          await AACHelper.speak('Subscription activated successfully');
          
          _showSuccessDialog();
        }
      }
    } catch (e) {
      _showErrorDialog('Payment failed: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<PaymentMethod?> _showPaymentMethodSelection() async {
    return showCupertinoModalPopup<PaymentMethod>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Payment Method'),
        message: const Text('Choose your preferred payment method'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, PaymentMethod.upi),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('💳', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text('UPI'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, PaymentMethod.googlePay),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('📱', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text('Google Pay'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context, PaymentMethod.phonePe),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('☎️', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text('PhonePe'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<bool> _processPayment(SubscriptionPlan plan, PaymentMethod method) async {
    try {
      final amount = Subscription.prices[plan]!;
      PaymentTransaction transaction;
      
      switch (method) {
        case PaymentMethod.upi:
          transaction = await PaymentService.processUPIPayment(
            plan: plan,
            amount: amount,
            upiId: 'your-merchant-upi@okaxis', // Replace with actual UPI ID
          );
          break;
        case PaymentMethod.googlePay:
          transaction = await PaymentService.processGooglePay(
            plan: plan,
            amount: amount,
          );
          break;
        case PaymentMethod.phonePe:
          transaction = await PaymentService.processPhonePe(
            plan: plan,
            amount: amount,
          );
          break;
        default:
          throw 'Unsupported payment method';
      }
      
      // Verify payment status
      final verificationStatus = await PaymentService.verifyPayment(transaction.id);
      
      return verificationStatus == PaymentStatus.success;
    } catch (e) {
      throw 'Payment processing failed: $e';
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('🎉 Success!'),
        content: const Text('Your subscription has been activated successfully. Enjoy premium features!'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Awesome!'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Payment Failed'),
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