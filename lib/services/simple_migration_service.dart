/// Simple Migration Service for AAC App
/// Helps transition from Firebase+Hive to Supabase architecture
/// Compatible with existing database schema

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'supabase_aac_service_compatible.dart';

class SimpleMigrationService {
  static const String _tag = 'SimpleMigrationService';

  /// Check if migration is needed for current user
  static Future<bool> isMigrationNeeded() async {
    try {
      final profile = await SupabaseAACService.getCurrentUserProfile();
      
      // If no profile exists, migration might be needed
      if (profile == null) {
        print('[$_tag] No Supabase profile found - migration may be needed');
        return true;
      }

      // Check if user has any data in Supabase
      final syncStatus = await SupabaseAACService.getSyncStatus();
      final totalItems = (syncStatus['symbols'] ?? 0) +
                        (syncStatus['categories'] ?? 0) +
                        (syncStatus['favorites'] ?? 0);

      print('[$_tag] Found $totalItems items in Supabase for user');
      return totalItems == 0; // Migration needed if no data exists
      
    } catch (e) {
      print('[$_tag] Error checking migration status: $e');
      return false;
    }
  }

  /// Initialize user profile in Supabase
  static Future<bool> initializeUserProfile({
    String? displayName,
    String? email,
    Map<String, dynamic> preferences = const {},
  }) async {
    try {
      print('[$_tag] Initializing user profile in Supabase...');
      
      final currentUser = SupabaseAACService.currentUser;
      if (currentUser == null) {
        print('[$_tag] No authenticated user');
        return false;
      }

      await SupabaseAACService.upsertUserProfile(
        name: displayName ?? currentUser.userMetadata?['full_name'] ?? 'AAC User',
        email: email ?? currentUser.email ?? '',
        role: 'communicator',
        settings: preferences,
      );

      print('[$_tag] User profile initialized successfully');
      return true;
      
    } catch (e) {
      print('[$_tag] Failed to initialize user profile: $e');
      return false;
    }
  }

  /// Migrate local favorites to Supabase
  static Future<int> migrateFavorites(List<String> favoriteSymbolIds) async {
    try {
      print('[$_tag] Migrating ${favoriteSymbolIds.length} favorites...');
      
      int migratedCount = 0;
      for (final symbolId in favoriteSymbolIds) {
        try {
          await SupabaseAACService.addToFavorites(symbolId);
          migratedCount++;
        } catch (e) {
          print('[$_tag] Failed to migrate favorite $symbolId: $e');
        }
      }

      print('[$_tag] Migrated $migratedCount favorites successfully');
      return migratedCount;
      
    } catch (e) {
      print('[$_tag] Favorites migration error: $e');
      return 0;
    }
  }

  /// Migrate communication phrases to Supabase
  static Future<int> migratePhrases(List<String> phrases) async {
    try {
      print('[$_tag] Migrating ${phrases.length} phrases...');
      
      int migratedCount = 0;
      for (final phrase in phrases) {
        try {
          await SupabaseAACService.savePhrase(text: phrase, isFavorite: true);
          migratedCount++;
        } catch (e) {
          print('[$_tag] Failed to migrate phrase "$phrase": $e');
        }
      }

      print('[$_tag] Migrated $migratedCount phrases successfully');
      return migratedCount;
      
    } catch (e) {
      print('[$_tag] Phrases migration error: $e');
      return 0;
    }
  }

  /// Migrate user settings to Supabase
  static Future<bool> migrateSettings(Map<String, dynamic> settings) async {
    try {
      print('[$_tag] Migrating user settings...');
      
      for (final entry in settings.entries) {
        try {
          // Group settings by category for better organization
          String settingGroup = 'general';
          if (entry.key.contains('speech')) {
            settingGroup = 'speech';
          } else if (entry.key.contains('ui') || entry.key.contains('display')) {
            settingGroup = 'ui';
          } else if (entry.key.contains('accessibility')) {
            settingGroup = 'accessibility';
          }

          await SupabaseAACService.saveSetting(
            settingGroup: settingGroup,
            settingKey: entry.key,
            settingValue: entry.value,
          );
        } catch (e) {
          print('[$_tag] Failed to migrate setting ${entry.key}: $e');
        }
      }

      print('[$_tag] Settings migration completed');
      return true;
      
    } catch (e) {
      print('[$_tag] Settings migration error: $e');
      return false;
    }
  }

