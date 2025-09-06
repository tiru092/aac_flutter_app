import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../utils/aac_logger.dart';
import 'cloud_sync_service.dart';
import 'user_profile_service.dart';

/// Custom exception for sync management-related errors
class SyncManagementException implements Exception {
  final String message;
  
  SyncManagementException(this.message);
  
  @override
  String toString() => 'SyncManagementException: $message';
}

/// Service to manage cross-device profile synchronization
class SyncManagementService {
  static final SyncManagementService _instance = SyncManagementService._internal();
  factory SyncManagementService() => _instance;
  SyncManagementService._internal();

  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _syncSettingsKey = 'sync_settings';
  static const String _pendingChangesKey = 'pending_changes';
  
  final CloudSyncService _cloudSyncService = CloudSyncService();
  final UserProfileService _userProfileService = UserProfileService();

  /// Initialize sync management service
  Future<void> initialize() async {
    try {
      // Load sync settings
      await _loadSyncSettings();
      
      // Start monitoring for changes
      _startChangeMonitoring();
      
      AACLogger.info('Sync management service initialized', tag: 'SyncManager');
    } catch (e) {
      AACLogger.error('Error initializing sync management service: $e', tag: 'SyncManager');
    }
  }

  /// Perform full sync of all profiles
  Future<SyncResult> performFullSync() async {
    try {
      print('Starting full sync...');
      
      // Record start time
      final startTime = DateTime.now();
      
      // Sync all profiles to cloud
      await _cloudSyncService.syncAllProfilesToCloud();
      
      // Load all profiles from cloud
      final cloudProfiles = await _cloudSyncService.loadAllProfilesFromCloud();
      
      // Update local profiles with cloud data
      for (final profile in cloudProfiles) {
        await _userProfileService.saveUserProfile(profile);
      }
      
      // Record completion
      final endTime = DateTime.now();
      await _recordSyncCompletion(endTime);
      
      print('Full sync completed in ${endTime.difference(startTime).inMilliseconds}ms');
      
      return SyncResult(
        success: true,
        profilesSynced: cloudProfiles.length,
        duration: endTime.difference(startTime),
        timestamp: endTime,
      );
    } catch (e) {
      print('Error performing full sync: $e');
      return SyncResult(
        success: false,
        profilesSynced: 0,
        duration: Duration.zero,
        timestamp: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  /// Sync a specific profile
  Future<SyncResult> syncProfile(String profileId) async {
    try {
      print('Starting sync for profile: $profileId');
      
      // Record start time
      final startTime = DateTime.now();
      
      // Get profile from local storage
      final profiles = await _userProfileService.getAllProfiles();
      final profile = profiles.firstWhere(
        (p) => p.id == profileId,
        orElse: () => throw SyncManagementException('Profile not found: $profileId'),
      );
      
      // Sync to cloud
      final syncSuccess = await _cloudSyncService.syncProfileToCloud(profile);
      
      if (!syncSuccess) {
        throw SyncManagementException('Failed to sync profile to cloud: $profileId');
      }
      
      // Load updated profile from cloud
      final updatedProfile = await _cloudSyncService.loadProfileFromCloud(profileId);
      
      if (updatedProfile != null) {
        // Save updated profile locally
        await _userProfileService.saveUserProfile(updatedProfile);
      }
      
      // Record completion
      final endTime = DateTime.now();
      await _recordSyncCompletion(endTime);
      
      print('Profile sync completed for: $profileId');
      
      return SyncResult(
        success: true,
        profilesSynced: 1,
        duration: endTime.difference(startTime),
        timestamp: endTime,
      );
    } catch (e) {
      print('Error syncing profile $profileId: $e');
      return SyncResult(
        success: false,
        profilesSynced: 0,
        duration: Duration.zero,
        timestamp: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  /// Force sync from cloud (overwrites local data)
  Future<SyncResult> forceSyncFromCloud() async {
    try {
      print('Starting force sync from cloud...');
      
      // Record start time
      final startTime = DateTime.now();
      
      // Load all profiles from cloud
      final cloudProfiles = await _cloudSyncService.loadAllProfilesFromCloud();
      
      // Clear local profiles
      await _userProfileService.clearAllProfiles();
      
      // Save cloud profiles locally
      for (final profile in cloudProfiles) {
        await _userProfileService.saveUserProfile(profile);
      }
      
      // Set first profile as active if there are any
      if (cloudProfiles.isNotEmpty) {
        await _userProfileService.setActiveProfile(cloudProfiles.first);
      }
      
      // Record completion
      final endTime = DateTime.now();
      await _recordSyncCompletion(endTime);
      
      print('Force sync from cloud completed');
      
      return SyncResult(
        success: true,
        profilesSynced: cloudProfiles.length,
        duration: endTime.difference(startTime),
        timestamp: endTime,
      );
    } catch (e) {
      print('Error force syncing from cloud: $e');
      return SyncResult(
        success: false,
        profilesSynced: 0,
        duration: Duration.zero,
        timestamp: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  /// Get sync status for all profiles
  Future<List<ProfileSyncStatus>> getSyncStatusForAllProfiles() async {
    try {
      final profiles = await _userProfileService.getAllProfiles();
      final statusList = <ProfileSyncStatus>[];
      
      for (final profile in profiles) {
        final status = await _cloudSyncService.getSyncStatus(profile.id);
        final lastSync = await _getLastSyncTime();
        final devices = await _cloudSyncService.getProfileSyncDevices(profile.id);
        
        statusList.add(ProfileSyncStatus(
          profileId: profile.id,
          profileName: profile.name,
          syncStatus: status,
          lastSync: lastSync,
          syncedDevices: devices,
        ));
      }
      
      return statusList;
    } catch (e) {
      print('Error getting sync status for profiles: $e');
      return [];
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    try {
      return await _getLastSyncTime();
    } catch (e) {
      print('Error getting last sync time: $e');
      return null;
    }
  }

  /// Check if sync is needed for any profiles
  Future<bool> isSyncNeeded() async {
    try {
      final lastSync = await _getLastSyncTime();
      
      // If never synced, sync is needed
      if (lastSync == null) {
        return true;
      }
      
      // Check if enough time has passed since last sync
      final now = DateTime.now();
      final timeSinceLastSync = now.difference(lastSync);
      
      // Sync needed if more than 1 hour has passed
      return timeSinceLastSync > const Duration(hours: 1);
    } catch (e) {
      print('Error checking if sync is needed: $e');
      return false;
    }
  }

  /// Resolve sync conflicts for a profile
  Future<bool> resolveConflicts(String profileId) async {
    try {
      print('Resolving conflicts for profile: $profileId');
      
      final success = await _cloudSyncService.resolveSyncConflicts(profileId);
      
      if (success) {
        print('Conflicts resolved for profile: $profileId');
      } else {
        print('Failed to resolve conflicts for profile: $profileId');
      }
      
      return success;
    } catch (e) {
      print('Error resolving conflicts for profile $profileId: $e');
      return false;
    }
  }

  /// Enable auto-sync
  Future<void> enableAutoSync() async {
    try {
      final settings = await _getSyncSettings();
      final updatedSettings = settings.copyWith(autoSyncEnabled: true);
      await _saveSyncSettings(updatedSettings);
      
      print('Auto-sync enabled');
    } catch (e) {
      print('Error enabling auto-sync: $e');
      rethrow;
    }
  }

  /// Disable auto-sync
  Future<void> disableAutoSync() async {
    try {
      final settings = await _getSyncSettings();
      final updatedSettings = settings.copyWith(autoSyncEnabled: false);
      await _saveSyncSettings(updatedSettings);
      
      print('Auto-sync disabled');
    } catch (e) {
      print('Error disabling auto-sync: $e');
      rethrow;
    }
  }

  /// Set sync frequency
  Future<void> setSyncFrequency(Duration frequency) async {
    try {
      final settings = await _getSyncSettings();
      final updatedSettings = settings.copyWith(syncFrequency: frequency);
      await _saveSyncSettings(updatedSettings);
      
      print('Sync frequency set to ${frequency.inMinutes} minutes');
    } catch (e) {
      print('Error setting sync frequency: $e');
      rethrow;
    }
  }

  /// Get sync settings
  Future<SyncSettings> getSyncSettings() async {
    try {
      return await _getSyncSettings();
    } catch (e) {
      print('Error getting sync settings: $e');
      // Return default settings
      return SyncSettings(
        autoSyncEnabled: true,
        syncFrequency: const Duration(minutes: 30),
        syncOnProfileChange: true,
        syncOnAppLaunch: true,
      );
    }
  }

  /// Add pending change for sync
  Future<void> addPendingChange(PendingChange change) async {
    try {
      await _addPendingChange(change);
    } catch (e) {
      print('Error adding pending change: $e');
    }
  }

  /// Process pending changes
  Future<void> processPendingChanges() async {
    try {
      final changes = await _getPendingChanges();
      
      if (changes.isEmpty) {
        return;
      }
      
      print('Processing ${changes.length} pending changes');
      
      // Process changes
      for (final change in changes) {
        await _processPendingChange(change);
      }
      
      // Clear processed changes
      await _clearPendingChanges();
      
      print('Processed ${changes.length} pending changes');
    } catch (e) {
      print('Error processing pending changes: $e');
    }
  }

  // Private methods

  Future<void> _loadSyncSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_syncSettingsKey);
      
      if (settingsJson != null) {
        // Settings already loaded
        return;
      }
      
      // Set default settings
      final defaultSettings = SyncSettings(
        autoSyncEnabled: true,
        syncFrequency: const Duration(minutes: 30),
        syncOnProfileChange: true,
        syncOnAppLaunch: true,
      );
      
      await _saveSyncSettings(defaultSettings);
    } catch (e) {
      print('Error loading sync settings: $e');
    }
  }

  Future<SyncSettings> _getSyncSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_syncSettingsKey);
      
      if (settingsJson == null) {
        // Return default settings
        return SyncSettings(
          autoSyncEnabled: true,
          syncFrequency: const Duration(minutes: 30),
          syncOnProfileChange: true,
          syncOnAppLaunch: true,
        );
      }
      
      final settingsData = jsonDecode(settingsJson) as Map<String, dynamic>;
      return SyncSettings.fromJson(settingsData);
    } catch (e) {
      print('Error getting sync settings: $e');
      rethrow;
    }
  }

  Future<void> _saveSyncSettings(SyncSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_syncSettingsKey, jsonEncode(settings.toJson()));
    } catch (e) {
      print('Error saving sync settings: $e');
      rethrow;
    }
  }

  Future<DateTime?> _getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncString = prefs.getString(_lastSyncKey);
      
      if (lastSyncString == null) {
        return null;
      }
      
      return DateTime.parse(lastSyncString);
    } catch (e) {
      print('Error getting last sync time: $e');
      return null;
    }
  }

