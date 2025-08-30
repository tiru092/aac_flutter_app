import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/symbol.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../services/crash_reporting_service.dart';

/// Custom exception for cloud sync-related errors
class CloudSyncException implements Exception {
  final String message;
  final String code;
  
  CloudSyncException(this.message, [this.code = 'unknown']);
  
  @override
  String toString() => 'CloudSyncException: $message (Code: $code)';
}

/// Service to handle cloud synchronization with Firestore
class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final CrashReportingService _crashReportingService = CrashReportingService();

  /// Sync user profile data to Firestore with comprehensive error handling
  Future<bool> syncProfileToCloud(UserProfile profile) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw CloudSyncException('User not authenticated', 'not_authenticated');
      }

      // Convert profile to Firestore-compatible format
      final profileData = profile.toJson();
      
      // Remove local-only fields that shouldn't be synced
      profileData.remove('userSymbols');
      profileData.remove('userCategories');
      
      // Add metadata
      profileData['updatedAt'] = FieldValue.serverTimestamp();
      profileData['userId'] = user.uid;
      profileData['lastSyncedAt'] = FieldValue.serverTimestamp();

      // Sync profile document
      await _firestore
          .collection('user_profiles')
          .doc(profile.id)
          .set(profileData, SetOptions(merge: true));

      // Sync user symbols
      await _syncSymbolsToCloud(profile.id, profile.userSymbols);
      
      // Sync user categories
      await _syncCategoriesToCloud(profile.id, profile.userCategories);

      return true;
    } on FirebaseException catch (e) {
      await _crashReportingService.reportException(
        CloudSyncException('Firebase error during profile sync: ${e.message}', e.code)
      );
      print('Firebase error syncing profile to cloud: $e');
      return false;
    } catch (e) {
      await _crashReportingService.reportException(
        CloudSyncException('Unexpected error during profile sync: $e')
      );
      print('Error syncing profile to cloud: $e');
      return false;
    }
  }

  /// Sync symbols to Firestore with batch operations and error handling
  Future<void> _syncSymbolsToCloud(String profileId, List<Symbol> symbols) async {
    try {
      if (symbols.isEmpty) return;
      
      // Process symbols in batches of 500 (Firestore limit)
      const batchSize = 500;
      for (int i = 0; i < symbols.length; i += batchSize) {
        final batch = _firestore.batch();
        final collection = _firestore.collection('user_profiles/$profileId/symbols');
        
        final end = (i + batchSize < symbols.length) ? i + batchSize : symbols.length;
        final batchSymbols = symbols.sublist(i, end);
        
        for (final symbol in batchSymbols) {
          final symbolData = symbol.toJson();
          symbolData['profileId'] = profileId;
          symbolData['createdAt'] = symbolData['dateCreated'];
          symbolData['updatedAt'] = FieldValue.serverTimestamp();
          symbolData.remove('dateCreated'); // Use consistent field name
          
          final docId = symbol.id ?? 'symbol_${DateTime.now().millisecondsSinceEpoch}_${i}';
          batch.set(collection.doc(docId), symbolData);
        }
        
        // Commit batch
        await batch.commit();
      }
    } on FirebaseException catch (e) {
      await _crashReportingService.reportException(
        CloudSyncException('Firebase error during symbols sync: ${e.message}', e.code)
      );
      print('Firebase error syncing symbols to cloud: $e');
    } catch (e) {
      await _crashReportingService.reportException(
        CloudSyncException('Unexpected error during symbols sync: $e')
      );
      print('Error syncing symbols to cloud: $e');
    }
  }

  /// Sync categories to Firestore with batch operations and error handling
  Future<void> _syncCategoriesToCloud(String profileId, List<Category> categories) async {
    try {
      if (categories.isEmpty) return;
      
      // Process categories in batches of 500 (Firestore limit)
      const batchSize = 500;
      for (int i = 0; i < categories.length; i += batchSize) {
        final batch = _firestore.batch();
        final collection = _firestore.collection('user_profiles/$profileId/categories');
        
        final end = (i + batchSize < categories.length) ? i + batchSize : categories.length;
        final batchCategories = categories.sublist(i, end);
        
        for (final category in batchCategories) {
          final categoryData = category.toJson();
          categoryData['profileId'] = profileId;
          categoryData['createdAt'] = categoryData['dateCreated'];
          categoryData['updatedAt'] = FieldValue.serverTimestamp();
          categoryData.remove('dateCreated'); // Use consistent field name
          
          final docId = 'category_${DateTime.now().millisecondsSinceEpoch}_${i}';
          batch.set(collection.doc(docId), categoryData);
        }
        
        // Commit batch
        await batch.commit();
      }
    } on FirebaseException catch (e) {
      await _crashReportingService.reportException(
        CloudSyncException('Firebase error during categories sync: ${e.message}', e.code)
      );
      print('Firebase error syncing categories to cloud: $e');
    } catch (e) {
      await _crashReportingService.reportException(
        CloudSyncException('Unexpected error during categories sync: $e')
      );
      print('Error syncing categories to cloud: $e');
    }
  }

  /// Load user profile data from Firestore with comprehensive error handling
  Future<UserProfile?> loadProfileFromCloud(String profileId) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw CloudSyncException('User not authenticated', 'not_authenticated');
      }

      // Load profile document
      final profileDoc = await _firestore
          .collection('user_profiles')
          .doc(profileId)
          .get();

      if (!profileDoc.exists) {
        throw CloudSyncException('Profile not found in cloud', 'profile_not_found');
      }

      final profileData = profileDoc.data()!;
      
      // Load symbols
      final symbolsSnapshot = await _firestore
          .collection('user_profiles/$profileId/symbols')
          .get();
      
      final symbols = symbolsSnapshot.docs
          .map((doc) => Symbol.fromJson(doc.data()))
          .toList();
      
      // Load categories
      final categoriesSnapshot = await _firestore
          .collection('user_profiles/$profileId/categories')
          .get();
      
      final categories = categoriesSnapshot.docs
          .map((doc) => Category.fromJson(doc.data()))
          .toList();

      // Create profile with cloud data with null safety
      final profile = UserProfile(
        id: profileData['id'] ?? '',
        name: profileData['name'] ?? 'Unnamed Profile',
        role: UserRole.values.firstWhere(
          (role) => role.toString() == profileData['role'],
          orElse: () => UserRole.child,
        ),
        avatarPath: profileData['avatarPath'],
        createdAt: profileData['createdAt'] != null 
            ? DateTime.parse(profileData['createdAt'])
            : DateTime.now(),
        settings: ProfileSettings.fromJson(profileData['settings'] ?? {}),
        pin: profileData['pin'],
        email: profileData['email'],
        phoneNumber: profileData['phoneNumber'],
        userSymbols: symbols,
        userCategories: categories,
      );

      return profile;
    } on FirebaseException catch (e) {
      await _crashReportingService.reportException(
        CloudSyncException('Firebase error during profile load: ${e.message}', e.code)
      );
      print('Firebase error loading profile from cloud: $e');
      return null;
    } catch (e) {
      await _crashReportingService.reportException(
        CloudSyncException('Unexpected error during profile load: $e')
      );
      print('Error loading profile from cloud: $e');
      return null;
    }
  }

  /// Sync all user profiles to cloud with error handling
  Future<SyncResult> syncAllProfilesToCloud() async {
    try {
      final startTime = DateTime.now();
      final profiles = await UserProfileService.getAllProfiles();
      int successCount = 0;
      int failureCount = 0;
      
      for (final profile in profiles) {
        final success = await syncProfileToCloud(profile);
        if (success) {
          successCount++;
        } else {
          failureCount++;
        }
      }
      
      final endTime = DateTime.now();
      
      return SyncResult(
        success: failureCount == 0,
        totalProfiles: profiles.length,
        successfulSyncs: successCount,
        failedSyncs: failureCount,
        duration: endTime.difference(startTime),
      );
    } catch (e) {
      await _crashReportingService.reportException(
        CloudSyncException('Unexpected error during bulk sync: $e')
      );
      print('Error syncing all profiles to cloud: $e');
      return SyncResult(
        success: false,
        totalProfiles: 0,
        successfulSyncs: 0,
        failedSyncs: 0,
        duration: Duration.zero,
        errorMessage: e.toString(),
      );
    }
  }

  /// Load all user profiles from cloud with error handling
  Future<List<UserProfile>> loadAllProfilesFromCloud() async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw CloudSyncException('User not authenticated', 'not_authenticated');
      }

      final profilesSnapshot = await _firestore
          .collection('user_profiles')
          .where('userId', isEqualTo: user.uid)
          .get();

      final profiles = <UserProfile>[];
      
      for (final doc in profilesSnapshot.docs) {
        final profile = await loadProfileFromCloud(doc.id);
        if (profile != null) {
          profiles.add(profile);
        }
      }

      return profiles;
    } on FirebaseException catch (e) {
      await _crashReportingService.reportException(
        CloudSyncException('Firebase error during bulk profile load: ${e.message}', e.code)
      );
      print('Firebase error loading all profiles from cloud: $e');
      return [];
    } catch (e) {
      await _crashReportingService.reportException(
        CloudSyncException('Unexpected error during bulk profile load: $e')
      );
      print('Error loading all profiles from cloud: $e');
      return [];
    }
  }

  /// Check if cloud sync is available (user is authenticated)
  bool get isCloudSyncAvailable {
    return _authService.currentUser != null;
  }
  
  /// Debug method to check profile data integrity
  Future<Map<String, dynamic>> debugProfileData(String profileId) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        return {'error': 'User not authenticated'};
      }

      final profileDoc = await _firestore
          .collection('user_profiles')
          .doc(profileId)
          .get();

      if (!profileDoc.exists) {
        return {'error': 'Profile not found', 'profileId': profileId};
      }

      final data = profileDoc.data()!;
      return {
        'profileExists': true,
        'hasId': data['id'] != null,
        'hasName': data['name'] != null,
        'hasCreatedAt': data['createdAt'] != null,
        'hasRole': data['role'] != null,
        'dataKeys': data.keys.toList(),
        'rawData': data,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// Get sync status for a specific profile
  Future<SyncStatusInfo> getProfileSyncStatus(String profileId) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        return SyncStatusInfo(
          profileId: profileId,
          status: SyncStatus.notSynced,
          lastSync: null,
          errorMessage: 'User not authenticated',
        );
      }

      final profileDoc = await _firestore
          .collection('user_profiles')
          .doc(profileId)
          .get();

      if (!profileDoc.exists) {
        return SyncStatusInfo(
          profileId: profileId,
          status: SyncStatus.notSynced,
          lastSync: null,
        );
      }

      final profileData = profileDoc.data()!;
      final lastSync = profileData['lastSyncedAt'] as Timestamp?;
      
      return SyncStatusInfo(
        profileId: profileId,
        status: SyncStatus.syncedToThisDevice,
        lastSync: lastSync?.toDate(),
      );
    } catch (e) {
      return SyncStatusInfo(
        profileId: profileId,
        status: SyncStatus.error,
        lastSync: null,
        errorMessage: e.toString(),
      );
    }
  }
}

// Data classes for sync information

enum SyncStatus {
  syncedToThisDevice,
  syncedToOtherDevice,
  notSynced,
  syncing,
  error,
  unknown,
}

class DeviceSyncInfo {
  final String deviceId;
  final String deviceName;
  final DateTime lastSync;
  final bool isCurrentDevice;
  
  DeviceSyncInfo({
    required this.deviceId,
    required this.deviceName,
    required this.lastSync,
    required this.isCurrentDevice,
  });
}

class SyncResult {
  final bool success;
  final int totalProfiles;
  final int successfulSyncs;
  final int failedSyncs;
  final Duration duration;
  final String? errorMessage;
  
  SyncResult({
    required this.success,
    required this.totalProfiles,
    required this.successfulSyncs,
    required this.failedSyncs,
    required this.duration,
    this.errorMessage,
  });
}

class SyncStatusInfo {
  final String profileId;
  final SyncStatus status;
  final DateTime? lastSync;
  final String? errorMessage;
  
  SyncStatusInfo({
    required this.profileId,
    required this.status,
    this.lastSync,
    this.errorMessage,
  });
}