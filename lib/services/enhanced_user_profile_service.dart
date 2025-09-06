import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/symbol.dart';
import '../models/subscription.dart';
import '../models/user_profile.dart';
import '../utils/aac_logger.dart';
import 'cloud_sync_service.dart';
import 'encryption_service.dart';
import 'shared_resource_service.dart';

/// Enhanced User Profile Service with Shared Resource Architecture
/// 
/// Major Changes:
/// - User profiles no longer store default symbols/categories
/// - Symbols/categories are fetched from SharedResourceService
/// - Massive scalability improvement and data deduplication
/// - Backward compatibility maintained for migration
class UserProfileService {
  static const String _currentProfileKey = 'current_profile_id';
  static const String _profilesKey = 'user_profiles';
  static UserProfile? _activeProfile;
  static final CloudSyncService _cloudSyncService = CloudSyncService();
  static final EncryptionService _encryptionService = EncryptionService();
  
  /// Get the active user profile
  static Future<UserProfile?> getActiveProfile() async {
    try {
      if (_activeProfile != null) {
        return _activeProfile;
      }
      
      // If user is authenticated, try to load their data from cloud using their Firebase UID
      if (_cloudSyncService.isCloudSyncAvailable) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final cloudProfile = await _cloudSyncService.loadProfileFromCloud(user.uid);
          if (cloudProfile != null) {
            _activeProfile = cloudProfile;
            return _activeProfile;
          }
        }
      }
      
      // Fallback to local storage for offline mode
      final prefs = await SharedPreferences.getInstance();
      final currentProfileId = prefs.getString(_currentProfileKey);
      
      if (currentProfileId == null) {
        return null;
      }
      
