import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'language_service.dart';
import '../utils/image_localization_helper.dart';

/// Custom localizations class that uses LanguageService for translations
class AACLocalizations {
  final LanguageService _languageService = LanguageService.instance;
  
  static AACLocalizations? of(BuildContext context) {
    return Localizations.of<AACLocalizations>(context, AACLocalizations);
  }
  
  String translate(String key, {String? fallback}) {
    return _languageService.translate(key, fallback: fallback);
  }
  
  String get currentLanguage => _languageService.currentLanguage;
  
  bool get isRTL => _languageService.isRTL();
  
  String get languageFlag => _languageService.getLanguageFlag();
  
  String get languageName => _languageService.getLanguageName();
  
  // Image localization helpers
  String getLocalizedImagePath(String originalPath) {
    return ImageLocalizationHelper.getLocalizedImagePath(originalPath);
  }
  
  String getLocalizedSymbolImage(String symbolName) {
    return ImageLocalizationHelper.getLocalizedSymbolImage(symbolName);
  }
  
  String getLocalizedSymbolName(String symbolKey) {
    return ImageLocalizationHelper.getLocalizedSymbolName(symbolKey);
  }
}

/// Delegate that provides AACLocalizations to the widget tree
class AACLocalizationsDelegate extends LocalizationsDelegate<AACLocalizations> {
  const AACLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Check if the locale is supported by our LanguageService
    final languageService = LanguageService.instance;
    return languageService.supportedLanguages.containsKey(locale.toString()) ||
           languageService.supportedLanguages.containsKey('${locale.languageCode}-${locale.countryCode}');
  }

  @override
  Future<AACLocalizations> load(Locale locale) async {
    // Ensure LanguageService is initialized and set to correct locale
    final languageService = LanguageService.instance;
    await languageService.initialize();
    
    // Try to match the locale with our supported languages
    String? matchedLanguageCode;
    
    // First try exact match (e.g., "en-US")
    if (languageService.supportedLanguages.containsKey(locale.toString())) {
      matchedLanguageCode = locale.toString();
    } 
    // Then try language-country format
    else if (locale.countryCode != null && 
             languageService.supportedLanguages.containsKey('${locale.languageCode}-${locale.countryCode}')) {
      matchedLanguageCode = '${locale.languageCode}-${locale.countryCode}';
    }
    // Finally try just language code with default country
    else {
      // Find the first supported language that matches the language code
      for (String supportedCode in languageService.supportedLanguages.keys) {
        if (supportedCode.startsWith('${locale.languageCode}-')) {
          matchedLanguageCode = supportedCode;
          break;
        }
      }
    }
    
    // Set the language if we found a match
    if (matchedLanguageCode != null && matchedLanguageCode != languageService.currentLanguage) {
      await languageService.changeLanguage(matchedLanguageCode);
    }
    
    return AACLocalizations();
  }

  @override
  bool shouldReload(AACLocalizationsDelegate old) => false;

  @override
  String toString() => 'AACLocalizationsDelegate';
}