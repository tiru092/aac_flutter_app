import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:aac_flutter_app/screens/home_screen.dart';
import 'package:aac_flutter_app/services/user_profile_service.dart';
import 'package:aac_flutter_app/models/symbol.dart';
import 'package:aac_flutter_app/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Custom Category Persistence Tests', () {
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      
      // Clear any existing profiles
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    tearDown(() async {
      // Clear all preferences between tests
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    testWidgets('should save and load custom categories across app restarts', (WidgetTester tester) async {
      // Create a user profile
      final profile = await UserProfileService.createProfile(
        name: 'Test User',
      );
      await UserProfileService.setActiveProfile(profile);

      // Create custom categories
      final customCategory1 = Category(
        name: 'My Category 1',
        iconPath: 'assets/icons/custom1.png',
        colorCode: 0xFF00FF00,
        dateCreated: DateTime.now(),
        isDefault: false,
      );

      final customCategory2 = Category(
        name: 'My Category 2',
        iconPath: 'assets/icons/custom2.png',
        colorCode: 0xFFFF0000,
        dateCreated: DateTime.now(),
        isDefault: false,
      );

      // Add categories to profile
      await UserProfileService.addCategoryToActiveProfile(customCategory1);
      await UserProfileService.addCategoryToActiveProfile(customCategory2);

      // Load home screen for the first time
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      // Wait for loading
      await tester.pumpAndSettle();

      // Verify custom categories are displayed
      expect(find.text('My Category 1'), findsOneWidget);
      expect(find.text('My Category 2'), findsOneWidget);

      // Simulate app restart by creating a new home screen instance
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      // Wait for loading
      await tester.pumpAndSettle();

      // Verify custom categories are still displayed after app restart
      expect(find.text('My Category 1'), findsOneWidget);
      expect(find.text('My Category 2'), findsOneWidget);
    });

    testWidgets('should persist custom categories after user relogin', (WidgetTester tester) async {
      // Create first user profile
      final profile1 = await UserProfileService.createProfile(
        name: 'Test User 1',
      );
      await UserProfileService.setActiveProfile(profile1);

      // Create custom categories for first user
      final customCategory1 = Category(
        name: 'User1 Category',
        iconPath: 'assets/icons/user1.png',
        colorCode: 0xFF00FF00,
        dateCreated: DateTime.now(),
        isDefault: false,
      );

      await UserProfileService.addCategoryToActiveProfile(customCategory1);

      // Create second user profile
      final profile2 = await UserProfileService.createProfile(
        name: 'Test User 2',
      );

      // Load home screen with first user
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify first user's categories are displayed
      expect(find.text('User1 Category'), findsOneWidget);

      // Switch to second user
      await UserProfileService.setActiveProfile(profile2);
      
      // Recreate home screen to simulate user switch
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify first user's categories are not displayed for second user
      expect(find.text('User1 Category'), findsNothing);

      // Switch back to first user
      await UserProfileService.setActiveProfile(profile1);
      
      // Recreate home screen to simulate user switch
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify first user's categories are displayed again
      expect(find.text('User1 Category'), findsOneWidget);
    });
  });
}
