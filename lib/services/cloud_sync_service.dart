
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/symbol.dart';
import '../models/user_profile.dart';
import '../models/subscription.dart';  // Add missing import
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../services/crash_reporting_service.dart';
import 'firebase_sync_service.dart';
import 'local_data_manager.dart';

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
  final FirebaseSyncService _firebaseSyncService = FirebaseSyncService();
  final LocalDataManager _localDataManager = LocalDataManager();

  DateTime? _lastSyncTimestamp;

  Future<void> syncAllData() async {
    final user = _authService.currentUser;
    if (user == null) {
      return;
    }

    try {
      final symbols = await _firebaseSyncService.getSymbolsFromCloud(user.uid, lastSync: _lastSyncTimestamp);
      for (final symbol in symbols) {
        await _localDataManager.addUserData(userId: user.uid, newSymbol: symbol);
      }

      final categories = await _firebaseSyncService.getCategoriesFromCloud(user.uid, lastSync: _lastSyncTimestamp);
      for (final category in categories) {
        await _localDataManager.addUserData(userId: user.uid, newCategory: category);
      }

      _lastSyncTimestamp = DateTime.now();
    } catch (e, s) {
      _crashReportingService.reportError(e, s, 'Error during full data sync');
    }
  }

  Future<void> syncOnDataChange(String userId, {Symbol? symbol, Category? category, String? deletedSymbolId, String? deletedCategoryId}) async {
    final user = _authService.currentUser;
    if (user == null || user.uid != userId) {
      return;
    }

    try {
      if (symbol != null) {
        await _firebaseSyncService.syncSymbolsToCloud(userId, [symbol]);
      }
      if (category != null) {
        await _firebaseSyncService.syncCategoriesToCloud(userId, [category]);
      }
      if (deletedSymbolId != null) {
        await _firebaseSyncService.deleteSymbolFromCloud(userId, deletedSymbolId);
      }
      if (deletedCategoryId != null) {
        await _firebaseSyncService.deleteCategoryFromCloud(userId, deletedCategoryId);
      }
    } catch (e, s) {
      _crashReportingService.reportError(e, s, 'Error during data change sync');
    }
  }

  /// Check if cloud sync is available
  bool get isCloudSyncAvailable {
    final user = _authService.currentUser;
    return user != null;
  }

  /// Load user profile from cloud
  Future<UserProfile?> loadProfileFromCloud(String userId) async {
    try {
      final doc = await _firestore.collection('profiles').doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Find profile by email
  Future<UserProfile?> findProfileByEmail(String email) async {
    try {
      final query = await _firestore.collection('profiles').where('email', isEqualTo: email).get();
      if (query.docs.isNotEmpty) {
        return UserProfile.fromJson(query.docs.first.data());
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Sync profile to cloud
  Future<void> syncProfileToCloud(UserProfile profile) async {
    try {
      await _firestore.collection('profiles').doc(profile.id).set(profile.toJson());
    } catch (e, s) {
      _crashReportingService.reportError(e, s, 'Error syncing profile to cloud');
    }
  }

  /// Load all profiles from cloud
  Future<List<UserProfile>> loadAllProfilesFromCloud() async {
    try {
      final query = await _firestore.collection('profiles').get();
      return query.docs.map((doc) => UserProfile.fromJson(doc.data())).toList();
    } catch (e) {
      return [];
    }
  }

  /// Sync all profiles to cloud
  Future<void> syncAllProfilesToCloud() async {
    try {
      // This would sync local profiles to cloud - placeholder implementation
    } catch (e, s) {
      _crashReportingService.reportError(e, s, 'Error syncing all profiles to cloud');
    }
  }
}
