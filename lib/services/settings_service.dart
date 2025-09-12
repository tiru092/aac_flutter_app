import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../services/user_data_manager.dart';
import '../utils/aac_logger.dart';

/// Settings Service that is initialized and managed by DataServicesInitializer.
class SettingsService extends ChangeNotifier {
  late UserDataManager _userDataManager;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  AppSettings? _currentSettings;

  Future<void> initialize(UserDataManager userDataManager) async {
    if (_isInitialized) {
      AACLogger.warning('SettingsService already initialized.', tag: 'SettingsService');
      return;
    }
    AACLogger.info('Initializing SettingsService...', tag: 'SettingsService');
    _userDataManager = userDataManager;
    await _loadSettings();
    _isInitialized = true;
    notifyListeners();
    AACLogger.info('SettingsService initialized successfully.', tag: 'SettingsService');
  }

  AppSettings get settings {
    if (!_isInitialized) {
      AACLogger.warning('SettingsService not initialized. Returning default settings.', tag: 'SettingsService');
      return AppSettings();
    }
    return _currentSettings ?? AppSettings();
  }

  Future<void> _loadSettings() async {
    try {
      if (!_userDataManager.isInitialized) {
        AACLogger.warning('UserDataManager not ready, cannot load settings.', tag: 'SettingsService');
        _currentSettings = AppSettings();
        return;
      }

      // Unified data loading logic from UserDataManager
      final userProfile = await _userDataManager.getUserProfile();
      if (userProfile != null) {
        _currentSettings = userProfile.appSettings;
        AACLogger.info('Settings loaded from user profile for user: ${_userDataManager.currentUser?.uid}', tag: 'SettingsService');
      } else {
        _currentSettings = AppSettings();
        AACLogger.info('Default settings created for user: ${_userDataManager.currentUser?.uid}', tag: 'SettingsService');
      }
      notifyListeners();
    } catch (e) {
      AACLogger.error('Failed to load settings: $e', tag: 'SettingsService');
      _currentSettings = AppSettings();
      notifyListeners();
    }
  }

  /// Update settings for the logged-in user
  Future<void> updateSettings(AppSettings newSettings) async {
    if (!_isInitialized) {
      AACLogger.warning('Cannot update settings: service not initialized.', tag: 'SettingsService');
      return;
    }

    try {
      _currentSettings = newSettings;
      
      final userProfile = await _userDataManager.getUserProfile();
      if (userProfile != null) {
        final updatedProfile = userProfile.copyWith(appSettings: newSettings);
        await _userDataManager.saveUserProfile(updatedProfile);
        AACLogger.info('Settings updated and saved for user: ${_userDataManager.currentUser?.uid}', tag: 'SettingsService');
      } else {
         AACLogger.warning('Could not update settings, user profile is null.', tag: 'SettingsService');
      }

      notifyListeners();
    } catch (e) {
      AACLogger.error('Failed to update settings: $e', tag: 'SettingsService');
      rethrow;
    }
  }

  /// Update only the language setting
  Future<void> updateLanguage(String languageCode) async {
    if (!_isInitialized) return;
    final updatedSettings = settings.copyWith(languageCode: languageCode);
    await updateSettings(updatedSettings);
  }

  /// Update only the voice setting
  Future<void> updateVoice(String? voiceName) async {
    if (!_isInitialized) return;
    final updatedSettings = settings.copyWith(voiceName: voiceName);
    await updateSettings(updatedSettings);
  }

  /// Update only the speech rate
  Future<void> updateSpeechRate(double rate) async {
    if (!_isInitialized) return;
    final updatedSettings = settings.copyWith(speechRate: rate);
    await updateSettings(updatedSettings);
  }

  void disposeService() {
    _isInitialized = false;
    _currentSettings = null;
    AACLogger.info('SettingsService disposed.', tag: 'SettingsService');
    super.dispose();
  }
}
