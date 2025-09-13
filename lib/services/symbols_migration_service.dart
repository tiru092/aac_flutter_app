import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/symbol.dart';
import '../utils/aac_logger.dart';

/// One-time migration service to move custom symbols from old path to new path
/// Migrates symbols from: user_profiles/{uid}/custom_symbols → user_profiles/{uid}/symbols
class SymbolsMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Migrate symbols from old Firebase path to new path for given user
  static Future<bool> migrateUserSymbols(String uid) async {
    try {
      AACLogger.info('🔄 Starting symbols migration for user: $uid', tag: 'SymbolsMigration');
      
      // Check if symbols already exist in new path
      final newPathRef = _firestore.collection('user_profiles').doc(uid).collection('symbols');
      final newPathSnapshot = await newPathRef.get();
      
      if (newPathSnapshot.docs.isNotEmpty) {
        AACLogger.info('✅ Symbols already exist in new path, skipping migration', tag: 'SymbolsMigration');
        return true;
      }
      
      // Get symbols from old path
      final oldPathRef = _firestore.collection('user_profiles').doc(uid).collection('custom_symbols');
      final oldPathSnapshot = await oldPathRef.get();
      
      if (oldPathSnapshot.docs.isEmpty) {
        AACLogger.info('ℹ️ No symbols found in old path to migrate', tag: 'SymbolsMigration');
        return true;
      }
      
      AACLogger.info('📦 Found ${oldPathSnapshot.docs.length} symbols to migrate', tag: 'SymbolsMigration');
      
      // Migrate each symbol
      final batch = _firestore.batch();
      int migratedCount = 0;
      
      for (final doc in oldPathSnapshot.docs) {
        try {
          final data = doc.data();
          
          // Validate symbol data
          if (data['text'] != null && data['imageUrl'] != null) {
            // Create new document in correct path
            final newDocRef = newPathRef.doc(doc.id);
            batch.set(newDocRef, data);
            migratedCount++;
            
            AACLogger.debug('📝 Queued symbol for migration: ${data['text']}', tag: 'SymbolsMigration');
          } else {
            AACLogger.warning('⚠️ Skipping invalid symbol document: ${doc.id}', tag: 'SymbolsMigration');
          }
        } catch (e) {
          AACLogger.warning('⚠️ Error processing symbol ${doc.id}: $e', tag: 'SymbolsMigration');
        }
      }
      
      if (migratedCount > 0) {
        // Execute batch migration
        await batch.commit();
        AACLogger.info('✅ Successfully migrated $migratedCount symbols to new path', tag: 'SymbolsMigration');
        
        // Optional: Clean up old path (commented out for safety)
        // await _cleanupOldPath(uid, oldPathRef);
      }
      
      return true;
      
    } catch (e, stackTrace) {
      AACLogger.error('❌ Symbols migration failed for user $uid: $e', stackTrace: stackTrace, tag: 'SymbolsMigration');
      return false;
    }
  }
  
  /// Clean up old path after successful migration (optional)
  static Future<void> _cleanupOldPath(String uid, CollectionReference oldPathRef) async {
    try {
      AACLogger.info('🧹 Cleaning up old symbols path...', tag: 'SymbolsMigration');
      
      final batch = _firestore.batch();
      final snapshot = await oldPathRef.get();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      AACLogger.info('✅ Old symbols path cleaned up', tag: 'SymbolsMigration');
      
    } catch (e) {
      AACLogger.warning('⚠️ Failed to clean up old path: $e', tag: 'SymbolsMigration');
    }
  }
  
  /// Check if migration is needed for a user
  static Future<bool> needsMigration(String uid) async {
    try {
      AACLogger.info('🔥🔄 SymbolsMigrationService: Checking migration need for UID: $uid', tag: 'SymbolsMigration');
      
      // Check if new path is empty and old path has data
      final newPathRef = _firestore.collection('user_profiles').doc(uid).collection('symbols');
      final newPathSnapshot = await newPathRef.limit(1).get();
      
      AACLogger.info('🔥🔄 SymbolsMigrationService: New path has ${newPathSnapshot.docs.length} documents', tag: 'SymbolsMigration');
      
      if (newPathSnapshot.docs.isNotEmpty) {
        AACLogger.info('🔥✅ SymbolsMigrationService: New path has data, migration not needed', tag: 'SymbolsMigration');
        return false; // Already migrated
      }
      
      final oldPathRef = _firestore.collection('user_profiles').doc(uid).collection('custom_symbols');
      final oldPathSnapshot = await oldPathRef.limit(1).get();
      
      AACLogger.info('🔥🔄 SymbolsMigrationService: Old path has ${oldPathSnapshot.docs.length} documents', tag: 'SymbolsMigration');
      
      final migrationNeeded = oldPathSnapshot.docs.isNotEmpty;
      AACLogger.info('🔥🔄 SymbolsMigrationService: Migration needed result: $migrationNeeded', tag: 'SymbolsMigration');
      
      return migrationNeeded; // Migration needed if old path has data
      
    } catch (e) {
      AACLogger.warning('🔥❌ SymbolsMigrationService: Error checking migration status: $e', tag: 'SymbolsMigration');
      return false;
    }
  }
}
