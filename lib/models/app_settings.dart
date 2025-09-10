import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 10) // Using a new, unused typeId
class AppSettings extends HiveObject {
  @HiveField(0)
  String languageCode;

  @HiveField(1)
  String? voiceName;

  @HiveField(2)
  double speechRate;

  @HiveField(3)
  double pitch;

  AppSettings({
    this.languageCode = 'en-IN',
    this.voiceName,
    this.speechRate = 0.5,
    this.pitch = 1.0,
  });

  // Serialization for Firestore
  Map<String, dynamic> toJson() => {
        'languageCode': languageCode,
        'voiceName': voiceName,
        'speechRate': speechRate,
        'pitch': pitch,
      };

  // Deserialization from Firestore
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      languageCode: json['languageCode'] as String? ?? 'en-IN',
      voiceName: json['voiceName'] as String?,
      speechRate: (json['speechRate'] as num?)?.toDouble() ?? 0.5,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 1.0,
    );
  }

  AppSettings copyWith({
    String? languageCode,
    String? voiceName,
    double? speechRate,
    double? pitch,
  }) {
    return AppSettings(
      languageCode: languageCode ?? this.languageCode,
      voiceName: voiceName ?? this.voiceName,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
    );
  }
}
