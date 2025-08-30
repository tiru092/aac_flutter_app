import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/voice_service.dart';

// Sound effect types for children
enum SoundEffect {
  buttonTap,
  symbolSelect,
  categoryOpen,
  success,
  error,
  notification,
  celebration,
  pop,
  swoosh,
  chime,
}

// Emotional tones for voice feedback
enum EmotionalTone {
  friendly,
  excited,
  calm,
  encouraging,
}

// Custom exception classes for better error handling
class AACException implements Exception {
  final String message;
  final String code;
  
  AACException(this.message, [this.code = 'unknown']);
  
  @override
  String toString() => 'AACException: $message (Code: $code)';
}

class DatabaseException extends AACException {
  DatabaseException(String message) : super(message, 'database_error');
}

class NetworkException extends AACException {
  NetworkException(String message) : super(message, 'network_error');
}

class AudioException extends AACException {
  AudioException(String message) : super(message, 'audio_error');
}

class ValidationException extends AACException {
  ValidationException(String message) : super(message, 'validation_error');
}

class AACHelper {
  static Box<Symbol>? _symbolBox;
  static Box<Category>? _categoryBox;
  static Box? _settingsBox;
  static FlutterTts? _flutterTts;
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final VoiceService _voiceService = VoiceService();
  
  // Performance optimization: Cache frequently accessed settings
  static final Map<String, dynamic> _settingsCache = {};
  static bool _settingsCacheInitialized = false;
  
  // Therapy-tested category colors (Avaz & Jellow approach)
  static const Map<String, Color> categoryColors = {
    // People/Pronouns → Yellow
    'People': Color(0xFFFFC107),
    'Pronouns': Color(0xFFFFC107),
    'Family': Color(0xFFFFC107),
    
    // Actions/Verbs → Green  
    'Actions': Color(0xFF4CAF50),
    'Verbs': Color(0xFF4CAF50),
    'Activities': Color(0xFF4CAF50),
    
    // Describing words → Blue
    'Describing': Color(0xFF2196F3),
    'Adjectives': Color(0xFF2196F3),
    'Emotions': Color(0xFF2196F3),
    
    // Social phrases → Pink/Purple
    'Social': Color(0xFFE91E63),
    'Greetings': Color(0xFFE91E63),
    'Politeness': Color(0xFF9C27B0),
    
    // Food/Things → Orange
    'Food & Drinks': Color(0xFFFF9800),
    'Food': Color(0xFFFF9800),
    'Objects': Color(0xFFFF9800),
    'Vehicles': Color(0xFFFF9800),
    
    // Misc → Gray
    'Misc': Color(0xFF607D8B),
    'Custom': Color(0xFF607D8B),
    'Other': Color(0xFF607D8B),
  };
  
  // High contrast colors for accessibility
  static const Map<String, Color> highContrastColors = {
    'People': Color(0xFFFFD54F),      // Darker yellow
    'Pronouns': Color(0xFFFFD54F),
    'Family': Color(0xFFFFD54F),
    
    'Actions': Color(0xFF388E3C),     // Darker green
    'Verbs': Color(0xFF388E3C),
    'Activities': Color(0xFF388E3C),
    
    'Describing': Color(0xFF1976D2),  // Darker blue
    'Adjectives': Color(0xFF1976D2),
    'Emotions': Color(0xFF1976D2),
    
    'Social': Color(0xFFC2185B),      // Darker pink
    'Greetings': Color(0xFFC2185B),
    'Politeness': Color(0xFF7B1FA2),  // Darker purple
    
    'Food & Drinks': Color(0xFFF57C00),  // Darker orange
    'Food': Color(0xFFF57C00),
    'Objects': Color(0xFFF57C00),
    'Vehicles': Color(0xFFF57C00),
    
    'Misc': Color(0xFF455A64),        // Darker gray
    'Custom': Color(0xFF455A64),
    'Other': Color(0xFF455A64),
  };
  
