import 'package:flutter/material.dart';
import 'lib/services/auth_wrapper_service.dart';
import 'lib/services/user_profile_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== Testing Authentication Flow and Cleanup ===');
  
  try {
    // Initialize the AuthWrapperService
    print('\n1. Initializing AuthWrapperService...');
    final authService = AuthWrapperService();
    await authService.initialize();
    
    // Check current profiles
    print('\n2. Getting all profiles...');
    final profiles = await UserProfileService.getAllProfiles();
    print('Found ${profiles.length} profiles:');
    for (var profile in profiles) {
      print('  - ID: ${profile.id}, Name: ${profile.name}, Role: ${profile.role}');
    }
    
    // Test cleanup
    print('\n3. Testing cleanup of duplicate Default Users...');
    await authService.cleanupDuplicateDefaultUsers();
    
    // Check profiles after cleanup
    print('\n4. Getting profiles after cleanup...');
    final profilesAfterCleanup = await UserProfileService.getAllProfiles();
    print('Found ${profilesAfterCleanup.length} profiles after cleanup:');
    for (var profile in profilesAfterCleanup) {
      print('  - ID: ${profile.id}, Name: ${profile.name}, Role: ${profile.role}');
    }
    
    // Check authentication state
    print('\n5. Checking authentication state...');
    print('Is signed in: ${authService.isSignedIn}');
    print('Has local profile: ${authService.hasLocalProfile}');
    print('Current profile: ${authService.currentProfile?.name ?? 'None'}');
    print('Is offline mode: ${authService.isOfflineMode}');
    
    print('\n=== Test completed successfully ===');
    
  } catch (e) {
    print('Error during test: $e');
  }
}
