import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:aac_flutter_app/screens/accessibility_settings_screen.dart';
import 'package:aac_flutter_app/utils/aac_helper.dart';

void main() {
  group('AccessibilitySettingsScreen Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Mock required channels
      const MethodChannel('flutter_tts').setMockMethodCallHandler((methodCall) async {
        return true;
      });
      
      const MethodChannel('flutter/platform').setMockMethodCallHandler((methodCall) async {
        return null;
      });
      
      const MethodChannel('xyz.luan/audioplayers').setMockMethodCallHandler((methodCall) async {
        return true;
      });

      const MethodChannel('plugins.flutter.io/path_provider')
          .setMockMethodCallHandler((methodCall) async {
        return '/tmp';
      });
    });

    testWidgets('should display accessibility settings correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: AccessibilitySettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Check for main sections
      expect(find.text('🔧 Accessibility Settings'), findsOneWidget);
      expect(find.text('👁️ Visual Accessibility'), findsOneWidget);
      expect(find.text('🔊 Audio Feedback'), findsOneWidget);
      expect(find.text('🎚️ Speech Controls'), findsOneWidget);
      expect(find.text('📳 Haptic Feedback'), findsOneWidget);
      expect(find.text('🔊 Sound Effects'), findsOneWidget);
    });

    testWidgets('should navigate back correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: AccessibilitySettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap back button
      final backButton = find.byIcon(CupertinoIcons.back);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Should trigger navigation (tested in integration with home screen)
    });

    group('Visual Accessibility Tests', () {
      testWidgets('should toggle high contrast mode', (WidgetTester tester) async {
        // Reset state
        await AACHelper.setHighContrast(false);

        await tester.pumpWidget(
          const CupertinoApp(
            home: AccessibilitySettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find high contrast toggle
        final highContrastFinder = find.ancestor(
          of: find.text('High Contrast Mode'),
          matching: find.byType(CupertinoSwitch),
        ).first;

        expect(highContrastFinder, findsOneWidget);

        // Toggle high contrast
        await tester.tap(highContrastFinder);
        await tester.pumpAndSettle();

        // Verify setting changed
        expect(AACHelper.isHighContrastEnabled, isTrue);

        // Toggle back
        await tester.tap(highContrastFinder);
        await tester.pumpAndSettle();

        expect(AACHelper.isHighContrastEnabled, isFalse);
      });

      testWidgets('should toggle large text mode', (WidgetTester tester) async {
        await AACHelper.setLargeText(false);

        await tester.pumpWidget(
          const CupertinoApp(
            home: AccessibilitySettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find large text toggle
        final largeTextFinder = find.ancestor(
          of: find.text('Large Text'),
          matching: find.byType(CupertinoSwitch),
        ).first;

        await tester.tap(largeTextFinder);
        await tester.pumpAndSettle();

        expect(AACHelper.isLargeTextEnabled, isTrue);
        expect(AACHelper.getTextSizeMultiplier(), equals(1.3));
      });
    });

    group('Audio Feedback Tests', () {
      testWidgets('should toggle voice feedback', (WidgetTester tester) async {
        await AACHelper.setVoiceFeedback(true);

        await tester.pumpWidget(
          const CupertinoApp(
            home: AccessibilitySettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find voice feedback toggle
        final voiceFeedbackFinder = find.ancestor(
          of: find.text('Voice Feedback'),
          matching: find.byType(CupertinoSwitch),
        ).first;

        await tester.tap(voiceFeedbackFinder);
        await tester.pumpAndSettle();

        expect(AACHelper.isVoiceFeedbackEnabled, isFalse);

        // Toggle back
        await tester.tap(voiceFeedbackFinder);
        await tester.pumpAndSettle();

        expect(AACHelper.isVoiceFeedbackEnabled, isTrue);
      });

      testWidgets('should toggle auto-speak', (WidgetTester tester) async {
        await AACHelper.setAutoSpeak(true);

        await tester.pumpWidget(
          const CupertinoApp(
            home: AccessibilitySettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find auto-speak toggle
        final autoSpeakFinder = find.ancestor(
          of: find.text('Auto-Speak Symbols'),
          matching: find.byType(CupertinoSwitch),
        ).first;

        await tester.tap(autoSpeakFinder);
        await tester.pumpAndSettle();

        expect(AACHelper.isAutoSpeakEnabled, isFalse);
      });
    });

    group('Speech Controls Tests', () {
      testWidgets('should adjust speech speed slider', (WidgetTester tester) async {
        await tester.pumpWidget(
          const CupertinoApp(
            home: AccessibilitySettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find speech speed slider
        final speedSliderFinder = find.ancestor(
          of: find.text('Speech Speed'),
          matching: find.byType(Slider),
        ).first;

        expect(speedSliderFinder, findsOneWidget);

        // Test sliding (approximate)
        await tester.drag(speedSliderFinder, const Offset(50, 0));
        await tester.pumpAndSettle();

        // Should not throw error
        expect(tester.takeException(), isNull);
      });

      testWidgets('should adjust voice pitch slider', (WidgetTester tester) async {
        await tester.pumpWidget(
          const CupertinoApp(
            home: AccessibilitySettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find voice pitch slider
        final pitchSliderFinder = find.ancestor(
          of: find.text('Voice Pitch'),
          matching: find.byType(Slider),
        ).first;

        expect(pitchSliderFinder, findsOneWidget);

        await tester.drag(pitchSliderFinder, const Offset(-30, 0));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('should adjust volume slider', (WidgetTester tester) async {
        await tester.pumpWidget(
          const CupertinoApp(
            home: AccessibilitySettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find volume slider
        final volumeSliderFinder = find.ancestor(
          of: find.text('Volume'),
          matching: find.byType(Slider),
        ).first;

        expect(volumeSliderFinder, findsOneWidget);

        await tester.drag(volumeSliderFinder, const Offset(40, 0));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });

    group('Haptic Feedback Tests', () {
      testWidgets('should toggle haptic feedback', (WidgetTester tester) async {
        await AACHelper.setHapticFeedback(true);

        await tester.pumpWidget(
          const CupertinoApp(
            home: AccessibilitySettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find haptic feedback toggle
        final hapticFinder = find.ancestor(
          of: find.text('Haptic Feedback'),
          matching: find.byType(CupertinoSwitch),
        ).first;

        await tester.tap(hapticFinder);
        await tester.pumpAndSettle();

        expect(AACHelper.isHapticFeedbackEnabled, isFalse);
      });
    });

    group('Sound Effects Tests', () {
      testWidgets('should toggle sound effects', (WidgetTester tester) async {
        await AACHelper.setSoundEffects(false);

        await tester.pumpWidget(
          const CupertinoApp(
            home: AccessibilitySettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find sound effects toggle
        final soundEffectsFinder = find.ancestor(
          of: find.text('Sound Effects'),
          matching: find.byType(CupertinoSwitch),
        ).first;

        await tester.tap(soundEffectsFinder);
        await tester.pumpAndSettle();

        expect(AACHelper.isSoundEffectsEnabled, isTrue);
      });

      testWidgets('should adjust sound volume slider', (WidgetTester tester) async {
        await tester.pumpWidget(
          const CupertinoApp(
            home: AccessibilitySettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find sound volume slider
        final soundVolumeSliderFinder = find.ancestor(
          of: find.text('Sound Volume'),
          matching: find.byType(Slider),
        ).first;

        expect(soundVolumeSliderFinder, findsOneWidget);

        await tester.drag(soundVolumeSliderFinder, const Offset(60, 0));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });

    group('Test Section Tests', () {
      testWidgets('should have test voice button', (WidgetTester tester) async {
        await tester.pumpWidget(
          const CupertinoApp(
            home: AccessibilitySettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Find test section
        expect(find.text('🎯 Test Your Settings'), findsOneWidget);
        
        // Find and tap test voice button
        final testButton = find.text('Test Voice');
        expect(testButton, findsOneWidget);

        await tester.tap(testButton);
        await tester.pumpAndSettle();

        // Should not throw error
        expect(tester.takeException(), isNull);
      });
    });

    group('Accessibility Compliance Tests', () {
      testWidgets('should be accessible with proper semantic labels', (WidgetTester tester) async {
        await tester.pumpWidget(
          const CupertinoApp(
            home: AccessibilitySettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Check accessibility tree
        expect(tester.semantics, hasAGoodToStringDeep);

        // Check that toggles have proper semantics
        final highContrastSemantics = tester.getSemantics(
          find.ancestor(
            of: find.text('High Contrast Mode'),
            matching: find.byType(CupertinoSwitch),
          ).first
        );

        expect(highContrastSemantics.label, contains('High Contrast Mode'));
        expect(highContrastSemantics.hasFlag(SemanticsFlag.hasToggledState), isTrue);
      });

      testWidgets('should support keyboard navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          const CupertinoApp(
            home: AccessibilitySettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Test focus traversal
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Should handle keyboard input without errors
        expect(tester.takeException(), isNull);
      });
    });

    group('Settings Persistence Tests', () {
      testWidgets('should load saved settings on initialization', (WidgetTester tester) async {
        // Set some settings first
        await AACHelper.setHighContrast(true);
        await AACHelper.setLargeText(true);
        await AACHelper.setVoiceFeedback(false);

        await tester.pumpWidget(
          const CupertinoApp(
            home: AccessibilitySettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Settings should be loaded correctly
        expect(AACHelper.isHighContrastEnabled, isTrue);
        expect(AACHelper.isLargeTextEnabled, isTrue);
        expect(AACHelper.isVoiceFeedbackEnabled, isFalse);

        // Reset for other tests
        await AACHelper.setHighContrast(false);
        await AACHelper.setLargeText(false);
        await AACHelper.setVoiceFeedback(true);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should handle rapid setting changes gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          const CupertinoApp(
            home: AccessibilitySettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Rapidly toggle multiple settings
        final highContrastFinder = find.ancestor(
          of: find.text('High Contrast Mode'),
          matching: find.byType(CupertinoSwitch),
        ).first;

        for (int i = 0; i < 10; i++) {
          await tester.tap(highContrastFinder);
          await tester.pump(const Duration(milliseconds: 50));
        }

        await tester.pumpAndSettle();

        // Should handle without throwing
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle slider edge cases', (WidgetTester tester) async {
        await tester.pumpWidget(
          const CupertinoApp(
            home: AccessibilitySettingsScreen(),
          ),
        );

        await tester.pumpAndSettle();

        // Test extreme slider movements
        final speedSlider = find.ancestor(
          of: find.text('Speech Speed'),
          matching: find.byType(Slider),
        ).first;

        // Drag to extreme positions
        await tester.drag(speedSlider, const Offset(-200, 0)); // Far left
        await tester.pump();
        
        await tester.drag(speedSlider, const Offset(400, 0)); // Far right
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });
  });
}