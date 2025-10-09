import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart';
import '../firebase_supabase_migration_service.dart';
import '../user_profile_service.dart';
import 'hybrid_auth_service.dart';
import 'hybrid_database_service.dart';

/// Hybrid User Profile Service
/// Manages user profiles across Firebase and Supabase during migration
class HybridUserProfileService {
  static HybridUserProfileService? _instance;
  
  final HybridAuthService _authService;
  final HybridDatabaseService _databaseService;
  
  // Cache for active profile
  static UserProfile? _activeProfile;
  
  HybridUserProfileService._internal()
      : _authService = HybridAuthService(),
        _databaseService = HybridDatabaseService();
  
  factory HybridUserProfileService() {
    _instance ??= HybridUserProfileService._internal();
    return _instance!;
  }
  
  /// Get the active user profile with hybrid support
  Future<UserProfile?> getActiveProfile() async {
    try {
      // Return cached profile if available
      if (_activeProfile != null) {
        return _activeProfile;
      }
      
      final userId = _authService.currentUserId;
      if (userId == null) {
        if (kDebugMode) {
          print('HybridUserProfileService: No authenticated user found');
        }
        return null;
      }
      
      // Get profile from hybrid database service
      final profileData = await _databaseService.getUserProfile(userId);
      
      if (profileData != null) {
        _activeProfile = UserProfile.fromJson(profileData);
        if (kDebugMode) {
          print('HybridUserProfileService: Loaded profile for user: ${_activeProfile!.name}');
        }
        return _activeProfile;
      }
      
      // If no profile exists, fallback to original service for now
      if (kDebugMode) {
        print('HybridUserProfileService: No hybrid profile found, falling back to Firebase');
      }
      return await UserProfileService.getActiveProfile();
      
    } catch (e) {
      if (kDebugMode) {
        print('HybridUserProfileService ERROR: Error in hybrid getActiveProfile: $e');
      }
      
      // Fallback to original service
      return await UserProfileService.getActiveProfile();
    }
  }
  
  /// Set the active user profile with hybrid support
  Future<void> setActiveProfile(UserProfile profile) async {
    try {
      _activeProfile = profile;
      
      final userId = _authService.currentUserId;
      if (userId == null) {
        throw Exception('No authenticated user');
      }
      
      // Update local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_profile_id', profile.id);
      
      // Save to hybrid database service
      await _databaseService.upsertUserProfile(userId, profile.toJson());
      
      if (kDebugMode) {
        print('HybridUserProfileService: Active profile set: ${profile.name}');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('HybridUserProfileService ERROR: Error in hybrid setActiveProfile: $e');
      }
      
      // Still cache the profile in memory
      _activeProfile = profile;
      
      // Fallback to original service
      await UserProfileService.setActiveProfile(profile);
    }
  }
  
  /// Create a new user profile with hybrid support
  Future<UserProfile> createProfile({
    String? name,
    String? email,
  }) async {
    try {
      // For now, delegate to the original service and cache the result
      final profile = await UserProfileService.createProfile(
        name: name ?? 'User',
        email: email,
      );
      
      _activeProfile = profile;
      
      if (kDebugMode) {
        print('HybridUserProfileService: Created new profile via Firebase: ${profile.name}');
      }
      
      return profile;
      
    } catch (e) {
      if (kDebugMode) {
        print('HybridUserProfileService ERROR: Error in hybrid createProfile: $e');
      }
      rethrow;
    }
  }
  
  /// Update user profile with hybrid support
  Future<void> updateProfile(UserProfile updatedProfile) async {
    try {
      // For now, delegate to original service
      await UserProfileService.saveUserProfile(updatedProfile);
      _activeProfile = updatedProfile;
      
      if (kDebugMode) {
        print('HybridUserProfileService: Updated profile via Firebase: ${updatedProfile.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('HybridUserProfileService ERROR: Error updating profile: $e');
      }
      rethrow;
    }
  }
  
  /// Delete user profile with hybrid support  
  Future<void> deleteProfile(String profileId) async {
    try {
      // Clear cached profile if it matches
      if (_activeProfile?.id == profileId) {
        _activeProfile = null;
      }
      
      // Delegate to original service
      await UserProfileService.deleteProfile(profileId);
      
      if (kDebugMode) {
        print('HybridUserProfileService: Deleted profile: $profileId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('HybridUserProfileService ERROR: Error deleting profile: $e');
      }
      rethrow;
    }
  }
  
  /// Get all profiles for the current user
  Future<List<UserProfile>> getAllProfiles() async {
    try {
      // Delegate to original service
      return await UserProfileService.getAllProfiles();
    } catch (e) {
      if (kDebugMode) {
        print('HybridUserProfileService ERROR: Error getting all profiles: $e');
      }
      return [];
    }
  }
  
  /// Clear cached profile (force reload)
  void clearCache() {
    _activeProfile = null;
    if (kDebugMode) {
      print('HybridUserProfileService: Cleared profile cache');
    }
  }
  
  /// Get migration status for user profiles
  Map<String, dynamic> getProfileMigrationStatus() {
    return {
      'hasActiveProfile': _activeProfile != null,
      'activeProfileId': _activeProfile?.id,
      'migrationEnabled': migrationService.isMigrationEnabled,
      'primaryService': migrationService.isSupabasePrimary ? 'supabase' : 'firebase',
    };
  }
}