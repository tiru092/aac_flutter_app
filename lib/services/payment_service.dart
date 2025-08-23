import 'package:flutter/services.dart';
import '../models/subscription.dart';

class PaymentService {
  static const MethodChannel _channel = MethodChannel('aac_payment_channel');

  /// Process UPI payment
  static Future<PaymentTransaction> processUPIPayment({
    required SubscriptionPlan plan,
    required double amount,
    required String upiId,
  }) async {
    try {
      // Create UPI payment URL
      final upiUrl = _buildUPIUrl(
        upiId: upiId,
        amount: amount,
        note: 'AAC App ${plan.name} subscription',
      );

      // Launch UPI app
      await _launchUPIApp(upiUrl);

      // Return success transaction (in real implementation, you'd verify with backend)
      return PaymentTransaction(
        id: 'TXN_UPI_${DateTime.now().millisecondsSinceEpoch}',
        method: PaymentMethod.upi,
        amount: amount,
        plan: plan,
        timestamp: DateTime.now(),
        status: PaymentStatus.success,
      );
    } catch (e) {
      return PaymentTransaction(
        id: 'TXN_FAILED_${DateTime.now().millisecondsSinceEpoch}',
        method: PaymentMethod.upi,
        amount: amount,
        plan: plan,
        timestamp: DateTime.now(),
        status: PaymentStatus.failed,
        failureReason: e.toString(),
      );
    }
  }

  /// Process Google Pay payment
  static Future<PaymentTransaction> processGooglePay({
    required SubscriptionPlan plan,
    required double amount,
  }) async {
    try {
      // Google Pay integration URL scheme
      final gpayUrl = _buildGooglePayUrl(
        amount: amount,
        note: 'AAC App ${plan.name} subscription',
      );

      await _launchPaymentApp('com.google.android.apps.nbu.paisa.user', gpayUrl);

      return PaymentTransaction(
        id: 'TXN_GPAY_${DateTime.now().millisecondsSinceEpoch}',
        method: PaymentMethod.googlePay,
        amount: amount,
        plan: plan,
        timestamp: DateTime.now(),
        status: PaymentStatus.success,
      );
    } catch (e) {
      return PaymentTransaction(
        id: 'TXN_FAILED_${DateTime.now().millisecondsSinceEpoch}',
        method: PaymentMethod.googlePay,
        amount: amount,
        plan: plan,
        timestamp: DateTime.now(),
        status: PaymentStatus.failed,
        failureReason: e.toString(),
      );
    }
  }

  /// Process PhonePe payment
  static Future<PaymentTransaction> processPhonePe({
    required SubscriptionPlan plan,
    required double amount,
  }) async {
    try {
      // PhonePe integration URL scheme
      final phonepeUrl = _buildPhonePeUrl(
        amount: amount,
        note: 'AAC App ${plan.name} subscription',
      );

      await _launchPaymentApp('com.phonepe.app', phonepeUrl);

      return PaymentTransaction(
        id: 'TXN_PHONEPE_${DateTime.now().millisecondsSinceEpoch}',
        method: PaymentMethod.phonePe,
        amount: amount,
        plan: plan,
        timestamp: DateTime.now(),
        status: PaymentStatus.success,
      );
    } catch (e) {
      return PaymentTransaction(
        id: 'TXN_FAILED_${DateTime.now().millisecondsSinceEpoch}',
        method: PaymentMethod.phonePe,
        amount: amount,
        plan: plan,
        timestamp: DateTime.now(),
        status: PaymentStatus.failed,
        failureReason: e.toString(),
      );
    }
  }

  /// Build UPI URL for payment
  static String _buildUPIUrl({
    required String upiId,
    required double amount,
    required String note,
  }) {
    final merchantCode = 'AACAPP001'; // Your merchant code
    final merchantName = 'AAC Communication App';
    final transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';
    
    return 'upi://pay?pa=$upiId'
        '&pn=$merchantName'
        '&mc=$merchantCode'
        '&tid=$transactionId'
        '&tr=$transactionId'
        '&tn=$note'
        '&am=${amount.toStringAsFixed(2)}'
        '&cu=INR';
  }

  /// Build Google Pay URL
  static String _buildGooglePayUrl({
    required double amount,
    required String note,
  }) {
    final merchantUPI = 'your-merchant-upi@okaxis'; // Replace with your UPI ID
    final transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';
    
    return 'tez://upi/pay?pa=$merchantUPI'
        '&pn=AAC Communication App'
        '&tid=$transactionId'
        '&tr=$transactionId'
        '&tn=$note'
        '&am=${amount.toStringAsFixed(2)}'
        '&cu=INR';
  }

  /// Build PhonePe URL
  static String _buildPhonePeUrl({
    required double amount,
    required String note,
  }) {
    final merchantUPI = 'your-merchant-upi@ybl'; // Replace with your UPI ID
    final transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';
    
    return 'phonepe://upi/pay?pa=$merchantUPI'
        '&pn=AAC Communication App'
        '&tid=$transactionId'
        '&tr=$transactionId'
        '&tn=$note'
        '&am=${amount.toStringAsFixed(2)}'
        '&cu=INR';
  }

  /// Launch UPI app
  static Future<void> _launchUPIApp(String upiUrl) async {
    try {
      await _channel.invokeMethod('launchUPI', {'url': upiUrl});
    } catch (e) {
      throw 'Failed to launch UPI app: $e';
    }
  }

  /// Launch payment app with package name
  static Future<void> _launchPaymentApp(String packageName, String url) async {
    try {
      await _channel.invokeMethod('launchPaymentApp', {
        'packageName': packageName,
        'url': url,
      });
    } catch (e) {
      throw 'Failed to launch payment app: $e';
    }
  }

  /// Verify payment status (call your backend API)
  static Future<PaymentStatus> verifyPayment(String transactionId) async {
    try {
      // In real implementation, call your backend API to verify payment
      // For now, simulate verification
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate random success/failure for demo
      final random = DateTime.now().millisecond % 10;
      return random < 8 ? PaymentStatus.success : PaymentStatus.failed;
    } catch (e) {
      return PaymentStatus.failed;
    }
  }

  /// Get supported payment methods
  static List<PaymentMethod> getSupportedPaymentMethods() {
    return [
      PaymentMethod.upi,
      PaymentMethod.googlePay,
      PaymentMethod.phonePe,
    ];
  }

  /// Check if payment app is installed
  static Future<bool> isPaymentAppInstalled(PaymentMethod method) async {
    try {
      String packageName;
      switch (method) {
        case PaymentMethod.googlePay:
          packageName = 'com.google.android.apps.nbu.paisa.user';
          break;
        case PaymentMethod.phonePe:
          packageName = 'com.phonepe.app';
          break;
        case PaymentMethod.paytm:
          packageName = 'net.one97.paytm';
          break;
        default:
          return true; // UPI is generally supported
      }

      final isInstalled = await _channel.invokeMethod('isAppInstalled', {
        'packageName': packageName,
      });
      
      return isInstalled as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get payment method display name
  static String getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.googlePay:
        return 'Google Pay';
      case PaymentMethod.phonePe:
        return 'PhonePe';
      case PaymentMethod.paytm:
        return 'Paytm';
      case PaymentMethod.razorpay:
        return 'Razorpay';
    }
  }

  /// Get payment method icon emoji
  static String getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.upi:
        return '💳';
      case PaymentMethod.googlePay:
        return '📱';
      case PaymentMethod.phonePe:
        return '☎️';
      case PaymentMethod.paytm:
        return '💰';
      case PaymentMethod.razorpay:
        return '🏦';
    }
  }
}