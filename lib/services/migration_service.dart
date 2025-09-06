import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/aac_logger.dart';
import '../utils/sample_data.dart';
import '../models/symbol.dart';
import '../models/user_profile.dart';
import 'shared_resource_service.dart';
import 'user_profile_service.dart';

/// Migration service to transition from old per-user storage to new shared architecture
/// 
/// This handles the critical transition from:
/// OLD: user_profiles/{uid}/symbols + user_profiles/{uid}/categories (massive duplication)
/// NEW: global_default_symbols + global_default_categories + user_profiles/{uid}/custom_* (efficient)
class MigrationService {
  static const String _migrationKey = 'shared_architecture_migration_v1';
  static const String _migrationCompleteKey = 'migration_complete_v1';
  
  /// Check if migration is needed and perform it
  static Future<void> performMigrationIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final migrationComplete = prefs.getBool(_migrationCompleteKey) ?? false;
      
      if (migrationComplete) {
        AACLogger.info('Migration already completed, skipping', tag: 'MigrationService');
        return;
      }
      
      AACLogger.info('Starting migration to shared architecture...', tag: 'MigrationService');
      
      // Step 1: Initialize global defaults
      await _initializeGlobalDefaults();
      
      // Step 2: Migrate user data if authenticated
      await _migrateUserData();
      
      // Step 3: Mark migration as complete
      await prefs.setBool(_migrationCompleteKey, true);
      