      return await _loadProfileById(currentProfileId);
    } catch (e) {
      AACLogger.error('Error in getActiveProfile: $e', tag: 'UserProfileService');
      return null;
    }
  }
  
  /// Set the active user profile
  static Future<void> setActiveProfile(UserProfile profile) async {
    try {
      _activeProfile = profile;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentProfileKey, profile.id);
      
      // Update last active timestamp
      final updatedProfile = profile.copyWith(lastActiveAt: DateTime.now());
      await saveUserProfile(updatedProfile);
      _activeProfile = updatedProfile;
    } catch (e) {
      AACLogger.error('Error in setActiveProfile: $e', tag: 'UserProfileService');
    }
  }
  
  /// Create a new user profile (lightweight - no embedded symbols/categories)
  static Future<UserProfile> createProfile({
    required String name, 
    String? email,
    UserRole role = UserRole.child,
    ProfileSettings? settings,
  }) async {
    try {
      final profile = UserProfile(
        id: 'profile_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        role: role,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
        settings: settings ?? ProfileSettings(),
        // MAJOR CHANGE: Remove userSymbols and userCategories
        // These are now handled by SharedResourceService
        userSymbols: [], // Keep empty for backward compatibility
        userCategories: [], // Keep empty for backward compatibility
      );
      
      await saveUserProfile(profile);
      AACLogger.info('Created new profile: ${profile.name}', tag: 'UserProfileService');
      
      return profile;
    } catch (e) {
      AACLogger.error('Error in createProfile: $e', tag: 'UserProfileService');
      rethrow;
    }
  }
  
  /// Save user profile (lightweight operation now)
  static Future<void> saveUserProfile(UserProfile profile) async {
    try {
      // Save to local storage with encryption
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getStringList(_profilesKey) ?? [];
      
      // Encrypt profile data before saving
      final encryptedData = await _encryptionService.encrypt(jsonEncode(profile.toJson()));
      
      // Find existing profile and update it, or add new one
      final profileIndex = profilesJson.indexWhere((p) {
        try {
          final decryptedData = _encryptionService.decrypt(p);
          final profileData = jsonDecode(decryptedData);
          return profileData['id'] == profile.id;
        } catch (e) {
          AACLogger.warning('Could not decrypt profile during save: $e', tag: 'UserProfileService');
          return false;
        }
      });
      
      if (profileIndex != -1) {
        profilesJson[profileIndex] = encryptedData;
      } else {
        profilesJson.add(encryptedData);
      }
      
      await prefs.setStringList(_profilesKey, profilesJson);
      
      // Sync to cloud if available
      if (_cloudSyncService.isCloudSyncAvailable) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _cloudSyncService.syncProfileToCloud(profile, user.uid);
        }
      }
      
      AACLogger.debug('Profile saved successfully: ${profile.name}', tag: 'UserProfileService');
    } catch (e) {
      AACLogger.error('Error in saveUserProfile: $e', tag: 'UserProfileService');
    }
  }
  
  /// Get all profiles
  static Future<List<UserProfile>> getAllProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getStringList(_profilesKey) ?? [];
      
      final profiles = <UserProfile>[];
      for (final profileJson in profilesJson) {
        try {
          final decryptedData = await _encryptionService.decrypt(profileJson);
          final profileMap = jsonDecode(decryptedData);
          profiles.add(UserProfile.fromJson(profileMap));
        } catch (e) {
          AACLogger.warning('Could not decrypt profile: $e', tag: 'UserProfileService');
        }
      }
      
      AACLogger.debug('Loaded ${profiles.length} profiles', tag: 'UserProfileService');
      return profiles;
    } catch (e) {
      AACLogger.error('Error in getAllProfiles: $e', tag: 'UserProfileService');
      return [];
    }
  }
  
  /// Delete a profile
  static Future<void> deleteProfile(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getStringList(_profilesKey) ?? [];
      
      // Remove profile from list
      final updatedProfilesJson = profilesJson.where((p) {
        try {
          final decryptedData = _encryptionService.decrypt(p);
          final profileData = jsonDecode(decryptedData);
          return profileData['id'] != profileId;
        } catch (e) {
          AACLogger.warning('Could not decrypt profile during deletion: $e', tag: 'UserProfileService');
          return true; // Keep profile if we can't decrypt it
        }
      }).toList();
      
      await prefs.setStringList(_profilesKey, updatedProfilesJson);
      
      // If the active profile was deleted, clear it
      if (_activeProfile?.id == profileId) {
        _activeProfile = null;
        await prefs.remove(_currentProfileKey);
      }
      
      AACLogger.info('Profile deleted: $profileId', tag: 'UserProfileService');
    } catch (e) {
      AACLogger.error('Error in deleteProfile: $e', tag: 'UserProfileService');
    }
  }
  
  /// ============= NEW ENTERPRISE ARCHITECTURE METHODS =============
  
  /// Get user's complete symbol set (global defaults + custom)
  /// This replaces the old getUserSymbols() method
  static Future<List<Symbol>> getAllSymbolsForUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AACLogger.warning('No authenticated user - returning empty symbols', tag: 'UserProfileService');
        return [];
      }
      
      // Use SharedResourceService to get combined symbols
      final allSymbols = await SharedResourceService.getAllSymbolsForUser(user.uid);
      
      AACLogger.debug('Retrieved ${allSymbols.length} total symbols for user', tag: 'UserProfileService');
      return allSymbols;
      
    } catch (e) {
      AACLogger.error('Error in getAllSymbolsForUser: $e', tag: 'UserProfileService');
      return [];
    }
  }
  
  /// Get user's complete category set (global defaults + custom)
  /// This replaces the old getUserCategories() method
  static Future<List<Category>> getAllCategoriesForUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AACLogger.warning('No authenticated user - returning empty categories', tag: 'UserProfileService');
        return [];
      }
      
      // Use SharedResourceService to get combined categories
      final allCategories = await SharedResourceService.getAllCategoriesForUser(user.uid);
      
      AACLogger.debug('Retrieved ${allCategories.length} total categories for user', tag: 'UserProfileService');
      return allCategories;
      
    } catch (e) {
      AACLogger.error('Error in getAllCategoriesForUser: $e', tag: 'UserProfileService');
      return [];
    }
  }
  
  /// Get only user's custom symbols (not including defaults)
  static Future<List<Symbol>> getUserCustomSymbols() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AACLogger.warning('No authenticated user - returning empty custom symbols', tag: 'UserProfileService');
        return [];
      }
      
      return await SharedResourceService.getUserCustomSymbols(user.uid);
      
    } catch (e) {
      AACLogger.error('Error in getUserCustomSymbols: $e', tag: 'UserProfileService');
      return [];
    }
  }
  
  /// Get only user's custom categories (not including defaults)
  static Future<List<Category>> getUserCustomCategories() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AACLogger.warning('No authenticated user - returning empty custom categories', tag: 'UserProfileService');
        return [];
      }
      
      return await SharedResourceService.getUserCustomCategories(user.uid);
      
    } catch (e) {
      AACLogger.error('Error in getUserCustomCategories: $e', tag: 'UserProfileService');
      return [];
    }
  }
  
  /// Add a custom symbol for the current user
  /// This replaces the old addSymbolToActiveProfile() method
  static Future<bool> addCustomSymbol(Symbol symbol, {String? imagePath}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AACLogger.warning('No authenticated user - cannot add custom symbol', tag: 'UserProfileService');
        return false;
      }
      
      // Use SharedResourceService to add custom symbol with image upload
      final createdSymbol = await SharedResourceService.addUserCustomSymbol(user.uid, symbol, imagePath: imagePath);
      
      if (createdSymbol != null) {
        AACLogger.info('Successfully added custom symbol: ${createdSymbol.label} with ID: ${createdSymbol.id}', tag: 'UserProfileService');
        return true;
      } else {
        AACLogger.warning('Failed to add custom symbol: ${symbol.label}', tag: 'UserProfileService');
        return false;
      }
      
    } catch (e) {
      AACLogger.error('Error in addCustomSymbol: $e', tag: 'UserProfileService');
      return false;
    }
  }
  
  /// Add a custom category for the current user
  /// This replaces the old addCategoryToActiveProfile() method
  static Future<bool> addCustomCategory(Category category, {String? iconPath}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AACLogger.warning('No authenticated user - cannot add custom category', tag: 'UserProfileService');
        return false;
      }
      
      // Use SharedResourceService to add custom category with icon upload
      final createdCategory = await SharedResourceService.addUserCustomCategory(user.uid, category, iconPath: iconPath);
      
      if (createdCategory != null) {
        AACLogger.info('Successfully added custom category: ${createdCategory.name} with ID: ${createdCategory.id}', tag: 'UserProfileService');
        return true;
      } else {
        AACLogger.warning('Failed to add custom category: ${category.name}', tag: 'UserProfileService');
        return false;
      }
      
    } catch (e) {
      AACLogger.error('Error in addCustomCategory: $e', tag: 'UserProfileService');
      return false;
    }
  }
  
  /// Delete a custom symbol for the current user
  /// This replaces the old deleteSymbolFromActiveProfile() method
  static Future<bool> deleteCustomSymbol(String symbolId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AACLogger.warning('No authenticated user - cannot delete custom symbol', tag: 'UserProfileService');
        return false;
      }
      
      // Use SharedResourceService to delete custom symbol and associated image
      final success = await SharedResourceService.deleteUserCustomSymbol(user.uid, symbolId);
      
      if (success) {
        AACLogger.info('Successfully deleted custom symbol: $symbolId', tag: 'UserProfileService');
      }
      
      return success;
      
    } catch (e) {
      AACLogger.error('Error in deleteCustomSymbol: $e', tag: 'UserProfileService');
      return false;
    }
  }
  
  /// Delete a custom category for the current user
  static Future<bool> deleteCustomCategory(String categoryId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AACLogger.warning('No authenticated user - cannot delete custom category', tag: 'UserProfileService');
        return false;
      }
      
      // Use SharedResourceService to delete custom category and associated icon
      final success = await SharedResourceService.deleteUserCustomCategory(user.uid, categoryId);
      
      if (success) {
        AACLogger.info('Successfully deleted custom category: $categoryId', tag: 'UserProfileService');
      }
      
      return success;
      
    } catch (e) {
      AACLogger.error('Error in deleteCustomCategory: $e', tag: 'UserProfileService');
      return false;
    }
  }
  
  /// Get storage statistics for the current user
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'error': 'No authenticated user'};
      }
      
      return await SharedResourceService.getStorageStats(user.uid);
      
    } catch (e) {
      AACLogger.error('Error getting storage stats: $e', tag: 'UserProfileService');
      return {'error': e.toString()};
    }
  }
  
  /// ============= MIGRATION AND COMPATIBILITY METHODS =============
  
  /// Migrate user's old embedded symbols/categories to new shared architecture
  /// This should be run once during app update to migrate existing users
  static Future<void> migrateToSharedArchitecture() async {
    try {
      AACLogger.info('Starting migration to shared architecture...', tag: 'UserProfileService');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AACLogger.warning('No authenticated user for migration', tag: 'UserProfileService');
        return;
      }
      
      // Initialize global defaults first
      await SharedResourceService.initializeGlobalDefaults();
      
      final activeProfile = await getActiveProfile();
      if (activeProfile == null) {
        AACLogger.warning('No active profile for migration', tag: 'UserProfileService');
        return;
      }
      
      // Migrate custom symbols (non-default ones)
      final customSymbols = activeProfile.userSymbols.where((symbol) => !symbol.isDefault).toList();
      for (final symbol in customSymbols) {
        final createdSymbol = await SharedResourceService.addUserCustomSymbol(user.uid, symbol);
        if (createdSymbol != null) {
          AACLogger.debug('Migrated symbol: ${symbol.label} with ID: ${createdSymbol.id}', tag: 'UserProfileService');
        }
      }
      
      // Migrate custom categories (non-default ones)
      final customCategories = activeProfile.userCategories.where((category) => !category.isDefault).toList();
      for (final category in customCategories) {
        final createdCategory = await SharedResourceService.addUserCustomCategory(user.uid, category);
        if (createdCategory != null) {
          AACLogger.debug('Migrated category: ${category.name} with ID: ${createdCategory.id}', tag: 'UserProfileService');
        }
      }
      
      // Clean up old profile data
      final migratedProfile = activeProfile.copyWith(
        userSymbols: [], // Clear old embedded data
        userCategories: [], // Clear old embedded data
      );
      await saveUserProfile(migratedProfile);
      
      AACLogger.info('Migration completed successfully', tag: 'UserProfileService');
      
    } catch (e) {
      AACLogger.error('Error during migration: $e', tag: 'UserProfileService');
      rethrow;
    }
  }
  
  /// ============= LEGACY COMPATIBILITY METHODS =============
  /// These methods maintain backward compatibility during transition
  
  @deprecated
  /// Use getAllSymbolsForUser() instead
  static Future<List<Symbol>> getUserSymbols() async {
    AACLogger.warning('getUserSymbols() is deprecated. Use getAllSymbolsForUser() instead.', tag: 'UserProfileService');
    return getAllSymbolsForUser();
  }
  
  @deprecated
  /// Use getAllCategoriesForUser() instead
  static Future<List<Category>> getUserCategories() async {
    AACLogger.warning('getUserCategories() is deprecated. Use getAllCategoriesForUser() instead.', tag: 'UserProfileService');
    return getAllCategoriesForUser();
  }
  
  @deprecated
  /// Use addCustomSymbol() instead
  static Future<void> addSymbolToActiveProfile(Symbol symbol) async {
    AACLogger.warning('addSymbolToActiveProfile() is deprecated. Use addCustomSymbol() instead.', tag: 'UserProfileService');
    await addCustomSymbol(symbol);
  }
  
  @deprecated
  /// Use addCustomCategory() instead
  static Future<void> addCategoryToActiveProfile(Category category) async {
    AACLogger.warning('addCategoryToActiveProfile() is deprecated. Use addCustomCategory() instead.', tag: 'UserProfileService');
    await addCustomCategory(category);
  }
  
  /// ============= PRIVATE HELPER METHODS =============
  
  /// Load profile by ID from local storage
  static Future<UserProfile?> _loadProfileById(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getStringList(_profilesKey) ?? [];
      
      for (final profileJson in profilesJson) {
        try {
          final decryptedData = await _encryptionService.decrypt(profileJson);
          final profileMap = jsonDecode(decryptedData);
          if (profileMap['id'] == profileId) {
            return UserProfile.fromJson(profileMap);
          }
        } catch (e) {
          AACLogger.warning('Could not decrypt profile: $e', tag: 'UserProfileService');
        }
      }
      
      return null;
    } catch (e) {
      AACLogger.error('Error in _loadProfileById: $e', tag: 'UserProfileService');
      return null;
    }
  }
  
  /// Sync all profiles to cloud (manual sync)
  static Future<void> syncAllProfilesToCloud() async {
    try {
      if (_cloudSyncService.isCloudSyncAvailable) {
        await _cloudSyncService.syncAllProfilesToCloud();
        AACLogger.info('All profiles synced to cloud', tag: 'UserProfileService');
      }
    } catch (e) {
      AACLogger.error('Error syncing profiles to cloud: $e', tag: 'UserProfileService');
    }
  }
}
