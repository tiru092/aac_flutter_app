import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'history_entry.g.dart';

@HiveType(typeId: 5) // Ensure this typeId is unique
class HistoryEntry extends HiveObject {
  @HiveField(0)
  String id; // This will be the Firebase Document ID

  @HiveField(1)
  final List<String> symbolIds;

  @HiveField(2)
  final String spokenText;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String userId;

  HistoryEntry({
    required this.id,
    required this.symbolIds,
    required this.spokenText,
    required this.timestamp,
    required this.userId,
  });

  // Factory constructor to create from a Firestore document
  factory HistoryEntry.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return HistoryEntry(
      id: doc.id,
      symbolIds: List<String>.from(data['symbolIds'] ?? []),
      spokenText: data['spokenText'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }

  // Method to convert to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'symbolIds': symbolIds,
      'spokenText': spokenText,
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
      // Note: 'id' is not included here as it's the document ID in Firestore
    };
  }
}
