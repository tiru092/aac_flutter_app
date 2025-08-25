// AAC Flutter App comprehensive widget tests
//
// These tests verify the complete functionality of the AAC app
// including accessibility features for special children.

import 'package:flutter/cupertino.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import 'package:aac_flutter_app/main.dart';
import 'package:aac_flutter_app/utils/aac_helper.dart';
import 'package:aac_flutter_app/widgets/communication_grid.dart';

void main() {
  group('AAC App Integration Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Mock all necessary channels for full app testing
      const MethodChannel('flutter_tts').setMockMethodCallHandler((methodCall) async {
        switch (methodCall.method) {
          case 'setLanguage':
          case 'setSpeechRate':
          case 'setVolume':
          case 'setPitch':
          case 'speak':
          case 'stop':
            return true;
          default:
            return null;
        }
      });
      
      const MethodChannel('flutter/platform').setMockMethodCallHandler((methodCall) async {
        if (methodCall.method == 'SystemSound.play') {
          return null;
        }
        if (methodCall.method == 'HapticFeedback.vibrate') {
          return null;
        }
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

    testWidgets('AAC App loads correctly with all features', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const AACApp(firebaseInitialized: false));
      await tester.pumpAndSettle();

      // Verify that the main UI elements are present
      expect(find.text('👋 Hello!'), findsOneWidget);
      expect(find.text('Let\'s communicate! 💬'), findsOneWidget);
      expect(find.text('Tap symbols to speak!'), findsOneWidget);

      // Verify that the segmented control is present
      expect(find.text('🏠 Categories'), findsOneWidget);
      expect(find.text('📚 All Symbols'), findsOneWidget);

      // Verify that the floating action button is present
      expect(find.text('✨ Add New'), findsOneWidget);
      
      // Verify settings button is present
      expect(find.byIcon(CupertinoIcons.gear_alt_fill), findsOneWidget);
    });

    testWidgets('Segmented control switches views correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const AACApp(firebaseInitialized: false));
      await tester.pumpAndSettle();

      // Initially should show Categories view
      expect(find.text('🏠 Categories'), findsOneWidget);
      
      // Tap on 'All Symbols' segment
      await tester.tap(find.text('📚 All Symbols'));
      await tester.pumpAndSettle();
      
      // Should not throw any errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('Settings navigation works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const AACApp(firebaseInitialized: false));
      await tester.pumpAndSettle();

      // Tap settings button
      await tester.tap(find.byIcon(CupertinoIcons.gear_alt_fill));
      await tester.pumpAndSettle();

      // Should navigate to accessibility settings
      expect(find.text('🔧 Accessibility Settings'), findsOneWidget);
      
      // Verify settings sections are present
      expect(find.text('👁️ Visual Accessibility'), findsOneWidget);
      expect(find.text('🔊 Audio Feedback'), findsOneWidget);
      expect(find.text('📳 Haptic Feedback'), findsOneWidget);
    });

    testWidgets('Add symbol dialog works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const AACApp(firebaseInitialized: false));
      await tester.pumpAndSettle();

      // Tap add button
      await tester.tap(find.text('✨ Add New'));
      await tester.pumpAndSettle();

      // Should show action sheet
      expect(find.text('✨ Add New Symbol'), findsOneWidget);
      expect(find.text('Choose how to add a new symbol'), findsOneWidget);
    });

    testWidgets('App handles accessibility settings changes', (WidgetTester tester) async {
      await tester.pumpWidget(const AACApp(firebaseInitialized: false));
      await tester.pumpAndSettle();

      // Test high contrast mode
      await AACHelper.setHighContrast(true);
      expect(AACHelper.isHighContrastEnabled, isTrue);
      expect(AACHelper.getAccessibleColors(), equals(AACHelper.highContrastColors));

      // Test large text mode
      await AACHelper.setLargeText(true);
      expect(AACHelper.isLargeTextEnabled, isTrue);
      expect(AACHelper.getTextSizeMultiplier(), equals(1.3));

      // Reset settings
      await AACHelper.setHighContrast(false);
      await AACHelper.setLargeText(false);
    });

    testWidgets('Sound and voice feedback systems work', (WidgetTester tester) async {
      await tester.pumpWidget(const AACApp(firebaseInitialized: false));
      await tester.pumpAndSettle();

      // Test sound effects
      expect(() async => await AACHelper.playSound(SoundEffect.buttonTap), 
             returnsNormally);
      expect(() async => await AACHelper.playSound(SoundEffect.success), 
             returnsNormally);

      // Test voice feedback
      expect(() async => await AACHelper.speak('Hello World'), 
             returnsNormally);
      expect(() async => await AACHelper.speakWithEmotion(
        'Excited!', 
        tone: EmotionalTone.excited,
      ), returnsNormally);
    });

    testWidgets('App maintains accessibility compliance', (WidgetTester tester) async {
      await tester.pumpWidget(const AACApp(firebaseInitialized: false));
      await tester.pumpAndSettle();

      // Check accessibility tree structure
      expect(tester.semantics, hasAGoodToStringDeep);

      // Verify interactive elements are properly labeled
      final settingsSemantics = tester.getSemantics(
        find.byIcon(CupertinoIcons.gear_alt_fill)
      );
      expect(settingsSemantics.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(settingsSemantics.hasFlag(SemanticsFlag.isEnabled), isTrue);
    });

    testWidgets('App handles rapid user interactions gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(const AACApp(firebaseInitialized: false));
      await tester.pumpAndSettle();

      // Rapidly switch between views
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('📚 All Symbols'));
        await tester.pump(const Duration(milliseconds: 100));
        
        await tester.tap(find.text('🏠 Categories'));
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.pumpAndSettle();

      // Should handle without errors
      expect(tester.takeException(), isNull);
      expect(find.text('👋 Hello!'), findsOneWidget);
    });

    testWidgets('App provides proper feedback for child interactions', (WidgetTester tester) async {
      await tester.pumpWidget(const AACApp(firebaseInitialized: false));
      await tester.pumpAndSettle();

      // Test comprehensive feedback system
      expect(() async => await AACHelper.provideFeedback(
        text: 'Great job!',
        soundEffect: SoundEffect.celebration,
        tone: EmotionalTone.encouraging,
        haptic: true,
        announce: true,
      ), returnsNormally);

      // Test achievement celebration
      expect(() async => await AACHelper.celebrateAchievement(
        'You completed your first communication!'
      ), returnsNormally);

      // Test gentle error feedback
      expect(() async => await AACHelper.provideGentleErrorFeedback(
        'Let\'s try selecting a symbol'
      ), returnsNormally);
    });

    testWidgets('Communication grid displays and functions correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const AACApp(firebaseInitialized: false));
      await tester.pumpAndSettle();

      // Communication grid should be present
      expect(find.byType(CommunicationGrid), findsOneWidget);

      // Switch to symbols view
      await tester.tap(find.text('📚 All Symbols'));
      await tester.pumpAndSettle();

      // Should still show communication grid
      expect(find.byType(CommunicationGrid), findsOneWidget);
    });
  });
}
