import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_settings.dart';
import '../services/user_profile_service.dart';
import '../utils/aac_logger.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  AppSettings? _currentSettings;

  /// Get current settings for the logged-in user
  Future<AppSettings> getSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // Return default settings if not logged in
        _currentSettings = AppSettings();
        return _currentSettings!;
      }

      // Get settings from active user profile
      final userProfile = await UserProfileService.getActiveProfile();
      if (userProfile != null) {
        _currentSettings = userProfile.appSettings;
        AACLogger.info('Settings loaded for user: ${user.uid}', tag: 'SettingsService');
      } else {
        // Create default settings if profile doesn't exist
        _currentSettings = AppSettings();
        AACLogger.info('Default settings created for user: ${user.uid}', tag: 'SettingsService');
      }

      return _currentSettings!;
    } catch (e) {
      AACLogger.error('Failed to load settings: $e', tag: 'SettingsService');
      _currentSettings = AppSettings();
      return _currentSettings!;
    }
  }

  /// Update settings for the logged-in user
  Future<void> updateSettings(AppSettings newSettings) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AACLogger.warning('Cannot update settings: user not logged in', tag: 'SettingsService');
        return;
      }

      // Get current user profile
      final userProfile = await UserProfileService.getActiveProfile();
      if (userProfile == null) {
        AACLogger.warning('Cannot update settings: user profile not found', tag: 'SettingsService');
        return;
      }

      // Update the profile with new settings
      final updatedProfile = userProfile.copyWith(appSettings: newSettings);
      await UserProfileService.saveUserProfile(updatedProfile);

      _currentSettings = newSettings;
      AACLogger.info('Settings updated for user: ${user.uid}', tag: 'SettingsService');
    } catch (e) {
      AACLogger.error('Failed to update settings: $e', tag: 'SettingsService');
      rethrow;
    }
  }

  /// Update only the language setting
  Future<void> updateLanguage(String languageCode) async {
    final currentSettings = await getSettings();
    final updatedSettings = currentSettings.copyWith(languageCode: languageCode);
    await updateSettings(updatedSettings);
  }

  /// Update only the voice setting
  Future<void> updateVoice(String? voiceName) async {
    final currentSettings = await getSettings();
    final updatedSettings = currentSettings.copyWith(voiceName: voiceName);
    await updateSettings(updatedSettings);
  }

  /// Update speech rate and pitch
  Future<void> updateSpeechSettings({double? speechRate, double? pitch}) async {
    final currentSettings = await getSettings();
    final updatedSettings = currentSettings.copyWith(
      speechRate: speechRate,
      pitch: pitch,
    );
    await updateSettings(updatedSettings);
  }

  /// Get current language code
  Future<String> getCurrentLanguage() async {
    final settings = await getSettings();
    return settings.languageCode;
  }

  /// Get current voice name
  Future<String?> getCurrentVoice() async {
    final settings = await getSettings();
    return settings.voiceName;
  }

  /// Get current speech rate
  Future<double> getSpeechRate() async {
    final settings = await getSettings();
    return settings.speechRate;
  }

  /// Get current pitch
  Future<double> getPitch() async {
    final settings = await getSettings();
    return settings.pitch;
  }

  /// Check if settings are available (cached)
  bool get hasSettings => _currentSettings != null;

  /// Get cached settings (may be null)
  AppSettings? get cachedSettings => _currentSettings;
}