  Future<void> _recordSyncCompletion(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, timestamp.toIso8601String());
    } catch (e) {
      print('Error recording sync completion: $e');
    }
  }

  void _startChangeMonitoring() {
    try {
      // Start periodic sync based on settings
      _startPeriodicSync();
    } catch (e) {
      print('Error starting change monitoring: $e');
    }
  }

  void _startPeriodicSync() async {
    try {
      final settings = await _getSyncSettings();
      
      if (!settings.autoSyncEnabled) {
        return;
      }
      
      // Periodically check if sync is needed
      Timer.periodic(settings.syncFrequency, (timer) async {
        if (await isSyncNeeded()) {
          await performFullSync();
        }
      });
    } catch (e) {
      AACLogger.error('Error starting periodic sync: $e', tag: 'SyncManager');
    }
  }

  Future<List<PendingChange>> _getPendingChanges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final changesJson = prefs.getStringList(_pendingChangesKey) ?? [];
      
      return changesJson
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .map((data) => PendingChange.fromJson(data))
          .toList();
    } catch (e) {
      print('Error getting pending changes: $e');
      return [];
    }
  }

  Future<void> _addPendingChange(PendingChange change) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing changes
      final changesJson = prefs.getStringList(_pendingChangesKey) ?? [];
      final changes = changesJson
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .map((data) => PendingChange.fromJson(data))
          .toList();
      
      // Add new change
      changes.add(change);
      
      // Save updated changes
      final updatedChangesJson = changes
          .map((change) => jsonEncode(change.toJson()))
          .toList();
      
      await prefs.setStringList(_pendingChangesKey, updatedChangesJson);
    } catch (e) {
      print('Error adding pending change: $e');
      rethrow;
    }
  }

  Future<void> _clearPendingChanges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingChangesKey);
    } catch (e) {
      print('Error clearing pending changes: $e');
      rethrow;
    }
  }

  Future<void> _processPendingChange(PendingChange change) async {
    try {
      // Process the pending change
      // This would depend on the type of change
      print('Processing pending change: ${change.changeType} for ${change.targetId}');
    } catch (e) {
      print('Error processing pending change: $e');
    }
  }
}

