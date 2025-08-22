import 'package:flutter_tts/flutter_tts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/symbol.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:audioplayers/audioplayers.dart';

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

class AACHelper {
  static late Box<Symbol> _symbolBox;
  static late Box<Category> _categoryBox;
  static late Box _settingsBox;
  static FlutterTts? _flutterTts;
  static final AudioPlayer _audioPlayer = AudioPlayer();
  
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
    final isHighContrast = getSetting<bool>('high_contrast', defaultValue: false) ?? false;
    final colorMap = isHighContrast ? highContrastColors : categoryColors;
    return colorMap[categoryName] ?? (isHighContrast ? highContrastColors['Misc']! : categoryColors['Misc']!);
  }

  // Initialize Hive database
  static Future<void> initializeDatabase() async {
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SymbolAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CategoryAdapter());
    }

    // Open boxes
    _symbolBox = await Hive.openBox<Symbol>('symbols');
    _categoryBox = await Hive.openBox<Category>('categories');
    _settingsBox = await Hive.openBox('settings');

    // Initialize default data if first time
    if (_categoryBox.isEmpty) {
      await _initializeDefaultData();
    }
  }

  // Initialize Text-to-Speech
  static Future<void> initializeTTS() async {
    _flutterTts = FlutterTts();
    
    await _flutterTts!.setLanguage('en-US');
    await _flutterTts!.setSpeechRate(0.6); // Slower for children
    await _flutterTts!.setVolume(1.0);
    await _flutterTts!.setPitch(1.2); // Slightly higher pitch for friendliness
  }

  // Text-to-Speech functionality (Enhanced with accessibility)
  static Future<void> speak(String text) async {
    await speakWithAccessibility(text);
  }

  static Future<void> stopSpeaking() async {
    if (_flutterTts != null) {
      await _flutterTts!.stop();
    }
  }

  // Symbol management
  static Future<void> addSymbol(Symbol symbol) async {
    await _symbolBox.add(symbol);
  }

  static Future<void> updateSymbol(int index, Symbol symbol) async {
    await _symbolBox.putAt(index, symbol);
  }

  static Future<void> deleteSymbol(int index) async {
    await _symbolBox.deleteAt(index);
  }

  static List<Symbol> getAllSymbols() {
    return _symbolBox.values.toList();
  }

  static List<Symbol> getSymbolsByCategory(String categoryName) {
    return _symbolBox.values
        .where((symbol) => symbol.category == categoryName)
        .toList();
  }

  // Category management
  static Future<void> addCategory(Category category) async {
    await _categoryBox.add(category);
  }

  static Future<void> updateCategory(int index, Category category) async {
    await _categoryBox.putAt(index, category);
  }

  static Future<void> deleteCategory(int index) async {
    await _categoryBox.deleteAt(index);
  }

  static List<Category> getAllCategories() {
    return _categoryBox.values.toList();
  }

  // Settings management
  static Future<void> setSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  static T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  // Initialize default categories and symbols
  static Future<void> _initializeDefaultData() async {
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
    return childFriendlyColors[
        DateTime.now().millisecond % childFriendlyColors.length];
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
  
  // Enhanced TTS with accessibility features
  static Future<void> initializeAccessibleTTS() async {
    _flutterTts = FlutterTts();
    
    // Get accessibility settings
    final speechRate = getSetting<double>(_speechRateKey, defaultValue: 0.5)!;
    final speechPitch = getSetting<double>(_speechPitchKey, defaultValue: 1.2)!;
    final speechVolume = getSetting<double>(_speechVolumeKey, defaultValue: 1.0)!;
    
    await _flutterTts!.setLanguage('en-US');
    await _flutterTts!.setSpeechRate(speechRate); // Adjustable for children
    await _flutterTts!.setVolume(speechVolume);
    await _flutterTts!.setPitch(speechPitch); // Higher pitch for friendliness
    
    // Set up TTS callbacks for better feedback
    _flutterTts!.setCompletionHandler(() {
      debugPrint('TTS: Speech completed');
    });
    
    _flutterTts!.setErrorHandler((message) {
      debugPrint('TTS Error: $message');
    });
  }
  
  // Enhanced speak method with accessibility features
  static Future<void> speakWithAccessibility(String text, {
    bool announce = false,
    bool haptic = true,
  }) async {
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
  }
  
  // Clean text for better speech synthesis
  static String _cleanTextForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), ' ')    // Normalize whitespace
        .trim();
  }
  
  // Auto-speak functionality for symbols
  static Future<void> autoSpeakSymbol(Symbol symbol) async {
    if (getSetting<bool>(_autoSpeakKey, defaultValue: true)!) {
      final text = symbol.description != null && symbol.description!.isNotEmpty
          ? '${symbol.label}. ${symbol.description}'
          : symbol.label;
      await speakWithAccessibility(text, haptic: false);
    }
  }
  
  // Accessibility Settings Getters/Setters
  static bool get isHighContrastEnabled => 
      getSetting<bool>(_highContrastKey, defaultValue: false)!;
      
  static Future<void> setHighContrast(bool enabled) async {
    await setSetting(_highContrastKey, enabled);
  }
  
  static bool get isLargeTextEnabled => 
      getSetting<bool>(_largeTextKey, defaultValue: false)!;
      
  static Future<void> setLargeText(bool enabled) async {
    await setSetting(_largeTextKey, enabled);
  }
  
  static bool get isVoiceFeedbackEnabled => 
      getSetting<bool>(_voiceFeedbackKey, defaultValue: true)!;
      
  static Future<void> setVoiceFeedback(bool enabled) async {
    await setSetting(_voiceFeedbackKey, enabled);
  }
  
  static bool get isHapticFeedbackEnabled => 
      getSetting<bool>(_hapticFeedbackKey, defaultValue: true)!;
      
  static Future<void> setHapticFeedback(bool enabled) async {
    await setSetting(_hapticFeedbackKey, enabled);
  }
  
  static bool get isAutoSpeakEnabled => 
      getSetting<bool>(_autoSpeakKey, defaultValue: true)!;
      
  static Future<void> setAutoSpeak(bool enabled) async {
    await setSetting(_autoSpeakKey, enabled);
  }
  
  // Speech rate control (0.1 to 1.0)
  static double get speechRate => 
      getSetting<double>(_speechRateKey, defaultValue: 0.5)!;
      
  static Future<void> setSpeechRate(double rate) async {
    final clampedRate = rate.clamp(0.1, 1.0);
    await setSetting(_speechRateKey, clampedRate);
    if (_flutterTts != null) {
      await _flutterTts!.setSpeechRate(clampedRate);
    }
  }
  
  // Speech pitch control (0.5 to 2.0)
  static double get speechPitch => 
      getSetting<double>(_speechPitchKey, defaultValue: 1.2)!;
      
  static Future<void> setSpeechPitch(double pitch) async {
    final clampedPitch = pitch.clamp(0.5, 2.0);
    await setSetting(_speechPitchKey, clampedPitch);
    if (_flutterTts != null) {
      await _flutterTts!.setPitch(clampedPitch);
    }
  }
  
  // Speech volume control (0.0 to 1.0)
  static double get speechVolume => 
      getSetting<double>(_speechVolumeKey, defaultValue: 1.0)!;
      
  static Future<void> setSpeechVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    await setSetting(_speechVolumeKey, clampedVolume);
    if (_flutterTts != null) {
      await _flutterTts!.setVolume(clampedVolume);
    }
  }
  
  // Get appropriate color scheme based on accessibility settings
  static List<Color> getAccessibleColors() {
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
  }
  
  // Get accessible text size multiplier
  static double getTextSizeMultiplier() {
    return isLargeTextEnabled ? 1.3 : 1.0;
  }
  
  // Create semantic label for symbols
  static String createSymbolSemanticLabel(Symbol symbol) {
    var label = 'Symbol: ${symbol.label}';
    if (symbol.description != null && symbol.description!.isNotEmpty) {
      label += ', ${symbol.description}';
    }
    label += ', Category: ${symbol.category}';
    label += ', Double tap to speak and interact';
    return label;
  }
  
  // Create semantic label for categories  
  static String createCategorySemanticLabel(Category category, int symbolCount) {
    return 'Category: ${category.name}, $symbolCount symbols available, Double tap to open';
  }
  
  // Provide haptic feedback based on settings
  static Future<void> accessibleHapticFeedback({
    HapticFeedback? feedbackType,
  }) async {
    if (!isHapticFeedbackEnabled) return;
    
    switch (feedbackType ?? HapticFeedback.lightImpact) {
      case HapticFeedback.lightImpact:
        await HapticFeedback.lightImpact();
        break;
      case HapticFeedback.mediumImpact:
        await HapticFeedback.mediumImpact();
        break;
      case HapticFeedback.heavyImpact:
        await HapticFeedback.heavyImpact();
        break;
      case HapticFeedback.selectionClick:
        await HapticFeedback.selectionClick();
        break;
      case HapticFeedback.vibrate:
        await HapticFeedback.vibrate();
        break;
    }
  }
  
  // Announce important information to screen readers
  static Future<void> announceToScreenReader(String message) async {
    await SemanticsService.announce(message, TextDirection.ltr);
  }
  
  // Focus management for keyboard navigation
  static void requestFocus(FocusNode focusNode) {
    if (focusNode.canRequestFocus) {
      focusNode.requestFocus();
    }
  }
  
  // ========== SOUND EFFECTS & ENHANCED AUDIO FEEDBACK ==========
  
  // Initialize sound effects
  static Future<void> initializeSoundEffects() async {
    await _audioPlayer.setVolume(soundVolume);
    
    // Preload common sound effects for better performance
    _preloadSoundEffects();
  }
  
  static void _preloadSoundEffects() {
    // Preload sound effects to reduce latency (platform-dependent implementation)
    // This helps ensure smooth audio playback for children
  }
  
  // Play sound effect with child-friendly audio
  static Future<void> playSound(SoundEffect soundEffect, {bool respectSettings = true}) async {
    if (respectSettings && !isSoundEffectsEnabled) {
      return;
    }
    
    try {
      // Generate child-friendly sound frequencies
      String soundPath = _getSoundPath(soundEffect);
      
      // For now, we'll use SystemSound for platform sounds
      // In a full implementation, you'd have actual sound files
      switch (soundEffect) {
        case SoundEffect.buttonTap:
        case SoundEffect.symbolSelect:
          await SystemSound.play(SystemSoundType.click);
          break;
        case SoundEffect.success:
        case SoundEffect.celebration:
          await SystemSound.play(SystemSoundType.alert);
          break;
        case SoundEffect.error:
          // Play error sound twice for emphasis
          await SystemSound.play(SystemSoundType.alert);
          await Future.delayed(const Duration(milliseconds: 100));
          await SystemSound.play(SystemSoundType.alert);
          break;
        case SoundEffect.notification:
        case SoundEffect.chime:
          await SystemSound.play(SystemSoundType.alert);
          break;
        case SoundEffect.categoryOpen:
        case SoundEffect.pop:
        case SoundEffect.swoosh:
          await SystemSound.play(SystemSoundType.click);
          break;
      }
      
    } catch (e) {
      debugPrint('Error playing sound effect: $e');
    }
  }
  
  static String _getSoundPath(SoundEffect soundEffect) {
    // Return paths to sound files for each effect
    // In a full implementation, these would be actual audio files
    switch (soundEffect) {
      case SoundEffect.buttonTap:
        return 'sounds/button_tap.mp3';
      case SoundEffect.symbolSelect:
        return 'sounds/symbol_select.mp3';
      case SoundEffect.categoryOpen:
        return 'sounds/category_open.mp3';
      case SoundEffect.success:
        return 'sounds/success.mp3';
      case SoundEffect.error:
        return 'sounds/error.mp3';
      case SoundEffect.notification:
        return 'sounds/notification.mp3';
      case SoundEffect.celebration:
        return 'sounds/celebration.mp3';
      case SoundEffect.pop:
        return 'sounds/pop.mp3';
      case SoundEffect.swoosh:
        return 'sounds/swoosh.mp3';
      case SoundEffect.chime:
        return 'sounds/chime.mp3';
    }
  }
  
  // Enhanced voice feedback with emotional context
  static Future<void> speakWithEmotion(String text, {
    EmotionalTone tone = EmotionalTone.friendly,
    bool playSoundEffect = true,
  }) async {
    // Adjust TTS parameters based on emotional tone
    if (_flutterTts != null) {
      switch (tone) {
        case EmotionalTone.excited:
          await _flutterTts!.setSpeechRate(0.7);
          await _flutterTts!.setPitch(1.4);
          if (playSoundEffect) await playSound(SoundEffect.celebration);
          break;
        case EmotionalTone.calm:
          await _flutterTts!.setSpeechRate(0.4);
          await _flutterTts!.setPitch(1.0);
          if (playSoundEffect) await playSound(SoundEffect.chime);
          break;
        case EmotionalTone.encouraging:
          await _flutterTts!.setSpeechRate(0.6);
          await _flutterTts!.setPitch(1.3);
          if (playSoundEffect) await playSound(SoundEffect.success);
          break;
        case EmotionalTone.friendly:
        default:
          await _flutterTts!.setSpeechRate(speechRate);
          await _flutterTts!.setPitch(speechPitch);
          if (playSoundEffect) await playSound(SoundEffect.buttonTap);
          break;
      }
    }
    
    await speakWithAccessibility(text, haptic: true);
    
    // Restore original settings
    if (_flutterTts != null) {
      await _flutterTts!.setSpeechRate(speechRate);
      await _flutterTts!.setPitch(speechPitch);
    }
  }
  
  // Voice feedback with contextual sounds for different interactions
  static Future<void> speakSymbolWithContext(Symbol symbol) async {
    await playSound(SoundEffect.symbolSelect);
    
    // Create rich context for the symbol
    String contextText = symbol.label;
    if (symbol.description != null && symbol.description!.isNotEmpty) {
      contextText += '. ${symbol.description}';
    }
    contextText += '. From ${symbol.category} category.';
    
    await speakWithEmotion(contextText, tone: EmotionalTone.friendly);
  }
  
  // Category opening with sound and voice
  static Future<void> speakCategoryWithContext(Category category, int symbolCount) async {
    await playSound(SoundEffect.categoryOpen);
    
    String contextText = 'Opening ${category.name} category. ';
    if (symbolCount > 0) {
      contextText += 'This category has $symbolCount symbols to choose from.';
    } else {
      contextText += 'This category is empty. You can add symbols here.';
    }
    
    await speakWithEmotion(contextText, tone: EmotionalTone.encouraging);
  }
  
  // Celebration feedback for achievements
  static Future<void> celebrateAchievement(String achievementText) async {
    await playSound(SoundEffect.celebration);
    await speakWithEmotion(
      'Great job! $achievementText',
      tone: EmotionalTone.excited,
      playSoundEffect: false, // Sound already played
    );
  }
  
  // Error feedback with gentle guidance
  static Future<void> provideGentleErrorFeedback(String errorText) async {
    await playSound(SoundEffect.error);
    await speakWithEmotion(
      'Let\'s try that again. $errorText',
      tone: EmotionalTone.calm,
      playSoundEffect: false, // Sound already played
    );
  }
  
  // Sound effects settings
  static const String _soundEffectsKey = 'sound_effects_enabled';
  static const String _soundVolumeKey = 'sound_volume';
  
  static bool get isSoundEffectsEnabled => 
      getSetting<bool>(_soundEffectsKey, defaultValue: true)!;
      
  static Future<void> setSoundEffects(bool enabled) async {
    await setSetting(_soundEffectsKey, enabled);
  }
  
  static double get soundVolume => 
      getSetting<double>(_soundVolumeKey, defaultValue: 0.8)!;
      
  static Future<void> setSoundVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    await setSetting(_soundVolumeKey, clampedVolume);
    await _audioPlayer.setVolume(clampedVolume);
  }
  
  // Enhanced interaction feedback
  static Future<void> provideFeedback({
    required String text,
    SoundEffect? soundEffect,
    EmotionalTone tone = EmotionalTone.friendly,
    bool haptic = true,
    bool announce = false,
  }) async {
    // Play sound effect if specified
    if (soundEffect != null) {
      await playSound(soundEffect);
    }
    
    // Provide haptic feedback
    if (haptic) {
      await accessibleHapticFeedback();
    }
    
    // Speak with emotional context
    await speakWithEmotion(text, tone: tone, playSoundEffect: false);
    
    // Screen reader announcement if needed
    if (announce) {
      await announceToScreenReader(text);
    }
  }
  
  // Dispose resources
  static Future<void> dispose() async {
    await _flutterTts?.stop();
    await _audioPlayer.dispose();
    await Hive.close();
  }
}