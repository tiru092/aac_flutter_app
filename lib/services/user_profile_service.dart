import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/symbol.dart';
import '../models/subscription.dart';

/// Service to manage user profiles and ensure data separation
class UserProfileService {
  static const String _currentProfileKey = 'current_profile_id';
  static const String _profilesKey = 'user_profiles';
  static UserProfile? _activeProfile;
  
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
        email: email,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
        subscription: const Subscription(
          plan: SubscriptionPlan.free,
          price: 0.0,
        ),
        settings: const ProfileSettings(),
        userSymbols: [],
        userCategories: [],
      );
      
      await saveUserProfile(newProfile);
      await setActiveProfile(newProfile);
      
      return newProfile;
    } catch (e) {
      print('Error in createProfile: $e');
      // Create a fallback profile that doesn't require storage
      return UserProfile(
        id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        createdAt: DateTime.now(),
        subscription: const Subscription(
          plan: SubscriptionPlan.free,
          price: 0.0,
        ),
        settings: const ProfileSettings(),
      );
    }
  }
  
  /// Save a user profile
  static Future<void> saveUserProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing profiles
      final profilesJson = prefs.getStringList(_profilesKey) ?? [];
      final profiles = profilesJson
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .toList();
      
      // Find and update or add the profile
      final index = profiles.indexWhere((p) => p['id'] == profile.id);
      final profileMap = profile.toJson();
      
      if (index >= 0) {
        profiles[index] = profileMap;
      } else {
        profiles.add(profileMap);
      }
      
      // Save the updated profiles list
      final updatedProfilesJson = profiles
          .map((p) => jsonEncode(p))
          .toList();
      
      await prefs.setStringList(_profilesKey, updatedProfilesJson);
    } catch (e) {
      print('Error in saveUserProfile: $e');
      // We'll continue even if saving fails
    }
  }
  
  /// Get all user profiles
  static Future<List<UserProfile>> getAllProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final profilesJson = prefs.getStringList(_profilesKey) ?? [];
    
    return profilesJson
        .map((json) => UserProfile.fromJson(jsonDecode(json)))
        .toList();
  }
  
  /// Delete a user profile
  static Future<void> deleteProfile(String profileId) async {
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
  }
  
  /// Add a symbol to the current user's profile
  static Future<void> addSymbolToActiveProfile(Symbol symbol) async {
    final profile = await getActiveProfile();
    if (profile == null) return;
    
    final updatedSymbols = [...profile.userSymbols, symbol];
    
    final updatedProfile = UserProfile(
      id: profile.id,
      name: profile.name,
      email: profile.email,
      phoneNumber: profile.phoneNumber,
      createdAt: profile.createdAt,
      lastActiveAt: DateTime.now(),
      subscription: profile.subscription,
      paymentHistory: profile.paymentHistory,
      settings: profile.settings,
      userSymbols: updatedSymbols,
      userCategories: profile.userCategories,
    );
    
    await saveUserProfile(updatedProfile);
    _activeProfile = updatedProfile;
  }
  
  /// Add a category to the current user's profile
  static Future<void> addCategoryToActiveProfile(Category category) async {
    final profile = await getActiveProfile();
    if (profile == null) return;
    
    final updatedCategories = [...profile.userCategories, category];
    
    final updatedProfile = UserProfile(
      id: profile.id,
      name: profile.name,
      email: profile.email,
      phoneNumber: profile.phoneNumber,
      createdAt: profile.createdAt,
      lastActiveAt: DateTime.now(),
      subscription: profile.subscription,
      paymentHistory: profile.paymentHistory,
      settings: profile.settings,
      userSymbols: profile.userSymbols,
      userCategories: updatedCategories,
    );
    
    await saveUserProfile(updatedProfile);
    _activeProfile = updatedProfile;
  }
  
  /// Load a profile by ID
  static Future<UserProfile?> _loadProfileById(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final profilesJson = prefs.getStringList(_profilesKey) ?? [];
    
    for (final json in profilesJson) {
      final Map<String, dynamic> profileMap = jsonDecode(json);
      if (profileMap['id'] == profileId) {
        return UserProfile.fromJson(profileMap);
      }
    }
    
    return null;
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
}