import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:aac_flutter_app/utils/aac_helper.dart';
import 'package:aac_flutter_app/models/symbol.dart';

void main() {
  group('AACHelper Tests', () {
    setUpAll(() async {
      // Mock Hive initialization
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Set up method channel mocks for TTS
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
      
      // Mock system sound channel
      const MethodChannel('flutter/platform').setMockMethodCallHandler((methodCall) async {
        if (methodCall.method == 'SystemSound.play') {
          return null;
        }
        return null;
      });
    });

    group('Accessibility Settings Tests', () {
      test('should set and get high contrast mode', () async {
        // Test setting high contrast
        await AACHelper.setHighContrast(true);
        expect(AACHelper.isHighContrastEnabled, isTrue);
        
        await AACHelper.setHighContrast(false);
        expect(AACHelper.isHighContrastEnabled, isFalse);
      });

      test('should set and get large text mode', () async {
        await AACHelper.setLargeText(true);
        expect(AACHelper.isLargeTextEnabled, isTrue);
        expect(AACHelper.getTextSizeMultiplier(), equals(1.3));
        
        await AACHelper.setLargeText(false);
        expect(AACHelper.isLargeTextEnabled, isFalse);
        expect(AACHelper.getTextSizeMultiplier(), equals(1.0));
      });

      test('should set and get voice feedback settings', () async {
        await AACHelper.setVoiceFeedback(false);
        expect(AACHelper.isVoiceFeedbackEnabled, isFalse);
        
        await AACHelper.setVoiceFeedback(true);
        expect(AACHelper.isVoiceFeedbackEnabled, isTrue);
      });

      test('should set and get haptic feedback settings', () async {
        await AACHelper.setHapticFeedback(false);
        expect(AACHelper.isHapticFeedbackEnabled, isFalse);
        
        await AACHelper.setHapticFeedback(true);
        expect(AACHelper.isHapticFeedbackEnabled, isTrue);
      });

      test('should set and get auto speak settings', () async {
        await AACHelper.setAutoSpeak(false);
        expect(AACHelper.isAutoSpeakEnabled, isFalse);
        
        await AACHelper.setAutoSpeak(true);
        expect(AACHelper.isAutoSpeakEnabled, isTrue);
      });
    });

    group('Speech Settings Tests', () {
      test('should set and get speech rate within valid range', () async {
        // Test valid range
        await AACHelper.setSpeechRate(0.5);
        expect(AACHelper.speechRate, equals(0.5));
        
        // Test clamping
        await AACHelper.setSpeechRate(-0.5);
        expect(AACHelper.speechRate, equals(0.1));
        
        await AACHelper.setSpeechRate(2.0);
        expect(AACHelper.speechRate, equals(1.0));
      });

      test('should set and get speech pitch within valid range', () async {
        await AACHelper.setSpeechPitch(1.2);
        expect(AACHelper.speechPitch, equals(1.2));
        
        // Test clamping
        await AACHelper.setSpeechPitch(0.1);
        expect(AACHelper.speechPitch, equals(0.5));
        
        await AACHelper.setSpeechPitch(3.0);
        expect(AACHelper.speechPitch, equals(2.0));
      });

      test('should set and get speech volume within valid range', () async {
        await AACHelper.setSpeechVolume(0.8);
        expect(AACHelper.speechVolume, equals(0.8));
        
        // Test clamping
        await AACHelper.setSpeechVolume(-0.5);
        expect(AACHelper.speechVolume, equals(0.0));
        
        await AACHelper.setSpeechVolume(1.5);
        expect(AACHelper.speechVolume, equals(1.0));
      });
    });

    group('Sound Effects Tests', () {
      test('should set and get sound effects settings', () async {
        await AACHelper.setSoundEffects(false);
        expect(AACHelper.isSoundEffectsEnabled, isFalse);
        
        await AACHelper.setSoundEffects(true);
        expect(AACHelper.isSoundEffectsEnabled, isTrue);
      });

      test('should set and get sound volume within valid range', () async {
        await AACHelper.setSoundVolume(0.7);
        expect(AACHelper.soundVolume, equals(0.7));
        
        // Test clamping
        await AACHelper.setSoundVolume(-0.3);
        expect(AACHelper.soundVolume, equals(0.0));
        
        await AACHelper.setSoundVolume(1.2);
        expect(AACHelper.soundVolume, equals(1.0));
      });

      test('should play sound effects when enabled', () async {
        await AACHelper.setSoundEffects(true);
        
        // Should not throw when playing sounds
        expect(() async => await AACHelper.playSound(SoundEffect.buttonTap), 
               returnsNormally);
        expect(() async => await AACHelper.playSound(SoundEffect.success), 
               returnsNormally);
        expect(() async => await AACHelper.playSound(SoundEffect.error), 
               returnsNormally);
      });
    });

    group('Color Scheme Tests', () {
      test('should return high contrast colors when enabled', () async {
        await AACHelper.setHighContrast(true);
        final colors = AACHelper.getAccessibleColors();
        expect(colors, equals(AACHelper.highContrastColors));
      });

      test('should return child-friendly colors when high contrast disabled', () async {
        await AACHelper.setHighContrast(false);
        final colors = AACHelper.getAccessibleColors();
        expect(colors, equals(AACHelper.childFriendlyColors));
      });

      test('should return random child-friendly color', () {
        final color = AACHelper.getRandomChildColor();
        expect(AACHelper.childFriendlyColors.contains(color), isTrue);
      });
    });

    group('Semantic Labels Tests', () {
      test('should create proper symbol semantic label', () {
        final symbol = Symbol(
          label: 'Apple',
          imagePath: 'assets/apple.png',
          category: 'Food',
          description: 'A red fruit',
        );
        
        final semanticLabel = AACHelper.createSymbolSemanticLabel(symbol);
        expect(semanticLabel, contains('Symbol: Apple'));
        expect(semanticLabel, contains('A red fruit'));
        expect(semanticLabel, contains('Category: Food'));
        expect(semanticLabel, contains('Double tap to speak'));
      });

      test('should create proper category semantic label', () {
        final category = Category(
          name: 'Food',
          iconPath: 'assets/food.png',
          colorCode: 0xFF00FF00,
        );
        
        final semanticLabel = AACHelper.createCategorySemanticLabel(category, 5);
        expect(semanticLabel, contains('Category: Food'));
        expect(semanticLabel, contains('5 symbols available'));
        expect(semanticLabel, contains('Double tap to open'));
      });
    });

    group('Category Color Tests', () {
      test('should return correct category color', () {
        expect(AACHelper.getCategoryColor('People'), equals(AACHelper.categoryColors['People']));
        expect(AACHelper.getCategoryColor('Actions'), equals(AACHelper.categoryColors['Actions']));
        expect(AACHelper.getCategoryColor('Describing'), equals(AACHelper.categoryColors['Describing']));
        expect(AACHelper.getCategoryColor('Social'), equals(AACHelper.categoryColors['Social']));
        expect(AACHelper.getCategoryColor('Food & Drinks'), equals(AACHelper.categoryColors['Food & Drinks']));
        expect(AACHelper.getCategoryColor('Misc'), equals(AACHelper.categoryColors['Misc']));
      });

      test('should return default color for unknown category', () {
        expect(AACHelper.getCategoryColor('Unknown'), equals(AACHelper.categoryColors['Misc']));
      });
    });

    group('Error Handling Tests', () {
      test('should create AACException with message and code', () {
        final exception = AACException('Test error', 'test_code');
        expect(exception.message, equals('Test error'));
        expect(exception.code, equals('test_code'));
        expect(exception.toString(), equals('AACException: Test error (Code: test_code)'));
      });

      test('should create DatabaseException with correct code', () {
        final exception = DatabaseException('Database error');
        expect(exception.code, equals('database_error'));
      });

      test('should create NetworkException with correct code', () {
        final exception = NetworkException('Network error');
        expect(exception.code, equals('network_error'));
      });

      test('should create AudioException with correct code', () {
        final exception = AudioException('Audio error');
        expect(exception.code, equals('audio_error'));
      });

      test('should create ValidationException with correct code', () {
        final exception = ValidationException('Validation error');
        expect(exception.code, equals('validation_error'));
      });
    });

    group('Utility Function Tests', () {
      test('should generate proper symbol grid key', () {
        final key = AACHelper.generateSymbolGridKey('Food', 3);
        expect(key, equals('symbols_Food_3'));
      });

      test('should validate email format', () {
        expect(AACHelper.isValidEmail('test@example.com'), isTrue);
        expect(AACHelper.isValidEmail('invalid-email'), isFalse);
        expect(AACHelper.isValidEmail(''), isFalse);
      });

      test('should validate phone number format', () {
        expect(AACHelper.isValidPhoneNumber('+1234567890'), isTrue);
        expect(AACHelper.isValidPhoneNumber('1234567890'), isTrue);
        expect(AACHelper.isValidPhoneNumber('invalid-phone'), isFalse);
        expect(AACHelper.isValidPhoneNumber(''), isFalse);
      });
    });
  });
}