// Data classes

class SyncResult {
  final bool success;
  final int profilesSynced;
  final Duration duration;
  final DateTime timestamp;
  final String? errorMessage;
  
  SyncResult({
    required this.success,
    required this.profilesSynced,
    required this.duration,
    required this.timestamp,
    this.errorMessage,
  });
  
  @override
  String toString() => '''
SyncResult(
  success: $success,
  profilesSynced: $profilesSynced,
  duration: ${duration.inMilliseconds}ms,
  timestamp: $timestamp
  ${errorMessage != null ? 'error: $errorMessage' : ''}
)''';
}

class ProfileSyncStatus {
  final String profileId;
  final String profileName;
  final SyncStatus syncStatus;
  final DateTime? lastSync;
  final List<DeviceSyncInfo> syncedDevices;
  
  ProfileSyncStatus({
    required this.profileId,
    required this.profileName,
    required this.syncStatus,
    this.lastSync,
    required this.syncedDevices,
  });
  
  @override
  String toString() => '''
ProfileSyncStatus(
  profile: $profileName ($profileId),
  status: $syncStatus,
  lastSync: $lastSync,
  devices: ${syncedDevices.length}
)''';
}

enum SyncStatus {
  synced,
  pending,
  conflict,
  error,
  disabled,
}

class SyncSettings {
  final bool autoSyncEnabled;
  final Duration syncFrequency;
  final bool syncOnProfileChange;
  final bool syncOnAppLaunch;
  
