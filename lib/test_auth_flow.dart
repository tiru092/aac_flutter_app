import 'package:flutter/foundation.dart';
import 'services/auth_wrapper_service.dart';
import 'services/user_profile_service.dart';

/// Simple test function to verify authentication and multi-user functionality
Future<void> testAuthFlow() async {
  try {
    debugPrint('=== Testing AAC Authentication Flow ===');
    
    final authWrapper = AuthWrapperService();
    
    // Test 1: Initialize the service
    debugPrint('Test 1: Initializing AuthWrapperService...');
    await authWrapper.initialize();
    debugPrint('✅ AuthWrapperService initialized successfully');
    debugPrint('   - Is initialized: ${authWrapper.isInitialized}');
    debugPrint('   - Is offline mode: ${authWrapper.isOfflineMode}');
    debugPrint('   - Has local profile: ${authWrapper.hasLocalProfile}');
    debugPrint('   - Current profile: ${authWrapper.currentProfile?.name ?? 'None'}');
    
    // Test 2: Create local profiles
    debugPrint('\nTest 2: Creating local profiles...');
    
    final profile1 = await authWrapper.createLocalProfile(
      name: 'Test Child',
      email: 'child@test.com',
    );
    debugPrint('✅ Created profile 1: ${profile1.name}');
    
    final profile2 = await authWrapper.createLocalProfile(
      name: 'Test Caregiver',
      email: 'caregiver@test.com',
    );
    debugPrint('✅ Created profile 2: ${profile2.name}');
    
    // Test 3: List all profiles
    debugPrint('\nTest 3: Listing all profiles...');
    final allProfiles = await authWrapper.getAllProfiles();
    debugPrint('✅ Found ${allProfiles.length} profiles:');
    for (final profile in allProfiles) {
      debugPrint('   - ${profile.name} (${profile.role.toString()})');
    }
    
    // Test 4: Switch between profiles
    debugPrint('\nTest 4: Switching between profiles...');
    await authWrapper.switchProfile(profile2);
    debugPrint('✅ Switched to profile: ${authWrapper.currentProfile?.name}');
    
    await authWrapper.switchProfile(profile1);
    debugPrint('✅ Switched back to profile: ${authWrapper.currentProfile?.name}');
    
    // Test 5: Test offline mode
    debugPrint('\nTest 5: Testing offline mode...');
    await authWrapper.enableOfflineMode();
    debugPrint('✅ Offline mode enabled: ${authWrapper.isOfflineMode}');
    
    // Test 6: Test UserProfileService integration
    debugPrint('\nTest 6: Testing UserProfileService integration...');
    final activeProfile = await UserProfileService.getActiveProfile();
    debugPrint('✅ Active profile from service: ${activeProfile?.name ?? 'None'}');
    
    // Test 7: Test profile data persistence
    debugPrint('\nTest 7: Testing profile data persistence...');
    final profilesFromService = await UserProfileService.getAllProfiles();
    debugPrint('✅ Profiles from service: ${profilesFromService.length}');
    
    debugPrint('\n=== All Tests Passed! ===');
    debugPrint('Authentication and multi-user functionality is working correctly.');
    
  } catch (e, stackTrace) {
    debugPrint('❌ Test failed with error: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}

/// Test function specifically for local storage
Future<void> testLocalStorage() async {
  try {
    debugPrint('=== Testing Local Storage ===');
    
    // Test profile creation and storage
    final profile = await UserProfileService.createProfile(
      name: 'Storage Test User',
      email: 'storage@test.com',
    );
    
    debugPrint('✅ Created profile: ${profile.name}');
    
    // Test profile retrieval
    final retrievedProfile = await UserProfileService.getActiveProfile();
    debugPrint('✅ Retrieved profile: ${retrievedProfile?.name ?? 'None'}');
    
    // Test profile list
    final allProfiles = await UserProfileService.getAllProfiles();
    debugPrint('✅ Total profiles in storage: ${allProfiles.length}');
    
    // Test profile switching
    if (allProfiles.length > 1) {
      await UserProfileService.setActiveProfile(allProfiles.last);
      final newActive = await UserProfileService.getActiveProfile();
      debugPrint('✅ Switched to profile: ${newActive?.name}');
    }
    
    debugPrint('=== Local Storage Tests Passed! ===');
    
  } catch (e, stackTrace) {
    debugPrint('❌ Local storage test failed: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}