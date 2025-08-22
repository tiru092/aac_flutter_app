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

  String _currentLanguage = 'en-US';
  Map<String, SupportedLanguage> _supportedLanguages = {};
  TTSVoiceSettings? _ttsVoiceSettings;
  Map<String, Map<String, String>> _translations = {};
  FlutterTts? _flutterTts;

  String get currentLanguage => _currentLanguage;
  Map<String, SupportedLanguage> get supportedLanguages => _supportedLanguages;
  TTSVoiceSettings? get ttsVoiceSettings => _ttsVoiceSettings;

  Future<void> initialize() async {
    await _loadCurrentLanguage();
    await _loadSupportedLanguages();
    await _loadTTSVoiceSettings();
    await _loadTranslations();
    await _initializeTTS();
    
    // If no supported languages, initialize with defaults
    if (_supportedLanguages.isEmpty) {
      await _initializeDefaultLanguages();
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
        final voices = await _flutterTts!.getVoices;
        final voice = voices?.firstWhere(
          (v) => v['name'] == _ttsVoiceSettings!.voiceId,
          orElse: () => null,
        );
        if (voice != null) {
          await _flutterTts!.setVoice(voice);
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
      },
    };
    
    await _saveTranslations();
  }

  Future<void> changeLanguage(String languageCode) async {
    if (_supportedLanguages.containsKey(languageCode)) {
      _currentLanguage = languageCode;
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
      }
    }
  }

  Future<List<TTSVoice>> getAvailableVoices() async {
    if (_flutterTts == null) return [];
    
    final voices = await _flutterTts!.getVoices;
    if (voices == null) return [];
    
    return voices
        .where((voice) => voice['locale']?.startsWith(_currentLanguage.split('-')[0]) == true)
        .map((voice) => TTSVoice(
          id: voice['name'] ?? '',
          name: voice['name'] ?? 'Unknown',
          language: voice['locale'] ?? _currentLanguage,
          gender: _determineGender(voice['name'] ?? ''),
        ))
        .toList();
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
        final voices = await _flutterTts!.getVoices;
        final voice = voices?.firstWhere(
          (v) => v['name'] == settings.voiceId,
          orElse: () => null,
        );
        if (voice != null) {
          await _flutterTts!.setVoice(voice);
        }
      }
    }
  }

  String translate(String key, {String? fallback}) {
    final translation = _translations[_currentLanguage]?[key];
    return translation ?? fallback ?? key;
  }

  Future<void> addCustomTranslation(String languageCode, String key, String translation) async {
    _translations[languageCode] ??= {};
    _translations[languageCode]![key] = translation;
    await _saveTranslations();
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
    _currentLanguage = prefs.getString(_currentLanguageKey) ?? 'en-US';
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
      final prefs = await SharedPreferences.getInstance();
      final translationsJson = prefs.getString(_translationsKey);
      
      if (translationsJson != null) {
        final Map<String, dynamic> translationsMap = jsonDecode(translationsJson);
        _translations = translationsMap.map(
          (key, value) => MapEntry(key, Map<String, String>.from(value)),
        );
      }
    } catch (e) {
      print('Error loading translations: $e');
    }
  }

  Future<void> _saveTranslations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final translationsJson = jsonEncode(_translations);
      await prefs.setString(_translationsKey, translationsJson);
    } catch (e) {
      print('Error saving translations: $e');
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