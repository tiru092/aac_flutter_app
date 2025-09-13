import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';

class LanguageService {
  static const String _currentLanguageKey = 'current_language';
  static const String _supportedLanguagesKey = 'supported_languages';
  static const String _ttsVoiceKey = 'tts_voice_settings';
  static const String _translationsKey = 'custom_translations';

  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();
  
  static LanguageService get instance => _instance;

  String _currentLanguage = 'en-IN';
  Map<String, SupportedLanguage> _supportedLanguages = {};
  TTSVoiceSettings? _ttsVoiceSettings;
  Map<String, Map<String, String>> _translations = {};
  FlutterTts? _flutterTts;
  
  // Performance monitoring
  int _translationCacheHits = 0;
  int _translationCacheMisses = 0;
  DateTime? _lastPerformanceReport;
  
  // Memory management
  static const int _maxCacheSize = 1000;
  final Map<String, String> _translationCache = {};

  String get currentLanguage => _currentLanguage;
  Map<String, SupportedLanguage> get supportedLanguages => _supportedLanguages;
  TTSVoiceSettings? get ttsVoiceSettings => _ttsVoiceSettings;
  
  // Performance monitoring methods
  void _reportPerformanceMetrics() {
    final now = DateTime.now();
    if (_lastPerformanceReport == null || 
        now.difference(_lastPerformanceReport!).inMinutes >= 5) {
      final totalRequests = _translationCacheHits + _translationCacheMisses;
      final hitRate = totalRequests > 0 ? (_translationCacheHits / totalRequests * 100).toStringAsFixed(2) : '0.00';
      
      print('[LanguageService] Performance Report:');
      print('  - Cache hits: $_translationCacheHits');
      print('  - Cache misses: $_translationCacheMisses');
      print('  - Hit rate: $hitRate%');
      print('  - Cache size: ${_translationCache.length}');
      print('  - Memory usage: ${_translations.length} languages loaded');
      
      _lastPerformanceReport = now;
    }
  }
  
  void _manageCacheSize() {
    if (_translationCache.length > _maxCacheSize) {
      // Remove oldest entries (simple LRU simulation)
      final keysToRemove = _translationCache.keys.take(_translationCache.length - _maxCacheSize ~/ 2).toList();
      for (final key in keysToRemove) {
        _translationCache.remove(key);
      }
      print('[LanguageService] Cache cleaned: removed ${keysToRemove.length} entries');
    }
  }
  
  // Security and maintenance methods
  void clearCache() {
    _translationCache.clear();
    _translationCacheHits = 0;
    _translationCacheMisses = 0;
    print('[LanguageService] Cache and metrics cleared');
  }
  
  Map<String, dynamic> getServiceHealth() {
    final totalRequests = _translationCacheHits + _translationCacheMisses;
    return {
      'status': 'healthy',
      'current_language': _currentLanguage,
      'supported_languages_count': _supportedLanguages.length,
      'translations_loaded': _translations.length,
      'cache_size': _translationCache.length,
      'cache_hits': _translationCacheHits,
      'cache_misses': _translationCacheMisses,
      'cache_hit_rate': totalRequests > 0 ? (_translationCacheHits / totalRequests * 100).toStringAsFixed(2) : '0.00',
      'tts_initialized': _flutterTts != null,
      'last_performance_report': _lastPerformanceReport?.toIso8601String(),
    };
  }

  Future<void> initialize() async {
    try {
      print('[LanguageService] Starting initialization...');
      
      await _loadCurrentLanguage();
      await _loadSupportedLanguages();
      await _loadTTSVoiceSettings();
      await _loadTranslations();
      
      // If no supported languages, initialize with defaults
      if (_supportedLanguages.isEmpty) {
        print('[LanguageService] No supported languages found, initializing defaults...');
        await _initializeDefaultLanguages();
      }
      
      // If no translations loaded, initialize defaults
      if (_translations.isEmpty) {
        print('[LanguageService] No translations found, initializing defaults...');
        await _initializeDefaultTranslations();
      }
      
      await _initializeTTS();
      
      print('[LanguageService] Initialization completed successfully');
      print('[LanguageService] Current language: $_currentLanguage');
      print('[LanguageService] Supported languages: ${_supportedLanguages.keys.join(", ")}');
      print('[LanguageService] Available translations: ${_translations.keys.join(", ")}');
      
    } catch (e, stackTrace) {
      print('[LanguageService] ERROR during initialization: $e');
      print('[LanguageService] Stack trace: $stackTrace');
      
      // Fallback initialization to ensure app doesn't crash
      try {
        await _initializeDefaultLanguages();
        await _initializeDefaultTranslations();
        print('[LanguageService] Fallback initialization completed');
      } catch (fallbackError) {
        print('[LanguageService] CRITICAL ERROR: Fallback initialization failed: $fallbackError');
        rethrow;
      }
    }
  }

