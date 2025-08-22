class UserProfile {
  final String id;
  final String name;
  final UserRole role;
  final String? avatarPath;
  final DateTime createdAt;
  final ProfileSettings settings;
  final String? pin; // For caregiver role only

  UserProfile({
    required this.id,
    required this.name,
    required this.role,
    this.avatarPath,
    required this.createdAt,
    required this.settings,
    this.pin,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role.toString(),
    'avatarPath': avatarPath,
    'createdAt': createdAt.toIso8601String(),
    'settings': settings.toJson(),
    'pin': pin,
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
  );

  UserProfile copyWith({
    String? id,
    String? name,
    UserRole? role,
    String? avatarPath,
    DateTime? createdAt,
    ProfileSettings? settings,
    String? pin,
  }) => UserProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    role: role ?? this.role,
    avatarPath: avatarPath ?? this.avatarPath,
    createdAt: createdAt ?? this.createdAt,
    settings: settings ?? this.settings,
    pin: pin ?? this.pin,
  );
}

enum UserRole {
  child,
  caregiver,
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

  ProfileSettings({
    this.textSize = 1.0,
    this.highContrast = false,
    this.hapticFeedback = true,
    this.voiceLanguage = 'en-US',
    this.speechRate = 0.5,
    this.showCategories = true,
    this.gridColumns = 3,
    this.theme = 'default',
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
  }) => ProfileSettings(
    textSize: textSize ?? this.textSize,
    highContrast: highContrast ?? this.highContrast,
    hapticFeedback: hapticFeedback ?? this.hapticFeedback,
    voiceLanguage: voiceLanguage ?? this.voiceLanguage,
    speechRate: speechRate ?? this.speechRate,
    showCategories: showCategories ?? this.showCategories,
    gridColumns: gridColumns ?? this.gridColumns,
    theme: theme ?? this.theme,
  );
}