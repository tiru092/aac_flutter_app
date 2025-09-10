import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:svarah/models/history_entry.dart';
import 'package:svarah/utils/aac_logger.dart';

class HistoryManager {
  static final HistoryManager _instance = HistoryManager._internal();
  factory HistoryManager() => _instance;
  HistoryManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _userId;
  Box<HistoryEntry>? _historyBox;

  Future<void> init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      final boxName = 'history_$_userId';
      if (!Hive.isAdapterRegistered(HistoryEntryAdapter().typeId)) {
        Hive.registerAdapter(HistoryEntryAdapter());
      }
      _historyBox = await Hive.openBox<HistoryEntry>(boxName);
      AACLogger.info('HistoryManager initialized for user: $_userId', tag: 'History');
    }
  }

  // Add a new history entry to both Firestore and Hive
  Future<void> addHistoryEntry(List<String> symbolIds, String spokenText) async {
    if (_userId == null) {
      AACLogger.warning('Cannot add history entry, user not logged in.', tag: 'History');
      return;
    }

    try {
      // Create a new document in Firestore to get a unique ID
      final docRef = _firestore.collection('users').doc(_userId).collection('history').doc();
      
      final newEntry = HistoryEntry(
        id: docRef.id,
        symbolIds: symbolIds,
        spokenText: spokenText,
        timestamp: DateTime.now(),
        userId: _userId!,
      );

      // Save to Firestore
      await docRef.set(newEntry.toFirestore());

      // Save to Hive with the same ID
      await _historyBox?.put(newEntry.id, newEntry);

      AACLogger.info('Added history entry: ${newEntry.id}', tag: 'History');
    } catch (e) {
      AACLogger.error('Failed to add history entry: $e', tag: 'History');
      rethrow;
    }
  }

  // Get all history entries from Hive
  List<HistoryEntry> getHistory() {
    if (_historyBox == null) {
      return [];
    }
    // Return sorted by timestamp, most recent first
    var entries = _historyBox!.values.toList();
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  // Sync history from Firestore to Hive
  Future<void> syncHistoryFromFirestore() async {
    if (_userId == null || _historyBox == null) {
      AACLogger.warning('Cannot sync history, user not logged in or box not open.', tag: 'History');
      return;
    }

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .limit(100) // Sync the last 100 entries
          .get();

      for (final doc in querySnapshot.docs) {
        final entry = HistoryEntry.fromFirestore(doc);
        await _historyBox!.put(entry.id, entry);
      }

      AACLogger.info('History synced from Firestore. ${querySnapshot.docs.length} entries updated.', tag: 'History');
    } catch (e) {
      AACLogger.error('Failed to sync history from Firestore: $e', tag: 'History');
    }
  }

  // Clear all history for the current user
  Future<void> clearHistory() async {
    if (_userId == null || _historyBox == null) {
      AACLogger.warning('Cannot clear history, user not logged in or box not open.', tag: 'History');
      return;
    }

    try {
      // Clear from Hive
      await _historyBox!.clear();

      // Clear from Firestore (delete all documents in the collection)
      final querySnapshot = await _firestore.collection('users').doc(_userId).collection('history').get();
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      AACLogger.info('History cleared for user: $_userId', tag: 'History');
    } catch (e) {
      AACLogger.error('Failed to clear history: $e', tag: 'History');
      rethrow;
    }
  }
}