      AACLogger.info('Migration completed successfully!', tag: 'MigrationService');
      
    } catch (e) {
      AACLogger.error('Migration failed: $e', tag: 'MigrationService');
      // Don't mark as complete if migration failed
      rethrow;
    }
  }
  
  /// Initialize global default resources from SampleData
  static Future<void> _initializeGlobalDefaults() async {
    try {
      AACLogger.info('Initializing global defaults from SampleData...', tag: 'MigrationService');
      
      // Check if global defaults already exist
      final globalSymbols = await SharedResourceService.getGlobalDefaultSymbols();
      if (globalSymbols.isNotEmpty) {
        AACLogger.info('Global defaults already exist (${globalSymbols.length} symbols), skipping initialization', tag: 'MigrationService');
        return;
      }
      
      // Initialize global defaults by migrating all SampleData
      await _migrateAllSampleDataToGlobal();
      
      AACLogger.info('Global defaults initialized successfully', tag: 'MigrationService');
      
    } catch (e) {
      AACLogger.error('Error initializing global defaults: $e', tag: 'MigrationService');
      rethrow;
    }
  }
  
  /// Migrate all symbols and categories from SampleData to global collections
  static Future<void> _migrateAllSampleDataToGlobal() async {
    try {
      AACLogger.info('Migrating SampleData to global collections...', tag: 'MigrationService');
      
      // Get all sample data
      final sampleCategories = SampleData.getSampleCategories();
      final sampleSymbols = SampleData.getSampleSymbols();
      
      AACLogger.info('Migrating ${sampleCategories.length} categories and ${sampleSymbols.length} symbols...', tag: 'MigrationService');
      
      // Migrate categories in batches
      await _migrateCategoriesInBatches(sampleCategories);
      
      // Migrate symbols in batches
      await _migrateSymbolsInBatches(sampleSymbols);
      
      AACLogger.info('SampleData migration completed', tag: 'MigrationService');
      
    } catch (e) {
      AACLogger.error('Error migrating SampleData: $e', tag: 'MigrationService');
      rethrow;
    }
  }
  
  /// Migrate categories to global collection in batches
  static Future<void> _migrateCategoriesInBatches(List<Category> categories) async {
    try {
      final firestore = FirebaseFirestore.instance;
      const batchSize = 500; // Firestore limit
      
      for (int i = 0; i < categories.length; i += batchSize) {
        final batch = firestore.batch();
        final collection = firestore.collection('global_default_categories');
        
        final end = (i + batchSize < categories.length) ? i + batchSize : categories.length;
        final batchCategories = categories.sublist(i, end);
        
        for (final category in batchCategories) {
          final categoryData = category.toJson();
          categoryData['isDefault'] = true;
          categoryData['createdAt'] = FieldValue.serverTimestamp();
          categoryData['updatedAt'] = FieldValue.serverTimestamp();
          
          final docRef = collection.doc(); // Auto-generate ID
          batch.set(docRef, categoryData);
        }
        
        await batch.commit();
        AACLogger.debug('Migrated categories batch: ${i + 1}-${end}', tag: 'MigrationService');
      }
      
    } catch (e) {
      AACLogger.error('Error migrating categories: $e', tag: 'MigrationService');
      rethrow;
    }
  }
  
  /// Migrate symbols to global collection in batches
  static Future<void> _migrateSymbolsInBatches(List<Symbol> symbols) async {
    try {
      final firestore = FirebaseFirestore.instance;
      const batchSize = 500; // Firestore limit
      
      for (int i = 0; i < symbols.length; i += batchSize) {
        final batch = firestore.batch();
        final collection = firestore.collection('global_default_symbols');
        
        final end = (i + batchSize < symbols.length) ? i + batchSize : symbols.length;
        final batchSymbols = symbols.sublist(i, end);
        
        for (final symbol in batchSymbols) {
          final symbolData = symbol.toJson();
          symbolData['isDefault'] = true;
          symbolData['createdAt'] = FieldValue.serverTimestamp();
          symbolData['updatedAt'] = FieldValue.serverTimestamp();
          
          final docRef = collection.doc(); // Auto-generate ID
          batch.set(docRef, symbolData);
        }
        
        await batch.commit();
        AACLogger.debug('Migrated symbols batch: ${i + 1}-${end}', tag: 'MigrationService');
      }
      
    } catch (e) {
      AACLogger.error('Error migrating symbols: $e', tag: 'MigrationService');
      rethrow;
    }
  }
  
  /// Migrate user's custom data from old structure to new structure
  static Future<void> _migrateUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AACLogger.info('No authenticated user, skipping user data migration', tag: 'MigrationService');
        return;
      }
      
      AACLogger.info('Migrating user data for: ${user.uid}', tag: 'MigrationService');
      
      // Get current user profile
      final profile = await UserProfileService.getActiveProfile();
      if (profile == null) {
        AACLogger.info('No active profile found, skipping user data migration', tag: 'MigrationService');
        return;
      }
      
      // Migrate custom symbols (non-default ones only)
      await _migrateUserCustomSymbols(user.uid, profile.userSymbols);
      
      // Migrate custom categories (non-default ones only)
      await _migrateUserCustomCategories(user.uid, profile.userCategories);
      
      // Clean up old data from profile
      await _cleanupOldProfileData(profile);
      
      AACLogger.info('User data migration completed for: ${user.uid}', tag: 'MigrationService');
      
    } catch (e) {
      AACLogger.error('Error migrating user data: $e', tag: 'MigrationService');
      rethrow;
    }
  }
  
  /// Migrate user's custom symbols to new architecture
  static Future<void> _migrateUserCustomSymbols(String userUid, List<Symbol> userSymbols) async {
    try {
      // Filter out default symbols - only migrate custom ones
      final customSymbols = userSymbols.where((symbol) => !symbol.isDefault).toList();
      
      if (customSymbols.isEmpty) {
        AACLogger.info('No custom symbols to migrate', tag: 'MigrationService');
        return;
      }
      
      AACLogger.info('Migrating ${customSymbols.length} custom symbols...', tag: 'MigrationService');
      
      for (final symbol in customSymbols) {
        try {
          // Add to new custom symbols collection
          await SharedResourceService.addUserCustomSymbol(userUid, symbol);
          AACLogger.debug('Migrated custom symbol: ${symbol.label}', tag: 'MigrationService');
        } catch (e) {
          AACLogger.error('Failed to migrate symbol ${symbol.label}: $e', tag: 'MigrationService');
          // Continue with other symbols
        }
      }
      
      AACLogger.info('Custom symbols migration completed', tag: 'MigrationService');
      
    } catch (e) {
      AACLogger.error('Error migrating custom symbols: $e', tag: 'MigrationService');
      rethrow;
    }
  }
  
  /// Migrate user's custom categories to new architecture
  static Future<void> _migrateUserCustomCategories(String userUid, List<Category> userCategories) async {
    try {
      // Filter out default categories - only migrate custom ones
      final customCategories = userCategories.where((category) => !category.isDefault).toList();
      
      if (customCategories.isEmpty) {
        AACLogger.info('No custom categories to migrate', tag: 'MigrationService');
        return;
      }
      
      AACLogger.info('Migrating ${customCategories.length} custom categories...', tag: 'MigrationService');
      
      for (final category in customCategories) {
        try {
          // Add to new custom categories collection
          await SharedResourceService.addUserCustomCategory(userUid, category);
          AACLogger.debug('Migrated custom category: ${category.name}', tag: 'MigrationService');
        } catch (e) {
          AACLogger.error('Failed to migrate category ${category.name}: $e', tag: 'MigrationService');
          // Continue with other categories
        }
      }
      
      AACLogger.info('Custom categories migration completed', tag: 'MigrationService');
      
    } catch (e) {
      AACLogger.error('Error migrating custom categories: $e', tag: 'MigrationService');
      rethrow;
    }
  }
  
  /// Clean up old embedded data from user profile
  static Future<void> _cleanupOldProfileData(UserProfile profile) async {
    try {
      AACLogger.info('Cleaning up old profile data...', tag: 'MigrationService');
      
      // Create updated profile with empty symbols/categories lists
      final cleanedProfile = profile.copyWith(
        userSymbols: [], // Clear old embedded symbols
        userCategories: [], // Clear old embedded categories
      );
      
      // Save cleaned profile
      await UserProfileService.saveUserProfile(cleanedProfile);
      
      AACLogger.info('Profile cleanup completed', tag: 'MigrationService');
      
    } catch (e) {
      AACLogger.error('Error cleaning up profile data: $e', tag: 'MigrationService');
      rethrow;
    }
  }
  
  /// Reset migration status (for testing/debugging)
  static Future<void> resetMigrationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_migrationCompleteKey);
      await prefs.remove(_migrationKey);
      AACLogger.info('Migration status reset', tag: 'MigrationService');
    } catch (e) {
      AACLogger.error('Error resetting migration status: $e', tag: 'MigrationService');
    }
  }
  
  /// Check migration status
  static Future<bool> isMigrationComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_migrationCompleteKey) ?? false;
    } catch (e) {
      AACLogger.error('Error checking migration status: $e', tag: 'MigrationService');
      return false;
    }
  }
  
  /// Get migration progress information
  static Future<Map<String, dynamic>> getMigrationProgress() async {
    try {
      final isComplete = await isMigrationComplete();
      
      if (!isComplete) {
        return {
          'complete': false,
          'status': 'Migration pending',
        };
      }
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final stats = await SharedResourceService.getStorageStats(user.uid);
        return {
          'complete': true,
          'status': 'Migration completed successfully',
          'storage_stats': stats,
        };
      }
      
      return {
        'complete': true,
        'status': 'Migration completed (user not authenticated)',
      };
      
    } catch (e) {
      AACLogger.error('Error getting migration progress: $e', tag: 'MigrationService');
      return {
        'complete': false,
        'status': 'Error checking migration status: $e',
      };
    }
  }
}
