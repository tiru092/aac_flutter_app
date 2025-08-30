import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      
      if (mounted) {
        setState(() {
          _canShowFreeTrial = !hasTrialUsed;
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
    // Placeholder method - in a real implementation, this would load actual subscription data
    if (mounted) {
      setState(() {
        _isLoading = false;
        // Set a sample subscription for demonstration
        _currentSubscription = const Subscription(
          plan: SubscriptionPlan.monthly,
          price: 249.0,
        );
      });
    }
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
          : const Center(child: Text('Subscription Screen - Working Version')),
    );
  }
}
