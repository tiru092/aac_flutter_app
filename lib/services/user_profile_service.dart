import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/symbol.dart';
import '../models/subscription.dart';
import '../models/user_profile.dart';
import '../utils/aac_logger.dart';
import 'cloud_sync_service.dart';
import 'encryption_service.dart';

/// Service to manage user profiles and ensure data separation
class UserProfileService {
  static const String _currentProfileKey = 'current_profile_id';
  static const String _profilesKey = 'user_profiles';
  static UserProfile? _activeProfile;
  static final CloudSyncService _cloudSyncService = CloudSyncService(); // Add cloud sync service
  static final EncryptionService _encryptionService = EncryptionService(); // Add encryption service
  
  /// Get the active user profile
  static Future<UserProfile?> getActiveProfile() async {
    try {
      if (_activeProfile != null) {
        return _activeProfile;
      }
      
      // Check if user is authenticated first
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // For authenticated users, ensure profile ID matches Firebase UID
        final prefs = await SharedPreferences.getInstance();
        final currentProfileId = prefs.getString(_currentProfileKey);
        
        // Fix profile ID mismatch - should always use Firebase UID for authenticated users
        if (currentProfileId != user.uid) {
          AACLogger.info('Fixing profile ID mismatch: $currentProfileId -> ${user.uid}', tag: 'UserProfileService');
          await prefs.setString(_currentProfileKey, user.uid);
        }
        
        // Try to load from cloud using Firebase UID - DISABLED for simple structure
        // NOTE: Temporarily disabled complex CloudSyncService to use simple Firebase structure
        if (false && _cloudSyncService.isCloudSyncAvailable) {
          var cloudProfile = await _cloudSyncService.loadProfileFromCloud(user.uid);
          
          // If not found by UID, try to find by email
          if (cloudProfile == null && user.email != null) {
            AACLogger.info('Profile not found by UID, trying email lookup: ${user.email}', tag: 'UserProfileService');
            cloudProfile = await _cloudSyncService.findProfileByEmail(user.email!);
          }
          
          if (cloudProfile != null) {
            _activeProfile = cloudProfile;
            AACLogger.info('Loaded profile from cloud: ${cloudProfile.name}', tag: 'UserProfileService');
            return _activeProfile;
          }
        }
        
        // Fallback to local storage using Firebase UID
        return await _loadProfileById(user.uid);
      } else {
        // For offline mode, use local profile ID
        final prefs = await SharedPreferences.getInstance();
        final currentProfileId = prefs.getString(_currentProfileKey);
        
        if (currentProfileId == null) {
          return null;
        }
        
        return await _loadProfileById(currentProfileId);
      }
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
      
      // Save the updated profile
      await saveUserProfile(profile);
      
      // Sync to cloud if available
      if (_cloudSyncService.isCloudSyncAvailable) {
        await _cloudSyncService.syncProfileToCloud(profile);
      }
    } catch (e) {
      AACLogger.error('Error in setActiveProfile: $e', tag: 'UserProfileService');
      // Still set the active profile in memory even if storage fails
      _activeProfile = profile;
    }
  }
  
  /// Create a new user profile
  static Future<UserProfile> createProfile({
    required String name,
    String? email,
    String? phoneNumber,
    String? id, // Optional ID parameter - use Firebase UID when available
  }) async {
    try {
      // Use provided ID (Firebase UID) if available, otherwise generate timestamp-based ID for offline users
      final profileId = id ?? 'profile_${DateTime.now().millisecondsSinceEpoch}';
      
      final newProfile = UserProfile(
        id: profileId,
        name: name,
        role: UserRole.child, // Default to child role
        email: email,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
        subscription: const Subscription(
          plan: SubscriptionPlan.free,
          price: 0.0,
        ),
        settings: ProfileSettings(),
        userSymbols: [],
        userCategories: [],
      );
      
      await saveUserProfile(newProfile);
      await setActiveProfile(newProfile);
      
      // Sync to cloud if available
      if (_cloudSyncService.isCloudSyncAvailable) {
        await _cloudSyncService.syncProfileToCloud(newProfile);
      }
      
      return newProfile;
    } catch (e) {
      AACLogger.error('Error in createProfile: $e', tag: 'UserProfileService');
      // Create a fallback profile that doesn't require storage
      final fallbackId = id ?? 'fallback_${DateTime.now().millisecondsSinceEpoch}';
      return UserProfile(
        id: fallbackId,
        name: name,
        role: UserRole.child, // Default to child role
        createdAt: DateTime.now(),
        subscription: const Subscription(
          plan: SubscriptionPlan.free,
          price: 0.0,
        ),
        settings: ProfileSettings(),
        userSymbols: [],
        userCategories: [],
      );
    }
  }
  
  /// Save a user profile with encryption
  static Future<void> saveUserProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing profiles
      final profilesJson = prefs.getStringList(_profilesKey) ?? [];
      final profiles = profilesJson
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .toList();
      
      // Convert profile to map and encrypt sensitive data
      final profileMap = profile.toJson();
      final encryptedProfileMap = await _encryptionService.encryptProfileData(profileMap);
      
      // Find and update or add the profile
      final index = profiles.indexWhere((p) => p['id'] == profile.id);
      
      if (index >= 0) {
        profiles[index] = encryptedProfileMap;
      } else {
        profiles.add(encryptedProfileMap);
      }
      
      // Save the updated profiles list
      final updatedProfilesJson = profiles
          .map((p) => jsonEncode(p))
          .toList();
      
      await prefs.setStringList(_profilesKey, updatedProfilesJson);
      
      // Sync to cloud if available (cloud service should handle its own encryption)
      if (_cloudSyncService.isCloudSyncAvailable) {
        await _cloudSyncService.syncProfileToCloud(profile);
      }
    } catch (e) {
      AACLogger.error('Error in saveUserProfile: $e', tag: 'UserProfileService');
      // We'll continue even if saving fails
    }
  }
  
  /// Get all user profiles with decryption and enhanced error handling
  static Future<List<UserProfile>> getAllProfiles() async {
    try {
      // Try to load from cloud first if available
      if (_cloudSyncService.isCloudSyncAvailable) {
        try {
          final cloudProfiles = await _cloudSyncService.loadAllProfilesFromCloud();
          if (cloudProfiles.isNotEmpty) {
            return cloudProfiles;
          }
        } catch (e) {
          AACLogger.error('Error loading from cloud: $e', tag: 'UserProfileService');
          // Continue to local fallback
        }
      }
      
      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getStringList(_profilesKey) ?? [];
      
      final profiles = <UserProfile>[];
      for (final json in profilesJson) {
        try {
          final profileMap = jsonDecode(json) as Map<String, dynamic>;
          // Decrypt sensitive data with enhanced error handling
          final decryptedProfileMap = await _encryptionService.decryptProfileData(profileMap);
          final profile = UserProfile.fromJson(decryptedProfileMap);
          profiles.add(profile);
        } catch (e) {
          AACLogger.error('Error decrypting profile: $e', tag: 'UserProfileService');
          // Skip this profile if decryption fails but continue with others
          continue;
        }
      }
      
      return profiles;
    } catch (e) {
      AACLogger.error('Error in getAllProfiles: $e', tag: 'UserProfileService');
      return [];
    }
  }
  
  /// Delete a user profile
  static Future<void> deleteProfile(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing profiles
      final profilesJson = prefs.getStringList(_profilesKey) ?? [];
      final profiles = profilesJson
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .toList();
      
      // Remove the profile
      profiles.removeWhere((p) => p['id'] == profileId);
      
      // Save the updated profiles list
      final updatedProfilesJson = profiles
          .map((p) => jsonEncode(p))
          .toList();
      
      await prefs.setStringList(_profilesKey, updatedProfilesJson);
      
      // If the active profile was deleted, clear it
      if (_activeProfile?.id == profileId) {
        _activeProfile = null;
        await prefs.remove(_currentProfileKey);
      }
    } catch (e) {
      AACLogger.error('Error in deleteProfile: $e', tag: 'UserProfileService');
    }
  }
  
  /// Add a symbol to the current user's profile
  static Future<void> addSymbolToActiveProfile(Symbol symbol) async {
    try {
      final profile = await getActiveProfile();
      if (profile == null) return;
      
      final updatedSymbols = [...profile.userSymbols, symbol];
      
      final updatedProfile = profile.copyWith(
        userSymbols: updatedSymbols,
        lastActiveAt: DateTime.now(),
      );
      
      await saveUserProfile(updatedProfile);
      _activeProfile = updatedProfile;
    } catch (e) {
      AACLogger.error('Error in addSymbolToActiveProfile: $e');
    }
  }
  
  /// Add a category to the current user's profile
  static Future<void> addCategoryToActiveProfile(Category category) async {
    try {
      final profile = await getActiveProfile();
      if (profile == null) return;
      
      // Check if category already exists to prevent duplication
      final existingCategoryIndex = profile.userCategories.indexWhere(
        (existingCategory) => existingCategory.name == category.name && !existingCategory.isDefault
      );
      
      List<Category> updatedCategories;
      if (existingCategoryIndex != -1) {
        // Category already exists, update it instead of adding duplicate
        updatedCategories = List<Category>.from(profile.userCategories);
        updatedCategories[existingCategoryIndex] = category;
      } else {
        // Category doesn't exist, add it
        updatedCategories = [...profile.userCategories, category];
      }
      
      final updatedProfile = profile.copyWith(
        userCategories: updatedCategories,
        lastActiveAt: DateTime.now(),
      );
      
      await saveUserProfile(updatedProfile);
      _activeProfile = updatedProfile;
    } catch (e) {
      AACLogger.error('Error in addCategoryToActiveProfile: $e');
    }
  }
  
  /// Update a symbol in the current user's profile
  static Future<void> updateSymbolInActiveProfile(Symbol oldSymbol, Symbol updatedSymbol) async {
    try {
      final profile = await getActiveProfile();
      if (profile == null) return;
      
      // Find and replace the symbol
      final updatedSymbols = [...profile.userSymbols];
      final index = updatedSymbols.indexWhere((s) => s.id == oldSymbol.id);
      if (index != -1) {
        updatedSymbols[index] = updatedSymbol;
      }
      
      final updatedProfile = profile.copyWith(
        userSymbols: updatedSymbols,
        lastActiveAt: DateTime.now(),
      );
      
      await saveUserProfile(updatedProfile);
      _activeProfile = updatedProfile;
    } catch (e) {
      AACLogger.error('Error in updateSymbolInActiveProfile: $e');
    }
  }
  
  /// Delete a symbol from the current user's profile
  static Future<void> deleteSymbolFromActiveProfile(Symbol symbol) async {
    try {
      final profile = await getActiveProfile();
      if (profile == null) return;
      
      // Remove the symbol
      final updatedSymbols = profile.userSymbols.where((s) => s.id != symbol.id).toList();
      
      final updatedProfile = profile.copyWith(
        userSymbols: updatedSymbols,
        lastActiveAt: DateTime.now(),
      );
      
      await saveUserProfile(updatedProfile);
      _activeProfile = updatedProfile;
    } catch (e) {
      AACLogger.error('Error in deleteSymbolFromActiveProfile: $e');
    }
  }
  
  /// Load a profile by ID with decryption
  static Future<UserProfile?> _loadProfileById(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getStringList(_profilesKey) ?? [];
      
      for (final json in profilesJson) {
        final Map<String, dynamic> profileMap = jsonDecode(json);
        if (profileMap['id'] == profileId) {
          // Decrypt sensitive data
          final decryptedProfileMap = await _encryptionService.decryptProfileData(profileMap);
          return UserProfile.fromJson(decryptedProfileMap);
        }
      }
      
      return null;
    } catch (e) {
      AACLogger.error('Error in _loadProfileById: $e');
      return null;
    }
  }
  
  /// Get user-specific symbols
  static Future<List<Symbol>> getUserSymbols() async {
    try {
      final profile = await getActiveProfile();
      return profile?.userSymbols ?? [];
    } catch (e) {
      AACLogger.error('Error in getUserSymbols: $e');
      return [];
    }
  }
  
  /// Get user-specific categories
  static Future<List<Category>> getUserCategories() async {
    try {
      final profile = await getActiveProfile();
      return profile?.userCategories ?? [];
    } catch (e) {
      AACLogger.error('Error in getUserCategories: $e');
      return [];
    }
  }
  
  /// Sync all profiles to cloud (manual sync)
  static Future<void> syncAllProfilesToCloud() async {
    try {
      if (_cloudSyncService.isCloudSyncAvailable) {
        await _cloudSyncService.syncAllProfilesToCloud();
      }
    } catch (e) {
      AACLogger.error('Error in syncAllProfilesToCloud: $e');
    }
  }

  /// Clear all profiles (for testing/reset purposes)
  static Future<void> clearAllProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profilesKey);
      await prefs.remove(_currentProfileKey);
      _activeProfile = null;
      AACLogger.info('All profiles cleared successfully', tag: 'UserProfile');
    } catch (e) {
      AACLogger.error('Error clearing profiles: $e');
    }
  }

  /// Get profiles count for debugging
  static Future<int> getProfilesCount() async {
    try {
      final profiles = await getAllProfiles();
      return profiles.length;
    } catch (e) {
      AACLogger.error('Error getting profiles count: $e');
      return 0;
    }
  }
  
  /// Reset user profile service (called on logout)
  static Future<void> reset() async {
    try {
      AACLogger.info('UserProfileService: Resetting active profile cache...');
      _activeProfile = null;
      
      // Clear current profile ID from preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentProfileKey);
      
      AACLogger.info('UserProfileService: Reset completed');
    } catch (e) {
      AACLogger.error('Error resetting UserProfileService: $e');
    }
  }
}