  // Get category color
  static Color getCategoryColor(String categoryName) {
    try {
      final isHighContrast = getSetting<bool>('high_contrast', defaultValue: false) ?? false;
      final colorMap = isHighContrast ? highContrastColors : categoryColors;
      return colorMap[categoryName] ?? (isHighContrast ? highContrastColors['Misc']! : categoryColors['Misc']!);
    } catch (e) {
      // Fallback to a default color if there's an error
      return categoryColors['Misc']!;
    }
  }

  // Initialize Hive database with error handling
  static Future<void> initializeDatabase() async {
    try {
      await Hive.initFlutter();
      
      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(SymbolAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(CategoryAdapter());
      }

      // Open boxes with timeout
      _symbolBox = await Hive.openBox<Symbol>('symbols');
      _categoryBox = await Hive.openBox<Category>('categories');
      _settingsBox = await Hive.openBox('settings');

      // Initialize settings cache for better performance
      await _initializeSettingsCache();

      // Initialize default data if first time (defer to avoid blocking startup)
      if (_categoryBox?.isEmpty ?? true) {
        Future.microtask(() => _initializeDefaultData());
      }
    } on HiveError catch (e) {
      throw DatabaseException('Failed to initialize database: ${e.message}');
    } catch (e) {
      throw DatabaseException('Unexpected error during database initialization: $e');
    }
  }

  // Initialize settings cache for better performance
  static Future<void> _initializeSettingsCache() async {
    if (_settingsCacheInitialized || _settingsBox == null) return;
    
    try {
      // Pre-load frequently accessed settings
      final commonSettings = [
        _highContrastKey, _largeTextKey, _voiceFeedbackKey,
        _hapticFeedbackKey, _autoSpeakKey, _speechRateKey,
        _speechPitchKey, _speechVolumeKey, _soundEffectsKey,
        _soundVolumeKey2
      ];
      
      for (final key in commonSettings) {
        if (_settingsBox!.containsKey(key)) {
          _settingsCache[key] = _settingsBox!.get(key);
        }
      }
      
      _settingsCacheInitialized = true;
    } catch (e) {
      debugPrint('Error initializing settings cache: $e');
    }
  }

  // Initialize Text-to-Speech with error handling - ULTRA LIGHTWEIGHT
  static Future<void> initializeTTS() async {
    try {
      _flutterTts = FlutterTts();
      
      // Only set essential settings to avoid blocking
      await _flutterTts!.setLanguage('en-US');
      await _flutterTts!.setSpeechRate(0.5);
      await _flutterTts!.setVolume(1.0);
      
      debugPrint('TTS initialized (lightweight mode)');
      
      // Initialize VoiceService for custom voice support
      try {
        await _voiceService.initialize();
        debugPrint('VoiceService initialized successfully');
      } catch (voiceError) {
        debugPrint('VoiceService initialization failed (ignored): $voiceError');
        // Continue without voice service - TTS will still work
      }
    } catch (e) {
      debugPrint('TTS initialization failed (ignored): $e');
      // Don't throw, just continue without TTS
    }
  }

  // Expose FlutterTts instance for direct access (needed to avoid recursion)
  static FlutterTts? getFlutterTtsInstance() {
    return _flutterTts;
  }

  // Text-to-Speech functionality with custom voice support
  static Future<void> speak(String text) async {
    try {
      // Use VoiceService to automatically select custom or default voice
      await _voiceService.speakWithCurrentVoice(text);
    } catch (e) {
      debugPrint('TTS error (ignored): $e');
      // Fallback to direct TTS if voice service fails
      try {
        if (_flutterTts != null) {
          await _flutterTts!.speak(text);
        }
      } catch (fallbackError) {
        debugPrint('Fallback TTS error: $fallbackError');
      }
    }
  }

