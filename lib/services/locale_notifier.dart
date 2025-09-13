import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'language_service.dart';

/// ChangeNotifier that notifies listeners when the app locale changes
class LocaleNotifier extends ChangeNotifier {
  static final LocaleNotifier _instance = LocaleNotifier._internal();
  factory LocaleNotifier() => _instance;
  LocaleNotifier._internal();
  
  static LocaleNotifier get instance => _instance;
  
  final LanguageService _languageService = LanguageService.instance;
  
  Locale? _currentLocale;
  
  Locale? get currentLocale => _currentLocale;
  
  /// Initialize the locale notifier and set up language service listener
  Future<void> initialize() async {
    await _languageService.initialize();
    _updateLocaleFromLanguageService();
  }
  
  /// Update locale based on current language service setting
  void _updateLocaleFromLanguageService() {
    final currentLanguage = _languageService.currentLanguage;
    final newLocale = _parseLocale(currentLanguage);
    
    if (newLocale != _currentLocale) {
      _currentLocale = newLocale;
      notifyListeners();
    }
  }
  
  /// Change the app locale and notify listeners
  Future<void> changeLocale(String languageCode) async {
    await _languageService.changeLanguage(languageCode);
    _updateLocaleFromLanguageService();
    
    // Re-initialize TTS for the new language to ensure proper voice switching
    await _languageService.initialize();
  }
  
  /// Parse language code string to Locale object
  Locale _parseLocale(String languageCode) {
    final parts = languageCode.split('-');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    } else {
      return Locale(parts[0]);
    }
  }
  
  /// Get supported locales from language service
  List<Locale> getSupportedLocales() {
    return _languageService.supportedLanguages.keys
        .map((code) => _parseLocale(code))
        .toList();
  }
}