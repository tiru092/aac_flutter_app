enum SubscriptionPlan {
  free,
  trial,
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
    SubscriptionPlan.trial: 0.0,
    SubscriptionPlan.monthly: 249.0,
    SubscriptionPlan.yearly: 2499.0,
  };

  static const Map<SubscriptionPlan, String> features = {
    SubscriptionPlan.free: '• 50 custom symbols\n• 5 basic categories\n• Local storage only\n• Basic TTS voices\n• Limited voice recordings (3)',
    SubscriptionPlan.trial: '• 30-day FREE trial\n• Unlimited symbols\n• All categories\n• Cloud backup\n• Advanced TTS voices\n• Unlimited voice recordings\n• Priority support',
    SubscriptionPlan.monthly: '• Unlimited symbols\n• All categories\n• Cloud backup & sync\n• Advanced TTS voices\n• Unlimited voice recordings\n• Priority support\n• Family sharing\n• Export data',
    SubscriptionPlan.yearly: '• Everything in Monthly\n• Save ₹1,489 per year\n• Offline mode\n• Advanced analytics\n• Early access to features\n• Premium support\n• Multiple device sync',
  };

  static const Map<SubscriptionPlan, String> planTitles = {
    SubscriptionPlan.free: 'Free Plan',
    SubscriptionPlan.trial: '30-Day Free Trial',
    SubscriptionPlan.monthly: 'Monthly Premium',
    SubscriptionPlan.yearly: 'Yearly Premium',
  };

  static const Map<SubscriptionPlan, String> planDescriptions = {
    SubscriptionPlan.free: 'Basic features for getting started',
    SubscriptionPlan.trial: 'Try all premium features free for 30 days',
    SubscriptionPlan.monthly: 'Full access with monthly billing',
    SubscriptionPlan.yearly: 'Best value - save 58% with annual billing',
  };

  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  bool get isTrial => plan == SubscriptionPlan.trial;
  
  bool get isPremium => plan == SubscriptionPlan.monthly || plan == SubscriptionPlan.yearly || 
                       (plan == SubscriptionPlan.trial && isActive && !isExpired);

  Duration? get remainingDuration {
    if (endDate == null) return null;
    final now = DateTime.now();
    if (now.isAfter(endDate!)) return Duration.zero;
    return endDate!.difference(now);
  }

  int get daysRemaining {
    final duration = remainingDuration;
    if (duration == null) return 0;
    return duration.inDays;
  }

  String get displayPrice {
    switch (plan) {
      case SubscriptionPlan.free:
        return 'Free';
      case SubscriptionPlan.trial:
        return 'Free for 30 days';
      case SubscriptionPlan.monthly:
        return '₹${price.toStringAsFixed(0)}/month';
      case SubscriptionPlan.yearly:
        return '₹${price.toStringAsFixed(0)}/year';
    }
  }

  String get displayTitle => planTitles[plan] ?? 'Unknown Plan';
  String get displayDescription => planDescriptions[plan] ?? '';
  String get displayFeatures => features[plan] ?? '';

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

  Subscription copyWith({
    SubscriptionPlan? plan,
    DateTime? startDate,
    DateTime? endDate,
    double? price,
    String? currency,
    bool? isActive,
    String? transactionId,
  }) {
    return Subscription(
      plan: plan ?? this.plan,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      transactionId: transactionId ?? this.transactionId,
    );
  }
}

enum PaymentMethod {
  upi,
  googlePay,
  phonePe,
  paytm,
  razorpay,
  creditCard,
  debitCard,
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
  final String? promoCode;

  const PaymentTransaction({
    required this.id,
    required this.method,
    required this.amount,
    this.currency = 'INR',
    required this.plan,
    required this.timestamp,
    required this.status,
    this.failureReason,
    this.promoCode,
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
      'promoCode': promoCode,
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
      promoCode: json['promoCode'],
    );
  }
}

enum PaymentStatus {
  pending,
  success,
  failed,
  cancelled,
  refunded,
}