  // Speak with emotional tone
  static Future<void> speakWithEmotion(String text, {EmotionalTone? tone}) async {
    try {
      // Adjust voice parameters based on emotional tone
      double pitch = 1.0;
      double rate = 0.6;
      
      switch (tone) {
        case EmotionalTone.friendly:
          pitch = 1.2;
          rate = 0.5;
          break;
        case EmotionalTone.excited:
          pitch = 1.4;
          rate = 0.7;
          break;
        case EmotionalTone.calm:
          pitch = 0.9;
          rate = 0.4;
          break;
        case EmotionalTone.encouraging:
          pitch = 1.3;
          rate = 0.6;
          break;
        default:
          pitch = 1.2;
          rate = 0.6;
      }
      
      if (_flutterTts != null) {
        await _flutterTts!.setPitch(pitch);
        await _flutterTts!.setSpeechRate(rate);
        await _flutterTts!.speak(text);
        
        // Reset to default settings
        await _flutterTts!.setPitch(speechPitch);
        await _flutterTts!.setSpeechRate(speechRate);
      }
    } catch (e) {
      print('Error in speakWithEmotion: $e');
      // Fallback to regular speak
      await speak(text);
    }
  }

  static Future<void> stopSpeaking() async {
    try {
      // Stop both regular TTS and any custom voice playback
      if (_flutterTts != null) {
        await _flutterTts!.stop();
      }
      
      // Also try to stop any audio playing through VoiceService
      try {
        await _voiceService.stopPlayback();
      } catch (voiceError) {
        debugPrint('Error stopping voice service playback: $voiceError');
      }
    } catch (e) {
      print('Error stopping speech: $e');
    }
  }

  // Symbol management with error handling
  static Future<void> addSymbol(Symbol symbol) async {
    try {
      await _symbolBox?.add(symbol);
    } on HiveError catch (e) {
      throw DatabaseException('Failed to add symbol: ${e.message}');
    } catch (e) {
      throw DatabaseException('Unexpected error adding symbol: $e');
    }
  }

  static Future<void> updateSymbol(int index, Symbol symbol) async {
    try {
      await _symbolBox?.putAt(index, symbol);
    } on HiveError catch (e) {
      throw DatabaseException('Failed to update symbol: ${e.message}');
    } catch (e) {
      throw DatabaseException('Unexpected error updating symbol: $e');
    }
  }

  static Future<void> deleteSymbol(int index) async {
    try {
      await _symbolBox?.deleteAt(index);
    } on HiveError catch (e) {
      throw DatabaseException('Failed to delete symbol: ${e.message}');
    } catch (e) {
      throw DatabaseException('Unexpected error deleting symbol: $e');
    }
  }

  static List<Symbol> getAllSymbols() {
    try {
      return _symbolBox?.values.toList() ?? [];
    } catch (e) {
      print('Error getting all symbols: $e');
      return [];
    }
  }

  static List<Symbol> getSymbolsByCategory(String categoryName) {
    try {
      return _symbolBox?.values
          .where((symbol) => symbol.category == categoryName)
          .toList() ?? [];
    } catch (e) {
      print('Error getting symbols by category: $e');
      return [];
    }
  }

  // Category management with error handling
  static Future<void> addCategory(Category category) async {
    try {
      await _categoryBox?.add(category);
    } on HiveError catch (e) {
      throw DatabaseException('Failed to add category: ${e.message}');
    } catch (e) {
      throw DatabaseException('Unexpected error adding category: $e');
    }
  }

  static Future<void> updateCategory(int index, Category category) async {
    try {
      await _categoryBox?.putAt(index, category);
    } on HiveError catch (e) {
      throw DatabaseException('Failed to update category: ${e.message}');
    } catch (e) {
      throw DatabaseException('Unexpected error updating category: $e');
    }
  }

  static Future<void> deleteCategory(int index) async {
    try {
      await _categoryBox?.deleteAt(index);
    } on HiveError catch (e) {
      throw DatabaseException('Failed to delete category: ${e.message}');
    } catch (e) {
      throw DatabaseException('Unexpected error deleting category: $e');
    }
  }

  static List<Category> getAllCategories() {
    try {
      return _categoryBox?.values.toList() ?? [];
    } catch (e) {
      print('Error getting all categories: $e');
      return [];
    }
  }

  // Settings management with error handling and caching
  static Future<void> setSetting(String key, dynamic value) async {
    try {
      if (_settingsBox != null) {
        await _settingsBox!.put(key, value);
        _settingsCache[key] = value; // Update cache
      }
    } catch (e) {
      debugPrint('Error setting value for key $key: $e');
    }
  }

