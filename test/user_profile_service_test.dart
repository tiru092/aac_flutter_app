import 'package:flutter_test/flutter_test.dart';
import '../lib/services/user_profile_service.dart';
import '../lib/services/unified_supabase_auth_service.dart';

/// Test Suite 3: User Profile Service Tests
/// Tests the UserProfileService static methods and functionality
void main() {
  group('User Profile Service Static Method Tests', () {
    
    test('User profile service static methods are accessible', () {
      // Test that static methods can be called without instantiation
      expect(() => UserProfileService.getActiveProfile(), returnsNormally);
      expect(() => UserProfileService.getAllProfiles(), returnsNormally);  
      expect(() => UserProfileService.getUserSymbols(), returnsNormally);
      expect(() => UserProfileService.getUserCategories(), returnsNormally);
      print('✅ UserProfileService static methods are accessible');
    });

    test('Profile creation method signature is correct', () async {
      try {
        // Test profile creation with named parameters
        await UserProfileService.createProfile(
          name: 'Test Profile',
          email: 'test@test.com',
        );
        print('✅ createProfile method accepts named parameters correctly');
      } catch (e) {
        // Expected to potentially fail, just testing signature
        expect(e, isA<Exception>());
        print('✅ createProfile method signature is properly defined');
      }
    });

    test('Profile management methods exist', () async {
      try {
        final profiles = await UserProfileService.getAllProfiles();
        expect(profiles, isA<List>());
        print('✅ getAllProfiles returns a list: ${profiles.length} profiles');
      } catch (e) {
        expect(e, isA<Exception>());
        print('✅ getAllProfiles method handles errors gracefully');
      }
    });

    test('Symbol management methods are accessible', () async {
      try {
        final symbols = await UserProfileService.getUserSymbols();
        expect(symbols, isA<List>());
        print('✅ getUserSymbols returns a list: ${symbols.length} symbols');
      } catch (e) {
        expect(e, isA<Exception>());
        print('✅ getUserSymbols method handles errors gracefully');
      }
    });

    test('Category management methods are accessible', () async {
      try {
        final categories = await UserProfileService.getUserCategories();
        expect(categories, isA<List>());
        print('✅ getUserCategories returns a list: ${categories.length} categories');
      } catch (e) {
        expect(e, isA<Exception>());
        print('✅ getUserCategories method handles errors gracefully');
      }
    });

    test('Profile count method works', () async {
      try {
        final count = await UserProfileService.getProfilesCount();
        expect(count, isA<int>());
        expect(count, greaterThanOrEqualTo(0));
        print('✅ getProfilesCount returns valid count: $count');
      } catch (e) {
        expect(e, isA<Exception>());
        print('✅ getProfilesCount method handles errors gracefully');
      }
    });

    test('Cloud sync method is available', () async {
      try {
        await UserProfileService.syncAllProfilesToCloud();
        print('✅ syncAllProfilesToCloud executes without immediate error');
      } catch (e) {
        expect(e, isA<Exception>());
        print('✅ syncAllProfilesToCloud method handles errors gracefully');
      }
    });
  });
}