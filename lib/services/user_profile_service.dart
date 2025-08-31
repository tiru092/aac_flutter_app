import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/symbol.dart';
import '../models/subscription.dart';
import '../models/user_profile.dart'; // Add missing import
import 'cloud_sync_service.dart'; // Add cloud sync service
import 'encryption_service.dart'; // Add encryption service

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
      
      final prefs = await SharedPreferences.getInstance();
      final currentProfileId = prefs.getString(_currentProfileKey);
      
      if (currentProfileId == null) {
        return null;
      }
      
      // Try to load from cloud first if available
      if (_cloudSyncService.isCloudSyncAvailable) {
        final cloudProfile = await _cloudSyncService.loadProfileFromCloud(currentProfileId);
        if (cloudProfile != null) {
          _activeProfile = cloudProfile;
          return _activeProfile;
        }
      }
      
      // Fallback to local storage
      return await _loadProfileById(currentProfileId);
    } catch (e) {
      print('Error in getActiveProfile: $e');
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
      print('Error in setActiveProfile: $e');
      // Still set the active profile in memory even if storage fails
      _activeProfile = profile;
    }
  }
  
  /// Create a new user profile
  static Future<UserProfile> createProfile({
    required String name,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final id = 'profile_${DateTime.now().millisecondsSinceEpoch}';
      
      final newProfile = UserProfile(
        id: id,
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
      print('Error in createProfile: $e');
      // Create a fallback profile that doesn't require storage
      return UserProfile(
        id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
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
      print('Error in saveUserProfile: $e');
      // We'll continue even if saving fails
    }
  }
  
  /// Get all user profiles with decryption
  static Future<List<UserProfile>> getAllProfiles() async {
    try {
      // Try to load from cloud first if available
      if (_cloudSyncService.isCloudSyncAvailable) {
        final cloudProfiles = await _cloudSyncService.loadAllProfilesFromCloud();
        if (cloudProfiles.isNotEmpty) {
          return cloudProfiles;
        }
      }
      
      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final profilesJson = prefs.getStringList(_profilesKey) ?? [];
      
      final profiles = <UserProfile>[];
      for (final json in profilesJson) {
        try {
          final profileMap = jsonDecode(json) as Map<String, dynamic>;
          // Decrypt sensitive data
          final decryptedProfileMap = await _encryptionService.decryptProfileData(profileMap);
          final profile = UserProfile.fromJson(decryptedProfileMap);
          profiles.add(profile);
        } catch (e) {
          print('Error decrypting profile: $e');
          // Skip this profile if decryption fails
        }
      }
      
      return profiles;
    } catch (e) {
      print('Error in getAllProfiles: $e');
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
      print('Error in deleteProfile: $e');
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
      print('Error in addSymbolToActiveProfile: $e');
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
      print('Error in addCategoryToActiveProfile: $e');
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
      print('Error in updateSymbolInActiveProfile: $e');
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
      print('Error in deleteSymbolFromActiveProfile: $e');
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
      print('Error in _loadProfileById: $e');
      return null;
    }
  }
  
  /// Get user-specific symbols
  static Future<List<Symbol>> getUserSymbols() async {
    try {
      final profile = await getActiveProfile();
      return profile?.userSymbols ?? [];
    } catch (e) {
      print('Error in getUserSymbols: $e');
      return [];
    }
  }
  
  /// Get user-specific categories
  static Future<List<Category>> getUserCategories() async {
    try {
      final profile = await getActiveProfile();
      return profile?.userCategories ?? [];
    } catch (e) {
      print('Error in getUserCategories: $e');
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
      print('Error in syncAllProfilesToCloud: $e');
    }
  }

  /// Clear all profiles (for testing/reset purposes)
  static Future<void> clearAllProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profilesKey);
      await prefs.remove(_currentProfileKey);
      _activeProfile = null;
      print('All profiles cleared successfully');
    } catch (e) {
      print('Error clearing profiles: $e');
    }
  }

  /// Get profiles count for debugging
  static Future<int> getProfilesCount() async {
    try {
      final profiles = await getAllProfiles();
      return profiles.length;
    } catch (e) {
      print('Error getting profiles count: $e');
      return 0;
    }
  }
}