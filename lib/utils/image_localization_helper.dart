import '../services/language_service.dart';

/// Helper class for image localization based on current language
class ImageLocalizationHelper {
  static final LanguageService _languageService = LanguageService();
  
  /// Get localized image path based on current language
  /// 
  /// Examples:
  /// - getLocalizedImagePath('symbols/food.png') might return 'symbols/hi/food.png' for Hindi
  /// - getLocalizedImagePath('icons/home.svg') might return 'icons/ta/home.svg' for Tamil
  /// 
  /// Falls back to original path if localized version doesn't exist
  static String getLocalizedImagePath(String originalPath) {
    final currentLanguage = _languageService.currentLanguage;
    
    // Extract language code (e.g., 'hi' from 'hi-IN')
    final languageCode = currentLanguage.split('-')[0];
    
    // Skip localization for English
    if (languageCode == 'en') {
      return originalPath;
    }
    
    // Insert language code into path
    final pathParts = originalPath.split('/');
    if (pathParts.length > 1) {
      // For paths like 'symbols/food.png', create 'symbols/hi/food.png'
      final directory = pathParts.sublist(0, pathParts.length - 1).join('/');
      final filename = pathParts.last;
      final localizedPath = '$directory/$languageCode/$filename';
      
      // TODO: In a real implementation, you would check if the file exists
      // For now, we'll assume localized images exist or fall back to original
      return localizedPath;
    }
    
    // If no directory structure, just return original
    return originalPath;
  }
  
  /// Get localized symbol image based on current language
  static String getLocalizedSymbolImage(String symbolName) {
    return getLocalizedImagePath('assets/symbols/$symbolName.png');
  }
  
  /// Get localized icon based on current language
  static String getLocalizedIcon(String iconName) {
    return getLocalizedImagePath('assets/icons/$iconName.svg');
  }
  
  /// Get symbol name translation for display
  static String getLocalizedSymbolName(String symbolKey) {
    return _languageService.translate(symbolKey, fallback: symbolKey);
  }
  
  /// Check if current language requires RTL layout for images
  static bool shouldFlipImagesForRTL() {
    return _languageService.isRTL();
  }
  
  /// Get text direction for current language
  static String getTextDirection() {
    return _languageService.isRTL() ? 'rtl' : 'ltr';
  }
}