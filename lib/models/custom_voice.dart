import 'package:equatable/equatable.dart';

enum VoiceType { female, male, child }

enum VoiceGender { female, male, neutral }

class CustomVoice extends Equatable {
  final String id;
  final String name;
  final String filePath;
  final DateTime createdAt;
  final bool isDefault;
  final VoiceType voiceType;
  final VoiceGender gender;
  final String description;

  const CustomVoice({
    required this.id,
    required this.name,
    required this.filePath,
    required this.createdAt,
    required this.isDefault,
    required this.voiceType,
    required this.gender,
    this.description = '',
  });

  factory CustomVoice.fromJson(Map<String, dynamic> json) {
    return CustomVoice(
      id: json['id'] as String,
      name: json['name'] as String,
      filePath: json['filePath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isDefault: json['isDefault'] as bool,
      voiceType: VoiceType.values.firstWhere(
        (e) => e.toString() == 'VoiceType.${json['voiceType']}',
        orElse: () => VoiceType.female,
      ),
      gender: VoiceGender.values.firstWhere(
        (e) => e.toString() == 'VoiceGender.${json['gender']}',
        orElse: () => VoiceGender.female,
      ),
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'isDefault': isDefault,
      'voiceType': voiceType.toString().split('.').last,
      'gender': gender.toString().split('.').last,
      'description': description,
    };
  }

  /// Create a copy with modified properties
  CustomVoice copyWith({
    String? id,
    String? name,
    String? filePath,
    DateTime? createdAt,
    bool? isDefault,
    VoiceType? voiceType,
    VoiceGender? gender,
    String? description,
  }) {
    return CustomVoice(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
      voiceType: voiceType ?? this.voiceType,
      gender: gender ?? this.gender,
      description: description ?? this.description,
    );
  }

  /// Get voice type display name
  String get voiceTypeDisplayName {
    switch (voiceType) {
      case VoiceType.female:
        return 'Female Voice';
      case VoiceType.male:
        return 'Male Voice';
      case VoiceType.child:
        return 'Child Voice';
    }
  }

  /// Get gender display name
  String get genderDisplayName {
    switch (gender) {
      case VoiceGender.female:
        return 'Female';
      case VoiceGender.male:
        return 'Male';
      case VoiceGender.neutral:
        return 'Neutral';
    }
  }

  /// Get voice category for grouping
  String get category {
    if (isDefault) {
      return 'Default Voices';
    } else {
      return 'Custom Voices';
    }
  }

  @override
  List<Object?> get props => [id, name, filePath, createdAt, isDefault, voiceType, gender, description];
}