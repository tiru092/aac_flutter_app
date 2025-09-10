import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/symbol.dart';
import '../models/user_profile.dart';
import '../models/subscription.dart';  // Add missing import
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
      
      // Convert symbols and categories to Firestore-compatible format
      final List<Map<String, dynamic>> userSymbolsData = 
          profile.userSymbols.map((symbol) => symbol.toJson()).toList();
      final List<Map<String, dynamic>> userCategoriesData = 
          profile.userCategories.map((category) => category.toJson()).toList();
      
      // Add symbols and categories to profile data
      profileData['userSymbols'] = userSymbolsData;
      profileData['userCategories'] = userCategoriesData;
      
      // Add metadata
      profileData['updatedAt'] = FieldValue.serverTimestamp();
      profileData['userId'] = user.uid;
      profileData['lastSyncedAt'] = FieldValue.serverTimestamp();

      // Sync profile document - Use Firebase UID as document ID
      await _firestore
          .collection('user_profiles')
          .doc(user.uid) // Use Firebase UID instead of profile.id
          .set(profileData, SetOptions(merge: true));

      // Sync user symbols - Use Firebase UID
      await _syncSymbolsToCloud(user.uid, profile.userSymbols);
      
      // Sync user categories - Use Firebase UID  
      await _syncCategoriesToCloud(user.uid, profile.userCategories);

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
  Future<void> _syncSymbolsToCloud(String userUid, List<Symbol> symbols) async {
    try {
      if (symbols.isEmpty) return;
      
      // Process symbols in batches of 500 (Firestore limit)
      const batchSize = 500;
      for (int i = 0; i < symbols.length; i += batchSize) {
        final batch = _firestore.batch();
        
        final end = (i + batchSize < symbols.length) ? i + batchSize : symbols.length;
        final batchSymbols = symbols.sublist(i, end);
        
        for (final symbol in batchSymbols) {
          final symbolData = symbol.toJson();
          symbolData['userId'] = userUid; // Store Firebase UID
          symbolData['createdAt'] = symbolData['dateCreated'] ?? FieldValue.serverTimestamp();
          symbolData['updatedAt'] = FieldValue.serverTimestamp();
          symbolData.remove('dateCreated'); // Use consistent field name
          
          // Use both subcollection and top-level collection for backward compatibility
          final docId = symbol.id ?? 'symbol_${DateTime.now().millisecondsSinceEpoch}_${i}';
          
          // Store in subcollection (preferred)
          final subcollection = _firestore.collection('user_profiles/$userUid/symbols');
          batch.set(subcollection.doc(docId), symbolData);
          
          // Also store in top-level custom_symbols collection for compatibility
          final topLevel = _firestore.collection('custom_symbols');
          batch.set(topLevel.doc(docId), symbolData);
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
  Future<void> _syncCategoriesToCloud(String userUid, List<Category> categories) async {
    try {
      if (categories.isEmpty) return;
      
      // Process categories in batches of 500 (Firestore limit)
      const batchSize = 500;
      for (int i = 0; i < categories.length; i += batchSize) {
        final batch = _firestore.batch();
        
        final end = (i + batchSize < categories.length) ? i + batchSize : categories.length;
        final batchCategories = categories.sublist(i, end);
        
        for (final category in batchCategories) {
          final categoryData = category.toJson();
          categoryData['userId'] = userUid; // Store Firebase UID
          categoryData['createdAt'] = categoryData['dateCreated'] ?? FieldValue.serverTimestamp();
          categoryData['updatedAt'] = FieldValue.serverTimestamp();
          categoryData.remove('dateCreated'); // Use consistent field name
          
          // Use both subcollection and top-level collection for backward compatibility
          final docId = category.id ?? 'category_${DateTime.now().millisecondsSinceEpoch}_${i}';
          
          // Store in subcollection (preferred)
          final subcollection = _firestore.collection('user_profiles/$userUid/categories');
          batch.set(subcollection.doc(docId), categoryData);
          
          // Also store in top-level custom_categories collection for compatibility
          final topLevel = _firestore.collection('custom_categories');
          batch.set(topLevel.doc(docId), categoryData);
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
      
      // Load symbols from both potential locations (for backward compatibility)
      List<Symbol> symbols = [];
      try {
        // Try subcollection first
        final symbolsSnapshot = await _firestore
            .collection('user_profiles/$profileId/symbols')
            .get();
        
        if (symbolsSnapshot.docs.isNotEmpty) {
          symbols = symbolsSnapshot.docs
              .map((doc) => Symbol.fromJson(doc.data()))
              .toList();
        } else {
          // Try custom_symbols collection as fallback
          final customSymbolsSnapshot = await _firestore
              .collection('custom_symbols')
              .where('userId', isEqualTo: profileId)
              .get();
          
          symbols = customSymbolsSnapshot.docs
              .map((doc) => Symbol.fromJson(doc.data()))
              .toList();
        }
      } catch (e) {
        print('Warning: Could not load symbols: $e');
        symbols = [];
      }
      
      // Load categories from both potential locations (for backward compatibility)
      List<Category> categories = [];
      try {
        // Try subcollection first
        final categoriesSnapshot = await _firestore
            .collection('user_profiles/$profileId/categories')
            .get();
        
        if (categoriesSnapshot.docs.isNotEmpty) {
          categories = categoriesSnapshot.docs
              .map((doc) => Category.fromJson(doc.data()))
              .toList();
        } else {
          // Try custom_categories collection as fallback
          final customCategoriesSnapshot = await _firestore
              .collection('custom_categories')
              .where('userId', isEqualTo: profileId)
              .get();
          
          categories = customCategoriesSnapshot.docs
              .map((doc) => Category.fromJson(doc.data()))
              .toList();
        }
      } catch (e) {
        print('Warning: Could not load categories: $e');
        categories = [];
      }

      // Create profile with cloud data with comprehensive null safety
      final profile = UserProfile(
        id: profileData['id']?.toString() ?? profileId,
        name: profileData['name']?.toString() ?? 'Unnamed Profile',
        role: _parseUserRole(profileData['role']),
        avatarPath: profileData['avatarPath']?.toString(),
        createdAt: _parseDateTime(profileData['createdAt']) ?? DateTime.now(),
        lastActiveAt: _parseDateTime(profileData['lastActiveAt']) ?? DateTime.now(),
        settings: _parseProfileSettings(profileData['settings']),
        pin: profileData['pin']?.toString(),
        email: profileData['email']?.toString(),
        phoneNumber: profileData['phoneNumber']?.toString(),
        subscription: _parseSubscription(profileData['subscription']),
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

  /// Find user profile by email when Firebase UID doesn't match document ID
  Future<UserProfile?> findProfileByEmail(String email) async {
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw CloudSyncException('User not authenticated', 'not_authenticated');
      }

      // Query for profile by email
      final querySnapshot = await _firestore
          .collection('user_profiles')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final profileDoc = querySnapshot.docs.first;
      final profileData = profileDoc.data();
      final profileId = profileDoc.id;
      
      // Load associated data using the found profile ID
      List<Symbol> symbols = [];
      List<Category> categories = [];
      
      try {
        // Try subcollection first
        final symbolsSnapshot = await _firestore
            .collection('user_profiles/$profileId/symbols')
            .get();
        
        if (symbolsSnapshot.docs.isNotEmpty) {
          symbols = symbolsSnapshot.docs
              .map((doc) => Symbol.fromJson(doc.data()))
              .toList();
        } else {
          // Try custom_symbols collection as fallback
          final customSymbolsSnapshot = await _firestore
              .collection('custom_symbols')
              .where('userId', isEqualTo: profileId)
              .get();
          
          symbols = customSymbolsSnapshot.docs
              .map((doc) => Symbol.fromJson(doc.data()))
              .toList();
        }
      } catch (e) {
        print('Warning: Could not load symbols for profile $profileId: $e');
      }
      
      try {
        // Try subcollection first
        final categoriesSnapshot = await _firestore
            .collection('user_profiles/$profileId/categories')
            .get();
        
        if (categoriesSnapshot.docs.isNotEmpty) {
          categories = categoriesSnapshot.docs
              .map((doc) => Category.fromJson(doc.data()))
              .toList();
        } else {
          // Try custom_categories collection as fallback
          final customCategoriesSnapshot = await _firestore
              .collection('custom_categories')
              .where('userId', isEqualTo: profileId)
              .get();
          
          categories = customCategoriesSnapshot.docs
              .map((doc) => Category.fromJson(doc.data()))
              .toList();
        }
      } catch (e) {
        print('Warning: Could not load categories for profile $profileId: $e');
      }

      // Create profile with found data
      final profile = UserProfile(
        id: profileData['id']?.toString() ?? profileId,
        name: profileData['name']?.toString() ?? 'Unnamed Profile',
        role: _parseUserRole(profileData['role']),
        avatarPath: profileData['avatarPath']?.toString(),
        createdAt: _parseDateTime(profileData['createdAt']) ?? DateTime.now(),
        lastActiveAt: _parseDateTime(profileData['lastActiveAt']) ?? DateTime.now(),
        settings: _parseProfileSettings(profileData['settings']),
        pin: profileData['pin']?.toString(),
        email: profileData['email']?.toString(),
        phoneNumber: profileData['phoneNumber']?.toString(),
        subscription: _parseSubscription(profileData['subscription']),
        userSymbols: symbols,
        userCategories: categories,
      );

      return profile;
    } on FirebaseException catch (e) {
      await _crashReportingService.reportException(
        CloudSyncException('Firebase error during profile search: ${e.message}', e.code)
      );
      print('Firebase error finding profile by email: $e');
      return null;
    } catch (e) {
      await _crashReportingService.reportException(
        CloudSyncException('Unexpected error during profile search: $e')
      );
      print('Error finding profile by email: $e');
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

      // Load user's profile directly using their Firebase UID
      final profile = await loadProfileFromCloud(user.uid);
      
      if (profile != null) {
        return [profile];
      } else {
        return [];
      }
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
  
  /// Helper method to safely parse UserRole
  UserRole _parseUserRole(dynamic roleData) {
    try {
      if (roleData == null) return UserRole.child;
      
      final roleString = roleData.toString();
      return UserRole.values.firstWhere(
        (role) => role.toString() == roleString || role.name == roleString,
        orElse: () => UserRole.child,
      );
    } catch (e) {
      print('Error parsing user role: $e');
      return UserRole.child;
    }
  }
  
  /// Helper method to safely parse DateTime
  DateTime? _parseDateTime(dynamic dateData) {
    try {
      if (dateData == null) return null;
      
      if (dateData is Timestamp) {
        return dateData.toDate();
      } else if (dateData is String) {
        return DateTime.parse(dateData);
      } else if (dateData is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateData);
      }
      
      return null;
    } catch (e) {
      print('Error parsing DateTime: $e');
      return null;
    }
  }
  
  /// Helper method to safely parse ProfileSettings
  ProfileSettings _parseProfileSettings(dynamic settingsData) {
    try {
      if (settingsData == null) return ProfileSettings();
      
      if (settingsData is Map<String, dynamic>) {
        return ProfileSettings.fromJson(settingsData);
      }
      
      return ProfileSettings();
    } catch (e) {
      print('Error parsing ProfileSettings: $e');
      return ProfileSettings();
    }
  }
  
  /// Helper method to safely parse Subscription
  Subscription _parseSubscription(dynamic subscriptionData) {
    try {
      if (subscriptionData == null) {
        return const Subscription(
          plan: SubscriptionPlan.free,
          price: 0.0,
        );
      }
      
      if (subscriptionData is Map<String, dynamic>) {
        return Subscription.fromJson(subscriptionData);
      }
      
      return const Subscription(
        plan: SubscriptionPlan.free,
        price: 0.0,
      );
    } catch (e) {
      print('Error parsing Subscription: $e');
      return const Subscription(
        plan: SubscriptionPlan.free,
        price: 0.0,
      );
    }
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