  static T? getSetting<T>(String key, {T? defaultValue}) {
    try {
      // If settings box is not initialized, return default value immediately
      if (_settingsBox == null) {
        return defaultValue;
      }
      
      // Use cache if available to avoid repeated box access
      if (_settingsCache.containsKey(key)) {
        return _settingsCache[key] as T?;
      }
      
      final value = _settingsBox!.get(key, defaultValue: defaultValue) as T?;
      if (value != null) {
        _settingsCache[key] = value; // Cache the value
      }
      return value;
    } catch (e) {
      debugPrint('Error getting value for key $key: $e');
      return defaultValue;
    }
  }



  // Initialize default categories and symbols
  static Future<void> _initializeDefaultData() async {
    try {
      // Default categories with child-friendly colors
      final defaultCategories = [
        Category(
          name: 'Food & Drinks',
          iconPath: 'assets/icons/food.png',
          colorCode: Colors.orange.value,
          isDefault: true,
        ),
        Category(
          name: 'Vehicles',
          iconPath: 'assets/icons/vehicle.png',
          colorCode: Colors.blue.value,
          isDefault: true,
        ),
        Category(
          name: 'Emotions',
          iconPath: 'assets/icons/emotion.png',
          colorCode: Colors.yellow.value,
          isDefault: true,
        ),
        Category(
          name: 'Actions',
          iconPath: 'assets/icons/action.png',
          colorCode: Colors.green.value,
          isDefault: true,
        ),
        Category(
          name: 'Family',
          iconPath: 'assets/icons/family.png',
          colorCode: Colors.pink.value,
          isDefault: true,
        ),
        Category(
          name: 'Custom',
          iconPath: 'assets/icons/custom.png',
          colorCode: Colors.purple.value,
          isDefault: false,
        ),
      ];

      for (final category in defaultCategories) {
        await addCategory(category);
      }

      // Default symbols
      final defaultSymbols = [
        Symbol(
          label: 'Apple',
          imagePath: 'assets/symbols/Apple.png',
          category: 'Food & Drinks',
          isDefault: true,
          description: 'A red apple fruit',
        ),
        Symbol(
          label: 'Water',
          imagePath: 'assets/symbols/Water.png',
          category: 'Food & Drinks',
          isDefault: true,
          description: 'A glass of water',
        ),
        Symbol(
          label: 'Car',
          imagePath: 'assets/symbols/Car.png',
          category: 'Vehicles',
          isDefault: true,
          description: 'A red car',
        ),
      ];

      for (final symbol in defaultSymbols) {
        await addSymbol(symbol);
      }
    } catch (e) {
      print('Error initializing default data: $e');
      // Continue without default data if initialization fails
    }
  }

  // Child-friendly color palette
  static const List<Color> childFriendlyColors = [
    Color(0xFFFF6B6B), // Coral Red
    Color(0xFF4ECDC4), // Turquoise
    Color(0xFF45B7D1), // Sky Blue
    Color(0xFF96CEB4), // Mint Green
    Color(0xFFFECA57), // Sunny Yellow
    Color(0xFFFF9FF3), // Pink
    Color(0xFFA29BFE), // Lavender
    Color(0xFF6C5CE7), // Purple
    Color(0xFFFFB142), // Orange
    Color(0xFF55A3FF), // Light Blue
  ];

  // Get random child-friendly color
  static Color getRandomChildColor() {
    try {
      return childFriendlyColors[
          DateTime.now().millisecond % childFriendlyColors.length];
    } catch (e) {
      // Fallback to a default color if there's an error
      return childFriendlyColors[0];
    }
  }

  // ========== ACCESSIBILITY FEATURES FOR SPECIAL CHILDREN ==========
  
