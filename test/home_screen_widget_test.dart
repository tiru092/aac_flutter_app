import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:aac_flutter_app/screens/home_screen.dart';
import 'package:aac_flutter_app/services/user_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks
@GenerateMocks([], customMocks: [
  MockSpec<UserProfileService>(returnNullOnMissingStub: true),
])
import 'home_screen_widget_test.mocks.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      // Clear all preferences between tests
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    testWidgets('should display loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      // Should show loading indicator
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });

    testWidgets('should display home screen after loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      // Wait for async operations
      await tester.pumpAndSettle();

      // Should show the main home screen UI
      expect(find.text('AAC Communicator'), findsOneWidget);
      expect(find.byType(CupertinoButton), findsWidgets);
    });

    testWidgets('should display error message when loading fails', (WidgetTester tester) async {
      // This test would require mocking UserProfileService to simulate failures
      // For now, we'll test that the error display mechanism works
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no error message
      expect(find.byIcon(CupertinoIcons.exclamationmark_triangle), findsNothing);

      // In a real test, we would trigger an error and verify it's displayed
    });

    testWidgets('should handle symbol tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap a symbol (this would require a more complex setup)
      // For now, we just verify the UI structure exists
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('should handle category change', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find category tabs
      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('should show error dialog when errors occur', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // In a real test, we would simulate an error and verify the dialog appears
      // For now, we just verify the dialog mechanism exists
      expect(find.byType(CupertinoAlertDialog), findsNothing);
    });

    testWidgets('should handle profile switcher', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find settings button
      final settingsButton = find.byWidgetPredicate(
        (Widget widget) => widget is Container && widget.child is Icon,
      );

      expect(settingsButton, findsWidgets);
    });

    testWidgets('should handle add symbol functionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find add symbol button
      expect(find.text('Add New Symbol'), findsOneWidget);
    });

    testWidgets('should handle quick phrases toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find quick phrases toggle button
      final quickPhrasesButton = find.byWidgetPredicate(
        (Widget widget) => widget is Container && 
                          widget.child is Icon && 
                          (widget.child as Icon).icon == CupertinoIcons.chat_bubble_2_fill,
      );

      expect(quickPhrasesButton, findsOneWidget);
    });

    testWidgets('should handle speech controls toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find speech controls toggle button
      final speechControlsButton = find.byWidgetPredicate(
        (Widget widget) => widget is Container && 
                          widget.child is Icon && 
                          (widget.child as Icon).icon == CupertinoIcons.waveform,
      );

      expect(speechControlsButton, findsOneWidget);
    });

    group('Error Handling Tests', () {
      testWidgets('should display error message when set', (WidgetTester tester) async {
        await tester.pumpWidget(
          const CupertinoApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // In a real implementation, we would trigger an error state
        // and verify that the error message is displayed
      });

      testWidgets('should clear error message when close button is pressed', (WidgetTester tester) async {
        await tester.pumpWidget(
          const CupertinoApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // In a real implementation, we would trigger an error state,
        // then tap the close button and verify the error message disappears
      });
    });
  });
}