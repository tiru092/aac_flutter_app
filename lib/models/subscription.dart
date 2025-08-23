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

class UserProfile {
  final String id;
  final String name;
  final String? email;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final Subscription subscription;
  final List<PaymentTransaction> paymentHistory;
  final ProfileSettings settings;

  const UserProfile({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    required this.createdAt,
    this.lastActiveAt,
    required this.subscription,
    this.paymentHistory = const [],
    required this.settings,
  });

  bool get isPremium => subscription.isActive && !subscription.isExpired;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'subscription': subscription.toJson(),
      'paymentHistory': paymentHistory.map((p) => p.toJson()).toList(),
      'settings': settings.toJson(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      createdAt: DateTime.parse(json['createdAt']),
      lastActiveAt: json['lastActiveAt'] != null 
          ? DateTime.parse(json['lastActiveAt']) 
          : null,
      subscription: Subscription.fromJson(json['subscription']),
      paymentHistory: (json['paymentHistory'] as List<dynamic>?)
              ?.map((p) => PaymentTransaction.fromJson(p))
              .toList() ?? [],
      settings: ProfileSettings.fromJson(json['settings']),
    );
  }
}

class ProfileSettings {
  final bool enableNotifications;
  final String preferredLanguage;
  final bool autoBackup;
  final bool darkMode;

  const ProfileSettings({
    this.enableNotifications = true,
    this.preferredLanguage = 'en',
    this.autoBackup = false,
    this.darkMode = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'enableNotifications': enableNotifications,
      'preferredLanguage': preferredLanguage,
      'autoBackup': autoBackup,
      'darkMode': darkMode,
    };
  }

  factory ProfileSettings.fromJson(Map<String, dynamic> json) {
    return ProfileSettings(
      enableNotifications: json['enableNotifications'] ?? true,
      preferredLanguage: json['preferredLanguage'] ?? 'en',
      autoBackup: json['autoBackup'] ?? false,
      darkMode: json['darkMode'] ?? false,
    );
  }
}