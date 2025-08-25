import '../models/symbol.dart';
import '../models/user_profile.dart'; // Import the main UserProfile class

enum SubscriptionPlan {
  free,
  monthly,
  yearly,
}

class Subscription {
  final SubscriptionPlan plan;
  final DateTime? startDate;
  final DateTime? endDate;
  final double price;
  final String currency;
  final bool isActive;
  final String? transactionId;

  const Subscription({
    required this.plan,
    this.startDate,
    this.endDate,
    required this.price,
    this.currency = 'INR',
    this.isActive = false,
    this.transactionId,
  });

  static const Map<SubscriptionPlan, double> prices = {
    SubscriptionPlan.free: 0.0,
    SubscriptionPlan.monthly: 249.0,
    SubscriptionPlan.yearly: 2499.0,
  };

  static const Map<SubscriptionPlan, String> features = {
    SubscriptionPlan.free: '• 10 custom symbols\n• Basic categories\n• Limited backup',
    SubscriptionPlan.monthly: '• Unlimited symbols\n• All categories\n• Cloud backup\n• Priority support\n• Advanced features',
    SubscriptionPlan.yearly: '• Unlimited symbols\n• All categories\n• Cloud backup\n• Priority support\n• Advanced features\n• Family sharing\n• Offline mode',
  };

  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  Duration? get remainingDuration {
    if (endDate == null) return null;
    final now = DateTime.now();
    if (now.isAfter(endDate!)) return Duration.zero;
    return endDate!.difference(now);
  }

  Map<String, dynamic> toJson() {
    return {
      'plan': plan.name,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'price': price,
      'currency': currency,
      'isActive': isActive,
      'transactionId': transactionId,
    };
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      plan: SubscriptionPlan.values.firstWhere(
        (e) => e.name == json['plan'],
        orElse: () => SubscriptionPlan.free,
      ),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'INR',
      isActive: json['isActive'] ?? false,
      transactionId: json['transactionId'],
    );
  }
}

enum PaymentMethod {
  upi,
  googlePay,
  phonePe,
  paytm,
  razorpay,
}

class PaymentTransaction {
  final String id;
  final PaymentMethod method;
  final double amount;
  final String currency;
  final SubscriptionPlan plan;
  final DateTime timestamp;
  final PaymentStatus status;
  final String? failureReason;

  const PaymentTransaction({
    required this.id,
    required this.method,
    required this.amount,
    this.currency = 'INR',
    required this.plan,
    required this.timestamp,
    required this.status,
    this.failureReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method.name,
      'amount': amount,
      'currency': currency,
      'plan': plan.name,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'failureReason': failureReason,
    };
  }

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'],
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => PaymentMethod.upi,
      ),
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'INR',
      plan: SubscriptionPlan.values.firstWhere(
        (e) => e.name == json['plan'],
        orElse: () => SubscriptionPlan.free,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.failed,
      ),
      failureReason: json['failureReason'],
    );
  }
}

enum PaymentStatus {
  pending,
  success,
  failed,
  cancelled,
}