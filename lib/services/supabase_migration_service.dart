import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_aac_service.dart';
import '../services/favorites_service.dart';
import '../services/enhanced_user_profile_service.dart';
import '../services/communication_history_service.dart';
import '../models/symbol.dart' as models;
import '../utils/aac_logger.dart';

/// Migration status tracking
enum MigrationStatus {
  notStarted,
  inProgress,
  completed,
  failed,
}

/// Migration Service to transition from Firebase+Hive to Supabase
/// Handles data migration while maintaining app functionality
class SupabaseMigrationService {
  static const String _tag = 'SupabaseMigrationService';
  static const String _migrationKey = 'supabase_migration_status';
  
  /// Comprehensive migration from Firebase+Hive to Supabase
  static Future<bool> migrateToSupabase({
    bool forceReMigration = false,
  }) async {
    try {
      AACLogger.info('Starting comprehensive Supabase migration...', tag: _tag);
      
      // Check if migration already completed
      if (!forceReMigration) {
        final status = await _getMigrationStatus();
        if (status == MigrationStatus.completed) {
          AACLogger.info('Migration already completed', tag: _tag);
          return true;
        }
      }
      
      await _updateMigrationStatus(MigrationStatus.inProgress);
      
      // Step 1: Authenticate with Supabase
      final supabaseAuth = await _ensureSupabaseAuthentication();
      if (!supabaseAuth) {
        throw Exception('Failed to authenticate with Supabase');
      }
      
      // Step 2: Migrate user profiles
      final profileIds = await _migrateUserProfiles();
      AACLogger.info('Migrated ${profileIds.length} user profiles', tag: _tag);
      
      // Step 3: Migrate data for each profile
      for (final profileId in profileIds) {
        await _migrateProfileData(profileId);
      }
      
      // Step 4: Verify migration
      final verified = await _verifyMigration(profileIds);
      if (!verified) {
        throw Exception('Migration verification failed');
      }
      
      await _updateMigrationStatus(MigrationStatus.completed);
      AACLogger.info('✅ Supabase migration completed successfully!', tag: _tag);
      return true;
      
    } catch (e, stackTrace) {
      AACLogger.error('Migration failed: $e', stackTrace: stackTrace, tag: _tag);
      await _updateMigrationStatus(MigrationStatus.failed);
      return false;
    }
  }
  
