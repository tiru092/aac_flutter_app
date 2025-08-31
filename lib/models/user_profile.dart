import '../models/symbol.dart'; // Import the correct Symbol and Category classes
import '../models/subscription.dart'; // Import the correct Subscription class
import '../models/subscription.dart'; // Import PaymentTransaction

class UserProfile {
  final String id;
  final String name;
  final UserRole role;
  final String? avatarPath;
  final DateTime createdAt;
  final ProfileSettings settings;
  final String? pin; // For caregiver role only
  final String? email;
  final String? phoneNumber;
  final List<SharedProfile> sharedWith;
  final List<SharedProfile> sharedBy;
  final DateTime? lastActiveAt;
  final Subscription? subscription;
  final List<Symbol> userSymbols; // Add missing property
  final List<Category> userCategories; // Add missing property
  final List<PaymentTransaction> paymentHistory; // Add payment history

  UserProfile({
    required this.id,
    required this.name,
    required this.role,
    this.avatarPath,
    required this.createdAt,
    required this.settings,
    this.pin,
    this.email,
    this.phoneNumber,
    this.sharedWith = const [],
    this.sharedBy = const [],
    this.lastActiveAt,
    this.subscription,
    this.userSymbols = const [], // Add missing parameter
    this.userCategories = const [], // Add missing parameter
    this.paymentHistory = const [], // Add payment history
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role.toString(),
    'avatarPath': avatarPath,
    'createdAt': createdAt.toIso8601String(),
    'settings': settings.toJson(),
    'pin': pin,
    'email': email,
    'phoneNumber': phoneNumber,
    'sharedWith': sharedWith.map((s) => s.toJson()).toList(),
    'sharedBy': sharedBy.map((s) => s.toJson()).toList(),
    'lastActiveAt': lastActiveAt?.toIso8601String(),
    'subscription': subscription?.toJson(),
    'userSymbols': userSymbols.map((s) => s.toJson()).toList(), // Add to JSON
    'userCategories': userCategories.map((c) => c.toJson()).toList(), // Add to JSON
    'paymentHistory': paymentHistory.map((p) => p.toJson()).toList(), // Add payment history
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'],
    name: json['name'],
    role: UserRole.values.firstWhere(
      (role) => role.toString() == json['role'],
      orElse: () => UserRole.child,
    ),
    avatarPath: json['avatarPath'],
    createdAt: DateTime.parse(json['createdAt']),
    settings: ProfileSettings.fromJson(json['settings'] ?? {}),
    pin: json['pin'],
    email: json['email'],
    phoneNumber: json['phoneNumber'],
    sharedWith: json['sharedWith'] != null
        ? List<SharedProfile>.from(
            json['sharedWith'].map((x) => SharedProfile.fromJson(x)))
        : [],
    sharedBy: json['sharedBy'] != null
        ? List<SharedProfile>.from(
            json['sharedBy'].map((x) => SharedProfile.fromJson(x)))
        : [],
    lastActiveAt: json['lastActiveAt'] != null
        ? DateTime.parse(json['lastActiveAt'])
        : null,
    subscription: json['subscription'] != null
        ? Subscription.fromJson(json['subscription'])
        : null,
    userSymbols: json['userSymbols'] != null // Add from JSON
        ? List<Symbol>.from(
            json['userSymbols'].map((x) => Symbol.fromJson(x)))
        : [],
    userCategories: json['userCategories'] != null // Add from JSON
        ? List<Category>.from(
            json['userCategories'].map((x) => Category.fromJson(x)))
        : [],
    paymentHistory: json['paymentHistory'] != null // Add payment history
        ? List<PaymentTransaction>.from(
            json['paymentHistory'].map((x) => PaymentTransaction.fromJson(x)))
        : [],
  );

  UserProfile copyWith({
    String? id,
    String? name,
    UserRole? role,
    String? avatarPath,
    DateTime? createdAt,
    ProfileSettings? settings,
    String? pin,
    String? email,
    String? phoneNumber,
    List<SharedProfile>? sharedWith,
    List<SharedProfile>? sharedBy,
    DateTime? lastActiveAt,
    Subscription? subscription,
    List<Symbol>? userSymbols, // Add missing parameter
    List<Category>? userCategories, // Add missing parameter
    List<PaymentTransaction>? paymentHistory, // Add payment history
  }) => UserProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    role: role ?? this.role,
    avatarPath: avatarPath ?? this.avatarPath,
    createdAt: createdAt ?? this.createdAt,
    settings: settings ?? this.settings,
    pin: pin ?? this.pin,
    email: email ?? this.email,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    sharedWith: sharedWith ?? this.sharedWith,
    sharedBy: sharedBy ?? this.sharedBy,
    lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    subscription: subscription ?? this.subscription,
    userSymbols: userSymbols ?? this.userSymbols, // Add missing parameter
    userCategories: userCategories ?? this.userCategories, // Add missing parameter
    paymentHistory: paymentHistory ?? this.paymentHistory, // Add payment history
  );

  /// Check if the user has a premium subscription
  bool get isPremium {
    if (subscription == null) return false;
    
    // Free plan is not premium
    if (subscription!.plan == SubscriptionPlan.free) return false;
    
    // Check if subscription is active and not expired
    return subscription!.isActive && !subscription!.isExpired;
  }
}

enum UserRole {
  child,
  caregiver,
  therapist,
  administrator,
}

