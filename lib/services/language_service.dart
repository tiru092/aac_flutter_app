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

        'stop': 'Stop',

        'more': 'More',

        'more_please': 'More please',

        'help_me_please': 'Help me please',

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