  SyncSettings({
    required this.autoSyncEnabled,
    required this.syncFrequency,
    required this.syncOnProfileChange,
    required this.syncOnAppLaunch,
  });
  
  SyncSettings copyWith({
    bool? autoSyncEnabled,
    Duration? syncFrequency,
    bool? syncOnProfileChange,
    bool? syncOnAppLaunch,
  }) =>
      SyncSettings(
        autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
        syncFrequency: syncFrequency ?? this.syncFrequency,
        syncOnProfileChange: syncOnProfileChange ?? this.syncOnProfileChange,
        syncOnAppLaunch: syncOnAppLaunch ?? this.syncOnAppLaunch,
      );
  
  Map<String, dynamic> toJson() => {
        'autoSyncEnabled': autoSyncEnabled,
        'syncFrequency': syncFrequency.inMilliseconds,
        'syncOnProfileChange': syncOnProfileChange,
        'syncOnAppLaunch': syncOnAppLaunch,
      };
  
  factory SyncSettings.fromJson(Map<String, dynamic> json) => SyncSettings(
        autoSyncEnabled: json['autoSyncEnabled'],
        syncFrequency: Duration(milliseconds: json['syncFrequency']),
        syncOnProfileChange: json['syncOnProfileChange'],
        syncOnAppLaunch: json['syncOnAppLaunch'],
      );
}

enum ChangeType {
  profileCreated,
  profileUpdated,
  profileDeleted,
  symbolCreated,
  symbolUpdated,
  symbolDeleted,
  categoryCreated,
  categoryUpdated,
  categoryDeleted,
}

class PendingChange {
  final ChangeType changeType;
  final String targetId;
  final String profileId;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  
  PendingChange({
    required this.changeType,
    required this.targetId,
    required this.profileId,
    required this.timestamp,
    this.data,
  });
  
  Map<String, dynamic> toJson() => {
        'changeType': changeType.toString(),
        'targetId': targetId,
        'profileId': profileId,
        'timestamp': timestamp.toIso8601String(),
        'data': data,
      };
  
  factory PendingChange.fromJson(Map<String, dynamic> json) => PendingChange(
        changeType: ChangeType.values.firstWhere(
          (type) => type.toString() == json['changeType'],
          orElse: () => ChangeType.profileUpdated,
        ),
        targetId: json['targetId'],
        profileId: json['profileId'],
        timestamp: DateTime.parse(json['timestamp']),
        data: json['data'] as Map<String, dynamic>?,
      );
}