  Future<void> _initializeTTS() async {
    _flutterTts = FlutterTts();
    
    // Set current language if TTS settings exist
    if (_ttsVoiceSettings != null) {
      await _flutterTts!.setLanguage(_ttsVoiceSettings!.languageCode);
      await _flutterTts!.setPitch(_ttsVoiceSettings!.pitch);
      await _flutterTts!.setSpeechRate(_ttsVoiceSettings!.speechRate);
      
      if (_ttsVoiceSettings!.voiceId.isNotEmpty) {
        // Try to set specific voice if supported
        try {
          final voices = await _flutterTts!.getVoices;
          final voice = voices?.firstWhere(
            (v) {
              try {
                if (v is! Map) return false;
                final voiceMap = Map<String, dynamic>.from(v as Map);
                return voiceMap['name']?.toString() == _ttsVoiceSettings!.voiceId;
              } catch (e) {
                return false;
              }
            },
            orElse: () => null,
          );
          if (voice != null) {
            // Convert to Map<String, String> as expected by setVoice
            final voiceData = Map<String, String>.from(
              Map<String, dynamic>.from(voice as Map).map(
                (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
              ),
            );
            await _flutterTts!.setVoice(voiceData);
          }
        } catch (e) {
          print('[TTS] Error setting voice during initialization: $e');
        }
      }
    }
  }

  Future<void> _initializeDefaultLanguages() async {

    _supportedLanguages = {

      'en-US': SupportedLanguage(

        code: 'en-US',

        name: 'English (US)',

        nativeName: 'English (US)',

        flag: '🇺🇸',

        isRTL: false,

      ),

      'en-IN': SupportedLanguage(

        code: 'en-IN',

        name: 'English (India)',

        nativeName: 'English (India)',

        flag: '🇮🇳',

        isRTL: false,

      ),

      // Indian Local Languages

      'hi-IN': SupportedLanguage(

        code: 'hi-IN',

        name: 'Hindi',

        nativeName: 'हिन्दी',

        flag: '🇮🇳',

        isRTL: false,

      ),

      'kn-IN': SupportedLanguage(

        code: 'kn-IN',

        name: 'Kannada',

        nativeName: 'ಕನ್ನಡ',

        flag: '🇮🇳',

        isRTL: false,

      ),

      'ta-IN': SupportedLanguage(

        code: 'ta-IN',

        name: 'Tamil',

        nativeName: 'தமிழ்',

        flag: '🇮🇳',

        isRTL: false,

      ),

      'te-IN': SupportedLanguage(

        code: 'te-IN',

        name: 'Telugu',

        nativeName: 'తెలుగు',

        flag: '🇮🇳',

        isRTL: false,

      ),

      'mr-IN': SupportedLanguage(

        code: 'mr-IN',

        name: 'Marathi',

        nativeName: 'मराठी',

        flag: '🇮🇳',

        isRTL: false,

      ),

      'gu-IN': SupportedLanguage(

        code: 'gu-IN',

        name: 'Gujarati',

        nativeName: 'ગુજરાતી',

        flag: '🇮🇳',

        isRTL: false,

      ),

      // International Languages  

      'es-ES': SupportedLanguage(

        code: 'es-ES',

        name: 'Spanish',

        nativeName: 'Español',

        flag: '🇪🇸',

        isRTL: false,

      ),

      'fr-FR': SupportedLanguage(

        code: 'fr-FR',

        name: 'French',

        nativeName: 'Français',

        flag: '🇫🇷',

        isRTL: false,

      ),

      'de-DE': SupportedLanguage(

        code: 'de-DE',

        name: 'German',

        nativeName: 'Deutsch',

        flag: '🇩🇪',

        isRTL: false,

      ),

      'zh-CN': SupportedLanguage(

        code: 'zh-CN',

        name: 'Chinese (Simplified)',

        nativeName: '中文 (简体)',

        flag: '🇨🇳',

        isRTL: false,

      ),

      'ar-SA': SupportedLanguage(

        code: 'ar-SA',

        name: 'Arabic',

        nativeName: 'العربية',

        flag: '🇸🇦',

        isRTL: true,

      ),

    };
    
    await _saveSupportedLanguages();
    
    // Initialize default translations
    await _initializeDefaultTranslations();
  }

  Future<void> _initializeDefaultTranslations() async {

    _translations = {

      'en-US': {

        'app_title': 'AAC Communication',

        'hello': 'Hello',

        'categories': 'Categories',

        'all_symbols': 'All Symbols',

        'settings': 'Settings',

        'history': 'History',

        'profile': 'Profile',

        'add_symbol': 'Add Symbol',

        'edit_symbol': 'Edit Symbol',

        'delete_symbol': 'Delete Symbol',

        'speak': 'Speak',

        'clear': 'Clear',

        'undo': 'Undo',

        'quick_phrases': 'Quick Phrases',

        'phrase_history': 'Phrase History',

        'recent': 'Recent',

        'favorites': 'Favorites',

        'language_settings': 'Language Settings',

        'voice_settings': 'Voice Settings',

        'select_language': 'Select Language',

        'select_voice': 'Select Voice',

        'speech_rate': 'Speech Rate',

        'pitch': 'Pitch',

        'test_voice': 'Test Voice',

        'all': 'All',

        'menu': 'Menu',

        'say_hello_friend': 'Say "hello" to a friend',

        'ask_for_drink': 'Ask for a drink',

        'express_emotion': 'Express an emotion',

        'practice_name': 'Practice saying my name',

        'access_app_features': 'Access app features and settings',

        'configure_aac_settings': 'Configure your AAC app settings',

        'error': 'Error',

        'ok': 'OK',

        'please': 'Please',

        'thank_you': 'Thank You',

        'help_me': 'Help Me',

        'feature_coming_soon': 'This feature coming soon on next release',

        'coming_soon_banner': 'Coming Soon',

        'stop': 'Stop',

        'more': 'More',

        'more_please': 'More please',

  'help_me_please': 'Help me please',
  'category_label': 'Category',
  'symbols_available': 'symbols available',
  'double_tap_to_open': 'Double tap to open',
  'symbol_label': 'Symbol',
  'double_tap_to_speak': 'Double tap to speak',
  'no_symbols_yet': 'No symbols yet!',
        'tap_plus_to_add': 'Tap the + button to add your first symbol',
        'failed_to_change_category': 'Failed to change category',
      },

      'en-IN': {

        'app_title': 'AAC Communication',

        'hello': 'Hello',

        'categories': 'Categories',

        'all_symbols': 'All Symbols',

        'settings': 'Settings',

        'history': 'History',

        'profile': 'Profile',

        'add_symbol': 'Add Symbol',

        'edit_symbol': 'Edit Symbol',

        'delete_symbol': 'Delete Symbol',

        'speak': 'Speak',

        'clear': 'Clear',

        'undo': 'Undo',

        'quick_phrases': 'Quick Phrases',

        'phrase_history': 'Phrase History',

        'recent': 'Recent',

        'favorites': 'Favourites',

        'language_settings': 'Language Settings',

        'voice_settings': 'Voice Settings',

        'select_language': 'Select Language',

        'select_voice': 'Select Voice',

        'speech_rate': 'Speech Rate',

        'pitch': 'Pitch',

        'test_voice': 'Test Voice',

        'all': 'All',

        'say_hello_friend': 'Say "hello" to a friend',

        'ask_for_drink': 'Ask for a drink',

        'express_emotion': 'Express an emotion',

        'practice_name': 'Practice saying my name',

        'access_app_features': 'Access app features and settings',

        'configure_aac_settings': 'Configure your AAC app settings',

        'error': 'Error',

  'ok': 'OK',
  'category_label': 'Category',
  'symbols_available': 'symbols available',
  'double_tap_to_open': 'Double tap to open',
  'symbol_label': 'Symbol',
  'double_tap_to_speak': 'Double tap to speak',
  'no_symbols_yet': 'No symbols yet!',
  'tap_plus_to_add': 'Tap the + button to add your first symbol',
        
        // Common symbol translations
        'milk': 'Milk',
        'water': 'Water',
        'apple': 'Apple',
        'food': 'Food',
        'drink': 'Drink',
        'hello': 'Hello',
        'yes': 'Yes',
        'no': 'No',
        'please': 'Please',
        'thank_you': 'Thank You',
        'help': 'Help',
        'more': 'More',
        'stop': 'Stop',
        
        // Core UI translations
        'initializing_security': 'Initializing security...',
        'try_again': 'Try Again',
        'ok': 'OK',
        'cancel': 'Cancel',
        'delete': 'Delete',
        'save': 'Save',
        'add': 'Add',
        'edit': 'Edit',
        'close': 'Close',
        'loading': 'Loading...',
        'error': 'Error',
        'success': 'Success',
        'warning': 'Warning',
        'confirm': 'Confirm',

      },

      // Hindi translations

      'hi-IN': {

        'app_title': 'एएसी संवाद',

        'hello': 'नमस्ते',

        'categories': 'श्रेणियां',

        'all_symbols': 'सभी प्रतीक',

        'settings': 'सेटिंग्स',

        'history': 'इतिहास',

        'profile': 'प्रोफ़ाइल',

        'add_symbol': 'प्रतीक जोड़ें',

        'edit_symbol': 'प्रतीक संपादित करें',

        'delete_symbol': 'प्रतीक हटाएं',

        'speak': 'बोलना',

        'clear': 'साफ़ करें',

        'undo': 'पूर्ववत करें',

        'quick_phrases': 'त्वरित वाक्य',

        'phrase_history': 'वाक्य इतिहास',

        'recent': 'हाल ही में',

        'favorites': 'पसंदीदा',

        'language_settings': 'भाषा सेटिंग्स',

        'voice_settings': 'आवाज़ सेटिंग्स',

        'select_language': 'भाषा चुनें',

        'select_voice': 'आवाज़ चुनें',

        'speech_rate': 'बोलने की गति',

        'pitch': 'स्वर',

        'test_voice': 'आवाज़ परखें',

        'all': 'सभी',

        'say_hello_friend': 'किसी दोस्त को "नमस्ते" कहें',

        'ask_for_drink': 'पीने की चीज़ मांगें',

        'express_emotion': 'भावना व्यक्त करें',

        'practice_name': 'अपना नाम कहने का अभ्यास करें',

        'access_app_features': 'ऐप सुविधाओं और सेटिंग्स तक पहुंचें',

        'configure_aac_settings': 'अपनी AAC ऐप सेटिंग्स कॉन्फ़िगर करें',

        'error': 'त्रुटि',

  'ok': 'ठीक है',
  'category_label': 'श्रेणी',
  'symbols_available': 'उपलब्ध प्रतीक',
  'double_tap_to_open': 'खोलने के लिए डबल टैप करें',
  'symbol_label': 'प्रतीक',
  'double_tap_to_speak': 'बोलने के लिए डबल टैप करें',
  'no_symbols_yet': 'अभी तक कोई प्रतीक नहीं!',
  'tap_plus_to_add': '+ बटन दबाकर अपना पहला प्रतीक जोड़ें',
        'failed_to_change_category': 'श्रेणी बदलने में असफल',
        
        // Common symbol translations
        'milk': 'दूध',
        'water': 'पानी',
        'apple': 'सेब',
        'food': 'खाना',
        'drink': 'पेय',
        'hello': 'नमस्ते',
        'yes': 'हाँ',
        'no': 'नहीं',
        'please': 'कृपया',
        'thank_you': 'धन्यवाद',
        'help': 'मदद',
        'more': 'और',
        'stop': 'रुको',
        
        // Core UI translations
        'initializing_security': 'सुरक्षा प्रारंभ की जा रही है...',
        'try_again': 'पुनः प्रयास करें',
        'ok': 'ठीक है',
        'cancel': 'रद्द करें',
        'delete': 'हटाएं',
        'save': 'सहेजें',
        'add': 'जोड़ें',
        'edit': 'संपादित करें',
        'close': 'बंद करें',
        'loading': 'लोड हो रहा है...',
        'error': 'त्रुटि',
        'success': 'सफलता',
        'warning': 'चेतावनी',
        'confirm': 'पुष्टि करें',

        'feature_coming_soon': 'यह सुविधा अगली रिलीज़ में जल्द आ रही है',

        'coming_soon_banner': 'जल्द आ रहा है',

      },

      // Kannada translations

      'kn-IN': {

        'app_title': 'ಎಎಸಿ ಸಂವಹನ',

        'hello': 'ನಮಸ್ಕಾರ',

        'categories': 'ವರ್ಗಗಳು',

        'all_symbols': 'ಎಲ್ಲಾ ಚಿಹ್ನೆಗಳು',

        'settings': 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು',

        'history': 'ಇತಿಹಾಸ',

        'profile': 'ಪ್ರೊಫೈಲ್',

        'add_symbol': 'ಚಿಹ್ನೆ ಸೇರಿಸಿ',

        'edit_symbol': 'ಚಿಹ್ನೆ ಸಂಪಾದಿಸಿ',

        'delete_symbol': 'ಚಿಹ್ನೆ ಅಳಿಸಿ',

        'speak': 'ಮಾತನಾಡು',

        'clear': 'ತೆರವುಗೊಳಿಸು',

        'undo': 'ರದ್ದುಗೊಳಿಸು',

        'quick_phrases': 'ತ್ವರಿತ ವಾಕ್ಯಗಳು',

        'phrase_history': 'ವಾಕ್ಯ ಇತಿಹಾಸ',

        'recent': 'ಇತ್ತೀಚಿನ',

        'favorites': 'ಮೆಚ್ಚಿನವುಗಳು',

        'language_settings': 'ಭಾಷಾ ಸೆಟ್ಟಿಂಗ್‌ಗಳು',

        'voice_settings': 'ಧ್ವನಿ ಸೆಟ್ಟಿಂಗ್‌ಗಳು',

        'select_language': 'ಭಾಷೆ ಆಯ್ಕೆಮಾಡಿ',

        'select_voice': 'ಧ್ವನಿ ಆಯ್ಕೆಮಾಡಿ',

        'speech_rate': 'ಮಾತಿನ ವೇಗ',

        'pitch': 'ಸ್ವರ',

        'test_voice': 'ಧ್ವನಿ ಪರೀಕ್ಷೆ',

        'all': 'ಎಲ್ಲಾ',

        'menu': 'ಮೆನು',

        'say_hello_friend': 'ಸ್ನೇಹಿತನಿಗೆ "ನಮಸ್ಕಾರ" ಹೇಳಿ',

        'ask_for_drink': 'ಪಾನೀಯವನ್ನು ಕೇಳಿ',

        'express_emotion': 'ಭಾವನೆಯನ್ನು ವ್ಯಕ್ತಪಡಿಸಿ',

        'practice_name': 'ನನ್ನ ಹೆಸರನ್ನು ಹೇಳುವ ಅಭ್ಯಾಸ ಮಾಡಿ',

        'access_app_features': 'ಆ್ಯಪ್ ವೈಶಿಷ್ಟ್ಯಗಳು ಮತ್ತು ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ಪ್ರವೇಶಿಸಿ',

        'configure_aac_settings': 'ನಿಮ್ಮ AAC ಆ್ಯಪ್ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ಕಾನ್ಫಿಗರ್ ಮಾಡಿ',

        'error': 'ದೋಷ',

        'ok': 'ಸರಿ',

        'please': 'ದಯವಿಟ್ಟು',

        'thank_you': 'ಧನ್ಯವಾದ',

        'help_me': 'ನನಗೆ ಸಹಾಯ ಮಾಡಿ',

        'stop': 'ನಿಲ್ಲಿಸಿ',

        'more': 'ಇನ್ನಷ್ಟು',

        'more_please': 'ಇನ್ನಷ್ಟು ದಯವಿಟ್ಟು',

  'help_me_please': 'ದಯವಿಟ್ಟು ನನಗೆ ಸಹಾಯ ಮಾಡಿ',
  'category_label': 'ವರ್ಗ',
  'symbols_available': 'ಲಭ್ಯ ಚಿಹ್ನೆಗಳು',
  'double_tap_to_open': 'ತೆರೆಯಲು ಡಬಲ್ ಟ್ಯಾಪ್ ಮಾಡಿ',
  'symbol_label': 'ಚಿಹ್ನೆ',
  'double_tap_to_speak': 'ಮಾತನಾಡಲು ಡಬಲ್ ಟ್ಯಾಪ್ ಮಾಡಿ',
  'no_symbols_yet': 'ಇನ್ನೂ ಚಿಹ್ನೆಗಳು ಇಲ್ಲ!',
  'tap_plus_to_add': '+ ಬಟನ್ ಒತ್ತಿ ಮೊದಲ ಚಿಹ್ನೆ ಸೇರಿಸಿ',
        'failed_to_change_category': 'ವರ್ಗವನ್ನು ಬದಲಾಯಿಸಲು ವಿಫಲವಾಗಿದೆ',
        
        // Common symbol translations
        'milk': 'ಹಾಲು',
        'water': 'ನೀರು',
        'apple': 'ಸೇಬು',
        'food': 'ಆಹಾರ',
        'drink': 'ಪಾನೀಯ',
        'hello': 'ನಮಸ್ಕಾರ',
        'yes': 'ಹೌದು',
        'no': 'ಇಲ್ಲ',
        'please': 'ದಯವಿಟ್ಟು',
        'thank_you': 'ಧನ್ಯವಾದ',
        'help': 'ಸಹಾಯ',
        'more': 'ಹೆಚ್ಚು',
        'stop': 'ನಿಲ್ಲಿಸಿ',
        
        // Core UI translations
        'initializing_security': 'ಭದ್ರತೆಯನ್ನು ಪ್ರಾರಂಭಿಸಲಾಗುತ್ತಿದೆ...',
        'try_again': 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ',
        'ok': 'ಸರಿ',
        'cancel': 'ರದ್ದುಮಾಡಿ',
        'delete': 'ಅಳಿಸಿ',
        'save': 'ಉಳಿಸಿ',
        'add': 'ಸೇರಿಸಿ',
        'edit': 'ಸಂಪಾದಿಸಿ',
        'close': 'ಮುಚ್ಚಿ',
        'loading': 'ಲೋಡ್ ಆಗುತ್ತಿದೆ...',
        'error': 'ದೋಷ',
        'success': 'ಯಶಸ್ಸು',
        'warning': 'ಎಚ್ಚರಿಕೆ',
        'confirm': 'ದೃಢೀಕರಿಸಿ',

        'feature_coming_soon': 'ಈ ವೈಶಿಷ್ಟ್ಯವು ಮುಂದಿನ ಬಿಡುಗಡೆಯಲ್ಲಿ ಶೀಘ್ರದಲ್ಲೇ ಬರುತ್ತಿದೆ',

        'coming_soon_banner': 'ಶೀಘ್ರದಲ್ಲೇ ಬರುತ್ತಿದೆ',

      },

      // Tamil translations

      'ta-IN': {

        'app_title': 'ஏஏசி தொடர்பு',

        'hello': 'வணக்கம்',

        'categories': 'பிரிவுகள்',

        'all_symbols': 'அனைத்து குறியீடுகள்',

        'settings': 'அமைப்புகள்',

        'history': 'வரலாறு',

        'profile': 'சுயவிவரம்',

        'add_symbol': 'குறியீடு சேர்க்கவும்',

        'edit_symbol': 'குறியீடு திருத்தவும்',

        'delete_symbol': 'குறியீடு நீக்கவும்',

        'speak': 'பேசு',

        'clear': 'அழிக்கவும்',

        'undo': 'செயல்தவிர்',

        'quick_phrases': 'விரைவு வாக்கியங்கள்',

        'phrase_history': 'வாக்கிய வரலாறு',

        'recent': 'சமீபத்திய',

        'favorites': 'பிடித்தவை',

        'language_settings': 'மொழி அமைப்புகள்',

        'voice_settings': 'குரல் அமைப்புகள்',

        'select_language': 'மொழியைத் தேர்ந்தெடுக்கவும்',

        'select_voice': 'குரலைத் தேர்ந்தெடுக்கவும்',

        'speech_rate': 'பேச்சு வேகம்',

        'pitch': 'சுரம்',

        'test_voice': 'குரல் சோதனை',

        'all': 'அனைத்தும்',

        'menu': 'மெனு',

        'say_hello_friend': 'நண்பரிடம் "வணக்கம்" சொல்லுங்கள்',

        'ask_for_drink': 'பானம் கேளுங்கள்',

        'express_emotion': 'உணர்வை வெளிப்படுத்துங்கள்',

        'practice_name': 'என் பெயரைச் சொல்லப் பயிற்சி செய்யுங்கள்',

        'access_app_features': 'ஆப்ஸ் அம்சங்கள் மற்றும் அமைப்புகளை அணுகவும்',

        'configure_aac_settings': 'உங்கள் AAC ஆப்ஸ் அமைப்புகளை கட்டமைக்கவும்',

        'error': 'பிழை',

        'ok': 'சரி',

        'please': 'தயவுசெய்து',

        'thank_you': 'நன்றி',

        'help_me': 'எனக்கு உதவுங்கள்',

        'stop': 'நிறுத்து',

        'more': 'மேலும்',

        'more_please': 'மேலும் தயவுசெய்து',

  'help_me_please': 'தயவுசெய்து எனக்கு உதவுங்கள்',
  'category_label': 'வகை',
  'symbols_available': 'கிடைக்கும் குறியீடுகள்',
  'double_tap_to_open': 'திறக்க இருமுறை தட்டவும்',
  'symbol_label': 'குறியீடு',
  'double_tap_to_speak': 'பேச இருமுறை தட்டவும்',
  'no_symbols_yet': 'இன்னும் குறியீடுகள் இல்லை!',
  'tap_plus_to_add': '+ பொத்தானைத் தட்டி முதல் குறியீட்டைச் சேர்க்கவும்',
        'failed_to_change_category': 'வகையை மாற்றுவதில் தோல்வி',
        
        // Common symbol translations
        'milk': 'பால்',
        'water': 'தண்ணீர்',
        'apple': 'ஆப்பிள்',
        'food': 'உணவு',
        'drink': 'பானம்',
        'hello': 'வணக்கம்',
        'yes': 'ஆம்',
        'no': 'இல்லை',
        'please': 'தயவுசெய்து',
        'thank_you': 'நன்றி',
        'help': 'உதவி',
        'more': 'மேலும்',
        'stop': 'நிறுத்து',
        
        // Core UI translations
        'initializing_security': 'பாதுகாப்பு தொடங்கப்படுகிறது...',
        'try_again': 'மீண்டும் முயற்சிக்கவும்',
        'ok': 'சரி',
        'cancel': 'ரத்து செய்',
        'delete': 'நீக்கு',
        'save': 'சேமி',
        'add': 'சேர்',
        'edit': 'திருத்து',
        'close': 'மூடு',
        'loading': 'ஏற்றப்படுகிறது...',
        'error': 'பிழை',
        'success': 'வெற்றி',
        'warning': 'எச்சரிக்கை',
        'confirm': 'உறுதிப்படுத்து',

      },

      // Telugu translations

      'te-IN': {

        'app_title': 'ఎఎసి కమ్యూనికేషన్',

        'hello': 'నమస్కారం',

        'categories': 'వర్గాలు',

        'all_symbols': 'అన్ని చిహ్నాలు',

        'settings': 'సెట్టింగులు',

        'history': 'చరిత్ర',

        'profile': 'ప్రొఫైల్',

        'add_symbol': 'చిహ్నం జోడించు',

        'edit_symbol': 'చిహ్నం సవరించు',

        'delete_symbol': 'చిహ్నం తొలగించు',

        'speak': 'మాట్లాడు',

        'clear': 'క్లియర్',

        'undo': 'రద్దు చేయి',

        'quick_phrases': 'త్వరిత వాక్యాలు',

        'phrase_history': 'వాక్య చరిత్ర',

        'recent': 'ఇటీవలి',

        'favorites': 'ఇష్టమైనవి',

        'language_settings': 'భాష సెట్టింగులు',

        'voice_settings': 'వాయిస్ సెట్టింగులు',

        'select_language': 'భాష ఎంచుకోండి',

        'select_voice': 'వాయిస్ ఎంచుకోండి',

        'speech_rate': 'మాట్లాడే వేగం',

        'pitch': 'పిచ్',

        'test_voice': 'వాయిస్ పరీక్ష',

        'all': 'అన్నీ',

        'menu': 'మెనూ',

        'say_hello_friend': 'స్నేహితుడికి "నమస్కారం" చెప్పండి',

        'ask_for_drink': 'పానీయం అడగండి',

        'express_emotion': 'భావనను వ్యక్తపరచండి',

        'practice_name': 'నా పేరు చెప్పడం అభ్యసించండి',

        'access_app_features': 'యాప్ ఫీచర్లు మరియు సెట్టింగ్‌లను యాక్సెస్ చేయండి',

        'configure_aac_settings': 'మీ AAC యాప్ సెట్టింగ్‌లను కాన్ఫిగర్ చేయండి',

        'error': 'దోషం',

        'ok': 'సరే',

        'please': 'దయచేసి',

        'thank_you': 'ధన్యవాదాలు',

        'help_me': 'నాకు సహాయం చేయండి',

        'stop': 'ఆపండి',

        'more': 'మరింత',

        'more_please': 'మరింత దయచేసి',

  'help_me_please': 'దయచేసి నాకు సహాయం చేయండి',
  'category_label': 'వర్గం',
  'symbols_available': 'లభ్యమయ్యే చిహ్నాలు',
  'double_tap_to_open': 'తెరవడానికి డబుల్ ట్యాప్ చేయండి',
  'symbol_label': 'చిహ్నం',
  'double_tap_to_speak': 'మాట్లాడేందుకు డబుల్ ట్యాప్ చేయండి',
  'no_symbols_yet': 'ఇంకా చిహ్నాలు లేవు!',
  'tap_plus_to_add': '+ బటన్‌ను నొక్కి మొదటి చిహ్నాన్ని జోడించండి',
  'failed_to_change_category': 'వర్గాన్ని మార్చడంలో విఫలమైంది',

      },

      // Marathi translations

      'mr-IN': {

        'app_title': 'एएसी संवाद',

        'hello': 'नमस्कार',

        'categories': 'श्रेण्या',

        'all_symbols': 'सर्व चिन्हे',

        'settings': 'सेटिंग्स',

        'history': 'इतिहास',

        'profile': 'प्रोफाइल',

        'add_symbol': 'चिन्ह जोडा',

        'edit_symbol': 'चिन्ह संपादित करा',

        'delete_symbol': 'चिन्ह हटवा',

        'speak': 'बोला',

        'clear': 'साफ करा',

        'undo': 'पूर्ववत करा',

        'quick_phrases': 'द्रुत वाक्ये',

        'phrase_history': 'वाक्य इतिहास',

        'recent': 'अलिकडील',

        'favorites': 'आवडते',

        'language_settings': 'भाषा सेटिंग्स',

        'voice_settings': 'आवाज सेटिंग्स',

        'select_language': 'भाषा निवडा',

        'select_voice': 'आवाज निवडा',

        'speech_rate': 'बोलण्याचा वेग',

        'pitch': 'स्वर',

        'test_voice': 'आवाज चाचणी',

        'all': 'सर्व',

        'menu': 'मेनू',

        'say_hello_friend': 'मित्राला "नमस्कार" म्हणा',

        'ask_for_drink': 'पेय मागा',

        'express_emotion': 'भावना व्यक्त करा',

        'practice_name': 'माझे नाव म्हणण्याचा सराव करा',

        'access_app_features': 'अॅप वैशिष्ट्ये आणि सेटिंग्स अॅक्सेस करा',

        'configure_aac_settings': 'तुमच्या AAC अॅप सेटिंग्स कॉन्फिगर करा',

        'error': 'त्रुटी',

        'ok': 'ठीक आहे',

        'please': 'कृपया',

        'thank_you': 'धन्यवाद',

        'help_me': 'मला मदत करा',

        'stop': 'थांबा',

        'more': 'अधिक',

        'more_please': 'अधिक कृपया',

  'help_me_please': 'कृपया मला मदत करा',
  'category_label': 'श्रेणी',
  'symbols_available': 'उपलब्ध चिन्हे',
  'double_tap_to_open': 'उघडण्यासाठी दुहेरी टॅप करा',
  'symbol_label': 'चिन्ह',
  'double_tap_to_speak': 'बोलण्यासाठी दुहेरी टॅप करा',
  'no_symbols_yet': 'अजून कोणतीही चिन्हे नाहीत!',
  'tap_plus_to_add': '+ बटणावर टॅप करून पहिले चिन्ह जोडा',
  'failed_to_change_category': 'श्रेणी बदलण्यात अयशस्वी',

      },

      // Gujarati translations

      'gu-IN': {

        'app_title': 'એએસી કમ્યુનિકેશન',

        'hello': 'નમસ્તે',

        'categories': 'શ્રેણીઓ',

        'all_symbols': 'બધા પ્રતીકો',

        'settings': 'સેટિંગ્સ',

        'history': 'ઇતિહાસ',

        'profile': 'પ્રોફાઇલ',

        'add_symbol': 'પ્રતીક ઉમેરો',

        'edit_symbol': 'પ્રતીક સંપાદિત કરો',

        'delete_symbol': 'પ્રતીક કાઢી નાખો',

        'speak': 'બોલો',

        'clear': 'સાફ કરો',

        'undo': 'પૂર્વવત્ કરો',

        'quick_phrases': 'ઝડપી વાક્યો',

        'phrase_history': 'વાક્ય ઇતિહાસ',

        'recent': 'તાજેતરના',

        'favorites': 'મનપસંદ',

        'language_settings': 'ભાષા સેટિંગ્સ',

        'voice_settings': 'અવાજ સેટિંગ્સ',

        'select_language': 'ભાષા પસંદ કરો',

        'select_voice': 'અવાજ પસંદ કરો',

        'speech_rate': 'બોલવાની ઝડપ',

        'pitch': 'સ્વર',

        'test_voice': 'અવાજ ટેસ્ટ',

        'all': 'બધું',

        'menu': 'મેનૂ',

        'say_hello_friend': 'મિત્રને "નમસ્તે" કહો',

        'ask_for_drink': 'પીણા માટે પૂછો',

        'express_emotion': 'લાગણી વ્યક્ત કરો',

        'practice_name': 'મારું નામ કહેવાની પ્રેક્ટિસ કરો',

        'access_app_features': 'એપ્લિકેશન ફીચર્સ અને સેટિંગ્સ ઍક્સેસ કરો',

        'configure_aac_settings': 'તમારી AAC એપ્લિકેશન સેટિંગ્સ કોન્ફિગર કરો',

        'error': 'ભૂલ',

        'ok': 'ઠીક છે',

        'please': 'કૃપા કરીને',

        'thank_you': 'આભાર',

        'help_me': 'મને મદદ કરો',

        'stop': 'અટકાવો',

        'more': 'વધુ',

        'more_please': 'વધુ કૃપા કરીને',

  'help_me_please': 'કૃપા કરીને મને મદદ કરો',
  'category_label': 'શ્રેણી',
  'symbols_available': 'ઉપલબ્ધ પ્રતીકો',
  'double_tap_to_open': 'ખોલવા માટે ડબલ ટેપ કરો',
  'symbol_label': 'પ્રતીક',
  'double_tap_to_speak': 'બોલવા માટે ડબલ ટેપ કરો',
  'no_symbols_yet': 'હજુ સુધી કોઈ પ્રતીકો નથી!',
  'tap_plus_to_add': '+ બટન પર ટેપ કરીને તમારું પ્રથમ પ્રતીક ઉમેરો',
  'failed_to_change_category': 'કેટેગરી બદલવામાં નિષ્ફળ',

      },

      'es-ES': {

        'app_title': 'Comunicación AAC',

        'hello': 'Hola',

        'categories': 'Categorías',

        'all_symbols': 'Todos los Símbolos',

        'settings': 'Configuración',

        'history': 'Historial',

        'profile': 'Perfil',

        'add_symbol': 'Agregar Símbolo',

        'edit_symbol': 'Editar Símbolo',

        'delete_symbol': 'Eliminar Símbolo',

        'speak': 'Hablar',

        'clear': 'Limpiar',

        'undo': 'Deshacer',

        'quick_phrases': 'Frases Rápidas',

        'phrase_history': 'Historial de Frases',

        'recent': 'Reciente',

        'favorites': 'Favoritos',

        'language_settings': 'Configuración de Idioma',

        'voice_settings': 'Configuración de Voz',

        'select_language': 'Seleccionar Idioma',

        'select_voice': 'Seleccionar Voz',

        'speech_rate': 'Velocidad de Habla',

        'pitch': 'Tono',

        'test_voice': 'Probar Voz',

        'all': 'Todo',

        'menu': 'Menú',

        'say_hello_friend': 'Dile "hola" a un amigo',

        'ask_for_drink': 'Pedir una bebida',

        'express_emotion': 'Expresar una emoción',

        'practice_name': 'Practicar decir mi nombre',

        'access_app_features': 'Acceder a funciones y configuración de la aplicación',

        'configure_aac_settings': 'Configurar la configuración de tu aplicación AAC',

        'error': 'Error',

        'ok': 'Aceptar',

        'please': 'Por favor',

        'thank_you': 'Gracias',

        'help_me': 'Ayúdame',

        'stop': 'Parar',

        'more': 'Más',

        'more_please': 'Más por favor',

  'help_me_please': 'Por favor ayúdame',
  'category_label': 'Categoría',
  'symbols_available': 'símbolos disponibles',
  'double_tap_to_open': 'Toque dos veces para abrir',
  'symbol_label': 'Símbolo',
  'double_tap_to_speak': 'Toque dos veces para hablar',
  'no_symbols_yet': '¡Aún no hay símbolos!',
  'tap_plus_to_add': 'Toque el botón + para agregar su primer símbolo',
  'failed_to_change_category': 'Error al cambiar categoría',

      },

      // French translations
      'fr-FR': {
        'app_title': 'Communication CAA',
        'hello': 'Bonjour',
        'categories': 'Catégories',
        'all_symbols': 'Tous les Symboles',
        'settings': 'Paramètres',
        'history': 'Historique',
        'profile': 'Profil',
        'add_symbol': 'Ajouter un Symbole',
        'edit_symbol': 'Modifier le Symbole',
        'delete_symbol': 'Supprimer le Symbole',
        'speak': 'Parler',
        'clear': 'Effacer',
        'undo': 'Annuler',
        'quick_phrases': 'Phrases Rapides',
        'phrase_history': 'Historique des Phrases',
        'recent': 'Récent',
        'favorites': 'Favoris',
        'language_settings': 'Paramètres de Langue',
        'voice_settings': 'Paramètres Vocaux',
        'select_language': 'Sélectionner la Langue',
        'select_voice': 'Sélectionner la Voix',
        'speech_rate': 'Vitesse de Parole',
        'pitch': 'Tonalité',
        'test_voice': 'Tester la Voix',
        'all': 'Tout',
        'menu': 'Menu',
        'say_hello_friend': 'Dire "bonjour" à un ami',
        'ask_for_drink': 'Demander une boisson',
        'express_emotion': 'Exprimer une émotion',
        'practice_name': 'Pratiquer dire mon nom',
        'access_app_features': 'Accéder aux fonctionnalités et paramètres de l\'application',
        'configure_aac_settings': 'Configurer les paramètres de votre application CAA',
        'error': 'Erreur',
        'ok': 'OK',
        'please': 'S\'il vous plaît',
        'thank_you': 'Merci',
        'help_me': 'Aidez-moi',
        'stop': 'Arrêter',
        'more': 'Plus',
        'more_please': 'Plus s\'il vous plaît',
        'help_me_please': 'S\'il vous plaît aidez-moi',
        'category_label': 'Catégorie',
        'symbols_available': 'symboles disponibles',
        'double_tap_to_open': 'Appuyez deux fois pour ouvrir',
        'symbol_label': 'Symbole',
        'double_tap_to_speak': 'Appuyez deux fois pour parler',
        'no_symbols_yet': 'Aucun symbole pour le moment!',
        'tap_plus_to_add': 'Appuyez sur le bouton + pour ajouter votre premier symbole',
        'failed_to_change_category': 'Échec du changement de catégorie',
      },

      // German translations
      'de-DE': {
        'app_title': 'AAC Kommunikation',
        'hello': 'Hallo',
        'categories': 'Kategorien',
        'all_symbols': 'Alle Symbole',
        'settings': 'Einstellungen',
        'history': 'Verlauf',
        'profile': 'Profil',
        'add_symbol': 'Symbol hinzufügen',
        'edit_symbol': 'Symbol bearbeiten',
        'delete_symbol': 'Symbol löschen',
        'speak': 'Sprechen',
        'clear': 'Löschen',
        'undo': 'Rückgängig',
        'quick_phrases': 'Schnelle Phrasen',
        'phrase_history': 'Phrasen-Verlauf',
        'recent': 'Kürzlich',
        'favorites': 'Favoriten',
        'language_settings': 'Spracheinstellungen',
        'voice_settings': 'Stimmeinstellungen',
        'select_language': 'Sprache auswählen',
        'select_voice': 'Stimme auswählen',
        'speech_rate': 'Sprechgeschwindigkeit',
        'pitch': 'Tonhöhe',
        'test_voice': 'Stimme testen',
        'all': 'Alle',
        'menu': 'Menü',
        'say_hello_friend': 'Sage "hallo" zu einem Freund',
        'ask_for_drink': 'Nach einem Getränk fragen',
        'express_emotion': 'Eine Emotion ausdrücken',
        'practice_name': 'Übe meinen Namen zu sagen',
        'access_app_features': 'Auf App-Funktionen und Einstellungen zugreifen',
        'configure_aac_settings': 'Konfiguriere deine AAC-App-Einstellungen',
        'error': 'Fehler',
        'ok': 'OK',
        'please': 'Bitte',
        'thank_you': 'Danke',
        'help_me': 'Hilf mir',
        'stop': 'Stopp',
        'more': 'Mehr',
        'more_please': 'Mehr bitte',
        'help_me_please': 'Bitte hilf mir',
        'category_label': 'Kategorie',
        'symbols_available': 'verfügbare Symbole',
        'double_tap_to_open': 'Doppelt tippen zum Öffnen',
        'symbol_label': 'Symbol',
        'double_tap_to_speak': 'Doppelt tippen zum Sprechen',
        'no_symbols_yet': 'Noch keine Symbole!',
        'tap_plus_to_add': 'Tippe auf + um dein erstes Symbol hinzuzufügen',
        'failed_to_change_category': 'Kategorie konnte nicht geändert werden',
      },

      // Chinese (Simplified) translations
      'zh-CN': {
        'app_title': 'AAC 沟通',
        'hello': '你好',
        'categories': '类别',
        'all_symbols': '所有符号',
        'settings': '设置',
        'history': '历史',
        'profile': '个人资料',
        'add_symbol': '添加符号',
        'edit_symbol': '编辑符号',
        'delete_symbol': '删除符号',
        'speak': '说话',
        'clear': '清除',
        'undo': '撤销',
        'quick_phrases': '快速短语',
        'phrase_history': '短语历史',
        'recent': '最近',
        'favorites': '收藏',
        'language_settings': '语言设置',
        'voice_settings': '语音设置',
        'select_language': '选择语言',
        'select_voice': '选择语音',
        'speech_rate': '语速',
        'pitch': '音调',
        'test_voice': '测试语音',
        'all': '全部',
        'menu': '菜单',
        'say_hello_friend': '对朋友说"你好"',
        'ask_for_drink': '要饮料',
        'express_emotion': '表达情感',
        'practice_name': '练习说我的名字',
        'access_app_features': '访问应用功能和设置',
        'configure_aac_settings': '配置您的AAC应用设置',
        'error': '错误',
        'ok': '确定',
        'please': '请',
        'thank_you': '谢谢',
        'help_me': '帮助我',
        'stop': '停止',
        'more': '更多',
        'more_please': '请再多一些',
        'help_me_please': '请帮助我',
        'category_label': '类别',
        'symbols_available': '可用符号',
        'double_tap_to_open': '双击打开',
        'symbol_label': '符号',
        'double_tap_to_speak': '双击说话',
        'no_symbols_yet': '还没有符号！',
        'tap_plus_to_add': '点击+按钮添加您的第一个符号',
        'failed_to_change_category': '更改类别失败',
      },

      // Arabic translations
      'ar-SA': {
        'app_title': 'تواصل AAC',
        'hello': 'مرحبا',
        'categories': 'الفئات',
        'all_symbols': 'جميع الرموز',
        'settings': 'الإعدادات',
        'history': 'التاريخ',
        'profile': 'الملف الشخصي',
        'add_symbol': 'إضافة رمز',
        'edit_symbol': 'تحرير الرمز',
        'delete_symbol': 'حذف الرمز',
        'speak': 'تحدث',
        'clear': 'مسح',
        'undo': 'تراجع',
        'quick_phrases': 'العبارات السريعة',
        'phrase_history': 'تاريخ العبارات',
        'recent': 'الأخيرة',
        'favorites': 'المفضلة',
        'language_settings': 'إعدادات اللغة',
        'voice_settings': 'إعدادات الصوت',
        'select_language': 'اختر اللغة',
        'select_voice': 'اختر الصوت',
        'speech_rate': 'سرعة الكلام',
        'pitch': 'النبرة',
        'test_voice': 'اختبار الصوت',
        'all': 'الكل',
        'menu': 'القائمة',
        'say_hello_friend': 'قل "مرحبا" لصديق',
        'ask_for_drink': 'اطلب مشروبا',
        'express_emotion': 'عبر عن مشاعر',
        'practice_name': 'تدرب على قول اسمي',
        'access_app_features': 'الوصول إلى ميزات التطبيق والإعدادات',
        'configure_aac_settings': 'تكوين إعدادات تطبيق AAC الخاص بك',
        'error': 'خطأ',
        'ok': 'موافق',
        'please': 'من فضلك',
        'thank_you': 'شكرا لك',
        'help_me': 'ساعدني',
        'stop': 'توقف',
        'more': 'المزيد',
        'more_please': 'المزيد من فضلك',
        'help_me_please': 'من فضلك ساعدني',
        'category_label': 'الفئة',
        'symbols_available': 'الرموز المتاحة',
        'double_tap_to_open': 'انقر مرتين للفتح',
        'symbol_label': 'الرمز',
        'double_tap_to_speak': 'انقر مرتين للتحدث',
        'no_symbols_yet': 'لا توجد رموز بعد!',
        'tap_plus_to_add': 'انقر على زر + لإضافة رمزك الأول',
        'failed_to_change_category': 'فشل في تغيير الفئة',
      },

    };
    
    await _saveTranslations();
  }

  Future<void> changeLanguage(String languageCode) async {
    try {
      // Input validation
      if (languageCode.isEmpty) {
        throw ArgumentError('Language code cannot be empty');
      }
      
      // Validate language code format (e.g., 'en-US', 'hi-IN')
      final languageCodeRegex = RegExp(r'^[a-z]{2}-[A-Z]{2}$');
      if (!languageCodeRegex.hasMatch(languageCode)) {
        throw ArgumentError('Invalid language code format: $languageCode');
      }
      
      if (!_supportedLanguages.containsKey(languageCode)) {
        throw ArgumentError('Unsupported language: $languageCode');
      }
      
      final previousLanguage = _currentLanguage;
      _currentLanguage = languageCode;
      
      print('[LanguageService] Changing language from $previousLanguage to $languageCode');
      
      await _saveCurrentLanguage();
      
      // Update TTS language
      if (_flutterTts != null) {
        await _flutterTts!.setLanguage(languageCode);
        
        // Reset voice settings for new language
        _ttsVoiceSettings = TTSVoiceSettings(
          languageCode: languageCode,
          voiceId: '',
          speechRate: 0.5,
          pitch: 1.0,
        );
        await _saveTTSVoiceSettings();
        print('[LanguageService] TTS language and voice settings updated');
      }
      
      // Clear translation cache when language changes for consistency
      _translationCache.clear();
      print('[LanguageService] Translation cache cleared for language change');
      
      print('[LanguageService] Language change completed successfully');
      
    } catch (e, stackTrace) {
      print('[LanguageService] ERROR changing language to $languageCode: $e');
      print('[LanguageService] Stack trace: $stackTrace');
      throw Exception('Failed to change language: $e');
    }
  }

  Future<List<TTSVoice>> getAvailableVoices() async {

    if (_flutterTts == null) return <TTSVoice>[];

    

    final voices = await _flutterTts!.getVoices;

    if (voices == null) return <TTSVoice>[];

    

    // Get the base language code (e.g., 'hi' from 'hi-IN')

    final baseLanguage = _currentLanguage.split('-')[0];

    

    final ttsVoices = voices
        .where((voice) {
          try {
            // Safely cast to Map<String, dynamic>
            if (voice is! Map) return false;
            final voiceMap = Map<String, dynamic>.from(voice as Map);
            final locale = voiceMap['locale']?.toString() ?? '';
            // Support both exact match and partial match for Indian languages
            return locale.startsWith(baseLanguage) || 
                   locale.contains(_currentLanguage) ||
                   locale.contains('IN') && locale.startsWith(baseLanguage);
          } catch (e) {
            return false;
          }
        })
        .map((voice) {
          try {
            final voiceMap = Map<String, dynamic>.from(voice as Map);
            return TTSVoice(
              id: voiceMap['name']?.toString() ?? '',
              name: voiceMap['name']?.toString() ?? 'Unknown',
              language: voiceMap['locale']?.toString() ?? _currentLanguage,
              gender: _determineGender(voiceMap['name']?.toString() ?? ''),
            );
          } catch (e) {
            return TTSVoice(
              id: 'fallback',
              name: 'Default Voice',
              language: _currentLanguage,
              gender: 'unknown',
            );
          }
        })
        .toList()
        .cast<TTSVoice>();

    

    return ttsVoices.whereType<TTSVoice>().toList();

  }

  String _determineGender(String voiceName) {
    final femaleIndicators = ['female', 'woman', 'girl', 'karen', 'samantha', 'victoria'];
    final maleIndicators = ['male', 'man', 'boy', 'alex', 'daniel', 'fred'];
    
    final lowerName = voiceName.toLowerCase();
    
    if (femaleIndicators.any((indicator) => lowerName.contains(indicator))) {
      return 'female';
    } else if (maleIndicators.any((indicator) => lowerName.contains(indicator))) {
      return 'male';
    }
    
    return 'neutral';
  }

  Future<void> updateTTSVoiceSettings(TTSVoiceSettings settings) async {
    _ttsVoiceSettings = settings;
    await _saveTTSVoiceSettings();
    
    // Apply settings to TTS engine
    if (_flutterTts != null) {
      await _flutterTts!.setLanguage(settings.languageCode);
      await _flutterTts!.setPitch(settings.pitch);
      await _flutterTts!.setSpeechRate(settings.speechRate);
      
      if (settings.voiceId.isNotEmpty) {
        try {
          final voices = await _flutterTts!.getVoices;
          final voice = voices?.firstWhere(
            (v) {
              try {
                if (v is! Map) return false;
                final voiceMap = Map<String, dynamic>.from(v as Map);
                return voiceMap['name']?.toString() == settings.voiceId;
              } catch (e) {
                return false;
              }
            },
            orElse: () => null,
          );
          if (voice != null) {
            // Convert to Map<String, String> as expected by setVoice
            final voiceData = Map<String, String>.from(
              Map<String, dynamic>.from(voice as Map).map(
                (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
              ),
            );
            await _flutterTts!.setVoice(voiceData);
          }
        } catch (e) {
          print('[TTS] Error setting voice: $e');
        }
      }
    }
  }

  String translate(String key, {String? fallback}) {
    // Input validation for security
    if (key.isEmpty) {
      print('[LanguageService] WARNING: Empty translation key provided');
      return fallback ?? '';
    }
    
    // Sanitize key to prevent injection attacks
    final sanitizedKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '');
    if (sanitizedKey != key) {
      print('[LanguageService] WARNING: Translation key sanitized: "$key" -> "$sanitizedKey"');
    }
    
    try {
      // Check cache first for performance
      final cacheKey = '${_currentLanguage}_$sanitizedKey';
      if (_translationCache.containsKey(cacheKey)) {
        _translationCacheHits++;
        _reportPerformanceMetrics();
        return _translationCache[cacheKey]!;
      }
      
      _translationCacheMisses++;
      
      final currentTranslations = _translations[_currentLanguage];
      final translation = currentTranslations?[sanitizedKey];
      
      if (translation == null) {
        print('[LanguageService] Missing translation for key: "$sanitizedKey" in language: $_currentLanguage');
        
        // Fallback to English if available
        final fallbackTranslation = _translations['en-US']?[sanitizedKey];
        if (fallbackTranslation != null) {
          print('[LanguageService] Using English fallback for key: "$sanitizedKey"');
          
          // Cache the fallback translation
          _translationCache[cacheKey] = fallbackTranslation;
          _manageCacheSize();
          
          return fallbackTranslation;
        }
        
        final result = fallback ?? sanitizedKey;
        
        // Cache the result to avoid repeated lookups
        _translationCache[cacheKey] = result;
        _manageCacheSize();
        
        return result;
      }
      
      // Cache the successful translation
      _translationCache[cacheKey] = translation;
      _manageCacheSize();
      _reportPerformanceMetrics();
      
      return translation;
    } catch (e, stackTrace) {
      print('[LanguageService] ERROR in translate(): $e');
      print('[LanguageService] Stack trace: $stackTrace');
      return fallback ?? sanitizedKey;
    }
  }

  Future<void> addCustomTranslation(String languageCode, String key, String translation) async {
    try {
      // Input validation
      if (languageCode.isEmpty || key.isEmpty || translation.isEmpty) {
        throw ArgumentError('Language code, key, and translation cannot be empty');
      }
      
      // Validate language code format
      final languageCodeRegex = RegExp(r'^[a-z]{2}-[A-Z]{2}$');
      if (!languageCodeRegex.hasMatch(languageCode)) {
        throw ArgumentError('Invalid language code format: $languageCode');
      }
      
      // Sanitize inputs to prevent injection
      final sanitizedKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '');
      final sanitizedTranslation = translation.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ''); // Remove control characters
      
      // Validate translation length for performance
      if (sanitizedTranslation.length > 1000) {
        throw ArgumentError('Translation value too long (max 1000 characters)');
      }
      
      _translations[languageCode] ??= {};
      _translations[languageCode]![sanitizedKey] = sanitizedTranslation;
      
      print('[LanguageService] Added custom translation: $languageCode.$sanitizedKey = "$sanitizedTranslation"');
      
      await _saveTranslations();
      
    } catch (e, stackTrace) {
      print('[LanguageService] ERROR adding custom translation: $e');
      print('[LanguageService] Stack trace: $stackTrace');
      throw Exception('Failed to add custom translation: $e');
    }
  }

  bool isRTL() {
    return _supportedLanguages[_currentLanguage]?.isRTL ?? false;
  }

  String getLanguageFlag() {
    return _supportedLanguages[_currentLanguage]?.flag ?? '🌐';
  }

  String getLanguageName() {
    return _supportedLanguages[_currentLanguage]?.nativeName ?? 'Unknown';
  }

  Future<void> testVoice(String text) async {
    if (_flutterTts != null) {
      await _flutterTts!.speak(text);
    }
  }

  // Save/Load methods
  Future<void> _loadCurrentLanguage() async {

    final prefs = await SharedPreferences.getInstance();

    _currentLanguage = prefs.getString(_currentLanguageKey) ?? 'en-IN';

  }

  Future<void> _saveCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentLanguageKey, _currentLanguage);
  }

  Future<void> _loadSupportedLanguages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languagesJson = prefs.getString(_supportedLanguagesKey);
      
      if (languagesJson != null) {
        final Map<String, dynamic> languagesMap = jsonDecode(languagesJson);
        _supportedLanguages = languagesMap.map(
          (key, value) => MapEntry(key, SupportedLanguage.fromJson(value)),
        );
      }
    } catch (e) {
      print('Error loading supported languages: $e');
    }
  }

  Future<void> _saveSupportedLanguages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languagesMap = _supportedLanguages.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
      final languagesJson = jsonEncode(languagesMap);
      await prefs.setString(_supportedLanguagesKey, languagesJson);
    } catch (e) {
      print('Error saving supported languages: $e');
    }
  }

  Future<void> _loadTTSVoiceSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_ttsVoiceKey);
      
      if (settingsJson != null) {
        final Map<String, dynamic> settingsMap = jsonDecode(settingsJson);
        _ttsVoiceSettings = TTSVoiceSettings.fromJson(settingsMap);
      }
    } catch (e) {
      print('Error loading TTS voice settings: $e');
    }
  }

  Future<void> _saveTTSVoiceSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_ttsVoiceSettings != null) {
        final settingsJson = jsonEncode(_ttsVoiceSettings!.toJson());
        await prefs.setString(_ttsVoiceKey, settingsJson);
      }
    } catch (e) {
      print('Error saving TTS voice settings: $e');
    }
  }

  Future<void> _loadTranslations() async {
    try {
      print('[LanguageService] Loading translations from storage...');
      final prefs = await SharedPreferences.getInstance();
      final translationsJson = prefs.getString(_translationsKey);
      
      if (translationsJson != null && translationsJson.isNotEmpty) {
        final Map<String, dynamic> translationsMap = jsonDecode(translationsJson);
        _translations = translationsMap.map(
          (key, value) => MapEntry(key, Map<String, String>.from(value ?? {})),
        );
        print('[LanguageService] Successfully loaded ${_translations.length} translation sets');
      } else {
        print('[LanguageService] No translations found in storage');
        _translations = {};
      }
    } catch (e, stackTrace) {
      print('[LanguageService] ERROR loading translations: $e');
      print('[LanguageService] Stack trace: $stackTrace');
      _translations = {}; // Ensure we have an empty map instead of null
    }
  }

  Future<void> _saveTranslations() async {
    try {
      print('[LanguageService] Saving translations to storage...');
      final prefs = await SharedPreferences.getInstance();
      
      if (_translations.isEmpty) {
        print('[LanguageService] WARNING: Attempting to save empty translations');
        return;
      }
      
      final translationsJson = jsonEncode(_translations);
      
      // Validate JSON before saving
      if (translationsJson.length > 1024 * 1024) { // 1MB limit
        print('[LanguageService] WARNING: Translations data is very large (${translationsJson.length} bytes)');
      }
      
      await prefs.setString(_translationsKey, translationsJson);
      print('[LanguageService] Successfully saved ${_translations.length} translation sets');
      
    } catch (e, stackTrace) {
      print('[LanguageService] ERROR saving translations: $e');
      print('[LanguageService] Stack trace: $stackTrace');
      throw Exception('Failed to save translations: $e');
    }
  }
}

class SupportedLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool isRTL;

  SupportedLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.isRTL,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'nativeName': nativeName,
    'flag': flag,
    'isRTL': isRTL,
  };

  factory SupportedLanguage.fromJson(Map<String, dynamic> json) => SupportedLanguage(
    code: json['code'],
    name: json['name'],
    nativeName: json['nativeName'],
    flag: json['flag'],
    isRTL: json['isRTL'],
  );
}

class TTSVoiceSettings {
  final String languageCode;
  final String voiceId;
  final double speechRate;
  final double pitch;

  TTSVoiceSettings({
    required this.languageCode,
    required this.voiceId,
    required this.speechRate,
    required this.pitch,
  });

  Map<String, dynamic> toJson() => {
    'languageCode': languageCode,
    'voiceId': voiceId,
    'speechRate': speechRate,
    'pitch': pitch,
  };

  factory TTSVoiceSettings.fromJson(Map<String, dynamic> json) => TTSVoiceSettings(
    languageCode: json['languageCode'],
    voiceId: json['voiceId'],
    speechRate: json['speechRate']?.toDouble() ?? 0.5,
    pitch: json['pitch']?.toDouble() ?? 1.0,
  );

  TTSVoiceSettings copyWith({
    String? languageCode,
    String? voiceId,
    double? speechRate,
    double? pitch,
  }) => TTSVoiceSettings(
    languageCode: languageCode ?? this.languageCode,
    voiceId: voiceId ?? this.voiceId,
    speechRate: speechRate ?? this.speechRate,
    pitch: pitch ?? this.pitch,
  );
}

class TTSVoice {
  final String id;
  final String name;
  final String language;
  final String gender;

  TTSVoice({
    required this.id,
    required this.name,
    required this.language,
    required this.gender,
  });
}