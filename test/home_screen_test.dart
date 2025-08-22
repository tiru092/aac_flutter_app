import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:aac_flutter_app/screens/home_screen.dart';
import 'package:aac_flutter_app/utils/aac_helper.dart';

void main() {
  group('HomeScreen Integration Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Mock all required channels
      const MethodChannel('flutter_tts').setMockMethodCallHandler((methodCall) async {
        return true;
      });
      
      const MethodChannel('flutter/platform').setMockMethodCallHandler((methodCall) async {
        return null;
      });
      
      const MethodChannel('xyz.luan/audioplayers').setMockMethodCallHandler((methodCall) async {
        return true;
      });

      // Mock Hive for testing
      const MethodChannel('plugins.flutter.io/path_provider')
          .setMockMethodCallHandler((methodCall) async {
        return '/tmp';
      });
    });

    testWidgets('should display home screen correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      // Wait for loading and animations
      await tester.pumpAndSettle();

      // Check for main UI elements
      expect(find.text('👋 Hello!'), findsOneWidget);
      expect(find.text('Let\'s communicate! 💬'), findsOneWidget);
      expect(find.text('Tap symbols to speak!'), findsOneWidget);
    });

    testWidgets('should have working segmented control', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap on different segments
      expect(find.text('🏠 Categories'), findsOneWidget);
      expect(find.text('📚 All Symbols'), findsOneWidget);

      // Tap on All Symbols
      await tester.tap(find.text('📚 All Symbols'));
      await tester.pumpAndSettle();

      // The segmented control should respond
      // (Exact behavior depends on implementation)
    });

    testWidgets('should have functional settings button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find settings button
      final settingsButton = find.byIcon(CupertinoIcons.gear_alt_fill);
      expect(settingsButton, findsOneWidget);

      // Tap settings button
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      // Should navigate to accessibility settings
      expect(find.text('🔧 Accessibility Settings'), findsOneWidget);
    });

    testWidgets('should have functional floating action button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap floating action button
      final fabText = find.text('✨ Add New');
      expect(fabText, findsOneWidget);

      await tester.tap(fabText);
      await tester.pumpAndSettle();

      // Should show action sheet
      expect(find.text('✨ Add New Symbol'), findsOneWidget);
      expect(find.text('Choose how to add a new symbol'), findsOneWidget);
    });

    testWidgets('should handle loading state gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      // Pump just once to see loading state
      await tester.pump();

      // Should handle loading without errors
      expect(tester.takeException(), isNull);
      
      // Wait for full load
      await tester.pumpAndSettle();
    });

    testWidgets('should display communication grid based on selected view', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should be on categories view
      // Communication grid should be visible
      expect(find.byType(CommunicationGrid), findsOneWidget);

      // Switch to symbols view
      await tester.tap(find.text('📚 All Symbols'));
      await tester.pumpAndSettle();

      // Should still show communication grid
      expect(find.byType(CommunicationGrid), findsOneWidget);
    });

    testWidgets('should handle error states gracefully', (WidgetTester tester) async {
      // Test with error-prone conditions
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should not throw any unhandled exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('should support accessibility features', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Check accessibility tree
      expect(tester.semantics, hasAGoodToStringDeep);

      // Main buttons should be accessible
      final settingsSemantics = tester.getSemantics(
        find.byIcon(CupertinoIcons.gear_alt_fill)
      );
      expect(settingsSemantics.hasFlag(SemanticsFlag.isButton), isTrue);
    });

    testWidgets('should handle view switching animations', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Switch views multiple times
      await tester.tap(find.text('📚 All Symbols'));
      await tester.pump(const Duration(milliseconds: 100));
      
      await tester.tap(find.text('🏠 Categories'));
      await tester.pump(const Duration(milliseconds: 100));
      
      // Should handle animations without errors
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    group('Settings Integration', () {
      testWidgets('should navigate to and from settings screen', (WidgetTester tester) async {
        await tester.pumpWidget(
          const CupertinoApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Go to settings
        await tester.tap(find.byIcon(CupertinoIcons.gear_alt_fill));
        await tester.pumpAndSettle();

        // Should be on settings screen
        expect(find.text('🔧 Accessibility Settings'), findsOneWidget);

        // Go back
        await tester.tap(find.byIcon(CupertinoIcons.back));
        await tester.pumpAndSettle();

        // Should be back on home screen
        expect(find.text('👋 Hello!'), findsOneWidget);
      });

      testWidgets('should persist settings changes', (WidgetTester tester) async {
        // Enable high contrast in settings
        await AACHelper.setHighContrast(true);

        await tester.pumpWidget(
          const CupertinoApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // The UI should adapt to high contrast
        expect(AACHelper.isHighContrastEnabled, isTrue);

        // Reset
        await AACHelper.setHighContrast(false);
      });
    });

    group('Add Symbol Flow', () {
      testWidgets('should show add symbol action sheet', (WidgetTester tester) async {
        await tester.pumpWidget(
          const CupertinoApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Tap add button
        await tester.tap(find.text('✨ Add New'));
        await tester.pumpAndSettle();

        // Should show action sheet with options
        expect(find.text('✨ Add New Symbol'), findsOneWidget);
        expect(find.text('Choose how to add a new symbol'), findsOneWidget);
      });

      testWidgets('should close action sheet on cancel', (WidgetTester tester) async {
        await tester.pumpWidget(
          const CupertinoApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Open action sheet
        await tester.tap(find.text('✨ Add New'));
        await tester.pumpAndSettle();

        // Find and tap cancel (usually just tapping outside)
        await tester.tapAt(const Offset(50, 100)); // Tap outside
        await tester.pumpAndSettle();

        // Action sheet should be closed
        expect(find.text('✨ Add New Symbol'), findsNothing);
      });
    });

    group('Performance Tests', () {
      testWidgets('should handle rapid view switching', (WidgetTester tester) async {
        await tester.pumpWidget(
          const CupertinoApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Rapidly switch views
        for (int i = 0; i < 10; i++) {
          await tester.tap(find.text('📚 All Symbols'));
          await tester.pump(const Duration(milliseconds: 50));
          
          await tester.tap(find.text('🏠 Categories'));
          await tester.pump(const Duration(milliseconds: 50));
        }

        await tester.pumpAndSettle();

        // Should handle without throwing
        expect(tester.takeException(), isNull);
        expect(find.text('👋 Hello!'), findsOneWidget);
      });

      testWidgets('should handle rapid button presses', (WidgetTester tester) async {
        await tester.pumpWidget(
          const CupertinoApp(
            home: HomeScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Rapidly press settings button
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.byIcon(CupertinoIcons.gear_alt_fill));
          await tester.pump(const Duration(milliseconds: 10));
        }

        await tester.pumpAndSettle();

        // Should still work correctly
        expect(find.text('🔧 Accessibility Settings'), findsOneWidget);
      });
    });
  });
}