  // Accessibility Settings
  static const String _highContrastKey = 'high_contrast_mode';
  static const String _largeTextKey = 'large_text_mode';
  static const String _voiceFeedbackKey = 'voice_feedback_enabled';
  static const String _hapticFeedbackKey = 'haptic_feedback_enabled';
  static const String _autoSpeakKey = 'auto_speak_enabled';
  static const String _speechRateKey = 'speech_rate';
  static const String _speechPitchKey = 'speech_pitch';
  static const String _speechVolumeKey = 'speech_volume';
  
  
  // Enhanced speak method with accessibility features
  static Future<void> speakWithAccessibility(String text, {
    bool announce = false,
    bool haptic = true,
  }) async {
    try {
      // Check if voice feedback is enabled
      if (!getSetting<bool>(_voiceFeedbackKey, defaultValue: true)!) {
        return;
      }
      
      // Provide haptic feedback if enabled
      if (haptic && getSetting<bool>(_hapticFeedbackKey, defaultValue: true)!) {
        await HapticFeedback.lightImpact();
      }
      
      if (_flutterTts != null) {
        // Clean text for better pronunciation
        final cleanText = _cleanTextForSpeech(text);
        
        if (announce) {
          // Use SemanticsService for screen reader announcements
          await SemanticsService.announce(cleanText, TextDirection.ltr);
        } else {
          await _flutterTts!.speak(cleanText);
        }
      }
    } catch (e) {
      print('Error in speakWithAccessibility: $e');
      // Fallback to system sound if TTS fails
      await _playErrorSound();
    }
  }
  
  // Clean text for better speech synthesis
  static String _cleanTextForSpeech(String text) {
    try {
      return text
          .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
          .replaceAll(RegExp(r'\s+'), ' ')    // Normalize whitespace
          .trim();
    } catch (e) {
      print('Error cleaning text for speech: $e');
      return text;
    }
  }
  
  // Auto-speak functionality for symbols
  static Future<void> autoSpeakSymbol(Symbol symbol) async {
    try {
      if (getSetting<bool>(_autoSpeakKey, defaultValue: true)!) {
        final text = symbol.description != null && symbol.description!.isNotEmpty
            ? '${symbol.label}. ${symbol.description}'
            : symbol.label;
        await speakWithAccessibility(text, haptic: false);
      }
    } catch (e) {
      print('Error in autoSpeakSymbol: $e');
    }
  }
  
  // Accessibility Settings Getters/Setters
  static bool get isHighContrastEnabled { 
    try {
      return getSetting<bool>(_highContrastKey, defaultValue: false)!;
    } catch (e) {
      print('Error getting high contrast setting: $e');
      return false;
    }
  }
      
  static Future<void> setHighContrast(bool enabled) async {
    try {
      await setSetting(_highContrastKey, enabled);
    } catch (e) {
      print('Error setting high contrast: $e');
    }
  }
  
  static bool get isLargeTextEnabled { 
    try {
      return getSetting<bool>(_largeTextKey, defaultValue: false)!;
    } catch (e) {
      print('Error getting large text setting: $e');
      return false;
    }
  }
      
  static Future<void> setLargeText(bool enabled) async {
    try {
      await setSetting(_largeTextKey, enabled);
    } catch (e) {
      print('Error setting large text: $e');
    }
  }
  
  static bool get isVoiceFeedbackEnabled { 
    try {
      return getSetting<bool>(_voiceFeedbackKey, defaultValue: true)!;
    } catch (e) {
      print('Error getting voice feedback setting: $e');
      return true; // Default to enabled
    }
  }
      
  static Future<void> setVoiceFeedback(bool enabled) async {
    try {
      await setSetting(_voiceFeedbackKey, enabled);
    } catch (e) {
      print('Error setting voice feedback: $e');
    }
  }
  
  static bool get isHapticFeedbackEnabled { 
    try {
      return getSetting<bool>(_hapticFeedbackKey, defaultValue: true)!;
    } catch (e) {
      print('Error getting haptic feedback setting: $e');
      return true; // Default to enabled
    }
  }
      
  static Future<void> setHapticFeedback(bool enabled) async {
    try {
      await setSetting(_hapticFeedbackKey, enabled);
    } catch (e) {
      print('Error setting haptic feedback: $e');
    }
  }
  
