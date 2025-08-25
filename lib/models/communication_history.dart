import 'package:hive/hive.dart';

part 'communication_history.g.dart';

@HiveType(typeId: 2)
class CommunicationHistoryEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String profileId;

  @HiveField(2)
  final List<String> symbolsUsed;

  @HiveField(3)
  final String? spokenText;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final String? category;

  @HiveField(6)
  final int? durationSeconds;

  @HiveField(7)
  final String? notes;

  CommunicationHistoryEntry({
    required this.id,
    required this.profileId,
    required this.symbolsUsed,
    this.spokenText,
    required this.timestamp,
    this.category,
    this.durationSeconds,
    this.notes,
  });

  CommunicationHistoryEntry copyWith({
    String? id,
    String? profileId,
    List<String>? symbolsUsed,
    String? spokenText,
    DateTime? timestamp,
    String? category,
    int? durationSeconds,
    String? notes,
  }) {
    return CommunicationHistoryEntry(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      symbolsUsed: symbolsUsed ?? this.symbolsUsed,
      spokenText: spokenText ?? this.spokenText,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'CommunicationHistoryEntry(id: $id, profileId: $profileId, symbolsUsed: $symbolsUsed, timestamp: $timestamp)';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'symbolsUsed': symbolsUsed,
        'spokenText': spokenText,
        'timestamp': timestamp.toIso8601String(),
        'category': category,
        'durationSeconds': durationSeconds,
        'notes': notes,
      };

  factory CommunicationHistoryEntry.fromJson(Map<String, dynamic> json) =>
      CommunicationHistoryEntry(
        id: json['id'],
        profileId: json['profileId'],
        symbolsUsed: List<String>.from(json['symbolsUsed']),
        spokenText: json['spokenText'],
        timestamp: DateTime.parse(json['timestamp']),
        category: json['category'],
        durationSeconds: json['durationSeconds'],
        notes: json['notes'],
      );
}

@HiveType(typeId: 3)
class EncryptedCommunicationHistory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String profileId;

  @HiveField(2)
  final String encryptedData;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final String? integrityHash;

  @HiveField(5)
  final String version;

  EncryptedCommunicationHistory({
    required this.id,
    required this.profileId,
    required this.encryptedData,
    required this.createdAt,
    this.integrityHash,
    this.version = '1.0',
  });

  EncryptedCommunicationHistory copyWith({
    String? id,
    String? profileId,
    String? encryptedData,
    DateTime? createdAt,
    String? integrityHash,
    String? version,
  }) {
    return EncryptedCommunicationHistory(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      encryptedData: encryptedData ?? this.encryptedData,
      createdAt: createdAt ?? this.createdAt,
      integrityHash: integrityHash ?? this.integrityHash,
      version: version ?? this.version,
    );
  }

  @override
  String toString() {
    return 'EncryptedCommunicationHistory(id: $id, profileId: $profileId, createdAt: $createdAt)';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'encryptedData': encryptedData,
        'createdAt': createdAt.toIso8601String(),
        'integrityHash': integrityHash,
        'version': version,
      };

  factory EncryptedCommunicationHistory.fromJson(Map<String, dynamic> json) =>
      EncryptedCommunicationHistory(
        id: json['id'],
        profileId: json['profileId'],
        encryptedData: json['encryptedData'],
        createdAt: DateTime.parse(json['createdAt']),
        integrityHash: json['integrityHash'],
        version: json['version'] ?? '1.0',
      );
}