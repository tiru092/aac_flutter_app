
import 'package:supabase_flutter/supabase_flutter.dart';
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

  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();
  final CrashReportingService _crashReportingService = CrashReportingService();
  // final FirebaseSyncService _firebaseSyncService = FirebaseSyncService(); // Disabled Firebase sync
  final LocalDataManager _localDataManager = LocalDataManager();

  DateTime? _lastSyncTimestamp;

  Future<void> syncAllData() async {
    final user = _authService.currentUser;
    if (user == null) {
      return;
    }

    try {
      // Firebase sync disabled - replace with Supabase
      // final symbols = await _firebaseSyncService.getSymbolsFromCloud(user.id, lastSync: _lastSyncTimestamp);
      // for (final symbol in symbols) {
      //   await _localDataManager.addUserData(userId: user.id, newSymbol: symbol);
      // }

      // final categories = await _firebaseSyncService.getCategoriesFromCloud(user.id, lastSync: _lastSyncTimestamp);
      // for (final category in categories) {
      //   await _localDataManager.addUserData(userId: user.id, newCategory: category);
      // }

      _lastSyncTimestamp = DateTime.now();
    } catch (e, s) {
      _crashReportingService.reportError(e, s, 'Error during full data sync');
    }
  }

  Future<void> syncOnDataChange(String userId, {Symbol? symbol, Category? category, String? deletedSymbolId, String? deletedCategoryId}) async {
    final user = _authService.currentUser;
    if (user == null || user.id != userId) {
      return;
    }

    try {
      // Firebase sync operations disabled - replace with Supabase
      // if (symbol != null) {
      //   await _firebaseSyncService.syncSymbolsToCloud(userId, [symbol]);
      // }
      // if (category != null) {
      //   await _firebaseSyncService.syncCategoriesToCloud(userId, [category]);
      // }
      // if (deletedSymbolId != null) {
      //   await _firebaseSyncService.deleteSymbolFromCloud(userId, deletedSymbolId);
      // }
      // if (deletedCategoryId != null) {
      //   await _firebaseSyncService.deleteCategoryFromCloud(userId, deletedCategoryId);
      // }
      
      // TODO: Add Supabase sync operations here
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
      // TODO: Replace with Supabase query
      final response = await _supabase.from('user_profiles').select().eq('id', userId).maybeSingle();
      if (response != null) {
        return UserProfile.fromJson(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Find profile by email
  Future<UserProfile?> findProfileByEmail(String email) async {
    try {
      // TODO: Replace with Supabase query
      final response = await _supabase.from('user_profiles').select().eq('email', email).maybeSingle();
      if (response != null) {
        return UserProfile.fromJson(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Sync profile to cloud
  Future<void> syncProfileToCloud(UserProfile profile) async {
    try {
      // TODO: Replace with Supabase upsert\n      await _supabase.from('user_profiles').upsert(profile.toJson());
    } catch (e, s) {
      _crashReportingService.reportError(e, s, 'Error syncing profile to cloud');
    }
  }

  /// Compatibility wrapper for older callers that expect a method named
  /// `shareProfileWithUser(profileId, email)`. This forwards to current
  /// sync APIs while keeping the cloud sync service as the single authority.
  Future<void> shareProfileWithUser(String profileId, String email) async {
    try {
      // TODO: Replace with Supabase operations
      final response = await _supabase.from('user_profiles').select().eq('id', profileId).maybeSingle();
      if (response == null) return;
      final data = Map<String, dynamic>.from(response);
      final sharedWith = List<String>.from(data['sharedWith'] ?? []);
      if (!sharedWith.contains(email)) {
        sharedWith.add(email);
        data['sharedWith'] = sharedWith;
        // TODO: Replace with Supabase upsert operation
        // await _supabase.from('shared_profiles').upsert(data);
      }
    } catch (e, s) {
      _crashReportingService.reportError(e, s, 'Error sharing profile with user');
    }
  }

  /// Load all profiles from cloud
  Future<List<UserProfile>> loadAllProfilesFromCloud() async {
    try {
      // TODO: Replace with Supabase query
      final response = await _supabase.from('user_profiles').select();
      return response.map<UserProfile>((data) => UserProfile.fromJson(data)).toList();
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