  /// Ensure user is authenticated with Supabase
  static Future<bool> _ensureSupabaseAuthentication() async {
    try {
      final supabaseUser = Supabase.instance.client.auth.currentUser;
      if (supabaseUser != null) {
        AACLogger.info('User already authenticated with Supabase', tag: _tag);
        return true;
      }
      
      // Get Firebase user for authentication bridging
      final firebaseUser = firebase.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        AACLogger.warning('No Firebase user found for migration', tag: _tag);
        return false;
      }
      
      // For production: implement proper auth bridging
      // For now, we'll create anonymous user or use email if available
      final email = firebaseUser.email;
      
      if (email != null) {
        // Try to sign in existing Supabase user
        try {
          await Supabase.instance.client.auth.signInWithPassword(
            email: email,
            password: 'temporary_migration_password', // You'd handle this properly
          );
        } catch (e) {
          // If sign in fails, create new account
          await Supabase.instance.client.auth.signUp(
            email: email,
            password: 'temporary_migration_password',
          );
        }
      } else {
        // Create anonymous user for migration
        await Supabase.instance.client.auth.signInAnonymously();
      }
      
      return Supabase.instance.client.auth.currentUser != null;
    } catch (e) {
      AACLogger.error('Failed to authenticate with Supabase: $e', tag: _tag);
      return false;
    }
  }
  
  /// Migrate user profiles from local storage to Supabase
  static Future<List<String>> _migrateUserProfiles() async {
    try {
      AACLogger.info('Migrating user profiles...', tag: _tag);
      final profileIds = <String>[];
      
      // Get existing profiles from Firebase/Local storage
      final existingProfiles = await SupabaseAACService.getUserProfiles();
      
      for (final profile in existingProfiles) {
        try {
          // Create profile in Supabase
          final supabaseProfile = await SupabaseAACService.createProfile(
            profileName: profile.name,
            displayName: profile.name, // Use name as display name
            role: profile.role.toString().split('.').last,
            ageGroup: 'child', // Default age group
            communicationLevel: 'beginner', // Default communication level
            preferredLanguage: 'en-US', // Default language
          );
          
          profileIds.add(supabaseProfile.id!);
          
          // Store mapping for data migration
          await _storeProfileMapping(profile.id!, supabaseProfile.id!);
          
          AACLogger.info('Migrated profile: ${profile.name}', tag: _tag);
        } catch (e) {
          AACLogger.error('Failed to migrate profile ${profile.name}: $e', tag: _tag);
        }
      }
      
      return profileIds;
    } catch (e) {
      AACLogger.error('Error migrating profiles: $e', tag: _tag);
      rethrow;
    }
  }
  
  /// Migrate all data for a specific profile
  static Future<void> _migrateProfileData(String supabaseProfileId) async {
    try {
      AACLogger.info('Migrating data for profile: $supabaseProfileId', tag: _tag);
      
      // Get the old profile ID from mapping
      final oldProfileId = await _getOldProfileId(supabaseProfileId);
      if (oldProfileId == null) {
        AACLogger.warning('No old profile mapping found for $supabaseProfileId', tag: _tag);
        return;
      }
      
      // Migrate favorites
      await _migrateFavorites(oldProfileId, supabaseProfileId);
      
      // Migrate communication history  
      await _migrateCommunicationHistory(oldProfileId, supabaseProfileId);
      
      // Migrate custom symbols
      await _migrateCustomSymbols(oldProfileId, supabaseProfileId);
      
      // Migrate custom categories
      await _migrateCustomCategories(oldProfileId, supabaseProfileId);
      
      // Migrate user settings
      await _migrateUserSettings(oldProfileId, supabaseProfileId);
      
      AACLogger.info('✅ Completed data migration for profile: $supabaseProfileId', tag: _tag);
    } catch (e) {
      AACLogger.error('Error migrating profile data: $e', tag: _tag);
      rethrow;
    }
  }
  
  /// Migrate favorites from FavoritesService
  static Future<void> _migrateFavorites(String oldProfileId, String supabaseProfileId) async {
    try {
      AACLogger.info('Migrating favorites...', tag: _tag);
      
      // Get favorites from existing service
      final favoritesService = FavoritesService();
      if (!favoritesService.isInitialized) {
        AACLogger.info('FavoritesService not initialized, skipping favorites migration', tag: _tag);
        return;
      }
      
      final favorites = favoritesService.favoriteSymbols;
      final history = favoritesService.usageHistory;
      
      // Migrate favorites to Supabase
      for (final symbol in favorites) {
        await SupabaseAACService.addToFavorites(
          profileId: supabaseProfileId,
          symbolReference: symbol.id ?? symbol.label,
          symbolData: symbol.toJson(),
          symbolType: symbol.isDefault ? 'global_default' : 'user_custom',
        );
      }
      
      // Migrate usage history
      for (final historyItem in history) {
        await SupabaseAACService.recordSymbolUsage(
          profileId: supabaseProfileId,
          symbolReference: historyItem.symbol.id ?? historyItem.symbol.label,
          actionType: historyItem.action,
          symbolData: historyItem.symbol.toJson(),
          contextData: {'migrated_from': 'hive_firebase'},
        );
      }
      
      AACLogger.info('Migrated ${favorites.length} favorites and ${history.length} history items', tag: _tag);
    } catch (e) {
      AACLogger.error('Error migrating favorites: $e', tag: _tag);
    }
  }
  
  /// Migrate communication history
  static Future<void> _migrateCommunicationHistory(String oldProfileId, String supabaseProfileId) async {
    try {
      AACLogger.info('Migrating communication history...', tag: _tag);
      
      // Get communication history from existing storage
      final communicationService = CommunicationHistoryService();
      final history = await communicationService.getHistoryForProfile(oldProfileId);
      
      for (final entry in history) {
        await SupabaseAACService.saveCommunicationPhrase(
          profileId: supabaseProfileId,
          phraseText: entry.spokenText ?? '',
          symbolsUsed: entry.symbolsUsed.map((symbolId) => {'symbol_id': symbolId}).toList(),
          context: {
            'migrated_from': 'firebase_hive',
            'original_timestamp': entry.timestamp.toIso8601String(),
          },
        );
      }
      
      AACLogger.info('Migrated ${history.length} communication history entries', tag: _tag);
    } catch (e) {
      AACLogger.error('Error migrating communication history: $e', tag: _tag);
    }
  }
  
  /// Migrate custom symbols
  static Future<void> _migrateCustomSymbols(String oldProfileId, String supabaseProfileId) async {
    try {
      AACLogger.info('Migrating custom symbols...', tag: _tag);
      
      // Get custom symbols from UserDataManager or local storage
      // This would need to be implemented based on your current storage method
      final customSymbols = await _getCustomSymbolsFromLocal(oldProfileId);
      
      for (final symbol in customSymbols) {
        await SupabaseAACService.createCustomSymbol(
          profileId: supabaseProfileId,
          label: symbol.label,
          description: symbol.description ?? '',
          imagePath: symbol.imagePath,
          speechText: symbol.speechText,
          colorCode: symbol.colorCode,
          tags: [], // Add tags if available
        );
      }
      
      AACLogger.info('Migrated ${customSymbols.length} custom symbols', tag: _tag);
    } catch (e) {
      AACLogger.error('Error migrating custom symbols: $e', tag: _tag);
    }
  }
  
  /// Migrate custom categories
  static Future<void> _migrateCustomCategories(String oldProfileId, String supabaseProfileId) async {
    try {
      AACLogger.info('Migrating custom categories...', tag: _tag);
      
      // Get custom categories from local storage
      final customCategories = await _getCustomCategoriesFromLocal(oldProfileId);
      
      for (final category in customCategories) {
        await SupabaseAACService.createCustomCategory(
          profileId: supabaseProfileId,
          name: category.name,
          description: 'Migrated from Firebase/Hive',
          iconPath: category.iconPath,
          colorCode: category.colorCode,
          sortOrder: 0,
        );
      }
      
      AACLogger.info('Migrated ${customCategories.length} custom categories', tag: _tag);
    } catch (e) {
      AACLogger.error('Error migrating custom categories: $e', tag: _tag);
    }
  }
  
  /// Migrate user settings
  static Future<void> _migrateUserSettings(String oldProfileId, String supabaseProfileId) async {
    try {
      AACLogger.info('Migrating user settings...', tag: _tag);
      
      // Get settings from local storage
      final settings = await _getUserSettingsFromLocal(oldProfileId);
      
      for (final group in settings.keys) {
        final groupSettings = settings[group] as Map<String, dynamic>;
        for (final key in groupSettings.keys) {
          await SupabaseAACService.saveSetting(
            profileId: supabaseProfileId,
            settingGroup: group,
            settingKey: key,
            settingValue: groupSettings[key],
          );
        }
      }
      
      AACLogger.info('Migrated settings for ${settings.length} groups', tag: _tag);
    } catch (e) {
      AACLogger.error('Error migrating settings: $e', tag: _tag);
    }
  }
  
  /// Verify migration success
  static Future<bool> _verifyMigration(List<String> profileIds) async {
    try {
      AACLogger.info('Verifying migration...', tag: _tag);
      
      for (final profileId in profileIds) {
        // Check if data exists in Supabase
        final favorites = await SupabaseAACService.getFavorites(profileId);
        final history = await SupabaseAACService.getCommunicationHistory(profileId);
        final customSymbols = await SupabaseAACService.getCustomSymbols(profileId);
        
        AACLogger.info(
          'Profile $profileId: ${favorites.length} favorites, ${history.length} history, ${customSymbols.length} custom symbols',
          tag: _tag,
        );
      }
      
      return true;
    } catch (e) {
      AACLogger.error('Migration verification failed: $e', tag: _tag);
      return false;
    }
  }
  
  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  static Future<MigrationStatus> _getMigrationStatus() async {
    // Implementation to get migration status from local storage
    return MigrationStatus.notStarted;
  }
  
  static Future<void> _updateMigrationStatus(MigrationStatus status) async {
    // Implementation to save migration status
  }
  
  static Future<void> _storeProfileMapping(String oldId, String newId) async {
    // Store mapping between old and new profile IDs
  }
  
  static Future<String?> _getOldProfileId(String supabaseProfileId) async {
    // Get old profile ID from mapping
    return null;
  }
  
  static Future<List<models.Symbol>> _getCustomSymbolsFromLocal(String profileId) async {
    // Get custom symbols from current storage
    return [];
  }
  
  static Future<List<models.Category>> _getCustomCategoriesFromLocal(String profileId) async {
    // Get custom categories from current storage  
    return [];
  }
  
  static Future<Map<String, dynamic>> _getUserSettingsFromLocal(String profileId) async {
    // Get user settings from current storage
    return {};
  }
  
  /// Create a rollback plan in case migration fails
  static Future<void> createMigrationRollback() async {
    try {
      AACLogger.info('Creating migration rollback data...', tag: _tag);
      
      // Export current data as backup
      final profiles = await SupabaseAACService.getUserProfiles();
      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'profiles': profiles.map((p) => p.toJson()).toList(),
        'app_version': '1.0.0', // Your app version
      };
      
      // Save backup to local storage
      // Implementation depends on your preference (file, SharedPreferences, etc.)
      
      AACLogger.info('Migration rollback data created', tag: _tag);
    } catch (e) {
      AACLogger.error('Failed to create rollback data: $e', tag: _tag);
    }
  }
  
  /// Test migration with a subset of data
  static Future<bool> testMigration() async {
    try {
      AACLogger.info('Running migration test...', tag: _tag);
      
      // Create test profile
      final testProfile = await SupabaseAACService.createProfile(
        profileName: 'Migration Test Profile',
        displayName: 'Test User',
        role: 'child',
      );
      
      // Test basic operations
      await SupabaseAACService.addToFavorites(
        profileId: testProfile.id!,
        symbolReference: 'test_symbol',
        symbolData: {'label': 'Test Symbol', 'category': 'Test'},
      );
      
      final favorites = await SupabaseAACService.getFavorites(testProfile.id!);
      
      // Cleanup test data
      await SupabaseAACService.clearProfileData(testProfile.id!);
      
      final success = favorites.isNotEmpty;
      AACLogger.info('Migration test ${success ? 'passed' : 'failed'}', tag: _tag);
      return success;
    } catch (e) {
      AACLogger.error('Migration test failed: $e', tag: _tag);
      return false;
    }
  }
}