  /// Create sample custom content for new users
  static Future<void> createSampleContent() async {
    try {
      print('[$_tag] Creating sample custom content...');
      
      // Create sample custom category
      final customCategory = await SupabaseAACService.createCustomCategory(
        name: 'My Custom Words',
        colorCode: 0xFF4CAF50, // Green
        iconPath: 'assets/categories/custom.png',
      );

      // Create sample custom symbol
      await SupabaseAACService.createCustomSymbol(
        label: 'My Special Word',
        description: 'A custom symbol created just for you',
        imagePath: 'assets/symbols/custom_example.png',
        categoryId: customCategory['id'],
        speechText: 'My special word',
      );

      print('[$_tag] Sample custom content created');
      
    } catch (e) {
      print('[$_tag] Failed to create sample content: $e');
    }
  }

  /// Perform complete migration with verification
  static Future<Map<String, dynamic>> performCompleteMigration({
    String? displayName,
    List<String> favoriteSymbolIds = const [],
    List<String> phrases = const [],
    Map<String, dynamic> settings = const {},
  }) async {
    final results = <String, dynamic>{
      'success': false,
      'profile_created': false,
      'favorites_migrated': 0,
      'phrases_migrated': 0,
      'settings_migrated': false,
      'errors': <String>[],
      'started_at': DateTime.now().toIso8601String(),
    };

    try {
      print('[$_tag] Starting complete migration process...');

      // 1. Initialize user profile
      final profileCreated = await initializeUserProfile(
        displayName: displayName,
        preferences: settings,
      );
      results['profile_created'] = profileCreated;

      if (!profileCreated) {
        results['errors'].add('Failed to create user profile');
        return results;
      }

      // 2. Migrate favorites
      if (favoriteSymbolIds.isNotEmpty) {
        final migratedFavorites = await migrateFavorites(favoriteSymbolIds);
        results['favorites_migrated'] = migratedFavorites;
      }

      // 3. Migrate phrases
      if (phrases.isNotEmpty) {
        final migratedPhrases = await migratePhrases(phrases);
        results['phrases_migrated'] = migratedPhrases;
      }

      // 4. Migrate settings
      if (settings.isNotEmpty) {
        final settingsMigrated = await migrateSettings(settings);
        results['settings_migrated'] = settingsMigrated;
      }

      // 5. Create sample content for new users
      await createSampleContent();

      // 6. Verify migration
      final syncStatus = await SupabaseAACService.getSyncStatus();
      results['final_status'] = syncStatus;

      results['success'] = true;
      results['completed_at'] = DateTime.now().toIso8601String();
      
      print('[$_tag] Migration completed successfully');
      print('[$_tag] Final status: $syncStatus');

    } catch (e) {
      results['errors'].add('Migration failed: $e');
      print('[$_tag] Migration failed: $e');
    }

    return results;
  }

  /// Quick setup for new users
  static Future<bool> quickSetupNewUser(String displayName) async {
    try {
      print('[$_tag] Setting up new user: $displayName');
      
      // Create profile
      final profileCreated = await initializeUserProfile(
        displayName: displayName,
        preferences: {
          'speech_rate': 1.0,
          'speech_pitch': 1.0,
          'ui_theme': 'default',
          'show_labels': true,
          'grid_columns': 3,
        },
      );

      if (profileCreated) {
        // Create sample content
        await createSampleContent();
        print('[$_tag] New user setup completed');
        return true;
      }
      
      return false;
      
    } catch (e) {
      print('[$_tag] New user setup failed: $e');
      return false;
    }
  }

  /// Get migration status report
  static Future<Map<String, dynamic>> getMigrationStatusReport() async {
    try {
      final profile = await SupabaseAACService.getCurrentUserProfile();
      final syncStatus = await SupabaseAACService.getSyncStatus();
      
      return {
        'has_profile': profile != null,
        'profile_created_at': profile?['created_at'],
        'sync_status': syncStatus,
        'migration_complete': profile != null && (syncStatus['symbols'] ?? 0) > 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}