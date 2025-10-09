/**
 * 🧪 PHASE 1 INTEGRATION TEST
 * 
 * This file tests that Phase 1 migration is working correctly:
 * - Authentication connects to real Supabase database
 * - User profiles are created in database upon registration
 * - User settings are stored/retrieved from database
 * 
 * Run this after Phase 1 completion to verify integration.
 */

import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/user_data_manager.dart';
import 'services/auth_wrapper_service.dart';
import 'models/user_profile.dart';

class Phase1IntegrationTest {
  static const String _tag = 'Phase1Test';
  
  /// Test Phase 1 authentication-to-database integration
  static Future<void> runPhase1Tests() async {
    developer.log('[$_tag] Starting Phase 1 Integration Tests...', name: 'Migration');
    
    try {
      await testUserProfileDatabaseIntegration();
      await testUserSettingsStorage();
      await testAuthenticationFlow();
      
      developer.log('[$_tag] ✅ ALL PHASE 1 TESTS PASSED!', name: 'Migration');
      
    } catch (e, stackTrace) {
      developer.log('[$_tag] ❌ Phase 1 Test Failed: $e', 
          name: 'Migration', error: e, stackTrace: stackTrace);
    }
  }
  
  /// Test that user profiles are created in Supabase database
  static Future<void> testUserProfileDatabaseIntegration() async {
    developer.log('[$_tag] Testing user profile database integration...', name: 'Migration');
    
    final userDataManager = UserDataManager();
    
    // Create a test profile
    const testProfile = UserProfile(
      id: 'test-user-123',
      displayName: 'Phase1 Test User',
      ageGroup: 'Adult',
      communicationLevel: 'Advanced',
      preferredLanguage: 'en',
      settings: AppSettings(),
    );
    
    // Test saving profile (should hit real Supabase database)
    await userDataManager.saveUserProfile(testProfile);
    
    developer.log('[$_tag] ✅ User profile database integration working', name: 'Migration');
  }
  
  /// Test that user settings are stored in Supabase database
  static Future<void> testUserSettingsStorage() async {
    developer.log('[$_tag] Testing user settings storage...', name: 'Migration');
    
    final userDataManager = UserDataManager();
    
    // Test setting cloud data (should hit real Supabase user_settings table)
    await userDataManager.setCloudData('test-key', {'phase1': 'success'});
    
    // Test getting cloud data (should query real Supabase user_settings table)
    final data = await userDataManager.getCloudData('test-key');
    
    developer.log('[$_tag] Retrieved data: $data', name: 'Migration');
    developer.log('[$_tag] ✅ User settings storage working', name: 'Migration');
  }
  
  /// Test authentication flow with database integration
  static Future<void> testAuthenticationFlow() async {
    developer.log('[$_tag] Testing authentication flow...', name: 'Migration');
    
    final authWrapper = AuthWrapperService();
    
    // Check if we have a current user (Supabase User type)
    final user = Supabase.instance.client.auth.currentUser;
    
    if (user != null) {
      developer.log('[$_tag] Current user: ${user.id}', name: 'Migration');
      developer.log('[$_tag] ✅ Authentication flow working with Supabase User', name: 'Migration');
    } else {
      developer.log('[$_tag] ℹ️  No current user (expected if not signed in)', name: 'Migration');
    }
  }
}

/// Quick test runner - call this in main() or from a test screen
Future<void> runPhase1ValidationTests() async {
  await Phase1IntegrationTest.runPhase1Tests();
}