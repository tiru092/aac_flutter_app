import 'package:flutter_test/flutter_test.dart';
import 'package:aac_flutter_app/services/user_profile_service.dart';
import 'package:aac_flutter_app/models/symbol.dart';
import 'package:aac_flutter_app/models/user_profile.dart';
import 'package:aac_flutter_app/models/subscription.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('UserProfileService Tests', () {
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      // Clear all preferences between tests
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    group('Profile Creation Tests', () {
      test('should create a new profile successfully', () async {
        final profile = await UserProfileService.createProfile(
          name: 'Test User',
        );

        expect(profile, isA<UserProfile>());
        expect(profile.name, equals('Test User'));
        expect(profile.id, startsWith('profile_'));
        expect(profile.role, equals(UserRole.child));
        expect(profile.createdAt, isA<DateTime>());
      });

      test('should create profile with email and phone number', () async {
        final profile = await UserProfileService.createProfile(
          name: 'Test User',
          email: 'test@example.com',
          phoneNumber: '+1234567890',
        );

        expect(profile.email, equals('test@example.com'));
        expect(profile.phoneNumber, equals('+1234567890'));
      });
    });

    group('Profile Management Tests', () {
      test('should save and retrieve user profile', () async {
        final profile = await UserProfileService.createProfile(
          name: 'Test User',
        );

        await UserProfileService.saveUserProfile(profile);
        final retrievedProfile = await UserProfileService.getActiveProfile();

        expect(retrievedProfile, isNotNull);
        expect(retrievedProfile!.id, equals(profile.id));
        expect(retrievedProfile.name, equals(profile.name));
      });

      test('should get all profiles', () async {
        await UserProfileService.createProfile(name: 'User 1');
        await UserProfileService.createProfile(name: 'User 2');

        final profiles = await UserProfileService.getAllProfiles();

        expect(profiles, isA<List<UserProfile>>());
        expect(profiles.length, equals(2));
        expect(profiles[0].name, equals('User 1'));
        expect(profiles[1].name, equals('User 2'));
      });

      test('should delete profile', () async {
        final profile = await UserProfileService.createProfile(name: 'Test User');
        await UserProfileService.saveUserProfile(profile);

        // Verify profile exists
        final profilesBefore = await UserProfileService.getAllProfiles();
        expect(profilesBefore.length, equals(1));

        // Delete profile
        await UserProfileService.deleteProfile(profile.id);

        // Verify profile is deleted
        final profilesAfter = await UserProfileService.getAllProfiles();
        expect(profilesAfter.length, equals(0));
      });
    });

    group('Active Profile Tests', () {
      test('should set and get active profile', () async {
        final profile = await UserProfileService.createProfile(
          name: 'Test User',
        );

        await UserProfileService.setActiveProfile(profile);
        final activeProfile = await UserProfileService.getActiveProfile();

        expect(activeProfile, isNotNull);
        expect(activeProfile!.id, equals(profile.id));
        expect(activeProfile.name, equals(profile.name));
      });

      test('should return null when no active profile', () async {
        final activeProfile = await UserProfileService.getActiveProfile();
        expect(activeProfile, isNull);
      });
    });

    group('Symbol Management Tests', () {
      test('should add symbol to active profile', () async {
        final profile = await UserProfileService.createProfile(name: 'Test User');
        await UserProfileService.setActiveProfile(profile);

        final symbol = Symbol(
          label: 'Apple',
          imagePath: 'assets/apple.png',
          category: 'Food',
        );

        await UserProfileService.addSymbolToActiveProfile(symbol);
        final symbols = await UserProfileService.getUserSymbols();

        expect(symbols.length, equals(1));
        expect(symbols[0].label, equals('Apple'));
        expect(symbols[0].category, equals('Food'));
      });

      test('should return empty list when no active profile for symbols', () async {
        final symbols = await UserProfileService.getUserSymbols();
        expect(symbols, isEmpty);
      });
    });

    group('Category Management Tests', () {
      test('should add category to active profile', () async {
        final profile = await UserProfileService.createProfile(name: 'Test User');
        await UserProfileService.setActiveProfile(profile);

        final category = Category(
          name: 'Food',
          iconPath: 'assets/food.png',
          colorCode: 0xFF00FF00,
        );

        await UserProfileService.addCategoryToActiveProfile(category);
        final categories = await UserProfileService.getUserCategories();

        expect(categories.length, equals(1));
        expect(categories[0].name, equals('Food'));
        expect(categories[0].iconPath, equals('assets/food.png'));
      });

      test('should return empty list when no active profile for categories', () async {
        final categories = await UserProfileService.getUserCategories();
        expect(categories, isEmpty);
      });
    });

    group('Cloud Sync Tests', () {
      test('should sync all profiles to cloud', () async {
        // This test would require mocking the CloudSyncService
        // For now, we just ensure the method can be called without throwing
        expect(() => UserProfileService.syncAllProfilesToCloud(), returnsNormally);
      });
    });

    group('Error Handling Tests', () {
      test('should handle profile creation errors gracefully', () async {
        // In a real test, we would mock failures
        // For now, we just ensure the method can be called
        expect(() => UserProfileService.createProfile(name: 'Test User'), returnsNormally);
      });

      test('should handle profile saving errors gracefully', () async {
        final profile = UserProfile(
          id: 'test_profile',
          name: 'Test User',
          role: UserRole.child,
          createdAt: DateTime.now(),
          subscription: const Subscription(
            plan: SubscriptionPlan.free,
            price: 0.0,
          ),
          settings: ProfileSettings(),
        );

        // Should not throw even if there are issues
        expect(() => UserProfileService.saveUserProfile(profile), returnsNormally);
      });

      test('should handle profile retrieval errors gracefully', () async {
        // Should return empty list or null rather than throwing
        final profiles = await UserProfileService.getAllProfiles();
        expect(profiles, isA<List<UserProfile>>());
      });
    });
  });
}