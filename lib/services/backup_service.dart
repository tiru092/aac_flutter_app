import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/symbol.dart';
import '../services/user_profile_service.dart';
import '../services/encryption_service.dart';
import '../services/cloud_sync_service.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';

/// Custom exception for backup-related errors
class BackupException implements Exception {
  final String message;
  
  BackupException(this.message);
  
  @override
  String toString() => 'BackupException: $message';
}

/// Service to handle profile backup and restore functionality
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  static const String _backupHistoryKey = 'backup_history';
  static const String _lastBackupKey = 'last_backup_timestamp';
  
  final CloudSyncService _cloudSyncService = CloudSyncService();

  /// Create a local backup of all profiles
  Future<BackupResult> createLocalBackup({
    String? backupName,
    bool encryptBackup = true,
    List<String>? profileIds,
  }) async {
    try {
      print('Creating local backup...');
      
      // Record start time
      final startTime = DateTime.now();
      
      // Get profiles to backup
      final allProfiles = await UserProfileService.getAllProfiles();
      final profilesToBackup = profileIds != null
          ? allProfiles.where((profile) => profileIds.contains(profile.id)).toList()
          : allProfiles;
      
      if (profilesToBackup.isEmpty) {
        throw BackupException('No profiles found to backup');
      }
      
      // Create backup data
      final backupData = {
        'version': '1.0',
        'createdAt': startTime.toIso8601String(),
        'profiles': profilesToBackup.map((profile) => profile.toJson()).toList(),
        'backupName': backupName ?? 'Backup ${startTime.toString().split(' ')[0]}',
      };
      
      // Convert to JSON
      final backupJson = jsonEncode(backupData);
      
      // Encrypt if requested
      final backupContent = encryptBackup
          ? EncryptionService().encrypt(backupJson)
          : backupJson;
      
      // Create backup file
      final backupFile = await _createBackupFile(backupContent, encryptBackup);
      
      // Record backup in history
      final backupInfo = BackupInfo(
        id: 'backup_${DateTime.now().millisecondsSinceEpoch}',
        name: backupData['backupName'] as String,
        filePath: backupFile.path,
        size: await backupFile.length(),
        createdAt: startTime,
        isEncrypted: encryptBackup,
        profileCount: profilesToBackup.length,
      );
      
      await _recordBackup(backupInfo);
      
      // Record completion
      final endTime = DateTime.now();
      
      print('Local backup created successfully: ${backupFile.path}');
      
      return BackupResult(
        success: true,
        backupInfo: backupInfo,
        duration: endTime.difference(startTime),
        timestamp: endTime,
      );
    } catch (e) {
      print('Error creating local backup: $e');
      return BackupResult(
        success: false,
        duration: Duration.zero,
        timestamp: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  /// Restore profiles from a local backup
  Future<RestoreResult> restoreFromLocalBackup(
    String backupFilePath, {
    bool decryptBackup = true,
  }) async {
    try {
      print('Restoring from local backup: $backupFilePath');
      
      // Record start time
      final startTime = DateTime.now();
      
      // Check if backup file exists
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        throw BackupException('Backup file not found: $backupFilePath');
      }
      
      // Read backup content
      final backupContent = await backupFile.readAsString();
      
      // Decrypt if requested
      final backupJson = decryptBackup
          ? EncryptionService().decrypt(backupContent)
          : backupContent;
      
      // Parse backup data
      final backupData = jsonDecode(backupJson) as Map<String, dynamic>;
      
      // Validate backup version
      final version = backupData['version'] as String?;
      if (version != '1.0') {
        throw BackupException('Unsupported backup version: $version');
      }
      
      // Get profiles from backup
      final profilesData = backupData['profiles'] as List;
      final restoredProfiles = profilesData
          .map((data) => UserProfile.fromJson(Map<String, dynamic>.from(data)))
          .toList();
      
      // Save restored profiles
      for (final profile in restoredProfiles) {
        await UserProfileService.saveUserProfile(profile);
      }
      
      // Set first profile as active if there are any
      if (restoredProfiles.isNotEmpty) {
        await UserProfileService.setActiveProfile(restoredProfiles.first);
      }
      
      // Record completion
      final endTime = DateTime.now();
      
      print('Restore from local backup completed successfully');
      
      return RestoreResult(
        success: true,
        profilesRestored: restoredProfiles.length,
        duration: endTime.difference(startTime),
        timestamp: endTime,
      );
    } catch (e) {
      print('Error restoring from local backup: $e');
      return RestoreResult(
        success: false,
        profilesRestored: 0,
        duration: Duration.zero,
        timestamp: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  /// Create a cloud backup of all profiles
  Future<BackupResult> createCloudBackup({
    String? backupName,
    List<String>? profileIds,
  }) async {
    try {
      print('Creating cloud backup...');
      
      // Check if cloud sync is available
      if (!_cloudSyncService.isCloudSyncAvailable) {
        throw BackupException('Cloud sync not available');
      }
      
      // Record start time
      final startTime = DateTime.now();
      
      // Get profiles to backup
      final allProfiles = await UserProfileService.getAllProfiles();
      final profilesToBackup = profileIds != null
          ? allProfiles.where((profile) => profileIds.contains(profile.id)).toList()
          : allProfiles;
      
      if (profilesToBackup.isEmpty) {
        throw BackupException('No profiles found to backup');
      }
      
      // Create backup data
      final backupData = {
        'version': '1.0',
        'createdAt': startTime.toIso8601String(),
        'profiles': profilesToBackup.map((profile) => profile.toJson()).toList(),
        'backupName': backupName ?? 'Cloud Backup ${startTime.toString().split(' ')[0]}',
      };
      
      // Convert to JSON
      final backupJson = jsonEncode(backupData);
      
      // Encrypt backup data
      final encryptedBackup = EncryptionService().encrypt(backupJson);
      
      // Upload to cloud storage (placeholder - implement actual cloud storage)
      final backupPath = 'backups/backup_${DateTime.now().millisecondsSinceEpoch}.backup';
      // final downloadUrl = await _cloudSyncService.uploadFile(backupPath, backupPath);
      final downloadUrl = 'https://example.com/$backupPath'; // Placeholder
      
      if (downloadUrl == null) {
        throw BackupException('Failed to upload backup to cloud');
      }
      
      // Record backup in history
      final backupInfo = BackupInfo(
        id: 'cloud_backup_${DateTime.now().millisecondsSinceEpoch}',
        name: backupData['backupName'] as String,
        filePath: downloadUrl,
        size: backupJson.length,
        createdAt: startTime,
        isEncrypted: true,
        profileCount: profilesToBackup.length,
        isCloudBackup: true,
      );
      
      await _recordBackup(backupInfo);
      
      // Record completion
      final endTime = DateTime.now();
      
      print('Cloud backup created successfully');
      
      return BackupResult(
        success: true,
        backupInfo: backupInfo,
        duration: endTime.difference(startTime),
        timestamp: endTime,
      );
    } catch (e) {
      print('Error creating cloud backup: $e');
      return BackupResult(
        success: false,
        duration: Duration.zero,
        timestamp: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  /// Restore profiles from a cloud backup
  Future<RestoreResult> restoreFromCloudBackup(String backupUrl) async {
    try {
      print('Restoring from cloud backup: $backupUrl');
      
      // Check if cloud sync is available
      if (!_cloudSyncService.isCloudSyncAvailable) {
        throw BackupException('Cloud sync not available');
      }
      
      // Record start time
      final startTime = DateTime.now();
      
      // Download backup from cloud (placeholder - implement actual cloud storage)
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_backup.backup');
      
      // final downloadSuccess = await _cloudSyncService.downloadFile(backupUrl, tempFile.path);
      final downloadSuccess = true; // Placeholder
      
      if (!downloadSuccess) {
        throw BackupException('Failed to download backup from cloud');
      }
      
      // Restore from downloaded file
      final result = await restoreFromLocalBackup(tempFile.path);
      
      // Clean up temp file
      await tempFile.delete();
      
      // Record completion
      final endTime = DateTime.now();
      
      if (result.success) {
        print('Restore from cloud backup completed successfully');
      } else {
        print('Restore from cloud backup failed: ${result.errorMessage}');
      }
      
      return result.copyWith(timestamp: endTime);
    } catch (e) {
      print('Error restoring from cloud backup: $e');
      return RestoreResult(
        success: false,
        profilesRestored: 0,
        duration: Duration.zero,
        timestamp: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  /// Get backup history
  Future<List<BackupInfo>> getBackupHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_backupHistoryKey) ?? [];
      
      final history = historyJson
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .map((data) => BackupInfo.fromJson(data))
          .toList();
      
      // Sort by creation date (newest first)
      history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return history;
    } catch (e) {
      print('Error getting backup history: $e');
      return [];
    }
  }

  /// Delete a backup
  Future<bool> deleteBackup(String backupId) async {
    try {
      // Get backup history
      final history = await getBackupHistory();
      final backup = history.firstWhere(
        (b) => b.id == backupId,
        orElse: () => throw BackupException('Backup not found: $backupId'),
      );
      
      // Delete backup file if it exists locally
      if (!backup.isCloudBackup) {
        final backupFile = File(backup.filePath);
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
      }
      
      // Remove from history
      final updatedHistory = history.where((b) => b.id != backupId).toList();
      await _saveBackupHistory(updatedHistory);
      
      return true;
    } catch (e) {
      print('Error deleting backup: $e');
      return false;
    }
  }

  /// Create backup file
  Future<File> _createBackupFile(String content, bool isEncrypted) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupsDir = Directory('${dir.path}/backups');
      
      // Create backups directory if it doesn't exist
      if (!await backupsDir.exists()) {
        await backupsDir.create(recursive: true);
      }
      
      // Create backup file
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = isEncrypted ? '.backup.enc' : '.backup';
      final backupFile = File('${backupsDir.path}/backup_$timestamp$extension');
      
      // Write content to file
      await backupFile.writeAsString(content);
      
      return backupFile;
    } catch (e) {
      print('Error creating backup file: $e');
      rethrow;
    }
  }

  /// Record backup in history
  Future<void> _recordBackup(BackupInfo backupInfo) async {
    try {
      final history = await getBackupHistory();
      history.insert(0, backupInfo);
      
      // Keep only last 50 backups
      if (history.length > 50) {
        history.removeRange(50, history.length);
      }
      
      await _saveBackupHistory(history);
      
      // Record last backup timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastBackupKey, backupInfo.createdAt.toIso8601String());
    } catch (e) {
      print('Error recording backup: $e');
    }
  }

  /// Save backup history
  Future<void> _saveBackupHistory(List<BackupInfo> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = history
          .map((info) => jsonEncode(info.toJson()))
          .toList();
      
      await prefs.setStringList(_backupHistoryKey, historyJson);
    } catch (e) {
      print('Error saving backup history: $e');
    }
  }

  /// Get last backup timestamp
  Future<DateTime?> getLastBackupTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampString = prefs.getString(_lastBackupKey);
      
      if (timestampString == null) return null;
      
      return DateTime.parse(timestampString);
    } catch (e) {
      print('Error getting last backup timestamp: $e');
      return null;
    }
  }

  /// Export profiles to JSON file
  Future<String> exportProfilesToJson() async {
    try {
      final profiles = await UserProfileService.getAllProfiles();
      final exportData = {
        'version': '1.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'profiles': profiles.map((profile) => profile.toJson()).toList(),
      };
      
      final jsonContent = jsonEncode(exportData);
      final encryptedContent = EncryptionService().encrypt(jsonContent);
      
      final dir = await getApplicationDocumentsDirectory();
      final exportFile = File('${dir.path}/profiles_export.json');
      await exportFile.writeAsString(encryptedContent);
      
      return exportFile.path;
    } catch (e) {
      print('Error exporting profiles to JSON: $e');
      rethrow;
    }
  }

  /// Import profiles from JSON file
  Future<bool> importProfilesFromJson(String filePath) async {
    try {
      final importFile = File(filePath);
      if (!await importFile.exists()) {
        throw BackupException('Import file not found: $filePath');
      }
      
      final content = await importFile.readAsString();
      final decryptedContent = EncryptionService().decrypt(content);
      final importData = jsonDecode(decryptedContent) as Map<String, dynamic>;
      
      // Validate version
      final version = importData['version'] as String?;
      if (version != '1.0') {
        throw BackupException('Unsupported import version: $version');
      }
      
      // Get profiles from import data
      final profilesData = importData['profiles'] as List;
      final importedProfiles = profilesData
          .map((data) => UserProfile.fromJson(Map<String, dynamic>.from(data)))
          .toList();
      
      // Save imported profiles
      for (final profile in importedProfiles) {
        await UserProfileService.saveUserProfile(profile);
      }
      
      // Set first profile as active if there are any and no active profile exists
      if (importedProfiles.isNotEmpty) {
        final activeProfile = await UserProfileService.getActiveProfile();
        if (activeProfile == null) {
          await UserProfileService.setActiveProfile(importedProfiles.first);
        }
      }
      
      return true;
    } catch (e) {
      print('Error importing profiles from JSON: $e');
      return false;
    }
  }
}

/// Information about a backup
class BackupInfo {
  final String id;
  final String name;
  final String filePath;
  final int size;
  final DateTime createdAt;
  final bool isEncrypted;
  final int profileCount;
  final bool isCloudBackup;

  BackupInfo({
    required this.id,
    required this.name,
    required this.filePath,
    required this.size,
    required this.createdAt,
    required this.isEncrypted,
    required this.profileCount,
    this.isCloudBackup = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'filePath': filePath,
    'size': size,
    'createdAt': createdAt.toIso8601String(),
    'isEncrypted': isEncrypted,
    'profileCount': profileCount,
    'isCloudBackup': isCloudBackup,
  };

  factory BackupInfo.fromJson(Map<String, dynamic> json) => BackupInfo(
    id: json['id'],
    name: json['name'],
    filePath: json['filePath'],
    size: json['size'],
    createdAt: DateTime.parse(json['createdAt']),
    isEncrypted: json['isEncrypted'],
    profileCount: json['profileCount'],
    isCloudBackup: json['isCloudBackup'] ?? false,
  );

  BackupInfo copyWith({
    String? id,
    String? name,
    String? filePath,
    int? size,
    DateTime? createdAt,
    bool? isEncrypted,
    int? profileCount,
    bool? isCloudBackup,
  }) => BackupInfo(
    id: id ?? this.id,
    name: name ?? this.name,
    filePath: filePath ?? this.filePath,
    size: size ?? this.size,
    createdAt: createdAt ?? this.createdAt,
    isEncrypted: isEncrypted ?? this.isEncrypted,
    profileCount: profileCount ?? this.profileCount,
    isCloudBackup: isCloudBackup ?? this.isCloudBackup,
  );
}

/// Result of a backup operation
class BackupResult {
  final bool success;
  final BackupInfo? backupInfo;
  final Duration duration;
  final DateTime timestamp;
  final String? errorMessage;

  BackupResult({
    required this.success,
    this.backupInfo,
    required this.duration,
    required this.timestamp,
    this.errorMessage,
  });

  BackupResult copyWith({
    bool? success,
    BackupInfo? backupInfo,
    Duration? duration,
    DateTime? timestamp,
    String? errorMessage,
  }) => BackupResult(
    success: success ?? this.success,
    backupInfo: backupInfo ?? this.backupInfo,
    duration: duration ?? this.duration,
    timestamp: timestamp ?? this.timestamp,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}

/// Result of a restore operation
class RestoreResult {
  final bool success;
  final int profilesRestored;
  final Duration duration;
  final DateTime timestamp;
  final String? errorMessage;

  RestoreResult({
    required this.success,
    required this.profilesRestored,
    required this.duration,
    required this.timestamp,
    this.errorMessage,
  });

  RestoreResult copyWith({
    bool? success,
    int? profilesRestored,
    Duration? duration,
    DateTime? timestamp,
    String? errorMessage,
  }) => RestoreResult(
    success: success ?? this.success,
    profilesRestored: profilesRestored ?? this.profilesRestored,
    duration: duration ?? this.duration,
    timestamp: timestamp ?? this.timestamp,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}