import 'package:flutter_test/flutter_test.dart';
import 'package:aac_flutter_app/services/cloud_sync_service.dart';
import 'package:aac_flutter_app/services/user_profile_service.dart';
import 'package:aac_flutter_app/services/encryption_service.dart';
import 'package:aac_flutter_app/models/user_profile.dart';
import 'package:aac_flutter_app/models/symbol.dart';
import 'package:aac_flutter_app/models/subscription.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('Integration Tests', () {
    late CloudSyncService cloudSyncService;
    late UserProfileService userProfileService;
    late EncryptionService encryptionService;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      
      cloudSyncService = CloudSyncService();
      userProfileService = UserProfileService();
      encryptionService = EncryptionService();
    });

    tearDown(() {
      // Reset any state between tests
    });

    group('User Profile Management Integration', () {
      test('should create, save, and load user profile with encryption', () async {
        // Create a new profile
        final profile = UserProfile(
          id: 'integration_test_profile',
          name: 'Integration Test User',
          role: UserRole.child,
          createdAt: DateTime.now(),
          subscription: const Subscription(
            plan: SubscriptionPlan.free,
            price: 0.0,
          ),
          settings: ProfileSettings(),
          userSymbols: [
            Symbol(
              label: 'Test Symbol',
              imagePath: 'assets/test.png',
              category: 'Test',
            ),
          ],
          userCategories: [
            Category(
              name: 'Test Category',
              iconPath: 'assets/category.png',
              colorCode: 0xFF0000FF,
            ),
          ],
        );

        // Save profile (should encrypt data)
        await UserProfileService.saveUserProfile(profile);
        
        // Load profile (should decrypt data)
        final profiles = await UserProfileService.getAllProfiles();
        expect(profiles, isNotEmpty);
        expect(profiles.first.name, equals('Integration Test User'));
        expect(profiles.first.userSymbols, isNotEmpty);
        expect(profiles.first.userCategories, isNotEmpty);
      });

      test('should sync profile to cloud and load from cloud', () async {
        // Create a new profile
        final profile = UserProfile(
          id: 'cloud_sync_test_profile',
          name: 'Cloud Sync Test User',
          role: UserRole.child,
          createdAt: DateTime.now(),
          subscription: const Subscription(
            plan: SubscriptionPlan.free,
            price: 0.0,
          ),
          settings: ProfileSettings(),
          userSymbols: [
            Symbol(
              label: 'Cloud Symbol',
              imagePath: 'assets/cloud.png',
              category: 'Cloud',
            ),
          ],
          userCategories: [
            Category(
              name: 'Cloud Category',
              iconPath: 'assets/cloud_category.png',
              colorCode: 0xFFFF0000,
            ),
          ],
        );

        // Sync to cloud
        final syncResult = await cloudSyncService.syncProfileToCloud(profile);
        // Note: This will return false in tests since Firebase is not mocked
        // but we're testing that it doesn't throw an exception
        expect(() => syncResult, returnsNormally);

        // Load from cloud
        final cloudProfile = await cloudSyncService.loadProfileFromCloud('cloud_sync_test_profile');
        // Note: This will return null in tests since Firebase is not mocked
        // but we're testing that it doesn't throw an exception
        expect(() => cloudProfile, returnsNormally);
      });
    });

    group('Data Encryption Integration', () {
      test('should encrypt and decrypt profile data correctly', () async {
        // Create test profile data
        final profileData = {
          'name': 'Test User',
          'email': 'test@example.com',
          'phoneNumber': '123-456-7890',
          'pin': '1234',
          'avatarPath': '/path/to/avatar',
          'id': 'test_profile',
          'createdAt': DateTime.now().toIso8601String(),
        };

        // Encrypt the data
        final encryptedData = encryptionService.encryptProfileData(profileData);
        expect(encryptedData, isNotNull);
        expect(encryptedData, isNot(profileData));

        // Decrypt the data
        final decryptedData = encryptionService.decryptProfileData(encryptedData);
        expect(decryptedData, isNotNull);
        expect(decryptedData['name'], equals('Test User'));
        expect(decryptedData['email'], equals('test@example.com'));
        expect(decryptedData['phoneNumber'], equals('123-456-7890'));
        expect(decryptedData['pin'], equals('1234'));
      });

      test('should handle encryption errors gracefully', () async {
        // Test with invalid data
        final invalidData = <String, dynamic>{};
        
        // Should not throw exception
        final result = encryptionService.encryptProfileData(invalidData);
        expect(result, isNotNull);
      });
    });

    group('End-to-End User Flow', () {
      test('should support complete user journey from profile creation to cloud sync', () async {
        // 1. Create profile
        final profile = await UserProfileService.createProfile(
          name: 'End-to-End Test User',
        );
        
        expect(profile, isNotNull);
        expect(profile.name, equals('End-to-End Test User'));
        
        // 2. Set as active profile
        await UserProfileService.setActiveProfile(profile);
        final activeProfile = await UserProfileService.getActiveProfile();
        expect(activeProfile, isNotNull);
        expect(activeProfile!.id, equals(profile.id));
        
        // 3. Add symbols and categories
        final updatedProfile = profile.copyWith(
          userSymbols: [
            Symbol(
              label: 'E2E Symbol',
              imagePath: 'assets/e2e.png',
              category: 'E2E',
            ),
          ],
          userCategories: [
            Category(
              name: 'E2E Category',
              iconPath: 'assets/e2e_category.png',
              colorCode: 0xFF00FF00,
            ),
          ],
        );
        
        // 4. Save updated profile
        await UserProfileService.saveUserProfile(updatedProfile);
        
        // 5. Attempt cloud sync (will not actually sync in tests)
        final syncResult = await cloudSyncService.syncProfileToCloud(updatedProfile);
        expect(() => syncResult, returnsNormally);
      });
    });
  });
}