  static bool get isAutoSpeakEnabled { 
    try {
      return getSetting<bool>(_autoSpeakKey, defaultValue: true)!;
    } catch (e) {
      print('Error getting auto speak setting: $e');
      return true; // Default to enabled
    }
  }
      
  static Future<void> setAutoSpeak(bool enabled) async {
    try {
      await setSetting(_autoSpeakKey, enabled);
    } catch (e) {
      print('Error setting auto speak: $e');
    }
  }
  
  // Speech rate control (0.1 to 1.0)
  static double get speechRate { 
    try {
      return getSetting<double>(_speechRateKey, defaultValue: 0.5)!;
    } catch (e) {
      print('Error getting speech rate: $e');
      return 0.5; // Default value
    }
  }
      
  static Future<void> setSpeechRate(double rate) async {
    try {
      final clampedRate = rate.clamp(0.1, 1.0);
      await setSetting(_speechRateKey, clampedRate);
      if (_flutterTts != null) {
        await _flutterTts!.setSpeechRate(clampedRate);
      }
    } catch (e) {
      print('Error setting speech rate: $e');
    }
  }
  
  // Speech pitch control (0.5 to 2.0)
  static double get speechPitch { 
    try {
      return getSetting<double>(_speechPitchKey, defaultValue: 1.2)!;
    } catch (e) {
      print('Error getting speech pitch: $e');
      return 1.2; // Default value
    }
  }
      
  static Future<void> setSpeechPitch(double pitch) async {
    try {
      final clampedPitch = pitch.clamp(0.5, 2.0);
      await setSetting(_speechPitchKey, clampedPitch);
      if (_flutterTts != null) {
        await _flutterTts!.setPitch(clampedPitch);
      }
    } catch (e) {
      print('Error setting speech pitch: $e');
    }
  }
  
  // Speech volume control (0.0 to 1.0)
  static double get speechVolume { 
    try {
      return getSetting<double>(_speechVolumeKey, defaultValue: 1.0)!;
    } catch (e) {
      print('Error getting speech volume: $e');
      return 1.0; // Default value
    }
  }
      
