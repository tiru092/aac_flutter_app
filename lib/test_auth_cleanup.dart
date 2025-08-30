import 'services/user_profile_service.dart';

/// Test utility to clean up profiles and test authentication flow
class AuthCleanupTester {
  
  /// Clear all profiles for clean testing
  static Future<void> clearAllProfilesForTesting() async {
    try {
      print('=== CLEARING ALL PROFILES FOR TESTING ===');
      
      final beforeCount = await UserProfileService.getProfilesCount();
      print('Profiles before cleanup: $beforeCount');
      
      await UserProfileService.clearAllProfiles();
      
      final afterCount = await UserProfileService.getProfilesCount();
      print('Profiles after cleanup: $afterCount');
      
      print('=== CLEANUP COMPLETE ===');
      
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }
  
  /// Test profile creation
  static Future<void> testProfileCreation() async {
    try {
      print('=== TESTING PROFILE CREATION ===');
      
      // Create a test profile
      final profile = await UserProfileService.createProfile(
        name: 'Test User',
        email: 'test@example.com',
      );
      
      print('Created profile: ${profile.name} (${profile.id})');
      
      final allProfiles = await UserProfileService.getAllProfiles();
      print('Total profiles after creation: ${allProfiles.length}');
      
      for (final p in allProfiles) {
        print('- Profile: ${p.name} (${p.id})');
      }
      
      print('=== PROFILE CREATION TEST COMPLETE ===');
      
    } catch (e) {
      print('Error during profile creation test: $e');
    }
  }
}
