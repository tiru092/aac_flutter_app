import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/symbol.dart';
import '../utils/aac_logger.dart';
import 'firebase_path_registry.dart';

/// Service to handle migration from legacy Firebase paths to canonical paths
/// This ensures smooth transition without data loss
class FirebaseMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Check if user needs migration from legacy custom_categories to categories
  static Future<bool> needsCategoriesMigration(String userUid) async {
    try {
      // Check if legacy path has data
      final legacySnapshot = await _firestore
          .collection(FirebasePathRegistry.legacyUserCustomCategories(userUid))
          .limit(1)
          .get();
      
      // Check if canonical path is empty
      final canonicalSnapshot = await _firestore
          .collection(FirebasePathRegistry.userCategories(userUid))
          .limit(1)
          .get();
      
      // Migration needed if legacy has data and canonical is empty
      return legacySnapshot.docs.isNotEmpty && canonicalSnapshot.docs.isEmpty;
    } catch (e) {
      AACLogger.error('Error checking migration need: $e', tag: 'FirebaseMigrationService');
      return false;
    }
  }
  
  /// Migrate user's custom categories from legacy path to canonical path
  static Future<bool> migrateUserCategories(String userUid) async {
    try {
      AACLogger.info('Starting migration for user $userUid', tag: 'FirebaseMigrationService');
      
      // Get all categories from legacy path
      final legacySnapshot = await _firestore
          .collection(FirebasePathRegistry.legacyUserCustomCategories(userUid))
          .get();
      
      if (legacySnapshot.docs.isEmpty) {
        AACLogger.info('No legacy categories to migrate', tag: 'FirebaseMigrationService');
        return true;
      }
      
      // Use batch for atomic migration
      final batch = _firestore.batch();
      final canonicalCollection = _firestore.collection(FirebasePathRegistry.userCategories(userUid));
      
      int migratedCount = 0;
      for (final doc in legacySnapshot.docs) {
        try {
          final data = doc.data();
          data['migratedAt'] = FieldValue.serverTimestamp();
          data['migratedFrom'] = 'custom_categories';
          
          // Use same document ID to maintain references
          final newDocRef = canonicalCollection.doc(doc.id);
          batch.set(newDocRef, data);
          migratedCount++;
        } catch (e) {
          AACLogger.warning('Failed to migrate category ${doc.id}: $e', tag: 'FirebaseMigrationService');
        }
      }
      
      // Commit the migration
      await batch.commit();
      AACLogger.info('Successfully migrated $migratedCount categories', tag: 'FirebaseMigrationService');
      
      // Mark migration as complete
      await _markMigrationComplete(userUid, 'categories');
      
      return true;
      
    } catch (e) {
      AACLogger.error('Migration failed for user $userUid: $e', tag: 'FirebaseMigrationService');
      return false;
    }
  }
  
  /// Mark migration as complete for a user
  static Future<void> _markMigrationComplete(String userUid, String migrationType) async {
    try {
      await _firestore.doc(FirebasePathRegistry.userDocument(userUid)).set({
        'migrations': {
          migrationType: {
            'completed': true,
            'completedAt': FieldValue.serverTimestamp(),
          }
        }
      }, SetOptions(merge: true));
    } catch (e) {
      AACLogger.warning('Failed to mark migration complete: $e', tag: 'FirebaseMigrationService');
    }
  }
  
  /// Check if migration was already completed
  static Future<bool> isMigrationCompleted(String userUid, String migrationType) async {
    try {
      final doc = await _firestore.doc(FirebasePathRegistry.userDocument(userUid)).get();
      final data = doc.data() as Map<String, dynamic>?;
      return data?['migrations']?[migrationType]?['completed'] ?? false;
    } catch (e) {
      AACLogger.warning('Failed to check migration status: $e', tag: 'FirebaseMigrationService');
      return false;
    }
  }
}