class ProfileSettings {
  final double textSize;
  final bool highContrast;
  final bool hapticFeedback;
  final String voiceLanguage;
  final double speechRate;
  final bool showCategories;
  final int gridColumns;
  final String theme;
  final bool enableCollaboration; // New setting for collaboration
  final bool enableNotifications; // New setting for notifications
  final bool autoBackup; // New setting for automatic backups
  final String preferredLanguage; // New setting for language preference
  final bool darkMode; // New setting for dark mode

  ProfileSettings({
    this.textSize = 1.0,
    this.highContrast = false,
    this.hapticFeedback = true,
    this.voiceLanguage = 'en-US',
    this.speechRate = 0.5,
    this.showCategories = true,
    this.gridColumns = 3,
    this.theme = 'default',
    this.enableCollaboration = false, // Default to disabled
    this.enableNotifications = true, // Default to enabled
    this.autoBackup = false, // Default to disabled
    this.preferredLanguage = 'en', // Default to English
    this.darkMode = false, // Default to light mode
  });

  Map<String, dynamic> toJson() => {
    'textSize': textSize,
    'highContrast': highContrast,
    'hapticFeedback': hapticFeedback,
    'voiceLanguage': voiceLanguage,
    'speechRate': speechRate,
    'showCategories': showCategories,
    'gridColumns': gridColumns,
    'theme': theme,
    'enableCollaboration': enableCollaboration,
    'enableNotifications': enableNotifications,
    'autoBackup': autoBackup,
    'preferredLanguage': preferredLanguage,
    'darkMode': darkMode,
  };

  factory ProfileSettings.fromJson(Map<String, dynamic> json) => ProfileSettings(
    textSize: json['textSize']?.toDouble() ?? 1.0,
    highContrast: json['highContrast'] ?? false,
    hapticFeedback: json['hapticFeedback'] ?? true,
    voiceLanguage: json['voiceLanguage'] ?? 'en-US',
    speechRate: json['speechRate']?.toDouble() ?? 0.5,
    showCategories: json['showCategories'] ?? true,
    gridColumns: json['gridColumns'] ?? 3,
    theme: json['theme'] ?? 'default',
    enableCollaboration: json['enableCollaboration'] ?? false,
    enableNotifications: json['enableNotifications'] ?? true,
    autoBackup: json['autoBackup'] ?? false,
    preferredLanguage: json['preferredLanguage'] ?? 'en',
    darkMode: json['darkMode'] ?? false,
  );

  ProfileSettings copyWith({
    double? textSize,
    bool? highContrast,
    bool? hapticFeedback,
    String? voiceLanguage,
    double? speechRate,
    bool? showCategories,
    int? gridColumns,
    String? theme,
    bool? enableCollaboration,
    bool? enableNotifications,
    bool? autoBackup,
  }) => ProfileSettings(
    textSize: textSize ?? this.textSize,
    highContrast: highContrast ?? this.highContrast,
    hapticFeedback: hapticFeedback ?? this.hapticFeedback,
    voiceLanguage: voiceLanguage ?? this.voiceLanguage,
    speechRate: speechRate ?? this.speechRate,
    showCategories: showCategories ?? this.showCategories,
    gridColumns: gridColumns ?? this.gridColumns,
    theme: theme ?? this.theme,
    enableCollaboration: enableCollaboration ?? this.enableCollaboration,
    enableNotifications: enableNotifications ?? this.enableNotifications,
    autoBackup: autoBackup ?? this.autoBackup,
  );
}

// New model for shared profiles
class SharedProfile {
  final String profileId;
  final String sharedWithUserId;
  final String sharedWithUserEmail;
  final SharingPermission permission;
  final DateTime sharedAt;
  final String sharedByUserId;
  final String? message;

  SharedProfile({
    required this.profileId,
    required this.sharedWithUserId,
    required this.sharedWithUserEmail,
    required this.permission,
    required this.sharedAt,
    required this.sharedByUserId,
    this.message,
  });

  Map<String, dynamic> toJson() => {
    'profileId': profileId,
    'sharedWithUserId': sharedWithUserId,
    'sharedWithUserEmail': sharedWithUserEmail,
    'permission': permission.toString(),
    'sharedAt': sharedAt.toIso8601String(),
    'sharedByUserId': sharedByUserId,
    'message': message,
  };

  factory SharedProfile.fromJson(Map<String, dynamic> json) => SharedProfile(
    profileId: json['profileId'],
    sharedWithUserId: json['sharedWithUserId'],
    sharedWithUserEmail: json['sharedWithUserEmail'],
    permission: SharingPermission.values.firstWhere(
      (p) => p.toString() == json['permission'],
      orElse: () => SharingPermission.view,
    ),
    sharedAt: DateTime.parse(json['sharedAt']),
    sharedByUserId: json['sharedByUserId'],
    message: json['message'],
  );

  SharedProfile copyWith({
    String? profileId,
    String? sharedWithUserId,
    String? sharedWithUserEmail,
    SharingPermission? permission,
    DateTime? sharedAt,
    String? sharedByUserId,
    String? message,
  }) => SharedProfile(
    profileId: profileId ?? this.profileId,
    sharedWithUserId: sharedWithUserId ?? this.sharedWithUserId,
    sharedWithUserEmail: sharedWithUserEmail ?? this.sharedWithUserEmail,
    permission: permission ?? this.permission,
    sharedAt: sharedAt ?? this.sharedAt,
    sharedByUserId: sharedByUserId ?? this.sharedByUserId,
    message: message ?? this.message,
  );
}

// Permissions for shared profiles
enum SharingPermission {
  view,      // Can view profile but not edit
  edit,      // Can view and edit profile
  collaborate, // Can view, edit, and collaborate in real-time
}