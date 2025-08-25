import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/communication_history.dart';
import 'secure_encryption_service.dart';
import 'cloud_sync_service.dart';

/// Custom exception for communication history-related errors
class CommunicationHistoryException implements Exception {
  final String message;
  final String code;
  
  CommunicationHistoryException(this.message, [this.code = 'unknown']);
  
  @override
  String toString() => 'CommunicationHistoryException: $message (Code: $code)';
}

/// Service to manage encrypted communication history
class CommunicationHistoryService {
  static final CommunicationHistoryService _instance = CommunicationHistoryService._internal();
  factory CommunicationHistoryService() => _instance;
  CommunicationHistoryService._internal();

  static const String _historyKey = 'communication_history';
  static final SecureEncryptionService _encryptionService = SecureEncryptionService();
  static final CloudSyncService _cloudSyncService = CloudSyncService();

  /// Add a new communication entry to history
  Future<void> addCommunicationEntry(CommunicationHistoryEntry entry) async {
    try {
      // Get existing history
      final history = await _getHistoryForProfile(entry.profileId);
      
      // Add new entry
      history.add(entry);
      
      // Save updated history
      await _saveHistoryForProfile(entry.profileId, history);
      
      // Sync to cloud if available
      if (_cloudSyncService.isCloudSyncAvailable) {
        try {
          await _syncHistoryToCloud(entry.profileId);
        } catch (e) {
          print('Warning: Failed to sync communication history to cloud: $e');
        }
      }
    } catch (e) {
      print('Error adding communication entry: $e');
      rethrow;
    }
  }

  /// Get communication history for a specific profile
  Future<List<CommunicationHistoryEntry>> getHistoryForProfile(String profileId) async {
    try {
      // Try to load from cloud first if available
      if (_cloudSyncService.isCloudSyncAvailable) {
        try {
          final cloudHistory = await _loadHistoryFromCloud(profileId);
          if (cloudHistory != null && cloudHistory.isNotEmpty) {
            return cloudHistory;
          }
        } catch (e) {
          print('Warning: Failed to load communication history from cloud: $e');
        }
      }
      
      // Fallback to local storage
      return await _getHistoryForProfile(profileId);
    } catch (e) {
      print('Error getting communication history: $e');
      return []; // Return empty list as fallback
    }
  }