  static Future<void> setSpeechVolume(double volume) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      await setSetting(_speechVolumeKey, clampedVolume);
      if (_flutterTts != null) {
        await _flutterTts!.setVolume(clampedVolume);
      }
    } catch (e) {
      print('Error setting speech volume: $e');
    }
  }
  
  // Get appropriate color scheme based on accessibility settings
  static List<Color> getAccessibleColors() {
    try {
      if (isHighContrastEnabled) {
        return [
          Color(0xFF000000), // Black
          Color(0xFFFFFFFF), // White  
          Color(0xFF1976D2), // High contrast blue
          Color(0xFFFFD54F), // High contrast yellow
          Color(0xFF388E3C), // High contrast green
          Color(0xFFC2185B), // High contrast pink
          Color(0xFFF57C00), // High contrast orange
          Color(0xFF455A64), // High contrast gray
        ];
      }
      
      // Return therapy-tested category colors
      return [
        categoryColors['People']!,      // Yellow
        categoryColors['Actions']!,     // Green  
        categoryColors['Describing']!,  // Blue
        categoryColors['Social']!,      // Pink
        categoryColors['Food']!,        // Orange
        categoryColors['Misc']!,        // Gray
      ];
    } catch (e) {
      print('Error getting accessible colors: $e');
      // Return a default color scheme
      return [
        Color(0xFFFFC107), // Yellow
        Color(0xFF4CAF50), // Green
        Color(0xFF2196F3), // Blue
        Color(0xFFE91E63), // Pink
        Color(0xFFFF9800), // Orange
        Color(0xFF607D8B), // Gray
      ];
    }
  }
  
  // Get accessible text size multiplier
  static double getTextSizeMultiplier() {
    try {
      return isLargeTextEnabled ? 1.3 : 1.0;
    } catch (e) {
      print('Error getting text size multiplier: $e');
      return 1.0; // Default value
    }
  }
  
  // Create semantic label for symbols
  static String createSymbolSemanticLabel(Symbol symbol) {
    try {
      var label = 'Symbol: ${symbol.label}';
      if (symbol.description != null && symbol.description!.isNotEmpty) {
        label += ', ${symbol.description}';
      }
      label += ', Category: ${symbol.category}';
      label += ', Double tap to speak and interact';
      return label;
    } catch (e) {
      print('Error creating symbol semantic label: $e');
      return 'Symbol';
    }
  }
  
  // Create semantic label for categories  
  static String createCategorySemanticLabel(Category category, int symbolCount) {
    try {
      return 'Category: ${category.name}, $symbolCount symbols available, Double tap to open';
    } catch (e) {
      print('Error creating category semantic label: $e');
      return 'Category';
    }
  }
  
  // Provide haptic feedback based on settings
  static Future<void> accessibleHapticFeedback({
    String feedbackType = 'lightImpact',
  }) async {
    try {
      if (!isHapticFeedbackEnabled) return;
      
      switch (feedbackType) {
        case 'lightImpact':
          await HapticFeedback.lightImpact();
          break;
        case 'mediumImpact':
          await HapticFeedback.mediumImpact();
          break;
        case 'heavyImpact':
          await HapticFeedback.heavyImpact();
          break;
        case 'selectionClick':
          await HapticFeedback.selectionClick();
          break;
        case 'vibrate':
          await HapticFeedback.vibrate();
          break;
        default:
          await HapticFeedback.lightImpact();
          break;
      }
    } catch (e) {
      print('Error providing haptic feedback: $e');
    }
  }

  // Celebrate achievements for positive reinforcement
  static Future<void> celebrateAchievement(String message) async {
    try {
      // Play celebration sound
      await playSound(SoundEffect.celebration);
      
      // Provide haptic feedback
      await accessibleHapticFeedback(feedbackType: 'heavyImpact');
      
      // Speak with excited tone
      await speakWithEmotion(message, tone: EmotionalTone.excited);
      
      // Announce to screen reader
      await announceToScreenReader('Achievement unlocked! $message');
    } catch (e) {
      print('Error in celebrateAchievement: $e');
      // Fallback to basic feedback
      await provideFeedback(
        text: message,
        soundEffect: SoundEffect.celebration,
        tone: EmotionalTone.excited,
        haptic: true,
      );
    }
  }
  
  // Announce important information to screen readers
  static Future<void> announceToScreenReader(String message) async {
    try {
      await SemanticsService.announce(message, TextDirection.ltr);
    } catch (e) {
      print('Error announcing to screen reader: $e');
    }
  }

  // Provide gentle error feedback for children
  static Future<void> provideGentleErrorFeedback(String message) async {
    try {
      // Play gentle error sound (only once)
      await playSound(SoundEffect.error);
      
      // Provide light haptic feedback
      await accessibleHapticFeedback(feedbackType: 'lightImpact');
      
      // Speak with calm, encouraging tone
      await speakWithEmotion(message, tone: EmotionalTone.calm);
      
      // Announce to screen reader
      await announceToScreenReader('Error: $message');
    } catch (e) {
      print('Error in provideGentleErrorFeedback: $e');
      // Fallback to basic feedback
      await provideFeedback(
        text: message,
        soundEffect: SoundEffect.error,
        tone: EmotionalTone.calm,
        haptic: true,
      );
    }
  }
  
  // Focus management for keyboard navigation
  static void requestFocus(FocusNode focusNode) {
    try {
      if (focusNode.canRequestFocus) {
        focusNode.requestFocus();
      }
    } catch (e) {
      print('Error requesting focus: $e');
    }
  }

  // Generate a unique key for symbol grid caching
  static String generateSymbolGridKey(String category, int symbolCount) {
    try {
      return 'symbol_grid_${category}_${symbolCount}_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      print('Error generating symbol grid key: $e');
      return 'symbol_grid_default';
    }
  }

  // Validate email format
  static bool isValidEmail(String email) {
    try {
      if (email.isEmpty) return false;
      
      // Simple email validation regex
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      return emailRegex.hasMatch(email);
    } catch (e) {
      print('Error validating email: $e');
      return false;
    }
  }

  // Validate phone number format
  static bool isValidPhoneNumber(String phoneNumber) {
    try {
      if (phoneNumber.isEmpty) return false;
      
      // Simple phone number validation (allows + and digits)
      final phoneRegex = RegExp(r'^[+]?[0-9]{10,15}$');
      return phoneRegex.hasMatch(phoneNumber);
    } catch (e) {
      print('Error validating phone number: $e');
      return false;
    }
  }
  
  // ========== SOUND EFFECTS & ENHANCED AUDIO FEEDBACK ==========
  
  // Initialize sound effects
  static Future<void> initializeSoundEffects() async {
    try {
      await _audioPlayer.setVolume(soundVolume);
      
      // Preload common sound effects for better performance
      _preloadSoundEffects();
    } catch (e) {
      print('Error initializing sound effects: $e');
    }
  }
  
  static void _preloadSoundEffects() {
    try {
      // Preload sound effects to reduce latency (platform-dependent implementation)
      // This helps ensure smooth audio playback for children
    } catch (e) {
      print('Error preloading sound effects: $e');
    }
  }
  
  // Play sound effect with child-friendly audio - OPTIMIZED
  static Future<void> playSound(SoundEffect soundEffect, {bool respectSettings = true}) async {
    try {
      if (respectSettings && !isSoundEffectsEnabled) {
        return;
      }
      
      // Simplified sound effects to improve performance
      switch (soundEffect) {
        case SoundEffect.buttonTap:
        case SoundEffect.symbolSelect:
        case SoundEffect.pop:
          await SystemSound.play(SystemSoundType.click);
          break;
        case SoundEffect.success:
        case SoundEffect.celebration:
        case SoundEffect.chime:
          await SystemSound.play(SystemSoundType.alert);
          break;
        case SoundEffect.error:
          await SystemSound.play(SystemSoundType.alert);
          break;
        default:
          // For other sound effects, use click as fallback
          await SystemSound.play(SystemSoundType.click);
          break;
      }
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }
  
  // Play error sound as fallback
  static Future<void> _playErrorSound() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      debugPrint('Error playing error sound: $e');
    }
  }

  // Provide comprehensive feedback for child interactions
  static Future<void> provideFeedback({
    required String text,
    SoundEffect? soundEffect,
    EmotionalTone? tone,
    bool haptic = true,
    bool announce = false,
  }) async {
    try {
      // Play sound effect if provided
      if (soundEffect != null) {
        await playSound(soundEffect);
      }
      
      // Provide haptic feedback if enabled
      if (haptic && isHapticFeedbackEnabled) {
        await accessibleHapticFeedback();
      }
      
      // Speak with emotional tone
      if (tone != null) {
        await speakWithEmotion(text, tone: tone);
      } else {
        await speakWithAccessibility(text, announce: announce);
      }
      
      // Announce to screen reader if requested
      if (announce) {
        await announceToScreenReader(text);
      }
    } catch (e) {
      print('Error in provideFeedback: $e');
    }
  }
  
  // Sound effect settings
  static const String _soundEffectsKey = 'sound_effects_enabled';
  static const String _soundVolumeKey2 = 'sound_volume';
  
  static bool get isSoundEffectsEnabled {
    try {
      return getSetting<bool>(_soundEffectsKey, defaultValue: true)!;
    } catch (e) {
      print('Error getting sound effects setting: $e');
      return true; // Default to enabled
    }
  }
  
  static Future<void> setSoundEffects(bool enabled) async {
    try {
      await setSetting(_soundEffectsKey, enabled);
    } catch (e) {
      print('Error setting sound effects: $e');
    }
  }
  
  static double get soundVolume {
    try {
      return getSetting<double>(_soundVolumeKey2, defaultValue: 0.8)!;
    } catch (e) {
      print('Error getting sound volume: $e');
      return 0.8; // Default value
    }
  }
  
  static Future<void> setSoundVolume(double volume) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      await setSetting(_soundVolumeKey2, clampedVolume);
      await _audioPlayer.setVolume(clampedVolume);
    } catch (e) {
      print('Error setting sound volume: $e');
    }
  }
}
