import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/aac_logger.dart';

/// Service to handle data corruption recovery and cleanup
class DataRecoveryService {
  static const String _dataHealthKey = 'data_health_check';
  static const String _lastRecoveryKey = 'last_recovery_timestamp';
  
  /// Perform health check and recovery of corrupted data
  static Future<bool> performDataHealthCheck() async {
    try {
      AACLogger.info('Starting data health check...', tag: 'DataRecovery');
      
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_dataHealthKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Only run health check once per day
      if (now - lastCheck < Duration(days: 1).inMilliseconds) {
        return true;
      }
      
      bool recoveryNeeded = false;
      
      // Check for corrupted encrypted data
      final profilesJson = prefs.getStringList('user_profiles') ?? [];
      int corruptedProfiles = 0;
      
      for (final json in profilesJson) {
        try {
          // Try to parse JSON
          final data = Map<String, dynamic>.from(jsonDecode(json));
          
          // Check for signs of corruption
          if (_isDataCorrupted(data)) {
            corruptedProfiles++;
            recoveryNeeded = true;
          }
        } catch (e) {
          corruptedProfiles++;
          recoveryNeeded = true;
        }
      }
      
      if (recoveryNeeded) {
        AACLogger.warning('Found $corruptedProfiles corrupted profiles, starting recovery...', tag: 'DataRecovery');
        await _performDataRecovery();
      }
      
      // Mark health check as completed
      await prefs.setInt(_dataHealthKey, now);
      
      AACLogger.info('Data health check completed', tag: 'DataRecovery');
      return !recoveryNeeded;
    } catch (e) {
      AACLogger.error('Error during data health check: $e', tag: 'DataRecovery');
      return false;
    }
  }
  
  /// Check if data appears corrupted
  static bool _isDataCorrupted(Map<String, dynamic> data) {
    try {
      // Check for required fields
      if (!data.containsKey('id') || !data.containsKey('name')) {
        return true;
      }
      
      // Check for extremely long encrypted strings (signs of corruption)
      for (final value in data.values) {
        if (value is String && value.length > 50000) {
          return true;
        }
      }
      
      // Check for invalid dates
      final createdAt = data['createdAt'];
      if (createdAt is String) {
        try {
          DateTime.parse(createdAt);
        } catch (e) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      return true;
    }
  }
  
  /// Perform data recovery operations
  static Future<void> _performDataRecovery() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear corrupted profile data
      await prefs.remove('user_profiles');
      await prefs.remove('current_profile_id');
      
      // Clear potentially corrupted sync data
      await prefs.remove('pending_changes');
      await prefs.remove('last_sync_timestamp');
      
      // Mark recovery as performed
      await prefs.setInt(_lastRecoveryKey, DateTime.now().millisecondsSinceEpoch);
      
      AACLogger.info('Data recovery completed - corrupted data cleared', tag: 'DataRecovery');
    } catch (e) {
      AACLogger.error('Error during data recovery: $e', tag: 'DataRecovery');
    }
  }
  
  /// Clear all local data (emergency recovery)
  static Future<void> emergencyDataClear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all AAC app data except Firebase auth tokens
      final keysToKeep = [
        'firebase_auth_token',
        'firebase_user_id',
        'app_version',
        'first_launch',
      ];
      
      final allKeys = prefs.getKeys().toList();
      for (final key in allKeys) {
        if (!keysToKeep.contains(key)) {
          await prefs.remove(key);
        }
      }
      
      AACLogger.info('Emergency data clear completed', tag: 'DataRecovery');
    } catch (e) {
      AACLogger.error('Error during emergency data clear: $e', tag: 'DataRecovery');
    }
  }
}
