import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// EMERGENCY ENCRYPTION CORRUPTION FIX
/// Clears all corrupted encryption data to allow app to restart cleanly
class EncryptionCorruptionFix {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  /// NUCLEAR OPTION: Clear all encryption keys and encrypted data
  static Future<void> fixEncryptionCorruption() async {
    try {
      print('[ENCRYPTION_FIX] Starting encryption corruption fix...');
      
      // 1. Delete all encryption keys
      await _secureStorage.delete(key: 'app_encryption_key');
      await _secureStorage.delete(key: 'aac_app_encryption_key');
      
      // 2. Clear all secure storage
      await _secureStorage.deleteAll();
      
      // 3. Clear SharedPreferences to remove any cached encrypted data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      print('[ENCRYPTION_FIX] All encryption keys and data cleared successfully');
      print('[ENCRYPTION_FIX] App will regenerate fresh encryption keys on next start');
      
    } catch (e) {
      print('[ENCRYPTION_FIX] Error during corruption fix: $e');
      // Don't rethrow - we want the app to continue
    }
  }
}