  /// Delete communication history for a specific profile
  Future<void> clearHistoryForProfile(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing history data
      final historyDataJson = prefs.getStringList(_historyKey) ?? [];
      final historyData = historyDataJson
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .toList();
      
      // Filter out history for this profile
      final filteredHistory = historyData
          .where((data) => data['profileId'] != profileId)
          .toList();
      
      // Save updated history data
      final updatedHistoryJson = filteredHistory
          .map((data) => jsonEncode(data))
          .toList();
      
      await prefs.setStringList(_historyKey, updatedHistoryJson);
      
      // Also clear from cloud if available
      if (_cloudSyncService.isCloudSyncAvailable) {
        try {
          await _clearHistoryFromCloud(profileId);
        } catch (e) {
          print('Warning: Failed to clear communication history from cloud: $e');
        }
      }
    } catch (e) {
      print('Error clearing communication history: $e');
      rethrow;
    }
  }

  /// Get local communication history for a specific profile
  Future<List<CommunicationHistoryEntry>> _getHistoryForProfile(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing history data
      final historyDataJson = prefs.getStringList(_historyKey) ?? [];
      final historyData = historyDataJson
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .toList();
      
      // Find history for this profile
      final profileHistoryData = historyData.firstWhere(
        (data) => data['profileId'] == profileId,
        orElse: () => {'profileId': profileId, 'entries': []},
      );
      
      // Decrypt entries if they are encrypted
      final entriesData = profileHistoryData['entries'] as List;
      final entries = <CommunicationHistoryEntry>[];
      
      for (final entryData in entriesData) {
        if (entryData is String) {
          // This is encrypted data, decrypt it
          final decryptedData = await _encryptionService.decrypt(entryData);
          if (decryptedData != null) {
            final entryJson = jsonDecode(decryptedData) as Map<String, dynamic>;
            entries.add(CommunicationHistoryEntry.fromJson(entryJson));
          }
        } else if (entryData is Map) {
          // This is unencrypted data
          entries.add(CommunicationHistoryEntry.fromJson(Map<String, dynamic>.from(entryData)));
        }
      }
      
      return entries;
    } catch (e) {
      print('Error getting local communication history: $e');
      return []; // Return empty list as fallback
    }
  }

  /// Save communication history for a specific profile
  Future<void> _saveHistoryForProfile(String profileId, List<CommunicationHistoryEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing history data
      final historyDataJson = prefs.getStringList(_historyKey) ?? [];
      final historyData = historyDataJson
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .toList();
      
      // Encrypt all entries
      final encryptedEntries = <String>[];
      for (final entry in entries) {
        final entryJson = jsonEncode(entry.toJson());
        final encryptedEntry = await _encryptionService.encrypt(entryJson);
        if (encryptedEntry != null) {
          encryptedEntries.add(encryptedEntry);
        }
      }
      
      // Create profile history data
      final profileHistoryData = {
        'profileId': profileId,
        'entries': encryptedEntries,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      // Find and update or add the profile history
      final index = historyData.indexWhere((data) => data['profileId'] == profileId);
      
      if (index >= 0) {
        historyData[index] = profileHistoryData;
      } else {
        historyData.add(profileHistoryData);
      }
      
      // Save the updated history data
      final updatedHistoryJson = historyData
          .map((data) => jsonEncode(data))
          .toList();
      
      await prefs.setStringList(_historyKey, updatedHistoryJson);
    } catch (e) {
      print('Error saving communication history: $e');
      rethrow;
    }
  }

  /// Sync communication history to cloud
  Future<void> _syncHistoryToCloud(String profileId) async {
    try {
      // This would sync the encrypted history to Firestore
      // Implementation would depend on your specific cloud storage structure
      print('Syncing communication history for profile $profileId to cloud');
    } catch (e) {
      print('Error syncing communication history to cloud: $e');
      rethrow;
    }
  }

  /// Load communication history from cloud
  Future<List<CommunicationHistoryEntry>?> _loadHistoryFromCloud(String profileId) async {
    try {
      // This would load the encrypted history from Firestore
      // Implementation would depend on your specific cloud storage structure
      print('Loading communication history for profile $profileId from cloud');
      return null; // Return null for now as we don't have cloud implementation
    } catch (e) {
      print('Error loading communication history from cloud: $e');
      return null;
    }
  }

  /// Clear communication history from cloud
  Future<void> _clearHistoryFromCloud(String profileId) async {
    try {
      // This would clear the history from Firestore
      // Implementation would depend on your specific cloud storage structure
      print('Clearing communication history for profile $profileId from cloud');
    } catch (e) {
      print('Error clearing communication history from cloud: $e');
      rethrow;
    }
  }

  /// Get statistics for communication history
  Future<Map<String, dynamic>> getHistoryStatistics(String profileId) async {
    try {
      final history = await getHistoryForProfile(profileId);
      
      // Calculate statistics
      final totalCommunications = history.length;
      final totalSymbols = history.fold<int>(0, (sum, entry) => sum + entry.symbolsUsed.length);
      final uniqueSymbols = <String>{};
      final categoryCount = <String, int>{};
      
      for (final entry in history) {
        uniqueSymbols.addAll(entry.symbolsUsed);
        
        if (entry.category != null) {
          categoryCount[entry.category!] = (categoryCount[entry.category!] ?? 0) + 1;
        }
      }
      
      // Find most used category
      String? mostUsedCategory;
      int maxCategoryCount = 0;
      categoryCount.forEach((category, count) {
        if (count > maxCategoryCount) {
          maxCategoryCount = count;
          mostUsedCategory = category;
        }
      });
      
      return {
        'totalCommunications': totalCommunications,
        'totalSymbols': totalSymbols,
        'uniqueSymbols': uniqueSymbols.length,
        'mostUsedCategory': mostUsedCategory,
        'categoryDistribution': categoryCount,
      };
    } catch (e) {
      print('Error calculating history statistics: $e');
      return {
        'totalCommunications': 0,
        'totalSymbols': 0,
        'uniqueSymbols': 0,
        'mostUsedCategory': null,
        'categoryDistribution': <String, int>{},
      };
    }
  }
}